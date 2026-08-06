# Proxy

## Why It Matters

Underpins Spring AOP, Hibernate lazy loading, and RPC stubs. Explaining how a framework "magically" adds transactions requires it.

## Core Idea

A stand-in with the **same interface** as the real object, controlling access to it.

```java
class ImageProxy implements Image {
    private final String path;
    private RealImage real;                       // created only when needed

    public void display() {
        if (real == null) real = new RealImage(path);   // lazy load
        real.display();
    }
}
```

## The Four Types

| Type | Purpose | Example |
|---|---|---|
| **Virtual** | Defer expensive creation | Hibernate lazy-loaded entities |
| **Protection** | Enforce access control | Spring Security method checks |
| **Remote** | Represent an object in another process | RMI stubs, gRPC clients |
| **Smart** | Add bookkeeping on access | Reference counting, caching, logging |

## Dynamic Proxies in Java

Frameworks generate proxies at runtime rather than writing them by hand:

```java
Foo proxy = (Foo) Proxy.newProxyInstance(
    Foo.class.getClassLoader(),
    new Class[]{ Foo.class },
    (p, method, args) -> {
        log.info("calling {}", method.getName());
        return method.invoke(target, args);
    });
```

| Mechanism | Requires | Used by |
|---|---|---|
| **JDK dynamic proxy** | The target must implement an **interface** | Spring (default when an interface exists) |
| **CGLIB** | Subclasses the class; the class must not be `final` | Spring (when there's no interface) |

## Why `@Transactional` Silently Fails on Self-Invocation

This is one of the highest-value practical questions in Java interviews:

```java
@Service
class OrderService {
    public void outer() {
        inner();               // ← direct call: bypasses the proxy entirely
    }
    @Transactional
    public void inner() { }    // NO transaction when called from outer()
}
```

Spring wraps the bean in a proxy. External callers hit the proxy, which starts the transaction. But `inner()` called from `outer()` is a plain `this.inner()` — it never leaves the object, so the proxy never sees it.

**Same reason `@Transactional` doesn't work on `private`, `final`, or `static` methods** — the proxy can't intercept them.

**Fixes:** self-injection, move the method to another bean, or use AspectJ load-time weaving.

## Proxy vs Decorator vs Adapter

| | Proxy | Decorator | Adapter |
|---|---|---|---|
| Interface | Same | Same | **Different** |
| Intent | **Control access** | **Add behaviour** | Make compatible |
| Instances | Usually one | Stacked | One |
| Creates the target | **Often yes** | No — receives it | No |

The "creates the target" row is the cleanest practical distinguisher: a decorator is handed the object; a proxy often controls its lifecycle.

## Real Uses

- Hibernate lazy collections (touching one triggers a query — the N+1 problem lives here)
- Spring `@Transactional`, `@Cacheable`, `@Async`, `@PreAuthorize`
- gRPC and Feign clients
- Mockito mocks

## Limitations

- Indirection makes stack traces and debugging harder
- Lazy-loading proxies can throw `LazyInitializationException` outside a session
- Proxy creation has a startup cost
- Self-invocation bypasses it (the most common real bug)

## Common Questions

- *Proxy vs Decorator?* — control access vs add behaviour; proxy often owns the target's lifecycle.
- *Why doesn't `@Transactional` work on an internal call?* — the call never passes through the proxy.
- *JDK proxy vs CGLIB?* — interface-based vs subclass-based; `final` classes and methods can't be CGLIB-proxied.
- *How does Hibernate lazy loading work?* — a virtual proxy issues the query on first access.

## Common Mistakes

- Expecting annotations to apply to self-invoked, private, or final methods
- Putting heavy logic in a proxy so callers pay unexpected cost
- Forgetting proxied objects fail `getClass()` comparisons against the target class
- Not accounting for `LazyInitializationException` in detached entities

## Related Topics

- [Decorator](Decorator.md)
- [Adapter](Adapter.md)
- [Design Pattern Selection](../Design%20Pattern%20Selection.md)

## Revision Summary

Same interface, controls access: virtual (lazy), protection (auth), remote (RPC), smart (bookkeeping). Java frameworks use JDK dynamic proxies or CGLIB. Self-invocation bypasses the proxy, which is why `@Transactional` silently fails on internal calls.

## Quick Recall

- Four types: virtual, protection, remote, smart
- JDK proxy needs an interface; CGLIB subclasses (no `final`)
- Self-invocation bypasses the proxy — `@Transactional` no-op
- Proxy controls access; Decorator adds behaviour
- Hibernate lazy loading is a virtual proxy
