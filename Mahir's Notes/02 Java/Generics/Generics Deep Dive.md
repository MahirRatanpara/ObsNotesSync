# Generics Deep Dive

## Why It Matters

Generics look simple until you write a library. Erasure, variance and wildcards explain every confusing compiler error, and PECS is a standard API-design question.

## Type Erasure

Generics are a **compile-time** feature. At runtime, type parameters are erased.

```java
List<String>  a = new ArrayList<>();
List<Integer> b = new ArrayList<>();
a.getClass() == b.getClass();       // TRUE — both are just ArrayList
```

**What erasure replaces type parameters with:**
- Unbounded `T` → `Object`
- Bounded `T extends Number` → `Number`
- Casts are inserted by the compiler at call sites

```java
// You write
List<String> list = new ArrayList<>();
String s = list.get(0);

// Runtime sees
List list = new ArrayList();
String s = (String) list.get(0);    // compiler-inserted cast
```

**Why erasure rather than reified generics:** **binary backward compatibility.** Java 5 needed pre-generics code and generic code to interoperate in the same JVM. C# chose reification because .NET generics arrived with a runtime change; Java couldn't break every existing class file.

### What erasure forbids

```java
new T();                            // no runtime type
new T[10];                          // same
T.class;                            // same
if (x instanceof List<String>)      // ILLEGAL — can only check raw List
catch (MyException<T> e)            // ILLEGAL — exceptions can't be generic
class Foo<T> { static T field; }    // ILLEGAL — statics are shared across all T
void f(List<String> l) { }
void f(List<Integer> l) { }         // ILLEGAL — same erasure
```

**Workarounds for instantiation:**
```java
// Class token
<T> T create(Class<T> type) throws Exception {
    return type.getDeclaredConstructor().newInstance();
}

// Supplier — cleaner, no reflection
<T> T create(Supplier<T> factory) { return factory.get(); }

// Array creation
@SuppressWarnings("unchecked")
T[] arr = (T[]) new Object[10];     // works if it never escapes as T[]
T[] arr = (T[]) Array.newInstance(componentType, 10);   // reflective, safer
```

## Invariance

```java
List<Object> list = new ArrayList<String>();   // COMPILE ERROR
```

**`List<String>` is not a subtype of `List<Object>`**, even though `String` is a subtype of `Object`.

**Why:** if it were allowed —
```java
List<Object> l = stringList;   // hypothetically
l.add(42);                     // would corrupt the String list
String s = stringList.get(0);  // ClassCastException at runtime
```

Generics chose **compile-time safety**. Arrays chose runtime checking:

```java
Object[] arr = new String[10];   // LEGAL — arrays are covariant
arr[0] = 42;                     // compiles, throws ArrayStoreException at RUNTIME
```

**Arrays are covariant and reified; generics are invariant and erased.** That contrast is a standard question, and it's why you should prefer `List` to arrays in generic code — the error arrives at compile time instead of in production.

## Wildcards and PECS

Invariance is too restrictive for APIs, so wildcards reintroduce flexible subtyping.

### Upper bound — `? extends T` — a **producer**

```java
double sum(List<? extends Number> numbers) {
    double total = 0;
    for (Number n : numbers) total += n.doubleValue();   // READ is safe
    // numbers.add(1);       // ILLEGAL
    return total;
}
sum(List.of(1, 2, 3));         // List<Integer> — accepted
sum(List.of(1.5, 2.5));        // List<Double>  — accepted
```

**Why you can't add:** the list might be a `List<Integer>`; adding a `Double` would corrupt it. The compiler knows only that the element type is *some* subtype of `Number`, not which. **You may add `null`, since null is a member of every type.**

### Lower bound — `? super T` — a **consumer**

```java
void addNumbers(List<? super Integer> list) {
    list.add(1);               // WRITE is safe
    list.add(2);
    Object o = list.get(0);    // reads come back as Object only
}
addNumbers(new ArrayList<Integer>());
addNumbers(new ArrayList<Number>());
addNumbers(new ArrayList<Object>());
```

**Why reads give `Object`:** the list could be `List<Object>`, so the only guaranteed supertype is `Object`.

### PECS

> **Producer Extends, Consumer Super**

If the parameter **produces** values you read → `extends`.
If it **consumes** values you write → `super`.
If it does **both** → use an exact type, no wildcard.

**The JDK's canonical example:**
```java
public static <T> void copy(List<? super T> dest, List<? extends T> src)
```
`src` produces, `dest` consumes. Both wildcards in one signature.

**Also:**
```java
Collections.max(Collection<? extends T> coll, Comparator<? super T> comp)
Stream.forEach(Consumer<? super T> action)
Optional.map(Function<? super T, ? extends U> mapper)
```

**Notice the pattern in functional interfaces:** parameters are `? super`, return types are `? extends`. That's PECS applied to functions, and it's why `Function<? super T, ? extends R>` appears everywhere in the JDK.

### Unbounded — `?`

```java
void printAll(List<?> list) {
    for (Object o : list) System.out.println(o);
    // list.add(anything);   // ILLEGAL except null
}
```

**`List<?>` is not `List<Object>`.** The former means "a list of some unknown type" (read-only); the latter means "a list that can hold anything" (writable).

## Bounded Type Parameters

