# DSA Interview Checklist

> Run through this in the interview. Each unchecked box is lost signal.

## Before Coding

- [ ] Restated the problem in my own words
- [ ] Asked for input size bounds
- [ ] Asked about empty/null input
- [ ] Asked about duplicates, negatives, sortedness
- [ ] Asked whether I may modify the input
- [ ] Confirmed the return format (index vs value, any valid answer vs all)
- [ ] Walked through the given example by hand
- [ ] **Said aloud: "n is X, so I need O(Y)"**
- [ ] **Named the pattern and why it fits**
- [ ] Described the approach and got a nod before typing

## While Coding

- [ ] Handled the edge case at the top of the function
- [ ] Used meaningful names (`left`/`right`, not `i`/`j`, for window bounds)
- [ ] Extracted a helper instead of nesting four levels deep
- [ ] Used `lo + (hi - lo) / 2` for midpoints
- [ ] Used `long` where sums could overflow
- [ ] Narrated the non-obvious lines, not every line

## After Coding — Do This Unprompted

- [ ] Dry-ran a normal case, tracking variables out loud
- [ ] Tested empty input
- [ ] Tested a single element
- [ ] Tested all-identical elements
- [ ] Tested the largest/smallest values (overflow)
- [ ] Tested the case my invariant is weakest on
- [ ] **Stated time complexity and justified it**
- [ ] **Stated space complexity, including recursion stack**
- [ ] Named one trade-off or possible optimisation

## If Stuck

- [ ] Said so calmly, without apologising repeatedly
- [ ] Stated the brute force and its complexity
- [ ] Named the specific bottleneck in the brute force
- [ ] Asked: what structure removes *that* bottleneck?
  - Repeated lookup → hash map
  - Repeated min/max → heap
  - Repeated range sum → prefix sum
  - Repeated nearest-greater → monotonic stack
- [ ] **Accepted the hint gracefully** and built on it

## Red Flags To Avoid

- [ ] Did not code in silence
- [ ] Did not start coding before confirming the approach
- [ ] Did not argue when redirected
- [ ] Did not claim a complexity I hadn't verified
- [ ] Did not optimise before having something working

## Language-Specific (Java)

- [ ] `ArrayDeque` for stacks and queues, not `Stack`/`LinkedList`
- [ ] `Integer.compare` in comparators, not `a - b`
- [ ] `>>>` not `>>` when bit-shifting possibly-negative values
- [ ] `new ArrayList<>(path)` when collecting backtracking results
- [ ] `map.put(0, 1)` seed for prefix-sum counting

## Related

- [Interview Execution Playbook](Interview%20Execution%20Playbook.md)
- [DSA Cheat Sheet](DSA%20Cheat%20Sheet.md)
- [DSA Flash Cards](DSA%20Flash%20Cards.md)
