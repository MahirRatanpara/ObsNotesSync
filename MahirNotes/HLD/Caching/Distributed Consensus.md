
This is a real tension in distributed systems — you've traded consistency for throughput, and now you need some of that consistency back.

Let me walk through the approaches, from simplest to most robust:

**Approach 1: Accept the hot key, use a single counter**

Sometimes the answer is — don't shard the counter at all. If your rate limit is, say, 1000 req/min for an API endpoint, a single Redis key with `INCR` + `EXPIRE` handles this fine. A single Redis instance can do 100K+ INCR ops/sec. Your "hot key" is only truly a problem if it's saturating a core — which for most rate limiting scenarios, it won't. So before fragmenting, ask whether you actually have a hot key problem or just a theoretical one.

**Approach 2: Shard the counter, aggregate on read**

You write to a random shard: `INCR rate_limit:user:123:{random(0-9)}`. When checking the limit, you read all 10 keys and sum them:

```
MGET rate_limit:user:123:0 rate_limit:user:123:1 ... rate_limit:user:123:9
```

The problem: if these keys land on different shards (which is the whole point), `MGET` can't be atomic across shards. You'd need the client to issue 10 `GET` commands to different shards and sum. This introduces a small race window — between reading shard 0 and shard 9, new increments could arrive. For rate limiting, this slight inaccuracy is often acceptable. You're off by maybe a few requests, not orders of magnitude.

But the bigger problem: you asked about **deduplication**. If the question is "has this exact request been processed before?", summing counters doesn't help.

**Approach 3: Lua script on a single shard (best for rate limiting)**

Force all operations for a given rate limit key onto _one_ shard by using a **hash tag**. In Redis Cluster, keys with `{...}` are hashed only on the content inside the braces:

```
rate_limit:{user:123}:counter
rate_limit:{user:123}:last_reset
```

Both keys land on the same shard because `{user:123}` is the hash slot input. Now you can run a Lua script atomically on that shard:

```lua
local current = redis.call('INCR', KEYS[1])
if current == 1 then
    redis.call('EXPIRE', KEYS[1], ARGV[1])
end
if current > tonumber(ARGV[2]) then
    return 0  -- rate limited
end
return 1  -- allowed
```

This gives you atomicity, accuracy, and no cross-shard coordination. The tradeoff: that one shard handles all rate-limit checks for `user:123`. But again — rate limit checks are cheap INCR operations; one shard can handle hundreds of thousands per second.

**Approach 4: For deduplication specifically — Bloom filter or SET on a pinned shard**

If your concern is "don't process this request twice even though 10 shards see traffic," use a hash-tagged `SET` or a Redis Bloom filter:

```
SADD {user:123}:processed_requests <request_id>
SISMEMBER {user:123}:processed_requests <request_id>
```

Same idea — hash tag pins it to one shard, so `SISMEMBER` is atomic and accurate. No cross-shard consensus needed.

**Approach 5: When you truly need distributed consensus**

This is where things get interesting and nuanced. Let me go deep on how distributed counters and consensus work in production rate-limiting systems.

## The Core Problem

You have a hot key like `rate_limit:api:expensive_service`. The limit is 10,000 req/min. Traffic is so heavy that pinning it to one shard saturates that shard. You _must_ spread the writes. But now you need an accurate-enough global count to enforce the limit.

**The fundamental tradeoff is captured by the CAP-adjacent reality of distributed counters: you can pick two of — exact accuracy, low latency, high throughput.**

## Production Pattern 1: Local Counters with Periodic Sync

This is the most common production approach. Each application node (or each Redis shard) maintains a local counter and periodically synchronizes with a central authority.

Here's how it works in practice. Say you have 5 application servers, each with a local Redis or even an in-memory counter. The global limit is 10,000 req/min.

**Step 1 — Quota pre-allocation.** On startup or at every sync interval, each node requests a _quota slice_ from a coordinator. The coordinator divides: 10,000 / 5 nodes = 2,000 per node. Each node now enforces locally against its own 2,000 budget — zero network calls for most requests.

**Step 2 — Local enforcement.** When a request hits Node 3, it does a local `INCR`. If under 2,000, allow. This is pure in-memory or single-shard, sub-millisecond.

**Step 3 — Periodic reconciliation.** Every N seconds (say 2–5s), each node reports its current count to the coordinator and gets an updated quota. If Node 1 is barely used (only consumed 200), the coordinator can redistribute its unused budget to Node 3 which is running hot.

The implementation looks roughly like this:

