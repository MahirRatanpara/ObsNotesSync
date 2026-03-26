
A practitioner's reference for making database choices, understanding distributed internals, and reasoning about trade-offs in system design interviews.

---

## 1. The Decision Landscape

Before diving into internals, here's the mental model. Every database choice is a trade-off across these axes:

|Axis|One End|Other End|
|---|---|---|
|Data Model|Rigid schema (SQL)|Flexible schema (NoSQL)|
|Consistency|Strong (linearizable)|Eventual|
|Availability|CP (sacrifice availability)|AP (sacrifice consistency)|
|Query Pattern|Complex joins, aggregations|Simple key-value lookups|
|Scale Direction|Vertical (bigger machine)|Horizontal (more machines)|
|Write Pattern|Write-light, read-heavy|Write-heavy, read-light|

The CAP theorem isn't a toggle — it's about what happens _during a network partition_. When all nodes can talk to each other, you can have both consistency and availability. The real question is: **when a partition occurs, do you refuse writes (CP) or allow divergence (AP)?**

---

## 2. SQL vs NoSQL — Internal Architecture Differences

### 2.1 SQL (Relational) Internals — Using PostgreSQL as Reference

**Storage Engine:**

- Data is stored in fixed-size **pages** (8 KB in Postgres). Each page holds multiple **tuples** (rows).
- Tables are organized as **heap files** — unordered collections of pages. Finding a specific row without an index requires a sequential scan.
- **B+ Tree indexes** are the default. The leaf nodes contain pointers to heap tuples. Range queries are efficient because leaf nodes are linked.
- Postgres uses **MVCC (Multi-Version Concurrency Control)**: every UPDATE creates a new version of the row. Old versions are eventually cleaned by VACUUM. This means readers never block writers and vice versa.

**Write Path (Postgres):**

```
Client sends INSERT/UPDATE
    → Parser → Planner → Executor
    → Write to WAL (Write-Ahead Log) on disk [durability guarantee]
    → Write to shared buffer pool (in memory)
    → Background writer flushes dirty pages to disk asynchronously
```

The WAL is the source of truth. If the server crashes after the WAL write but before the page flush, Postgres replays the WAL on recovery. This is how ACID durability works.

**Read Path:**

```
Client sends SELECT
    → Parser → Planner (cost-based optimizer picks best plan)
    → Executor reads from buffer pool (memory) or disk
    → Returns result set
```

The query planner is critical. It decides between sequential scan, index scan, bitmap scan, hash join, merge join, nested loop, etc., based on table statistics.

**Transaction Isolation Levels in Postgres:**

|Level|Dirty Read|Non-Repeatable Read|Phantom Read|Implementation|
|---|---|---|---|---|
|Read Committed (default)|No|Yes|Yes|Each statement sees latest committed data|
|Repeatable Read|No|No|No*|Snapshot at transaction start|
|Serializable|No|No|No|SSI (Serializable Snapshot Isolation) — detects conflicts|

*Postgres's Repeatable Read actually prevents phantoms too, unlike the SQL standard minimum.

### 2.2 NoSQL Internals — The LSM Tree Family (Cassandra, DynamoDB, RocksDB)

Most write-heavy NoSQL databases use **LSM Trees (Log-Structured Merge Trees)** instead of B+ Trees.

**Write Path (LSM Tree):**

```
Client sends write
    → Write to commit log (WAL equivalent) [durability]
    → Write to MemTable (in-memory sorted structure, usually a red-black tree or skip list)
    → When MemTable is full, flush to disk as an immutable SSTable (Sorted String Table)
    → Background compaction merges SSTables to reduce read amplification
```

**Read Path (LSM Tree):**

```
Client sends read
    → Check MemTable (most recent data)
    → Check Bloom filters for each SSTable (probabilistic: "definitely not here" or "maybe here")
    → Read matching SSTables from newest to oldest
    → Merge results, return most recent version
```

**Why LSM Trees favor writes:**

- Writes are sequential (append to log + insert to MemTable). No random I/O.
- B+ Trees require random I/O to find and update the correct leaf page.
- Trade-off: reads may need to check multiple SSTables → **read amplification**.

**Compaction Strategies:**

