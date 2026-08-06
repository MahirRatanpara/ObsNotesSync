# Template Method

## Why It Matters

The inheritance-based counterpart to Strategy, and the pattern behind most framework extension points ("extend this class, override these methods").

## Core Idea

A base class defines the **skeleton** of an algorithm and defers specific steps to subclasses. The overall sequence is fixed; the steps vary.

```java
abstract class DataProcessor {

    public final void process() {          // FINAL — the skeleton must not change
        Data data = read();                // abstract — subclass must implement
        if (shouldValidate()) validate(data);   // hook — optional override
        Data transformed = transform(data);
        write(transformed);
        cleanup();                         // hook with a default no-op
    }

    protected abstract Data read();
    protected abstract Data transform(Data d);
    protected abstract void write(Data d);

    protected boolean shouldValidate() { return true; }   // hook
    protected void validate(Data d) { }                   // hook
    protected void cleanup() { }                          // hook
}
```

**Making the template method `final` is the detail interviewers look for.** Without it, a subclass can override the whole algorithm and the pattern's guarantee evaporates.

## The Three Method Kinds

| Kind | Modifier | Meaning |
|---|---|---|
| **Template method** | `public final` | The fixed skeleton |
| **Abstract step** | `protected abstract` | Subclass **must** implement |
| **Hook** | `protected` with default | Subclass **may** override |

**Hooks are what make the pattern flexible.** A hook with an empty or sensible default lets subclasses opt in without being forced to care.

**Steps should be `protected`, not `public`** — they're extension points, not API.

## The Hollywood Principle

"Don't call us, we'll call you." The framework calls your code, not the reverse. This inversion is why Template Method underlies so many frameworks: you supply the parts, the framework owns the flow.

## Template Method vs Strategy

| | Template Method | Strategy |
|---|---|---|
| Mechanism | **Inheritance** | **Composition** |
| Bound at | Compile time | Runtime |
| Varies | Steps within a fixed algorithm | The whole algorithm |
| Class explosion | One subclass per variation | Combinable |
| Testable in isolation | Harder | **Easier** |

**Prefer Strategy** in new code — composition over inheritance. Template Method earns its place when the *sequence itself* is the valuable, invariant thing you want to enforce.

A common hybrid: a template method whose steps are injected strategies. Best of both.

## Real Uses

- `java.util.AbstractList` — implement `get()` and `size()`, inherit everything else
- `InputStream.read(byte[], int, int)` calling the abstract `read()`
- Spring's `JdbcTemplate` — manages connection, statement, exception translation; you supply the row mapper
- JUnit lifecycle (`@BeforeEach`, `@Test`, `@AfterEach`)
- Servlet `HttpServlet.service()` dispatching to `doGet`/`doPost`
- Build tool lifecycles (Maven phases)

**`HttpServlet` is a clean example:** `service()` is the template; `doGet`, `doPost` are hooks.

## When To Use

- Several variants share an identical sequence but differ in steps
- You want to prevent subclasses from altering the order
- You're building a framework with defined extension points
- Duplicated algorithm structure exists across classes

## Limitations

- Inheritance couples subclasses to the base class's internals — the **fragile base class problem**
- Single inheritance is consumed
- Harder to test steps in isolation
- Adding a step can break every existing subclass

## Common Questions

- *Why is the template method `final`?* — so subclasses can't change the algorithm's structure.
- *What is a hook?* — an optional step with a default implementation.
- *Template Method vs Strategy?* — inheritance/compile-time/steps vs composition/runtime/whole algorithm.
- *JDK example?* — `AbstractList`, `HttpServlet.service()`, `JdbcTemplate`.
- *What's the Hollywood Principle?* — the framework calls your code.

## Common Mistakes

- Not making the template method `final`
- Public step methods, exposing internals as API
- Too many abstract steps, making subclasses painful to write
- Using it where Strategy (runtime-swappable, testable) is the better fit
- Changing the base class and silently breaking subclasses

## Related Topics

- [Strategy](Strategy.md)
- [Factory Method](../Creational/Factory%20Method.md)
- [OOP Core Concepts](../../OOP%20Foundations/OOP%20Core%20Concepts.md)

## Revision Summary

A `final` base method fixes the algorithm's sequence; abstract steps and optional hooks vary the details. The inheritance counterpart to Strategy, and the mechanism behind most framework extension points. Prefer Strategy unless the sequence itself must be enforced.

## Quick Recall

- Template method must be `final`
- Abstract = must implement; hook = may override
- Steps are `protected`, never `public`
- Hollywood Principle: framework calls you
- `AbstractList`, `HttpServlet`, `JdbcTemplate`
- Prefer Strategy in new code
