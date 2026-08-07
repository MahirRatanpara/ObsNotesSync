# Java IO and NIO

## Why It Matters

Streaming large files without exhausting memory, choosing blocking versus non-blocking, and knowing why Netty and Kafka are fast all come from here.

## java.io — Decorator Streams

The classic API, and the textbook example of the [Decorator pattern](../../03%20Low%20Level%20Design/Design%20Patterns/Structural/Decorator.md).

```java
try (var in = new BufferedReader(
                new InputStreamReader(
                  new FileInputStream(path), StandardCharsets.UTF_8))) {
    return in.lines().toList();
}
```

Each layer adds one capability:

| Layer | Adds |
|---|---|
| `FileInputStream` | Raw bytes from a file |
| `InputStreamReader` | **Bytes → characters**, with an encoding |
| `BufferedReader` | **Buffering** plus `readLine`/`lines` |

**Byte streams vs character streams:**

| | Byte | Character |
|---|---|---|
| Base classes | `InputStream` / `OutputStream` | `Reader` / `Writer` |
| For | Binary — images, protocols | **Text** |
| Bridge | `InputStreamReader` / `OutputStreamWriter` | — |

**Always specify the charset.** `new InputStreamReader(in)` uses the platform default, which differs between your laptop and the server. Java 18+ defaults file encoding to UTF-8, which removed a long-standing class of bugs — but being explicit is still correct.

**Buffering matters enormously.** An unbuffered `FileInputStream.read()` is one syscall per byte. Wrapping in `BufferedInputStream` reads 8 KB at a time — often a 100× difference. **Every syscall is a user-to-kernel mode switch**; see [Processes and Threads](../../10%20Operating%20Systems/Processes%20and%20Threads/Processes%20and%20Threads.md).

## The Modern File API

`java.nio.file` (Java 7+) replaces `java.io.File`, which had genuinely bad error reporting — `delete()` returned `false` with no reason.

```java
Path path = Path.of("data", "input.txt");

Files.readString(path);                       // whole file — small files only
Files.readAllLines(path);
Files.writeString(path, content);
Files.exists(path);
Files.size(path);
Files.copy(src, dst, REPLACE_EXISTING);
Files.createDirectories(path);
Files.delete(path);                           // THROWS with a reason on failure
```

**Streaming large files — the important pattern:**

```java
try (Stream<String> lines = Files.lines(path, UTF_8)) {   // MUST close
    lines.filter(l -> l.contains("ERROR"))
         .forEach(System.out::println);
}
```

**`Files.lines` returns a stream backed by an open file handle**, so it must be closed — hence try-with-resources. This is one of the few streams that holds a resource.

**Constant memory regardless of file size.** `Files.readAllLines` on a 10 GB file is an `OutOfMemoryError`; `Files.lines` handles it fine.

**Walking a tree:**
```java
try (Stream<Path> paths = Files.walk(root)) {
    paths.filter(Files::isRegularFile).forEach(this::process);
}
```

## NIO — Buffers and Channels

A different model: **channels** move data, **buffers** hold it.

```java
try (FileChannel ch = FileChannel.open(path, READ)) {
    ByteBuffer buf = ByteBuffer.allocate(8192);
    while (ch.read(buf) > 0) {
        buf.flip();                      // switch from writing to reading
        process(buf);
        buf.clear();                     // prepare for the next write
    }
}
```

### Buffer state — the part people get wrong

A buffer has three markers: **position**, **limit**, **capacity**.

