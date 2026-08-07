# CRDTs and Conflict Resolution

## Why It Matters

In any multi-writer system — multi-leader replication, offline-capable apps, collaborative editing — concurrent writes conflict. How you resolve them determines whether data is silently lost.

## The Problem

```
Replica A: set price = 100
Replica B: set price = 120        (concurrent, no coordination)
→ replicas converge to... which?
```

Vector clocks can **detect** that these were concurrent. Detection is not resolution — something must decide.

## Resolution Strategies

| Strategy | Behaviour | Risk |
|---|---|---|
| **Last-Write-Wins** | Highest timestamp wins | **Silent data loss**; depends on clock sync |
| **Multi-value / siblings** | Return both, let the application choose | Pushes complexity to the caller |
| **Application merge** | Domain-specific logic | Most work, best results |
| **CRDTs** | **Mathematically guaranteed convergence** | Limited to specific data types |
| Reject concurrent writes | Use consensus instead | Loses availability |

### Last-Write-Wins — Know Its Cost

The default in **Cassandra** and **DynamoDB global tables**.

```
A writes price=100 at t=1000
B writes price=120 at t=1001
→ 120 wins; A's write is SILENTLY DISCARDED
```

**Two problems:**

1. **Data loss is silent** — no error, no sibling, no record that a write was dropped
2. **Clock skew decides the winner** — the "later" write may have happened first in real time

**LWW is acceptable when writes are naturally idempotent or last-value-wins is semantically correct** (a status field, a cached value). It is **not** acceptable for anything cumulative — counters, shopping carts, balances.

**Saying "Cassandra uses LWW, which silently loses concurrent writes" is a strong signal** — it shows you know the trade-off, not just the label.

## CRDTs — Convergence Without Coordination

**Conflict-free Replicated Data Types** are structures whose merge operation is:

- **Commutative** — `merge(a,b) = merge(b,a)`
- **Associative** — grouping doesn't matter
- **Idempotent** — `merge(a,a) = a`

**Given those three properties, replicas converge regardless of message order, duplication, or delay** — no coordination, no conflict resolution logic, no data loss.

**That is the whole idea, and it's worth stating precisely.** The mathematics does what a coordination protocol would otherwise have to.

### Two Families

| | **State-based (CvRDT)** | **Operation-based (CmRDT)** |
|---|---|---|
| Ships | The full state | The operation |
| Merge | Join of two states | Apply the operation |
| Requires | Nothing — idempotent merge | **Exactly-once, causally-ordered delivery** |
| Bandwidth | Higher | Lower |

State-based is more robust (duplicates and reordering are harmless); operation-based is more efficient but needs delivery guarantees.

### The Common CRDTs

| Type | Behaviour |
|---|---|
| **G-Counter** | Grow-only; per-replica counts, merge by max, value = sum |
| **PN-Counter** | Two G-Counters (increments, decrements); supports decrement |
| **G-Set** | Grow-only set; merge = union |
| **2P-Set** | Add and remove, but **an element removed can never be re-added** |
| **LWW-Register** | Single value with a timestamp — LWW, so still lossy |
| **OR-Set** | Add/remove with unique tags — **add wins on concurrent add/remove** |
| **RGA / Logoot** | Ordered sequences for collaborative text |

**G-Counter is the clearest example:**

```
Replica A: [A:5, B:0, C:0]
Replica B: [A:0, B:3, C:0]
merge → element-wise max → [A:5, B:3, C:0] → value = 8
```

Merge by max is commutative, associative, and idempotent. **Replaying the same merge changes nothing**, so duplicate delivery is harmless.

### Why Naive Sets Don't Work

```
A: add(x), then remove(x)
B: add(x)          (concurrent)
→ is x in the set?
```

**2P-Set** answers "no, permanently" — once removed, never re-addable. Often wrong.
**OR-Set** tags each add uniquely; a remove only cancels the tags it observed, so B's concurrent add survives. **Add-wins semantics.**

**This is the standard illustration of why CRDT design is subtle** — the "obvious" set doesn't behave sensibly.

## The Shopping Cart Example

