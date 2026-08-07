# Object Class Contract

## Why It Matters

Every class inherits these five methods, and getting them wrong breaks collections, debugging and cleanup in ways that surface far from the mistake.

## The Methods

| Method | Default | Override when |
|---|---|---|
| **`equals`** | Reference identity | Value semantics |
| **`hashCode`** | Identity hash | **Whenever you override `equals`** |
| **`toString`** | `ClassName@hexHash` | **Almost always** |
| `clone` | Shallow field copy | **Almost never — use a copy constructor** |
| `finalize` | No-op | **Never — removed in Java 18** |

Plus `getClass`, `wait`, `notify`, `notifyAll` — which you never override.

## equals and hashCode

Covered fully in [equals and hashCode](../Language%20Core/Equals%20and%20HashCode.md). The one-line summary:

**Equal objects must have equal hash codes**, or hash-based lookups silently fail. Override both, over the same fields, and never use a mutable field in `hashCode` for an object used as a map key.

## toString — Underrated

```java
@Override public String toString() {
    return "Order[id=%s, status=%s, total=%d]".formatted(id, status, totalCents);
}
```

**Every log line, exception message, and debugger view uses it.** A default `Order@3f1a2b` in a production log is an hour of wasted debugging.

**Rules:**

| Rule | Reason |
|---|---|
| **Include all interesting fields** | That's the point |
| **Never include secrets** | Passwords, tokens, PII end up in logs |
| Don't rely on the format | Callers must not parse it — expose accessors instead |
| Make it cheap and non-throwing | It runs in exception paths |
| Don't recurse into large graphs | A `toString` that walks a 10,000-element list is a performance bug |

**A `toString` that throws is genuinely dangerous** — it can mask the original exception you were trying to log. Null-check inside it.

**Records generate a good `toString` automatically**, which is another reason to use them for value types.

**Watch for cycles:** if `Order.toString` prints its `Customer` and `Customer.toString` prints its `Orders`, you get a `StackOverflowError` in your logging path. Print IDs, not nested objects.

## clone — Avoid It

```java
class Foo implements Cloneable {
    @Override public Foo clone() {
        try { return (Foo) super.clone(); }
        catch (CloneNotSupportedException e) { throw new AssertionError(e); }
    }
}
```

**`Cloneable` is broken by design:**

| Problem | Detail |
|---|---|
| **A marker interface with no `clone()` method** | It doesn't declare the contract it enables |
| `Object.clone()` is `protected` | You must override and widen it |
| **Shallow by default** | Nested mutable objects are shared |
| **Bypasses constructors** | Invariants aren't enforced; `final` fields can't be assigned |
| Throws a checked exception | For something that "can't fail" |

**Use a copy constructor or static factory instead:**

```java
public Order(Order other) {
    this.id = other.id;
    this.items = List.copyOf(other.items);      // explicit deep copy
}
// or
public static Order copyOf(Order other) { ... }
```

**Copy constructors are explicit, work with `final` fields, enforce invariants, and can return a different type.** Saying "I'd use a copy constructor rather than `Cloneable`, because `Cloneable` is a broken marker interface that bypasses constructors" is a strong answer.

**Shallow vs deep** is the standard follow-up: `super.clone()` copies field values, so an `ArrayList` field is shared between original and copy. Mutating one mutates both.

**Arrays are the exception** — `array.clone()` is idiomatic and fine (still shallow for object arrays).

## finalize — Removed

Deprecated in Java 9, **removed in Java 18**.

| Problem | Detail |
|---|---|
| Unpredictable timing | May run late, or never |
| **Costs two GC cycles** | One to discover, one to reclaim |
| **Can resurrect objects** | `this` can escape to a static field |
| Exceptions swallowed silently | |
| Unbounded finalizer queue | Can starve |
| **Finalizer attacks** | On partially-constructed objects |

**Use `AutoCloseable` with try-with-resources**, and `Cleaner` as a backstop. See [Reference Types and Cleaners](../JVM%20and%20Memory/Reference%20Types%20and%20Cleaners.md).