```java
public class DistributedRateLimiter {
    private final AtomicInteger localCount = new AtomicInteger(0);
    private volatile int localQuota;
    private final ScheduledExecutorService scheduler;
    private final RedisClient coordinatorClient;
    
    public DistributedRateLimiter(int globalLimit, int nodeCount) {
        this.localQuota = globalLimit / nodeCount;
        
        // Sync every 2 seconds
        scheduler = Executors.newScheduledThreadPool(1);
        scheduler.scheduleAtFixedRate(this::syncWithCoordinator, 
            2, 2, TimeUnit.SECONDS);
    }
    
    public boolean allowRequest(String key) {
        int current = localCount.incrementAndGet();
        return current <= localQuota;
    }
    
    private void syncWithCoordinator() {
        int consumed = localCount.getAndSet(0);
        // Report consumed, get new quota
        // Coordinator redistributes unused budget
        this.localQuota = coordinatorClient.reportAndGetQuota(consumed);
    }
}
```

**Production considerations:**

The sync interval is your accuracy knob. A 1-second interval means you could overshoot the global limit by at most `numNodes * (max_requests_per_node_per_second)`. For rate limiting, overshooting by 2–5% is usually fine — you're protecting a downstream service from overload, not enforcing a billing contract down to the exact request.

What happens if the coordinator goes down? Each node falls back to its last known quota and enforces conservatively. You can also set a hard local ceiling as a safety net — even if sync fails, no node can exceed, say, `globalLimit / nodeCount * 1.5`.

## Production Pattern 2: Sliding Window with Redis Streams

This is more accurate than local counters and works well when you need a true global view.

Each shard or app node appends events to a Redis Stream:

```
XADD rate_events:{service} * node node3 count 1 ts 1679000000
```

A dedicated consumer (or consumer group) tails the stream, maintains a sliding window count, and publishes the current total to a shared key:

```
SET rate_current:{service} 9847 EX 60
```

Nodes check this key before allowing requests. The lag between a request being counted and the global count being updated is the consumer's processing delay — typically 50–200ms.

The advantage is you get a true global count with full auditability (the stream is your log). The disadvantage is the consumer becomes a bottleneck and a single point of failure, though you can mitigate that with consumer groups.

## Production Pattern 3: Token Bucket with Central Reservoir

Think of it like a water tank with multiple taps. There's a central token bucket that refills at the desired rate (10,000 tokens/min). Each node periodically grabs a batch of tokens:

```lua
-- Central reservoir Lua script
local available = tonumber(redis.call('GET', KEYS[1]) or 0)
local requested = tonumber(ARGV[1])
local granted = math.min(available, requested)
redis.call('DECRBY', KEYS[1], granted)
return granted
```

A node might request 500 tokens every 2 seconds. If it gets them, it can serve 500 requests locally with no coordination. If the reservoir is empty, the node starts rejecting.

This is how Google's rate limiting works internally (described in their SRE book). The token grab is a single Redis call every few seconds, not per-request.

## Production Pattern 4: CRDTs (for truly distributed, no-coordinator setups)

If you can't tolerate a coordinator at all, you use a Conflict-free Replicated Data Type — specifically a G-Counter (grow-only counter). Each node maintains its own counter:

```
Node1: 3402
Node2: 2891  
Node3: 3100
```

The global count is the sum: 9393. Each node periodically gossips its count to others. CRDTs guarantee eventual convergence regardless of network partitions or message ordering.

Redis doesn't natively support CRDTs for counters, but you can implement it with a hash:

```
HINCRBY rate_gcounter:{service} node1 1
```

And to read the global count:

```
HVALS rate_gcounter:{service}  -- then sum client-side
```

The tradeoff: convergence lag means you might overshoot. CRDTs guarantee you'll _eventually_ see the right count, not that you'll see it _right now_.

## What to Actually Use in Production

For most production rate limiting scenarios, Pattern 1 (local counters with periodic sync) is the right answer. Here's the decision framework:

If the consequence of overshooting by 5% is a slightly higher load on downstream, go with local counters and periodic sync. This covers 90% of cases including API rate limiting, throttling expensive DB queries, and protecting microservices.

If you need auditability and a global event log, use the Redis Streams approach. Good for compliance-heavy environments where you might need to answer "exactly how many requests did user X make between 2:00 and 2:05?"

If you're doing multi-region rate limiting (say, enforcing a global limit across US-East, EU-West, AP-South), CRDTs or the token bucket reservoir pattern work well because they tolerate network partitions gracefully.

If the limit is a hard legal or billing boundary (e.g., "this API key gets exactly 10,000 calls/month, no exceptions"), you need the single-shard Lua script approach from my previous answer. Eat the hot key cost — correctness matters more than throughput here.

Want me to dig into any of these patterns further, or talk about how this might apply to the regulatory data pipeline throttling you work on in CREST?