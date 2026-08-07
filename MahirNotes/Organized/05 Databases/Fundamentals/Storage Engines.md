# Storage Engines

> Why databases behave the way they do. Almost every performance characteristic you reason about in a design interview traces back to the engine underneath.

## Why It Matters

"Cassandra is good for writes" is a memorised fact. "Cassandra uses an LSM tree, so writes are sequential appends with no read-modify-write" is understanding — and it lets you reason about a database you've never used.

## The Fundamental Constraint

**Disks are fast at sequential access and slow at random access.**

| Operation | HDD | SSD |
|---|---|---|
| Sequential read | ~200 MB/s | ~3 GB/s |
| **Random read** | **~1 MB/s (seek-bound)** | ~500 MB/s |
| Random write | Slow | **Wears the device; write amplification** |

Every storage engine is a strategy for converting random access into sequential access. B-trees and LSM trees make opposite bets about where to pay that cost.

## B-Tree

The classic design, used by PostgreSQL, MySQL InnoDB, Oracle, SQL Server, and MongoDB's WiredTiger.

### Structure

```
              [ 50 | 100 ]                    ← internal: keys + child pointers
             /     |      \
    [10|30]   [60|80]   [120|150]
       |         |          |
   leaves: actual rows (or row pointers), LINKED left-to-right
```

| Property | Consequence |
|---|---|
| **High fan-out** (hundreds of keys/node) | Depth 3–4 even for billions of rows |
| **Data in leaves** | Internal nodes hold only keys, so more fit per page |
| **Leaves linked** | Range scans are sequential, no re-traversal |
| Balanced | Guaranteed O(log n) |

**A binary tree over a billion rows would be 30 levels deep — 30 random seeks. A B+ tree is 3–4.** That gap is the entire reason B-trees exist.

### Writes

```
1. Traverse to the leaf                    (random reads, usually cached)
2. Modify the page in the buffer pool
3. Write to the WAL and fsync              (sequential — this is the durability point)
4. Flush the dirty page later              (random write)
```

**Write amplification:** changing one 100-byte row rewrites an entire 8 KB page. **Page splits** when a node fills cause further writes and fragmentation.

**The WAL is what makes commits fast** — a sequential append and fsync, rather than waiting for random page writes. Recovery replays the log. See [Database Replication](../Replication%20and%20Failover/Database%20Replication.md).

### Strengths and weaknesses

| Good at | Bad at |
|---|---|
| **Reads — one traversal, predictable** | Very high write throughput |
| Range scans (linked leaves) | Write amplification on small updates |
| Predictable latency | Random I/O on flush |
| In-place updates, no compaction | — |

---

## LSM Tree

Log-Structured Merge tree. Used by Cassandra, RocksDB, LevelDB, ScyllaDB, HBase, and (optionally) MyRocks.

### Structure

```
WRITE → commit log (durability)
      → memtable (in-memory sorted structure, usually a skip list)
      → when full: FLUSH → SSTable (immutable, sorted, on disk)
      → background: COMPACTION merges SSTables
```

**Writes never read first.** No traversal, no read-modify-write, no random I/O — just an in-memory insert plus a sequential log append. That is why LSM write throughput is high.

### Reads are the cost

A key may live in the memtable or in any of several SSTables. A read must check them in order, newest first, and merge.

| Accelerator | Purpose |
|---|---|
| **Bloom filter per SSTable** | "Definitely not here" → skip the file entirely |
| Sparse index / partition summary | Locate the block within an SSTable |
| Block cache | Avoid disk for hot data |

**Bloom filters are what make LSM reads viable.** Without them, every read would touch every SSTable. See [Data Structures for Big Data](../../04%20High%20Level%20Design/Advanced%20Topics/Data%20Structures%20for%20Big%20Data.md).

### Compaction — the hidden cost

Background merging of SSTables reclaims space from overwritten and deleted rows and reduces the number of files a read must check.

| Strategy | Trade-off |
|---|---|
| **Size-tiered (STCS)** | **Write-optimised**; higher read and space amplification |
| **Leveled (LCS)** | **Read-optimised**; higher write amplification |
| Time-window (TWCS) | For time-series with TTL — drops whole windows |

**Compaction consumes I/O and CPU in the background and causes latency spikes.** This is the honest cost of cheap writes, and naming it demonstrates real understanding.

**Tombstones:** deletes write a marker rather than removing data, so it can propagate to replicas that were down. Tombstones survive until compaction *and* `gc_grace_seconds`. A partition full of tombstones is slow to read and can time out — which is why **delete-heavy, queue-like workloads are a Cassandra anti-pattern**.

---

## The Three Amplifications

Every engine trades between these, and you cannot minimise all three.

| Amplification | Meaning | B-tree | LSM |
|---|---|---|---|
| **Write** | Bytes written to disk per byte of data | Moderate (page rewrites) | **Low at write time, high via compaction** |
| **Read** | Disk reads per logical read | **Low (one traversal)** | Higher (multiple SSTables) |
| **Space** | Disk used per byte of data | Lower | Higher (obsolete data until compaction) |

**RUM conjecture: you can optimise for at most two of Read, Update, and Memory.** Naming this framing is a good senior-level aside.

- Leveled compaction reduces read and space amplification, raising write amplification
- Size-tiered does the reverse

---

## Side-by-Side

