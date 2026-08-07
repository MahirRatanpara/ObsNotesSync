# HLD Cheat Sheet

## The 45-Minute Map

| Phase | Min |
|---|---|
| Requirements (functional + non-functional) | 5 |
| Estimation | 5 |
| API | 5 |
| Data model | 5 |
| High-level design | 10 |
| **Deep dives** | 12 |
| Wrap-up | 3 |

**Always ask the read:write ratio.**

## Numbers

| Latency | |
|---|---|
| Memory reference | 100 ns |
| SSD random read | 100 µs |
| Datacentre round trip | 500 µs |
| Disk seek | 10 ms |
| CA → Europe | 150 ms |

| Capacity | |
|---|---|
| Seconds/day | 86,400 |
| 1M/day | ~12/sec |
| Redis node | ~100K ops/sec |
| Postgres node | ~5–10K writes/sec |
| Commodity server | ~10–50K QPS |

Peak = 2–3× average.

## CAP / PACELC

- P is mandatory → choose **CP or AP** during a partition
- **PACELC**: else, choose **Latency or Consistency**
- `R + W > N` → strong consistency; N=3, W=2, R=2 is standard
- CA does not exist in a distributed system

## Scaling Reads

1. Index and optimise queries
2. Read replicas (watch replication lag)
3. Cache (cache-aside + delete on write)
4. CDN for static and cacheable content

## Scaling Writes

1. Vertical scaling
2. Shard (choose the key carefully — avoid hotspots)
3. Write queue for burst absorption
4. Batch writes
5. LSM-tree store for write-heavy workloads
6. Load shedding

## Caching

- **Cache-aside + delete on write**, DB first
- Stampede → request coalescing / probabilistic early expiry
- Penetration → Bloom filter / negative caching
- Avalanche → TTL jitter
- Hot key → local cache or key splitting
- Always set a TTL; never make the cache a hard dependency

## Database Selection — The Procedure

1. **Enumerate access patterns** — say this out loud before naming any database
2. **Read:write ratio?** — always ask
3. **Query shape?** — point lookup / range / join / aggregate / search / traversal
4. **Consistency per pattern** — not system-wide
5. **Does it fit on ONE node?** — usually yes; say so
6. Match shape → engine (B-tree = reads, LSM = writes)
7. **Name what you gave up**

Full procedure: [Choosing the Right Database](Choosing%20the%20Right%20Database.md)

## Database Selection

| Need | Choice |
|---|---|
| Transactions, joins, ad-hoc queries | PostgreSQL |
| Massive write throughput, known access pattern | Cassandra |
| Managed KV at scale, predictable latency | DynamoDB |
| Full-text search | Elasticsearch |
| Time series | TimescaleDB, InfluxDB |
| Graph traversal | Neo4j |
| Cache / ephemeral | Redis |
| Global strong consistency | Spanner, CockroachDB |

## Common Deep Dives

| Problem | Answer |
|---|---|
| Celebrity fan-out | Hybrid push/pull |
| Hot shard | Consistent hashing + replicate hot ranges |
| Thundering herd | Coalescing, early expiry |
| Exactly-once | Idempotency key + transactional dedup |
| Cross-service transaction | Saga + compensating actions |
| Real-time push | WebSocket/SSE + pub-sub backplane |
| Rate limiting | Local token bucket + async global sync |
| Unique ID at scale | Snowflake (timestamp + machine + sequence) |
| Large file upload | Presigned URL direct to blob storage |
| Search | Elasticsearch alongside the source of truth |

## Rate Limiting Algorithms

| Algorithm | Property |
|---|---|
| Fixed window | Simple; allows 2× burst at boundaries |
| Sliding window log | Exact; memory-heavy |
| **Sliding window counter** | Good approximation, cheap |
| **Token bucket** | Allows bursts, smooth average — most common |
| Leaky bucket | Constant output rate |

## Message Queue Selection

| Need | Choice |
|---|---|
| Replay, high throughput, multiple consumers | **Kafka** |
| Simple decoupling on AWS, zero ops | **SQS** |
| Complex routing, priority, delay | **RabbitMQ** |

## Reliability Toolkit

Timeout → Bulkhead → Circuit breaker → Rate limiter → Retry (jittered, idempotent only)

Timeouts must **decrease** with depth.

## Wrap-Up Script

> "The main bottleneck is X. I traded Y for Z because the requirement prioritised it. I'd monitor A and B, and the next thing I'd add is C."

## Related

- [System Design Delivery Framework](System%20Design%20Delivery%20Framework.md)
- [CAP and PACELC](CAP%20and%20PACELC.md)
- [Caching](Caching.md)
