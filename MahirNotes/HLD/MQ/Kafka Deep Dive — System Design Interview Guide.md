
---

## 1. Consumer Groups & Partition Assignment

- Topic → N partitions. Each partition → exactly 1 consumer in a group.
- One consumer can handle multiple partitions.
- **Max parallelism = number of partitions.** Extra consumers sit idle.

### Rebalancing (Common Cross-Question)

Triggered when: consumer joins/leaves, crashes, new partitions added.

|Strategy|Behavior|Downside|
|---|---|---|
|Eager|Revokes ALL partitions, reassigns|Full stop-the-world pause|
|Cooperative (Incremental)|Only moves affected partitions|Preferred in production; minor latency blip|

**Cross-Q: "What happens if a consumer is slow but alive?"** → If `poll()` interval exceeds `max.poll.interval.ms`, coordinator considers it dead → triggers rebalance. Tuning: increase interval or reduce `max.poll.records`.

### Partition Assignment Strategies

|Strategy|Use When|
|---|---|
|RangeAssignor|Co-partitioned topics (joins across topics)|
|RoundRobinAssignor|Uniform distribution, no ordering needs|
|StickyAssignor|Minimize partition movement during rebalance|
|CooperativeStickyAssignor|Best default — sticky + incremental rebalance|

---

## 2. Offset Management

- Each consumer tracks its position per partition via **committed offset**.
- Stored in internal topic: `__consumer_offsets`.

|Mode|Behavior|Risk|
|---|---|---|
|`enable.auto.commit=true`|Commits periodically (default 5s)|Duplicates on crash (offset committed but processing incomplete)|
|Manual sync commit|`commitSync()` after processing|Blocks thread, slower|
|Manual async commit|`commitAsync()` after processing|Fast but no retry on failure|

**Interview pattern:** Manual commit + idempotent processing = at-least-once with safe replay.

**Cross-Q: "What if a consumer restarts with no committed offset?"** → `auto.offset.reset`: `earliest` (replay all) | `latest` (skip to head) | `none` (throw error).

---

## 3. How `poll()` Works

- Fetches from **all** assigned partitions in one call.
- Returns `ConsumerRecords` → `Map<TopicPartition, List<ConsumerRecord>>`.
- Ordering guaranteed **only within a partition**, never across.

```java
for (TopicPartition partition : records.partitions()) {
    for (ConsumerRecord record : records.records(partition)) {
        process(record);
    }
    // commit per-partition if needed
    consumer.commitSync(Map.of(partition, new OffsetAndMetadata(lastOffset + 1)));
}
```

**Cross-Q: "How to process partitions in parallel?"** → Dispatch each partition's records to a thread pool. Commit offsets only after thread confirms completion. Be careful — out-of-order commits can cause data loss.

---

## 4. Replication Model (Leader-Follower)

- Each partition: 1 Leader + N-1 Followers (replication factor = N).
- Producers → Leader. Consumers → Leader (default).
- Followers pull from leader (poll-based replication, not push).

### Write Path (Internal)

```
Producer → Leader Broker
  → Append to local log (page cache + sequential write)
  → Followers fetch via ReplicaFetcherThread
  → Leader advances HW once ISR replicas catch up
```

