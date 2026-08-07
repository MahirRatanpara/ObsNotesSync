# Lambdas and Functional Interfaces

## Why It Matters

Lambdas underpin streams, `CompletableFuture`, and modern API design. The question that separates users from people who understand them is "how do lambdas actually compile?" — and the answer is not "anonymous classes".

## Functional Interfaces

An interface with exactly **one abstract method** (a SAM type).

```java
@FunctionalInterface
interface Validator<T> {
    boolean test(T value);                          // the SAM
    default Validator<T> negate() { ... }           // defaults don't count
    static <T> Validator<T> always() { ... }        // statics don't count
}
```

**Methods that override `Object`'s public methods don't count** either — which is why `Comparator` declares both `compare` and `equals` yet remains functional.

**`@FunctionalInterface` is optional but should always be used.** It makes the compiler reject a second abstract method, so nobody silently breaks every lambda that implements your interface.

## The Standard Families

| Interface | Signature | Use |
|---|---|---|
| `Function<T,R>` | `R apply(T)` | Transform |
| `BiFunction<T,U,R>` | `R apply(T,U)` | Two inputs |
| `Predicate<T>` | `boolean test(T)` | Filter |
| `Consumer<T>` | `void accept(T)` | Side effect |
| `Supplier<T>` | `T get()` | **Lazy production** |
| `UnaryOperator<T>` | `T apply(T)` | `Function<T,T>` |
| `BinaryOperator<T>` | `T apply(T,T)` | Reduce |
| `Runnable` | `void run()` | No input, no output |
| `Callable<V>` | `V call() throws Exception` | **Can throw checked** |

**Primitive variants exist to avoid boxing** — `IntPredicate`, `ToIntFunction`, `IntSupplier`, `ObjIntConsumer` and so on. In a stream over millions of elements, using `Function<Integer,Integer>` instead of `IntUnaryOperator` means millions of allocations.

**`Supplier` is the one people underuse.** It's how you defer work:
```java
optional.orElse(expensiveCall());      // ALWAYS evaluated
optional.orElseGet(this::expensiveCall); // evaluated only if empty
logger.debug(() -> buildExpensiveMessage()); // built only if DEBUG is on
```

## How Lambdas Actually Compile

**Not to anonymous classes.** This is the depth question.

```java
Runnable r = () -> System.out.println("hi");
```

The compiler:
1. Emits the lambda body as a **private static (or instance) synthetic method** in the enclosing class
2. Replaces the lambda expression with an **`invokedynamic`** instruction
3. At **first execution**, `LambdaMetafactory` spins up an implementing class and links the call site
4. Subsequent executions run through the now-linked, JIT-friendly call site

**Why this design rather than anonymous classes:**

| Benefit | Detail |
|---|---|
| **No class file per lambda** | Anonymous classes generate `Outer$1.class`, `Outer$2.class`… — thousands in a large codebase |
| **Faster startup** | Classes are created lazily, only if the lambda is reached |
| **Stateless lambdas are cached** | A non-capturing lambda reuses a single instance |
| **Future-proof** | The strategy can change without recompiling |

**Non-capturing lambdas are singletons:**
```java
Supplier<String> a = () -> "x";
Supplier<String> b = () -> "x";
// each call site has its own instance, but repeated evaluation of ONE site reuses it
```

A lambda inside a loop that captures nothing allocates **once**, not per iteration. A capturing lambda allocates per evaluation, because it must hold the captured values.

**Practical implication: prefer non-capturing lambdas in hot loops**, and be aware that a lambda capturing a loop variable allocates each time.

## Lambdas vs Anonymous Classes

| | Lambda | Anonymous class |
|---|---|---|
| Compiles to | **`invokedynamic`** | A real class file |
| `this` | **The enclosing instance** | **The anonymous instance** |
| Can have state | No | Yes (fields) |
| Can implement multiple methods | No | Yes |
| Shadowing enclosing names | **Not allowed** | Allowed |

**The `this` difference is the trap:**
```java
class Widget {
    void register() {
        Runnable lambda    = () -> System.out.println(this);   // the Widget
        Runnable anonymous = new Runnable() {
            public void run() { System.out.println(this); }    // the Runnable!
        };
    }
}
```

**A lambda is lexically scoped — it does not introduce a new `this`.** That's usually what you want, and it's why lambdas don't leak the enclosing instance the way inner classes do.

## Effectively Final Capture

```java
int counter = 0;
list.forEach(x -> counter++);   // COMPILE ERROR — not effectively final
```

A lambda may capture only variables that are **final or effectively final** (never reassigned after initialisation).

