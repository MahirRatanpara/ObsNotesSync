---

tags:

- dsa
- graph-theory
- algorithms
- interview-prep date: 2026-04-18 topic: Eulerian Circuits & Paths difficulty: medium

---

# 🔁 Eulerian Circuits & Paths

## What is an Eulerian Circuit?

An **Eulerian Circuit** is a closed walk in a graph that traverses every edge **exactly once** and returns to the starting vertex.

An **Eulerian Path** is the same but does _not_ need to return to the starting vertex — it's an open walk.

> [!tip] Memory Hook Think of it like drawing a shape without lifting your pen **and** not retracing any line.
> 
> - **Circuit** → pen ends where it started
> - **Path** → pen ends somewhere else

---

## Existence Conditions

### Undirected Graph

|Type|Conditions|
|---|---|
|**Eulerian Circuit**|Graph is **connected** (ignoring isolated vertices) **AND** every vertex has **even degree**|
|**Eulerian Path**|Graph is connected **AND** exactly **0 or 2** vertices have odd degree (the 2 odd-degree vertices are the start and end)|

> [!note] Why even degree? At every intermediate vertex you enter and exit — consuming edges in pairs. If any vertex has odd degree, you'll get stuck there and can't return to the start.

---

### Directed Graph

|Type|Conditions|
|---|---|
|**Eulerian Circuit**|Graph is **strongly connected** AND for every vertex: `in-degree == out-degree`|
|**Eulerian Path**|Graph is **weakly connected** AND exactly one vertex with `out − in = 1` (start), exactly one with `in − out = 1` (end), all others with `in == out`|

> [!note] Why in == out for directed circuit? Every time you enter a vertex you must also be able to leave it. `in == out` guarantees this for every node.

---

## Degree Check — Quick Examples

### Undirected Example

```
Graph:  A - B - C
            |   |
            D - E

Degrees:
  A → 1   (odd)
  B → 3   (odd)
  C → 2   (even)
  D → 2   (even)
  E → 2   (even)

→ 2 vertices with odd degree (A, B)
→ Eulerian PATH exists (A to B or B to A), NOT a circuit.
```

### Undirected — Circuit Example

```
Graph:  A - B
        |   |
        C - D

Degrees: A=2, B=2, C=2, D=2 → all even
→ Eulerian CIRCUIT exists ✓
```

### Directed Example

```
Graph:  0 → 1 → 2 → 0

in-degrees:  0=1, 1=1, 2=1
out-degrees: 0=1, 1=1, 2=1
→ in == out for all → Eulerian CIRCUIT exists ✓
```

---

## Hierholzer's Algorithm

> [!abstract] Core Intuition Build subcircuits greedily, then **splice** them together into one big circuit. Each edge is touched exactly once → **O(E)**.

### High-Level Steps

1. Start at any valid vertex (for a path, start at the vertex with `out − in = 1` in directed, or odd degree in undirected).
2. Follow unused edges, marking them as visited, until you return to the starting vertex → this is your **first subcircuit**.
3. Scan the current path for any vertex that still has **unused edges**.
4. From that vertex, walk unused edges to form a **new subcircuit**.
5. **Splice** the new subcircuit into the main path at that vertex.
6. Repeat steps 3–5 until **no unused edges remain**.
7. The final spliced path is the Eulerian circuit.

> [!warning] Edge Case If at step 3 you can't find any vertex with unused edges but not all edges are used → **no Eulerian circuit exists** (graph not connected or degree condition violated).

---

## Algorithm — Code

### Undirected Graph (Java)

```java
import java.util.*;

public class EulerianCircuit {

    // Hierholzer's Algorithm — Undirected
    public List<Integer> findCircuit(int n, List<List<Integer>> adj) {
        // Step 1: Check all degrees are even
        for (int v = 0; v < n; v++) {
            if (adj.get(v).size() % 2 != 0) return Collections.emptyList(); // no circuit
        }

        // Step 2: Track edge usage (use index pointers per vertex)
        int[] ptr = new int[n]; // pointer to next unused edge per vertex
        Deque<Integer> stack = new ArrayDeque<>();
        List<Integer> circuit = new ArrayList<>();

        stack.push(0); // start from vertex 0

        while (!stack.isEmpty()) {
            int v = stack.peek();
            if (ptr[v] < adj.get(v).size()) {
                int u = adj.get(v).get(ptr[v]++);
                stack.push(u);
            } else {
                circuit.add(stack.pop()); // backtrack — v is finalized
            }
        }

        Collections.reverse(circuit);
        return circuit;
    }
}
```

### Directed Graph (Java)

