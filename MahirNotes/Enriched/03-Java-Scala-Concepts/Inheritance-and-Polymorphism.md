# 🧬 Inheritance & Polymorphism - Complete Java Guide

> **"Inheritance is the mechanism by which one class can inherit the features of another class"**

---

## 🎯 Table of Contents

1. [Inheritance Fundamentals](#-inheritance-fundamentals)
2. [Class vs Abstract Class vs Interface](#-class-vs-abstract-class-vs-interface)  
3. [Polymorphism Deep Dive](#-polymorphism-deep-dive)
4. [Method Overriding & Overloading](#-method-overriding--overloading)
5. [Diamond Problem & Solutions](#-diamond-problem--solutions)
6. [Real-World Examples](#-real-world-examples)
7. [Interview Questions](#-interview-questions)

---

## 🏗️ Inheritance Fundamentals

### **What is Inheritance?** #fundamental

**Definition:** A mechanism where a new class (child/subclass) acquires the properties and behaviors of an existing class (parent/superclass).

**Key Benefits:**
- **Code Reusability:** Don't repeat common functionality
- **Method Overriding:** Customize inherited behavior
- **Polymorphism:** Treat objects of different types uniformly
- **Hierarchical Organization:** Model real-world relationships

### **Basic Syntax**
```java
// Parent class (Superclass)
class Animal {
    protected String name;
    protected int age;
    
    public Animal(String name, int age) {
        this.name = name;
        this.age = age;
    }
    
    public void eat() {
        System.out.println(name + " is eating");
    }
    
    public void sleep() {
        System.out.println(name + " is sleeping");
    }
}

// Child class (Subclass)
class Dog extends Animal {
    private String breed;
    
    public Dog(String name, int age, String breed) {
        super(name, age);  // Call parent constructor
        this.breed = breed;
    }
    
    public void bark() {
        System.out.println(name + " is barking");
    }
    
    @Override
    public void eat() {
        System.out.println(name + " the " + breed + " is eating dog food");
    }
}
```

### **Types of Inheritance in Java**

| **Type** | **Support in Java** | **Example** |
|----------|---------------------|-------------|
| **Single** | ✅ Supported | `class B extends A` |
| **Multiple** | ❌ Not supported (classes) | Use interfaces instead |
| **Multilevel** | ✅ Supported | `A → B → C` chain |
| **Hierarchical** | ✅ Supported | Multiple classes extend same parent |
| **Hybrid** | ✅ Partial (via interfaces) | Combination of above |

---

## ⚖️ Class vs Abstract Class vs Interface

### **Comprehensive Comparison Table**

| **Feature** | **Class** | **Abstract Class** | **Interface** |
|-------------|-----------|--------------------| --------------|
| **Instantiation** | ✅ `new MyClass()` | ❌ Cannot instantiate | ❌ Cannot instantiate |
| **Constructors** | ✅ Yes | ✅ Yes | ❌ No |
| **Instance Variables** | ✅ Any type | ✅ Any type | ✅ Only `public static final` |
| **Method Types** | ✅ Concrete only | ✅ Abstract + Concrete | ✅ Abstract + Default + Static |
| **Access Modifiers** | ✅ All types | ✅ All types | ✅ Only `public` (default) |
| **Inheritance** | Single (`extends`) | Single (`extends`) | Multiple (`implements`) |
| **When to Use** | Complete implementation | Partial implementation | Contract/Capability |

### **1. Concrete Class Example**
```java
public class Vehicle {
    private String brand;
    private int year;
    
    public Vehicle(String brand, int year) {
        this.brand = brand;
        this.year = year;
    }
    
    public void start() {
        System.out.println("Vehicle started");
    }
    
    public void stop() {
        System.out.println("Vehicle stopped");
    }
    
    // Getters and setters
    public String getBrand() { return brand; }
    public int getYear() { return year; }
}
```

### **2. Abstract Class Example**
```java
public abstract class Vehicle {
    protected String brand;
    protected int year;
    
    // Constructor in abstract class
    public Vehicle(String brand, int year) {
        this.brand = brand;
        this.year = year;
    }
    
    // Concrete method
    public void displayInfo() {
        System.out.println(brand + " - " + year);
    }
    
    // Abstract methods - must be implemented by subclasses
    public abstract void start();
    public abstract void stop();
    public abstract double calculateFuelEfficiency();
}

// Concrete implementation
class Car extends Vehicle {
    private String fuelType;
    
    public Car(String brand, int year, String fuelType) {
        super(brand, year);
        this.fuelType = fuelType;
    }
    
    @Override
    public void start() {
        System.out.println("Car engine started with " + fuelType);
    }
    
    @Override
    public void stop() {
        System.out.println("Car engine stopped");
    }
    
    @Override
    public double calculateFuelEfficiency() {
        // Car-specific fuel efficiency logic
        return 25.5; // miles per gallon
    }
}
```

### **3. Interface Example**
```java
// Basic interface
public interface Flyable {
    // Abstract method (implicitly public abstract)
    void fly();
    
    // Static method (Java 8+)
    static void printFlightInfo() {
        System.out.println("Flight information system");
    }
    
    // Default method (Java 8+)
    default void land() {
        System.out.println("Landing safely");
    }
    
    // Constants (implicitly public static final)
    int MAX_ALTITUDE = 40000;
}

// Multiple interface implementation
interface Swimmable {
    void swim();
}

interface Walkable {
    void walk();
}

// Multiple inheritance through interfaces
class Duck implements Flyable, Swimmable, Walkable {
    @Override
    public void fly() {
        System.out.println("Duck is flying");
    }
    
    @Override
    public void swim() {
        System.out.println("Duck is swimming");
    }
    
    @Override
    public void walk() {
        System.out.println("Duck is walking");
    }
}
```

### **Interface Evolution (Java 8+)**

#### **Default Methods**
```java
public interface PaymentProcessor {
    // Abstract method
    boolean processPayment(double amount);
    
    // Default method - provides backward compatibility
    default void sendReceipt(String email) {
        System.out.println("Sending receipt to " + email);
    }
    
    // Static utility method
    static boolean validateAmount(double amount) {
        return amount > 0 && amount <= 10000;
    }
}

class CreditCardProcessor implements PaymentProcessor {
    @Override
    public boolean processPayment(double amount) {
        if (PaymentProcessor.validateAmount(amount)) {
            System.out.println("Processing credit card payment: $" + amount);
            return true;
        }
        return false;
    }
    
    // Can optionally override default method
    @Override
    public void sendReceipt(String email) {
        System.out.println("Sending detailed credit card receipt to " + email);
    }
}
```

#### **Private Methods in Interfaces (Java 9+)**
```java
public interface Calculator {
    default int addPositiveNumbers(int a, int b) {
        return add(validate(a), validate(b));
    }
    
    default int subtractPositiveNumbers(int a, int b) {
        return subtract(validate(a), validate(b));
    }
    
    // Private helper method - code reuse within interface
    private int validate(int number) {
        if (number < 0) {
            throw new IllegalArgumentException("Number must be positive");
        }
        return number;
    }
    
    // Private static method
    private static int add(int a, int b) {
        return a + b;
    }
    
    private static int subtract(int a, int b) {
        return a - b;
    }
}
```

---

## 🔄 Polymorphism Deep Dive

### **What is Polymorphism?** #polymorphism

**Definition:** The ability of a single interface to represent different underlying forms (data types).

**Two Main Types:**
1. **Compile-time Polymorphism** (Static) - Method Overloading
2. **Runtime Polymorphism** (Dynamic) - Method Overriding

### **Runtime Polymorphism Example**
```java
// Base class
abstract class Shape {
    protected String color;
    
    public Shape(String color) {
        this.color = color;
    }
    
    // Abstract method to be overridden
    public abstract double calculateArea();
    
    // Concrete method
    public void displayColor() {
        System.out.println("Shape color: " + color);
    }
}

// Concrete implementations
class Circle extends Shape {
    private double radius;
    
    public Circle(String color, double radius) {
        super(color);
        this.radius = radius;
    }
    
    @Override
    public double calculateArea() {
        return Math.PI * radius * radius;
    }
}

class Rectangle extends Shape {
    private double width, height;
    
    public Rectangle(String color, double width, double height) {
        super(color);
        this.width = width;
        this.height = height;
    }
    
    @Override
    public double calculateArea() {
        return width * height;
    }
}

// Polymorphism in action
public class PolymorphismDemo {
    public static void main(String[] args) {
        // Array of Shape references pointing to different concrete objects
        Shape[] shapes = {
            new Circle("Red", 5.0),
            new Rectangle("Blue", 4.0, 6.0),
            new Circle("Green", 3.0)
        };
        
        // Polymorphic method calls
        for (Shape shape : shapes) {
            shape.displayColor();           // Inherited method
            System.out.println("Area: " + shape.calculateArea()); // Overridden method
            System.out.println("---");
        }
    }
}
```

### **How Dynamic Method Dispatch Works**
```java
public class MethodDispatchExample {
    public static void main(String[] args) {
        Animal animal;  // Reference variable
        
        // Dynamic binding at runtime
        animal = new Dog("Buddy", 3, "Golden Retriever");
        animal.eat();   // Calls Dog's overridden eat() method
        
        animal = new Cat("Whiskers", 2, "Persian");
        animal.eat();   // Calls Cat's overridden eat() method
        
        // Compile-time type vs Runtime type
        // animal.bark(); // Compilation error - bark() not in Animal
        
        // Type checking and casting
        if (animal instanceof Dog) {
            Dog dog = (Dog) animal;
            dog.bark(); // Now we can call Dog-specific methods
        }
    }
}
```

---

## 🔄 Method Overriding & Overloading

### **Method Overriding** #overriding

**Rules for Method Overriding:**
1. **Same method signature** (name, parameters)
2. **Return type** must be same or covariant
3. **Access modifier** cannot be more restrictive
4. **Cannot override** `static`, `final`, or `private` methods
5. **Exception handling** - cannot throw broader checked exceptions

```java
class Parent {
    // Method to be overridden
    public Animal createAnimal() {
        return new Animal("Generic", 0);
    }
    
    protected void display() {
        System.out.println("Parent display");
    }
    
    // Cannot be overridden
    final void finalMethod() {
        System.out.println("Cannot override this");
    }
    
    static void staticMethod() {
        System.out.println("Static method - hidden, not overridden");
    }
}

class Child extends Parent {
    // Covariant return type - Dog is a subtype of Animal
    @Override
    public Dog createAnimal() {
        return new Dog("Child's Dog", 1, "Labrador");
    }
    
    // Access modifier can be same or less restrictive
    @Override
    public void display() {  // protected -> public (allowed)
        super.display();     // Call parent method
        System.out.println("Child display");
    }
    
    // This hides the parent's static method (not overriding)
    static void staticMethod() {
        System.out.println("Child static method");
    }
}
```

### **Method Overloading** #overloading

**Rules for Method Overloading:**
1. **Different parameter lists** (number, types, or order)
2. **Return type** can be different (but not sufficient alone)
3. **Access modifiers** can be different
4. **Can throw different exceptions**

```java
public class Calculator {
    // Same method name, different parameters
    
    // Method 1: Two integers
    public int add(int a, int b) {
        return a + b;
    }
    
    // Method 2: Three integers
    public int add(int a, int b, int c) {
        return a + b + c;
    }
    
    // Method 3: Two doubles
    public double add(double a, double b) {
        return a + b;
    }
    
    // Method 4: Array of integers
    public int add(int[] numbers) {
        int sum = 0;
        for (int num : numbers) {
            sum += num;
        }
        return sum;
    }
    
    // Method 5: Varargs (variable arguments)
    public int add(int... numbers) {
        int sum = 0;
        for (int num : numbers) {
            sum += num;
        }
        return sum;
    }
    
    // Method overloading with generics
    public <T extends Number> double add(T a, T b) {
        return a.doubleValue() + b.doubleValue();
    }
}

// Usage examples
Calculator calc = new Calculator();
int result1 = calc.add(5, 3);           // Calls method 1
int result2 = calc.add(1, 2, 3);        // Calls method 2  
double result3 = calc.add(2.5, 3.7);    // Calls method 3
int result4 = calc.add(new int[]{1,2,3,4}); // Calls method 4
int result5 = calc.add(1, 2, 3, 4, 5);  // Calls method 5
```

---

## 💎 Diamond Problem & Solutions

### **What is the Diamond Problem?** #diamond-problem

**Definition:** Ambiguity that arises when a class inherits from two classes that have a common base class, creating a "diamond" shape in the inheritance hierarchy.

```
     A
    / \
   B   C
    \ /
     D
```

### **Java's Solution with Interfaces**

#### **Problem Scenario:**
```java
interface A {
    default void method() {
        System.out.println("Method from A");
    }
}

interface B extends A {
    default void method() {
        System.out.println("Method from B");
    }
}

interface C extends A {
    default void method() {
        System.out.println("Method from C");
    }
}

// Diamond problem: Which method() should D inherit?
class D implements B, C {
    // Compilation error: D inherits unrelated defaults for method()
    
    // SOLUTION: Explicitly resolve the conflict
    @Override
    public void method() {
        // Option 1: Choose one interface's implementation
        B.super.method();
        
        // Option 2: Provide custom implementation
        // System.out.println("D's custom implementation");
        
        // Option 3: Call both and combine
        // B.super.method();
        // C.super.method();
    }
}
```

#### **Advanced Diamond Problem Resolution:**
```java
public class DiamondProblemSolution {
    interface Printer {
        default void print() {
            System.out.println("Printing from Printer");
        }
    }
    
    interface Scanner {
        default void scan() {
            System.out.println("Scanning from Scanner");
        }
        
        default void print() {  // Conflict with Printer.print()
            System.out.println("Printing from Scanner");
        }
    }
    
    interface Copier {
        default void copy() {
            System.out.println("Copying document");
        }
    }
    
    // Multiple interface implementation with conflict resolution
    static class AllInOnePrinter implements Printer, Scanner, Copier {
        @Override
        public void print() {
            // Resolve conflict by choosing specific interface
            System.out.println("AllInOne: ");
            Printer.super.print();      // Call Printer's version
            Scanner.super.print();      // Also call Scanner's version
        }
        
        // Define priority resolution method
        public void printHighQuality() {
            Printer.super.print();  // Use Printer's implementation for high quality
        }
        
        public void printFast() {
            Scanner.super.print();  // Use Scanner's implementation for speed
        }
    }
    
    public static void main(String[] args) {
        AllInOnePrinter device = new AllInOnePrinter();
        device.print();             // Uses resolved implementation
        device.scan();              // From Scanner interface
        device.copy();              // From Copier interface
        device.printHighQuality();  // Explicit choice
        device.printFast();         // Explicit choice
    }
}
```

---

## 🏢 Real-World Examples

### **1. Shape Drawing Application**
```java
// Abstract base class
abstract class Drawable {
    protected Point position;
    protected Color color;
    
    public Drawable(Point position, Color color) {
        this.position = position;
        this.color = color;
    }
    
    // Template method pattern
    public final void render() {
        setupDrawing();
        draw();
        cleanup();
    }
    
    protected void setupDrawing() {
        System.out.println("Setting up drawing context");
    }
    
    protected abstract void draw();  // Must be implemented by subclasses
    
    protected void cleanup() {
        System.out.println("Cleaning up drawing context");
    }
}

// Concrete implementations
class Circle extends Drawable {
    private double radius;
    
    public Circle(Point position, Color color, double radius) {
        super(position, color);
        this.radius = radius;
    }
    
    @Override
    protected void draw() {
        System.out.printf("Drawing circle at (%d,%d) with radius %.2f%n", 
                         position.x, position.y, radius);
    }
}

class Rectangle extends Drawable {
    private double width, height;
    
    public Rectangle(Point position, Color color, double width, double height) {
        super(position, color);
        this.width = width;
        this.height = height;
    }
    
    @Override
    protected void draw() {
        System.out.printf("Drawing rectangle at (%d,%d) with size %.2fx%.2f%n",
                         position.x, position.y, width, height);
    }
}

// Usage with polymorphism
List<Drawable> shapes = Arrays.asList(
    new Circle(new Point(10, 10), Color.RED, 5.0),
    new Rectangle(new Point(20, 20), Color.BLUE, 10.0, 15.0)
);

shapes.forEach(Drawable::render);  // Polymorphic method calls
```

### **2. Payment Processing System**
```java
// Interface for payment capability
interface PaymentMethod {
    boolean processPayment(double amount);
    String getPaymentType();
    
    // Default method for common validation
    default boolean validateAmount(double amount) {
        return amount > 0 && amount <= 10000;
    }
}

// Interface for refund capability
interface RefundCapable {
    boolean processRefund(double amount, String transactionId);
}

// Concrete payment implementations
class CreditCardPayment implements PaymentMethod, RefundCapable {
    private String cardNumber;
    private String cvv;
    
    public CreditCardPayment(String cardNumber, String cvv) {
        this.cardNumber = cardNumber;
        this.cvv = cvv;
    }
    
    @Override
    public boolean processPayment(double amount) {
        if (!validateAmount(amount)) return false;
        
        // Credit card specific processing
        System.out.println("Processing credit card payment: $" + amount);
        return authenticateCard() && chargeCard(amount);
    }
    
    @Override
    public boolean processRefund(double amount, String transactionId) {
        System.out.println("Processing credit card refund: $" + amount);
        return true;
    }
    
    @Override
    public String getPaymentType() {
        return "Credit Card";
    }
    
    private boolean authenticateCard() {
        // Validate card details
        return cardNumber != null && cvv != null;
    }
    
    private boolean chargeCard(double amount) {
        // Simulate charging the card
        return true;
    }
}

class DigitalWalletPayment implements PaymentMethod {
    private String walletId;
    private double balance;
    
    public DigitalWalletPayment(String walletId, double balance) {
        this.walletId = walletId;
        this.balance = balance;
    }
    
    @Override
    public boolean processPayment(double amount) {
        if (!validateAmount(amount)) return false;
        
        if (balance >= amount) {
            balance -= amount;
            System.out.println("Digital wallet payment processed: $" + amount);
            return true;
        }
        return false;
    }
    
    @Override
    public String getPaymentType() {
        return "Digital Wallet";
    }
}

// Payment processor using polymorphism
class PaymentProcessor {
    public void processOrder(double amount, PaymentMethod paymentMethod) {
        System.out.println("Processing order with " + paymentMethod.getPaymentType());
        
        boolean success = paymentMethod.processPayment(amount);
        
        if (success) {
            System.out.println("Payment successful!");
        } else {
            System.out.println("Payment failed!");
            
            // Handle refund if payment method supports it
            if (paymentMethod instanceof RefundCapable) {
                RefundCapable refundable = (RefundCapable) paymentMethod;
                refundable.processRefund(amount, "FAILED_TXN_123");
            }
        }
    }
}
```

---

## 🧠 Interview Questions & Scenarios

### **🔥 Common Interview Questions**

#### **Q1: What's the difference between method overriding and overloading?**

| **Aspect** | **Overriding** | **Overloading** |
|------------|----------------|-----------------|
| **Purpose** | Change inherited behavior | Multiple methods with same name |
| **When resolved** | Runtime (dynamic binding) | Compile-time (static binding) |
| **Parameters** | Must be identical | Must be different |
| **Return type** | Same or covariant | Can be different |
| **Inheritance** | Required | Not required |

#### **Q2: Can you override a static method?**
**Answer:** No, static methods are hidden, not overridden. They belong to the class, not the instance.

```java
class Parent {
    static void method() { System.out.println("Parent static"); }
}

class Child extends Parent {
    static void method() { System.out.println("Child static"); }  // Hiding, not overriding
}

Parent p = new Child();
p.method();  // Prints "Parent static" - resolved at compile time
```

#### **Q3: What happens if a class implements two interfaces with same default method?**
**Answer:** Compilation error. Must explicitly resolve the conflict.

```java
interface A { default void method() { } }
interface B { default void method() { } }

class C implements A, B {
    @Override
    public void method() {
        A.super.method();  // Explicitly choose which one
    }
}
```

#### **Q4: Explain the Liskov Substitution Principle**
**Answer:** Objects of a superclass should be replaceable with objects of a subclass without breaking the application.

```java
// Violation of LSP
class Bird {
    public void fly() { /* flying logic */ }
}

class Penguin extends Bird {
    @Override
    public void fly() {
        throw new UnsupportedOperationException("Penguins can't fly!");
    }
}

// Better design
interface Flyable {
    void fly();
}

abstract class Bird {
    public void eat() { /* eating logic */ }
}

class Eagle extends Bird implements Flyable {
    @Override
    public void fly() { /* flying implementation */ }
}

class Penguin extends Bird {
    // Penguins don't implement Flyable - no flying behavior
    public void swim() { /* swimming logic */ }
}
```

---

## 💪 Practical Exercises

### **Exercise 1: Design a Vehicle Hierarchy**
Design a inheritance hierarchy for vehicles with the following requirements:
- All vehicles have brand, model, and year
- Some vehicles can fly (planes, helicopters)
- Some can float (boats, amphibious vehicles)
- Some are electric (Tesla, electric boats)
- Implement proper polymorphism for starting and stopping

### **Exercise 2: Create a Shape Drawing System**
Implement a shape drawing system where:
- All shapes can calculate area and perimeter
- Some shapes can be filled with color
- Support for composite shapes (made of multiple shapes)
- Use visitor pattern for different drawing modes

### **Solution Preview:**
```java
// Exercise 1 solution structure
abstract class Vehicle {
    protected String brand, model;
    protected int year;
    
    public abstract void start();
    public abstract void stop();
}

interface Flyable { void takeOff(); void land(); }
interface Floatable { void launch(); void dock(); }
interface Electric { void charge(); int getBatteryLevel(); }

class Airplane extends Vehicle implements Flyable {
    // Implementation
}

class Boat extends Vehicle implements Floatable {
    // Implementation  
}

class AmphibiousVehicle extends Vehicle implements Flyable, Floatable {
    // Implementation of both interfaces
}
```

---

**Study Progress:**
- [ ] Inheritance Fundamentals (0/3 concepts mastered)
- [ ] Class Types Comparison (0/3 types understood)
- [ ] Polymorphism Implementation (0/2 types practiced)
- [ ] Method Overriding/Overloading (0/5 rules memorized)
- [ ] Diamond Problem Solutions (0/2 patterns implemented)
- [ ] Real-world Examples (0/2 systems built)

**Last Updated:** August 2025  
**Next Focus:** [Implement complex polymorphic system with multiple inheritance]