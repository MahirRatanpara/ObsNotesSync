# Monotonic Queue

## Why It Matters

The only O(n) way to get the min or max of every sliding window. A heap gives O(n log k); a monotonic deque gives O(n).

## Core Idea

A double-ended queue holding **indices**, kept in decreasing order of value (for a max-queue). The front is always the maximum of the current window.

Three operations per step:
1. **Evict from front** if the front index has slid out of the window
2. **Evict from back** while the back value is ≤ the incoming value (it can never be the max again)
3. **Push** the new index at the back

## Template — Sliding Window Maximum

```java
Deque<Integer> dq = new ArrayDeque<>();   // indices, values decreasing
int[] res = new int[n - k + 1];
for (int i = 0; i < n; i++) {
    if (!dq.isEmpty() && dq.peekFirst() <= i - k) dq.pollFirst();   // out of window
    while (!dq.isEmpty() && arr[dq.peekLast()] <= arr[i]) dq.pollLast();
    dq.offerLast(i);
    if (i >= k - 1) res[i - k + 1] = arr[dq.peekFirst()];
}
```

**Why can we discard smaller elements at the back?** If `arr[j] <= arr[i]` and `j < i`, then `j` leaves the window no later than `i` and is never larger. It can never be the answer for any future window. Safe to drop permanently.

## Monotonic Queue vs Heap vs Monotonic Stack

| | Monotonic Deque | Heap | Monotonic Stack |
|---|---|---|---|
| Sliding window max | O(n) | O(n log k) | Not applicable |
| Supports arbitrary removal | Front/back only | Lazy deletion needed | LIFO only |
| Use for | Window extremes | Top-K, streaming median | Next greater/smaller |

## Key Problems

| Problem | Note |
|---|---|
| Sliding Window Maximum | Canonical |
| Shortest Subarray with Sum at Least K | Deque over prefix sums; handles negatives |
| Constrained Subsequence Sum | DP + max-deque over a window |
| Jump Game VI | DP + max-deque |
| Longest Continuous Subarray with Abs Diff ≤ Limit | Two deques (min and max) |

## Advantages

- True O(n) — each index enters and leaves the deque once
- O(k) space

## Limitations

- Only gives window extremes, not arbitrary order statistics (no "kth largest in window" — use two heaps or an ordered multiset)
- Requires a fixed or monotonically advancing window

## Common Mistakes

- Storing values instead of indices, making front-eviction impossible
- Using `<` instead of `<=` when popping the back, which keeps stale duplicates
- Forgetting the front-eviction step, letting expired indices stay
- Writing the result before the window is full (`i >= k - 1` guard)

## Related Topics

- [Monotonic Stack](Monotonic%20Stack.md)
- [Sliding Window](../Two%20Pointers%20and%20Sliding%20Window/Sliding%20Window.md)
- [Heaps and Priority Queues](../Heaps/Heaps%20and%20Priority%20Queues.md)

## Revision Summary

Deque of indices, values decreasing, front is the window max. Evict expired from front, evict dominated from back, push. O(n).

## Quick Recall

- Front = answer, back = insertion point
- Pop back while `arr[back] <= arr[new]`
- Pop front while `front <= i - k`
- Two deques (min + max) for "abs diff ≤ limit"
