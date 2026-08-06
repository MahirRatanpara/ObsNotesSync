# Observer

## Why It Matters

The foundation of event-driven design, from UI listeners to pub-sub messaging. Every "notify multiple systems when X happens" requirement is Observer.

## Core Idea

A subject maintains a list of observers and notifies them all when its state changes. Subject and observers are decoupled — the subject knows only the interface.

```java
interface OrderObserver { void onOrderPlaced(Order order); }

class OrderService {
    private final List<OrderObserver> observers = new CopyOnWriteArrayList<>();

    public void subscribe(OrderObserver o)   { observers.add(o); }
    public void unsubscribe(OrderObserver o) { observers.remove(o); }

    public void placeOrder(Order order) {
        save(order);
        for (OrderObserver o : observers) {
            try { o.onOrderPlaced(order); }
            catch (Exception e) { log.error("observer failed", e); }   // isolate failures
        }
    }
}
```

**Two details interviewers look for:**

1. **`CopyOnWriteArrayList`** — observers commonly unsubscribe *during* notification, which would throw `ConcurrentModificationException` on a plain list. This is the textbook use case for a copy-on-write collection.
2. **Exception isolation** — one failing observer must not prevent the rest from being notified, nor break the subject.

## Push vs Pull

| | Push | Pull |
|---|---|---|
| Subject sends | The changed data | Just a notification |
| Observer then | Uses it directly | Queries the subject for what it needs |
| Coupling | Higher (subject decides what's relevant) | Lower |
| Efficiency | Wasteful if observers need different data | Extra round trip |

Push is simpler and usually right for a small, well-known payload. Pull suits observers with diverse needs.

## Synchronous vs Asynchronous

**Synchronous** (as above) is simple but: the subject's latency becomes the sum of all observers, and a slow observer blocks the business operation.

**Asynchronous** — publish to a queue or executor:

```java
observers.forEach(o -> executor.submit(() -> o.onOrderPlaced(order)));
```

Decouples latency, but you lose ordering guarantees and error visibility. At service boundaries this becomes a message broker — Observer scaled out is pub-sub ([Kafka](../../../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md) consumer groups are the distributed form).

## The Memory Leak

**The single most important practical point.** A subject holds strong references to observers. If an observer is never unsubscribed, it can never be garbage collected — and neither can anything it references.

Classic in long-lived services and UI code. Mitigations:
- Always unsubscribe in a `close()` / lifecycle hook
- `WeakReference`-based registries
- Scoped subscriptions returned as an `AutoCloseable`

```java
try (Subscription s = service.subscribe(observer)) { ... }   // auto-unsubscribes
```

## Why `java.util.Observer` Was Deprecated

Deprecated in Java 9 because: it isn't thread-safe, `Observable` is a **class** (so you must extend it, burning your single inheritance), it offers no ordering guarantees, and it can't be serialised usefully. **Use your own interface, `PropertyChangeListener`, or a reactive library.** Knowing why it was deprecated is a good signal.

## Real Uses

- Swing/Android UI listeners
- Spring `ApplicationEvent` and `@EventListener`
- Reactive streams (`Publisher`/`Subscriber`) — Observer plus backpressure
- Kafka consumer groups — the distributed form
- Model-View architectures

## When To Use

- One change must trigger several independent reactions
- The set of reactors changes at runtime
- You want the subject unaware of who's listening

## Limitations

- **Memory leaks** from missed unsubscribes
- Notification order is generally unspecified — don't build logic on it
- Cascading updates can be hard to trace and can cycle
- Debugging is harder: control flow is implicit

## Common Questions

- *Push vs pull?* — send data vs send a signal and let observers query.
- *How do you avoid the memory leak?* — explicit unsubscribe, weak references, or scoped subscriptions.
- *Why was `java.util.Observer` deprecated?* — not thread-safe, class not interface, no ordering.
- *How does it become pub-sub?* — asynchronous notification across a broker.
- *Which collection for the observer list?* — `CopyOnWriteArrayList`.

## Common Mistakes

- Plain `ArrayList`, then `ConcurrentModificationException` on unsubscribe-during-notify
- One observer's exception aborting the whole notification
- Relying on notification order
- Never unsubscribing
- Doing slow work synchronously in an observer

## Related Topics

- [Mediator](Mediator.md)
- [Concurrent Collections](../../../02%20Java/Concurrency/Concurrent%20Collections.md)
- [Kafka Deep Dive](../../../07%20Messaging%20and%20Kafka/Kafka/Kafka%20Deep%20Dive.md)

## Revision Summary

Subject notifies a registered list of observers on state change. Use `CopyOnWriteArrayList` and isolate observer exceptions. The main hazard is the memory leak from missed unsubscribes. Asynchronous Observer across services is pub-sub.

## Quick Recall

- `CopyOnWriteArrayList` for the observer list
- Isolate each observer's exceptions
- Unsubscribe or leak
- Push = send data; pull = send a signal
- `java.util.Observer` deprecated in Java 9
