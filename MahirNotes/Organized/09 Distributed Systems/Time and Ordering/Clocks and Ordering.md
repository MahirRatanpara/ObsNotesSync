# Clocks and Ordering

## Why It Matters

"Just use timestamps" is the wrong answer to almost every distributed ordering question, and interviewers know it. Understanding why separates candidates who have operated distributed systems from those who haven't.

## Why Wall Clocks Fail

| Problem | Detail |
|---|---|
| **Clock skew** | NTP-synced machines still differ by milliseconds; unsynced by seconds or more |
| **Clocks go backwards** | NTP corrections, leap seconds, VM migration |
| **Different granularity** | Two events in the same millisecond are indistinguishable |
| **Untrustworthy sources** | Client clocks can be wrong or deliberately falsified |

**Consequence:** an event with a *later* timestamp may have happened *earlier*. Last-write-wins conflict resolution built on wall clocks silently loses data.

**Never order distributed events by client timestamps.** This is the practical takeaway.

## Monotonic vs Wall Clock

| | Wall clock | Monotonic clock |
|---|---|---|
| Java | `System.currentTimeMillis()` | `System.nanoTime()` |
| Can go backwards | **Yes** | No |
| Meaningful across machines | Yes (roughly) | **No** |
| Use for | Timestamps, display | **Measuring elapsed time** |

**Measuring a duration with `currentTimeMillis()` is a real bug** — an NTP correction mid-measurement produces a negative or wildly wrong duration. Always use `nanoTime()` for elapsed time.

## Lamport Timestamps

A logical counter that captures **causality**, not real time.

```
1. Each process keeps a counter L
2. Before any event:        L = L + 1
3. When sending:            attach L
4. On receiving with L_msg: L = max(L, L_msg) + 1
```

**Guarantee:** if A happened-before B, then `L(A) < L(B)`.

**The limitation:** the converse doesn't hold. `L(A) < L(B)` does **not** mean A caused B — they may be concurrent. Lamport timestamps give a total order but can't distinguish causality from coincidence.

## Vector Clocks

Each node tracks a counter **per node**: `[A:2, B:5, C:1]`.

| Comparison | Meaning |
|---|---|
| Every element of V1 ≤ V2, and at least one is strictly less | **V1 happened-before V2** |
| Every element of V1 ≥ V2 | V2 happened-before V1 |
| **Neither** — some greater, some lesser | **Concurrent — a genuine conflict** |

**Vector clocks can detect concurrency; Lamport timestamps cannot.** That's the whole reason they exist.

**Used by:** DynamoDB (originally), Riak, and CRDT implementations to identify conflicting writes and surface siblings to the application.

**Cost:** the vector grows with the number of nodes, and pruning entries for departed nodes is genuinely awkward. This is why DynamoDB moved away from exposing them.

## Hybrid Logical Clocks

Combine physical time with a logical counter: close to wall-clock time (so timestamps are human-meaningful and comparable across systems) while preserving causality.

Used by CockroachDB and MongoDB. **A good thing to name** when asked "how do you get ordered timestamps in a distributed database?"

## TrueTime — Google Spanner

Spanner's approach is different and worth knowing: GPS receivers and atomic clocks in every datacentre give an API returning a bounded **interval** `[earliest, latest]` rather than a point.

To commit, Spanner **waits out the uncertainty** (typically ~7 ms) before acknowledging. This guarantees that any transaction starting later gets a strictly later timestamp — delivering **external consistency**, the strongest guarantee available.

**Spanner buys global consistency with hardware and deliberate latency.** That trade is the interesting part, and it's why most systems don't do this.

## Snowflake IDs — The Practical Answer

For most systems, you need IDs that are unique, roughly time-ordered, and require no coordination:

```
[ 41 bits: timestamp ][ 10 bits: machine ID ][ 12 bits: sequence ]
```

- 41 bits of milliseconds ≈ 69 years
- 1,024 machines
- 4,096 IDs per machine per millisecond

**Properties:** sortable by time, no coordination, compact (fits in a `long`).

**The clock-going-backwards hazard:** if the machine clock rewinds, Snowflake can generate duplicate IDs. Production implementations detect this and either wait or refuse to issue IDs until the clock catches up.

**Snowflake is the answer to "how do you generate ordered unique IDs at scale?"**

## Choosing An Approach

| Requirement | Use |
|---|---|
| Measure elapsed time | Monotonic clock |
| Unique, roughly ordered IDs | **Snowflake** |
| Detect concurrent conflicting writes | **Vector clocks** |
| Total order without causality detection | Lamport timestamps |
| Human-meaningful ordered timestamps in a distributed DB | Hybrid logical clocks |
| Global external consistency | TrueTime / Spanner (specialised hardware) |
| Order within one entity | **Partition by entity, use a sequence** |

**The last row is the pragmatic answer most systems use.** Route all events for an entity through one partition and let the log's offset define the order — no clocks required.

## Common Mistakes

- Ordering distributed events by client timestamps
- Using `currentTimeMillis()` to measure durations
- Last-write-wins without acknowledging silent data loss
- Assuming NTP makes clocks identical
- Claiming vector clocks resolve conflicts — they only **detect** them; resolution is application logic
- Snowflake without clock-rewind handling

## Related Topics

- [Consistency Models](../Consistency/Consistency%20Models.md)
- [Consensus Algorithms](../Consensus/Consensus%20Algorithms.md)
- [Two Generals Problem](../Theory/Two%20Generals%20Problem.md)
- [Kafka Deep Dive](../../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md)

## Revision Summary

Wall clocks skew and move backwards, so they cannot order distributed events. Lamport timestamps preserve causality but can't detect concurrency; vector clocks can, at the cost of size. Snowflake IDs give coordination-free time-sortable identifiers, and partitioning by entity gives ordering without clocks at all.

## Quick Recall

- Never order by client timestamps
- `nanoTime()` for durations, `currentTimeMillis()` for wall time
- Lamport: preserves causality, can't detect concurrency
- Vector clocks: **detect** concurrent writes (don't resolve them)
- Snowflake = timestamp + machine + sequence; watch clock rewind
- Spanner buys external consistency with atomic clocks and commit-wait
- Simplest real answer: partition by entity, use the log offset
