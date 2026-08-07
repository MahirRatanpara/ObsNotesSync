# Exceptions Deep Dive

## Why It Matters

Error handling is where correctness quietly fails. Swallowed exceptions, lost causes, and resources closed in the wrong order are among the most common production defects — and all are avoidable.

## The Hierarchy

```
Throwable
├── Error                    — JVM problems; DO NOT CATCH
│   ├── OutOfMemoryError
│   ├── StackOverflowError
│   └── NoClassDefFoundError
└── Exception
    ├── RuntimeException     — UNCHECKED
    │   ├── NullPointerException
    │   ├── IllegalArgumentException
    │   ├── IllegalStateException
    │   ├── IndexOutOfBoundsException
    │   └── ClassCastException
    └── (everything else)    — CHECKED
        ├── IOException
        ├── SQLException
        └── InterruptedException
```

**`Error` means the JVM is in trouble.** You cannot meaningfully recover from `OutOfMemoryError`, and catching it hides the real failure. **Never catch `Throwable` or `Error`.**

**The one nuance:** a top-level handler in a server may catch `Throwable` purely to log before the process dies. That's telemetry, not recovery, and it should rethrow.

## Checked vs Unchecked

| | Checked | Unchecked |
|---|---|---|
| Must declare or catch | **Yes** | No |
| Intended for | Recoverable conditions | Programming errors |
| Extends | `Exception` | `RuntimeException` |

**The original intent:** checked for conditions the caller can reasonably recover from; unchecked for bugs.

**The modern position, and the better interview answer:** checked exceptions have largely fallen out of favour because they —

1. **Leak implementation details** — `throws SQLException` tells every caller you use JDBC
2. **Don't compose with lambdas or streams** — `Consumer.accept` can't throw checked
3. **Are routinely swallowed** — `catch (Exception e) {}` to make the compiler quiet
4. **Force ripple changes** — adding one propagates up every signature

**Evidence:** Kotlin removed them entirely. Spring wraps `SQLException` into unchecked `DataAccessException`. Most modern Java libraries throw unchecked.

**Say the naive answer *and* the informed one.** "Checked for recoverable, unchecked for bugs — though in practice the industry has largely moved to unchecked, because checked exceptions don't compose with lambdas and tend to get swallowed."

## try-with-resources

```java
try (var conn = dataSource.getConnection();
     var stmt = conn.prepareStatement(sql)) {
    return stmt.executeQuery();
}   // closed in REVERSE order, even on exception
```

Any `AutoCloseable` works. Resources close in **reverse declaration order**, which matters when one depends on another.

### Why it beats a manual finally

```java
// BROKEN — close() throws and REPLACES the original exception
Connection c = null;
try { c = open(); work(c); }
finally { if (c != null) c.close(); }   // if this throws, you lose the real cause
```

**try-with-resources keeps the original exception and attaches close failures as suppressed:**

```java
catch (Exception e) {
    e.getMessage();                       // the REAL failure
    for (Throwable s : e.getSuppressed()) // close failures
        log.warn("suppressed", s);
}
```

**This is the single strongest argument for try-with-resources**, and it's the answer to "why not just use finally?"

**Java 9 improvement:** an effectively-final resource declared outside can be used directly.
```java
var conn = getConnection();
try (conn) { ... }
```

## Never Return From finally

```java
int f() {
    try { throw new RuntimeException("real problem"); }
    finally { return 42; }     // DISCARDS the exception entirely
}
```

A `return`, `break`, or `continue` in `finally` **silently swallows any in-flight exception**. Compilers warn; heed it.

## Exception Chaining

```java
// LOSES the cause — unforgivable
catch (SQLException e) { throw new DataException("failed"); }

// CORRECT
catch (SQLException e) { throw new DataException("loading user " + id, e); }
```

**Always pass the cause.** Without it, the stack trace stops at your wrapper and the actual failure is gone. Debugging a production incident with a truncated trace is the direct consequence.

**Include context in the message** — the ID, the operation, the parameter. "Failed" is useless; "loading user 4521" is actionable.

## Multi-Catch and Precise Rethrow

```java
try { risky(); }
catch (IOException | SQLException e) {     // multi-catch
    log.error("failed", e);
    throw new ServiceException(e);
}
```

The multi-catch parameter is **implicitly final** — you cannot reassign it.

**Precise rethrow (Java 7+):** the compiler tracks which exceptions can actually reach a `catch (Exception e)` and lets you declare only those.
```java
void f() throws IOException, SQLException {      // NOT "throws Exception"
    try { doIO(); doSQL(); }
    catch (Exception e) { log.error("", e); throw e; }   // analysed precisely
}
```

## InterruptedException — A Special Case

```java
try { Thread.sleep(1000); }
catch (InterruptedException e) {
    Thread.currentThread().interrupt();   // RESTORE the flag
    throw new CancellationException();
}
```

