# Observer Pattern - Quick Revision Guide

## 🎯 One-Line Summary
Define a one-to-many dependency between objects so that when one object changes state, all its dependents are automatically notified and updated.

## 📖 The Problem
**Without Observer**: Tight coupling and polling
- Objects must constantly check (poll) for state changes
- Code is tightly coupled to specific classes
- Hard to add/remove dependencies
- Inefficient (wastes CPU checking when nothing changes)

**With Observer**: Event-driven and decoupled
- Subjects notify observers automatically when state changes
- Observers only updated when needed
- Easy to add/remove observers at runtime
- Loose coupling between subject and observers

## 🔑 Key Concept
```
Subject (Publisher) ←──── Observer (Subscriber)
     │                         ▲
     │ notifyAll()            │
     └─────────────────────────┘
          "Push" updates
```

**Also Known As**: Publish-Subscribe, Event-Listener, Dependents

**Key Participants**:
- **Subject**: Maintains list of observers, sends notifications
- **Observer**: Receives updates from subject
- **ConcreteSubject**: Stores state, notifies when changed
- **ConcreteObserver**: Implements update logic

## ✅ When to Use

| Use When | Don't Use When |
|----------|----------------|
| ✓ One object change affects many | ✗ Simple one-to-one dependency |
| ✓ Don't know how many dependents | ✗ Fixed number of dependents |
| ✓ Objects need to notify others without coupling | ✗ Performance critical (notification overhead) |
| ✓ Need dynamic subscription/unsubscription | ✗ Subscribers never change |

## 📐 Structure

```
┌─────────────┐
│  Subject    │ ◄─── Maintains observers
├─────────────┤
│ +attach()   │
│ +detach()   │
│ +notify()   │
└──────┬──────┘
       │
       │ 1    *  ┌─────────────┐
       └────────►│  Observer   │ ◄─── Interface for observers
                 ├─────────────┤
                 │ +update()   │
                 └──────▲──────┘
                        │
         ┌──────────────┼──────────────┐
         │              │              │
┌────────┴────┐  ┌──────┴──────┐  ┌───┴────────┐
│ConcreteObs1 │  │ConcreteObs2 │  │ConcreteObs3│
├─────────────┤  ├─────────────┤  ├────────────┤
│ +update()   │  │ +update()   │  │ +update()  │
└─────────────┘  └─────────────┘  └────────────┘
```

## 💻 Implementation Pattern

### 1. Observer Interface
```java
public interface Observer {
    void update(String event);
}
```

### 2. Subject Interface
```java
public interface Subject {
    void attach(Observer observer);
    void detach(Observer observer);
    void notifyObservers();
}
```

### 3. Concrete Subject
```java
public class WeatherStation implements Subject {
    private List<Observer> observers = new ArrayList<>();
    private float temperature;
    private float humidity;

    @Override
    public void attach(Observer observer) {
        observers.add(observer);
    }

    @Override
    public void detach(Observer observer) {
        observers.remove(observer);
    }

    @Override
    public void notifyObservers() {
        for (Observer observer : observers) {
            observer.update("Temperature: " + temperature + ", Humidity: " + humidity);
        }
    }

    public void setMeasurements(float temperature, float humidity) {
        this.temperature = temperature;
        this.humidity = humidity;
        notifyObservers();  // Notify on state change
    }

    // Getters for pull model
    public float getTemperature() { return temperature; }
    public float getHumidity() { return humidity; }
}
```

### 4. Concrete Observers
```java
public class PhoneDisplay implements Observer {
    private String name;

    public PhoneDisplay(String name) {
        this.name = name;
    }

    @Override
    public void update(String event) {
        System.out.println(name + " received: " + event);
    }
}

public class TVDisplay implements Observer {
    @Override
    public void update(String event) {
        System.out.println("TV Display: " + event);
    }
}
```

### 5. Usage
```java
// Create subject
WeatherStation station = new WeatherStation();

// Create observers
Observer phone = new PhoneDisplay("iPhone");
Observer tv = new TVDisplay();

// Subscribe observers
station.attach(phone);
station.attach(tv);

// Change state → automatic notification
station.setMeasurements(25.5f, 65.0f);
// Output:
// iPhone received: Temperature: 25.5, Humidity: 65.0
// TV Display: Temperature: 25.5, Humidity: 65.0

// Unsubscribe
station.detach(phone);

// Only TV notified now
station.setMeasurements(26.0f, 70.0f);
// Output:
// TV Display: Temperature: 26.0, Humidity: 70.0
```

## 🎓 Real-World Examples

| Domain | Subject | Observers |
|--------|---------|-----------|
| **GUI** | Button | Click listeners |
| **MVC** | Model | View components |
| **Messaging** | Message broker | Subscribers |
| **Stock Market** | Stock | Traders, dashboards |
| **Social Media** | User | Followers |
| **Java** | Observable | Observer (deprecated) |

