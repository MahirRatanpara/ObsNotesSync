
# 📌 Caching – HLD Interview Notes

## 🧠 Definition
> Caching is a technique used to store frequently accessed data in fast-access memory to reduce latency and improve performance.

---

## ⚙️ Types of Caching

### 1. **Client-side Cache**
- Example: Browser caching (images, HTML, JS files)
- Reduces server load and latency
- Data persists locally on user's device

### 2. **CDN (Content Delivery Network)**
- Stores static content closer to users geographically
- Caches assets like images, stylesheets, videos, etc.
- Great for **read-heavy** traffic and **static files**

### 3. **Load Balancer Caching**
- Can cache requests/responses at the edge/load balancer level
- Ideal for reducing repeated requests to backend

### 4. **Server-side (Application) Cache**
- Stored within application memory or separate caching layers (e.g., Redis, Memcached)
- Commonly used for:
  - Database query results
  - Session data
  - Expensive computations

---

## 🔁 Basic Cache Flow

```
Client --> Load Balancer --> Server --> Cache (Redis) --> Database
```

### Read Flow:
1. Try to read from **cache**.
2. If cache miss, then query from **DB**.
3. Update cache with the DB response (Write-back or Write-through).

---

## 🏗️ Distributed Systems Design

### 🔹 Redis as a Distributed Cache
- Multiple Redis nodes (sharded/replicated)
- Data partitioning via consistent hashing
- Reduces latency & improves scalability

### 🔹 Key Considerations
- **Cache clustering** for high availability
- **Cache invalidation** strategy
- **Consistency model** (eventual vs strong)
- **Concurrency** and thread safety
- Preventing **cache stampede** and **thundering herd** problems

---

## ⚖️ Eviction Policies

| Policy | Description |
|--------|-------------|
| **LRU (Least Recently Used)** | Evicts the least recently accessed entry |
| **FIFO (First In First Out)** | Removes entries in order of their arrival |
| **LFU (Least Frequently Used)** | Evicts entries with least access frequency |
| Others | Random, MRU, TTL-based |

---

## ⏱️ TTL – Time To Live

- Every cache entry can have a TTL.
- After TTL expires, the entry is:
  - **Evicted** or
  - **Invalidated**
- Prevents stale data, useful for volatile datasets.

---

## ⚠️ Pitfalls and Challenges

