# Nested and Inner Classes

## Why It Matters

The distinction between static nested and inner classes is a real memory-leak source, and it explains why lambdas were designed differently. Frequently asked precisely because most people blur the four kinds together.

## The Four Kinds

| Kind | Declared | Holds outer `this` | Can access outer instance state |
|---|---|---|---|
| **Static nested** | `static class` inside a class | **No** | Only `static` members |
| **Inner (non-static)** | `class` inside a class | **Yes** | **Yes** |
| **Local** | Inside a method | Yes (if in an instance method) | Yes + effectively-final locals |
| **Anonymous** | Inline `new X() { }` | Yes | Yes + effectively-final locals |

**The one distinction that matters: an inner class holds an implicit reference to the enclosing instance. A static nested class does not.**

## Static Nested Class

```java
public class Outer {
    private static int shared;
    private int instanceField;

    static class Nested {
        void f() {
            shared = 1;            // OK — static members only
            // instanceField = 1;  // ILLEGAL — no enclosing instance
        }
    }
}
new Outer.Nested();                // no Outer instance needed
```

**Just a top-level class in a namespace.** Use it for a helper that's conceptually tied to the outer class but doesn't need its state.

**Examples in the JDK:** `Map.Entry`, `HashMap.Node`, `Thread.State`, and every builder (`HttpRequest.Builder`).

## Inner Class

```java
public class Outer {
    private int value = 42;

    class Inner {
        void f() {
            System.out.println(value);          // outer instance field
            System.out.println(Outer.this.value); // explicit form
        }
    }
}

Outer o = new Outer();
Outer.Inner i = o.new Inner();   // note the unusual syntax
```

The compiler adds a synthetic field `this$0` pointing at the enclosing instance, and a constructor parameter to set it.

**`Outer.this` is how you disambiguate** when the inner class shadows a name.

## The Memory Leak

**This is the reason to care.**

```java
public class DataHolder {
    private byte[] hugeArray = new byte[100_000_000];   // 100 MB

    class Listener implements EventListener {           // INNER — holds DataHolder
        public void onEvent(Event e) { /* never touches hugeArray */ }
    }

    public EventListener createListener() { return new Listener(); }
}

// Elsewhere
registry.register(holder.createListener());   // the registry now pins 100 MB
```

**The listener holds `this$0`, which keeps the entire `DataHolder` — including the 100 MB array — reachable**, even though the listener never uses it. As long as the registry lives, the array cannot be collected.

**Fix: make it static and pass only what's needed.**
```java
static class Listener implements EventListener {
    private final String id;                 // only what it actually uses
    Listener(String id) { this.id = id; }
}
```

**Rule: make every nested class `static` unless it genuinely needs the enclosing instance.** This is straight from *Effective Java*, and it's the practical takeaway.

**The same leak occurs with non-static inner `Runnable`s submitted to long-lived executors**, and with Android `AsyncTask`s holding an `Activity` — a notorious case.

## Local Classes

```java
void process(List<String> items) {
    int threshold = 10;                      // effectively final

    class Filter {                           // local to this method
        boolean accept(String s) { return s.length() > threshold; }
    }

    items.stream().filter(new Filter()::accept).forEach(System.out::println);
}
```

Scoped to the enclosing block. Can capture **effectively final** locals — the value is copied into a synthetic field, because the stack frame may be gone by the time the class is used.

**Rarely worth it.** A lambda or a private method is almost always clearer.

## Anonymous Classes

```java
Runnable r = new Runnable() {
    private int counter = 0;                 // CAN have state
    public void run() { counter++; }
};
```

A local class declared and instantiated in one expression, with no name.

| Can | Cannot |
|---|---|
| Have fields and instance initialisers | Have a constructor (no name) |
| Implement one interface **or** extend one class | Both |
| Override multiple methods | Be reused |

**They still have their uses** where lambdas can't reach: when you need state, when you need to override several methods, or when the interface isn't functional.

## Anonymous Class vs Lambda

| | Anonymous class | Lambda |
|---|---|---|
| Compiles to | **A real class file** (`Outer$1.class`) | **`invokedynamic`** |
| `this` | **The anonymous instance** | **The enclosing instance** |
| Can have state | Yes | No |
| Multiple methods | Yes | No — SAM only |
| Shadowing enclosing names | Allowed | **Not allowed** |
| Non-capturing instance reuse | New instance each time | **Cached** |

**The `this` difference is the classic trap:**

```java
class Widget {
    void register() {
        Runnable lambda = () -> System.out.println(this);   // the Widget
        Runnable anon = new Runnable() {
            public void run() { System.out.println(this); } // the Runnable!
        };
    }
}
```

**A lambda does not introduce a new scope for `this`** — it's lexically scoped, like a block. That's why lambdas don't accidentally capture and leak the enclosing instance the way anonymous inner classes do.

**The class-file consequence:** a large codebase with thousands of anonymous classes generates thousands of class files, slowing class loading and inflating the jar. Lambdas generate none — a real motivation for the `invokedynamic` design. See [Lambdas and Functional Interfaces](../Streams%20and%20Functional/Lambdas%20and%20Functional%20Interfaces.md).

## Access to Private Members

Nested and outer classes can access each other's `private` members. Before Java 11 the compiler generated **synthetic bridge accessor methods** (`access$000`) to make this work at the bytecode level, since the JVM enforced access strictly.

**Java 11's `Nestmates` (JEP 181) made nesting a first-class JVM concept**, so private access works directly without synthetic methods. Cleaner bytecode, better reflection behaviour, and one fewer surprise in stack traces.

Worth knowing if asked why `access$000` used to appear in profiles.

## When To Use What

| Situation | Use |
|---|---|
| Helper tied to the outer class, no state needed | **Static nested** |
| Genuinely needs enclosing instance state | Inner — and consider whether it should |
| One-off single-method implementation | **Lambda** |
| Needs state or multiple methods | Anonymous class |
| Used in exactly one method, complex | Local class (rare) |
| Value object | **Record** |

**Default to static nested or a lambda.** Inner classes should be a deliberate choice, not an accident of omitting `static`.

## Common Mistakes

- Forgetting `static` and leaking the enclosing instance
- Long-lived listeners implemented as inner classes
- Expecting `this` in an anonymous class to be the outer instance
- Anonymous classes where a lambda is clearer
- Deeply nested class definitions hurting readability
- Not realising local and anonymous classes capture by **value**

## Related Topics

- [Lambdas and Functional Interfaces](../Streams%20and%20Functional/Lambdas%20and%20Functional%20Interfaces.md)
- [Inheritance and Polymorphism](Inheritance%20and%20Polymorphism.md)
- [Java Memory Leaks](../JVM%20and%20Memory/Java%20Memory%20Leaks.md)
- [Observer](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Observer.md)

## Revision Summary

A static nested class is just a namespaced top-level class; an inner class carries a hidden reference to the enclosing instance, which is a genuine leak source for long-lived listeners. Local and anonymous classes capture effectively-final locals by value. Lambdas differ from anonymous classes in `this` semantics and compile via `invokedynamic` rather than generating class files.

## Quick Recall

- **Inner classes hold `this$0`; static nested don't**
- **Make nested classes `static` unless they need the enclosing instance**
- Long-lived listener as a non-static inner class = **memory leak**
- `Outer.this` disambiguates
- Anonymous class `this` = itself; **lambda `this` = enclosing instance**
- Anonymous classes generate class files; lambdas don't
- Capture is **by value** and requires effectively final
- Java 11 Nestmates removed synthetic `access$000` bridges
