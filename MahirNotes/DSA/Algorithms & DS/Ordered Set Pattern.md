# Ordered Set / Ordered Map Pattern (DSA Notes)

## What is the Ordered Set Pattern?

The **Ordered Set pattern** is used when you need a data structure that:
- Maintains elements in sorted order at all times
- Supports fast insertion and deletion
- Supports fast retrieval of minimum / maximum elements

In Java, this pattern is implemented using:
- `TreeSet` (ordered set)
- `TreeMap` (ordered map / ordered multiset)

---

## When to Use This Pattern

Use the Ordered Set pattern when a problem requires:
- Dynamic updates (insert / delete)
- Queries like:
  - minimum
  - maximum
  - predecessor / successor
- No tolerance for stale or outdated data

Typical problems:
- Stock price tracking
- Sliding window min/max (with deletions)
- Interval scheduling
- Maintaining rankings or leaderboards

---

## Core Idea

Instead of using heaps (which cannot delete arbitrary elements efficiently),
we use an **ordered structure** that supports:

| Operation | Time |
|---------|------|
Insert | O(log n) |
Delete | O(log n) |
Min | O(log n) |
Max | O(log n) |

---

## Ordered Multiset using TreeMap

Java does not have a built-in multiset.
We simulate it using:

```java
TreeMap<Integer, Integer> countMap;
```

- Key   → value being tracked
- Value → frequency

### Insert
```java
countMap.put(x, countMap.getOrDefault(x, 0) + 1);
```

### Remove
```java
countMap.put(x, countMap.get(x) - 1);
if (countMap.get(x) == 0) countMap.remove(x);
```

### Min / Max
```java
countMap.firstKey(); // minimum
countMap.lastKey();  // maximum
```

---

## Pattern vs Heap (Lazy Deletion)

| Aspect | Ordered Set | Heap + Lazy |
|------|-------------|-------------|
Deletion | Eager | Lazy |
Stale Data | Never | Possible |
Implementation | Clean | Complex |
Memory | Lower | Higher |
Speed | O(log n) | Amortized |

---

## Stock Price Problem (Canonical Example)

### Data Structures Used
```java
TreeMap<Integer, Integer> timestampToPrice;
TreeMap<Integer, Integer> priceCount;
```

### Why This Works
- `timestampToPrice` → source of truth
- `priceCount` → ordered multiset
- Supports eager deletion
- No cleanup loops

---

## Key Invariants

- Ordered structure always reflects CURRENT state
- No stale entries exist
- Min / Max always correct

---

## Interview Tips

Say this confidently:
> “When I need dynamic min/max with deletions, I prefer the ordered set pattern over heaps to avoid lazy cleanup.”

---

## Decision Rule (Memorize This)

- Need min/max only → Heap
- Need min/max + deletions → Ordered Set
- Need range queries → Ordered Set
