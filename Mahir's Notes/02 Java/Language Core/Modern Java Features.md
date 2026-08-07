# Modern Java Features (8 → 21)

## Why It Matters

Interviewers use this to check whether you've kept current. Answering a design question with Java 8 idioms when records and sealed types exist reads as stale.

## The Headline Features By Version

| Version | Feature |
|---|---|
| 8 | Lambdas, streams, `Optional`, default methods, `java.time` |
| 9 | Modules, collection factories (`List.of`) |
| 10 | `var` |
| 11 | **LTS** — HTTP client, `String` methods |
| 14 | `switch` expressions |
| 15 | Text blocks |
| 16 | **Records**, pattern matching for `instanceof` |
| 17 | **LTS** — **sealed classes** |
| 21 | **LTS** — **virtual threads**, pattern matching for `switch`, record patterns |

**8, 11, 17, and 21 are the LTS releases.** Most production systems are on 17 or 21.

## Records

```java
public record Money(BigDecimal amount, Currency currency) {
    public Money {                                   // compact constructor
        Objects.requireNonNull(amount);
        if (amount.scale() > 2) throw new IllegalArgumentException();
    }
    public Money add(Money other) { return new Money(amount.add(other.amount), currency); }
}
```

Generates `equals`, `hashCode`, `toString`, accessors, and a canonical constructor — **correctly**, over all components.

**This eliminates the entire [equals/hashCode](Equals%20and%20HashCode.md) bug class for value types.** Use records for DTOs, value objects, and query results.

**Limitations:** implicitly final, cannot extend a class, all fields are final. **Records do not replace Builder** — a record with 10 components has the same telescoping-constructor problem.

## Sealed Classes

```java
public sealed interface Shape permits Circle, Square, Triangle {}

public record Circle(double radius) implements Shape {}
public record Square(double side) implements Shape {}
```

Restricts which types may implement an interface. The compiler then knows the complete set.

**Combined with pattern matching, this gives exhaustive switches:**

```java
double area(Shape s) {
    return switch (s) {
        case Circle c   -> Math.PI * c.radius() * c.radius();
        case Square q   -> q.side() * q.side();
        case Triangle t -> 0.5 * t.base() * t.height();
    };                       // no default needed — compiler verifies exhaustiveness
}
```

**Adding a new `Shape` breaks compilation everywhere it's switched on** — which is exactly what you want. This is the modern alternative to the [Visitor pattern](Visitor.md), with compile-time safety and none of the double-dispatch ceremony.

**Sealed types plus records model algebraic data types** — the closest Java gets to a proper sum type.

## Pattern Matching

```java
// instanceof (16+) — no cast needed
if (obj instanceof String s && s.length() > 5) { use(s); }

// switch with guards (21)
String describe(Object o) {
    return switch (o) {
        case Integer i when i > 100 -> "big number";
        case Integer i              -> "number " + i;
        case String s               -> "string of length " + s.length();
        case null                   -> "null";        // explicit null case
        default                     -> "unknown";
    };
}

// record patterns (21) — destructuring
if (shape instanceof Circle(double radius)) { use(radius); }
```

**`switch` handling `null` explicitly is new** — previously it threw `NullPointerException`. Now an unhandled null still throws unless you add a `case null`.

## Virtual Threads (21)

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (var task : tasks) executor.submit(task);
}
```

Millions of threads, scheduled by the JVM onto a small carrier pool. **Blocking a virtual thread unmounts it rather than blocking an OS thread.**

| Rule | Reason |
|---|---|
| **For I/O-bound work only** | No benefit for CPU-bound — you still have N cores |
| **Don't pool them** | They're cheap to create; pooling defeats the purpose |
| **Prefer `ReentrantLock` over `synchronized`** | `synchronized` can **pin** a virtual thread to its carrier |
| Avoid `ThreadLocal` | Millions of threads × ThreadLocal = memory problem |

**This is what makes thread-per-request viable again** and removes most of the reason to adopt reactive frameworks. See [Spring Web and Boot Internals](Spring%20Web%20and%20Boot%20Internals.md).

## Optional — Used Correctly

```java
// GOOD — a return type signalling possible absence
Optional<User> findByEmail(String email);
user.map(User::getName).orElse("Anonymous");
user.orElseThrow(() -> new UserNotFoundException(email));

