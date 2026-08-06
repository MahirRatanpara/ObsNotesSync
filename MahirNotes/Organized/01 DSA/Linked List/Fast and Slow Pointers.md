# Fast and Slow Pointers

## Why It Matters

Solves cycle detection, midpoint finding, and nth-from-end in O(1) space where the naive approach needs a hash set or two passes.

## Core Idea

Two pointers advancing at different rates. If a cycle exists, the fast pointer laps the slow one and they meet. If not, fast reaches the end first.

## Cycle Detection (Floyd's Tortoise and Hare)

```java
ListNode slow = head, fast = head;
while (fast != null && fast.next != null) {
    slow = slow.next;
    fast = fast.next.next;
    if (slow == fast) return true;
}
return false;
```

## Finding The Cycle Start — The Proof

After they meet, reset one pointer to head and advance both one step at a time. They meet at the cycle entrance.

**Why:** let `a` = distance from head to cycle start, `b` = distance from cycle start to meeting point, `c` = remaining cycle length. Fast travelled `a + b + k·(b+c)`; slow travelled `a + b`. Since fast went exactly twice as far:

```
2(a + b) = a + b + k(b + c)
      a + b = k(b + c)
          a = k(b + c) - b = (k-1)(b+c) + c
```

So `a ≡ c` modulo the cycle length — walking `a` from the head and `c` from the meeting point lands on the same node.

**State this proof.** It's the difference between memorising and understanding, and interviewers probe it.

```java
slow = head;
while (slow != fast) { slow = slow.next; fast = fast.next; }
return slow;   // cycle entrance
```

## Middle of a List

```java
ListNode slow = head, fast = head;
while (fast != null && fast.next != null) { slow = slow.next; fast = fast.next.next; }
return slow;   // second middle for even length
```

For the *first* middle on even lengths, start `fast = head.next`.

## Nth Node From End

```java
ListNode fast = head;
for (int i = 0; i < n; i++) fast = fast.next;
if (fast == null) return head.next;        // removing the head
ListNode slow = head;
while (fast.next != null) { slow = slow.next; fast = fast.next; }
slow.next = slow.next.next;
```

Use a dummy node to avoid the head special case.

## Beyond Linked Lists

The technique works on any **functional graph** (each node has exactly one successor):

- **Find the Duplicate Number** — treat `nums[i]` as a pointer to index `nums[i]`; the duplicate is the cycle entrance. O(n) time, O(1) space, without modifying the array.
- **Happy Number** — digit-square-sum is the successor function; a cycle means not happy.

Recognising this generalisation is a strong signal.

## Key Problems

| Problem | Use |
|---|---|
| Linked List Cycle I / II | Detection / entrance |
| Middle of the Linked List | Midpoint |
| Remove Nth Node From End | Gap of n |
| Palindrome Linked List | Midpoint + reverse half |
| Reorder List | Midpoint + reverse + merge |
| Find the Duplicate Number | Cycle in a functional graph |
| Happy Number | Cycle in digit transforms |

## Common Mistakes

- Not null-checking `fast.next` before `fast.next.next`
- Off-by-one on which middle you get for even-length lists
- Forgetting the dummy node when the head may be removed
- Not restoring the list after reversing half of it (for palindrome checks) when the caller expects it intact

## Related Topics

- [Linked List Reversal](Linked%20List%20Reversal.md)
- [Two Pointers](../Two%20Pointers%20and%20Sliding%20Window/Two%20Pointers.md)

## Revision Summary

Slow +1, fast +2. Meeting means a cycle. Reset one to head and step both to find the entrance. Generalises to any functional graph.

## Quick Recall

- `while (fast != null && fast.next != null)`
- Cycle start: reset slow to head, step both by 1
- Midpoint: slow ends at the middle
- Nth from end: gap of n, then walk together
- Duplicate Number = cycle entrance
