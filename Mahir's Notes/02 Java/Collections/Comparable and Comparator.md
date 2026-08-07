# Comparable and Comparator

## Why It Matters

Sorting is everywhere, and a broken comparator throws at runtime rather than failing silently. The contract rules are precise and frequently violated.

## The Two Interfaces

| | **`Comparable<T>`** | **`Comparator<T>`** |
|---|---|---|
| Method | `int compareTo(T other)` | `int compare(T a, T b)` |
| Lives | **Inside** the class | **Outside** the class |
| Count | **One** — the natural order | **Many** |
| Modifies the class | Yes | No |
| Package | `java.lang` | `java.util` |

**`Comparable` defines *the* natural order** — the one obviously-correct ordering for the type (`String` alphabetically, `Integer` numerically).

**`Comparator` defines *an* order** — one of many possible, chosen by the caller. It's the [Strategy pattern](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Strategy.md) in the JDK.

**Use `Comparable` only when there's an unambiguous natural order.** For a `Person`, there isn't one — by name? by age? by ID? Leave it out and supply comparators.

## The Contract

Both must satisfy:

| Rule | Meaning |
|---|---|
| **Antisymmetry** | `sgn(compare(a,b)) == -sgn(compare(b,a))` |
| **Transitivity** | `a > b` and `b > c` ⟹ `a > c` |
| **Consistency** | `compare(a,b) == 0` ⟹ `sgn(compare(a,c)) == sgn(compare(b,c))` |
| **Total order** | Any two elements must be comparable |
| *Recommended* | `compare(a,b) == 0` ⟺ `a.equals(b)` |

**Violating the contract throws at runtime:**
```
java.lang.IllegalArgumentException: Comparison method violates its general contract!
```

TimSort detects inconsistency during merging. It isn't being fussy — an inconsistent comparator can loop forever or corrupt the array, so the JDK fails loudly instead.

## The Subtraction Trap

```java
// WRONG — overflows
Comparator<Integer> bad = (a, b) -> a - b;
bad.compare(Integer.MAX_VALUE, -1);   // overflows to negative → says MAX < -1

// CORRECT
Comparator<Integer> good = Integer::compare;
Comparator<Integer> also = Comparator.naturalOrder();
```

**`a - b` is the single most common comparator bug.** It only works when you can prove no overflow — which you usually can't. Use `Integer.compare`, `Long.compare`, `Double.compare`.

**`Double.compare` also handles `NaN` and `-0.0` correctly**, where `<` and `>` do not. That's why it exists.

## Building Comparators Fluently

```java
Comparator<Person> byAgeThenName =
    Comparator.comparingInt(Person::age)
              .thenComparing(Person::name);

Comparator<Person> descending =
    Comparator.comparing(Person::name).reversed();

Comparator<Person> nullsLast =
    Comparator.nullsLast(Comparator.comparing(Person::name));

Comparator<Person> byNameCaseInsensitive =
    Comparator.comparing(Person::name, String.CASE_INSENSITIVE_ORDER);
```

**Use the primitive variants where applicable** — `comparingInt`, `comparingLong`, `comparingDouble` — to avoid boxing on every comparison. In a sort of a million elements that's a million avoided allocations.

**`.reversed()` reverses everything before it**, which trips people up:
```java
comparing(Person::age).thenComparing(Person::name).reversed()
// reverses BOTH keys

comparing(Person::age).reversed().thenComparing(Person::name)
// age descending, then name ascending — usually what you want
```

## Consistency With equals

**Recommended, not required** — but violating it breaks sorted collections.

```java
BigDecimal a = new BigDecimal("1.0");
BigDecimal b = new BigDecimal("1.00");

a.equals(b);        // false — equals compares scale
a.compareTo(b);     // 0     — compareTo ignores scale

Set<BigDecimal> hash = new HashSet<>(List.of(a, b));   // size 2
Set<BigDecimal> tree = new TreeSet<>(List.of(a, b));   // size 1  ← !
```

**`TreeSet` and `TreeMap` use `compareTo`, not `equals`, to decide membership.** So the same two objects give different set sizes depending on the implementation.

