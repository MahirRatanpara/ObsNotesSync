# Chain of Responsibility

## Why It Matters

The pattern behind middleware, filters, and interceptors. Any pipeline of independent checks or transformations is this.

## Core Idea

Pass a request along a chain of handlers. Each either handles it or forwards it, and the sender doesn't know which one will act.

```java
abstract class Handler {
    private Handler next;

    public Handler setNext(Handler next) { this.next = next; return next; }

    public void handle(Request r) {
        if (canHandle(r)) process(r);
        else if (next != null) next.handle(r);
        else throw new UnhandledRequestException(r);   // explicit end of chain
    }

    protected abstract boolean canHandle(Request r);
    protected abstract void process(Request r);
}

authHandler.setNext(rateLimitHandler).setNext(validationHandler).setNext(businessHandler);
```

**Decide what happens when nobody handles it.** Silently dropping is the most common bug — throw, or have an explicit terminal handler.

## Two Variants

| Variant | Behaviour | Example |
|---|---|---|
| **Pure** | Exactly one handler processes, then stops | Approval by amount threshold |
| **Filter chain** | **Every** handler processes, then forwards | Servlet filters, middleware |

The filter-chain variant is far more common in practice:

```java
interface Filter { void doFilter(Request r, Response res, FilterChain chain); }

class AuthFilter implements Filter {
    public void doFilter(Request r, Response res, FilterChain chain) {
        if (!authenticate(r)) { res.setStatus(401); return; }   // short-circuit
        chain.doFilter(r, res);                                  // continue
        // code here runs on the way BACK — enables timing, logging, cleanup
    }
}
```

**The code after `chain.doFilter()` runs on the return path.** That's what lets a single filter measure end-to-end latency or wrap the whole downstream in a try/finally. Explaining this bidirectional flow is a strong signal.

## Real Uses

- Servlet `Filter`, Spring `HandlerInterceptor`, Spring Security's filter chain
- OkHttp / Retrofit interceptors
- Express and ASP.NET middleware
- Logging frameworks — a record passes through appenders
- Exception handlers
- Approval workflows by authority level
- Event bubbling in UI toolkits

**Spring Security is the best example to name** — authentication, authorisation, CSRF, and CORS are each a handler in one chain.

## Building The Chain

| Approach | Notes |
|---|---|
| Manual linking | Explicit but verbose |
| **List + index** | Easier to reorder, test, and inject |
| DI with `@Order` | Framework-managed, declarative |

The list-based form is usually cleaner than linked handlers:

```java
class Chain {
    private final List<Filter> filters; private int index = 0;
    void proceed(Request r) {
        if (index < filters.size()) filters.get(index++).doFilter(r, this);
    }
}
```

## When To Use

- Several handlers may process a request and the set varies
- The handler isn't known until runtime
- You want to add, remove, or reorder processing steps without touching the others
- Cross-cutting concerns must be applied uniformly

## Chain of Responsibility vs Decorator

Genuinely similar — both wrap and delegate:

| | Chain of Responsibility | Decorator |
|---|---|---|
| May stop early | **Yes** — that's the point | No, always delegates |
| Handlers may not act | **Yes** | No, each always adds behaviour |
| Interface | Handler-specific | **Same as the wrapped object** |

**Short-circuiting is the distinguishing capability.**

## Limitations

- No guarantee anything handles the request
- Debugging is harder — behaviour depends on chain order and composition
- Long chains add latency
- Order-dependence can be subtle (auth must precede business logic)

## Common Questions

- *What if no handler handles it?* — design it: throw, or add a terminal default handler.
- *CoR vs Decorator?* — short-circuiting versus always delegating.
- *Real-world example?* — Servlet filters, Spring Security.
- *Why does code after `chain.doFilter()` matter?* — it runs on the return path, enabling timing and cleanup.

## Common Mistakes

- Silently dropping unhandled requests
- Order-sensitive handlers assembled in the wrong order
- Handlers with hidden mutable shared state
- Forgetting to call the next handler, silently truncating the chain
- Overusing it for a fixed two-step process

## Related Topics

- [Decorator](../Structural/Decorator.md)
- [Command](Command.md)
- [API Gateway](../../../08%20Microservices/API%20Gateway.md)

## Revision Summary

A request travels a chain of handlers, each able to process, forward, or short-circuit. The filter-chain variant (every handler participates, with code on the return path) dominates real frameworks. Always define unhandled behaviour.

## Quick Recall

- Pipeline of independent handlers
- Pure = one handles; filter = all participate
- Code after `chain.doFilter()` runs on the way back
- Short-circuiting distinguishes it from Decorator
- Servlet filters, Spring Security
- Define what happens if nobody handles it