// BAD
Optional<User> field;                    // never a field — not Serializable
void process(Optional<User> u);          // never a parameter — use overloads
if (opt.isPresent()) { opt.get(); }      // defeats the purpose — use map/ifPresent
opt.orElse(expensiveCall());             // ALWAYS evaluated — use orElseGet
```

**`orElse` vs `orElseGet` is the trap:** `orElse` evaluates its argument eagerly even when the Optional has a value. If that argument is a database call, you make it every time.

**`Optional` is for return types.** It exists to make absence explicit in a method signature, not to replace null everywhere.

## Text Blocks

```java
String query = """
    SELECT o.id, c.name
      FROM orders o
      JOIN customers c ON c.id = o.customer_id
     WHERE o.status = ?
    """;
```

Incidental leading whitespace is stripped based on the closing delimiter's position. Useful for SQL, JSON, and HTML.

## var

```java
var users = new ArrayList<User>();                    // clear
var result = service.process(input);                  // unclear — what type?
```

**Use it when the type is obvious from the right-hand side.** Local variables only — not fields, parameters, or return types. It's inferred at compile time, so Java remains statically typed.

## Other Additions Worth Knowing

| Feature | Version |
|---|---|
| `List.of` / `Map.of` — **immutable, reject nulls** | 9 |
| `Stream.toList()` — **returns unmodifiable** | 16 |
| `String.repeat`, `strip`, `isBlank`, `lines` | 11 |
| `HttpClient` — HTTP/2, async, built in | 11 |
| `teeing` collector | 12 |
| `Stream.takeWhile` / `dropWhile` | 9 |
| Helpful NullPointerExceptions | 14 |
| `SequencedCollection` — `getFirst()`, `reversed()` | 21 |

**`List.of()` returns an immutable list that rejects nulls** — different from `Arrays.asList()` (fixed-size, mutable elements, allows nulls) and `new ArrayList<>()`. Confusing them causes `UnsupportedOperationException` at runtime.

**Helpful NPEs (Java 14+)** tell you exactly which reference was null in a chained expression — a genuine debugging improvement worth mentioning.

## What To Say In An Interview

When modelling data: **"I'd use a record for this value object."**
When modelling a closed set of types: **"I'd make this a sealed interface so the switch is exhaustive."**
When handling high-concurrency I/O: **"On Java 21 I'd use virtual threads rather than a large platform-thread pool."**

Each signals current knowledge in one sentence.

## Common Mistakes

- `Optional` as a field or parameter
- `orElse` with an expensive argument
- `isPresent()` + `get()` instead of functional composition
- Pooling virtual threads
- `synchronized` in virtual-thread code (pinning)
- `var` where the type isn't obvious
- Assuming `List.of()` is mutable
- Using records where a Builder is needed

## Related Topics

- [Streams](Streams.md)
- [Threads and Lifecycle](Threads%20and%20Lifecycle.md)
- [equals and hashCode](Equals%20and%20HashCode.md)
- [Visitor](Visitor.md)

## Revision Summary

Records eliminate value-object boilerplate correctly. Sealed types plus pattern matching give exhaustive, compiler-checked switches and largely replace Visitor. Virtual threads make blocking I/O cheap and thread-per-request viable again. Use `Optional` for return types only, and prefer `orElseGet` over `orElse`.

## Quick Recall

- LTS: 8, 11, 17, **21**
- Records: correct `equals`/`hashCode`, but no optional params — Builder still needed
- **Sealed + pattern matching = exhaustive switch**, replaces Visitor
- Virtual threads: I/O only, don't pool, avoid `synchronized`
- `Optional` for return types; **`orElseGet`, not `orElse`**
- `List.of()` immutable and null-hostile
- `var` only when the type is obvious
