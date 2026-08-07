# Segment Tree

## Why It Matters

The answer when you need **range queries with updates**. Prefix sums die the moment the array becomes mutable; segment trees handle both in O(log n).

## Core Idea

A binary tree where each node stores an aggregate over a range. The root covers `[0, n-1]`, each node splits into halves, leaves are single elements.

```
                [0,7] sum=36
          /                    \
    [0,3] sum=10          [4,7] sum=26
     /      \               /      \
  [0,1]   [2,3]         [4,5]   [6,7]
```

Any range decomposes into **at most 2·log n** nodes — that's the complexity bound.

## Array Implementation

```java
class SegmentTree {
    private final int[] tree; private final int n;

    SegmentTree(int[] a) {
        n = a.length;
        tree = new int[4 * n];          // 4n is the safe size
        build(a, 1, 0, n - 1);
    }

    private void build(int[] a, int node, int lo, int hi) {
        if (lo == hi) { tree[node] = a[lo]; return; }
        int mid = (lo + hi) >>> 1;
        build(a, 2*node, lo, mid);
        build(a, 2*node+1, mid+1, hi);
        tree[node] = tree[2*node] + tree[2*node+1];       // merge
    }

    int query(int node, int lo, int hi, int l, int r) {
        if (r < lo || hi < l) return 0;                   // no overlap → identity
        if (l <= lo && hi <= r) return tree[node];        // total overlap
        int mid = (lo + hi) >>> 1;                        // partial → recurse both
        return query(2*node, lo, mid, l, r) + query(2*node+1, mid+1, hi, l, r);
    }

    void update(int node, int lo, int hi, int idx, int val) {
        if (lo == hi) { tree[node] = val; return; }
        int mid = (lo + hi) >>> 1;
        if (idx <= mid) update(2*node, lo, mid, idx, val);
        else update(2*node+1, mid+1, hi, idx, val);
        tree[node] = tree[2*node] + tree[2*node+1];
    }
}
```

**Why `4 * n`?** The tree isn't perfectly balanced when n isn't a power of two. `4n` is the safe upper bound; `2 * nextPowerOfTwo(n)` is tighter.

**The three-case query (no overlap / total overlap / partial) is the pattern to memorise** — it generalises to every segment tree variant.

## Any Associative Merge Works

Replace `+` with any associative operation and its identity:

| Operation | Merge | Identity |
|---|---|---|
| Sum | `a + b` | 0 |
| Min | `Math.min` | `+∞` |
| Max | `Math.max` | `−∞` |
| GCD | `gcd(a,b)` | 0 |
| Bitwise OR/AND | `\|` / `&` | 0 / all-ones |

**Associativity is the requirement** — the tree merges in a fixed structural order, so a non-associative operation gives wrong answers.

## Lazy Propagation (range updates)

Point updates are O(log n), but updating a whole range one element at a time is O(n log n). Lazy propagation defers the work:

```java
void push(int node, int lo, int hi) {
    if (lazy[node] == 0) return;
    tree[node] += lazy[node] * (hi - lo + 1);      // apply to this node
    if (lo != hi) {                                // defer to children
        lazy[2*node]   += lazy[node];
        lazy[2*node+1] += lazy[node];
    }
    lazy[node] = 0;
}
```

Call `push` at the top of every query and update. This makes range updates O(log n) too.

**Mention lazy propagation when asked about range updates** — it's the expected senior answer.

## Segment Tree vs Fenwick vs Prefix Sum

| | Prefix sum | Fenwick (BIT) | Segment tree |
|---|---|---|---|
| Build | O(n) | O(n) | O(n) |
| Range query | **O(1)** | O(log n) | O(log n) |
| Point update | **O(n)** | O(log n) | O(log n) |
| Range update | O(n) | O(log n)† | **O(log n)** with lazy |
| Operations | Invertible only | **Invertible only** | **Any associative** |
| Code size | Tiny | **Small** | Large |
| Memory | n | **n** | 4n |

† with a second BIT

**Decision rule:**
- No updates → **prefix sum**
- Point update + prefix sum → **Fenwick** (much less code)
- Min/max/GCD, or range updates → **segment tree**

**Fenwick can't do min/max** because subtraction doesn't undo them. That's the key distinction and a common follow-up.

## Variants Worth Naming

| Variant | Use |
|---|---|
| Merge sort tree | Count elements less than k in a range |
| Persistent segment tree | Query historical versions |
| 2D segment tree | Matrix range queries |
| Segment tree beats | Range min-assign with sum queries |

## Key Problems

| Problem | Note |
|---|---|
| Range Sum Query — Mutable | Canonical |
| Range Minimum Query | Needs segment tree, not Fenwick |
| Count of Smaller Numbers After Self | Or use a Fenwick tree over compressed values |
| The Skyline Problem | Segment tree or heap |
| Falling Squares | Range max + range assign |
| My Calendar III | Range add, max query |

## Common Mistakes

- Sizing the array `2n` instead of `4n` → index out of bounds
- Wrong identity for the no-overlap case (returning 0 for a min query)
- Forgetting `push` in lazy propagation
- Using a non-associative merge
- Building one when a Fenwick tree or prefix sum would do

## Related Topics

- [Fenwick Tree](Fenwick%20Tree.md)
- [Prefix Sum](Prefix%20Sum.md)
- [Complexity Analysis](Complexity%20Analysis.md)

## Revision Summary

A binary tree of range aggregates giving O(log n) queries and updates for any associative operation. Query decomposes into no-overlap, total-overlap, and partial-overlap cases. Lazy propagation makes range updates O(log n). Prefer Fenwick when the operation is invertible.

## Quick Recall

- `4 * n` array size
- Three cases: no overlap → identity, total → return, partial → recurse
- Any **associative** merge
- Lazy propagation for range updates
- Min/max needs segment tree; Fenwick can't do it
