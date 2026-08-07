# Union Find (Disjoint Set Union)

## Why It Matters

Near-constant-time dynamic connectivity. The right answer whenever edges arrive over time and you must repeatedly ask "are these two connected?"

## Core Idea

Maintain a forest where each tree is a connected component. Two optimisations make it near-O(1):

- **Path compression** — flatten the tree during `find`
- **Union by rank/size** — always attach the smaller tree under the larger

Together they give O(α(n)) amortised, where α is the inverse Ackermann function — under 5 for any realistic n.

## Implementation

```java
class DSU {
    int[] parent, size;
    int components;

    DSU(int n) {
        parent = new int[n];
        size = new int[n];
        components = n;
        for (int i = 0; i < n; i++) { parent[i] = i; size[i] = 1; }
    }

    int find(int x) {
        while (parent[x] != x) {
            parent[x] = parent[parent[x]];   // path halving
            x = parent[x];
        }
        return x;
    }

    boolean union(int a, int b) {
        int ra = find(a), rb = find(b);
        if (ra == rb) return false;          // already connected → this edge forms a cycle
        if (size[ra] < size[rb]) { int t = ra; ra = rb; rb = t; }
        parent[rb] = ra;
        size[ra] += size[rb];
        components--;
        return true;
    }
}
```

**`union` returning `false` means a cycle.** That single fact solves Redundant Connection and drives Kruskal's algorithm.

## When Union-Find Beats DFS

| | Union-Find | DFS/BFS |
|---|---|---|
| Edges known upfront | Either works | Either works |
| Edges arrive incrementally | **Union-Find** | Rebuild each time — O(V+E) per query |
| Need component count live | **Union-Find** | Recompute |
| Need the actual path | No | **DFS** |
| Deletion of edges | No (needs rollback DSU) | Rebuild |

**Union-Find cannot delete edges.** If the problem removes connections, process it in reverse — turning deletions into additions. That trick solves "Last Day Where You Can Still Cross".

## Kruskal's MST

Sort edges by weight, union greedily, skip edges whose endpoints already share a root:

```java
Arrays.sort(edges, Comparator.comparingInt(e -> e[2]));
int cost = 0, used = 0;
for (int[] e : edges)
    if (dsu.union(e[0], e[1])) { cost += e[2]; if (++used == n - 1) break; }
```

## Key Problems

| Problem | Use |
|---|---|
| Number of Connected Components | Count roots |
| Redundant Connection | First edge where `union` returns false |
| Accounts Merge | Union by shared email |
| Number of Islands II | Dynamic island count as land is added |
| Most Stones Removed | Components of a row/column graph |
| Satisfiability of Equality Equations | Union `==`, then verify `!=` |
| Min Cost to Connect All Points | Kruskal on a complete graph |
| Longest Consecutive Sequence | Union adjacent values (hash map preferred) |

## Advantages

- Near-constant amortised time
- Trivial to implement correctly
- Component count maintained for free

## Limitations

- No edge deletion
- No path reconstruction
- Undirected connectivity only (directed needs SCC algorithms)

## Common Mistakes

- Omitting path compression → O(n) worst case per find
- Comparing `parent[a] == parent[b]` instead of `find(a) == find(b)`
- Union by index instead of by size/rank, creating long chains
- Using it for directed reachability, which it cannot model

## Related Topics

- [Graph Algorithm Selection](Graph%20Algorithm%20Selection.md)
- [BFS and DFS](BFS%20and%20DFS.md)

## Revision Summary

Dynamic connectivity with path compression and union by size. `union` returning false detects a cycle. No deletions — reverse the timeline instead.

## Quick Recall

- O(α(n)) ≈ O(1) amortised
- `union` false → cycle → Redundant Connection
- Component count decremented on each successful union
- Deletions → process in reverse
- Kruskal = sort edges + union
