# Bridge Pattern  
  
## Overview  
The Bridge pattern is a structural design pattern that **decouples an abstraction from its implementation** so that the two can vary independently. It uses composition to separate interface (abstraction) from implementation into two separate class hierarchies.  
  
**Analogy**: Think of a TV remote control (abstraction) that can work with different TV brands (implementations). You can change the TV without changing the remote, and vice versa.  
  
## The Problem: Combinatorial Explosion  
  
### Without Bridge Pattern  
  
Imagine you have:  
- **3 message types**: Urgent, Warning, Info  
- **3 delivery channels**: Email, SMS, Slack  
  
**Inheritance approach** would require:  
```  
UrgentEmailNotification  
UrgentSMSNotification  
UrgentSlackNotification  
WarningEmailNotification  
WarningSMSNotification  
WarningSlackNotification  
InfoEmailNotification  
InfoSMSNotification  
InfoSlackNotification  
```  
  
**Result**: 9 classes (3 × 3)!  
  
Adding a new message type? **+3 classes**  
Adding a new channel? **+3 classes**  
  
This is **combinatorial explosion** - classes grow multiplicatively!  
  
### With Bridge Pattern  
  
**Two separate hierarchies**:  
  
```  
Abstraction Side (Message Types):     Implementation Side (Channels):  
├── Notification                      ├── MessageChannel  
    ├── UrgentNotification                ├── EmailChannel    ├── WarningNotification               ├── SMSChannel    └── InfoNotification                  └── SlackChannel```  
  
**Result**: 6 classes (3 + 3)!  
  
Adding a new message type? **+1 class**  
Adding a new channel? **+1 class**  
  
## When to Use  
  
### Use Bridge Pattern When:  
  
1. **Multiple dimensions that vary independently**  
   - Message types and delivery channels  
   - Shapes and colors  
   - UI controls and platforms  
  
2. **Avoid permanent binding between abstraction and implementation**  
   - Want to switch implementations at runtime  
   - Different implementations for different contexts  
  
3. **Both abstractions and implementations should be extensible**  
   - Need to add new abstractions  
   - Need to add new implementations  
   - Without affecting each other  
  
4. **Prevent class explosion**  
   - Have n abstractions and m implementations  
   - Don't want n × m classes  
  
5. **Share implementation among multiple objects**  
   - Hide implementation details from clients  
   - Multiple abstractions use same implementation  
  
6. **Changes in implementation shouldn't affect clients**  
   - Implementation can change without recompiling abstraction  
   - Abstraction provides stable interface  
  
### Don't Use When:  
  
- Only one implementation exists  
- Abstraction and implementation won't vary independently  
- Simple inheritance is sufficient  
- Adding extra indirection hurts more than helps  
  
## Structure  
  
```  
┌────────────┐  
│   Client   │  
└─────┬──────┘  
      │ uses      ▼┌─────────────────┐           ┌──────────────────┐  
│   Abstraction   │ ◇────────▶│ Implementation   │  
│   (Notification)│  bridge   │ (MessageChannel) │  
└────────┬────────┘           └────────┬─────────┘  
         │                              │         │ extends                      │ implements         │                              │    ┌────┴─────┬────────┐         ┌────┴─────┬──────────┐    │          │        │         │          │          │┌───▼──┐  ┌───▼───┐ ┌──▼───┐ ┌──▼────┐ ┌───▼───┐ ┌───▼────┐  
│Urgent│  │Warning│ │ Info │ │ Email │ │  SMS  │ │ Slack  │  
└──────┘  └───────┘ └──────┘ └───────┘ └───────┘ └────────┘  
```  
  
## Key Components  
  
1. **Abstraction** (e.g., `Notification`)  
   - Defines the abstraction's interface  
   - Maintains reference to Implementation  
   - Delegates to Implementation  
  
2. **Refined Abstraction** (e.g., `UrgentNotification`)  
   - Extends the interface defined by Abstraction  
   - Adds specific behavior  
  
3. **Implementation** (e.g., `MessageChannel`)  
   - Defines the interface for implementation classes  
   - Doesn't have to match Abstraction's interface  
  
4. **Concrete Implementation** (e.g., `EmailChannel`)  
   - Implements the Implementation interface  
  
## Benefits  
  
### 1. **Separation of Concerns**  
```java  
// Abstraction handles high-level logic  
class UrgentNotification extends Notification {  
    public void send(String msg, String recipient) {        String formatted = "[URGENT] " + msg;  // Abstraction's job        channel.sendMessage(formatted, recipient);  // Implementation's job    }}  
  
// Implementation handles low-level details  
class EmailChannel implements MessageChannel {  
    public void sendMessage(String msg, String recipient) {        // Email-specific logic    }}  
```  
  