The canonical case, from Amazon's Dynamo paper.

**With LWW:** two devices modify the cart concurrently; one device's additions vanish silently. Amazon considered lost cart items unacceptable.

**With an OR-Set:** merging is a union of adds minus observed removes — **items are never silently lost**. The failure mode inverts: a removed item may reappear.

**Amazon chose reappearing items over vanishing items**, because a customer removing something twice is a minor annoyance while a lost purchase is lost revenue.

**That reasoning — choosing which failure mode you prefer — is the interview-worthy insight.** CRDTs don't eliminate anomalies; they let you choose a benign one.

## Where CRDTs Are Used

| System | Use |
|---|---|
| **Riak** | Native CRDT data types |
| **Redis Enterprise** | Active-active geo-replication |
| **Automerge / Yjs** | Collaborative document editing |
| Figma, Linear | Real-time multiplayer state |
| Azure Cosmos DB | Multi-region conflict resolution |
| SoundCloud, Bet365 | Distributed counters |

## Limitations

| Limitation | Detail |
|---|---|
| **Metadata growth** | Tombstones and tags accumulate; garbage collection is genuinely hard |
| **Limited operations** | No "set to exactly X", no global invariants |
| **Cannot enforce constraints** | "Inventory ≥ 0" is impossible without coordination |
| Semantics may surprise users | Reappearing items, unusual merge outcomes |

**The hard constraint: CRDTs cannot enforce a global invariant.** If two replicas each sell the last item, both succeed and the merge produces −1 stock. **Anything requiring a global limit needs coordination** — consensus, or a single writer for that key.

**This is the boundary to state clearly:** CRDTs give availability and convergence, not correctness against invariants.

## Operational Transformation — The Alternative

Used by Google Docs. Transforms concurrent operations against each other to preserve intent.

| | OT | CRDT |
|---|---|---|
| Requires a central server | **Usually yes** | **No** |
| Metadata | Low | Higher |
| Implementation | Notoriously hard to get right | Complex but composable |
| Peer-to-peer | Difficult | **Natural** |

**Newer systems favour CRDTs** because they work without a central coordinator. Google Docs predates practical CRDTs.

## Choosing

| Situation | Approach |
|---|---|
| Single writer per key | **No conflict** — best answer where achievable |
| Status field, cache value | LWW is fine |
| Counters, sets, carts | **CRDT** |
| Collaborative text | RGA / Yjs / Automerge |
| Global invariant required | **Consensus or a single writer** — not CRDTs |
| Complex domain rules | Application merge with siblings |

**Partitioning so each key has one writer eliminates the problem entirely** — always ask whether that's possible before reaching for conflict resolution.

## Common Mistakes

- LWW for cumulative data — silent loss
- Assuming vector clocks *resolve* conflicts (they only detect)
- Expecting CRDTs to enforce invariants
- Ignoring tombstone and metadata growth
- 2P-Set where OR-Set semantics are needed
- Not asking whether single-writer partitioning is possible
- Trusting clocks for LWW ordering

## Related Topics

- [Consistency Models](Consistency%20Models.md)
- [Clocks and Ordering](Clocks%20and%20Ordering.md)
- [CAP and PACELC](CAP%20and%20PACELC.md)
- [Cassandra](Cassandra.md)

## Revision Summary

Concurrent writes must be resolved somehow: LWW is simple and silently lossy, siblings push work to the application, and CRDTs converge automatically because their merge is commutative, associative, and idempotent. CRDTs cannot enforce global invariants — that still requires coordination. Single-writer partitioning avoids the problem entirely.

## Quick Recall

- **LWW silently drops concurrent writes** — Cassandra, DynamoDB global tables
- CRDT merge: **commutative, associative, idempotent** → convergence guaranteed
- G-Counter merges by per-replica max, sums for the value
- **OR-Set: add wins**; 2P-Set can never re-add
- Amazon's cart chose reappearing items over lost items
- Vector clocks **detect**, they don't resolve
- **CRDTs cannot enforce invariants** — inventory ≥ 0 needs coordination
- Single writer per key beats all conflict resolution
