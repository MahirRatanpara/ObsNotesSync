# System Design Interview Checklist

## Requirements (first 5 minutes)

- [ ] Listed 3–4 functional requirements and wrote them down
- [ ] **Asked which are highest priority**
- [ ] Stated non-goals explicitly ("I'm excluding payments — reasonable?")
- [ ] **Asked the read:write ratio**
- [ ] Asked expected scale (DAU, QPS, data volume)
- [ ] Asked the latency target
- [ ] Asked the availability target
- [ ] Asked whether consistency or availability matters more
- [ ] Asked about data retention and compliance constraints

## Estimation

- [ ] Computed writes/sec from daily volume
- [ ] Applied a peak multiplier (2–3×)
- [ ] Computed reads/sec from the ratio
- [ ] Computed storage per year
- [ ] **Concluded whether this fits on one machine** — and said so
- [ ] Rounded aggressively rather than doing precise arithmetic

## API

- [ ] Defined the core endpoints with request and response shapes
- [ ] Used cursor pagination, not offset
- [ ] Considered idempotency keys on write endpoints
- [ ] Chose sensible status codes (including 429)

## Data Model

- [ ] Listed the access patterns **before** choosing a database
- [ ] Justified the database choice against those patterns
- [ ] Defined the partition/shard key and justified it
- [ ] Named the indexes each query needs
- [ ] Considered whether denormalisation is warranted

## High-Level Design

- [ ] Started minimal, added components only when a requirement forced them
- [ ] **Can justify every box in one sentence**
- [ ] Showed the write path and the read path separately
- [ ] Identified the source of truth
- [ ] Marked where the data is cached

## Deep Dives (the part that decides your level)

- [ ] **Proposed the deep-dive topic myself**
- [ ] Covered at least two of:
  - [ ] Hot key / celebrity problem
  - [ ] Cache stampede or invalidation
  - [ ] Exactly-once / idempotency
  - [ ] Cross-service consistency (saga)
  - [ ] Real-time delivery mechanism
  - [ ] Failure and failover behaviour
  - [ ] Rate limiting at scale
- [ ] Gave concrete numbers, not just component names

## Reliability

- [ ] Every synchronous call has a timeout
- [ ] Retries are jittered and only on idempotent operations
- [ ] Circuit breaker on external dependencies
- [ ] Bulkhead / pool isolation per dependency
- [ ] Stated what happens when each major component fails
- [ ] Stated the degraded mode (what still works if the cache dies?)

## Wrap Up

- [ ] Named the remaining bottleneck
- [ ] Named the main trade-off I made and why
- [ ] Named what I'd monitor (p99, cache hit rate, replication lag, queue depth, DLQ)
- [ ] Named what I'd build next

## Red Flags To Avoid

- [ ] Did not add Kafka/Redis/Elasticsearch without justification
- [ ] Did not design for 1B users when asked for 10K
- [ ] Did not spend 30 minutes on the box diagram
- [ ] Did not claim "CA" from CAP
- [ ] Did not claim exactly-once delivery end to end
- [ ] Did not ignore the failure cases

## Related

- [System Design Delivery Framework](../04%20High%20Level%20Design/Interview%20Framework/System%20Design%20Delivery%20Framework.md)
- [HLD Cheat Sheet](../Cheat%20Sheets/HLD%20Cheat%20Sheet.md)
- [System Design Flash Cards](../Flash%20Cards/System%20Design%20Flash%20Cards.md)
