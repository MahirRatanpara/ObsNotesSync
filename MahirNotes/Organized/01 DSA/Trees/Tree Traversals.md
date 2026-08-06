# Tree Traversals

## Why It Matters

Half of all tree problems reduce to "pick the right traversal order". Choosing wrongly makes an easy problem hard.

## Core Idea

| Traversal | Order | Use when |
|---|---|---|
| Preorder | Node, Left, Right | Copying/serialising a tree, top-down state |
| Inorder | Left, Node, Right | **BST → sorted sequence** |
| Postorder | Left, Right, Node | Aggregating from children (heights, sums, deletion) |
| Level-order | BFS by depth | Anything phrased "per level" |

**The decision rule:** does a node need information from its children before it can answer? → postorder. Does it pass information down? → preorder. Is it a BST and you want order? → inorder.

## Recursive Templates

```java
void preorder(TreeNode n)  { if (n == null) return; visit(n); preorder(n.left); preorder(n.right); }
void inorder(TreeNode n)   { if (n == null) return; inorder(n.left); visit(n); inorder(n.right); }
void postorder(TreeNode n) { if (n == null) return; postorder(n.left); postorder(n.right); visit(n); }
```

## Iterative Inorder (asked often)

```java
Deque<TreeNode> st = new ArrayDeque<>();
TreeNode cur = root;
while (cur != null || !st.isEmpty()) {
    while (cur != null) { st.push(cur); cur = cur.left; }
    cur = st.pop();
    visit(cur);
    cur = cur.right;
}
```

## Level Order with Boundaries

```java
Deque<TreeNode> q = new ArrayDeque<>();
q.offer(root);
while (!q.isEmpty()) {
    int sz = q.size();                     // freeze — this is the level
    List<Integer> level = new ArrayList<>();
    for (int i = 0; i < sz; i++) {
        TreeNode n = q.poll();
        level.add(n.val);
        if (n.left != null) q.offer(n.left);
        if (n.right != null) q.offer(n.right);
    }
    res.add(level);
}
```

## The Postorder Aggregation Pattern

Most "hard" tree problems are this shape — return one thing, track another globally:

```java
int best = Integer.MIN_VALUE;

int gain(TreeNode n) {            // returns: best path going DOWN from n
    if (n == null) return 0;
    int l = Math.max(gain(n.left), 0);    // clamp negatives to 0
    int r = Math.max(gain(n.right), 0);
    best = Math.max(best, n.val + l + r); // path THROUGH n — global answer
    return n.val + Math.max(l, r);        // only one branch can go up
}
```

This exact skeleton solves Binary Tree Maximum Path Sum, Diameter of Binary Tree, and Longest Univalue Path. **Memorise the split between "what I return" and "what I record".**

## BST Property

Inorder traversal of a valid BST is strictly increasing. Validation must pass down a `(min, max)` range — comparing only against the immediate parent is the classic wrong answer:

```java
boolean valid(TreeNode n, long lo, long hi) {
    if (n == null) return true;
    if (n.val <= lo || n.val >= hi) return false;
    return valid(n.left, lo, n.val) && valid(n.right, n.val, hi);
}
```

## Key Problems

| Problem | Traversal |
|---|---|
| Maximum Depth | Postorder |
| Diameter of Binary Tree | Postorder aggregation |
| Binary Tree Maximum Path Sum | Postorder aggregation |
| Validate BST | Inorder or range-passing preorder |
| Kth Smallest in BST | Inorder with counter |
| Level Order / Zigzag | BFS |
| Right Side View | BFS, last of each level |
| Lowest Common Ancestor | Postorder |
| Serialize/Deserialize | Preorder with null markers |
| Construct from Preorder + Inorder | Preorder index + inorder map |

## Common Mistakes

- Validating a BST against the parent only, instead of a range
- Integer overflow in BST validation — use `long` bounds
- Forgetting to clamp negative gains to 0 in path-sum problems
- Not freezing `q.size()` when levels matter
- Recursion depth on skewed trees (n up to 10⁵)

## Related Topics

- [Lowest Common Ancestor](Lowest%20Common%20Ancestor.md)
- [BFS and DFS](../Graphs/BFS%20and%20DFS.md)
- [Dynamic Programming Fundamentals](../Dynamic%20Programming/Dynamic%20Programming%20Fundamentals.md)

## Revision Summary

Pick the traversal from the data flow direction. Postorder aggregation with a global accumulator solves most hard tree problems.

## Quick Recall

- Inorder on BST → sorted
- Children-first → postorder
- "per level" → BFS with frozen size
- Return one value, record another globally
- BST validation needs a range, not a parent check
