# Knapsack Patterns

## Why It Matters

A large share of DP interview problems are knapsack in disguise: "can we reach a target sum", "count the ways", "partition into equal halves", "minimum coins". Recognise the skeleton and the problem is solved.

## Core Idea

You have items with weights (and possibly values) and a capacity. For each item you make a take/skip decision. The state is `(items considered, capacity used)`.

## The Four Variants

| Variant | Item reuse | Inner loop direction (1D) |
|---|---|---|
| 0/1 Knapsack | At most once | **Backward** |
| Unbounded | Unlimited | **Forward** |
| Bounded | At most k times | Binary-split into 0/1 items |
| Multi-dimensional | Two capacity constraints | Two nested capacity loops |

**The loop direction is the entire difference in code.** Backward prevents reusing the item already updated in this pass; forward permits it.

## 0/1 Knapsack

```java
int[] dp = new int[W + 1];
for (int i = 0; i < n; i++)
    for (int w = W; w >= weight[i]; w--)          // BACKWARD
        dp[w] = Math.max(dp[w], value[i] + dp[w - weight[i]]);
return dp[W];
```

## Unbounded Knapsack (Coin Change)

```java
int[] dp = new int[amount + 1];
Arrays.fill(dp, Integer.MAX_VALUE);
dp[0] = 0;
for (int c : coins)
    for (int a = c; a <= amount; a++)             // FORWARD
        if (dp[a - c] != Integer.MAX_VALUE)
            dp[a] = Math.min(dp[a], dp[a - c] + 1);
```

## Counting vs Optimising

Same skeleton, different accumulator:

| Goal | Accumulator | Base |
|---|---|---|
| Max value | `max` | `dp[0] = 0` |
| Min count | `min` | `dp[0] = 0`, rest = ∞ |
| Count ways | `+=` | `dp[0] = 1` |
| Feasibility | `\|=` | `dp[0] = true` |

## Combinations vs Permutations

This trips up almost everyone in Coin Change II vs Combination Sum IV:

```java
// COMBINATIONS (order doesn't matter) — coin loop OUTSIDE
for (int c : coins) for (int a = c; a <= amount; a++) dp[a] += dp[a - c];

// PERMUTATIONS (order matters) — amount loop OUTSIDE
for (int a = 1; a <= amount; a++) for (int c : coins) if (a >= c) dp[a] += dp[a - c];
```

**Rule:** item loop outside → combinations. Capacity loop outside → permutations.

## Partition Equal Subset Sum

Reduces to: is there a subset summing to `total / 2`?

```java
if (total % 2 != 0) return false;
boolean[] dp = new boolean[total / 2 + 1];
dp[0] = true;
for (int num : nums)
    for (int s = total / 2; s >= num; s--)
        dp[s] |= dp[s - num];
return dp[total / 2];
```

## Target Sum (assign + / −)

Let `P` be the positive subset. `P − N = target` and `P + N = total`, so `P = (target + total) / 2`. Now it's a counting subset-sum. Check `(target + total)` is non-negative and even first.

## Key Problems

| Problem | Variant |
|---|---|
| Partition Equal Subset Sum | 0/1, feasibility |
| Target Sum | 0/1, counting (after transform) |
| Last Stone Weight II | 0/1, minimise difference |
| Coin Change | Unbounded, min count |
| Coin Change II | Unbounded, count combinations |
| Combination Sum IV | Unbounded, count permutations |
| Ones and Zeroes | Multi-dimensional 0/1 |
| Perfect Squares | Unbounded, min count |

## Common Mistakes

- Wrong loop direction — the single most common knapsack bug
- Swapping the loop order and getting permutations when you wanted combinations
- Forgetting `dp[0] = 1` for counting problems
- Integer overflow when adding to `Integer.MAX_VALUE` sentinels — guard before adding
- Not checking parity/feasibility before the Target Sum transform

## Related Topics

- [Dynamic Programming Fundamentals](Dynamic%20Programming%20Fundamentals.md)
- [Pattern Confusion Matrix](Pattern%20Confusion%20Matrix.md)

## Revision Summary

Take-or-skip on items with a capacity. Backward loop = each item once; forward = unlimited. Item loop outside = combinations; capacity loop outside = permutations.

## Quick Recall

- 0/1 → `for w = W down to weight[i]`
- Unbounded → `for a = c up to amount`
- Count ways → `dp[0] = 1`, accumulate with `+=`
- Partition → subset sum to `total / 2`
- Target Sum → `P = (target + total) / 2`
