# Java Version Guide: 8 to 25

> What changed, when, and what actually matters. Use this to answer "what's new in Java?" without waffling.

## Why It Matters

Answering a design question with Java 8 idioms when records and sealed types exist reads as stale. Conversely, naming a preview feature as though it's final reads as careless.

## The Release Model

Since Java 9: a release every **six months**, with an **LTS every two years** (previously three).

| LTS | Released | Support |
|---|---|---|
| **8** | 2014 | Extended; still widely deployed |
| **11** | Sept 2018 | Widely deployed |
| **17** | Sept 2021 | Very widely deployed |
| **21** | Sept 2023 | **Current mainstream target** |
| **25** | Sept 2025 | Newest LTS |

**Most production systems are on 17 or 21.** Knowing 8 → 21 well matters more than knowing every 25 preview feature.

**Preview vs incubator vs final:**
- **Preview** — complete but may change; needs `--enable-preview`
- **Incubator** — an API in a separate module, expected to change
- **Final** — stable and permanent

**Features move between these across releases.** Verify against your JDK's release notes before relying on any preview API.

---

## Java 8 (2014) — The Big One

Still the most important release.

| Feature | Notes |
|---|---|
| **Lambdas** | Compile via `invokedynamic` |
| **Streams** | Lazy pipelines |
| **`Optional`** | For return types |
| **Default and static interface methods** | Added so `Collection.stream()` could exist |
| **`java.time`** | Replaced the broken `Date`/`Calendar` |
| `CompletableFuture` | Composable async |
| `ConcurrentHashMap` rewrite | CAS + per-bin locking |
| Metaspace | Replaced PermGen |
| `StampedLock`, `LongAdder` | Concurrency additions |

**Default methods existed for backward compatibility**, not design elegance — that's the answer to "why were they added?"

## Java 9 (2017)

| Feature | Notes |
|---|---|
| **JPMS modules** | Ambitious; **low adoption in applications** |
| **Collection factories** | `List.of`, `Map.of` — immutable, null-hostile |
| **Compact strings** | `byte[]` + coder → **5–15% heap reduction** |
| Private interface methods | Share code between defaults |
| `Stream.takeWhile` / `dropWhile` / `iterate` with predicate | |
| `Optional.stream` / `ifPresentOrElse` | |
| `var` handles preview → JEP 193 `VarHandle` | Safe `Unsafe` replacement |
| G1 becomes the default collector | |

**Compact strings is the highest-impact change nobody mentions** — a free double-digit heap saving.

## Java 10–11

| Version | Feature |
|---|---|
| 10 | **`var`** for local variables; parallel full GC for G1 |
| **11 (LTS)** | **`HttpClient`** (HTTP/2, async, built in) |
| 11 | `String.strip`, `isBlank`, `lines`, `repeat` |
| 11 | `Files.readString` / `writeString` |
| 11 | Single-file source execution (`java Foo.java`) |
| 11 | **Flight Recorder open-sourced**; ZGC and Epsilon (experimental) |
| 11 | Applets, Java EE and CORBA modules **removed** |

**`strip` is Unicode-aware; `trim` is not.** A real behavioural difference, not a rename.

## Java 12–16

| Version | Feature |
|---|---|
| 12 | Switch expressions (preview); `Collectors.teeing` |
| 14 | **Switch expressions final**; **helpful NullPointerExceptions**; records (preview) |
| 15 | **Text blocks final**; sealed classes (preview); ZGC and Shenandoah production-ready |
| **16** | **Records final**; **pattern matching for `instanceof` final**; `Stream.toList()` |

**Helpful NPEs (14)** name the exact null expression in a chain — a genuine debugging improvement.

**`Stream.toList()` returns an unmodifiable list**, unlike `Collectors.toList()`. Know the difference.

## Java 17 (LTS, 2021)

| Feature | Notes |
|---|---|
| **Sealed classes final** | Enables exhaustive switches |
| Pattern matching for `switch` (preview) | |
| Enhanced pseudo-random generators | |
| Strong encapsulation of JDK internals | **Breaks reflective access to internals** |
| Security Manager deprecated | |

**Strong encapsulation is the migration pain point from 8/11** — libraries that reflected into `sun.misc.*` or `java.lang` internals stop working.

## Java 21 (LTS, 2023) — The Second Big One

| Feature | Notes |
|---|---|
| **Virtual threads final** | Thread-per-request scales again |
| **Pattern matching for `switch` final** | With guards (`when`) and `null` cases |
| **Record patterns final** | Destructuring |
| **Sequenced collections** | `getFirst`, `getLast`, `reversed` |
| **Generational ZGC** | Much better throughput than non-generational ZGC |
| Structured concurrency (preview) | |
| Scoped values (preview) | |
| String templates (preview) | *Later withdrawn — do not cite as coming* |

```java
// Java 21 pattern matching with guards and record patterns
String describe(Object o) {
    return switch (o) {
        case Integer i when i > 100  -> "big";
        case Integer i               -> "number " + i;
        case Point(int x, int y)     -> "point " + x + "," + y;   // record pattern
        case null                    -> "null";
        default                      -> "other";
    };
}
```

