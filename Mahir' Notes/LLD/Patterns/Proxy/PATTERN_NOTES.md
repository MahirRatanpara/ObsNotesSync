# Proxy Pattern

## Overview
The Proxy pattern is a structural design pattern that provides a surrogate or placeholder object for another object. The proxy controls access to the original object, allowing you to perform operations before or after the request reaches the original object.

**Analogy**: Like a credit card acting as a proxy for your bank account. When you pay with a credit card, it doesn't directly access your cash - it's a proxy that adds extra features (delayed payment, fraud protection, transaction logging) while eventually accessing your bank account.

## When to Use

### Use Proxy Pattern When:
1. **Lazy Initialization (Virtual Proxy)**
   - Object creation is expensive (heavy resource, large image, etc.)
   - Object might not be needed immediately
   - Want to delay creation until actually used

2. **Access Control (Protection Proxy)**
   - Need to control who can access an object
   - Different permissions for different clients
   - Authentication/authorization required

3. **Remote Object Access (Remote Proxy)**
   - Object exists in different address space
   - Need to communicate over network
   - Hide network communication complexity

4. **Logging/Monitoring (Logging Proxy)**
   - Track method calls, parameters, results
   - Measure performance
   - Audit access

5. **Caching (Caching Proxy)**
   - Store expensive operation results
   - Return cached results when possible
   - Improve performance

6. **Smart Reference**
   - Count references to object
   - Load persistent object on first access
   - Lock object before modification

### Don't Use When:
- Direct access is sufficient and simple
- No additional behavior needed
- Performance overhead is unacceptable
- Complexity outweighs benefits

## Types of Proxies

### 1. Virtual Proxy (Lazy Loading)
```java
// Delay expensive object creation
class ImageProxy implements Image {
    private RealImage realImage; // Created only when needed
    private String filename;

    public void display() {
        if (realImage == null) {
            realImage = new RealImage(filename); // Lazy init
        }
        realImage.display();
    }
}
```

### 2. Protection Proxy (Access Control)
```java
// Control access based on permissions
class ProtectedDocument implements Document {
    private RealDocument document;
    private User currentUser;

    public void view() {
        if (currentUser.hasPermission("READ")) {
            document.view();
        } else {
            throw new AccessDeniedException();
        }
    }
}
```

### 3. Remote Proxy
```java
// Access object in different address space
class RemoteServiceProxy implements Service {
    private String serverUrl;

    public String getData() {
        // Make HTTP request to remote server
        return httpClient.get(serverUrl + "/data");
    }
}
```

### 4. Caching Proxy
```java
// Cache expensive results
class CachingProxy implements DataService {
    private RealDataService service;
    private Map<String, Data> cache;

    public Data getData(String id) {
        if (cache.containsKey(id)) {
            return cache.get(id); // Return cached
        }
        Data data = service.getData(id);
        cache.put(id, data); // Cache for next time
        return data;
    }
}
```

### 5. Logging Proxy
```java
// Log all method calls
class LoggingProxy implements Service {
    private RealService service;

    public void operation() {
        System.out.println("Calling operation() at " + System.currentTimeMillis());
        service.operation();
        System.out.println("operation() completed");
    }
}
```

## Key Components

```
┌─────────────┐
│   Subject   │ ←─── Common interface
├─────────────┤
│ +request()  │
└──────┬──────┘
       │
   ┌───┴─────────────┐
   │                 │
┌──▼────────┐  ┌────▼─────┐
│   Proxy   │  │RealSubject│
├───────────┤  ├───────────┤
│-realSubj  │  │+request() │
│+request() │  └───────────┘
└─────┬─────┘
      │
      │ delegates to
      ▼
┌──────────────┐
│ RealSubject  │
└──────────────┘
```

1. **Subject**: Common interface for RealSubject and Proxy
2. **RealSubject**: Real object that does the actual work
3. **Proxy**: Maintains reference to RealSubject, controls access

## Benefits

