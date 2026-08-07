# OOP Core Concepts

## Why It Matters

The vocabulary of every LLD interview. Interviewers probe the distinctions (abstraction vs encapsulation, overloading vs overriding) because candidates routinely blur them.

## The Four Pillars

| Pillar | Definition | In practice |
|---|---|---|
| **Encapsulation** | Bundle data with the methods that operate on it; hide internal state | Private fields, public behaviour |
| **Abstraction** | Expose *what* something does, hide *how* | Interfaces, abstract classes |
| **Inheritance** | A type derives behaviour from another | `extends` |
| **Polymorphism** | One interface, many implementations | Dynamic dispatch |

### Abstraction vs Encapsulation

Frequently confused, cleanly separable:

- **Abstraction** is a *design-time* concern: what should the caller see? It removes irrelevant detail. `List` abstracts away whether it's an array or nodes.
- **Encapsulation** is an *implementation* concern: protect internal state from outside modification. Private fields with validating setters.

**One sentence:** abstraction hides complexity; encapsulation hides data.

## Polymorphism: Two Kinds

| | Compile-time (overloading) | Runtime (overriding) |
|---|---|---|
| Resolved | At compile time, by static type | At runtime, by actual object |
| Signature | Must differ | Must match |
| Also called | Static / ad-hoc | Dynamic / subtype |

```java
// Overloading — chosen by the DECLARED type
void print(Object o) { }
void print(String s) { }
Object x = "hello";
print(x);       // calls print(Object) — surprises people

// Overriding — chosen by the ACTUAL type
Animal a = new Dog();
a.speak();      // calls Dog.speak()
```

**Fields are not polymorphic** — they're resolved by the static type. Neither are `static` and `private` methods.

## Inheritance vs Composition

| | Inheritance | Composition |
|---|---|---|
| Relationship | is-a | has-a |
| Binding | Compile-time, fixed | **Runtime, swappable** |
| Coupling | **Tight** — subclass depends on superclass internals | Loose |
| Multiple sources | Single class only (Java) | Any number |
| Testability | Harder | **Easier — inject a fake** |

**Prefer composition.** The reasons:

1. **The fragile base class problem** — changing a superclass silently breaks subclasses that depended on its internal call sequence.
2. **Combinatorial explosion** — behaviours A, B, C in any combination need 2³ subclasses but only 3 composed components.
3. **Rigidity** — you can't change an object's superclass at runtime; you can swap a strategy.

**Use inheritance only when:** it's a genuine is-a, the subtype honours [Liskov](SOLID%20Principles.md), and the hierarchy is stable and shallow.

## Abstract Class vs Interface

| | Abstract class | Interface |
|---|---|---|
| Multiple inheritance | No | **Yes** |
| State (fields) | Yes | Only `static final` constants |
| Constructor | Yes | No |
| Method bodies | Yes | `default` and `static` (Java 8+), `private` (Java 9+) |
| Access modifiers | Any | `public` (and `private` for helpers) |
| Semantics | "is-a", shared implementation | "can-do", capability |

**Choose an interface by default.** Choose an abstract class when subclasses genuinely share state or a constructor, or when you need a Template Method skeleton.

### The Diamond Problem

Java forbids multiple class inheritance, so the diamond can't arise for state. With `default` methods it *can* arise for behaviour — and Java forces you to resolve it explicitly:

```java
interface A { default void go() { } }
interface B { default void go() { } }
class C implements A, B {
    public void go() { A.super.go(); }   // must disambiguate — won't compile otherwise
}
```

## Coupling and Cohesion

- **Cohesion** — how focused a class is. **High is good.**
- **Coupling** — how much classes depend on each other. **Low is good.**

The goal is high cohesion, low coupling. Every SOLID principle serves one of these two.

**Law of Demeter ("don't talk to strangers"):** `a.getB().getC().doThing()` couples you to three classes and their entire structure. Ask the immediate collaborator to do the work instead.

## Common Interview Questions

- *Abstraction vs encapsulation?* — hiding complexity vs hiding data.
- *Why prefer composition?* — fragile base class, combinatorial explosion, runtime flexibility, testability.
- *Can you override a static method?* — no. Declaring the same signature in a subclass **hides** it, and resolution uses the static type.
- *Interface vs abstract class?* — capability vs shared implementation with state.
- *Can an interface have state?* — only `public static final` constants.

## Common Mistakes

- Using inheritance to reuse code rather than to model an is-a relationship
- Deep hierarchies (three or more levels)
- Getters and setters on every field — that's not encapsulation, it's a public field with extra steps
- Returning mutable internal collections instead of unmodifiable views
- Confusing method hiding with overriding

## Related Topics

- [SOLID Principles](SOLID%20Principles.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)
- [LLD Delivery Framework](LLD%20Delivery%20Framework.md)

## Revision Summary

Abstraction hides complexity, encapsulation hides data. Overloading is static, overriding is dynamic. Prefer composition — inheritance is tight, compile-time coupling. Interfaces for capability, abstract classes for shared state.

## Quick Recall

- Abstraction = what; encapsulation = how it's protected
- Overloading → declared type; overriding → actual type
- Fields and statics are never polymorphic
- Composition: runtime-swappable, testable, no fragile base class
- Interface by default; abstract class for shared state
- High cohesion, low coupling
