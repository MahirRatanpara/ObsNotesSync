
> **Tags:** #dsa #java #collections #lru #interview #revision  
> **Difficulty:** Medium  
> **Pattern:** Design / HashMap  
> **Related:** [[LinkedHashSet]], [[HashMap Internals]], [[Cache Eviction Policies]]

---

## 🧠 What is an LRU Cache?

**LRU = Least Recently Used**

A cache with a fixed capacity that **evicts the least recently accessed item** when full.

```
Access order: A → B → C → A  (capacity = 3)
Cache state:  [B, C, A]        ← A moved to front, B is now LRU
Insert D  →   [C, A, D]        ← B evicted (was LRU)
```

### The Core Contract

|Operation|Expected Time Complexity|
|---|---|
|`get(key)`|O(1)|
|`put(key, value)`|O(1)|

---

## ✅ The Java Solution — Using `LinkedHashMap`

```java
class LRUCache {
    private final int capacity;
    private LinkedHashMap<Integer, Integer> lruCache;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        this.lruCache = new LinkedHashMap<Integer, Integer>(capacity, 0.75f, true) {
            @Override
            protected boolean removeEldestEntry(Map.Entry<Integer, Integer> eldest) {
                return size() > LRUCache.this.capacity;
            }
        };
    }

    public int get(int key) {
        return this.lruCache.getOrDefault(key, -1);
    }

    public void put(int key, int value) {
        this.lruCache.put(key, value);
    }
}
```

---

## 🔬 Line-by-Line Breakdown

### Constructor: `new LinkedHashMap<>(capacity, 0.75f, true)`

The `LinkedHashMap` constructor being used here is:

```java
LinkedHashMap(int initialCapacity, float loadFactor, boolean accessOrder)
```

|Parameter|Value|Meaning|
|---|---|---|
|`initialCapacity`|`capacity`|Pre-size the internal hash table to avoid early rehashing|
|`loadFactor`|`0.75f`|Resize when 75% full — standard Java default, balances memory vs collision|
|`accessOrder`|`true`|**Key flag**: orders entries by _access time_, not insertion time|

> [!important] `accessOrder = true` is the magic ingredient When `true`, every `get()` and `put()` call **moves that entry to the tail** of the internal doubly-linked list. The **head** always holds the least recently used entry.

---

### `removeEldestEntry` Override

```java
@Override
protected boolean removeEldestEntry(Map.Entry<Integer, Integer> eldest) {
    return size() > LRUCache.this.capacity;
}
```

- This is a **hook method** in `LinkedHashMap` called automatically after every `put()`
- Return `true` → Java removes the `eldest` entry (head of list = LRU)
- Return `false` → nothing is evicted
- `LRUCache.this.capacity` — needed because `this` inside the anonymous class refers to the `LinkedHashMap` instance, not the outer `LRUCache`

> [!tip] This is an **anonymous inner class** that extends `LinkedHashMap` and overrides just one method. Elegant and zero-boilerplate.

---

### `get(int key)`

```java
return this.lruCache.getOrDefault(key, -1);
```

- `getOrDefault` returns the value or `-1` if absent — matches Leetcode's contract
- Because `accessOrder = true`, this `get()` call **automatically promotes** the accessed key to the "most recently used" position

---

### `put(int key, int value)`

```java
this.lruCache.put(key, value);
```

- Inserts or updates the entry
- After the put, `removeEldestEntry` is checked — if over capacity, the LRU entry (head) is evicted automatically

---

## 🏗️ How `LinkedHashMap` Works Internally

`LinkedHashMap` = `HashMap` + **doubly-linked list** running through all entries.

```
HashMap buckets:
  [key3] → Node{key3, val, prev, next}
  [key1] → Node{key1, val, prev, next}
  [key2] → Node{key2, val, prev, next}
                  ↕ linked list ↕
  HEAD (LRU) ←→ Node1 ←→ Node2 ←→ Node3 ←→ TAIL (MRU)
```