### 1. **Lazy Initialization**
```java
// Create expensive object only when needed
ImageProxy proxy = new ImageProxy("large_image.jpg");
// Image not loaded yet!

proxy.display(); // Now loaded
```

### 2. **Access Control**
```java
// Control who can access
Document doc = new ProtectedDocument(realDoc, currentUser);
doc.edit(); // Checks permissions first
```

### 3. **Performance Optimization**
```java
// Cache expensive computations
DataService service = new CachingProxy(realService);
Data data = service.compute(params); // Computed
Data data2 = service.compute(params); // Cached!
```

### 4. **Logging and Monitoring**
```java
// Track all access
Service service = new LoggingProxy(realService);
service.operation(); // Logged automatically
```

### 5. **Open/Closed Principle**
```java
// Add new functionality without modifying RealSubject
Service service = new LoggingProxy(
    new CachingProxy(
        new RealService()
    )
);
```

## Implementation Example

### Scenario: Image Viewer with Lazy Loading

```java
// Subject Interface
interface Image {
    void display();
    String getMetadata();
}

// RealSubject - Heavy object
class RealImage implements Image {
    private String filename;
    private byte[] imageData;

    public RealImage(String filename) {
        this.filename = filename;
        loadFromDisk(); // Expensive operation
    }

    private void loadFromDisk() {
        System.out.println("Loading image from disk: " + filename);
        // Simulate expensive I/O operation
        try {
            Thread.sleep(2000); // Simulate delay
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        // Load actual image data
        imageData = new byte[1024 * 1024]; // 1MB image
        System.out.println("Image loaded: " + filename);
    }

    @Override
    public void display() {
        System.out.println("Displaying image: " + filename);
    }

    @Override
    public String getMetadata() {
        return "Filename: " + filename + ", Size: " + imageData.length + " bytes";
    }
}

// Proxy - Lazy initialization
class ImageProxy implements Image {
    private String filename;
    private RealImage realImage; // Will be created lazily

    public ImageProxy(String filename) {
        this.filename = filename;
        System.out.println("ImageProxy created for: " + filename);
        // RealImage NOT created yet!
    }

    @Override
    public void display() {
        // Create RealImage only when actually needed
        if (realImage == null) {
            System.out.println("First access - initializing real image...");
            realImage = new RealImage(filename);
        }
        realImage.display();
    }

    @Override
    public String getMetadata() {
        // Can return metadata without loading full image
        return "Filename: " + filename + " (via proxy)";
    }
}

// Client Code
public class Main {
    public static void main(String[] args) {
        System.out.println("=== Creating image proxies ===");
        Image image1 = new ImageProxy("photo1.jpg");
        Image image2 = new ImageProxy("photo2.jpg");
        Image image3 = new ImageProxy("photo3.jpg");
        // Images NOT loaded yet! Fast creation.

        System.out.println("\n=== Getting metadata ===");
        System.out.println(image1.getMetadata()); // No loading needed
        System.out.println(image2.getMetadata());

        System.out.println("\n=== Displaying images ===");
        image1.display(); // NOW image1 loads (slow)
        image1.display(); // Already loaded (fast)

        System.out.println("\n=== Performance comparison ===");
        long start = System.currentTimeMillis();
        Image directImage = new RealImage("direct.jpg"); // Loads immediately
        long directTime = System.currentTimeMillis() - start;

        start = System.currentTimeMillis();
        Image proxyImage = new ImageProxy("proxy.jpg"); // Fast creation
        long proxyTime = System.currentTimeMillis() - start;

        System.out.println("Direct creation time: " + directTime + "ms");
        System.out.println("Proxy creation time: " + proxyTime + "ms");
    }
}
```

## Advanced Example: Protection Proxy

