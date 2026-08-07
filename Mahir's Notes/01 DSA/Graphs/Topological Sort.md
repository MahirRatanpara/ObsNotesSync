# Topological Sort

## Why It Matters

Any problem phrased with prerequisites, dependencies, build order, or course scheduling is a topological sort. It also unlocks DP on DAGs.

## Core Idea

A linear ordering of a **directed acyclic graph** such that every edge `u → v` places `u` before `v`. Exists if and only if the graph has no cycle — which makes topological sort a cycle detector too.

## Kahn's Algorithm (BFS, preferred)

```java
int[] indeg = new int[n];
for (int u = 0; u < n; u++) for (int v : adj[u]) indeg[v]++;

Deque<Integer> q = new ArrayDeque<>();
for (int i = 0; i < n; i++) if (indeg[i] == 0) q.offer(i);

List<Integer> order = new ArrayList<>();
while (!q.isEmpty()) {
    int u = q.poll();
    order.add(u);
    for (int v : adj[u]) if (--indeg[v] == 0) q.offer(v);
}
return order.size() == n ? order : List.of();   // short → cycle exists
```

**`order.size() != n` means a cycle.** This is the cleanest cycle check in interviews.

## DFS Variant

Post-order DFS, then reverse the finish order. Needs separate cycle detection (three-colour) because a plain DFS won't notice.

Prefer Kahn's: it detects cycles for free and avoids recursion depth limits.

## Lexicographically Smallest Order

Swap the queue for a `PriorityQueue<Integer>`. Complexity becomes O(V log V + E).

## DP on a DAG

Once you have a topological order, longest/shortest path and path counting become straightforward DP:

```java
for (int u : topoOrder)
    for (int v : adj[u])
        dp[v] = Math.max(dp[v], dp[u] + weight(u, v));
```

This is why "longest path" is tractable on a DAG but NP-hard on a general graph.

## Key Problems

| Problem | Note |
|---|---|
| Course Schedule | Cycle detection only |
| Course Schedule II | Return the order |
| Alien Dictionary | Build edges from adjacent word pairs |
| Minimum Height Trees | Peel leaves (indegree ≤ 1) layer by layer |
| Parallel Courses | Number of BFS levels = minimum semesters |
| Sequence Reconstruction | Unique order ⟺ queue size is always 1 |

## Alien Dictionary — The Trap

Compare adjacent words character by character; the first differing character gives edge `a → b`. **If a word is a prefix of the previous word and shorter, the input is invalid** — return `""`. Candidates miss this constantly.

## Advantages

- O(V + E), simple
- Free cycle detection with Kahn's
- Enables DAG DP

## Limitations

- DAGs only
- The order is generally not unique (unless the queue holds exactly one node at every step)

## Common Mistakes

- Forgetting the `order.size() == n` cycle check
- Building edges in the wrong direction (prerequisite → course, not the reverse)
- Missing the prefix-invalid case in Alien Dictionary
- Using DFS topo sort without separate cycle detection

## Related Topics

- [BFS and DFS](BFS%20and%20DFS.md)
- [Graph Algorithm Selection](Graph%20Algorithm%20Selection.md)
- [Dynamic Programming Fundamentals](Dynamic%20Programming%20Fundamentals.md)

## Revision Summary

Kahn's algorithm: compute indegrees, queue the zeros, peel. If you emit fewer than n nodes, there's a cycle. A topological order turns a DAG into a DP-friendly sequence.

## Quick Recall

- "prerequisite", "dependency", "build order" → topo sort
- Kahn = indegree + queue
- `order.size() < n` → cycle
- Lexicographic smallest → priority queue
- Unique order ⟺ queue size always 1
