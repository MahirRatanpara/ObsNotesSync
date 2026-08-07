# Bytecode, Reflection and Method Handles

## Why It Matters

Every framework you use — Spring, Hibernate, Jackson, Mockito, JUnit — is built on these. Explaining how `@Autowired` or a dynamic proxy actually works requires them.

## Bytecode Basics

Java compiles to **platform-independent bytecode** executed by a **stack-based** VM (unlike the register-based Dalvik).

```java
int sum(int a, int b) { return a + b; }
```
```
iload_1        // push a
iload_2        // push b
iadd           // pop two, push sum
ireturn        // return top of stack
```

**Inspect with `javap -c -p ClassName`.** Genuinely useful for answering "what does this actually compile to?" — string concatenation, autoboxing, lambdas, and enhanced-for all become visible.

### The five invoke instructions

| Instruction | Dispatch |
|---|---|
| `invokestatic` | Static method — no receiver |
| `invokespecial` | Constructor, `private`, `super` — **no virtual dispatch** |
| **`invokevirtual`** | **Instance method — vtable lookup** |
| `invokeinterface` | Interface method — itable lookup, slightly slower |
| **`invokedynamic`** | **User-defined linkage — lambdas, string concat** |

**`invokedynamic` is the one that matters.** Added in Java 7 for dynamic languages, it lets the *call site* decide at first execution what to link to, via a bootstrap method.

**Lambdas use it:** `LambdaMetafactory` spins the implementing class at first execution. **Java 9+ string concatenation uses it too**, via `StringConcatFactory`, which is why `"a" + b + "c"` no longer compiles to a `StringBuilder` chain.

**This is why lambdas don't generate a class file per lambda** — see [Lambdas and Functional Interfaces](../Streams%20and%20Functional/Lambdas%20and%20Functional%20Interfaces.md).

## Reflection

Inspect and manipulate classes at runtime.

```java
Class<?> clazz = Class.forName("com.app.User");
Object instance = clazz.getDeclaredConstructor().newInstance();

Field f = clazz.getDeclaredField("name");
f.setAccessible(true);                     // bypass private
f.set(instance, "Mahir");

Method m = clazz.getDeclaredMethod("greet", String.class);
m.invoke(instance, "hello");

Annotation[] annotations = clazz.getAnnotations();
```

| Method pair | Difference |
|---|---|
| `getFields()` | **Public only**, including inherited |
| `getDeclaredFields()` | **All access levels**, this class only |

Same distinction for methods and constructors — a frequent source of "why can't it find my private field?"

### Costs

| Operation | Relative cost |
|---|---|
| Direct call | 1× |
| Reflective call (cached `Method`) | ~2–3× |
| **Reflective call (lookup each time)** | **~20×+** |
| `setAccessible(true)` | One-off, but blocked by modules |

**Cache `Method` and `Field` objects.** Looking them up per invocation is the expensive part, not the invocation itself. Every serious framework does this at startup.

**Other costs:** no compile-time type checking, no inlining by the JIT in the general case, obscured stack traces, and breakage under refactoring since names are strings.

### Modules block reflection

Since Java 9, `setAccessible` into another module's non-exported package throws `InaccessibleObjectException` unless the module opens it:

```java
module app { opens com.app.model to com.fasterxml.jackson.databind; }
```

Or the escape hatch at runtime: `--add-opens java.base/java.lang=ALL-UNNAMED`.

**This is the main breakage when migrating 8 → 17** — libraries that reflected into JDK internals stop working. See [Java Version Guide](../Modern%20Java/Java%20Version%20Guide%208%20to%2025.md).

## Dynamic Proxies

Generate an implementing class at runtime.

```java
Foo proxy = (Foo) Proxy.newProxyInstance(
    Foo.class.getClassLoader(),
    new Class<?>[]{ Foo.class },
    (p, method, args) -> {
        long start = System.nanoTime();
        try { return method.invoke(target, args); }
        finally { log.info("{} took {}ns", method.getName(), System.nanoTime() - start); }
    });
```

| Mechanism | Requires | Used by |
|---|---|---|
| **JDK dynamic proxy** | The target must implement an **interface** | Spring (when an interface exists) |
| **CGLIB / ByteBuddy** | Subclasses the class — must not be `final` | Spring (no interface), Mockito, Hibernate |

**This is how `@Transactional`, `@Cacheable`, `@Async` and `@PreAuthorize` work** — and why all four fail on self-invocation, private methods, and `final` classes. One mechanism, one set of limitations. See [Proxy](../../03%20Low%20Level%20Design/Design%20Patterns/Structural/Proxy.md).

## Method Handles

The modern, faster alternative to reflection (Java 7+).

```java
MethodHandles.Lookup lookup = MethodHandles.lookup();
MethodType type = MethodType.methodType(String.class, String.class);
MethodHandle mh = lookup.findVirtual(String.class, "concat", type);
String result = (String) mh.invokeExact("Hello, ", "world");
```