```java
// Subject
interface BankAccount {
    void deposit(double amount);
    void withdraw(double amount);
    double getBalance();
}

// RealSubject
class RealBankAccount implements BankAccount {
    private double balance;
    private String accountNumber;

    public RealBankAccount(String accountNumber, double initialBalance) {
        this.accountNumber = accountNumber;
        this.balance = initialBalance;
    }

    @Override
    public void deposit(double amount) {
        balance += amount;
        System.out.println("Deposited $" + amount + ", New balance: $" + balance);
    }

    @Override
    public void withdraw(double amount) {
        if (balance >= amount) {
            balance -= amount;
            System.out.println("Withdrew $" + amount + ", New balance: $" + balance);
        } else {
            System.out.println("Insufficient funds");
        }
    }

    @Override
    public double getBalance() {
        return balance;
    }
}

// Protection Proxy
class ProtectedBankAccount implements BankAccount {
    private RealBankAccount realAccount;
    private String userRole; // "owner", "viewer", etc.

    public ProtectedBankAccount(RealBankAccount realAccount, String userRole) {
        this.realAccount = realAccount;
        this.userRole = userRole;
    }

    @Override
    public void deposit(double amount) {
        if (userRole.equals("owner") || userRole.equals("admin")) {
            realAccount.deposit(amount);
        } else {
            System.out.println("Access Denied: Only owner can deposit");
        }
    }

    @Override
    public void withdraw(double amount) {
        if (userRole.equals("owner")) {
            realAccount.withdraw(amount);
        } else {
            System.out.println("Access Denied: Only owner can withdraw");
        }
    }

    @Override
    public double getBalance() {
        if (userRole.equals("owner") || userRole.equals("viewer")) {
            return realAccount.getBalance();
        } else {
            System.out.println("Access Denied: Cannot view balance");
            return 0.0;
        }
    }
}

// Usage
public class BankDemo {
    public static void main(String[] args) {
        RealBankAccount account = new RealBankAccount("12345", 1000.0);

        // Owner has full access
        BankAccount ownerProxy = new ProtectedBankAccount(account, "owner");
        ownerProxy.withdraw(100); // Allowed
        System.out.println("Balance: $" + ownerProxy.getBalance()); // Allowed

        // Viewer has read-only access
        BankAccount viewerProxy = new ProtectedBankAccount(account, "viewer");
        viewerProxy.withdraw(100); // Denied
        System.out.println("Balance: $" + viewerProxy.getBalance()); // Allowed

        // Stranger has no access
        BankAccount strangerProxy = new ProtectedBankAccount(account, "stranger");
        strangerProxy.withdraw(100); // Denied
        System.out.println("Balance: $" + strangerProxy.getBalance()); // Denied
    }
}
```

## Real-World Use Cases

### 1. **JPA/Hibernate Lazy Loading**
```java
@Entity
class User {
    @OneToMany(fetch = FetchType.LAZY) // Proxy pattern
    private List<Order> orders; // Loaded only when accessed
}
```

### 2. **Spring AOP**
```java
@Transactional // Creates proxy with transaction management
public void saveUser(User user) {
    userRepository.save(user);
}
```

### 3. **Java RMI (Remote Method Invocation)**
```java
// Proxy for remote object
RemoteService service = (RemoteService) Naming.lookup("rmi://server/Service");
service.remoteMethod(); // Calls over network
```

### 4. **Image Loading in UI**
```java
// Show placeholder while loading
ImageView imageView = new ImageView(new ImageProxy("large_image.jpg"));
// Shows loading indicator, loads in background
```

### 5. **Database Connection Pooling**
```java
// Proxy manages connection lifecycle
Connection conn = dataSource.getConnection(); // Gets from pool
// Proxy handles return to pool on close
```

### 6. **Security/Authentication**
```java
// Spring Security creates proxies for secured methods
@PreAuthorize("hasRole('ADMIN')")
public void deleteUser(Long id) { }
```

## Comparison with Other Patterns

| Pattern | Purpose | Key Difference |
|---------|---------|----------------|
| **Proxy** | Control access to object | Same interface, adds control |
| **Adapter** | Make incompatible interfaces work | Converts interface |
| **Decorator** | Add responsibilities | Same interface, enhances behavior |
| **Facade** | Simplify complex subsystem | Simpler interface to many classes |

### Proxy vs Decorator

