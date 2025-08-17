
**CopyOnWriteArrayList** is a thread-safe variant of ArrayList in Java that's part of the `java.util.concurrent` package. It implements a copy-on-write strategy to achieve thread safety without using locks for read operations.

## How it Works

The core concept is in the name: whenever the list is modified (write operation), the entire underlying array is copied to a new array with the changes applied. The original array remains unchanged until all existing readers are done with it.

Here's the basic mechanism:

- **Read operations** (get, size, iterator) access the current array snapshot directly - no synchronization needed
- **Write operations** (add, remove, set) create a completely new array copy with modifications, then atomically replace the reference to point to the new array

## Key Characteristics

**Thread Safety**: Multiple threads can read concurrently without any synchronization overhead. Write operations are synchronized with each other but don't block readers.

**Memory Overhead**: Each modification creates a new array copy, so memory usage can be significant with frequent writes or large lists.

**Performance Trade-offs**:

- Excellent for read-heavy workloads (O(1) reads with no contention)
- Poor for write-heavy scenarios (O(n) for each write due to array copying)

**Iterator Behavior**: Iterators work on a snapshot of the array from when the iterator was created. They won't reflect changes made after creation and never throw `ConcurrentModificationException`.

## When to Use

CopyOnWriteArrayList is ideal when:

- Reads vastly outnumber writes
- You need thread-safe iteration without external synchronization
- List size remains relatively small
- You can tolerate slightly stale data during iteration

Common use cases include observer/listener lists, configuration settings, or caches where updates are infrequent but reads are frequent.

## Simple Example

```java
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
list.add("item1");
list.add("item2");

// Multiple threads can read safely
String first = list.get(0); // No synchronization needed

// Iterator sees snapshot from creation time
Iterator<String> iter = list.iterator();
list.add("item3"); // This won't appear in the iterator
```

The key insight is that CopyOnWriteArrayList trades write performance and memory efficiency for excellent concurrent read performance and simplified thread safety.