```java
<T extends Comparable<T>> T max(List<T> list)                   // single bound
<T extends Number & Comparable<T>> void f(T t)                  // multiple bounds
```

**Rules for multiple bounds:** at most one class, which must come first; the rest are interfaces.

**Recursive generics** (`<T extends Comparable<T>>`) express "comparable to itself". Used for self-referential builders:
```java
abstract class Builder<T extends Builder<T>> {
    @SuppressWarnings("unchecked")
    protected T self() { return (T) this; }
    public T name(String n) { this.name = n; return self(); }
}
class PersonBuilder extends Builder<PersonBuilder> { }   // fluent chaining preserved
```

**This is the "curiously recurring generic pattern"** and it's how a fluent builder hierarchy keeps returning the concrete subtype.

## Generic Methods and Inference

```java
static <T> List<T> listOf(T... items) { ... }

List<String> l = listOf("a", "b");        // T inferred as String
List<String> l = Collections.<String>emptyList();   // explicit when inference fails
```

**Target typing:** since Java 8, inference uses the assignment context.
```java
List<String> empty = Collections.emptyList();   // infers String from the target
process(Collections.emptyList());               // infers from the parameter type
```

**The diamond** `new ArrayList<>()` infers from the declaration. Since Java 9 it also works with anonymous classes.

## Heap Pollution and @SafeVarargs

```java
static <T> List<T> listOf(T... items) {     // WARNING: possible heap pollution
    return Arrays.asList(items);
}
```

**Generic varargs create an array of a generic type**, which erasure makes unsound:
```java
static <T> T[] toArray(T... args) { return args; }

static <T> T[] pick(T a, T b) { return toArray(a, b); }
String[] s = pick("x", "y");    // ClassCastException — the array is actually Object[]
```

**`@SafeVarargs` asserts you only read from the array and never let it escape.** Applicable to `static`, `final` and `private` methods (and constructors) — not to overridable methods, since a subclass could break the promise.

## Bridge Methods

Erasure creates a signature mismatch when a generic method is overridden:

```java
class Node<T> { void set(T value) { } }
class StringNode extends Node<String> {
    @Override void set(String value) { }
}
```

After erasure, `Node.set` takes `Object` but `StringNode.set` takes `String` — different signatures, so overriding would break.

**The compiler generates a synthetic bridge method:**
```java
// synthetic, in StringNode
void set(Object value) { set((String) value); }
```

**Consequences:** bridge methods appear in reflection (`getDeclaredMethods` shows them; check `isBridge()`), and they're why a `ClassCastException` can occur inside a method you never wrote.

## Type Tokens

Erasure means you can't recover `T` at runtime — unless you capture it.

```java
// Simple token
<T> T parse(String json, Class<T> type)

// Super type token — captures a PARAMETERISED type
abstract class TypeRef<T> {
    final Type type = ((ParameterizedType) getClass()
        .getGenericSuperclass()).getActualTypeArguments()[0];
}
var ref = new TypeRef<List<String>>() {};   // anonymous subclass preserves the type
```

**Anonymous subclasses retain their generic superclass information in the class file**, which is the loophole. Jackson's `TypeReference` and Guava's `TypeToken` work exactly this way — worth naming.

## Raw Types

```java
List rawList = new ArrayList();      // pre-generics style
rawList.add("string");
rawList.add(42);                     // no check
List<String> typed = rawList;        // unchecked warning
String s = typed.get(1);             // ClassCastException at runtime
```

**Raw types exist only for backward compatibility.** Using one disables *all* generic checking for that reference, not just the one you skipped.

**`List<?>` is the safe alternative** when you genuinely don't know the type.

## Common Mistakes

- Expecting `T` to be available at runtime
- Assuming `List<String>` is a `List<Object>`
- Adding to a `? extends` collection
- Reading a specific type from a `? super` collection
- Using raw types
- `@SafeVarargs` on a method that lets the array escape
- Not using PECS in library signatures, forcing exact-type callers
- Confusing `List<?>` with `List<Object>`
- Using arrays where generics would catch the error at compile time

## Related Topics

- [Exceptions Deep Dive](../Exceptions/Exceptions%20Deep%20Dive.md)
- [Collections Overview](../Collections/Collections%20Overview.md)
- [Lambdas and Functional Interfaces](../Streams%20and%20Functional/Lambdas%20and%20Functional%20Interfaces.md)

## Revision Summary

Generics are erased for binary compatibility, which forbids `new T()`, generic arrays and `instanceof` on parameterised types. Generics are invariant, so wildcards restore flexibility: `extends` for producers you read, `super` for consumers you write. Bridge methods reconcile erasure with overriding, and type tokens recover types via anonymous subclasses.

## Quick Recall

- **Erasure exists for binary backward compatibility**
- No `new T()`, no `new T[]`, no `instanceof List<String>`, no generic exceptions
- **Generics invariant; arrays covariant** (`ArrayStoreException` at runtime)
- **PECS: Producer `extends` (read), Consumer `super` (write)**
- Can't add to `? extends`; can only read `Object` from `? super`
- `List<?>` ≠ `List<Object>`
- **Recursive generics** `<T extends Builder<T>>` for fluent hierarchies
- Generic varargs → heap pollution → `@SafeVarargs` (static/final/private only)
- **Bridge methods** reconcile erasure with overriding
- Type tokens use anonymous subclasses to retain the type
