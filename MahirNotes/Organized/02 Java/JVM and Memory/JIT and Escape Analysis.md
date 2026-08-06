# JIT and Escape Analysis

## Why It Matters

Explains why Java performance approaches C for hot code, why microbenchmarks lie, and why "objects are always heap-allocated" is false.

## Tiered Compilation

The JVM starts interpreting and progressively compiles hot code:

| Tier | What | When |
|---|---|---|
| 0 | Interpreter | Always, initially |
| 1–3 | C1 (client compiler) | Quick compilation, gathers profiling data |
| 4 | C2 (server compiler) | Aggressive optimisation of hot methods |

**Hotspot detection** uses invocation and loop back-edge counters. Once a threshold is crossed the method (or loop, via *on-stack replacement*) is compiled.

## Key Optimisations

| Optimisation | What it does |
|---|---|
| **Method inlining** | Copies a small method's body into the caller, enabling everything else |
| **Escape analysis** | Proves an object never leaves a scope |
| **Scalar replacement** | Replaces a non-escaping object with plain local variables — no allocation at all |
| **Lock elision** | Removes synchronisation on provably thread-confined objects |
| **Loop unrolling / vectorisation** | Fewer branches, SIMD instructions |
| **Devirtualisation** | Turns a virtual call into a direct call when only one implementation is loaded |
| **Dead code elimination** | Removes code with no observable effect |

**Inlining is the enabler.** Most other optimisations only become possible once call boundaries disappear — which is why very large methods (>325 bytecodes by default) optimise poorly.

## Escape Analysis

The compiler classifies each object:

| Escape state | Meaning | Optimisation |
|---|---|---|
| **NoEscape** | Never leaves the method | Scalar replacement — no allocation |
| **ArgEscape** | Passed to a method but doesn't escape further | Lock elision possible |
| **GlobalEscape** | Stored in a field, returned, or thrown | Must be heap-allocated |

```java
public double distance(double x, double y) {
    Point p = new Point(x, y);    // NoEscape
    return Math.sqrt(p.x * p.x + p.y * p.y);
}
// After scalar replacement, no Point object is ever allocated.
```

**This is the correct nuance to the "all objects live on the heap" claim.** Java has no stack allocation *in the language*, but the JIT can eliminate the allocation entirely.

Escape analysis is defeated by: storing into a static or instance field, returning the object, passing it to a non-inlined method, or throwing it.

## Lock Elision and Coarsening

```java
public String build() {
    StringBuffer sb = new StringBuffer();   // synchronized, but thread-confined
    sb.append("a").append("b");
    return sb.toString();
}
```
The JIT proves `sb` never escapes and removes the locking entirely. **Lock coarsening** merges adjacent synchronised blocks on the same monitor into one.

This is why the StringBuffer/StringBuilder performance gap is smaller than folklore suggests — though StringBuilder is still the correct choice.

## Deoptimisation

C2 optimises **speculatively** based on observed behaviour — for example, assuming only one implementation of an interface exists. If a second is loaded later, the compiled code is invalidated and execution falls back to the interpreter, then recompiles.

This is why:
- Benchmarks must **warm up** before measuring
- Performance can regress after a new class is loaded
- Use **JMH** for microbenchmarks; hand-rolled loops measure the interpreter, dead-code elimination, or constant folding rather than real work

## Useful Flags

| Flag | Purpose |
|---|---|
| `-XX:+PrintCompilation` | Log JIT compilation events |
| `-XX:+UnlockDiagnosticVMOptions -XX:+PrintInlining` | Show inlining decisions |
| `-XX:-DoEscapeAnalysis` | Disable EA (for A/B measurement) |
| `-XX:+PrintAssembly` | Emitted native code (needs hsdis) |

## Common Questions

- *Are all Java objects on the heap?* — logically yes, but escape analysis plus scalar replacement can eliminate the allocation entirely.
- *Why is my microbenchmark faster than production?* — dead-code elimination and constant folding; use JMH with blackholes.
- *Why does performance degrade after startup?* — a new implementation was loaded, causing deoptimisation.

## Common Mistakes

- Benchmarking without warm-up
- Writing huge methods and preventing inlining
- Assuming `synchronized` always costs — it may be elided
- Trusting `System.nanoTime()` loops instead of JMH

## Related Topics

- [JVM Architecture and Memory Areas](JVM%20Architecture%20and%20Memory%20Areas.md)
- [Garbage Collection](../Garbage%20Collection/Garbage%20Collection.md)
- Performance Tuning *(not yet written)*

## Revision Summary

Interpreter → C1 → C2 based on hotness. Inlining enables everything else. Escape analysis plus scalar replacement can remove allocations and locks. Speculative optimisation means deoptimisation is normal — always warm up benchmarks.

## Quick Recall

- Tier 0 interpreter, C1 profiling, C2 aggressive
- Inlining is the gateway optimisation
- NoEscape → scalar replacement → zero allocation
- Lock elision removes uncontended, thread-confined locks
- Use JMH, always warm up
