# Spring Transactions and AOP

## Why It Matters

`@Transactional` is the most-used and most-misunderstood annotation in Spring. Every failure mode traces back to how proxies work.

## How It Works — Proxies

Spring wraps your bean in a proxy. The proxy starts a transaction, calls your method, and commits or rolls back.

| Mechanism | When | Constraint |
|---|---|---|
| **JDK dynamic proxy** | The bean implements an interface | Only interface methods are advised |
| **CGLIB** | No interface (Spring Boot's default) | The class and method must not be `final` |

**Everything below follows from this single fact.**

## The Four Silent Failures

### 1. Self-invocation

```java
@Service
public class OrderService {
    public void process() {
        save();                  // ← plain this.save() — bypasses the proxy
    }

    @Transactional
    public void save() { }       // NO TRANSACTION when called internally
}
```

The proxy only sees calls arriving from *outside*. `this.save()` never leaves the object.

**Fixes:** move the method to another bean (preferred), self-inject via `ObjectProvider`, or use AspectJ load-time weaving.

### 2. Non-public methods
`@Transactional` on `private`, `protected`, or package-private methods is **silently ignored** with the default proxy mode.

### 3. `final` methods or classes
CGLIB subclasses your class. A `final` class can't be subclassed; a `final` method can't be overridden. Both silently disable the transaction.

### 4. Checked exceptions don't roll back

**The default is: roll back on `RuntimeException` and `Error`, commit on checked exceptions.**

```java
@Transactional
public void transfer() throws InsufficientFundsException {
    debit();
    throw new InsufficientFundsException();   // CHECKED → COMMITS the debit
}
```

**Fix:** `@Transactional(rollbackFor = Exception.class)`.

**This default surprises almost everyone and is the highest-value thing to know in this note.**

## Propagation

| Propagation | Behaviour |
|---|---|
| **REQUIRED** (default) | Join the existing transaction, or start one |
| **REQUIRES_NEW** | **Suspend** the outer transaction, run in a new independent one |
| SUPPORTS | Join if one exists, otherwise run without |
| NOT_SUPPORTED | Suspend any existing transaction |
| MANDATORY | Throw if no transaction exists |
| NEVER | Throw if one exists |
| NESTED | Savepoint within the current transaction |

**REQUIRED vs REQUIRES_NEW is the key distinction.**

With `REQUIRED`, an inner method's exception marks the **whole** transaction rollback-only — even if the outer method catches it:

```java
@Transactional
public void outer() {
    try { inner(); }               // inner is @Transactional(REQUIRED)
    catch (Exception e) { log.warn("ignored"); }
    // Commit still FAILS: UnexpectedRollbackException
}
```

**Use `REQUIRES_NEW` for work that must survive the outer transaction's failure** — audit logs, notifications, and failure records. It runs on a separate connection, so beware of connection-pool exhaustion and self-deadlock (the outer transaction may hold locks the inner one waits for).

## Isolation

`@Transactional(isolation = Isolation.REPEATABLE_READ)` maps directly to database isolation levels — see [Transactions and Isolation Levels](Transactions%20and%20Isolation%20Levels.md). `DEFAULT` uses the database's own default, which differs between Postgres (Read Committed) and MySQL (Repeatable Read).

## readOnly

```java
@Transactional(readOnly = true)
```

- Hints the JDBC driver and database (some can route to a replica)
- **Disables Hibernate dirty checking**, a real performance gain on large read queries
- Does **not** prevent writes by itself

Worth applying to every query-only service method.

## Transaction Boundaries

**Put `@Transactional` on the service layer, not the repository.** A business operation spanning three repository calls must be one transaction; annotating repositories gives you three.

**Keep transactions short.** A transaction held open across a remote HTTP call holds database locks for the duration of a network round trip — a classic cause of connection-pool exhaustion and lock contention under load.

**Never do this:**
```java
@Transactional
public void process() {
    repo.save(entity);
    paymentGateway.charge();   // ← external call inside a transaction
}
```

## AOP Concepts

| Term | Meaning |
|---|---|
| **Aspect** | A cross-cutting concern module |
| **Join point** | A point where advice can apply (in Spring: method execution only) |
| **Pointcut** | An expression selecting join points |
| **Advice** | The code to run (`@Before`, `@After`, `@Around`, `@AfterThrowing`) |
| **Weaving** | Applying aspects — at runtime for Spring AOP |

```java
@Aspect @Component
public class TimingAspect {
    @Around("@annotation(Timed)")
    public Object time(ProceedingJoinPoint pjp) throws Throwable {
        long t = System.nanoTime();
        try { return pjp.proceed(); }
        finally { log.info("{} took {}ms", pjp.getSignature(), (System.nanoTime()-t)/1_000_000); }
    }
}
```

**Spring AOP vs AspectJ:** Spring AOP is proxy-based, method-execution only, and has all the limitations above. AspectJ does real bytecode weaving, works on fields, constructors, and self-invocation — at the cost of a build-time or load-time weaving step.

**Ordering:** multiple aspects on one method run in `@Order` sequence. `@Transactional` has a defined order relative to other advice — if you need your aspect inside or outside the transaction, set the order explicitly.

## Other Proxy-Based Annotations

`@Async`, `@Cacheable`, `@Retryable`, `@PreAuthorize` all use the same mechanism — **so all four have the identical self-invocation limitation**. Recognising that they share one root cause is the insight worth carrying.

## Common Questions

- *Why doesn't `@Transactional` work on an internal call?* — the call never passes through the proxy.
- *Does a checked exception roll back?* — no, unless `rollbackFor` is set.
- *REQUIRED vs REQUIRES_NEW?* — join vs suspend and run independently.
- *Why does catching an inner exception still fail the commit?* — the transaction is marked rollback-only.
- *Can you annotate a private method?* — no, silently ignored.
- *JDK proxy vs CGLIB?* — interface-based vs subclass-based; `final` breaks CGLIB.

## Common Mistakes

- Self-invocation
- `@Transactional` on private or final methods
- Assuming checked exceptions roll back
- Transactions on repositories rather than services
- External calls inside a transaction
- Catching an inner transactional exception and expecting the outer to commit
- Forgetting `readOnly = true` on query methods

## Related Topics

- [Spring Core and Dependency Injection](Spring%20Core%20and%20Dependency%20Injection.md)
- [Proxy](Proxy.md)
- [Transactions and Isolation Levels](Transactions%20and%20Isolation%20Levels.md)

## Revision Summary

`@Transactional` works through a proxy, so self-invocation, non-public methods, and `final` classes silently disable it. Checked exceptions do not roll back by default. Use REQUIRED to join and REQUIRES_NEW to run independently, keep transactions at the service layer, and never hold one across a remote call.

## Quick Recall

- Proxy-based → **self-invocation does nothing**
- Public, non-final methods only
- **Checked exceptions commit** — use `rollbackFor`
- REQUIRED joins; REQUIRES_NEW suspends
- Inner rollback marks the whole transaction rollback-only
- Service layer, short, no external calls inside
- `@Async`, `@Cacheable`, `@Retryable` share the same limitation
