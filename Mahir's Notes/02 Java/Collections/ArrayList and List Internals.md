# ArrayList and List Internals

## Why It Matters

`ArrayList` is the most-used class in Java after `String`. Its growth strategy, iteration semantics, and why it beats `LinkedList` in practice are standard interview material.

## ArrayList Internals

Backed by a plain `Object[]`.

```java
transient Object[] elementData;   // the backing array
private int size;                 // number of elements actually used
protected transient int modCount; // structural modification counter
```

**`size` and `elementData.length` are different.** Capacity is the array length; size is how much is used. `size()` returns the latter.

### Growth

```java
int newCapacity = oldCapacity + (oldCapacity >> 1);   // 1.5×
```

**Growth factor is 1.5×, not 2×.** Starting from the default 10: 10 → 15 → 22 → 33 → 49 …

Each growth is an `Arrays.copyOf` — an O(n) allocation and copy. Amortised over the appends, `add` is **O(1) amortised**.

**Why 1.5 rather than 2:** it wastes less memory on average, and freed blocks are more likely to be reusable by the allocator for the next growth. **Why not a fixed increment:** that would make `add` O(n) amortised rather than O(1).

**Lazy allocation:** `new ArrayList<>()` starts with a shared empty array and only allocates on first `add`. So an unused `ArrayList` is very cheap — relevant when you have millions of mostly-empty lists.

**Pre-size when you know the count:**
```java
new ArrayList<>(expectedSize);   // avoids repeated grow-and-copy
```

### Removal

```java
public E remove(int index) {
    E old = elementData(index);
    int numMoved = size - index - 1;
    System.arraycopy(elementData, index+1, elementData, index, numMoved);
    elementData[--size] = null;    // let GC reclaim
    return old;
}
```

**Removing from the middle shifts everything after it** — O(n). Removing from the end is O(1).

**`elementData[--size] = null` matters.** Without it the array would retain a strong reference to a removed element, leaking it. This is a real detail worth knowing: the JDK explicitly nulls the slot.

**Removing in a loop is a classic quadratic bug:**
```java
for (int i = 0; i < list.size(); i++)
    if (test(list.get(i))) list.remove(i--);   // O(n²) AND fiddly

list.removeIf(this::test);                     // O(n), single pass
```

`removeIf` compacts in one pass rather than shifting per removal.

### modCount and Fail-Fast

Every structural modification increments `modCount`. An iterator captures it at creation and compares on each `next()`:

```java
if (modCount != expectedModCount) throw new ConcurrentModificationException();
```

**This is a best-effort bug detector, not a guarantee.** The check isn't synchronised, so it can miss violations. **Never write logic that depends on catching `ConcurrentModificationException`.**

```java
for (String s : list) if (s.isEmpty()) list.remove(s);   // throws

Iterator<String> it = list.iterator();                    // correct
while (it.hasNext()) if (it.next().isEmpty()) it.remove();
list.removeIf(String::isEmpty);                           // also correct
```

**`Iterator.remove()` is safe** because it updates both `modCount` and `expectedModCount` together.

## ArrayList vs LinkedList

| Operation | `ArrayList` | `LinkedList` |
|---|---|---|
| `get(i)` | **O(1)** | O(n) |
| `add(end)` | O(1) amortised | O(1) |
| `add`/`remove` at index | O(n) shift | **O(1) given the node**, O(n) to find it |
| `add`/`remove` at head | O(n) | **O(1)** |
| Memory per element | 4–8 bytes (reference) | **~40 bytes** (node + 2 pointers + header) |
| Cache locality | **Excellent** — contiguous | **Poor** — scattered nodes |

**Use `ArrayList` by default.** `LinkedList` looks better on paper for insertions, but:

1. **You must traverse to the position first** — O(n) — so the O(1) insert almost never materialises
2. **Cache misses dominate.** A contiguous array is prefetched; a linked list is a pointer chase through scattered memory. Modern CPUs make this gap enormous — often 10× or more for iteration.
3. **~40 bytes per node** versus 4–8, so it thrashes cache further.

**In practice, `ArrayList` wins even for middle insertion at realistic sizes**, because `System.arraycopy` is a highly-optimised bulk memory move while `LinkedList` traversal is a dependent-load chain.

**`LinkedList`'s only real use is as a `Deque`** — and `ArrayDeque` beats it there too. Its genuine niche is essentially empty.

## The Other List Implementations

