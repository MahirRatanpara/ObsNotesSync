I'll walk you through the SOLID principles using a **coffee shop ordering system** - something we can all relate to. We'll start with terrible code that violates every principle, then fix it step by step.

## The Disaster: Our Initial Coffee Shop Code

Imagine you're building software for a coffee shop. Here's the nightmare version that violates all SOLID principles:

```java
public class CoffeeShop {
    private List<String> orders = new ArrayList<>();
    private double totalRevenue = 0;
    
    // This monster class does EVERYTHING
    public void processOrder(String customerName, String drinkType, String size, boolean withMilk, boolean withSugar) {
        // Calculate price (pricing logic)
        double price = 0;
        if (drinkType.equals("coffee")) {
            if (size.equals("small")) price = 2.50;
            else if (size.equals("medium")) price = 3.00;
            else if (size.equals("large")) price = 3.50;
        } else if (drinkType.equals("latte")) {
            if (size.equals("small")) price = 4.00;
            else if (size.equals("medium")) price = 4.50;
            else if (size.equals("large")) price = 5.00;
        } else if (drinkType.equals("tea")) {
            price = 2.00; // tea only comes in one size apparently
        }
        
        // Add extras
        if (withMilk) price += 0.50;
        if (withSugar) price += 0.25;
        
        // Make the drink (preparation logic)
        System.out.println("Brewing " + drinkType + "...");
        if (withMilk) {
            System.out.println("Adding milk...");
        }
        if (withSugar) {
            System.out.println("Adding sugar...");
        }
        
        // Save to database (persistence logic)
        String order = customerName + " ordered " + drinkType + " for $" + price;
        orders.add(order);
        
        // Update accounting (financial logic)
        totalRevenue += price;
        
        // Send email receipt (notification logic)
        System.out.println("Sending email to " + customerName + "@email.com");
        System.out.println("Receipt: " + order);
        
        // Print receipt (printing logic)
        System.out.println("Printing physical receipt...");
        System.out.println("====RECEIPT====");
        System.out.println(order);
        System.out.println("===============");
    }
    
    public void generateDailyReport() {
        System.out.println("Daily revenue: $" + totalRevenue);
        for (String order : orders) {
            System.out.println(order);
        }
    }
}
```

**Why this is a disaster:**

- One class is doing 7+ different jobs (pricing, brewing, database, accounting, emails, printing, reporting)
- Adding a new drink type? Modify the giant if-else chain
- Want SMS receipts instead of email? Dig through the method and change it
- Different tea sizes? Good luck - the code assumes tea has no sizes
- Want to test just the pricing logic? You can't without triggering emails and prints

Let's fix this mess, one SOLID principle at a time.

---

## Step 1: Single Responsibility Principle (SRP)

_"A class should have only one reason to change"_

Our CoffeeShop class has like 7 reasons to change! Let's break it apart:

```java
// BEFORE: Everything jumbled in one class
// AFTER: Separate classes with single responsibilities

// Handles ONLY drink preparation
class Barista {
    public void prepareDrink(Drink drink) {
        System.out.println("Brewing " + drink.getType() + "...");
        for (String extra : drink.getExtras()) {
            System.out.println("Adding " + extra + "...");
        }
    }
}

// Handles ONLY pricing calculations
class PriceCalculator {
    private Map<String, Map<String, Double>> priceChart = new HashMap<>();
    
    public PriceCalculator() {
        // Coffee prices
        Map<String, Double> coffeePrices = new HashMap<>();
        coffeePrices.put("small", 2.50);
        coffeePrices.put("medium", 3.00);
        coffeePrices.put("large", 3.50);
        priceChart.put("coffee", coffeePrices);
        
        // Latte prices
        Map<String, Double> lattePrices = new HashMap<>();
        lattePrices.put("small", 4.00);
        lattePrices.put("medium", 4.50);
        lattePrices.put("large", 5.00);
        priceChart.put("latte", lattePrices);
    }
    
    public double calculatePrice(Drink drink) {
        double basePrice = priceChart.get(drink.getType()).get(drink.getSize());
        double extrasPrice = drink.getExtras().size() * 0.50; // simplified
        return basePrice + extrasPrice;
    }
}

// Handles ONLY order storage
class OrderRepository {
    private List<Order> orders = new ArrayList<>();
    
    public void save(Order order) {
        orders.add(order);
    }
    
    public List<Order> getAllOrders() {
        return orders;
    }
}

// Handles ONLY receipt sending
class ReceiptService {
    public void sendReceipt(Order order) {
        System.out.println("Sending receipt to " + order.getCustomerEmail());
        System.out.println("Order: " + order.getDescription());
    }
}

// Simple data classes
class Drink {
    private String type;
    private String size;
    private List<String> extras;
    // constructor, getters...
}

class Order {
    private String customerName;
    private String customerEmail;
    private Drink drink;
    private double price;
    private LocalDateTime timestamp;
    // constructor, getters...
}
```

