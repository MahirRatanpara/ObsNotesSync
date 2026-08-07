# Abstract Classes and Interfaces

## Why It Matters

The "abstract class vs interface" question is asked in almost every Java interview, and the correct answer changed materially when Java 8 added default methods.

## The Comparison

| | **Abstract class** | **Interface** |
|---|---|---|
| Multiple inheritance | **No** | **Yes** |
| Instance state (fields) | **Yes** | Only `public static final` constants |
| Constructor | Yes | **No** |
| Method bodies | Yes | `default`, `static` (8+), `private` (9+) |
| Access modifiers | Any | `public` (and `private` for helpers) |
| `protected` members | Yes | **No** |
| Semantics | **"is-a" with shared implementation** | **"can-do" capability** |

## The Decision Rule

**Choose an interface by default.** Choose an abstract class only when you genuinely need:

1. **Shared mutable state** (fields)
2. **A constructor** to enforce an invariant at construction
3. **`protected` members** for subclasses but not callers
4. A **Template Method** skeleton where the sequence is the valuable, invariant thing

**The reason to prefer interfaces:** a class can implement many, so you keep the single inheritance slot free. Committing it to an abstract class is a decision you can never undo without breaking every subclass.

## Interface Methods Since Java 8

```java
public interface Validator<T> {
    boolean isValid(T value);                                  // abstract

    default String describe() {                                // default
        return "Validator of " + getClass().getSimpleName();
    }

    static <T> Validator<T> alwaysTrue() {                     // static
        return v -> true;
    }

    private String helper() { return "internal"; }             // private (9+)
}
```

| Kind | Purpose |
|---|---|
| **`default`** | Add a method to an existing interface **without breaking implementers** |
| **`static`** | Utility/factory methods that belong to the type |
| **`private`** | Share code between defaults without exposing it |

**Why `default` was added:** Java 8 needed to add `stream()` to `Collection`. Without default methods, every existing implementation in the world would have failed to compile. **Backward compatibility was the driver, not design elegance** — and that's the answer interviewers want.

**This means an interface can now break the "no implementation" rule**, which is precisely why the abstract-class-vs-interface distinction narrowed.

## The Diamond Problem

Java forbids multiple *class* inheritance, so state can't diamond. But `default` methods reintroduced it for *behaviour*:

```java
interface A { default void go() { System.out.println("A"); } }
interface B { default void go() { System.out.println("B"); } }

class C implements A, B {
    // WON'T COMPILE without this
    @Override public void go() { A.super.go(); }
}
```

**Java forces explicit resolution** — it will not silently pick one. `A.super.go()` is the syntax for delegating to a specific interface's default.

**The resolution rules when there's no explicit override:**

1. **Classes win over interfaces** — a concrete method inherited from a superclass beats any default
2. **More specific interfaces win** — if `B extends A`, `B`'s default wins over `A`'s
3. **Otherwise: compile error**, and you must resolve it

Rule 1 is sometimes called "the class always wins", and it's worth knowing by name.

## Marker Interfaces vs Annotations

A **marker interface** has no members and exists to tag a type: `Serializable`, `Cloneable`, `RandomAccess`.

