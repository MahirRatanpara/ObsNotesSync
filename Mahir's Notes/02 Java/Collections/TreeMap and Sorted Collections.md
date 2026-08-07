# TreeMap and Sorted Collections

## Why It Matters

The underused half of the collections framework. Range queries, floor/ceiling lookups, and ordered iteration are things hash-based structures simply cannot do — and several classic interview problems reduce to them.

## What TreeMap Is

A **red-black tree** — a self-balancing binary search tree.

| Operation | Complexity |
|---|---|
| `get` / `put` / `remove` | **O(log n)** |
| `firstKey` / `lastKey` | O(log n) |
| `floorKey` / `ceilingKey` | **O(log n)** |
| `subMap` / `headMap` / `tailMap` | O(log n) to locate, then iterate |
| Ordered iteration | **O(n), already sorted** |

**Red-black invariants** (worth knowing at a high level, rarely more):
- Every node is red or black; the root is black
- No red node has a red child
- Every root-to-leaf path has the same number of black nodes

These guarantee the longest path is at most twice the shortest, so height is O(log n).

**Why red-black rather than AVL:** red-black rebalances less aggressively, so it's faster for insert-heavy workloads at the cost of slightly deeper trees. AVL is better for read-heavy. The JDK chose red-black for the general case.

## The Navigation API — The Real Value

This is what makes `TreeMap` worth reaching for.

| Method | Returns |
|---|---|
| **`floorKey(k)`** | Greatest key **≤ k** |
| **`ceilingKey(k)`** | Smallest key **≥ k** |
| `lowerKey(k)` | Greatest key **< k** (strict) |
| `higherKey(k)` | Smallest key **> k** (strict) |
| `firstKey()` / `lastKey()` | Extremes |
| `pollFirstEntry()` / `pollLastEntry()` | Remove and return |
| **`subMap(from, to)`** | **View** of a range |
| `headMap(k)` / `tailMap(k)` | Everything before / after |
| `descendingMap()` | Reversed **view** |

**These are views, not copies.** Changes write through in both directions, and the view is bounded — inserting outside the range throws `IllegalArgumentException`.

