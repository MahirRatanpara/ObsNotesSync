# System Design Delivery Framework

## Why It Matters

System design interviews are unbounded. Without a framework you drift, cover the wrong things, and run out of time before reaching the parts that actually differentiate levels.

## The 45-Minute Map

| Phase | Time | Output |
|---|---|---|
| 1. Requirements | 5 min | Functional, non-functional, explicit scope |
| 2. Scale estimation | 5 min | QPS, storage, bandwidth |
| 3. API design | 5 min | Core endpoints, request/response shapes |
| 4. Data model | 5 min | Entities, access patterns, DB choice |
| 5. High-level design | 10 min | Boxes and arrows that satisfy the requirements |
| 6. Deep dives | 12 min | 2–3 areas where the design is hard |
| 7. Wrap-up | 3 min | Bottlenecks, trade-offs, what you'd do next |

**The deep dives are where levels are decided.** Junior candidates spend 30 minutes on the high-level diagram; senior candidates get there in 10 and spend the rest on hard problems.

## Phase 1 — Requirements

**Functional** — cap at 3–4. Write them on the board and ask which matter most.

> "Users can post a tweet. Users can view a timeline of people they follow. Users can follow others. I'll treat search and DMs as out of scope — is that reasonable?"

**Non-functional** — this is where the design is actually determined:

| Question | Determines |
|---|---|
| Read:write ratio | Caching strategy, replication, fan-out approach |
| Consistency vs availability | Database choice, replication mode |
| Latency target | Caching, CDN, geographic distribution |
| Availability target | Redundancy, failover, multi-region |
| Data durability | Replication factor, backup strategy |

**Always ask for the read:write ratio.** A 100:1 read-heavy system and a write-heavy one have completely different designs.

## Phase 2 — Estimation

Keep it rough and round aggressively.

```
DAU 100M, 2 posts/day        → 200M writes/day
200M / 86,400                → ~2,300 writes/sec
Peak = 2× average            → ~5,000 writes/sec
Read:write 100:1             → ~500,000 reads/sec

Post = 300 bytes             → 200M × 300B = 60 GB/day
5 years                      → ~110 TB
```

**Numbers to know:**

| Operation | Latency |
|---|---|
| L1 cache reference | 1 ns |
| Main memory reference | 100 ns |
| SSD random read | 100 µs |
| Network round trip within a datacentre | 500 µs |
| Disk seek (HDD) | 10 ms |
| Round trip CA → Netherlands | 150 ms |

| Quantity | Value |
|---|---|
| Seconds per day | 86,400 (~10⁵) |
| 1M writes/day | ~12/sec |
| Single Redis node | ~100K ops/sec |
| Single Postgres node | ~5–10K writes/sec |
| Single commodity server | ~10–50K QPS |

The purpose of estimation is deciding **"does this fit on one machine?"** If yes, don't distribute.

## Phase 3 — API

Define the contract before the boxes:

```
POST /v1/posts            {content, mediaIds}       → {postId, createdAt}
GET  /v1/feed?cursor=X&limit=20                     → {posts[], nextCursor}
POST /v1/users/{id}/follow                          → 204
```

**Use cursor pagination, not offset.** Offset drifts when items are inserted, and `OFFSET 1000000` forces the database to scan and discard a million rows.

## Phase 4 — Data Model

Design from **access patterns**, not from normalised entities. For each query you must serve, ask: what index or partition key makes this O(1) or a single range scan?

| Access pattern | Implication |
|---|---|
| Point lookup by key | Any KV store |
| Range scan by time | Sort key on timestamp |
| Many-to-many traversal | Graph DB, or a well-indexed join table |
| Full-text search | Elasticsearch alongside the primary store |
| Aggregation over huge volumes | Pre-computed rollups or a stream processor |

## Phase 5 — High-Level Design

Start minimal and only add components when a requirement forces them:

```
Client → CDN → Load Balancer → API Gateway → Services → Cache → Database
                                                   ↓
                                            Message Queue → Workers
```

**Justify every box.** An unjustified Kafka is worse than no Kafka. If asked "why is that there?" and you can't answer in one sentence, remove it.

## Phase 6 — Deep Dives

Pick the genuinely hard parts. Common ones:

| Problem | Deep dive |
|---|---|
| Celebrity fan-out | Hybrid push/pull timeline |
| Hot keys | Consistent hashing + replication of hot shards |
| Thundering herd on cache miss | Request coalescing, probabilistic early expiry |
| Exactly-once processing | Idempotency keys + dedup store |
| Cross-service transactions | Saga with compensating actions |
| Real-time delivery | WebSocket/SSE with a pub-sub backplane |
| Rate limiting at scale | Local buckets + async global sync |

**Drive this yourself.** "The hardest part here is the celebrity fan-out — let me go deep on that" is a senior signal.

## Phase 7 — Wrap Up

State the remaining bottleneck, the main trade-off you made, and what you'd monitor. Naming your own design's weakness reads as maturity, not weakness.

## Common Mistakes

- Skipping requirements and designing a generic architecture
- Spending 30 minutes on boxes and never reaching a deep dive
- Adding Kafka, Redis, and Elasticsearch without justification
- Ignoring the read:write ratio
- Designing for 1B users when the requirement is 10K
- Not stating trade-offs — every choice has a cost

## Related Topics

- Back of the Envelope Estimation *(not yet written)*
- [CAP and PACELC](CAP%20and%20PACELC.md)
- [Scaling Reads](Scaling%20Reads.md)
- [Scaling Writes](Scaling%20Writes.md)

## Revision Summary

Requirements, estimation, API, data model, high-level design in 30 minutes; deep dives in the remaining 12. Justify every component. Drive the deep dive yourself.

## Quick Recall

- Always ask the read:write ratio
- 1M/day ≈ 12/sec; peak = 2× average
- Cursor pagination, never offset
- Model from access patterns
- Deep dives decide the level
