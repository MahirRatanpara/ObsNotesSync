# CS Fundamentals + Java Internals — Deep Checklist

**Do this Saturday. Fundamentals stop Saturday night. Sunday onwards = director round prep.**

---

## Read this first

- **This list is bigger than one day.** Roughly 25–30 hours of real work. Today you will finish **Tier 1** and part of **Tier 2**. That is the correct outcome, not a failure.
- **Tier 1 = must know cold today.** Tier 2 = do if time remains. Tier 3 = stretch, only if you have extra days.
- **Learn traces, not lists.** Section A gives you three end-to-end stories. Every topic below hangs off one of them. When an interviewer asks a fundamentals question, you locate it on a trace and walk from there. This is what makes you sound like you _understand_ rather than _memorised_.
- **Out loud or it doesn't count.** Reading is not learning. Explain each item to an empty room in 60–90 seconds.

---

# SECTION A — The three spine traces (TIER 1 · do these first, 2 hours)

If you nail only this section, you can improvise most fundamentals questions.

## Trace 1 — "What happens when Java runs `int[] arr = new int[1000];` and then reads `arr[500]`?"

Walk it top to bottom. Tick when you can narrate the whole chain unprompted:

- [x] JVM allocates the array in the **heap**, in the **Eden** space of the young generation
- [x] A reference to it sits in the **thread's stack frame** (a local variable)
- [x] The allocation is a pointer bump in a **TLAB** (thread-local allocation buffer) — fast, no lock
- [x] Reading `arr[500]` produces a **virtual address**
- [ ] The CPU checks its **caches**: L1 → L2 → L3
- [ ] On a miss, the **MMU** translates virtual → physical address
- [ ] It checks the **TLB** (cache of recent translations) first
- [ ] TLB miss → walk the **multi-level page table**
- [ ] If the page isn't in RAM → **page fault** → OS loads it from disk/swap
- [ ] The data comes back in a **cache line** (typically 64 bytes) — so neighbours come free (spatial locality)
- [ ] Later, when nothing references the array, **GC** reclaims it: found unreachable from **GC roots**, collected in a **minor GC**

**Self-test:** explain this in 3 minutes without notes.

## Trace 2 — "What happens when you type a URL and press enter?"

- [x] Browser cache → OS cache → **DNS** resolver → root → TLD → authoritative nameserver → IP address
- [ ] **ARP** resolves the next-hop MAC address on the local network
- [ ] **TCP three-way handshake** (SYN → SYN-ACK → ACK) to port 443
- [ ] **TLS handshake** — certificate validation, key agreement, then symmetric encryption
- [ ] HTTP request written to a **socket** → kernel **socket buffer**
- [ ] Data becomes **TCP segments** → **IP packets** → **Ethernet frames** → NIC → wire
- [ ] Through switches (MAC), routers (IP), possibly NAT, a CDN edge, a load balancer
- [ ] Server accepts from the **backlog queue**, reads the request, application handles it
- [ ] Response travels back; TCP reassembles in order, retransmits losses
- [ ] Browser parses HTML, builds the DOM, fetches CSS/JS/images, renders
- [ ] Connection is reused (**keep-alive**) or closed (FIN/ACK, **TIME_WAIT**)

## Trace 3 — "What happens when you run `UPDATE accounts SET balance = 100 WHERE id = 42;`?"

- [ ] Connection taken from the **connection pool**
- [ ] SQL parsed → validated → **query planner** picks a plan using table **statistics**
- [ ] Index lookup on the primary key → **B+ tree** descent → leaf page
- [ ] Page fetched into the **buffer pool** (in-memory page cache) if not already there
- [ ] Row **locked** (or an MVCC version created)
- [ ] Change written to the **write-ahead log (WAL/redo log)** — this is what makes it durable
- [ ] `COMMIT` → WAL flushed to disk (`fsync`) → transaction is durable
- [ ] The dirty data page is written to disk later, at a **checkpoint**
- [ ] Change streamed to **replicas** (sync, async, or semi-sync) → **replication lag**
- [ ] Locks released; other transactions see the new value per the **isolation level**

