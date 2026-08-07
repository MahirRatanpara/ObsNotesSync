# Pattern Matching and Control Flow

## Why It Matters

Pattern matching is the biggest change to Java's expressiveness since lambdas. It removes the `instanceof`-plus-cast ritual, makes switches exhaustive, and largely replaces the Visitor pattern.

## switch Expressions (Java 14+)

```java
// Old statement form — fallthrough, no value, verbose
switch (day) {
    case MONDAY:
    case TUESDAY: result = "early"; break;      // forget break → bug
    default: result = "late";
}

// Expression form — arrow labels, no fallthrough, returns a value
String result = switch (day) {
    case MONDAY, TUESDAY -> "early";            // multiple labels
    case WEDNESDAY       -> "mid";
    default              -> "late";
};
```

| Property | Arrow form |
|---|---|
| Fallthrough | **None** — no `break` needed |
| Returns a value | **Yes** |
| Multiple labels | `case A, B ->` |
| Exhaustiveness | **Required** for expressions |
| Scope | Each arm has its own scope |

**Use `yield` for a multi-statement arm:**
```java
int size = switch (category) {
    case SMALL -> 1;
    case LARGE -> {
        log.info("large item");
        yield 10;                    // yield, not return
    }
};
```

**`return` inside a switch expression returns from the enclosing *method*, which is illegal in an expression** — hence `yield`.

**Exhaustiveness is the real gain.** A switch *expression* must cover every case, so the compiler catches a missing branch. Over an enum, omit `default` deliberately: adding a constant then becomes a compile error rather than a silent fall-through to `default`.

## Pattern Matching for instanceof (Java 16+)

```java
// Old
if (obj instanceof String) {
    String s = (String) obj;        // redundant cast
    if (s.length() > 5) { ... }
}

// New — binding variable
if (obj instanceof String s && s.length() > 5) { ... }
```

**Flow scoping** is the clever part: the compiler knows exactly where the binding is definitely assigned.

```java
if (!(obj instanceof String s)) return;
// s IS in scope here — the compiler knows we returned otherwise
System.out.println(s.length());
```

This makes the guard-clause style work naturally, which the old cast form did not.

## Pattern Matching for switch (Java 21+)

```java
String describe(Object o) {
    return switch (o) {
        case null            -> "null";                     // explicit null case
        case Integer i when i > 100 -> "big number";        // GUARD
        case Integer i       -> "number " + i;
        case String s        -> "string of length " + s.length();
        case int[] arr       -> "int array of " + arr.length;
        default              -> "unknown";
    };
}
```

**Three things worth noting:**

1. **`case null` is now explicit.** Historically a `switch` on a null threw `NullPointerException`. It still does *unless* you add `case null` — so the behaviour is opt-in and backward compatible.
2. **Guards use `when`**, not `if`.
3. **Order matters.** Cases are tested top to bottom, so more specific patterns must come first. The compiler rejects a dominated case (an unreachable one after a broader pattern).

## Record Patterns (Java 21+)

Destructuring:

```java
record Point(int x, int y) { }
record Line(Point start, Point end) { }

// Simple
if (obj instanceof Point(int x, int y)) {
    System.out.println(x + "," + y);
}

// NESTED destructuring
switch (shape) {
    case Line(Point(var x1, var y1), Point(var x2, var y2)) ->
        Math.hypot(x2 - x1, y2 - y1);
    case Point p -> 0;
}
```

**Nested record patterns are where this becomes powerful** — extracting deep structure in one readable line that would otherwise be four levels of accessor calls and null checks.

`var` infers the component type; you may also name the type explicitly for documentation.

## Sealed Types + Patterns = Exhaustive Switches

```java
sealed interface Shape permits Circle, Square, Triangle { }

double area(Shape s) {
    return switch (s) {
        case Circle c   -> Math.PI * c.radius() * c.radius();
        case Square q   -> q.side() * q.side();
        case Triangle t -> 0.5 * t.base() * t.height();
    };                          // NO default — compiler verifies completeness
}
```

