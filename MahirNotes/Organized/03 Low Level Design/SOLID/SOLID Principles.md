# SOLID Principles

## Why It Matters

The vocabulary interviewers use to critique your design. You need to *apply* them, not recite them — and know when they conflict.

## S — Single Responsibility

**A class should have one reason to change.**

"Reason to change" means one stakeholder or one axis of change — not "one method".

```java
// Violation: three reasons to change
class Order {
    void calculateTotal() { }
    void saveToDatabase() { }     // persistence changes
    void sendConfirmationEmail() { }  // notification changes
}

// Fixed
class Order { BigDecimal calculateTotal() { } }
class OrderRepository { void save(Order o) { } }
class OrderNotifier { void sendConfirmation(Order o) { } }
```

**Test:** describe the class in one sentence without using "and" or "or".

## O — Open/Closed

**Open for extension, closed for modification.**

Adding a feature should mean adding a class, not editing an existing one.

```java
// Violation — every new type edits this method
double area(Shape s) {
    if (s instanceof Circle) ...
    else if (s instanceof Square) ...
}

// Fixed — new shapes just implement the interface
interface Shape { double area(); }
```

**The tell is a growing `if/else` or `switch` on type.** That's the signal to introduce polymorphism, Strategy, or a Factory.

## L — Liskov Substitution

**Subtypes must be usable anywhere the base type is, without surprising the caller.**

The classic violation:

```java
class Rectangle { void setWidth(int w); void setHeight(int h); }
class Square extends Rectangle {
    void setWidth(int w) { this.w = w; this.h = w; }   // breaks the caller's expectation
}
// A test asserting "set width 5, height 4 → area 20" now fails for Square.
```

Square *is-a* rectangle mathematically, but not behaviourally. **"Is-a" in language is not "is-a" in code.**

Rules a subclass must respect:
- Don't strengthen preconditions
- Don't weaken postconditions
- Preserve invariants
- Don't throw new checked exceptions

**Throwing `UnsupportedOperationException` in an override is an LSP violation** — and `Arrays.asList().add()` is a well-known example in the JDK itself.

## I — Interface Segregation

**Clients shouldn't depend on methods they don't use.**

```java
// Violation
interface Worker { void work(); void eat(); }
class Robot implements Worker {
    public void eat() { throw new UnsupportedOperationException(); }  // smell
}

// Fixed
interface Workable { void work(); }
interface Feedable { void eat(); }
```

Many small role-based interfaces beat one large one. This is why `Runnable`, `Callable`, and `Comparable` each have a single method.

## D — Dependency Inversion

**Depend on abstractions, not concretions. High-level modules shouldn't depend on low-level ones.**

```java
// Violation — OrderService is welded to MySQL
class OrderService {
    private MySqlOrderRepository repo = new MySqlOrderRepository();
}

// Fixed — depends on an interface, injected
class OrderService {
    private final OrderRepository repo;
    OrderService(OrderRepository repo) { this.repo = repo; }
}
```

**The critical detail:** the interface should be owned by the *high-level* module (defined in terms of what the business needs), not by the database layer. Otherwise you've just added a layer of indirection without inverting anything.

This is what makes unit testing possible — inject a fake.

## When They Conflict

SOLID principles pull against each other, and the honest answer matters in senior interviews:

- **SRP vs cohesion** — split too far and you get anaemic classes and scattered logic
- **OCP vs YAGNI** — building extension points for requirements that never arrive is waste. Apply OCP on the axis that has *demonstrably* changed before.
- **ISP vs simplicity** — a dozen one-method interfaces can obscure the design

**Say this if asked "do you always follow SOLID?"** The mature answer is that they're heuristics for managing change, applied where change is likely, not laws.

## Quick Diagnosis

| Smell | Violated | Fix |
|---|---|---|
| Class name contains "And" or "Manager" | SRP | Split |
| `if/else` on type, growing | OCP | Polymorphism / Strategy |
| Override throws UnsupportedOperation | LSP | Rework the hierarchy |
| Implementers stub out methods | ISP | Split the interface |
| `new` on a concrete class inside business logic | DIP | Inject |

## Related Topics

- [LLD Delivery Framework](../In%20A%20Hurry/LLD%20Delivery%20Framework.md)
- [Design Pattern Selection](../Design%20Patterns/Design%20Pattern%20Selection.md)
- [OOP Core Concepts](../OOP%20Foundations/OOP%20Core%20Concepts.md)

## Revision Summary

SRP one reason to change; OCP extend don't modify; LSP subtypes must not surprise; ISP small role interfaces; DIP depend on abstractions owned by the high-level module. They are heuristics, and they conflict.

## Quick Recall

- Describe the class without "and" → SRP
- Growing `switch` on type → OCP violation
- `UnsupportedOperationException` override → LSP violation
- Stubbed-out methods → ISP violation
- `new` in business logic → DIP violation