---

# SECTION B — CPU and memory hierarchy (TIER 1 · 1.5 hours)

This is the section that directly answers "how is memory managed inside a CPU."

## Tier 1

- [ ] **Instruction cycle** — fetch, decode, execute, write-back
- [ ] **Registers** — fastest storage, inside the CPU, sub-nanosecond
- [ ] **Cache hierarchy** — L1 (per core, ~1ns), L2 (per core), L3 (shared across cores), then RAM (~100ns), then SSD (~100µs), then disk. Know the rough ratios: RAM is ~100x slower than L1; SSD is ~1000x slower than RAM.
- [ ] **Cache line** — memory moves in ~64-byte blocks, not single bytes. Explains why array iteration is fast and linked-list traversal is slow.
- [ ] **Locality of reference** — temporal (reuse the same data soon) and spatial (use nearby data soon). Caches exist because programs have both.
- [ ] **Cache hit vs miss**; cold/capacity/conflict misses
- [ ] **MMU (memory management unit)** — the hardware that translates virtual to physical addresses
- [ ] **TLB** — small cache of recent virtual→physical translations; a TLB miss costs a page-table walk
- [ ] **Page table** — usually multi-level (4 levels on x86-64) to avoid one giant flat table
- [ ] **Virtual vs physical address** — why virtualisation exists: isolation, security, the illusion of more memory, simpler programming model
- [ ] **Process address space layout** — text (code), data, BSS, **heap** (grows up), **stack** (grows down), memory-mapped regions
- [ ] **Stack vs heap** — stack: per-thread, automatic, LIFO frames, fast, size-limited (StackOverflowError). Heap: shared, dynamic, managed by allocator/GC.

## Tier 2

- [ ] **Cache coherence** — MESI protocol basics; why multiple cores need to agree on memory
- [ ] **False sharing** — two threads writing different variables on the same cache line cause contention. Directly relevant to Java performance.
- [ ] **Memory barriers / fences** and **instruction reordering** — CPUs and compilers reorder for speed; barriers stop that. This is the hardware basis of Java's `volatile`.
- [ ] **Store buffer**, write combining
- [ ] **DMA** (direct memory access) — devices write to RAM without the CPU
- [ ] **Interrupts** — how hardware gets the CPU's attention
- [ ] **Pipelining and branch prediction** — why unpredictable branches are slow

## Tier 3

- [ ] NUMA (non-uniform memory access) on multi-socket machines
- [ ] Huge pages / transparent huge pages
- [ ] Speculative execution and its security implications (Spectre/Meltdown, at a conceptual level)

---

# SECTION C — Operating systems (TIER 1 core, 1.5 hours)

## Tier 1 — the ones you fudged, plus their neighbours

- [ ] **Memory leak** — definition; Java causes (static collections, unclosed resources, ThreadLocal in pooled threads, unremoved listeners, ClassLoader leaks); C/C++ version; detection via heap dump + Eclipse MAT
- [ ] **Virtual memory** — pages, page tables, TLB, demand paging, swap
- [ ] **Page fault** — minor (page in RAM, just not mapped — cheap) vs major (must read from disk — slow)
- [ ] **Thrashing** — working set exceeds RAM; system spends its time paging instead of working
- [ ] **The 16GB-on-8GB answer** — usually launches; working set vs total allocation; paging; thrashing; OOM killer on Linux; 32-bit ~4GB address cap; more RAM beats a bigger page file
- [ ] **Process vs thread** — separate address space vs shared; context switch cost (saved registers, TLB/cache pollution)
- [ ] **User space vs kernel space**; **system calls** and the trap into the kernel
- [ ] **Deadlock** — four Coffman conditions (mutual exclusion, hold-and-wait, no preemption, circular wait); prevention vs avoidance vs detection
- [ ] **Race condition**; **mutex vs semaphore** (mutex has ownership, used for locking; semaphore is a counter, used for signalling)

## Tier 2

