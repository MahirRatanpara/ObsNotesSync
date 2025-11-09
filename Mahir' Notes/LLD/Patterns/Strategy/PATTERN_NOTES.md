# Strategy Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Define a family of algorithms, encapsulate each one, and make them interchangeable, allowing the algorithm to vary independently from clients that use it.

## 📖 The Problem
**Without Strategy**: Conditional nightmare
```java
class PaymentProcessor {
    public void processPayment(String type, double amount) {
        if (type.equals("CREDIT_CARD")) {
            // Credit card payment logic
            System.out.println("Processing credit card: " + amount);
        } else if (type.equals("PAYPAL")) {
            // PayPal payment logic
            System.out.println("Processing PayPal: " + amount);
        } else if (type.equals("CRYPTO")) {
            // Crypto payment logic
            System.out.println("Processing crypto: " + amount);
        }
    }
}
```
❌ Violates Open/Closed Principle (modify code for new payment method)
❌ Hard to test each payment method separately
❌ Can't change payment method at runtime easily
❌ All payment logic mixed in one class

**With Strategy**: Clean, interchangeable algorithms
```java
interface PaymentStrategy {
    void pay(double amount);
}

class CreditCardPayment implements PaymentStrategy {
    public void pay(double amount) {
        System.out.println("Paid via credit card: " + amount);
    }
}

class PaymentProcessor {
    private PaymentStrategy strategy;

    public void setStrategy(PaymentStrategy strategy) {
        this.strategy = strategy;
    }

    public void processPayment(double amount) {
        strategy.pay(amount);  // Delegate to strategy
    }
}
```
✅ Easy to add new payment methods (new class)
✅ Each strategy can be tested independently
✅ Can swap strategies at runtime
✅ Clean separation of concerns

## 🔑 Key Concept
```
Context → uses → Strategy interface
                      ▲
                      │ implements
              ConcreteStrategy A, B, C
```

**Core Idea**: Encapsulate algorithms in separate classes, allow runtime selection.

**Also Known As**: Policy Pattern

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ Multiple algorithms for same task | ✗ Only one algorithm exists |
| ✓ Need to switch algorithms at runtime | ✗ Algorithm never changes |
| ✓ Many conditional statements selecting algorithm | ✗ Simple if-else suffices |
| ✓ Algorithms have different implementations | ✗ Overhead not justified |

## 📐 Structure

```
┌──────────────┐
│   Context    │ ◄─── Uses strategy
├──────────────┤
│ -strategy    │
│ +setStrategy()│
│ +execute()   │──────┐
└──────────────┘      │ delegates to
                      ▼
              ┌───────────────┐
              │   Strategy    │ ◄─── Algorithm interface
              ├───────────────┤
              │ +algorithm()  │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
┌───────▼─────┐ ┌─────▼──────┐ ┌───▼────────┐
│ConcreteStrat│ │ConcreteStrat│ │ConcreteStrat│
│    A        │ │     B       │ │     C      │
├─────────────┤ ├────────────┤ ├────────────┤
│+algorithm() │ │+algorithm()│ │+algorithm()│
└─────────────┘ └────────────┘ └────────────┘
```

## 💻 Implementation Pattern

### 1. Strategy Interface
```java
public interface PaymentStrategy {
    void pay(double amount);
    boolean validate();
}
```

### 2. Concrete Strategies
```java
public class CreditCardPayment implements PaymentStrategy {
    private String cardNumber;
    private String cvv;

    public CreditCardPayment(String cardNumber, String cvv) {
        this.cardNumber = cardNumber;
        this.cvv = cvv;
    }

    @Override
    public boolean validate() {
        // Validate card number and CVV
        return cardNumber != null && cardNumber.length() == 16;
    }

    @Override
    public void pay(double amount) {
        if (validate()) {
            System.out.println("Paid $" + amount + " using Credit Card " + cardNumber);
        } else {
            System.out.println("Invalid card");
        }
    }
}

public class PayPalPayment implements PaymentStrategy {
    private String email;
    private String password;

    public PayPalPayment(String email, String password) {
        this.email = email;
        this.password = password;
    }

    @Override
    public boolean validate() {
        return email != null && email.contains("@");
    }

    @Override
    public void pay(double amount) {
        if (validate()) {
            System.out.println("Paid $" + amount + " using PayPal " + email);
        } else {
            System.out.println("Invalid PayPal credentials");
        }
    }
}

public class CryptoPayment implements PaymentStrategy {
    private String walletAddress;

    public CryptoPayment(String walletAddress) {
        this.walletAddress = walletAddress;
    }

    @Override
    public boolean validate() {
        return walletAddress != null && walletAddress.length() == 42;
    }

    @Override
    public void pay(double amount) {
        if (validate()) {
            System.out.println("Paid $" + amount + " using Crypto wallet " + walletAddress);
        } else {
            System.out.println("Invalid wallet");
        }
    }
}
```

