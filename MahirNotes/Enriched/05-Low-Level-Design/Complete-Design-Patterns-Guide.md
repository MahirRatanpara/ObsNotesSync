# 🎯 Complete Design Patterns Guide

#must-do #faang #design-patterns #lld

## 📚 Table of Contents

### **Creational Patterns**
- [Singleton Pattern](#-singleton-pattern) - Single instance control
- [Factory Method](#-factory-method-pattern) - Object creation delegation  
- [Abstract Factory](#-abstract-factory-pattern) - Family of related objects
- [Builder Pattern](#-builder-pattern) - Complex object construction
- [Prototype Pattern](#-prototype-pattern) - Object cloning

### **Structural Patterns**
- [Adapter Pattern](#-adapter-pattern) - Interface compatibility
- [Decorator Pattern](#-decorator-pattern) - Dynamic behavior extension
- [Facade Pattern](#-facade-pattern) - Simplified interface
- [Flyweight Pattern](#-flyweight-pattern) - Memory optimization

### **Behavioral Patterns**
- [Strategy Pattern](#-strategy-pattern) - Algorithm selection
- [Observer Pattern](#-observer-pattern) - Event notification
- [Command Pattern](#-command-pattern) - Request encapsulation
- [Chain of Responsibility](#-chain-of-responsibility-pattern) - Request handling chain
- [Template Method](#-template-method-pattern) - Algorithm skeleton
- [State Pattern](#-state-pattern) - State-dependent behavior
- [Mediator Pattern](#-mediator-pattern) - Object interaction management

---

## 🔒 Singleton Pattern

### 📖 Concept
Ensures only one instance of a class exists globally and provides controlled access to it.

### ⚠️ Common Mistakes
- **Not thread-safe** - Multiple threads can create multiple instances
- **Reflection attacks** - Can break singleton property
- **Serialization issues** - Deserialization creates new instances
- **Memory leaks** - Static references prevent garbage collection

### 💡 Thread-Safe Implementations

#### 1. Double-Checked Locking
```java
public class Logger {
    private static volatile Logger instance;
    private final LinkedBlockingQueue<String> logQueue;
    private final ExecutorService executor;
    
    private Logger() {
        logQueue = new LinkedBlockingQueue<>();
        executor = Executors.newSingleThreadExecutor();
        executor.submit(this::processLogs);
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
    
    public void log(LogLevel level, String message) {
        String timestamp = LocalDateTime.now().toString();
        String threadName = Thread.currentThread().getName();
        logQueue.offer(String.format("[%s] [%s] [%s] %s", 
            level, timestamp, threadName, message));
    }
    
    private void processLogs() {
        while (true) {
            try {
                String log = logQueue.take();
                if ("__SHUTDOWN__".equals(log)) break;
                System.out.println(log);
                // Forward to external logging system
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }
    
    // Prevent reflection attacks
    private Object readResolve() {
        return getInstance();
    }
}
```

#### 2. Bill Pugh's Holder Pattern (Preferred)
```java
public class DatabaseConnection {
    private final Connection connection;
    
    private DatabaseConnection() {
        this.connection = createConnection();
    }
    
    private static class ConnectionHolder {
        private static final DatabaseConnection INSTANCE = new DatabaseConnection();
    }
    
    public static DatabaseConnection getInstance() {
        return ConnectionHolder.INSTANCE;
    }
    
    public ResultSet executeQuery(String sql) {
        // Thread-safe database operations
        synchronized(connection) {
            try {
                return connection.createStatement().executeQuery(sql);
            } catch (SQLException e) {
                throw new RuntimeException("Query failed", e);
            }
        }
    }
}
```

#### 3. Enum Singleton (Most Robust)
```java
public enum ConfigurationManager {
    INSTANCE;
    
    private final Properties properties;
    
    ConfigurationManager() {
        properties = new Properties();
        loadConfiguration();
    }
    
    public String getProperty(String key) {
        return properties.getProperty(key);
    }
    
    public void setProperty(String key, String value) {
        synchronized(properties) {
            properties.setProperty(key, value);
            persistConfiguration();
        }
    }
    
    private void loadConfiguration() {
        // Load from file/database
    }
    
    private void persistConfiguration() {
        // Save to file/database
    }
}
```

### 🎯 Interview Questions
1. **Q**: How do you make Singleton thread-safe?
   **A**: Use double-checked locking with volatile, Bill Pugh's holder pattern, or enum singleton.

2. **Q**: How to prevent reflection attacks on Singleton?
   **A**: Check if instance already exists in constructor and throw exception, or use enum singleton.

3. **Q**: What are the drawbacks of Singleton?
   **A**: Violates Single Responsibility Principle, difficult to test, creates global state, can cause memory leaks.

---

## 🏭 Factory Method Pattern

### 📖 Concept
Provides an interface for creating objects without specifying their exact class, delegating instantiation to subclasses.

### 💡 Implementation: Notification System

```java
// Product interface
interface Notification {
    void send(String recipient, String message);
    NotificationType getType();
}

// Concrete products
class EmailNotification implements Notification {
    @Override
    public void send(String recipient, String message) {
        System.out.printf("EMAIL to %s: %s%n", recipient, message);
        // SMTP logic here
    }
    
    @Override
    public NotificationType getType() {
        return NotificationType.EMAIL;
    }
}

class SMSNotification implements Notification {
    @Override
    public void send(String recipient, String message) {
        System.out.printf("SMS to %s: %s%n", recipient, message);
        // SMS gateway logic here
    }
    
    @Override
    public NotificationType getType() {
        return NotificationType.SMS;
    }
}

class PushNotification implements Notification {
    @Override
    public void send(String recipient, String message) {
        System.out.printf("PUSH to %s: %s%n", recipient, message);
        // Push notification service logic here
    }
    
    @Override
    public NotificationType getType() {
        return NotificationType.PUSH;
    }
}

// Creator abstract class
abstract class NotificationCreator {
    // Factory method
    public abstract Notification createNotification();
    
    // Business logic that uses the factory method
    public void processNotification(String recipient, String message) {
        Notification notification = createNotification();
        notification.send(recipient, message);
        logNotification(notification.getType(), recipient);
    }
    
    private void logNotification(NotificationType type, String recipient) {
        System.out.printf("Logged %s notification to %s%n", type, recipient);
    }
}

// Concrete creators
class EmailNotificationCreator extends NotificationCreator {
    @Override
    public Notification createNotification() {
        return new EmailNotification();
    }
}

class SMSNotificationCreator extends NotificationCreator {
    @Override
    public Notification createNotification() {
        return new SMSNotification();
    }
}

class PushNotificationCreator extends NotificationCreator {
    @Override
    public Notification createNotification() {
        return new PushNotification();
    }
}

// Factory registry for extensibility
class NotificationFactory {
    private static final Map<NotificationType, Supplier<NotificationCreator>> creators = new HashMap<>();
    
    static {
        creators.put(NotificationType.EMAIL, EmailNotificationCreator::new);
        creators.put(NotificationType.SMS, SMSNotificationCreator::new);
        creators.put(NotificationType.PUSH, PushNotificationCreator::new);
    }
    
    public static NotificationCreator getCreator(NotificationType type) {
        Supplier<NotificationCreator> creatorSupplier = creators.get(type);
        if (creatorSupplier == null) {
            throw new IllegalArgumentException("Unsupported notification type: " + type);
        }
        return creatorSupplier.get();
    }
    
    // Runtime registration for plugins
    public static void registerCreator(NotificationType type, Supplier<NotificationCreator> creatorSupplier) {
        creators.put(type, creatorSupplier);
    }
}

enum NotificationType {
    EMAIL, SMS, PUSH, SLACK, WEBHOOK
}
```

### 🎯 Interview Questions
1. **Q**: Difference between Factory Method and Simple Factory?
   **A**: Factory Method uses inheritance and virtual dispatch, Simple Factory uses conditionals.

2. **Q**: How to add new notification types without modifying existing code?
   **A**: Create new concrete creator classes and register them with factory registry.

---

## 🏭🏭 Abstract Factory Pattern

### 📖 Concept
Provides interface for creating families of related objects without specifying their concrete classes.

### 💡 Implementation: Cross-Platform UI Components

```java
// Abstract products
interface Button {
    void render();
    void onClick(Runnable action);
}

interface Menu {
    void show();
    void addMenuItem(String item, Runnable action);
}

interface Dialog {
    void display();
    void setTitle(String title);
}

// Windows family
class WindowsButton implements Button {
    private Runnable clickAction;
    
    @Override
    public void render() {
        System.out.println("Rendering Windows-style button");
    }
    
    @Override
    public void onClick(Runnable action) {
        this.clickAction = action;
        // Windows-specific click handling
        System.out.println("Windows button clicked");
        if (clickAction != null) clickAction.run();
    }
}

class WindowsMenu implements Menu {
    private final List<MenuItem> items = new ArrayList<>();
    
    @Override
    public void show() {
        System.out.println("Showing Windows-style menu");
        items.forEach(item -> System.out.println("  " + item.name));
    }
    
    @Override
    public void addMenuItem(String item, Runnable action) {
        items.add(new MenuItem(item, action));
    }
    
    private static class MenuItem {
        final String name;
        final Runnable action;
        
        MenuItem(String name, Runnable action) {
            this.name = name;
            this.action = action;
        }
    }
}

class WindowsDialog implements Dialog {
    private String title = "Windows Dialog";
    
    @Override
    public void display() {
        System.out.printf("Displaying Windows dialog: %s%n", title);
    }
    
    @Override
    public void setTitle(String title) {
        this.title = title;
    }
}

// MacOS family
class MacOSButton implements Button {
    private Runnable clickAction;
    
    @Override
    public void render() {
        System.out.println("Rendering MacOS-style button");
    }
    
    @Override
    public void onClick(Runnable action) {
        this.clickAction = action;
        System.out.println("MacOS button clicked");
        if (clickAction != null) clickAction.run();
    }
}

class MacOSMenu implements Menu {
    private final List<String> items = new ArrayList<>();
    
    @Override
    public void show() {
        System.out.println("Showing MacOS-style menu");
        items.forEach(item -> System.out.println("• " + item));
    }
    
    @Override
    public void addMenuItem(String item, Runnable action) {
        items.add(item);
        // Store action in separate map if needed
    }
}

class MacOSDialog implements Dialog {
    private String title = "MacOS Dialog";
    
    @Override
    public void display() {
        System.out.printf("Displaying MacOS dialog: %s%n", title);
    }
    
    @Override
    public void setTitle(String title) {
        this.title = title;
    }
}

// Abstract factory
interface UIFactory {
    Button createButton();
    Menu createMenu();
    Dialog createDialog();
}

// Concrete factories
class WindowsUIFactory implements UIFactory {
    @Override
    public Button createButton() {
        return new WindowsButton();
    }
    
    @Override
    public Menu createMenu() {
        return new WindowsMenu();
    }
    
    @Override
    public Dialog createDialog() {
        return new WindowsDialog();
    }
}

class MacOSUIFactory implements UIFactory {
    @Override
    public Button createButton() {
        return new MacOSButton();
    }
    
    @Override
    public Menu createMenu() {
        return new MacOSMenu();
    }
    
    @Override
    public Dialog createDialog() {
        return new MacOSDialog();
    }
}

// Factory provider
class UIFactoryProvider {
    public static UIFactory getFactory(String osType) {
        switch (osType.toLowerCase()) {
            case "windows":
                return new WindowsUIFactory();
            case "macos":
                return new MacOSUIFactory();
            default:
                throw new IllegalArgumentException("Unsupported OS: " + osType);
        }
    }
    
    public static UIFactory getFactory() {
        String os = System.getProperty("os.name").toLowerCase();
        if (os.contains("win")) {
            return new WindowsUIFactory();
        } else if (os.contains("mac")) {
            return new MacOSUIFactory();
        }
        throw new UnsupportedOperationException("OS not supported: " + os);
    }
}

// Client code
class Application {
    private final UIFactory factory;
    private Button button;
    private Menu menu;
    private Dialog dialog;
    
    public Application(UIFactory factory) {
        this.factory = factory;
    }
    
    public void createUI() {
        button = factory.createButton();
        menu = factory.createMenu();
        dialog = factory.createDialog();
        
        button.render();
        menu.addMenuItem("File", () -> System.out.println("File clicked"));
        menu.addMenuItem("Edit", () -> System.out.println("Edit clicked"));
        menu.show();
        
        dialog.setTitle("Application Dialog");
        dialog.display();
    }
}
```

### 🎯 Interview Questions
1. **Q**: When to use Abstract Factory vs Factory Method?
   **A**: Abstract Factory when you need families of related objects; Factory Method for single object creation with inheritance.

---

## 🧱 Builder Pattern

### 📖 Concept
Constructs complex objects step by step, allowing different representations of the same construction process.

### 💡 Implementation: Database Query Builder

```java
// Product class - Complex SQL Query
class SQLQuery {
    private final String select;
    private final String from;
    private final List<String> joins;
    private final List<String> where;
    private final List<String> groupBy;
    private final List<String> having;
    private final List<String> orderBy;
    private final Integer limit;
    private final Integer offset;
    
    private SQLQuery(Builder builder) {
        this.select = builder.select;
        this.from = builder.from;
        this.joins = Collections.unmodifiableList(builder.joins);
        this.where = Collections.unmodifiableList(builder.where);
        this.groupBy = Collections.unmodifiableList(builder.groupBy);
        this.having = Collections.unmodifiableList(builder.having);
        this.orderBy = Collections.unmodifiableList(builder.orderBy);
        this.limit = builder.limit;
        this.offset = builder.offset;
    }
    
    public String toSQL() {
        StringBuilder sql = new StringBuilder();
        
        // SELECT clause
        sql.append("SELECT ").append(select != null ? select : "*");
        
        // FROM clause
        if (from != null) {
            sql.append(" FROM ").append(from);
        }
        
        // JOIN clauses
        joins.forEach(join -> sql.append(" ").append(join));
        
        // WHERE clause
        if (!where.isEmpty()) {
            sql.append(" WHERE ").append(String.join(" AND ", where));
        }
        
        // GROUP BY clause
        if (!groupBy.isEmpty()) {
            sql.append(" GROUP BY ").append(String.join(", ", groupBy));
        }
        
        // HAVING clause
        if (!having.isEmpty()) {
            sql.append(" HAVING ").append(String.join(" AND ", having));
        }
        
        // ORDER BY clause
        if (!orderBy.isEmpty()) {
            sql.append(" ORDER BY ").append(String.join(", ", orderBy));
        }
        
        // LIMIT clause
        if (limit != null) {
            sql.append(" LIMIT ").append(limit);
        }
        
        // OFFSET clause
        if (offset != null) {
            sql.append(" OFFSET ").append(offset);
        }
        
        return sql.toString();
    }
    
    // Builder class
    public static class Builder {
        private String select;
        private String from;
        private final List<String> joins = new ArrayList<>();
        private final List<String> where = new ArrayList<>();
        private final List<String> groupBy = new ArrayList<>();
        private final List<String> having = new ArrayList<>();
        private final List<String> orderBy = new ArrayList<>();
        private Integer limit;
        private Integer offset;
        
        public Builder select(String columns) {
            this.select = columns;
            return this;
        }
        
        public Builder from(String table) {
            this.from = table;
            return this;
        }
        
        public Builder innerJoin(String table, String condition) {
            joins.add("INNER JOIN " + table + " ON " + condition);
            return this;
        }
        
        public Builder leftJoin(String table, String condition) {
            joins.add("LEFT JOIN " + table + " ON " + condition);
            return this;
        }
        
        public Builder where(String condition) {
            where.add(condition);
            return this;
        }
        
        public Builder whereEquals(String column, Object value) {
            if (value instanceof String) {
                where.add(column + " = '" + value + "'");
            } else {
                where.add(column + " = " + value);
            }
            return this;
        }
        
        public Builder whereIn(String column, List<?> values) {
            List<String> stringValues = values.stream()
                .map(v -> v instanceof String ? "'" + v + "'" : v.toString())
                .collect(Collectors.toList());
            where.add(column + " IN (" + String.join(", ", stringValues) + ")");
            return this;
        }
        
        public Builder groupBy(String... columns) {
            this.groupBy.addAll(Arrays.asList(columns));
            return this;
        }
        
        public Builder having(String condition) {
            having.add(condition);
            return this;
        }
        
        public Builder orderBy(String column, SortOrder order) {
            orderBy.add(column + " " + order.name());
            return this;
        }
        
        public Builder orderBy(String column) {
            return orderBy(column, SortOrder.ASC);
        }
        
        public Builder limit(int limit) {
            this.limit = limit;
            return this;
        }
        
        public Builder offset(int offset) {
            this.offset = offset;
            return this;
        }
        
        public SQLQuery build() {
            // Validation
            if (from == null) {
                throw new IllegalStateException("FROM clause is required");
            }
            
            if (having.size() > 0 && groupBy.isEmpty()) {
                throw new IllegalStateException("HAVING clause requires GROUP BY");
            }
            
            return new SQLQuery(this);
        }
    }
    
    public enum SortOrder {
        ASC, DESC
    }
}

// Usage example
class QueryService {
    public List<User> getUsersByDepartmentWithStats(String department, int minSalary) {
        SQLQuery query = new SQLQuery.Builder()
            .select("u.id, u.name, u.email, d.name as dept_name, AVG(u.salary) as avg_salary")
            .from("users u")
            .innerJoin("departments d", "u.department_id = d.id")
            .where("u.active = true")
            .whereEquals("d.name", department)
            .where("u.salary >= " + minSalary)
            .groupBy("u.id", "u.name", "u.email", "d.name")
            .having("AVG(u.salary) > 50000")
            .orderBy("avg_salary", SQLQuery.SortOrder.DESC)
            .limit(100)
            .build();
            
        System.out.println("Generated SQL: " + query.toSQL());
        // Execute query and return results
        return executeQuery(query);
    }
    
    private List<User> executeQuery(SQLQuery query) {
        // Database execution logic
        return new ArrayList<>();
    }
}

// Alternative: Immutable HTTP Request Builder
class HttpRequest {
    private final String url;
    private final String method;
    private final Map<String, String> headers;
    private final Map<String, String> queryParams;
    private final String body;
    private final int timeout;
    
    private HttpRequest(Builder builder) {
        this.url = builder.url;
        this.method = builder.method;
        this.headers = Collections.unmodifiableMap(builder.headers);
        this.queryParams = Collections.unmodifiableMap(builder.queryParams);
        this.body = builder.body;
        this.timeout = builder.timeout;
    }
    
    public static class Builder {
        private String url;
        private String method = "GET";
        private final Map<String, String> headers = new HashMap<>();
        private final Map<String, String> queryParams = new HashMap<>();
        private String body;
        private int timeout = 30000; // 30 seconds default
        
        public Builder url(String url) {
            this.url = url;
            return this;
        }
        
        public Builder get() {
            this.method = "GET";
            return this;
        }
        
        public Builder post() {
            this.method = "POST";
            return this;
        }
        
        public Builder put() {
            this.method = "PUT";
            return this;
        }
        
        public Builder delete() {
            this.method = "DELETE";
            return this;
        }
        
        public Builder header(String name, String value) {
            headers.put(name, value);
            return this;
        }
        
        public Builder bearerAuth(String token) {
            return header("Authorization", "Bearer " + token);
        }
        
        public Builder contentType(String contentType) {
            return header("Content-Type", contentType);
        }
        
        public Builder jsonBody(String json) {
            this.body = json;
            return contentType("application/json");
        }
        
        public Builder queryParam(String name, String value) {
            queryParams.put(name, value);
            return this;
        }
        
        public Builder timeout(int timeoutMs) {
            this.timeout = timeoutMs;
            return this;
        }
        
        public HttpRequest build() {
            if (url == null || url.trim().isEmpty()) {
                throw new IllegalStateException("URL is required");
            }
            
            if (("POST".equals(method) || "PUT".equals(method)) && body == null) {
                throw new IllegalStateException(method + " requests should have a body");
            }
            
            return new HttpRequest(this);
        }
    }
    
    // Getters
    public String getUrl() { return url; }
    public String getMethod() { return method; }
    public Map<String, String> getHeaders() { return headers; }
    public Map<String, String> getQueryParams() { return queryParams; }
    public String getBody() { return body; }
    public int getTimeout() { return timeout; }
}
```

### 🎯 Interview Questions
1. **Q**: When to use Builder pattern?
   **A**: When constructing complex objects with many optional parameters, especially immutable objects.

2. **Q**: Difference between Builder and Constructor with many parameters?
   **A**: Builder provides fluent interface, handles optional parameters gracefully, and ensures object immutability.

---

## 🧬 Prototype Pattern

### 📖 Concept
Creates new objects by cloning existing instances rather than creating from scratch.

### 💡 Implementation: Document Templates System

```java
// Prototype interface
interface DocumentPrototype extends Cloneable {
    DocumentPrototype clone();
    void customize(String content);
    void render();
}

// Abstract base class
abstract class Document implements DocumentPrototype {
    protected String title;
    protected String author;
    protected LocalDateTime createdDate;
    protected List<String> sections;
    protected Map<String, Object> metadata;
    
    protected Document() {
        this.createdDate = LocalDateTime.now();
        this.sections = new ArrayList<>();
        this.metadata = new HashMap<>();
    }
    
    protected Document(Document other) {
        this.title = other.title;
        this.author = other.author;
        this.createdDate = LocalDateTime.now(); // New timestamp for clone
        this.sections = new ArrayList<>(other.sections); // Shallow copy for sections
        this.metadata = new HashMap<>(other.metadata); // Shallow copy for metadata
    }
    
    @Override
    public abstract Document clone();
    
    public void setTitle(String title) { this.title = title; }
    public void setAuthor(String author) { this.author = author; }
    public void addSection(String section) { sections.add(section); }
    public void setMetadata(String key, Object value) { metadata.put(key, value); }
}

// Concrete prototypes
class ReportDocument extends Document {
    private String reportType;
    private List<Chart> charts;
    private boolean includeExecutiveSummary;
    
    public ReportDocument() {
        super();
        this.reportType = "STANDARD";
        this.charts = new ArrayList<>();
        this.includeExecutiveSummary = true;
    }
    
    private ReportDocument(ReportDocument other) {
        super(other);
        this.reportType = other.reportType;
        this.charts = new ArrayList<>();
        // Deep copy charts
        for (Chart chart : other.charts) {
            this.charts.add(chart.clone());
        }
        this.includeExecutiveSummary = other.includeExecutiveSummary;
    }
    
    @Override
    public ReportDocument clone() {
        return new ReportDocument(this);
    }
    
    @Override
    public void customize(String content) {
        addSection("Executive Summary: " + content);
        setMetadata("customized", true);
    }
    
    @Override
    public void render() {
        System.out.printf("REPORT: %s by %s (%s)%n", title, author, reportType);
        sections.forEach(section -> System.out.println("  - " + section));
        System.out.println("  Charts: " + charts.size());
    }
    
    public void setReportType(String type) { this.reportType = type; }
    public void addChart(Chart chart) { charts.add(chart); }
}

class LetterDocument extends Document {
    private String recipient;
    private String letterhead;
    private boolean formal;
    
    public LetterDocument() {
        super();
        this.formal = true;
        this.letterhead = "Default Letterhead";
    }
    
    private LetterDocument(LetterDocument other) {
        super(other);
        this.recipient = other.recipient;
        this.letterhead = other.letterhead;
        this.formal = other.formal;
    }
    
    @Override
    public LetterDocument clone() {
        return new LetterDocument(this);
    }
    
    @Override
    public void customize(String content) {
        addSection(formal ? "Dear " + recipient + "," : "Hi " + recipient + ",");
        addSection(content);
        addSection(formal ? "Sincerely," : "Best regards,");
        addSection(author);
    }
    
    @Override
    public void render() {
        System.out.printf("LETTER: %s%n", letterhead);
        System.out.printf("To: %s, From: %s%n", recipient, author);
        sections.forEach(System.out::println);
    }
    
    public void setRecipient(String recipient) { this.recipient = recipient; }
    public void setLetterhead(String letterhead) { this.letterhead = letterhead; }
    public void setFormal(boolean formal) { this.formal = formal; }
}

// Supporting classes
class Chart implements Cloneable {
    private String type;
    private String title;
    private List<String> data;
    
    public Chart(String type, String title) {
        this.type = type;
        this.title = title;
        this.data = new ArrayList<>();
    }
    
    private Chart(Chart other) {
        this.type = other.type;
        this.title = other.title;
        this.data = new ArrayList<>(other.data);
    }
    
    @Override
    public Chart clone() {
        return new Chart(this);
    }
    
    public void addData(String dataPoint) { data.add(dataPoint); }
}

// Document registry and manager
class DocumentRegistry {
    private static final Map<String, Document> prototypes = new HashMap<>();
    
    static {
        // Pre-register common templates
        ReportDocument quarterlyReport = new ReportDocument();
        quarterlyReport.setTitle("Quarterly Report Template");
        quarterlyReport.setAuthor("Template Author");
        quarterlyReport.setReportType("QUARTERLY");
        quarterlyReport.addSection("Financial Overview");
        quarterlyReport.addSection("Market Analysis");
        quarterlyReport.addSection("Future Outlook");
        quarterlyReport.addChart(new Chart("BAR", "Revenue Chart"));
        
        LetterDocument businessLetter = new LetterDocument();
        businessLetter.setTitle("Business Letter Template");
        businessLetter.setAuthor("Template Author");
        businessLetter.setLetterhead("Company Letterhead");
        businessLetter.setFormal(true);
        
        prototypes.put("QUARTERLY_REPORT", quarterlyReport);
        prototypes.put("BUSINESS_LETTER", businessLetter);
    }
    
    public static Document getPrototype(String type) {
        Document prototype = prototypes.get(type);
        if (prototype == null) {
            throw new IllegalArgumentException("Unknown document type: " + type);
        }
        return prototype.clone();
    }
    
    public static void registerPrototype(String type, Document prototype) {
        prototypes.put(type, prototype);
    }
    
    public static Set<String> getAvailableTypes() {
        return prototypes.keySet();
    }
}

// Document factory using prototype pattern
class DocumentFactory {
    public static Document createQuarterlyReport(String author, String quarter) {
        ReportDocument report = (ReportDocument) DocumentRegistry.getPrototype("QUARTERLY_REPORT");
        report.setAuthor(author);
        report.setTitle("Q" + quarter + " Report");
        report.customize("This quarterly report covers our performance for Q" + quarter);
        return report;
    }
    
    public static Document createBusinessLetter(String author, String recipient, String content) {
        LetterDocument letter = (LetterDocument) DocumentRegistry.getPrototype("BUSINESS_LETTER");
        letter.setAuthor(author);
        letter.setRecipient(recipient);
        letter.customize(content);
        return letter;
    }
}
```

### ⚠️ Common Mistakes
- **Shallow vs Deep Copy** - Not properly copying nested objects
- **Mutable State** - Cloned objects sharing mutable references  
- **Clone Method Issues** - Not overriding clone() properly
- **Performance Assumptions** - Cloning might not always be faster than construction

### 🎯 Interview Questions
1. **Q**: When is Prototype pattern useful?
   **A**: When object creation is expensive, when you need to avoid subclass explosion, or when creating objects at runtime.

2. **Q**: Shallow vs Deep copy in Prototype?
   **A**: Shallow copies references, deep copy creates new instances of nested objects. Choose based on whether clones should share state.

---

## 🔌 Adapter Pattern

### 📖 Concept
Allows incompatible interfaces to work together by wrapping one class with another that provides the expected interface.

### 💡 Implementation: Payment Gateway Integration

```java
// Target interface (what our application expects)
interface PaymentProcessor {
    PaymentResult processPayment(PaymentRequest request);
    boolean refundPayment(String transactionId, BigDecimal amount);
    PaymentStatus getPaymentStatus(String transactionId);
}

// Modern payment request/response classes
class PaymentRequest {
    private final String merchantId;
    private final BigDecimal amount;
    private final Currency currency;
    private final String customerEmail;
    private final Map<String, String> metadata;
    
    public PaymentRequest(String merchantId, BigDecimal amount, Currency currency, String customerEmail) {
        this.merchantId = merchantId;
        this.amount = amount;
        this.currency = currency;
        this.customerEmail = customerEmail;
        this.metadata = new HashMap<>();
    }
    
    // Getters and builder methods
    public String getMerchantId() { return merchantId; }
    public BigDecimal getAmount() { return amount; }
    public Currency getCurrency() { return currency; }
    public String getCustomerEmail() { return customerEmail; }
    public Map<String, String> getMetadata() { return metadata; }
    
    public PaymentRequest withMetadata(String key, String value) {
        metadata.put(key, value);
        return this;
    }
}

class PaymentResult {
    private final String transactionId;
    private final PaymentStatus status;
    private final String message;
    private final BigDecimal processedAmount;
    private final LocalDateTime processedAt;
    
    public PaymentResult(String transactionId, PaymentStatus status, String message, 
                        BigDecimal processedAmount) {
        this.transactionId = transactionId;
        this.status = status;
        this.message = message;
        this.processedAmount = processedAmount;
        this.processedAt = LocalDateTime.now();
    }
    
    // Getters
    public String getTransactionId() { return transactionId; }
    public PaymentStatus getStatus() { return status; }
    public String getMessage() { return message; }
    public BigDecimal getProcessedAmount() { return processedAmount; }
    public LocalDateTime getProcessedAt() { return processedAt; }
}

enum PaymentStatus {
    SUCCESS, FAILED, PENDING, CANCELLED, REFUNDED
}

enum Currency {
    USD, EUR, GBP, INR, JPY
}

// Legacy payment system (existing third-party system)
class LegacyPaymentGateway {
    public String sendPayment(String accountId, float amount, String currencyCode, String email) {
        // Legacy implementation with different parameter types and order
        System.out.printf("Legacy: Processing $%.2f %s for %s (Account: %s)%n", 
            amount, currencyCode, email, accountId);
        
        // Simulate processing
        try {
            Thread.sleep(100); // Simulate network call
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // Legacy returns simple transaction ID
        return "LEG_" + System.currentTimeMillis();
    }
    
    public int checkPaymentStatus(String transactionId) {
        // Legacy returns integer status codes: 1=success, 0=failed, 2=pending
        return transactionId.startsWith("LEG_") ? 1 : 0;
    }
    
    public boolean revertPayment(String transactionId, float refundAmount) {
        System.out.printf("Legacy: Refunding $%.2f for transaction %s%n", 
            refundAmount, transactionId);
        return true; // Simplified for demo
    }
}

// Adapter that makes legacy system work with new interface
class LegacyPaymentAdapter implements PaymentProcessor {
    private final LegacyPaymentGateway legacyGateway;
    private final Logger logger;
    
    public LegacyPaymentAdapter(LegacyPaymentGateway legacyGateway) {
        this.legacyGateway = legacyGateway;
        this.logger = Logger.getInstance();
    }
    
    @Override
    public PaymentResult processPayment(PaymentRequest request) {
        logger.log(LogLevel.INFO, "Adapting payment request for legacy gateway");
        
        try {
            // Convert modern request to legacy parameters
            String accountId = request.getMerchantId();
            float amount = request.getAmount().floatValue(); // Type conversion
            String currencyCode = request.getCurrency().name();
            String email = request.getCustomerEmail();
            
            // Log compatibility warning
            logger.log(LogLevel.WARN, "Using legacy payment gateway - consider migrating");
            
            // Call legacy system
            String transactionId = legacyGateway.sendPayment(accountId, amount, currencyCode, email);
            
            // Convert legacy response to modern format
            PaymentStatus status = convertLegacyStatus(legacyGateway.checkPaymentStatus(transactionId));
            
            return new PaymentResult(
                transactionId,
                status,
                "Payment processed via legacy gateway",
                request.getAmount()
            );
            
        } catch (Exception e) {
            logger.log(LogLevel.ERROR, "Legacy payment processing failed: " + e.getMessage());
            return new PaymentResult(
                null,
                PaymentStatus.FAILED,
                "Legacy gateway error: " + e.getMessage(),
                BigDecimal.ZERO
            );
        }
    }
    
    @Override
    public boolean refundPayment(String transactionId, BigDecimal amount) {
        logger.log(LogLevel.INFO, "Adapting refund request for legacy gateway");
        
        try {
            float legacyAmount = amount.floatValue(); // Type conversion
            return legacyGateway.revertPayment(transactionId, legacyAmount);
        } catch (Exception e) {
            logger.log(LogLevel.ERROR, "Legacy refund failed: " + e.getMessage());
            return false;
        }
    }
    
    @Override
    public PaymentStatus getPaymentStatus(String transactionId) {
        try {
            int legacyStatus = legacyGateway.checkPaymentStatus(transactionId);
            return convertLegacyStatus(legacyStatus);
        } catch (Exception e) {
            logger.log(LogLevel.ERROR, "Failed to get payment status: " + e.getMessage());
            return PaymentStatus.FAILED;
        }
    }
    
    private PaymentStatus convertLegacyStatus(int legacyStatus) {
        // Convert legacy integer codes to modern enum
        switch (legacyStatus) {
            case 1: return PaymentStatus.SUCCESS;
            case 0: return PaymentStatus.FAILED;
            case 2: return PaymentStatus.PENDING;
            default: return PaymentStatus.FAILED;
        }
    }
}

// Modern payment system (new implementation)
class StripePaymentProcessor implements PaymentProcessor {
    private final String apiKey;
    
    public StripePaymentProcessor(String apiKey) {
        this.apiKey = apiKey;
    }
    
    @Override
    public PaymentResult processPayment(PaymentRequest request) {
        // Modern implementation
        System.out.printf("Stripe: Processing %s %s for %s%n",
            request.getCurrency(), request.getAmount(), request.getCustomerEmail());
        
        // Generate modern transaction ID
        String transactionId = "stripe_" + UUID.randomUUID().toString();
        
        return new PaymentResult(
            transactionId,
            PaymentStatus.SUCCESS,
            "Payment processed successfully",
            request.getAmount()
        );
    }
    
    @Override
    public boolean refundPayment(String transactionId, BigDecimal amount) {
        System.out.printf("Stripe: Refunding %s for %s%n", amount, transactionId);
        return true;
    }
    
    @Override
    public PaymentStatus getPaymentStatus(String transactionId) {
        return PaymentStatus.SUCCESS; // Simplified
    }
}

// Payment service that uses the adapter
class PaymentService {
    private final PaymentProcessor processor;
    
    public PaymentService(PaymentProcessor processor) {
        this.processor = processor;
    }
    
    public PaymentResult makePayment(String merchantId, BigDecimal amount, 
                                   Currency currency, String customerEmail) {
        PaymentRequest request = new PaymentRequest(merchantId, amount, currency, customerEmail)
            .withMetadata("source", "web_app")
            .withMetadata("version", "1.0");
            
        return processor.processPayment(request);
    }
    
    public boolean processRefund(String transactionId, BigDecimal amount) {
        return processor.refundPayment(transactionId, amount);
    }
}

// Usage example
class PaymentDemo {
    public static void main(String[] args) {
        // Using legacy system through adapter
        LegacyPaymentGateway legacyGateway = new LegacyPaymentGateway();
        PaymentProcessor legacyAdapter = new LegacyPaymentAdapter(legacyGateway);
        
        PaymentService legacyService = new PaymentService(legacyAdapter);
        PaymentResult legacyResult = legacyService.makePayment(
            "MERCH_001", new BigDecimal("99.99"), Currency.USD, "customer@example.com"
        );
        
        System.out.println("Legacy result: " + legacyResult.getStatus());
        
        // Using modern system
        PaymentProcessor stripeProcessor = new StripePaymentProcessor("sk_test_...");
        PaymentService modernService = new PaymentService(stripeProcessor);
        PaymentResult modernResult = modernService.makePayment(
            "MERCH_001", new BigDecimal("99.99"), Currency.USD, "customer@example.com"
        );
        
        System.out.println("Modern result: " + modernResult.getStatus());
    }
}
```

### ⚠️ Common Mistakes
- **Not handling data type conversions properly** - Loss of precision or data
- **Ignoring exception translation** - Legacy exceptions need to be wrapped
- **Performance overhead** - Additional layer can impact performance
- **Memory leaks** - Not properly managing resources from adaptee

### 🎯 Interview Questions
1. **Q**: Difference between Adapter and Facade patterns?
   **A**: Adapter converts interface, Facade simplifies complex subsystem interface.

2. **Q**: When to use Object Adapter vs Class Adapter?
   **A**: Object Adapter (composition) is more flexible; Class Adapter (inheritance) only works with single inheritance languages.

---

## 🎨 Decorator Pattern

### 📖 Concept
Dynamically adds new behaviors to objects without changing their structure by wrapping them in decorator objects.

### 💡 Implementation: Coffee Shop Ordering System

```java
// Component interface
interface Coffee {
    String getDescription();
    BigDecimal getCost();
    List<String> getIngredients();
}

// Concrete component - Base coffee
class SimpleCoffee implements Coffee {
    @Override
    public String getDescription() {
        return "Simple Coffee";
    }
    
    @Override
    public BigDecimal getCost() {
        return new BigDecimal("2.00");
    }
    
    @Override
    public List<String> getIngredients() {
        return Arrays.asList("Coffee beans", "Water");
    }
}

class Espresso implements Coffee {
    @Override
    public String getDescription() {
        return "Rich Espresso";
    }
    
    @Override
    public BigDecimal getCost() {
        return new BigDecimal("1.50");
    }
    
    @Override
    public List<String> getIngredients() {
        return Arrays.asList("Espresso beans", "Water");
    }
}

// Base decorator class
abstract class CoffeeDecorator implements Coffee {
    protected final Coffee coffee;
    
    protected CoffeeDecorator(Coffee coffee) {
        this.coffee = coffee;
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription();
    }
    
    @Override
    public BigDecimal getCost() {
        return coffee.getCost();
    }
    
    @Override
    public List<String> getIngredients() {
        return new ArrayList<>(coffee.getIngredients());
    }
}

// Concrete decorators
class MilkDecorator extends CoffeeDecorator {
    public MilkDecorator(Coffee coffee) {
        super(coffee);
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + " + Milk";
    }
    
    @Override
    public BigDecimal getCost() {
        return coffee.getCost().add(new BigDecimal("0.50"));
    }
    
    @Override
    public List<String> getIngredients() {
        List<String> ingredients = super.getIngredients();
        ingredients.add("Milk");
        return ingredients;
    }
}

class SugarDecorator extends CoffeeDecorator {
    private final int packets;
    
    public SugarDecorator(Coffee coffee, int packets) {
        super(coffee);
        this.packets = packets;
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + " + " + packets + " Sugar packet(s)";
    }
    
    @Override
    public BigDecimal getCost() {
        return coffee.getCost().add(new BigDecimal("0.10").multiply(new BigDecimal(packets)));
    }
    
    @Override
    public List<String> getIngredients() {
        List<String> ingredients = super.getIngredients();
        ingredients.add(packets + " sugar packet(s)");
        return ingredients;
    }
}

class WhippedCreamDecorator extends CoffeeDecorator {
    public WhippedCreamDecorator(Coffee coffee) {
        super(coffee);
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + " + Whipped Cream";
    }
    
    @Override
    public BigDecimal getCost() {
        return coffee.getCost().add(new BigDecimal("0.75"));
    }
    
    @Override
    public List<String> getIngredients() {
        List<String> ingredients = super.getIngredients();
        ingredients.add("Whipped Cream");
        return ingredients;
    }
}

class VanillaSyrupDecorator extends CoffeeDecorator {
    public VanillaSyrupDecorator(Coffee coffee) {
        super(coffee);
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + " + Vanilla Syrup";
    }
    
    @Override
    public BigDecimal getCost() {
        return coffee.getCost().add(new BigDecimal("0.60"));
    }
    
    @Override
    public List<String> getIngredients() {
        List<String> ingredients = super.getIngredients();
        ingredients.add("Vanilla Syrup");
        return ingredients;
    }
}

// Size decorator (affects cost multiplier)
class SizeDecorator extends CoffeeDecorator {
    private final CoffeeSize size;
    
    public SizeDecorator(Coffee coffee, CoffeeSize size) {
        super(coffee);
        this.size = size;
    }
    
    @Override
    public String getDescription() {
        return size.name() + " " + coffee.getDescription();
    }
    
    @Override
    public BigDecimal getCost() {
        return coffee.getCost().multiply(size.getPriceMultiplier());
    }
    
    @Override
    public List<String> getIngredients() {
        List<String> ingredients = super.getIngredients();
        ingredients.add("Size: " + size.name());
        return ingredients;
    }
    
    enum CoffeeSize {
        SMALL(new BigDecimal("0.9")),
        MEDIUM(new BigDecimal("1.0")),
        LARGE(new BigDecimal("1.3")),
        EXTRA_LARGE(new BigDecimal("1.6"));
        
        private final BigDecimal priceMultiplier;
        
        CoffeeSize(BigDecimal priceMultiplier) {
            this.priceMultiplier = priceMultiplier;
        }
        
        public BigDecimal getPriceMultiplier() {
            return priceMultiplier;
        }
    }
}

// Advanced decorator with conditional logic
class DiscountDecorator extends CoffeeDecorator {
    private final BigDecimal discountPercentage;
    private final String reason;
    
    public DiscountDecorator(Coffee coffee, BigDecimal discountPercentage, String reason) {
        super(coffee);
        this.discountPercentage = discountPercentage;
        this.reason = reason;
    }
    
    @Override
    public String getDescription() {
        return coffee.getDescription() + " (" + discountPercentage + "% off - " + reason + ")";
    }
    
    @Override
    public BigDecimal getCost() {
        BigDecimal originalCost = coffee.getCost();
        BigDecimal discount = originalCost.multiply(discountPercentage).divide(new BigDecimal("100"));
        return originalCost.subtract(discount);
    }
}

// Coffee shop order builder using decorator pattern
class CoffeeOrderBuilder {
    private Coffee coffee;
    
    public CoffeeOrderBuilder(Coffee baseCoffee) {
        this.coffee = baseCoffee;
    }
    
    public CoffeeOrderBuilder addMilk() {
        coffee = new MilkDecorator(coffee);
        return this;
    }
    
    public CoffeeOrderBuilder addSugar(int packets) {
        coffee = new SugarDecorator(coffee, packets);
        return this;
    }
    
    public CoffeeOrderBuilder addWhippedCream() {
        coffee = new WhippedCreamDecorator(coffee);
        return this;
    }
    
    public CoffeeOrderBuilder addVanillaSyrup() {
        coffee = new VanillaSyrupDecorator(coffee);
        return this;
    }
    
    public CoffeeOrderBuilder setSize(SizeDecorator.CoffeeSize size) {
        coffee = new SizeDecorator(coffee, size);
        return this;
    }
    
    public CoffeeOrderBuilder applyDiscount(BigDecimal percentage, String reason) {
        coffee = new DiscountDecorator(coffee, percentage, reason);
        return this;
    }
    
    public Coffee build() {
        return coffee;
    }
}

// Usage and demonstration
class CoffeeShop {
    public static void main(String[] args) {
        // Simple coffee order
        Coffee simpleCoffee = new SimpleCoffee();
        System.out.println(formatOrder(simpleCoffee));
        
        // Complex coffee order using fluent interface
        Coffee fancyCoffee = new CoffeeOrderBuilder(new Espresso())
            .setSize(SizeDecorator.CoffeeSize.LARGE)
            .addMilk()
            .addSugar(2)
            .addWhippedCream()
            .addVanillaSyrup()
            .applyDiscount(new BigDecimal("10"), "Loyalty customer")
            .build();
            
        System.out.println(formatOrder(fancyCoffee));
        
        // Manual decoration (shows flexibility)
        Coffee manualOrder = new WhippedCreamDecorator(
            new MilkDecorator(
                new SugarDecorator(
                    new SizeDecorator(new SimpleCoffee(), SizeDecorator.CoffeeSize.MEDIUM),
                    1
                )
            )
        );
        
        System.out.println(formatOrder(manualOrder));
    }
    
    private static String formatOrder(Coffee coffee) {
        StringBuilder sb = new StringBuilder();
        sb.append("=== Coffee Order ===\n");
        sb.append("Description: ").append(coffee.getDescription()).append("\n");
        sb.append("Cost: $").append(coffee.getCost()).append("\n");
        sb.append("Ingredients: ").append(String.join(", ", coffee.getIngredients())).append("\n");
        sb.append("==================\n");
        return sb.toString();
    }
}
```

### ⚠️ Common Mistakes
- **Too many small decorators** - Can lead to object explosion
- **Order dependency** - Decorators applied in wrong order can cause issues
- **Performance overhead** - Many wrapper objects can impact performance
- **Interface bloat** - Base interface becomes too large to support all decorators

### 🎯 Interview Questions
1. **Q**: Decorator vs Inheritance for adding functionality?
   **A**: Decorator allows runtime composition and multiple features; inheritance is compile-time and single path.

2. **Q**: How to handle decorator ordering issues?
   **A**: Design decorators to be order-independent, or provide builder pattern for correct ordering.

---

*Continue to next patterns...*

### 🎯 Pattern Selection Guide

| **Scenario** | **Recommended Pattern** | **Alternative** |
|--------------|------------------------|-----------------|
| Single global instance | Singleton | Static class |
| Creating object families | Abstract Factory | Factory Method |
| Runtime algorithm switching | Strategy | Command |
| Adding features dynamically | Decorator | Inheritance |
| Converting interfaces | Adapter | Wrapper |
| Complex object construction | Builder | Telescoping Constructor |
| Expensive object creation | Prototype | Factory |
| Chain of handlers | Chain of Responsibility | Command |
| Encapsulating requests | Command | Strategy |
| State-dependent behavior | State | Strategy |
| Object interaction mediation | Mediator | Observer |

### 🧠 Memory Techniques

**Creational**: **S**ally **F**ound **A**n **B**ig **P**ython
- **S**ingleton, **F**actory, **A**bstract Factory, **B**uilder, **P**rototype

**Structural**: **A**ll **D**ogs **F**ly
- **A**dapter, **D**ecorator, **F**acade, **F**lyweight

**Behavioral**: **S**mart **O**wls **C**an **C**atch **T**iny **S**nakes **M**ost **T**imes
- **S**trategy, **O**bserver, **C**ommand, **C**hain, **T**emplate, **S**tate, **M**ediator, **T**ime

### 📊 Complexity Analysis

| Pattern | **Time Complexity** | **Space Complexity** | **Usage Frequency** |
|---------|--------------------|--------------------|-------------------|
| Singleton | O(1) | O(1) | ⭐⭐⭐⭐⭐ |
| Factory | O(1) | O(1) | ⭐⭐⭐⭐⭐ |
| Builder | O(n) | O(n) | ⭐⭐⭐⭐ |
| Observer | O(n) | O(n) | ⭐⭐⭐⭐⭐ |
| Strategy | O(1) | O(1) | ⭐⭐⭐⭐⭐ |
| Decorator | O(n) | O(n) | ⭐⭐⭐⭐ |
| Adapter | O(1) | O(1) | ⭐⭐⭐⭐ |
| Command | O(1) | O(n) | ⭐⭐⭐ |

### 🔗 Related Topics
- [[System Design Patterns]]
- [[Java Concurrency Patterns]]  
- [[Microservices Design Patterns]]
- [[Database Design Patterns]]

---

*Tags: #design-patterns #oop #software-architecture #java #interview-prep*