**Catching `InterruptedException` clears the interrupt flag.** Swallowing it without restoring means higher layers never learn the thread was asked to stop — a genuine bug that makes shutdown hang.

**Either restore the flag or propagate the exception. Never swallow it.**

## Custom Exception Design

```java
public class InsufficientFundsException extends RuntimeException {
    private final String accountId;
    private final long shortfallCents;

    public InsufficientFundsException(String accountId, long shortfall) {
        super("Account %s short by %d cents".formatted(accountId, shortfall));
        this.accountId = accountId;
        this.shortfallCents = shortfall;
    }
    public String accountId() { return accountId; }
    public long shortfallCents() { return shortfallCents; }
}
```

**Rules:**

| Rule | Why |
|---|---|
| **Unchecked by default** | Composes with lambdas; doesn't pollute signatures |
| **Carry structured data**, not just a message | Callers shouldn't parse strings |
| Always offer a `(message, cause)` constructor | Enables chaining |
| One exception per *recoverable* condition | Not one per throw site |
| Name it `...Exception` | Convention |

**Don't create an exception hierarchy mirroring your domain.** Three or four meaningful types beat thirty. Callers distinguish by type only when they'd *act* differently.

## Performance

Constructing an exception captures the stack trace via `fillInStackTrace` — a native walk that costs roughly a microsecond and scales with depth.

**Exceptions must not be used for control flow.** A loop throwing an exception per iteration is orders of magnitude slower than a conditional.

**Stackless exceptions** for genuinely hot paths:
```java
protected MyException(String msg) {
    super(msg, null, false, false);   // no suppression, no stack trace
}
```
Or override `fillInStackTrace()` to return `this`. Used by some frameworks for control-flow signals — but it makes debugging much harder, so reserve it for measured hot paths.

**`-XX:-OmitStackTraceInFastThrow`** is worth knowing: the JIT eventually replaces repeatedly-thrown implicit exceptions (like NPE) with a preallocated stackless instance, so production logs suddenly show exceptions with **no stack trace at all**. That flag disables the optimisation and restores them.

## Anti-Patterns

| Anti-pattern | Problem |
|---|---|
| `catch (Exception e) { }` | **Swallowing** — the worst |
| `e.printStackTrace()` | Goes to stderr, not your logs, no context |
| `throw new RuntimeException()` | Loses the cause |
| `catch (Exception e)` where a specific type is meant | Catches bugs you didn't intend |
| Exceptions for control flow | Slow and unreadable |
| Logging **and** rethrowing | Duplicate entries; log once, at the boundary |
| `catch (Throwable)` | Catches `Error` |
| Empty catch with a `// won't happen` comment | It will |

**"Log and rethrow" is the subtle one.** If every layer logs, one failure produces five stack traces. **Log where you handle, not where you catch and rethrow.**

## Where To Handle

| Layer | Behaviour |
|---|---|
| Deep internals | **Let it propagate** |
| Service layer | Translate to a domain exception, with cause |
| **API boundary** | Catch, log **once**, map to a status code and error body |
| Background worker | Catch, log, decide retry vs DLQ |

**One global handler at the boundary beats scattered try/catch.** In Spring that's `@RestControllerAdvice`. See [API Design](../../04%20High%20Level%20Design/Core%20Concepts/API%20Design.md).

## Common Mistakes

- Swallowing exceptions
- Rethrowing without the cause
- `return` inside `finally`
- Swallowing `InterruptedException` without restoring the flag
- `printStackTrace()` in production code
- Catching `Throwable` or `Error`
- Exceptions for control flow
- Logging at every layer
- Generic messages with no context

## Related Topics

- [Generics Deep Dive](../Generics/Generics%20Deep%20Dive.md)
- [Threads and Lifecycle](../Concurrency/Threads%20and%20Lifecycle.md)
- [Spring Transactions and AOP](../../14%20Spring%20Boot/Spring%20Transactions%20and%20AOP.md)
- [API Design](../../04%20High%20Level%20Design/Core%20Concepts/API%20Design.md)

## Revision Summary

Never catch `Error`. Checked exceptions are increasingly avoided because they don't compose with lambdas and get swallowed. try-with-resources preserves the original exception and suppresses close failures, which a manual `finally` cannot. Always chain the cause, restore the interrupt flag, and handle once at the boundary.

## Quick Recall

- **Never catch `Throwable` or `Error`**
- Checked: the informed answer is that the industry moved away from them
- **try-with-resources: reverse order, close failures become suppressed**
- **Never `return` from `finally`** — it discards the exception
- Always pass the cause; include the ID in the message
- **Catching `InterruptedException` clears the flag — restore it**
- Multi-catch parameter is implicitly final; precise rethrow narrows `throws`
- Exceptions cost a stack walk — **never for control flow**
- `-XX:-OmitStackTraceInFastThrow` restores missing traces
- Log **once**, at the boundary