### Java Built-in Observer (Pre-Java 9)
```java
import java.util.Observable;
import java.util.Observer;

// Subject
class Stock extends Observable {
    private double price;

    public void setPrice(double price) {
        this.price = price;
        setChanged();          // Mark as changed
        notifyObservers(price); // Notify with data
    }
}

// Observer
class Trader implements Observer {
    public void update(Observable o, Object arg) {
        System.out.println("Stock price: " + arg);
    }
}

// Usage
Stock stock = new Stock();
Trader trader = new Trader();
stock.addObserver(trader);
stock.setPrice(150.50);  // Trader notified
```

**Note**: `Observable` deprecated in Java 9 (not serializable, not thread-safe)

## 🔄 Push vs Pull Model

### Push Model
```java
// Subject pushes all data to observers
interface Observer {
    void update(float temp, float humidity, float pressure);
}

subject.notifyObservers(temp, humidity, pressure);
```
- ✅ Observers get all data
- ❌ May send unnecessary data
- ❌ Changes to subject data require observer interface changes

### Pull Model
```java
// Subject just notifies, observers pull what they need
interface Observer {
    void update(Subject subject);
}

public void update(Subject subject) {
    WeatherStation station = (WeatherStation) subject;
    float temp = station.getTemperature();  // Pull only what's needed
}
```
- ✅ Observers pull only needed data
- ✅ More flexible
- ❌ Observers need reference to subject

**Best Practice**: Use pull model for flexibility.

## ⚖️ Observer vs Similar Patterns

| Pattern | Intent | Key Difference |
|---------|--------|----------------|
| **Observer** | One-to-many notification | Automatic push/pull updates |
| **Mediator** | Centralized communication | Many-to-many via mediator |
| **Publisher-Subscribe** | Decoupled messaging | Indirect (via message queue) |
| **Event Bus** | Global event distribution | Central event dispatcher |

### Observer vs Mediator
```java
// Observer: Direct notification
Subject → Observer1, Observer2, Observer3

// Mediator: Indirect via mediator
Component1 → Mediator → Component2, Component3
```

## 🚨 Common Mistakes

### ❌ Mistake 1: Memory leaks from unremoved observers
```java
// Wrong: Observer never removed
Observer obs = new PhoneDisplay();
subject.attach(obs);
obs = null;  // ❌ Object eligible for GC but subject still holds reference!

// Right: Detach before discarding
Observer obs = new PhoneDisplay();
subject.attach(obs);
subject.detach(obs);  // ✅ Explicitly remove
obs = null;
```

### ❌ Mistake 2: Notifying during state change
```java
// Wrong: Observers see inconsistent state
public void update(float temp, float pressure) {
    this.temp = temp;
    notifyObservers();     // ❌ Pressure not set yet!
    this.pressure = pressure;
}

// Right: Notify after all changes
public void update(float temp, float pressure) {
    this.temp = temp;
    this.pressure = pressure;
    notifyObservers();     // ✅ Consistent state
}
```

### ❌ Mistake 3: Observer modifies subject during update
```java
// Wrong: Causes infinite loop or inconsistency
public void update(Subject subject) {
    subject.setState(newValue);  // ❌ Triggers notify → update → notify...
}

// Right: Don't modify subject in update
public void update(Subject subject) {
    // Only read and react, don't modify subject
    displayState(subject.getState());
}
```

### ❌ Mistake 4: Non-thread-safe implementation
```java
// Wrong: Race condition
private List<Observer> observers = new ArrayList<>();  // ❌ Not thread-safe

// Right: Thread-safe collection
private List<Observer> observers = new CopyOnWriteArrayList<>();  // ✅
// Or synchronize access
```

### ❌ Mistake 5: Update order dependency
```java
// Wrong: Observers depend on notification order
// Observer1 must run before Observer2
observers.add(observer1);
observers.add(observer2);  // ❌ Fragile!

// Right: Observers should be independent
// Each observer should handle updates independently
```

## 🎤 Interview Questions & Answers

### Q1: What is the Observer pattern?
**A**: A behavioral pattern that defines a one-to-many dependency where when one object (subject) changes state, all dependent objects (observers) are automatically notified and updated.

### Q2: When would you use Observer?
**A**: When:
1. Change to one object requires changing others
2. Don't know how many objects need to be updated
3. Objects should be loosely coupled
4. Need dynamic subscription at runtime

### Q3: What are the key components?
**A**:
1. **Subject**: Maintains observers, sends notifications
2. **Observer**: Interface for receiving updates
3. **ConcreteSubject**: Stores state, triggers notifications
4. **ConcreteObserver**: Implements update logic

### Q4: Push vs Pull model?
**A**:
- **Push**: Subject sends all data to observers (`update(data)`)
- **Pull**: Subject just notifies, observers pull data they need (`update(subject)`)
- **Preference**: Pull is more flexible