- [ ] **Process lifecycle** — `fork`, `exec`, `wait`, zombie and orphan processes
- [ ] **Scheduling** — preemptive vs cooperative, time slices, priority, why context switches aren't free
- [ ] **IPC** — pipes, shared memory, message queues, sockets, signals
- [ ] **File descriptors**; blocking vs non-blocking I/O
- [ ] **I/O multiplexing** — `select` / `poll` / `epoll`; why epoll scales (this underpins Netty, Node.js, nginx)
- [ ] **Page cache** — OS caches file data in RAM; buffered vs direct I/O; `fsync` and why databases need it
- [ ] **mmap** — mapping a file into the address space
- [ ] **Copy-on-write** — how `fork()` avoids copying memory until a write happens
- [ ] **Zero-copy** — `sendfile`, avoiding user-space copies (why Kafka is fast)
- [ ] **Fragmentation** — internal vs external; why paging eliminates external fragmentation
- [ ] **Paging vs segmentation**

## Tier 2 — container-aware (directly relevant to your work)

- [ ] **cgroups and memory limits** — how containers cap memory
- [ ] **What happens when a JVM in a container exceeds its limit** — the kernel OOM-kills the process (exit code 137), and you get no Java stack trace. A classic production puzzle.
- [ ] **Why `-XX:MaxRAMPercentage` matters** — older JVMs read host RAM, not container limits, and over-allocate

---

# SECTION D — Java internals (TIER 1 · this is your language, highest leverage, 2.5 hours)

## D1. JVM memory model — structure (Tier 1)

- [ ] **Heap** — shared across threads. Young generation (**Eden** + two **Survivor** spaces) and **Old/Tenured** generation.
- [ ] **Metaspace** — class metadata; native memory since Java 8 (replaced PermGen)
- [ ] **Thread stacks** — one per thread, holds frames, local variables, references
- [ ] **Code cache** — JIT-compiled native code
- [ ] **Off-heap / direct memory** — `ByteBuffer.allocateDirect`, not managed by GC the same way
- [ ] **Object layout** — object header (mark word + class pointer), fields, padding; **compressed oops** (why heaps under 32GB are more efficient)
- [ ] **TLAB** — thread-local allocation buffer; allocation is a fast pointer bump

## D2. Garbage collection (Tier 1)

- [ ] **Reachability** — objects are collected when unreachable from **GC roots** (stack locals, static fields, JNI refs, active threads)
- [ ] **Generational hypothesis** — most objects die young, so collect the young generation frequently and cheaply
- [ ] **Minor GC** (young gen) vs **major/full GC** (whole heap) — and why full GCs hurt
- [ ] **Mark-sweep-compact**; copying collection in the young gen
- [ ] **Stop-the-world** pauses and **safepoints**
- [ ] **Collectors**: Serial, Parallel (throughput), **G1** (default since Java 9, region-based, pause-target driven), **ZGC / Shenandoah** (low-latency, sub-millisecond pauses). CMS is removed.
- [ ] **Key flags** — `-Xms`, `-Xmx`, `-XX:MaxMetaspaceSize`, `-XX:MaxRAMPercentage`
- [ ] **OutOfMemoryError variants** — Java heap space, GC overhead limit exceeded, Metaspace, unable to create native thread, Direct buffer memory. Each has a _different_ cause; being able to distinguish them is a strong signal.
- [ ] **Diagnostic tools** — `jmap` (heap dump), `jstack` (thread dump), `jstat` (GC stats), `jcmd`, JFR (Flight Recorder), VisualVM, Eclipse MAT, async-profiler

**Interview gold:** "How would you debug a memory leak in production?" → monitor heap growth after full GC → take a heap dump → open in MAT → find the dominator tree / biggest retained set → trace the GC-root reference chain → identify the unintended reference.

## D3. Java concurrency (Tier 1 — Adobe asks this)

