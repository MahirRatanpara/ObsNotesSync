# Redis Lua Scripting - Complete Guide

## Overview

Redis Lua scripting allows server-side execution of atomic operations, providing a powerful solution for complex Redis operations that need consistency guarantees.

## Key Concepts

### Atomicity Scope

- Scripts execute atomically across **all keys involved in the transaction**
- Keys not accessed by the script can still be modified by other operations
- No partial execution - either entire script succeeds or fails

### Single-Threaded Execution

- Redis uses single event loop thread for all command processing
- **Entire Redis instance blocks** during Lua script execution
- Not just the keys involved - ALL Redis operations wait

## Read-After-Write Problem Solution

### Traditional Approach Problems

```java
// Multiple network round trips + race conditions
try {
    redis.lock("user:123", "user:456");  // Network call 1
    int balance = redis.get("user:123:balance");  // Network call 2
    if (balance >= 100) {
        redis.decrBy("user:123:balance", 100);  // Network call 3
        redis.incrBy("user:456:balance", 100);  // Network call 4
    }
} finally {
    redis.unlock("user:123", "user:456");  // Network call 5
}
```

### Lua Script Advantages

```lua
-- Single atomic operation, one network round trip
local balance = redis.call('GET', 'user:123:balance')
if tonumber(balance) >= 100 then
    redis.call('DECRBY', 'user:123:balance', 100)
    redis.call('INCRBY', 'user:456:balance', 100)
    return "success"
end
return "insufficient funds"
```

## Concurrency Issues Comparison

|Issue|Traditional Java Locking|Redis Lua Scripts|
|---|---|---|
|**Deadlocks**|Possible between clients|Impossible between clients|
|**Race Conditions**|Possible|Impossible within script|
|**Starvation**|Possible on locked resources|Possible on entire Redis instance|
|**Blocking Scope**|Only locked keys|Entire Redis server|
|**Time Bounds**|Manual timeout handling|Built-in execution limits|

## Performance Implications

### Serial Processing Impact

- **Problem**: All requests processed one at a time
- **Bottleneck**: If each script takes 2ms, max throughput = 500 req/sec
- **Solution**: Use Lua selectively, not for every operation

### When to Use Lua vs Regular Commands

#### ✅ Use Lua Scripts For:

- Operations requiring atomicity (financial transactions)
- Complex read-modify-write operations
- Rate limiting algorithms
- Operations where race conditions are critical
- Infrequent but critical operations

#### ❌ Avoid Lua Scripts For:

- Simple read operations (`GET`, `HGET`)
- High-frequency operations (page views, metrics)
- Operations that can be done with single Redis commands
- Long-running computations

## Rate Limiting Implementation

### Why Lua is Perfect for Rate Limiting

- ✅ Atomic check-and-increment operations
- ✅ Fast execution (typically <1ms)
- ✅ Single network round trip
- ✅ Race condition prevention

### Token Bucket Algorithm Example

```lua
local key = KEYS[1]
local capacity = tonumber(ARGV[1])
local refill_rate = tonumber(ARGV[2])
local requested = tonumber(ARGV[3])
local now = tonumber(ARGV[4])

-- Get current state
local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
local tokens = tonumber(bucket[1]) or capacity
local last_refill = tonumber(bucket[2]) or now

-- Calculate refill
local elapsed = now - last_refill
local tokens_to_add = math.floor(elapsed * refill_rate)
tokens = math.min(capacity, tokens + tokens_to_add)

-- Check and consume
if tokens >= requested then
    tokens = tokens - requested
    redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
    redis.call('EXPIRE', key, 3600)
    return {1, tokens}  -- Success
else
    redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
    redis.call('EXPIRE', key, 3600)
    return {0, tokens}  -- Rate limited
end
```

## Redis Architecture Deep Dive

### Why Entire Redis Instance Blocks

#### Single-Threaded Design Philosophy

```
Redis Process:
┌─────────────────────────────────────┐
│  ┌─────────────────────────────┐   │
│  │     Main Event Loop         │   │
│  │    (Single Thread)          │   │
│  │  ┌─────┐ ┌─────┐ ┌─────┐   │   │
│  │  │ GET │ │ SET │ │ LUA │   │   │
│  │  └─────┘ └─────┘ └─────┘   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

#### Benefits of Single-Threading

- **Simplicity**: No complex locking mechanisms needed
- **Performance**: No context switching or cache line bouncing
- **Safety**: Data structures don't need thread-safety
- **Predictability**: Consistent performance characteristics

#### Why Not Concurrent Lua?

- Would require thread-safe data structures (performance cost)
- Complex deadlock prevention needed
- Lock ordering complexity
- Would break Redis's simple architecture

## Best Practices

### Script Design

```lua
-- ✅ Good: Fast, bounded operations
local value = redis.call('GET', KEYS[1])
redis.call('SET', KEYS[2], value)

-- ❌ Bad: Long-running loops
for i = 1, 1000000 do
    redis.call('SET', 'key:' .. i, 'value')
end
```

### Performance Optimizations

1. **Pre-compile with EVALSHA**
    
    ```java
    String scriptSha = redis.scriptLoad(luaScript);
    redis.evalsha(scriptSha, keys, args);  // Faster execution
    ```
    
2. **Keep execution under 1ms**
    
    ```bash
    lua-time-limit 5000  # 5 second default limit
    ```
    
3. **Use appropriate data structures**
    
    - Sorted sets for sliding windows
    - Simple counters for fixed windows
    - Hash tables for token buckets

### Mitigation Strategies

1. **Hybrid Approach**: Use Lua only for operations requiring atomicity
2. **Redis Clustering**: Distribute load across nodes
3. **Pipeline**: Use for bulk non-atomic operations
4. **Async Processing**: For non-critical operations

## Redis 6.0+ Improvements

```
Modern Redis Architecture:
┌─────────────────────────────────────┐
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │I/O      │ │I/O      │ │I/O      ││ ← Multiple threads
│  │Thread 1 │ │Thread 2 │ │Thread 3 ││
│  └─────────┘ └─────────┘ └─────────┘│
│       └─────────┐ │ ┌─────────┘     │
│                 ▼ ▼ ▼               │
│    ┌─────────────────────────────┐  │
│    │     Command Processing      │  │ ← Still single-threaded
│    │      (Including Lua)        │  │
│    └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

- **Threaded I/O**: Improves network processing
- **Command Processing**: Still single-threaded for consistency
- **Lua Scripts**: Still execute atomically and block entire instance

## Key Takeaways

1. **Lua scripts trade complexity for performance** - eliminating distributed locking challenges
2. **Use strategically** - not for every operation, focus on atomic requirements
3. **Keep scripts fast** - single-threaded nature means long scripts block everything
4. **Perfect for rate limiting** - atomic check-and-increment with minimal performance impact
5. **Architecture drives behavior** - Redis's single-threaded design necessitates blocking

## Related Concepts

- [[Redis Architecture]]
- [[Distributed Locking]]
- [[Rate Limiting Algorithms]]
- [[Atomic Operations]]
- [[Other's Notes/HLD/Concurrency Control]]