
Great — here's a **detailed system design** for a **globally distributed rate limiter** that enforces both **per-user** and **global rate limits** across multiple regions.

---

## 🌍 **System Overview**

We need a **rate limiting system** that:

- Works **across multiple geographic regions**

- Enforces **user-level** and **global-level** API rate limits

- Maintains **low latency**, **high availability**, and **global consistency**

- Scales to **millions of requests/sec**


---

## 🧱 High-Level Architecture

### Components:

1. **API Gateway (per region)**

2. **Local Rate Limiter (per region)**

3. **Global Rate Limiting Service**

4. **Distributed Coordination Layer (e.g., Redis + CRDTs or DynamoDB Global Tables)**

5. **Configuration & Admin Panel**

6. **Monitoring/Logging**


![[Pasted image 20250722001628.png]]

---

## ⚙️ Core Design Decisions

### ✅ **Local vs Global Rate Limiting**

- **Local rate limiter** (in-region) handles most traffic with fast counters.

- **Global limiter** handles distributed coordination using approximate counting or sync via CRDTs/counters.

- Use **token bucket** or **leaky bucket** algorithms locally.

- Use **global approximate counters** to enforce global thresholds.


### ✅ **Data Store Choices**

- **Redis (with CRDT support)** or **DynamoDB Global Tables** to store rate counters.

- **CRDTs** ensure **eventual consistency** without locking or strict coordination.

- **Redis Enterprise** or **Upstash Global Redis** supports global replication with bounded staleness.


### ✅ **Sharding Strategy**

- Rate limit keys are sharded by user ID / API key / endpoint.

- Use consistent hashing to distribute counters across nodes.


### ✅ **Key Format**

- `user:{userId}:api:{endpoint}:window:{timestamp}`

- `global:api:{endpoint}:window:{timestamp}`


### ✅ **Time Window**

- Use **sliding window** or **fixed window with randomization** to smooth spikes.

- Use **TTL** to auto-expire old counters.


---

## 🌐 **Cross-Region Coordination**

### 📦 Option 1: CRDT-based Replicated Redis

- Each region has a Redis node.

- CRDTs automatically merge counters across regions.

- Low write overhead and eventual consistency.


### 📦 Option 2: Global DynamoDB Tables

- Global counters stored in DynamoDB Global Tables.

- Use conditional writes to prevent overshoot.

- Higher latency than CRDTs but **stronger consistency**.


### 📉 Trade-off:

- **CRDTs** = low latency, eventual consistency

- **DynamoDB Global Tables** = stronger guarantees, higher cost and latency


---

## ⚠️ Consistency & Conflict Resolution

- Prefer **eventual consistency** with **local rate limiting buffers**.

- Use **local burst buffers** (e.g., allow 10% overage locally).

- Sync with global counter every N requests or every X seconds.


---

## 🔁 Fallback and Resilience

- If **global limiter is unreachable**, local limits can degrade gracefully.

- Use **circuit breakers** or **cached limits** to prevent total outage.

- In case of **partial regional failure**, CDN/DNS reroutes traffic.


---

## 🛠️ Technologies

|Component|Tech Suggestions|
|---|---|
|In-memory counters|Redis, Envoy filters|
|Global counter store|Redis CRDTs, DynamoDB Global Tables|
|Coordination|Kafka (optional), Raft, gRPC|
|Rate limiting logic|Token Bucket, Sliding Window|
|Configuration Service|etcd, Consul|
|Monitoring|Prometheus, Grafana, Datadog|
|API Gateway|NGINX, Kong, AWS API Gateway|

---

## 📊 Monitoring & Metrics

- Expose metrics per region:

- Requests per second

- Blocked requests

- Rate limit overflows

- Use **Grafana dashboards**

- Alert on:

- Global limit saturation

- Regional failures

- High latency between regions


---

## 🧠 Optimization Ideas

- **Probabilistic global updates**: sync 1 in N requests to reduce overhead

- **Bloom filters** to check if user exceeded global limit before fetch

- **Edge caching** of limits for short TTL


---

## 🔐 Security

- Authenticated requests only (JWT/API keys)

- Tamper-proof headers between gateways and limiters

