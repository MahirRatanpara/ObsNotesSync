### [Chat GPT Ref](https://chatgpt.com/c/684c6adc-a640-8009-a953-4df96ba55d18)
# Java Inheritance: Class vs Abstract Class vs Interface

## 📌 Overview

Java supports inheritance through:
- **Classes**
- **Abstract classes**
- **Interfaces**

Inheritance promotes **code reuse**, **polymorphism**, and **extensibility**.

---

## 🔷 1. Inheritance Using Class

### ✅ Syntax
```java
class Parent { }

class Child extends Parent { }
```

### ✅ Example
```java
class Animal {
    void eat() { System.out.println("Animal eats"); }
}

class Dog extends Animal {
    void bark() { System.out.println("Dog barks"); }
}
```

---

## 🔷 2. Inheritance Using Abstract Class

### ✅ Syntax
```java
abstract class Vehicle {
    abstract void start();
    void fuelType() { System.out.println("Fuel"); }
}

class Car extends Vehicle {
    void start() { System.out.println("Starts with key"); }
}
```

---

## 🔷 3. Inheritance Using Interface

### ✅ Syntax
```java
interface Flyable {
    void fly();
}

class Bird implements Flyable {
    public void fly() { System.out.println("Bird flies"); }
}
```

### ✅ Multiple Inheritance with Interfaces
```java
interface A { void methodA(); }
interface B { void methodB(); }

class C implements A, B {
    public void methodA() { ... }
    public void methodB() { ... }
}
```

---

## 🔶 Differences Table: Class vs Abstract Class vs Interface

| Feature               | Class          | Abstract Class                | Interface                       |
|-----------------------|----------------|--------------------------------|----------------------------------|
| Can be instantiated   | ✅ Yes         | ❌ No                          | ❌ No                            |
| Constructors          | ✅ Yes         | ✅ Yes                         | ❌ No                            |
| Fields                | ✅ Yes         | ✅ Yes                         | ✅ (Only constants)              |
| Methods               | ✅ Yes         | ✅ Abstract + Concrete         | ✅ Abstract (default/static ok)  |
| Inheritance type      | Single         | Single                         | Multiple                        |
| Access modifiers      | Any            | Any                            | Only `public` (by default)      |

---

## 🧠 Diamond Problem in Java

### 🚫 What is it?
Occurs in multiple inheritance scenarios where:
- Class D inherits from B and C
- Both B and C inherit from A
- Now D has **two A's** — ambiguous

### ✅ Java's Solution with Interfaces
```java
interface A {
    default void sayHello() { System.out.println("Hello from A"); }
}

interface B {
    default void sayHello() { System.out.println("Hello from B"); }
}

class C implements A, B {
    public void sayHello() {
        A.super.sayHello(); // Resolve manually
    }
}
```

Java forces you to resolve **interface conflicts explicitly** — no ambiguity.

---

## 🔶 implements vs extends

| Keyword     | Used With             | Used For                         |
|-------------|------------------------|-----------------------------------|
| `extends`   | Class/Abstract Class   | Inherit functionality             |
| `implements`| Interface              | Implement behavior/contract       |

---

## 🧩 Real-World Analogy

- `Vehicle` → abstract class = "Is a Vehicle"
- `Flyable`, `Floatable` → interfaces = "Can Fly", "Can Float"

```java
class FlyingCar extends Vehicle implements Flyable, Floatable {
    void start() { ... }
    public void fly() { ... }
    public void floatOnWater() { ... }
}
```

---

## 🧪 Modern Interface Features (Java 8+)

| Feature         | Java Version | Description                            |
|-----------------|--------------|----------------------------------------|
| `default`       | Java 8       | Method with body in interface          |
| `static`        | Java 8       | Static helper methods                  |
| `private`       | Java 9       | Helper methods inside interfaces       |

### Example:
```java
interface Logger {
    default void log(String msg) {
        System.out.println("LOG: " + msg);
    }

    static void printVersion() {
        System.out.println("Logger v1.0");
    }
}
```

---

## 🧰 Best Practices

| Use Case                                        | Prefer            |
|------------------------------------------------|-------------------|
| Need to share common fields/methods            | Abstract class    |
| Need to enforce a contract/capability          | Interface         |
| Want multiple behaviors                        | Interface         |
| Need to extend existing class hierarchy        | Abstract class    |
| Want to support default behavior without state | Interface         |

---

## ✅ SDK Examples

| Interface     | Common Implementations       |
|---------------|------------------------------|
| `Runnable`    | `Thread`, `ExecutorTask`     |
| `Comparable`  | `String`, `Integer`, `Date`  |
| `Serializable`| `HashMap`, `ArrayList`       |
| `List`        | `ArrayList`, `LinkedList`    |

---

## 🔍 Interview Tips

- **Interfaces = Capability**, **Abstract class = Partial implementation**
- **Interfaces solve diamond problem** via explicit overrides
- **Class can `implement` multiple interfaces, but only `extend` one class**
- **Interfaces cannot have constructors**
- **Interfaces can have static/default methods (Java 8+)**

---

## 🧠 Final Cheat Sheet

```text
Want to define a contract?        → Interface
Need partial implementation?     → Abstract Class
Need shared state/fields?        → Abstract Class
Need multiple inheritance?       → Interface
```

---
