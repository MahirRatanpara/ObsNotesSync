# AMAZON SDE-2 HLD INTERVIEW - 25 MINUTE QUICK REVISION GUIDE

## SECTION 1: CORE DATABASE CONCEPTS (3 minutes)

### Database Scaling Journey (0-1B)
- **Single DB**: ~10K-50K writes/sec, ~100K reads/sec
- **Optimization**: Indexing, denormalization, query optimization
- **Read Scaling**: Add 3-5 read replicas, route writes to primary only
- **Write Scaling**: Sharding (hash-based, range-based, geographic, directory-based)
- **Ultimate Scale**: Multi-region with different strategies per region

### CAP Theorem
- **Can only choose 2 of 3**: Consistency, Availability, Partition Tolerance
- **CP**: HBase, Zookeeper, Etcd (banking, critical systems)
- **AP**: Cassandra, DynamoDB, Couchbase (Amazon shopping cart, feeds)
- **CA**: Only single-node systems (impractical for cloud)
- **Key insight**: Distributed systems MUST choose AP or CP, never CA

### Replication Strategies
**Master-Slave (Primary-Replica)**:
- Writes go to primary, replicated asynchronously/synchronously to replicas
- Reads distributed across replicas
- Single point of failure (primary), limited write scalability
- Strong consistency for writes

**Master-Master (Multi-Primary)**:
- Multiple primaries accept writes, replicate to each other
- No single point of failure, better write availability
- Eventual consistency, conflict resolution needed
- Examples: CockroachDB, Cassandra, MySQL Group Replication

**Replication Types**:
- **Async**: Primary commits, replicates in background. Fast but risk of data loss
- **Sync**: Primary waits for replicas. Strong consistency but higher latency
- **Semi-Sync**: Primary waits for one replica acknowledgment (compromise)

### Database Failover
- **Cold Standby**: Manual activation, slow recovery (hours)
- **Warm Standby**: Periodic sync, moderate recovery (minutes)
- **Hot Standby**: Real-time sync (streaming/sync replication), automatic failover (seconds)

### Partitioning & Sharding
**Partitioning** (within single DB):
- Horizontal: Split rows by range/hash
- Vertical: Split columns into separate tables
- No application logic needed, DBMS handles

**Sharding** (across multiple DBs):
- **Hash-based**: Even distribution, difficult resharding, range queries hard
- **Range-based**: Easy resharding, easy range queries, hotspots possible
- **Geographic**: Low latency, compliance, uneven load
- **Directory-based**: Most flexible, adds lookup overhead
- **Consistent Hashing**: Virtual nodes for minimal rebalancing (~1/N data moves)

**Partition Key Selection** (CRITICAL):
- Ensures even distribution (no hotspots)
- Keeps related data together (minimize cross-shard queries)
- Bad keys: status, date (current) → hotspots; random ID for social graph → breaks queries

### Write-Ahead Logging (WAL)
- Write changes to log FIRST, then apply to data
- Ensures durability before commit
- Foundation for replication and recovery
- Crash recovery: replay WAL to restore consistent state

### Consistent Hashing
- Hash ring (0 to 2^32-1) divided into hash slots
- Each key maps to first node clockwise
- **Rebalancing**: Only affects keys in affected range (~1/N data)
- **Virtual Nodes**: Improves distribution, handles failure gracefully
- **Replication Strategy**: Store on N consecutive nodes clockwise

---

## SECTION 2: INDEXING & QUERY OPTIMIZATION (2 minutes)

### Database Indexing Fundamentals
- **B+ Tree Index**: Balanced tree, O(log n) search, leaf nodes linked for range queries
- **Search**: Navigate internal nodes → reach leaf node → data pointer
- **Page Splitting**: Overflow → split → promote middle key to parent

### Clustered vs Non-Clustered Indexes
- **Clustered**: Physical order of data, one per table, leaf level IS data
- **Non-Clustered**: Separate structure, many per table, leaf level has row pointers
- **Lookup Process**: Non-clustered → row locator (clustered key if exists) → actual data