### 2. **Independent Extension**  
```java  
// Add new abstraction - no impact on implementations  
class CriticalNotification extends Notification {  
    // New message type}  
  
// Add new implementation - no impact on abstractions  
class WhatsAppChannel implements MessageChannel {  
    // New channel}  
  
// Works immediately!  
Notification critical = new CriticalNotification(new WhatsAppChannel());  
```  
  
### 3. **Runtime Binding**  
```java  
// Can change implementation at runtime  
Notification notification = new UrgentNotification(emailChannel);  
notification.send("Alert", "admin@example.com");  
  
// Switch to different channel  
notification = new UrgentNotification(smsChannel);  
notification.send("Alert", "+1234567890");  
```  
  
### 4. **Reduces Class Count**  
- Without Bridge: n × m classes  
- With Bridge: n + m classes  
  
### 5. **Open/Closed Principle**  
- Open for extension (add new abstractions/implementations)  
- Closed for modification (existing code unchanged)  
  
### 6. **Single Responsibility Principle**  
- Abstraction: High-level logic  
- Implementation: Platform-specific details  
  
### 7. **Hides Implementation Details**  
```java  
// Client only knows about abstraction  
Notification notification = new UrgentNotification(channel);  
// Client doesn't know if it's Email, SMS, or Slack  
```  
  
## Real-World Use Cases  
  
### 1. **UI Frameworks (Cross-Platform)**  
```java  
// Abstraction: UI Controls  
Button button = new RoundButton(windowsImpl);  
Button button2 = new SquareButton(macOSImpl);  
Button button3 = new RoundButton(linuxImpl);  
  
// Can have different button styles on different platforms  
```  
  
### 2. **Database Drivers**  
```java  
// Abstraction: Database operations  
Database db = new RelationalDB(mySQLDriver);  
Database db2 = new RelationalDB(postgresDriver);  
Database db3 = new NoSQLDB(mongoDriver);  
```  
  
### 3. **Graphics Rendering**  
```java  
// Abstraction: Shapes  
Shape circle = new Circle(openGLRenderer);  
Shape square = new Square(directXRenderer);  
Shape triangle = new Triangle(vulkanRenderer);  
```  
  
### 4. **Notification Systems** (Our example!)  
```java  
Notification urgent = new UrgentNotification(emailChannel);  
Notification warning = new WarningNotification(smsChannel);  
Notification info = new InfoNotification(slackChannel);  
```  
  
### 5. **Remote Controls**  
```java  
// Abstraction: Remote control features  
RemoteControl basic = new BasicRemote(sonyTV);  
RemoteControl advanced = new AdvancedRemote(lgTV);  
```  
  
### 6. **Logging Systems**  
```java  
// Abstraction: Log levels  
Logger logger = new ErrorLogger(fileLogger);  
Logger logger2 = new DebugLogger(consoleLogger);  
Logger logger3 = new InfoLogger(cloudLogger);  
```  
  
### 7. **Payment Processing**  
```java  
// Abstraction: Payment types  
Payment oneTime = new OneTimePayment(stripeProcessor);  
Payment recurring = new RecurringPayment(paypalProcessor);  
```  
  
## Bridge vs Similar Patterns  
  
| Pattern | Purpose | Key Difference |  
|---------|---------|----------------|  
| **Bridge** | Decouple abstraction from implementation | Two hierarchies connected via composition |  
| **Adapter** | Make incompatible interfaces work | One interface converted to another |  
| **Strategy** | Encapsulate algorithms | One hierarchy (algorithms), no abstraction hierarchy |  
| **Abstract Factory** | Create families of objects | About object creation, not structure |  
| **Decorator** | Add responsibilities dynamically | Same interface, wrapping behavior |  
  
### Bridge vs Adapter  
  
```java  
// Bridge: Designed upfront, two hierarchies that vary independently  
Notification urgent = new UrgentNotification(emailChannel);  
  
// Adapter: Retrofitted, makes incompatible interfaces work  
PaymentProcessor adapted = new StripeAdapter(stripePay);  
```  
  
**Bridge**: Designed before implementation (proactive)  
**Adapter**: Applied after implementation (reactive)  
  
### Bridge vs Strategy  
  
```java  
// Strategy: One algorithm dimension  
Sorter sorter = new Sorter(quickSortStrategy);  
  
// Bridge: Two independent dimensions  
Notification notification = new UrgentNotification(emailChannel);  
// Both notification type AND channel can vary  
```  
  
