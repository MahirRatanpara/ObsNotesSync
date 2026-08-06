# DSA Flash Cards

> Cover the answer column. Say the answer out loud before revealing it.

## Pattern Recognition

| Prompt | Answer |
|---|---|
| n ≤ 20 in constraints | Bitmask DP or backtracking — exponential is intended |
| n ≤ 10⁵ | O(n log n) — sort, heap, or binary search |
| "contiguous subarray" | Sliding window or prefix sum |
| "subsequence" | DP |
| "minimize the maximum" | Binary search on answer |
| "kth largest" | Min heap of size k, or quickselect |
| "next greater element" | Monotonic stack (decreasing) |
| "shortest path", unweighted | BFS |
| "shortest path", weighted non-negative | Dijkstra |
| "shortest path", negative edges | Bellman–Ford |
| "prerequisites" / "build order" | Topological sort |
| "connected components", edges arrive over time | Union-Find |
| "all combinations" | Backtracking |
| "prefix" / "autocomplete" | Trie |
| Range query **with updates** | Fenwick (sums) or segment tree (min/max) |
| Cycle in a linked list | Fast and slow pointers |

## Complexity

| Prompt | Answer |
|---|---|
| Dijkstra with a binary heap | O((V + E) log V) |
| Bellman–Ford | O(V·E) |
| Floyd–Warshall | O(V³) |
| Union-Find with path compression + union by rank | O(α(n)), effectively O(1) |
| Building a heap from an array | O(n), not O(n log n) |
| Trie insert/search | O(L), independent of dictionary size |
| Quickselect average / worst | O(n) / O(n²) |
| Why is a monotonic stack O(n) despite the inner while? | Each element is pushed and popped at most once — amortised |

## Templates

| Prompt | Answer |
|---|---|
| Binary search loop condition and update | `while (lo < hi)`, `hi = mid`, `lo = mid + 1`, return `lo` |
| Overflow-safe midpoint | `lo + (hi - lo) / 2` |
| Sliding window shape | Expand `right`; `while (invalid) left++`; record |
| Where to record the answer for a **minimum** window | Inside the shrink loop |
| exactly(k) subarrays formula | `atMost(k) − atMost(k−1)` |
| 0/1 knapsack inner loop direction | **Backward** |
| Unbounded knapsack inner loop direction | Forward |
| Coin Change **combinations** loop order | Coin loop **outside** |
| Coin Change **permutations** loop order | Amount loop outside |
| Prefix-sum-counting map seed | `map.put(0, 1)` |
| Backtracking three steps | Choose, explore, un-choose |
| What must you copy in backtracking? | The path — `new ArrayList<>(path)` |
| Union-Find cycle detection | `union` returns false |
| Topological sort cycle detection | `order.size() < n` |
| BFS: when to mark visited | On **enqueue** |
| Histogram rectangle width when popping index j | `i - stack.peek() - 1` |

## Traps

| Prompt | Answer |
|---|---|
| Greedy counterexample to memorise | `coins = [1,3,4]`, amount 6 → greedy 3 coins, optimal 2 |
| Why do you sort by **end** time for activity selection? | Finishing earliest leaves the most room for the rest |
| Container With Most Water: which pointer moves? | The shorter line — area is bounded by it |
| K largest → which heap? | **Min** heap of size k |
| Java's `PriorityQueue` default order | Min heap |
| Why is `(a, b) -> a - b` a bad comparator? | Integer overflow — use `Integer.compare` |
| Java `>>` vs `>>>` on negatives | `>>` sign-extends and can loop forever; use `>>>` |
| BST validation: compare against what? | A `(min, max)` **range**, not the parent |
| 3Sum duplicate skip condition | `i > start && nums[i] == nums[i-1]` |
| Fenwick tree cannot do which operations? | Min, max, GCD — not invertible |

## Data Structure Choice

| Prompt | Answer |
|---|---|
| Stack in Java | `ArrayDeque` — never `Stack` |
| Queue in Java | `ArrayDeque` — never `LinkedList` |
| Need floor/ceiling/range queries | `TreeMap` |
| Ordered multiset with deletion | `TreeMap<value, count>` |
| Window min **and** max | Two monotonic deques |
| Streaming median | Two heaps — max for lower half, min for upper |
| O(1) get and O(1) LRU eviction | Hash map + doubly linked list |

## Related

- [DSA Cheat Sheet](../Cheat%20Sheets/DSA%20Cheat%20Sheet.md)
- [Pattern Recognition Framework](../01%20DSA/Foundations/Pattern%20Recognition%20Framework.md)
- [Pattern Confusion Matrix](../01%20DSA/Foundations/Pattern%20Confusion%20Matrix.md)