Now each class has ONE job. Change email logic? Only touch ReceiptService. New pricing model? Only modify PriceCalculator.

---

## Step 2: Open-Closed Principle (OCP)

_"Classes should be open for extension but closed for modification"_

Our pricing calculator still needs modification for every new drink. Let's fix that:

```java
// BEFORE: Have to modify PriceCalculator for each new drink type
// AFTER: Use abstraction so we can add new drinks without changing existing code

interface DrinkPricing {
    double getPrice(String size);
}

class CoffeePricing implements DrinkPricing {
    public double getPrice(String size) {
        switch(size) {
            case "small": return 2.50;
            case "medium": return 3.00;
            case "large": return 3.50;
            default: throw new IllegalArgumentException("Unknown size: " + size);
        }
    }
}

class LattePricing implements DrinkPricing {
    public double getPrice(String size) {
        switch(size) {
            case "small": return 4.00;
            case "medium": return 4.50;
            case "large": return 5.00;
            default: throw new IllegalArgumentException("Unknown size: " + size);
        }
    }
}

// New drink? Just add a new class - don't touch existing code!
class MatchaLattePricing implements DrinkPricing {
    public double getPrice(String size) {
        switch(size) {
            case "small": return 5.00;
            case "medium": return 5.50;
            case "large": return 6.00;
            default: throw new IllegalArgumentException("Unknown size: " + size);
        }
    }
}

class PriceCalculator {
    private Map<String, DrinkPricing> pricingStrategies = new HashMap<>();
    
    public PriceCalculator() {
        pricingStrategies.put("coffee", new CoffeePricing());
        pricingStrategies.put("latte", new LattePricing());
        pricingStrategies.put("matcha_latte", new MatchaLattePricing());
    }
    
    public double calculatePrice(Drink drink) {
        DrinkPricing pricing = pricingStrategies.get(drink.getType());
        double basePrice = pricing.getPrice(drink.getSize());
        double extrasPrice = drink.getExtras().size() * 0.50;
        return basePrice + extrasPrice;
    }
}
```

Now adding a new drink is just creating a new class - we never modify the existing ones!

---

## Step 3: Liskov Substitution Principle (LSP)

_"Subtypes must be substitutable for their base types without altering program correctness"_

Let's say we add a "Free Sample" drink that violates this:

```java
// BEFORE: Subclass that breaks expectations

class Drink {
    protected String type;
    protected String size;
    protected List<String> extras;
    
    public double getPrice() {
        // normal pricing logic
        return 3.00;
    }
    
    public void prepare() {
        System.out.println("Preparing " + type);
    }
}

class FreeSampleDrink extends Drink {
    @Override
    public double getPrice() {
        throw new UnsupportedOperationException("Free samples don't have prices!");
    }
    
    @Override
    public void prepare() {
        throw new UnsupportedOperationException("Free samples are pre-made!");
    }
}

// This breaks! FreeSampleDrink can't be used where Drink is expected
public void processAnyDrink(Drink drink) {
    double price = drink.getPrice(); // BOOM! Exception for free samples
    drink.prepare(); // BOOM! Another exception
}
```

```java
// AFTER: Proper abstraction that respects LSP

interface Beverage {
    String getDescription();
}

interface PricedBeverage extends Beverage {
    double getPrice();
}

interface PreparableBeverage extends Beverage {
    void prepare();
}

class RegularDrink implements PricedBeverage, PreparableBeverage {
    private String type;
    private String size;
    private double price;
    
    @Override
    public String getDescription() {
        return type + " (" + size + ")";
    }
    
    @Override
    public double getPrice() {
        return price;
    }
    
    @Override
    public void prepare() {
        System.out.println("Preparing " + type);
    }
}

class FreeSample implements Beverage {
    private String type;
    
    @Override
    public String getDescription() {
        return "Free sample of " + type;
    }
    // No price() or prepare() methods - it doesn't claim to have them!
}

// Now our code is honest about what it needs
public void processPaidOrder(PricedBeverage beverage) {
    double price = beverage.getPrice(); // Only accepts drinks that have prices
}

public void prepareCustomDrink(PreparableBeverage beverage) {
    beverage.prepare(); // Only accepts drinks that can be prepared
}
```

