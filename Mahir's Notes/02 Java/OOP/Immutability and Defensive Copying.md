# Immutability and Defensive Copying

## Why It Matters

Immutable objects are inherently thread-safe, cacheable, and safe as map keys. Building one correctly requires more than adding `final` — and interviewers ask precisely because most attempts leak.

## The Five Rules

To make a class genuinely immutable:

1. **Make the class `final`** (or all constructors private with static factories) — otherwise a subclass can add mutable state
2. **Make all fields `private final`**
3. **No setters**, and no method that mutates state
4. **Defensively copy mutable inputs** in the constructor
5. **Defensively copy mutable outputs** in getters

**Rules 4 and 5 are the ones people forget**, and they're what separates a real immutable class from a naive one.

## The Naive Version Leaks

```java
public final class Period {
    private final Date start;
    private final Date end;

    public Period(Date start, Date end) {
        this.start = start;      // NO COPY
        this.end = end;
    }
    public Date getStart() { return start; }   // NO COPY
}

// Attack 1 — mutate through the caller's reference
Date start = new Date();
Period p = new Period(start, end);
start.setTime(0);                 // p.start CHANGED

// Attack 2 — mutate through the returned reference
p.getStart().setTime(0);          // p.start CHANGED again
```

**The object was never immutable.** `final` protects the *reference*, not the object it points at.

## The Correct Version

```java
public final class Period {
    private final Date start;
    private final Date end;

    public Period(Date start, Date end) {
        this.start = new Date(start.getTime());     // defensive copy IN
        this.end   = new Date(end.getTime());
        if (this.start.after(this.end))             // validate the COPIES
            throw new IllegalArgumentException("start after end");
    }

    public Date getStart() { return new Date(start.getTime()); }   // copy OUT
    public Date getEnd()   { return new Date(end.getTime()); }
}
```

**Validate the copies, not the parameters.** Otherwise a hostile caller can mutate the object between your check and your copy — a time-of-check-to-time-of-use attack on your own constructor.

```java
// WRONG — TOCTOU window
if (start.after(end)) throw ...;      // check the caller's object
this.start = new Date(start.getTime()); // copy AFTER — caller may have mutated it
```

## Collections Need Copying Too

```java
public final class Team {
    private final List<Player> players;

    public Team(List<Player> players) {
        this.players = List.copyOf(players);          // immutable COPY
        // NOT: Collections.unmodifiableList(players) — that's a VIEW
    }

    public List<Player> getPlayers() { return players; }   // already immutable
}
```

**`Collections.unmodifiableList` is a view, not a copy.** The caller keeps a reference to the backing list and can still mutate it, which changes your "immutable" object.

```java
List<Player> src = new ArrayList<>(...);
List<Player> view = Collections.unmodifiableList(src);
src.add(newPlayer);          // view NOW SEES the new player
```

**`List.copyOf` (Java 10+) makes a genuine immutable copy** and is the correct choice. It also short-circuits if the input is already an immutable `List.of` instance.

**Deep vs shallow:** copying the list still shares the *elements*. If `Player` is mutable, the team is still mutable through its players. **Immutability is only as deep as the object graph** — which is the strongest argument for making value types immutable all the way down.

## Java's Immutable Types

`String`, all primitive wrappers, `BigDecimal`, `BigInteger`, `LocalDate`, `Instant`, `Duration`, `UUID`, `Path`, `List.of`/`Map.of`/`Set.of`, records with immutable components, enums.

**`Date` and `Calendar` are mutable and legacy** — the reason `java.time` exists. **`java.util.Date` is the standard example** of a type that should have been immutable.

## Records Do Most of This

```java
public record Period(LocalDate start, LocalDate end) {
    public Period {                                   // compact constructor
        Objects.requireNonNull(start);
        if (start.isAfter(end)) throw new IllegalArgumentException();
    }
}
```

Records give you `final` fields, no setters, and correct `equals`/`hashCode`/`toString` automatically.

**But records are only shallowly immutable.** A record with a `List` component still exposes the caller's mutable list:

