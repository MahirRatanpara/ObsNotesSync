# Records, Enums and Sealed Types

## Why It Matters

Three features that changed how modern Java models data. Together with pattern matching they replace a large amount of boilerplate and several classic design patterns.

---

# Records

## What They Are

A transparent carrier for immutable data.

```java
public record Point(int x, int y) { }
```

The compiler generates:
- `private final` fields
- A **canonical constructor**
- Accessors named `x()` and `y()` — **not** `getX()`
- `equals` and `hashCode` over **all components**
- `toString`

**This eliminates the entire [equals/hashCode](../Language%20Core/Equals%20and%20HashCode.md) bug class for value types**, which is the strongest reason to use them.

## Constructors

```java
public record Range(int lo, int hi) {
    // COMPACT constructor — validate and normalise
    public Range {
        if (lo > hi) throw new IllegalArgumentException("lo > hi");
        lo = Math.max(lo, 0);          // assign to the PARAMETER
    }

    // Additional constructor must delegate to the canonical one
    public Range(int hi) { this(0, hi); }

    // Static factory
    public static Range of(int lo, int hi) { return new Range(lo, hi); }
}
```

**In a compact constructor you assign to the parameter, not `this.field`.** The compiler assigns the (possibly modified) parameters to the fields afterwards. Non-obvious, and a common stumbling block.

## Deep Immutability

**Records are only shallowly immutable.**

```java
record Team(String name, List<Player> players) { }   // NOT immutable — caller keeps the list
```

```java
record Team(String name, List<Player> players) {
    Team { players = List.copyOf(players); }         // now deeply immutable (given immutable Players)
}
```

**A record with a mutable component is a standard interview trap.** See [Immutability and Defensive Copying](Immutability%20and%20Defensive%20Copying.md).

## What Records Cannot Do

| Restriction | Detail |
|---|---|
| Implicitly `final` | Cannot be extended |
| Cannot extend a class | Already extends `java.lang.Record` |
| **No additional instance fields** | Only the declared components |
| Cannot be abstract | |
| **Cannot express optional parameters** | A 10-component record has the telescoping problem |

**Records do not replace Builder.** That's the answer when someone claims they do — a record with ten components needs a builder just as much as a class would.

Records **can** implement interfaces, declare static members, and override the generated methods.

## When To Use

**Good:** DTOs, value objects, query results, compound map keys, tuple returns, events, pattern-matching targets.

**Not:** entities with identity and lifecycle (JPA needs a no-arg constructor and mutability), anything with many optional fields, anything needing inheritance.

---

# Enums

## More Than Constants

```java
public enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    EARTH  (5.976e+24, 6.37814e6);

    private final double mass, radius;

    Planet(double mass, double radius) {   // constructor is implicitly private
        this.mass = mass; this.radius = radius;
    }

    public double surfaceGravity() { return 6.67300E-11 * mass / (radius * radius); }
}
```

**Enums are full classes** — fields, constructors, methods, interfaces.

## Constant-Specific Behaviour

```java
public enum Operation {
    PLUS("+")  { public double apply(double x, double y) { return x + y; } },
    MINUS("-") { public double apply(double x, double y) { return x - y; } };

    private final String symbol;
    Operation(String symbol) { this.symbol = symbol; }
    public abstract double apply(double x, double y);
}
```

**This replaces a `switch` on the enum with polymorphism.** Adding a constant *forces* you to implement the method — the compiler enforces completeness, which a `switch` does not.

**Enums with abstract methods are often the cleanest Java expression of [Strategy](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Strategy.md) or [State](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/State.md)** — type-safe, exhaustive, serialisable, no allocation.

## Enum as Singleton

```java
public enum Config {
    INSTANCE;
    public void doWork() { }
}
```

**Joshua Bloch's recommended singleton.** The JVM guarantees a single instance even under **serialisation and reflection** — the two attacks that break a conventional singleton. See [Singleton](../../03%20Low%20Level%20Design/Design%20Patterns/Creational/Singleton.md).

## EnumMap and EnumSet

```java
EnumMap<Day, String> schedule = new EnumMap<>(Day.class);
EnumSet<Day> weekend = EnumSet.of(Day.SAT, Day.SUN);
EnumSet<Day> weekdays = EnumSet.complementOf(weekend);
```

| | Implementation | Why it's fast |
|---|---|---|
| **`EnumMap`** | **A plain array indexed by `ordinal()`** | No hashing, no collisions — array access |
| **`EnumSet`** | **A bit vector** (`long` for ≤64 constants) | Set operations are single CPU instructions |

**Always prefer these over `HashMap`/`HashSet` for enum keys.** `EnumSet.contains` is a bit test; `HashSet.contains` hashes and probes. The difference is large and free.

## Enum Traps

**`ordinal()` is fragile** — reordering constants silently changes every persisted value. **Never persist `ordinal()`.** Store `name()`, or an explicit code field.

