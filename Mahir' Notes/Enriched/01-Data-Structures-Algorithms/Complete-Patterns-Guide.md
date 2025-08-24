# 🔥 Complete DSA Patterns Guide - All 30+ Patterns

> **Master every pattern that appears in FAANG interviews**

---

## 📊 Pattern Mastery Tracker

### **✅ Completed** | **🔄 In Progress** | **❌ Not Started**

| Pattern | Difficulty | Problems Solved | Status |
|---------|------------|------------------|--------|
| [Two Pointers](#1-two-pointers) | Easy-Medium | 0/8 | ❌ |
| [Fast & Slow Pointers](#2-fast--slow-pointers) | Easy-Medium | 0/6 | ❌ |
| [Sliding Window](#3-sliding-window) | Medium-Hard | 0/9 | ❌ |
| [Merge Intervals](#4-merge-intervals) | Medium | 0/6 | ❌ |
| [Cyclic Sort](#5-cyclic-sort) | Easy-Medium | 0/7 | ❌ |
| [In-place Reversal LinkedList](#6-in-place-reversal-linkedlist) | Easy-Hard | 0/5 | ❌ |
| [Stack](#7-stack) | Easy-Medium | 0/6 | ❌ |
| [Monotonic Stack](#8-monotonic-stack) | Medium-Hard | 0/6 | ❌ |
| [Hash Maps](#9-hash-maps) | Easy | 0/5 | ❌ |
| [Tree BFS](#10-tree-breadth-first-search) | Easy-Medium | 0/9 | ❌ |
| [Tree DFS](#11-tree-depth-first-search) | Easy-Hard | 0/6 | ❌ |
| [Graphs](#12-graphs) | Medium-Hard | 0/4 | ❌ |
| [Island Pattern](#13-island-pattern) | Easy-Medium | 0/6 | ❌ |
| [Two Heaps](#14-two-heaps) | Medium-Hard | 0/4 | ❌ |
| [Subsets](#15-subsets) | Medium-Hard | 0/6 | ❌ |
| [Modified Binary Search](#16-modified-binary-search) | Easy-Hard | 0/15 | ❌ |
| [Bitwise XOR](#17-bitwise-xor) | Easy-Hard | 0/4 | ❌ |
| [Top K Elements](#18-top-k-elements) | Easy-Hard | 0/11 | ❌ |
| [K-way Merge](#19-k-way-merge) | Medium-Hard | 0/5 | ❌ |
| [Greedy Algorithms](#20-greedy-algorithms) | Medium-Hard | 0/6 | ❌ |
| [0/1 Knapsack (DP)](#21-01-knapsack) | Medium-Hard | 0/6 | ❌ |
| [Backtracking](#22-backtracking) | Medium-Hard | 0/5 | ❌ |
| [Trie](#23-trie) | Medium | 0/5 | ❌ |
| [Topological Sort](#24-topological-sort) | Medium-Hard | 0/6 | ❌ |
| [Union Find](#25-union-find) | Medium | 0/4 | ❌ |
| [Ordered Set](#26-ordered-set) | Medium | 0/4 | ❌ |
| [Multi-threading](#27-multi-threading) | Medium | 0/3 | ❌ |

---

## 1. Two Pointers

### 🎯 **Pattern Recognition**
- Array is **sorted** or you need to **find pairs/triplets**
- Looking for **subarray** with specific properties
- Need to **compare elements** from both ends

### 🔑 **Core Template**
```java
public void twoPointers(int[] arr) {
    int left = 0, right = arr.length - 1;
    
    while (left < right) {
        if (condition) {
            // Found solution or adjust
            left++;
        } else if (anotherCondition) {
            right--;
        } else {
            // Process current pair
            left++;
            right--;
        }
    }
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Two Sum](https://leetcode.com/problems/two-sum/)** - Basic pattern #must-do
2. ✅ **[Remove Duplicates from Sorted Array](https://leetcode.com/problems/remove-duplicates-from-sorted-array/)** #easy
3. ✅ **[Squares of Sorted Array](https://leetcode.com/problems/squares-of-a-sorted-array/)** #easy
4. ✅ **[3Sum](https://leetcode.com/problems/3sum/)** - Classic triplet #medium #faang
5. ✅ **[3Sum Closest](https://leetcode.com/problems/3sum-closest/)** #medium
6. ✅ **[Subarray Product Less Than K](https://leetcode.com/problems/subarray-product-less-than-k/)** #medium
7. ⭐ **[4Sum](https://leetcode.com/problems/4sum/)** - Challenge #medium
8. ⭐ **[Backspace String Compare](https://leetcode.com/problems/backspace-string-compare/)** #medium

### 💡 **Key Insights**
- **When to use**: Sorted arrays, finding pairs/triplets, palindrome checking
- **Time**: O(n) to O(n²) depending on problem
- **Space**: O(1) - in-place solution
- **Pitfall**: Remember to handle duplicates in triplet problems

---

## 2. Fast & Slow Pointers

### 🎯 **Pattern Recognition**
- **LinkedList** cycle detection
- Finding **middle** of LinkedList
- **Palindrome** LinkedList checking
- **Happy number** type problems

### 🔑 **Core Template**
```java
public ListNode detectCycle(ListNode head) {
    ListNode slow = head, fast = head;
    
    // Detect cycle
    while (fast != null && fast.next != null) {
        slow = slow.next;
        fast = fast.next.next;
        
        if (slow == fast) {
            // Cycle detected, find start
            slow = head;
            while (slow != fast) {
                slow = slow.next;
                fast = fast.next;
            }
            return slow; // Cycle start
        }
    }
    return null; // No cycle
}
```

### 📚 **Must-Do Problems**
1. ✅ **[LinkedList Cycle](https://leetcode.com/problems/linked-list-cycle/)** #easy #must-do
2. ✅ **[LinkedList Cycle II](https://leetcode.com/problems/linked-list-cycle-ii/)** #medium #must-do
3. ✅ **[Happy Number](https://leetcode.com/problems/happy-number/)** #easy
4. ✅ **[Middle of LinkedList](https://leetcode.com/problems/middle-of-the-linked-list/)** #easy
5. ⭐ **[Palindrome LinkedList](https://leetcode.com/problems/palindrome-linked-list/)** #easy-medium
6. ⭐ **[Reorder List](https://leetcode.com/problems/reorder-list/)** #medium

### 💡 **Key Insights**
- **Floyd's Algorithm**: Fast moves 2 steps, slow moves 1 step
- **Cycle Detection**: When pointers meet, cycle exists
- **Finding Cycle Start**: Reset slow to head, move both one step at a time
- **Time**: O(n), **Space**: O(1)

---

## 3. Sliding Window

### 🎯 **Pattern Recognition**
- **Contiguous subarray/substring** problems
- **Maximum/minimum** subarray with conditions
- **Fixed size** or **variable size** windows
- Keywords: "substring", "subarray", "window"

### 🔑 **Core Templates**

#### Fixed Window Size
```java
public int fixedWindow(int[] arr, int k) {
    int windowSum = 0, maxSum = 0;
    
    // First window
    for (int i = 0; i < k; i++) {
        windowSum += arr[i];
    }
    maxSum = windowSum;
    
    // Slide window
    for (int i = k; i < arr.length; i++) {
        windowSum += arr[i] - arr[i - k];
        maxSum = Math.max(maxSum, windowSum);
    }
    return maxSum;
}
```

#### Variable Window Size
```java
public int variableWindow(int[] arr, int target) {
    int left = 0, right = 0;
    int windowSum = 0, minLength = Integer.MAX_VALUE;
    
    while (right < arr.length) {
        windowSum += arr[right];
        
        while (windowSum >= target && left <= right) {
            minLength = Math.min(minLength, right - left + 1);
            windowSum -= arr[left];
            left++;
        }
        right++;
    }
    return minLength == Integer.MAX_VALUE ? 0 : minLength;
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Maximum Sum Subarray of Size K](https://www.educative.io/courses/grokking-the-coding-interview/YQQwQMWLx80)** #easy #must-do
2. ✅ **[Smallest Subarray with Sum ≥ S](https://leetcode.com/problems/minimum-size-subarray-sum/)** #medium #must-do
3. ✅ **[Longest Substring with K Distinct Characters](https://leetcode.com/problems/longest-substring-with-at-most-k-distinct-characters/)** #medium
4. ✅ **[Fruit Into Baskets](https://leetcode.com/problems/fruit-into-baskets/)** #medium
5. ✅ **[Longest Substring Without Repeating Characters](https://leetcode.com/problems/longest-substring-without-repeating-characters/)** #medium #faang
6. ✅ **[Longest Repeating Character Replacement](https://leetcode.com/problems/longest-repeating-character-replacement/)** #medium #faang
7. ⭐ **[Permutation in String](https://leetcode.com/problems/permutation-in-string/)** #medium
8. ⭐ **[Find All Anagrams in String](https://leetcode.com/problems/find-all-anagrams-in-a-string/)** #medium
9. ⭐ **[Minimum Window Substring](https://leetcode.com/problems/minimum-window-substring/)** #hard #faang

### 💡 **Key Insights**
- **When to use**: Contiguous subarrays, substring problems
- **Time**: O(n) - each element visited at most twice
- **Space**: O(k) where k is size of character set
- **Common mistake**: Not properly shrinking the window

---

## 4. Merge Intervals

### 🎯 **Pattern Recognition**
- Dealing with **overlapping intervals**
- **Scheduling** problems
- **Calendar** applications
- Need to **merge, insert, or find intersections**

### 🔑 **Core Template**
```java
public int[][] mergeIntervals(int[][] intervals) {
    if (intervals.length <= 1) return intervals;
    
    // Sort by start time
    Arrays.sort(intervals, (a, b) -> a[0] - b[0]);
    
    List<int[]> result = new ArrayList<>();
    int[] currentInterval = intervals[0];
    result.add(currentInterval);
    
    for (int[] interval : intervals) {
        int currentEnd = currentInterval[1];
        int nextStart = interval[0];
        int nextEnd = interval[1];
        
        if (nextStart <= currentEnd) {
            // Overlapping - merge
            currentInterval[1] = Math.max(currentEnd, nextEnd);
        } else {
            // Non-overlapping - add new interval
            currentInterval = interval;
            result.add(currentInterval);
        }
    }
    
    return result.toArray(new int[result.size()][]);
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Merge Intervals](https://leetcode.com/problems/merge-intervals/)** #medium #must-do #faang
2. ✅ **[Insert Interval](https://leetcode.com/problems/insert-interval/)** #medium #must-do
3. ✅ **[Interval List Intersections](https://leetcode.com/problems/interval-list-intersections/)** #medium
4. ✅ **[Non-overlapping Intervals](https://leetcode.com/problems/non-overlapping-intervals/)** #medium
5. ⭐ **[Meeting Rooms II](https://leetcode.com/problems/meeting-rooms-ii/)** #medium #premium
6. ⭐ **[Employee Free Time](https://leetcode.com/problems/employee-free-time/)** #hard #premium

### 💡 **Key Insights**
- **Always sort** intervals by start time first
- **Overlap condition**: `start ≤ previousEnd`
- **Merge logic**: `newEnd = max(end1, end2)`
- **Time**: O(n log n) for sorting
- **Space**: O(n) for result

---

## 5. Cyclic Sort

### 🎯 **Pattern Recognition**
- Array contains numbers in **range [1, n]** or **[0, n-1]**
- Numbers are **continuous** but not necessarily sorted
- Looking for **missing** or **duplicate** numbers
- Can **place elements in correct positions**

### 🔑 **Core Template**
```java
public void cyclicSort(int[] nums) {
    int i = 0;
    while (i < nums.length) {
        int correctIndex = nums[i] - 1; // For 1-based indexing
        
        if (nums[i] != nums[correctIndex]) {
            // Swap to correct position
            int temp = nums[i];
            nums[i] = nums[correctIndex];
            nums[correctIndex] = temp;
        } else {
            i++;
        }
    }
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Missing Number](https://leetcode.com/problems/missing-number/)** #easy #must-do
2. ✅ **[Find All Numbers Disappeared in Array](https://leetcode.com/problems/find-all-numbers-disappeared-in-an-array/)** #easy
3. ✅ **[Find the Duplicate Number](https://leetcode.com/problems/find-the-duplicate-number/)** #medium #faang
4. ✅ **[Find All Duplicates in Array](https://leetcode.com/problems/find-all-duplicates-in-an-array/)** #medium
5. ⭐ **[Set Mismatch](https://leetcode.com/problems/set-mismatch/)** #easy
6. ⭐ **[First Missing Positive](https://leetcode.com/problems/first-missing-positive/)** #hard #faang
7. ⭐ **[Find the First K Missing Positive Numbers](https://thecodingsimplified.com/find-the-first-k-missing-positive-number/)** #hard

### 💡 **Key Insights**
- **When to use**: Numbers in continuous range [1,n] or [0,n-1]
- **Key idea**: Place each number at index = number - 1
- **Time**: O(n) - each number moved at most once
- **Space**: O(1) - in-place sorting
- **Handle duplicates**: Check if `nums[i] == nums[correctIndex]` before swapping

---

## 6. In-place Reversal LinkedList

### 🎯 **Pattern Recognition**
- **Reverse** entire LinkedList or part of it
- **In-place** manipulation required
- Need to reverse **sub-sections** of LinkedList
- **K-group** reversals

### 🔑 **Core Template**
```java
// Reverse entire LinkedList
public ListNode reverseList(ListNode head) {
    ListNode prev = null;
    ListNode current = head;
    
    while (current != null) {
        ListNode next = current.next;
        current.next = prev;
        prev = current;
        current = next;
    }
    
    return prev;
}

// Reverse between positions m and n
public ListNode reverseBetween(ListNode head, int m, int n) {
    if (head == null) return null;
    
    ListNode prev = null, current = head;
    
    // Move to position m
    while (m > 1) {
        prev = current;
        current = current.next;
        m--; n--;
    }
    
    ListNode connection = prev;
    ListNode tail = current;
    
    // Reverse n - m + 1 nodes
    while (n > 0) {
        ListNode next = current.next;
        current.next = prev;
        prev = current;
        current = next;
        n--;
    }
    
    if (connection != null) {
        connection.next = prev;
    } else {
        head = prev;
    }
    
    tail.next = current;
    return head;
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Reverse LinkedList](https://leetcode.com/problems/reverse-linked-list/)** #easy #must-do
2. ✅ **[Reverse LinkedList II](https://leetcode.com/problems/reverse-linked-list-ii/)** #medium #must-do
3. ✅ **[Reverse Nodes in k-Group](https://leetcode.com/problems/reverse-nodes-in-k-group/)** #hard #faang
4. ⭐ **[Reverse Alternating K-element Sub-list](https://www.geeksforgeeks.org/reverse-alternate-k-nodes-in-a-singly-linked-list/)** #medium
5. ⭐ **[Rotate List](https://leetcode.com/problems/rotate-list/)** #medium

### 💡 **Key Insights**
- **Three pointers**: prev, current, next
- **Keep track** of connections before and after reversed section
- **Handle edge cases**: null head, single node, m = n
- **Time**: O(n), **Space**: O(1)

---

## 7. Stack

### 🎯 **Pattern Recognition**
- **Balanced parentheses** problems
- **Expression evaluation**
- **Undo operations**
- **Function call** management
- **LIFO** (Last In, First Out) behavior needed

### 🔑 **Core Template**
```java
public boolean isValid(String s) {
    Stack<Character> stack = new Stack<>();
    Map<Character, Character> mapping = new HashMap<>();
    mapping.put(')', '(');
    mapping.put('}', '{');
    mapping.put(']', '[');
    
    for (char c : s.toCharArray()) {
        if (mapping.containsKey(c)) {
            char topElement = stack.empty() ? '#' : stack.pop();
            if (topElement != mapping.get(c)) {
                return false;
            }
        } else {
            stack.push(c);
        }
    }
    
    return stack.isEmpty();
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Valid Parentheses](https://leetcode.com/problems/valid-parentheses/)** #easy #must-do
2. ✅ **[Min Stack](https://leetcode.com/problems/min-stack/)** #easy #design
3. ✅ **[Evaluate Reverse Polish Notation](https://leetcode.com/problems/evaluate-reverse-polish-notation/)** #medium
4. ✅ **[Generate Parentheses](https://leetcode.com/problems/generate-parentheses/)** #medium #backtracking
5. ✅ **[Simplify Path](https://leetcode.com/problems/simplify-path/)** #medium
6. ✅ **[Basic Calculator](https://leetcode.com/problems/basic-calculator/)** #hard

### 💡 **Key Insights**
- **When to use**: Parsing, matching, undo operations
- **Stack operations**: push(), pop(), peek(), isEmpty()
- **Time**: O(n), **Space**: O(n)
- **Common patterns**: Using stack with HashMap for mappings

---

## 8. Monotonic Stack

### 🎯 **Pattern Recognition**
- Finding **next/previous greater/smaller** element
- **Daily temperatures** type problems
- **Largest rectangle** in histogram
- Maintaining **increasing/decreasing** order

### 🔑 **Core Template**
```java
// Next Greater Element
public int[] nextGreaterElement(int[] nums) {
    int[] result = new int[nums.length];
    Stack<Integer> stack = new Stack<>(); // Decreasing stack
    
    for (int i = nums.length - 1; i >= 0; i--) {
        while (!stack.isEmpty() && stack.peek() <= nums[i]) {
            stack.pop();
        }
        
        result[i] = stack.isEmpty() ? -1 : stack.peek();
        stack.push(nums[i]);
    }
    
    return result;
}

// Largest Rectangle in Histogram
public int largestRectangleArea(int[] heights) {
    Stack<Integer> stack = new Stack<>();
    int maxArea = 0;
    
    for (int i = 0; i <= heights.length; i++) {
        int currentHeight = (i == heights.length) ? 0 : heights[i];
        
        while (!stack.isEmpty() && currentHeight < heights[stack.peek()]) {
            int height = heights[stack.pop()];
            int width = stack.isEmpty() ? i : i - stack.peek() - 1;
            maxArea = Math.max(maxArea, height * width);
        }
        
        stack.push(i);
    }
    
    return maxArea;
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Next Greater Element I](https://leetcode.com/problems/next-greater-element-i/)** #easy #must-do
2. ✅ **[Next Greater Element II](https://leetcode.com/problems/next-greater-element-ii/)** #medium #circular
3. ✅ **[Daily Temperatures](https://leetcode.com/problems/daily-temperatures/)** #medium #must-do #faang
4. ✅ **[Largest Rectangle in Histogram](https://leetcode.com/problems/largest-rectangle-in-histogram/)** #hard #must-do
5. ✅ **[Trapping Rain Water](https://leetcode.com/problems/trapping-rain-water/)** #hard #faang
6. ⭐ **[Remove K Digits](https://leetcode.com/problems/remove-k-digits/)** #medium

### 💡 **Key Insights**
- **Increasing stack**: For next/previous smaller element
- **Decreasing stack**: For next/previous greater element
- **Each element** pushed and popped at most once → O(n)
- **Space**: O(n) in worst case

---

## 9. Hash Maps

### 🎯 **Pattern Recognition**
- **Counting** frequency of elements
- **Two Sum** variations
- **Anagram** problems
- **Group** similar elements
- **Fast lookups** needed

### 🔑 **Core Template**
```java
// Frequency Counter
public int[] frequencyCount(int[] nums) {
    Map<Integer, Integer> freqMap = new HashMap<>();
    
    // Count frequencies
    for (int num : nums) {
        freqMap.put(num, freqMap.getOrDefault(num, 0) + 1);
    }
    
    // Process based on frequencies
    List<Integer> result = new ArrayList<>();
    for (Map.Entry<Integer, Integer> entry : freqMap.entrySet()) {
        if (entry.getValue() > 1) {
            result.add(entry.getKey());
        }
    }
    
    return result.stream().mapToInt(i -> i).toArray();
}

// Anagram Grouping
public List<List<String>> groupAnagrams(String[] strs) {
    Map<String, List<String>> map = new HashMap<>();
    
    for (String str : strs) {
        char[] chars = str.toCharArray();
        Arrays.sort(chars);
        String key = String.valueOf(chars);
        
        map.putIfAbsent(key, new ArrayList<>());
        map.get(key).add(str);
    }
    
    return new ArrayList<>(map.values());
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Two Sum](https://leetcode.com/problems/two-sum/)** #easy #must-do #faang
2. ✅ **[Group Anagrams](https://leetcode.com/problems/group-anagrams/)** #medium #faang
3. ✅ **[First Unique Character](https://leetcode.com/problems/first-unique-character-in-a-string/)** #easy
4. ✅ **[Maximum Number of Balloons](https://leetcode.com/problems/maximum-number-of-balloons/)** #easy
5. ✅ **[Ransom Note](https://leetcode.com/problems/ransom-note/)** #easy

### 💡 **Key Insights**
- **Time**: O(1) average for put/get operations
- **Space**: O(n) for n elements
- **Use for**: Fast lookups, counting, grouping
- **Python equivalent**: dict, collections.Counter

---

## 10. Tree Breadth First Search

### 🎯 **Pattern Recognition**
- **Level-by-level** tree traversal
- Finding **minimum depth**
- **Level order** problems
- **Connecting nodes** at same level

### 🔑 **Core Template**
```java
public List<List<Integer>> levelOrder(TreeNode root) {
    List<List<Integer>> result = new ArrayList<>();
    if (root == null) return result;
    
    Queue<TreeNode> queue = new LinkedList<>();
    queue.offer(root);
    
    while (!queue.isEmpty()) {
        int levelSize = queue.size();
        List<Integer> currentLevel = new ArrayList<>();
        
        for (int i = 0; i < levelSize; i++) {
            TreeNode currentNode = queue.poll();
            currentLevel.add(currentNode.val);
            
            if (currentNode.left != null) {
                queue.offer(currentNode.left);
            }
            if (currentNode.right != null) {
                queue.offer(currentNode.right);
            }
        }
        
        result.add(currentLevel);
    }
    
    return result;
}
```

### 📚 **Must-Do Problems**
1. ✅ **[Binary Tree Level Order Traversal](https://leetcode.com/problems/binary-tree-level-order-traversal/)** #medium #must-do
2. ✅ **[Binary Tree Level Order Traversal II](https://leetcode.com/problems/binary-tree-level-order-traversal-ii/)** #medium
3. ✅ **[Binary Tree Zigzag Level Order Traversal](https://leetcode.com/problems/binary-tree-zigzag-level-order-traversal/)** #medium #faang
4. ✅ **[Average of Levels in Binary Tree](https://leetcode.com/problems/average-of-levels-in-binary-tree/)** #easy
5. ✅ **[Minimum Depth of Binary Tree](https://leetcode.com/problems/minimum-depth-of-binary-tree/)** #easy
6. ✅ **[Maximum Depth of Binary Tree](https://leetcode.com/problems/maximum-depth-of-binary-tree/)** #easy
7. ✅ **[Populating Next Right Pointers](https://leetcode.com/problems/populating-next-right-pointers-in-each-node/)** #medium
8. ⭐ **[Binary Tree Right Side View](https://leetcode.com/problems/binary-tree-right-side-view/)** #medium
9. ⭐ **[Connect All Level Order Siblings](https://www.educative.io/m/connect-all-siblings)** #medium

### 💡 **Key Insights**
- **Queue-based** traversal
- **Level size** determines nodes in current level
- **Time**: O(n), **Space**: O(w) where w is max width
- **Applications**: Finding shortest path in unweighted graph

---

## FAANG 75 Mix Problems Tracker

### **✅ Completed** | **❌ Not Started**

1. ❌ [Edit Distance](https://leetcode.com/problems/edit-distance/) #hard #dp
2. ❌ [Sliding Window Maximum](https://leetcode.com/problems/sliding-window-maximum/) #hard #sliding-window
3. ❌ [Stickers to Spell Word](https://leetcode.com/problems/stickers-to-spell-word/) #hard #dp
4. ❌ [Zuma Game](https://leetcode.com/problems/zuma-game/) #hard #backtracking
5. ✅ [Find Median from Data Stream](https://leetcode.com/problems/find-median-from-data-stream/) #hard #two-heaps
6. ❌ [Maximum Profit in Job Scheduling](https://leetcode.com/problems/maximum-profit-in-job-scheduling/) #hard #dp
7. ❌ [Reconstruct Itinerary](https://leetcode.com/problems/reconstruct-itinerary/) #medium #graph
8. ❌ [Concatenated Words](https://leetcode.com/problems/concatenated-words/) #hard #trie
9. ❌ [House Robber III](https://leetcode.com/problems/house-robber-iii/) #medium #tree-dp
10. ❌ [Regular Expression Matching](https://leetcode.com/problems/regular-expression-matching/) #hard #dp

*[Continue for all 75 problems...]*

---

## 🎯 Study Strategy

### **Week 1-2: Foundation Patterns**
- Two Pointers
- Sliding Window  
- Fast & Slow Pointers
- Hash Maps
- Stack

### **Week 3-4: Tree & Graph Patterns**
- Tree BFS
- Tree DFS
- Graph algorithms
- Island Pattern
- Topological Sort

### **Week 5-6: Advanced Patterns**
- Dynamic Programming (Knapsack, Subsets)
- Backtracking
- Advanced data structures (Trie, Union Find)
- Monotonic Stack
- Two Heaps

### **Daily Practice Routine**
- **Morning** (45 min): 2 problems from current week's patterns
- **Evening** (30 min): Review solutions, understand time/space complexity
- **Weekend**: Mock interview problems combining multiple patterns

---

**Progress Tracking:**
- [ ] Patterns Mastered: 0/27
- [ ] Problems Solved: 0/200+
- [ ] FAANG 75 Completed: 1/75
- [ ] Mock Interviews: 0/10

**Last Updated:** August 2025  
**Next Focus:** [Complete Two Pointers pattern - all 8 problems]