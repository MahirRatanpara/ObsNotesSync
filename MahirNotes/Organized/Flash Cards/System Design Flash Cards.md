# System Design Flash Cards

> Cover the answer column. Say the answer out loud before revealing it.

## Numbers

| Prompt | Answer |
|---|---|
| Seconds in a day | 86,400 (~10⁵) |
| 1M events/day in per-second terms | ~12/sec |
| Peak vs average multiplier | 2–3× |
| Memory reference latency | 100 ns |
| SSD random read | 100 µs |
| Datacentre round trip | 500 µs |
| Disk seek | 10 ms |
| California → Europe round trip | 150 ms |
| Single Redis node throughput | ~100K ops/sec |
| Single Postgres node writes | ~5–10K/sec |
| Commodity server QPS | ~10–50K |

## Theory

| Prompt | Answer |
|---|---|
| Why is "CA" not a real option? | Partitions are inevitable, so P is mandatory |
| CAP's C means what exactly? | Linearizability — not ACID's C |
| PACELC in one line | If Partition → A or C; Else → Latency or Consistency |
| Quorum condition for strong consistency | `R + W > N` |
| Standard quorum for N=3 | W=2, R=2 |
| Nodes needed to tolerate f failures (crash) | `2f + 1` |
| Nodes needed for Byzantine tolerance | `3f + 1` |
| Why an odd number of consensus nodes? | 4 tolerates the same failures as 3 but needs one more ack |
| What does a timeout tell you? | **Nothing** — success and failure are indistinguishable (Two Generals) |
| Practical answer to Two Generals | Idempotency keys — make retries safe |
| Why do distributed locks need fencing tokens? | A GC pause can expire the lease while the holder still acts |

## Caching

| Prompt | Answer |
|---|---|
| Default caching pattern | Cache-aside |
| On write, update or delete the cache? | **Delete** — updating races |
| Order of operations on write | DB first, then invalidate |
| Cache stampede fix | Request coalescing, or probabilistic early expiry |
| Cache penetration fix | Bloom filter, or cache the negative result |
| Cache avalanche fix | TTL jitter |
| Hot key fix | Local cache in front, or key splitting |
| Redis eviction policy that fails writes | `noeviction` |
| Is Redis LRU exact? | No — it samples |

## Data

| Prompt | Answer |
|---|---|
| Why B+ trees, not binary trees? | High fan-out → depth 3–4 → 3–4 disk seeks instead of 30 |
| What makes range scans fast in a B+ tree? | Linked leaf nodes |
| InnoDB secondary index points to what? | The **primary key**, not a physical address |
| Covering index gives you what? | An index-only scan — no second lookup |
| Composite index `(a,b,c)` cannot serve | Queries without `a` (leftmost prefix rule) |
| Column order rule | Equality columns before range columns |
| What kills index usage? | A function on the indexed column |
| LSM tree vs B-tree | LSM: higher write throughput, higher read amplification |
| Bad shard keys | Timestamp, auto-increment id, low-cardinality fields |
| Consistent hashing benefit | Only K/N keys move when a node is added |
| Why virtual nodes? | Even distribution, and failure load spreads across all nodes |
| Semi-synchronous replication means | Wait for one replica ack — bounded data loss |
| Replication vs backup | Replication faithfully copies your `DROP TABLE` |

## Messaging

| Prompt | Answer |
|---|---|
| Kafka ordering guarantee | Per **partition** only — key by entity id |
| Max useful consumers in a group | The partition count |
| Durable Kafka config | `acks=all` + `min.insync.replicas=2` + RF=3 |
| What does `min.insync.replicas=1` do to `acks=all`? | Silently reduces it to `acks=1` |
| High watermark purpose | Consumers only read fully-replicated messages |
| Log compaction keeps what? | The latest value per key |
| Does Kafka's exactly-once cover your database? | **No** — only within Kafka |
| Practical exactly-once | At-least-once + idempotent consumer |
| Where must the dedup record be written? | In the **same transaction** as the side effect |
| When to choose SQS over Kafka | Simple decoupling, no replay needed, no ops capacity |

## Resilience

| Prompt | Answer |
|---|---|
| Circuit breaker states | CLOSED → OPEN → HALF_OPEN |
| Why trip on slow calls, not just errors? | A dependency returning 200s in 10 s is failing |
| Why is a bulkhead needed alongside a breaker? | Otherwise threads still exhaust waiting on other dependencies |
| Retry preconditions | Idempotent operation, exponential backoff, **jitter**, capped attempts |
| Timeout rule across layers | Timeouts must **decrease** with depth |
| Most damaging omission | No timeout at all |
| Rate limiter allowing bursts | Token bucket |
| Fixed window flaw | 2× the limit across a window boundary |
| Rate limiter fail-open or fail-closed? | Open for user-facing reads, closed for expensive writes |

## Patterns

| Prompt | Answer |
|---|---|
| Feed fan-out for normal users vs celebrities | Push (write) vs pull (read) — hybrid |
| Large file upload | Presigned URL direct to blob storage |
| Cross-service transaction | Saga with compensating actions |
| Unique IDs at scale | Snowflake — timestamp + machine + sequence |
| Real-time push to clients | WebSocket or SSE with a pub-sub backplane |
| Pagination style | Cursor, never offset |
| Why not offset pagination? | Drifts on insert, and forces a scan-and-discard |

## Related

- [HLD Cheat Sheet](../Cheat%20Sheets/HLD%20Cheat%20Sheet.md)
- [System Design Delivery Framework](../04%20High%20Level%20Design/Interview%20Framework/System%20Design%20Delivery%20Framework.md)
- [CAP and PACELC](../04%20High%20Level%20Design/Core%20Concepts/CAP%20and%20PACELC.md)
