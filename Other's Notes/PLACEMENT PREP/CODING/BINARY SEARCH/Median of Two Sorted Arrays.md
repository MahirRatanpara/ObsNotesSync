#### Metadata

timestamp: **12:35**  &emsp;  **22-06-2021**
topic tags: #binary_search 
list tags: #sde 
question link: https://leetcode.com/problems/median-of-two-sorted-arrays/
resource: [TUF](https://www.youtube.com/watch?v=NTop3VTjmxk&list=PLgUwDviBIf0p4ozDR_kJJkONnb1wdx2Ma&index=66)
parent link: [[SDE SHEET]], [[1. BINARY SEARCH GUIDE]]

---

# Median of Two Sorted Arrays

### Question
Given two sorted arrays `nums1` and `nums2` of size `m` and `n` respectively, return **the median** of the two sorted arrays.

The overall run time complexity should be `O(log (m+n))`.

>**Example 1:**
**Input:** nums1 = [1,3], nums2 = [2]
**Output:** 2.00000
**Explanation:** merged array = [1,2,3] and median is 2.


---


### Approach: Binary Search
- Basic idea is to create partitions in both the arrays.
- Watch the video link in metadata for detailed explanation.

#### Algorithm

#### Complexity Analysis
- Time: O(log(min(n1, n2)))

#### Code

``` cpp

class Solution {
public:
    double findMedianSortedArrays(vector<int>& nums1, vector<int>& nums2) {
        if(nums2.size() < nums1.size()) return findMedianSortedArrays(nums2, nums1);
        
        int n1 = nums1.size(), n2 = nums2.size(), flag = 0;
        
        int low = 0, high = n1;
        
        while(low <= high){
            int cut1 = low + (high - low)/2;
            int cut2 = (n1 + n2 + 1)/2 - cut1;
            
            int left1  = cut1 == 0 ? INT_MIN : nums1[cut1-1];
            int left2  = cut2 == 0 ? INT_MIN : nums2[cut2-1];
            int right1 = cut1 >= n1 ? INT_MAX : nums1[cut1];
            int right2 = cut2 >= n2 ? INT_MAX : nums2[cut2];
            
            if(left1 <= right2 && left2 <= right1){
                if((n1+n2)%2 == 0)
                    return (max(left1, left2) + min(right1, right2))/2.0;
                else
                    return max(left1, left2);
            }
            else if(left1 > right2)
                high = cut1-1;
            else
                low = cut1+1;
        }
        return 0.0;
    }
};
```

---