**Adding a new `Shape` breaks compilation everywhere it's switched on.** That's the point — a `default` would silently do the wrong thing for the new type.

**This combination replaces the [Visitor pattern](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Visitor.md)** with compile-time exhaustiveness and none of the double-dispatch ceremony. Saying that is a strong modern-Java signal.

## Text Blocks (Java 15+)

```java
String json = """
    {
      "name": "%s",
      "id": %d
    }
    """.formatted(name, id);
```

- Incidental leading whitespace is stripped based on the **closing delimiter's** indentation
- A trailing `\` suppresses the newline
- `\s` preserves a trailing space that would otherwise be stripped

**The closing-delimiter rule is the one to remember:** move the `"""` left and you keep more indentation.

## Enhanced for and var

```java
for (var entry : map.entrySet()) { }         // inferred
for (var i = 0; i < n; i++) { }              // legal but often less clear
```

**`var` is allowed for:** local variables with an initialiser, enhanced-for variables, try-with-resources, and lambda parameters (Java 11+, all-or-nothing).

**`var` is not allowed for:** fields, method parameters, return types, or without an initialiser.

**Use it when the type is obvious from the right-hand side.** `var users = new ArrayList<User>()` is clear; `var result = process(x)` is not.

## Labelled Break and Continue

```java
outer:
for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
        if (matrix[i][j] == target) break outer;    // exits BOTH loops
    }
}
```

**The legitimate alternative to a flag variable** in nested loops. Rare, but cleaner than `boolean found` when you need it. Extracting a method and returning is usually cleaner still.

## Operator Gotchas

```java
// Ternary unboxing NPE
Integer x = null;
Integer r = flag ? x : 0;          // NPE even when flag is TRUE
```
One branch is `int`, so the conditional's type is `int` and `x` is unboxed regardless of which branch is taken. **A genuinely surprising trap.**

```java
// Short-circuit vs bitwise
if (a != null && a.isValid())      // short-circuits — safe
if (a != null &  a.isValid())      // evaluates BOTH — NPE
```

```java
// Compound assignment hides a cast
byte b = 10;
b += 300;                          // compiles, truncates to 54
b = b + 300;                       // compile error
```

```java
// Increment order
int i = 0;
i = i++;                           // still 0 — the old value is assigned back
```

```java
// String switch on null
switch (s) { case "a" -> ...; }    // NPE if s is null, unless `case null` present
```

## Common Mistakes

- `break` forgotten in the old statement-form switch
- `return` instead of `yield` in a switch expression
- Adding `default` to an exhaustive enum switch, losing compile-time safety
- Ordering pattern cases from general to specific
- Forgetting `case null` and getting an NPE
- `var` where the type isn't obvious
- Bitwise `&` where `&&` was meant
- Ternary mixing `Integer` and `int`, causing an unboxing NPE

## Related Topics

- [Records Enums and Sealed Types](../OOP/Records%20Enums%20and%20Sealed%20Types.md)
- [Types, Primitives and Autoboxing](Types%2C%20Primitives%20and%20Autoboxing.md)
- [Modern Java Features](Modern%20Java%20Features.md)
- [Visitor](../../03%20Low%20Level%20Design/Design%20Patterns/Behavioural/Visitor.md)

## Revision Summary

Switch expressions eliminate fallthrough and require exhaustiveness; use `yield` for multi-statement arms. Pattern matching binds and casts in one step with flow scoping, and `switch` patterns add guards via `when` plus an explicit `case null`. Record patterns destructure, and sealed types make switches compiler-verified exhaustive — replacing Visitor.

## Quick Recall

- Arrow switch: **no fallthrough, returns a value, must be exhaustive**
- **`yield`, not `return`**, in a switch expression
- **Omit `default` on enum switches** so new constants break the build
- `instanceof String s` binds; **flow scoping** works with guard clauses
- Pattern switch: **guards use `when`**; `case null` is explicit
- **Record patterns destructure, including nested**
- Sealed + patterns = **exhaustive, replaces Visitor**
- Text block indentation is set by the **closing delimiter**
- Ternary with `Integer`/`int` can NPE on the untaken branch
