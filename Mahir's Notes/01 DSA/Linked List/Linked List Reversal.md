# Linked List Reversal

## Why It Matters

A building block inside many harder problems (palindrome check, reorder list, k-group reversal). Pointer manipulation errors are extremely visible in an interview.

## Full Reversal — Iterative

```java
ListNode prev = null, cur = head;
while (cur != null) {
    ListNode next = cur.next;   // 1. save
    cur.next = prev;            // 2. flip
    prev = cur;                 // 3. advance prev
    cur = next;                 // 4. advance cur
}
return prev;
```

The four-line body in that exact order. Say the steps aloud as you write them — save, flip, advance, advance.

## Recursive

```java
ListNode reverse(ListNode head) {
    if (head == null || head.next == null) return head;
    ListNode newHead = reverse(head.next);
    head.next.next = head;    // the node ahead now points back
    head.next = null;         // sever the old forward link
    return newHead;
}
```

O(n) stack space — mention this trade-off.

## Reverse a Sublist (positions m..n)

Use a dummy node so that reversing from position 1 needs no special case:

```java
ListNode dummy = new ListNode(0, head);
ListNode prev = dummy;
for (int i = 1; i < m; i++) prev = prev.next;

ListNode cur = prev.next;
for (int i = 0; i < n - m; i++) {          // head-insertion
    ListNode moved = cur.next;
    cur.next = moved.next;
    moved.next = prev.next;
    prev.next = moved;
}
return dummy.next;
```

This "pull the next node to the front of the segment" idiom is cleaner than reversing and re-stitching.

## Reverse in K-Groups

```java
ListNode reverseKGroup(ListNode head, int k) {
    ListNode node = head;
    for (int i = 0; i < k; i++) {           // verify k nodes exist
        if (node == null) return head;      // fewer than k → leave as is
        node = node.next;
    }
    ListNode newHead = reverseFirstK(head, k);
    head.next = reverseKGroup(node, k);     // head is now the group tail
    return newHead;
}
```

**Check the group is full before reversing** — the common bug is reversing a trailing partial group.

## Always Use A Dummy Node

Any problem that may modify the head benefits from `ListNode dummy = new ListNode(0, head)`. It eliminates every "what if it's the first node" branch. Return `dummy.next`.

## Key Problems

| Problem | Technique |
|---|---|
| Reverse Linked List | Iterative or recursive |
| Reverse Linked List II | Head insertion with dummy |
| Reverse Nodes in k-Group | Count then reverse |
| Palindrome Linked List | Midpoint + reverse second half |
| Reorder List | Midpoint + reverse + interleave |
| Swap Nodes in Pairs | k-group with k=2 |
| Rotate List | Close into a ring, then break |

## Common Mistakes

- Losing the rest of the list by flipping before saving `next`
- Not using a dummy node, then mishandling head removal
- In k-group, reversing a final partial group when the problem says not to
- Creating a cycle by forgetting `head.next = null` in the recursive version

## Related Topics

- [Fast and Slow Pointers](Fast%20and%20Slow%20Pointers.md)

## Revision Summary

Save, flip, advance, advance. Dummy node for anything touching the head. Head-insertion for sublists. Verify group size before k-group reversal.

## Quick Recall

- `next = cur.next; cur.next = prev; prev = cur; cur = next;`
- Return `prev` (the new head)
- Dummy node removes all head edge cases
- Recursive costs O(n) stack
