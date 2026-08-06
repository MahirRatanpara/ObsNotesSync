# LRU Cache

## Why It Matters

Asked directly at almost every company, and it doubles as a design question — the follow-ups go into thread safety and distributed caching.

## Requirements

`get` and `put` both in **O(1)**, evicting the least recently used entry when at capacity.

## The Structure

**Hash map + doubly linked list.** Each alone is insufficient:

| Structure | Gives | Missing |
|---|---|---|
| Hash map | O(1) lookup | No ordering |
| Doubly linked list | O(1) move/remove **given a node** | O(n) to find a node |
| **Both** | O(1) lookup **and** O(1) reorder | — |

The map stores `key → node`, so you can jump straight to a node and splice it in O(1).

**Why doubly linked?** Removing a node requires updating its predecessor. With a singly linked list you'd need an O(n) scan to find it.

## Implementation

```java
class LRUCache {
    private static class Node {
        int key, value; Node prev, next;
        Node(int k, int v) { key = k; value = v; }
    }

    private final Map<Integer, Node> map = new HashMap<>();
    private final Node head = new Node(0, 0), tail = new Node(0, 0);   // sentinels
    private final int capacity;

    LRUCache(int capacity) {
        this.capacity = capacity;
        head.next = tail; tail.prev = head;
    }

    public int get(int key) {
        Node n = map.get(key);
        if (n == null) return -1;
        moveToFront(n);                       // mark as recently used
        return n.value;
    }

    public void put(int key, int value) {
        Node n = map.get(key);
        if (n != null) { n.value = value; moveToFront(n); return; }

        if (map.size() == capacity) {
            Node lru = tail.prev;             // least recently used
            remove(lru);
            map.remove(lru.key);              // MUST remove from the map too
        }
        Node fresh = new Node(key, value);
        map.put(key, fresh);
        addFirst(fresh);
    }

    private void remove(Node n)      { n.prev.next = n.next; n.next.prev = n.prev; }
    private void addFirst(Node n)    { n.next = head.next; n.prev = head;
                                       head.next.prev = n; head.next = n; }
    private void moveToFront(Node n) { remove(n); addFirst(n); }
}
```

**Two details interviewers check:**

1. **Sentinel head and tail nodes** eliminate every null check in `remove` and `addFirst`. Without them the code is twice as long and buggy.
2. **The evicted node must be removed from the map**, not just the list. Forgetting this is the classic bug — the map grows unbounded and `get` returns a detached node.

**Storing the key inside the node** is what makes map removal possible during eviction — you need `lru.key` to know which map entry to delete.

## The Five-Line Java Version

```java
new LinkedHashMap<Integer, Integer>(capacity, 0.75f, true) {   // true = ACCESS order
    protected boolean removeEldestEntry(Map.Entry<Integer, Integer> eldest) {
        return size() > capacity;
    }
};
```

`LinkedHashMap` already maintains a doubly linked list over its entries. The third constructor argument switches from insertion order to **access order**, and `removeEldestEntry` is the eviction hook.

**Mention this, then implement the manual version.** Knowing the library shortcut shows Java depth; interviewers almost always want the hand-rolled version to see the data-structure reasoning.

## LFU — The Harder Variant

Least *Frequently* Used needs an extra layer: `freq → doubly linked list of nodes at that frequency`, plus a `minFreq` pointer.

- `get` increments the frequency and moves the node to the next frequency's list
- Eviction removes the tail of the `minFreq` list
- Ties broken by recency, since each frequency bucket is itself an LRU list

Still O(1), but noticeably more state. **Frequency-only LFU also ossifies** — an item popular last year never gets evicted. Real implementations use ageing or a windowed variant (TinyLFU).

## Follow-Ups

| Question | Answer |
|---|---|
| **Make it thread-safe** | A single lock is simplest but serialises everything. Better: segment the cache (lock striping) as `ConcurrentHashMap` does, or use `Caffeine`, which buffers reads and applies reordering asynchronously to avoid contention. |
| **Add TTL** | Store an expiry timestamp per node; treat expired entries as misses on read (lazy expiry) and optionally sweep in the background. |
| **Distributed LRU** | Redis with `maxmemory-policy allkeys-lru`. Note Redis LRU is **approximate** — it samples keys rather than maintaining a global list, trading precision for speed. |
| **Why not a TreeMap by timestamp?** | O(log n) instead of O(1), and timestamps collide. |

**The thread-safety follow-up is where senior candidates separate themselves** — naming lock striping and Caffeine's asynchronous reordering is a strong answer.

## Common Mistakes

- Singly linked list → O(n) removal
- Forgetting to remove the evicted key from the map
- No sentinel nodes, leading to null-pointer bugs at the boundaries
- Not moving the node on `get` (only on `put`)
- Not storing the key in the node, making eviction impossible
- Using `LinkedHashMap` without being able to explain the manual version

## Related Topics

- [Collections Overview](../../02%20Java/Collections/Collections%20Overview.md)
- [HashMap Internals](../../02%20Java/Collections/HashMap%20Internals.md)
- [Caching](../../04%20High%20Level%20Design/Core%20Concepts/Caching.md)
- [Redis](../../04%20High%20Level%20Design/Key%20Technologies/Redis.md)

## Revision Summary

Hash map for O(1) lookup plus a doubly linked list for O(1) reordering, with sentinel nodes and the key stored in each node so eviction can clean the map. `LinkedHashMap` in access-order mode is the library equivalent.

## Quick Recall

- Map → node; doubly linked list → recency order
- Sentinel head and tail remove all null checks
- Store the key in the node for eviction
- Remove from **both** map and list
- `new LinkedHashMap<>(cap, 0.75f, true)` + `removeEldestEntry`
- Thread-safe → lock striping or Caffeine
