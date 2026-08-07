# Collectors and Advanced Streams

## Why It Matters

`collect` is where most real stream work happens, and `Collectors.toMap` has a trap that causes production exceptions. Custom collectors are a genuine depth signal.

## The Core Collectors

```java
.collect(toList())              // Java 8; Stream.toList() in 16+ is unmodifiable
.collect(toSet())
.collect(toCollection(TreeSet::new))     // choose the implementation
.collect(joining(", ", "[", "]"))
.collect(counting())
.collect(summingInt(Item::qty))
.collect(averagingDouble(Item::price))
.collect(summarizingInt(Item::qty))      // count, sum, min, avg, max in one pass
```

**`summarizing*` returns an `IntSummaryStatistics`** with all five figures from a single traversal — better than five separate streams.

## toMap — The Trap

```java
.collect(toMap(User::id, Function.identity()))
```

**Throws `IllegalStateException: Duplicate key` on any collision.** This is the most common `Collectors` bug, and it usually surfaces in production when data that "can't have duplicates" does.

```java
// Supply a merge function
.collect(toMap(User::email, identity(), (existing, replacement) -> existing))

// Choose the map implementation too
.collect(toMap(User::id, identity(), (a, b) -> a, LinkedHashMap::new))
```

**Second trap: `toMap` throws `NullPointerException` on a null value**, because it uses `Map.merge` internally. `groupingBy` does not have this problem. If values may be null, collect manually or use `groupingBy`.

## groupingBy — The Workhorse

```java
// Simple
Map<Dept, List<Employee>> byDept = employees.stream()
    .collect(groupingBy(Employee::dept));

// With a downstream collector
Map<Dept, Long> countByDept = employees.stream()
    .collect(groupingBy(Employee::dept, counting()));

Map<Dept, Double> avgSalary = employees.stream()
    .collect(groupingBy(Employee::dept, averagingDouble(Employee::salary)));

// Choose the map type
Map<Dept, List<Employee>> sorted = employees.stream()
    .collect(groupingBy(Employee::dept, TreeMap::new, toList()));

// Multi-level
Map<Dept, Map<Grade, List<Employee>>> nested = employees.stream()
    .collect(groupingBy(Employee::dept, groupingBy(Employee::grade)));

// Transform the grouped values
Map<Dept, Set<String>> namesByDept = employees.stream()
    .collect(groupingBy(Employee::dept, mapping(Employee::name, toSet())));
```

**`mapping` is the one people miss** — it transforms elements *before* the downstream collector, avoiding a second pass.

**`partitioningBy` is `groupingBy` with a boolean key**, and it **always returns exactly two entries** (`true` and `false`), even when one is empty. `groupingBy` with a boolean predicate would omit the empty side — a real behavioural difference.

```java
Map<Boolean, List<Employee>> split = employees.stream()
    .collect(partitioningBy(e -> e.salary() > 100_000));
```

## The Downstream Collectors

| Collector | Purpose |
|---|---|
| `counting()` | Count per group |
| `summingInt` / `averagingDouble` | Aggregate |
| **`mapping(fn, downstream)`** | Transform before collecting |
| **`filtering(pred, downstream)`** | Filter **within** the group (Java 9+) |
| `flatMapping(fn, downstream)` | Flatten within the group (9+) |
| `reducing(identity, op)` | Custom reduction |
| **`collectingAndThen(c, finisher)`** | Post-process the result |
| `toUnmodifiable*` | Immutable results |
| **`teeing(c1, c2, merger)`** | **Two collectors, one pass** (Java 12+) |

**`filtering` versus filtering upstream is a genuine difference:**
```java
// Groups with no matches DISAPPEAR
.filter(e -> e.salary() > 100_000).collect(groupingBy(Employee::dept))

// Groups are PRESERVED, with empty lists
.collect(groupingBy(Employee::dept, filtering(e -> e.salary() > 100_000, toList())))
```

**`collectingAndThen` for immutability:**
```java
.collect(collectingAndThen(toList(), Collections::unmodifiableList))
```

**`teeing` computes two things in one traversal:**
```java
record Stats(long count, double avg) {}
Stats s = employees.stream().collect(teeing(
    counting(),
    averagingDouble(Employee::salary),
    Stats::new));
```

## Custom Collectors

```java
Collector<T, A, R> = Collector.of(
    supplier,      // () -> A            create the container
    accumulator,   // (A, T) -> void     add one element
    combiner,      // (A, A) -> A        MERGE two containers (parallel only)
    finisher,      // A -> R             optional final transform
    characteristics
);
```

Example — join with a running count:

