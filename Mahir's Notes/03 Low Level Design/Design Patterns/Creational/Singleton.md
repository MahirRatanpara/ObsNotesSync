# Singleton

## Why It Matters

The most-asked and most-criticised pattern. Interviewers use it to test thread safety, the JMM, and whether you can argue *against* a pattern.

## Core Idea

Exactly one instance per JVM, with a global access point.

## Implementations, Worst to Best

### 1. Eager — fine, but not lazy
```java
public class Config {
    private static final Config INSTANCE = new Config();
    private Config() {}
    public static Config getInstance() { return INSTANCE; }
}
```
Thread-safe by class-initialisation semantics. Wasteful only if construction is expensive and it's never used.

### 2. Synchronised method — correct but slow
```java
public static synchronized Config getInstance() { ... }
```
Every call pays lock cost forever, though only the first needs it.

### 3. Double-checked locking — correct **only** with `volatile`
```java
private static volatile Config instance;
public static Config getInstance() {
    if (instance == null) {
        synchronized (Config.class) {
            if (instance == null) instance = new Config();
        }
    }
    return instance;
}
```
**Without `volatile` this is broken.** `new Config()` is allocate → construct → assign, and the JVM may reorder assign before construct. Another thread then sees a non-null, half-built object.

### 4. Bill Pugh holder — **preferred**
```java
public class Config {
    private Config() {}
    private static class Holder { static final Config INSTANCE = new Config(); }
    public static Config getInstance() { return Holder.INSTANCE; }
}
```
Lazy (the holder loads on first access) and thread-safe (the JVM guarantees class initialisation is synchronised) with **no locking in your code**. This is the answer to give.

### 5. Enum — safest against reflection and serialisation
```java
public enum Config {
    INSTANCE;
    public void doWork() { }
}
```
Joshua Bloch's recommendation. The JVM guarantees a single instance even under serialisation and reflection.

## The Attacks

| Attack | Defence |
|---|---|
| **Reflection** — `setAccessible(true)` on the private constructor | Throw from the constructor if the instance already exists; or use an enum |
| **Serialisation** — deserialising creates a new instance | Implement `readResolve()` returning the singleton; or use an enum |
| **Cloning** | Override `clone()` to throw |
| **Multiple classloaders** | Each loader gets its own instance — unavoidable |

## Why It Is Criticised

- **Global mutable state** — any code can reach it, so reasoning about state is hard
- **Untestable** — you cannot inject a fake; tests leak state into each other
- **Hidden dependency** — a class using a singleton doesn't declare it in its constructor
- **Not distributed** — one instance *per JVM*, not per cluster. Candidates routinely assume otherwise.

**The mature answer:** use a DI container to manage a single instance and inject it as an interface. Same benefit, testable, dependency is explicit. Reach for the pattern itself only for genuinely process-wide, stateless concerns.

## When It Is Actually Appropriate

Logging facades, configuration holders, connection pools, caches, hardware access — all process-wide, all with a genuine reason for a single instance.

## Common Questions

- *Why does DCL need volatile?* — reordering can publish a partially constructed object.
- *Why is the holder idiom lazy and thread-safe?* — class initialisation is JVM-synchronised and triggered only on first use.
- *Is a singleton one instance per cluster?* — no, per JVM (per classloader, strictly).
- *How do you break a singleton?* — reflection or serialisation; enum resists both.

## Common Mistakes

- DCL without `volatile`
- Assuming cluster-wide uniqueness
- Making singletons mutable and shared, then debugging cross-test pollution
- Using it where a DI-managed bean is the right answer

## Related Topics

- [Java Memory Model](Java%20Memory%20Model.md)
- [Class Loading](Class%20Loading.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)

## Revision Summary

Prefer the Bill Pugh holder or an enum. DCL requires `volatile`. Criticised for global state and untestability — a DI-managed instance is usually better. One instance per JVM, never per cluster.

## Quick Recall

- Holder idiom = lazy + thread-safe + lock-free
- Enum = reflection- and serialisation-safe
- DCL without `volatile` is broken
- Per JVM, not per cluster
- Prefer DI over the pattern