```java
import java.util.*;

public class EulerianCircuitDirected {

    // Hierholzer's Algorithm — Directed
    public List<Integer> findCircuit(int n, List<List<Integer>> adj) {
        // Step 1: Check in-degree == out-degree for all vertices
        int[] inDeg = new int[n];
        int[] outDeg = new int[n];
        for (int v = 0; v < n; v++) {
            outDeg[v] = adj.get(v).size();
            for (int u : adj.get(v)) inDeg[u]++;
        }
        for (int v = 0; v < n; v++) {
            if (inDeg[v] != outDeg[v]) return Collections.emptyList();
        }

        // Step 2: Iterative DFS with pointer per vertex
        int[] ptr = new int[n];
        Deque<Integer> stack = new ArrayDeque<>();
        List<Integer> circuit = new ArrayList<>();

        stack.push(0);

        while (!stack.isEmpty()) {
            int v = stack.peek();
            if (ptr[v] < adj.get(v).size()) {
                stack.push(adj.get(v).get(ptr[v]++));
            } else {
                circuit.add(stack.pop());
            }
        }

        Collections.reverse(circuit);
        return circuit;
    }
}
```

> [!tip] Key Implementation Detail Using a **pointer per vertex** (`ptr[v]`) instead of removing edges avoids O(E) deletions. When `ptr[v]` reaches the end of `adj[v]`, all edges from `v` are exhausted — pop `v` onto the result.

---

### Eulerian Path (Directed) — find start vertex first

```java
public int findStartVertex(int n, int[] inDeg, int[] outDeg) {
    for (int v = 0; v < n; v++) {
        if (outDeg[v] - inDeg[v] == 1) return v; // start of path
    }
    return 0; // circuit — any vertex works
}
```

---

## Complexity Analysis

||Time|Space|
|---|---|---|
|Existence check|O(V + E)|O(V)|
|Hierholzer's (find circuit)|**O(V + E)**|O(V + E)|
|Naïve DFS (incorrect)|O(E²)|O(E)|

> [!danger] Common Mistake Don't use a plain recursive DFS removing edges one by one — it's O(E²) and blows the stack for large inputs. Always use the **iterative stack + pointer** version.

---

## Trace Through Example

```
Graph (directed):  0→1, 1→2, 2→0, 0→3, 3→4, 4→0

Start at 0.

Stack trace:
  push 0
  0→1: push 1
  1→2: push 2
  2→0: push 0
  0→3: push 3   (0's first edge was 1, already used — ptr moves)
  3→4: push 4
  4→0: push 0
  0 has no more edges → pop 0 → circuit: [0]
  4 has no more edges → pop 4 → circuit: [0, 4]
  3 has no more edges → pop 3 → circuit: [0, 4, 3]
  0 has no more edges → pop 0 → circuit: [0, 4, 3, 0]
  2 has no more edges → pop 2 → circuit: [0, 4, 3, 0, 2]
  1 has no more edges → pop 1 → circuit: [0, 4, 3, 0, 2, 1]
  0 has no more edges → pop 0 → circuit: [0, 4, 3, 0, 2, 1, 0]

Reversed: [0, 1, 2, 0, 3, 4, 0] ✓
```

---

## Common LeetCode / Interview Patterns

|Problem|Pattern|
|---|---|
|Reconstruct Itinerary (LC 332)|Eulerian path on directed graph (lexicographic order)|
|Valid Arrangement of Pairs (LC 2097)|Eulerian path — find start by `out − in = 1`|
|Chinese Postman Problem|Add minimum edges to make all degrees even (T-joins)|
|De Bruijn Sequence|Eulerian circuit on a specially constructed de Bruijn graph|

> [!example] LC 332 — Reconstruct Itinerary Airports are vertices, tickets are directed edges. Find Eulerian path starting from "JFK". Trick: sort adjacency lists lexicographically so the greedy walk picks alphabetically smallest next airport.
> 
> ```java
> // Key difference: use PriorityQueue instead of List for adj
> Map<String, PriorityQueue<String>> graph = new HashMap<>();
> ```

---

## Summary Cheatsheet

```
┌─────────────────────────────────────────────────────────┐
│              EULERIAN — QUICK REFERENCE                 │
├──────────────────┬──────────────────┬───────────────────┤
│                  │  UNDIRECTED      │  DIRECTED         │
├──────────────────┼──────────────────┼───────────────────┤
│ Circuit exists   │ Connected +      │ Strongly conn. +  │
│                  │ all deg even     │ in == out (all)   │
├──────────────────┼──────────────────┼───────────────────┤
│ Path exists      │ Connected +      │ Weakly conn. +    │
│                  │ exactly 2 odd    │ one out-in=1,     │
│                  │ degree vertices  │ one in-out=1      │
├──────────────────┼──────────────────┼───────────────────┤
│ Algorithm        │ Hierholzer's     │ Hierholzer's      │
│ Complexity       │ O(V + E)         │ O(V + E)          │
└──────────────────┴──────────────────┴───────────────────┘
```

> [!check] Before every interview problem involving edges traversed exactly once:
> 
> 1. Check existence conditions first (degree check)
> 2. Find start vertex (odd-degree node or `out-in=1` node)
> 3. Run Hierholzer's iteratively with pointer array
> 4. Reverse the result at the end