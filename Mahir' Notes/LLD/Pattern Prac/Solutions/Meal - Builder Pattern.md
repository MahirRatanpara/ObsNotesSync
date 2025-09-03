

### 💡 Use Case: Immutable Meal Plan Generator with Fluent API


### 🧩 Problem Statement  

Design a `Meal` class that supports the building of complex, immutable objects representing daily meal plans. Use a fluent builder interface to construct combinations.

  

Constraints:

- `Meal` is immutable.

- Support validation (e.g., max 2 desserts, 1 drink).

- Builder should support chaining and enforce valid build sequences.

  

### 🧱 Class Scaffolding

```java

class Meal {

    private final List<String> mainCourse;

    private final String drink;

    private final List<String> desserts;

    // Getters

  

    static class Builder {

        // fluent methods like addMainCourse(), setDrink(), addDessert(), build()

    }

}

```

  

### 🧠 Hints

- Use private constructor in `Meal`.

- Use nested `Builder` class.

- Apply validation logic inside `build()`.

  

### ✅ Expected Output

```

Meal: Pasta, Coke, IceCream, Brownie

```

  

# Computer Builder Example:

# Builder Pattern Implementation Guide

## Overview
The Builder pattern separates the construction of complex objects from their representation, allowing the same construction process to create different representations.

## Key Components

### 1. Product Class
The complex object being built.

```java
class Computer {
    private String cpu, ram, storage;
    private boolean hasWifi;
    
    private Computer() {} // Private constructor - only builder can create
    
    // Getters
    public String getCpu() { return cpu; }
    public String getRam() { return ram; }
    public String getStorage() { return storage; }
    public boolean hasWifi() { return hasWifi; }
    
    // Package-private setters for builder access
    void setCpu(String cpu) { this.cpu = cpu; }
    void setRam(String ram) { this.ram = ram; }
    void setStorage(String storage) { this.storage = storage; }
    void setWifi(boolean hasWifi) { this.hasWifi = hasWifi; }
    
    @Override
    public String toString() {
        return "Computer{cpu='" + cpu + "', ram='" + ram + 
               "', storage='" + storage + "', hasWifi=" + hasWifi + '}';
    }
}
```

### 2. Builder Interface
Defines the contract for all builders and enables polymorphism.

```java
interface ComputerBuilder {
    ComputerBuilder reset();
    ComputerBuilder setCpu(String cpu);
    ComputerBuilder setRam(String ram);
    ComputerBuilder setStorage(String storage);
    ComputerBuilder setWifi(boolean hasWifi);
    Computer build();
}
```

### 3. Concrete Builder Implementations

#### Standard Builder
Basic implementation without validation.

```java
class StandardComputerBuilder implements ComputerBuilder {
    private Computer computer;
    
    public StandardComputerBuilder() { reset(); }
    
    @Override
    public ComputerBuilder reset() {
        this.computer = new Computer();
        return this;
    }
    
    @Override
    public ComputerBuilder setCpu(String cpu) {
        computer.setCpu(cpu);
        return this;
    }
    
    @Override
    public ComputerBuilder setRam(String ram) {
        computer.setRam(ram);
        return this;
    }
    
    @Override
    public ComputerBuilder setStorage(String storage) {
        computer.setStorage(storage);
        return this;
    }
    
    @Override
    public ComputerBuilder setWifi(boolean hasWifi) {
        computer.setWifi(hasWifi);
        return this;
    }
    
    @Override
    public Computer build() {
        Computer result = this.computer;
        reset(); // Reset for next build
        return result;
    }
}
```

#### Gaming Builder with Validation
Specialized builder with gaming-specific validation and defaults.

```java
class GamingComputerBuilder implements ComputerBuilder {
    private Computer computer;
    
    public GamingComputerBuilder() { reset(); }
    
    @Override
    public ComputerBuilder reset() {
        this.computer = new Computer();
        computer.setWifi(true); // Gaming default
        return this;
    }
    
    @Override
    public ComputerBuilder setCpu(String cpu) {
        if (cpu.contains("i3")) {
            System.out.println("Warning: " + cpu + " may not be optimal for gaming");
        }
        computer.setCpu(cpu);
        return this;
    }
    
    @Override
    public ComputerBuilder setRam(String ram) {
        if (ram.contains("8GB")) {
            System.out.println("Warning: 8GB RAM may be insufficient for gaming");
        }
        computer.setRam(ram);
        return this;
    }
    
    @Override
    public ComputerBuilder setStorage(String storage) {
        computer.setStorage(storage);
        return this;
    }
    
    @Override
    public ComputerBuilder setWifi(boolean hasWifi) {
        computer.setWifi(hasWifi);
        return this;
    }
    
    @Override
    public Computer build() {
        Computer result = this.computer;
        reset();
        return result;
    }
}
```