### 3. Context
```java
public class ShoppingCart {
    private List<Item> items = new ArrayList<>();
    private PaymentStrategy paymentStrategy;

    public void addItem(Item item) {
        items.add(item);
    }

    public void setPaymentStrategy(PaymentStrategy strategy) {
        this.paymentStrategy = strategy;
    }

    public double calculateTotal() {
        return items.stream().mapToDouble(Item::getPrice).sum();
    }

    public void checkout() {
        double total = calculateTotal();
        if (paymentStrategy == null) {
            System.out.println("Please select a payment method");
            return;
        }
        paymentStrategy.pay(total);
    }
}
```

### 4. Usage
```java
ShoppingCart cart = new ShoppingCart();
cart.addItem(new Item("Laptop", 1200));
cart.addItem(new Item("Mouse", 25));

// Customer chooses payment method at runtime
PaymentStrategy payment = new CreditCardPayment("1234567812345678", "123");
cart.setPaymentStrategy(payment);
cart.checkout();  // Paid $1225 using Credit Card

// Customer can change payment method
payment = new PayPalPayment("user@example.com", "pass123");
cart.setPaymentStrategy(payment);
cart.checkout();  // Paid $1225 using PayPal
```

## 🎓 Real-World Examples

| Domain | Strategies | Context |
|--------|-----------|---------|
| **Sorting** | QuickSort, MergeSort, BubbleSort | Sorter |
| **Compression** | ZIP, RAR, TAR | FileCompressor |
| **Navigation** | Car, Bike, Walk | RouteCalculator |
| **Discount** | SeasonalDiscount, MemberDiscount | PriceCalculator |
| **Validation** | EmailValidator, PhoneValidator | InputValidator |

### Sorting Example
```java
interface SortStrategy {
    void sort(int[] array);
}

class QuickSort implements SortStrategy {
    public void sort(int[] array) {
        // QuickSort implementation
        System.out.println("Sorting using QuickSort");
    }
}

class MergeSort implements SortStrategy {
    public void sort(int[] array) {
        // MergeSort implementation
        System.out.println("Sorting using MergeSort");
    }
}

class Sorter {
    private SortStrategy strategy;

    public void setStrategy(SortStrategy strategy) {
        this.strategy = strategy;
    }

    public void sort(int[] array) {
        strategy.sort(array);
    }
}

// Usage
Sorter sorter = new Sorter();
sorter.setStrategy(new QuickSort());
sorter.sort(data);  // Uses QuickSort

sorter.setStrategy(new MergeSort());
sorter.sort(data);  // Uses MergeSort
```

## ⚖️ Strategy vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Strategy** | Interchangeable algorithms | Client chooses algorithm |
| **State** | State-dependent behavior | State controls transitions |
| **Template Method** | Algorithm skeleton with hooks | Inheritance-based |
| **Command** | Encapsulate request | Stores operation + undo |

### Strategy vs State
```java
// Strategy: Client explicitly chooses
context.setStrategy(new StrategyA());  // Client decides

// State: State auto-transitions internally
context.operation();  // State may change internally
```

