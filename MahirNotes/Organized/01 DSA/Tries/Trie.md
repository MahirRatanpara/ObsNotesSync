# Trie (Prefix Tree)

## Why It Matters

The only structure that makes prefix queries O(L) regardless of dictionary size. Required for autocomplete, word-search-on-grid, and XOR-maximisation problems.

## Core Idea

A tree where each edge is a character. A path from the root spells a prefix. Nodes carry a terminal flag marking complete words.

```java
class TrieNode {
    TrieNode[] children = new TrieNode[26];
    boolean isWord;
}

void insert(String w) {
    TrieNode cur = root;
    for (char c : w.toCharArray()) {
        int i = c - 'a';
        if (cur.children[i] == null) cur.children[i] = new TrieNode();
        cur = cur.children[i];
    }
    cur.isWord = true;
}

boolean search(String w, boolean prefixOnly) {
    TrieNode cur = root;
    for (char c : w.toCharArray()) {
        cur = cur.children[c - 'a'];
        if (cur == null) return false;
    }
    return prefixOnly || cur.isWord;
}
```

Array children for a fixed alphabet (fast); `HashMap<Character, TrieNode>` for large or unknown alphabets (memory-efficient).

## Complexity

| Operation | Time | Space |
|---|---|---|
| Insert | O(L) | O(L) new nodes worst case |
| Search / startsWith | O(L) | O(1) |
| Total structure | — | O(A · N · L) worst case |

Independent of the number of stored words — that's the whole point versus a hash set.

## Trie vs Hash Set

| | Trie | Hash Set |
|---|---|---|
| Exact lookup | O(L) | O(L) hash |
| **Prefix query** | **O(L)** | O(n · L) scan |
| Sorted iteration | Yes (DFS) | No |
| Memory | Higher | Lower |
| Longest common prefix | Trivial | O(n · L) |

**Use a trie only when prefixes matter.** For pure membership, a hash set wins.

## Wildcard Search

Support `.` matching any character by branching at wildcards:

```java
boolean search(String w, int i, TrieNode node) {
    if (node == null) return false;
    if (i == w.length()) return node.isWord;
    char c = w.charAt(i);
    if (c == '.') {
        for (TrieNode child : node.children)
            if (search(w, i + 1, child)) return true;
        return false;
    }
    return search(w, i + 1, node.children[c - 'a']);
}
```

## Word Search II — The Key Optimisation

Building a trie of all words and DFS-ing the grid once beats running Word Search per word.

Two optimisations interviewers look for:
1. **Store the word itself** on the terminal node so you don't rebuild strings
2. **Prune** — after finding a word, null out the terminal marker; delete leaf nodes so exhausted branches stop being explored

Without pruning this times out on large inputs.

## Bit Trie (XOR Problems)

For "maximum XOR of two numbers", build a binary trie over the 32 bits, most significant first. Then greedily walk the *opposite* bit at each level to maximise the XOR.

```java
for (int b = 31; b >= 0; b--) {
    int bit = (num >> b) & 1;
    if (node.children[1 - bit] != null) { best |= (1 << b); node = node.children[1 - bit]; }
    else node = node.children[bit];
}
```

## Key Problems

| Problem | Variant |
|---|---|
| Implement Trie | Basic |
| Design Add and Search Words | Wildcard |
| Word Search II | Trie + grid DFS + pruning |
| Replace Words | Shortest-prefix lookup |
| Maximum XOR of Two Numbers | Bit trie |
| Longest Word in Dictionary | DFS with terminal-only path |
| Search Suggestions System | Trie DFS or sort + binary search |

## Common Mistakes

- Using a trie for problems with no prefix requirement — wasted memory
- Not pruning in Word Search II
- Forgetting the terminal flag, so prefixes are reported as words
- Fixed 26-slot arrays when the alphabet is Unicode or large

## Related Topics

- [Bit Manipulation](../Bit%20Manipulation/Bit%20Manipulation.md)
- [Backtracking](../Backtracking/Backtracking.md)

## Revision Summary

Trie when prefixes matter. O(L) per operation regardless of dictionary size. Word Search II needs pruning. Bit tries solve XOR maximisation greedily.

## Quick Recall

- "prefix", "autocomplete", "dictionary" → trie
- O(L) insert and search
- Store the word on the terminal node for grid search
- Prune exhausted branches
- XOR max → binary trie, walk the opposite bit
