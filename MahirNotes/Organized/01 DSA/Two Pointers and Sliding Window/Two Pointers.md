# Two Pointers

## Why It Matters

Converts an O(n²) nested-loop scan into O(n) whenever the data is sorted or can be sorted. Appears in almost every interview loop.

## Core Idea

Maintain two indices and move them based on a comparison, so each element is visited a bounded number of times. Two shapes:

- **Converging** — `left` at start, `right` at end, move inward
- **Same-direction** — `slow` and `fast` both move forward at different rates

## Recognition

- Array is sorted, or sorting doesn't break the problem
- Looking for a pair/triplet with a target property
- In-place removal, partitioning, or reversal
- Palindrome checks

## Templates

**Converging (sorted array, find pair summing to target):**
```java
int l = 0, r = arr.length - 1;
while (l < r) {
    int sum = arr[l] + arr[r];
    if (sum == target) return new int[]{l, r};
    if (sum < target) l++;      // need bigger
    else r--;                   // need smaller
}
```

**Same-direction (in-place removal):**
```java
int slow = 0;
for (int fast = 0; fast < arr.length; fast++) {
    if (keep(arr[fast])) arr[slow++] = arr[fast];
}
return slow;  // new length
```

**3Sum (sort + fix one + two pointers):**
```java
Arrays.sort(nums);
for (int i = 0; i < nums.length - 2; i++) {
    if (i > 0 && nums[i] == nums[i-1]) continue;   // skip dup anchor
    int l = i + 1, r = nums.length - 1;
    while (l < r) {
        int sum = nums[i] + nums[l] + nums[r];
        if (sum == 0) {
            res.add(List.of(nums[i], nums[l], nums[r]));
            while (l < r && nums[l] == nums[l+1]) l++;   // skip dups
            while (l < r && nums[r] == nums[r-1]) r--;
            l++; r--;
        } else if (sum < 0) l++;
        else r--;
    }
}
```

## Why Moving Inward Is Correct

At `(l, r)` with `sum < target`: every pair `(l, k)` for `k < r` has an even smaller sum, so `l` can never be part of a valid pair with anything to the left of `r`. Discarding `l` is safe. This is the proof to state aloud.

## Key Problems

| Problem | Variant |
|---|---|
| Two Sum II (sorted) | Converging |
| 3Sum / 4Sum | Sort + fix + converge |
| Container With Most Water | Converging, greedy on height |
| Trapping Rain Water | Converging with running maxima |
| Valid Palindrome | Converging |
| Remove Duplicates from Sorted Array | Same-direction |
| Sort Colors (Dutch flag) | Three pointers |
| Move Zeroes | Same-direction |

## Advantages

- O(n) after sorting, O(1) extra space
- Simple to reason about and to prove correct

## Limitations

- Usually requires sorted input — the O(n log n) sort may dominate
- Sorting destroys original indices; if the answer needs indices, use a hash map instead

## Tradeoffs

| | Two Pointers | Hash Map |
|---|---|---|
| Time | O(n log n) with sort | O(n) |
| Space | O(1) | O(n) |
| Preserves indices | No | Yes |

## Common Questions

- *Why is it safe to move the smaller pointer?* — see the proof above.
- *How do you avoid duplicate triplets?* — skip equal values at the anchor and after each match.
- *Container With Most Water: why move the shorter line?* — area is bounded by the shorter side; moving the taller one can never increase area, so moving the shorter is the only move that can improve.

## Common Mistakes

- Forgetting duplicate-skipping in 3Sum, producing repeated triplets
- Using `l <= r` when the pair must be distinct (causes an element to pair with itself)
- Integer overflow on `arr[l] + arr[r]` with large values — use `long`

## Related Topics

- [Sliding Window](Sliding%20Window.md)
- [Fast and Slow Pointers](../Linked%20List/Fast%20and%20Slow%20Pointers.md)
- [Pattern Confusion Matrix](../Foundations/Pattern%20Confusion%20Matrix.md)

## Revision Summary

Sorted data plus a pair-finding goal means two pointers. The correctness argument is always "moving this pointer can only make things worse, so discard it."

## Quick Recall

- Converging: sum too small → `l++`; too big → `r--`
- 3Sum = sort + fix i + converge, skip dups twice
- Container: always move the shorter line
- Same-direction pointer = in-place filter