**Sequenced collections fixed a 25-year-old gap:** there was no uniform way to ask a `List`, `LinkedHashSet` or `LinkedHashMap` for its first element.

**String templates were previewed and then withdrawn.** Mentioning them as an upcoming feature is now wrong — a good example of why preview status matters.

## Java 22–24

| Version | Feature |
|---|---|
| 22 | **Foreign Function & Memory API final** — the `JNI` replacement |
| 22 | Unnamed variables and patterns (`_`) |
| 23 | Markdown documentation comments; ZGC generational by default |
| **24** | **`synchronized` no longer pins virtual threads (JEP 491)** |
| 24 | Ahead-of-time class loading and linking (Project Leyden) |
| 24 | Compact object headers (experimental); permanently disable Security Manager |

**JEP 491 is the important one** — it removed the biggest practical obstacle to virtual thread adoption, since library code was full of `synchronized`.

**The Foreign Function & Memory API** replaces JNI with a safe, pure-Java way to call native code and manage off-heap memory. Relevant if you're asked about native interop.

## Java 25 (LTS, Sept 2025)

| Feature | Status |
|---|---|
| **Scoped values** | **Final** |
| **Compact source files and instance `main`** | **Final** — simplified entry point for scripts and learners |
| **Module import declarations** | **Final** |
| **Flexible constructor bodies** | **Final** — statements before `super()` |
| Structured concurrency | Still preview |
| Primitive types in patterns | Preview |
| Stable values | Preview |
| **Compact object headers** | **Production** — meaningful heap savings |
| Generational Shenandoah | |
| Vector API | Still incubating |

**Flexible constructor bodies** finally allow validation before `super()`:
```java
class Sub extends Base {
    Sub(int value) {
        if (value < 0) throw new IllegalArgumentException();   // now legal BEFORE super()
        super(value);
    }
}
```

**Compact object headers** shrink the per-object header from 12–16 bytes to 8, which is a real heap saving on allocation-heavy workloads.

**Caveat:** preview and incubator status shifts between releases. Treat this table as a guide and confirm against the release notes for the exact JDK you target.

---

## What To Actually Say In An Interview

| Situation | Say |
|---|---|
| Modelling a value object | "I'd use a **record**." |
| A closed set of types | "A **sealed interface**, so the switch is exhaustive." |
| High-concurrency I/O | "On 21+, **virtual threads** rather than a large platform pool." |
| Type-dependent behaviour | "**Pattern matching** — it replaces the Visitor ceremony." |
| Building a string | "**Text block** if it's multi-line." |
| Cross-cutting request context | "**Scoped values** on 25, not `ThreadLocal`." |

Each is one sentence and signals currency.

## Migration Pain Points

| From → To | Breaks |
|---|---|
| 8 → 11 | Removed Java EE modules; `--illegal-access` warnings |
| **11 → 17** | **Strong encapsulation** of JDK internals; reflection into `sun.*` fails |
| 17 → 21 | Generally smooth |
| 21 → 25 | Generally smooth |

**The 11 → 17 jump is the hard one** because of strong encapsulation. Old libraries using `Unsafe` or reflecting into JDK internals need updating.

## Common Mistakes

- Citing preview features as final (string templates in particular)
- Claiming records replace Builder — they can't express optional parameters
- Saying modules are widely used in applications — they mostly aren't
- Not knowing `Stream.toList()` differs from `Collectors.toList()`
- Assuming `synchronized` still pins virtual threads on current JDKs
- Treating "Java 8" as current

## Related Topics

- [Modern Java Features](../Language%20Core/Modern%20Java%20Features.md)
- [Virtual Threads and Structured Concurrency](../Concurrency/Virtual%20Threads%20and%20Structured%20Concurrency.md)
- [Java Modules JPMS](Java%20Modules%20JPMS.md)
- [Garbage Collection](../Garbage%20Collection/Garbage%20Collection.md)

## Revision Summary

Java 8 introduced lambdas, streams and `java.time`; 9 added modules and compact strings; 11 the HTTP client; 16–17 records, sealed types and pattern matching; 21 virtual threads and sequenced collections; 25 finalised scoped values and shipped compact object headers. The 11 → 17 migration is the hard one because of strong encapsulation.

## Quick Recall

- LTS: **8, 11, 17, 21, 25**; six-month cadence, LTS every two years
- 8: lambdas, streams, `java.time`, default methods (**for compatibility**)
- 9: modules, **compact strings (5–15% heap)**, `List.of`
- 11: `HttpClient`, `strip`, JFR
- 16–17: **records, pattern matching, sealed**
- **21: virtual threads, sequenced collections, generational ZGC**
- **24: `synchronized` no longer pins virtual threads**
- 25: scoped values final, compact object headers, flexible constructor bodies
- **String templates were withdrawn** — don't cite them
- 11 → 17 breaks reflective access to JDK internals
