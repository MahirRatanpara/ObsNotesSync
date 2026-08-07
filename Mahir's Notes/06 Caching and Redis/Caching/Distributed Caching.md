# Distributed Caching

## Why It Matters

A single cache node runs out of memory and becomes a single point of failure. Distributing it introduces partitioning, replication, and hot-key problems that don't exist locally.

## Local vs Distributed

| | **Local (in-process)** | **Distributed** |
|---|---|---|
| Latency | **Nanoseconds** | ~0.5–1 ms (network) |
| Capacity | Bounded by one JVM heap | **Scales horizontally** |
| Consistency across instances | **None — each diverges** | Shared, consistent |
| Survives restart | No | Yes |
| Cost | Free | Infrastructure |

**Use both.** A small local cache (Caffeine) in front of Redis eliminates most network round trips and neutralises hot keys, at the cost of brief divergence between instances.

```
Request → local cache (5s TTL) → Redis → Database
```

**Only cache locally what tolerates seconds of divergence.** Configuration, feature flags, and reference data qualify; a user's account balance does not.

## Partitioning Strategies

| Strategy | Rebalancing cost | Used by |
|---|---|---|
| **`hash(key) % N`** | **Catastrophic — nearly every key remaps** | Naive clients |
| **Consistent hashing** | **K/N keys move** | Memcached clients, Cassandra |
| **Fixed hash slots** | Move whole slots | **Redis Cluster** (16,384 slots) |

**Modulo hashing is the wrong answer** and interviewers check for it. Adding one node to a four-node cache remaps ~80% of keys — a total cold start and an instant stampede onto the database.

**Redis Cluster's fixed-slot approach** is worth contrasting with a hash ring: 16,384 slots are explicitly mapped to nodes, so resharding means migrating slots. Simpler to reason about and to operate than a ring, at the cost of a fixed maximum granularity.

See [Consistent Hashing](Consistent%20Hashing.md).

## Redis Cluster Constraints

**Multi-key operations only work within a single slot.**

```
MGET user:1:name user:2:name        # ERROR — likely different slots
MGET {user:1}:name {user:1}:email   # OK — hash tag forces same slot
```

**Hash tags** `{...}` make Redis hash only the braced portion, co-locating related keys.

**A key lives on exactly one primary** (plus its replicas). Redis Cluster does **not** replicate every key to every node — a common misconception worth correcting explicitly.

**Replicas serve reads only if the client opts in** (`READONLY`); by default all traffic goes to the primary.

## Redis vs Memcached

| | **Redis** | **Memcached** |
|---|---|---|
| Data structures | **Rich** — hashes, sorted sets, streams | Strings only |
| Persistence | RDB / AOF | **None** |
| Replication | Built in | None (client-side only) |
| Threading | Single-threaded commands | **Multi-threaded** |
| Memory efficiency | Higher overhead | **Slightly better for plain KV** |
| Clustering | Redis Cluster | Client-side consistent hashing |
| Eviction | Configurable, approximate | LRU (slab-based) |

**Memcached is still defensible** for pure ephemeral string caching at very high throughput — it's multi-threaded and marginally more memory-efficient. **Redis wins nearly everywhere else** because of its data structures, persistence options, and built-in replication.

**Memcached's slab allocator causes a subtle problem:** memory is divided into fixed size classes, so a workload whose value sizes shift can end up with memory stranded in the wrong slab class. Restart is often the only fix.

## Hot Keys

Consistent hashing balances **key count**, not **access frequency**. One viral key saturates one node regardless of how well keys are distributed.

| Mitigation | Detail |
|---|---|
| **Local cache in front** | The most effective — absorbs most reads before the network |
| **Key splitting** | `celebrity#0..9`, write to all, read a random one |
| **Replicate the hot key** | Copy to several nodes; read from any |
| Client-side request coalescing | One in-flight load per key per instance |

**The local cache is the answer to give first** — it requires no changes to key design and handles the problem generically.

## Consistency Between Cache And Database

The cache is a **derived** store, not a source of truth. Divergence is inevitable; the question is how you bound it.

| Guarantee needed | Approach |
|---|---|
| Bounded staleness | TTL |
| Near-real-time | Explicit invalidation + short TTL |
| Correctness under all writers | **CDC-driven invalidation** |
| Read-your-writes | Read from the primary database for N seconds after a write |

See [Cache Invalidation](Cache%20Invalidation.md).

## Failure Behaviour

**The cache must be an optimisation, never a hard dependency.**

| Failure | Correct behaviour |
|---|---|
| Cache node down | Requests fall through to the database — **slower, still correct** |
| Entire cache down | Degraded latency; must not be an outage |
| Cache returns an error | Treat as a miss, log, continue |
| Cache is slow | **Timeout aggressively** — a 50 ms cache call defeats the purpose |

**Set a very short timeout on cache calls** (10–50 ms). A slow cache is worse than no cache, because you pay its latency *and* the database's.

**Guard the fall-through.** If the cache dies and 100% of traffic hits the database, the database may not survive. Combine with request coalescing, a circuit breaker, and load shedding.

**This is the failure mode that turns a cache outage into a full outage**, and it's what interviewers probe.

## Sizing

```
working set = daily unique keys × 20% (80/20 rule) × average value size
add ~30% overhead for Redis metadata and fragmentation
```

Monitor **eviction rate** — sustained evictions mean the working set exceeds capacity, and hit rate will be poor no matter what policy you choose.

## Common Mistakes

- `hash % N` partitioning
- Multi-key operations across cluster slots without hash tags
- Assuming Redis Cluster replicates every key everywhere
- No timeout on cache calls
- Cache as a hard dependency
- No plan for the thundering herd when the cache dies
- Ignoring hot keys because "consistent hashing balances load"
- Local caches holding data that must be consistent

## Related Topics

- [Caching Strategies](Caching%20Strategies.md)
- [Cache Invalidation](Cache%20Invalidation.md)
- [Consistent Hashing](Consistent%20Hashing.md)
- [Redis](Redis.md)

## Revision Summary

Combine a small local cache with a distributed one. Partition with consistent hashing or fixed slots, never modulo. Hot keys survive good partitioning — a local cache is the general fix. Treat the cache as an optimisation with aggressive timeouts, and plan for the database load when it fails.

## Quick Recall

- Local + distributed together; local TTL in seconds
- **Never `hash % N`** — consistent hashing or fixed slots
- Redis Cluster: one primary per key; hash tags `{...}` co-locate
- Hot keys defeat consistent hashing → **local cache in front**
- Memcached: multi-threaded, no persistence, slab stranding
- **Timeout cache calls at 10–50 ms**
- Cache down must degrade, not fail — guard the herd
