# Design Pattern Selection

## Why It Matters

Knowing 23 patterns is worthless if you can't map a problem to one in 30 seconds. This is the lookup table.

## Problem → Pattern

| The problem sounds like | Pattern | Category |
|---|---|---|
| "Only one instance should exist" | **Singleton** | Creational |
| "Create objects without naming the concrete class" | **Factory Method** | Creational |
| "Create families of related objects" | **Abstract Factory** | Creational |
| "Too many constructor parameters / optional fields" | **Builder** | Creational |
| "Copying is cheaper than constructing" | **Prototype** | Creational |
| "Two incompatible interfaces must work together" | **Adapter** | Structural |
| "Add behaviour at runtime without subclassing" | **Decorator** | Structural |
| "Control access to an object" | **Proxy** | Structural |
| "Simplify a complex subsystem" | **Facade** | Structural |
| "Treat individual and composite objects uniformly" | **Composite** | Structural |
| "Decouple an abstraction from its implementation" | **Bridge** | Structural |
| "Too many similar objects consume memory" | **Flyweight** | Structural |
| "Swap the algorithm at runtime" | **Strategy** | Behavioural |
| "Notify many objects when one changes" | **Observer** | Behavioural |
| "Behaviour changes with internal state" | **State** | Behavioural |
| "Encapsulate a request; support undo/queue" | **Command** | Behavioural |
| "Pass a request along a series of handlers" | **Chain of Responsibility** | Behavioural |
| "Fixed algorithm skeleton, varying steps" | **Template Method** | Behavioural |
| "Traverse a collection without exposing internals" | **Iterator** | Behavioural |
| "Many objects communicate in a tangle" | **Mediator** | Behavioural |
| "Capture and restore state (undo)" | **Memento** | Behavioural |
| "Add operations to a class hierarchy without editing it" | **Visitor** | Behavioural |
| "Evaluate a grammar or expression" | **Interpreter** | Behavioural |

## The Confusable Pairs

These are what interviewers actually probe.

### Strategy vs State
Structurally identical; **intent differs**.
- **Strategy** — the *client* picks the algorithm; strategies don't know about each other
- **State** — the *object* transitions between states; states often trigger the next transition

### Factory Method vs Abstract Factory
- **Factory Method** — one product, subclasses decide which concrete class
- **Abstract Factory** — a *family* of related products that must be used together (e.g. all Windows widgets or all Mac widgets)

### Decorator vs Proxy
Both wrap an object with the same interface.
- **Decorator** — adds *behaviour*; you stack many; the client chooses them
- **Proxy** — controls *access* (lazy loading, permission, remoting, caching); typically one; the client often doesn't know it's there

### Adapter vs Facade
- **Adapter** — makes one incompatible interface fit an expected one
- **Facade** — provides a simpler interface over many classes

### Decorator vs Inheritance
Decorator composes at runtime and avoids the combinatorial subclass explosion (`CoffeeWithMilkAndSugarAndCream`).

### Template Method vs Strategy
- **Template Method** — inheritance, compile-time, base class controls the skeleton
- **Strategy** — composition, runtime-swappable

Prefer Strategy — composition over inheritance.

## Patterns You'll Actually Use In Interviews

Roughly 80% of LLD interviews use only these six:

1. **Strategy** — pricing, sorting, routing rules
2. **Factory** — object creation by type
3. **Observer** — notifications and events
4. **Singleton** — configuration, connection pools (be ready to critique it)
5. **State** — workflows, order/trip lifecycle
6. **Builder** — complex object construction

Master these before the rest.

## Singleton — Be Ready to Critique It

Interviewers often ask about Singleton to see if you understand the criticism:

- Global mutable state, hard to reason about
- Hard to unit test (can't inject a fake)
- Hides dependencies — callers don't declare it
- Difficult in distributed systems (one instance *per JVM*, not per cluster)

**Preferred:** a single instance managed by a DI container, injected as an interface. Same benefit, testable.

If you must implement it, use the **Bill Pugh holder idiom** (see [Java Memory Model](../../02%20Java/JVM%20and%20Memory/Java%20Memory%20Model.md)) or an `enum`, which is serialisation- and reflection-safe.

## Anti-Patterns

- Naming patterns you didn't need ("pattern worship")
- Singleton for everything
- Deep inheritance where Strategy would do
- A Factory that returns one type — that's just a constructor

## Related Topics

- [SOLID Principles](../SOLID/SOLID%20Principles.md)
- [LLD Delivery Framework](../In%20A%20Hurry/LLD%20Delivery%20Framework.md)
- Design Patterns Cheat Sheet *(not yet written)*

## Revision Summary

Map the problem sentence to the pattern. Know the six that dominate interviews and the five confusable pairs. Justify every pattern you name; never name one you don't need.

## Quick Recall

- Swap algorithm → Strategy; behaviour by state → State
- Add behaviour → Decorator; control access → Proxy
- Incompatible interface → Adapter; simplify subsystem → Facade
- Growing `switch` on type → Factory + polymorphism
- Six that matter: Strategy, Factory, Observer, Singleton, State, Builder
