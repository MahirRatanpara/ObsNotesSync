# Concurrent Collections

## Why It Matters

Choosing the right concurrent structure is usually better than writing your own synchronisation. Interviewers check whether you reach for the library first.

## The Selection Table

| Need | Use | Mechanism |
|---|---|---|
| Concurrent map | `ConcurrentHashMap` | CAS + per-bin lock |
| Sorted concurrent map | `ConcurrentSkipListMap` | Lock-free skip list |
| Read-mostly list | `CopyOnWriteArrayList` | Copy on every write |
| Producer-consumer, bounded | `ArrayBlockingQueue` | One lock + conditions |
| Producer-consumer, unbounded | `LinkedBlockingQueue` | Separate head/tail locks |
| Direct handoff | `SynchronousQueue` | Zero capacity |
| Priority + blocking | `PriorityBlockingQueue` | Heap + lock |
| Scheduled delivery | `DelayQueue` | Delay-ordered heap |
| High-throughput, non-blocking | `ConcurrentLinkedQueue` | Michael-Scott lock-free |
| Work stealing | `LinkedBlockingDeque` | Both-ends access |

## ConcurrentHashMap

**Java 7:** segment locking — the map was split into 16 segments, each with its own lock.

**Java 8+:** no segments. Per-**bin** synchronisation:
- Empty bin → insert with a **CAS**, no lock at all
- Non-empty bin → `synchronized` on the **first node** of that bin only
- Bins treeify at 8 entries, exactly like `HashMap`
- `size()` uses a `LongAdder`-style counter array, so it's approximate under concurrent modification

Result: concurrency scales with the number of bins, not a fixed segment count.

### Atomic Compound Operations

```java
map.putIfAbsent(k, v);
map.computeIfAbsent(k, key -> expensiveInit(key));   // atomic — runs once
map.merge(k, 1, Integer::sum);                       // atomic counter increment
map.compute(k, (key, old) -> old == null ? 1 : old + 1);
```

**These replace check-then-act races:**
```java
if (!map.containsKey(k)) map.put(k, v);   // RACE — two threads can both pass the check
map.putIfAbsent(k, v);                    // atomic
```

**Deadlock warning:** the mapping function in `computeIfAbsent` runs while holding the bin lock. Never modify the same map inside it, and never perform blocking I/O there.

### No Nulls

`ConcurrentHashMap` rejects null keys and values, because `get(k) == null` would be ambiguous between "absent" and "mapped to null", and you cannot resolve it with `containsKey` without a race.

## CopyOnWriteArrayList

Every mutation copies the entire backing array.

| | Cost |
|---|---|
| Read | O(1), **no locking at all** |
| Write | O(n) copy under a lock |
| Iteration | Snapshot — never throws `ConcurrentModificationException` |

Use for **listener/observer registries**: many reads (every event), rare writes (registration). Never for write-heavy workloads.

Iterators are snapshots and **do not support `remove()`**.

## BlockingQueue — The Four Method Families

| | Throws | Returns special | Blocks | Times out |
|---|---|---|---|---|
| Insert | `add` | `offer` | **`put`** | `offer(e, t, u)` |
| Remove | `remove` | `poll` | **`take`** | `poll(t, u)` |
| Examine | `element` | `peek` | — | — |

**Producer-consumer needs `put`/`take`** — they block, providing natural backpressure. Using `offer`/`poll` silently drops or spins.

```java
BlockingQueue<Task> q = new ArrayBlockingQueue<>(1000);   // BOUNDED

// producer
q.put(task);        // blocks when full → slows the producer

// consumer
Task t = q.take();  // blocks when empty → no busy-wait
```

**A bounded queue is the entire point.** Unbounded queues convert a throughput problem into an OOM.

### Poison Pill Shutdown

```java
static final Task POISON = new Task();
// producer, when done:
for (int i = 0; i < consumerCount; i++) q.put(POISON);
// consumer:
while (true) { Task t = q.take(); if (t == POISON) break; process(t); }
```

## Synchronisation Utilities

| Utility | Purpose | Reusable |
|---|---|---|
| `CountDownLatch` | Wait for N events, one-shot gate | **No** |
| `CyclicBarrier` | N threads meet, then all proceed | **Yes** |
| `Semaphore` | Limit concurrent access to N permits | Yes |
| `Phaser` | Flexible multi-phase barrier | Yes |
| `Exchanger` | Two threads swap objects | Yes |

**`CountDownLatch` vs `CyclicBarrier`** is a standard question:
- Latch: one or more threads wait for *others* to finish; counts **down**; cannot be reset
- Barrier: threads wait for *each other*; resets automatically; supports a barrier action

**Semaphore for rate limiting / resource pools:**
```java
Semaphore permits = new Semaphore(10);
permits.acquire();
try { useConnection(); } finally { permits.release(); }   // release in finally
```

## Common Mistakes

- `Collections.synchronizedMap` instead of `ConcurrentHashMap` — one global lock
- Check-then-act instead of `putIfAbsent` / `merge`
- Blocking I/O inside `computeIfAbsent`
- `CopyOnWriteArrayList` for write-heavy data
- Unbounded `LinkedBlockingQueue` in a producer-consumer pipeline
- `release()` outside a `finally` block, permanently leaking permits

## Related Topics

- [HashMap Internals](../Collections/HashMap%20Internals.md)
- [Atomics and CAS](Atomics%20and%20CAS.md)
- Concurrency Problem Patterns *(not yet written)*

## Revision Summary

ConcurrentHashMap uses CAS for empty bins and per-bin locks otherwise. Use its atomic compound operations instead of check-then-act. BlockingQueue with `put`/`take` and a bounded capacity gives correct producer-consumer backpressure.

## Quick Recall

- CHM: CAS on empty bin, `synchronized` on the first node otherwise
- `merge` / `computeIfAbsent` are atomic — use them
- No nulls in CHM
- COWList = read-mostly listener lists only
- `put`/`take` block; bounded queue = backpressure
- Latch counts down once; barrier resets
