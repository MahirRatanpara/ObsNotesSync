# Bit Manipulation

## Why It Matters

Appears in XOR puzzles, subset enumeration, and bitmask DP. Also the basis for space-efficient state representation.

## Essential Operations

| Goal                 | Expression                    |
| -------------------- | ----------------------------- |
| Get bit i            | `(x >> i) & 1`                |
| Set bit i            | `x \| (1 << i)`               |
| Clear bit i          | `x & ~(1 << i)`               |
| Toggle bit i         | `x ^ (1 << i)`                |
| Lowest set bit       | `x & -x`                      |
| Clear lowest set bit | `x & (x - 1)`                 |
| Is power of two      | `x > 0 && (x & (x - 1)) == 0` |
| Count set bits       | `Integer.bitCount(x)`         |
| All bits below i     | `(1 << i) - 1`                |

## XOR — The Four Properties

```
x ^ x = 0
x ^ 0 = x
XOR is commutative and associative
```

Everything else follows:

- **Single Number** — XOR the whole array; pairs cancel, the loner survives
- **Missing Number** — XOR indices with values; the missing one survives
- **Two Single Numbers** — XOR everything to get `a ^ b`, isolate any set bit with `d = x & -x`, then partition the array by that bit and XOR each group separately
- **Swap without a temp** — `a ^= b; b ^= a; a ^= b;` (a party trick, not production code)

## Subset Enumeration

```java
for (int mask = 0; mask < (1 << n); mask++) {
    for (int i = 0; i < n; i++)
        if ((mask & (1 << i)) != 0) { /* element i is in this subset */ }
}
```

O(2ⁿ · n). Viable for n ≤ 20.

**Enumerate all sub-masks of a mask** (used in set-cover DP):
```java
for (int sub = mask; sub > 0; sub = (sub - 1) & mask) { ... }
```
Total across all masks is O(3ⁿ), not O(4ⁿ) — worth knowing.

## Java Signed-Shift Trap

Java has no unsigned types. `>>` is arithmetic (sign-extending); `>>>` is logical (zero-filling).

```java
-8 >> 1   // -4   sign preserved
-8 >>> 1  // 2147483644   sign bit treated as data
```

For bit counting or hashing over a full 32-bit range, **use `>>>`**. Using `>>` on a negative number in a `while (x != 0)` loop causes an infinite loop.

## Bitmask DP

State compression when n ≤ 20: `dp[mask]` where bit `i` means "element i used".

```java
// Travelling Salesman skeleton
int[][] dp = new int[1 << n][n];
for (int mask = 1; mask < (1 << n); mask++)
    for (int last = 0; last < n; last++) {
        if ((mask & (1 << last)) == 0) continue;
        int prev = mask ^ (1 << last);
        for (int j = 0; j < n; j++)
            if ((prev & (1 << j)) != 0)
                dp[mask][last] = Math.min(dp[mask][last], dp[prev][j] + cost[j][last]);
    }
```

**n ≤ 20 in the constraints is a strong hint that bitmask DP is intended.**

## Key Problems

| Problem | Technique |
|---|---|
| Single Number | XOR all |
| Single Number II | Bit counting mod 3 |
| Single Number III | XOR + isolate a differing bit |
| Missing Number | XOR indices and values |
| Counting Bits | `dp[i] = dp[i >> 1] + (i & 1)` |
| Reverse Bits | Shift and accumulate |
| Sum of Two Integers | XOR = sum without carry, AND << 1 = carry |
| Subsets | Mask enumeration |
| Maximum XOR of Two Numbers | Bit trie |
| Partition to K Equal Sum Subsets | Bitmask DP |

## Common Mistakes

- `>>` instead of `>>>` on negatives, causing infinite loops
- Operator precedence: `&` binds looser than `==`, so `(x & 1) == 1` needs the parentheses
- `1 << i` overflowing for i ≥ 31 — use `1L << i`
- Using bitmask DP when n > 20

## Related Topics

- [Backtracking](Backtracking.md)
- [Dynamic Programming Fundamentals](Dynamic%20Programming%20Fundamentals.md)
- [Trie](Trie.md)

## Revision Summary

`x & (x-1)` clears the lowest set bit; `x & -x` isolates it. XOR cancels pairs. Masks enumerate subsets for n ≤ 20. Use `>>>` in Java.

## Quick Recall

- Power of two: `x & (x-1) == 0`
- Isolate lowest set bit: `x & -x`
- XOR cancels duplicates
- Sub-mask loop: `sub = (sub - 1) & mask`
- n ≤ 20 → bitmask DP
