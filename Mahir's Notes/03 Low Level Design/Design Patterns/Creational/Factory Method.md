# Factory Method

## Why It Matters

The standard cure for a growing `switch` on type — the most common Open/Closed violation in interview code.

## Core Idea

Define an interface for creating an object, but let subclasses (or a factory) decide which concrete class to instantiate. The caller depends on the abstraction, never on `new ConcreteThing()`.

## The Problem It Solves

```java
// Every new type edits this method — OCP violation
Notification create(String type) {
    if (type.equals("EMAIL")) return new EmailNotification();
    else if (type.equals("SMS")) return new SmsNotification();
    else if (type.equals("PUSH")) return new PushNotification();
    throw new IllegalArgumentException(type);
}
```

## Implementations

### Simple Factory (not a GoF pattern, but the common interview answer)
```java
public class NotificationFactory {
    private static final Map<Type, Supplier<Notification>> REGISTRY = Map.of(
        Type.EMAIL, EmailNotification::new,
        Type.SMS,   SmsNotification::new,
        Type.PUSH,  PushNotification::new
    );

    public static Notification create(Type type) {
        return Optional.ofNullable(REGISTRY.get(type))
            .orElseThrow(() -> new IllegalArgumentException("Unknown: " + type))
            .get();
    }
}
```

**The registry map is the upgrade interviewers look for.** Adding a type is a map entry, not a new `if` branch — and with a registration hook it becomes genuinely open for extension.

### True Factory Method (GoF) — subclasses decide
```java
abstract class Dialog {
    abstract Button createButton();           // the factory method
    void render() {                           // template using it
        Button b = createButton();
        b.onClick(this::close);
        b.render();
    }
}
class WindowsDialog extends Dialog { Button createButton() { return new WindowsButton(); } }
```
The base class defines *when* creation happens; subclasses define *what* is created. Notice this is Factory Method combined with Template Method — a common pairing.

## Use An Enum With Behaviour Instead

Often cleaner than a factory in Java:
```java
enum NotificationType {
    EMAIL { Notification create() { return new EmailNotification(); } },
    SMS   { Notification create() { return new SmsNotification(); } };
    abstract Notification create();
}
```
Type-safe, exhaustive, and no registry to keep in sync. Worth suggesting.

## When To Use

- Creation logic is non-trivial or likely to change
- The caller shouldn't know concrete types
- New types get added over time
- You need to swap implementations for testing

**Do not use it** when there's exactly one implementation — that's a constructor with extra steps, and interviewers will say so.

## Factory Method vs Abstract Factory

| | Factory Method | Abstract Factory |
|---|---|---|
| Produces | **One** product | A **family** of related products |
| Mechanism | Inheritance (subclass overrides) | Composition (inject a factory) |
| Example | `createButton()` | `createButton()` + `createCheckbox()` + `createMenu()`, all Windows or all Mac |

## In The JDK

`Calendar.getInstance()`, `NumberFormat.getInstance()`, `ThreadFactory`, `DocumentBuilderFactory`, `Executors.newFixedThreadPool()`.

## Common Questions

- *Difference from Abstract Factory?* — one product vs a coherent family.
- *Is Simple Factory a GoF pattern?* — no, but it's what most interviews mean.
- *How do you make a factory open for extension?* — a registry map with a registration method, or service loading.

## Common Mistakes

- A factory returning a single type
- Keeping the `if/else` chain and calling it a factory
- Factory that returns concrete types, so callers still couple to them
- Over-applying it to simple value objects

## Related Topics

- [Abstract Factory](Abstract%20Factory.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)
- [SOLID Principles](SOLID%20Principles.md)

## Revision Summary

Encapsulate instantiation behind an abstraction so adding a type doesn't edit existing code. A registry map beats an `if/else` chain. One product = Factory Method; a family = Abstract Factory.

## Quick Recall

- Growing `switch` on type → Factory
- Registry `Map<Type, Supplier<T>>` for extensibility
- Enum with abstract method is often cleaner in Java
- One product vs family distinguishes it from Abstract Factory
- Never build a factory for one implementation
