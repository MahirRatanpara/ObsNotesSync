# Specialised Collections

## Why It Matters

The collections most people never reach for, each of which is dramatically better than the general-purpose alternative in its niche. Knowing when to use `EnumMap` over `HashMap` is a small, cheap signal of depth.

## EnumMap and EnumSet

**Not hash-based at all.**

| | Implementation | Consequence |
|---|---|---|
| **`EnumMap`** | A plain **array indexed by `ordinal()`** | No hashing, no collisions, no `Node` objects |
| **`EnumSet`** | A **bit vector** — a single `long` for ≤64 constants | Set operations are single CPU instructions |

```java
EnumMap<Day, Schedule> byDay = new EnumMap<>(Day.class);   // needs the Class token
EnumSet<Day> weekend  = EnumSet.of(SATURDAY, SUNDAY);
EnumSet<Day> weekdays = EnumSet.complementOf(weekend);
EnumSet<Day> all      = EnumSet.allOf(Day.class);
EnumSet<Day> none     = EnumSet.noneOf(Day.class);
EnumSet<Day> range    = EnumSet.range(MONDAY, FRIDAY);
```

**`EnumSet.contains` is a bit test; `HashSet.contains` hashes and probes.** For 64 or fewer constants an entire set fits in one `long`, so union and intersection are `|` and `&`.

**Both maintain natural (declaration) order** on iteration, which `HashMap`/`HashSet` do not.

**Always use these for enum keys.** It's strictly better and costs nothing.

**The `Class` token is required** because `EnumMap` must know how many constants exist to size its array.

## WeakHashMap

Keys are held by **weak references**, so entries vanish when the key becomes unreachable elsewhere.

```java
Map<ClassLoader, Metadata> perLoader = new WeakHashMap<>();
```

**Two traps:**

1. **Values are strongly held.** If a value references its key, the entry is immortal:
```java
weakMap.put(key, new Holder(key));   // never collected
```
Wrap the value in a `WeakReference` if it must reference the key.

2. **String literals and interned strings are never collected**, so `WeakHashMap<String, ...>` with literal keys behaves like a normal map.

**Legitimate use:** associating metadata with objects you don't own and whose lifetime you don't control — classloader data, listener registries, canonicalising maps.

**Not a cache.** There's no eviction policy and no size bound; entries disappear on GC timing, which you don't control. Use Caffeine.

## IdentityHashMap

Uses **reference equality (`==`)** instead of `equals`, and `System.identityHashCode` instead of `hashCode`.

```java
Map<Object, String> seen = new IdentityHashMap<>();
seen.put(new String("a"), "1");
seen.put(new String("a"), "2");
seen.size();                    // 2 — equal but not identical
```

**Uses:** cycle detection in object-graph traversal (serialisation, deep copy, `toString` of recursive structures), and any place where two `equals` objects must be treated as distinct.

**Also correct when the key's `equals` is expensive or broken**, or where the key is mutable and its `hashCode` would drift.

**Uses linear probing rather than chaining** — an implementation detail that shows up as different iteration characteristics.

## LinkedHashMap

`HashMap` plus a doubly-linked list threading all entries.

```java
new LinkedHashMap<>();                          // insertion order
new LinkedHashMap<>(16, 0.75f, true);           // ACCESS order
```

**Access-order mode plus `removeEldestEntry` gives an LRU cache in five lines:**

```java
new LinkedHashMap<K, V>(capacity, 0.75f, true) {
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity;
    }
};
```

**Cost: two extra pointers per entry.** Worth it when you need predictable iteration order.

**Note:** in access-order mode, even `get()` is a structural modification for iteration purposes — so iterating while calling `get` throws `ConcurrentModificationException`.

## Legacy — Do Not Use

| Class | Problem | Replacement |
|---|---|---|
| **`Vector`** | `synchronized` on every method | `ArrayList`, or `CopyOnWriteArrayList` |
| **`Stack`** | Extends `Vector`; **iterates bottom-to-top** — the wrong order | **`ArrayDeque`** |
| **`Hashtable`** | Synchronised, no null keys or values | `HashMap` or `ConcurrentHashMap` |
| `Enumeration` | Pre-`Iterator` | `Iterator` |

**`Stack`'s iteration order is the memorable bug**: pushing 1, 2, 3 and iterating yields 1, 2, 3 — the opposite of pop order. Nobody expects that.

**Their synchronisation is also useless** — per-method locking doesn't make compound operations atomic:
```java
if (!vector.contains(x)) vector.add(x);   // still a race
```

## The Immutable Trio — All Different

```java
Arrays.asList("a", "b")                    // FIXED-SIZE VIEW over the array
Collections.unmodifiableList(list)         // UNMODIFIABLE VIEW of a live list
List.of("a", "b")                          // genuinely IMMUTABLE, rejects null
```

| | Mutable elements | Add/remove | Null allowed | Independent of source |
|---|---|---|---|---|
| `Arrays.asList` | **Yes** (`set` works) | No | Yes | **No — writes through** |
| `unmodifiableList` | No | No | Depends | **No — it's a view** |
| **`List.of`** | **No** | **No** | **No** | **Yes** |