### Types of Indexes
- **Primary Key**: Clustered by default
- **Composite Index**: Multiple columns in specific order matters
- **Covering Index**: Index contains all needed columns (no table access needed)
- **Full-text Index**: For text search
- **Bitmap Index**: Low-cardinality columns

### Query Optimization
1. **Identify slow queries** → Use EXPLAIN ANALYZE
2. **Add indexes** → On WHERE clause columns, JOIN keys, ORDER BY
3. **Avoid N+1 queries** → Use JOINs or batch IN clauses
4. **Select only needed columns** → Not SELECT *
5. **Use LIMIT for pagination** → Don't fetch all results
6. **Denormalize where needed** → Pre-compute aggregations

---

## SECTION 3: CACHING STRATEGIES (3 minutes)

### Caching Patterns (Choose based on use case)

**1. Cache-Aside (Lazy Loading)**
- App checks cache → miss → fetch DB → update cache
- Best for: Read-heavy, application controls what to cache
- Handles cache failure gracefully (fallback to DB)
- Challenge: Cache miss on new data

**2. Read-Through Cache**
- App delegates to cache layer → cache fetches DB if needed
- Best for: Plug-and-play caching, simpler app logic
- Challenge: Cache must understand DB structure

**3. Write-Around Cache**
- Writes bypass cache, go to DB → invalidate cache
- Best for: Read-heavy, infrequent writes
- Challenge: Cache miss for recently written data

**4. Write-Through Cache**
- Writes go to cache → DB simultaneously
- Best for: Strong consistency needed
- Trade-off: Higher write latency, DB must be up

**5. Write-Behind (Write-Back)**
- Writes to cache → queue → async DB write
- Best for: High write throughput, eventual consistency OK
- Challenge: Data loss risk if cache crashes

### Cache Invalidation
- **TTL-based**: Expires automatically (simple, may be stale)
- **Event-based**: Invalidate on update (always fresh, complex tracking)
- **Write-through**: Update on write (consistent, higher latency)
- **Hybrid**: TTL + event-based (best of both)

### Redis Architecture
- **Single-threaded command execution** → Atomicity, no locks needed
- **Connection multiplexing** → Handles thousands of concurrent connections
- **Hot key problem**: Cannot distribute single key across nodes
- **Solutions**: Client-side caching, local in-memory cache, manual distribution (key_1, key_2, key_3)

**Redis Cluster**:
- 16,384 hash slots, each mapped to nodes
- CRC16(key) % 16384 determines slot
- Consistent hashing for minimal rebalancing
- Virtual nodes for load distribution

### Caching Challenges
- **Cache Stampede**: Hot key expires → many misses → all query DB
  - Solution: Stale-while-revalidate or probabilistic early expiration
- **Hot Keys**: Single key gets millions of requests
  - Solution: Local in-memory cache, client-side caching, replica keys
- **Cache vs DB Consistency**: Race conditions from asynchronous updates
  - Solution: Delete from cache (not update), accept eventual consistency

---

## SECTION 4: CONCURRENCY CONTROL (1 minute)

### Optimistic vs Pessimistic
- **Optimistic**: Assume no conflicts, validate at commit (retries possible, no deadlocks)
- **Pessimistic**: Lock early (prevents conflicts, risk of deadlocks)

### Two-Phase Locking (2PL)
- **Growing Phase**: Acquire locks
- **Shrinking Phase**: Release locks
- **Types**:
  - **Basic 2PL**: Dynamically release (allows cascading aborts, deadlocks)
  - **Strict 2PL**: Hold exclusive locks until commit (prevents cascading, deadlocks still possible)
  - **Conservative 2PL**: Acquire all locks before execution (prevents deadlocks, reduces concurrency)
  - **Rigorous 2PL**: Hold all locks until commit (strongest, lowest concurrency)

### Best Use
- **Financial/Banking**: Strict + Conservative 2PL (safest)
- **E-commerce**: Strict 2PL (good balance)
- **Analytics**: Optimistic or basic 2PL (low conflict)

---