| | Reflection | Method handles |
|---|---|---|
| Access check | **On every call** | **Once, at lookup** |
| JIT optimisation | Poor | **Good — can be inlined** |
| Type safety | `Object[]` args | **`MethodType`-checked** |
| Ergonomics | Simple | Verbose |

**Access checking at lookup rather than per call is the key advantage**, and it's why method handles can be inlined while reflective calls generally can't.

**`invokeExact` requires exact type matching** — including the return type cast. `invoke` allows conversions but is slower. Getting this wrong throws `WrongMethodTypeException`, which is the usual first stumbling block.

## VarHandle

The supported replacement for `sun.misc.Unsafe` (Java 9+), giving fine-grained memory-ordering control.

```java
private static final VarHandle VALUE;
static {
    VALUE = MethodHandles.lookup().findVarHandle(Counter.class, "value", int.class);
}

VALUE.compareAndSet(this, expected, newValue);
VALUE.getAndAdd(this, 1);
VALUE.setRelease(this, x);        // release semantics — cheaper than volatile
VALUE.getAcquire(this);
```

**Five access modes:** plain, opaque, acquire/release, volatile, and the atomic update operations.

**You pay only for the barrier you need.** A `setRelease` is cheaper than a volatile write when you don't need full sequential consistency. This is what `java.util.concurrent` uses internally.

**If asked "what replaced `Unsafe`?" the answer is `VarHandle`** (for memory access) **and the Foreign Function & Memory API** (for off-heap memory).

## Annotations and Retention

```java
@Retention(RetentionPolicy.RUNTIME)     // visible via reflection
@Target(ElementType.METHOD)
public @interface Timed {
    String value() default "";
}
```

| Retention | Available |
|---|---|
| `SOURCE` | Compile only — `@Override`, Lombok |
| `CLASS` | In the class file, **not at runtime** (the default) |
| **`RUNTIME`** | **Visible to reflection** — required for Spring, JUnit, Jackson |

**Forgetting `@Retention(RUNTIME)` means your framework never sees the annotation.** The default is `CLASS`, which is almost never what you want for a custom annotation — a classic silent failure.

**Annotation processors** (`SOURCE` retention) run at compile time and generate code — Lombok, MapStruct, Dagger. **Zero runtime cost**, which is why they're preferred over reflection where possible.

## How Frameworks Use This

| Framework | Mechanism |
|---|---|
| **Spring DI** | Reflection to scan, instantiate, and inject |
| **Spring AOP** | JDK/CGLIB proxies |
| **Hibernate** | Proxies for lazy loading; reflection for field access |
| **Jackson** | Reflection, cached; annotation-driven |
| **JUnit 5** | Reflection to find and invoke `@Test` methods |
| **Mockito** | ByteBuddy to generate mock subclasses |
| Lombok | **Annotation processing** — compile-time AST manipulation |

**The performance pattern is universal: reflect once at startup, cache the handles, use the cached form thereafter.** That's why Spring startup is slow and steady-state is fast.

## Class Loading Interaction

Reflection resolves classes through a classloader, so **class identity is name + loader**. Two classloaders loading the same file produce distinct, incompatible types — the source of confusing `ClassCastException`s in app servers. See [Class Loading](Class%20Loading.md).

## Common Mistakes

- Reflection in a hot path without caching `Method`/`Field`
- `getFields()` when you meant `getDeclaredFields()`
- Custom annotations without `@Retention(RUNTIME)`
- Assuming `setAccessible` always works — modules block it
- Expecting proxies to intercept self-invocation, private or final methods
- `invokeExact` with a mismatched signature
- Using `Unsafe` instead of `VarHandle`
- Reflection where an interface or a factory would do

## Related Topics

- [Class Loading](Class%20Loading.md)
- [JIT and Escape Analysis](JIT%20and%20Escape%20Analysis.md)
- [Proxy](../../03%20Low%20Level%20Design/Design%20Patterns/Structural/Proxy.md)
- [Spring Transactions and AOP](../../14%20Spring%20Boot/Spring%20Transactions%20and%20AOP.md)

## Revision Summary

Bytecode is stack-based with five invoke instructions, of which `invokedynamic` powers lambdas and modern string concatenation. Reflection is flexible but costly and blocked by the module system; cache `Method` objects. Dynamic proxies underpin Spring AOP and explain its self-invocation limitation. Method handles and `VarHandle` are the faster, supported successors to reflection and `Unsafe`.

## Quick Recall

- Stack-based bytecode; inspect with **`javap -c -p`**
- **`invokedynamic` powers lambdas and Java 9+ string concat**
- `getFields` = public + inherited; `getDeclaredFields` = all access, this class
- **Cache `Method`/`Field`** — lookup is the expensive part
- Modules block `setAccessible` → `opens` or `--add-opens`
- JDK proxy needs an interface; CGLIB subclasses (no `final`)
- **Proxies explain why `@Transactional` fails on self-invocation**
- Method handles check access **once at lookup** and can be inlined
- **`VarHandle` replaced `Unsafe`**; five memory-ordering modes
- **Custom annotations need `@Retention(RUNTIME)`**
