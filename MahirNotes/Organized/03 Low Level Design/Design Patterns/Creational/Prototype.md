# Prototype

## Why It Matters

The least-used creational pattern, but it appears whenever object creation is expensive and you need many near-identical copies.

## Core Idea

Create new objects by **cloning an existing instance** rather than constructing from scratch. The prototype carries its own configuration, so the copy starts pre-configured.

```java
interface Prototype<T> { T copy(); }

class Document implements Prototype<Document> {
    private final String template;
    private final List<Section> sections;

    public Document copy() {
        return new Document(template, sections.stream()
            .map(Section::copy).collect(toList()));   // deep copy
    }
}
```

## When It Pays Off

- Construction is expensive: database load, network fetch, heavy parsing, complex computation
- You need many objects differing only slightly from a baseline
- The concrete class isn't known at compile time (you hold an instance, not a type)
- Configuration is more easily captured by example than by parameters

**Game objects, document templates, and pre-configured HTTP clients are the standard examples.**

## Shallow vs Deep Copy — The Whole Interview

| | Shallow | Deep |
|---|---|---|
| Primitives | Copied | Copied |
| Object references | **Shared** | **Recursively copied** |
| Mutating a nested object | **Affects both** | Independent |

```java
// Shallow — the bug
Config a = new Config(new ArrayList<>(List.of("x")));
Config b = a.shallowCopy();
b.getItems().add("y");
a.getItems();   // ["x", "y"] — a was mutated
```

**Almost every Prototype bug is an unintended shallow copy.** Say this explicitly.

## Java's `Cloneable` Is Broken — Know Why

```java
class Foo implements Cloneable {
    public Foo clone() throws CloneNotSupportedException { return (Foo) super.clone(); }
}
```

Problems:
- `Cloneable` is a **marker interface with no `clone()` method** — it doesn't actually declare the contract
- `Object.clone()` is `protected`, so you must override and widen it
- It performs a **shallow** copy by default
- It bypasses constructors, so invariants and `final` fields aren't handled normally
- Throws a checked `CloneNotSupportedException`

**Joshua Bloch's advice: avoid `Cloneable`.** Prefer a **copy constructor** or a static factory:

```java
public Document(Document other) {          // copy constructor
    this.template = other.template;
    this.sections = other.sections.stream().map(Section::new).collect(toList());
}
```

Saying "I'd use a copy constructor rather than `Cloneable`, because `Cloneable` is a broken marker interface that bypasses constructors" is a strong senior answer.

## Deep Copy Techniques

| Technique | Notes |
|---|---|
| **Manual copy constructor** | Explicit, fast, correct — preferred |
| Serialisation round-trip | Easy for deep graphs; slow; requires `Serializable` |
| JSON round-trip (Jackson/Gson) | Convenient; lossy on types; slow |
| Copy-on-write | Defer copying until a mutation actually happens |

**The best deep copy is no copy: make the object immutable** and share it freely. Prototype exists largely to work around mutability.

## Prototype Registry

```java
class ShapeRegistry {
    private final Map<String, Shape> prototypes = new HashMap<>();
    void register(String key, Shape s) { prototypes.put(key, s); }
    Shape create(String key) { return prototypes.get(key).copy(); }
}
```
Combines Prototype with a Factory — clients request by key and receive a fresh copy.

## Common Questions

- *Shallow vs deep copy?* — whether nested references are shared or recursively copied.
- *Why avoid `Cloneable`?* — marker interface with no method, shallow by default, bypasses constructors, checked exception.
- *When is Prototype better than a Factory?* — when the new object should inherit an existing instance's runtime state, not just its type.
- *How do you deep-copy a cyclic graph?* — track visited objects in an identity map to avoid infinite recursion.

## Common Mistakes

- Shallow-copying mutable collections
- Implementing `Cloneable` without understanding its semantics
- Forgetting cycles in the object graph
- Using it where immutability would remove the need entirely

## Related Topics

- [Builder](Builder.md)
- [Factory Method](Factory%20Method.md)
- [OOP Core Concepts](../../OOP%20Foundations/OOP%20Core%20Concepts.md)

## Revision Summary

Clone a configured instance instead of constructing anew. The real content is shallow vs deep copy. Avoid `Cloneable`; use a copy constructor. Immutability often makes the pattern unnecessary.

## Quick Recall

- Copy an instance, not a class
- Shallow shares nested references — the classic bug
- `Cloneable` is broken → copy constructor
- Deep copy needs cycle handling
- Immutable objects need no copying
