# Builder Pattern - Interview Follow-Up Questions & Answers

## Question 1: Performance Concern - Defensive Copies in Getters

### Problem Statement
Your getters create a new `HashMap` on every call. If someone calls `getHeaders()` 1000 times in a loop, you create 1000 objects. Is this acceptable? How would you optimize this while maintaining immutability?

### Answer

**Is it acceptable?**
- For most use cases: **YES** - The overhead is negligible
- For high-frequency access in tight loops: **Consider optimization**
- Always **measure first** before optimizing (premature optimization is the root of all evil)

### Optimization Approach: Lazy Immutable Wrapping

Instead of creating copies on every call, wrap the map once with `Collections.unmodifiableMap()`:

```java
public class HttpRequest {
    private final Map<String, String> headers;
    private final Map<String, String> queryParams;

    private HttpRequest(Builder builder) {
        // Defensive copy + make unmodifiable
        this.headers = builder.headers == null ? null :
            Collections.unmodifiableMap(new HashMap<>(builder.headers));
        this.queryParams = builder.queryParams == null ? null :
            Collections.unmodifiableMap(new HashMap<>(builder.queryParams));
        // ... rest of initialization
    }

    public Map<String, String> getHeaders() {
        return headers;  // Already unmodifiable, safe to return directly
    }

    public Map<String, String> getQueryParams() {
        return queryParams;  // Already unmodifiable, safe to return directly
    }
}
```

### Trade-offs:

| Approach | Pros | Cons |
|----------|------|------|
| **Defensive copy on every get** (current) | Simple, truly immutable | Creates objects on every call |
| **UnmodifiableMap wrapper** | No object creation per call, O(1) | Throws exception if modified (not always ideal) |
| **Both** (copy + wrap) | Best immutability guarantee | Slight memory overhead for wrapper |

### Best Practice for Production:
Use `Collections.unmodifiableMap(new HashMap<>(builder.headers))` - it's the sweet spot between performance and safety.

---

## Question 2: API Extension - Bulk Operations

### Problem Statement
How would you add support for **bulk operations** (e.g., `.headers(Map<String, String>)`) alongside the existing `.addHeader()` method? Should it replace or merge with existing headers?

### Answer

**Design Decision: Should bulk operations replace or merge?**
- **Replace**: Clearer semantics, less surprising behavior
- **Merge**: More flexible, but can lead to bugs

**Recommendation: Support BOTH with clear naming**

```java
static class Builder {
    private Map<String, String> headers;
    private Map<String, String> queryParams;

    // Individual add - MERGES
    public Builder addHeader(String headerName, String headerValue) {
        if (this.headers == null) this.headers = new HashMap<>();
        this.headers.put(headerName, headerValue);
        return this;
    }

    // Bulk add - MERGES (additive)
    public Builder addHeaders(Map<String, String> headers) {
        if (headers == null) return this;
        if (this.headers == null) this.headers = new HashMap<>();
        this.headers.putAll(headers);  // Merge
        return this;
    }

    // Bulk set - REPLACES (destructive)
    public Builder setHeaders(Map<String, String> headers) {
        this.headers = headers == null ? null : new HashMap<>(headers);
        return this;
    }

    // Same pattern for query params
    public Builder addQueryParam(String name, String value) { /*...*/ }
    public Builder addQueryParams(Map<String, String> params) { /*...*/ }
    public Builder setQueryParams(Map<String, String> params) { /*...*/ }
}
```

### Naming Convention:
- `add*` (singular) → Add one item
- `add*s` (plural) → Add multiple items (merge)
- `set*s` → Replace all items

### Example Usage:
```java
Map<String, String> defaultHeaders = Map.of("Accept", "application/json");

HttpRequest request = new HttpRequest.Builder()
    .setHeaders(defaultHeaders)           // Replace: only "Accept" header
    .addHeader("Authorization", "Bearer token")  // Merge: now 2 headers
    .addHeaders(Map.of("X-Custom", "value"))     // Merge: now 3 headers
    .build();
```

---

## Question 3: Thread Safety of Builder

### Problem Statement
Is the `Builder` class thread-safe? Should it be? What would happen if two threads call `addHeader()` concurrently on the same builder instance?

### Answer

**Is it thread-safe?**
**NO** - The current implementation is NOT thread-safe.

**What happens with concurrent access?**
```java
Builder builder = new HttpRequest.Builder();

// Thread 1
builder.addHeader("Auth", "token1");

// Thread 2 (concurrent)
builder.addHeader("Content-Type", "json");
```

**Potential issues:**
1. **Lost updates** - HashMap is not thread-safe, concurrent puts can corrupt internal structure
2. **Race conditions** - `if (headers == null)` check can happen twice
3. **Visibility issues** - Changes in one thread may not be visible to another

**Should it be thread-safe?**
**NO** - Builders are typically **NOT** designed for thread safety because:
1. Builders are usually **short-lived, local objects** used in a single thread
2. Making them thread-safe adds unnecessary overhead
3. The Builder pattern implies **construction in progress** - sharing under construction objects across threads is poor design

### Recommended Approach:

**Document the contract:**
```java
/**
 * Builder for constructing HttpRequest objects.
 *
 * <p><b>Thread Safety:</b> This builder is NOT thread-safe.
 * Each thread should use its own builder instance.
 * The built HttpRequest object is immutable and thread-safe.
 */
static class Builder {
    // ...
}
```

### If Thread Safety is Required:

**Option 1: Synchronize methods**
```java
public synchronized Builder addHeader(String name, String value) {
    if (this.headers == null) this.headers = new HashMap<>();
    this.headers.put(name, value);
    return this;
}
```