- [ ] **Java Memory Model** — the three problems: **atomicity, visibility, ordering**
- [ ] **happens-before** relationship — the rule that makes writes visible to other threads
- [ ] **`volatile`** — guarantees visibility and prevents reordering, but NOT atomicity (`count++` is still broken)
- [ ] **`synchronized`** — mutual exclusion + visibility; intrinsic locks; monitor enter/exit
- [ ] **`ReentrantLock`** — tryLock, timed lock, fairness, condition variables; when to prefer it over `synchronized`
- [ ] **`ReadWriteLock` / `StampedLock`** — many readers, one writer
- [ ] **Atomic classes and CAS** (compare-and-swap) — lock-free updates; the **ABA problem**
- [ ] **Thread pools** — `ExecutorService`, core vs max pool size, queue choice, rejection policies. Know why an unbounded queue means max pool size is never reached.
- [ ] **`CompletableFuture`** — composing async work, `thenApply` vs `thenCompose`, exception handling
- [ ] **`ConcurrentHashMap`** — Java 8+ uses CAS + per-bucket `synchronized`, not segment locks
- [ ] **`CountDownLatch`, `Semaphore`, `CyclicBarrier`** — what each is for
- [ ] **`ThreadLocal`** — useful, but a leak source in thread pools if you don't `remove()`
- [ ] **Deadlock in Java** — how to reproduce, how to detect with a thread dump, how to avoid (consistent lock ordering, timeouts)
- [ ] **Virtual threads / Project Loom** (Java 21) — lightweight threads managed by the JVM; why they help blocking I/O workloads and why they don't help CPU-bound ones. **High chance of coming up as a "keeping current" question.**

## D4. Java core internals (Tier 2)

- [ ] **HashMap internals** — array of buckets, hash spreading, collision chains, **treeify at 8 entries**, resize at load factor 0.75, why the default capacity is 16, why it's unsafe under concurrency
- [ ] **`equals` / `hashCode` contract** — and what breaks if you violate it
- [ ] **ArrayList vs LinkedList** — growth by ~1.5x, why ArrayList wins in practice (cache locality)
- [ ] **String** — immutability, the string pool, `intern()`, why `StringBuilder` exists
- [ ] **Immutability and `final`** — thread safety for free
- [ ] **Checked vs unchecked exceptions**; try-with-resources
- [ ] **Generics and type erasure** — why you can't do `new T[]`
- [ ] **Streams** — lazy evaluation, terminal vs intermediate ops, when parallel streams hurt (shared ForkJoinPool)
- [ ] **ClassLoader hierarchy** — bootstrap → platform → application; delegation model; class loading phases (load, link, initialise)
- [ ] **JIT compilation** — interpreter → C1 → C2, tiered compilation, **inlining**, **escape analysis** (objects that never escape can be stack-allocated), JVM warm-up. Explains why benchmarks need warm-up runs.

## D5. Modern Java awareness (Tier 3 — cheap credibility)

- [ ] Records, sealed classes, pattern matching for switch, text blocks
- [ ] What's in Java 17 vs 21 LTS, and which one you use

---

# SECTION E — Networking, deeper (TIER 1 core, 1.5 hours)

## Tier 1

- [ ] **The packet journey** — application data → socket → TCP segment → IP packet → Ethernet frame → NIC → wire, and the reverse on the way up. Know which layer adds which header.
- [ ] **TCP vs UDP** — and _when_ you'd pick UDP
- [ ] **Three-way handshake**; four-way teardown
- [ ] **Flow control** (receiver window) vs **congestion control** (network) — slow start, AIMD
- [ ] **The URL trace** (Section A, Trace 2) — narrate it in 2 minutes
- [ ] **TLS handshake** — asymmetric crypto authenticates the server via a CA-signed certificate and agrees a shared secret; symmetric crypto then encrypts the data. TLS 1.3 does it in one round trip instead of two.
- [ ] **HTTP/1.1 vs 2 vs 3** — keep-alive and pooling; HTTP/2 multiplexing; **head-of-line blocking** and how HTTP/3 (QUIC over UDP) removes it
- [ ] **Connection refused vs timeout vs connection reset** — three different failures with three different causes (nothing listening / no response or firewall drop / peer sent RST). **Classic interview question and a real debugging skill.**

## Tier 2

