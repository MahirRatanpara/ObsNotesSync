# Decorator

## Why It Matters

The canonical answer to "add behaviour without subclassing", and the cure for combinatorial subclass explosion.

## The Problem

Coffee with milk, sugar, cream, in any combination. With inheritance you need `CoffeeWithMilk`, `CoffeeWithMilkAndSugar`, `CoffeeWithMilkAndSugarAndCream`… **2ⁿ classes for n options.**

## The Solution

Wrap the object in decorators that share its interface and add behaviour.

```java
interface Coffee { BigDecimal cost(); String description(); }

class SimpleCoffee implements Coffee {
    public BigDecimal cost() { return new BigDecimal("2.00"); }
    public String description() { return "Coffee"; }
}

abstract class CoffeeDecorator implements Coffee {
    protected final Coffee wrapped;                      // SAME interface
    CoffeeDecorator(Coffee wrapped) { this.wrapped = wrapped; }
}

class Milk extends CoffeeDecorator {
    Milk(Coffee c) { super(c); }
    public BigDecimal cost() { return wrapped.cost().add(new BigDecimal("0.50")); }
    public String description() { return wrapped.description() + ", milk"; }
}

Coffee order = new Sugar(new Milk(new SimpleCoffee()));   // stack freely
```

**n options become n decorator classes, combinable at runtime.**

## Why The Same Interface Matters

Because the decorator implements the same interface as what it wraps, decorators nest arbitrarily and the client cannot tell how many layers exist. That's what makes them stackable — and the key structural difference from an Adapter.

## Real Uses

- **`java.io`** — the textbook example: `new BufferedReader(new InputStreamReader(new FileInputStream(f)))`. Each layer adds one capability.
- `Collections.unmodifiableList()` / `synchronizedList()` — decorators adding immutability or synchronisation
- Servlet filters, Spring's `HandlerInterceptor`
- Resilience4j — retry, circuit breaker, rate limiter are decorators composed around a call

**Resilience4j is the best modern example** and ties directly to [Circuit Breaker](Circuit%20Breaker.md).

## Order Matters

```java
retry(circuitBreaker(call))   // retries can re-trip the breaker
circuitBreaker(retry(call))   // breaker sees one logical call
```

Different behaviour, both defensible. **Being able to explain why the order matters is a strong signal.**

## Decorator vs Proxy

Structurally near-identical; intent differs:

| | Decorator | Proxy |
|---|---|---|
| Purpose | **Add** behaviour | **Control** access |
| Count | Many, stacked | Usually one |
| Client awareness | Client composes them deliberately | Often transparent |
| Wrapped object | Passed in by the client | Often created/managed by the proxy |

## Decorator vs Inheritance vs Strategy

| | Decorator | Inheritance | Strategy |
|---|---|---|---|
| Binding | Runtime | Compile-time | Runtime |
| Combines | **Freely stackable** | Combinatorial explosion | One at a time |
| Changes | Wraps behaviour | Overrides | Replaces an algorithm |

## Limitations

- Many small classes
- Debugging a deep stack is painful — stack traces get long
- **Identity breaks:** `decorated != original`, so `equals`, `==`, and `instanceof` checks against the concrete type fail
- Order-dependence can be surprising

## Common Questions

- *Decorator vs Proxy?* — adds behaviour vs controls access.
- *Why not inheritance?* — 2ⁿ subclasses and no runtime flexibility.
- *Where in the JDK?* — `java.io`, `Collections.unmodifiable*`.
- *Does order matter?* — yes; give the retry/circuit-breaker example.

## Common Mistakes

- Decorator not implementing the same interface, breaking stackability
- Stateful decorators that break when reused
- Relying on object identity after decoration
- Using it where a Strategy (one swappable algorithm) is the real need

## Related Topics

- [Proxy](Proxy.md)
- [Adapter](Adapter.md)
- [Circuit Breaker](Circuit%20Breaker.md)

## Revision Summary

Wrap an object in same-interface layers to add behaviour at runtime. Avoids 2ⁿ subclasses. `java.io` and Resilience4j are the canonical examples. Order of composition changes semantics.

## Quick Recall

- Same interface → stackable
- n options → n classes, not 2ⁿ
- `new BufferedReader(new InputStreamReader(...))`
- Decorator adds; Proxy controls
- Decoration breaks object identity
