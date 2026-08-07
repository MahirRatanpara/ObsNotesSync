# Garbage Collection

## Why It Matters

Pause times are a production concern and a standard senior interview topic. You need to explain collector trade-offs, not just name them.

## Core Idea

GC reclaims unreachable objects. Reachability is determined by tracing from **GC roots**: stack locals, static fields, JNI references, and active thread objects. Anything not reachable is garbage — **reference counting is not used**, so cycles are collected correctly.

## The Generational Hypothesis

Most objects die young. So:
- Collect the young generation frequently and cheaply (copy the few survivors)
- Collect the old generation rarely and expensively

**Minor GC** cost is proportional to the number of *survivors*, not the amount of garbage. This is why allocating many short-lived objects is cheap in Java.

## Mark-Sweep-Compact

1. **Mark** — trace from roots, flag reachable objects
2. **Sweep** — reclaim unmarked space
3. **Compact** — slide survivors together, eliminating fragmentation and making allocation a pointer bump

## The Collectors

| Collector | Algorithm | Pause | Throughput | Use when |
|---|---|---|---|---|
| **Serial** | Single-threaded copy + mark-compact | High | Low | Small heaps, containers with 1 CPU |
| **Parallel (Throughput)** | Multi-threaded, stop-the-world | High | **Highest** | Batch jobs, throughput over latency |
| **G1** | Region-based, mostly concurrent | ~50–200 ms | Good | **Default since Java 9**, heaps > 4 GB |
| **ZGC** | Concurrent, coloured pointers | **< 1 ms** | Slightly lower | Latency-critical, huge heaps (TB) |
| **Shenandoah** | Concurrent, Brooks forwarding pointers | **< 10 ms** | Slightly lower | Latency-critical |
| **Epsilon** | No-op | — | — | Benchmarking, short-lived jobs |

## G1 In Detail

Divides the heap into equal **regions** (1–32 MB), each dynamically labelled Eden, Survivor, Old, or Humongous.

- Concurrently marks to find regions with the most garbage
- Collects those first — hence "**Garbage First**"
- Targets a pause goal: `-XX:MaxGCPauseMillis=200`
- **Humongous objects** (> half a region) are allocated directly in contiguous old regions and are a common cause of unexpected full GCs

G1 is a **soft** real-time collector: it tries to meet the pause target but doesn't guarantee it.

## ZGC and Shenandoah

Achieve sub-millisecond pauses by doing marking *and relocation* concurrently with the application.

- **ZGC** uses **coloured pointers** — metadata stored in unused pointer bits — plus load barriers to fix references lazily
- **Shenandoah** uses a **forwarding pointer** in each object header with read/write barriers

Both trade ~5–15% throughput for pause times that don't grow with heap size. That is the key selling point: a 4 GB heap and a 4 TB heap have the same pause.

## Reference Types

| Type | Cleared when | Use |
|---|---|---|
| Strong | Never while reachable | Normal references |
| **Soft** | Before OOM | Memory-sensitive caches |
| **Weak** | Next GC cycle | Canonicalising maps, `WeakHashMap` |
| **Phantom** | After finalisation | Cleanup actions, replaces `finalize()` |

`finalize()` is deprecated — it's unpredictable, can resurrect objects, and delays collection. Use `Cleaner` or try-with-resources instead.

## Diagnosing GC Problems

| Symptom | Likely cause | Action |
|---|---|---|
| Frequent minor GCs | Eden too small / high allocation rate | Increase young gen, reduce allocation |
| Frequent full GCs | Old gen filling, possible leak | Heap dump, check for retained sets |
| Long pauses | Wrong collector for the workload | Switch to G1/ZGC |
| `OutOfMemoryError: GC overhead limit exceeded` | >98% time in GC, <2% reclaimed | Real leak or badly undersized heap |
| Rising old gen after each full GC | **Memory leak** | Eclipse MAT dominator tree |

Enable logging: `-Xlog:gc*:file=gc.log:time,uptime,level,tags`

## Common Interview Questions

- *Why is a minor GC fast?* — cost scales with survivors, and most objects die young.
- *Can GC collect cyclic references?* — yes; tracing from roots, not reference counting.
- *How does ZGC get sub-ms pauses?* — concurrent marking and relocation, coloured pointers, load barriers.
- *Does `System.gc()` force a GC?* — no, it's a hint; it can be disabled entirely with `-XX:+DisableExplicitGC`.
- *What is a memory leak in Java?* — an unintended strong reference keeping objects reachable (static collections, unclosed listeners, ThreadLocals in pooled threads).

## Common Mistakes

- Calling `System.gc()` in production code
- Assuming reference counting is used
- Setting a very low `MaxGCPauseMillis` on G1 — it shrinks the young gen and increases GC frequency, hurting throughput
- Forgetting to remove `ThreadLocal` values in a thread pool — the thread outlives the request and the value leaks

## Related Topics

- [JVM Architecture and Memory Areas](JVM%20Architecture%20and%20Memory%20Areas.md)
- [JIT and Escape Analysis](JIT%20and%20Escape%20Analysis.md)
- Performance Tuning *(not yet written)*

## Revision Summary

Tracing from GC roots, generational split for cheap minor collections. G1 is the default region-based collector; ZGC/Shenandoah trade throughput for sub-millisecond pauses. Leaks are unintended strong references.

## Quick Recall

- GC roots: stack, statics, JNI, live threads
- Minor GC cost ∝ survivors
- G1 default since Java 9, region-based, pause-target driven
- ZGC/Shenandoah: concurrent relocation, pause independent of heap size
- Soft = cache, Weak = canonical map, Phantom = cleanup
