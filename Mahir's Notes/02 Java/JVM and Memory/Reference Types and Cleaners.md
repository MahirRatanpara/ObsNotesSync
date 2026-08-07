# Reference Types and Cleaners

## Why It Matters

The four reference strengths are how you build caches that don't leak and cleanup that actually runs. Also the answer to "how would you implement a memory-sensitive cache?" and "why is `finalize` deprecated?"

## The Four Strengths

| Type | Collected when | Use |
|---|---|---|
| **Strong** | Never while reachable | Normal references |
| **Soft** | **Before `OutOfMemoryError`** | Memory-sensitive caches |
| **Weak** | **Next GC cycle** | Canonicalising maps, metadata |
| **Phantom** | After finalisation, before reclamation | **Cleanup actions** |

```java
Object strong = new Object();                       // ordinary
SoftReference<Object>    soft   = new SoftReference<>(obj);
WeakReference<Object>    weak   = new WeakReference<>(obj);
PhantomReference<Object> phantom = new PhantomReference<>(obj, queue);

Object o = weak.get();      // may be null at any time
if (o != null) { use(o); }  // MUST null-check
```

**Reachability is the strongest path that exists.** An object referenced both strongly and weakly is strongly reachable — the weak reference has no effect.

## Soft References

Cleared **at the collector's discretion, but guaranteed before `OutOfMemoryError`**.

```java
Map<String, SoftReference<byte[]>> imageCache = new HashMap<>();
```

**The theory:** a cache that shrinks under memory pressure and grows when memory is plentiful.

**The practice: soft references are a poor cache.** Real reasons:

| Problem | Detail |
|---|---|
| **No eviction policy** | The GC decides, not your access pattern — LRU is impossible |
| **Cleared too late** | Usually only during a full GC, so they extend GC pauses |
| **All-or-nothing** | Under pressure the collector often clears nearly all of them at once |
| **Delays collection** | Softly-reachable objects survive extra cycles |

**Use Caffeine or Guava instead** — a real cache with size bounds, TTL, and a proper eviction policy ([W-TinyLFU](../../06%20Caching%20and%20Redis/Caching/Cache%20Eviction%20Policies.md)). Saying this rather than reaching for `SoftReference` demonstrates production judgement.

**`-XX:SoftRefLRUPolicyMSPerMB`** controls how long soft references survive per MB of free heap — worth knowing the knob exists.

## Weak References

Cleared at the **next GC** once no strong reference remains. Do not delay collection at all.

**The canonical use is `WeakHashMap`** — keys are weakly referenced, so entries disappear when the key becomes unreachable elsewhere:

```java
Map<ClassLoader, Metadata> perLoader = new WeakHashMap<>();
```

**Two traps:**

**1. The values are strong.** If a value references its key, the entry is immortal:
```java
weakMap.put(key, new Holder(key));   // value holds key strongly → never collected
```

**2. Literals and interned strings are never collected**, so `WeakHashMap<String, ...>` with literal keys behaves like a normal map.

**Where `WeakHashMap` is genuinely correct:** associating metadata with objects you don't own and whose lifetime you don't control — classloader metadata, listener registries, `ThreadLocalMap` keys.

**`ThreadLocalMap` uses weak keys and strong values**, which is precisely why you must call `remove()` — the key can be collected but the value stays. See [Java Memory Leaks](Java%20Memory%20Leaks.md).

## Reference Queues

Any reference type can register a `ReferenceQueue` and be enqueued when cleared, so you can react.

```java
ReferenceQueue<Connection> queue = new ReferenceQueue<>();
WeakReference<Connection> ref = new WeakReference<>(conn, queue);

// Later, on a background thread
Reference<?> cleared = queue.remove();   // blocks until something is cleared
cleanup(cleared);
```

This is how `WeakHashMap` purges stale entries — it drains its queue on access rather than running a background thread.

## Phantom References

```java
PhantomReference<Resource> ref = new PhantomReference<>(resource, queue);
ref.get();     // ALWAYS returns null — by design
```

**`get()` always returns null**, which is the point: you cannot resurrect the object. You only learn *that* it became unreachable, via the queue.

**Enqueued after finalisation, before memory is reclaimed** — the last safe moment to release an associated native resource.

**Use for cleanup of off-heap resources**: native memory, file handles, GPU buffers. In practice you'd use `Cleaner`, which wraps this correctly.

## Why finalize() Was Deprecated

`Object.finalize()` was deprecated in Java 9 and **removed in Java 18**.

