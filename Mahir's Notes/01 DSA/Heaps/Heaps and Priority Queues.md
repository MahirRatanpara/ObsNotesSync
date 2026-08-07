# Heaps and Priority Queues

## Why It Matters

The answer to every "top K", "kth largest", "merge k sorted", and "streaming median" question.

## Core Idea

A binary heap gives O(1) access to the extreme element and O(log n) insert/remove. It does **not** give sorted order or arbitrary search — that's the trade you're making versus a balanced BST.

| Operation | Cost |
|---|---|
| peek | O(1) |
| offer | O(log n) |
| poll | O(log n) |
| heapify an array | O(n) |
| search arbitrary | O(n) |

## The Counter-Intuitive Rule for Top K

**To find the K largest, use a MIN heap of size K.**

The heap holds the current best K. The smallest of those sits at the top, so it's the cheapest to evict when a better candidate arrives.

```java
PriorityQueue<Integer> minHeap = new PriorityQueue<>();
for (int x : nums) {
    minHeap.offer(x);
    if (minHeap.size() > k) minHeap.poll();   // drop the smallest
}
return minHeap.peek();                        // kth largest
```

O(n log k) time, O(k) space — better than sorting when k ≪ n.

Symmetrically: **K smallest → MAX heap of size K.**

## Two Heaps — Streaming Median

Max-heap for the lower half, min-heap for the upper half. Keep sizes balanced within one.

```java
PriorityQueue<Integer> lo = new PriorityQueue<>(Comparator.reverseOrder());  // max
PriorityQueue<Integer> hi = new PriorityQueue<>();                           // min

void add(int num) {
    lo.offer(num);
    hi.offer(lo.poll());                 // funnel through to keep order
    if (hi.size() > lo.size()) lo.offer(hi.poll());
}
double median() {
    return lo.size() > hi.size() ? lo.peek() : (lo.peek() + hi.peek()) / 2.0;
}
```

The push-then-pull step guarantees every element in `lo` is ≤ every element in `hi` without extra comparisons.

## Merge K Sorted Lists

```java
PriorityQueue<ListNode> pq = new PriorityQueue<>((a, b) -> a.val - b.val);
for (ListNode l : lists) if (l != null) pq.offer(l);
ListNode dummy = new ListNode(0), tail = dummy;
while (!pq.isEmpty()) {
    ListNode n = pq.poll();
    tail.next = n; tail = n;
    if (n.next != null) pq.offer(n.next);
}
```

O(N log k) where N is total nodes and k is the number of lists.

## Lazy Deletion

`PriorityQueue.remove(Object)` is O(n). When you need to invalidate entries, don't remove — mark them stale and skip them on poll:

```java
while (!pq.isEmpty() && isStale(pq.peek())) pq.poll();
```

Used in task schedulers and "Sliding Window Median" style problems.

## Heap vs Quickselect vs TreeMap

| | Heap | Quickselect | TreeMap |
|---|---|---|---|
| Kth largest | O(n log k) | O(n) avg | O(n log n) |
| Streaming | Yes | No | Yes |
| Ordered iteration | No | No | Yes |
| Arbitrary delete | O(n) | No | O(log n) |
| Duplicates | Yes | Yes | Needs count map |

Use **TreeMap as an ordered multiset** when you need both order statistics *and* arbitrary removal.

## Key Problems

| Problem | Technique |
|---|---|
| Kth Largest Element | Min heap size k, or quickselect |
| Top K Frequent Elements | Count map + heap, or bucket sort O(n) |
| Merge K Sorted Lists | Heap of list heads |
| Find Median from Data Stream | Two heaps |
| Task Scheduler | Max heap + cooldown queue |
| Meeting Rooms II | Min heap of end times |
| K Closest Points to Origin | Max heap size k |
| Reorganize String | Max heap by frequency |

## Common Mistakes

- Using a max heap for "K largest" — it's a min heap
- Forgetting Java's `PriorityQueue` is a **min** heap by default
- `a.val - b.val` comparators overflowing on extreme ints — use `Integer.compare`
- Assuming iteration order is sorted (it isn't)
- Calling `remove(Object)` in a loop, silently making the solution O(n²)

## Related Topics

- [Quickselect](Quickselect.md)
- [Monotonic Queue](Monotonic%20Queue.md)
- [Intervals](Intervals.md)

## Revision Summary

Min heap of size K for K largest. Two heaps for streaming median. Lazy deletion instead of `remove`. Consider quickselect for a one-shot kth element and TreeMap when you need ordered access plus deletion.

## Quick Recall

- K largest → MIN heap size k
- K smallest → MAX heap size k
- Java `PriorityQueue` is min by default
- Median → max-heap(lower) + min-heap(upper)
- Never `remove(Object)` in a loop — mark stale
