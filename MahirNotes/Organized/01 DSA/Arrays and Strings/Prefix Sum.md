# Prefix Sum

## Why It Matters

Answers unlimited range-sum queries in O(1) after O(n) preprocessing, and combined with a hash map solves the entire "subarray sum equals K" family — including with negative numbers, where sliding window fails.

## Core Idea

`prefix[i]` = sum of the first `i` elements. Then:

```
sum(i..j) = prefix[j + 1] - prefix[i]
```

Use a length `n+1` array with `prefix[0] = 0` to avoid boundary special-casing.

## 1D Template

```java
long[] prefix = new long[n + 1];
for (int i = 0; i < n; i++) prefix[i + 1] = prefix[i] + arr[i];
// inclusive range [i, j]
long rangeSum = prefix[j + 1] - prefix[i];
```

## Prefix Sum + Hash Map (the important one)

Counts subarrays summing to `k`, works with negatives:

```java
Map<Long, Integer> seen = new HashMap<>();
seen.put(0L, 1);          // empty prefix — critical
long running = 0; int count = 0;
for (int x : arr) {
    running += x;
    count += seen.getOrDefault(running - k, 0);
    seen.merge(running, 1, Integer::sum);
}
```

**Why `seen.put(0L, 1)`?** It accounts for subarrays starting at index 0. Forgetting it is the single most common bug in this pattern.

## 2D Prefix Sum

```java
int[][] p = new int[m + 1][n + 1];
for (int i = 0; i < m; i++)
    for (int j = 0; j < n; j++)
        p[i+1][j+1] = grid[i][j] + p[i][j+1] + p[i+1][j] - p[i][j];

// sum of rectangle (r1,c1) to (r2,c2) inclusive
int s = p[r2+1][c2+1] - p[r1][c2+1] - p[r2+1][c1] + p[r1][c1];
```

Inclusion–exclusion: add the two overlapping rectangles back the double-subtracted corner.

## Difference Array (inverse trick)

For many *range updates* and one final read:

```java
diff[l] += val; diff[r + 1] -= val;      // O(1) per update
// then prefix-sum diff once to get final values
```

Used in "Corporate Flight Bookings", "Range Addition", and interval-overlap counting.

## Key Problems

| Problem | Technique |
|---|---|
| Range Sum Query — Immutable | 1D prefix |
| Range Sum Query 2D — Immutable | 2D prefix |
| Subarray Sum Equals K | Prefix + hash map |
| Continuous Subarray Sum | Prefix mod k + hash map |
| Contiguous Array (equal 0s and 1s) | Map 0→−1, prefix + hash map |
| Product of Array Except Self | Prefix/suffix products |
| Corporate Flight Bookings | Difference array |
| Maximum Size Subarray Sum Equals k | Prefix + first-occurrence map |

## Advantages

- O(1) queries after O(n) build
- Handles negative numbers, unlike sliding window
- The difference-array variant makes range updates O(1)

## Limitations

- Static data only — an update invalidates the prefix array (O(n) rebuild). Use a **Fenwick tree** or **segment tree** if updates are interleaved with queries.
- O(n) extra space

## Tradeoffs

| Approach | Query | Update | Use when |
|---|---|---|---|
| Prefix sum | O(1) | O(n) | No updates |
| Fenwick tree | O(log n) | O(log n) | Point updates, range sums |
| Segment tree | O(log n) | O(log n) | Range updates, arbitrary merges |

## Common Mistakes

- Omitting `seen.put(0, 1)` in the hash-map variant
- Integer overflow — use `long` for prefix arrays
- Off-by-one on the `n+1` sizing convention
- Using prefix sum when the array is mutable

## Related Topics

- [Sliding Window](../Two%20Pointers%20and%20Sliding%20Window/Sliding%20Window.md)
- [Fenwick Tree](../Range%20Queries/Fenwick%20Tree.md)
- [Segment Tree](../Range%20Queries/Segment%20Tree.md)

## Revision Summary

Prefix sum for static range queries; prefix + hash map for counting subarrays with a target sum; difference array for bulk range updates; Fenwick/segment tree once updates appear.

## Quick Recall

- `sum(i..j) = prefix[j+1] − prefix[i]`
- Always seed the map with `{0: 1}`
- 2D uses inclusion–exclusion (add the corner back)
- Mutable data → Fenwick, not prefix
