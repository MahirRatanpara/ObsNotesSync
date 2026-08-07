# LLD Cheat Sheet

## The 35-Minute Map

| Phase | Min | Output |
|---|---|---|
| Clarify + scope | 5 | Requirements, explicit non-goals |
| Entities | 5 | Classes with one responsibility each |
| Relationships | 5 | Composition/aggregation, class skeleton |
| Behaviour | 10 | Methods, state transitions |
| Follow-up | 7 | Extend by adding, not editing |
| Concurrency | 3 | Locking strategy |

## SOLID Quick Diagnosis

| Smell | Violated | Fix |
|---|---|---|
| Class name has "And" / "Manager" | SRP | Split |
| Growing `switch` on type | OCP | Polymorphism / Strategy |
| Override throws `UnsupportedOperation` | LSP | Rework hierarchy |
| Implementers stub methods out | ISP | Split the interface |
| `new` on a concrete class in business logic | DIP | Inject |

## Problem → Pattern

| Sounds like | Pattern |
|---|---|
| Swap the algorithm at runtime | **Strategy** |
| Create without naming the class | **Factory** |
| Families of related products | Abstract Factory |
| Too many constructor params | **Builder** |
| Notify many on change | **Observer** |
| Behaviour varies by state | **State** |
| Add behaviour at runtime | Decorator |
| Control access | Proxy |
| Incompatible interfaces | Adapter |
| Simplify a subsystem | Facade |
| Chain of handlers | Chain of Responsibility |
| Undo / queue / log requests | Command |
| Fixed skeleton, varying steps | Template Method |
| Tree of uniform parts | Composite |
| Many similar objects, memory pressure | Flyweight |

**The six that dominate interviews:** Strategy, Factory, Observer, Singleton, State, Builder.

## Confusable Pairs

| Pair | Difference |
|---|---|
| Strategy vs State | Client picks vs object transitions |
| Factory Method vs Abstract Factory | One product vs a family |
| Decorator vs Proxy | Adds behaviour vs controls access |
| Adapter vs Facade | Fits one interface vs simplifies many |
| Template Method vs Strategy | Inheritance vs composition |

## Relationships

| | Meaning | Lifetime |
|---|---|---|
| Composition | part-of | Child dies with parent |
| Aggregation | has-a | Independent |
| Association | uses-a | Independent |
| Inheritance | is-a | — |

**Prefer composition.**

## State Transitions

```java
enum State { CREATED, ACTIVE, COMPLETED, CANCELLED }

void activate() {
    if (state != CREATED) throw new IllegalStateException("from " + state);
    state = ACTIVE;
}
```

**Guard every transition.** Interviewers check for this.

## Concurrency in LLD

| Contention | Tool |
|---|---|
| Counter | `AtomicInteger` |
| Shared map | `ConcurrentHashMap` + `compute` |
| Resource pool | `Semaphore` |
| Compound invariant | `ReentrantLock` |
| Read-heavy | `ReadWriteLock` |

**Lock the smallest unit.** Locking the whole system serialises every user.

## Anti-Patterns

- God class
- Anaemic model (data classes + a "Service" holding all logic)
- Inheritance three levels deep
- Boolean parameters — use enums
- Public mutable collections — return unmodifiable views
- Naming patterns you don't need

## Common Problems and Their Core Pattern

| Problem | Key patterns |
|---|---|
| Parking Lot | Strategy (pricing), Factory (spot/vehicle), Singleton |
| Elevator | State, Strategy (scheduling), Observer |
| Vending Machine | **State** |
| Movie Booking | State, concurrency on seat locking (optimistic vs pessimistic) |
| Rate Limiter | Strategy (algorithm), Token Bucket |
| Logging Framework | Chain of Responsibility, Strategy (appenders), Singleton |
| Chess / Tic-Tac-Toe | Strategy (rules per piece), State, Command (undo) |
| Notification System | Observer + Factory + Strategy |
| Splitwise | Strategy (split types), Observer |
| File System | **Composite** |

## Related

- [LLD Delivery Framework](LLD%20Delivery%20Framework.md)
- [SOLID Principles](SOLID%20Principles.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)
