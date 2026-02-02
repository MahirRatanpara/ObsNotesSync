
# 📌 Rolling Hash – Detailed Notes

## 🔹 What is Rolling Hash?
Rolling Hash is a hashing technique that allows efficient computation of substring hashes in O(1) time after preprocessing.

---

## 🔹 Why Use Rolling Hash?
- Fast substring comparison
- Pattern matching (Rabin–Karp)
- Palindrome detection
- Longest common substring
- Competitive programming

---

## 🔹 Core Idea
Treat a string as a number in a base system.

Example:
abc → a·base² + b·base¹ + c·base⁰

---

## 🔹 Hash Formula
hash(s) = (s[0]·base^(n-1) + s[1]·base^(n-2) + ... ) mod M

---

## 🔹 Prefix Hashing
prefix[i] = hash of s[0..i]

prefix[i] = (prefix[i-1] * base + value(s[i])) mod M

---

## 🔹 Substring Hash in O(1)
hash(l, r) = prefix[r] − prefix[l−1] * base^(r−l+1)

---

## 🔹 Precomputation
- Prefix hash array
- Power array

---

## 🔹 Sliding Window Update
new_hash = (old_hash − leading_char * base^(k−1)) * base + trailing_char

---

## 🔹 Rabin–Karp Algorithm
1. Hash pattern
2. Rolling hash over text
3. Compare hashes
4. Verify on match

---

## 🔹 Hash Collisions
Two different strings may have the same hash.

### Reduce collisions:
- Large prime modulus
- Random base
- Double hashing

---

## 🔹 Double Hashing
Use two (base, mod) pairs.
Compare both hashes.

---

## 🔹 Common Parameters
| Parameter | Value |
|---------|-------|
| base | 31, 53 |
| mod | 1e9+7 |
| mapping | a → 1 |

---

## 🔹 Complexity
- Preprocessing: O(n)
- Substring hash: O(1)
- Space: O(n)

---

## 🔹 Summary
Rolling Hash enables fast string comparison using prefix hashes and base powers.
