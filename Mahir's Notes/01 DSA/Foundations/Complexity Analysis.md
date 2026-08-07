# Complexity Analysis

## Why It Matters

Every interviewer asks "what's the complexity?" Getting it wrong after a correct solution still costs you. Getting it right *before* you code steers you to the correct pattern.

## Core Idea

Complexity is about growth rate as input grows, ignoring constants. But in interviews you must also reason about *which* n — many problems have several input dimensions (nodes vs edges, rows vs columns, items vs capacity).

## Complexity Ladder

| Class | Name | Example |
|---|---|---|
| O(1) | Constant | Hash lookup, array index |
| O(log n) | Logarithmic | Binary search, balanced tree op |
| O(n) | Linear | Single scan, hash-map pass |
| O(n log n) | Linearithmic | Sorting, heap of n elements |
| O(n²) | Quadratic | Nested loops, 2D DP |
| O(2ⁿ) | Exponential | Subset generation |
| O(n!) | Factorial | Permutations |

## Common Structures

| Structure | Access | Search | Insert | Delete | Space |
|---|---|---|---|---|---|
| Array | O(1) | O(n) | O(n) | O(n) | O(n) |
| Sorted array | O(1) | O(log n) | O(n) | O(n) | O(n) |
| Linked list | O(n) | O(n) | O(1)* | O(1)* | O(n) |
| Hash map | — | O(1) avg | O(1) avg | O(1) avg | O(n) |
| Binary heap | O(1) peek | O(n) | O(log n) | O(log n) | O(n) |
| Balanced BST | O(log n) | O(log n) | O(log n) | O(log n) | O(n) |
| Trie | — | O(L) | O(L) | O(L) | O(A·N·L) |
| Union-Find | — | O(α(n)) | O(α(n)) | — | O(n) |

\* given a reference to the node. α is the inverse Ackermann function — effectively constant.

## Graph Complexities

| Algorithm | Time | Space |
|---|---|---|
| BFS / DFS | O(V + E) | O(V) |
| Dijkstra (binary heap) | O((V + E) log V) | O(V) |
| Bellman–Ford | O(V·E) | O(V) |
| Floyd–Warshall | O(V³) | O(V²) |
| Topological sort | O(V + E) | O(V) |
| Kruskal | O(E log E) | O(V) |
| Prim (heap) | O(E log V) | O(V) |

## Amortised Analysis

Some operations are occasionally expensive but cheap on average.

- **Dynamic array append:** O(1) amortised. Doubling costs O(n) but happens every n appends.
- **Union-Find with path compression + union by rank:** O(α(n)) amortised, effectively O(1).
- **Monotonic stack:** each element is pushed and popped at most once → O(n) total despite the inner while loop.

**Interview move:** when an inner `while` loop makes a solution *look* O(n²), say explicitly: "each element enters and leaves the stack once, so this is O(n) amortised, not O(n²)."

## Recursion and Space

Recursion costs stack space equal to maximum depth.

- Balanced tree DFS: O(log n) stack
- Skewed tree / linked-list DFS: O(n) stack — mention this as a risk
- Iterative conversion trades stack space for explicit heap-allocated structure

## Master Theorem (Quick Form)

For `T(n) = a·T(n/b) + O(n^d)`:

| Condition | Result |
|---|---|
| d > log_b(a) | O(n^d) |
| d = log_b(a) | O(n^d log n) |
| d < log_b(a) | O(n^(log_b a)) |

Merge sort: a=2, b=2, d=1 → d = log₂2 → O(n log n).
Binary search: a=1, b=2, d=0 → d = log₂1 = 0 → O(log n).

## Common Mistakes

- Reporting O(n) for a solution that calls `list.remove()` or `arr.contains()` inside a loop — those are O(n) themselves.
- Forgetting recursion stack space when asked for space complexity.
- Saying "O(n²)" for monotonic stack / two-pointer solutions that are actually amortised O(n).
- Confusing O(V + E) with O(V²) — they differ enormously for sparse graphs.
- Ignoring the cost of sorting inside an otherwise O(n) solution.

## Related Topics

- [Pattern Recognition Framework](Pattern%20Recognition%20Framework.md)
- [Sorting Algorithms](Sorting%20Algorithms.md)

## Revision Summary

Know the ladder, the structure table, the graph table, and be ready to defend amortised claims. State complexity *before* coding to justify your pattern choice.

## Quick Recall

- Hash map O(1) average, O(n) worst (collisions)
- Dijkstra O((V+E) log V); Bellman–Ford O(VE)
- Monotonic stack / two pointers → amortised O(n)
- Recursion space = max depth
- Sorting inside a loop is the most common hidden cost