**Option 2: Use ConcurrentHashMap**
```java
private Map<String, String> headers = new ConcurrentHashMap<>();

public Builder addHeader(String name, String value) {
    this.headers.put(name, value);
    return this;
}
```

**Option 3: ThreadLocal Builder (if needed)**
```java
private static final ThreadLocal<Builder> BUILDER =
    ThreadLocal.withInitial(Builder::new);
```

### Amazon Interview Answer:
> "Builders are not typically thread-safe by design. They're meant to be used within a single thread's scope to construct an object. The final HttpRequest object is immutable and therefore thread-safe. If we needed to build requests concurrently, each thread should have its own Builder instance. Making the Builder thread-safe would add unnecessary synchronization overhead for the common case."

---

## Question 4: Enhanced Validation

### Problem Statement
Currently, you only validate that method/url are non-null. What other validations might be important?

### Answer

### Important Validations:

```java
private HttpRequest(Builder builder) {
    // 1. Required field validation
    if (builder.method == null) {
        throw new IllegalStateException("HTTP method is required");
    }
    if (builder.url == null || builder.url.trim().isEmpty()) {
        throw new IllegalStateException("URL is required and cannot be empty");
    }

    // 2. URL format validation
    if (!isValidUrl(builder.url)) {
        throw new IllegalStateException("Invalid URL format: " + builder.url);
    }

    // 3. Timeout validation
    if (builder.timeout <= 0) {
        throw new IllegalStateException("Timeout must be positive, got: " + builder.timeout);
    }

    // 4. Method-specific validation
    if ((builder.method == HttpMethods.GET || builder.method == HttpMethods.DELETE)
        && builder.body != null) {
        throw new IllegalStateException("GET/DELETE requests cannot have a body");
    }

    // 5. Body validation for POST/PUT
    if ((builder.method == HttpMethods.POST || builder.method == HttpMethods.PUT)) {
        if (builder.body == null || builder.body.isEmpty()) {
            // Warning or error depending on requirements
            // Could be lenient and allow empty body
        }
    }

    // Copy fields after validation
    this.method = builder.method;
    this.url = builder.url;
    this.body = builder.body;
    this.headers = makeDefensiveCopy(builder.headers);
    this.queryParams = makeDefensiveCopy(builder.queryParams);
    this.timeout = builder.timeout;
}

private boolean isValidUrl(String url) {
    try {
        new java.net.URL(url);
        return true;
    } catch (java.net.MalformedURLException e) {
        return false;
    }
}
```

### Validation Categories:

| Category | Examples | When to Apply |
|----------|----------|---------------|
| **Null checks** | method != null, url != null | Always |
| **Empty checks** | url.trim().isEmpty() | For strings |
| **Format validation** | URL syntax, JSON body | Domain-specific |
| **Range validation** | timeout > 0, timeout < MAX | Numeric fields |
| **Business rules** | GET has no body | Domain logic |
| **Cross-field validation** | If auth header, require HTTPS | Complex rules |

### Trade-off: Fail-Fast vs Lenient

**Fail-Fast (Strict Validation):**
```java
// Pros: Catches errors early, clearer contract
// Cons: Less flexible, may reject valid edge cases
if (timeout <= 0) throw new IllegalStateException("...");
```

**Lenient (Permissive):**
```java
// Pros: More flexible, handles edge cases
// Cons: Errors surface later, harder to debug
if (timeout <= 0) timeout = 30;  // Use default
```

### Best Practice:
- **Fail-fast for required fields** (method, url)
- **Lenient for optional fields** with sensible defaults
- **Validate format** when it affects correctness (URL syntax)
- **Document validation rules** in JavaDoc

### Example with Better Error Messages:

```java
private void validate() {
    StringBuilder errors = new StringBuilder();

    if (method == null) {
        errors.append("- HTTP method is required\n");
    }
    if (url == null || url.trim().isEmpty()) {
        errors.append("- URL is required\n");
    } else if (!isValidUrl(url)) {
        errors.append("- Invalid URL format: ").append(url).append("\n");
    }
    if (timeout <= 0) {
        errors.append("- Timeout must be positive, got: ").append(timeout).append("\n");
    }

    if (errors.length() > 0) {
        throw new IllegalStateException("Invalid HttpRequest:\n" + errors.toString());
    }
}
```

---

## Key Interview Takeaways

### What Interviewers Look For:

1. **Understanding Trade-offs**: Every design decision has pros/cons
2. **Performance Awareness**: Know when optimization matters
3. **Thread Safety**: Understand concurrency implications
4. **API Design**: Clear, predictable, hard to misuse
5. **Validation Strategy**: Balance strictness and usability
6. **Production Thinking**: Documentation, error messages, edge cases

### Strong Interview Answers Include:
- ✅ "It depends on the use case..."
- ✅ "The trade-off here is..."
- ✅ "I would measure first before optimizing..."
- ✅ "For production, I would also consider..."
- ✅ Concrete code examples
- ✅ Discussing edge cases

### Weak Interview Answers:
- ❌ "This is the only way to do it"
- ❌ "Performance doesn't matter"
- ❌ "I would make everything thread-safe"
- ❌ Ignoring trade-offs
- ❌ Over-engineering simple problems

---

## Further Reading

- **Effective Java (3rd Edition)** by Joshua Bloch - Item 2: "Consider a builder when faced with many constructor parameters"
- **Java Concurrency in Practice** - Chapter on thread safety and immutability
- **Clean Code** by Robert Martin - Chapter on meaningful names and error handling
