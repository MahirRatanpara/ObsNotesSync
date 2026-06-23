The whole thing reduces to two questions. Answer them in order and the algorithm is forced.

1. **What are the edge weights?** (uniform / {0,1} / non-negative / negative / it's a DAG)
2. **When is a node's answer final?** (this dictates the revisit + termination rule)

Everything below is just the consequence of those two questions.

---

## Part 1 — The selection decision tree

Walk this top to bottom. Stop at the first match.

```
Is "shortest path / min cost" actually the goal?
├─ NO → pick by goal:
│      reachability / # components      → BFS / DFS / Union-Find
│      cycle detection (directed)       → DFS with 3 colors
│      cycle detection (undirected)     → Union-Find / DFS
│      ordering with dependencies       → Topological sort (Kahn / DFS)
│      connect all nodes min cost       → MST (Kruskal / Prim)
│
└─ YES → it's a shortest-path family problem:
       │
       ├─ Need ALL pairs?
       │     small V (≤ ~400)           → Floyd-Warshall  O(V³)
       │     large + sparse             → Dijkstra from every source
       │
       └─ Single source (or multi-source):
             graph is a DAG             → topo order + relax  O(V+E)   ← even works with negative weights
             all edges equal weight     → BFS                          ← multi-source if many starts
             edges ∈ {0, 1}             → 0-1 BFS (deque)   O(V+E)
             edges ≥ 0                  → Dijkstra  O(E log V)          ← multi-source = seed all sources
             any negative edge          → Bellman-Ford  O(V·E)         ← also: detects negative cycles
```

### The single rule that resolves "is this DP?"

Most "is it graph or DP?" confusion dissolves with one move:

> **When the problem adds a constraint, fold that constraint into the node.** Your state stops being `node` and becomes `(node, extra_state)`.

Then re-run the decision tree on the **state graph**. Examples of `extra_state`:

|Constraint in the problem|State becomes|Algorithm on the state graph|
|---|---|---|
|"within at most K steps/stops"|`(node, steps_used)`|layered Bellman-Ford / DP over rounds|
|"may remove up to K obstacles"|`(r, c, k_remaining)`|BFS (LC 1293)|
|"collect all keys"|`(r, c, key_bitmask)`|BFS (LC 864)|
|"visit every node once" (TSP)|`(node, visited_bitmask)`|bitmask DP / Held-Karp|
|"fuel / budget remaining"|`(node, budget)`|Dijkstra or DP depending on weights|

So **DP is not a separate branch** — it's what you reach for when (a) the state graph is a DAG and you're _counting / accumulating / taking longest_, or (b) there's a **bounded-step** dimension, or (c) the state is a **subset/bitmask**. If the augmented state graph is just non-negative-weighted, it's _still Dijkstra_ — you didn't need DP at all.

### When greedy (Dijkstra) is _not_ allowed — say this out loud in the interview

Dijkstra's correctness rests on "the first time I pop a node, its distance is final." That invariant needs **non-negative weights**. The moment a negative edge exists, a node you already finalized could later be improved through that negative edge → invariant broken → **switch to Bellman-Ford**. Being able to articulate _why_ (not just "negatives → Bellman-Ford") is exactly the signal Google's looking for.

---

## Part 2 — The revisit & termination rule (your core question)

This is the table to memorize. "Finalized" = answer can never improve again.

| Algorithm            | Mark visited / finalize **when?**     | Do you re-process a node?                                                 | Relaxation                                    | Termination                               |
| -------------------- | ------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------------- | ----------------------------------------- |
| **BFS** (unweighted) | when you **enqueue** it               | **No.** First discovery = shortest.                                       | none                                          | queue empty (or target dequeued)          |
| **0-1 BFS**          | when **popped** (first pop is final)  | No re-process; skip stale pops                                            | push front (w=0) / back (w=1)                 | deque empty (or target popped)            |
| **Dijkstra**         | when **popped** from heap (first pop) | You **push** updated distances many times, but **process each node once** | `if dist[u]+w < dist[v]: update, push`        | heap empty (or target popped)             |
| **Bellman-Ford**     | only after **all V−1 passes**         | Every node may improve across passes — nothing is final mid-run           | relax **all** edges, V−1 times                | V−1 iterations (or a pass with no change) |
| **Floyd-Warshall**   | after the full triple loop            | `dist[i][j]` keeps improving as `k` grows                                 | `dist[i][j] = min(.., dist[i][k]+dist[k][j])` | three nested loops complete               |

### The mental model for "do I revisit?"

- **BFS — never revisit.** Because every edge costs the same, the queue is _already sorted by distance_. The first time you touch a node, you arrived by a shortest path. Mark visited at **enqueue** time (not dequeue) so you never push the same node twice.
    
- **Dijkstra — revisit the _queue_, not the _node_.** You can discover a shorter route to a node _after_ first seeing it but _before_ it's finalized, so you push the better distance. But you **process** (expand neighbors of) each node exactly once — its first pop. Use **lazy deletion**:
    
    ```python
    while heap:
        d, u = heappop(heap)
        if d > dist[u]:        # stale entry — a better one was already processed
            continue           # this is your "already finalized, skip" guard
        for v, w in adj[u]:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                heappush(heap, (dist[v], v))
    ```
    
    The `if d > dist[u]: continue` line **is** the answer to "do we revisit based on the new distance" — you re-examine entries, but you discard the ones that no longer reflect the best distance.
    
- **Bellman-Ford — there is no visited set.** You relax every edge, V−1 times, unconditionally. A node's distance can keep dropping until the last pass. The "revisit" question doesn't apply — it's relaxation by iteration count, not by visitation.
    

### Early termination nuance

For BFS/0-1 BFS/Dijkstra you may stop the instant the **target** is finalized (dequeued/popped) — its value can't improve. You **cannot** early-stop Bellman-Ford on a single target before the passes complete (an improvement could still arrive in a later pass), though you _can_ stop the whole run early if an entire pass changes nothing.

---

## Part 3 — Bellman-Ford & Floyd-Warshall, the parts interviews probe

### Bellman-Ford

- **Why V−1 passes:** a shortest path has at most V−1 edges; pass `k` guarantees correctness for all shortest paths of ≤ k edges. After V−1, all are settled.
- **Negative-cycle detection:** run one extra (V-th) pass. If _any_ edge still relaxes, a negative cycle is reachable.
- **It is DP:** `dp[k][v]` = shortest distance to `v` using ≤ k edges. That framing is the bridge to the next problem ↓

#### The canonical trap: "Cheapest Flights Within K Stops" (LC 787)

K stops = K+1 edges → run **K+1** relaxation rounds. Critical bug to avoid: relax from a **snapshot of the previous round's distances** (copy the array each round), otherwise a single round chains multiple edges and silently uses more than K stops.

```python
dist = [INF]*n; dist[src] = 0
for _ in range(K+1):
    snap = dist[:]                  # <-- snapshot is the whole trick
    for u, v, w in flights:
        if snap[u] + w < dist[v]:
            dist[v] = snap[u] + w
```

### Floyd-Warshall

- **`k` must be the outermost loop.** `k` = "intermediate vertices allowed so far." Invariant: after processing `{0..k}`, `dist[i][j]` is the best path using only those as intermediates. Inner `k` breaks the invariant — classic silent bug.
    
    ```python
    for k in range(V):            # outermost — non-negotiable
        for i in range(V):
            for j in range(V):
                dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
    ```
    
- **Use it when:** V is small (≤ ~400) AND you want all pairs, transitive closure, or negative-cycle detection (`dist[i][i] < 0` for some `i`). Handles negative edges (no negative cycle).
    

---

## Part 4 — Fast pattern → algorithm lookup (drill these)

|Problem signal|Algorithm|Example|
|---|---|---|
|unweighted grid/graph, shortest steps|BFS|LC 1091, 127|
|"nearest X from every cell", many sources|multi-source BFS|LC 994 (rotting oranges), 542, 286|
|edges only 0 or 1|0-1 BFS|LC 1368 (min cost to make path)|
|positive weights, single source|Dijkstra|LC 743, 1631, 778|
|maximize product of probabilities|Dijkstra (max-heap)|LC 1514|
|"at most K stops/edges" bound|Bellman-Ford (K+1 rounds)|LC 787|
|negative edges / detect neg cycle|Bellman-Ford|—|
|all-pairs, small graph|Floyd-Warshall|LC 1334, 399|
|DAG + count paths / longest path|topo sort + DP|LC 1857|
|collect keys / remove obstacles / state|BFS on `(pos, state)`|LC 864, 1293|
|visit all nodes (TSP-ish)|bitmask DP|LC 943, 847|

---

## The 15-second interview routine

1. Weighted? → no = BFS family, yes = continue.
2. Negative edges? → yes = Bellman-Ford (or Floyd-Warshall if all-pairs).
3. Non-negative weights? → Dijkstra. Weights {0,1}? → 0-1 BFS.
4. Extra constraint (K stops / keys / mask / budget)? → fold into the node, re-run steps 1–3 on the state graph; if it's a bounded-step or subset dimension, it's DP.
5. State your revisit rule before coding: BFS marks visited on enqueue and never revisits; Dijkstra finalizes on pop and skips stale heap entries.