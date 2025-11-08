# Adapter Pattern  
  
## Overview  
The Adapter pattern is a structural design pattern that allows objects with incompatible interfaces to work together. It acts as a bridge between two incompatible interfaces by wrapping an object and exposing a different interface.  
  
**Analogy**: Like a power adapter that lets you plug a US device into a European outlet - it converts one interface to another.  
  
## When to Use  
  
### Use Adapter Pattern When:  
1. **Integrating third-party libraries**  
   - External library has incompatible interface  
   - You cannot modify the third-party code  
   - Need to make it work with your existing system  
  
2. **Legacy code integration**  
   - Old system with different interface  
   - Don't want to rewrite legacy code  
   - Need gradual migration  
  
3. **Interface incompatibility**  
   - Two classes should work together but have incompatible interfaces  
   - Different method signatures, parameter types, or return types  
   - Different data formats (XML vs JSON, etc.)  
  
4. **Multiple implementations with different interfaces**  
   - Want to use several classes interchangeably  
   - Each has different interface  
   - Need a common interface for all  
  
5. **Reusing existing classes**  
   - Existing class does what you need  
   - But interface doesn't match what you require  
   - Creating adapter is cheaper than rewriting  
  
### Don't Use When:  
- You control both interfaces (just change them directly)  
- Interfaces are already compatible  
- A simple wrapper function would suffice  
- You're just trying to avoid fixing bad design  
  
## Key Components  
  
```  
┌─────────────┐  
│   Client    │  
└──────┬──────┘  
       │ uses       ▼┌─────────────────┐  
│ Target Interface│  
└──────┬──────────┘  
       │ implements       ▼┌─────────────┐      wraps      ┌──────────┐  
│   Adapter   │ ◆──────────────▶│ Adaptee  │  
└─────────────┘                 └──────────┘  
```  
  
