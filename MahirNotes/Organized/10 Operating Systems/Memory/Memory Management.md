# Memory Management

## Why It Matters

Explains page faults, why memory-mapped files are fast, what "the database is I/O bound" really means, and why container memory limits kill processes.

## Virtual Memory

Every process sees a private, contiguous address space. The MMU translates virtual addresses to physical ones via **page tables**.

**Why it exists:**

| Benefit | Detail |
|---|---|
| **Isolation** | A process cannot address another's memory |
| **Simplicity** | Programs see contiguous memory regardless of physical fragmentation |
| **Overcommit** | Allocate more virtual memory than physical RAM exists |
| **Sharing** | Shared libraries mapped once, visible in many processes |

Pages are typically **4 KB** (with 2 MB / 1 GB "huge pages" available to reduce TLB pressure).

## The TLB

Page-table lookups are themselves memory accesses, so the **Translation Lookaside Buffer** caches recent translations.

**A TLB miss costs a page-table walk** — several memory accesses. This is why:
- Huge pages help memory-heavy workloads (fewer entries needed for the same span)
- Process context switches are expensive (TLB flush)
- Random access patterns hurt more than the cache-miss cost alone suggests

## Page Faults

| Type | Cause | Cost |
|---|---|---|
| **Minor** | Page is in RAM but not mapped to this process | Cheap — just update the page table |
| **Major** | Page must be read from disk | **Expensive — milliseconds** |
| Invalid | Illegal address | Segmentation fault |

**Major faults are the killer.** A workload whose working set exceeds RAM thrashes: constant paging to disk, and throughput collapses by orders of magnitude.

**"The database is I/O bound" usually means the working set no longer fits in the buffer pool.** That's the diagnosis to reach for.

## Page Cache

The kernel caches file contents in otherwise-free RAM. Reads hit RAM; writes are buffered and flushed later.

**This is why `free` showing "low free memory" is not a problem** — the kernel is using spare RAM productively and will release it under pressure. Cached memory is available memory.

**Consequences for system design:**

- **Kafka relies on the page cache** rather than an application-level cache — sequential writes land in cache and are read from cache by consumers who are caught up. That's a large part of its throughput.
- Databases usually manage their own buffer pool and use `O_DIRECT` to bypass the page cache, avoiding double-caching.

## Memory-Mapped Files

`mmap` maps a file into the address space; reading memory triggers page faults that load file data on demand.

| Advantage | Detail |
|---|---|
| **No explicit read/write syscalls** | Access is ordinary memory access |
| **Zero copy** | No user-space buffer copy |
| Lazy loading | Only touched pages are read |
| **Shared** | Multiple processes map the same pages once |

Used by: Kafka (index files), LMDB, SQLite, RocksDB, and the JVM for loading class files.

**Downsides:** fault latency is unpredictable, flushing is at the mercy of the kernel unless you `msync`, and it's awkward for files larger than the address space on 32-bit systems.

## Allocation

| Region | Managed by | Cost |
|---|---|---|
| **Stack** | Compiler — pointer bump | **Very cheap** |
| **Heap** | Allocator (`malloc`, JVM GC) | More expensive |

**Fragmentation:**
- **External** — free memory exists but isn't contiguous. Compacting collectors fix this by moving objects.
- **Internal** — allocated blocks are larger than requested (rounding to size classes).

**Modern allocators** (jemalloc, tcmalloc) use per-thread caches and size classes to avoid lock contention — the same idea as `LongAdder` in Java: shard the hot structure per thread.

## Cache Hierarchy

| Level | Latency | Size |
|---|---|---|
| Register | 0 cycles | Bytes |
| L1 | ~1 ns | 32–64 KB |
| L2 | ~4 ns | 256 KB–1 MB |
| L3 | ~10 ns | 8–32 MB (shared) |
| **RAM** | **~100 ns** | GB |
| SSD | ~100 µs | TB |

**RAM is ~100× slower than L1.** This is why data locality dominates performance and why an `ArrayList` outperforms a `LinkedList` despite identical asymptotic complexity for iteration — contiguous memory means the prefetcher works.

**False sharing:** two threads writing to different variables on the same 64-byte cache line invalidate each other's caches constantly. Padding (`@Contended` in Java) separates them.

## OOM And Containers

**The OOM killer** activates when the kernel can't satisfy an allocation, and terminates a process by a heuristic score.

**In containers this is the common production failure:** a container's memory limit counts the JVM heap **plus** metaspace, thread stacks, direct byte buffers, JIT code cache, and native allocations.

```
container limit = heap + metaspace + (threads × stack) + direct buffers + code cache + native
```

Setting `-Xmx` equal to the container limit guarantees an eventual OOM kill. **Leave 20–25% headroom**, or use `-XX:MaxRAMPercentage=75`.

**Container-aware JVMs (Java 10+) read cgroup limits** rather than host memory — but only if `UseContainerSupport` is on (it is by default). Older JVMs saw the host's RAM and sized the heap catastrophically wrong.

**A container OOM kill (exit code 137) is a different event from a Java `OutOfMemoryError`** — the first is the kernel killing the process, the second is the JVM failing to allocate within its heap. Diagnosing them requires different tools.

## Common Mistakes

- Reading low "free memory" as a problem when it's page cache
- `-Xmx` equal to the container limit
- Ignoring non-heap JVM memory when sizing containers
- Assuming `mmap` writes are durable without `msync`
- Ignoring false sharing on contended counters
- Confusing exit code 137 with a Java OOM

## Related Topics

- [JVM Architecture and Memory Areas](../../02%20Java/JVM%20and%20Memory/JVM%20Architecture%20and%20Memory%20Areas.md)
- [Garbage Collection](../../02%20Java/Garbage%20Collection/Garbage%20Collection.md)
- [Processes and Threads](../Processes%20and%20Threads/Processes%20and%20Threads.md)
- [Kubernetes Core Concepts](../../13%20Kubernetes/Kubernetes%20Core%20Concepts.md)

## Revision Summary

Virtual memory gives isolation and overcommit at the cost of translation; TLB misses and major page faults are the expensive events. The page cache makes free RAM productive and underpins Kafka's throughput. In containers, the memory limit covers far more than the JVM heap — leave headroom.

## Quick Recall

- 4 KB pages; TLB caches translations; huge pages reduce misses
- Major page fault = disk read = milliseconds
- Low "free" memory is page cache — not a problem
- RAM ≈ 100× slower than L1 → locality dominates
- False sharing → pad hot counters
- Container limit = heap + metaspace + stacks + direct + code cache
- Exit 137 ≠ Java OutOfMemoryError