- Use mTLS for inter-service communication


---

## 📌 Example Flow: Per-user Global Limit

1. Request hits Region A Gateway

2. Local limiter checks local Redis counter

3. If near threshold → check global counter

4. If allowed → increment counters locally + globally

5. If blocked → return `429 Too Many Requests`


## ✅ **Rate Limit Decision Logic**

### Step-by-step:

1. **Local Check (Fast Path):**

- On every request, the **local rate limiter** (e.g., in-memory Redis) checks:

- `localCounter < localThreshold`

- If true → **allow request immediately** and **increment local counter**.

- Else → fallback to **global check**.

1. **Global Check (Fallback Path):**

- Only invoked when:

- Local counter is close to threshold (`> 80–90%`)

- Or per periodic sync (e.g., every N requests)

- Global counter is read from **CRDT Redis** or **DynamoDB Global Table**.

- Check:

- `globalCounter < globalThreshold`

- If true → allow request, and:

- Increment global counter

- Optionally sync/update local buffer

- If false → **reject with 429**.

1. **Soft Sync Strategy (to reduce latency):**

- Local limiters occasionally sync global state every `T seconds` or `M requests` to keep local estimate fresh.

- Use `atomic increment` on global counter when crossing boundaries.


---

## 🔄 Buffering Strategy

To prevent every request from needing a global call:

- **Local burst quota** is pre-allocated (like a token bucket):

- E.g., if global allows 1000 RPM/user across 5 regions → allocate 200 RPM/user locally per region.

- Each region enforces local limit quickly, without syncing every time.

- When region's burst is exhausted, it requests fresh quota or checks global state.


---

## 🧠 Example Logic in Pseudocode

```scala
if (localCounter < localLimit) {
allowRequest()
incrementLocal()
} else {
globalCounter = readGlobal()
if (globalCounter < globalLimit) {
allowRequest()
incrementGlobal()
optionallyUpdateLocal()
} else {
rejectRequest(429)
}
}
```

---

## 📉 Trade-offs

|Approach|Pros|Cons|
|---|---|---|
|Local-only|Ultra-fast, low latency|Risk of global overuse|
|Global-only|Strong consistency|High latency, expensive|
|Hybrid (above)|Best balance|Complexity, eventual consistency|

# 🌍 Global Rate Limiting using Local + Global Logic

## 🎯 Goal
Enforce a **global rate limit** across multiple regions.  
Example: Allow **1000 requests per minute per user**, regardless of which region the user is in.

---

## 🧩 The Problem Without Coordination

If each region enforces 1000 RPM independently:

- User sends 1000 RPM to Region A  
- 1000 RPM to Region B  
- ...  
- ➡️ Total: 5000+ RPM → **Global limit violated**

---

## ✅ The Solution: Local + Global Coordination

### 1. Divide the Global Limit
- Split global limit across regions.
- Example: Global limit = 1000 RPM; 5 regions ⇒ 200 RPM each.

### 2. Enforce Locally First
- Each region enforces its **allocated buffer** locally for fast checks.
- Avoids cross-region calls for every request.

### 3. Coordinate with Global Limiter
- When local quota is nearly exhausted:
  - Region contacts **Global Rate Limiter**
  - Requests more quota
  - Global limiter checks if global limit is not breached
  - Approves or rejects based on current global usage

### 4. Probabilistic Syncing
- Regions **do not sync on every request**
- Instead, sync every `N` requests or if usage hits threshold (e.g. 80%)

---

## 📌 Example

- **Global Limit:** 1000 RPM per user
- **Current Usage:**
  - Region A: 400 RPM
  - Region B: 300 RPM
  - Region C: 250 RPM
  - ➡️ Total: 950 RPM → ✅ OK

- Region A requests +50 quota:
  - Global sees 950 used
  - Approves +50 → now 1000 used
  - Further requests are **denied**

---

## 🧠 Summary

| Without Local+Global | With Local+Global |
|----------------------|------------------|
| Global limit can be violated | Global limit enforced collaboratively |
| High latency from global checks | Low latency via local buffering |
| Central bottleneck or SPOF | Decentralized & resilient |


