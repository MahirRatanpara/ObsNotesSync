# 🏗️ Low Level Design (LLD) - SDE2 Interview Master Guide

> **"Good design is obvious. Great design is transparent." - Joe Sparano**

---

## 📋 Quick Navigation

| **Design Principles** | **Design Patterns** | **System Components** |
|---|---|---|
| [SOLID Principles](#solid-principles) | [Creational Patterns](#creational-patterns) | [Common LLD Problems](#-common-lld-problems) |
| [Design Principles](#design-principles) | [Structural Patterns](#structural-patterns) | [Real-World Examples](#-real-world-examples) |
| [Code Quality](#code-quality) | [Behavioral Patterns](#behavioral-patterns) | [Interview Framework](#-interview-framework) |
| [Architecture Patterns](#architecture-patterns) | [Advanced Patterns](#advanced-patterns) | [Best Practices](#-best-practices) |

---

## 🎯 LLD Interview Strategy

### 📚 **Phase 1: Fundamentals (Week 1)**
**Goal:** Master design principles and basic patterns
- ✅ SOLID principles with real examples
- ✅ Basic design patterns (Singleton, Factory, Observer)
- ✅ UML diagrams and class relationships
- ✅ Code organization and structure

### 🔥 **Phase 2: Common Problems (Week 2)**
**Goal:** Practice standard LLD interview questions  
- ✅ Parking lot system, ATM machine, Elevator system
- ✅ Vending machine, Chess game, Library management
- ✅ Design patterns application in real scenarios
- ✅ Requirements gathering and clarification

### 🚀 **Phase 3: Advanced Design (Week 3)**
**Goal:** Handle complex systems and trade-offs
- ✅ Multi-threaded designs (thread-safe components)
- ✅ Extensible and maintainable architectures
- ✅ Performance considerations and optimization
- ✅ Integration with external systems

---

## 🏛️ SOLID Principles

### **S - Single Responsibility Principle** #srp

**Definition:** A class should have one, and only one, reason to change.

#### **❌ Violation Example:**
```java
// BAD: Employee class has multiple responsibilities
class Employee {
    private String name;
    private double salary;
    
    // Responsibility 1: Employee data management
    public void setName(String name) { this.name = name; }
    public String getName() { return name; }
    
    // Responsibility 2: Salary calculation (should be separate)
    public double calculateAnnualBonus() {
        return salary * 0.1;  // 10% bonus
    }
    
    // Responsibility 3: Data persistence (should be separate)
    public void saveToDatabase() {
        // Database saving logic
        System.out.println("Saving " + name + " to database");
    }
    
    // Responsibility 4: Report generation (should be separate)
    public void generatePaySlip() {
        System.out.println("Generating pay slip for " + name);
    }
}
```

#### **✅ Correct Implementation:**
```java
// GOOD: Each class has single responsibility
class Employee {
    private String name;
    private double salary;
    
    // Only responsible for employee data
    public Employee(String name, double salary) {
        this.name = name;
        this.salary = salary;
    }
    
    // Getters and setters only
    public String getName() { return name; }
    public double getSalary() { return salary; }
}

class SalaryCalculator {
    public double calculateAnnualBonus(Employee employee) {
        return employee.getSalary() * 0.1;
    }
    
    public double calculateTax(Employee employee) {
        return employee.getSalary() * 0.2;
    }
}

class EmployeeRepository {
    public void save(Employee employee) {
        // Database saving logic
        System.out.println("Saving " + employee.getName() + " to database");
    }
    
    public Employee findById(int id) {
        // Database retrieval logic
        return new Employee("John", 50000);
    }
}

class PaySlipGenerator {
    private SalaryCalculator calculator;
    
    public PaySlipGenerator(SalaryCalculator calculator) {
        this.calculator = calculator;
    }
    
    public void generatePaySlip(Employee employee) {
        double bonus = calculator.calculateAnnualBonus(employee);
        System.out.println("Pay slip for " + employee.getName() + 
                          " - Salary: " + employee.getSalary() + ", Bonus: " + bonus);
    }
}
```

### **O - Open/Closed Principle** #ocp

**Definition:** Software entities should be open for extension but closed for modification.

#### **✅ Implementation Example:**
```java
// Base abstraction - closed for modification
abstract class Shape {
    public abstract double calculateArea();
}

// Extensions - open for extension
class Rectangle extends Shape {
    private double width, height;
    
    public Rectangle(double width, double height) {
        this.width = width;
        this.height = height;
    }
    
    @Override
    public double calculateArea() {
        return width * height;
    }
}

class Circle extends Shape {
    private double radius;
    
    public Circle(double radius) {
        this.radius = radius;
    }
    
    @Override
    public double calculateArea() {
        return Math.PI * radius * radius;
    }
}

// Area calculator doesn't need modification when new shapes are added
class AreaCalculator {
    public double calculateTotalArea(List<Shape> shapes) {
        return shapes.stream()
                    .mapToDouble(Shape::calculateArea)
                    .sum();
    }
}

// Adding new shape without modifying existing code
class Triangle extends Shape {
    private double base, height;
    
    public Triangle(double base, double height) {
        this.base = base;
        this.height = height;
    }
    
    @Override
    public double calculateArea() {
        return 0.5 * base * height;
    }
}
```

### **L - Liskov Substitution Principle** #lsp

**Definition:** Objects of a superclass should be replaceable with objects of a subclass without breaking the application.

#### **❌ Violation Example:**
```java
// BAD: Square violates LSP
class Rectangle {
    protected double width, height;
    
    public void setWidth(double width) { this.width = width; }
    public void setHeight(double height) { this.height = height; }
    public double getArea() { return width * height; }
}

class Square extends Rectangle {
    @Override
    public void setWidth(double width) {
        this.width = width;
        this.height = width;  // Violates expected behavior
    }
    
    @Override
    public void setHeight(double height) {
        this.width = height;
        this.height = height;  // Violates expected behavior
    }
}

// This will break with Square
public void testRectangle(Rectangle rect) {
    rect.setWidth(5);
    rect.setHeight(4);
    assert rect.getArea() == 20;  // Fails for Square!
}
```

#### **✅ Correct Implementation:**
```java
// GOOD: Proper abstraction
abstract class Shape {
    public abstract double getArea();
}

class Rectangle extends Shape {
    private double width, height;
    
    public Rectangle(double width, double height) {
        this.width = width;
        this.height = height;
    }
    
    @Override
    public double getArea() {
        return width * height;
    }
    
    // Immutable - no setters that can break invariants
    public Rectangle withWidth(double width) {
        return new Rectangle(width, this.height);
    }
    
    public Rectangle withHeight(double height) {
        return new Rectangle(this.width, height);
    }
}

class Square extends Shape {
    private double side;
    
    public Square(double side) {
        this.side = side;
    }
    
    @Override
    public double getArea() {
        return side * side;
    }
    
    public Square withSide(double side) {
        return new Square(side);
    }
}
```

### **I - Interface Segregation Principle** #isp

**Definition:** No client should be forced to depend on methods it does not use.

#### **❌ Violation Example:**
```java
// BAD: Fat interface
interface Worker {
    void work();
    void eat();
    void sleep();
}

class Human implements Worker {
    @Override
    public void work() { System.out.println("Human working"); }
    
    @Override
    public void eat() { System.out.println("Human eating"); }
    
    @Override
    public void sleep() { System.out.println("Human sleeping"); }
}

class Robot implements Worker {
    @Override
    public void work() { System.out.println("Robot working"); }
    
    @Override
    public void eat() { 
        // Robot doesn't eat - forced to implement unnecessary method
        throw new UnsupportedOperationException("Robot doesn't eat");
    }
    
    @Override
    public void sleep() { 
        // Robot doesn't sleep - forced to implement unnecessary method
        throw new UnsupportedOperationException("Robot doesn't sleep");
    }
}
```

#### **✅ Correct Implementation:**
```java
// GOOD: Segregated interfaces
interface Workable {
    void work();
}

interface Eatable {
    void eat();
}

interface Sleepable {
    void sleep();
}

class Human implements Workable, Eatable, Sleepable {
    @Override
    public void work() { System.out.println("Human working"); }
    
    @Override
    public void eat() { System.out.println("Human eating"); }
    
    @Override
    public void sleep() { System.out.println("Human sleeping"); }
}

class Robot implements Workable {
    @Override
    public void work() { System.out.println("Robot working"); }
    // Robot only implements what it needs
}

// More specific interfaces for different types of workers
interface Rechargeable {
    void recharge();
}

class AdvancedRobot implements Workable, Rechargeable {
    @Override
    public void work() { System.out.println("Advanced robot working"); }
    
    @Override
    public void recharge() { System.out.println("Robot recharging"); }
}
```

### **D - Dependency Inversion Principle** #dip

**Definition:** High-level modules should not depend on low-level modules. Both should depend on abstractions.

#### **✅ Implementation Example:**
```java
// Abstraction
interface NotificationService {
    void sendNotification(String message);
}

// Low-level modules (concrete implementations)
class EmailService implements NotificationService {
    @Override
    public void sendNotification(String message) {
        System.out.println("Email: " + message);
    }
}

class SMSService implements NotificationService {
    @Override
    public void sendNotification(String message) {
        System.out.println("SMS: " + message);
    }
}

// High-level module depends on abstraction
class OrderService {
    private final NotificationService notificationService;
    
    // Dependency injection - depends on abstraction, not concrete class
    public OrderService(NotificationService notificationService) {
        this.notificationService = notificationService;
    }
    
    public void processOrder(Order order) {
        // Process order logic
        System.out.println("Processing order: " + order.getId());
        
        // Send notification through abstraction
        notificationService.sendNotification("Order " + order.getId() + " processed");
    }
}

// Usage - easily switchable implementations
public class Application {
    public static void main(String[] args) {
        // Can switch notification service without changing OrderService
        OrderService emailOrderService = new OrderService(new EmailService());
        OrderService smsOrderService = new OrderService(new SMSService());
        
        Order order = new Order("12345");
        emailOrderService.processOrder(order);
        smsOrderService.processOrder(order);
    }
}
```

---

## 🎨 Design Patterns

### Creational Patterns

#### **Singleton Pattern** #singleton

**Use Case:** Database connection pool, logging service, configuration manager

```java
// Thread-safe Singleton using enum (recommended)
public enum DatabaseConnection {
    INSTANCE;
    
    private Connection connection;
    
    private DatabaseConnection() {
        // Initialize connection
        this.connection = createConnection();
    }
    
    public Connection getConnection() {
        return connection;
    }
    
    public void executeQuery(String query) {
        // Execute query using connection
        System.out.println("Executing: " + query);
    }
    
    private Connection createConnection() {
        // Create actual database connection
        return new Connection() {
            // Mock connection implementation
        };
    }
}

// Alternative: Thread-safe lazy initialization
public class Logger {
    private static volatile Logger instance;
    private final List<String> logs;
    
    private Logger() {
        this.logs = new ArrayList<>();
    }
    
    public static Logger getInstance() {
        if (instance == null) {
            synchronized (Logger.class) {
                if (instance == null) {
                    instance = new Logger();
                }
            }
        }
        return instance;
    }
    
    public synchronized void log(String message) {
        logs.add(LocalDateTime.now() + ": " + message);
    }
    
    public synchronized List<String> getLogs() {
        return new ArrayList<>(logs);
    }
}
```

#### **Factory Pattern** #factory

**Use Case:** Creating objects without specifying their exact class

```java
// Product hierarchy
abstract class Vehicle {
    protected String type;
    protected double price;
    
    public abstract void start();
    public abstract void stop();
    
    public String getType() { return type; }
    public double getPrice() { return price; }
}

class Car extends Vehicle {
    public Car() {
        this.type = "Car";
        this.price = 25000;
    }
    
    @Override
    public void start() { System.out.println("Car engine started"); }
    
    @Override
    public void stop() { System.out.println("Car engine stopped"); }
}

class Motorcycle extends Vehicle {
    public Motorcycle() {
        this.type = "Motorcycle";
        this.price = 15000;
    }
    
    @Override
    public void start() { System.out.println("Motorcycle engine started"); }
    
    @Override
    public void stop() { System.out.println("Motorcycle engine stopped"); }
}

// Factory
class VehicleFactory {
    public static Vehicle createVehicle(VehicleType type) {
        switch (type) {
            case CAR:
                return new Car();
            case MOTORCYCLE:
                return new Motorcycle();
            default:
                throw new IllegalArgumentException("Unknown vehicle type: " + type);
        }
    }
}

enum VehicleType {
    CAR, MOTORCYCLE
}

// Usage
public class FactoryDemo {
    public static void main(String[] args) {
        Vehicle car = VehicleFactory.createVehicle(VehicleType.CAR);
        Vehicle motorcycle = VehicleFactory.createVehicle(VehicleType.MOTORCYCLE);
        
        car.start();      // Car engine started
        motorcycle.start(); // Motorcycle engine started
    }
}
```

#### **Builder Pattern** #builder

**Use Case:** Creating complex objects with many optional parameters

```java
// Complex object with many optional fields
public class Computer {
    private final String processor;
    private final String memory;
    private final String storage;
    private final String graphicsCard;
    private final boolean hasBluetooth;
    private final boolean hasWifi;
    
    private Computer(Builder builder) {
        this.processor = builder.processor;
        this.memory = builder.memory;
        this.storage = builder.storage;
        this.graphicsCard = builder.graphicsCard;
        this.hasBluetooth = builder.hasBluetooth;
        this.hasWifi = builder.hasWifi;
    }
    
    // Static nested Builder class
    public static class Builder {
        // Required parameters
        private final String processor;
        private final String memory;
        
        // Optional parameters with default values
        private String storage = "256GB SSD";
        private String graphicsCard = "Integrated";
        private boolean hasBluetooth = false;
        private boolean hasWifi = true;
        
        public Builder(String processor, String memory) {
            this.processor = processor;
            this.memory = memory;
        }
        
        public Builder storage(String storage) {
            this.storage = storage;
            return this;
        }
        
        public Builder graphicsCard(String graphicsCard) {
            this.graphicsCard = graphicsCard;
            return this;
        }
        
        public Builder hasBluetooth(boolean hasBluetooth) {
            this.hasBluetooth = hasBluetooth;
            return this;
        }
        
        public Builder hasWifi(boolean hasWifi) {
            this.hasWifi = hasWifi;
            return this;
        }
        
        public Computer build() {
            return new Computer(this);
        }
    }
    
    @Override
    public String toString() {
        return String.format("Computer{processor='%s', memory='%s', storage='%s', " +
                           "graphicsCard='%s', hasBluetooth=%s, hasWifi=%s}",
                           processor, memory, storage, graphicsCard, hasBluetooth, hasWifi);
    }
}

// Usage
public class BuilderDemo {
    public static void main(String[] args) {
        // Build basic computer
        Computer basicComputer = new Computer.Builder("Intel i5", "8GB")
            .build();
        
        // Build gaming computer
        Computer gamingComputer = new Computer.Builder("Intel i9", "32GB")
            .storage("1TB NVMe SSD")
            .graphicsCard("RTX 4080")
            .hasBluetooth(true)
            .build();
        
        System.out.println(basicComputer);
        System.out.println(gamingComputer);
    }
}
```

### Structural Patterns

#### **Adapter Pattern** #adapter

**Use Case:** Making incompatible interfaces work together

```java
// Legacy payment system with different interface
class LegacyPaymentGateway {
    public boolean makePayment(String account, float amount) {
        System.out.println("Legacy payment: $" + amount + " from " + account);
        return true;
    }
}

// New payment interface expected by the application
interface PaymentProcessor {
    boolean processPayment(String accountNumber, double amount, String currency);
}

// Adapter to make legacy system work with new interface
class PaymentAdapter implements PaymentProcessor {
    private final LegacyPaymentGateway legacyGateway;
    
    public PaymentAdapter(LegacyPaymentGateway legacyGateway) {
        this.legacyGateway = legacyGateway;
    }
    
    @Override
    public boolean processPayment(String accountNumber, double amount, String currency) {
        // Adapt the interface: convert double to float, add logging
        System.out.println("Adapter: Converting " + currency + " payment");
        
        // Convert amount if needed (e.g., currency conversion)
        float convertedAmount = (float) amount;
        if (!"USD".equals(currency)) {
            convertedAmount = convertCurrency(amount, currency);
        }
        
        // Call legacy system
        return legacyGateway.makePayment(accountNumber, convertedAmount);
    }
    
    private float convertCurrency(double amount, String fromCurrency) {
        // Mock currency conversion
        return (float) (amount * 0.85); // Example conversion rate
    }
}

// Usage
public class AdapterDemo {
    public static void main(String[] args) {
        // Legacy system
        LegacyPaymentGateway legacySystem = new LegacyPaymentGateway();
        
        // Adapter makes it compatible with new interface
        PaymentProcessor processor = new PaymentAdapter(legacySystem);
        
        // Application can use new interface
        processor.processPayment("ACC123", 100.0, "EUR");
    }
}
```

#### **Decorator Pattern** #decorator

**Use Case:** Adding behavior to objects dynamically

```java
// Base interface
interface Coffee {
    String getDescription();
    double getCost();
}

// Concrete implementation
class SimpleCoffee implements Coffee {
    @Override
    public String getDescription() {
        return "Simple Coffee";
    }
    
    @Override
    public double getCost() {
        return 2.0;
    }
}

// Base decorator
abstract class CoffeeDecorator implements Coffee {
    protected final Coffee coffee;
    
    public CoffeeDecorator(Coffee coffee) {
        this.coffee = coffee;
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription();
    }
    
    @Override
    public double getCost() {
        return coffee.getCost();
    }
}

// Concrete decorators
class MilkDecorator extends CoffeeDecorator {
    public MilkDecorator(Coffee coffee) {
        super(coffee);
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + ", Milk";
    }
    
    @Override
    public double getCost() {
        return coffee.getCost() + 0.5;
    }
}

class SugarDecorator extends CoffeeDecorator {
    public SugarDecorator(Coffee coffee) {
        super(coffee);
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + ", Sugar";
    }
    
    @Override
    public double getCost() {
        return coffee.getCost() + 0.25;
    }
}

// Usage
public class DecoratorDemo {
    public static void main(String[] args) {
        // Build coffee with multiple decorators
        Coffee coffee = new SimpleCoffee();
        coffee = new MilkDecorator(coffee);
        coffee = new SugarDecorator(coffee);
        
        System.out.println(coffee.getDescription() + " costs $" + coffee.getCost());
        // Output: Simple Coffee, Milk, Sugar costs $2.75
    }
}
```

### Behavioral Patterns

#### **Observer Pattern** #observer

**Use Case:** Event handling, model-view architectures

```java
// Observer interface
interface Observer {
    void update(String stockSymbol, double price);
}

// Subject interface
interface Subject {
    void addObserver(Observer observer);
    void removeObserver(Observer observer);
    void notifyObservers();
}

// Concrete Subject
class Stock implements Subject {
    private final String symbol;
    private double price;
    private final List<Observer> observers;
    
    public Stock(String symbol, double price) {
        this.symbol = symbol;
        this.price = price;
        this.observers = new ArrayList<>();
    }
    
    @Override
    public void addObserver(Observer observer) {
        observers.add(observer);
    }
    
    @Override
    public void removeObserver(Observer observer) {
        observers.remove(observer);
    }
    
    @Override
    public void notifyObservers() {
        for (Observer observer : observers) {
            observer.update(symbol, price);
        }
    }
    
    public void setPrice(double price) {
        this.price = price;
        notifyObservers();
    }
    
    public String getSymbol() { return symbol; }
    public double getPrice() { return price; }
}

// Concrete Observers
class StockDisplay implements Observer {
    private final String name;
    
    public StockDisplay(String name) {
        this.name = name;
    }
    
    @Override
    public void update(String stockSymbol, double price) {
        System.out.printf("[%s] %s price updated: $%.2f%n", name, stockSymbol, price);
    }
}

// Usage
public class ObserverDemo {
    public static void main(String[] args) {
        Stock appleStock = new Stock("AAPL", 150.0);
        
        // Create observers
        StockDisplay mobileApp = new StockDisplay("Mobile App");
        StockDisplay webApp = new StockDisplay("Web App");
        StockDisplay dashboard = new StockDisplay("Dashboard");
        
        // Subscribe observers
        appleStock.addObserver(mobileApp);
        appleStock.addObserver(webApp);
        appleStock.addObserver(dashboard);
        
        // Change price - all observers get notified
        appleStock.setPrice(155.50);
        appleStock.setPrice(148.75);
        
        // Unsubscribe one observer
        appleStock.removeObserver(webApp);
        appleStock.setPrice(160.25);  // Only mobile app and dashboard notified
    }
}
```

#### **Strategy Pattern** #strategy

**Use Case:** Algorithm selection at runtime

```java
// Strategy interface
interface PaymentStrategy {
    boolean pay(double amount);
    String getPaymentType();
}

// Concrete strategies
class CreditCardPayment implements PaymentStrategy {
    private final String cardNumber;
    private final String name;
    
    public CreditCardPayment(String cardNumber, String name) {
        this.cardNumber = cardNumber;
        this.name = name;
    }
    
    @Override
    public boolean pay(double amount) {
        System.out.printf("Paid $%.2f using Credit Card ending in %s%n", 
                         amount, cardNumber.substring(cardNumber.length() - 4));
        return true;
    }
    
    @Override
    public String getPaymentType() {
        return "Credit Card";
    }
}

class PayPalPayment implements PaymentStrategy {
    private final String email;
    
    public PayPalPayment(String email) {
        this.email = email;
    }
    
    @Override
    public boolean pay(double amount) {
        System.out.printf("Paid $%.2f using PayPal account %s%n", amount, email);
        return true;
    }
    
    @Override
    public String getPaymentType() {
        return "PayPal";
    }
}

// Context class
class ShoppingCart {
    private final List<Item> items;
    private PaymentStrategy paymentStrategy;
    
    public ShoppingCart() {
        this.items = new ArrayList<>();
    }
    
    public void addItem(Item item) {
        items.add(item);
    }
    
    public void setPaymentStrategy(PaymentStrategy paymentStrategy) {
        this.paymentStrategy = paymentStrategy;
    }
    
    public boolean checkout() {
        double totalAmount = items.stream().mapToDouble(Item::getPrice).sum();
        
        if (paymentStrategy == null) {
            System.out.println("Please select a payment method");
            return false;
        }
        
        System.out.printf("Total amount: $%.2f%n", totalAmount);
        return paymentStrategy.pay(totalAmount);
    }
}

class Item {
    private final String name;
    private final double price;
    
    public Item(String name, double price) {
        this.name = name;
        this.price = price;
    }
    
    public String getName() { return name; }
    public double getPrice() { return price; }
}

// Usage
public class StrategyDemo {
    public static void main(String[] args) {
        ShoppingCart cart = new ShoppingCart();
        cart.addItem(new Item("Book", 15.99));
        cart.addItem(new Item("Pen", 2.50));
        
        // Pay with credit card
        cart.setPaymentStrategy(new CreditCardPayment("1234567890123456", "John Doe"));
        cart.checkout();
        
        // Switch to PayPal
        cart.setPaymentStrategy(new PayPalPayment("john@example.com"));
        cart.checkout();
    }
}
```

---

## 🔥 Common LLD Problems

### **🎯 Must-Practice Problems** #must-do

#### **1. Parking Lot System** #parking-lot #must-do
**Complexity:** Medium | **Time:** 45-60 minutes | **Companies:** Amazon, Microsoft, Uber

**Requirements:**
- Multiple vehicle types (Car, Motorcycle, Truck)
- Different parking spot sizes
- Entry/exit with ticket system
- Hourly rate calculation
- Multiple floors support

**Key Classes:**
```java
// Core entities
class ParkingLot {
    private List<ParkingFloor> floors;
    private List<Entrance> entrances;
    private List<Exit> exits;
    
    public ParkingTicket parkVehicle(Vehicle vehicle) { /* */ }
    public boolean unparkVehicle(ParkingTicket ticket) { /* */ }
}

class ParkingFloor {
    private Map<SpotType, List<ParkingSpot>> spots;
    public ParkingSpot findAvailableSpot(VehicleType vehicleType) { /* */ }
}

abstract class Vehicle {
    protected String licensePlate;
    protected VehicleType type;
}

class ParkingSpot {
    private SpotType type;
    private boolean isAvailable;
    private Vehicle parkedVehicle;
}
```

#### **2. ATM Machine** #atm #must-do
**Complexity:** Medium | **Time:** 45 minutes | **Companies:** Bank of America, Wells Fargo

**Requirements:**
- Cash withdrawal, deposit, balance inquiry
- PIN authentication
- Cash dispensing mechanism
- Receipt generation
- Transaction logging

#### **3. Vending Machine** #vending-machine #must-do
**Complexity:** Medium-Hard | **Time:** 60 minutes | **Companies:** Google, Facebook

**Requirements:**
- Product selection and inventory management
- Coin/bill acceptance and change dispensing
- State-based behavior (idle, has money, dispensing)
- Product restocking capability

```java
// State pattern implementation
interface VendingMachineState {
    void insertCoin(int amount);
    void selectProduct(String productCode);
    void dispenseProduct();
    void cancelTransaction();
}

class VendingMachine {
    private VendingMachineState currentState;
    private int currentAmount;
    private Map<String, Product> inventory;
    
    public VendingMachine() {
        this.currentState = new IdleState();
        initializeInventory();
    }
    
    public void setState(VendingMachineState state) {
        this.currentState = state;
    }
    
    // Delegate all operations to current state
    public void insertCoin(int amount) {
        currentState.insertCoin(amount);
    }
    
    public void selectProduct(String productCode) {
        currentState.selectProduct(productCode);
    }
}

class IdleState implements VendingMachineState {
    @Override
    public void insertCoin(int amount) {
        // Transition to HasMoneyState
        System.out.println("Coin inserted: " + amount);
    }
    
    @Override
    public void selectProduct(String productCode) {
        System.out.println("Please insert money first");
    }
    
    // ... other methods
}
```

#### **4. Chess Game** #chess #hard
**Complexity:** Hard | **Time:** 90 minutes | **Companies:** Google, Amazon

**Requirements:**
- Complete chess rules implementation
- Move validation for all pieces
- Check/checkmate detection
- Castling and en passant special moves
- Game state management

#### **5. Library Management System** #library #medium
**Complexity:** Medium | **Time:** 60 minutes | **Companies:** Various

**Requirements:**
- Book catalog management
- Member registration and authentication
- Book borrowing and returning
- Due date tracking and fine calculation
- Search functionality

#### **6. Tic Tac Toe Game** #tictactoe #easy
**Complexity:** Easy-Medium | **Time:** 30 minutes | **Companies:** Entry-level

**Requirements:**
- 3x3 grid game board
- Two-player alternating turns
- Win condition checking
- Draw detection

```java
class TicTacToeGame {
    private Board board;
    private List<Player> players;
    private int currentPlayerIndex;
    private GameStatus status;
    
    public TicTacToeGame() {
        this.board = new Board();
        this.players = Arrays.asList(
            new Player("X", PlayerType.HUMAN),
            new Player("O", PlayerType.HUMAN)
        );
        this.currentPlayerIndex = 0;
        this.status = GameStatus.IN_PROGRESS;
    }
    
    public boolean makeMove(int row, int col) {
        if (status != GameStatus.IN_PROGRESS) {
            return false;
        }
        
        Player currentPlayer = players.get(currentPlayerIndex);
        if (board.placeMark(row, col, currentPlayer.getSymbol())) {
            if (checkWinner(currentPlayer)) {
                status = GameStatus.PLAYER_WINS;
            } else if (board.isFull()) {
                status = GameStatus.DRAW;
            } else {
                currentPlayerIndex = (currentPlayerIndex + 1) % 2;
            }
            return true;
        }
        return false;
    }
}

class Board {
    private char[][] grid;
    
    public Board() {
        this.grid = new char[3][3];
        initializeBoard();
    }
    
    public boolean placeMark(int row, int col, char symbol) {
        if (row >= 0 && row < 3 && col >= 0 && col < 3 && grid[row][col] == ' ') {
            grid[row][col] = symbol;
            return true;
        }
        return false;
    }
}
```

---

## 🎯 Interview Framework

### **📋 LLD Interview Process** #interview-process

#### **Step 1: Requirements Clarification (10-15 minutes)**
**Essential Questions to Ask:**
- What are the core functionalities needed?
- What are the scale requirements? (users, data volume)
- Are there any specific constraints? (performance, technology)
- Should we consider extensibility for future features?

**Example for Parking Lot:**
```
"Let me clarify the requirements:
- What types of vehicles should we support? (Car, Motorcycle, Truck, Bus?)
- How many floors and spots per floor?
- What's the pricing strategy? Flat rate or hourly?
- Do we need to track user accounts or just ticket-based?
- Should we consider handicap spots, electric vehicle charging?
- Any integration with payment systems?"
```

#### **Step 2: Core Classes & Relationships (15-20 minutes)**
**Design Process:**
1. Identify main entities (nouns in requirements)
2. Define relationships between entities
3. Identify key behaviors (methods)
4. Apply SOLID principles

**Template Approach:**
```java
// 1. Identify core entities
class ParkingLot { }
class ParkingFloor { }
class ParkingSpot { }
class Vehicle { }
class ParkingTicket { }

// 2. Define relationships
// ParkingLot HAS-A List<ParkingFloor>
// ParkingFloor HAS-A List<ParkingSpot>
// ParkingSpot HAS-A Vehicle (when occupied)

// 3. Add behaviors
class ParkingLot {
    public ParkingTicket parkVehicle(Vehicle vehicle);
    public double calculateFee(ParkingTicket ticket);
    public boolean unparkVehicle(ParkingTicket ticket);
}
```

#### **Step 3: Design Patterns Application (10-15 minutes)**
**Common Patterns for LLD:**
- **Factory Pattern:** Creating different types of objects
- **Strategy Pattern:** Different algorithms/behaviors
- **State Pattern:** Object behavior changes based on internal state
- **Observer Pattern:** Event notification
- **Singleton Pattern:** Single instance resources

#### **Step 4: Handle Edge Cases & Extensibility (10 minutes)**
**Consider:**
- Error handling and validation
- Thread safety (if applicable)
- Performance optimization
- Future extensibility

#### **Step 5: Code Implementation (15-20 minutes)**
**Implementation Tips:**
- Start with interfaces and abstract classes
- Implement core functionality first
- Keep methods small and focused
- Add comments for complex logic

---

## 💡 Best Practices

### **Code Quality Guidelines** #code-quality

#### **1. Naming Conventions**
```java
// ✅ GOOD: Clear, descriptive names
class ParkingSpotManager {
    private Map<SpotType, List<ParkingSpot>> availableSpots;
    
    public Optional<ParkingSpot> findNearestAvailableSpot(VehicleType vehicleType) {
        // Implementation
    }
}

// ❌ BAD: Vague, abbreviated names
class PSM {
    private Map<String, List<Object>> spots;
    
    public Object find(String type) {
        // Implementation
    }
}
```

#### **2. Method Design**
```java
// ✅ GOOD: Single responsibility, clear parameters
public class PaymentProcessor {
    public PaymentResult processPayment(PaymentRequest request) {
        validateRequest(request);
        PaymentResult result = chargeAmount(request.getAmount(), request.getPaymentMethod());
        logTransaction(request, result);
        return result;
    }
    
    private void validateRequest(PaymentRequest request) {
        if (request == null || request.getAmount() <= 0) {
            throw new IllegalArgumentException("Invalid payment request");
        }
    }
}

// ❌ BAD: Multiple responsibilities, unclear parameters
public class PaymentProcessor {
    public boolean process(double amt, String method, String user, boolean log) {
        // Doing too many things in one method
        if (amt <= 0) return false;
        // charge logic
        // logging logic
        // user notification logic
        return true;
    }
}
```

#### **3. Exception Handling**
```java
// ✅ GOOD: Specific exceptions, proper handling
public class VendingMachine {
    public void selectProduct(String productCode) throws ProductNotFoundException, InsufficientFundsException {
        Product product = findProduct(productCode);
        if (product == null) {
            throw new ProductNotFoundException("Product " + productCode + " not found");
        }
        
        if (currentAmount < product.getPrice()) {
            throw new InsufficientFundsException("Need $" + (product.getPrice() - currentAmount) + " more");
        }
        
        dispenseProduct(product);
    }
}

// Custom exceptions
class ProductNotFoundException extends Exception {
    public ProductNotFoundException(String message) {
        super(message);
    }
}
```

### **Thread Safety Considerations** #thread-safety

```java
// Thread-safe parking lot implementation
public class ThreadSafeParkingLot {
    private final Map<String, ParkingSpot> spots;
    private final ReadWriteLock lock = new ReentrantReadWriteLock();
    
    public ThreadSafeParkingLot() {
        this.spots = new ConcurrentHashMap<>();
    }
    
    public boolean parkVehicle(Vehicle vehicle) {
        lock.writeLock().lock();
        try {
            ParkingSpot availableSpot = findAvailableSpot(vehicle.getType());
            if (availableSpot != null) {
                availableSpot.parkVehicle(vehicle);
                return true;
            }
            return false;
        } finally {
            lock.writeLock().unlock();
        }
    }
    
    public List<ParkingSpot> getAvailableSpots() {
        lock.readLock().lock();
        try {
            return spots.values().stream()
                       .filter(ParkingSpot::isAvailable)
                       .collect(Collectors.toList());
        } finally {
            lock.readLock().unlock();
        }
    }
}
```

---

## 🎓 Study Progress & Next Steps

### **Mastery Checkpoints**

**✅ Beginner Level:**
- [ ] Understand all SOLID principles with examples
- [ ] Implement 3 basic design patterns (Singleton, Factory, Observer)
- [ ] Complete 2 easy LLD problems (Tic Tac Toe, Simple Calculator)
- [ ] Can explain class relationships and UML basics

**✅ Intermediate Level:**
- [ ] Applied design patterns appropriately in 5+ LLD problems
- [ ] Completed medium complexity problems (Parking Lot, ATM, Vending Machine)
- [ ] Understand thread safety and concurrency considerations
- [ ] Can handle requirements gathering and clarification

**✅ Advanced Level:**
- [ ] Designed complex systems (Chess, Library Management)
- [ ] Applied multiple patterns in single design
- [ ] Considered performance, scalability, and extensibility
- [ ] Can lead LLD discussion and mentor others

### **Practice Schedule**

**Week 1:** SOLID principles + Basic patterns (Singleton, Factory, Builder)
**Week 2:** Structural patterns (Adapter, Decorator) + 2 LLD problems
**Week 3:** Behavioral patterns (Observer, Strategy, State) + 3 LLD problems
**Week 4:** Advanced patterns + Complex LLD problems + Mock interviews

---

**Study Progress Tracker:**
- [ ] SOLID Principles (0/5 principles mastered)
- [ ] Design Patterns (0/15 patterns implemented)
- [ ] LLD Problems (0/10 problems solved)
- [ ] Code Quality Practices (0/5 practices applied)
- [ ] Mock Interviews (0/3 completed)

**Last Updated:** August 2025  
**Next Focus:** [Implement parking lot system with multiple design patterns]