**`values()` returns a defensive copy on every call** — it allocates. Cache it in a `private static final` array if called in a hot loop.

**`valueOf` throws** `IllegalArgumentException` for unknown names. For parsing external input, build a lookup map and return `Optional`.

**Enums and `switch`:** since Java 21, a `switch` over an enum can be exhaustive without a `default`, which means adding a constant becomes a compile error rather than a silent fallthrough. **Omit `default` deliberately** to get that safety.

---

# Sealed Types

## What They Are

```java
public sealed interface Shape permits Circle, Square, Triangle { }

public record Circle(double radius)   implements Shape { }
public record Square(double side)     implements Shape { }
public record Triangle(double b, double h) implements Shape { }
```

Restricts which types may implement or extend, so the compiler knows the complete set.

**Every permitted subtype must be `final`, `sealed`, or `non-sealed`**, and must be in the same module (or same package if unnamed). The `permits` clause can be omitted when all subtypes are in the same file.

## Why They Matter — Exhaustive Switches

```java
double area(Shape s) {
    return switch (s) {
        case Circle c   -> Math.PI * c.radius() * c.radius();
        case Square q   -> q.side() * q.side();
        case Triangle t -> 0.5 * t.b() * t.h();
    };                          // NO default needed — compiler verifies exhaustiveness
}
```

**Adding a new `Shape` breaks compilation everywhere it's switched on** — which is exactly what you want. Without sealing you'd need a `default` that silently does the wrong thing for the new type.

## Sealed + Records = Algebraic Data Types

```java
sealed interface Result<T> permits Success, Failure { }
record Success<T>(T value)      implements Result<T> { }
record Failure<T>(Exception e)  implements Result<T> { }

String describe(Result<String> r) {
    return switch (r) {
        case Success<String>(var value) -> "ok: " + value;      // record pattern
        case Failure<String>(var e)     -> "failed: " + e.getMessage();
    };
}
```

**This is the closest Java gets to a sum type**, and it's the modern replacement for the [Visitor pattern](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Visitor.md) — compile-time exhaustiveness with none of the double-dispatch ceremony.

## The Trade-Off

**Sealing inverts extensibility.** A sealed hierarchy is cheap to add *operations* to (a new switch) and expensive to add *types* to (edit every switch). An open hierarchy is the reverse.

**Seal when the set of types is genuinely closed** — results, states, AST nodes, protocol messages. Don't seal a plugin interface.

This is the **expression problem**, and naming it is a strong signal.

## Choosing Between the Three

| Need | Use |
|---|---|
| Immutable data carrier | **Record** |
| A fixed set of named constants with behaviour | **Enum** |
| A fixed set of *shapes* with different data | **Sealed interface + records** |
| An open set of implementations | Plain interface |
| Singleton | **Enum** |
| Map/set keyed by enum | **`EnumMap` / `EnumSet`** |

**Enum vs sealed:** an enum is a fixed set of *instances*; a sealed hierarchy is a fixed set of *types*, each able to carry different data. `Status.ACTIVE` versus `Circle(radius)` — that's the distinction.

## Common Mistakes

- Assuming a record with a collection component is immutable
- Claiming records replace Builder
- Using records for JPA entities
- **Persisting `ordinal()`**
- `HashMap`/`HashSet` for enum keys instead of `EnumMap`/`EnumSet`
- Calling `values()` in a hot loop
- Adding `default` to an exhaustive switch, losing compile-time safety
- Sealing an interface intended for external extension

## Related Topics

- [Immutability and Defensive Copying](Immutability%20and%20Defensive%20Copying.md)
- [Abstract Classes and Interfaces](Abstract%20Classes%20and%20Interfaces.md)
- [Modern Java Features](../Language%20Core/Modern%20Java%20Features.md)
- [Visitor](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Visitor.md)

## Revision Summary

Records generate correct `equals`/`hashCode` for value types but are only shallowly immutable and can't express optional parameters. Enums are full classes; constant-specific bodies replace switches, and `EnumMap`/`EnumSet` are array- and bitset-backed. Sealed types close a hierarchy so switches are compiler-verified exhaustive, replacing Visitor.

## Quick Recall

- Records: `final`, no extra fields, accessors are `x()` not `getX()`
- **Compact constructor assigns to the parameter**
- **Records are shallowly immutable** — `List.copyOf` in the constructor
- Records **don't replace Builder**
- Enums are full classes; **constant-specific bodies force completeness**
- **Enum is the safest singleton** — survives serialisation and reflection
- **`EnumMap` = array by ordinal; `EnumSet` = bit vector**
- **Never persist `ordinal()`**; `values()` allocates
- Sealed → **exhaustive switch, no `default`**; adding a type breaks compilation
- Sealed + records = algebraic data types, replacing Visitor
