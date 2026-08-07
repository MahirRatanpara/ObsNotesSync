# Flyweight

## Why It Matters

The memory-optimisation pattern. Rarely needed, but when an interviewer says "millions of objects", this is the expected answer.

## Core Idea

Share common state between many objects instead of duplicating it. Split each object's data:

| State | Meaning | Stored |
|---|---|---|
| **Intrinsic** | Shared, immutable, context-independent | **In the flyweight, shared** |
| **Extrinsic** | Unique per use, context-dependent | Passed in by the caller |

```java
// Intrinsic — shared across every occurrence of this character
final class CharacterStyle {
    private final String font; private final int size; private final Color colour;
}

// Extrinsic — position differs per occurrence, passed at render time
class TextRenderer {
    void render(char c, CharacterStyle style, int x, int y) { }
}

class StyleFactory {
    private static final Map<String, CharacterStyle> CACHE = new ConcurrentHashMap<>();
    static CharacterStyle get(String font, int size, Color c) {
        return CACHE.computeIfAbsent(font + size + c, k -> new CharacterStyle(font, size, c));
    }
}
```

A million characters in a document share a handful of style objects.

## The Factory Is Mandatory

Clients must never `new` a flyweight — otherwise sharing doesn't happen. A factory with a cache is part of the pattern, not an optional extra.

## Flyweights Must Be Immutable

Shared mutable state is a correctness disaster: mutating one flyweight changes it for every user. **Immutability is a hard requirement**, not a recommendation.

## Real Examples

- **`Integer.valueOf()`** — caches −128 to 127. This is why `Integer a = 127, b = 127; a == b` is `true` but the same with `128` is `false`. A famous interview trap and a genuine flyweight.
- **String interning** — the string pool shares identical literals
- `Boolean.valueOf()`, `Character.valueOf()`
- Game engines — one mesh/texture shared by thousands of instances, with position/rotation extrinsic
- Text editors — shared glyph and style objects

**The `Integer` cache is the best example to give** because it connects the pattern to observable Java behaviour.

## When To Use

All of these must hold:

1. You have a **very large** number of objects
2. Storage cost is genuinely a problem
3. Most object state can be made **extrinsic**
4. Objects don't depend on identity (since many "distinct" objects become one)

**If any fail, don't use it.** The complexity is only justified by real measured memory pressure.

## The Trade-Off

| Gain | Cost |
|---|---|
| Large memory reduction | **CPU cost** — extrinsic state is recomputed or passed each time |
| Better cache locality for shared data | Code complexity |
| Fewer allocations, less GC pressure | **Identity semantics break** — `==` and identity maps behave unexpectedly |

**You are trading CPU and clarity for memory.** State this trade-off explicitly.

## Flyweight vs Singleton vs Object Pool

| | Flyweight | Singleton | Object Pool |
|---|---|---|---|
| Instances | Many, shared by value | Exactly one | Fixed set, **borrowed and returned** |
| Mutable | **No** | Usually | Yes |
| Purpose | Save memory | Global access | Reuse expensive resources |

**Object Pool is the one people confuse it with:** a pool lends a mutable object exclusively and takes it back (database connections, threads). A flyweight is shared concurrently and never mutated.

## Common Questions

- *Intrinsic vs extrinsic?* — shared/immutable vs per-context/passed in.
- *Why must flyweights be immutable?* — they're shared; mutation would affect all users.
- *JDK example?* — `Integer.valueOf` caching −128..127, and the string pool.
- *Why is `Integer a=128, b=128; a==b` false?* — outside the flyweight cache range, so two distinct objects.
- *Flyweight vs object pool?* — shared immutable vs borrowed mutable.

## Common Mistakes

- Mutable flyweights
- Letting clients construct them directly, defeating sharing
- Applying it without measuring — premature optimisation
- Relying on `==` for objects that are now shared
- Confusing it with an object pool

## Related Topics

- [Singleton](Singleton.md)
- [Prototype](Prototype.md)
- [Design Pattern Selection](Design%20Pattern%20Selection.md)

## Revision Summary

Share immutable intrinsic state across many objects; pass extrinsic state in. Requires a caching factory and strict immutability. `Integer.valueOf` and the string pool are the JDK examples. Trades CPU and identity semantics for memory.

## Quick Recall

- Intrinsic = shared; extrinsic = passed in
- Factory with cache is mandatory
- Must be immutable
- `Integer.valueOf` caches −128..127
- Flyweight = shared immutable; pool = borrowed mutable
- Only with measured memory pressure