**`Collections.unmodifiableList` is a view.** The caller keeps the original and can still mutate what you handed out:
```java
List<String> src = new ArrayList<>(List.of("a"));
List<String> given = Collections.unmodifiableList(src);
src.add("b");            // `given` now shows "b"
```

**Use `List.copyOf(src)` to hand out a genuinely safe list.**

**`List.of` rejecting nulls surprises people** — it throws `NullPointerException` on a null element, and `contains(null)` also throws.

## Concurrent Collections — Quick Map

| Need | Use |
|---|---|
| Concurrent map | `ConcurrentHashMap` |
| **Concurrent sorted map** | **`ConcurrentSkipListMap`** |
| Read-mostly list | `CopyOnWriteArrayList` |
| Producer-consumer, bounded | `ArrayBlockingQueue` |
| Unbounded queue | `LinkedBlockingQueue` (**bound it anyway**) |
| Direct handoff | `SynchronousQueue` |
| Scheduled delivery | `DelayQueue` |
| Lock-free queue | `ConcurrentLinkedQueue` |

**`ConcurrentSkipListMap` uses a skip list rather than a tree** because skip lists can be updated with lock-free CAS on individual pointers, whereas rebalancing a red-black tree requires locking several nodes. Concurrency is the reason, not raw speed.

See [Concurrent Collections](../Concurrency/Concurrent%20Collections.md).

## PriorityQueue

A **binary heap in an array** — not a sorted structure.

| Operation | Cost |
|---|---|
| `peek` | **O(1)** |
| `offer` / `poll` | O(log n) |
| **`remove(Object)`** | **O(n)** |
| Build from a collection | **O(n)** — heapify, not n inserts |

**Iteration order is NOT sorted.** Only `poll()` returns elements in order — printing a `PriorityQueue` shows raw heap array order, which surprises people constantly.

**`remove(Object)` in a loop silently makes your algorithm O(n²).** Use lazy deletion (mark stale, skip on poll) or a `TreeMap`.

## ArrayDeque

The correct stack **and** the correct queue.

```java
Deque<Integer> stack = new ArrayDeque<>();
stack.push(x); stack.pop(); stack.peek();

Deque<Integer> queue = new ArrayDeque<>();
queue.offer(x); queue.poll(); queue.peek();
```

A circular array — faster than `LinkedList` (cache locality, no per-node allocation) and faster than `Stack` (no synchronisation).

**Does not permit null elements**, because null is used as a sentinel internally.

## Choosing At A Glance

| Need | Use |
|---|---|
| Enum keys | **`EnumMap` / `EnumSet`** |
| Metadata on objects you don't own | `WeakHashMap` |
| Reference-identity keys, cycle detection | `IdentityHashMap` |
| Insertion or access order | `LinkedHashMap` |
| **LRU cache** | `LinkedHashMap` access-order |
| Stack or queue | **`ArrayDeque`** |
| Repeated min/max | `PriorityQueue` |
| Range or nearest-key queries | `TreeMap` |
| Immutable snapshot | **`List.copyOf` / `Map.copyOf`** |
| Read-mostly concurrent list | `CopyOnWriteArrayList` |

## Common Mistakes

- `HashMap`/`HashSet` for enum keys
- `WeakHashMap` values referencing their keys
- `WeakHashMap` as a cache
- `Stack` or `Vector` in new code
- Confusing `unmodifiableList` (view) with `List.copyOf` (copy)
- Nulls in `List.of` or `ArrayDeque`
- Expecting `PriorityQueue` iteration to be sorted
- `PriorityQueue.remove(Object)` in a loop
- `LinkedHashMap` access-order iteration while calling `get`

## Related Topics

- [Collections Overview](Collections%20Overview.md)
- [HashMap Internals](HashMap%20Internals.md)
- [TreeMap and Sorted Collections](TreeMap%20and%20Sorted%20Collections.md)
- [Reference Types and Cleaners](../JVM%20and%20Memory/Reference%20Types%20and%20Cleaners.md)

## Revision Summary

`EnumMap` is an array and `EnumSet` a bit vector — always use them for enum keys. `WeakHashMap` holds keys weakly but values strongly. `IdentityHashMap` compares by reference, which suits cycle detection. `Arrays.asList`, `unmodifiableList` and `List.of` differ in mutability and independence — only `List.of`/`copyOf` are genuinely safe to hand out.

## Quick Recall

- **`EnumMap` = array by ordinal; `EnumSet` = bit vector** — always prefer them
- `WeakHashMap`: **weak keys, strong values**; not a cache
- `IdentityHashMap` uses `==` — cycle detection
- `LinkedHashMap` access-order + `removeEldestEntry` = **LRU in five lines**
- **`Stack` iterates in the wrong order**; use `ArrayDeque`
- `unmodifiableList` = **view**; `List.copyOf` = copy; `List.of` rejects nulls
- **`PriorityQueue` iteration isn't sorted**; `remove(Object)` is O(n)
- `ArrayDeque` allows no nulls
- `ConcurrentSkipListMap` uses a skip list because it's **CAS-friendly**
