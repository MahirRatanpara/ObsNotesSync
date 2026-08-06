# Fenwick Tree (Binary Indexed Tree)

## Why It Matters

Does most of what a segment tree does for prefix-sum-style problems, in a fraction of the code. If you can only memorise one range-query structure under interview pressure, memorise this one.

## Core Idea

Each index `i` stores the sum of a range whose length is the **lowest set bit** of `i`. Traversing by adding or removing that bit walks the tree in O(log n).

```java
class Fenwick {
    private final long[] tree;                     // 1-INDEXED

    Fenwick(int n) { tree = new long[n + 1]; }

    void update(int i, long delta) {               // add delta at index i
        for (i++; i < tree.length; i += i & -i)    // i & -i = lowest set bit
            tree[i] += delta;
    }

    long prefixSum(int i) {                        // sum of [0, i]
        long s = 0;
        for (i++; i > 0; i -= i & -i)
            s += tree[i];
        return s;
    }

    long rangeSum(int l, int r) {                  // sum of [l, r]
        return prefixSum(r) - prefixSum(l - 1);
    }
}
```

**Eight lines of real logic.** That's the whole reason to prefer it.

## Why `i & -i` Gives The Lowest Set Bit

Two's complement negation flips all bits and adds one, so `-i` has every bit above the lowest set bit inverted and everything below still zero. ANDing leaves exactly the lowest set bit.

```
i  = 12 = 0b1100
-i =      0b0100  (in two's complement)
i & -i =  0b0100 = 4
```

That value is the *length of the range* node `i` is responsible for.

## Why It Is 1-Indexed

Index 0 has no set bits, so `i -= i & -i` would loop forever. The `i++` inside `update` and `prefixSum` converts a 0-indexed public API to the 1-indexed internal array — a clean way to avoid off-by-one bugs at every call site.

## The Fundamental Limitation

`rangeSum(l, r) = prefixSum(r) − prefixSum(l−1)` relies on **subtraction undoing addition**.

That means Fenwick works only for **invertible** operations:

| Works | Doesn't work |
|---|---|
| Sum, XOR, count | **Min, max, GCD** |

**You cannot "un-min" a value.** For min/max/GCD range queries you need a [Segment Tree](Segment%20Tree.md). This is the single most common follow-up question.

## Range Update, Point Query

Store deltas instead of values:

```java
void rangeAdd(int l, int r, long v) { update(l, v); update(r + 1, -v); }
long pointValue(int i) { return prefixSum(i); }
```

Same difference-array idea as in [Prefix Sum](../Arrays%20and%20Strings/Prefix%20Sum.md).

**Range update + range query** needs two Fenwick trees — worth naming, rarely worth deriving in an interview.

## Coordinate Compression

Fenwick is indexed by position, so large or non-integer values must be mapped to a dense `0..k-1` range first:

```java
int[] sorted = Arrays.stream(nums).distinct().sorted().toArray();
int rank = Arrays.binarySearch(sorted, x);        // compressed index
```

**This unlocks the "count smaller/greater elements" family** — Count of Smaller Numbers After Self, Reverse Pairs, Count of Range Sum. Iterate right to left, query the prefix, then insert.

```java
// Count of Smaller Numbers After Self
for (int i = n - 1; i >= 0; i--) {
    res[i] = (int) fen.prefixSum(rank(nums[i]) - 1);   // how many smaller already seen
    fen.update(rank(nums[i]), 1);
}
```

**This combination — coordinate compression plus Fenwick — is the intended solution to several hard problems.** Recognising it is high value.

## Fenwick vs Segment Tree

| | Fenwick | Segment tree |
|---|---|---|
| Code | **~10 lines** | ~50 lines |
| Memory | **n** | 4n |
| Constant factor | **Lower** | Higher |
| Operations | Invertible only | **Any associative** |
| Range update + range query | Two trees | Lazy propagation |
| Debug under pressure | **Easy** | Harder |

**Default to Fenwick for sums and counts; escalate to a segment tree only when the operation isn't invertible or you need range assignment.**

## Key Problems

| Problem | Technique |
|---|---|
| Range Sum Query — Mutable | Basic Fenwick |
| Count of Smaller Numbers After Self | Compression + Fenwick |
| Reverse Pairs | Compression + Fenwick |
| Count of Range Sum | Prefix sums + compression + Fenwick |
| Create Sorted Array through Instructions | Fenwick over value counts |
| Number of Longest Increasing Subsequence | Fenwick over values (max variant needs segment tree) |

## Common Mistakes

- Using 0-indexing internally → infinite loop
- Trying to use it for min/max
- Forgetting coordinate compression with large or sparse values
- `int` overflow on accumulated sums — use `long`
- Off-by-one in `rangeSum` (`prefixSum(l - 1)`, not `prefixSum(l)`)

## Related Topics

- [Segment Tree](Segment%20Tree.md)
- [Prefix Sum](../Arrays%20and%20Strings/Prefix%20Sum.md)
- [Sorting Algorithms](../Sorting%20and%20Selection/Sorting%20Algorithms.md)

## Revision Summary

Prefix sums with point updates in O(log n) and about ten lines of code, using the lowest-set-bit trick. Restricted to invertible operations, so min/max need a segment tree. Coordinate compression plus Fenwick solves the "count smaller elements" family.

## Quick Recall

- `i & -i` = lowest set bit = range length
- 1-indexed internally, always
- `update`: `i += i & -i`; `query`: `i -= i & -i`
- Invertible operations only — no min/max
- Compression + Fenwick → count smaller/greater
- Prefer over segment tree when it applies