| Method | Effect |
|---|---|
| **`flip()`** | limit = position; position = 0 → **switch from filling to draining** |
| `clear()` | position = 0; limit = capacity → **prepare to fill again** (doesn't erase data) |
| `rewind()` | position = 0, limit unchanged → re-read |
| `compact()` | Move unread bytes to the front → **partial drain then continue filling** |

**Forgetting `flip()` is the classic NIO bug** — you read from position 0 to the current position, which is empty, so you get nothing.

**`clear()` does not clear the data**, only the markers. The old bytes are still there until overwritten.

### Direct vs heap buffers

| | Heap (`allocate`) | **Direct (`allocateDirect`)** |
|---|---|---|
| Lives | On the Java heap | **Off-heap, native memory** |
| Copy on I/O | **Extra copy** to a native buffer | **None — I/O reads/writes it directly** |
| Allocation cost | Cheap | **Expensive** |
| Freed by | GC | **A `Cleaner`, non-deterministically** |

**Use direct buffers for long-lived, frequently-reused I/O buffers.** Allocating one per request is worse than a heap buffer, because allocation is expensive and reclamation is non-deterministic.

**Direct buffer memory is outside `-Xmx`** and counts toward the container limit — a real cause of `OOMKilled` with a heap that looks healthy. Cap it with `-XX:MaxDirectMemorySize`.

## Blocking vs Non-Blocking

| | Blocking (`java.io`) | Non-blocking (NIO selectors) |
|---|---|---|
| Thread per connection | **Yes** | **No** |
| Ceiling | ~10K connections (1 MB stack each) | **100K+** |
| Code | Simple, sequential | Event-driven, harder |
| Best for | Few connections, simple servers | Many mostly-idle connections |

```java
Selector selector = Selector.open();
channel.configureBlocking(false);
channel.register(selector, SelectionKey.OP_READ);

while (true) {
    selector.select();                          // blocks until a channel is ready
    for (SelectionKey key : selector.selectedKeys()) {
        if (key.isReadable()) read(key);
    }
}
```

**One thread serves thousands of connections** by only touching those that are ready. Backed by `epoll` on Linux and `kqueue` on BSD.

**Nobody writes raw selector code.** Use **Netty**, which handles the platform differences, buffer pooling, and the many subtle bugs.

**Virtual threads (Java 21+) largely remove the need for this model.** Blocking a virtual thread unmounts it rather than an OS thread, so thread-per-connection scales to millions with ordinary blocking code. **For most new servers, virtual threads plus blocking I/O beats hand-written NIO** — see [Virtual Threads and Structured Concurrency](../Concurrency/Virtual%20Threads%20and%20Structured%20Concurrency.md).

## Zero-Copy

A normal file-to-socket send copies data four times: disk → kernel buffer → user buffer → socket buffer → NIC.

```java
FileChannel.transferTo(position, count, socketChannel);
```

**`transferTo` / `transferFrom` keep the data in kernel space** (`sendfile` on Linux), eliminating the user-space round trip.

**This is a large part of why Kafka is fast** — it sends log segments straight from page cache to socket, never materialising them in the JVM heap. Naming it is a strong answer to "why is Kafka fast?", alongside sequential I/O and batching.

## Memory-Mapped Files

```java
MappedByteBuffer buf = channel.map(READ_WRITE, 0, size);
buf.putInt(42);                       // writes to the file via a memory write
```

Maps a file region into the address space; reads trigger page faults that load data on demand.

| Advantage | Detail |
|---|---|
| **No read/write syscalls** | Access is ordinary memory access |
| **Zero copy** | No user-space buffer |
| Lazy | Only touched pages are loaded |
| **Shared** | Multiple processes map the same pages once |

**Downsides:** unpredictable fault latency, flushing is at the kernel's discretion unless you `force()`, and unmapping is non-deterministic — a mapped file may stay locked on Windows long after you're done.

**Used by** Kafka (index files), Lucene, RocksDB, and the JVM for class files.

## Choosing

| Need | Use |
|---|---|
| Read a small text file | `Files.readString` |
| **Process a huge file** | **`Files.lines` in try-with-resources** |
| Binary file | `FileChannel` + `ByteBuffer` |
| Copy a file | `Files.copy` |
| **Serve a file over a socket** | **`transferTo` (zero-copy)** |
| Random access to a large file | Memory-mapped |
| Thousands of connections | **Virtual threads**, or Netty |
| Walk a directory tree | `Files.walk` |

## Common Mistakes

- No charset specified
- Unbuffered streams — one syscall per byte
- `Files.readAllLines` on a large file
- Not closing `Files.lines` / `Files.walk`
- **Forgetting `flip()`**
- Allocating direct buffers per request
- Ignoring direct memory in container sizing
- Hand-writing selector code instead of using Netty or virtual threads
- Using `java.io.File` instead of `Path`

## Related Topics

- [Serialization](Serialization.md)
- [Virtual Threads and Structured Concurrency](../Concurrency/Virtual%20Threads%20and%20Structured%20Concurrency.md)
- [Memory Management](../../10%20Operating%20Systems/Memory/Memory%20Management.md)
- [Kafka Deep Dive](../../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md)

## Revision Summary

`java.io` composes decorator streams and must be buffered and given an explicit charset. `java.nio.file` replaces `File`, and `Files.lines` streams huge files in constant memory but holds a file handle. NIO buffers need `flip()` between filling and draining; direct buffers avoid a copy but live off-heap. Zero-copy `transferTo` is why Kafka is fast, and virtual threads have largely displaced selector-based servers.

## Quick Recall

- `java.io` = **Decorator**; always buffer, always specify the charset
- **`Files.lines` streams in constant memory — must be closed**
- **`flip()` between writing and reading a buffer**; `clear()` resets markers, not data
- **Direct buffers: no copy, off-heap, expensive to allocate**, outside `-Xmx`
- `transferTo` = **zero-copy** = part of why Kafka is fast
- Memory-mapped files for random access to large files
- Selectors scale to 100K+, but **virtual threads make blocking code scale too**
- Use `Path`, not `File` — real error messages
