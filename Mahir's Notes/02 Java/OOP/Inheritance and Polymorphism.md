# Inheritance and Polymorphism

## Why It Matters

Dispatch rules decide which method actually runs, and Java's answer is subtler than "the most specific one". Overload-versus-override questions separate people who know Java from people who know object-oriented syntax.

## The Two Kinds of Polymorphism

| | **Overloading** | **Overriding** |
|---|---|---|
| Also called | Compile-time, static, ad-hoc | Runtime, dynamic, subtype |
| Resolved by | **Compile-time (declared) type** | **Runtime (actual) type** |
| Signature | Must **differ** | Must **match** |
| Return type | May differ freely | Must be same or **covariant** |
| Access | Any | **Cannot narrow** |
| Applies to `static` | Yes | **No — that's hiding** |

## Overloading Is Resolved Statically

```java
void print(Object o) { System.out.println("Object"); }
void print(String s) { System.out.println("String"); }

Object x = "hello";
print(x);       // prints "Object" — chosen by the DECLARED type
print("hello"); // prints "String"
```

**The compiler picks the overload from the static type; the runtime type is irrelevant.** This surprises people because overriding behaves the opposite way.

**Resolution order** when several overloads could match:

1. **Widening** primitive conversion (`int` → `long`)
2. **Boxing/unboxing** (`int` → `Integer`)
3. **Varargs**

```java
void f(long x)      { }
void f(Integer x)   { }
void f(int... x)    { }

f(5);   // calls f(long) — widening beats boxing beats varargs
```

**This is why `list.remove(1)` removes an index rather than a value** — `remove(int)` matches exactly, so it wins over `remove(Object)`.

**Ambiguity is a compile error**, not a silent choice:
```java
void g(Integer i) { }
void g(Long l)    { }
g(5);   // ERROR — int boxes to Integer, but neither is more specific after boxing
```

## Overriding Is Resolved Dynamically

```java
class Animal { void speak() { System.out.println("..."); } }
class Dog extends Animal { @Override void speak() { System.out.println("Woof"); } }

Animal a = new Dog();
a.speak();      // "Woof" — chosen by the ACTUAL type
```

Java uses a **vtable** (virtual method table): each class has a table of method pointers, and an instance carries a pointer to its class's table. Dispatch is an indirect call through it — a few nanoseconds.

**The JIT often devirtualises** when only one implementation is loaded, turning the virtual call into a direct (and inlinable) one. If a second implementation loads later, the code is deoptimised and recompiled. See [JIT and Escape Analysis](../JVM%20and%20Memory/JIT%20and%20Escape%20Analysis.md).

### The overriding rules

| Rule | Detail |
|---|---|
| Signature | Must match exactly |
| **Return type** | Same, or a **subtype** (covariant) |
| **Access modifier** | May widen, **never narrow** |
| **Checked exceptions** | May throw fewer/narrower, **never broader** |
| `final` methods | Cannot be overridden |
| `private` methods | Not inherited — **not overridable** |
| `static` methods | **Hidden**, not overridden |

**Covariant return types** let a subclass return something more specific:
```java
class Animal { Animal reproduce() { ... } }
class Dog extends Animal { @Override Dog reproduce() { ... } }   // legal
```

**Always use `@Override`.** It's not decoration — it catches typos and signature drift at compile time. Without it, `equals(MyType o)` silently becomes an overload rather than an override, which is one of the most common Java bugs.

## What Is Not Polymorphic

**Three things are resolved by the static type, not the runtime type:**

### 1. Fields — hidden, not overridden

```java
class A { String name = "A"; }
class B extends A { String name = "B"; }

A obj = new B();
obj.name;              // "A"  — field access uses the DECLARED type
((B) obj).name;        // "B"
```

**Never shadow fields.** There is no legitimate reason, and it produces code that behaves differently depending on the reference type used.

### 2. Static methods — hidden

```java
class A { static void hello() { System.out.println("A"); } }
class B extends A { static void hello() { System.out.println("B"); } }

A obj = new B();
obj.hello();      // "A" — resolved statically; also a compiler warning
```

Call static methods on the class (`A.hello()`), never on an instance.

### 3. Private methods — not inherited

A subclass "override" of a private method is an unrelated new method. This is why calling a private `@Transactional` method does nothing in Spring — but the deeper reason there is [proxying](../../03%20Low%20Level%20Design/Design%20Patterns/Structural/Proxy.md).

## Initialisation Order

