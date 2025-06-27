
## Description

Whenever we have array ranging from [0, n] where n is the length of the array, we can easily sort this by using cyclic sort.

We iterate through the arrays and try to place the element of the array in the index location where it belong (if possible) by swapping it with the misplaces element in that location.

```
for(int i = 0; i < nums.length; i++) {

            if(nums[i] != i && nums[i] != nums.length) {

                int x = nums[nums[i]];

                nums[nums[i]] = nums[i];

                nums[i] = x;

                i--;

            }

        }
```

here we can see that we are swapping the elements in the correct location, and if we do a swap we again check for this index, if the element we swapped with can be placed in another location again.

NOTE: Adjust indexes based on the range of the elements (Starting from one then place at nums[i] - 1)

To handle duplicate we check if the element present in the location is same as we are trying to swap, then we do not execute swap.


```
for(int i = 0 ; i < nums.length; i++) {

            int act = nums[i] - 1;

            if(act < nums.length && nums[act] != nums[i]) {

                int x = nums[act];

                nums[act] = nums[i];

                nums[i] = x;

                i--;

            }

        }
```

Second Iteration would reveal the actual logic of the question, whether it is to find the missing number of the duplicate number, the numbers which does not fit the criteria are the answers:

```
        for(int i = 0; i < nums.length; i++) {

            if(nums[i] != i + 1) ans.add(nums[i]);

        }
```