- [ ] **TCP state machine** — LISTEN, SYN_SENT, ESTABLISHED, FIN_WAIT, **TIME_WAIT**. Know why TIME_WAIT exists and why thousands of them can exhaust ports on a busy client.
- [ ] **Socket buffers** and the **accept backlog queue**
- [ ] **MAC vs IP**; **ARP**; switches (layer 2) vs routers (layer 3)
- [ ] **Subnetting / CIDR** basics; private IP ranges; **NAT**
- [ ] **DNS internals** — record types (A, AAAA, CNAME, MX, TXT), TTL, recursive vs iterative resolution, why a low TTL matters during failover
- [ ] **L4 vs L7 load balancing**; health checks; sticky sessions
- [ ] **Reverse proxy vs forward proxy vs API gateway**; CDN edge caching
- [ ] **WebSockets vs SSE vs long polling**; **gRPC** over HTTP/2 with protobufs
- [ ] **Idempotent HTTP methods**; status code semantics (when 4xx vs 5xx); REST conventions
- [ ] **Latency vs bandwidth vs throughput**; retries with **exponential backoff and jitter**; why naive retries cause retry storms
- [ ] **Rough latency numbers** — L1 ~1ns, RAM ~100ns, SSD read ~100µs, same-datacentre round trip ~0.5ms, cross-continent ~150ms. Being able to reason with these is a strong signal.

## Tier 3

- [ ] Nagle's algorithm and delayed ACK (and why they interact badly)
- [ ] mTLS, SNI, certificate pinning
- [ ] MTU, fragmentation, path MTU discovery

---

# SECTION F — Databases, deeper (TIER 1 core, 1.5 hours)

## Tier 1

- [ ] **ACID** — and what each letter actually guarantees
- [ ] **Isolation levels** and the anomaly each prevents — Read Uncommitted (dirty read), Read Committed (stops dirty), Repeatable Read (stops non-repeatable), Serializable (stops phantoms)
- [ ] **MVCC** — readers see a snapshot, don't block writers
- [ ] **B+ tree indexes** — why B+ and not a binary tree (high fanout = fewer disk reads; leaves are linked for range scans)
- [ ] **Clustered vs non-clustered**, **covering index**, **composite index left-prefix rule** (an index on (a,b,c) helps queries on a, a+b, a+b+c — not on b alone)
- [ ] **When indexes hurt** — write overhead, storage, low-cardinality columns
- [ ] **EXPLAIN plans**; the **N+1 query problem** and its fix
- [ ] **CAP and PACELC** — "CAP is about partition time; PACELC adds the latency-vs-consistency trade even when healthy"
- [ ] **Optimistic vs pessimistic locking**; **idempotency** for safe retries

## Tier 2

- [ ] **Storage internals** — pages, the **buffer pool**, **write-ahead log (WAL)**, checkpoints, why WAL gives durability without random writes
- [ ] **LSM tree vs B+ tree** — LSM (Cassandra, RocksDB) optimises writes via memtable + SSTable + compaction; B+ tree optimises reads
- [ ] **Join algorithms** — nested loop, hash join, merge join, and when the planner picks each
- [ ] **Query planner** — cost estimation from statistics; why stale statistics cause bad plans
- [ ] **Lock types** — row, gap, table; lock escalation; DB deadlock detection and victim selection
- [ ] **Replication** — sync vs async vs semi-sync; leader-follower vs multi-leader; **replication lag** and read-your-own-writes
- [ ] **Sharding vs partitioning**; shard key choice; **consistent hashing**
- [ ] **Connection pool sizing** — why a bigger pool is often _slower_
- [ ] **2PC vs saga**; compensating transactions
- [ ] **Normalization vs deliberate denormalization**

---

# SECTION G — Distributed systems (TIER 2 · relevant because CREST is distributed)

