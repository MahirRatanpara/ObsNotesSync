# Streams

## Why It Matters

Expected knowledge in any modern Java round, and interviewers use laziness and parallelism to separate people who use streams from people who understand them.

## Core Idea

A stream is **not a data structure**. It holds no elements — it's a pipeline description over a source, evaluated only when a terminal operation runs.

```
source → intermediate ops (lazy) → terminal op (eager, triggers everything)
```

## Laziness — The Key Mechanism

Intermediate operations (`map`, `filter`, `sorted`, `limit`) build a pipeline and do nothing. Only a terminal operation (`collect`, `forEach`, `reduce`, `findFirst`, `count`) executes it.

```java
list.stream().filter(x -> { System.out.println("filtering"); return x > 2; });
// prints NOTHING — no terminal operation
```

**Elements are pulled one at a time through the whole pipeline**, not processed stage by stage:

```java
Stream.of("a","b","c")
      .map(s -> { System.out.println("map " + s); return s.toUpperCase(); })
      .filter(s -> { System.out.println("filter " + s); return !s.equals("B"); })
      .findFirst();
// map a, filter a — then STOPS. "b" and "c" are never touched.
```

**This element-at-a-time pull model is what enables short-circuiting and infinite streams.** Explaining it is the highest-value thing you can say about streams.

## Short-Circuiting and Infinite Streams

```java
Stream.iterate(1, n -> n + 1)      // infinite
      .filter(n -> n % 7 == 0)
      .limit(5)                     // short-circuits
      .toList();
```

Works only because of laziness. `findFirst`, `anyMatch`, `allMatch`, `noneMatch`, `limit`, and `takeWhile` all short-circuit.

## Streams Are Single-Use

```java
Stream<String> s = list.stream();
s.count();
s.forEach(...);   // IllegalStateException: stream has already been operated upon or closed
```

Create a new stream each time. If you need reuse, use a `Supplier<Stream<T>>`.

## Collectors Worth Knowing

```java
.collect(Collectors.toList())                              // or .toList() in Java 16+
.collect(Collectors.toMap(User::id, Function.identity()))  // throws on duplicate keys!
.collect(Collectors.groupingBy(User::dept))
.collect(Collectors.groupingBy(User::dept, Collectors.counting()))
.collect(Collectors.groupingBy(User::dept, Collectors.averagingInt(User::age)))
.collect(Collectors.partitioningBy(u -> u.age() > 30))     // always exactly 2 keys
.collect(Collectors.joining(", ", "[", "]"))
.collect(Collectors.summarizingInt(User::age))             // count, sum, min, avg, max
```

**`Collectors.toMap` throws `IllegalStateException` on duplicate keys.** Supply a merge function:
```java
Collectors.toMap(User::id, Function.identity(), (a, b) -> a)
```
This is a very common production bug and a good interview answer.

**`toList()` (Java 16+) returns an unmodifiable list**; `Collectors.toList()` gives no such guarantee. Know the difference.

## map vs flatMap

```java
List<List<String>> nested = ...;
nested.stream().map(List::stream)        // Stream<Stream<String>> — usually wrong
nested.stream().flatMap(List::stream)    // Stream<String> — flattened
```

Same `map`/`flatMap` distinction as `thenApply`/`thenCompose` in [CompletableFuture](../Concurrency/CompletableFuture.md) and `Optional.map`/`flatMap`.

## reduce

```java
.reduce(0, Integer::sum)                             // identity + accumulator
.reduce(0, (a, b) -> a + b, Integer::sum)            // + combiner, for parallel
```

Three requirements for correctness, especially in parallel:
1. **Identity** — `combiner(identity, x) == x`
2. **Associative** — grouping must not matter
3. **Stateless / non-interfering** — no mutation of external state

Subtraction is not associative, so `reduce(0, (a,b) -> a - b)` gives different results in parallel. That's a favourite trap.

## Parallel Streams — Handle With Care

```java
list.parallelStream().filter(...).collect(...)
```

**Uses the shared `ForkJoinPool.commonPool()`**, sized `cores − 1` and shared JVM-wide. One blocking parallel stream starves every other user of that pool — including other parallel streams and any library that uses it.

**Only worth it when all of these hold:**
- Large data set (rule of thumb: 10,000+ elements)
- Genuinely CPU-bound work per element
- The source splits well (`ArrayList`, arrays — **not** `LinkedList` or `Iterator`-based sources)
- Operations are stateless and associative
- **No blocking I/O**

**For blocking I/O, use a dedicated executor with `CompletableFuture`, never a parallel stream.**

Measure before and after. Parallel streams are frequently slower than sequential for realistic workloads.

## Primitive Streams

`IntStream`, `LongStream`, `DoubleStream` avoid boxing:

```java
list.stream().mapToInt(User::age).average().orElse(0);
IntStream.rangeClosed(1, 100).sum();
```

Use them for numeric work — boxing a million `Integer` objects is real overhead.

## Common Questions

- *Are streams lazy?* — intermediate ops are; terminal ops trigger execution.
- *How does the pipeline process elements?* — one element through the whole chain, enabling short-circuiting.
- *Can a stream be reused?* — no.
- *When are parallel streams appropriate?* — large, CPU-bound, splittable, stateless, no I/O.
- *What does `toMap` do on duplicate keys?* — throws, unless you supply a merge function.
- *`map` vs `flatMap`?* — one-to-one vs one-to-many with flattening.

## Common Mistakes

- Blocking I/O in a parallel stream
- Mutating external state inside a lambda (breaks parallelism, and is a race)
- `Collectors.toMap` without a merge function
- Reusing a consumed stream
- Using streams for simple loops where they hurt readability
- Assuming `parallelStream` is automatically faster

## Related Topics

- [CompletableFuture](../Concurrency/CompletableFuture.md)
- [Collections Overview](../Collections/Collections%20Overview.md)
- [Executors and Thread Pools](../Concurrency/Executors%20and%20Thread%20Pools.md)

## Revision Summary

A stream describes a lazy pipeline over a source, pulling one element at a time through the whole chain, which is what enables short-circuiting and infinite sources. Single-use. Parallel streams share the common pool and suit only large CPU-bound splittable work.

## Quick Recall

- Intermediate = lazy; terminal = triggers
- One element traverses the whole pipeline
- Streams are single-use
- `toMap` throws on duplicate keys — pass a merge function
- Parallel streams use the shared common pool; never for I/O
- `flatMap` flattens; `mapToInt` avoids boxing