### Strategy vs Template Method
```java
// Strategy: Composition (has-a)
class Context {
    private Strategy strategy;  // Composition
    void execute() { strategy.algorithm(); }
}

// Template Method: Inheritance (is-a)
abstract class Algorithm {
    final void execute() {
        step1();  // Fixed
        step2();  // Overridden by subclass
    }
    abstract void step2();
}
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Client aware of all strategies
```java
// Wrong: Client has to know all implementations
if (type.equals("CREDIT")) {
    cart.setStrategy(new CreditCardPayment(...));
} else if (type.equals("PAYPAL")) {
    cart.setStrategy(new PayPalPayment(...));
}
// Defeats the purpose!

// Better: Factory Pattern
PaymentStrategy strategy = PaymentFactory.create(type);
cart.setStrategy(strategy);
```

### ❌ Mistake 2: Strategy has too much logic
```java
// Wrong: Strategy does everything
class PaymentStrategy {
    void pay() {
        validateUser();
        checkBalance();
        processPayment();
        sendEmail();
        updateDatabase();  // ❌ Too much responsibility
    }
}

// Right: Strategy focuses on algorithm, context handles rest
class PaymentStrategy {
    void pay(double amount) {
        // Only payment-specific logic
    }
}
```

### ❌ Mistake 3: Not setting strategy
```java
// Wrong: No default strategy
Context context = new Context();
context.execute();  // NullPointerException!

// Right: Provide default or validate
class Context {
    private Strategy strategy = new DefaultStrategy();  // ✅ Default

    void execute() {
        if (strategy == null) {
            throw new IllegalStateException("Strategy not set");
        }
        strategy.algorithm();
    }
}
```

### ❌ Mistake 4: Strategies not interchangeable
```java
// Wrong: Strategies have different interfaces
class StrategyA {
    void methodA(int x) { }
}

class StrategyB {
    void methodB(String s) { }  // ❌ Different signature
}

// Right: Same interface
interface Strategy {
    void execute(Data data);  // ✅ Uniform interface
}
```

### ❌ Mistake 5: Strategy stores context state
```java
// Wrong: Strategy has state
class ConcreteStrategy implements Strategy {
    private Data contextData;  // ❌ Don't store context state

    void algorithm() {
        // Uses stored state
    }
}

// Right: Strategy is stateless, receives data as parameter
class ConcreteStrategy implements Strategy {
    void algorithm(Data data) {  // ✅ Receives data
        // Uses parameter
    }
}
```

## 🎤 Interview Questions & Answers

### Q1: What is the Strategy pattern?
**A**: A behavioral pattern that defines a family of algorithms, encapsulates each one in a separate class, and makes them interchangeable. The algorithm can be selected at runtime by the client.

### Q2: When would you use Strategy?
**A**: When:
1. You have multiple ways to perform the same task
2. Need to switch algorithms at runtime
3. Want to avoid conditional statements for algorithm selection
4. Algorithms should be independent and interchangeable

### Q3: What are the key components?
**A**:
1. **Strategy**: Interface for all algorithms
2. **ConcreteStrategy**: Specific implementations
3. **Context**: Uses a Strategy, can change it at runtime

### Q4: Strategy vs State pattern?
**A**:
- **Strategy**: Client chooses which strategy to use
- **State**: States manage their own transitions
- **Strategy**: Algorithms are independent
- **State**: States know about each other

### Q5: How is it different from Template Method?
**A**:
- **Strategy**: Uses composition (has-a), runtime flexibility
- **Template Method**: Uses inheritance (is-a), compile-time
- **Strategy**: Entire algorithm swappable
- **Template Method**: Only some steps overridden

### Q6: What are the benefits?
**A**:
1. Open/Closed Principle (add strategies without modifying context)
2. Single Responsibility (each algorithm in separate class)
3. Runtime flexibility (switch algorithms dynamically)
4. Eliminates conditional statements
5. Easier testing (test strategies independently)

### Q7: What are the drawbacks?
**A**:
1. More classes (one per strategy)
2. Client must be aware of strategies
3. Communication overhead between context and strategy
4. May be overkill for simple algorithms

### Q8: Can you give a Java library example?
**A**:
- `Comparator` interface: Different sorting strategies
```java
List<String> list = Arrays.asList("banana", "apple", "cherry");
list.sort(Comparator.naturalOrder());  // Strategy 1
list.sort(Comparator.reverseOrder());  // Strategy 2
list.sort((a, b) -> a.length() - b.length());  // Strategy 3
```

### Q9: Should strategies be stateless?
**A**: **Yes**, ideally. Strategies should:
- Not store context state
- Receive all needed data as parameters
- Be reusable across multiple contexts
- Can store algorithm-specific configuration (e.g., compression level)

### Q10: How do you handle strategy selection?
**A**: Options:
1. **Client chooses**: `context.setStrategy(new ConcreteStrategy())`
2. **Factory**: `strategy = StrategyFactory.create(type)`
3. **Dependency Injection**: Framework injects strategy
4. **Configuration**: Read from config file

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Make algorithms interchangeable |
| **Core Idea** | Encapsulate algorithms in separate classes |
| **Selection** | Client chooses strategy at runtime |
| **Composition** | Context has-a strategy (not is-a) |
| **vs State** | Strategy = client choice; State = auto-transition |
| **vs Template** | Strategy = composition; Template = inheritance |

## 🔍 Quick Checklist

When implementing Strategy pattern:
- [ ] Define Strategy interface with algorithm method
- [ ] Create ConcreteStrategy classes implementing the interface
- [ ] Context has a Strategy field
- [ ] Context provides `setStrategy()` method
- [ ] Context delegates to strategy
- [ ] Strategies are stateless (no context state)
- [ ] All strategies have same interface
- [ ] Consider Factory for strategy creation
- [ ] Don't use if only one algorithm exists
- [ ] Test strategies independently

## 📊 Pattern Template

```java
// 1. Strategy Interface
interface Strategy {
    void algorithm(Data data);
}