## SECTION 5: MICROSERVICE ARCHITECTURE (4 minutes)

### API Gateway
- **Single entry point** for all external requests
- **Benefits**:
  - API Composition: Aggregate data from multiple services
  - Centralized Auth: OAuth, JWT validation
  - Rate Limiting & Throttling
  - Request/Response transformation
  - Monitoring & Logging
  - Service Discovery integration
  - Version management

### Load Balancer vs API Gateway
- **Load Balancer**: Distributes traffic across instances of SAME service (L4/L7)
- **API Gateway**: Routes to DIFFERENT services based on path/headers (L7, business logic)

### Service Discovery
- **Registry**: Central database of available services and their addresses
- **Client-Side Discovery**: Client queries registry, calls service directly
- **Server-Side Discovery**: Client calls gateway, gateway queries registry
- **Technologies**: Eureka (Netflix), Consul, Kubernetes service discovery

### Circuit Breaker (CRITICAL)
- **States**: Closed (allowing), Open (blocking), Half-Open (testing)
- **Purpose**: Prevent cascading failures, fail fast
- **Implementation**: Monitor failure rate, open after threshold, test periodically
- **Trade-off**: Not removing failure, but CONTAINING it
- **Tools**: Resilience4j, Spring Cloud Circuit Breaker, Hystrix (deprecated), Istio

**Cascading Failure Prevention**:
1. Circuit breaker stops calls to failing service
2. Timeouts prevent thread blocking
3. Bulkheads isolate resources
4. Retries with exponential backoff
5. Fallback mechanisms

### Service Mesh
- **Purpose**: Abstract service-to-service communication complexity
- **Components**: Sidecar proxies (Envoy), control plane (Istio management)
- **Benefits**: Traffic management, security (mTLS), observability, policy enforcement
- **Trade-off**: Operational complexity, adds latency, resource overhead

---

## SECTION 6: MESSAGE QUEUES (2 minutes)

### Kafka vs SQS vs RabbitMQ

| Feature | Kafka | SQS | RabbitMQ |
|---------|-------|-----|----------|
| **Type** | Event streaming | Task queue | Message broker |
| **Retention** | Configurable (days/weeks) | After consumption | Until acknowledged |
| **Multiple Consumers** | Yes, at own pace | No (each msg once) | Yes, with routing |
| **Replay** | Yes, from offset | No | No |
| **Scale** | 100K+ msg/sec | High (managed) | Lower (self-hosted) |
| **Use Case** | Event sourcing, analytics, real-time | Async tasks, job processing | Complex routing, pub/sub |

**When to Choose**:
- **Kafka**: High-volume streams, multiple consumers, audit trail, event sourcing, real-time analytics
- **SQS**: Microservice decoupling, task distribution, serverless, work queues
- **RabbitMQ**: Complex routing, priority messages, enterprise integration, sophisticated patterns

### Retries in MQ
- **Exponential backoff with jitter**: Avoid thundering herd
- **Dead Letter Queue (DLQ)**: Failed messages after max retries
- **Idempotent processing**: Handle duplicate deliveries gracefully

---

## SECTION 7: DESIGN PATTERNS (3 minutes)

### Scaling Reads
1. **Database Optimization**: Indexing, denormalization, query optimization
2. **Read Replicas**: 3-5 replicas, handle replication lag (read-your-own-writes problem)
3. **Caching**: Redis (1-hour TTL for hot data), CDN (images, static)
4. **CQRS**: Separate read model from write model

**Replication Lag Solutions**:
- Read from primary for recent writes (sticky routing)
- Check replication position before reading
- Accept eventual consistency

### Scaling Writes
1. **Database Optimization**: Batch writes, async replication
2. **Horizontal Sharding**:
   - Hash-based (partition by user_id)
   - Range-based (partition by time/date)
   - Geographic (partition by region)
3. **Write Queues**: Kafka/SQS to buffer spikes, workers batch write to DB
4. **Batching**: 1,000 items per batch = 1000x throughput improvement
5. **Load Shedding**: Reject low-priority requests under overload
6. **Vertical Partitioning**: Different DB for different data types