| Problem | Detail |
|---|---|
| **Unpredictable timing** | May run late, or never |
| **No ordering guarantee** | Between objects |
| **Can resurrect objects** | `this` can be reassigned to a static field |
| **Delays collection** | Finalizable objects need **two GC cycles** |
| **Exceptions are swallowed** | A throwing finalizer aborts silently |
| Runs on an unbounded queue thread | Can starve; the queue can grow without bound |
| **Security risk** | Finalizer attacks on partially-constructed objects |

**The two-cycle point is the concrete one:** cycle one discovers the object is unreachable and queues it for finalisation; cycle two actually reclaims it. Finalizable objects therefore live longer and add GC pressure.

## Cleaner — The Replacement

```java
public class NativeResource implements AutoCloseable {
    private static final Cleaner CLEANER = Cleaner.create();

    // MUST be static — a non-static inner class would hold the outer instance
    private static class State implements Runnable {
        private final long handle;
        State(long handle) { this.handle = handle; }
        @Override public void run() { freeNative(handle); }   // the cleanup
    }

    private final State state;
    private final Cleaner.Cleanable cleanable;

    public NativeResource() {
        this.state = new State(allocateNative());
        this.cleanable = CLEANER.register(this, state);
    }

    @Override public void close() { cleanable.clean(); }   // deterministic, preferred
}
```

**The critical rule: the cleanup action must not reference the object being cleaned.** If `State` were a non-static inner class it would hold `NativeResource`, making it permanently reachable — and the cleaner would never fire. This is the mistake everyone makes first.

**`Cleaner` is a safety net, not a strategy.** The primary mechanism should be `AutoCloseable` plus try-with-resources; the cleaner catches the case where a caller forgets.

**Used by the JDK itself** for `DirectByteBuffer` native memory.

## Choosing

| Need | Use |
|---|---|
| Normal object | Strong |
| Memory-sensitive cache | **Caffeine/Guava**, not soft references |
| Metadata keyed by objects you don't own | **`WeakHashMap`** |
| Know when an object is collected | Weak or phantom + `ReferenceQueue` |
| Release native resources | **`AutoCloseable` + `Cleaner` as backup** |
| Deterministic cleanup | **try-with-resources** — always preferred |

**The hierarchy of preference: try-with-resources → `Cleaner` → phantom references → never `finalize`.**

## Common Questions

- *Difference between soft and weak?* — soft survives until memory pressure; weak dies at the next GC.
- *Why is `finalize` deprecated?* — unpredictable, resurrects objects, needs two GC cycles, swallows exceptions.
- *Why does `PhantomReference.get()` return null?* — to make resurrection impossible.
- *Why do soft references make a bad cache?* — no eviction policy, cleared too late, all-or-nothing.
- *Why must a `Cleaner` action be static?* — otherwise it holds the object and prevents collection.

## Common Mistakes

- Using `SoftReference` to build a cache instead of a real cache library
- Values referencing keys in a `WeakHashMap`
- Not null-checking `weakRef.get()`
- A non-static cleanup class in `Cleaner.register`
- Relying on `Cleaner` for correctness rather than as a backstop
- Any use of `finalize`
- `WeakHashMap` with string-literal keys

## Related Topics

- [Garbage Collection](../Garbage%20Collection/Garbage%20Collection.md)
- [Java Memory Leaks](Java%20Memory%20Leaks.md)
- [Cache Eviction Policies](../../06%20Caching%20and%20Redis/Caching/Cache%20Eviction%20Policies.md)
- [Threads and Lifecycle](../Concurrency/Threads%20and%20Lifecycle.md)

## Revision Summary

Soft references clear before OOM but make poor caches; weak references clear at the next GC and power `WeakHashMap`; phantom references signal unreachability without allowing resurrection. `finalize` was removed because it's unpredictable and costs two GC cycles — use `AutoCloseable` with `Cleaner` as a backstop, and keep the cleanup action static.

## Quick Recall

- Strong → Soft (before OOM) → Weak (next GC) → Phantom (post-finalisation)
- **Soft references are a bad cache** — no eviction policy; use Caffeine
- `WeakHashMap`: **weak keys, strong values** — a value holding its key is immortal
- **`PhantomReference.get()` always returns null**
- `finalize` removed in 18 — unpredictable, **two GC cycles**, resurrection
- **`Cleaner` state class must be `static`** or it never fires
- Preference: try-with-resources → `Cleaner` → phantom → never `finalize`
