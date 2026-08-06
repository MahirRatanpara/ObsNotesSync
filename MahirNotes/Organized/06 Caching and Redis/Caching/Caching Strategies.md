# Caching Strategies

> Companion to [Caching](../../04%20High%20Level%20Design/Core%20Concepts/Caching.md), focused on choosing and combining patterns.

## Why It Matters

Picking the wrong read/write pattern combination is how caches end up serving stale data or losing writes.

## Read Patterns

| Pattern | Flow | Trade-off |
|---|---|---|
| **Cache-aside (lazy)** | App checks cache → miss → reads DB → populates | **Default.** Only requested data is cached; survives cache failure |
| **Read-through** | Cache itself loads on miss | Same behaviour, logic moved into the cache layer |
| **Refresh-ahead** | Proactively refresh entries nearing expiry | Avoids misses on hot keys; wasted work on cold ones |

## Write Patterns

| Pattern | Flow | Risk |
|---|---|---|
| **Write-around** | Write DB, invalidate cache | New data misses on first read |
| **Write-through** | Write cache **and** DB synchronously | Higher write latency; caches data that may never be read |
| **Write-back** | Write cache, flush to DB asynchronously | **Data loss if the cache dies before flush** |

## The Combinations That Actually Work

| Workload | Combination | Why |
|---|---|---|
| **Read-heavy, tolerant of brief staleness** | Cache-aside + write-around | Simplest, most common; cache holds only what's read |
| Read-heavy, needs freshness | Read-through + write-through | Cache always consistent, at write-latency cost |
| **Write-heavy, bursty** | Write-back + async flush | Absorbs bursts; **only if losing recent writes is acceptable** |
| Read-after-write critical | Cache-aside + write-through on that key | Guarantees the writer sees their own change |

**Cache-aside + write-around covers the large majority of systems.** Start there and justify anything else.

## Why Delete, Not Update

```
T1: writes DB value = A
T2: writes DB value = B
T2: updates cache = B
T1: updates cache = A          ← cache now permanently wrong
```

Two writers can interleave and leave the cache holding a stale value indefinitely. **Deleting means the next reader repopulates from the source of truth**, so the worst case is one extra miss rather than permanent corruption.

## Ordering

```
CORRECT:  write DB → delete cache
WRONG:    delete cache → write DB
```

The wrong order lets a concurrent reader repopulate from the *old* DB value in the gap between the two steps.

Even the correct order has a narrow race. Defences, in increasing robustness:

1. **Short TTL** — bounds staleness regardless of any bug
2. **Delayed double delete** — delete, write, wait briefly, delete again
3. **CDC-driven invalidation** — invalidate from the database replication log (Debezium); authoritative and correctly ordered

## Multi-Level Caching

```
Browser → CDN → App-local (Caffeine) → Distributed (Redis) → Database
```

Each layer absorbs load from the next. The **app-local layer is the underused one** — a small in-process cache in front of Redis eliminates most network round trips and neutralises hot keys.

**The cost of local caches is inconsistency between instances.** Keep TTLs very short (seconds) and only cache data where brief divergence is harmless.

## Sizing and Measuring

| Metric | Target |
|---|---|
| **Hit rate** | > 80%; below that, question whether the cache earns its complexity |
| Eviction rate | Rising evictions mean the cache is undersized |
| Latency p99 | Cache should be an order of magnitude faster than the DB |
| Memory usage | Track against `maxmemory` |

**A cache with a 40% hit rate is adding a network hop to 60% of requests.** Measure before assuming it helps.

## Common Mistakes

- Updating instead of deleting on write
- Deleting before writing
- No TTL — a bug becomes permanent staleness
- Uniform TTLs causing synchronised expiry (avalanche)
- Making the cache a hard dependency instead of an optimisation
- Never measuring the hit rate

## Related Topics

- [Caching](../../04%20High%20Level%20Design/Core%20Concepts/Caching.md)
- [Redis](../../04%20High%20Level%20Design/Key%20Technologies/Redis.md)
- [CDN](../CDN/CDN.md)
- [Scaling Reads](../../04%20High%20Level%20Design/Patterns/Scaling%20Reads.md)

## Revision Summary

Cache-aside with write-around covers most systems. Always delete rather than update, and always write the database before invalidating. Layer local caches in front of distributed ones for hot keys, bound staleness with short TTLs, and measure the hit rate.

## Quick Recall

- Default: cache-aside + write-around
- **Delete, don't update**; DB first, then invalidate
- Write-back risks losing recent writes
- Local cache in front of Redis kills hot keys
- Hit rate below 80% → reconsider
- Never a hard dependency