### 4. Director Class
Knows how to construct specific product configurations using any builder.

```java
class ComputerDirector {
    private ComputerBuilder builder;
    
    public ComputerDirector(ComputerBuilder builder) {
        this.builder = builder;
    }
    
    public void setBuilder(ComputerBuilder builder) {
        this.builder = builder;
    }
    
    public Computer buildGamingComputer() {
        return builder.reset()
                .setCpu("Intel i7-13700K")
                .setRam("32GB DDR5")
                .setStorage("1TB NVMe SSD")
                .setWifi(true)
                .build();
    }
    
    public Computer buildOfficeComputer() {
        return builder.reset()
                .setCpu("Intel i5-13400")
                .setRam("16GB DDR4")
                .setStorage("512GB SSD")
                .setWifi(true)
                .build();
    }
}
```

## Usage Examples

### Direct Builder Usage (Fluent Interface)
```java
Computer customPC = new StandardComputerBuilder()
        .setCpu("AMD Ryzen 7")
        .setRam("32GB DDR5")
        .setStorage("2TB SSD")
        .setWifi(true)
        .build();
```

### Using Director with Different Builders
```java
// With standard builder
ComputerDirector director = new ComputerDirector(new StandardComputerBuilder());
Computer gamingPC = director.buildGamingComputer();

// Switch to gaming builder (polymorphism)
director.setBuilder(new GamingComputerBuilder());
Computer gamingPCWithValidation = director.buildGamingComputer();
```

### Validation Example
```java
Computer lowEndGaming = new GamingComputerBuilder()
        .setCpu("Intel i3-12100") // Triggers warning
        .setRam("8GB DDR4")       // Triggers warning
        .setStorage("500GB SSD")
        .build();
```

## Complete Demo
```java
public class BuilderPatternDemo {
    public static void main(String[] args) {
        // 1. Direct builder usage (fluent interface)
        Computer customPC = new StandardComputerBuilder()
                .setCpu("AMD Ryzen 7")
                .setRam("32GB DDR5")
                .setStorage("2TB SSD")
                .setWifi(true)
                .build();
        System.out.println("Custom PC: " + customPC);
        
        // 2. Using Director with different builders
        ComputerDirector director = new ComputerDirector(new StandardComputerBuilder());
        Computer gamingPC = director.buildGamingComputer();
        System.out.println("Gaming PC: " + gamingPC);
        
        // 3. Switch to gaming builder (shows polymorphism)
        director.setBuilder(new GamingComputerBuilder());
        Computer gamingPCWithValidation = director.buildGamingComputer();
        System.out.println("Gaming PC (validated): " + gamingPCWithValidation);
        
        // 4. Gaming builder with warnings
        Computer lowEndGaming = new GamingComputerBuilder()
                .setCpu("Intel i3-12100") // Triggers warning
                .setRam("8GB DDR4")       // Triggers warning
                .setStorage("500GB SSD")
                .build();
        System.out.println("Low-end Gaming PC: " + lowEndGaming);
    }
}
```

## Expected Output
```
Custom PC: Computer{cpu='AMD Ryzen 7', ram='32GB DDR5', storage='2TB SSD', hasWifi=true}
Gaming PC: Computer{cpu='Intel i7-13700K', ram='32GB DDR5', storage='1TB NVMe SSD', hasWifi=true}
Gaming PC (validated): Computer{cpu='Intel i7-13700K', ram='32GB DDR5', storage='1TB NVMe SSD', hasWifi=true}
Warning: Intel i3-12100 may not be optimal for gaming
Warning: 8GB RAM may be insufficient for gaming
Low-end Gaming PC: Computer{cpu='Intel i3-12100', ram='8GB DDR4', storage='500GB SSD', hasWifi=true}
```

## Key Benefits

### ✅ **Interface Enables Polymorphism**
- Director works with any builder implementation
- Can switch builders at runtime

### ✅ **Fluent Interface** 
- Method chaining for readable code
- Each method returns `this` for chaining

### ✅ **Separation of Concerns**
- Construction logic separated from product representation
- Different builders can have different validation rules

### ✅ **Flexibility**
- Can use builders directly or through director
- Same director can produce different results with different builders

### ✅ **Extensibility**
- Easy to add new builder types without changing existing code
- New product variants can be added by implementing the interface

## When to Use Builder Pattern

- **Complex object construction** with many optional parameters
- **Multiple representations** of the same product are needed
- **Step-by-step construction** is required
- **Immutable objects** need to be created with many parameters
- **Validation logic** differs based on product type