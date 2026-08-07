# Redis

## Why It Matters

The default distributed cache and the Swiss army knife of system design — used for rate limiting, leaderboards, sessions, locks, and queues.

## Core Model

Single-threaded, in-memory key-value store with rich data structures.

**Why single-threaded is fast:** no lock contention, no context switches, atomic commands by construction. It's bound by memory and network, not CPU. Redis 6+ uses threads for **I/O only**; command execution remains single-threaded.

**The consequence:** one slow command blocks *everything*. `KEYS *` on a large dataset, a big `SORT`, or an expensive Lua script stalls all clients. Use `SCAN` instead of `KEYS`, always.

## Data Structures and What They're For

| Type | Use case | Key commands |
|---|---|---|
| **String** | Cache, counters | `GET`, `SET`, `INCR`, `SETNX` |
| **Hash** | Objects with fields | `HGET`, `HSET`, `HINCRBY` |
| **List** | Queues, recent items | `LPUSH`, `RPOP`, `BRPOP` |
| **Set** | Unique membership, tags | `SADD`, `SISMEMBER`, `SINTER` |
| **Sorted Set** | **Leaderboards, rate limiting, delayed queues, time-ordered feeds** | `ZADD`, `ZRANGEBYSCORE`, `ZREMRANGEBYSCORE` |
| **Bitmap** | Daily-active-user tracking | `SETBIT`, `BITCOUNT` |
| **HyperLogLog** | Approximate cardinality in 12 KB | `PFADD`, `PFCOUNT` |
| **Stream** | Append-only log with consumer groups | `XADD`, `XREADGROUP` |
| **Geo** | Proximity search | `GEOADD`, `GEOSEARCH` |

**Sorted sets are the most interview-relevant structure.** A sliding-window rate limiter is a sorted set keyed by user, scored by timestamp: remove entries older than the window, count what remains, add the new one.

**HyperLogLog** counting a billion unique visitors in 12 KB with ~0.81% error is a great detail to volunteer.

## Atomicity and Lua

Individual commands are atomic. Multi-step logic is not:

```
GET count → check limit → INCR      # RACE between GET and INCR
```

**Lua scripts execute atomically** — the whole script runs as one blocking unit:

```lua
local current = redis.call('GET', KEYS[1])
if current and tonumber(current) >= tonumber(ARGV[1]) then return 0 end
redis.call('INCR', KEYS[1])
redis.call('EXPIRE', KEYS[1], ARGV[2])
return 1
```

This is the standard rate-limiter implementation. Keep scripts short — they block the whole server.

`MULTI`/`EXEC` batches commands but **has no rollback** and can't branch on intermediate results. Lua is almost always the better tool.

## Persistence

| Mode | Mechanism | Loss window |
|---|---|---|
| **RDB** | Periodic point-in-time snapshot | Up to the snapshot interval |
| **AOF** | Append every write command | `everysec` → ~1 s; `always` → ~0 but slow |
| **Both** | RDB for fast restart, AOF for durability | Recommended default |

**Redis is not a durable database.** Even AOF `always` has edge cases. Treat it as a cache or as state you can rebuild.

## Clustering vs Replication

**Replication** — one primary, N read replicas, **asynchronous**. Replicas serve reads; failover promotes a replica. Async means a failover can lose recent writes.

**Cluster** — 16,384 hash slots distributed across primaries. The key's CRC16 determines its slot. Each primary has replicas; failover is automatic.

**The cluster constraint:** multi-key operations only work when all keys are in the **same slot**. Force this with hash tags — `{user123}:profile` and `{user123}:settings` hash only on the braced part and land together.

**Redis Cluster does not replicate a key to every node.** Each key lives on exactly one primary (plus its replicas). This surprises people who expect a globally readable cache.

**Sentinel** provides HA (monitoring and automatic failover) for non-clustered deployments.

## Distributed Locks — Handle With Care

```
SET lock:resource <unique-token> NX PX 30000
```

`NX` = only if absent; `PX` = expiry so a crashed holder doesn't deadlock. Release with a Lua script that checks the token matches — otherwise you may delete someone else's lock.

**Redlock is contested.** Martin Kleppmann's critique: a GC pause longer than the lease means two clients believe they hold the lock. **The fix is a fencing token** — a monotonic number that the protected resource checks and rejects if stale. Knowing this argument is a strong senior signal.

## Eviction

| Policy | Behaviour |
|---|---|
| `noeviction` | **Writes fail** when memory is full (default) |
| `allkeys-lru` | Evict least recently used from all keys |
| `volatile-lru` | Only among keys with a TTL |
| `allkeys-lfu` | Least frequently used |

Redis LRU is **approximate** — it samples a few keys rather than maintaining a global list, trading precision for speed.

## Common Mistakes

- `KEYS *` in production
- Long-running Lua scripts blocking the server
- Treating Redis as a durable store
- Multi-key commands across cluster slots without hash tags
- Redlock without fencing tokens
- `noeviction` in a cache role, causing write failures
- Storing very large values (>100 KB) — they block on serialisation

## Related Topics

- [Caching](Caching.md)
- [Rate Limiting](Rate%20Limiting.md)
- [Consistency Models](Consistency%20Models.md)

## Revision Summary

Single-threaded and in-memory, so one slow command blocks everything. Sorted sets cover leaderboards, rate limiting, and delayed queues. Lua gives atomic multi-step logic. Cluster keys live on one primary; use hash tags for multi-key ops. Locks need fencing tokens.

## Quick Recall

- Single-threaded → never `KEYS *`, never long scripts
- Sorted set = rate limiter, leaderboard, delayed queue
- Lua = atomic multi-step
- Async replication → failover can lose writes
- Hash tags `{...}` co-locate keys in a slot
- Fencing tokens, not Redlock alone
- HyperLogLog: 1B uniques in 12 KB