## getClass vs instanceof

```java
obj.getClass() == other.getClass()     // exact type
obj instanceof Order                   // type or subtype
```

**In `equals`, `getClass()` preserves symmetry; `instanceof` can break it** when subclasses add value components. See [equals and hashCode](../Language%20Core/Equals%20and%20HashCode.md).

**`getClass()` on a proxied object returns the proxy class**, not your class — which is why `getClass() == other.getClass()` fails for Hibernate entities and Spring beans. Hibernate documentation specifically recommends `instanceof` for entity `equals` for this reason.

## wait, notify, notifyAll

Live on `Object` because **every object has a monitor**.

```java
synchronized (lock) {
    while (!condition) lock.wait();     // WHILE, never if
    proceed();
}
```

**Three rules:**
1. **Must hold the monitor**, or `IllegalMonitorStateException`
2. **Always loop** — spurious wakeups are permitted, and another thread may consume the condition first
3. **Prefer `notifyAll()`** — `notify()` wakes one arbitrary waiter, which may be waiting on a different condition

**Prefer `java.util.concurrent`.** `BlockingQueue`, `CountDownLatch`, `Condition` and `CompletableFuture` are correct by construction. Hand-rolled `wait`/`notify` is a code smell in modern Java. See [Synchronisation and Locks](../Concurrency/Synchronisation%20and%20Locks.md).

## Records Handle Most of This

```java
public record Order(String id, Status status, long totalCents) { }
```

Generates `equals`, `hashCode` and `toString` correctly over all components — eliminating the entire bug class.

**They do not generate `clone`** (unnecessary — they're immutable) or `finalize`.

## The Checklist

For any value class:

- [ ] `equals` and `hashCode` overridden together, over the same fields
- [ ] Those fields are **immutable**
- [ ] `equals` takes `Object` (not your type — that's an overload)
- [ ] `@Override` on all of them
- [ ] `toString` includes the interesting fields, **excludes secrets**, doesn't throw or recurse
- [ ] `Comparable` consistent with `equals`, or documented if not
- [ ] Copy constructor rather than `clone`
- [ ] `AutoCloseable` rather than `finalize`
- [ ] **Or just use a record**

## Common Mistakes

- Overriding `equals` without `hashCode`
- `public boolean equals(MyType o)` — an overload, not an override
- Default `toString`, making logs useless
- Secrets in `toString`
- `toString` that recurses into a bidirectional relationship → `StackOverflowError`
- Implementing `Cloneable` without understanding shallow copying
- Any use of `finalize`
- `getClass()` comparison on proxied entities
- `if` instead of `while` around `wait()`

## Related Topics

- [equals and hashCode](../Language%20Core/Equals%20and%20HashCode.md)
- [Immutability and Defensive Copying](Immutability%20and%20Defensive%20Copying.md)
- [Reference Types and Cleaners](../JVM%20and%20Memory/Reference%20Types%20and%20Cleaners.md)
- [Records Enums and Sealed Types](Records%20Enums%20and%20Sealed%20Types.md)

## Revision Summary

Override `equals` and `hashCode` together over immutable fields, and always write a useful `toString` that excludes secrets and cannot throw or recurse. Avoid `Cloneable` in favour of a copy constructor, never use `finalize`, and prefer `java.util.concurrent` over `wait`/`notify`. Records give you the first three correctly for free.

## Quick Recall

- **`equals` + `hashCode` together, same fields, immutable**
- `equals` must take **`Object`** or it's an overload
- **`toString` on everything** — no secrets, no throwing, no recursion
- **`Cloneable` is broken** → copy constructor
- `super.clone()` is **shallow**
- **`finalize` removed in Java 18** → `AutoCloseable` + `Cleaner`
- `getClass()` breaks on **proxied entities** — use `instanceof` there
- `wait()` in a **`while`**, prefer `notifyAll`, prefer `java.util.concurrent`
- **Records generate the first three correctly**
