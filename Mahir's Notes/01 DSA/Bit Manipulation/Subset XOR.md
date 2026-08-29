# Subset XOR Sum — Quick Notes

  

## 1. Recursive / Take-Skip

  

```java

public int solve(int[] nums, int i, int xor) {

if (i >= nums.length) return xor;

  

int take = solve(nums, i + 1, nums[i] ^ xor);

int skip = solve(nums, i + 1, xor);

  

return take + skip;

}

```

  

### Idea

For every element there are 2 choices:

  

- **Take** → `xor ^ nums[i]`

- **Skip** → XOR unchanged

  

So for `n` elements:

  

```text

2 choices × 2 choices × ... = 2^n subsets

```

  

The recursion tree has one leaf per subset.

  

### Complexity

- Time: **O(2^n)**

- Space: **O(n)** recursion stack

  

---

  

## 2. Bitmasking

  

```java

int total = (1 << n) - 1;

  

for (int mask = 0; mask <= total; mask++) {

int xor = 0;

  

for (int i = 0; i < n; i++) {

if ((mask & (1 << i)) != 0) {

xor ^= nums[i];

}

}

  

sum += xor;

}

```

  

### Idea

Represent each subset using `n` bits:

  

```text

0 = Skip

1 = Take

```

  

Example:

  

```text

nums = [1, 3, 5]

mask = 101

  

→ take 1

→ skip 3

→ take 5

  

subset = [1, 5]

```

  

`(1 << n) - 1` gives the largest `n`-bit mask, so masks `0 ... 2^n - 1` represent all subsets.

  

### Complexity

- Time: **O(n × 2^n)**

- Space: **O(1)**

  

---

  

## Key Connection

  

```text

Recursion Bitmask

  

Take ↔ 1

Skip ↔ 0

  

Binary decision tree ↔ Binary number

```

  

Both enumerate the same `2^n` subsets.

  

---

  

## 3. Mathematical Optimization

  

For this specific problem:

  

```text

answer = (OR of all elements) × 2^(n-1)

```

  

Example:

  

```text

nums = [1, 3, 5]

  

1 | 3 | 5 = 7

2^(3-1) = 4

  

answer = 7 × 4 = 28

```

  

### Why?

For every bit that appears in at least one number, that bit is set in the XOR of exactly half of all subsets.

  

### Complexity

- Time: **O(n)**

- Space: **O(1)**

  

---

  

## Interview Takeaway

  

Think:

  

```text

Subset problem

↓

Every element → Take / Skip

↓

2^n subsets

↓

Can represent choices using bitmask

```

  

For **Subset XOR Sum**, know all three approaches, but the recursive Take/Skip solution is the simplest to explain.