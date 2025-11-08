## 🏭 2. Factory Method (Expert Level)  

### 💡 Use Case: Extensible Notification System with Runtime Plugin Support

  

### 🧩 Problem Statement  

Design a notification system that supports Email, SMS, and Push notifications. The system must:

- Allow new notification types to be plugged in without modifying the existing factory logic.

- Select the appropriate notification sender at runtime using configuration.

- Handle invalid or unsupported types gracefully.

  

You must implement a `NotificationFactory` that delegates creation to appropriate concrete creators and encapsulates object instantiation logic.

  

### 🧱 Class Scaffolding

```java

interface Notification {

    void send(String to, String message);

}

  

class EmailNotification implements Notification { ... }

class SMSNotification implements Notification { ... }

class PushNotification implements Notification { ... }

  

abstract class NotificationCreator {

    public abstract Notification create();

}

  

class EmailNotificationCreator extends NotificationCreator { ... }

// Same for SMS, Push

  

class NotificationFactory {

    public static Notification getNotification(String type) { ... }

}

```

  

### 🧠 Hints

- Use `ServiceLoader` or a registration map for pluggability.

- Apply Open-Closed Principle for new notification types.

- Inject via config/environment properties.

  

### ✅ Expected Output

```

Sending email to foo@bar.com

Sending SMS to +91900000000

Sending push notification to deviceId:xyz

```

  


# Factory Pattern Implementation Notes

## Overview
The Factory Pattern is a creational design pattern that provides an interface for creating objects without specifying their exact classes. This implementation demonstrates a notification system using the Simple Factory pattern.

## Pattern Structure

### 1. Product Interface - `Notification.java`
```java
package Patterns.Factory.NotificationSystem;

public interface Notification {
    void send(String to, String msg);
}
```
- Defines the common interface for all notification types
- Single method `send()` for sending notifications

### 2. Concrete Products

#### EmailNotification.java
```java
package Patterns.Factory.NotificationSystem;

public class EmailNotification implements Notification{
    @Override
    public void send(String to, String msg) {
        System.out.println("Sending Email to " + to + ": " + msg);
    }
}
```

#### SMSNotification.java
```java
package Patterns.Factory.NotificationSystem;

public class SMSNotification implements Notification{
    @Override
    public void send(String to, String msg) {
        System.out.println("Sending SMS to " + to + ": " + msg);
    }
}
```

#### PushNotification.java
```java
package Patterns.Factory.NotificationSystem;

public class PushNotification implements Notification{
    @Override
    public void send(String to, String msg) {
        System.out.println("Sending Push to " + to + ": " + msg);
    }
}
```

### 3. Factory Class - `NotificationFactory.java`
```java
package Patterns.Factory.NotificationSystem;

import java.util.Locale;

public class NotificationFactory {
    public static Notification createNotification(String type) {
        return switch (type.toLowerCase()) {
            case "email" -> new EmailNotification();
            case "sms" -> new SMSNotification();
            case "push" -> new PushNotification();
            default -> throw new IllegalStateException("Unexpected notification type: " + type);
        };
    }
}
```
- **Static Factory Method**: Uses static method for object creation
- **Switch Expression**: Modern Java switch expression for cleaner code
- **Case Insensitive**: Converts input to lowercase for consistent matching
- **Error Handling**: Throws exception for unsupported types

### 4. Configuration - `ApplicationConfiguration.java`
```java
package Patterns.Factory.NotificationSystem;

public class ApplicationConfiguration {
    public static final String NOTIFICATION_TYPE = "sms";
}
```
- Centralized configuration for notification type
- Allows easy switching between notification types

### 5. Client/Creator - `NotificationCreator.java`
```java
package Patterns.Factory.NotificationSystem;

public class NotificationCreator {
    private final Notification sender;

    public NotificationCreator() {
        this.sender = NotificationFactory.createNotification(ApplicationConfiguration.NOTIFICATION_TYPE);
    }

    public void send(String to, String msg) {
        this.sender.send(to, msg);
    }
}
```
- **Dependency Injection**: Factory creates the notification object
- **Immutable Reference**: `final` sender field
- **Configuration Driven**: Uses ApplicationConfiguration for type selection

### 6. Main Application - `NotificationSystem.java`
```java
package Patterns.Factory.NotificationSystem;

public class NotificationSystem {
    public static void main(String[] args) {
        NotificationCreator notificationCreator = new NotificationCreator();
        notificationCreator.send("mahir.ratanpara131@gmail.com", "You have been selected!");
    }
}
```

## Analysis & Design Notes

### Strengths
1. **Encapsulation**: Object creation logic is centralized in the factory
2. **Extensibility**: Easy to add new notification types without modifying existing code
3. **Configuration Driven**: Type selection through configuration makes it flexible
4. **Type Safety**: Strong typing through interface implementation
5. **Modern Java**: Uses switch expressions and proper exception handling

### Pattern Variations Demonstrated
- **Simple Factory**: Static method creates objects based on parameters
- **Configuration Factory**: Uses external configuration to determine object type

### Potential Improvements
1. **Factory Method Pattern**: Could be extended to use abstract factory methods
2. **Abstract Factory Pattern**: Could support families of related notification objects
3. **Dependency Injection**: Could use DI framework instead of hardcoded factory calls
4. **Builder Pattern Integration**: Complex notifications could use Builder pattern
5. **Strategy Pattern**: Could combine with Strategy pattern for different sending algorithms

### Usage Scenarios
- **Email Systems**: Different email providers (Gmail, Outlook, etc.)
- **Payment Processing**: Different payment gateways (PayPal, Stripe, etc.)
- **Database Connections**: Different database types (MySQL, PostgreSQL, etc.)
- **File Formats**: Different file exporters (PDF, Excel, CSV, etc.)

### Key Benefits
- **Loose Coupling**: Client doesn't depend on concrete classes
- **Single Responsibility**: Factory handles creation, client handles business logic
- **Open/Closed Principle**: Open for extension, closed for modification
- **Testability**: Easy to mock factory for unit testing

## Current Configuration
- **Active Notification Type**: SMS (as per ApplicationConfiguration.java:4)
- **Supported Types**: email, sms, push
- **Default Behavior**: Throws exception for unsupported types