**Strategy**: Focuses on **how** to do something (algorithm)  
**Bridge**: Focuses on **what** and **how** (abstraction + implementation)  
  
## Common Pitfalls  
  
### 1. **Confusing with Adapter**  
```java  
// Bridge: DESIGNED with two hierarchies  
class Notification {  
    protected MessageChannel channel;  // Intentional separation}  
  
// Adapter: RETROFITTING incompatible interfaces  
class StripeAdapter {  
    private StripePay stripePay;  // Making existing code work}  
```  
  
**Bridge**: Design-time decision  
**Adapter**: Fix for existing code  
  
### 2. **Over-Engineering Simple Cases**  
```java  
// Don't use Bridge if:  
// - Only one implementation exists  
// - Abstraction and implementation won't vary independently  
  
// Bad: Using Bridge for one shape, one renderer  
Shape circle = new Circle(renderer);  // Overkill!  
  
// Good: Just use inheritance  
class Circle {  
    void draw() { /* render */ }}  
```  
  
### 3. **Not Truly Independent Dimensions**  
```java  
// Bad: Dimensions depend on each other  
class EmailOnlyUrgent extends Notification {  
    // This breaks the whole point of Bridge!}  
  
// Good: Any combination possible  
new UrgentNotification(emailChannel);   ✓  
new UrgentNotification(smsChannel);     ✓  
new WarningNotification(emailChannel);  ✓  
```  
  
### 4. **Forgetting the Bridge (Composition)**  
```java  
// Bad: Using inheritance instead of composition  
class UrgentEmail extends Urgent, Email {  // Wrong!  
}  
  
// Good: Composition creates the bridge  
class UrgentNotification extends Notification {  
    protected MessageChannel channel;  // The bridge!}  
```  
  
### 5. **Too Many Abstractions**  
```java  
// Bad: Creating unnecessary abstraction layers  
Notification -> BaseNotification -> AbstractNotification -> UrgentNotification  
  
// Good: Keep it simple  
Notification -> UrgentNotification  
```  
  
## Implementation Steps  
  
### Step 1: Identify Two Orthogonal Dimensions  
- What varies independently?  
- Example: Message types (Urgent, Warning, Info) and Channels (Email, SMS, Slack)  
  
### Step 2: Create Implementation Interface  
```java  
public interface MessageChannel {  
    void sendMessage(String message, String recipient);}  
```  
  
### Step 3: Create Concrete Implementations  
```java  
public class EmailChannel implements MessageChannel {  
    public void sendMessage(String msg, String recipient) {        System.out.println("[Email] To: " + recipient + " - " + msg);    }}  
```  
  
### Step 4: Create Abstraction with Reference to Implementation  
```java  
public abstract class Notification {  
    protected MessageChannel channel;  // THE BRIDGE!  
    public Notification(MessageChannel channel) {        this.channel = channel;    }  
    public abstract void send(String message, String recipient);}  
```  
  
### Step 5: Create Refined Abstractions  
```java  
public class UrgentNotification extends Notification {  
    public UrgentNotification(MessageChannel channel) {        super(channel);    }  
    public void send(String message, String recipient) {        channel.sendMessage("[URGENT] " + message, recipient);    }}  
```  
  
### Step 6: Use It  
```java  
MessageChannel email = new EmailChannel();  
Notification urgent = new UrgentNotification(email);  
urgent.send("Server down!", "admin@example.com");  
```  
  
## Code Example from Our Implementation  
  
### Implementation Side (Channels)  
```java  
// Implementation interface  
public interface MessageChannel {  
    void sendMessage(String message, String recipient);}  
  
// Concrete implementations  
public class EmailChannel implements MessageChannel {  
    public void sendMessage(String msg, String recipient) {        System.out.println("[Email] To: " + recipient + " - " + msg);    }}  
  
public class SMSChannel implements MessageChannel {  
    public void sendMessage(String msg, String recipient) {        System.out.println("[SMS] To: " + recipient + " - " + msg);    }}  
```  
  
### Abstraction Side (Notifications)  
```java  
// Abstraction  
public abstract class Notification {  
    protected MessageChannel channel;  // THE BRIDGE!  
    public Notification(MessageChannel channel) {        this.channel = channel;    }  
    public abstract void send(String message, String recipient);}  
  
// Refined abstractions  
public class UrgentNotification extends Notification {  
    public UrgentNotification(MessageChannel channel) {        super(channel);    }  
    public void send(String message, String recipient) {        // Add urgent-specific behavior        String formatted = "[URGENT] " + message;        // Delegate to implementation        channel.sendMessage(formatted, recipient);    }}  
```  
  