**Key Decision: Partition Key**
- Even distribution (hash for cardinality)
- Related data together (minimize cross-shard queries)
- Avoid hotspots (status, current date)

### Real-Time Updates
- **Short Polling** (5-10s interval): Simple, wasteful
- **Long Polling** (30-60s hold): Better than short, still wasteful
- **Server-Sent Events (SSE)**: One-way, push from server, automatic reconnect
- **WebSockets**: Bidirectional, low latency, stateful, harder to scale

**Server Architecture**:
- **Pub/Sub**: Events → Message broker → WebSocket servers → Clients
- **Stateful Servers**: Consistent hashing, direct routing, heavy processing per connection

### Handling Large Blobs (Dropbox, Video Uploads)
- **Never route through app server**: 1GB × 10 concurrent = 10GB/s needed
- **Presigned URLs**: Temporary, time-limited, scoped permissions
- **Direct client-to-S3 upload**: Server only handles metadata
- **Multipart Upload**: For files >100MB, resume capability
- **CDN for downloads**: Cache at edge, 90% hit rate, 10x faster
- **Post-processing**: S3 events → Lambda for transcoding, thumbnails, scanning

### Proximity-Based Services
- **Problem**: Find nearest X (drivers, stores, restaurants)
- **Solutions**:
  - PostgreSQL + PostGIS (moderate scale)
  - Redis Geospatial (fast, in-memory)
  - Elasticsearch (geo + text search)
- **Sharding**: Regional or grid-based (handle border queries)
- **Optimization**: Bounding box queries faster than radius, then exact distance

### Managing Long-Running Tasks
- **Message Queue**: Accept async, acknowledge immediately
- **Polling**: Client polls for completion status
- **Webhooks**: Server calls back when done
- **WebSockets**: Real-time updates

---

## SECTION 8: IDEMPOTENCY & RELIABILITY (1 minute)

### Idempotency Keys
- **Purpose**: Safely retry failed requests without duplication
- **Generation**:
  - Client-generated UUIDs (most common)
  - Content-based hashing (deterministic)
  - Compound keys with business logic
- **Storage**: In-memory during operation, expires after retry window
- **Validation**: Check before processing, return same result if already processed

**When Critical**:
- Payment processing (cannot double-charge)
- Order creation (cannot create duplicate)
- Any financial transaction

### Idempotent API Design
- **POST**: Create (needs idempotency key)
- **PUT**: Update (idempotent by default)
- **DELETE**: Delete (idempotent by default)
- **GET**: Retrieve (idempotent by default)

---

## SECTION 9: SYSTEM DESIGN EXAMPLES (2 minutes)

### Rate Limiter
**Algorithms**:
- **Fixed Window**: Simple, boundary burst (2x at edge)
- **Sliding Window Log**: Perfect accuracy, high memory
- **Sliding Window Counter**: Low memory, approximation
- **Token Bucket**: Handles bursts + steady rate ✓

**Implementation**:
- **Placement**: API Gateway (global view, catch early)
- **Storage**: Redis Cluster (20+ shards for 1M req/sec)
- **Atomicity**: Lua scripting (prevents race conditions)
- **Failover**: Read replicas, async replication
- **Config**: Push-based via ZooKeeper/etcd (not polling)

**Response Headers**: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, Retry-After

### URL Shortener
- **Write**: Generate short code (counter or hash), store mapping
- **Read**: Redirect (301 or 302)
- **Scaling Writes**: Distributed counter with atomic increment
- **Scaling Reads**: Cache popular URLs, CDN for redirects
- **Analytics**: Counter for each link

### Chat/Real-time Messaging
- **Protocol**: WebSockets (bidirectional, low latency)
- **Server Architecture**: Pub/Sub for message broadcast
- **Consistency**: Sequence numbers to detect gaps
- **Offline Messages**: Store in queue until user comes online
- **Typing Indicators**: Low-priority, can drop

