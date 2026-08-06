# Lowest Common Ancestor

## Why It Matters

A staple question with three distinct variants — the interviewer picks based on whether it's a BST, whether parent pointers exist, and whether there are many queries.

## Variant 1: Binary Tree, No Parent Pointers

```java
TreeNode lca(TreeNode root, TreeNode p, TreeNode q) {
    if (root == null || root == p || root == q) return root;
    TreeNode l = lca(root.left, p, q);
    TreeNode r = lca(root.right, p, q);
    if (l != null && r != null) return root;   // split point → this is the LCA
    return l != null ? l : r;
}
```

**Why it works:** if both subtrees return non-null, `p` and `q` are on opposite sides, so `root` is the LCA. Otherwise the answer bubbles up from whichever side found something.

O(n) time, O(h) space.

**Caveat:** this assumes both nodes exist in the tree. If they might not, you need a flagged variant that verifies both were actually found.

## Variant 2: BST

Use the ordering — no full traversal needed:

```java
TreeNode lca(TreeNode root, TreeNode p, TreeNode q) {
    while (root != null) {
        if (p.val < root.val && q.val < root.val) root = root.left;
        else if (p.val > root.val && q.val > root.val) root = root.right;
        else return root;          // split point
    }
    return null;
}
```

O(h) time, O(1) space.

## Variant 3: With Parent Pointers

Reduces to "intersection of two linked lists":

```java
Set<TreeNode> seen = new HashSet<>();
while (p != null) { seen.add(p); p = p.parent; }
while (!seen.contains(q)) q = q.parent;
return q;
```

Or the O(1)-space two-pointer trick: walk both up, switching to the other's start on reaching null — they meet at the LCA.

## Variant 4: Many Queries — Binary Lifting

Preprocess `up[k][v]` = the 2^k-th ancestor of `v`. O(n log n) build, O(log n) per query.

```java
// build
for (int k = 1; k < LOG; k++)
    for (int v = 0; v < n; v++)
        up[k][v] = up[k-1][ up[k-1][v] ];
```

Then lift the deeper node to equal depth, and lift both together while ancestors differ.

Mention this when the interviewer says "millions of queries" — it's the expected senior-level answer.

## Comparison

| Variant | Time | Space | When |
|---|---|---|---|
| Recursive | O(n) | O(h) | General binary tree, single query |
| BST | O(h) | O(1) | BST |
| Parent pointers | O(h) | O(h) or O(1) | Parent links available |
| Binary lifting | O(log n)/query | O(n log n) | Many queries |

## Common Mistakes

- Applying the general recursive solution to a BST and missing the O(h) optimisation
- Assuming both nodes exist when the problem doesn't guarantee it
- Comparing by value instead of reference when duplicates exist
- Forgetting that a node can be its own ancestor (LCA(p, p) = p)

## Related Topics

- [Tree Traversals](Tree%20Traversals.md)
- [Graph Algorithm Selection](../Graphs/Graph%20Algorithm%20Selection.md)

## Revision Summary

Recursive split-point detection for general trees; ordering comparison for BSTs; set-intersection for parent pointers; binary lifting for many queries.

## Quick Recall

- Both subtrees non-null → current node is the LCA
- BST → walk down while both on the same side
- Parent pointers → linked-list intersection
- Many queries → binary lifting, O(log n) each