- [ ] **Consistency models** — strong, eventual, causal, read-your-writes
- [ ] **Quorum** — N/R/W, why R + W > N gives consistency
- [ ] **Consensus** — Raft at a conceptual level: leader election, log replication, why a majority is needed
- [ ] **Exactly-once is a myth** — you get at-least-once delivery plus idempotent processing
- [ ] **Resilience patterns** — retry with backoff + jitter, circuit breaker, bulkhead, timeout budgets, **backpressure**
- [ ] **Dead-letter queues** and poison-message handling
- [ ] **Distributed tracing** — correlation IDs, spans; why you need them
- [ ] **Clock problems** — why you can't trust wall-clock ordering across machines (logical clocks, vector clocks at a concept level)

---

# SECTION H — Rapid-fire self-test (do this LAST, Saturday night)

Answer each aloud in 60–90 seconds. Tick only if fluent. Anything you stumble on goes on tomorrow's 15-minute review list.

**Memory / CPU**

- [ ] How is memory managed inside a CPU? (walk Trace 1)
- [ ] What is virtual memory and why does it exist?
- [ ] What happens on a page fault?
- [ ] Game needs 16GB, machine has 8GB — what happens?
- [ ] Why is a cache line 64 bytes and why does that matter?
- [ ] What is false sharing?
- [ ] Stack vs heap — what goes where and why?

**OS**

- [ ] Process vs thread. What does a context switch actually cost?
- [ ] What is a system call?
- [ ] Four conditions for deadlock, and how to break them.
- [ ] Mutex vs semaphore.
- [ ] What's epoll and why does it scale better than select?
- [ ] A container gets OOM-killed with exit code 137 — what happened and why is there no stack trace?

**Java**

- [ ] Walk me through JVM memory areas.
- [ ] How does GC decide what to collect?
- [ ] Minor GC vs full GC. Why do full GCs hurt?
- [ ] Name three OutOfMemoryError types and their different causes.
- [ ] How would you debug a memory leak in a production Java service?
- [ ] What does `volatile` guarantee — and what does it NOT?
- [ ] Why is `count++` not thread-safe even on a volatile field?
- [ ] How does `ConcurrentHashMap` achieve thread safety?
- [ ] How does HashMap work internally? What happens at 8 entries in a bucket?
- [ ] What are virtual threads and what problem do they solve?
- [ ] What is escape analysis?

**Networking**

- [ ] What happens when you type a URL and press enter? (walk Trace 2)
- [ ] TCP vs UDP — when would you actually choose UDP?
- [ ] Explain the TLS handshake.
- [ ] Connection refused vs timeout vs connection reset — what's different about each?
- [ ] What is head-of-line blocking and how does HTTP/3 fix it?
- [ ] Why does TIME_WAIT exist?
- [ ] L4 vs L7 load balancing.

**Databases**

- [ ] Explain the isolation levels and which anomaly each prevents.
- [ ] Why B+ trees instead of binary trees for indexes?
- [ ] When does an index make things worse?
- [ ] What is the N+1 problem?
- [ ] Walk me through what happens on a single UPDATE + COMMIT. (walk Trace 3)
- [ ] CAP vs PACELC.
- [ ] Optimistic vs pessimistic locking — when each?

**Distributed**

- [ ] Why is exactly-once delivery not really achievable?
- [ ] What is backpressure and why does it matter?
- [ ] A downstream service starts failing — walk me through your defences.

---

# Saturday time plan

|Block|Time|Content|
|---|---|---|
|1|2h|**Section A** — the three traces. Narrate each aloud until smooth.|
|2|1.5h|**Section B** Tier 1 — CPU and memory hierarchy|
|3|1.5h|**Section C** Tier 1 + container/OOM items|
|—|break|—|
|4|2.5h|**Section D** — JVM memory, GC, concurrency (D1–D3). Your highest-leverage section.|
|5|1.5h|**Section E** Tier 1 — networking|
|6|1.5h|**Section F** Tier 1 — databases|
|7|1h|**Section H** — rapid-fire self-test, aloud, timed|

If you run short: **cut Section G entirely, and cut Tier 2 everywhere.** Do not cut Section A or Section D.

---

# The one rule

**Fundamentals stop tonight.** Tomorrow is stories, positioning, and Adobe knowledge — the things that actually decide this round. Carry forward only a 15-minute daily review of whatever you stumbled on in Section H.