**Mnemonic:** *floor* is below you, *ceiling* is above you. *Lower*/*higher* are the strict versions.

## What It Solves That HashMap Cannot

```java
// "What was the price at or before this timestamp?"
TreeMap<Long, BigDecimal> prices = new TreeMap<>();
prices.floorEntry(timestamp);           // most recent price at or before

// "Which meetings overlap this range?"
TreeMap<LocalTime, Meeting> calendar = new TreeMap<>();
calendar.subMap(start, true, end, false);

// "What's the next available slot?"
calendar.ceilingKey(desiredTime);
```

**Any question containing "nearest", "before", "after", "between", or "next" is a `TreeMap` question.** Recognising that is the interview signal.

## The Ordered Multiset Idiom

`TreeMap<T, Integer>` as a counting multiset — the answer to several hard problems:

```java
TreeMap<Integer, Integer> counts = new TreeMap<>();

counts.merge(x, 1, Integer::sum);                            // add
if (counts.merge(x, -1, Integer::sum) == 0) counts.remove(x); // remove — MUST clean up
int max = counts.lastKey();
int min = counts.firstKey();
```

**Removing the zero-count entry is essential.** Leave it and `firstKey`/`lastKey` return values that are no longer present.

**Why this beats a heap:** a `PriorityQueue` gives O(1) access to *one* end and cannot remove an arbitrary element in less than O(n). A `TreeMap` gives both ends **and** O(log n) arbitrary removal.

**This is the structure for "sliding window maximum with arbitrary removal", "Longest Continuous Subarray with Absolute Diff ≤ Limit", and "Sliding Window Median".** See [Monotonic Queue](../../01%20DSA/Stacks%20and%20Queues/Monotonic%20Queue.md) for the O(n) alternative when only the window extremes are needed.

## TreeSet

`TreeSet` is a `TreeMap` with a dummy value. Same API, same complexity, same navigation methods (`floor`, `ceiling`, `lower`, `higher`, `subSet`, `headSet`, `tailSet`).

**`TreeSet` uses `compareTo`, not `equals`, for membership.** Two elements comparing equal are the *same* element to a `TreeSet`, even if `equals` says otherwise — the [BigDecimal trap](Comparable%20and%20Comparator.md).

## Comparison

| | `HashMap` | `LinkedHashMap` | **`TreeMap`** |
|---|---|---|---|
| Order | None | Insertion or **access** | **Sorted by key** |
| get/put | **O(1)** avg | **O(1)** avg | O(log n) |
| Range queries | **No** | No | **Yes** |
| Null key | One | One | **No** |
| Memory | Lower | +2 refs/node | Tree node overhead |

**`TreeMap` rejects null keys** — it must call `compareTo` on them. `HashMap` allows exactly one null key (bucket 0, special-cased).

**Use `TreeMap` only when you need ordering.** O(log n) with pointer-chasing is meaningfully slower than O(1) array indexing; don't pay it for nothing.

## PriorityQueue — The Other Ordered Structure

A **binary heap** in an array, not a sorted structure.

| Operation | Complexity |
|---|---|
| `peek` | **O(1)** |
| `offer` / `poll` | O(log n) |
| `remove(Object)` | **O(n)** — linear scan |
| `contains` | O(n) |
| Heapify from a collection | **O(n)** |

**Critical: iteration order is NOT sorted.** Only `poll()` returns elements in order. Printing a `PriorityQueue` shows heap array order, which surprises people constantly.

**`remove(Object)` is O(n).** In a loop that silently makes your solution O(n²). Use **lazy deletion** — mark entries stale and skip them on `poll` — or a `TreeMap` if you need arbitrary removal.

**Building from a collection is O(n), not O(n log n)**, because heapify works bottom-up. `new PriorityQueue<>(list)` is cheaper than n inserts.

## Choosing

| Need | Structure |
|---|---|
| Key lookup only | `HashMap` |
| Insertion order | `LinkedHashMap` |
| **LRU cache** | `LinkedHashMap` access-order |
| **Range / nearest-key queries** | **`TreeMap`** |
| **Ordered multiset with removal** | **`TreeMap<T,Integer>`** |
| Repeated min or max only | `PriorityQueue` |
| **Top-K** | `PriorityQueue` of size k |
| Streaming median | **Two heaps** |
| Window min **and** max | Two monotonic deques, or a `TreeMap` |

## ConcurrentSkipListMap

The concurrent sorted map. A **skip list** rather than a tree — probabilistic balancing via randomised level assignment.

**Why a skip list and not a red-black tree:** rebalancing a tree requires locking multiple nodes; a skip list can be updated with lock-free CAS operations on individual pointers. **Concurrency is the reason**, not performance in the single-threaded case.

Same `NavigableMap` API, O(log n) expected, fully concurrent and non-blocking.

Redis uses skip lists for sorted sets for the same reason.

## Common Mistakes

- Expecting `PriorityQueue` iteration to be sorted
- `PriorityQueue.remove(Object)` in a loop — silently O(n²)
- Forgetting to remove zero-count entries from a `TreeMap` multiset
- Using `TreeMap` when a `HashMap` would do
- Null keys in a `TreeMap`
- Assuming `TreeSet` membership uses `equals`
- **Mutating an object while it's a key in a `TreeMap`** — it becomes unreachable, exactly like a mutated `HashMap` key
- Missing that `subMap` returns a bounded, write-through view

## Related Topics

- [Comparable and Comparator](Comparable%20and%20Comparator.md)
- [HashMap Internals](HashMap%20Internals.md)
- [Heaps and Priority Queues](../../01%20DSA/Heaps/Heaps%20and%20Priority%20Queues.md)
- [Collections Overview](Collections%20Overview.md)

## Revision Summary

`TreeMap` is a red-black tree giving O(log n) operations plus the navigation API — floor, ceiling, subMap — that hash structures cannot provide. Used as `TreeMap<T,Integer>` it becomes an ordered multiset supporting both extremes and arbitrary O(log n) removal, which a heap cannot. `PriorityQueue` is a heap: O(1) peek, unsorted iteration, O(n) arbitrary removal.

## Quick Recall

- Red-black tree, **O(log n)**; height bounded by the black-height invariant
- **`floorKey` ≤ k, `ceilingKey` ≥ k**; `lower`/`higher` are strict
- `subMap`/`headMap` are **bounded write-through views**
- **"nearest / before / after / between / next" → `TreeMap`**
- `TreeMap<T,Integer>` multiset: **remove the entry at count zero**
- **`TreeSet` membership uses `compareTo`, not `equals`**
- No null keys in `TreeMap`
- **`PriorityQueue` iteration is not sorted**; `remove(Object)` is O(n)
- Heapify from a collection is O(n)
- `ConcurrentSkipListMap` uses a skip list because it's **CAS-friendly**