| | Marker interface | Annotation |
|---|---|---|
| Checked at | **Compile time** (it's a type) | Runtime (usually, via reflection) |
| Usable in a type signature | **Yes** | No |
| Carries data | No | **Yes** (elements) |

**Prefer annotations for metadata; prefer marker interfaces when you want the compiler to enforce it in a signature.** `RandomAccess` is a good example: `Collections.binarySearch` checks `instanceof RandomAccess` to choose an algorithm — a runtime check on a compile-time-meaningful type.

## Functional Interfaces

An interface with exactly **one abstract method** (SAM) can be implemented by a lambda.

```java
@FunctionalInterface
interface Transformer<T, R> {
    R apply(T input);                      // the single abstract method
    default Transformer<T,R> andThen(...) { ... }   // defaults don't count
    static Transformer<T,T> identity() { ... }      // statics don't count
}
```

**`@FunctionalInterface` is optional but recommended** — it makes the compiler enforce the single-abstract-method rule, so someone adding a second abstract method gets an error rather than silently breaking every lambda.

**Methods that override `Object`'s public methods don't count** toward the SAM total — which is why `Comparator` has both `compare` and `equals` declared yet remains functional.

## Abstract Classes In Practice

```java
public abstract class AbstractProcessor<T> {
    private final Validator<T> validator;              // shared state

    protected AbstractProcessor(Validator<T> v) {      // enforce an invariant
        this.validator = Objects.requireNonNull(v);
    }

    public final void process(T item) {                // FINAL — the skeleton
        if (!validator.isValid(item)) throw new IllegalArgumentException();
        doProcess(item);
        afterProcess(item);
    }

    protected abstract void doProcess(T item);         // must implement
    protected void afterProcess(T item) { }            // hook — may override
}
```

**Three things this demonstrates:**
- The template method is **`final`**, so subclasses can't change the sequence
- Steps are **`protected`**, not `public` — extension points, not API
- A **hook** with an empty default lets subclasses opt in

See [Template Method](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Template%20Method.md).

## The Abstract Skeleton Pattern

The JDK uses interface **plus** abstract skeletal implementation together:

```
Collection (interface)  ←  AbstractCollection (skeleton)
List (interface)        ←  AbstractList (skeleton)
Map (interface)         ←  AbstractMap (skeleton)
```

**You get both benefits:** implementers may take the skeleton for convenience, or implement the interface directly if they already extend something else.

**This is the recommended way to ship an abstract type.** Publish the interface; provide the skeleton as a courtesy. Naming this pattern is a strong signal.

## Sealed Interfaces (Java 17+)

```java
public sealed interface Shape permits Circle, Square, Triangle { }
```

Restricts implementers to a known set, enabling **exhaustive switches** the compiler verifies:

```java
double area(Shape s) {
    return switch (s) {
        case Circle c   -> Math.PI * c.radius() * c.radius();
        case Square q   -> q.side() * q.side();
        case Triangle t -> 0.5 * t.base() * t.height();
    };                     // no default needed
}
```

**Sealed types plus records model algebraic data types**, and largely replace the [Visitor pattern](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Visitor.md) with compile-time safety and none of the double-dispatch ceremony.

**Permitted subtypes must be `final`, `sealed`, or `non-sealed`** and must be in the same module (or package, if unnamed).

## Interface Evolution — What Breaks

| Change | Safe? |
|---|---|
| Add a `default` method | **Usually** — unless an implementer already has a clashing method |
| Add a `static` method | Yes |
| **Add an abstract method** | **No** — breaks every implementer |
| Remove any method | No |
| Add a superinterface | Usually yes |

**Even adding a `default` can break things:** if a class implements two interfaces and you add a default that now clashes with another, it stops compiling. Backward compatibility is *usually* preserved, not always.

## Common Mistakes

- Choosing an abstract class when an interface would do, burning the inheritance slot
- Constants in interfaces (the "constant interface antipattern" — use a final class or enum)
- Not marking the template method `final`
- `public` step methods, exposing internals as API
- Omitting `@FunctionalInterface` on an intended SAM type
- Assuming Java picks a default automatically in a diamond
- Adding an abstract method to a published interface

## Related Topics

- [Inheritance and Polymorphism](Inheritance%20and%20Polymorphism.md)
- [Lambdas and Functional Interfaces](../Streams%20and%20Functional/Lambdas%20and%20Functional%20Interfaces.md)
- [Template Method](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Template%20Method.md)
- [SOLID Principles](../../03%20Low%20Level%20Design/SOLID/SOLID%20Principles.md)

## Revision Summary

Interfaces express capability and support multiple inheritance; abstract classes carry state, constructors and `protected` members. Default methods exist for backward compatibility, and they reintroduced the diamond — which Java forces you to resolve explicitly, with classes winning over interfaces. Prefer an interface plus an optional skeletal abstract class.

## Quick Recall

- **Interface by default**; abstract class for state, constructor, or `protected`
- `default` exists so `Collection.stream()` could be added — **backward compatibility**
- Diamond → **explicit `A.super.go()`**; class beats interface; more specific interface wins
- SAM = one abstract method; `Object` methods don't count
- **`@FunctionalInterface`** makes the compiler enforce it
- Template method **`final`**, steps `protected`, hooks with defaults
- Interface + `Abstract*` skeleton is the JDK's pattern
- **Sealed + records + switch replaces Visitor**
- Adding an abstract method to a published interface breaks everyone
