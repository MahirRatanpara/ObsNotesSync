# Serialization

## Why It Matters

Java's built-in serialization is one of the language's biggest design mistakes and a major security vulnerability class. Knowing *why* — and what to use instead — is a genuine senior signal.

## How It Works

```java
class User implements Serializable {          // marker interface
    private static final long serialVersionUID = 1L;
    private String name;
    private transient String password;         // NOT serialized
}

// Write
try (var out = new ObjectOutputStream(new FileOutputStream("u.ser"))) {
    out.writeObject(user);
}

// Read
try (var in = new ObjectInputStream(new FileInputStream("u.ser"))) {
    User u = (User) in.readObject();
}
```

**Deserialization does not call a constructor.** The JVM allocates the object and populates fields directly. That single fact causes most of the problems below — every invariant your constructor enforces is bypassed.

## serialVersionUID

An identifier for the class's serialized form.

```java
private static final long serialVersionUID = 1L;
```

**If you don't declare it, the compiler generates one from the class structure** — field names, types, method signatures. Adding a method changes it, so old data fails to deserialize with `InvalidClassException`.

**Always declare it explicitly** on any `Serializable` class. Then *you* control compatibility rather than the compiler.

| Change | Compatible? |
|---|---|
| Add a field | **Yes** — new field gets the default value |
| Remove a field | Yes — the value is discarded |
| **Change a field type** | **No** |
| **Rename a field** | **No** — treated as remove + add |
| Change the hierarchy | No |
| Add/remove methods | Yes (with an explicit UID) |

## Why It Is Dangerous

### 1. Remote code execution via gadget chains

**Deserializing untrusted data is remote code execution**, not a theoretical risk.

`readObject` can run arbitrary code. An attacker crafts a byte stream referencing classes already on your classpath whose `readObject`, `finalize` or `hashCode` methods chain together into a **gadget chain** ending in `Runtime.exec`.

**Commons Collections, Spring, Groovy and many others have shipped exploitable gadgets.** Tools like `ysoserial` generate the payloads automatically.

**You do not need to be deserializing an attacker's class** — only classes already present. There is no allowlist by default.

**Real incidents:** the 2015 Apache Commons Collections vulnerability affected WebLogic, WebSphere, JBoss and Jenkins simultaneously. This is why the JDK added deserialization filters.

**Rule: never deserialize untrusted input.** No amount of validation after `readObject` helps, because the damage is done during it.

### 2. It bypasses constructors and invariants

```java
class Age implements Serializable {
    private int value;
    Age(int value) {
        if (value < 0) throw new IllegalArgumentException();   // NEVER RUNS on deserialize
        this.value = value;
    }
}
```

A crafted stream can produce `Age(-5)`. Every constructor check is void.

### 3. It breaks singletons

Deserialization creates a **new instance**, defeating a singleton — unless you implement `readResolve`:

```java
private Object readResolve() { return INSTANCE; }
```

**An `enum` singleton is immune**, because the JVM handles enum deserialization specially. That's one of the strongest arguments for the enum singleton idiom. See [Singleton](../../03%20Low%20Level%20Design/Design%20Patterns/Creational/Singleton.md).

### 4. It cements your class structure

The serialized form becomes part of your public API. Field names, types and the hierarchy can't change freely — private implementation details become a compatibility contract.

### 5. Performance

Java serialization is slow and verbose. It writes class metadata for every type, produces large output, and uses reflection throughout. Protobuf and Avro are several times faster and much smaller.

## The Defences

### Serialization filters (Java 9+)

```java
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(
    "com.myapp.model.*;java.util.*;!*");        // allowlist, reject everything else
ois.setObjectInputFilter(filter);
```

Or globally with `-Djdk.serialFilter=...`. Java 17 added **filter factories** for per-context filters.

**An allowlist ending in `!*` is the only safe configuration.** A denylist is unwinnable — new gadgets are found continuously.

### Custom serialized form

```java
private void writeObject(ObjectOutputStream out) throws IOException {
    out.defaultWriteObject();
    out.writeInt(derivedValue);
}
private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
    in.defaultReadObject();
    if (value < 0) throw new InvalidObjectException("negative");   // re-validate
}
```

