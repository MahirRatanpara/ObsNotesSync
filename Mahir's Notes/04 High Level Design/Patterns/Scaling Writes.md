# Scaling Writes

## Why It Matters

Much harder than scaling reads — you can't just add replicas, since every replica must apply every write. This is where designs genuinely diverge.

## The Progression

### 1. Vertical Scaling
Genuinely underrated. A modern server with NVMe storage handles tens of thousands of writes per second. Cheaper and simpler than distribution. **Exhaust this before sharding** — and say so in an interview, because it demonstrates judgement rather than reflexive complexity.

### 2. Batching
Group many small writes into one round trip. A batched insert of 1,000 rows is dramatically faster than 1,000 individual inserts — fewer round trips, fewer transaction commits, fewer WAL fsyncs.

Trade-off: latency (you wait to fill a batch) and durability (a crash loses the unflushed buffer).

### 3. Write Queue (Buffering)
Accept the write into a durable queue, acknowledge immediately, and process asynchronously.

- Absorbs bursts — the queue smooths spikes the database can't handle
- Converts a synchronous write into an eventual one
- **Only valid when the client doesn't need immediate read-back**
- The queue must be durable, or you've traded correctness for throughput

### 4. Sharding
The real answer for sustained write scaling. See [Partitioning and Sharding](Partitioning%20and%20Sharding.md). Adds capacity linearly; costs joins, transactions, and global indexes.

### 5. Write-Optimised Storage (LSM Trees)
B-trees do random writes and read-modify-write pages. **LSM trees** buffer writes in a memtable, flush sequential SSTables, and compact in the background.

| | B-tree | LSM tree |
|---|---|---|
| Write amplification | Higher | **Lower** |
| Write throughput | Moderate | **High** |
| Read amplification | **Low** | Higher (multiple SSTables + Bloom filters) |
| Space amplification | Lower | Higher (until compaction) |
| Used by | Postgres, MySQL InnoDB | **Cassandra, RocksDB, LevelDB, ScyllaDB** |

**Choosing Cassandra for a write-heavy workload is really choosing an LSM tree.** Saying that is a strong signal.

### 6. Denormalise to Avoid Write Contention
Multiple writers updating one row (a counter, an inventory count) serialise on a lock. Instead write independent rows and aggregate on read, or use per-shard counters summed later.

### 7. Load Shedding
When saturated, reject low-priority writes explicitly rather than degrading everything. Return 429 with `Retry-After`. Graceful degradation beats collapse.

## Contention: The Other Write Problem

High write *rate* and high *contention on the same row* are different problems.

| Approach | Mechanism | Best for |
|---|---|---|
| **Pessimistic locking** | `SELECT ... FOR UPDATE` | High contention, short transactions |
| **Optimistic locking** | Version column, retry on mismatch | **Low contention** — the common case |
| Atomic operations | `UPDATE x SET n = n - 1 WHERE n > 0` | Simple counters |
| Queue serialisation | Route all writes for a key to one consumer | Guaranteed ordering |
| Distributed lock | Redis/ZooKeeper + **fencing token** | Cross-service coordination |

**Optimistic locking is the default choice** because most workloads have low actual conflict. Pessimistic locking serialises even when there'd be no conflict.

```sql
UPDATE inventory SET count = count - 1, version = version + 1
WHERE id = ? AND version = ? AND count > 0;
-- 0 rows updated → someone else won → retry
```

The `count > 0` predicate makes the check and the decrement atomic — no read-then-write race.

## Idempotency

At scale, retries are guaranteed. Every write endpoint should accept an idempotency key. See [Idempotent Consumers](Idempotent%20Consumers.md).

## Common Mistakes

- Sharding before exhausting vertical scaling
- A write queue where the client needs immediate read-back
- Pessimistic locking on a low-contention workload
- Read-then-write instead of a conditional update
- Ignoring hotspots — one hot key saturates one shard regardless of total capacity
- Non-durable buffering

## Related Topics

- [Scaling Reads](Scaling%20Reads.md)
- [Partitioning and Sharding](Partitioning%20and%20Sharding.md)
- [Idempotent Consumers](Idempotent%20Consumers.md)

## Revision Summary

Scale up, batch, buffer through a durable queue, then shard. LSM trees beat B-trees for write throughput. Distinguish write *rate* from write *contention* — optimistic locking handles the latter in most cases.

## Quick Recall

- Vertical scaling first — one node goes further than people assume
- Queue only if eventual is acceptable
- Sharding is the real write-scaling answer
- Cassandra/RocksDB = LSM = write-optimised
- Optimistic locking by default; conditional update, not read-then-write
- Hot key beats total capacity
