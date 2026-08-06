# Binary Search on Answer

## Why It Matters

Turns "find the optimal value" into "check whether a value is feasible" — a much easier question. The single most under-recognised pattern in mid-level interviews.

## Core Idea

Instead of searching an array, search the **space of possible answers**. Requires a monotonic feasibility predicate: if `x` works, then every value on one side of `x` also works.

## Recognition

Trigger phrases:

- "minimize the maximum ..."
- "maximize the minimum ..."
- "smallest capacity/speed/size such that ..."
- "can we achieve X in D units?"

Plus: the answer is a number in a bounded range, and checking a candidate is O(n) or O(n log n).

## Template

```java
long lo = minPossible, hi = maxPossible;
while (lo < hi) {
    long mid = lo + (hi - lo) / 2;
    if (feasible(mid)) hi = mid;     // mid works, try smaller
    else lo = mid + 1;               // mid fails, need bigger
}
return lo;
```

For *maximise* problems, flip: `if (feasible(mid)) lo = mid; else hi = mid - 1;` with `mid = lo + (hi - lo + 1) / 2` to avoid an infinite loop.

## Worked Example: Koko Eating Bananas

Piles of bananas, `h` hours, find the minimum eating speed.

- **Answer range:** `1` to `max(piles)`
- **Feasibility:** `sum(ceil(pile / speed)) <= h`
- **Monotonic?** Yes — a faster speed never takes more hours.

```java
boolean feasible(int[] piles, int speed, int h) {
    long hours = 0;
    for (int p : piles) hours += (p + speed - 1) / speed;   // ceil div
    return hours <= h;
}
```

O(n log(max)) total.

## Worked Example: Split Array Largest Sum

Split into `k` subarrays, minimise the largest subarray sum.

- **Range:** `max(arr)` to `sum(arr)`
- **Feasibility:** greedily pack; count the subarrays needed with cap `mid`; feasible if `count <= k`

## Identifying The Range

| Problem type | lo | hi |
|---|---|---|
| Split into k parts | `max(arr)` | `sum(arr)` |
| Rate / speed | `1` | `max(arr)` |
| Distance / spacing | `1` or `0` | `max − min` |
| Time to complete | `1` | `slowest × total` |

Setting `lo` too high or `hi` too low silently produces a wrong answer — derive both from the problem, don't guess.

## Key Problems

| Problem | Predicate |
|---|---|
| Koko Eating Bananas | hours needed ≤ h |
| Capacity to Ship Packages in D Days | days needed ≤ D |
| Split Array Largest Sum | parts needed ≤ k |
| Minimum Time to Complete Trips | trips done ≥ target |
| Aggressive Cows / Magnetic Force | placements ≥ k |
| Median of Two Sorted Arrays | partition is valid |
| Minimum Speed to Arrive on Time | time ≤ hour |

## Common Questions

- *How do you know it's monotonic?* — state it explicitly: "if speed s works, s+1 also works, because each pile takes no more time."
- *Why binary search instead of DP?* — the answer space is small (log of the range) and feasibility is cheap. DP over the value space would be far slower.

## Common Mistakes

- Not verifying monotonicity — the pattern silently gives wrong answers on non-monotonic predicates
- Wrong initial bounds
- Integer overflow in `feasible` — use `long` for accumulations
- Using the minimise template on a maximise problem, causing an infinite loop

## Related Topics

- [Binary Search Templates](Binary%20Search%20Templates.md)
- [Greedy Algorithms](../Greedy%20and%20Intervals/Greedy%20Algorithms.md)
- [Pattern Confusion Matrix](../Foundations/Pattern%20Confusion%20Matrix.md)

## Revision Summary

"Minimize the maximum" is the tell. Define the answer range, write a boolean feasibility check, confirm monotonicity aloud, then run the lower-bound template.

## Quick Recall

- Search the answer space, not the array
- Must be monotonic — say why
- Minimise: `feasible → hi = mid`
- Maximise: `feasible → lo = mid`, use ceiling mid
- O(n log(range))