1. **Target Interface**: The interface your client expects  
2. **Adapter**: Implements target interface and wraps adaptee  
3. **Adaptee**: The class with incompatible interface  
4. **Client**: Uses target interface (doesn't know about adapter)  
  
## Benefits  
  
### 1. **Single Responsibility Principle**  
```java  
// Adapter handles ONLY interface conversion  
class StripePayAdapter implements PaymentProcessor {  
    // Only converts PaymentProcessor → StripePay}  
```  
- Separates interface conversion from business logic  
- Each class has one reason to change  
  
### 2. **Open/Closed Principle**  
```java  
// Add new payment providers without modifying existing code  
PaymentProcessor stripe = new StripePayAdapter(new StripePay(), token);  
PaymentProcessor paypal = new PayPalAdapter(new PayPal());  
```  
- Open for extension (add new adapters)  
- Closed for modification (don't touch client code)  
  
### 3. **Reusability**  
- Use existing classes without modification  
- Integrate third-party libraries seamlessly  
- Preserve legacy code  
  
### 4. **Flexibility**  
- Swap implementations at runtime  
- Support multiple incompatible interfaces  
- Easy to add new adaptees  
  
### 5. **Maintainability**  
- Changes to adaptee don't affect client  
- Clear separation of concerns  
- Easy to test in isolation  
  
## Implementation Types  
  
### 1. Object Adapter (Composition) ✅ Recommended  
  
```java  
public class StripePayAdapter implements PaymentProcessor {  
    private StripePay stripePay;  // Composition  
    public StripePayAdapter(StripePay stripePay, String cardToken) {        this.stripePay = stripePay;        this.cardToken = cardToken;    }  
    @Override    public boolean processPayment(double amount, String currency) {        String txId = stripePay.charge(new Money(amount, currency), cardToken);        return txId != null;    }}  
```  
  
**Advantages:**  
- Works with any StripePay subclass  
- Can adapt multiple objects  
- More flexible  
- Loose coupling  
  
**Disadvantages:**  
- Slightly more code (delegation)  
  
### 2. Class Adapter (Inheritance)  
  
```java  
public class StripePayAdapter extends StripePay implements PaymentProcessor {  
    @Override    public boolean processPayment(double amount, String currency) {        String txId = this.charge(new Money(amount, currency), cardToken);        return txId != null;    }}  
```  
  
**Advantages:**  
- Less code (no delegation)  
- Can override adaptee methods  
  
**Disadvantages:**  
- Requires multiple inheritance (not possible in Java for classes)  
- Tight coupling  
- Can only adapt specific class, not its subclasses  
- Less flexible  
  
**In Java, use Object Adapter!**  
  
## Real-World Use Cases  
  
### 1. **Payment Gateways**  
```java  
PaymentProcessor stripe = new StripeAdapter(stripePay);  
PaymentProcessor paypal = new PayPalAdapter(paypal);  
PaymentProcessor square = new SquareAdapter(square);  
// All used via same interface  
```  
  
### 2. **Database Drivers (JDBC)**  
```java  
// Different databases, same interface  
Connection conn = DriverManager.getConnection(url);  
// Works with MySQL, PostgreSQL, Oracle, etc.  
```  
  
### 3. **Logging Frameworks**  
```java  
// Adapting different logging libraries to SLF4J  
Logger logger = LoggerFactory.getLogger(MyClass.class);  
// Works with Log4j, Logback, JUL, etc.  
```  
  
### 4. **Data Format Conversion**  
```java  
// XML to JSON adapter  
JsonObject json = new XmlToJsonAdapter(xmlData).convert();  
```  
  
### 5. **Legacy System Integration**  
```java  
// Modern REST API wrapping old SOAP service  
RestController adapter = new SoapToRestAdapter(legacySoapService);  
```  
  
### 6. **UI Frameworks**  
```java  
// Adapting data models to UI list views  
ListAdapter adapter = new ArrayAdapter<>(context, layout, data);  
```  
  
## Adapter vs Similar Patterns  
  
| Pattern | Purpose | Key Difference |  
|---------|---------|----------------|  
| **Adapter** | Make incompatible interfaces work together | Converts existing interface |  
| **Decorator** | Add new functionality | Same interface, enhanced behavior |  
| **Proxy** | Control access to object | Same interface, controls access |  
| **Facade** | Simplify complex subsystem | Provides simpler interface to many classes |  
| **Bridge** | Separate abstraction from implementation | Designed upfront, not retrofitted |  
  
### Adapter vs Decorator  
```java  
// Adapter: CHANGES interface  
PaymentProcessor adapter = new StripeAdapter(stripePay);  // Different interface  
  
// Decorator: SAME interface, adds behavior  
PaymentProcessor decorated = new LoggingPaymentProcessor(processor);  // Same interface  
```  
  
### Adapter vs Facade  
```java  
// Adapter: One-to-one conversion  
StripeAdapter adapts ONE StripePay class  
  
// Facade: Simplifies MANY classes  
PaymentFacade simplifies entire payment subsystem (validation, processing, logging, etc.)  
```  
  
## Common Pitfalls  
  
### 1. **Forgetting to Handle Exceptions**  
```java  
// Bad: Let exceptions leak  
public boolean processPayment(double amount, String currency) {  
    return stripePay.charge(new Money(amount, currency), token) != null;    // StripePayException leaks to client!}  
  
// Good: Translate exceptions  
public boolean processPayment(double amount, String currency) {  
    try {        return stripePay.charge(new Money(amount, currency), token) != null;    } catch (StripePayException e) {        return false;  // Or wrap in your own exception    }}  
```  
  
### 2. **Adapter Doing Too Much**  
```java  
// Bad: Adapter has business logic  
public boolean processPayment(double amount, String currency) {  
    if (amount > 1000) {        // Send fraud alert - NOT adapter's job!    }    return stripePay.charge(new Money(amount, currency), token) != null;}  
  
// Good: Adapter only converts interface  
public boolean processPayment(double amount, String currency) {  
    return stripePay.charge(new Money(amount, currency), token) != null;}  
```  
  
### 3. **Not Validating Inputs**  
```java  
// Better: Validate before converting  
public boolean processPayment(double amount, String currency) {  
    if (amount < 0 || currency == null) {        throw new IllegalArgumentException("Invalid payment details");    }    return stripePay.charge(new Money(amount, currency), token) != null;}  
```  
  
### 4. **Tight Coupling**  
```java  
// Bad: Adapter creates adaptee  
class StripeAdapter {  
    private StripePay stripePay = new StripePay();  // Hard-coded!}  
  
// Good: Dependency injection  
class StripeAdapter {  
    private StripePay stripePay;  
    public StripeAdapter(StripePay stripePay) {  // Injected        this.stripePay = stripePay;    }}  
```  
  
### 5. **Over-adapting**  
```java  
// Don't create adapters for every small difference  
// If you control both interfaces, just make them compatible!  
```  
  
## Design Decisions  
  
### Where to Store Extra Parameters?  
  
**Problem**: Target interface doesn't support all parameters needed by adaptee.  
  
```java  
// Target interface  
interface PaymentProcessor {  
    boolean processPayment(double amount, String currency);}  
  
// Adaptee needs cardToken, but interface doesn't support it!  
class StripePay {  
    String charge(Money money, String cardToken);}  
```  
  
**Solution 1: Constructor Injection** ✅ (Used in our example)  
```java  
class StripeAdapter {  
    private String cardToken;  
    public StripeAdapter(StripePay stripePay, String cardToken) {        this.cardToken = cardToken;  // Store extra param    }  
    public boolean processPayment(double amount, String currency) {        return stripePay.charge(new Money(amount, currency), cardToken) != null;    }}  
```  
- ✅ Simple and clean  
- ✅ Works when token doesn't change per transaction  
- ❌ Not flexible if token changes per payment  
  
**Solution 2: Setter Method**  
```java  
class StripeAdapter {  
    private String cardToken;  
    public void setCardToken(String token) {        this.cardToken = token;    }}  
```  
- ✅ More flexible  
- ❌ Can forget to set before calling  
- ❌ Not thread-safe  
  
**Solution 3: ThreadLocal**  
```java  
class StripeAdapter {  
    private ThreadLocal<String> cardToken = new ThreadLocal<>();}  
```  
- ✅ Thread-safe  
- ❌ More complex  
  
**Solution 4: Extend Target Interface** (if possible)  
```java  
interface EnhancedPaymentProcessor extends PaymentProcessor {  
    boolean processPayment(double amount, String currency, String cardToken);}  
```  
- ✅ Most flexible  
- ❌ Changes interface (may not be possible)  
  
## Interview Questions to Expect  
  
### 1. **What problem does Adapter pattern solve?**  
**Answer**: Makes incompatible interfaces work together without modifying existing code.  
  
### 2. **Adapter vs Decorator?**  
**Answer**:  
- Adapter: **Changes** interface (interface conversion)  
- Decorator: **Same** interface (adds behavior)  
  
### 3. **When would you use Adapter pattern?**  
**Answer**:  
- Integrating third-party libraries  
- Legacy system integration  
- Making multiple classes work through common interface  
  
### 4. **What's the difference between Object Adapter and Class Adapter?**  
**Answer**:  
- Object Adapter: Uses composition (has-a relationship)  
- Class Adapter: Uses inheritance (is-a relationship)  
- Object Adapter preferred in Java (no multiple inheritance)  
  
### 5. **Can you give a real-world example of Adapter pattern?**  
**Answer**: JDBC drivers - different databases (MySQL, PostgreSQL) work through same `Connection` interface.  
  
### 6. **What are the downsides of Adapter pattern?**  
**Answer**:  
- Increases complexity (extra layer)  
- Performance overhead (delegation)  
- Can be overused (if you control both sides, just make them compatible)  
  
### 7. **How do you handle exceptions in an adapter?**  
**Answer**: Catch adaptee's exceptions and either:  
- Convert to boolean/null return  
- Wrap in target interface's expected exception  
- Never let adaptee exceptions leak to client  
  
### 8. **What if the adaptee needs extra parameters not in target interface?**  
**Answer**: Store them in adapter as instance variables (constructor injection or setters).  
  
## Code Example from Our Implementation  
  
### Target Interface  
```java  
public interface PaymentProcessor {  
    boolean processPayment(double amount, String currency);}  
```  
  
### Adaptee (Third-party)  
```java  
public class StripePay {  
    public String charge(Money money, String cardToken) {        // Different method signature!    }}  
```  
  
### Adapter  
```java  
public class StripePayAdapter implements PaymentProcessor {  
    private StripePay stripePay;  // Composition    private String cardToken;     // Extra param  
    public StripePayAdapter(StripePay stripePay, String cardToken) {        this.stripePay = stripePay;        this.cardToken = cardToken;    }  
    @Override    public boolean processPayment(double amount, String currency) {        // Convert interface: processPayment → charge        // Convert data: (amount, currency) → Money        String txId = stripePay.charge(            new Money(amount, currency),  // Data conversion            this.cardToken        );        return txId != null;  // Convert return type: String → boolean    }}  
```  
  
### Client Code  
```java  
// Client works with PaymentProcessor interface  
PaymentProcessor processor1 = new SimplePaymentProcessor();  
PaymentProcessor processor2 = new StripePayAdapter(stripePay, token);  
  
// Both used identically (polymorphism)  
processOrder(processor1, 99.99, "USD");  
processOrder(processor2, 149.99, "EUR");  
```  
  
## Key Takeaways  
  
1. **Purpose**: Bridge between incompatible interfaces  
2. **When**: Third-party integration, legacy systems, interface mismatches  
3. **How**: Wrapper that implements target interface and delegates to adaptee  
4. **Type**: Use Object Adapter (composition) in Java  
5. **Remember**: Adapter only converts interface - no business logic!  
6. **Extra params**: Store in adapter as instance variables if target interface doesn't support them  
7. **Exceptions**: Always translate/handle adaptee exceptions  
  
## Summary  
  
The Adapter pattern is your go-to solution when:  
- ✅ You need to integrate external code you can't modify  
- ✅ Interfaces are incompatible  
- ✅ You want to reuse existing classes  
- ✅ You need a common interface for different implementations  
  
Remember: The adapter is like a translator - it just converts one language (interface) to another. It doesn't add business logic or new functionality.