|Strategy|How It Works|Good For|
|---|---|---|
|Size-Tiered (Cassandra default)|Merge SSTables of similar size into larger ones|Write-heavy workloads|
|Leveled (RocksDB, Cassandra option)|SSTables organized into levels; each level is 10x larger|Read-heavy workloads, less space amplification|
|FIFO|Drop oldest SSTables|Time-series data with TTL|

### 2.3 Document Store Internals — MongoDB

MongoDB uses a **B-Tree variant (WiredTiger engine)** — not LSM Trees.

**Write Path:**

```
Client sends write
    → Write to journal (WAL equivalent)
    → Write to WiredTiger cache (in-memory B-Tree)
    → Checkpoint flushes to disk every 60 seconds (or 2 GB of journal data)
```

**Key Difference from SQL:**

- No schema enforcement at the engine level (schema validation is optional).
- Documents are stored as BSON (Binary JSON). Related data is often embedded in a single document rather than normalized across tables.
- Joins are possible (`$lookup`) but expensive — the data model is designed to avoid them.

---

## 3. Distributed Database Architectures

### 3.1 Single-Leader (Primary-Replica) — PostgreSQL, MySQL, MongoDB

```
                    ┌─────────────┐
         Writes ──→ │   Primary   │
                    │  (Leader)   │
                    └──────┬──────┘
                           │ Replication Stream (WAL / Oplog)
                ┌──────────┼──────────┐
                ▼          ▼          ▼
          ┌──────────┐ ┌──────────┐ ┌──────────┐
  Reads ← │ Replica 1│ │ Replica 2│ │ Replica 3│
          └──────────┘ └──────────┘ └──────────┘
```

**How replication works in PostgreSQL:**

1. Primary writes to its WAL.
2. WAL records are streamed to replicas via **streaming replication**.
3. Replicas apply WAL records to their local data files.

**Synchronous vs Asynchronous replication:**

|Mode|Behavior|Trade-off|
|---|---|---|
|Async (default)|Primary doesn't wait for replicas to confirm|Fast writes, but replica may lag → stale reads|
|Sync|Primary waits for at least one replica to confirm|Slower writes, but guaranteed no data loss on primary failure|
|Semi-sync|Primary waits for one replica, rest are async|Balance between the two|

**Replication lag problem:** If you write to the primary and immediately read from a replica, you might not see your write. Solutions:

- **Read-your-writes consistency**: route reads to the primary for data the user just wrote.
- **Monotonic reads**: pin a user to one replica so they don't see time go backward.
- **Causal consistency**: track causal dependencies and only serve reads that respect them.

**Failover:** When the primary dies:

1. Replicas detect the failure (heartbeat timeout).
2. An election happens (or an external orchestrator like Patroni decides).
3. The most up-to-date replica is promoted.
4. Other replicas re-point to the new primary.
5. Old primary, when recovered, joins as a replica.

Risk: if async replication was used, the new primary might be missing some writes from the old primary → **data loss**.

### 3.2 Multi-Leader — CockroachDB, YugabyteDB, MongoDB (multi-region)

```
       Region A                    Region B
   ┌─────────────┐            ┌─────────────┐
   │  Leader A    │◄──────────│  Leader B    │
   │  (reads +   │  bidirectional  │  (reads +   │
   │   writes)   │──────────►│   writes)   │
   └──────┬──────┘            └──────┬──────┘
          │                          │
     ┌────┴────┐                ┌────┴────┐
     │Replica A│                │Replica B│
     └─────────┘                └─────────┘
```

**When to use:** Multi-region deployments where you need low-latency writes in each region.

**Conflict problem:** If Leader A and Leader B both accept a write to the same row at the same time, you have a conflict. Strategies:

- **Last-Write-Wins (LWW)**: Timestamp-based, simple but lossy. Used by Cassandra.
- **Custom conflict resolution**: Application-level merge logic. Used by CouchDB.
- **Consensus-based**: Use Raft/Paxos per-row so only one leader accepts writes for a given key range. Used by CockroachDB, Spanner.

### 3.3 Leaderless — Cassandra, DynamoDB, Riak

```
        Client
       /  |  \
      ▼   ▼   ▼
   ┌────┐┌────┐┌────┐
   │ N1 ││ N2 ││ N3 │   ← All nodes are equal, any can accept reads/writes
   └────┘└────┘└────┘
   ┌────┐┌────┐┌────┐
   │ N4 ││ N5 ││ N6 │
   └────┘└────┘└────┘
```

