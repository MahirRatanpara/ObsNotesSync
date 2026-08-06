# Spring Core and Dependency Injection

## Why It Matters

The foundation of every Spring question. Interviewers use bean scopes and proxying to test whether you understand what the framework actually does at runtime.

## Inversion of Control

You don't construct dependencies; the container constructs and injects them. This is [Dependency Inversion](../03%20Low%20Level%20Design/SOLID/SOLID%20Principles.md) enforced by a framework.

```java
@Service
public class OrderService {
    private final OrderRepository repo;
    private final PaymentClient payments;

    // Constructor injection — no @Autowired needed since Spring 4.3
    public OrderService(OrderRepository repo, PaymentClient payments) {
        this.repo = repo;
        this.payments = payments;
    }
}
```

## Injection Types — Use Constructor

| | Constructor | Setter | Field (`@Autowired` on the field) |
|---|---|---|---|
| Immutability (`final`) | **Yes** | No | No |
| Fails fast on missing dependency | **Yes** | No | No |
| Testable without Spring | **Yes** | Yes | **No — needs reflection** |
| Circular dependencies | **Detected at startup** | Silently allowed | Silently allowed |
| Exposes too many dependencies | **Visibly** — a long constructor is a design smell | Hidden | Hidden |

**Constructor injection, always.** The last row is the underrated argument: a constructor with nine parameters is obviously wrong, whereas nine `@Autowired` fields look tidy while being equally wrong.

**Field injection makes unit testing require Spring or reflection**, which is the practical reason it's discouraged.

## Bean Scopes

| Scope | Instances | Use |
|---|---|---|
| **singleton** (default) | One per container | **Stateless services** |
| prototype | New on every injection/lookup | Stateful helpers |
| request | One per HTTP request | Web only |
| session | One per HTTP session | Web only |
| application | One per ServletContext | Web only |

**Singletons must be stateless.** A mutable field on a singleton service is shared across every concurrent request — a race condition that appears only under load. This is the most common Spring concurrency bug.

**The scope-mismatch trap:** injecting a prototype bean into a singleton gives you **one** prototype instance, created once, because injection happens once at startup. To get a fresh instance per call you need `ObjectProvider<T>`, `@Lookup`, or a scoped proxy.

## Component Stereotypes

| Annotation | Meaning |
|---|---|
| `@Component` | Generic managed bean |
| `@Service` | Business logic (semantic only) |
| `@Repository` | Data access — **also translates persistence exceptions** into Spring's `DataAccessException` hierarchy |
| `@Controller` / `@RestController` | Web layer |
| `@Configuration` | Declares `@Bean` methods |

`@Repository` is the only one with behaviour beyond documentation — the exception translation is real and worth knowing.

## @Configuration vs @Component

```java
@Configuration
public class AppConfig {
    @Bean ServiceA serviceA() { return new ServiceA(serviceB()); }
    @Bean ServiceB serviceB() { return new ServiceB(); }   // called TWICE?
}
```

**No — called once.** `@Configuration` classes are CGLIB-proxied so that inter-bean method calls return the container-managed singleton rather than constructing a new object.

With `@Component` instead of `@Configuration` ("lite mode"), no proxy is created and `serviceB()` genuinely runs twice, producing two instances. **This is a classic interview question** and a real source of subtle bugs.

## Resolving Ambiguity

When several beans match a type:

| Mechanism | Use |
|---|---|
| `@Primary` | Mark the default choice |
| `@Qualifier("name")` | Select explicitly |
| Parameter name matching | Spring matches the variable name to the bean name |
| `List<Interface>` injection | **Inject all implementations** — pairs perfectly with the Strategy pattern |

```java
public OrderService(List<PricingStrategy> strategies) {   // all implementations
    this.byType = strategies.stream()
        .collect(toMap(PricingStrategy::type, identity()));
}
```

**Injecting a `List` of an interface is the idiomatic Spring way to build a Strategy registry** — new strategies register themselves simply by existing as beans.

## Bean Lifecycle

```
Instantiate → populate dependencies → *Aware callbacks →
BeanPostProcessor.before → @PostConstruct → afterPropertiesSet →
BeanPostProcessor.after  →  [ BEAN READY ]  →
@PreDestroy → destroy()
```

**`BeanPostProcessor.after` is where proxies are created** — this is the hook that implements `@Transactional`, `@Async`, `@Cacheable`, and AOP generally.

**Consequence:** inside `@PostConstruct`, `this` is the raw object, not the proxy. Calling your own `@Transactional` method there does nothing.

## Configuration Properties

```java
@ConfigurationProperties(prefix = "app.payment")
public record PaymentProps(String apiUrl, Duration timeout, int maxRetries) { }
```

Type-safe, validated (`@Validated`), IDE-completable, and testable — strongly preferable to scattering `@Value("${...}")` across classes.

**Property resolution order** (highest wins): command-line args → environment variables → `application-{profile}.yml` → `application.yml` → defaults.

**Profiles** (`@Profile("prod")`) select beans per environment. Avoid profile-specific logic inside beans; select whole beans instead.

## Circular Dependencies

```
A → B → A
```

Constructor injection **fails at startup** with a clear error. Field/setter injection silently resolves it via a three-level cache — which hides a design problem.

Spring Boot 2.6+ **disables circular references by default**, forcing you to fix them.

**The fix is almost always to extract the shared logic into a third bean**, not to add `@Lazy`.

## Common Questions

- *Why constructor injection?* — immutability, fail-fast, testability, and visible over-dependency.
- *Are singletons thread-safe?* — Spring guarantees one instance, **not** thread safety. Keep them stateless.
- *`@Configuration` vs `@Component` for `@Bean` methods?* — CGLIB proxying versus none; the latter creates duplicate instances.
- *Prototype into a singleton?* — injected once; use `ObjectProvider` for a fresh instance.
- *Where are proxies created?* — `BeanPostProcessor` after initialisation.

## Common Mistakes

- Field injection
- Mutable state on singleton beans
- Expecting a prototype to be fresh per method call
- `@Bean` methods in `@Component` classes
- Calling a self `@Transactional` method from `@PostConstruct`
- Adding `@Lazy` to paper over a circular dependency

## Related Topics

- [Spring Transactions and AOP](Spring%20Transactions%20and%20AOP.md)
- [Proxy](../03%20Low%20Level%20Design/Design%20Patterns/Structural/Proxy.md)
- [SOLID Principles](../03%20Low%20Level%20Design/SOLID/SOLID%20Principles.md)

## Revision Summary

The container owns construction; use constructor injection for immutability and fail-fast behaviour. Singletons are one instance, not thread-safe — keep them stateless. `@Configuration` is CGLIB-proxied so inter-bean calls return singletons. Proxies are applied by a `BeanPostProcessor` after initialisation.

## Quick Recall

- **Constructor injection always**
- Singleton = one instance, **not** thread-safe → stateless
- Prototype into singleton = injected once
- `@Configuration` proxied; `@Component` `@Bean` methods are not
- `List<Interface>` injection = Strategy registry
- Proxies created in `BeanPostProcessor.after`
- Circular refs disabled by default since Boot 2.6