**`BigDecimal` is the JDK's own documented violation** and the standard example for this question.

**Practical consequence:** if your `compareTo` isn't consistent with `equals`, document it loudly, and never use the type as a `TreeMap` key.

## Where Each Is Used

```java
// Comparable — natural ordering
Collections.sort(list);
list.sort(null);
new TreeSet<>();                          // requires Comparable elements
new PriorityQueue<>();

// Comparator — explicit ordering
list.sort(byAge);
new TreeSet<>(byAge);
new PriorityQueue<>(byAge);
stream.sorted(byAge);
stream.max(byAge);
Collections.max(list, byAge);
```

**A `TreeSet` of a non-`Comparable` type throws `ClassCastException` at the first `add`, not at construction** — a confusing failure if you don't know it.

## Sorting Algorithms Underneath

| Input | Algorithm | Property |
|---|---|---|
| **Objects** | **TimSort** | **Stable**, O(n) on sorted input |
| **Primitives** | Dual-pivot quicksort | Not stable — irrelevant for primitives |

**Stability is why objects and primitives use different algorithms.** Primitives have no identity, so two equal `int`s are indistinguishable and stability is meaningless. Objects need it for multi-key sorting:

```java
people.sort(comparing(Person::name));   // secondary key FIRST
people.sort(comparing(Person::age));    // primary — names stay ordered within each age
```

**This only works because the second sort is stable.** It's the practical reason stability matters, and a good answer to "why does Java use two sorting algorithms?"

## Comparator In Streams

```java
list.stream().sorted(comparing(Person::age)).toList();
list.stream().max(comparingInt(Person::age));      // returns Optional
list.stream().collect(groupingBy(Person::dept,
        TreeMap::new,                              // sorted grouping
        counting()));
```

## null Handling

`compareTo` should throw `NullPointerException` on a null argument — that's the documented contract. To sort collections containing nulls, wrap:

```java
Comparator.nullsFirst(naturalOrder());
Comparator.nullsLast(comparing(Person::name));
```

**`Comparator.comparing` with a key extractor that returns null still NPEs** — `nullsLast` guards the *element*, not the extracted key. Guard the key separately if it can be null:
```java
comparing(Person::name, nullsLast(naturalOrder()))
```

## Common Mistakes

- `a - b` comparators — overflow
- `<` / `>` on doubles instead of `Double.compare` — NaN handling
- `.reversed()` reversing more than intended
- Implementing `Comparable` when there's no natural order
- `compareTo` inconsistent with `equals`, then using the type as a `TreeMap` key
- Boxing comparators (`comparing` instead of `comparingInt`) in hot sorts
- Assuming `TreeSet` uses `equals` for membership
- Mutating an object while it's in a `TreeSet` — it becomes unreachable

## Related Topics

- [ArrayList and List Internals](ArrayList%20and%20List%20Internals.md)
- [TreeMap and Sorted Collections](TreeMap%20and%20Sorted%20Collections.md)
- [equals and hashCode](../Language%20Core/Equals%20and%20HashCode.md)
- [Strategy](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Strategy.md)

## Revision Summary

`Comparable` is the single natural order defined inside the class; `Comparator` is one of many defined outside. Both must be antisymmetric, transitive and consistent, or TimSort throws. Never subtract to compare. Sorted collections use `compareTo`, not `equals`, for membership — which is why `BigDecimal` behaves differently in `HashSet` and `TreeSet`.

## Quick Recall

- `Comparable` = natural order, one, inside; `Comparator` = many, outside
- **Never `a - b`** — use `Integer.compare` / `Double.compare`
- `Double.compare` handles `NaN` and `-0.0`; `<` doesn't
- **`.reversed()` reverses everything before it**
- **`TreeSet`/`TreeMap` use `compareTo` for membership, not `equals`**
- `BigDecimal` is the JDK's own consistency violation
- Multi-key sorting works because **TimSort is stable**
- `comparingInt` avoids boxing
- Contract violation → `IllegalArgumentException` at runtime