**No single point of failure.** The client (or a coordinator node) sends writes to multiple nodes simultaneously.

**Quorum Protocol (the core mechanism):**

Given:

- **N** = total replicas for a key
- **W** = number of nodes that must acknowledge a write
- **R** = number of nodes that must respond to a read

The rule: **W + R > N** guarantees that at least one node in the read set has the latest write.

Common configurations:

|Config|N|W|R|Consistency|Availability|
|---|---|---|---|---|---|
|Strong|3|2|2|Strong (quorum overlap)|Tolerate 1 failure|
|Write-optimized|3|1|3|Eventual (no quorum overlap on write)|Writes survive 2 failures|
|Read-optimized|3|3|1|Eventual (no quorum overlap on read)|Reads survive 2 failures|

**Important subtlety:** Even with W + R > N, you don't get linearizability. You get "quorum consistency" — which handles many cases but can still have anomalies during concurrent writes. True linearizability requires coordination (like Paxos) on top.

---

## 4. Consistency Models — Deep Dive

### 4.1 The Spectrum

```
Strongest ◄──────────────────────────────────────────► Weakest

Linearizable → Sequential → Causal → Read-your-writes → Monotonic → Eventual
```

**Linearizable (Strongest):**

- Every operation appears to happen at a single instant between its invocation and response.
- If operation A completes before operation B starts, B must see A's effects.
- Used by: Spanner (TrueTime), CockroachDB (hybrid logical clocks), ZooKeeper (for writes).
- Cost: coordination on every write → higher latency.

**Sequential Consistency:**

- Operations appear in some sequential order that respects each client's ordering.
- Different from linearizable: doesn't require real-time ordering between different clients.
- Less useful in practice; rarely offered as a standalone guarantee.

**Causal Consistency:**

- If operation A causally precedes B (A happened-before B), everyone sees A before B.
- Concurrent operations (no causal relation) can be seen in different orders by different nodes.
- Used by: MongoDB (causal consistency sessions).

**Eventual Consistency:**

- If no new writes occur, all replicas will _eventually_ converge to the same value.
- No bound on how long "eventually" is.
- Used by: DynamoDB (default), Cassandra (with low W/R), DNS, CDN caches.

### 4.2 How Specific Databases Implement Consistency

**PostgreSQL:**

- Single-node: Serializable (SSI) provides linearizability for transactions.
- Replicated: Synchronous replication + reading from primary = linearizable. Reading from async replicas = eventual.

**Cassandra:**

- Per-query tunable consistency:
    - `ONE`, `TWO`, `THREE`: write/read to that many replicas.
    - `QUORUM`: majority of replicas (⌊N/2⌋ + 1).
    - `LOCAL_QUORUM`: quorum within the local data center.
    - `EACH_QUORUM`: quorum in every data center.
    - `ALL`: all replicas must respond.
- Typical production: `LOCAL_QUORUM` for both reads and writes → strong consistency within a DC, eventual across DCs.

**DynamoDB:**

- Writes: always go to all replicas (within a region).
- Reads:
    - **Eventually consistent read** (default): may read from any replica, might be stale.
    - **Strongly consistent read**: reads from the leader replica, guaranteed latest.
- DynamoDB Global Tables: eventual consistency across regions, LWW conflict resolution.

**MongoDB:**