### Client Code  
```java  
// Mix and match freely!  
MessageChannel email = new EmailChannel();  
MessageChannel sms = new SMSChannel();  
  
Notification urgent1 = new UrgentNotification(email);  
Notification urgent2 = new UrgentNotification(sms);  
Notification warning = new WarningNotification(email);  
  
urgent1.send("Server down!", "admin@example.com");  
urgent2.send("Server down!", "+1234567890");  
warning.send("Disk space low", "sysadmin@example.com");  
```  
  
## Interview Questions to Expect  
  
### 1. **What is the Bridge pattern?**  
**Answer**: A structural pattern that decouples abstraction from implementation so they can vary independently. It uses composition to connect two separate hierarchies.  
  
### 2. **When would you use Bridge pattern?**  
**Answer**: When you have two dimensions that vary independently and want to avoid class explosion. Example: Different UI controls on different platforms.  
  
### 3. **Bridge vs Adapter - what's the difference?**  
**Answer**:  
- **Bridge**: Designed upfront, separates abstraction from implementation  
- **Adapter**: Retrofitted, makes incompatible interfaces work together  
- Bridge is proactive, Adapter is reactive  
  
### 4. **What problem does Bridge solve?**  
**Answer**: Combinatorial explosion. Without Bridge, n abstractions × m implementations = n×m classes. With Bridge: n + m classes.  
  
### 5. **Can you give a real-world example?**  
**Answer**: Remote control (abstraction) working with different TV brands (implementation). You can change TV without changing remote design.  
  
### 6. **What's the "bridge" in Bridge pattern?**  
**Answer**: The composition relationship (reference) between abstraction and implementation. It's the field that holds the implementation object.  
  
### 7. **Bridge vs Strategy pattern?**  
**Answer**:  
- **Bridge**: Two hierarchies (abstraction + implementation)  
- **Strategy**: One hierarchy (just algorithms)  
- Bridge focuses on **what** and **how**; Strategy focuses on **how** only  
  
### 8. **What are the benefits of Bridge pattern?**  
**Answer**:  
- Reduces class count (n+m instead of n×m)  
- Independent extension of both hierarchies  
- Runtime implementation switching  
- Hides implementation details  
- Follows Open/Closed and Single Responsibility principles  
  
### 9. **How do you identify when to use Bridge?**  
**Answer**: Look for:  
- Two independent dimensions of variation  
- Need to avoid class explosion  
- Want to switch implementations at runtime  
- Both abstraction and implementation need to be extensible  
  
### 10. **What's a disadvantage of Bridge pattern?**  
**Answer**:  
- Increases complexity (more classes and interfaces)  
- Adds indirection (extra layer)  
- Can be overkill for simple cases  
- Harder to understand for beginners  
  
## Key Takeaways  
  
1. **Purpose**: Decouple abstraction from implementation  
2. **Problem**: Avoids class explosion when two dimensions vary independently  
3. **Solution**: Two separate hierarchies connected via composition (the bridge)  
4. **When**: Multiple independent variations, need runtime flexibility  
5. **Structure**: Abstraction has-a Implementation (composition, not inheritance)  
6. **Benefits**: n+m classes instead of n×m, independent extension  
7. **Remember**: Design-time decision (not a fix like Adapter)  
  
## Visual Summary  
  
```  
WITHOUT BRIDGE:                    WITH BRIDGE:  
3 types × 3 channels = 9 classes   3 types + 3 channels = 6 classes  
  
UrgentEmail                        Urgent ───┐  
UrgentSMS                          Warning ──┼─▶ Email  
UrgentSlack                        Info ─────┘   SMS  
WarningEmail                                     Slack  
WarningSMS  
WarningSlack                       Any type works with any channel!  
InfoEmail  
InfoSMS  
InfoSlack  
```  
  
## Summary  
  
The Bridge pattern is ideal when:  
- ✅ You have two dimensions that vary independently  
- ✅ Want to avoid class explosion  
- ✅ Need runtime flexibility to switch implementations  
- ✅ Want to hide implementation details from clients  
- ✅ Both abstraction and implementation need to be extensible  
  
**Core Concept**: Use composition (has-a) to connect abstraction and implementation, instead of inheritance (is-a).  
  
**The Bridge**: The field in the abstraction that holds a reference to the implementation.  
  
Remember: Bridge is about **designing** for flexibility, not **fixing** existing incompatibilities (that's Adapter).