- ❌ Stale reads (if TTL isn't managed)
- ❌ Cache miss and cold start
- ❌ Synchronization across distributed caches
- ❌ Increased complexity when cache and DB are out-of-sync
- ❌ Memory pressure & eviction storms

---

## ✅ Best Practices

- Use **cache-aside** pattern for dynamic data.
- Monitor cache hit/miss ratio.
- Handle **cache failures gracefully** (fallback to DB).
- Automate **cache warm-up** during deployment.
- Use **retry with backoff** to avoid cache stampede.

---

## 🔍 Interview Use-Cases

### Q: How would you scale your cache in a large-scale distributed system?
- Use sharded Redis or clustered Memcached.
- Apply consistent hashing to distribute keys.
- Ensure fault tolerance with replication.
- Monitor key eviction and latency metrics.

### Q: When would you not use a cache?
- Highly volatile data (changes every second).
- When data consistency is critical (e.g., payment records).
- If memory is a major constraint.

### Q: Difference between write-through and write-back cache?

| Write-Through | Write-Back |
|---------------|------------|
| Writes go to both cache and DB immediately | Writes go to cache first, DB update happens later |
| Data consistency with DB ensured | Faster, but DB can lag |


# 🧠 Caching Patterns

## 🧩 1. Cache-Aside Pattern (Lazy Loading)

### 🔁 Flow
```text
Client --> Server --> Cache --> DB

Sequence:
1. Client sends a read request to the server
2. Server checks the cache
    - If HIT → Return data from cache
    - If MISS → Fetch from DB
3. Server writes the result to the cache
4. Server returns the response to the client
```

### ✅ Advantages
- Excellent for **read-heavy** workloads
- Request **won’t fail** if cache is down (DB fallback)
- Cached data can differ from DB (good for flexibility)

### ❌ Disadvantages
- **New data** always results in cache miss (write logic needs to explicitly handle cache updates)
- Risk of **inconsistencies** between cache and DB
- Manual effort needed to maintain cache freshness

---

## 🧩 2. Read-Through Cache

### 🔁 Flow
```text
Client --> Server --> Cache (logic embedded) --> DB

Sequence:
1. Client sends a read request
2. Server delegates read to cache
    - If HIT → Return from cache
    - If MISS → Cache system fetches from DB and writes back to cache
3. Server returns response to client
```

### ✅ Advantages
- Great for **read-heavy** systems
- Cache management logic is **abstracted from application**
- Reduces application-level complexity

### ❌ Disadvantages
- **Misses still occur** for new data
- Can still have **inconsistencies** during writes
- Cache must store same structure as DB for compatibility

---

## 🔍 Interview Comparison Summary

| Aspect | Cache-Aside | Read-Through |
|--------|-------------|--------------|
| Cache on Write | Manual | Automatic |
| Read Miss Handling | App loads DB and populates cache | Cache loads DB automatically |
| Failure Handling | More resilient (falls back to DB) | Depends on cache system’s fallback |
| Flexibility | More control | More abstraction |
| Complexity | Slightly higher (handled in app logic) | Lower (handled by cache layer) |
| Write Complexity | High | Moderate |

---

## 🧪 When to Use What?

### Use **Cache-Aside** when:
- You need **fine-grained control** over cache logic
- You want to **separate concerns** (read logic vs write logic)
- You can afford occasional stale reads

### Use **Read-Through** when:
- You want a **plug-and-play** caching solution
- You want minimal app logic to handle caching
- Your data model is stable and consistent with cache format

🧠 Write Caching Strategies – HLD Interview Notes

## 🧩 3. Write-Around Cache

### 🔁 Flow
```text
Client --> Server --> DB (write)
                      ↓
               Invalidate Cache
```

### ✅ Advantages
- Excellent for **read-heavy** systems
- **Resolves inconsistencies** between cache and DB

### ❌ Disadvantages
- **Cache miss** for newly written data (requires warm-up or pre-heating)
- **DB is a single point of failure** – if down, write operation fails

---

## 🧩 4. Write-Through Cache

### 🔁 Flow
```text
Client --> Server --> Cache --> DB
```

### ✅ Advantages
- Data is **always consistent** between cache and DB
- Ensures **cache hit** for future reads
- Works well when used with read patterns like **read-through** or **cache-aside**

### ❌ Disadvantages
- Slightly **increased write latency** due to dual write
- Requires **2-phase commit** for guaranteed consistency
- If DB is down, **write operation fails**

---

## 🧩 5. Write-Back (Write-Behind) Cache

### 🔁 Flow
```text
Client --> Server --> Cache --> Queue --> DB (Async)
```

### 📝 Sequence
1. Client writes to the server
2. Server writes to **cache**
3. Cache pushes write message to a **queue**
4. Asynchronously, a consumer/service writes data to DB from queue

### ✅ Advantages
- **Low latency** writes
- Highly **resilient to DB load spikes**
- **Write batching** possible, improves DB efficiency

### ❌ Disadvantages
- **Data loss** possible if cache or queue fails before DB write
- Complex **failure recovery** and **message deduplication**
- Need for **durable queue** and **retries**

---

## 🔍 Comparison Table

| Strategy         | Latency | Consistency | Use Case                      | Failure Impact              |
|------------------|---------|-------------|-------------------------------|-----------------------------|
| Write-Around     | Low     | Eventual    | Read-heavy loads              | Writes fail if DB is down   |
| Write-Through    | High    | Strong      | Read-consistent apps          | Writes fail if DB is down   |
| Write-Behind     | Low     | Eventual    | High write throughput systems | Data loss if cache/queue fails |

---

## 🧪 When to Use What?

### Use **Write-Around** when:
- Reads dominate your workload
- You can tolerate cache misses for fresh data

### Use **Write-Through** when:
- You need strong consistency
- Reads immediately follow writes

### Use **Write-Behind** when:
- You want to minimize write latency
- You have infrastructure for reliable queues and retries
- You can tolerate eventual consistency


# [[Caching Interview Perspective]]