- Write concern: `w:1` (primary ack), `w:majority` (majority of replica set ack), `w:0` (fire and forget).
- Read concern: `local` (read from any), `majority` (read data acknowledged by majority), `linearizable` (read data that has been majority-committed and won't be rolled back).
- Read preference: `primary`, `primaryPreferred`, `secondary`, `secondaryPreferred`, `nearest`.

---

## 5. Conflict Resolution — How Each Database Handles It

### 5.1 Cassandra — Last-Write-Wins (LWW)

Every write carries a **client-side timestamp**. When conflicting writes arrive:

1. The write with the highest timestamp wins.
2. The losing write is silently discarded.
3. This happens at the **column level**, not the row level — so two concurrent updates to different columns of the same row both survive.

**Anti-entropy mechanisms:**

- **Read Repair**: during a read, if replicas return different values, the coordinator sends the newest value to stale replicas.
- **Merkle Tree Anti-Entropy**: background process compares Merkle tree hashes between replicas and syncs differences.
- **Hinted Handoff**: if a target node is down, another node stores the write as a "hint" and forwards it when the target recovers.

**The problem with LWW:** If two clients write at nearly the same time, one write is permanently lost with no notification. The system cannot detect this as a conflict — it just picks a winner.

```
Time →
Client A: write(key=X, value="A", timestamp=100)  → Node 1, Node 2
Client B: write(key=X, value="B", timestamp=101)  → Node 2, Node 3

Result: value="B" wins everywhere. "A" is gone forever.
```

### 5.2 DynamoDB — LWW for Global Tables, Conditional Writes for Single Region

**Single Region:**

- DynamoDB doesn't have write-write conflicts in a single region because all writes go through a single leader partition.
- Use **conditional writes** (e.g., `PutItem` with `ConditionExpression`) for optimistic concurrency control: `attribute_not_exists(pk) OR version = :expected_version`.
- **Transactions** (`TransactWriteItems`): up to 100 items across tables, all-or-nothing, serializable isolation.

**Global Tables (Multi-Region):**

- Every region is a full read-write replica.
- Conflict resolution: **LWW using wall-clock timestamps**.
- All item-level changes are replicated asynchronously to other regions.
- Replication latency: typically under 1 second, but no guarantee.

### 5.3 MongoDB — Oplog-Based, Single-Primary Avoids Conflicts

In a standard replica set, all writes go to the primary → no write conflicts.

The **oplog (operations log)** is a capped collection that records every write operation. Secondaries tail the oplog and apply operations in order.

**Where conflicts can arise:**

- **Sharded clusters with multi-document transactions**: the transaction coordinator ensures atomicity across shards using a two-phase commit protocol.
- **MongoDB Atlas Global Clusters with zone sharding**: writes to the same document in different zones are prevented by routing — each document belongs to one zone's primary.

### 5.4 PostgreSQL — MVCC + Locks, No Conflicts by Design

Postgres prevents conflicts rather than resolving them:

- **Pessimistic locking**: `SELECT ... FOR UPDATE` locks rows.
- **Optimistic concurrency**: application checks a version column before writing.
- **SSI (Serializable Snapshot Isolation)**: detects conflicting transaction dependencies and aborts one of them. The application retries.

---

## 6. Partitioning (Sharding) Strategies

### 6.1 Why Shard?

When a single node can't handle the data volume or throughput, you split the data across multiple nodes.

### 6.2 Hash Partitioning

```
partition = hash(key) mod N
```

- Used by: DynamoDB, Cassandra, Redis Cluster.
- Pros: even distribution, no hotspots (if the hash function is good).
- Cons: range queries are expensive (data for adjacent keys is scattered).

**Consistent Hashing (Cassandra, DynamoDB):** Instead of `mod N`, keys are mapped to a position on a hash ring. Each node owns a range of the ring. When nodes are added/removed, only adjacent ranges are affected → minimal data movement.

```
        0
       / \
     N4   N1
     |     |
     N3   N2
       \ /
       180
       
Key "user:123" → hash = 42 → falls in N1's range
Key "user:456" → hash = 190 → falls in N4's range
```

**Virtual Nodes (vnodes):** Each physical node gets multiple positions on the ring (e.g., 256 vnodes). This improves balance because a node with more capacity gets more vnodes.

### 6.3 Range Partitioning

```
Partition 1: keys A-M
Partition 2: keys N-Z
```

- Used by: Spanner, CockroachDB, HBase, PostgreSQL (declarative partitioning).
- Pros: range queries are efficient (scan one partition).
- Cons: hotspots if data is skewed (e.g., most users have names starting with S).

### 6.4 PostgreSQL Sharding — Citus / Native Partitioning

**Declarative Partitioning (single node, not true sharding):**

```sql
CREATE TABLE orders (
    id BIGINT,
    created_at TIMESTAMP,
    amount DECIMAL
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2025_q1 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
```

**True Distributed Sharding (Citus extension):**

```sql
-- Distribute table by customer_id across worker nodes
SELECT create_distributed_table('orders', 'customer_id');
```

Citus routes queries to the correct shard. Cross-shard queries are supported but slower (scatter-gather).

### 6.5 Cassandra Partitioning

```sql
CREATE TABLE users (
    user_id UUID,
    email TEXT,
    name TEXT,
    PRIMARY KEY (user_id)  -- user_id is the partition key
);

-- Compound partition key for time-series
CREATE TABLE events (
    sensor_id UUID,
    event_date DATE,
    event_time TIMESTAMP,
    data TEXT,
    PRIMARY KEY ((sensor_id, event_date), event_time)
    -- (sensor_id, event_date) = partition key
    -- event_time = clustering column (sorted within partition)
);
```

The partition key determines which node stores the data. The clustering column determines sort order within a partition. This is fundamental — Cassandra data modeling is driven by query patterns, not entity relationships.

---

## 7. Global Distributed Setup — Putting It All Together

### 7.1 PostgreSQL Global Setup (Strong Consistency Path)

```
┌─────────────────────── Region: US-East ────────────────────────┐
│                                                                 │
│   ┌──────────────┐    sync replication    ┌──────────────┐     │
│   │   Primary    │ ──────────────────────►│  Sync Replica │     │
│   │  (writes +   │                        │  (failover    │     │
│   │   reads)     │                        │   candidate)  │     │
│   └──────┬───────┘                        └──────────────┘     │
│          │ async replication                                    │
│          ▼                                                      │
│   ┌──────────────┐                                             │
│   │ Async Replica │  ← read-only, for analytics                │
│   └──────────────┘                                             │
└─────────────────────────────────────────────────────────────────┘
          │ async replication (cross-region)
          ▼
┌─────────────────────── Region: EU-West ────────────────────────┐
│   ┌──────────────┐                                             │
│   │ Read Replica  │  ← serves local reads, may be stale        │
│   └──────────────┘                                             │
└─────────────────────────────────────────────────────────────────┘

Managed by: Patroni (HA orchestrator) + etcd (consensus store)
Connection routing: PgBouncer / HAProxy
```

**Scaling strategy:**

- Vertical scaling first (Postgres can handle a lot on a single large machine).
- Read replicas for read scaling.
- Citus for horizontal write scaling when single-node is exhausted.
- Partitioning for large tables (by time for time-series, by tenant for multi-tenant).

### 7.2 Cassandra Global Setup (Availability-First Path)

```
┌──────── DC: US-East ────────┐     ┌──────── DC: EU-West ────────┐
│                              │     │                              │
│  ┌────┐ ┌────┐ ┌────┐      │     │  ┌────┐ ┌────┐ ┌────┐      │
│  │ N1 │ │ N2 │ │ N3 │      │◄───►│  │ N4 │ │ N5 │ │ N6 │      │
│  └────┘ └────┘ └────┘      │     │  └────┘ └────┘ └────┘      │
│                              │     │                              │
│  Replication Factor: 3       │     │  Replication Factor: 3       │
│  Each key → 3 nodes in DC    │     │  Each key → 3 nodes in DC    │
└──────────────────────────────┘     └──────────────────────────────┘

NetworkTopologyStrategy: {'US-East': 3, 'EU-West': 3}
Consistency: LOCAL_QUORUM for reads and writes
```

**How a write flows:**

1. Client connects to any node (the **coordinator**).
2. Coordinator hashes the partition key → determines which 3 nodes own this key in each DC.
3. In the local DC, coordinator sends write to all 3 replicas, waits for 2 acks (`LOCAL_QUORUM`).
4. Simultaneously, coordinator forwards write to remote DC (async by default, or `EACH_QUORUM` for sync).
5. Returns success to client after local quorum is met.

**Node failure handling:**

- If one of the 3 local replicas is down, the write still succeeds (only need 2/3).
- Hinted handoff stores the missed write and replays it when the node returns.
- If the node is down too long, Merkle-tree repair syncs it when it comes back.

### 7.3 DynamoDB Global Setup

```
┌──────── Region: us-east-1 ──────┐     ┌──────── Region: eu-west-1 ──────┐
│                                   │     │                                   │
│  ┌─────────────────────────────┐ │     │  ┌─────────────────────────────┐ │
│  │      DynamoDB Table         │ │◄───►│  │    DynamoDB Global Table    │ │
│  │  (fully managed partitions) │ │async │  │       (full replica)        │ │
│  └─────────────────────────────┘ │repli-│  └─────────────────────────────┘ │
│                                   │cation│                                   │
│  Automatic partitioning by PK     │     │  Automatic partitioning by PK     │
│  Auto-scaling read/write capacity │     │  Auto-scaling read/write capacity │
└───────────────────────────────────┘     └───────────────────────────────────┘

Conflict resolution: Last-Writer-Wins (wall clock)
Replication: typically < 1 second
```

DynamoDB is fully managed — you don't configure nodes, replicas, or compaction. You choose:

- **Partition key** (and optional sort key)
- **Capacity mode**: on-demand or provisioned
- **Global tables**: which regions to replicate to
- **Consistency**: eventual or strong per-read

Under the hood, DynamoDB uses a Paxos-based replication protocol within a region for the leader of each partition. But this is abstracted away.

### 7.4 MongoDB Global Setup

```
┌──── Replica Set: shard-1 ─────┐   ┌──── Replica Set: shard-2 ─────┐
│ Primary ↔ Secondary ↔ Secondary│   │ Primary ↔ Secondary ↔ Secondary│
│ (Arbiter optional)             │   │                                 │
└────────────────────────────────┘   └────────────────────────────────┘
                    ▲                                ▲
                    └────────┬───────────────────────┘
                             │
                    ┌────────┴────────┐
                    │   mongos Router  │  ← client connects here
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │  Config Servers  │  ← shard metadata (which ranges on which shard)
                    │  (replica set)   │
                    └─────────────────┘
```

**Sharding in MongoDB:**

- Choose a **shard key** (e.g., `user_id`). MongoDB supports hash-based or range-based sharding.
- **Chunks** are contiguous ranges of shard key values. Each chunk lives on one shard.
- The **balancer** moves chunks between shards to maintain even distribution.
- **mongos** routes queries: if the query includes the shard key, it goes to one shard (targeted query). Otherwise, it broadcasts to all shards (scatter-gather).

---

## 8. Choosing the Right Database — Decision Framework

### 8.1 Start with the Access Pattern

|Access Pattern|Best Fit|Why|
|---|---|---|
|Complex queries with joins, aggregations|PostgreSQL, MySQL|SQL query planner handles this natively|
|Simple key-value lookups at massive scale|DynamoDB, Redis|Optimized for single-key access, auto-scaling|
|Wide-column, time-series, high write throughput|Cassandra, ScyllaDB|LSM trees + leaderless = write-optimized|
|Flexible/evolving schema, moderate scale|MongoDB|Document model, rich query language|
|Graph traversals (social networks, recommendations)|Neo4j, Neptune|Adjacency-based storage makes traversals O(1) per hop|
|Full-text search|Elasticsearch, OpenSearch|Inverted indexes, relevance scoring|
|Real-time analytics on large datasets|ClickHouse, Druid|Columnar storage, vectorized execution|

### 8.2 Then Evaluate the System Requirements

**Do you need ACID transactions across multiple entities?**

- Yes → SQL database (Postgres, MySQL) or NewSQL (CockroachDB, Spanner).
- No → NoSQL options become viable.

**What's your consistency requirement?**

- Financial systems, inventory (stock counts), booking systems → strong consistency.
- Social media feeds, analytics, recommendations → eventual consistency is fine.
- Mixed → use different databases for different parts of the system.

**What's your scale?**

- < 1 TB, < 10K QPS → single Postgres node handles this easily. Don't over-engineer.
- 1-10 TB, 10K-100K QPS → Postgres with read replicas, or start considering DynamoDB/Cassandra.
- 10 TB+, 100K+ QPS → distributed databases become necessary.

**What's your availability requirement?**

- 99.9% (8.7 hours downtime/year) → single-leader with automated failover.
- 99.99% (52 minutes/year) → multi-region active-active, leaderless.
- 99.999% (5 minutes/year) → this is extremely hard; need multi-region + consensus protocols.

### 8.3 Common System Design Scenarios

|System|Primary DB|Why|Consistency Model|
|---|---|---|---|
|E-commerce (orders, payments)|PostgreSQL + Redis cache|ACID for orders, cache for product pages|Strong for orders, eventual for catalog|
|Social media feed|Cassandra (feed storage) + Postgres (user data)|Feed is write-heavy, fan-out; user data needs consistency|Eventual for feeds, strong for user data|
|Chat/messaging|Cassandra or DynamoDB|Message writes are append-only, time-series-like|Eventual (ordering by timestamp)|
|Ride-sharing (Uber-like)|Postgres (trips, payments) + Redis (location) + DynamoDB (events)|Mix of transactional + high-throughput + low-latency|Strong for trips, eventual for location|
|URL shortener|DynamoDB or Redis|Simple key-value, high read throughput|Eventual (redirect is idempotent)|
|Booking/reservation|PostgreSQL|Need transactions to prevent double-booking|Serializable isolation|
|Logging/monitoring|Elasticsearch + Cassandra|Full-text search + time-series writes|Eventual|
|Distributed rate limiter|Redis (Cluster mode)|In-memory, sub-ms latency, Lua scripting for atomicity|Approximate (eventual across cluster)|

---

## 9. Database Design Considerations for System Design Interviews

### 9.1 Schema Design Principles

**SQL — Normalize, Then Denormalize Where Needed:**

1. Start with 3NF (Third Normal Form) — no redundant data.
2. Identify slow query patterns.
3. Denormalize selectively: materialized views, precomputed columns, summary tables.
4. Add indexes based on query patterns (not preemptively).

**NoSQL (Cassandra / DynamoDB) — Query-First Design:**

1. List all the queries the application needs.
2. Design one table per query (denormalization is the norm).
3. Choose partition keys to distribute load evenly.
4. Choose sort keys to enable the query's ordering/filtering.
5. Accept data duplication as the cost of performance.

**MongoDB — Embed vs Reference:**

|Criteria|Embed (subdocument)|Reference (foreign key)|
|---|---|---|
|Read pattern|Always read together|Read separately|
|Data size|Sub-document < 16 MB (doc limit)|Large or growing data|
|Update pattern|Updated together|Updated independently|
|Relationship|1:1 or 1:few|1:many or many:many|

### 9.2 Indexing Strategy

**PostgreSQL:**

- B-Tree (default): equality, range, sorting.
- GIN: full-text search, JSONB containment.
- GiST: geometric, range types, proximity.
- BRIN: large tables sorted by a column (e.g., time-series — tiny index, huge table).
- Partial index: `CREATE INDEX idx ON orders(status) WHERE status = 'pending';`

**Cassandra:**

- Primary index = partition key (mandatory, hash-based).
- Clustering columns = sort order within partition.
- **Secondary indexes** exist but are dangerous in production (scatter-gather across all nodes). Use **materialized views** or denormalized tables instead.

**DynamoDB:**

- **Primary key**: partition key + optional sort key.
- **GSI (Global Secondary Index)**: different partition key, eventually consistent with base table.
- **LSI (Local Secondary Index)**: same partition key, different sort key, must be defined at table creation.

### 9.3 What Interviewers Want to Hear

1. **Start with requirements, not technology.** "Given that we need X consistency, Y throughput, and Z query patterns, I'd choose..."
2. **Acknowledge trade-offs.** "By choosing Cassandra here, we gain write throughput and availability but lose the ability to do ad-hoc joins."
3. **Design for failure.** "If this node goes down..." should have a clear answer.
4. **Show you understand internals.** "Cassandra uses LOCAL_QUORUM, which means..." demonstrates depth.
5. **Don't use one DB for everything.** Real systems use polyglot persistence — different databases for different use cases.
6. **Mention caching.** Almost every system uses Redis/Memcached to reduce DB load. Discuss cache invalidation strategy.
7. **Mention connection pooling.** Databases have connection limits. Use PgBouncer (Postgres), connection pooling in drivers (MongoDB, Cassandra).

### 9.4 Performance Numbers to Know

|Operation|Approximate Latency|
|---|---|
|Redis GET|0.1 - 0.5 ms|
|DynamoDB GetItem|1 - 5 ms (single-digit ms)|
|PostgreSQL indexed query|1 - 10 ms|
|Cassandra read (LOCAL_QUORUM)|2 - 10 ms|
|MongoDB indexed query|1 - 10 ms|
|PostgreSQL full table scan (1M rows)|100 - 1000 ms|
|Cross-region replication latency|50 - 200 ms|

---

## 10. Advanced Topics

### 10.1 Change Data Capture (CDC)

CDC captures row-level changes from a database and streams them to other systems.

- **PostgreSQL**: logical replication slots + Debezium → Kafka.
- **DynamoDB**: DynamoDB Streams → Lambda or Kinesis.
- **MongoDB**: Change Streams (tails the oplog) → application or Kafka.
- **Cassandra**: CDC log → custom consumer.

Use cases: keeping a search index in sync, building materialized views, event-driven architectures.

### 10.2 Multi-Model Databases

Some databases blur the line:

- **PostgreSQL**: relational + JSONB (document-like) + PostGIS (spatial) + full-text search. Often "good enough" for multiple models.
- **CosmosDB (Azure)**: offers SQL, MongoDB, Cassandra, and Gremlin APIs on the same engine. Tunable consistency (5 levels from strong to eventual).
- **CockroachDB / YugabyteDB**: PostgreSQL-compatible SQL with auto-sharding and Raft-based replication.

### 10.3 Connection Patterns and Pooling

**Why it matters:** Each database connection consumes memory. PostgreSQL forks a process per connection. At high scale, you run out of connections before you run out of CPU.

|Database|Default Connection Model|Pooling Solution|
|---|---|---|
|PostgreSQL|Process per connection (~10 MB each)|PgBouncer (external), Supavisor, application-level|
|MySQL|Thread per connection (~1-4 MB)|ProxySQL, application-level|
|MongoDB|Thread per connection (driver-managed)|Built-in driver pool (default 100 per host)|
|Cassandra|Multiplexed (many queries per TCP connection)|Built into driver protocol|
|DynamoDB|HTTP API (no persistent connections)|SDK handles connection reuse|

### 10.4 The PACELC Theorem (Extension of CAP)

CAP only describes behavior during partitions. PACELC adds: "else, what do you trade — latency or consistency?"

|Database|During Partition (PAC)|Else (ELC)|
|---|---|---|
|PostgreSQL (async replicas)|PC (refuses writes to replicas)|EL (low latency reads from replicas)|
|Cassandra (QUORUM)|PA (serves from available quorum)|EL (tunable, can sacrifice consistency for speed)|
|DynamoDB|PA (eventually consistent reads available)|EL (default eventual reads are faster)|
|Spanner / CockroachDB|PC (refuses stale reads)|EC (pays latency for consistency via consensus)|
|MongoDB (w:majority)|PC (blocks writes until majority ack)|EC (waits for majority ack even when healthy)|

---

## Quick Reference: Database Comparison Matrix

|Feature|PostgreSQL|Cassandra|DynamoDB|MongoDB|
|---|---|---|---|---|
|Data Model|Relational (tables)|Wide-column|Key-value / Document|Document (BSON)|
|Storage Engine|Heap + B-Tree (MVCC)|LSM Tree|LSM Tree (managed)|B-Tree (WiredTiger)|
|Replication|Primary-replica (WAL)|Leaderless (gossip)|Managed (Paxos within region)|Primary-replica (oplog)|
|Sharding|Citus extension / declarative partitioning|Consistent hashing (automatic)|Automatic hash partitioning|Range or hash (manual shard key)|
|Consistency|Serializable (single node)|Tunable (ONE → ALL)|Eventual or strong (per-read)|Tunable (write concern + read concern)|
|Transactions|Full ACID (multi-row, multi-table)|Lightweight transactions (single partition)|TransactWriteItems (up to 100 items)|Multi-document ACID (since 4.0)|
|Conflict Resolution|Locks / SSI (prevent conflicts)|LWW (timestamp)|LWW (global tables) / conditional writes|Single-primary (no conflicts)|
|Best For|Complex queries, ACID, moderate scale|Write-heavy, time-series, availability|Serverless, auto-scaling, simple access|Flexible schema, moderate scale|
|Worst For|Write-heavy at massive scale|Ad-hoc queries, joins|Complex queries, joins|Write-heavy at extreme scale|
|Operational Complexity|Medium (tuning, VACUUM, etc.)|High (compaction tuning, data modeling)|Low (fully managed)|Medium (sharding decisions, index management)|

---

_This guide covers the core concepts. For interview prep, practice applying these concepts to specific system design problems — the best way to internalize this is to design 5-10 systems and justify your database choice for each one._