| | **B-tree** | **LSM tree** |
|---|---|---|
| Write path | Traverse → modify page → WAL | **Append to memtable + log** |
| Write throughput | Moderate | **High** |
| Read path | One traversal | Memtable + N SSTables + Bloom filters |
| Read latency | **Predictable** | Variable (depends on SSTable count) |
| Range scans | **Excellent (linked leaves)** | Good (SSTables are sorted) |
| Space | Compact | Higher until compaction |
| Background work | Minimal | **Compaction** |
| Deletes | In place | **Tombstones** |
| Latency spikes | Page splits, checkpoint flush | **Compaction** |
| Databases | Postgres, MySQL, MongoDB | **Cassandra, RocksDB, ScyllaDB** |

---

## Row vs Column Storage

An orthogonal choice, and it decides OLTP versus OLAP.

```
ROW-ORIENTED (OLTP)          COLUMN-ORIENTED (OLAP)
[id|name|age|city]           [id,id,id...] [name,name...] [age,age...]
[id|name|age|city]
```

| | Row | Column |
|---|---|---|
| `SELECT * WHERE id=?` | **One read** | Reassemble from every column file |
| `SELECT avg(age)` | **Reads every column of every row** | **Reads one column** |
| Compression | Poor (mixed types adjacent) | **Excellent (same type, similar values)** |
| Writes | **Cheap** | Expensive (touch every column file) |
| Used by | Postgres, MySQL | ClickHouse, Snowflake, BigQuery, Redshift |

**Columnar compresses far better** because adjacent values are the same type and often highly similar — enabling run-length, dictionary, and delta encoding. Time-series data reaches ~12× via delta-of-delta plus XOR encoding.

**Never run analytics on the OLTP primary.** A long scan holds a snapshot open, blocks vacuum, causes bloat, and competes for buffer cache. Replicate to a columnar store via CDC.

---

## Indexes On Top

| Index | Structure | Best for |
|---|---|---|
| **B-tree** | Balanced tree | Equality, range, ordering — the default |
| Hash | Hash table | Equality only; **no ranges** |
| **GIN** (inverted) | Term → row list | Full-text, JSONB, arrays |
| GiST / R-tree | Bounding boxes | Geospatial, nearest-neighbour |
| **BRIN** | Block-range min/max | **Huge naturally-ordered tables** — tiny index |
| LSM secondary | Separate SSTables | Wide-column stores |

**BRIN on an append-only time-series table can be thousands of times smaller than a B-tree** while still pruning most blocks — because the data is already ordered by the indexed column.

**Clustered vs secondary:** a clustered index holds the row data in key order (InnoDB's primary key); secondary indexes point back to it, requiring a second lookup unless the index is **covering**. Postgres has no clustered index — every index is secondary and points at a physical tuple location.

---

## In-Memory Engines

Redis, Memcached, VoltDB.

**Removing the disk changes the design entirely:** no B-tree needed for lookups (hash tables suffice), no buffer pool, no page management. Redis uses skip lists for sorted sets precisely because it doesn't need disk-oriented structures.

**Persistence becomes a separate concern** — snapshots or command logs, bolted on rather than fundamental. That's why Redis persistence has real loss windows: durability was never the primary design goal.

---

## Reasoning About An Unfamiliar Database

Ask four questions and you can predict most of its behaviour:

1. **B-tree or LSM?** → write throughput, read predictability, compaction behaviour
2. **Row or column?** → OLTP or OLAP
3. **Where's the durability point?** → WAL, commit log, or nothing
4. **How does it delete?** → in place, or tombstones with a grace period

**ScyllaDB:** LSM, row-oriented, commit log, tombstones → a faster Cassandra (C++, shard-per-core), same modelling rules and same anti-patterns.

**That's the payoff of this note** — you can reason about databases you've never used.

---

## Common Mistakes

- Explaining write performance without mentioning the storage engine
- Ignoring compaction cost when praising LSM write throughput
- Forgetting tombstones make delete-heavy LSM workloads pathological
- Running analytics on a row-oriented OLTP primary
- Assuming all indexes are B-trees
- Not knowing Postgres has no clustered index
- Treating in-memory stores as durable

## Related Topics

- [Choosing the Right Database](Choosing%20the%20Right%20Database.md)
- [Database Indexing](../Indexing/Database%20Indexing.md)
- [SQL vs NoSQL](../SQL%20vs%20NoSQL/SQL%20vs%20NoSQL.md)
- [Time Series and Analytics Databases](../../04%20High%20Level%20Design/Advanced%20Topics/Time%20Series%20and%20Analytics%20Databases.md)

## Revision Summary

B-trees update in place with high fan-out, giving predictable reads and moderate writes; LSM trees append sequentially for high write throughput, paying with compaction and multi-SSTable reads mitigated by Bloom filters. Row storage suits OLTP, columnar suits analytics through better compression and selective column reads. Engine choice explains nearly every behavioural difference between databases.

## Quick Recall

- Disks: sequential fast, random slow — every engine works around this
- **B-tree: depth 3–4, linked leaves, in-place update, WAL for durability**
- **LSM: memtable → SSTable → compaction; writes never read first**
- Bloom filters make LSM reads viable
- **Compaction is the hidden cost; tombstones break delete-heavy workloads**
- RUM conjecture: optimise two of Read, Update, Memory
- Row = OLTP; column = OLAP (better compression, selective reads)
- BRIN for huge ordered tables; Postgres has no clustered index