**Proxy:**
```java
// Controls ACCESS to object
class ImageProxy implements Image {
    private RealImage image; // May or may not exist yet

    void display() {
        if (image == null) image = new RealImage(); // Lazy init
        image.display();
    }
}
// Same interface, controls when RealImage is created
```

**Decorator:**
```java
// Adds BEHAVIOR to object
class BorderedImage implements Image {
    private Image image; // Always exists

    void display() {
        drawBorder(); // Add behavior
        image.display();
        drawBorder();
    }
}
// Same interface, adds visual border
```

**Key Difference:**
- **Proxy**: Controls access (lazy init, permissions, etc.)
- **Decorator**: Adds features (borders, scroll bars, etc.)
- Proxy manages object lifecycle, Decorator enhances functionality

### Proxy vs Adapter

**Proxy:**
- Same interface as real subject
- Controls access to existing object
- Example: LazyImage implements Image

**Adapter:**
- Different interfaces
- Makes incompatible interfaces work together
- Example: StripeAdapter implements PaymentProcessor, wraps StripePay

## Common Pitfalls

### 1. **Proxy Not Implementing Same Interface**
```java
// Bad: Different interface
class ImageProxy {
    void show() { } // Different method name!
}

// Good: Same interface
class ImageProxy implements Image {
    void display() { } // Same as RealImage
}
```

### 2. **Memory Leaks in Caching Proxy**
```java
// Bad: Unbounded cache
class CachingProxy {
    private Map<String, Data> cache = new HashMap<>(); // Never cleared!
}

// Good: Bounded cache
class CachingProxy {
    private LRUCache<String, Data> cache = new LRUCache<>(100);
}
```

### 3. **Not Thread-Safe Lazy Initialization**
```java
// Bad: Race condition
class ImageProxy {
    private RealImage image;

    void display() {
        if (image == null) { // Two threads can both see null!
            image = new RealImage(); // Created twice!
        }
    }
}

// Good: Thread-safe
class ImageProxy {
    private volatile RealImage image;

    void display() {
        if (image == null) {
            synchronized (this) {
                if (image == null) { // Double-checked locking
                    image = new RealImage();
                }
            }
        }
        image.display();
    }
}
```

### 4. **Proxy Doing Too Much**
```java
// Bad: Proxy has business logic
class UserProxy implements User {
    void save() {
        validateUser(); // Business logic shouldn't be here!
        calculateDiscount();
        sendNotification();
        realUser.save();
    }
}

// Good: Proxy only controls access
class UserProxy implements User {
    void save() {
        checkPermissions(); // Access control only
        logAccess();
        realUser.save();
    }
}
```

### 5. **Forgetting to Delegate**
```java
// Bad: Doesn't delegate
class ImageProxy implements Image {
    void display() {
        System.out.println("Displaying..."); // Does it itself!
    }
}

// Good: Delegates to real object
class ImageProxy implements Image {
    void display() {
        if (image == null) image = new RealImage();
        image.display(); // Delegates
    }
}
```

## Design Decisions

### When to Create RealSubject?

**Option 1: Lazy (Virtual Proxy)**
```java
// Create on first use
void operation() {
    if (realSubject == null) {
        realSubject = new RealSubject();
    }
    realSubject.operation();
}
```
- ✅ Saves resources if never used
- ❌ First call is slow

**Option 2: Eager**
```java
// Create in constructor
Proxy(RealSubject subject) {
    this.realSubject = subject;
}
```
- ✅ Predictable performance
- ❌ Wastes resources if not used

**Best Practice**: Use lazy for expensive objects, eager for cheap ones.

### Should Proxy Cache Results?

**Depends on use case:**
- ✅ Yes for: Expensive computations, remote calls, database queries
- ❌ No for: Changing data, security-sensitive operations

```java
// With caching
class CachingProxy {
    private Data cachedData;
    private long cacheTime;

    Data getData() {
        if (cachedData == null || isCacheExpired()) {
            cachedData = realSubject.getData();
            cacheTime = System.currentTimeMillis();
        }
        return cachedData;
    }
}
```