Now FreeSample doesn't pretend to be something it's not. Each type only promises what it can actually deliver.

---

## Step 4: Interface Segregation Principle (ISP)

_"Clients shouldn't be forced to depend on interfaces they don't use"_

Let's fix our receipt system that forces everyone to implement methods they don't need:

```java
// BEFORE: Fat interface that does too much

interface ReceiptSender {
    void sendEmail(Order order);
    void sendSMS(Order order);
    void printPhysicalReceipt(Order order);
    void saveToCloud(Order order);
}

// Every implementation is forced to implement ALL methods
class EmailOnlyReceiptSender implements ReceiptSender {
    public void sendEmail(Order order) {
        System.out.println("Emailing receipt...");
    }
    
    public void sendSMS(Order order) {
        throw new UnsupportedOperationException("We don't do SMS!");
    }
    
    public void printPhysicalReceipt(Order order) {
        throw new UnsupportedOperationException("We don't print!");
    }
    
    public void saveToCloud(Order order) {
        throw new UnsupportedOperationException("We don't use cloud!");
    }
}
```

```java
// AFTER: Segregated interfaces - pick what you need

interface EmailSender {
    void sendEmail(Order order);
}

interface SmsSender {
    void sendSMS(Order order);
}

interface PhysicalPrinter {
    void print(Order order);
}

interface CloudStorage {
    void save(Order order);
}

// Now classes only implement what they actually do
class EmailReceiptService implements EmailSender {
    @Override
    public void sendEmail(Order order) {
        System.out.println("Emailing receipt to " + order.getCustomerEmail());
    }
}

class SmsReceiptService implements SmsSender {
    @Override
    public void sendSMS(Order order) {
        System.out.println("Texting receipt to " + order.getCustomerPhone());
    }
}

// Can combine multiple interfaces if needed
class MultiChannelReceiptService implements EmailSender, SmsSender, PhysicalPrinter {
    @Override
    public void sendEmail(Order order) {
        System.out.println("Emailing receipt...");
    }
    
    @Override
    public void sendSMS(Order order) {
        System.out.println("Sending SMS...");
    }
    
    @Override
    public void print(Order order) {
        System.out.println("Printing receipt...");
    }
}
```

Now each service only implements what it actually supports. No more dummy methods throwing exceptions!

---

## Step 5: Dependency Inversion Principle (DIP)

_"Depend on abstractions, not concretions"_

Our coffee shop still directly creates and depends on specific implementations:

```java
// BEFORE: High-level class depends on low-level concrete classes

class CoffeeShopService {
    private EmailReceiptService emailService = new EmailReceiptService(); // Concrete!
    private MySQLOrderRepository orderRepo = new MySQLOrderRepository(); // Concrete!
    private StandardBarista barista = new StandardBarista(); // Concrete!
    
    public void processOrder(Order order) {
        barista.prepare(order.getDrink());
        orderRepo.save(order);
        emailService.sendEmail(order); // What if customer wants SMS?
    }
}
```

```java
// AFTER: Depend on abstractions, inject dependencies

interface NotificationService {
    void notify(Order order);
}

interface OrderRepository {
    void save(Order order);
    List<Order> findAll();
}

interface DrinkMaker {
    void prepare(Beverage beverage);
}

class CoffeeShopService {
    private final NotificationService notificationService;
    private final OrderRepository orderRepository;
    private final DrinkMaker drinkMaker;
    private final PriceCalculator priceCalculator;
    
    // Dependencies are injected, not created internally
    public CoffeeShopService(
            NotificationService notificationService,
            OrderRepository orderRepository,
            DrinkMaker drinkMaker,
            PriceCalculator priceCalculator) {
        this.notificationService = notificationService;
        this.orderRepository = orderRepository;
        this.drinkMaker = drinkMaker;
        this.priceCalculator = priceCalculator;
    }
    
    public void processOrder(String customerName, String customerContact, Beverage beverage) {
        // Create order
        double price = priceCalculator.calculate(beverage);
        Order order = new Order(customerName, customerContact, beverage, price);
        
        // Process it using injected dependencies
        drinkMaker.prepare(beverage);
        orderRepository.save(order);
        notificationService.notify(order);
    }
}

// Now we can easily swap implementations
public class CoffeeShopApplication {
    public static void main(String[] args) {
        // For a tech-savvy customer who wants email
        CoffeeShopService emailShop = new CoffeeShopService(
            new EmailNotificationService(),
            new InMemoryOrderRepository(),
            new ExperiencedBarista(),
            new StandardPriceCalculator()
        );
        
        // For a customer who prefers SMS
        CoffeeShopService smsShop = new CoffeeShopService(
            new SmsNotificationService(),
            new InMemoryOrderRepository(),
            new ExperiencedBarista(),
            new StandardPriceCalculator()
        );
        
        // For testing - use test doubles
        CoffeeShopService testShop = new CoffeeShopService(
            new MockNotificationService(),
            new InMemoryOrderRepository(),
            new MockDrinkMaker(),
            new FixedPriceCalculator(5.00)
        );
    }
}
```