**Cross-Q: "Is replication synchronous or asynchronous?"** → Technically async (followers pull), but `acks=all` makes the producer **wait** until all ISR replicas acknowledge (Here the wait means that the producer has not got an 200 or an acknowledge response. Even though the producer can send the new message in the newer version of Kafka, they can multi-line the different messages in the pipeline until the HW progresses. Here the wait only means that the producer has not received the ACK response until the replicas acknowledge. If the producer is producing the messages from the different thread, then they might be able to send two different messages, may be in different or same partition; we don't know. They should be able to send two different messages and should be waiting for the acknowledgement). So from the producer's perspective it behaves synchronously — from replication internals, it's async pull.

---

## 5. ISR (In-Sync Replicas)

ISR = subset of replicas that are:

- Caught up to leader's log end offset (within `replica.lag.time.max.ms`, default 30s)
- Heartbeating to controller

**Key behaviors:**

- Follower falls behind → removed from ISR → no impact on writes if `min.insync.replicas` still met.
- Follower catches up → re-added to ISR automatically.
- Leader fails → new leader elected **only from ISR**.

**Cross-Q: "What if all ISR replicas die?"** → Depends on `unclean.leader.election.enable`:

- `false` (default): partition goes offline. No data loss but unavailable.
- `true`: out-of-sync replica becomes leader. Available but **data loss possible**.

This is a classic **availability vs consistency** trade-off question.

---

## 6. High Watermark (HW)

- HW = highest offset replicated to **all ISR replicas**.
- Consumers can **only read up to HW** — prevents dirty reads.
- Leader Epoch (introduced later) prevents log divergence after leader changes.

### Message Visibility Flow

```
Producer sends M10
  → Leader appends at offset 10 (LEO=11)
  → Followers replicate M10
  → All ISR at offset 10
  → HW advances to 10
  → Consumer can now read M10
```

**Cross-Q: "Can a consumer ever read uncommitted data?"** → No, HW prevents this. Even with `acks=1`, the message is only visible to consumers after HW advances (ISR replication).

**Subtle point:** `acks=1` means producer gets ACK before HW advances. So producer thinks message is safe, but if leader dies before replication, message is **lost AND was never visible to consumers**.

---

## 7. Producer Durability Settings

|Setting|Meaning|Trade-off|
|---|---|---|
|`acks=0`|Fire and forget|Fastest, no durability|
|`acks=1`|Leader ACK only|Fast, risk of loss on leader crash|
|`acks=all`|All ISR ACK|Safest, slight latency (+2-5ms typical)|
|`min.insync.replicas=2`|At least 2 ISR must ACK|Prevents single-replica ISR from accepting writes|

**Production-safe combo:** `acks=all` + `min.insync.replicas=2` + `replication.factor=3`.

**Cross-Q: "What if ISR shrinks to 1 and min.insync.replicas=2?"** → Producer gets `NotEnoughReplicasException`. Writes fail. This is by design — you chose consistency over availability.

---

## 8. Exactly-Once Semantics (EOS)

### Idempotent Producer (`enable.idempotence=true`)

- Assigns Producer ID (PID) + sequence number per partition.
- Broker deduplicates retries. Prevents duplicates within a single session.
- No protection across producer restarts (new PID).

### Transactional Producer

- `transactional.id` → survives restarts (fences zombie producers).
- Atomic writes across multiple partitions.
- Consumer side: `isolation.level=read_committed` → only reads committed transactional messages.

**Cross-Q: "Is Kafka exactly-once end-to-end?"** → Only within Kafka-to-Kafka (consume-transform-produce). For external sinks (DB, API), you need idempotent consumers + deduplication at the sink.

---

## 9. Partitioning Strategy

|Strategy|Behavior|
|---|---|
|Key-based (default)|`hash(key) % numPartitions` → same key always same partition|
|Round-robin|No key → even distribution, no ordering|
|Custom partitioner|Implement `Partitioner` interface|

**Cross-Q: "What happens when you add partitions?"** → Key-to-partition mapping breaks (different hash result). Existing data stays in old partitions, new data goes to new mapping. **Never increase partitions for keyed topics in production without careful planning.**

**Cross-Q: "How many partitions should I have?"** → Rule of thumb: target throughput / per-partition throughput. Each partition adds ~few KB metadata overhead. 10K+ partitions per cluster is where things get heavy (leader election storms, controller bottleneck).

---

## 10. Log Storage & Retention

### Retention Policies

|Policy|Config|Use Case|
|---|---|---|
|Time-based|`retention.ms` (default 7 days)|Event streams|
|Size-based|`retention.bytes`|Bounded storage|
|Compaction|`cleanup.policy=compact`|Changelog / KTable / latest-state-per-key|

### Log Compaction (Cross-Question Favorite)

- Keeps **only the latest value per key**.
- Tombstone: message with key + null value → signals deletion.
- Use case: CDC, materialized views, config topics.

**Cross-Q: "How does Kafka achieve fast writes?"** → Sequential disk I/O (append-only log), OS page cache (no JVM GC pressure), zero-copy transfer (`sendfile` syscall), batching at producer and broker.

---

## 11. Fetch-From-Follower (KIP-392)

- Consumer sets `client.rack` → broker matches to closest replica.
- Useful for multi-DC / multi-AZ deployments to reduce cross-AZ network costs.

|Mode|Consistency|Latency|
|---|---|---|
|Leader read|Strong (up to HW)|Cross-AZ possible|
|Follower read|Still bounded by HW (safe)|Local-AZ, lower latency|

**Key point:** Even follower reads are bounded by HW — no dirty reads. The trade-off is **staleness** (follower may be slightly behind leader's HW), not correctness.

---

## 12. Kafka vs Alternatives (System Design Context)

|When to Use Kafka|When NOT to Use Kafka|
|---|---|
|High-throughput event streaming|Simple task queue (use SQS/RabbitMQ)|
|Event sourcing / CDC|Request-reply pattern|
|Decoupling microservices at scale|Low message volume (<100 msg/s)|
|Replay capability needed|Need message-level routing/filtering (use RabbitMQ)|
|Ordered processing per entity|Priority queues|

---

## 13. Common System Design Integration Patterns

**Event-Driven Architecture:**

```
Service A → Kafka Topic → Service B, Service C (independent consumer groups)
```

**CQRS + Kafka:**

```
Command → Write DB → CDC via Kafka → Read DB (materialized view)
```

**Saga / Choreography:**

```
Order Service → order-events → Payment Service → payment-events → Shipping Service
```

Each service consumes and produces to coordinate distributed transactions.

---

## 14. Key Configs Cheat Sheet

|Config|Default|What It Controls|
|---|---|---|
|`replication.factor`|1|Number of copies per partition|
|`min.insync.replicas`|1|Min replicas for `acks=all`|
|`acks`|all (≥3.0)|Producer durability level|
|`max.poll.interval.ms`|300000|Max time between polls before rebalance|
|`session.timeout.ms`|45000|Heartbeat-based consumer liveness|
|`replica.lag.time.max.ms`|30000|Max lag before follower leaves ISR|
|`unclean.leader.election.enable`|false|Allow out-of-sync leader election|
|`enable.idempotence`|true (≥3.0)|Deduplicate producer retries|

---

## 15. ZooKeeper vs KRaft (Post Kafka 3.3+)

|Aspect|ZooKeeper Mode|KRaft Mode|
|---|---|---|
|Metadata management|External ZK cluster|Internal quorum controller|
|Scalability bottleneck|ZK watches at ~200K partitions|Millions of partitions possible|
|Operational complexity|2 systems to manage|Single system|
|Leader election|Via ZK ephemeral nodes|Raft-based internal consensus|

**Status:** ZK deprecated in 3.5, removal planned in 4.0. KRaft is production-ready.

---

## 16. Interview Quick-Fire Answers

**"How does Kafka guarantee ordering?"** → Per-partition only. Same key → same partition → ordered. Cross-partition = no ordering.

**"Can messages be lost?"** → With `acks=all` + `min.insync.replicas=2` + `replication.factor=3`: no, unless entire cluster dies.

**"How does Kafka handle backpressure?"** → It doesn't explicitly. Consumer pulls at its own pace. If consumer is slow → lag grows. Monitor via consumer lag metric. Scale consumers (up to partition count).

**"What's the difference between Kafka and a traditional message queue?"** → Kafka retains messages after consumption (log-based). Multiple consumer groups can independently read. Messages are not deleted on read. Enables replay.

**"How do you handle poison pills / bad messages?"** → Dead letter topic pattern. Catch processing exceptions → publish to DLT → alert + manual review. Don't let one bad record block the partition.

**"What happens during a broker failure?"** → Controller detects failure → reassigns leadership for affected partitions from ISR → producers/consumers discover new leaders via metadata refresh. Typically <5s recovery.

---

## 17. One-Liner for Interview Introduction

> "Kafka is a distributed, partitioned, replicated commit log that provides durable, ordered, high-throughput messaging with replay capability — using leader-based replication, ISR tracking, and high watermark to balance consistency, durability, and latency."