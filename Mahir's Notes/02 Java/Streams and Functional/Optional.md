# Optional

## Why It Matters

Misusing `Optional` is more common than using it well. It exists for one narrow purpose, and interviewers ask because most codebases get it wrong.

## What It Is For

**`Optional<T>` is a return type that makes "there may be no result" explicit in the method signature.**

```java
Optional<User> findByEmail(String email);    // the signature tells you it may be empty
User           findByEmail(String email);    // does this return null? who knows
```

**That's the entire purpose.** Brian Goetz (Java language architect) stated it directly: `Optional` was designed to provide a limited mechanism for library method return types where there needed to be a clear way to represent "no result".

**It is not:**
- A general null replacement
- A field type
- A parameter type
- A collection element type

## Correct Usage

```java
// Creation
Optional.of(value);              // NPE if value is null
Optional.ofNullable(maybeNull);  // empty if null
Optional.empty();

// Consumption — functional, not imperative
user.map(User::name).orElse("Anonymous");
user.filter(u -> u.isActive()).map(User::email);
user.ifPresent(this::send);
user.ifPresentOrElse(this::send, this::logMissing);     // Java 9+
user.orElseThrow(() -> new UserNotFound(email));
user.orElseThrow();                                     // NoSuchElementException, Java 10+
user.or(() -> findInBackup(email));                     // Java 9+
user.stream();                                          // 0 or 1 element, Java 9+
```

## The Anti-Patterns

### 1. isPresent + get

```java
// BAD — this is just a null check with extra ceremony
if (opt.isPresent()) { use(opt.get()); }

// GOOD
opt.ifPresent(this::use);
```

**If you write `.get()`, you've almost certainly missed a better method.** `get()` was even renamed conceptually — `orElseThrow()` is now the preferred spelling for the same behaviour, precisely because `get()` invited unchecked calls.

### 2. Optional as a field

```java
class User {
    private Optional<String> middleName;   // WRONG
}
```

**Why it's wrong:**
- `Optional` is **not `Serializable`**
- Adds an object header plus a pointer per field — real memory cost at scale
- Fields can be null anyway, so you've added a wrapper without removing the problem
- Frameworks (JPA, Jackson) handle it inconsistently

**Use a nullable field and return `Optional` from the getter:**
```java
private String middleName;                                    // nullable field
public Optional<String> middleName() { return Optional.ofNullable(middleName); }
```

### 3. Optional as a parameter

```java
void process(Optional<Config> config);      // WRONG

// The caller now has to write:
process(Optional.empty());                  // noise
process(Optional.of(cfg));                  // more noise
```

**Use overloads instead:**
```java
void process();
void process(Config config);
```

**And note: an `Optional` parameter can itself be null**, so you've gained nothing while forcing ceremony on every caller.

### 4. orElse with an expensive argument

```java
opt.orElse(expensiveDefault());      // ALWAYS evaluated, even when present
opt.orElseGet(this::expensiveDefault); // evaluated only when empty
```

**This is the single most common performance mistake with `Optional`.** `orElse` takes a value, so the argument is computed before the call regardless. `orElseGet` takes a `Supplier`.

**Rule: use `orElse` only for constants; `orElseGet` for anything computed.**

### 5. Optional in collections

```java
List<Optional<String>> results;      // WRONG — nested emptiness
Map<String, Optional<User>> cache;   // WRONG — a missing key is already "empty"
```

A `Map` already expresses absence through a missing key. Wrapping the value adds a second, redundant notion of "absent" — and now you must handle three states instead of two.

**Filter empties out instead:**
```java
List<String> present = optionals.stream().flatMap(Optional::stream).toList();
```

### 6. Returning null from an Optional method

```java
Optional<User> find(String id) {
    return null;      // catastrophic — defeats the entire point
}
```

Callers will chain `.map(...)` and get an NPE from the thing designed to prevent NPEs.

## map vs flatMap

Same relationship as everywhere else in Java.

```java
Optional<User> user = findUser(id);

user.map(User::address);            // Optional<Address>              — getAddress returns Address
user.map(User::findAddress);        // Optional<Optional<Address>>    — WRONG, nested
user.flatMap(User::findAddress);    // Optional<Address>              — flattened
```

