# 🚀 Caching Strategies - Complete System Design Guide

> **"There are only two hard things in Computer Science: cache invalidation and naming things" - Phil Karlton**

---

## 🎯 Table of Contents

1. [Caching Fundamentals](#-caching-fundamentals)
2. [Types of Caching](#-types-of-caching)  
3. [Caching Patterns](#-caching-patterns)
4. [Eviction Policies](#-eviction-policies)
5. [Distributed Caching](#-distributed-caching)
6. [Interview Questions](#-interview-questions)
7. [Best Practices](#-best-practices)

---

## 🔍 Caching Fundamentals

### **What is Caching?** #fundamental

**Definition:** Storing frequently accessed data in fast-access memory to reduce latency and improve performance.

**Key Principle:** **Locality of Reference**
- **Temporal Locality:** Recently accessed data likely to be accessed again
- **Spatial Locality:** Data near recently accessed data likely to be accessed

### **Why Caching Works** 📈

**The 80-20 Rule:** 80% of requests access 20% of the data
- Cache this 20% → Massive performance improvement
- Example: Product catalog - popular items accessed far more than niche items

### **Cache Performance Metrics** 📊

| **Metric** | **Formula** | **Good Target** |
|------------|-------------|-----------------|
| **Hit Ratio** | Cache Hits / Total Requests | > 90% |
| **Miss Ratio** | Cache Misses / Total Requests | < 10% |
| **Hit Time** | Time to serve from cache | < 1ms |
| **Miss Penalty** | Additional time on cache miss | Minimize this |

---

## 🏗️ Types of Caching

### **1. Client-Side Cache** 💻

**Location:** User's device/browser
**Use Cases:** Static assets, API responses, computed results

**Examples:**
- **Browser Cache:** HTML, CSS, JavaScript, images
- **Mobile App Cache:** User profile, frequently viewed content
- **CDN Edge Cache:** Geographically distributed static content

**Pros & Cons:**
```
✅ Fastest possible access time
✅ Reduces server load
✅ Works offline
❌ Data freshness issues
❌ Limited storage capacity
❌ User can clear cache
```

### **2. CDN (Content Delivery Network)** 🌍

**Location:** Geographically distributed edge servers
**Use Cases:** Static assets, images, videos, API responses

**How it Works:**
```
User (NY) → CDN Edge (NY) → Origin Server (CA)
              ↓ CACHE HIT
         Serve from NY cache
```

**Popular CDNs:** CloudFlare, AWS CloudFront, Fastly, Azure CDN

**Configuration Example:**
```nginx
# Cache static assets for 1 year
location ~* \.(jpg|jpeg|png|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Cache API responses for 5 minutes
location /api/products {
    proxy_cache_valid 200 5m;
    add_header X-Cache-Status $upstream_cache_status;
}
```

### **3. Load Balancer Caching** ⚖️

**Location:** Between client and application servers
**Use Cases:** Response caching, SSL termination, compression

**Benefits:**
- Reduces backend server load
- Faster response times for repeated requests
- Can handle cache invalidation at edge

### **4. Application-Level Cache** 🖥️

**Location:** Within application server memory or dedicated cache servers
**Use Cases:** Database query results, computed values, session data

**Technologies:**
- **In-Memory:** Redis, Memcached
- **Application Cache:** Caffeine (Java), Guava Cache
- **Database Cache:** MySQL Query Cache, PostgreSQL Buffer

---

## 🔄 Caching Patterns

### **1. Cache-Aside (Lazy Loading)** #cache-aside

**Flow:**
```
1. Application checks cache
2. If MISS → Fetch from database  
3. Store result in cache
4. Return to client
```

**Implementation:**
```java
public User getUser(String userId) {
    // 1. Check cache first
    User user = cache.get("user:" + userId);
    
    if (user != null) {
        return user; // Cache HIT
    }
    
    // 2. Cache MISS - fetch from DB
    user = database.getUserById(userId);
    
    // 3. Store in cache with TTL
    if (user != null) {
        cache.setex("user:" + userId, 3600, user); // 1 hour TTL
    }
    
    return user;
}
```

**When to Use:**
- ✅ Read-heavy workloads
- ✅ Data doesn't change frequently  
- ✅ Cache failures shouldn't break the system

**Trade-offs:**
```
✅ Simple to implement
✅ Cache failures don't break app (fallback to DB)
✅ Cache only what's needed
❌ Cache miss penalty (database round-trip)
❌ Stale data possible
❌ Manual cache management
```

### **2. Write-Through Cache** #write-through

**Flow:**
```
1. Application writes to cache
2. Cache synchronously writes to database
3. Both cache and DB updated before response
```

**Implementation:**
```java
public void updateUser(User user) {
    // Write to cache first
    cache.set("user:" + user.getId(), user);
    
    // Synchronously write to database
    database.updateUser(user);
    
    // Both operations must succeed
}
```

**When to Use:**
- ✅ Strong consistency requirements
- ✅ Read-after-write scenarios
- ✅ Critical data that must be consistent

**Trade-offs:**
```
✅ Cache and DB always consistent
✅ Read-after-write always returns fresh data
❌ Higher write latency (2 operations)
❌ Cache must implement database writes
❌ Write operation fails if DB is down
```

### **3. Write-Behind (Write-Back) Cache** #write-behind

**Flow:**
```  
1. Application writes to cache only
2. Cache asynchronously writes to database later
3. Return immediately after cache write
```

**Implementation:**
```java
public void updateUser(User user) {
    // 1. Write to cache immediately
    cache.set("user:" + user.getId(), user);
    
    // 2. Queue for async DB write
    writeQueue.add(new DatabaseWrite("users", user));
    
    // 3. Return immediately - don't wait for DB
}

// Background process
private void processWriteQueue() {
    while (true) {
        DatabaseWrite write = writeQueue.poll();
        if (write != null) {
            database.write(write);
        }
    }
}
```

**When to Use:**
- ✅ High write throughput requirements
- ✅ Write latency is critical  
- ✅ Can tolerate eventual consistency

**Trade-offs:**
```
✅ Very low write latency
✅ Can batch writes for efficiency
✅ Reduces database write load
❌ Risk of data loss if cache fails
❌ Complex error handling and recovery
❌ Eventual consistency only
```

### **4. Write-Around Cache** #write-around

**Flow:**
```
1. Writes go directly to database
2. Cache is invalidated/ignored on writes  
3. Reads check cache first, fallback to DB
```

**Implementation:**
```java
public void updateUser(User user) {
    // 1. Write directly to database
    database.updateUser(user);
    
    // 2. Invalidate cache entry
    cache.delete("user:" + user.getId());
}

public User getUser(String userId) {
    // Read flow same as cache-aside
    return cacheAsideGet(userId);
}
```

**When to Use:**
- ✅ Write-once, read-many workloads
- ✅ Large datasets that don't fit in cache
- ✅ Write frequency is low

---

## 🔄 Eviction Policies

### **Common Eviction Algorithms**

#### **LRU (Least Recently Used)** #lru
**Logic:** Remove item that was accessed longest time ago
**Use Case:** General-purpose caching, web browsers
**Implementation:** Doubly-linked list + HashMap

```java
class LRUCache<K, V> {
    private final int capacity;
    private final Map<K, Node<K, V>> map = new HashMap<>();
    private final Node<K, V> head = new Node<>(null, null);
    private final Node<K, V> tail = new Node<>(null, null);
    
    public LRUCache(int capacity) {
        this.capacity = capacity;
        head.next = tail;
        tail.prev = head;
    }
    
    public V get(K key) {
        Node<K, V> node = map.get(key);
        if (node == null) return null;
        
        // Move to head (mark as recently used)
        moveToHead(node);
        return node.value;
    }
    
    public void put(K key, V value) {
        Node<K, V> existing = map.get(key);
        
        if (existing != null) {
            existing.value = value;
            moveToHead(existing);
        } else {
            Node<K, V> newNode = new Node<>(key, value);
            
            if (map.size() >= capacity) {
                // Remove least recently used (tail)
                Node<K, V> last = removeTail();
                map.remove(last.key);
            }
            
            addToHead(newNode);
            map.put(key, newNode);
        }
    }
}
```

#### **LFU (Least Frequently Used)** #lfu  
**Logic:** Remove item with lowest access frequency
**Use Case:** Long-term caching, database buffer pools
**Complex:** Need to track frequency + handle ties with recency

#### **FIFO (First In, First Out)** #fifo
**Logic:** Remove oldest inserted item regardless of usage
**Use Case:** Simple caching, circular buffers
**Simple:** Queue-based implementation

#### **Random** #random
**Logic:** Remove random item when eviction needed
**Use Case:** Approximate algorithms, low-overhead caching
**Benefit:** Simple implementation, surprisingly effective

### **Eviction Policy Comparison**

| **Policy** | **Cache Hit Rate** | **Implementation** | **Memory Overhead** | **Use Cases** |
|------------|--------------------|--------------------|---------------------|---------------|
| **LRU** | High | Complex | Medium | General purpose |
| **LFU** | Highest | Very Complex | High | Long-term patterns |
| **FIFO** | Medium | Simple | Low | Simple scenarios |
| **Random** | Medium | Very Simple | Very Low | Approximate caching |

---

## 🌐 Distributed Caching

### **Scaling Caching Systems** #distributed-cache

#### **1. Replication Strategy** 
**Approach:** Same data on multiple cache servers
**Benefits:** High availability, fault tolerance
**Drawbacks:** Memory inefficiency, consistency challenges

```
Cache Server 1: [A, B, C, D]
Cache Server 2: [A, B, C, D]  ← Full replication
Cache Server 3: [A, B, C, D]
```

#### **2. Partitioning Strategy**
**Approach:** Distribute different data across servers
**Benefits:** Memory efficiency, linear scalability  
**Implementation:** Consistent hashing

```
Cache Server 1: [A, B]
Cache Server 2: [C, D]    ← Data partitioned
Cache Server 3: [E, F]
```

### **Consistent Hashing for Cache Distribution** #consistent-hashing

**Problem:** Simple hashing doesn't handle server failures well
**Solution:** Consistent hashing minimizes rehashing on server changes

**Algorithm:**
```java
public class ConsistentHashCache {
    private final TreeMap<Long, String> ring = new TreeMap<>();
    private final int virtualNodes = 150; // Virtual nodes per server
    
    public void addServer(String server) {
        for (int i = 0; i < virtualNodes; i++) {
            String virtualNode = server + "#" + i;
            long hash = hash(virtualNode);
            ring.put(hash, server);
        }
    }
    
    public String getServer(String key) {
        if (ring.isEmpty()) return null;
        
        long hash = hash(key);
        Map.Entry<Long, String> entry = ring.ceilingEntry(hash);
        
        // Wrap around to first server if needed
        if (entry == null) {
            entry = ring.firstEntry();
        }
        
        return entry.getValue();
    }
    
    private long hash(String input) {
        // Use consistent hash function (e.g., MD5, SHA1)
        return input.hashCode();
    }
}
```

### **Cache Cluster Management** #cluster-management

#### **Redis Cluster Setup**
```bash
# Create 6-node Redis cluster (3 masters, 3 replicas)
redis-cli --cluster create \
  127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 \
  127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 \
  --cluster-replicas 1
```

#### **Application Configuration**
```java
@Configuration
public class RedisClusterConfig {
    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        List<String> clusterNodes = Arrays.asList(
            "127.0.0.1:7001", 
            "127.0.0.1:7002", 
            "127.0.0.1:7003"
        );
        
        RedisClusterConfiguration clusterConfig = 
            new RedisClusterConfiguration(clusterNodes);
        
        return new LettuceConnectionFactory(clusterConfig);
    }
}
```

---

## 💡 Interview Questions & Scenarios

### **🔥 Classic Interview Questions**

#### **Q1: Design a cache for a social media news feed** #interview-q1

**Requirements Analysis:**
- 1B users, 100M daily active
- Average 50 posts per user per day  
- Each post ~1KB data
- 95% read, 5% write operations

**Solution Design:**
```java
public class NewsFeedCache {
    private final RedisTemplate<String, Object> redis;
    private final int FEED_SIZE = 100; // Posts per feed
    private final int CACHE_TTL = 3600; // 1 hour
    
    public List<Post> getUserFeed(String userId) {
        String cacheKey = "feed:" + userId;
        
        // Try cache first
        List<Post> cachedFeed = redis.opsForList()
            .range(cacheKey, 0, FEED_SIZE - 1);
            
        if (cachedFeed != null && !cachedFeed.isEmpty()) {
            return cachedFeed;
        }
        
        // Cache miss - generate feed
        List<Post> freshFeed = generateFeed(userId);
        
        // Cache the generated feed
        redis.opsForList().rightPushAll(cacheKey, freshFeed);
        redis.expire(cacheKey, CACHE_TTL);
        
        return freshFeed;
    }
    
    public void invalidateFeedCache(String userId) {
        // When user posts, invalidate their followers' feeds
        List<String> followers = getFollowers(userId);
        for (String follower : followers) {
            redis.delete("feed:" + follower);
        }
    }
}
```

**Key Design Decisions:**
- **Cache Pattern:** Write-around with manual invalidation
- **Cache Key:** `feed:{userId}` for user-specific feeds
- **Eviction:** TTL-based to handle memory pressure
- **Invalidation:** Push-based when users post

#### **Q2: Handle cache stampede problem** #interview-q2

**Problem:** Multiple threads simultaneously fetch same data on cache miss
**Solution:** Use distributed locking or single-flight pattern

```java
public class StampedeProtectedCache {
    private final RedisTemplate<String, Object> redis;
    private final ConcurrentHashMap<String, CompletableFuture<Object>> 
        ongoingRequests = new ConcurrentHashMap<>();
    
    public Object get(String key, Supplier<Object> dataLoader) {
        // Check cache first
        Object cached = redis.opsForValue().get(key);
        if (cached != null) {
            return cached;
        }
        
        // Use single-flight pattern to prevent stampede
        CompletableFuture<Object> future = ongoingRequests.get(key);
        if (future != null) {
            return future.join(); // Wait for ongoing request
        }
        
        // Create new future for this key
        CompletableFuture<Object> newFuture = CompletableFuture.supplyAsync(() -> {
            try {
                // Double-check cache (might be populated by now)
                Object rechecked = redis.opsForValue().get(key);
                if (rechecked != null) {
                    return rechecked;
                }
                
                // Load data and cache it
                Object data = dataLoader.get();
                if (data != null) {
                    redis.opsForValue().set(key, data, Duration.ofMinutes(30));
                }
                return data;
                
            } finally {
                ongoingRequests.remove(key);
            }
        });
        
        ongoingRequests.put(key, newFuture);
        return newFuture.join();
    }
}
```

#### **Q3: Design cache with automatic refresh** #interview-q3

**Requirement:** Keep cache warm without cache misses
**Solution:** Background refresh before expiration

```java
@Component
public class RefreshAheadCache {
    private final RedisTemplate<String, Object> redis;
    private final ScheduledExecutorService scheduler = 
        Executors.newScheduledThreadPool(10);
    
    public Object get(String key, Supplier<Object> loader, Duration ttl) {
        CachedValue cached = (CachedValue) redis.opsForValue().get(key);
        
        if (cached != null) {
            // Check if we need to refresh soon (20% of TTL remaining)
            long timeToRefresh = cached.expirationTime - System.currentTimeMillis();
            long refreshThreshold = ttl.toMillis() / 5; // 20% of TTL
            
            if (timeToRefresh <= refreshThreshold) {
                // Asynchronously refresh cache
                scheduler.submit(() -> refreshCache(key, loader, ttl));
            }
            
            return cached.value;
        }
        
        // Cache miss - load synchronously  
        return loadAndCache(key, loader, ttl);
    }
    
    private void refreshCache(String key, Supplier<Object> loader, Duration ttl) {
        try {
            Object freshData = loader.get();
            CachedValue cached = new CachedValue(
                freshData, 
                System.currentTimeMillis() + ttl.toMillis()
            );
            redis.opsForValue().set(key, cached, ttl);
        } catch (Exception e) {
            // Log error but don't fail - old cache value still valid
            log.warn("Failed to refresh cache for key: " + key, e);
        }
    }
}
```

---

## 🎯 Best Practices

### **🛡️ Cache Reliability Patterns** #reliability

#### **1. Circuit Breaker for Cache**
```java
@Component
public class ResilientCache {
    private final CircuitBreaker circuitBreaker;
    private final RedisTemplate<String, Object> redis;
    
    public Object get(String key, Supplier<Object> fallback) {
        return circuitBreaker.executeSupplier(() -> {
            return redis.opsForValue().get(key);
        }).recover(throwable -> {
            log.warn("Cache failure, falling back to data source", throwable);
            return fallback.get();
        });
    }
}
```

#### **2. Cache Warming Strategies**
```java
@Service
public class CacheWarmer {
    
    @EventListener
    public void onApplicationReady(ApplicationReadyEvent event) {
        // Warm critical caches on startup
        warmUserProfiles();
        warmPopularProducts();
        warmFrequentQueries();
    }
    
    private void warmUserProfiles() {
        // Pre-load profiles of active users
        List<String> activeUsers = userService.getActiveUserIds(1000);
        activeUsers.parallelStream().forEach(userId -> {
            userProfileCache.get(userId, () -> userService.getProfile(userId));
        });
    }
}
```

#### **3. Cache Monitoring & Alerting**
```java
@Component
public class CacheMetrics {
    private final MeterRegistry meterRegistry;
    private final Counter cacheHits;
    private final Counter cacheMisses;
    private final Timer cacheResponseTime;
    
    public CacheMetrics(MeterRegistry registry) {
        this.meterRegistry = registry;
        this.cacheHits = Counter.builder("cache.hits").register(registry);
        this.cacheMisses = Counter.builder("cache.misses").register(registry);
        this.cacheResponseTime = Timer.builder("cache.response.time").register(registry);
    }
    
    public Object getWithMetrics(String key, Supplier<Object> loader) {
        Timer.Sample sample = Timer.start(meterRegistry);
        
        Object cached = redis.opsForValue().get(key);
        if (cached != null) {
            cacheHits.increment();
            sample.stop(cacheResponseTime);
            return cached;
        }
        
        cacheMisses.increment();
        Object loaded = loader.get();
        
        // Cache the loaded value
        redis.opsForValue().set(key, loaded, Duration.ofMinutes(30));
        
        sample.stop(cacheResponseTime);
        return loaded;
    }
}
```

### **⚠️ Common Anti-Patterns** #anti-patterns

#### **❌ Cache Everything Anti-Pattern**
```java
// DON'T DO THIS
public class BadCacheService {
    public UserSettings getUserSettings(String userId) {
        // Caching data that changes frequently
        return cache.get("settings:" + userId, () -> 
            database.getUserSettings(userId));
    }
    
    public String generateOTP(String userId) {
        // Caching non-cacheable data
        return cache.get("otp:" + userId, () -> 
            otpGenerator.generate());
    }
}
```

**Why it's bad:**
- Wastes cache memory on inappropriate data
- Can cause consistency issues
- Generates are meant to be unique

#### **❌ Cache Without TTL Anti-Pattern**
```java
// DON'T DO THIS
public void badCacheUsage(String key, Object value) {
    // No expiration time - cache grows indefinitely
    cache.put(key, value);
}
```

**Better approach:**
```java
public void goodCacheUsage(String key, Object value) {
    // Always set appropriate TTL
    cache.put(key, value, Duration.ofMinutes(30));
}
```

---

## 🚀 Advanced Topics

### **Cache Coherence in Microservices** #microservices-cache

**Problem:** Keeping caches consistent across multiple services
**Solutions:**
1. **Event-Driven Invalidation:** Publish events when data changes
2. **Centralized Cache:** Shared cache cluster (Redis)
3. **Cache-Last Pattern:** Always check authoritative source

```java
@EventListener
public class CacheInvalidationListener {
    @Autowired
    private RedisTemplate<String, Object> redis;
    
    @EventHandler
    public void handleUserProfileUpdated(UserProfileUpdatedEvent event) {
        // Invalidate user profile cache across all services
        String cacheKey = "user:profile:" + event.getUserId();
        redis.delete(cacheKey);
        
        // Also invalidate derived caches
        redis.delete("user:feed:" + event.getUserId());
        redis.delete("user:recommendations:" + event.getUserId());
    }
}
```

### **Multi-Layer Caching Architecture** #multi-layer

```
Client Browser Cache (L1)
        ↓
    CDN Cache (L2)  
        ↓
Load Balancer Cache (L3)
        ↓
Application Cache (L4)
        ↓
Database Buffer Pool (L5)
        ↓
    Disk Cache (L6)
```

**Benefits:** Each layer optimizes for different access patterns and latencies

---

**Study Progress:**
- [ ] Caching Fundamentals (0/4 concepts mastered)
- [ ] Caching Patterns (0/4 patterns implemented)
- [ ] Distributed Caching (0/3 techniques practiced)  
- [ ] Interview Questions (0/5 scenarios solved)
- [ ] Best Practices (0/3 patterns applied)

**Last Updated:** August 2025  
**Next Focus:** [Implement LRU cache from scratch]