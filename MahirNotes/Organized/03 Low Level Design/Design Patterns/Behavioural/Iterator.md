# Iterator

## Why It Matters

Built into the language, so it's easy to overlook — but interviewers use it to probe fail-fast semantics, custom collection design, and lazy evaluation.

## Core Idea

Provide sequential access to a collection's elements without exposing its internal representation. The client traverses without knowing whether it's an array, a tree, or a database cursor.

```java
interface Iterator<T> {
    boolean hasNext();
    T next();
    default void remove() { throw new UnsupportedOperationException(); }
}
```

## Custom Iterator

```java
class Playlist implements Iterable<Song> {
    private final List<Song> songs;

    public Iterator<Song> iterator() {
        return new Iterator<>() {
            private int index = 0;
            public boolean hasNext() { return index < songs.size(); }
            public Song next() {
                if (!hasNext()) throw new NoSuchElementException();   // required by contract
                return songs.get(index++);
            }
        };
    }
}

for (Song s : playlist) { ... }   // implementing Iterable enables for-each
```

**`next()` must throw `NoSuchElementException` when exhausted** — that's the contract, and omitting it is a common slip.

**Implementing `Iterable` (not just `Iterator`) is what enables the for-each loop.**

## Fail-Fast vs Fail-Safe

| | Fail-fast | Fail-safe |
|---|---|---|
| On structural modification | Throws `ConcurrentModificationException` | Continues |
| Iterates | The live collection | A **snapshot** |
| Examples | `ArrayList`, `HashMap` | `CopyOnWriteArrayList`, `ConcurrentHashMap` |
| Sees concurrent changes | N/A (throws) | No — snapshot may be stale |

**How fail-fast works:** the collection keeps a `modCount`; the iterator records it at creation and compares on every `next()`. A mismatch throws.

**It's a best-effort bug detector, not a guarantee** — the check isn't synchronised, so it can miss violations. Never write logic that depends on catching `ConcurrentModificationException`.

```java
for (String s : list) if (s.isEmpty()) list.remove(s);   // throws

list.removeIf(String::isEmpty);                           // correct
Iterator<String> it = list.iterator();                    // also correct
while (it.hasNext()) if (it.next().isEmpty()) it.remove();
```

**`Iterator.remove()` is the only safe way to remove during iteration** — it updates `modCount` and the expected value together.

## Internal vs External Iterators

| | External (`Iterator`) | Internal (`forEach`, Streams) |
|---|---|---|
| Controls iteration | **The client** | The collection |
| Can stop early | Easily | Needs `findFirst`/`anyMatch`/short-circuit |
| Parallelisable | No | **Yes** (`parallelStream`) |
| Style | Imperative | Declarative |

Java 8 Streams are internal iteration, which is what allows the library to reorder, fuse, and parallelise operations. `Spliterator` is the underlying abstraction supporting parallel splitting.

## Lazy and Infinite Iteration

Iterators need not be backed by an in-memory collection:

```java
Iterator<Integer> naturals = new Iterator<>() {
    private int n = 0;
    public boolean hasNext() { return true; }     // infinite
    public Integer next() { return n++; }
};
```

This is how database cursors, file line readers, and `Stream.iterate` work — elements are produced on demand, so memory stays constant regardless of size. **Streaming a 10 GB file line by line is this pattern.**

## Real Uses

- Every `java.util` collection
- `Scanner`, `BufferedReader.lines()`
- JDBC `ResultSet` — a cursor over rows
- Tree and graph traversals exposed as iterators
- Paginated API clients that fetch the next page transparently

## When To Write A Custom One

- Traversing a custom data structure
- Multiple traversal orders (in-order, level-order) over the same structure
- Lazy or infinite sequences
- Hiding an expensive backing source (network, disk) behind a simple interface

## Limitations

- Single-pass — you cannot rewind
- Overkill for a simple array
- Concurrent modification requires care
- Stateful, so an iterator is not thread-safe

## Common Questions

- *Fail-fast vs fail-safe?* — throws on modification vs iterates a snapshot.
- *How does fail-fast work?* — `modCount` comparison; best-effort only.
- *How do you remove safely during iteration?* — `Iterator.remove()` or `removeIf`.
- *Internal vs external iteration?* — who drives the loop; internal enables parallelism.
- *How do you iterate something infinite?* — generate lazily in `next()`.

## Common Mistakes

- Removing from the collection inside a for-each
- Not throwing `NoSuchElementException` on exhaustion
- Implementing `Iterator` but not `Iterable`, losing for-each
- Sharing one iterator across threads
- Depending on `ConcurrentModificationException` for control flow

## Related Topics

- [Composite](../Structural/Composite.md)
- [Collections Overview](../../../02%20Java/Collections/Collections%20Overview.md)
- [Concurrent Collections](../../../02%20Java/Concurrency/Concurrent%20Collections.md)

## Revision Summary

Sequential access without exposing internals. Implement `Iterable` for for-each. Fail-fast iterators use `modCount` as a best-effort bug detector; use `Iterator.remove()` or `removeIf` to mutate safely. Lazy iterators handle infinite and out-of-memory sources.

## Quick Recall

- Implement `Iterable`, not just `Iterator`
- `next()` throws `NoSuchElementException` when exhausted
- Fail-fast = `modCount`; fail-safe = snapshot
- Only `Iterator.remove()` is safe mid-iteration
- Lazy iterators enable infinite and streaming sources
