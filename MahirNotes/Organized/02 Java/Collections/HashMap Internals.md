# HashMap Internals

## Why It Matters

The single most-asked Java data-structure question. Interviewers use it to probe hashing, collisions, resizing, and thread-safety in one go.

## Structure

An array of buckets. Each bucket holds either a **linked list** or, once it grows large, a **red-black tree**.

```
table[0] → null
table[1] → Node(k1,v1) → Node(k9,v9)
table[2] → TreeNode root (balanced, ≥ 8 entries)
```

| Constant | Value | Meaning |
|---|---|---|
| Default capacity | 16 | Initial bucket count (always a power of 2) |
| Load factor | 0.75 | Resize when `size > capacity × 0.75` |
| TREEIFY_THRESHOLD | 8 | List → tree |
| UNTREEIFY_THRESHOLD | 6 | Tree → list (hysteresis prevents thrashing) |
| MIN_TREEIFY_CAPACITY | 64 | Below this, **resize instead of treeify** |

**The subtlety:** with 8 collisions in a table smaller than 64, HashMap resizes rather than treeifies — because small tables collide simply from being small.

## Index Calculation

```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
int index = (capacity - 1) & hash;
```

Two things to explain:

1. **`(n - 1) & hash` instead of `%`** — works because capacity is a power of two, and bitwise AND is far cheaper than modulo.
2. **`h ^ (h >>> 16)`** — because the AND only keeps the *low* bits, poor hash functions that differ only in high bits would all collide. XOR-ing the high 16 bits down mixes them in. This is called **spreading**.

## Treeification

Java 8 added the list→tree conversion to bound worst-case lookup at **O(log n)** instead of O(n).

**Why it matters:** it mitigates hash-collision DoS attacks, where an attacker sends keys that all hash to one bucket.

TreeNodes compare by hash, then by `Comparable` if the key implements it, then by a tie-breaking identity comparison.

## Resizing

When `size > threshold`, capacity doubles and entries are redistributed.

Java 8's clever trick: since capacity doubles, an entry either stays at index `i` or moves to `i + oldCapacity`, decided by a single bit test (`hash & oldCapacity`). **No rehashing is needed** — split each bucket into a "lo" and "hi" list.

Resizing is O(n) and allocates a new array. **Pre-size your maps** when you know the count:
```java
new HashMap<>(expectedSize / 0.75f + 1);
```

## The equals/hashCode Contract

```
1. Equal objects MUST have equal hash codes.
2. Unequal objects MAY share a hash code (collision).
3. hashCode must be consistent while the object is in the map.
```

Breaking rule 1 means `get()` looks in the wrong bucket and returns null for a key that is present.

**Mutable keys are a bug:** mutating a field used in `hashCode` after insertion strands the entry — it's in the map but unreachable and never garbage collected.

```java
Set<List<String>> set = new HashSet<>();
List<String> key = new ArrayList<>();
set.add(key);
key.add("x");            // hashCode changed
set.contains(key);       // false — the entry is lost
```

## Thread Safety

`HashMap` is **not** thread-safe. Concurrent `put` during resize could produce an infinite loop in Java 7 (circular list). Java 8's tail-preserving split removed the infinite loop, but concurrent use still causes **lost updates and corrupted state**.

| Option | Mechanism | Throughput |
|---|---|---|
| `Hashtable` | Synchronise every method | Poor (legacy) |
| `Collections.synchronizedMap` | One lock around a wrapper | Poor |
| **`ConcurrentHashMap`** | CAS + per-bin synchronisation | **Best** |

## HashMap vs LinkedHashMap vs TreeMap

| | HashMap | LinkedHashMap | TreeMap |
|---|---|---|---|
| Order | None | Insertion or **access** | Sorted by key |
| get/put | O(1) avg | O(1) avg | O(log n) |
| Null key | One allowed | One allowed | **Not allowed** |
| Extra cost | — | Two pointers per node | Red-black tree |

**LinkedHashMap with access order gives you an LRU cache in five lines:**
```java
new LinkedHashMap<K, V>(capacity, 0.75f, true) {
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity;
    }
};
```

## Common Questions

- *Why power-of-two capacity?* — enables `(n-1) & hash` instead of modulo.
- *Why XOR the high bits?* — the mask discards high bits, so they must be mixed down.
- *Why treeify at 8?* — with a good hash, the probability of 8 in one bucket is ~10⁻⁸ (Poisson); reaching it implies a bad hash or an attack.
- *Why untreeify at 6, not 8?* — hysteresis, to avoid converting back and forth on a boundary.
- *What if I override equals but not hashCode?* — equal objects land in different buckets; lookups fail.

## Common Mistakes

- Overriding `equals` without `hashCode`
- Using mutable objects as keys
- Not pre-sizing large maps, causing repeated O(n) resizes
- Assuming iteration order is stable across JVM versions
- Using `HashMap` from multiple threads

## Related Topics

- [Collections Overview](Collections%20Overview.md)
- [Concurrent Collections](../Concurrency/Concurrent%20Collections.md)
- LRU Cache *(not yet written)*

## Revision Summary

Array of buckets, list→red-black-tree at 8 entries with capacity ≥ 64. Power-of-two capacity enables bitmask indexing; the hash is spread by XOR-ing high bits. Load factor 0.75. Not thread-safe — use ConcurrentHashMap.

## Quick Recall

- 16 buckets, 0.75 load factor, treeify at 8, untreeify at 6, min capacity 64
- `index = (n - 1) & (h ^ h >>> 16)`
- Resize splits each bucket by one bit — no rehash
- Equal objects must have equal hash codes
- LinkedHashMap access-order = LRU
