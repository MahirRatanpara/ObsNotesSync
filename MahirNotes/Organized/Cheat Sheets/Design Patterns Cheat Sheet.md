# Design Patterns Cheat Sheet

## Problem → Pattern

| The problem sounds like | Pattern |
|---|---|
| Only one instance should exist | [Singleton](../03%20Low%20Level%20Design/Design%20Patterns/Creational/Singleton.md) |
| Create objects without naming the class | [Factory Method](../03%20Low%20Level%20Design/Design%20Patterns/Creational/Factory%20Method.md) |
| Families of related objects that must match | [Abstract Factory](../03%20Low%20Level%20Design/Design%20Patterns/Creational/Abstract%20Factory.md) |
| Too many constructor parameters | [Builder](../03%20Low%20Level%20Design/Design%20Patterns/Creational/Builder.md) |
| Copying beats constructing | [Prototype](../03%20Low%20Level%20Design/Design%20Patterns/Creational/Prototype.md) |
| Incompatible interfaces must work together | [Adapter](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Adapter.md) |
| Add behaviour at runtime, stackable | [Decorator](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Decorator.md) |
| Control access to an object | [Proxy](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Proxy.md) |
| Simplify a complex subsystem | [Facade](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Facade.md) |
| Treat leaf and tree uniformly | [Composite](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Composite.md) |
| Two independent axes of variation | [Bridge](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Bridge.md) |
| Millions of objects, memory pressure | [Flyweight](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Flyweight.md) |
| Swap the algorithm at runtime | [Strategy](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Strategy.md) |
| Notify many on a change | [Observer](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Observer.md) |
| Behaviour depends on lifecycle stage | [State](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/State.md) |
| Undo, queue, or log requests | [Command](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Command.md) |
| Pipeline of handlers, may short-circuit | [Chain of Responsibility](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Chain%20of%20Responsibility.md) |
| Fixed skeleton, varying steps | [Template Method](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Template%20Method.md) |
| Traverse without exposing internals | [Iterator](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Iterator.md) |
| Many-to-many component tangle | [Mediator](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Mediator.md) |
| Snapshot and restore state | [Memento](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Memento.md) |
| Add operations to a stable hierarchy | [Visitor](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Visitor.md) |
| Evaluate a small grammar | [Interpreter](../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Interpreter.md) |

## The Six That Dominate Interviews

Strategy · Factory · Observer · Singleton · State · Builder

Master these before the rest.

## Confusable Pairs — One-Line Tests

| Pair | Test |
|---|---|
| **Strategy vs State** | Client picks vs object transitions itself |
| **Factory Method vs Abstract Factory** | One product vs a coherent family |
| **Decorator vs Proxy** | Adds behaviour vs controls access |
| **Decorator vs Chain of Responsibility** | Always delegates vs may short-circuit |
| **Adapter vs Facade** | Makes one thing compatible vs makes many things simple |
| **Adapter vs Bridge** | Retrofitted vs designed up front |
| **Bridge vs Strategy** | Two hierarchies vs one swappable algorithm |
| **Template Method vs Strategy** | Inheritance/compile-time vs composition/runtime |
| **Mediator vs Observer** | Bidirectional coordination vs one-way broadcast |
| **Facade vs Mediator** | Subsystem unaware vs peers know the mediator |
| **Flyweight vs Object Pool** | Shared immutable vs borrowed mutable |
| **Composite vs Decorator** | Tree of parts vs stacked wrappers |

## JDK Examples

| Pattern | In the JDK |
|---|---|
| Singleton | `Runtime.getRuntime()` |
| Factory | `Calendar.getInstance()`, `Executors.*` |
| Abstract Factory | `DocumentBuilderFactory` |
| Builder | `StringBuilder`, `HttpRequest.newBuilder()` |
| Prototype | `Object.clone()` (avoid it) |
| Adapter | `Arrays.asList()`, `InputStreamReader` |
| Decorator | `java.io` streams, `Collections.unmodifiableList` |
| Proxy | `java.lang.reflect.Proxy`, Hibernate lazy loading |
| Facade | `JdbcTemplate`, SLF4J |
| Composite | Swing containers |
| Bridge | JDBC API vs drivers |
| Flyweight | `Integer.valueOf` (−128..127), string pool |
| Strategy | `Comparator` |
| Observer | `PropertyChangeListener`, Spring events |
| State | `Thread.State`, `Matcher` |
| Command | `Runnable`, `Callable` |
| Chain of Responsibility | Servlet `Filter` |
| Template Method | `AbstractList`, `HttpServlet.service()` |
| Iterator | Every collection |
| Interpreter | `Pattern` / `Matcher` |

## Anti-Patterns

- Naming a pattern you don't need ("pattern worship")
- Singleton for everything
- A factory with one implementation
- Inheritance three levels deep where Strategy would do
- God mediator
- Mutable flyweights
- Public-getter "mementos"

## Modern Java Notes

- **Sealed types + pattern-matching `switch`** often replace Visitor
- **Records** cover value objects, but not optional parameters (still need Builder)
- **Lambdas** replace single-method Strategy/Command classes
- **Enums with abstract methods** are often the cleanest State or Factory in Java
- **DI containers** are usually better than hand-rolled Singletons

## Related

- [Design Pattern Selection](../03%20Low%20Level%20Design/Design%20Patterns/Design%20Pattern%20Selection.md)
- [SOLID Principles](../03%20Low%20Level%20Design/SOLID/SOLID%20Principles.md)
- [LLD Cheat Sheet](LLD%20Cheat%20Sheet.md)
