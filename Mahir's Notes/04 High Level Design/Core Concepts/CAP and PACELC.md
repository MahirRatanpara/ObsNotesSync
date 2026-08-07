# CAP and PACELC

## Why It Matters

The most cited and most misused theorem in system design. Stating it precisely separates candidates who understand distributed systems from those who memorised a triangle.

## CAP — Stated Correctly

For a distributed data store, you can guarantee at most two of:

- **Consistency** — every read returns the most recent write (this is *linearizability*, not ACID's C)
- **Availability** — every non-failing node returns a non-error response
- **Partition tolerance** — the system continues despite dropped messages between nodes

**The critical correction:** in a real distributed system, **network partitions will happen**. P is not optional. So CAP is really a binary choice that applies *only during a partition*:

> When a partition occurs, do you return possibly-stale data (AP), or refuse to answer (CP)?

**"CA systems" don't exist** in a distributed setting. A single-node database is trivially CA, but it isn't distributed. Saying "we'll pick CA" is the classic wrong answer.

## The Choice, Concretely

Two nodes, partitioned, a client writes to node A and another reads from node B:

| Choice | Behaviour |
|---|---|
| **CP** | Node B refuses the read (or blocks) rather than return stale data |
| **AP** | Node B returns its stale value, and the systems reconcile later |

## Classification

| System | Default | Notes |
|---|---|---|
| PostgreSQL / MySQL (single primary) | CP | Failover means unavailability |
| MongoDB | CP | Primary election pauses writes |
| HBase, Zookeeper, etcd, Consul | CP | Consensus-based; minority partition unavailable |
| Cassandra | **AP** (tunable) | Quorum settings move it toward CP |
| DynamoDB | AP by default | Strongly consistent reads available |
| Riak, CouchDB | AP | Conflict resolution on read |
| Spanner, CockroachDB | CP | External consistency via synchronised clocks / Raft |

**Cassandra and DynamoDB are tunable** — per-query consistency levels let you choose. Saying this shows depth.

## Tunable Consistency

```
R + W > N  ⟹  strong consistency
```

Where N = replicas, W = write quorum, R = read quorum.

| Config (N=3) | Property |
|---|---|
| W=1, R=1 | Fast, eventually consistent |
| W=3, R=1 | Fast reads, slow writes, read-your-writes |
| W=1, R=3 | Fast writes, slow reads |
| **W=2, R=2** | **Balanced quorum, strongly consistent** |

W=2, R=2 with N=3 is the standard production choice: it tolerates one node failure while remaining strongly consistent.

## PACELC — The Extension

CAP only describes behaviour *during* a partition. PACELC adds the normal case:

> **If Partition, choose Availability or Consistency; Else, choose Latency or Consistency.**

This matters because partitions are rare but the latency/consistency trade-off applies **all the time**.

| System | PACELC |
|---|---|
| DynamoDB, Cassandra | PA/EL — available under partition, low latency otherwise |
| MongoDB | PA/EC (configurable) |
| PostgreSQL (sync replication) | PC/EC |
| Spanner | PC/EC — pays latency for global consistency |

**Bringing up PACELC unprompted is a strong senior signal.** The everyday question isn't "what happens in a partition" — it's "are you willing to wait for a cross-region round trip on every write?"

## The Consistency Spectrum

CAP's binary framing hides a spectrum:

| Model | Guarantee |
|---|---|
| **Linearizable** | Reads see the most recent write, globally ordered |
| **Sequential** | All nodes see operations in the same order |
| **Causal** | Causally related operations are seen in order |
| **Read-your-writes** | You always see your own writes |
| **Monotonic reads** | You never see time go backwards |
| **Eventual** | Given no new writes, replicas converge |

**Read-your-writes is what users actually notice.** A user posting a comment and not seeing it is a bug report; another user seeing it 200 ms late is not. Session consistency (sticky routing or reading from the primary after a write) usually solves the perceived problem far more cheaply than global strong consistency.

## Interview Explanation

> "Partitions are inevitable, so the real choice is between CP and AP during a partition. For a payment ledger I'd choose CP — refusing a transaction is better than double-spending. For a social feed I'd choose AP, because a slightly stale timeline is fine and downtime isn't. PACELC also matters here: outside partitions, I'd rather serve the feed from a local replica with a few hundred milliseconds of lag than pay a cross-region round trip on every read."

## Common Mistakes

- Claiming a system is "CA"
- Treating CAP's C as ACID's C — they're different properties
- Assuming CAP forces a global, permanent choice rather than a per-operation one
- Ignoring that most databases are tunable per query
- Reaching for strong consistency when read-your-writes would satisfy the requirement

## Related Topics

- [Consistency Models](Consistency%20Models.md)
- [Consensus Algorithms](Consensus%20Algorithms.md)
- [Database Replication](Database%20Replication.md)

## Revision Summary

P is mandatory, so CAP is a CP-vs-AP choice made during partitions. PACELC adds the latency-vs-consistency trade-off in normal operation. Quorums (R + W > N) make consistency tunable per query.

## Quick Recall

- CA is not an option in a distributed system
- CAP's C = linearizability, not ACID's C
- R + W > N → strong consistency
- N=3, W=2, R=2 is the standard quorum
- PACELC: partition → A or C; else → L or C
- Read-your-writes is what users actually perceive
