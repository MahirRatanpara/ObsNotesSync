# Cassandra

## Why It Matters

The reference answer for write-heavy, horizontally-scaled workloads. Interviewers use it to test whether you can model from access patterns rather than from entities.

## Architecture — Masterless

**Every node is identical.** No primary, no coordinator role, no single point of failure. Any node can accept any request and acts as the coordinator for it.

Data is partitioned by **consistent hashing** onto a ring, with virtual nodes for even distribution. See [Consistent Hashing](Consistent%20Hashing.md).

**Membership is via a gossip protocol** — nodes exchange state with a few random peers each second, so the cluster converges on a shared view without a coordinator.

## The Storage Engine — LSM Tree

This is where Cassandra's characteristics come from:

```
write → commit log (durability)  +  memtable (in-memory, sorted)
      → memtable full → flush → SSTable (immutable, on disk)
      → background compaction merges SSTables
```

**Writes are append-only and never read first.** No read-modify-write, no random I/O, no in-place update. That's why write throughput is so high.

**Reads are harder:** a row may exist in the memtable and several SSTables, all of which must be checked and merged.

| Read accelerator | Purpose |
|---|---|
| **Bloom filter** | Skip SSTables that definitely don't contain the key |
| Partition index / summary | Locate the row within an SSTable |
| Row cache / key cache | Skip disk entirely for hot data |

**Compaction is the cost.** Merging SSTables consumes I/O and CPU in the background and can cause latency spikes. Different strategies (size-tiered, leveled, time-window) trade write amplification against read amplification — leveled favours reads, size-tiered favours writes.

## Tunable Consistency

Per-query consistency level on both reads and writes:

| Level | Meaning |
|---|---|
| ONE | One replica responds |
| **QUORUM** | Majority of replicas |
| LOCAL_QUORUM | Majority **within the local datacentre** |
| ALL | Every replica |

```
R + W > N  →  strong consistency
```

With RF=3: **W=QUORUM(2), R=QUORUM(2)** gives strong consistency while tolerating one node loss. This is the standard production setting.

**LOCAL_QUORUM is the multi-datacentre answer** — it avoids cross-region latency on every operation while remaining consistent within a region. Mentioning it signals real familiarity.

## Repair Mechanisms

Because writes can succeed on a subset of replicas, Cassandra has three convergence mechanisms:

| Mechanism | When |
|---|---|
| **Hinted handoff** | A replica is down; the coordinator stores a hint and replays it on recovery |
| **Read repair** | On read, mismatched replicas are corrected |
| **Anti-entropy repair** | Scheduled `nodetool repair` using **Merkle trees** to find divergent ranges efficiently |

**Merkle trees** let two nodes compare terabytes of data by exchanging a small hash tree, descending only into subtrees that differ.

**Anti-entropy repair must be run regularly** — within `gc_grace_seconds` — or deleted data can resurrect.

## Data Modelling — Query-First

**The single most important rule: one table per query.** Denormalisation and duplication are expected, not a smell.

```sql
CREATE TABLE messages_by_conversation (
    conversation_id uuid,
    message_id      timeuuid,
    sender_id       uuid,
    content         text,
    PRIMARY KEY ((conversation_id), message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);
```

- **Partition key** (`conversation_id`) determines the node — must appear in every query
- **Clustering key** (`message_id`) determines on-disk sort order within the partition

This makes "the last 50 messages in this conversation" a **single sequential read from one partition** — the ideal access pattern.

**What you give up:** no joins, no ad-hoc `WHERE`, no aggregation, no `ORDER BY` on arbitrary columns.

## The Failure Modes To Name

### Unbounded partitions
A partition that grows without limit (all events for a long-lived entity) eventually exceeds practical size and causes timeouts and heap pressure. **Fix: add a time bucket to the partition key** — `((conversation_id, month), message_id)`.

**Target: under 100 MB and under 100,000 rows per partition.**

### Tombstones
Deletes write a **tombstone** rather than removing data, so it can be propagated to replicas that were down. Tombstones live for `gc_grace_seconds` (default 10 days).

A query scanning many tombstones is slow and can fail outright. **Queue-like workloads — insert, read, delete — are a Cassandra anti-pattern** precisely because they generate tombstone-heavy partitions.

### Last-write-wins
Conflict resolution is by cell timestamp. **Concurrent writes silently lose one**, and clock skew makes the outcome unpredictable. There are no transactions to prevent it.

**Lightweight transactions** (`IF NOT EXISTS`) use Paxos for compare-and-set — correct, but four round trips and roughly an order of magnitude slower. Use sparingly.

### Secondary indexes
Cassandra secondary indexes are **local to each node**, so a query using one hits every node in the cluster. They perform acceptably only on low-cardinality columns within a known partition. **Prefer a separate denormalised table.**

## Cassandra vs DynamoDB vs MongoDB

| | Cassandra | DynamoDB | MongoDB |
|---|---|---|---|
| Operations | **Self-managed** (or Astra) | **Fully managed** | Either |
| Model | Wide column | Key-value / document | Document |
| Consistency | Tunable per query | Eventual or strong per read | Tunable |
| Scaling | Add nodes | Automatic | Sharding |
| Multi-region writes | **Native, symmetric** | Global tables (LWW) | Configurable |
| Cost model | Infrastructure | **Per request/capacity** | Varies |

**Choose Cassandra** for very high write volume, multi-region active-active, and when you can run it. **Choose DynamoDB** for the same access patterns without the operational burden, on AWS.

## When Not To Use It

- You need joins, ad-hoc queries, or aggregations
- Strong multi-row transactions are required
- Data volume is small — the operational cost isn't justified
- Access patterns aren't known yet, or change frequently
- The workload is queue-like

## Common Mistakes

- Modelling relationally, then discovering there are no joins
- Unbounded partitions
- Queue-like delete-heavy workloads
- Relying on secondary indexes
- Not running scheduled repair
- Assuming LWW is safe for concurrent writes
- Choosing it before knowing the access patterns

## Related Topics

- [SQL vs NoSQL](SQL%20vs%20NoSQL.md)
- [Consistent Hashing](Consistent%20Hashing.md)
- [CAP and PACELC](CAP%20and%20PACELC.md)
- [Consistency Models](Consistency%20Models.md)

## Revision Summary

Masterless ring with consistent hashing and an LSM storage engine, giving very high write throughput. Consistency is tunable per query — QUORUM/QUORUM at RF=3 is standard. Model one table per query, keep partitions bounded, avoid delete-heavy workloads, and accept last-write-wins.

## Quick Recall

- Masterless, gossip, consistent hashing with vnodes
- LSM: commit log + memtable → SSTables → compaction
- Bloom filters make reads viable
- `R + W > N`; QUORUM/QUORUM at RF=3; LOCAL_QUORUM cross-region
- **One table per query**; partition key in every query
- Bound partitions with a time bucket (<100 MB)
- Tombstones make queue workloads an anti-pattern
- LWW loses concurrent writes; LWT is Paxos and slow
