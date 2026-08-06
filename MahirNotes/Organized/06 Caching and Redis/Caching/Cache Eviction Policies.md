# Cache Eviction Policies

## Why It Matters

A cache is finite; eviction decides what survives. The wrong policy on the wrong workload silently halves your hit rate, and interviewers use LRU-versus-LFU to test whether you reason about access patterns.

## The Policies

| Policy | Evicts | Strength | Weakness |
|---|---|---|---|
| **LRU** | Least recently used | Adapts fast to changing patterns | **Destroyed by a scan** |
| **LFU** | Least frequently used | Protects genuinely hot items | **Ossifies** — old popularity never decays |
| **FIFO** | Oldest inserted | Trivial, O(1) | Ignores usage entirely |
| Random | Arbitrary | Very cheap, scan-resistant | No intelligence |
| **TTL only** | Whatever expired | Bounded staleness | Doesn't bound memory |
| **ARC** | Adaptive LRU/LFU balance | Self-tuning | Patented, complex |
| **W-TinyLFU** | Frequency-gated admission | **Best hit rates in practice** | More complex |

## LRU And Its Failure Mode

Evict the item untouched for longest. Assumes **temporal locality** — recently used implies soon-to-be-used again. Usually true.

**The scan problem:** a batch job reading a million rows once pushes every genuinely hot entry out of the cache. The scanned data is never read again, but it has evicted everything valuable.

```
Cache holds hot items A,B,C  →  scan loads X1..X1000000
                             →  cache now holds only scan data
                             →  hit rate collapses to ~0
```

**This is a real production failure**, not a theoretical one. It's the strongest argument against naive LRU.

**Mitigations:** segmented LRU (a probationary segment that scanned items land in and are evicted from before reaching the protected segment), or frequency-based admission.

**Implementation:** hash map + doubly linked list gives O(1) get and evict. See [LRU Cache](../../01%20DSA/Arrays%20and%20Strings/LRU%20Cache.md).

## LFU And Its Failure Mode

Evict the least frequently accessed. Protects items that are genuinely popular rather than merely recent.

**The ossification problem:** an item that was accessed a million times last year has an unbeatable count. It never gets evicted, even though nobody has requested it in months. Meanwhile a newly popular item can't accumulate enough hits to survive.

**Fix: ageing.** Periodically halve all counters, so recent behaviour dominates. Redis's `allkeys-lfu` does this with a configurable decay time.

**Implementation:** O(1) LFU needs frequency buckets — a map of frequency → doubly linked list of items at that frequency, plus a `minFreq` pointer. Ties broken by recency within each bucket.

## W-TinyLFU — What Modern Caches Actually Use

Used by **Caffeine** (Java) and increasingly elsewhere. It changes the question from "what do I evict?" to **"should I admit this at all?"**

```
New item arrives on a miss
   ↓
Compare its estimated frequency against the eviction candidate's
   ↓
Admit only if the newcomer is more frequent
```

**Frequency is estimated with a [Count-Min Sketch](../../04%20High%20Level%20Design/Advanced%20Topics/Data%20Structures%20for%20Big%20Data.md)** — approximate counts for a huge key space in a few kilobytes, with periodic ageing.

| Component | Purpose |
|---|---|
| **Window cache** (~1%) | LRU — absorbs bursts of genuinely new items |
| **Main cache** (~99%) | Segmented LRU — protected and probationary |
| **TinyLFU admission filter** | Frequency gate between them |

**Why it beats both:** the admission filter makes it **scan-resistant** (scanned items have frequency 1 and are rejected), while the small LRU window keeps it responsive to genuinely new hot items. Ageing prevents ossification.

**Caffeine typically achieves near-optimal hit rates**, materially better than LRU on realistic workloads. Naming Caffeine and W-TinyLFU is a strong signal in any caching discussion.

## Redis Eviction Policies

```
maxmemory 4gb
maxmemory-policy allkeys-lru
```

| Policy | Behaviour |
|---|---|
| **`noeviction`** (default) | **Writes fail** with an error when memory is full |
| `allkeys-lru` | Evict LRU from all keys |
| `volatile-lru` | Evict LRU only among keys with a TTL |
| `allkeys-lfu` | Evict LFU from all keys |
| `volatile-lfu` | LFU among keys with a TTL |
| `allkeys-random` | Random from all keys |
| `volatile-ttl` | Shortest remaining TTL first |

**`noeviction` is the default and is wrong for a cache** — it turns memory pressure into write failures. Set it deliberately.

**`volatile-*` policies are dangerous if not all keys have a TTL** — if nothing is evictable, Redis behaves as `noeviction`. Use `allkeys-*` unless you're deliberately mixing cache and persistent data in one instance (which itself is usually a mistake).

**Redis LRU and LFU are approximate.** Redis samples a handful of keys (`maxmemory-samples`, default 5) and evicts the best candidate among them, rather than maintaining a global ordering. Higher sampling means better accuracy and more CPU. **This trade — precision for speed — is worth mentioning.**

## Choosing

| Workload | Policy |
|---|---|
| General purpose, changing hot set | **LRU** (or W-TinyLFU if available) |
| Stable hot set, scans present | **LFU with ageing**, or W-TinyLFU |
| Time-sensitive data | TTL-driven |
| Memory-constrained, cheap eviction matters | Random |
| Java application-level cache | **Caffeine (W-TinyLFU)** |

## Sizing And Measuring

**Hit rate is the metric.** Below ~80% and the cache is often adding a network hop without earning it.

```
effective latency = hit_rate × cache_latency + (1 - hit_rate) × db_latency
```

At 90% hit rate with a 1 ms cache and 50 ms database: `0.9 × 1 + 0.1 × 50 = 5.9 ms`. At 50%: `25.5 ms`. **Hit rate matters far more than cache latency** — that arithmetic is worth stating.

**Diminishing returns:** doubling cache size rarely doubles hit rate. Plot hit rate against size and stop where the curve flattens.

**Monitor:** hit rate, eviction rate, memory usage, and key TTL distribution. A rising eviction rate means the cache is undersized for its working set.

## Common Mistakes

- `noeviction` on a cache instance
- `volatile-*` policy with keys that have no TTL
- LRU on a scan-heavy workload
- LFU without ageing
- Never measuring the hit rate
- Assuming Redis LRU is exact
- Sizing the cache by guesswork rather than working-set measurement

## Related Topics

- [Caching Strategies](Caching%20Strategies.md)
- [Cache Invalidation](Cache%20Invalidation.md)
- [LRU Cache](../../01%20DSA/Arrays%20and%20Strings/LRU%20Cache.md)
- [Data Structures for Big Data](../../04%20High%20Level%20Design/Advanced%20Topics/Data%20Structures%20for%20Big%20Data.md)

## Revision Summary

LRU adapts quickly but collapses under scans; LFU protects hot items but ossifies without ageing. W-TinyLFU gates admission by estimated frequency and gets the best of both — it's what Caffeine uses. Redis eviction is approximate and defaults to `noeviction`, which fails writes.

## Quick Recall

- **LRU dies on scans; LFU ossifies without ageing**
- W-TinyLFU = Count-Min Sketch admission filter + small LRU window → scan-resistant
- Caffeine implements it; near-optimal hit rates
- Redis default is `noeviction` — **change it**
- `volatile-*` with no TTLs behaves as `noeviction`
- Redis LRU/LFU are sampled, not exact
- Hit rate dominates effective latency, not cache speed