---

## The Final Polished Version

Here's our complete coffee shop system with all SOLID principles applied:

```java
// ========== Core Domain Models ==========

class Beverage {
    private final String type;
    private final String size;
    private final List<String> extras;
    
    public Beverage(String type, String size, List<String> extras) {
        this.type = type;
        this.size = size;
        this.extras = new ArrayList<>(extras);
    }
    
    // Getters...
    public String getType() { return type; }
    public String getSize() { return size; }
    public List<String> getExtras() { return new ArrayList<>(extras); }
}

class Order {
    private final String orderId;
    private final String customerName;
    private final String customerContact;
    private final Beverage beverage;
    private final double price;
    private final LocalDateTime timestamp;
    
    public Order(String customerName, String customerContact, Beverage beverage, double price) {
        this.orderId = UUID.randomUUID().toString();
        this.customerName = customerName;
        this.customerContact = customerContact;
        this.beverage = beverage;
        this.price = price;
        this.timestamp = LocalDateTime.now();
    }
    
    // Getters...
    public String getOrderId() { return orderId; }
    public String getCustomerName() { return customerName; }
    public String getCustomerContact() { return customerContact; }
    public Beverage getBeverage() { return beverage; }
    public double getPrice() { return price; }
    public LocalDateTime getTimestamp() { return timestamp; }
}

// ========== Abstractions (Interfaces) ==========

interface DrinkMaker {
    void prepare(Beverage beverage);
}

interface PriceCalculator {
    double calculate(Beverage beverage);
}

interface OrderRepository {
    void save(Order order);
    List<Order> findAll();
    Optional<Order> findById(String orderId);
}

interface NotificationService {
    void notify(Order order);
}

interface PricingStrategy {
    double getBasePrice(String size);
}

// ========== Implementations ==========

class Barista implements DrinkMaker {
    @Override
    public void prepare(Beverage beverage) {
        System.out.println("🔨 Preparing " + beverage.getSize() + " " + beverage.getType());
        
        // Simulate preparation time
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        for (String extra : beverage.getExtras()) {
            System.out.println("  ➕ Adding " + extra);
        }
        
        System.out.println("✅ " + beverage.getType() + " is ready!");
    }
}

class FlexiblePriceCalculator implements PriceCalculator {
    private final Map<String, PricingStrategy> strategies;
    private final double extraPrice;
    
    public FlexiblePriceCalculator(Map<String, PricingStrategy> strategies, double extraPrice) {
        this.strategies = new HashMap<>(strategies);
        this.extraPrice = extraPrice;
    }
    
    @Override
    public double calculate(Beverage beverage) {
        PricingStrategy strategy = strategies.get(beverage.getType());
        if (strategy == null) {
            throw new IllegalArgumentException("Unknown beverage type: " + beverage.getType());
        }
        
        double basePrice = strategy.getBasePrice(beverage.getSize());
        double extrasTotal = beverage.getExtras().size() * extraPrice;
        return basePrice + extrasTotal;
    }
}

class CoffeePricingStrategy implements PricingStrategy {
    @Override
    public double getBasePrice(String size) {
        switch(size.toLowerCase()) {
            case "small": return 2.50;
            case "medium": return 3.00;
            case "large": return 3.50;
            default: throw new IllegalArgumentException("Invalid size: " + size);
        }
    }
}

class LattePricingStrategy implements PricingStrategy {
    @Override
    public double getBasePrice(String size) {
        switch(size.toLowerCase()) {
            case "small": return 4.00;
            case "medium": return 4.50;
            case "large": return 5.00;
            default: throw new IllegalArgumentException("Invalid size: " + size);
        }
    }
}

class InMemoryOrderRepository implements OrderRepository {
    private final Map<String, Order> orders = new ConcurrentHashMap<>();
    
    @Override
    public void save(Order order) {
        orders.put(order.getOrderId(), order);
    }
    
    @Override
    public List<Order> findAll() {
        return new ArrayList<>(orders.values());
    }
    
    @Override
    public Optional<Order> findById(String orderId) {
        return Optional.ofNullable(orders.get(orderId));
    }
}

class EmailNotificationService implements NotificationService {
    @Override
    public void notify(Order order) {
        System.out.println("📧 Sending email receipt to: " + order.getCustomerContact());
        System.out.println("   Order: " + order.getBeverage().getType() + 
                          " - $" + String.format("%.2f", order.getPrice()));
    }
}

class SmsNotificationService implements NotificationService {
    @Override
    public void notify(Order order) {
        System.out.println("📱 Sending SMS receipt to: " + order.getCustomerContact());
        System.out.println("   Your " + order.getBeverage().getType() + 
                          " order ($" + String.format("%.2f", order.getPrice()) + ") is ready!");
    }
}

class CompositeNotificationService implements NotificationService {
    private final List<NotificationService> services;
    
    public CompositeNotificationService(NotificationService... services) {
        this.services = Arrays.asList(services);
    }
    
    @Override
    public void notify(Order order) {
        services.forEach(service -> service.notify(order));
    }
}

// ========== Main Service (Orchestrator) ==========

class CoffeeShopService {
    private final DrinkMaker drinkMaker;
    private final PriceCalculator priceCalculator;
    private final OrderRepository orderRepository;
    private final NotificationService notificationService;
    
    public CoffeeShopService(
            DrinkMaker drinkMaker,
            PriceCalculator priceCalculator,
            OrderRepository orderRepository,
            NotificationService notificationService) {
        this.drinkMaker = drinkMaker;
        this.priceCalculator = priceCalculator;
        this.orderRepository = orderRepository;
        this.notificationService = notificationService;
    }
    
    public Order processOrder(String customerName, String contact, Beverage beverage) {
        // Calculate price
        double price = priceCalculator.calculate(beverage);
        
        // Create order
        Order order = new Order(customerName, contact, beverage, price);
        
        // Process the order
        System.out.println("\n🛍️ New order from " + customerName);
        drinkMaker.prepare(beverage);
        orderRepository.save(order);
        notificationService.notify(order);
        
        System.out.println("✨ Order complete!\n");
        return order;
    }
    
    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }
}

// ========== Application Bootstrap ==========

public class CoffeeShopApplication {
    public static void main(String[] args) {
        // Configure pricing strategies
        Map<String, PricingStrategy> pricingStrategies = new HashMap<>();
        pricingStrategies.put("coffee", new CoffeePricingStrategy());
        pricingStrategies.put("latte", new LattePricingStrategy());
        
        // Build the service with dependencies
        CoffeeShopService coffeeShop = new CoffeeShopService(
            new Barista(),
            new FlexiblePriceCalculator(pricingStrategies, 0.50),
            new InMemoryOrderRepository(),
            new CompositeNotificationService(
                new EmailNotificationService(),
                new SmsNotificationService()
            )
        );
        
        // Process some orders
        coffeeShop.processOrder(
            "Alice", 
            "alice@email.com", 
            new Beverage("latte", "medium", Arrays.asList("vanilla", "whipped cream"))
        );
        
        coffeeShop.processOrder(
            "Bob", 
            "555-1234", 
            new Beverage("coffee", "large", Arrays.asList("milk"))
        );
    }
}
```

---

## Why You'll Remember This

Think of SOLID like running a real coffee shop:

1. **Single Responsibility**: Your barista makes drinks, your cashier handles money, your accountant does the books. Nobody does multiple jobs.
    
2. **Open-Closed**: You can add new drink recipes (matcha latte, flat white) without retraining your existing baristas on how to make coffee.
    
3. **Liskov Substitution**: If you promise "hot beverages", everything you serve better be hot and drinkable. Don't serve ice cream and claim it's a beverage.
    
4. **Interface Segregation**: Your SMS-only customers shouldn't be forced to give you their email. Your email-only customers shouldn't need to provide phone numbers.
    
5. **Dependency Inversion**: The coffee shop manager shouldn't care whether receipts go by email, SMS, or carrier pigeon - they just say "send the receipt" and the right thing happens.
    

The beauty is that our final code is actually **easier** to understand, test, and modify than the original mess. Each piece does one thing well, and you can swap parts in and out like LEGO blocks. Want to add a loyalty program? Create a new service and inject it. Want database storage instead of memory? Swap the repository implementation. The system just works.