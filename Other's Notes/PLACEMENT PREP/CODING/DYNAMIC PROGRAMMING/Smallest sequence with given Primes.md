#### Metadata

timestamp: **16:56**  &emsp;  **30-07-2021**
topic tags: #dp, #imp
question link: https://www.interviewbit.com/old/problems/smallest-sequence-with-given-primes/
resource: https://www.geeksforgeeks.org/super-ugly-number-number-whose-prime-factors-given-set/
parent link: [[1. DP GUIDE]]

---

# Smallest sequence with given Primes

### Question

GIven three prime numbers **A, B** and **C** and an integer **D**.

You need to find the first(smallest) **D** integers which only have **A, B, C** or a combination of them as their prime factors.

---


### Approach

The naive solution will be to check prime factorization of every natural number incrementally till k numbers are found. However, that will be too slow.

As mentioned in the previous hint, this problem can be addressed as a modified BFS / Dijkstra. We push p1, p2 and p3 to a min heap. Every time, we repeat the following process till we find k numbers :

```
 - M = Pop out the min element in the min heap. 
 - Add M to the final answer. 
 - Push M * p1, M * p2, M * p3 to the min heap if they are not already present in the heap ( We can use a hash map to track this ) 
```

However, this is O( k * log k ). Can we do better than this ?

It turns out we can. We use the fact that there are only 3 possibilities of getting to a new number : Multiply by p1 or p2 or p3.

For each of p1, p2 and p3, we maintain the minimum number in our set which has not been multiplied with the corresponding prime number yet. So, at a time we will have 3 numbers to compare. The corresponding approach would look something like the following :

```
initialSet = [p1, p2, p3] 
indexInFinalSet = [0, 0, 0]

for i = 1 to k 
  M = get min from initialSet. 
  add M to the finalAnswer if last element in finalAnswer != M
  if M corresponds to p1 ( or in other words M = initialSet[0] )
    initialSet[0] = finalAnswer[indexInFinalSet[0]] * p1
    indexInFinalSet[0] += 1
  else if M corresponds to p2 ( or in other words M = initialSet[1] )
    initialSet[1] = finalAnswer[indexInFinalSet[1]] * p1
    indexInFinalSet[1] += 1
  else 
    # Similar steps for p3. 
end
```


#### Code

``` cpp
vector<int> Solution::solve(int A, int B, int C, int D) {
    vector<int> res;
    res.push_back(1);
    int i = 0, x = 0, y = 0, z = 0;
    while(i < D)  {
        int tmp = min(A*res[x], min(B*res[y], C*res[z]));
        res.push_back(tmp);
        ++i;
        if(tmp == A*res[x]) ++x;
        if(tmp == B*res[y]) ++y;
        if(tmp == C*res[z]) ++z;
    }
    res.erase(res.begin());
    return res;
}

```

---
#### Code

``` cpp
vector<int> Solution::solve(int A, int B, int C, int D)
{
    set<int> s;
    swap(A,D);
    int ctr = 0;
    vector<int> ans;
    s.insert(B);
    s.insert(C);
    s.insert(D);
    while(ctr<A)
    {
        auto i = s.begin();
        ans.push_back(*i);
    
        s.insert((*i)*B);
        s.insert((*i)*C);
        s.insert((*i)*D);
        s.erase(i);
        ctr++;
    }
    return ans;
}

```

---

