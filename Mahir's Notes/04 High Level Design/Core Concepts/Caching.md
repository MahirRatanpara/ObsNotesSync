# Caching

## Why It Matters

The first and highest-leverage answer to almost every latency and read-scaling problem. Also the source of the hardest correctness bugs.

## Where Caches Live

| Layer | Example | Caches | Invalidation |
|---|---|---|---|
| Client | Browser cache | Static assets, API responses | TTL / ETag |
| **CDN** | CloudFront, Cloudflare | Static and cacheable dynamic content | TTL / purge API |
| Load balancer | Nginx | Full responses | TTL |
| **Application** | Caffeine, in-process map | Hot objects, config | TTL / manual |
| **Distributed** | Redis, Memcached | Sessions, query results, computed data | TTL / explicit delete |
| Database | Buffer pool, query cache | Pages, plans | Automatic |

**Cache as close to the user as possible.** A CDN hit never touches your infrastructure at all.

## Read Patterns

### Cache-Aside (Lazy Loading) — the default

```
read:  check cache → miss → read DB → populate cache → return
write: write DB → invalidate (delete) cache entry
```

- **Pros:** only cached data is what's actually requested; cache failure is survivable
- **Cons:** every miss pays a DB hit; stale data possible between write and invalidate
- **Used by:** the overwhelming majority of systems

**Delete, don't update, on write.** Updating creates a race: two concurrent writers can interleave DB and cache writes and leave the cache permanently wrong. Deleting means the next reader repopulates from the source of truth.

### Read-Through
The cache itself loads from the DB on a miss. Same behaviour as cache-aside but the logic lives in the cache layer, not the application.

## Write Patterns

| Pattern | Flow | Pros | Cons |
|---|---|---|---|
| **Write-around** | Write DB, invalidate cache | Avoids caching write-only data | New data always misses first |
| **Write-through** | Write cache **and** DB synchronously | Cache always consistent | Higher write latency; caches data that may never be read |
| **Write-back (write-behind)** | Write cache, flush to DB async | **Fastest writes**, absorbs bursts | **Data loss if the cache dies** before flush |

**Write-back is the one to be careful with.** It's what makes some systems fast and some systems lose data. Only acceptable when loss of recent writes is tolerable, or when backed by a durable log.

## The Three Failure Modes

### Cache Stampede (Thundering Herd)
A hot key expires; thousands of concurrent requests all miss and hit the database simultaneously.

**Fixes:**
1. **Request coalescing** — the first miss takes a lock and loads; others wait for that result. In-process: `ConcurrentHashMap.computeIfAbsent`. Distributed: a short-TTL Redis lock.
2. **Probabilistic early expiration** — each reader recomputes with probability rising as the TTL approaches, so one lucky request refreshes before expiry:
   ```
   if (now - lastCompute + beta * computeTime * log(rand()) >= expiry) recompute();
   ```
3. **Stale-while-revalidate** — serve the stale value and refresh asynchronously.

### Cache Penetration
Requests for keys that **don't exist anywhere** bypass the cache and hammer the database. Often malicious.

**Fixes:** cache the negative result with a short TTL, or put a **Bloom filter** in front to reject definitely-absent keys.

### Cache Avalanche
Many keys expire simultaneously (e.g. everything was warmed at deploy with the same TTL).

**Fix:** add jitter — `ttl = base + random(0, base * 0.1)`.

## Eviction Policies

| Policy | Evicts | Best for |
|---|---|---|
| **LRU** | Least recently used | General purpose, temporal locality |
| **LFU** | Least frequently used | Stable hot sets; needs ageing or it ossifies |
| **FIFO** | Oldest inserted | Rarely optimal |
| **TTL only** | Expired entries | Time-sensitive data |
| **Random** | Arbitrary | Surprisingly competitive, very cheap |

Redis offers `allkeys-lru`, `volatile-lru`, `allkeys-lfu`, and `noeviction`. **`noeviction` makes writes fail when memory is full** — choose deliberately.

## Hot Key Problem

One key receives a disproportionate share of traffic (a celebrity, a viral post) and saturates a single shard.

**Fixes:**
- **Local caching** in front of the distributed cache — a tiny in-process cache absorbs most reads
- **Key splitting** — store `key#1..key#N` across shards, read a random one
- **Read replicas** for the hot shard

## Consistency

The hardest question in caching. Ordering matters:

```
CORRECT:  write DB → delete cache
WRONG:    delete cache → write DB
```

The wrong order lets a concurrent reader repopulate the cache from the *old* DB value between the two steps, leaving it permanently stale.

Even the correct order has a narrow race. Robust options:
- **Short TTLs** as a backstop — bounds staleness regardless of bugs
- **Delayed double delete** — delete, write, wait, delete again
- **Change data capture** — invalidate from the DB's replication log (Debezium), which is authoritative and ordered

## Common Mistakes

- Updating the cache instead of deleting it on write
- Deleting before writing
- No TTL at all — a bug then means permanent staleness
- Uniform TTLs causing avalanches
- Caching without measuring the hit rate (below ~80% often isn't worth the complexity)
- Ignoring that cache failure must be survivable — never make the cache a hard dependency

## Related Topics

- [Redis](Redis.md)
- CDN *(not yet written)*
- [Scaling Reads](Scaling%20Reads.md)
- [Consistency Models](Consistency%20Models.md)

## Revision Summary

Cache-aside with delete-on-write is the default. Guard against stampede (coalescing), penetration (Bloom filter), and avalanche (TTL jitter). Always write DB first, then invalidate. Always set a TTL.

## Quick Recall

- Cache-aside + **delete** on write, DB first
- Stampede → request coalescing / early expiry
- Penetration → Bloom filter or negative caching
- Avalanche → TTL jitter
- Hot key → local cache or key splitting
- Never make the cache a hard dependency
