# Subset XOR Sum — Notes

**Problem:** Given an array `nums`, find the XOR of every possible subset, then sum all those XOR values.

---

## Approach 1: Recursion (Take / Skip)

```java
class Solution {
    public int subsetXORSum(int[] nums) {
        return solve(nums, 0, 0);
    }

    public int solve(int[] nums, int i, int Xor) {
        if (i >= nums.length) return Xor;

        int take = solve(nums, i + 1, nums[i] ^ Xor);
        int skip = solve(nums, i + 1, Xor);

        return take + skip;
    }
}
```

### How it works

- At every index `i`, there are only two choices: **take** `nums[i]` into the current XOR, or **skip** it.
- `Xor` is carried forward as a parameter — it's the running XOR of everything chosen so far on this path.
- **Base case:** when `i` reaches the end of the array, the current `Xor` value represents one complete subset. Return it.
- Every leaf of the recursion tree corresponds to exactly one subset. Summing all leaves = summing all subset XORs.

### Complexity

- **Time: O(2^n)** Two branches per call, depth `n` → `2^n` leaf nodes. Each node does O(1) work (a single XOR).
- **Space: O(n)** Recursion stack depth = array length.

---

## Approach 2: Bitmasking (Iterative)

```java
class Solution {
    public int subsetXORSum(int[] nums) {
        int n = nums.length;
        int total = (1 << n) - 1;

        int sum = 0;
        for (int bit = 0; bit <= total; bit++) {
            int xor = 0;
            for (int i = 0; i < n; i++) {
                if ((bit & (1 << i)) != 0) {
                    xor ^= nums[i];
                }
            }
            sum += xor;
        }

        return sum;
    }
}
```

### How it works

- Every subset of an `n`-element array can be represented as a number from `0` to `2^n - 1`.
- Bit `i` of that number tells you whether `nums[i]` belongs to this subset (1 = included, 0 = excluded).
- **Outer loop:** iterates through all `2^n` possible subsets (masks).
- **Inner loop:** checks each of the `n` bits and XORs in the matching element if the bit is set.

### Complexity

- **Time: O(n × 2^n)** `2^n` masks, each requiring an O(n) scan to rebuild its XOR from scratch.
- **Space: O(1)** extra.

---

## Head-to-Head Comparison

||Approach 1 (Recursion)|Approach 2 (Bitmask)|
|---|---|---|
|Time|O(2^n)|O(n × 2^n)|
|Space|O(n)|O(1)|
|Core idea|XOR carried incrementally|XOR rebuilt from scratch each time|

**Approach 1 wins on time.** Approach 2 does redundant work — it recomputes the XOR from zero for every single mask instead of reusing what's already known. There's no scenario where Approach 2 is the better choice between these two.

---

## The O(n) Solution (the one that actually matters)

Both approaches above are brute force. There's a linear-time solution based on a bit-level observation, and in an interview setting, this is what separates a pass from a strong pass.

### The insight

For each bit position, ask: **does _any_ number in the array have that bit set?**

- **If yes:** exactly half of all `2^n` subsets will end up with an _odd_ count of elements carrying that bit. An odd count means the bit survives the XOR. So that bit is set in exactly `2^(n-1)` of the subset XOR results.
- **If no number has that bit set:** it can never appear in any subset's XOR — contributes nothing.

So instead of tracking subsets at all, just:

1. OR together all numbers in the array → this tells you which bits are "active" (present in at least one number).
2. Multiply by `2^(n-1)` (equivalent to left-shifting by `n - 1`) → this accounts for how many subsets each active bit shows up in.

### Code

```java
class Solution {
    public int subsetXORSum(int[] nums) {
        int orAll = 0;
        for (int num : nums) orAll |= num;
        return orAll << (nums.length - 1);
    }
}
```

### Complexity

- **Time: O(n)**
- **Space: O(1)**

---

## Takeaway for Interviews

- Lead with the **take/skip recursion** — it demonstrates you understand subset generation cleanly.
- Skip the bitmask iterative version as your "backup" solution — it's strictly worse than recursion (same subsets, extra recomputation cost) and doesn't teach the interviewer anything new about your thinking.
- Follow up with the **O(n) OR-trick** to show you can push past brute force. This is very likely what a strong interviewer is fishing for, since the problem has a well-known bit-manipulation shortcut.