**Always re-validate in `readObject`.** It's the only place to restore the invariants your constructor would have enforced.

### The serialization proxy pattern

The safest approach when you must use Java serialization:

```java
class Period implements Serializable {
    private final Date start, end;

    private Object writeReplace() { return new SerializationProxy(this); }

    private void readObject(ObjectInputStream in) throws InvalidObjectException {
        throw new InvalidObjectException("Proxy required");   // block direct deserialization
    }

    private static class SerializationProxy implements Serializable {
        private final Date start, end;
        SerializationProxy(Period p) { this.start = p.start; this.end = p.end; }
        private Object readResolve() { return new Period(start, end); }  // USES THE CONSTRUCTOR
    }
}
```

**`readResolve` calls the real constructor**, so all invariants are enforced and `final` fields work correctly. The `readObject` that throws prevents an attacker bypassing the proxy.

**This is Effective Java's recommended pattern**, and knowing it is a strong signal.

## Use Something Else

| Format | Strengths | Weaknesses |
|---|---|---|
| **JSON** (Jackson, Gson) | Human-readable, universal, schema-optional | Verbose, no schema enforcement, slower |
| **Protobuf** | **Fast, compact, schema-enforced, cross-language** | Requires a schema and codegen |
| **Avro** | Schema evolution built in, compact | Schema registry needed |
| MessagePack / CBOR | Compact binary JSON | Less tooling |
| Kryo | Fast Java-specific | Java-only; **same security concerns** |

**For service-to-service: Protobuf or Avro.** Schema-enforced, versioned, fast, and cross-language.

**For APIs and config: JSON.** Readable and universal.

**Jackson has had its own deserialization vulnerabilities** — polymorphic type handling (`enableDefaultTyping`) is essentially the same gadget-chain problem. **Never enable default typing on untrusted input.** The lesson generalises: *any* deserializer that instantiates types named in the data is dangerous.

## Records and Serialization

Records serialize using their **canonical constructor**, so invariants are enforced automatically and the gadget-chain surface is much smaller.

**Records cannot customise their serialized form** — no `writeObject`/`readObject`. That's a deliberate restriction that makes them safe by construction.

**Another argument for using records as DTOs.**

## The Direction of Travel

**JEP 154 proposed removing Java serialization entirely.** It hasn't happened, but the intent is clear: the JDK team considers it a mistake. Deserialization filters, records' restricted form, and the deprecation of `finalize` all point the same way.

**In an interview: "I'd avoid Java serialization entirely and use Protobuf or JSON"** is the correct answer, with the security reasoning behind it.

## Common Mistakes

- **Deserializing untrusted input** — remote code execution
- No `serialVersionUID`
- No re-validation in `readObject`
- Forgetting `readResolve` on a serializable singleton
- Assuming `transient` fields are secure (they're just absent)
- Jackson default typing on untrusted input
- Treating serialization compatibility as an afterthought
- Using Java serialization for cross-language communication

## Related Topics

- [Java IO and NIO](Java%20IO%20and%20NIO.md)
- [Records Enums and Sealed Types](../OOP/Records%20Enums%20and%20Sealed%20Types.md)
- [Singleton](../../03%20Low%20Level%20Design/Design%20Patterns/Creational/Singleton.md)
- [Immutability and Defensive Copying](../OOP/Immutability%20and%20Defensive%20Copying.md)

## Revision Summary

Java serialization bypasses constructors, so invariants are void and crafted streams can chain existing classes into remote code execution. Always declare `serialVersionUID`, re-validate in `readObject`, and use the serialization proxy pattern if you must. In practice, use Protobuf, Avro or JSON instead — and never deserialize untrusted input in any format that instantiates types named in the data.

## Quick Recall

- **Deserialization does not call the constructor** — invariants bypassed
- **Deserializing untrusted input = RCE** via gadget chains (`ysoserial`)
- Filters must be an **allowlist ending `!*`** — denylists are unwinnable
- Always declare **`serialVersionUID`**; re-validate in `readObject`
- Singletons need **`readResolve`**; **enums are immune**
- **Serialization proxy** routes through the real constructor
- Records use the canonical constructor — safe by construction
- **Jackson default typing has the same problem**
- Prefer **Protobuf/Avro** for services, JSON for APIs