| Class | Notes |
|---|---|
| `ArrayList` | **The default** |
| `LinkedList` | Doubly-linked; also a `Deque`; rarely correct |
| **`CopyOnWriteArrayList`** | Every write copies the array; **read-mostly listener lists** |
| `Vector` | **Legacy** — synchronized on every method |
| `Stack` | **Legacy** — extends `Vector`, iterates in the wrong order |
| `Arrays.asList(...)` | **Fixed-size view** over the array — `add` throws |
| `List.of(...)` | **Immutable**, rejects nulls |
| `Collections.unmodifiableList(l)` | **View** — the backing list can still change |

### The three "immutable" lists are different

```java
List<String> a = Arrays.asList("x", "y");        // fixed size, set() works, add() throws
a.set(0, "z");                                   // OK — writes through to the array

List<String> b = List.of("x", "y");              // fully immutable, rejects null
b.set(0, "z");                                   // UnsupportedOperationException

List<String> src = new ArrayList<>(List.of("x"));
List<String> c = Collections.unmodifiableList(src);
src.add("y");                                    // c NOW SEES "y" — it's a VIEW
```

**`unmodifiableList` is a view, not a copy.** If the caller keeps the original reference, they can still mutate what you handed out. To hand out a genuinely safe list, copy first: `List.copyOf(src)`.

**`Arrays.asList` returning a fixed-size list is also an LSP violation in the JDK** — `add` throws `UnsupportedOperationException` on something typed as `List`.

## CopyOnWriteArrayList

```java
public boolean add(E e) {
    synchronized (lock) {
        Object[] es = getArray();
        Object[] newEs = Arrays.copyOf(es, es.length + 1);   // FULL COPY per write
        newEs[es.length] = e;
        setArray(newEs);
        return true;
    }
}
```

| | Cost |
|---|---|
| Read | **O(1), no locking at all** |
| Write | **O(n) copy under a lock** |
| Iteration | Snapshot — never throws `ConcurrentModificationException` |

**Use for listener/observer registries** — many reads (every event), rare writes (registration). Never for write-heavy data.

**Iterators are snapshots and do not support `remove()`.** They also won't reflect concurrent additions, which is usually what you want for event dispatch.

## Sorting

`Collections.sort` / `List.sort` delegates to `Arrays.sort`:

| Input | Algorithm | Why |
|---|---|---|
| **Primitives** | Dual-pivot quicksort | No identity, so stability is meaningless; in-place is better |
| **Objects** | **TimSort** | Objects need **stability** for multi-key sorting |

**TimSort** finds naturally ordered runs, extends short ones with insertion sort, and merges with stack-size invariants. **O(n) on already-sorted input**, O(n log n) worst case, stable.

**Stability matters** because it makes multi-key sorting work:
```java
people.sort(comparing(Person::name));   // secondary key first
people.sort(comparing(Person::age));    // primary — names stay ordered within each age
```

**A broken comparator throws** `IllegalArgumentException: Comparison method violates its general contract!` — TimSort detects inconsistency during merging. It's not being pedantic; an inconsistent comparator can produce an infinite loop or corrupt the array.

## Common Mistakes

- `LinkedList` expecting fast insertion
- Removing inside a for-each loop
- Manual index-based removal in a loop instead of `removeIf`
- Not pre-sizing a large list
- `Stack` or `Vector` in new code
- Assuming `Arrays.asList` is mutable, or `unmodifiableList` is a copy
- `CopyOnWriteArrayList` for write-heavy data
- Comparators that violate transitivity

## Related Topics

- [Collections Overview](Collections%20Overview.md)
- [HashMap Internals](HashMap%20Internals.md)
- [Comparable and Comparator](Comparable%20and%20Comparator.md)
- [Concurrent Collections](../Concurrency/Concurrent%20Collections.md)

## Revision Summary

`ArrayList` grows 1.5× with an O(n) copy, giving amortised O(1) append; removal shifts and nulls the vacated slot. `modCount` powers best-effort fail-fast iteration. `ArrayList` beats `LinkedList` in practice because of cache locality and because you must traverse to a position anyway. Objects sort with stable TimSort, primitives with dual-pivot quicksort.

## Quick Recall

- **Growth is 1.5×**, not 2×; default capacity 10, allocated lazily
- Remove shifts with `System.arraycopy` and **nulls the last slot**
- `modCount` fail-fast is **best-effort** — never rely on catching CME
- `removeIf` instead of removing in a loop
- **`ArrayList` beats `LinkedList`** — cache locality plus traversal cost
- `Arrays.asList` = fixed-size view; `unmodifiableList` = **view, not copy**; `List.of` = immutable
- `CopyOnWriteArrayList` = read-mostly listener lists only
- **TimSort for objects (stable), dual-pivot quicksort for primitives**
