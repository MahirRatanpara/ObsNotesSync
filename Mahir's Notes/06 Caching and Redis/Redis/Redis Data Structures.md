# Redis Data Structures

> Companion to [Redis](Redis.md), focused on choosing the right structure for a problem.

## Why It Matters

Redis is not just a key-value store. Most interview problems involving Redis are really "which data structure solves this?" — and the answer is a sorted set more often than people expect.

## Structure Selection

| Problem | Structure | Key commands |
|---|---|---|
| Cache a value | **String** | `SET key val EX 300` |
| Counter | String | `INCR`, `INCRBY` |
| Distributed lock | String | `SET k token NX PX 30000` |
| Object with fields | **Hash** | `HSET`, `HGETALL`, `HINCRBY` |
| Recent items list | **List** | `LPUSH` + `LTRIM` |
| Simple job queue | List | `LPUSH` / `BRPOP` (blocking) |
| Unique membership | **Set** | `SADD`, `SISMEMBER` |
| Common friends | Set | `SINTER` |
| **Leaderboard** | **Sorted set** | `ZADD`, `ZREVRANGE`, `ZRANK` |
| **Rate limiting (sliding window)** | **Sorted set** | `ZREMRANGEBYSCORE` + `ZCARD` + `ZADD` |
| **Delayed job queue** | **Sorted set** | score = execute-at timestamp; `ZRANGEBYSCORE` |
| **Time-ordered feed** | **Sorted set** | score = timestamp, `ZREVRANGE` |
| Daily active users | **Bitmap** | `SETBIT`, `BITCOUNT`, `BITOP` |
| Approximate unique count | **HyperLogLog** | `PFADD`, `PFCOUNT` |
| Event log with consumer groups | **Stream** | `XADD`, `XREADGROUP` |
| Proximity search | **Geo** | `GEOADD`, `GEOSEARCH` |

**Sorted sets solve four distinct interview problems** — leaderboards, rate limiting, delayed queues, and feeds. If you remember one structure, remember this one.

## Sorted Set Recipes

**Sliding-window rate limiter:**
```lua
redis.call('ZREMRANGEBYSCORE', KEYS[1], 0, now - window)   -- drop old entries
local count = redis.call('ZCARD', KEYS[1])
if count >= limit then return 0 end
redis.call('ZADD', KEYS[1], now, requestId)
redis.call('EXPIRE', KEYS[1], window_seconds)
return 1
```

**Delayed queue:**
```
ZADD jobs {executeAtEpoch} {jobId}
ZRANGEBYSCORE jobs 0 {now} LIMIT 0 10     -- due jobs
ZREM jobs {jobId}                          -- claim (use Lua for atomicity)
```

**Capped feed:**
```
ZADD feed:{user} {timestamp} {postId}
ZREMRANGEBYRANK feed:{user} 0 -1001        -- keep newest 1000
ZREVRANGE feed:{user} 0 49                 -- newest 50
```

## Bitmaps and HyperLogLog

**Bitmap** — one bit per user ID:
```
SETBIT dau:2026-08-06 {userId} 1
BITCOUNT dau:2026-08-06                    -- today's active users
BITOP AND weekly dau:d1 dau:d2 ... dau:d7  -- active every day this week
```
10M users = 10M bits = **1.25 MB per day**. Extremely cheap.

**HyperLogLog** — approximate cardinality in a fixed **12 KB**, ~0.81% error:
```
PFADD visitors:2026-08-06 {userId}
PFCOUNT visitors:2026-08-06
PFMERGE visitors:week visitors:d1 ... visitors:d7
```

**One billion unique visitors counted in 12 KB is a genuinely striking figure** and worth volunteering when a design needs unique counts at scale.

**Choosing between them:** bitmaps are exact and support per-user lookup but need dense integer IDs; HyperLogLog is approximate, tiny, and works with any identifier.

## Streams vs Lists vs Pub/Sub

| | List | Pub/Sub | **Stream** |
|---|---|---|---|
| Persistence | Yes | **No** | Yes |
| Multiple consumers | One takes each | All receive | **Consumer groups** |
| Replay | No | No | **Yes** |
| Offline consumers | Message waits | **Message lost** | Message waits |
| Acknowledgement | No | No | **Yes (`XACK`)** |

**Redis Pub/Sub is fire-and-forget** — a disconnected subscriber misses messages permanently. This is the single most common Redis surprise, and it's why chat systems need durable storage alongside it.

**Streams are Redis's Kafka-like structure** — use them when you need consumer groups, acknowledgement, and replay without running Kafka.

## Memory Optimisation

- Small hashes, lists, and sorted sets use **compact encodings** (ziplist/listpack) — keeping collections under the configured thresholds saves substantial memory
- **Prefer hashes over many top-level keys**: `HSET user:1 name x email y` uses far less memory than `SET user:1:name x` plus `SET user:1:email y`, because each top-level key carries overhead
- Set TTLs on everything that can expire
- `OBJECT ENCODING key` reveals which encoding is in use

## Operational Rules

- **Never `KEYS *`** — it blocks the single thread. Use `SCAN`.
- Keep Lua scripts short — they block everything
- Avoid values over ~100 KB
- Set `maxmemory` and an eviction policy deliberately; `noeviction` makes writes fail
- Use hash tags `{user123}:profile` to co-locate keys in the same cluster slot for multi-key operations

## Common Mistakes

- Using Pub/Sub for anything that must not be lost
- `KEYS` in production
- Long-running Lua scripts
- Many top-level keys where a hash would do
- Multi-key commands across cluster slots without hash tags
- Treating Redis as durable storage

## Related Topics

- [Redis](Redis.md)
- [Rate Limiting](Rate%20Limiting.md)
- [Design a News Feed](Design%20a%20News%20Feed.md)
- [Caching Strategies](Caching%20Strategies.md)

## Revision Summary

Sorted sets cover leaderboards, rate limiting, delayed queues, and feeds. Bitmaps and HyperLogLog give very cheap analytics. Streams provide durable consumer groups where Pub/Sub loses messages. Prefer hashes over many top-level keys, and never block the single thread.

## Quick Recall

- Sorted set = leaderboard, rate limiter, delayed queue, feed
- Bitmap = exact DAU, 1.25 MB per 10M users
- HyperLogLog = 1B uniques in 12 KB
- **Pub/Sub loses messages for offline clients** — use Streams
- Hashes beat many top-level keys
- Never `KEYS *`; hash tags for cluster multi-key ops
