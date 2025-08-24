# 📚 Monotonic Stack - Complete Pattern Guide

> **"When you need the next/previous greater/smaller element - think monotonic stack!"**

---

## 🎯 Table of Contents

1. [Core Concept](#-core-concept)
2. [Recognition Patterns](#-recognition-patterns)  
3. [Problem Categories](#-problem-categories)
4. [Implementation Templates](#-implementation-templates)
5. [Interview Problems](#-interview-problems)
6. [Advanced Applications](#-advanced-applications)
7. [Common Pitfalls](#-common-pitfalls)

---

## 🔍 Core Concept

### **What is a Monotonic Stack?** #fundamental

A **monotonic stack** maintains elements in **monotonic order** (increasing or decreasing) while iterating through data. It's the secret weapon for **O(n)** solutions to "next/previous greater/smaller" problems.

**Key Insight:** Each element is pushed and popped **at most once** → Total operations = **O(n)**

### **Two Types** 🔄

#### **Monotonic Increasing Stack** ↗️
Elements are in **increasing** order from bottom to top
```
Bottom → [1, 3, 5, 8] ← Top
```

#### **Monotonic Decreasing Stack** ↘️  
Elements are in **decreasing** order from bottom to top
```
Bottom → [8, 5, 3, 1] ← Top
```

---

## 🧠 Recognition Patterns

### **When to Use Monotonic Stack** #recognition

**Keywords that trigger monotonic stack thinking:**
- ✅ "Next greater/smaller element"
- ✅ "Previous greater/smaller element" 
- ✅ "Largest rectangle/area"
- ✅ "Daily temperatures"
- ✅ "Trapping water"
- ✅ "Stock span problem"

### **Pattern Recognition Matrix**

| **Problem Type** | **Stack Type** | **When to Pop** | **What to Store** |
|------------------|----------------|-----------------|-------------------|
| Next Greater Element | Decreasing | `curr > stack.top()` | Index or Value |
| Next Smaller Element | Increasing | `curr < stack.top()` | Index or Value |
| Previous Greater | Decreasing | `curr < stack.top()` | Index or Value |
| Previous Smaller | Increasing | `curr > stack.top()` | Index or Value |
| Largest Rectangle | Increasing | `curr < stack.top()` | Index (for width) |
| Trapping Water | Decreasing | `curr > stack.top()` | Index (for bounds) |

---

## 📊 Problem Categories

### **1. Next Greater Element Pattern** #next-greater

**Core Idea:** For each element, find the next element that's greater than it.

#### **🔥 Example: Next Greater Elements I**
```java
/**
 * Input: [2, 1, 2, 4, 3]
 * Output: [4, 2, 4, -1, -1]
 */
public int[] nextGreaterElements(int[] nums) {
    int[] result = new int[nums.length];
    Arrays.fill(result, -1);
    Deque<Integer> stack = new ArrayDeque<>(); // Decreasing stack
    
    for (int i = 0; i < nums.length; i++) {
        // Pop all smaller elements
        while (!stack.isEmpty() && nums[i] > nums[stack.peek()]) {
            int index = stack.pop();
            result[index] = nums[i];
        }
        stack.push(i); // Always push current index
    }
    
    return result;
}
```

**Visual Walkthrough:**
```
Array: [2, 1, 2, 4, 3]
       
i=0: stack=[0], result=[-1,-1,-1,-1,-1]
i=1: 1<2, stack=[0,1], result=[-1,-1,-1,-1,-1] 
i=2: 2>1, pop 1, result=[-1,2,-1,-1,-1], then 2==2, stack=[0,2]
i=3: 4>2, pop 2, result=[4,2,-1,-1,-1], 4>2, pop 0, result=[4,2,4,-1,-1], stack=[3]
i=4: 3<4, stack=[3,4], result=[4,2,4,-1,-1]
```

#### **🔥 Practice Problems:**
- ✅ [Next Greater Element I](https://leetcode.com/problems/next-greater-element-i/) #easy #must-do
- ✅ [Next Greater Element II](https://leetcode.com/problems/next-greater-element-ii/) #medium #circular
- ✅ [Daily Temperatures](https://leetcode.com/problems/daily-temperatures/) #medium #must-do

### **2. Largest Rectangle in Histogram** #largest-rectangle

**Core Idea:** Find the largest rectangular area using heights array.

**Strategy:** Use monotonic increasing stack. When we pop, calculate area with popped height.

```java
/**
 * Find largest rectangle area in histogram
 * Input: [2,1,5,6,2,3]  
 * Output: 10 (rectangle with height 5, width 2)
 */
public int largestRectangleArea(int[] heights) {
    // Add 0 at end to force final calculations
    int[] newHeights = Arrays.copyOf(heights, heights.length + 1);
    Deque<Integer> stack = new ArrayDeque<>();
    stack.push(-1); // Boundary marker
    int maxArea = 0;
    
    for (int i = 0; i < newHeights.length; i++) {
        while (stack.peek() != -1 && newHeights[i] < newHeights[stack.peek()]) {
            int height = newHeights[stack.pop()];
            int width = i - stack.peek() - 1;
            maxArea = Math.max(maxArea, height * width);
        }
        stack.push(i);
    }
    
    return maxArea;
}
```

**Key Insights:**
- When we pop index `j`, the rectangle height = `heights[j]`  
- Rectangle width = `i - stack.peek() - 1` (current pos - left boundary - 1)
- Left boundary = element below popped element in stack

### **3. Trapping Rain Water** #trapping-water

**Core Idea:** Calculate trapped water between bars after raining.

**Strategy:** Use monotonic decreasing stack to find valleys.

```java
/**
 * Calculate trapped rainwater
 * Input: [0,1,0,2,1,0,1,3,2,1,2,1]
 * Output: 6
 */
public int trap(int[] height) {
    int water = 0;
    Deque<Integer> stack = new ArrayDeque<>(); // Decreasing stack
    
    for (int i = 0; i < height.length; i++) {
        while (!stack.isEmpty() && height[i] > height[stack.peek()]) {
            int bottom = stack.pop(); // Valley bottom
            if (stack.isEmpty()) break; // No left boundary
            
            int left = stack.peek();
            int width = i - left - 1;
            int boundedHeight = Math.min(height[i], height[left]) - height[bottom];
            water += width * boundedHeight;
        }
        stack.push(i);
    }
    
    return water;
}
```

**Visual Understanding:**
```
Heights: [3, 0, 1, 0, 4]
                 ↑     ↑
              valley   right wall
                      
Water trapped = min(left_wall, right_wall) - valley_height
```

### **4. Daily Temperatures** #daily-temperatures

**Core Idea:** For each day, find how many days until a warmer temperature.

```java
/**
 * Input: [73,74,75,71,69,72,76,73]
 * Output: [1,1,4,2,1,1,0,0]
 */
public int[] dailyTemperatures(int[] temperatures) {
    int[] result = new int[temperatures.length];
    Deque<Integer> stack = new ArrayDeque<>(); // Decreasing stack
    
    for (int i = 0; i < temperatures.length; i++) {
        while (!stack.isEmpty() && temperatures[i] > temperatures[stack.peek()]) {
            int index = stack.pop();
            result[index] = i - index; // Days difference
        }
        stack.push(i);
    }
    
    return result; // Unmatched elements remain 0
}
```

---

## 🛠️ Implementation Templates

### **Generic Next Greater Template**

```java
public int[] nextGreater(int[] arr) {
    int n = arr.length;
    int[] result = new int[n];
    Arrays.fill(result, -1); // Default: no greater element
    Deque<Integer> stack = new ArrayDeque<>();
    
    for (int i = 0; i < n; i++) {
        // Pop all smaller elements
        while (!stack.isEmpty() && arr[i] > arr[stack.peek()]) {
            int idx = stack.pop();
            result[idx] = arr[i]; // or i-idx for distance
        }
        stack.push(i);
    }
    
    return result;
}
```

### **Generic Previous Greater Template**

```java
public int[] previousGreater(int[] arr) {
    int n = arr.length;
    int[] result = new int[n];
    Arrays.fill(result, -1);
    Deque<Integer> stack = new ArrayDeque<>();
    
    for (int i = 0; i < n; i++) {
        // Pop all smaller elements  
        while (!stack.isEmpty() && arr[i] >= arr[stack.peek()]) {
            stack.pop();
        }
        
        // If stack not empty, top is previous greater
        if (!stack.isEmpty()) {
            result[i] = arr[stack.peek()];
        }
        
        stack.push(i);
    }
    
    return result;
}
```

### **Circular Array Handling**

For circular arrays (like Next Greater Element II):

```java
public int[] nextGreaterElementsCircular(int[] nums) {
    int n = nums.length;
    int[] result = new int[n];
    Arrays.fill(result, -1);
    Deque<Integer> stack = new ArrayDeque<>();
    
    // Process array twice for circular effect
    for (int i = 0; i < 2 * n; i++) {
        int idx = i % n;
        while (!stack.isEmpty() && nums[idx] > nums[stack.peek()]) {
            result[stack.pop()] = nums[idx];
        }
        if (i < n) { // Only push in first pass
            stack.push(idx);
        }
    }
    
    return result;
}
```

---

## 🔥 Interview Problem Bank

### **Easy Level** (Foundation Building)
1. ✅ [Next Greater Element I](https://leetcode.com/problems/next-greater-element-i/) #must-do
2. ✅ [Valid Parentheses](https://leetcode.com/problems/valid-parentheses/) #stack-basics
3. ✅ [Remove Outermost Parentheses](https://leetcode.com/problems/remove-outermost-parentheses/)

### **Medium Level** (Core Practice)  
1. ✅ [Next Greater Element II](https://leetcode.com/problems/next-greater-element-ii/) #circular #must-do
2. ✅ [Daily Temperatures](https://leetcode.com/problems/daily-temperatures/) #must-do #faang
3. ✅ [Online Stock Span](https://leetcode.com/problems/online-stock-span/) #design
4. ✅ [Remove K Digits](https://leetcode.com/problems/remove-k-digits/) #greedy
5. ✅ [132 Pattern](https://leetcode.com/problems/132-pattern/) #tricky
6. ✅ [Sum of Subarray Minimums](https://leetcode.com/problems/sum-of-subarray-minimums/) #contribution

### **Hard Level** (Advanced Mastery)
1. ✅ [Largest Rectangle in Histogram](https://leetcode.com/problems/largest-rectangle-in-histogram/) #hard #must-do
2. ✅ [Trapping Rain Water](https://leetcode.com/problems/trapping-rain-water/) #hard #must-do
3. ✅ [Maximal Rectangle](https://leetcode.com/problems/maximal-rectangle/) #2d-extension
4. ✅ [Sliding Window Maximum](https://leetcode.com/problems/sliding-window-maximum/) #deque-variation

---

## 🚀 Advanced Applications

### **1. Contribution Technique** #contribution

For problems like "Sum of Subarray Minimums":

**Key Idea:** For each element, calculate how many subarrays it contributes to as minimum.

```java
public int sumSubarrayMins(int[] arr) {
    long MOD = 1_000_000_007;
    int n = arr.length;
    
    // Find previous smaller and next smaller for each element
    int[] prevSmaller = previousSmallerElements(arr);
    int[] nextSmaller = nextSmallerElements(arr);
    
    long result = 0;
    for (int i = 0; i < n; i++) {
        long left = i - prevSmaller[i];  // Count of elements to left
        long right = nextSmaller[i] - i; // Count of elements to right
        result = (result + arr[i] * left * right) % MOD;
    }
    
    return (int) result;
}
```

### **2. Maximum Width Ramp** #width-ramp

**Problem:** Find maximum `j - i` where `j > i` and `arr[j] >= arr[i]`.

**Strategy:** Use decreasing stack to store potential left boundaries.

```java
public int maxWidthRamp(int[] nums) {
    Deque<Integer> stack = new ArrayDeque<>();
    
    // Build decreasing stack (potential left boundaries)
    for (int i = 0; i < nums.length; i++) {
        if (stack.isEmpty() || nums[i] < nums[stack.peek()]) {
            stack.push(i);
        }
    }
    
    int maxWidth = 0;
    // Traverse from right, find matches
    for (int j = nums.length - 1; j >= 0; j--) {
        while (!stack.isEmpty() && nums[j] >= nums[stack.peek()]) {
            int i = stack.pop();
            maxWidth = Math.max(maxWidth, j - i);
        }
    }
    
    return maxWidth;
}
```

---

## ⚠️ Common Pitfalls

### **❌ Mistakes That Cost Interviews** #pitfalls

1. **Wrong Stack Type**
   - ❌ Using increasing stack for next greater element
   - ✅ **Remember**: Decreasing stack for next greater, increasing for next smaller

2. **Storing Values vs Indices**
   - ❌ Storing values when you need distances/widths
   - ✅ **Rule**: Store indices if you need positions, values if you only need comparison

3. **Boundary Handling**
   - ❌ Not handling empty stack cases
   - ✅ **Check**: What happens when no previous/next element exists?

4. **Circular Array Logic**  
   - ❌ Processing array only once for circular problems
   - ✅ **Solution**: Process 2*n elements with modulo indexing

5. **Off-by-One in Width Calculation**
   - ❌ Width = `right - left` (missing -1)
   - ✅ **Correct**: Width = `right - left - 1`

### **🛡️ Debugging Checklist**

When your monotonic stack solution fails:
- [ ] Verify stack type matches problem requirement
- [ ] Check if storing indices vs values correctly  
- [ ] Test with simple examples (array of 2-3 elements)
- [ ] Confirm boundary conditions (empty stack, no match found)
- [ ] Validate width/distance calculations

---

## 📈 Complexity Analysis

### **Time Complexity: Always O(n)** ⏰
**Reason:** Each element is pushed and popped at most once.
- Push operations: n (one per element)
- Pop operations: ≤ n (can't pop more than pushed)
- Total: O(n)

### **Space Complexity: O(n)** 💾
**Worst case:** All elements in decreasing/increasing order → stack holds all elements

---

## 💪 Practice Strategy

### **Week 1: Foundation**
- Master basic next/previous greater element
- Understand stack type selection
- Practice 5-6 easy problems

### **Week 2: Application**  
- Largest rectangle and variations
- Trapping water problems
- Daily temperatures pattern

### **Week 3: Advanced**
- Contribution technique problems
- Sliding window maximum (deque variation)
- Complex stack state management

### **Interview Readiness Checklist**
- [ ] Can identify monotonic stack problems instantly
- [ ] Know when to use increasing vs decreasing stack
- [ ] Can implement from scratch in 10-15 minutes
- [ ] Understand time complexity proof
- [ ] Can explain approach clearly to interviewer

---

**Study Progress:**
- [ ] Basic Patterns (0/5 problems solved)
- [ ] Rectangle Problems (0/3 problems solved)  
- [ ] Advanced Applications (0/4 problems solved)
- [ ] Mock Interview Practice (0/3 completed)

**Last Updated:** August 2025  
**Next Focus:** [Sliding Window Maximum using Deque]