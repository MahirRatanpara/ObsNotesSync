# DSA Cheat Sheet

> One page. Read before every coding round.

## Constraint → Complexity

| n | Complexity | Pattern |
|---|---|---|
| ≤ 10 | O(n!) | Backtracking, permutations |
| ≤ 20 | O(2ⁿ) | Bitmask DP |
| ≤ 100 | O(n³) | Floyd–Warshall, 3D DP |
| ≤ 1,000 | O(n²) | 2D DP |
| ≤ 10⁵ | O(n log n) | Sort, heap, binary search |
| ≤ 10⁶ | O(n) | Hash map, two pointers, sliding window |
| ≤ 10⁹ | O(log n) | Binary search on answer, math |

## Signal Word → Pattern

| Word | Pattern |
|---|---|
| contiguous / subarray / substring | Sliding window, prefix sum |
| subsequence | DP |
| shortest (unweighted) | BFS |
| shortest (weighted) | Dijkstra |
| minimize the maximum | Binary search on answer |
| kth largest / top k | Heap (size k) or quickselect |
| next greater / smaller | Monotonic stack |
| all combinations / permutations | Backtracking |
| prerequisites / dependencies | Topological sort |
| connected / island | DFS, BFS, union-find |
| intervals / meetings | Sort + sweep or heap |
| prefix / autocomplete | Trie |
| range query + updates | Fenwick / segment tree |
| cycle in list | Fast & slow pointers |

## Templates

**Binary search (lower bound)**
```java
int lo = 0, hi = n;
while (lo < hi) { int mid = lo + (hi-lo)/2; if (pred(mid)) hi = mid; else lo = mid+1; }
return lo;
```

**Sliding window (variable)**
```java
int l = 0;
for (int r = 0; r < n; r++) { add(r); while (invalid()) remove(l++); best = max(best, r-l+1); }
```

**Monotonic stack (next greater)**
```java
for (int i = 0; i < n; i++) { while (!st.isEmpty() && a[i] > a[st.peek()]) res[st.pop()] = a[i]; st.push(i); }
```

**BFS grid**
```java
q.offer(start); seen[start] = true;
while (!q.isEmpty()) { int sz = q.size(); for (int i=0;i<sz;i++){ ... } steps++; }
```

**Backtracking**
```java
void bt(path, start) {
  if (done) { res.add(new ArrayList<>(path)); return; }
  for (int i = start; i < n; i++) { path.add(x); bt(path, i+1); path.remove(path.size()-1); }
}
```

**Union-Find**
```java
int find(int x){ while(p[x]!=x){ p[x]=p[p[x]]; x=p[x]; } return x; }
boolean union(int a,int b){ int ra=find(a), rb=find(b); if(ra==rb) return false; p[rb]=ra; return true; }
```

**Prefix + hash map (subarray sum = k)**
```java
map.put(0L, 1);
for (int x : a) { run += x; count += map.getOrDefault(run - k, 0); map.merge(run, 1, Integer::sum); }
```

## Complexity Reference

| Structure | Access | Search | Insert | Delete |
|---|---|---|---|---|
| Array | O(1) | O(n) | O(n) | O(n) |
| Hash map | — | O(1) | O(1) | O(1) |
| Heap | O(1) peek | O(n) | O(log n) | O(log n) |
| Balanced BST | O(log n) | O(log n) | O(log n) | O(log n) |
| Trie | — | O(L) | O(L) | O(L) |
| Union-Find | — | O(α) | O(α) | — |

| Graph algorithm | Time |
|---|---|
| BFS / DFS | O(V + E) |
| Dijkstra | O((V+E) log V) |
| Bellman–Ford | O(VE) |
| Floyd–Warshall | O(V³) |
| Kruskal / Prim | O(E log E) |

## Traps

- Greedy without proof — try `coins=[1,3,4], amount=6`
- `(lo+hi)/2` overflow → `lo + (hi-lo)/2`
- Adding `path` instead of a copy in backtracking
- 0/1 knapsack inner loop must go **backward**
- `map.put(0,1)` in prefix-sum counting
- BFS marks visited on **enqueue**
- K largest → **min** heap
- `a - b` comparators overflow

## The 60-Second Opening

1. Restate the problem
2. Ask about bounds, nulls, duplicates, sortedness
3. Say: "n is X, so I need O(Y)"
4. Name the pattern and why
5. Describe the approach before coding
6. Code
7. Dry-run, then edge cases, unprompted
8. State time and space complexity

## Related

- [Pattern Recognition Framework](Pattern%20Recognition%20Framework.md)
- [Pattern Confusion Matrix](Pattern%20Confusion%20Matrix.md)
- [Interview Execution Playbook](Interview%20Execution%20Playbook.md)
