# BFS and DFS

## Why It Matters

Every graph and grid problem starts here. Choosing wrongly costs you the whole question.

## Core Idea

| | BFS | DFS |
|---|---|---|
| Structure | Queue | Stack / recursion |
| Explores | Level by level | Deep before wide |
| Gives shortest path | Yes (unweighted only) | No |
| Space | O(width) — can be huge | O(depth) |
| Natural for | Minimum steps, level order | Paths, connectivity, cycles, backtracking |

## BFS Template (grid, shortest steps)

```java
Deque<int[]> q = new ArrayDeque<>();
boolean[][] seen = new boolean[m][n];
q.offer(new int[]{sr, sc}); seen[sr][sc] = true;
int steps = 0;
int[][] DIRS = {{1,0},{-1,0},{0,1},{0,-1}};
while (!q.isEmpty()) {
    int sz = q.size();                       // freeze level size
    for (int i = 0; i < sz; i++) {
        int[] cur = q.poll();
        if (isTarget(cur)) return steps;
        for (int[] d : DIRS) {
            int r = cur[0] + d[0], c = cur[1] + d[1];
            if (r < 0 || r >= m || c < 0 || c >= n || seen[r][c] || grid[r][c] == '#') continue;
            seen[r][c] = true;               // mark on ENQUEUE, not dequeue
            q.offer(new int[]{r, c});
        }
    }
    steps++;
}
```

**Mark visited on enqueue.** Marking on dequeue lets the same cell enter the queue many times and degrades to exponential behaviour.

## DFS Template

```java
void dfs(int r, int c) {
    if (out of bounds || seen[r][c] || blocked) return;
    seen[r][c] = true;
    for (int[] d : DIRS) dfs(r + d[0], c + d[1]);
}
```

For deep graphs (10⁵+ nodes) convert to an explicit stack to avoid `StackOverflowError`.

## Multi-Source BFS

Seed the queue with **all** sources at distance 0, then run ordinary BFS. The first time a cell is reached is its distance to the *nearest* source — no need to run BFS per source.

```java
for (each source s) { q.offer(s); dist[s] = 0; seen[s] = true; }
// then standard BFS loop
```

Used in: Rotting Oranges, 01 Matrix, Walls and Gates, Shortest Distance to Any Building.

**Recognition:** "distance to the nearest X" or "spread simultaneously from many points".

## Cycle Detection

**Directed** — three-colour DFS:
```java
// 0 = unvisited, 1 = in current path, 2 = done
boolean hasCycle(int u) {
    if (colour[u] == 1) return true;      // back edge → cycle
    if (colour[u] == 2) return false;
    colour[u] = 1;
    for (int v : adj[u]) if (hasCycle(v)) return true;
    colour[u] = 2;
    return false;
}
```

**Undirected** — DFS tracking the parent, or union-find (an edge joining two nodes already in the same set is a cycle).

## Key Problems

| Problem | Technique |
|---|---|
| Number of Islands | DFS/BFS flood fill |
| Rotting Oranges | Multi-source BFS |
| 01 Matrix | Multi-source BFS |
| Word Ladder | BFS on implicit graph |
| Shortest Path in Binary Matrix | BFS, 8 directions |
| Course Schedule | DFS 3-colour or Kahn |
| Clone Graph | DFS + hash map |
| Pacific Atlantic Water Flow | Reverse DFS from borders |
| Surrounded Regions | DFS from borders, mark safe |

## Common Mistakes

- Marking visited on dequeue instead of enqueue
- Using BFS on a weighted graph and claiming shortest path
- Recursion depth overflow on large grids
- Forgetting to freeze `q.size()` when you need level boundaries
- Running single-source BFS repeatedly where multi-source would do it in one pass

## Related Topics

- [Graph Algorithm Selection](Graph%20Algorithm%20Selection.md)
- [Topological Sort](Topological%20Sort.md)
- [Union Find](Union%20Find.md)

## Revision Summary

BFS for minimum steps on unweighted graphs, DFS for paths and connectivity. Mark on enqueue. Multi-source BFS when the question says "nearest".

## Quick Recall

- BFS = queue = shortest (unweighted)
- DFS = stack = paths, cycles, components
- Freeze `q.size()` for level-by-level
- "nearest X" → seed all sources at once
- Directed cycle → 3-colour DFS
