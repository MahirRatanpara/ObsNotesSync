# Visitor

## Why It Matters

The hardest GoF pattern, and the one that tests whether you understand double dispatch. It's also the standard answer for operations over an AST or object tree.

## Core Idea

Separate an **algorithm** from the **object structure** it operates on, so you can add new operations without modifying the element classes.

```java
interface Visitor {
    void visit(Circle c);
    void visit(Square s);
    void visit(Group g);
}

interface Shape {
    void accept(Visitor v);        // double dispatch entry point
}

class Circle implements Shape {
    public void accept(Visitor v) { v.visit(this); }    // `this` is statically Circle here
}

class AreaVisitor implements Visitor {
    double total;
    public void visit(Circle c) { total += Math.PI * c.r() * c.r(); }
    public void visit(Square s) { total += s.side() * s.side(); }
}
```

Adding `ExportVisitor` or `ValidationVisitor` requires **no change** to `Circle` or `Square`.

## Double Dispatch — The Actual Content

Java dispatches on the **runtime type of the receiver** but the **compile-time type of the arguments**. So this fails:

```java
void render(Shape s) { ... }
void render(Circle c) { ... }
Shape s = new Circle();
render(s);          // calls render(Shape) — NOT render(Circle)
```

Visitor gets around it with **two** virtual calls:

1. `shape.accept(visitor)` — dispatches on the shape's runtime type, landing in `Circle.accept`
2. Inside `Circle.accept`, `visitor.visit(this)` — `this` is *statically* `Circle`, so overload resolution picks `visit(Circle)`, and dispatch on the visitor's runtime type picks the right visitor

**Two dispatches resolve two types.** That's the entire mechanism, and being able to explain it is the point of the question.

## The Central Trade-Off

Visitor inverts which axis is cheap to extend:

| Adding a new… | Without Visitor | With Visitor |
|---|---|---|
| **Operation** | Edit **every** element class | **One new visitor class** |
| **Element type** | One new class | Edit **every** visitor |

**Use Visitor when the element hierarchy is stable and operations change often.** If new element types appear regularly, Visitor is the wrong choice — you'll be editing every visitor each time.

This is called the **expression problem**, and stating it by name is a strong signal.

## Real Uses

- **Compilers and interpreters** — an AST visited by type-checkers, optimisers, and code generators. The canonical use.
- `javax.lang.model.element.ElementVisitor` (annotation processing)
- `java.nio.file.FileVisitor` — `Files.walkFileTree`
- Document object models exporting to PDF, HTML, plain text
- Static analysis tools
- ASM and bytecode manipulation libraries

**Pairs naturally with [Composite](../Structural/Composite.md):** Composite defines the tree, Visitor adds operations over it.

```java
class Group implements Shape {
    public void accept(Visitor v) {
        v.visit(this);
        children.forEach(c -> c.accept(v));   // traversal
    }
}
```

**Where traversal lives is a design decision** — in the elements (as above), or in the visitor. Putting it in the visitor gives more control (pre-order vs post-order, early exit) at the cost of duplication.

## Modern Java Alternatives

Java 21 pattern matching for `switch` with sealed types gives much of the benefit without the ceremony:

```java
sealed interface Shape permits Circle, Square {}

double area(Shape s) {
    return switch (s) {
        case Circle c -> Math.PI * c.r() * c.r();
        case Square q -> q.side() * q.side();
    };                       // exhaustive — compiler enforces it
}
```

**Sealed types make the switch exhaustive at compile time**, which was Visitor's main safety benefit. Mentioning this shows current knowledge — and in modern Java it's often the better answer.

## Limitations

- Adding an element type breaks every visitor
- `accept` methods pollute the element classes with awareness of visiting
- Visitors may need access to element internals, weakening encapsulation
- Verbose and unfamiliar to many readers

## Common Questions

- *What is double dispatch?* — resolving behaviour on two runtime types via two chained virtual calls.
- *Why not just overload?* — Java resolves overloads on the static argument type.
- *When is Visitor a bad choice?* — when element types change frequently.
- *What is the expression problem?* — the difficulty of extending both types and operations without modifying existing code.
- *Modern alternative?* — sealed interfaces plus exhaustive pattern-matching switch.

## Common Mistakes

- Using it when element types are unstable
- Forgetting to add a `visit` overload, so a type silently falls through to a default
- `instanceof` chains inside the visitor, defeating the purpose
- Not recognising that sealed types plus switch now solve the same problem more simply

## Related Topics

- [Composite](../Structural/Composite.md)
- [Interpreter](Interpreter.md)
- [Design Pattern Selection](../Design%20Pattern%20Selection.md)

## Revision Summary

Separates operations from a stable object structure via double dispatch (`accept` then `visit`). Adding operations is cheap; adding element types is expensive. Canonical for ASTs, and pairs with Composite. Sealed types plus pattern-matching switch is the modern Java alternative.

## Quick Recall

- Double dispatch: `element.accept(v)` then `v.visit(this)`
- Java overloads resolve on static argument type — hence the workaround
- Cheap to add operations, expensive to add element types
- Requires a stable element hierarchy
- Compiler/AST is the canonical use
- Java 21 sealed + switch is often better now
