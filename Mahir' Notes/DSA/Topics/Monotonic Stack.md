
# 📚 Monotonic Stack

A **monotonic stack** is a stack that maintains elements in a **monotonic order**—either **increasing** or **decreasing**—as you iterate through a data structure. It allows you to solve many problems in **O(n)** time, especially those involving "next" or "previous" **greater/smaller** elements.

---

## 🔍 What is a Monotonic Stack?

- **Monotonic Increasing Stack**: Elements are in **increasing** order from top to bottom.
- **Monotonic Decreasing Stack**: Elements are in **decreasing** order from top to bottom.

> 💡 The stack is not fully sorted—it's *logically* ordered to satisfy certain constraints.

---

## ✅ Key Idea

While iterating through an array:
- **Pop** elements that break the required order.
- **Push** the current element (or index) once the condition is met.

⏱️ **Time Complexity**:  
Each element is pushed and popped **once**, so total operations = **O(n)**.

---

## 🧠 Common Applications

### 1. **Next Greater Element**

> Find the next greater element for each element in an array.

**Example**:  
Input: `[2, 1, 2, 4, 3]`  
Output: `[4, 2, 4, -1, -1]`

**Approach**: Use a **monotonic decreasing stack**.

```java
public int[] nextGreaterElements(int[] nums) {
    int[] res = new int[nums.length];
    Arrays.fill(res, -1);
    Deque<Integer> stack = new ArrayDeque<>();

    for (int i = 0; i < nums.length; i++) {
        while (!stack.isEmpty() && nums[i] > nums[stack.peek()]) {
            int idx = stack.pop();
            res[idx] = nums[i];
        }
        stack.push(i);
    }
    return res;
}
```

---

### 2. **Next Smaller Element**

Just reverse the comparison.

Use a **monotonic increasing stack**.

---

### 3. **Largest Rectangle in Histogram**

> Find the largest rectangular area in a histogram.

Use a **monotonic increasing stack** to store indices.

```java
public int largestRectangleArea(int[] heights) {
    int[] newHeights = Arrays.copyOf(heights, heights.length + 1);
    Deque<Integer> stack = new ArrayDeque<>();
    stack.push(-1);
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

---

### 4. **Trapping Rain Water**

> Compute how much water is trapped between bars after raining.

Use a **monotonic decreasing stack**.

```java
public int trap(int[] height) {
    int water = 0;
    Deque<Integer> stack = new ArrayDeque<>();

    for (int i = 0; i < height.length; i++) {
        while (!stack.isEmpty() && height[i] > height[stack.peek()]) {
            int bottom = stack.pop();
            if (stack.isEmpty()) break;

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

---

### 5. **Daily Temperatures (Leetcode 739)**

> For each day, find how many days until a warmer temperature.

Use a **monotonic decreasing stack**.

```java
public int[] dailyTemperatures(int[] temperatures) {
    int[] res = new int[temperatures.length];
    Deque<Integer> stack = new ArrayDeque<>();

    for (int i = 0; i < temperatures.length; i++) {
        while (!stack.isEmpty() && temperatures[i] > temperatures[stack.peek()]) {
            int idx = stack.pop();
            res[idx] = i - idx;
        }
        stack.push(i);
    }
    return res;
}
```

---

## ✍️ Generic Template

```java
Stack<Integer> stack = new Stack<>();

for (int i = 0; i < arr.length; i++) {
    while (!stack.isEmpty() && arr[i] > arr[stack.peek()]) { // or < for next smaller
        int idx = stack.pop();
        result[idx] = arr[i]; // or i - idx for days/waiting time
    }
    stack.push(i);
}
```

---

## 📌 Summary Table

| Problem                   | Stack Type           | Condition                              |
|---------------------------|----------------------|-----------------------------------------|
| Next Greater Element      | Monotonic Decreasing | `while stack not empty && curr > top` |
| Next Smaller Element      | Monotonic Increasing | `while stack not empty && curr < top` |
| Largest Rectangle         | Monotonic Increasing | `while curr height < top height`      |
| Daily Temperatures        | Monotonic Decreasing | `while curr > top`                    |
| Trapping Rain Water       | Monotonic Decreasing | Valley detection using bars            |

---

## 📎 Tip

Store **indices** instead of values if you need to calculate distances or reference the original array.

---

## 🧭 Related Concepts

- Sliding Window
- Stack-based Greedy
- Two Pointers