### Q5: What are the main problems with Observer?
**A**:
1. **Memory leaks**: Observers not removed keep objects in memory
2. **Unexpected updates**: Cascade of updates can be hard to trace
3. **Update order**: No guaranteed order of notification
4. **Performance**: Many observers = many notifications

### Q6: How do you prevent memory leaks?
**A**:
1. Always `detach()` observers when done
2. Use weak references: `WeakHashMap<Observer, ...>`
3. Implement auto-cleanup (dispose pattern)
4. Use framework lifecycle (Android `LiveData`, RxJava)

### Q7: Observer vs Pub-Sub?
**A**:
- **Observer**: Subject knows observers (direct)
- **Pub-Sub**: Publishers and subscribers don't know each other (via message broker)
- **Observer**: Synchronous
- **Pub-Sub**: Can be asynchronous

### Q8: Real-world example?
**A**:
- **Java Swing**: `button.addActionListener(listener)`
- **Android**: `LiveData.observe(observer)`
- **JavaScript**: `element.addEventListener('click', handler)`
- **MVC**: Model notifies View on data changes

### Q9: How to make it thread-safe?
**A**:
1. Use thread-safe collections: `CopyOnWriteArrayList`
2. Synchronize notification: `synchronized(observers) { ... }`
3. Snapshot observers before notifying
4. Use immutable state

### Q10: What if observer throws exception?
**A**: Wrap in try-catch to prevent one bad observer from stopping others:
```java
public void notifyObservers() {
    for (Observer obs : observers) {
        try {
            obs.update(this);
        } catch (Exception e) {
            // Log and continue
            logger.error("Observer failed", e);
        }
    }
}
```

## ✨ Key Takeaways

| Concept | Remember |
|---------|----------|
| **Purpose** | Automatic notification of dependent objects |
| **Relationship** | One-to-many (one subject, many observers) |
| **Coupling** | Loose (subject doesn't know concrete observers) |
| **Registration** | Dynamic (attach/detach at runtime) |
| **Models** | Push (send data) vs Pull (observers fetch) |
| **Risk** | Memory leaks if observers not removed |

## 🔍 Quick Checklist

When implementing Observer pattern:
- [ ] Define Observer interface with `update()` method
- [ ] Define Subject interface with `attach()`, `detach()`, `notify()`
- [ ] Implement ConcreteSubject with observer list
- [ ] Call `notifyObservers()` when state changes
- [ ] Implement ConcreteObservers with update logic
- [ ] Ensure observers are removed to prevent memory leaks
- [ ] Consider thread-safety if multi-threaded
- [ ] Decide push vs pull model
- [ ] Handle exceptions in observer updates
- [ ] Avoid observer modifying subject during update

## 📊 Pattern Template

```java
// 1. Observer Interface
interface Observer {
    void update(Subject subject);
}

// 2. Subject Interface
interface Subject {
    void attach(Observer obs);
    void detach(Observer obs);
    void notifyObservers();
}

// 3. Concrete Subject
class ConcreteSubject implements Subject {
    private List<Observer> observers = new ArrayList<>();
    private State state;

    public void attach(Observer obs) { observers.add(obs); }
    public void detach(Observer obs) { observers.remove(obs); }

    public void notifyObservers() {
        for (Observer obs : observers) {
            obs.update(this);
        }
    }

    public void setState(State state) {
        this.state = state;
        notifyObservers();
    }

    public State getState() { return state; }
}

// 4. Concrete Observer
class ConcreteObserver implements Observer {
    public void update(Subject subject) {
        State state = ((ConcreteSubject) subject).getState();
        // React to state change
    }
}

// 5. Usage
Subject subject = new ConcreteSubject();
Observer obs1 = new ConcreteObserver();
subject.attach(obs1);
((ConcreteSubject) subject).setState(newState);  // obs1 notified
```

## 💡 Remember
> "Observer is like a newsletter subscription: when new content (state) is published, all subscribers (observers) are automatically notified."

## 🔧 Modern Alternatives

### Java
- **PropertyChangeListener** (JavaBeans)
- **EventBus** (Guava, GreenRobot)
- **RxJava** (Reactive Extensions)
- **Reactor** (Project Reactor)

### Example: RxJava (Reactive)
```java
Observable<String> observable = Observable.just("Event1", "Event2");

observable.subscribe(
    event -> System.out.println("Received: " + event),
    error -> System.err.println("Error: " + error),
    () -> System.out.println("Complete")
);
```

---

**For Amazon Interviews**: Focus on **one-to-many notification** (why), **decoupling** subjects and observers (how), **memory leaks** (pitfall), and **push vs pull** models. Be ready to discuss thread-safety and real-world applications like GUI event listeners or MVC.