### Twitter Timeline
- **Feed Generation**: Fanout on write vs fanout on read
  - Fanout on write: Pre-compute, cache, fast read
  - Fanout on read: Fetch friends' posts, merge, expensive read
- **Hybrid**: Hot users use fanout-on-read, normal users fanout-on-write
- **Caching**: Timeline cached 5 minutes, invalidate on new posts
- **Denormalization**: Store username, like count in tweet

---

## SECTION 10: AWS-SPECIFIC & MISC (1 minute)

### DynamoDB
**When to Use**:
- Predictable access patterns (queries known upfront)
- Massive scale with consistent latency
- Real-time applications (gaming, chat)
- Serverless architectures

**When to Avoid**:
- Complex analytical queries with JOINs
- Ad-hoc queries on unpredictable columns
- Complex aggregations

**Consistency Models**:
- Eventually consistent reads (fast, may be stale)
- Strongly consistent reads (slower, always fresh)
- Transaction support for ACID operations

### Distributed Systems Concepts
- **Vector Clocks**: Track causality of events
- **Merkle Trees**: Efficient data integrity verification
- **Gossip Protocols**: Decentralized information dissemination
- **Quorum**: Majority rule for consensus
- **Two Generals Problem**: No perfect solution to distributed consensus

### High Availability
- **Multi-region active-active**: Max availability, consistency challenges
- **Multi-region active-passive**: Simpler, slower failover
- **Within region**: Replicate across AZs
- **Monitoring**: Health checks, circuit breakers, automatic failover

---

## SECTION 11: QUICK INTERVIEW DECISION FRAMEWORK (2 minutes)

### Functional Requirements
- What data to store? → Relational vs NoSQL
- Read/Write patterns? → Caching, replication, sharding
- Consistency requirements? → CAP choice
- Real-time needs? → WebSockets, message queue

### Non-Functional Requirements
- Scale (users, requests/sec, data size)?
- Latency targets? → Caching, geo-distribution
- Availability target (99.9%? 99.99%)?
- Consistency tolerance (strong vs eventual)?

### Design Flow
1. **Requirements gathering** (5 min)
2. **High-level architecture** (5-10 min)
3. **Deep dive** (15-20 min):
   - Pick 1-2 critical components
   - Address bottlenecks
   - Discuss scaling
4. **Trade-offs** (5 min)
   - Justify choices
   - Discuss alternatives
   - When to revisit decisions

---

## AMAZON SDE-2 SPECIFIC TIPS

**What Amazon Interviewers Want**:
1. **Scalability mindset**: "What if 10B users?"
2. **Trade-off analysis**: Pros vs cons for every decision
3. **Operational thinking**: Monitoring, failover, operational complexity
4. **AWS knowledge**: When and why to use AWS services
5. **Distributed systems**: CAP, consistency, fault tolerance

**Must-Know Patterns for Amazon**:
1. Sharding + Consistent Hashing
2. Circuit Breaker
3. Cache-Aside
4. Idempotency
5. Message Queue + Async
6. Read Replicas
7. CDN for static content

**Common Follow-up Questions**:
- "How would this scale to 100M users?"
- "What happens if a component fails?"
- "How do you maintain consistency?"
- "How do you detect and fix data loss?"
- "What's the failure mode if [X] goes down?"

---

## FINAL CHECKLIST (Before Interview)

- [ ] Understand CAP theorem deeply (CP vs AP choice)
- [ ] Know sharding strategies and when each fits
- [ ] Explain idempotency clearly (critical for Amazon)
- [ ] Be comfortable with read/write scaling separately
- [ ] Know Redis architecture (single-threaded, cluster mode)
- [ ] Understand WebSockets vs polling trade-offs
- [ ] Circuit breaker state transitions (open-half-open-closed)
- [ ] Can justify every technology choice
- [ ] Practice back-of-envelope calculations
- [ ] Discuss monitoring/alerting/operational concerns

**Remember**: Amazon values engineers who think about operational excellence, scalability, and reliability. Always discuss not just WHAT to build, but HOW to monitor it, WHAT can go wrong, and HOW to recover.

Good luck with your interview!