Asked frequently, and easy to get wrong.

```
1. Static fields and static blocks of the SUPERCLASS   (once, at class init)
2. Static fields and static blocks of the SUBCLASS     (once)
3. Instance fields and instance blocks of the SUPERCLASS
4. SUPERCLASS constructor body
5. Instance fields and instance blocks of the SUBCLASS
6. SUBCLASS constructor body
```

**Within each category, textual order applies.**

```java
class Base {
    { System.out.println("base instance block"); }
    Base() { System.out.println("base ctor"); init(); }
    void init() { System.out.println("base init"); }
}
class Derived extends Base {
    String value = "set";
    { System.out.println("derived instance block"); }
    Derived() { System.out.println("derived ctor"); }
    @Override void init() { System.out.println("derived init, value = " + value); }
}
new Derived();
```

Output:
```
base instance block
base ctor
derived init, value = null      ← THE TRAP
derived instance block
derived ctor
```

**Calling an overridable method from a constructor is a serious bug.** The subclass override runs *before* the subclass's fields are initialised, so it sees `null`/`0`. **Never call a non-final, non-private method from a constructor.**

## this() and super()

- A constructor may call **either** `this(...)` **or** `super(...)`, and it must be the **first statement**
- If neither is written, the compiler inserts `super()` — which fails to compile if the superclass has no no-arg constructor
- `this()` chaining must eventually reach a constructor that calls `super()`

## Composition Over Inheritance

| | Inheritance | Composition |
|---|---|---|
| Relationship | is-a | has-a |
| Binding | **Compile-time, fixed** | **Runtime, swappable** |
| Coupling | **Tight** — depends on superclass internals | Loose |
| Multiple sources | One class only | Any number |
| Testability | Harder | **Easier — inject a fake** |

**Three reasons to prefer composition:**

1. **The fragile base class problem** — changing a superclass silently breaks subclasses that depended on its internal call sequence. The classic example is `HashSet.addAll` calling `add`, so a subclass counting both double-counts.
2. **Combinatorial explosion** — behaviours A, B, C in any combination need 2³ subclasses but only 3 composed components.
3. **Rigidity** — you can't change a superclass at runtime; you can swap a strategy.

**Use inheritance only when:** it's a genuine is-a, the subtype honours [Liskov](../SOLID/SOLID%20Principles.md), and the hierarchy is shallow and stable.

**Design for inheritance or forbid it.** Either document precisely which methods may be overridden and how they're called internally, or make the class `final`. An undocumented, non-final class is a maintenance hazard.

## Liskov In Practice

A subtype must be usable anywhere the supertype is, without surprising the caller:

- Don't strengthen preconditions
- Don't weaken postconditions
- Preserve invariants
- Don't throw new checked exceptions

**`UnsupportedOperationException` in an override is an LSP violation** — and `Arrays.asList().add()` is exactly that, in the JDK itself.

## Common Mistakes

- Omitting `@Override`
- Shadowing fields
- Calling static methods through an instance
- **Calling an overridable method from a constructor**
- Assuming fields are polymorphic
- Deep hierarchies (three or more levels)
- Inheriting to reuse code rather than to model an is-a relationship
- Non-final classes with no guidance on safe subclassing

## Related Topics

- [Abstract Classes and Interfaces](Abstract%20Classes%20and%20Interfaces.md)
- [Object Class Contract](Object%20Class%20Contract.md)
- [OOP Core Concepts](../../03%20Low%20Level%20Design/OOP%20Foundations/OOP%20Core%20Concepts.md)
- [SOLID Principles](../../03%20Low%20Level%20Design/SOLID/SOLID%20Principles.md)

## Revision Summary

Overloading is resolved from the declared type at compile time; overriding from the actual type at runtime via a vtable. Fields, statics and privates are never polymorphic. Initialisation runs superclass-first, which is why calling an overridable method from a constructor sees uninitialised subclass fields. Prefer composition.

## Quick Recall

- **Overloading → declared type; overriding → actual type**
- Resolution: **widening → boxing → varargs**
- **Fields, `static` and `private` are not polymorphic**
- Covariant returns allowed; access may widen, never narrow
- **Always `@Override`** — it catches silent overloads
- Init order: static (super→sub) → instance (super) → super ctor → instance (sub) → sub ctor
- **Never call an overridable method from a constructor**
- Composition: runtime-swappable, testable, no fragile base class
- `UnsupportedOperationException` override = LSP violation