**Why:** local variables live on the stack, which disappears when the method returns. The lambda may outlive it, so the value is **copied** into the lambda. Allowing reassignment would make it ambiguous which copy is authoritative.

**Instance and static fields are not restricted** — they live on the heap and are captured by reference through `this`:
```java
class Counter {
    int count = 0;
    void run(List<String> l) { l.forEach(x -> count++); }   // legal
}
```

**The workarounds — and why they're usually wrong:**
```java
int[] counter = {0};
list.forEach(x -> counter[0]++);   // compiles, but it's mutation in disguise
```
This defeats the point. If you're accumulating, use `reduce`, a collector, or `count()`. Mutable capture also breaks silently under `parallelStream()`.

## Method References

Four kinds — knowing all four is a common question.

| Kind | Syntax | Equivalent lambda |
|---|---|---|
| **Static** | `Integer::parseInt` | `s -> Integer.parseInt(s)` |
| **Bound instance** | `System.out::println` | `x -> System.out.println(x)` |
| **Unbound instance** | `String::length` | `s -> s.length()` |
| **Constructor** | `ArrayList::new` | `() -> new ArrayList<>()` |

**Unbound is the subtle one:** `String::toUpperCase` becomes `Function<String,String>` where the receiver is the *first argument*. That's how `comparing(Person::getName)` works.

**Ambiguity is a compile error:** if a class has both a static and an instance method with the same name, `Type::method` won't compile.

## Composition

```java
Predicate<String> notEmpty = s -> !s.isEmpty();
Predicate<String> shortStr = s -> s.length() < 10;
notEmpty.and(shortStr);
notEmpty.or(shortStr);
notEmpty.negate();

Function<Integer,Integer> add1 = x -> x + 1;
Function<Integer,Integer> dbl  = x -> x * 2;
add1.andThen(dbl).apply(3);    // (3+1)*2 = 8
add1.compose(dbl).apply(3);    // (3*2)+1 = 7
```

**`andThen` runs left-to-right; `compose` runs right-to-left.** Confusing them is a common slip.

## Checked Exceptions — The Real Pain

```java
list.forEach(f -> Files.delete(f));   // WON'T COMPILE — IOException is checked
```

`Consumer.accept` doesn't declare a checked exception, so you cannot throw one from a lambda implementing it.

**Options:**
```java
// 1. Wrap (most common)
list.forEach(f -> {
    try { Files.delete(f); }
    catch (IOException e) { throw new UncheckedIOException(e); }
});

// 2. A throwing functional interface + adapter
@FunctionalInterface interface ThrowingConsumer<T> { void accept(T t) throws Exception; }
static <T> Consumer<T> unchecked(ThrowingConsumer<T> c) {
    return t -> { try { c.accept(t); } catch (Exception e) { throw new RuntimeException(e); } };
}
list.forEach(unchecked(Files::delete));

// 3. Use a plain loop
for (Path f : list) Files.delete(f);
```

**This friction is a large part of why checked exceptions are increasingly disliked** — they don't compose with lambdas or streams. Worth saying if asked about checked exceptions.

## Common Mistakes

- Mutable capture via a one-element array
- Assuming lambdas compile to anonymous classes
- Expecting `this` inside a lambda to mean the lambda
- Boxing functional interfaces in hot paths
- `orElse` with an expensive argument instead of `orElseGet`
- Confusing `andThen` and `compose`
- Long multi-statement lambdas that should be extracted methods
- Omitting `@FunctionalInterface`

## Related Topics

- [Streams](Streams.md)
- [Optional](Optional.md)
- [Abstract Classes and Interfaces](../OOP/Abstract%20Classes%20and%20Interfaces.md)
- [Nested and Inner Classes](../OOP/Nested%20and%20Inner%20Classes.md)

## Revision Summary

A functional interface has one abstract method. Lambdas compile to `invokedynamic` with `LambdaMetafactory` linking at first use — not to anonymous classes — which avoids a class file per lambda and lets non-capturing lambdas be cached. Capture requires effectively-final locals because the value is copied off the stack. `this` inside a lambda is the enclosing instance.

## Quick Recall

- SAM = one abstract method; `default`, `static` and `Object` methods don't count
- **Lambdas → `invokedynamic`, not anonymous classes**
- **Non-capturing lambdas are cached; capturing ones allocate**
- `this` in a lambda = **enclosing instance**; in an anonymous class = itself
- Capture requires **effectively final** — locals are copied off the stack
- Four method-reference kinds; **unbound puts the receiver first**
- `andThen` left-to-right, `compose` right-to-left
- Use primitive variants to avoid boxing
- **Checked exceptions don't compose with lambdas**
