# equals and hashCode

## Why It Matters

Get this wrong and `HashMap`, `HashSet`, `contains`, and `distinct` all silently misbehave. It's the most consequential contract in Java and a guaranteed interview question.

## The Contract

**`equals` must be:**

| Property | Meaning |
|---|---|
| Reflexive | `x.equals(x)` is true |
| Symmetric | `x.equals(y)` ⟺ `y.equals(x)` |
| Transitive | `x.equals(y)` and `y.equals(z)` ⟹ `x.equals(z)` |
| Consistent | Repeated calls give the same result |
| Null-safe | `x.equals(null)` is false, never throws |

**`hashCode` must be:**

1. **Equal objects must have equal hash codes.** (The one that matters.)
2. Unequal objects *may* share a hash code — that's a collision, and it's fine.
3. Consistent while the object is unmodified.

## Why Overriding One Requires The Other

`HashMap` finds the bucket via `hashCode`, then compares within it via `equals`.

Override `equals` only → two equal objects get different hash codes → they land in different buckets → `map.get(key)` returns `null` for a key that is present.

```java
class Point { int x, y;
    public boolean equals(Object o) { ... }   // overridden
    // hashCode NOT overridden → identity hash
}
Set<Point> s = new HashSet<>();
s.add(new Point(1,1));
s.contains(new Point(1,1));   // false — different buckets
```

## Correct Implementation

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;                        // fast path
    if (o == null || getClass() != o.getClass()) return false;
    Point p = (Point) o;
    return x == p.x && y == p.y;                       // compare significant fields
}

@Override
public int hashCode() {
    return Objects.hash(x, y);                         // must use the SAME fields
}
```

**The fields used in `hashCode` must be a subset of those used in `equals`** — otherwise equal objects can hash differently.

## getClass() vs instanceof

| | `getClass() !=` | `instanceof` |
|---|---|---|
| Subclass equals superclass | Never | Possible |
| Symmetry with subclasses | **Guaranteed** | **Can break** |
| Liskov-friendly | Less | More |

The symmetry problem with `instanceof`:

```java
class Point { boolean equals(Object o) { return o instanceof Point && ...; } }
class ColorPoint extends Point { boolean equals(Object o) { ... also compares colour ... } }

point.equals(colorPoint);   // true  (Point only checks x, y)
colorPoint.equals(point);   // false (ColorPoint also checks colour)
// SYMMETRY VIOLATED
```

**Joshua Bloch's conclusion:** there's no way to extend an instantiable class and add a value component while preserving the `equals` contract. **Favour composition over inheritance for value types.** Saying this is a strong signal.

Java 16+ pattern matching cleans up the syntax:
```java
return o instanceof Point p && x == p.x && y == p.y;
```

## Mutable Keys — The Silent Bug

```java
Set<List<String>> set = new HashSet<>();
List<String> key = new ArrayList<>();
set.add(key);
key.add("x");              // hashCode changed
set.contains(key);         // false — the entry is stranded
set.remove(key);           // fails — and it can never be removed
```

The entry sits in the old bucket, unreachable and un-garbage-collectable. **Use immutable objects as keys**, or never mutate fields participating in `hashCode` after insertion.

## Records Do This For You

```java
record Point(int x, int y) { }
```

Java 16+ records auto-generate `equals`, `hashCode`, and `toString` over all components, correctly and consistently. **For value types, use a record** — it eliminates the entire class of bug.

## Bad hashCode Implementations

```java
public int hashCode() { return 1; }         // legal but catastrophic
```

Every object lands in one bucket. `HashMap` degrades to O(n) — or O(log n) since Java 8 treeifies large buckets, which is precisely the mitigation for hash-collision DoS attacks.

A good `hashCode` distributes evenly. `Objects.hash(...)` is fine for most cases; it allocates a varargs array, so hand-written `31 * result + field` is marginally faster in hot paths.

**Why 31?** It's an odd prime, and `31 * i` compiles to `(i << 5) - i` — a cheap shift and subtract.

## Comparable Consistency

`compareTo` should be **consistent with equals**: `x.compareTo(y) == 0` ⟺ `x.equals(y)`.

`BigDecimal` famously violates this: `new BigDecimal("1.0").equals(new BigDecimal("1.00"))` is `false`, but `compareTo` returns `0`. Consequently a `HashSet` and a `TreeSet` of `BigDecimal` behave differently — a classic trap question.

## Common Questions

- *Why override both?* — hashing finds the bucket, equals confirms the match.
- *What breaks if only equals is overridden?* — hash-based lookups fail.
- *`getClass()` or `instanceof`?* — `getClass()` preserves symmetry; `instanceof` is friendlier to subclassing but can break it.
- *Can two unequal objects share a hash code?* — yes, that's a collision.
- *Why 31?* — odd prime, and the JIT turns the multiply into a shift and subtract.
- *What happens with a mutable key?* — the entry becomes unreachable.

## Common Mistakes

- Overriding `equals` without `hashCode`
- `public boolean equals(MyType o)` — that's **overloading**, not overriding; the signature must take `Object`
- Different field sets in `equals` and `hashCode`
- Mutable objects as map keys
- Ignoring the `compareTo`/`equals` consistency requirement

## Related Topics

- [HashMap Internals](../Collections/HashMap%20Internals.md)
- [Collections Overview](../Collections/Collections%20Overview.md)
- [OOP Core Concepts](../../03%20Low%20Level%20Design/OOP%20Foundations/OOP%20Core%20Concepts.md)

## Revision Summary

Equal objects must have equal hash codes, or hash-based collections break. Use the same fields in both, prefer `getClass()` for symmetry, never use mutable objects as keys, and prefer records for value types.

## Quick Recall

- Override both, over the same fields
- `equals` must take `Object`, or it's an overload
- `getClass()` preserves symmetry; `instanceof` can break it
- Mutable key → stranded entry
- Records generate both correctly
- `BigDecimal` breaks compareTo/equals consistency
