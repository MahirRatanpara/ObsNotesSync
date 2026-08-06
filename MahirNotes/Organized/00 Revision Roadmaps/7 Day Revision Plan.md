# 7-Day Revision Plan

> One week, ~6 focused hours per day. Assumes prior exposure — this is revision, not first learning.

## Allocation

| Area | Share | Rationale |
|---|---|---|
| DSA | 40% | Highest volume, most rounds |
| System design (HLD) | 25% | Differentiates at SDE-2+ |
| LLD | 15% | Often a separate round |
| Java / language depth | 15% | Backend rounds |
| Behavioural | 5% | Cheap to prepare, expensive to fail |

## Day 1 — DSA Foundations + Patterns

| Time | Task |
|---|---|
| 2h | [Pattern Recognition Framework](../01%20DSA/Foundations/Pattern%20Recognition%20Framework.md), [Pattern Confusion Matrix](../01%20DSA/Foundations/Pattern%20Confusion%20Matrix.md), [Complexity Analysis](../01%20DSA/Foundations/Complexity%20Analysis.md) |
| 2h | [Two Pointers](../01%20DSA/Two%20Pointers%20and%20Sliding%20Window/Two%20Pointers.md), [Sliding Window](../01%20DSA/Two%20Pointers%20and%20Sliding%20Window/Sliding%20Window.md), [Prefix Sum](../01%20DSA/Arrays%20and%20Strings/Prefix%20Sum.md) — 6 problems |
| 1h | [Binary Search Templates](../01%20DSA/Binary%20Search/Binary%20Search%20Templates.md), [Binary Search on Answer](../01%20DSA/Binary%20Search/Binary%20Search%20on%20Answer.md) — 3 problems |
| 1h | Classification drill: 20 problems, pattern only, no coding |

## Day 2 — Trees, Graphs, Heaps

| Time | Task |
|---|---|
| 2h | [Tree Traversals](../01%20DSA/Trees/Tree%20Traversals.md), [Lowest Common Ancestor](../01%20DSA/Trees/Lowest%20Common%20Ancestor.md) — 5 problems |
| 2h | [BFS and DFS](../01%20DSA/Graphs/BFS%20and%20DFS.md), [Graph Algorithm Selection](../01%20DSA/Graphs/Graph%20Algorithm%20Selection.md), [Topological Sort](../01%20DSA/Graphs/Topological%20Sort.md) — 5 problems |
| 1h | [Heaps and Priority Queues](../01%20DSA/Heaps/Heaps%20and%20Priority%20Queues.md), [Union Find](../01%20DSA/Union%20Find/Union%20Find.md) — 3 problems |
| 1h | Mixed review of Day 1 |

## Day 3 — DP, Backtracking, Stacks

| Time | Task |
|---|---|
| 2.5h | [Dynamic Programming Fundamentals](../01%20DSA/Dynamic%20Programming/Dynamic%20Programming%20Fundamentals.md), [Knapsack Patterns](../01%20DSA/Dynamic%20Programming/Knapsack%20Patterns.md) — 6 problems |
| 1.5h | [Backtracking](../01%20DSA/Backtracking/Backtracking.md) — 4 problems |
| 1h | [Monotonic Stack](../01%20DSA/Stacks%20and%20Queues/Monotonic%20Stack.md), [Monotonic Queue](../01%20DSA/Stacks%20and%20Queues/Monotonic%20Queue.md) — 3 problems |
| 1h | [Intervals](../01%20DSA/Greedy%20and%20Intervals/Intervals.md), [Greedy Algorithms](../01%20DSA/Greedy%20and%20Intervals/Greedy%20Algorithms.md) |

## Day 4 — Java Depth

| Time | Task |
|---|---|
| 1.5h | [Java Memory Model](../02%20Java/JVM%20and%20Memory/Java%20Memory%20Model.md), [JVM Architecture](../02%20Java/JVM%20and%20Memory/JVM%20Architecture%20and%20Memory%20Areas.md) |
| 1h | [Garbage Collection](../02%20Java/Garbage%20Collection/Garbage%20Collection.md), [JIT and Escape Analysis](../02%20Java/JVM%20and%20Memory/JIT%20and%20Escape%20Analysis.md) |
| 1.5h | [HashMap Internals](../02%20Java/Collections/HashMap%20Internals.md), [Collections Overview](../02%20Java/Collections/Collections%20Overview.md) |
| 2h | [Synchronisation and Locks](../02%20Java/Concurrency/Synchronisation%20and%20Locks.md), [Executors](../02%20Java/Concurrency/Executors%20and%20Thread%20Pools.md), [CompletableFuture](../02%20Java/Concurrency/CompletableFuture.md), [Atomics and CAS](../02%20Java/Concurrency/Atomics%20and%20CAS.md) |

## Day 5 — HLD

| Time | Task |
|---|---|
| 1h | [System Design Delivery Framework](../04%20High%20Level%20Design/Interview%20Framework/System%20Design%20Delivery%20Framework.md) |
| 1.5h | [CAP and PACELC](../04%20High%20Level%20Design/Core%20Concepts/CAP%20and%20PACELC.md), [Consistency Models](../09%20Distributed%20Systems/Consistency/Consistency%20Models.md), [Consensus Algorithms](../09%20Distributed%20Systems/Consensus/Consensus%20Algorithms.md) |
| 1.5h | [Caching](../04%20High%20Level%20Design/Core%20Concepts/Caching.md), [Database Indexing](../05%20Databases/Indexing/Database%20Indexing.md) |
| 2h | **Two timed designs, 45 min each:** URL shortener, then a news feed. Whiteboard, out loud. |

## Day 6 — LLD + Messaging + Resilience

| Time | Task |
|---|---|
| 1h | [LLD Delivery Framework](../03%20Low%20Level%20Design/In%20A%20Hurry/LLD%20Delivery%20Framework.md), [SOLID Principles](../03%20Low%20Level%20Design/SOLID/SOLID%20Principles.md) |
| 1h | [Design Pattern Selection](../03%20Low%20Level%20Design/Design%20Patterns/Design%20Pattern%20Selection.md) |
| 1.5h | **Two timed LLD designs, 35 min each:** parking lot, then a rate limiter |
| 1.5h | [Kafka Deep Dive](../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md), [Idempotent Consumers](../07%20Messaging%20and%20Kafka/Reliability%20Patterns/Idempotent%20Consumers.md) |
| 1h | [Circuit Breaker](../08%20Microservices/Circuit%20Breaker.md), [Two Generals Problem](../09%20Distributed%20Systems/Theory/Two%20Generals%20Problem.md) |

## Day 7 — Mock + Consolidate

| Time | Task |
|---|---|
| 1.5h | Full mock: 1 DSA (45 min) + 1 system design (45 min), timed, out loud, ideally with a person |
| 1h | Review every mistake from the mock; write them into a personal traps list |
| 1.5h | Reread all four cheat sheets |
| 1h | Rehearse 6 STAR stories aloud |
| 1h | Weak-area targeted practice, based on the mock |

## Daily Habits

- **Always speak out loud.** Silent practice does not transfer.
- Log every problem: pattern, whether you classified it correctly, time taken.
- Review misclassifications — those are the highest-value fixes.
- Stop on time. Fatigue produces false confidence.

## Related

- [1 Day Emergency Revision](1%20Day%20Emergency%20Revision.md)
- [DSA Cheat Sheet](../Cheat%20Sheets/DSA%20Cheat%20Sheet.md)
- [HLD Cheat Sheet](../Cheat%20Sheets/HLD%20Cheat%20Sheet.md)