**Use `flatMap` when the mapping function itself returns an `Optional`.** Identical to `Stream.flatMap` and `CompletableFuture.thenCompose`.

## Chaining

```java
String city = findUser(id)
    .flatMap(User::address)        // returns Optional<Address>
    .map(Address::city)
    .filter(c -> !c.isBlank())
    .orElse("Unknown");
```

**This is where `Optional` earns its place** — a null-safe chain without nested null checks. The equivalent imperative code is four nested `if` statements.

## Optional Is Not Free

| Cost | Detail |
|---|---|
| Allocation | An object per call, unless the JIT eliminates it |
| Indirection | An extra pointer hop |
| **Escape analysis often removes it** | In hot paths, for non-escaping instances |

**Don't use it in genuinely hot loops** where you've measured it to matter. Everywhere else, correctness beats the nanoseconds.

**No primitive specialisation exists in practice** — `OptionalInt`, `OptionalLong` and `OptionalDouble` exist but lack `map`/`flatMap`, so they're used almost exclusively as stream terminal-operation return types.

## Optional and Streams

```java
// Terminal operations returning Optional
stream.findFirst();
stream.findAny();
stream.max(comparator);
stream.min(comparator);
stream.reduce(accumulator);

// Optional.stream() — flatten away empties (Java 9+)
List<User> users = ids.stream()
    .map(this::findUser)          // Stream<Optional<User>>
    .flatMap(Optional::stream)    // Stream<User> — empties dropped
    .toList();
```

**`Optional::stream` is the clean way to filter empties**, replacing `.filter(Optional::isPresent).map(Optional::get)`.

## When Not to Use It

| Situation | Use instead |
|---|---|
| A collection that may be empty | **An empty collection, never `Optional<List<T>>`** |
| A field | Nullable field, `Optional` getter |
| A parameter | Overloads |
| Inside a `Map` value | A missing key |
| An array | Empty array |

**"Never return `Optional<List<T>>`" is worth stating.** An empty list already means "nothing"; wrapping it forces callers to handle two kinds of nothing.

## Common Questions

- *Why not use it as a field?* — not `Serializable`, memory overhead, frameworks handle it inconsistently, fields can be null anyway.
- *`orElse` vs `orElseGet`?* — `orElse` evaluates eagerly; use `orElseGet` for anything computed.
- *`map` vs `flatMap`?* — `flatMap` when the function already returns an `Optional`.
- *Does it eliminate NPEs?* — no. It makes absence explicit in signatures; you can still deref badly or return null.
- *Should every method return `Optional`?* — no. Only where absence is a normal, expected outcome.

## Common Mistakes

- `isPresent()` + `get()`
- `Optional` fields, parameters, or collection elements
- `orElse` with an expensive argument
- Returning `null` from an `Optional`-returning method
- `Optional<List<T>>` instead of an empty list
- `get()` without checking
- Using it in measured hot paths

## Related Topics

- [Streams](Streams.md)
- [Lambdas and Functional Interfaces](Lambdas%20and%20Functional%20Interfaces.md)
- [Collectors and Advanced Streams](Collectors%20and%20Advanced%20Streams.md)
- [Exceptions Deep Dive](../Exceptions/Exceptions%20Deep%20Dive.md)

## Revision Summary

`Optional` exists to make absence explicit in return types — not as a general null replacement. Never use it for fields, parameters, or collection elements. Compose with `map`, `flatMap`, `filter` and `orElseGet` rather than `isPresent` plus `get`, and remember `orElse` evaluates its argument eagerly.

## Quick Recall

- **Return types only** — never fields, parameters, or collection elements
- **`isPresent()` + `get()` is a code smell** — use `ifPresent`/`map`/`orElseThrow`
- **`orElse` evaluates eagerly; `orElseGet` is lazy**
- `flatMap` when the mapper already returns `Optional`
- **Never return `Optional<List<T>>`** — return an empty list
- Not `Serializable`; costs an allocation
- `Optional::stream` flattens empties away
- **Never return `null` from an `Optional` method**