```java
Collector<String, ?, String> joinWithCount = Collector.of(
    StringBuilder::new,
    (sb, s) -> sb.append(s).append(","),
    StringBuilder::append,
    sb -> sb + " (" + sb.chars().filter(c -> c == ',').count() + " items)"
);
```

**The combiner is only used in parallel streams** — but it must still be correct, and it must be **associative**. Writing a combiner that isn't associative gives correct sequential results and wrong parallel ones, which is a nasty class of bug.

**Characteristics:**
- `UNORDERED` — the result doesn't depend on encounter order
- `CONCURRENT` — the accumulator is thread-safe, so one shared container can be used
- `IDENTITY_FINISH` — the finisher is the identity function (a small optimisation)

## reduce vs collect

| | `reduce` | `collect` |
|---|---|---|
| Produces | An **immutable** value | A **mutable** container |
| Per element | Creates a new value | Mutates the accumulator |
| Good for | Sums, min/max, single values | Lists, maps, strings |

```java
// WRONG — O(n²), allocates a new string per element
stream.reduce("", (a, b) -> a + b);

// RIGHT — mutable accumulation
stream.collect(joining());
```

**`reduce` with an accumulating container is a performance bug.** That's the distinction: `reduce` for immutable folds, `collect` for mutable accumulation.

**`reduce` requires** an identity where `f(identity, x) == x`, an **associative** operator, and no side effects. Subtraction is not associative, so `reduce(0, (a,b) -> a-b)` gives different answers in parallel.

## Advanced Stream Operations

| Operation | Notes |
|---|---|
| `flatMap` | One-to-many, flattened |
| **`mapMulti`** (Java 16+) | Like `flatMap` but **without allocating an intermediate stream** — faster for few outputs |
| `takeWhile` / `dropWhile` | Short-circuit on a predicate (9+) |
| `iterate(seed, hasNext, next)` | Bounded iterate (9+) |
| `peek` | **Debugging only** — may be skipped entirely |
| `distinct` | Uses `equals`/`hashCode`; **stateful** |
| `sorted` | **Fully buffers** — never on an infinite stream |
| `mapToObj` | Primitive stream back to objects |

**`peek` is not a `forEach`.** The JDK explicitly permits implementations to skip it when the result can be computed without it — since Java 9, `stream.peek(...).count()` may never call the peek action at all. Use it only for debugging.

**`sorted` and `distinct` are stateful barriers** — they must see all elements, so they break laziness and cannot be used on infinite streams.

## Grouping Into a Complex Result

A realistic example combining several ideas:

```java
Map<String, List<String>> topEarnersByDept = employees.stream()
    .collect(groupingBy(
        Employee::dept,
        TreeMap::new,
        collectingAndThen(
            toList(),
            list -> list.stream()
                        .sorted(comparingDouble(Employee::salary).reversed())
                        .limit(3)
                        .map(Employee::name)
                        .toList())));
```

**Readability caveat:** deeply nested collectors become unreadable fast. If it takes more than a few seconds to parse, extract a method or use a loop. Cleverness in stream code is a real maintenance cost.

## Common Mistakes

- `toMap` without a merge function
- `toMap` with null values → NPE
- Filtering upstream when you meant `filtering` downstream
- `reduce` with string concatenation
- Non-associative reduce or combiner
- Relying on `peek` for side effects
- `sorted` or `distinct` on an infinite stream
- Deeply nested collectors nobody can read
- Assuming `Collectors.toList()` returns an unmodifiable list (it doesn't; `Stream.toList()` does)

## Related Topics

- [Streams](Streams.md)
- [Lambdas and Functional Interfaces](Lambdas%20and%20Functional%20Interfaces.md)
- [Parallel Streams and Spliterators](Parallel%20Streams%20and%20Spliterators.md)
- [Optional](Optional.md)

## Revision Summary

`toMap` throws on duplicate keys and on null values — supply a merge function. `groupingBy` with downstream collectors (`counting`, `mapping`, `filtering`, `collectingAndThen`) covers most aggregation. Use `collect` for mutable accumulation and `reduce` for immutable folds. Custom collectors need an associative combiner even if you never run in parallel.

## Quick Recall

- **`toMap` throws on duplicate keys** — always pass a merge function
- **`toMap` NPEs on null values**; `groupingBy` doesn't
- `mapping` transforms before the downstream collector
- **`filtering` preserves empty groups; upstream `filter` drops them**
- `partitioningBy` always returns both `true` and `false` keys
- `teeing` = two collectors, one pass
- **`reduce` immutable, `collect` mutable** — never `reduce` strings
- Combiner must be **associative** even if sequential
- **`peek` may be skipped** — debugging only
- `sorted`/`distinct` are stateful barriers
