# Distributed Rate Limiter - Complete Design Notes

## High-Level Design Decisions

### 1. **Placement Strategy**

**Options:**

- Inside each microservice → No global coordination ✗
- Separate rate limiter service → Extra network hop ✗
- **API Gateway/Load Balancer** ✓ → "Bouncer at the door"

**Why Gateway:** Catches bad requests before they hit backend, minimal latency, global view

---

### 2. **Client Identification**

**Options:** User ID, IP address, API key

**Best Practice:** Layered approach

- Authenticated users: higher limits
- Premium users: 10x limits (via JWT claims)
- Anonymous IPs: lower limits
- Per-API quotas

---

### 3. **Algorithm Selection**

|Algorithm|Storage|Pros|Cons|
|---|---|---|---|
|**Fixed Window**|2 ints|Simple|Boundary effect (2x burst at window edge)|
|**Sliding Window Log**|Heap/deque|Perfect accuracy|High memory|
|**Sliding Window Counter**|2 ints|Low memory|Approximation (assumes even distribution)|
|**Token Bucket** ✓|2 ints|Handles bursts + steady rate|Tuning complexity|

**Token Bucket Details:**

- Bucket size = burst capacity (e.g., 100 tokens)
- Refill rate = steady rate (e.g., 10 tokens/min)
- Each request consumes 1 token
- Reject when empty

---

## Deep Dive Solutions

### 1. **Scalability (1M req/s)**

**Problem:** Single Redis ~50K req/s (2 ops: `HMGET` + `HMSET`)

**Solution:** Redis Cluster with sharding

- 20+ shards (1M ÷ 50K)
- Shard by client ID using hash slots (16,384 slots)
- Automatic rebalancing

**Key Concept:** Consistent hashing distributes load evenly

---

### 2. **Race Condition (Critical)**

**Problem:**

```
Gateway A: read(tokens=1) → check → write(tokens=0)
Gateway B: read(tokens=1) → check → write(tokens=0)  
Result: 2 requests pass, but only 1 token available
```

**Solution:** Lua Scripting in Redis

- Atomic read-modify-write in single operation
- Redis is single-threaded → guarantees atomicity
- One Lua script does: fetch tokens → calculate → update → return result
- No race condition possible

**Code Concept:**

```lua
-- Lua script runs atomically
current = HMGET(user_bucket, "tokens", "last_refill")
tokens_to_add = calculate_refill(current.last_refill, refill_rate)
new_tokens = min(current.tokens + tokens_to_add, bucket_size)
if new_tokens > 0:
    HMSET(user_bucket, "tokens", new_tokens-1, "last_refill", now)
    return {allowed: true, remaining: new_tokens-1}
else:
    return {allowed: false, remaining: 0}
```

---

### 3. **Availability & Fault Tolerance**

**Problem:** Redis node failure = no rate limiting

**Decision:** Fail open vs fail close

- **Fail open:** Allow all → backend overload risk
- **Fail close:** Reject all → site down but protects backend ✓

**Solution:** Read replicas + async replication

- 1-2 replicas per shard
- Auto-failover promotes replica
- Async replication → eventual consistency (AP over CP)

**Advanced Fallback:** Gateway local memory with simple fixed-window counter

**Tradeoff:** Lose 1-2 checks during failover vs complete outage

---

### 4. **Low Latency (<10ms)**

**Problem:** Network calls add latency

**Solutions:**

**a) Connection Pooling** (biggest win)

- Reuse persistent TCP connections
- Eliminates 20-50ms TCP handshake per request
- Most Redis clients auto-handle this

**b) Geographic Distribution**

- Co-locate gateway + Redis (same data center)
- Regional deployments (Tokyo users → Tokyo gateway + Redis)

**c) In-Memory Storage**

- Redis keeps all buckets in RAM (sub-ms ops)

---

### 5. **Dynamic Rule Configuration**

**Problem:** Update limits without redeployment

**Anti-patterns:**

- Database polling: lag + CPU waste
- Redis lookup per check: added latency

**Solution:** ZooKeeper/etcd (push-based)

```
1. Gateway loads rules at startup → stores in memory
2. Opens persistent TCP connection to ZooKeeper
3. Subscribes to rule changes via watch
4. ZooKeeper pushes updates when rules change
5. Gateway updates in-memory rules instantly
```

**Benefits:**

- Zero latency (rules cached locally)
- Instant updates (push vs poll)
- Centralized config management

---

## Key Technical Components

### Redis Data Structure

```
User bucket: {
  "tokens": 85,
  "last_refill": 1638360420
}
```

### Rate Limit Check Flow

1. Request arrives at gateway
2. Gateway executes Lua script on Redis
3. Script: fetch → calculate refill → update → return
4. Gateway: pass (200) or reject (429)

### Response Headers (429)

```
HTTP/1.1 429 Too Many Requests
X-Rate-Limit-Limit: 100
X-Rate-Limit-Remaining: 0
X-Rate-Limit-Reset: 1638360480
Retry-After: 60
```

---

## Interview Cheat Sheet

### Scalability Pattern

Shard → Replicate → Distribute Geographically

### CAP Theorem Choice

**AP** (Availability + Partition Tolerance) over C

- Rate limiter must stay up
- Brief inconsistency acceptable (wrong count by 1-2)

### Critical Optimizations (in order)

1. **Connection pooling** (20-50ms savings)
2. **Lua scripting** (prevents race conditions)
3. **Sharding** (horizontal scale)
4. **Replicas** (99.9% availability)
5. **Push config** (operational agility)

### Common Pitfalls to Mention

- Boundary effect in fixed window
- Read-after-write race conditions
- Single point of failure
- Cold start (empty buckets)
- Clock skew in distributed systems

### Depth Topics (Senior+)

- Redis Cluster internals (hash slots vs consistent hashing)
- Lua script performance characteristics
- Async replication lag implications
- Connection pool sizing strategies
- Token bucket cold start handling

### Level Expectations

**Mid:** Understand algorithms, propose Redis, answer probing questions **Senior:** Proactively identify issues (sharding math, fault tolerance) **Staff:** Deep dive on Redis Cluster, Lua atomicity, connection pooling tuning, trade-off analysis

More: DeepDive at [[Rate Limiting]]
