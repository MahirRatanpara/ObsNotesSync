# Strategy

## Why It Matters

The most used pattern in real LLD interviews. Any "support multiple algorithms" follow-up is answered with Strategy.

## Core Idea

Encapsulate each algorithm behind a common interface and make them interchangeable at runtime. The context delegates rather than branching.

```java
interface PricingStrategy { BigDecimal price(Booking b); }

class RegularPricing  implements PricingStrategy { ... }
class SurgePricing    implements PricingStrategy { ... }
class PromoPricing    implements PricingStrategy { ... }

class BookingService {
    private PricingStrategy strategy;                    // injected or swapped
    void setStrategy(PricingStrategy s) { this.strategy = s; }
    BigDecimal quote(Booking b) { return strategy.price(b); }   // no if/else
}
```

## The Smell It Removes

```java
// Every new pricing rule edits this method — OCP violation
if (type == REGULAR) { ... } else if (type == SURGE) { ... } else if (type == PROMO) { ... }
```

**A growing conditional on a "kind of thing" is the trigger.** Say that out loud in an interview — it's the recognition signal being tested.

## Modern Java: Lambdas

For single-method strategies, an interface plus lambda is often cleaner than a class per strategy:

```java
Map<RideType, PricingStrategy> STRATEGIES = Map.of(
    RideType.REGULAR, b -> b.distance().multiply(BASE),
    RideType.SURGE,   b -> b.distance().multiply(BASE).multiply(surgeFactor())
);
```

Use full classes when the strategy has state, dependencies, or needs its own tests.

## Choosing The Strategy

| Mechanism | When |
|---|---|
| Constructor injection | Fixed for the object's lifetime |
| Setter | Changes at runtime |
| Factory / registry map | Selected by a runtime key |
| DI container | Selected by configuration or profile |

Combining Strategy with a registry Factory is extremely common — the factory picks the strategy, the context runs it.

## Strategy vs State

Structurally identical; the difference is who drives the change:

| | Strategy | State |
|---|---|---|
| Who changes it | **The client** | **The object itself** |
| Strategies know each other | No | **Often yes** — a state triggers the next |
| Represents | Interchangeable algorithms | Lifecycle stages |
| Typical count | Independent options | A transition graph |

## Strategy vs Template Method

| | Strategy | Template Method |
|---|---|---|
| Mechanism | **Composition** | **Inheritance** |
| Swappable at runtime | **Yes** | No |
| Varies | The whole algorithm | Specific steps in a fixed skeleton |

**Prefer Strategy** — composition over inheritance, and testable in isolation.

## Real Uses

- `Comparator` — the purest JDK example; `list.sort(comparator)` is Strategy
- `ThreadPoolExecutor`'s `RejectedExecutionHandler`
- Spring's `Resource` loading, `PasswordEncoder`
- Payment methods, shipping cost calculation, compression algorithms, retry policies, load-balancing algorithms

## When To Use

- Multiple ways to do the same thing
- The choice varies by input, config, or user
- You want to unit-test each algorithm independently
- New variants are expected

## Limitations

- Class per strategy (mitigated by lambdas)
- The client must know which strategy to pick — often pushed into a factory
- Overkill for two branches that will never grow

## Common Questions

- *Strategy vs State?* — client selects vs object transitions itself.
- *Strategy vs Template Method?* — composition/runtime vs inheritance/compile-time.
- *JDK example?* — `Comparator`, `RejectedExecutionHandler`.
- *How is the strategy selected?* — injection, or a registry keyed by type.

## Common Mistakes

- Keeping the `if/else` and calling the branches "strategies"
- Strategies with different method signatures, defeating interchangeability
- Stateful strategies shared across threads
- Applying it to a binary choice that will never expand

## Related Topics

- [State](State.md)
- [Template Method](Template%20Method.md)
- [Factory Method](Factory%20Method.md)

## Revision Summary

Encapsulate interchangeable algorithms behind one interface; the context delegates instead of branching. Triggered by a growing conditional on type. Composition-based, runtime-swappable, individually testable.

## Quick Recall

- Growing `if/else` on kind → Strategy
- Composition, runtime-swappable
- Lambdas for single-method strategies
- `Comparator` is the JDK example
- Client picks (Strategy) vs object transitions (State)
