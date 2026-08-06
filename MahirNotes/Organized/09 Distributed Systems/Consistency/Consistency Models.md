# Consistency Models

## Why It Matters

"Eventually consistent" is used to mean a dozen different things. Being precise about which guarantee you need is what separates a designed system from a hopeful one.

## The Spectrum (strongest to weakest)

| Model | Guarantee | Cost |
|---|---|---|
| **Linearizable** | Every read sees the latest committed write, as if there were one copy | Consensus round trip per operation |
| **Sequential** | All nodes see operations in the same order, not necessarily real-time order | Ordering protocol |
| **Causal** | Causally related operations are seen in order; concurrent ones may differ | Vector clocks / dependency tracking |
| **Read-your-writes** | You always see your own writes | Sticky routing or read-from-primary |
| **Monotonic reads** | You never see time go backwards | Sticky session to one replica |
| **Monotonic writes** | Your writes apply in the order you issued them | Per-session ordering |
| **Eventual** | With no new writes, replicas converge | Cheapest |

## The Session Guarantees Are What Users Notice

Read-your-writes, monotonic reads, and monotonic writes together are called **session consistency**. In practice:

- A user posts a comment and doesn't see it → bug report
- Another user sees it 300 ms later → nobody notices
- A user refreshes and their comment **disappears** → serious bug (violates monotonic reads)

**Session consistency is far cheaper than linearizability and solves most perceived problems.** Implement it by routing a user's reads to the primary for a few seconds after a write, or by pinning them to one replica.

This is the single most useful practical insight in this note.

## Achieving Each

| Model | Mechanism |
|---|---|
| Linearizable | Raft/Paxos, or quorum reads/writes with `R + W > N` |
| Causal | Vector clocks, version vectors, Lamport timestamps |
| Read-your-writes | Read from primary after write, or track the last-written version |
| Monotonic reads | Sticky session to a single replica |
| Eventual | Async replication + conflict resolution |

## Conflict Resolution in Eventually Consistent Systems

| Strategy | Behaviour | Risk |
|---|---|---|
| **Last-Write-Wins** | Highest timestamp wins | **Silent data loss**; depends on clock sync |
| Version vectors | Detect concurrent writes, surface siblings | Application must merge |
| **CRDTs** | Mathematically guaranteed convergence | Limited to specific data types |
| Application merge | Domain-specific logic | Most work, best results |

**LWW is the default in Cassandra and DynamoDB global tables, and it silently loses concurrent writes.** Say this if asked about Cassandra — it's a real trade-off, not a detail.

**CRDTs** (counters, sets, registers, sequences) converge without coordination because their merge operation is commutative, associative, and idempotent. Used in collaborative editors and distributed counters.

## Replication Lag Problems

| Problem | Symptom | Fix |
|---|---|---|
| Read-after-write | User doesn't see their own update | Read from primary for N seconds after write |
| Monotonic reads | Data appears then disappears on refresh | Pin the session to one replica |
| Consistent prefix | Reply appears before the message it answers | Causal ordering or same-partition routing |

## Interview Explanation

> "I'd use eventual consistency for the feed since a few hundred milliseconds of lag is invisible, but I'd add read-your-writes for the author by routing their reads to the primary for five seconds after a post. That gives the perceived correctness users care about without paying for linearizability on every read."

## Common Mistakes

- Treating "eventual consistency" as a single guarantee
- Using LWW without acknowledging the data-loss risk
- Reaching for strong consistency when session consistency would do
- Ignoring the consistent-prefix problem in chat and comment systems
- Assuming synchronised clocks (they aren't — see clock skew)

## Related Topics

- [CAP and PACELC](../../04%20High%20Level%20Design/Core%20Concepts/CAP%20and%20PACELC.md)
- [Consensus Algorithms](../Consensus/Consensus%20Algorithms.md)
- [Database Replication](../../05%20Databases/Replication%20and%20Failover/Database%20Replication.md)

## Revision Summary

Consistency is a spectrum, not a binary. Session guarantees (read-your-writes, monotonic reads) address what users actually perceive at a fraction of the cost of linearizability. LWW silently drops concurrent writes.

## Quick Recall

- Linearizable → sequential → causal → session → eventual
- Session consistency solves most perceived bugs cheaply
- `R + W > N` gives strong consistency in a quorum system
- LWW loses data; CRDTs converge safely
- Replication lag causes read-after-write and monotonic-read bugs
