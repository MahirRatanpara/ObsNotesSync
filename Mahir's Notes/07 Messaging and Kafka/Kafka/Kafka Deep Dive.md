# Kafka Deep Dive

## Why It Matters

The default answer for event streaming in system design, and interviewers probe the internals to separate users from people who understand it.

## Core Model

Kafka is a **distributed, partitioned, replicated commit log**. Not a queue — messages are not removed on read; consumers track their own offset.

```
Topic
 ├── Partition 0 : [msg0][msg1][msg2] ...   ← ordered, append-only
 ├── Partition 1 : [msg0][msg1] ...
 └── Partition 2 : [msg0][msg1][msg2] ...
```

**Ordering is guaranteed only within a partition**, never across a topic. To get ordering for an entity, use its id as the message key — the same key always hashes to the same partition.

## Consumer Groups

- Each partition is assigned to **exactly one consumer** within a group
- Multiple groups each receive **all** messages independently (pub-sub)
- **Parallelism is capped by partition count** — 10 consumers on 4 partitions leaves 6 idle

**This is the most common Kafka interview question:** you cannot scale consumers beyond the partition count. Choose partition count for peak future parallelism, since increasing it later breaks key-to-partition mapping.

### Rebalancing

Triggered when a consumer joins, leaves, or fails a heartbeat. With the default eager protocol, **all** consumers stop briefly ("stop-the-world"). **Cooperative sticky** assignment (`CooperativeStickyAssignor`) only moves the partitions that must move — the modern default recommendation.

Common cause of unwanted rebalances: `max.poll.interval.ms` exceeded because processing a batch took too long. The consumer is presumed dead. Fix by reducing `max.poll.records` or moving work off the poll thread.

## Replication and ISR

Each partition has one **leader** and N−1 **followers**. All reads and writes go to the leader (except with follower fetching, KIP-392, for locality).

**ISR (In-Sync Replicas)** — replicas caught up within `replica.lag.time.max.ms`. A replica that falls behind is removed from the ISR and cannot be elected leader (unless unclean election is enabled).

**High Watermark** — the highest offset replicated to all ISR members. **Consumers can only read up to the high watermark**, which guarantees they never see a message that could be lost in a leader failover.

## Durability Configuration

| Setting | Guarantee |
|---|---|
| `acks=0` | Fire and forget — may lose everything |
| `acks=1` | Leader wrote it — lost if the leader dies before replication |
| **`acks=all`** | All ISR members wrote it |

`acks=all` alone is insufficient. Combine with:

```properties
acks=all
min.insync.replicas=2          # on the topic; fail the write if fewer
replication.factor=3
unclean.leader.election.enable=false
```

**`min.insync.replicas=2` with `replication.factor=3`** is the standard durable configuration: it survives one broker loss and refuses writes rather than accepting unreplicated data. Setting `min.insync.replicas=1` silently reduces `acks=all` to `acks=1`.

**Unclean leader election** allows an out-of-sync replica to become leader — restoring availability at the cost of **silent data loss**. Keep it off unless availability strictly dominates.

## Delivery Semantics

| Semantic | How |
|---|---|
| At-most-once | Commit offset **before** processing |
| **At-least-once** | Commit **after** processing — the practical default |
| Exactly-once | Idempotent producer + transactions, or at-least-once + idempotent consumer |

**Idempotent producer** (`enable.idempotence=true`, default since 3.0) — each producer gets a PID and per-partition sequence numbers, so the broker discards duplicates from retries. Prevents duplicates from *producer retries only*.

**Transactions** give atomic writes across partitions plus offset commits, enabling exactly-once *within Kafka* (consume-transform-produce). Consumers must set `isolation.level=read_committed`.

**The honest caveat:** exactly-once does **not** extend to external systems. If your consumer writes to a database, you still need an idempotency key there. Say this — interviewers look for it.

## Log Storage

Partitions are segment files. Retention is by time (`retention.ms`) or size (`retention.bytes`).

**Log compaction** (`cleanup.policy=compact`) keeps only the **latest value per key** indefinitely — turning a topic into a durable changelog. This is how Kafka Connect stores state and how you build a materialisable table from a stream.

## Kafka vs SQS vs RabbitMQ

| | Kafka | SQS | RabbitMQ |
|---|---|---|---|
| Model | Distributed log | Managed queue | Broker with exchanges |
| Throughput | **Millions/sec** | High | Moderate |
| Ordering | Per partition | FIFO queues only | Per queue |
| Replay | **Yes — reset offsets** | No | No |
| Multiple consumers of the same message | **Yes (groups)** | No (unless SNS fan-out) | Yes (exchanges) |
| Per-message TTL / delay | No | Yes | Yes |
| Routing | Simple (key → partition) | Simple | **Rich (topic/header exchanges)** |
| Ops burden | **High** | **None (managed)** | Moderate |

**Choose Kafka** for high throughput, replay, event sourcing, or multiple independent consumers.
**Choose SQS** for simple decoupling on AWS with no ops burden.
**Choose RabbitMQ** for complex routing and per-message priority or delay.

**Don't reach for Kafka by default.** If the requirement is "decouple two services with modest volume", SQS is the better engineering answer, and saying so demonstrates judgement.

## KRaft

Kafka 3.3+ replaces ZooKeeper with **KRaft** — an internal Raft quorum for metadata. Simpler operations, faster failover, and support for far more partitions. ZooKeeper was removed entirely in Kafka 4.0.

## Common Mistakes

- Expecting global ordering across a topic
- More consumers than partitions and expecting more throughput
- `acks=all` without `min.insync.replicas ≥ 2`
- Believing exactly-once covers external side effects
- Leaving unclean leader election enabled
- Under-provisioning partitions (hard to increase later without breaking key ordering)

## Related Topics

- Messaging Fundamentals *(not yet written)*
- [Idempotent Consumers](Idempotent%20Consumers.md)
- Event Driven Architecture *(not yet written)*

## Revision Summary

Partitioned commit log; ordering per partition via keys; parallelism bounded by partitions. Durability needs `acks=all` plus `min.insync.replicas=2`. At-least-once plus an idempotent consumer is the practical exactly-once.

## Quick Recall

- Ordering per partition only — key by entity id
- Consumers ≤ partitions
- `acks=all` + `min.insync.replicas=2` + RF=3
- High watermark bounds consumer reads
- Compaction keeps the latest value per key
- Exactly-once stops at Kafka's boundary