- Every node has `before` and `after` pointers (in addition to HashMap's `next` for chaining)
- `HashMap` gives O(1) lookup; the linked list maintains order
- `accessOrder = true` → on access, node is unlinked and reinserted at tail

### Internal Class Structure

```
LinkedHashMap.Entry<K,V> extends HashMap.Node<K,V>
  + Entry<K,V> before   // pointer to less-recently used
  + Entry<K,V> after    // pointer to more-recently used
```

---

## 📦 `LinkedHashMap` — Full Usage Guide

### When to Use

|Scenario|Why `LinkedHashMap`?|
|---|---|
|LRU Cache|`accessOrder=true` + `removeEldestEntry`|
|Maintaining insertion order in a map|Default (insertion order)|
|Bounded cache with auto-eviction|Override `removeEldestEntry`|
|Predictable iteration order|Unlike `HashMap`|

### Constructors

```java
// 1. Default: insertion order, capacity 16, load factor 0.75
new LinkedHashMap<>()

// 2. Insertion order with initial capacity
new LinkedHashMap<>(initialCapacity)

// 3. Full control — access order for LRU
new LinkedHashMap<>(initialCapacity, loadFactor, accessOrder)

// 4. Copy constructor
new LinkedHashMap<>(existingMap)
```

### Key Methods

```java
LinkedHashMap<String, Integer> map = new LinkedHashMap<>(16, 0.75f, true);

map.put("a", 1);
map.put("b", 2);
map.put("c", 3);

map.get("a");             // moves "a" to tail (most recent)
map.getOrDefault("z", 0); // safe get, returns 0 if absent

// Iteration — always in order (insertion or access depending on flag)
for (Map.Entry<String, Integer> e : map.entrySet()) {
    System.out.println(e.getKey() + " = " + e.getValue());
}

// Remove eldest entry pattern
new LinkedHashMap<String, Integer>(capacity, 0.75f, true) {
    protected boolean removeEldestEntry(Map.Entry<String, Integer> eldest) {
        return size() > MAX_SIZE;
    }
};
```

### Insertion Order (default) vs Access Order

```java
// INSERTION ORDER (accessOrder = false, default)
LinkedHashMap<String, Integer> map = new LinkedHashMap<>();
map.put("x", 1); map.put("y", 2); map.put("z", 3);
map.get("x");
// Iteration: x → y → z  (get doesn't change order)

// ACCESS ORDER (accessOrder = true)
LinkedHashMap<String, Integer> map = new LinkedHashMap<>(16, 0.75f, true);
map.put("x", 1); map.put("y", 2); map.put("z", 3);
map.get("x");
// Iteration: y → z → x  (x moved to tail after access)
```

---

## 📦 `LinkedHashSet` — Full Usage Guide

`LinkedHashSet` = `HashSet` + insertion-order linked list.

> [!note] There is **no access-order option** in `LinkedHashSet`. It always maintains **insertion order**.

### When to Use

|Scenario|Why `LinkedHashSet`?|
|---|---|
|Unique elements, insertion order needed|Over `TreeSet` (no sorting overhead)|
|Deduplication while preserving order|Over `HashSet` (unpredictable order)|
|Sliding window — seen elements|Track unique items in order of first seen|

### Key Methods

```java
LinkedHashSet<String> set = new LinkedHashSet<>();

set.add("banana");
set.add("apple");
set.add("cherry");
set.add("apple");       // duplicate — ignored

// Iteration always in insertion order
for (String s : set) System.out.println(s);
// Output: banana → apple → cherry

set.contains("apple");  // O(1)
set.remove("apple");    // O(1), insertion order maintained for rest

// Convert to list preserving order
List<String> ordered = new ArrayList<>(set);
```

### `LinkedHashSet` vs `HashSet` vs `TreeSet`

|Feature|`HashSet`|`LinkedHashSet`|`TreeSet`|
|---|---|---|---|
|Order|None|Insertion order|Sorted (natural/comparator)|
|`add` / `contains`|O(1) avg|O(1) avg|O(log n)|
|Memory|Low|Medium (+linked list)|Medium (+tree nodes)|
|Null allowed|✅ (one)|✅ (one)|❌ (if using natural order)|
|Use case|Fast lookup, no order needed|Dedup + preserve order|Sorted unique elements|

---

## 🆚 `LinkedHashMap` vs `HashMap` vs `TreeMap`

|Feature|`HashMap`|`LinkedHashMap`|`TreeMap`|
|---|---|---|---|
|Order|None|Insertion or Access|Sorted by key|
|`get` / `put`|O(1) avg|O(1) avg|O(log n)|
|Memory overhead|Low|Medium (+2 pointers per node)|Medium (+color bit + pointers)|
|Iteration order|Unpredictable|Predictable|Always sorted|
|Best for|Fast lookup, no order|LRU cache, ordered map|Range queries, sorted access|

---

## 🧩 Interview Patterns Using These Collections

### Pattern 1 — LRU Cache (this problem)

```java
// LinkedHashMap with accessOrder=true + removeEldestEntry
```

### Pattern 2 — First Non-Repeating Character

```java
// Use LinkedHashMap<Character, Integer> (insertion order)
// Iterate to find first entry with value == 1
LinkedHashMap<Character, Integer> freq = new LinkedHashMap<>();
for (char c : s.toCharArray())
    freq.merge(c, 1, Integer::sum);
for (Map.Entry<Character, Integer> e : freq.entrySet())
    if (e.getValue() == 1) return e.getKey();
return '#';
```

### Pattern 3 — Deduplicate While Preserving Order

```java
// LinkedHashSet — O(n) dedup keeping first occurrence
String[] arr = {"a", "b", "a", "c", "b"};
Set<String> seen = new LinkedHashSet<>(Arrays.asList(arr));
// Result: [a, b, c]
```

### Pattern 4 — Bounded Cache (General)

```java
// Any fixed-size cache that needs auto-eviction
private static final int MAX = 100;
Map<String, Data> cache = new LinkedHashMap<>(MAX, 0.75f, true) {
    protected boolean removeEldestEntry(Map.Entry<String, Data> e) {
        return size() > MAX;
    }
};
```

### Pattern 5 — LFU (Least Frequently Used) hint

```java
// LFU is harder — needs two maps:
// Map<key, freq> + Map<freq, LinkedHashSet<key>>  ← insertion order within same freq
```

---

## ⚠️ Common Gotchas

> [!warning] `LRUCache.this.capacity` vs `this.capacity` Inside the anonymous subclass of `LinkedHashMap`, `this` refers to the map, not the outer `LRUCache`. You **must** use `LRUCache.this.capacity` to reach the outer field.

> [!warning] `removeEldestEntry` is called after `put`, not after `get` It only fires on write operations. Reads alone never trigger eviction.

> [!warning] `LinkedHashMap` is NOT thread-safe For concurrent LRU, use `Collections.synchronizedMap(...)` wrapping or `ConcurrentHashMap` with manual eviction logic.

> [!warning] Load factor and initial capacity Setting `initialCapacity = capacity` avoids internal resizing _within your logical capacity_, but internal rehashing triggers at `capacity * 0.75`. This is acceptable since `removeEldestEntry` keeps logical size bounded.

---

## 🔁 Quick Revision Flashcards

**Q: What does `accessOrder = true` do in `LinkedHashMap`?**  
A: Orders entries by last access time (get/put), not insertion. Used for LRU.

**Q: When is `removeEldestEntry` called?**  
A: After every `put()`. Return `true` to evict the head (LRU) entry.

**Q: What's the iteration order of `LinkedHashSet`?**  
A: Insertion order. Always. No access-order variant exists.

**Q: Time complexity of LRU get/put with `LinkedHashMap`?**  
A: O(1) average for both.

**Q: Why use `LRUCache.this.capacity` instead of `capacity` inside the anonymous class?**  
A: The anonymous class is a subclass of `LinkedHashMap`, so `this` refers to the map. `LRUCache.this` explicitly references the enclosing instance.

---

## 📎 Related Problems

- [ ] LFU Cache (Leetcode 460) — harder variant
- [ ] Design HashMap (Leetcode 706)
- [ ] First Unique Character in a String (Leetcode 387)
- [ ] Insert Delete GetRandom O(1) (Leetcode 380)
- [ ] All O'one Data Structure (Leetcode 432)