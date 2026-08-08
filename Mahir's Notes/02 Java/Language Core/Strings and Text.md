# Strings and Text

## Why It Matters

Strings are the most-allocated object in most Java applications, and the most-asked language topic after collections. Immutability, the pool, and `StringBuilder` come up in nearly every Java round.

## Immutability

`String` is immutable. Every "modification" returns a new object.

```java
String s = "hello";
s.toUpperCase();          // returns a NEW string; s is unchanged
s = s.toUpperCase();      // reassignment, not mutation
```

**Why the JDK made it immutable:**

| Reason | Detail |
|---|---|
| **Thread safety** | Shared freely with no synchronisation |
| **Safe caching of `hashCode`** | Computed once, cached in a field |
| **The pool is only possible because of it** | Sharing requires immutability |
| **Security** | A file path or URL can't be mutated after validation |
| Class loading | Class names can't be tampered with mid-load |

**The security argument is the one to give.** If `String` were mutable, a caller could pass `"/safe/path"`, pass a security check, and then mutate it to `"/etc/passwd"` before the file is opened — a time-of-check-to-time-of-use attack.

**`hashCode` caching detail:** it's lazily computed and stored in a non-volatile `int` field. A benign data race — two threads may both compute it, but they compute the same value, so it's safe. This is the textbook example of a benign race.

## The String Pool

String **literals** are interned in a pool (in the heap since Java 7; previously in PermGen).

```java
String a = "hello";                  // pooled
String b = "hello";                  // same reference
String c = new String("hello");      // NEW object on the heap
String d = c.intern();               // returns the pooled instance

a == b;        // true
a == c;        // false
a == d;        // true
a.equals(c);   // true
```

**Always compare strings with `.equals()`.** `==` compares references and works only by accident when both operands happen to be pooled.

**Compile-time constant folding:**
```java
String x = "hel" + "lo";        // folded at COMPILE time → pooled → x == a is true
String y = getHel() + "lo";     // runtime concatenation → new object → y == a is false
final String h = "hel";
String z = h + "lo";            // h is a compile-time constant → folded → true
```

**`new String("hello")` is always wrong in real code** — it creates a redundant object. It exists in examples only to demonstrate the pool.

**`intern()` is rarely worth it.** It can reduce memory when you have many duplicate runtime-built strings, but the pool is a fixed-size hash table (`-XX:StringTableSize`) and heavy interning can slow it down. Measure first.

## String Concatenation

```java
// In a loop — QUADRATIC
String s = "";
for (String part : parts) s += part;    // new String each iteration: O(n²)

// Correct
StringBuilder sb = new StringBuilder();
for (String part : parts) sb.append(part);
String s = sb.toString();               // O(n)
```

**Why quadratic:** each `+=` allocates a new string and copies everything so far. For 10,000 parts you copy ~50 million characters.

**Single-expression concatenation is fine.** `"a" + b + "c"` compiles to an efficient form — since Java 9, via `invokedynamic` and `StringConcatFactory`, which the JIT optimises well. Before Java 9 it became a `StringBuilder` chain.

**The rule: concatenation in a loop is the problem, not concatenation itself.**

| Class               | Thread-safe        | Use                                       |
| ------------------- | ------------------ | ----------------------------------------- |
| `String`            | Yes (immutable)    | Values, keys, everything by default       |
| **`StringBuilder`** | **No**             | **Building strings — the default choice** |
| `StringBuffer`      | Yes (synchronized) | Legacy; almost never needed               |

**`StringBuffer` is a legacy class.** Its synchronisation is nearly always useless — a builder is almost always confined to one method. The JIT can also elide the locks via [escape analysis](../JVM%20and%20Memory/JIT%20and%20Escape%20Analysis.md), so the performance gap is smaller than folklore suggests — but `StringBuilder` remains correct.

**Pre-size when you know the length:** `new StringBuilder(1024)` avoids repeated array growth.

## Compact Strings (Java 9+)

Before Java 9, `String` stored a `char[]` — 2 bytes per character, even for pure ASCII.

Java 9 changed it to a `byte[]` plus a coder flag: **LATIN1** (1 byte/char) or **UTF16** (2 bytes/char).

**Most applications saw a 5–15% heap reduction with no code change** — one of the highest-impact JDK changes for memory. Worth knowing as a concrete example of a JVM-level optimisation.

## Text Blocks (Java 15+)

```java
String query = """
    SELECT o.id, c.name
      FROM orders o
      JOIN customers c ON c.id = o.customer_id
     WHERE o.status = ?
    """;
```

