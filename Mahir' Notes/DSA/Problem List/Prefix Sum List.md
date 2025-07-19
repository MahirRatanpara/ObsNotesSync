# Prefix Sum | Summary with Practice Questions (1D & 2D)

*Source: Amit Maity — Prefix Sum summary on Medium* ([medium.com](https://medium.com/%40maityamit/prefix-sum-summary-with-practice-questions-sheet-1d-2d-on-leetcode-83c8deb4f713?utm_source=chatgpt.com))

---

## 🧠 1D Prefix Sums

### Warm‑up
- [x] [Running Sum of 1d Array](https://leetcode.com/problems/running-sum-of-1d-array/)  
- [x] [Find the Highest Altitude](https://leetcode.com/problems/find-the-highest-altitude/)  
- [x] [Find the Middle Index in Array](https://leetcode.com/problems/find-the-middle-index-in-array/)  
- [x] Codeforces 327A (not LeetCode)

### Core Concept
Use a prefix array to compute range-sum queries in O(1).

```cpp
prefix[i] = sum(arr[0] … arr[i]);
sum[L..R] = prefix[R] - (L > 0 ? prefix[L - 1] : 0);
```

## **NOTE**: if we require only one value of prefix at a time (not the range), we can use only variable to calculate the prefix sum, Similar if you want suffix, precalculated the sum and keep on subtracting the values as we go

### Practice Questions
- [x] [Range Sum Query ‑ Immutable](https://leetcode.com/problems/range-sum-query-immutable/)  
- [x] [Number of Ways to Split Array](https://leetcode.com/problems/number-of-ways-to-split-array/)  
- [x] [Corporate Flight Bookings](https://leetcode.com/problems/corporate-flight-bookings/)  
- [x] [Product of Array Except Self](https://leetcode.com/problems/product-of-array-except-self/)  
- [x] [Number of Sub-arrays with Odd Sum](https://leetcode.com/problems/number-of-sub-arrays-with-odd-sum/)  
- [ ] [Contiguous Array](https://leetcode.com/problems/contiguous-array/)

### Extra Practice (Not mandatory)
- [ ]  Yosupo static_range_sum  
- [ ] USACO problems (cpid 572, 595)  
- [ ] SPOJ RANGESUM

### Prefix Sum + Hashmap
- [ ]  CSES 1660 & 1661  
- [ ]  Codeforces 1398C  
- [ ]  [Find the Longest Substring Containing Vowels in Even Counts](https://leetcode.com/problems/find-the-longest-substring-containing-vowels-in-even-counts/)

---

## 💠 2D Prefix Sums

### Warm‑up
- [ ] CSES 1652  
- [] [ ][Range Sum Query 2D ‑ Immutable](https://leetcode.com/problems/range-sum-query-2d-immutable/)

### Building 2D Prefix Grid
```cpp
prefix[i][j] = prefix[i][j-1] + prefix[i-1][j]
               - prefix[i-1][j-1] + grid[i-1][j-1];
```

### Querying Submatrix Sum
```cpp
sum = prefix[r2][c2]
    - prefix[r1-1][c2]
    - prefix[r2][c1-1]
    + prefix[r1-1][c1-1];
```

### Practice Question
- [ ] [Matrix Block Sum](https://leetcode.com/problems/matrix-block-sum/)

---

## ✅ Summary of LeetCode Problems with Links

### 1D Problems
- [ ] https://leetcode.com/problems/running-sum-of-1d-array/  
- [ ] https://leetcode.com/problems/find-the-highest-altitude/  
- [ ] https://leetcode.com/problems/find-the-middle-index-in-array/  
- [ ] https://leetcode.com/problems/range-sum-query-immutable/  
- [ ] https://leetcode.com/problems/number-of-ways-to-split-array/  
- [ ] https://leetcode.com/problems/corporate-flight-bookings/  
- [ ] https://leetcode.com/problems/product-of-array-except-self/  
- [ ] https://leetcode.com/problems/number-of-sub-arrays-with-odd-sum/  
- [ ] https://leetcode.com/problems/contiguous-array/  
- [ ] https://leetcode.com/problems/find-the-longest-substring-containing-vowels-in-even-counts/

### 2D Problems
- [ ] https://leetcode.com/problems/range-sum-query-2d-immutable/  
- [ ] https://leetcode.com/problems/matrix-block-sum/

---

## 📌 Obsidian Tags
```yaml
tags:
  - [ ] prefix-sum
  - [ ] leetcode
  - [ ] algorithms
  - [ ] practice
```
