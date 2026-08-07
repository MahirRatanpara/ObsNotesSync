# Builder

## Why It Matters

The answer to telescoping constructors and objects with many optional fields — and the pattern most likely to appear in a real code review.

## The Problem

```java
// Telescoping constructors — unreadable and error-prone
new Pizza(12, true, false, true, false, true);   // what are these?
new User("Mahir", null, null, 30, null, true, null);
```

Two same-typed adjacent parameters can be swapped and it still compiles. That's a runtime bug the compiler can't catch.

## The Solution

```java
public final class Pizza {
    private final int size;
    private final boolean cheese, pepperoni, mushroom;

    private Pizza(Builder b) {
        this.size = b.size; this.cheese = b.cheese;
        this.pepperoni = b.pepperoni; this.mushroom = b.mushroom;
    }

    public static Builder builder(int size) { return new Builder(size); }

    public static class Builder {
        private final int size;              // required → constructor arg
        private boolean cheese, pepperoni, mushroom;   // optional → setters

        Builder(int size) { this.size = size; }

        public Builder cheese(boolean v)    { this.cheese = v; return this; }
        public Builder pepperoni(boolean v) { this.pepperoni = v; return this; }
        public Builder mushroom(boolean v)  { this.mushroom = v; return this; }

        public Pizza build() {
            if (size <= 0) throw new IllegalArgumentException("size must be positive");
            return new Pizza(this);
        }
    }
}

Pizza p = Pizza.builder(12).cheese(true).mushroom(true).build();
```

**Two details interviewers look for:**

1. **Required fields go in the builder's constructor**, optional ones in setter methods. This makes it impossible to build an invalid object.
2. **Validate in `build()`**, not in each setter — cross-field invariants ("end must be after start") can only be checked once everything is set.

## Why It Produces Immutable Objects

The product's fields are `final` and its constructor is private. Nothing can mutate it after construction, so it's inherently thread-safe. This is a major reason to prefer Builder over setters.

**The builder itself is not thread-safe** — don't share one across threads.

## Builder vs Alternatives

| Approach | Readability | Immutability | Compile-time safety |
|---|---|---|---|
| Telescoping constructors | Poor | Yes | Weak (swappable params) |
| JavaBeans setters | Good | **No** — object is mutable and temporarily invalid | Weak |
| **Builder** | **Good** | **Yes** | Good |
| Java 16 `record` | Good | Yes | Good, but **no optional fields** |

**Records don't replace Builder.** A record with 10 components has the same telescoping problem. Records plus a builder is a fine combination.

## Step Builder (compile-time enforcement)

If required fields must be set in order, return a *different interface* from each step so the compiler enforces the sequence:

```java
interface SizeStep  { ToppingStep size(int cm); }
interface ToppingStep { BuildStep cheese(boolean v); }
interface BuildStep { Pizza build(); }
```

`build()` isn't reachable until the required steps are done. Strong signal if you mention it; overkill for most cases.

## Director (the GoF part people forget)

GoF's Builder includes a **Director** that encapsulates common construction recipes:

```java
class PizzaDirector {
    Pizza margherita(PizzaBuilder b) { return b.cheese(true).build(); }
}
```
Rarely used in modern Java — the fluent builder alone is usually enough — but knowing it exists distinguishes you from someone who only knows the Lombok version.

## Real Uses

`StringBuilder`, `Stream.Builder`, `HttpRequest.newBuilder()` (Java 11), `Locale.Builder`, `OkHttpClient.Builder`, Lombok's `@Builder`, protobuf message builders.

## When To Use

- More than ~4 constructor parameters
- Many optional parameters
- You want an immutable result
- Construction requires validation across fields

## When Not To Use

- 2–3 required parameters — a constructor is clearer
- Simple DTOs — a record is better

## Common Questions

- *Builder vs setters?* — Builder yields an immutable object that is never in a partially-valid state.
- *Where do you validate?* — in `build()`, for cross-field invariants.
- *Is the builder thread-safe?* — no; the product is.
- *Does `record` make Builder obsolete?* — no; records don't solve optional parameters.

## Common Mistakes

- Validating in setters instead of `build()`
- Making the product mutable, discarding the main benefit
- A public product constructor, letting callers bypass the builder
- Reusing one builder instance to create multiple objects without resetting

## Related Topics

- [Factory Method](Factory%20Method.md)
- [Prototype](Prototype.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)

## Revision Summary

Fluent step-by-step construction producing an immutable object. Required fields in the builder's constructor, optional as methods, validation in `build()`. Records don't replace it because they can't express optional parameters.

## Quick Recall

- More than 4 params, or optional params → Builder
- Required → builder constructor; optional → methods
- Validate in `build()`
- Product immutable; builder not thread-safe
- `HttpRequest.newBuilder()`, `StringBuilder` in the JDK
