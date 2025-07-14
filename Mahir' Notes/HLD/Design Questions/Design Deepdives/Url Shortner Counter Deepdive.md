
# 🌐 URL Shortener Design Notes

## 🧠 Overview

Designing a URL shortener involves generating **unique, compact, URL-safe identifiers** for long URLs. This document covers:

- Unique ID generation using Redis or random values
- How Zookeeper can help
- Base62 encoding
- Restricting the short URL length
- Encoding numbers into short URLs

---

## 🔢 Unique ID Generation

### ✅ Option 1: Sequential ID with Redis
Use Redis' atomic `INCR` command:
```bash
INCR url_id_counter  # returns: 125
```
Each call returns a unique, increasing number.

### ✅ Option 2: Random ID with Cache Check
1. Generate a random Base62 string (e.g., 6 characters)
2. Check Redis or DB for existence
3. Retry if collision is found

⚠️ **Note**: As usage increases, collisions increase → retry logic becomes essential.

---

## 🛠️ Zookeeper in URL Shortener

### When to Use:
- **Distributed ID Coordination**: Assign ID ranges (e.g., Node A = 1–1M, Node B = 1M–2M)
- **Leader Election**: Single master generates global IDs
- **Dynamic Configuration Management**

Zookeeper is useful in **multi-node**, **high-availability** setups.

---

## 🔡 Base62 Encoding

### Why Base62?
- Uses digits, uppercase, lowercase: `0-9A-Za-z`
- URL-safe (no `/`, `+`, etc.)
- Compact representation

### Base62 Character Set
```
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
```

### Total Permutations by Length

| Length | Total Short URLs (Base62^n) |
|--------|-----------------------------|
| 5      | ~916 million                |
| 6      | ~57 billion                 |
| 7      | ~3.5 trillion               |

---

## 🔗 Converting Redis Number to Short URL

### Java Code (Base62 Encode)

```java
private static final String BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

public String encodeToBase62(long num) {
    StringBuilder sb = new StringBuilder();
    while (num > 0) {
        int remainder = (int)(num % 62);
        sb.append(BASE62.charAt(remainder));
        num /= 62;
    }
    return sb.reverse().toString(); // Important: reverse it!
}
```

### Padding to Fixed Length (e.g., 6 characters)
```java
String code = encodeToBase62(redisId);
code = String.format("%6s", code).replace(' ', '0'); // Pads with '0'
```

### Reverse Decode (Optional)
```java
public long decodeFromBase62(String shortCode) {
    long result = 0;
    for (char c : shortCode.toCharArray()) {
        result = result * 62 + BASE62.indexOf(c);
    }
    return result;
}
```

---

## 🔗 Final URL Construction

```text
short.ly/000021   ← domain + short code
```

---

## ✅ Summary

| Concept                  | Details                                                      |
|--------------------------|--------------------------------------------------------------|
| **ID Generation**        | Redis INCR (atomic), or random+check with cache              |
| **Zookeeper**            | Useful for ID sharding, leader election in distributed setup |
| **Encoding**             | Base62 for compact, URL-safe encoding                        |
| **Fixed Length**         | Use padding or reserved ID ranges for uniform code length    |
| **Base62 Possibilities** | 6 characters → ~57 billion combinations                      |

---

## ✅ Optional Enhancements

- Use **Bloom Filter** to reduce DB/collision checks
- Add **expiration** for temporary URLs
- Track **analytics** (click count, geolocation)
- Custom aliases (e.g., `short.ly/mycode`)

---