- Incidental leading whitespace is stripped based on the **closing delimiter's** indentation
- A trailing `\` suppresses the newline
- `\s` preserves a trailing space that would otherwise be stripped

Useful for SQL, JSON, HTML — anything previously written as escaped concatenation.

## Methods Worth Knowing

| Method | Notes |
|---|---|
| **`strip()`** vs `trim()` | `strip` is **Unicode-aware**; `trim` only removes ≤ U+0020 |
| `isBlank()` | Empty or whitespace-only |
| `isEmpty()` | Length zero only |
| `lines()` | Stream of lines — memory-efficient |
| `repeat(n)` | Java 11+ |
| `formatted(args)` | Instance-method form of `String.format` |
| `chars()` | `IntStream` of code units |
| `codePoints()` | `IntStream` of code **points** — correct for emoji |
| `join` | `String.join(", ", list)` |
| `split(regex)` | **Takes a regex**, not a literal |
| `matches`, `replaceAll` | **Regex**; `replace` is literal |

**`split` and `replaceAll` take regular expressions.** `"a.b".split(".")` returns an empty array because `.` matches everything. Use `split("\\.")` or `Pattern.quote(".")`.

**`strip` vs `trim` is a real difference:** `trim` predates Unicode awareness and won't remove a non-breaking space or ideographic space. Prefer `strip` in new code.

## Unicode — The Part People Get Wrong

Java `char` is a **UTF-16 code unit**, not a character. Characters outside the Basic Multilingual Plane (emoji, some CJK) use a **surrogate pair** — two `char` values.

```java
String emoji = "😀";
emoji.length();              // 2  — not 1!
emoji.charAt(0);             // half a surrogate pair — meaningless alone
emoji.codePointCount(0, emoji.length());  // 1 — correct
```

**`String.length()` returns code units, not characters.** Any code that truncates strings by `length()` will eventually split an emoji in half and produce mojibake.

**Use `codePoints()` when correctness matters** for user-visible text.

**Encoding:** always specify one. `new String(bytes)` uses the platform default, which differs between your laptop and the server.
```java
new String(bytes, StandardCharsets.UTF_8);   // explicit
```
Java 18+ defaults file encoding to UTF-8, which removes a long-standing class of bugs — but being explicit is still correct.

## Switching on Strings

```java
switch (command) {
    case "start" -> start();
    case "stop"  -> stop();
    default      -> unknown();
}
```

Compiles to a `hashCode` switch plus `equals` checks — efficient, not a linear scan. `null` throws `NullPointerException` unless you add `case null` (Java 21+).

## Regex Performance

`Pattern.compile` is expensive; `String.matches` recompiles every call.

```java
// BAD — recompiles on every invocation
if (input.matches("\\d{3}-\\d{4}")) { }

// GOOD — compile once, reuse
private static final Pattern PHONE = Pattern.compile("\\d{3}-\\d{4}");
if (PHONE.matcher(input).matches()) { }
```

**Catastrophic backtracking** is the security concern: a pattern with nested quantifiers like `(a+)+b` can take exponential time on a crafted input — a ReDoS attack. Avoid nested quantifiers on untrusted input.

## Common Mistakes

- `==` instead of `.equals()`
- Concatenating in a loop
- `split(".")` — regex, not literal
- Assuming `length()` counts characters
- `new String(bytes)` without a charset
- `StringBuffer` in new code
- Recompiling a regex on every call
- `new String("literal")`

## Related Topics

- [Types, Primitives and Autoboxing](Types%2C%20Primitives%20and%20Autoboxing.md)
- [equals and hashCode](Equals%20and%20HashCode.md)
- [JIT and Escape Analysis](../JVM%20and%20Memory/JIT%20and%20Escape%20Analysis.md)
- [JVM Architecture and Memory Areas](../JVM%20and%20Memory/JVM%20Architecture%20and%20Memory%20Areas.md)

## Revision Summary

Strings are immutable, which enables the pool, cached hash codes, thread safety, and security. Literals are pooled and constant-folded at compile time; always compare with `equals`. Build strings with `StringBuilder` — loop concatenation is quadratic. `length()` counts UTF-16 code units, so emoji count as two.

## Quick Recall

- Immutable → poolable, cacheable hash, thread-safe, **secure against TOCTOU**
- **`==` compares references — always use `.equals()`**
- Compile-time constants are folded and pooled; runtime concatenation isn't
- **Loop concatenation is O(n²)** → `StringBuilder`
- `StringBuffer` is legacy; `StringBuilder` by default
- Compact strings (Java 9) cut heap 5–15%
- **`split`/`replaceAll` take regex**; `replace` is literal
- `strip` is Unicode-aware; `trim` is not
- **`length()` is code units — emoji are 2**
- Precompile regex; beware catastrophic backtracking
