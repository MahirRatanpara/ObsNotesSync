

TC:
**Average Case: O(n)**
**Worst Case: O(n^2)**

```
class Solution {

    public int findKthLargest(int[] nums, int k) {

        return quickSelect(nums, 0, nums.length - 1, nums.length - k);

    }

  

    private int quickSelect(int[] nums, int left, int right, int kSmallest) {

        if (left == right) return nums[left]; // Only one element

  

        int pivotIndex = partition(nums, left, right);

        if (kSmallest == pivotIndex) {

            return nums[kSmallest];

        } else if (kSmallest < pivotIndex) {

            return quickSelect(nums, left, pivotIndex - 1, kSmallest);

        } else {

            return quickSelect(nums, pivotIndex + 1, right, kSmallest);

        }

    }

  

    private int partition(int[] nums, int left, int right) {

        int pivotIndex = left + new Random().nextInt(right - left + 1);

        int pivotValue = nums[pivotIndex];

        swap(nums, pivotIndex, right); // Move pivot to end

        int storeIndex = left;

  

        for (int i = left; i < right; i++) {

            if (nums[i] < pivotValue) {

                swap(nums, storeIndex, i);

                storeIndex++;

            }

        }

  

        swap(nums, storeIndex, right); // Move pivot to final place

        return storeIndex;

    }

  

    private void swap(int[] nums, int i, int j) {

        int tmp = nums[i];

        nums[i] = nums[j];

        nums[j] = tmp;

    }

}
```