// 2. Concrete Strategies
class StrategyA implements Strategy {
    public void algorithm(Data data) {
        // Algorithm A implementation
    }
}

class StrategyB implements Strategy {
    public void algorithm(Data data) {
        // Algorithm B implementation
    }
}

// 3. Context
class Context {
    private Strategy strategy;

    public void setStrategy(Strategy strategy) {
        this.strategy = strategy;
    }

    public void executeStrategy(Data data) {
        if (strategy == null) {
            throw new IllegalStateException("Strategy not set");
        }
        strategy.algorithm(data);
    }
}

// 4. Usage
Context context = new Context();
context.setStrategy(new StrategyA());
context.executeStrategy(data);  // Uses StrategyA

context.setStrategy(new StrategyB());
context.executeStrategy(data);  // Uses StrategyB
```

## 💡 Remember
> "Strategy is like choosing transportation: you can drive, bike, or walk to the same destination. The goal is the same, but the method varies based on your choice."

## 🔧 Modern Java Example (Lambdas)

Since Java 8, strategies with single methods can use lambdas:

```java
// Strategy interface (functional)
interface DiscountStrategy {
    double apply(double price);
}

// Context
class PriceCalculator {
    private DiscountStrategy strategy;

    public void setStrategy(DiscountStrategy strategy) {
        this.strategy = strategy;
    }

    public double calculate(double price) {
        return strategy.apply(price);
    }
}

// Usage with lambdas (no concrete classes needed!)
PriceCalculator calc = new PriceCalculator();

calc.setStrategy(price -> price * 0.9);  // 10% off
calc.calculate(100);  // 90.0

calc.setStrategy(price -> price - 20);   // $20 off
calc.calculate(100);  // 80.0

calc.setStrategy(price -> price * 0.5);  // 50% off
calc.calculate(100);  // 50.0
```

## 📈 Comparison Table

| Aspect | Strategy | State | Template Method |
|--------|----------|-------|-----------------|
| **Mechanism** | Composition | Composition | Inheritance |
| **Runtime change** | ✅ Yes | ✅ Yes | ❌ No |
| **Who decides** | Client | State itself | Subclass |
| **Relation** | Independent | Know each other | Parent-child |
| **Purpose** | Algorithm selection | State management | Code reuse |

---

**For Amazon Interviews**: Focus on **algorithm encapsulation** (why), **composition over inheritance** (how), and **Strategy vs State** difference. Be ready to discuss real examples (sorting, payment methods) and when to use lambdas vs classes. Mention Open/Closed Principle adherence.
