# Binary Search Templates

## Why It Matters

Simple in concept, notoriously bug-prone in practice. Interviewers use boundary variants (first/last occurrence, rotated arrays) precisely because they expose sloppy invariants.

## Core Idea

Maintain a search interval and an invariant that guarantees the answer stays inside it. Halve the interval each step. The only hard part is **which boundary convention you commit to** — pick one and use it every time.

## The One Template To Memorise

Use the **lower-bound** form. It answers "first index where predicate is true" and everything else reduces to it.

```java
// Finds first index in [0, n] where pred(i) is true.
// Requires pred to be monotonic: false...false true...true
int lo = 0, hi = n;                  // hi = n, not n-1
while (lo < hi) {                    // strict <
    int mid = lo + (hi - lo) / 2;    // overflow-safe
    if (pred(mid)) hi = mid;         // mid might be the answer, keep it
    else lo = mid + 1;               // mid is not, discard it
}
return lo;                           // == hi
```

Loop always terminates: interval strictly shrinks. No off-by-one, no `mid - 1` vs `mid` confusion.

## Deriving The Standard Operations

| Goal | Predicate |
|---|---|
| Exact find | lower bound, then check `a[lo] == target` |
| First occurrence | `a[i] >= target` |
| Last occurrence | `a[i] > target`, then `lo - 1` |
| Insertion position | `a[i] >= target` |
| Count of target | `upperBound − lowerBound` |

## Rotated Sorted Array

```java
int lo = 0, hi = n - 1;
while (lo <= hi) {
    int mid = lo + (hi - lo) / 2;
    if (a[mid] == target) return mid;
    if (a[lo] <= a[mid]) {                       // left half sorted
        if (a[lo] <= target && target < a[mid]) hi = mid - 1;
        else lo = mid + 1;
    } else {                                     // right half sorted
        if (a[mid] < target && target <= a[hi]) lo = mid + 1;
        else hi = mid - 1;
    }
}
return -1;
```

**Key insight:** at least one half is always sorted. Decide which, then check whether the target lies inside that sorted range.

With duplicates, `a[lo] == a[mid] == a[hi]` is ambiguous — shrink both ends by one and continue. Worst case degrades to O(n).

## Common Mistakes

- `(lo + hi) / 2` overflows for large indices — use `lo + (hi - lo) / 2`
- Mixing `lo <= hi` with `hi = mid` → infinite loop
- Mixing `lo < hi` with `hi = mid - 1` → skips the answer
- Assuming the predicate is monotonic without checking

## Related Topics

- [Binary Search on Answer](Binary%20Search%20on%20Answer.md)
- [Complexity Analysis](../Foundations/Complexity%20Analysis.md)

## Revision Summary

Memorise one lower-bound template with `lo < hi` and `hi = mid`. Derive everything else from it.

## Quick Recall

- `lo < hi`, `hi = mid`, `lo = mid + 1`, return `lo`
- `mid = lo + (hi - lo) / 2`
- Rotated: one half is always sorted — find it first
