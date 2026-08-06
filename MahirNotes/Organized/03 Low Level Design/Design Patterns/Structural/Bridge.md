# Bridge

## Why It Matters

The least intuitive GoF pattern, and the correct answer when a class hierarchy is growing along **two independent axes**.

## The Problem

Shapes (Circle, Square) that can be drawn with different renderers (Vector, Raster). With inheritance:

```
VectorCircle, RasterCircle, VectorSquare, RasterSquare …
```

**m shapes × n renderers = m × n classes.** Adding one renderer means adding m classes.

## The Solution

Split the two dimensions into separate hierarchies and connect them with composition.

```java
interface Renderer {                       // IMPLEMENTATION hierarchy
    void renderCircle(double r);
    void renderSquare(double side);
}

abstract class Shape {                     // ABSTRACTION hierarchy
    protected final Renderer renderer;     // ← the bridge
    Shape(Renderer renderer) { this.renderer = renderer; }
    abstract void draw();
}

class Circle extends Shape {
    private final double radius;
    Circle(Renderer r, double radius) { super(r); this.radius = radius; }
    void draw() { renderer.renderCircle(radius); }
}

new Circle(new VectorRenderer(), 5).draw();
```

**m + n classes instead of m × n.** Both hierarchies now vary independently.

## The Two Hierarchies

| Hierarchy | Contains | Varies by |
|---|---|---|
| **Abstraction** | High-level logic the client uses | Business concept (Shape, Message, Remote) |
| **Implementation** | Low-level primitives | Platform/backend (Renderer, Sender, Device) |

**The abstraction does not extend the implementation — it holds a reference to it.** That reference is the "bridge".

## Bridge vs Strategy

Structurally almost identical — both compose an interface. The distinction is scope and intent:

| | Bridge | Strategy |
|---|---|---|
| Scope | **Structural** — organises two hierarchies | **Behavioural** — swaps one algorithm |
| Set at | Usually construction, long-lived | Often swapped per call |
| Both sides vary | **Yes** — both are hierarchies | No — one context, many algorithms |
| Intent | Prevent class explosion | Vary behaviour |

**A fair interview answer:** "Structurally these are the same; Bridge describes the situation where *both* sides form hierarchies that must vary independently, while Strategy is about swapping one algorithm behind a stable context."

## Bridge vs Adapter

- **Bridge** is designed **up front**, deliberately separating dimensions
- **Adapter** is applied **after the fact** to reconcile things that already exist

## Real Examples

| Domain | Abstraction | Implementation |
|---|---|---|
| **JDBC** | `Connection`, `Statement` | Vendor drivers |
| Logging | SLF4J API | Logback, Log4j2 backends |
| Notifications | `Message` types | `Sender` channels (email/SMS/push) |
| AWT | `Component` | Peer classes per OS |
| Persistence | Repository interfaces | JPA / JDBC / in-memory implementations |

**JDBC is the cleanest example:** `java.sql` is the abstraction, each vendor driver the implementation. Neither hierarchy forces changes on the other.

## When To Use

- Two (or more) independent dimensions of variation
- You want to switch implementations at runtime
- Both hierarchies are expected to grow
- Implementation details should be invisible to clients

**Don't use it** when only one dimension varies — that's plain polymorphism or Strategy, and the extra indirection isn't earned.

## Limitations

- More indirection and more classes up front
- Over-engineering if the second dimension never materialises
- Harder to follow for readers unfamiliar with the pattern

## Common Questions

- *Bridge vs Strategy?* — structural separation of two hierarchies vs behavioural swap of one algorithm.
- *Bridge vs Adapter?* — designed in advance vs retrofitted.
- *Why not inheritance?* — m × n class explosion.
- *JDK example?* — JDBC, SLF4J, AWT peers.

## Common Mistakes

- Applying it with only one axis of variation
- Making the abstraction extend rather than compose the implementation
- Leaking implementation types through the abstraction's public API
- Confusing it with Strategy without articulating the difference

## Related Topics

- [Strategy](../Behavioural/Strategy.md)
- [Adapter](Adapter.md)
- [Design Pattern Selection](../Design%20Pattern%20Selection.md)

## Revision Summary

Separates an abstraction from its implementation so both vary independently, turning m × n classes into m + n. Composition, not inheritance, links them. JDBC and SLF4J are the canonical examples.

## Quick Recall

- Two independent axes of variation
- m + n classes instead of m × n
- Abstraction **holds** the implementation
- JDBC API vs vendor drivers
- Designed up front; Adapter is retrofitted
