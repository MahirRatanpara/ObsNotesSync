#### Metadata

timestamp: **12:04**  &emsp;  **14-08-2021**
topic tags: #dp
question link: https://leetcode.com/problems/unique-binary-search-trees/
resource: https://leetcode.com/problems/unique-binary-search-trees/discuss/31666/DP-Solution-in-6-lines-with-explanation.-F(i-n)-G(i-1)-*-G(n-i)
parent link: [[1. DP GUIDE]]

---

# Unique Binary Search Trees

### Question
Given an integer `n`, return _the number of structurally unique **BST'**s (binary search trees) which has exactly_ `n` _nodes of unique values from_ `1` _to_ `n`.

>**Example 1:**
![](https://assets.leetcode.com/uploads/2021/01/18/uniquebstn3.jpg)
**Input:** n = 3
**Output:** 5


---


### Approach

Given a sequence 1…n, to construct a Binary Search Tree (BST) out of the sequence, we could enumerate each number i in the sequence, and use the number as the root, naturally, the subsequence 1…(i-1) on its left side would lay on the left branch of the root, and similarly the right subsequence (i+1)…n lay on the right branch of the root. We then can construct the subtree from the subsequence recursively. Through the above approach, we could ensure that the BST that we construct are all unique, since they have unique roots.

The problem is to calculate the number of unique BST. To do so, we need to define two functions:

`G(n)`: the number of unique BST for a sequence of length n.

`F(i, n), 1 <= i <= n`: the number of unique BST, where the number i is the root of BST, and the sequence ranges from 1 to n.

As one can see, `G(n)` is the actual function we need to calculate in order to solve the problem. And `G(n)` can be derived from `F(i, n)`, which at the end, would recursively refer to `G(n)`.

First of all, given the above definitions, we can see that the total number of unique BST `G(n)`, is the sum of BST `F(i)` using each number i as a root.  
_i.e._

```
G(n) = F(1, n) + F(2, n) + ... + F(n, n). 
```

Particularly, the bottom cases, there is only one combination to construct a BST out of a sequence of length 1 (only a root) or 0 (empty tree).  
_i.e._

```
G(0)=1, G(1)=1. 
```

Given a sequence 1…n, we pick a number i out of the sequence as the root, then the number of unique BST with the specified root `F(i)`, is the cartesian product of the number of BST for its left and right subtrees. For example, `F(3, 7)`: the number of unique BST tree with number 3 as its root. To construct an unique BST out of the entire sequence [1, 2, 3, 4, 5, 6, 7] with 3 as the root, which is to say, we need to construct an unique BST out of its left subsequence [1, 2] and another BST out of the right subsequence [4, 5, 6, 7], and then combine them together (_i.e._ cartesian product). The tricky part is that we could consider the number of unique BST out of sequence [1,2] as `G(2)`, and the number of of unique BST out of sequence [4, 5, 6, 7] as `G(4)`. Therefore, `F(3,7) = G(2) * G(4)`.

_i.e._

```
F(i, n) = G(i-1) * G(n-i)	1 <= i <= n 
```

Combining the above two formulas, we obtain the recursive formula for `G(n)`. _i.e._

```
G(n) = G(0) * G(n-1) + G(1) * G(n-2) + … + G(n-1) * G(0) 
```

In terms of calculation, we need to start with the lower number, since the value of `G(n)` depends on the values of `G(0) … G(n-1)`.

#### Complexity Analysis
- Time: O(n^2)
- Space: O(n)

#### Code

``` cpp
class Solution {
public:
    int numTrees(int n) {
        vector<int> dp(n+1, 0);
        
        dp[0] = dp[1] = 1;
        for(int i = 2; i <= n; i++){
            for(int j = 1; j <= i; j++)
                dp[i] += dp[j-1]*dp[i-j];
        }
        
        return dp[n];
    }
};

```

---

#### Generate All unique BST

``` cpp
vector<TreeNode*> solve(int l, int r) {
    if(l > r) return vector<TreeNode*>{NULL};
    vector<TreeNode*> res;
    for(int root = l; root <= r; root++) {
        vector<TreeNode*> lefts = solve(l, root - 1);
        vector<TreeNode*> rights = solve(root + 1, r);
        for(TreeNode* left : lefts) {
            for(TreeNode* right : rights) {
                TreeNode* rootNode = new TreeNode(root);
                rootNode -> left = left;
                rootNode -> right = right;
                res.push_back(rootNode);
            }
        }
    }
    return res;
}

vector<TreeNode*> Solution::generateTrees(int A) {
    return solve(1, A);
}

```
