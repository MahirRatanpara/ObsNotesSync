# Exceptions and Generics

## Why It Matters

Two areas where interviewers probe design judgement rather than syntax: when to use checked exceptions, and why generic collections behave unintuitively.

## Exception Hierarchy

```
Throwable
├── Error              — JVM problems; do NOT catch (OutOfMemoryError, StackOverflowError)
└── Exception
    ├── RuntimeException — UNCHECKED (NullPointerException, IllegalArgumentException)
    └── everything else  — CHECKED (IOException, SQLException)
```

| | Checked | Unchecked |
|---|---|---|
| Must declare or catch | **Yes** | No |
| Represents | Recoverable, expected conditions | Programming errors |
| Modern opinion | **Largely disliked** | Preferred |

**The modern position:** checked exceptions leak implementation details through APIs, don't compose with lambdas or streams, and are routinely swallowed. Kotlin removed them entirely; Spring wraps `SQLException` into unchecked `DataAccessException`.

Say this if asked — the naive answer is "checked for recoverable, unchecked for bugs", but the informed answer acknowledges the industry has largely moved on.

## try-with-resources

```java
try (var conn = dataSource.getConnection();
     var stmt = conn.prepareStatement(sql)) {
    return stmt.executeQuery();
}   // closed in REVERSE order, even on exception
```

**Why it beats a `finally` block:** in a manual `finally`, if `close()` throws it *replaces* the original exception and you lose the real cause. try-with-resources keeps the original and attaches the close failure as a **suppressed** exception (`getSuppressed()`).

## Exception Anti-Patterns

```java
catch (Exception e) { }                        // swallowing — the worst
catch (Exception e) { e.printStackTrace(); }   // not logging properly
catch (Exception e) { throw new RuntimeException(); }   // LOSES THE CAUSE
```

Always chain the cause:
```java
catch (SQLException e) { throw new DataAccessException("loading user " + id, e); }
```

**Never catch `Throwable` or `Error`** — you cannot meaningfully recover from `OutOfMemoryError`, and catching it hides the real failure.

**`finally` overrides everything:** a `return` or `throw` inside `finally` discards a pending exception. Never return from `finally`.

## Generics: Type Erasure

Generics are compile-time only. At runtime `List<String>` and `List<Integer>` are both `List`.

Consequences:

```java
List<String> a = new ArrayList<>();
List<Integer> b = new ArrayList<>();
a.getClass() == b.getClass();          // true

new T();                               // ILLEGAL — no runtime type
new T[10];                             // ILLEGAL
if (x instanceof List<String>) { }     // ILLEGAL
void f(List<String> l) {}
void f(List<Integer> l) {}             // ILLEGAL — same erasure
```

**Workaround for creation:** pass a `Class<T>` token or a `Supplier<T>`.

**Erasure exists for backward compatibility** with pre-generics code — that's the "why".

## Invariance

```java
List<Object> list = new ArrayList<String>();   // COMPILE ERROR
```

**`List<String>` is not a subtype of `List<Object>`**, even though `String` is a subtype of `Object`.

If it were allowed:
```java
List<Object> l = stringList;   // hypothetically
l.add(42);                     // would corrupt the String list
```

Arrays *are* covariant, which is why this compiles but throws at runtime:
```java
Object[] arr = new String[10];
arr[0] = 42;                   // ArrayStoreException
```

**Generics chose compile-time safety; arrays chose runtime checking.** That comparison is a strong answer.

## PECS — Producer Extends, Consumer Super

```java
// Producer — you READ from it
void copyFrom(List<? extends Number> src) {
    Number n = src.get(0);     // reading is safe
    // src.add(...);           // ILLEGAL — element type unknown
}

// Consumer — you WRITE to it
void copyTo(List<? super Integer> dst) {
    dst.add(42);               // writing Integer is safe
    Object o = dst.get(0);     // reads come back as Object only
}
```

**Mnemonic: PECS — Producer Extends, Consumer Super.**

`Collections.copy(List<? super T> dest, List<? extends T> src)` uses both in one signature — the canonical example.

**Why can't you add to `? extends Number`?** The list might be a `List<Integer>`; adding a `Double` would corrupt it. The compiler only knows the element is *some* subtype of `Number`, not which.

## Bounded Type Parameters

```java
<T extends Comparable<T>> T max(List<T> list) { }        // T must be comparable
<T extends Number & Serializable> void f(T t) { }        // multiple bounds
```

## Common Questions

- *Checked vs unchecked?* — must-declare vs not; state the modern criticism of checked.
- *What is type erasure?* — generics are compile-time only, erased at runtime for backward compatibility.
- *Why is `List<String>` not a `List<Object>`?* — it would permit heap pollution.
- *What is PECS?* — producer extends (read), consumer super (write).
- *Why can't you `new T()`?* — no runtime type information.
- *Arrays vs generics?* — covariant with runtime checks vs invariant with compile-time checks.
- *Why try-with-resources?* — the original exception is preserved; close failures are suppressed, not substituted.

## Common Mistakes

- Swallowing exceptions
- Rethrowing without the cause
- Catching `Exception` where a specific type is meant
- Returning from `finally`
- Using raw types (`List` instead of `List<String>`)
- Trying to overload on generic type parameters

## Related Topics

- [equals and hashCode](Equals%20and%20HashCode.md)
- [Collections Overview](../Collections/Collections%20Overview.md)
- [Streams](../Streams%20and%20Functional/Streams.md)

## Revision Summary

Checked exceptions are increasingly avoided; always chain causes and use try-with-resources so the original exception survives. Generics are erased at compile time, which makes them invariant and blocks `new T()`. Use PECS for flexible APIs.

## Quick Recall

- Never swallow; always pass the cause
- try-with-resources closes in reverse and suppresses close failures
- Never return from `finally`
- Erasure → no `new T()`, no `instanceof List<String>`
- Generics invariant; arrays covariant (ArrayStoreException)
- PECS: producer `extends`, consumer `super`