```java
record Team(String name, List<Player> players) { }   // NOT immutable

// Fix — copy in the compact constructor
record Team(String name, List<Player> players) {
    Team {
        players = List.copyOf(players);              // reassigning the PARAMETER
    }
}
```

**In a compact constructor you assign to the parameter, not `this.field`** — the compiler assigns the (possibly modified) parameters to fields afterwards. That's the idiom, and it's non-obvious.

**A record with a mutable component is a common interview trap.** The answer is: records are shallowly immutable; deep immutability requires copying in the compact constructor.

## Why Immutability Matters

| Benefit | Detail |
|---|---|
| **Thread safety** | No synchronisation needed, ever — safely shared |
| **Safe as map keys** | `hashCode` can't change, so entries can't be stranded |
| **Cacheable `hashCode`** | Compute once — `String` does exactly this |
| **Free to share** | No defensive copies needed by *callers* |
| **Failure atomicity** | An operation either produces a valid new object or throws |
| **Security** | No TOCTOU on validated data |

**Safe publication:** an immutable object with `final` fields is guaranteed visible to other threads without synchronisation, provided `this` doesn't escape the constructor. That's a JMM guarantee specific to `final` fields, and a good detail to cite. See [Java Memory Model](../JVM%20and%20Memory/Java%20Memory%20Model.md).

**The `this`-escape caveat matters:** registering a listener or starting a thread in a constructor publishes a partially-constructed object and voids the final-field guarantee.

## The Cost

| Cost | Mitigation |
|---|---|
| Allocation per change | The JIT often removes it via [escape analysis](../JVM%20and%20Memory/JIT%20and%20Escape%20Analysis.md) |
| Copying large structures | **Persistent data structures** — share unchanged parts |
| Defensive copies on every accessor | Return an already-immutable type instead |

**Persistent data structures** (as in Clojure, or Java's `List.of` internals) share structure between versions, so "copying" is O(log n) rather than O(n). Worth naming when someone objects that immutability is too expensive.

## Copy Constructors and Wither Methods

```java
public Period withEnd(LocalDate newEnd) {
    return new Period(this.start, newEnd);      // new object, original untouched
}
```

**The `withX` naming convention** signals "returns a modified copy". Records pair naturally with it, and it's how `java.time` works (`plusDays`, `withYear`).

## Effectively Immutable

An object that is technically mutable but never mutated after publication. Safe **only** if publication is safe — via a `volatile` field, a `final` field, an `AtomicReference`, or a concurrent collection.

**Genuinely immutable is safer**, because it doesn't depend on every future maintainer honouring an unwritten rule.

## Common Mistakes

- `final` fields holding mutable objects, with no copying
- `Collections.unmodifiableList` instead of `List.copyOf`
- Validating parameters instead of the copies (TOCTOU)
- Forgetting the class must be `final`
- Assuming a record with a `List` component is immutable
- Letting `this` escape the constructor
- Deep structures where only the top level is immutable

## Related Topics

- [Object Class Contract](Object%20Class%20Contract.md)
- [Java Memory Model](../JVM%20and%20Memory/Java%20Memory%20Model.md)
- [equals and hashCode](../Language%20Core/Equals%20and%20HashCode.md)
- [Concurrency in LLD](../../03%20Low%20Level%20Design/Concurrency%20in%20LLD/Concurrency%20in%20LLD.md)

## Revision Summary

Immutability requires a final class, private final fields, no mutators, and defensive copies both in and out. Validate the copies, not the parameters. `unmodifiableList` is a view; use `List.copyOf`. Records are shallowly immutable — copy mutable components in the compact constructor. Immutable objects with final fields are safely published without synchronisation.

## Quick Recall

- Five rules: final class, private final fields, no setters, **copy in, copy out**
- **`final` protects the reference, not the object**
- **Validate the copy, not the parameter** — TOCTOU
- **`unmodifiableList` is a view; `List.copyOf` is a copy**
- **Records are shallowly immutable** — copy in the compact constructor
- Compact constructor assigns to the **parameter**, not `this.field`
- Final fields are safely published — unless `this` escapes
- Immutable → thread-safe, cacheable hash, safe map key