## Interview Questions to Expect

### 1. **What is the Proxy pattern?**
**Answer**: A structural pattern that provides a surrogate or placeholder for another object to control access to it. The proxy has the same interface as the real object.

### 2. **What are the different types of proxies?**
**Answer**:
- **Virtual Proxy**: Lazy initialization of expensive objects
- **Protection Proxy**: Access control based on permissions
- **Remote Proxy**: Local representative of remote object
- **Caching Proxy**: Cache results of expensive operations
- **Logging Proxy**: Log method calls for monitoring

### 3. **Proxy vs Decorator?**
**Answer**:
- **Proxy**: Controls access (lazy loading, permissions)
- **Decorator**: Adds behavior (visual effects, features)
- Proxy manages lifecycle, Decorator enhances functionality
- Proxy may not have real object yet, Decorator always wraps existing object

### 4. **When would you use Proxy?**
**Answer**:
- Expensive object creation (lazy loading)
- Access control needed
- Remote object access
- Logging/monitoring
- Caching

### 5. **Real-world examples?**
**Answer**:
- Hibernate lazy loading (virtual proxy)
- Spring AOP transactions (protection/logging proxy)
- Java RMI (remote proxy)
- Image placeholders in web/mobile apps (virtual proxy)

### 6. **What's the main disadvantage?**
**Answer**: Adds an extra layer of indirection which can:
- Complicate code
- Add slight performance overhead
- Make debugging harder
- Require careful thread-safety handling

### 7. **How do you make lazy initialization thread-safe?**
**Answer**: Use double-checked locking with volatile:
```java
private volatile RealSubject subject;

void operation() {
    if (subject == null) {
        synchronized (this) {
            if (subject == null) {
                subject = new RealSubject();
            }
        }
    }
    subject.operation();
}
```

### 8. **Can you combine Proxy with other patterns?**
**Answer**: Yes:
- **Proxy + Factory**: Factory creates proxies
- **Proxy + Decorator**: Chain proxies for multiple concerns
- **Proxy + Singleton**: Proxy to singleton object

## Advantages vs Disadvantages

### Advantages
- ✅ Controls access to expensive resources
- ✅ Lazy initialization
- ✅ Access control/security
- ✅ Logging and monitoring
- ✅ Performance optimization (caching)
- ✅ Open/Closed Principle
- ✅ Single Responsibility (access control separate from business logic)

### Disadvantages
- ❌ Code complexity increases
- ❌ Response time may increase
- ❌ Extra layer of indirection
- ❌ Harder to debug
- ❌ Thread-safety concerns
- ❌ May hide real object's behavior

## Key Takeaways

1. **Purpose**: Control access to an object
2. **When**: Expensive creation, access control, remote access, caching
3. **How**: Proxy implements same interface, delegates to real object
4. **Remember**: Same interface, controls access
5. **Trade-off**: Control and flexibility vs complexity

## Summary

The Proxy pattern is ideal when:
- ✅ Need lazy initialization of expensive objects
- ✅ Need access control
- ✅ Working with remote objects
- ✅ Need logging/monitoring
- ✅ Want to cache results

Remember: Proxy **controls access** to an object with the **same interface**. It's different from Decorator (adds behavior) and Adapter (converts interface). Common types include Virtual (lazy loading), Protection (access control), Remote (network), and Caching proxies.

## Pattern Checklist

When implementing Proxy:
- [ ] Define Subject interface
- [ ] Implement RealSubject
- [ ] Implement Proxy with same interface
- [ ] Proxy holds reference to RealSubject
- [ ] Decide when to create RealSubject (lazy vs eager)
- [ ] Proxy delegates to RealSubject
- [ ] Add control logic (permissions, logging, caching)
- [ ] Handle thread-safety if needed
- [ ] Don't add business logic to proxy
- [ ] Ensure proxy is transparent to client
- [ ] Consider caching strategy if applicable
- [ ] Document proxy's purpose and behavior
