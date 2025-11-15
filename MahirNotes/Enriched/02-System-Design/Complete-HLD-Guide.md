# 🏗️ Complete High-Level Design Guide - System Architecture Mastery

> **"Design systems that scale from 100 to 100 million users"**

---

## 📊 System Design Mastery Tracker

### **Database & Storage Systems**
- [ ] [Database 0 to 1B Users](#database-scaling-0-to-1b-users) - Scale progression
- [ ] [Database Replication](#database-replication-strategies) - Master-slave, Master-master
- [ ] [Database Partitioning & Sharding](#database-partitioning--sharding) - Horizontal scaling
- [ ] [CAP Theorem](#cap-theorem-deep-dive) - Consistency vs Availability
- [ ] [ACID vs BASE](#acid-vs-base-properties) - Transaction models

### **Caching Architecture**
- [ ] [Caching Strategies](#caching-strategies-complete-guide) - All patterns & implementations
- [ ] [CDN Architecture](#cdn-content-delivery-networks) - Global content distribution
- [ ] [Cache Invalidation](#cache-invalidation-patterns) - Keeping data fresh
- [ ] [Redis vs Memcached](#redis-vs-memcached-comparison) - Technology comparison

### **Message Queues & Communication**
- [ ] [Kafka vs SQS vs RabbitMQ](#kafka-vs-sqs-vs-rabbitmq-detailed-comparison) - Complete comparison
- [ ] [Event-Driven Architecture](#event-driven-architecture) - Async systems
- [ ] [Pub-Sub Patterns](#publisher-subscriber-patterns) - Decoupling systems
- [ ] [Message Queue Patterns](#message-queue-patterns) - Reliability & ordering

### **Load Balancing & Traffic**
- [ ] [Load Balancing Strategies](#load-balancing-complete-guide) - Layer 4 vs Layer 7
- [ ] [Rate Limiting Systems](#rate-limiting-global-distributed) - Global rate limiting
- [ ] [API Gateway Patterns](#api-gateway-architecture) - Request routing & management
- [ ] [Traffic Shaping](#traffic-shaping--throttling) - Managing request flow

### **Microservices & Architecture**
- [ ] [Microservices Design](#microservices-architecture-patterns) - Service decomposition
- [ ] [Service Discovery](#service-discovery-patterns) - Service registration
- [ ] [Circuit Breaker Pattern](#circuit-breaker-implementation) - Fault tolerance
- [ ] [Saga Pattern](#saga-pattern-distributed-transactions) - Distributed transactions

### **Design Problems Practice**
- [ ] [URL Shortener](#design-url-shortener) - Complete implementation
- [ ] [Chat System](#design-chat-system) - Real-time messaging
- [ ] [Social Media Feed](#design-social-media-feed) - Timeline generation
- [ ] [Video Streaming](#design-video-streaming) - Content delivery
- [ ] [Search Engine](#design-search-engine) - Distributed search
- [ ] [Ride Sharing](#design-ride-sharing) - Location-based services

---

## Database Scaling: 0 to 1B Users

### **Phase 1: Single Database (0 - 10K Users)**

**Architecture:**
```
[Web App] → [Single MySQL Database]
```

**Characteristics:**
- Single server handles everything
- Simple CRUD operations
- Vertical scaling (add RAM/CPU)
- **When it breaks:** ~10K concurrent users, 1TB data

**Technologies:**
- MySQL/PostgreSQL for ACID compliance
- Simple connection pooling
- Basic indexing strategies

### **Phase 2: Read Replicas (10K - 100K Users)**

**Architecture:**
```
[Web App] → [Master DB] → [Read Replica 1]
                      → [Read Replica 2]
```

**Implementation Details:**
```java
@Service
public class UserService {
    @Autowired
    @Qualifier("masterDataSource")
    private JdbcTemplate masterDb;
    
    @Autowired  
    @Qualifier("slaveDataSource")
    private JdbcTemplate slaveDb;
    
    public void createUser(User user) {
        masterDb.update("INSERT INTO users...", user); // Write to master
    }
    
    public User getUser(String id) {
        return slaveDb.queryForObject("SELECT * FROM users WHERE id = ?", id); // Read from slave
    }
}
```

**Key Decisions:**
- Master handles all writes
- Slaves handle read traffic (80% of typical workload)
- Replication lag: 1-2 seconds acceptable
- **Scaling capacity:** 100K users, 10TB data

### **Phase 3: Horizontal Sharding (100K - 1M Users)**

**Sharding Strategy - User ID Based:**
```
Hash(user_id) % num_shards = shard_assignment

Shard 0: user_id ending 0,1
Shard 1: user_id ending 2,3  
Shard 2: user_id ending 4,5
...
```

**Sharding Router Implementation:**
```java
@Component
public class DatabaseShardRouter {
    private final Map<Integer, DataSource> shardDataSources;
    
    public DataSource getShardForUser(String userId) {
        int shard = Math.abs(userId.hashCode()) % shardDataSources.size();
        return shardDataSources.get(shard);
    }
    
    public List<DataSource> getAllShards() {
        return new ArrayList<>(shardDataSources.values());
    }
}

@Service
public class ShardedUserService {
    @Autowired
    private DatabaseShardRouter shardRouter;
    
    public User getUser(String userId) {
        DataSource shard = shardRouter.getShardForUser(userId);
        JdbcTemplate jdbcTemplate = new JdbcTemplate(shard);
        return jdbcTemplate.queryForObject("SELECT * FROM users WHERE id = ?", userId);
    }
    
    // Cross-shard queries require scatter-gather
    public List<User> getUsersByCity(String city) {
        List<User> allUsers = new ArrayList<>();
        for (DataSource shard : shardRouter.getAllShards()) {
            JdbcTemplate jdbcTemplate = new JdbcTemplate(shard);
            List<User> shardUsers = jdbcTemplate.query(
                "SELECT * FROM users WHERE city = ?", city);
            allUsers.addAll(shardUsers);
        }
        return allUsers;
    }
}
```

### **Phase 4: NoSQL + Polyglot Persistence (1M - 10M Users)**

**Polyglot Architecture:**
```
User Profiles → MongoDB (document-based)
Social Graph → Neo4j (graph database)  
Session Data → Redis (key-value)
Analytics → Cassandra (wide-column)
Transactions → PostgreSQL (relational)
```

**Data Access Layer:**
```java
@Service
public class PolyglotUserService {
    @Autowired private UserProfileRepository mongoRepo;     // MongoDB
    @Autowired private SocialGraphRepository neo4jRepo;    // Neo4j
    @Autowired private SessionRepository redisRepo;        // Redis
    @Autowired private AnalyticsRepository cassandraRepo;  // Cassandra
    
    public UserProfile getFullUserProfile(String userId) {
        // Parallel data fetching from multiple stores
        CompletableFuture<UserProfile> profile = 
            CompletableFuture.supplyAsync(() -> mongoRepo.findById(userId));
            
        CompletableFuture<List<String>> friends = 
            CompletableFuture.supplyAsync(() -> neo4jRepo.getFriends(userId));
            
        CompletableFuture<SessionData> session = 
            CompletableFuture.supplyAsync(() -> redisRepo.getSession(userId));
            
        // Combine results
        return CompletableFuture.allOf(profile, friends, session)
            .thenApply(v -> {
                UserProfile p = profile.join();
                p.setFriends(friends.join());
                p.setSessionData(session.join());
                return p;
            }).join();
    }
}
```

### **Phase 5: Global Distribution (10M - 1B Users)**

**Multi-Region Architecture:**
```
US-East:  [App Servers] → [DB Cluster] → [Cache Cluster]
US-West:  [App Servers] → [DB Cluster] → [Cache Cluster]  
Europe:   [App Servers] → [DB Cluster] → [Cache Cluster]
Asia:     [App Servers] → [DB Cluster] → [Cache Cluster]
```

**Cross-Region Data Consistency:**
- **Strong consistency:** Financial data (single region writes)
- **Eventual consistency:** User profiles, posts (async replication)
- **Session affinity:** Users stick to home region when possible

---

## Database Replication Strategies

### **Master-Slave Replication Deep Dive**

**Synchronous Replication Flow:**
```
1. Client sends write to Master
2. Master writes to local transaction log
3. Master sends write to ALL slaves
4. Slaves acknowledge write completion
5. Master commits transaction
6. Master responds to client
```

**Asynchronous Replication Flow:**
```
1. Client sends write to Master
2. Master writes locally and responds immediately
3. Master sends write to slaves in background
4. Slaves apply writes when they can
```

**Implementation with Spring Boot:**
```java
@Configuration
public class DatabaseConfig {
    
    @Bean
    @Primary
    public DataSource masterDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://master-db:3306/app");
        config.setMaximumPoolSize(20);
        config.setConnectionTimeout(30000);
        return new HikariDataSource(config);
    }
    
    @Bean
    public DataSource slaveDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://slave-db:3306/app");
        config.setMaximumPoolSize(20);
        config.setReadOnly(true);
        return new HikariDataSource(config);
    }
}

@Service
@Transactional
public class ReplicationAwareService {
    
    @Transactional(readOnly = false)
    public void writeOperation(User user) {
        // Automatically routes to master
        userRepository.save(user);
    }
    
    @Transactional(readOnly = true)  
    public User readOperation(String userId) {
        // Routes to slave replica
        return userRepository.findById(userId);
    }
}
```

### **Master-Master Replication**

**Conflict Resolution Strategies:**
1. **Last Write Wins (LWW):** Use timestamps
2. **Application-level resolution:** Custom business logic
3. **Manual resolution:** Flag conflicts for review

**Implementation Example:**
```java
@Entity
public class User {
    private String id;
    private String name;
    private long version; // For optimistic locking
    private Instant lastModified;
    private String modifiedBy; // Which datacenter
    
    @PreUpdate
    public void preUpdate() {
        this.lastModified = Instant.now();
        this.version++;
    }
}

@Service
public class ConflictResolutionService {
    
    public User resolveConflict(User version1, User version2) {
        // Last Write Wins strategy
        if (version1.getLastModified().isAfter(version2.getLastModified())) {
            return version1;
        } else if (version2.getLastModified().isAfter(version1.getLastModified())) {
            return version2;
        } else {
            // Same timestamp - use datacenter priority
            return resolveByDatacenterPriority(version1, version2);
        }
    }
    
    private User resolveByDatacenterPriority(User v1, User v2) {
        // US-East > US-West > Europe > Asia
        Map<String, Integer> priorities = Map.of(
            "US-EAST", 1,
            "US-WEST", 2, 
            "EUROPE", 3,
            "ASIA", 4
        );
        
        int priority1 = priorities.get(v1.getModifiedBy());
        int priority2 = priorities.get(v2.getModifiedBy());
        
        return priority1 <= priority2 ? v1 : v2;
    }
}
```

---

## Database Partitioning & Sharding

### **Horizontal Partitioning Strategies**

#### **Range-Based Sharding**
```java
@Component
public class RangeBasedShardRouter {
    private final List<ShardRange> shardRanges;
    
    static class ShardRange {
        private final String shardId;
        private final long minValue;
        private final long maxValue;
        private final DataSource dataSource;
    }
    
    public DataSource getShardForKey(long key) {
        return shardRanges.stream()
            .filter(range -> key >= range.minValue && key <= range.maxValue)
            .findFirst()
            .map(range -> range.dataSource)
            .orElseThrow(() -> new IllegalArgumentException("No shard found for key: " + key));
    }
}

// Configuration
@Bean
public RangeBasedShardRouter rangeBasedRouter() {
    return new RangeBasedShardRouter(Arrays.asList(
        new ShardRange("shard0", 0L, 1000000L, shard0DataSource()),
        new ShardRange("shard1", 1000001L, 2000000L, shard1DataSource()),
        new ShardRange("shard2", 2000001L, 3000000L, shard2DataSource())
    ));
}
```

#### **Hash-Based Sharding**
```java
@Component
public class HashBasedShardRouter {
    private final List<DataSource> shards;
    private final ConsistentHash<DataSource> consistentHash;
    
    public HashBasedShardRouter(List<DataSource> shards) {
        this.shards = shards;
        this.consistentHash = new ConsistentHash<>(shards, 150); // 150 virtual nodes per shard
    }
    
    public DataSource getShardForKey(String key) {
        return consistentHash.get(key);
    }
    
    // Consistent hashing implementation
    private static class ConsistentHash<T> {
        private final TreeMap<Long, T> ring = new TreeMap<>();
        
        public ConsistentHash(List<T> nodes, int virtualNodes) {
            for (T node : nodes) {
                for (int i = 0; i < virtualNodes; i++) {
                    ring.put(hash(node.toString() + i), node);
                }
            }
        }
        
        public T get(String key) {
            if (ring.isEmpty()) return null;
            Long hashValue = hash(key);
            Map.Entry<Long, T> entry = ring.ceilingEntry(hashValue);
            if (entry == null) {
                entry = ring.firstEntry();
            }
            return entry.getValue();
        }
        
        private Long hash(String input) {
            return (long) input.hashCode();
        }
    }
}
```

### **Directory-Based Sharding**
```java
@Entity
public class ShardDirectory {
    private String entityType;
    private String entityKey; 
    private String shardId;
    private String shardEndpoint;
    private Instant lastUpdated;
}

@Service
public class DirectoryBasedShardRouter {
    @Autowired
    private ShardDirectoryRepository directoryRepo;
    @Autowired
    private Map<String, DataSource> shardDataSources;
    
    @Cacheable(value = "shardDirectory", key = "#entityType + '_' + #entityKey")
    public DataSource getShardForEntity(String entityType, String entityKey) {
        ShardDirectory entry = directoryRepo.findByEntityTypeAndEntityKey(entityType, entityKey);
        if (entry == null) {
            // Auto-assign to least loaded shard
            entry = assignToOptimalShard(entityType, entityKey);
        }
        return shardDataSources.get(entry.getShardId());
    }
    
    private ShardDirectory assignToOptimalShard(String entityType, String entityKey) {
        // Find shard with lowest current load
        String optimalShardId = findLeastLoadedShard();
        
        ShardDirectory newEntry = new ShardDirectory();
        newEntry.setEntityType(entityType);
        newEntry.setEntityKey(entityKey);
        newEntry.setShardId(optimalShardId);
        newEntry.setLastUpdated(Instant.now());
        
        return directoryRepo.save(newEntry);
    }
}
```

---

## Kafka vs SQS vs RabbitMQ: Detailed Comparison

### **Decision Framework Implementation**

```java
public enum MessagingPattern {
    EVENT_STREAMING,    // Kafka
    TASK_QUEUE,        // SQS  
    COMPLEX_ROUTING    // RabbitMQ
}

@Component
public class MessagingPatternDetector {
    
    public MessagingPattern detectPattern(MessagingRequirements requirements) {
        if (requirements.needsMultipleConsumers() && 
            requirements.needsReplay() &&
            requirements.isHighVolume()) {
            return MessagingPattern.EVENT_STREAMING;
        }
        
        if (requirements.hasComplexRoutingRules() ||
            requirements.needsPrioritization() ||
            requirements.hasMultipleExchangeTypes()) {
            return MessagingPattern.COMPLEX_ROUTING;
        }
        
        return MessagingPattern.TASK_QUEUE;
    }
}

@Service
public class MessagingServiceFactory {
    
    @Autowired private KafkaProducerService kafkaService;
    @Autowired private SqsMessageService sqsService;
    @Autowired private RabbitMqService rabbitService;
    
    public MessageService getService(MessagingPattern pattern) {
        switch (pattern) {
            case EVENT_STREAMING:
                return kafkaService;
            case COMPLEX_ROUTING: 
                return rabbitService;
            case TASK_QUEUE:
            default:
                return sqsService;
        }
    }
}
```

### **Kafka Event Streaming Implementation**

```java
@Service
public class KafkaEventStreamingService {
    
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
    
    // Producer: User behavior events
    public void publishUserEvent(String userId, UserEvent event) {
        String topic = "user-events";
        String key = userId; // Partition by user ID
        
        kafkaTemplate.send(topic, key, event)
            .addCallback(
                result -> log.info("Event sent successfully: {}", event),
                failure -> log.error("Failed to send event: {}", event, failure)
            );
    }
    
    // Consumer: Multiple services consume same events
    @KafkaListener(topics = "user-events", groupId = "recommendation-service")
    public void handleEventForRecommendations(UserEvent event) {
        // Update recommendation model
        recommendationEngine.updateUserProfile(event);
    }
    
    @KafkaListener(topics = "user-events", groupId = "analytics-service") 
    public void handleEventForAnalytics(UserEvent event) {
        // Store for batch analytics
        analyticsStore.append(event);
    }
    
    @KafkaListener(topics = "user-events", groupId = "fraud-detection")
    public void handleEventForFraud(UserEvent event) {
        // Real-time fraud analysis
        if (fraudDetector.isSupicious(event)) {
            alertService.sendFraudAlert(event.getUserId());
        }
    }
}
```

### **SQS Task Queue Implementation**

```java
@Service
public class SqsOrderProcessingService {
    
    @Autowired
    private AmazonSQS amazonSQS;
    
    private static final String ORDER_QUEUE = "order-processing-queue";
    private static final String DLQ = "order-processing-dlq";
    
    // Producer: Order placed
    public void processOrder(Order order) {
        OrderProcessingTask task = new OrderProcessingTask();
        task.setOrderId(order.getId());
        task.setUserId(order.getUserId());
        task.setRetryCount(0);
        task.setCreatedAt(Instant.now());
        
        SendMessageRequest sendMessageRequest = new SendMessageRequest()
            .withQueueUrl(getQueueUrl(ORDER_QUEUE))
            .withMessageBody(JsonUtils.toJson(task))
            .withDelaySeconds(0);
            
        amazonSQS.sendMessage(sendMessageRequest);
    }
    
    // Consumer: Process orders with retry logic
    @SqsListener(value = ORDER_QUEUE)
    public void handleOrderProcessing(OrderProcessingTask task) {
        try {
            // Process payment
            PaymentResult paymentResult = paymentService.processPayment(task);
            if (!paymentResult.isSuccessful()) {
                throw new PaymentFailedException("Payment failed for order: " + task.getOrderId());
            }
            
            // Reserve inventory
            inventoryService.reserveItems(task.getOrderId());
            
            // Send confirmation
            notificationService.sendOrderConfirmation(task.getUserId(), task.getOrderId());
            
        } catch (PaymentFailedException e) {
            handleRetryableFailure(task, e);
        } catch (Exception e) {
            handleNonRetryableFailure(task, e);
        }
    }
    
    private void handleRetryableFailure(OrderProcessingTask task, Exception e) {
        task.setRetryCount(task.getRetryCount() + 1);
        
        if (task.getRetryCount() > 3) {
            // Send to Dead Letter Queue
            sendToDLQ(task, e);
        } else {
            // Retry with exponential backoff
            int delaySeconds = (int) Math.pow(2, task.getRetryCount()) * 30; // 30s, 60s, 120s
            
            SendMessageRequest retryRequest = new SendMessageRequest()
                .withQueueUrl(getQueueUrl(ORDER_QUEUE))
                .withMessageBody(JsonUtils.toJson(task))
                .withDelaySeconds(delaySeconds);
                
            amazonSQS.sendMessage(retryRequest);
        }
    }
}
```

### **RabbitMQ Complex Routing Implementation**

```java
@Configuration
public class RabbitMqNotificationConfig {
    
    // Topic exchange for complex routing
    @Bean
    public TopicExchange notificationExchange() {
        return new TopicExchange("notification.exchange", true, false);
    }
    
    // Different queues for different notification types
    @Bean
    public Queue emailQueue() {
        return QueueBuilder.durable("notification.email").build();
    }
    
    @Bean  
    public Queue smsQueue() {
        return QueueBuilder.durable("notification.sms").build();
    }
    
    @Bean
    public Queue pushQueue() {
        return QueueBuilder.durable("notification.push").build();
    }
    
    // Priority queue for urgent notifications
    @Bean
    public Queue urgentQueue() {
        return QueueBuilder.durable("notification.urgent")
            .withArgument("x-max-priority", 10)
            .build();
    }
    
    // Bindings with routing patterns
    @Bean
    public Binding emailBinding() {
        return BindingBuilder
            .bind(emailQueue())
            .to(notificationExchange())
            .with("*.email.*");
    }
    
    @Bean
    public Binding smsBinding() {
        return BindingBuilder
            .bind(smsQueue())
            .to(notificationExchange())
            .with("*.sms.*");
    }
    
    @Bean
    public Binding urgentBinding() {
        return BindingBuilder
            .bind(urgentQueue())
            .to(notificationExchange())
            .with("urgent.*.*");
    }
}

@Service
public class RabbitMqNotificationService {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void sendNotification(NotificationRequest request) {
        String routingKey = buildRoutingKey(request);
        
        // Add headers for additional routing logic
        MessageProperties properties = new MessageProperties();
        properties.setHeader("userId", request.getUserId());
        properties.setHeader("region", request.getRegion());
        properties.setHeader("userPreference", request.getUserPreference());
        
        if (request.isUrgent()) {
            properties.setPriority(10);
        }
        
        Message message = new Message(JsonUtils.toJson(request).getBytes(), properties);
        
        rabbitTemplate.send("notification.exchange", routingKey, message);
    }
    
    private String buildRoutingKey(NotificationRequest request) {
        String urgency = request.isUrgent() ? "urgent" : "normal";
        String channel = request.getChannel().toLowerCase(); // email, sms, push
        String type = request.getType().toLowerCase(); // security, marketing, system
        
        return String.format("%s.%s.%s", urgency, channel, type);
    }
}

// Consumer with complex processing logic
@Component
public class NotificationConsumer {
    
    @RabbitListener(queues = "notification.email")
    public void handleEmailNotification(NotificationRequest request, 
                                       @Header Map<String, Object> headers) {
        String userId = (String) headers.get("userId");
        String region = (String) headers.get("region");
        
        // Check user preferences
        UserPreferences prefs = userPreferenceService.getPreferences(userId);
        if (!prefs.isEmailEnabled()) {
            // Try alternative channel
            request.setChannel(Channel.SMS);
            sendToAlternativeChannel(request);
            return;
        }
        
        // Localization based on region
        String localizedContent = localizationService.localize(request.getContent(), region);
        request.setContent(localizedContent);
        
        // Send email
        emailService.sendEmail(request);
    }
    
    @RabbitListener(queues = "notification.urgent")
    public void handleUrgentNotification(NotificationRequest request) {
        // Bypass normal processing - immediate delivery
        urgentNotificationService.sendImmediately(request);
        
        // Log for audit
        auditService.logUrgentNotification(request);
    }
}
```

---

## Rate Limiting: Global Distributed Implementation

### **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Region US     │    │   Region EU     │    │   Region ASIA   │
│                 │    │                 │    │                 │
│ [API Gateway]   │    │ [API Gateway]   │    │ [API Gateway]   │
│ [Local Limiter] │    │ [Local Limiter] │    │ [Local Limiter] │
│ [Redis Local]   │    │ [Redis Local]   │    │ [Redis Local]   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Global Rate    │
                    │  Coordinator    │
                    │  [Redis CRDT]   │
                    │  [DynamoDB]     │
                    └─────────────────┘
```

### **Local Rate Limiter Implementation**

```java
@Component
public class LocalRateLimiter {
    
    private final RedisTemplate<String, Object> redisTemplate;
    private final GlobalRateLimitCoordinator globalCoordinator;
    
    // Token bucket algorithm for local limiting
    public boolean isAllowed(String userId, String endpoint, int tokensRequested) {
        String localKey = String.format("local:%s:%s:%d", userId, endpoint, getCurrentWindow());
        
        // Local token bucket check
        TokenBucket localBucket = getOrCreateLocalBucket(localKey);
        
        if (localBucket.hasTokens(tokensRequested)) {
            localBucket.consumeTokens(tokensRequested);
            
            // Periodically sync with global limiter  
            if (shouldSyncWithGlobal(localBucket)) {
                asyncSyncWithGlobal(userId, endpoint, localBucket.getConsumedTokens());
            }
            
            return true;
        }
        
        // Local limit exceeded - check global
        return checkGlobalLimit(userId, endpoint, tokensRequested);
    }
    
    private TokenBucket getOrCreateLocalBucket(String key) {
        TokenBucket bucket = (TokenBucket) redisTemplate.opsForValue().get(key);
        if (bucket == null) {
            bucket = new TokenBucket(100, 100); // 100 tokens, refill rate 100/min
            redisTemplate.opsForValue().set(key, bucket, Duration.ofMinutes(1));
        }
        return bucket;
    }
    
    private boolean shouldSyncWithGlobal(TokenBucket bucket) {
        // Sync when 80% of local quota consumed OR every 100 requests
        return bucket.getUtilization() > 0.8 || bucket.getRequestCount() % 100 == 0;
    }
    
    @Async
    private void asyncSyncWithGlobal(String userId, String endpoint, long consumedTokens) {
        globalCoordinator.reportLocalConsumption(userId, endpoint, consumedTokens);
    }
    
    private boolean checkGlobalLimit(String userId, String endpoint, int tokensRequested) {
        return globalCoordinator.checkAndConsumeGlobal(userId, endpoint, tokensRequested);
    }
}

@Component
public class TokenBucket implements Serializable {
    private final long capacity;
    private final long refillRate;
    private long tokens;
    private long lastRefill;
    private long consumedTokens;
    private long requestCount;
    
    public TokenBucket(long capacity, long refillRate) {
        this.capacity = capacity;
        this.refillRate = refillRate;
        this.tokens = capacity;
        this.lastRefill = System.currentTimeMillis();
        this.consumedTokens = 0;
        this.requestCount = 0;
    }
    
    public synchronized boolean hasTokens(int requested) {
        refillTokens();
        return tokens >= requested;
    }
    
    public synchronized void consumeTokens(int requested) {
        if (hasTokens(requested)) {
            tokens -= requested;
            consumedTokens += requested;
            requestCount++;
        }
    }
    
    private void refillTokens() {
        long now = System.currentTimeMillis();
        long timePassed = now - lastRefill;
        long tokensToAdd = (timePassed * refillRate) / 60000; // per minute
        
        tokens = Math.min(capacity, tokens + tokensToAdd);
        lastRefill = now;
    }
    
    public double getUtilization() {
        return 1.0 - ((double) tokens / capacity);
    }
}
```

### **Global Rate Limit Coordinator**

```java
@Service
public class GlobalRateLimitCoordinator {
    
    private final RedisTemplate<String, Object> globalRedis;
    private final DynamoDbClient dynamoDbClient;
    private final CircuitBreaker circuitBreaker;
    
    @Value("${rate.limit.global.window.minutes:1}")
    private int globalWindowMinutes;
    
    public boolean checkAndConsumeGlobal(String userId, String endpoint, int tokensRequested) {
        String globalKey = buildGlobalKey(userId, endpoint);
        
        try {
            return circuitBreaker.executeSupplier(() -> {
                // Try Redis CRDT first (faster)
                return checkWithRedisCRDT(globalKey, tokensRequested);
            });
        } catch (Exception e) {
            log.warn("Global rate limiter unavailable, falling back to local-only", e);
            // Graceful degradation - allow with local limits only
            return true;
        }
    }
    
    private boolean checkWithRedisCRDT(String globalKey, int tokensRequested) {
        // Use Lua script for atomic check-and-increment
        String luaScript = """
            local key = KEYS[1]
            local limit = tonumber(ARGV[1])
            local tokens_requested = tonumber(ARGV[2])
            local window_seconds = tonumber(ARGV[3])
            
            local current = redis.call('HGET', key, 'count')
            if current == false then
                current = 0
            else
                current = tonumber(current)
            end
            
            if current + tokens_requested <= limit then
                redis.call('HINCRBY', key, 'count', tokens_requested)
                redis.call('EXPIRE', key, window_seconds)
                return 1
            else
                return 0
            end
        """;
        
        Long result = (Long) globalRedis.execute(
            RedisScript.of(luaScript, Long.class),
            Collections.singletonList(globalKey),
            "1000", // Global limit: 1000 requests per window
            String.valueOf(tokensRequested),
            String.valueOf(globalWindowMinutes * 60)
        );
        
        return result != null && result == 1L;
    }
    
    public void reportLocalConsumption(String userId, String endpoint, long consumedTokens) {
        String globalKey = buildGlobalKey(userId, endpoint);
        
        // Async update global counter
        CompletableFuture.runAsync(() -> {
            try {
                globalRedis.opsForHash().increment(globalKey, "count", consumedTokens);
                globalRedis.expire(globalKey, Duration.ofMinutes(globalWindowMinutes));
            } catch (Exception e) {
                log.warn("Failed to sync local consumption to global", e);
            }
        });
    }
    
    private String buildGlobalKey(String userId, String endpoint) {
        long windowStart = System.currentTimeMillis() / (globalWindowMinutes * 60000L);
        return String.format("global:%s:%s:%d", userId, endpoint, windowStart);
    }
}
```

### **Rate Limiting Middleware**

```java
@Component
@Order(1)
public class RateLimitingFilter implements Filter {
    
    @Autowired
    private LocalRateLimiter rateLimiter;
    
    @Autowired
    private RateLimitConfigService configService;
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        
        String userId = extractUserId(httpRequest);
        String endpoint = extractEndpoint(httpRequest);
        String clientIp = extractClientIp(httpRequest);
        
        // Multi-dimensional rate limiting
        RateLimitResult result = checkRateLimits(userId, endpoint, clientIp);
        
        if (!result.isAllowed()) {
            sendRateLimitResponse(httpResponse, result);
            return;
        }
        
        // Add rate limit headers to response
        addRateLimitHeaders(httpResponse, result);
        
        chain.doFilter(request, response);
    }
    
    private RateLimitResult checkRateLimits(String userId, String endpoint, String clientIp) {
        // Check multiple rate limit dimensions
        List<RateLimitCheck> checks = Arrays.asList(
            new RateLimitCheck("user", userId, endpoint),
            new RateLimitCheck("ip", clientIp, endpoint), 
            new RateLimitCheck("global", "global", endpoint)
        );
        
        for (RateLimitCheck check : checks) {
            RateLimitConfig config = configService.getConfig(check.dimension, check.identifier, check.endpoint);
            
            boolean allowed = rateLimiter.isAllowed(
                check.identifier, 
                check.endpoint, 
                1 // 1 token per request
            );
            
            if (!allowed) {
                return RateLimitResult.denied(check.dimension, config);
            }
        }
        
        return RateLimitResult.allowed();
    }
    
    private void sendRateLimitResponse(HttpServletResponse response, RateLimitResult result) 
            throws IOException {
        response.setStatus(429);
        response.setHeader("Content-Type", "application/json");
        response.setHeader("Retry-After", String.valueOf(result.getRetryAfterSeconds()));
        response.setHeader("X-RateLimit-Limit", String.valueOf(result.getLimit()));
        response.setHeader("X-RateLimit-Remaining", "0");
        response.setHeader("X-RateLimit-Reset", String.valueOf(result.getResetTime()));
        
        String body = String.format(
            "{\"error\":\"Rate limit exceeded\",\"dimension\":\"%s\",\"retry_after\":%d}",
            result.getDimension(),
            result.getRetryAfterSeconds()
        );
        
        response.getWriter().write(body);
    }
    
    private void addRateLimitHeaders(HttpServletResponse response, RateLimitResult result) {
        response.setHeader("X-RateLimit-Limit", String.valueOf(result.getLimit()));
        response.setHeader("X-RateLimit-Remaining", String.valueOf(result.getRemaining()));
        response.setHeader("X-RateLimit-Reset", String.valueOf(result.getResetTime()));
    }
}
```

---

## Design Problems: Complete Solutions

### **Design URL Shortener (Comprehensive Implementation)**

#### **Requirements Analysis**
- **Functional:** Shorten URLs, redirect to original URLs, custom aliases
- **Non-Functional:** 100M URLs/day, 100:1 read/write ratio, 99.9% availability  
- **Scale:** 1.2K writes/sec, 120K reads/sec
- **Storage:** 5 years retention = 180TB total

#### **System Architecture**
```
[Client] → [Load Balancer] → [API Gateway] → [URL Service]
                                         → [Cache (Redis)]  
                                         → [Database (Sharded)]
                                         → [Analytics Service]
```

#### **Database Schema**
```sql
-- Sharded by hash(short_url) 
CREATE TABLE url_mappings (
    id BIGINT PRIMARY KEY,
    short_url VARCHAR(7) UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    user_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    click_count BIGINT DEFAULT 0,
    is_custom BOOLEAN DEFAULT FALSE,
    INDEX idx_short_url (short_url),
    INDEX idx_user_id (user_id)
) PARTITION BY HASH(short_url);

CREATE TABLE analytics (
    id BIGINT PRIMARY KEY,
    short_url VARCHAR(7) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    referer TEXT,
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    country VARCHAR(2),
    city VARCHAR(100)
) PARTITION BY RANGE (UNIX_TIMESTAMP(clicked_at));
```

#### **Complete Implementation**

```java
@RestController
@RequestMapping("/api/v1/url")
public class UrlShortenerController {
    
    @Autowired private UrlShorteningService urlService;
    @Autowired private AnalyticsService analyticsService;
    @Autowired private RateLimitingService rateLimitService;
    
    @PostMapping("/shorten")
    public ResponseEntity<ShortenResponse> shortenUrl(@RequestBody ShortenRequest request,
                                                     HttpServletRequest httpRequest) {
        String clientId = extractClientId(httpRequest);
        
        // Rate limiting
        if (!rateLimitService.isAllowed(clientId, "shorten", 10)) { // 10 per minute
            return ResponseEntity.status(429).build();
        }
        
        // Validation
        if (!isValidUrl(request.getOriginalUrl())) {
            return ResponseEntity.badRequest().build();
        }
        
        // Check for existing mapping
        UrlMapping existingMapping = urlService.findExistingMapping(request.getOriginalUrl());
        if (existingMapping != null && !request.isForceNew()) {
            return ResponseEntity.ok(ShortenResponse.from(existingMapping));
        }
        
        // Create short URL
        UrlMapping mapping = urlService.createShortUrl(request);
        
        return ResponseEntity.ok(ShortenResponse.from(mapping));
    }
    
    @GetMapping("/{shortCode}")
    public ResponseEntity<Void> redirect(@PathVariable String shortCode,
                                       HttpServletRequest request,
                                       HttpServletResponse response) throws IOException {
        // Analytics tracking
        AnalyticsEvent event = AnalyticsEvent.builder()
            .shortUrl(shortCode)
            .ipAddress(getClientIp(request))
            .userAgent(request.getHeader("User-Agent"))
            .referer(request.getHeader("Referer"))
            .timestamp(Instant.now())
            .build();
        
        analyticsService.trackClick(event);
        
        // Get original URL
        UrlMapping mapping = urlService.getUrlMapping(shortCode);
        if (mapping == null || mapping.isExpired()) {
            return ResponseEntity.notFound().build();
        }
        
        // Redirect
        response.sendRedirect(mapping.getOriginalUrl());
        return ResponseEntity.status(HttpStatus.FOUND).build();
    }
}

@Service
public class UrlShorteningService {
    
    @Autowired private UrlMappingRepository urlRepository;
    @Autowired private CacheService cacheService;
    @Autowired private Base62Encoder encoder;
    @Autowired private CounterService counterService;
    
    @Cacheable(value = "url-mappings", key = "#shortCode")
    public UrlMapping getUrlMapping(String shortCode) {
        // Try cache first
        UrlMapping cached = cacheService.get("url:" + shortCode, UrlMapping.class);
        if (cached != null) {
            return cached;
        }
        
        // Database lookup
        UrlMapping mapping = urlRepository.findByShortUrl(shortCode);
        if (mapping != null) {
            // Cache for 1 hour
            cacheService.set("url:" + shortCode, mapping, Duration.ofHours(1));
        }
        
        return mapping;
    }
    
    @Transactional
    public UrlMapping createShortUrl(ShortenRequest request) {
        String shortCode;
        
        if (request.getCustomAlias() != null) {
            // Custom alias
            if (urlRepository.existsByShortUrl(request.getCustomAlias())) {
                throw new CustomAliasAlreadyExistsException();
            }
            shortCode = request.getCustomAlias();
        } else {
            // Generate unique short code
            shortCode = generateUniqueShortCode();
        }
        
        UrlMapping mapping = UrlMapping.builder()
            .shortUrl(shortCode)
            .originalUrl(request.getOriginalUrl())
            .userId(request.getUserId())
            .createdAt(Instant.now())
            .expiresAt(request.getExpiresAt())
            .isCustom(request.getCustomAlias() != null)
            .build();
        
        mapping = urlRepository.save(mapping);
        
        // Cache the new mapping
        cacheService.set("url:" + shortCode, mapping, Duration.ofHours(24));
        
        return mapping;
    }
    
    private String generateUniqueShortCode() {
        // Use distributed counter for unique IDs
        long uniqueId = counterService.getNextId("url-shortener");
        String shortCode = encoder.encode(uniqueId);
        
        // Double-check uniqueness (rare collision with custom aliases)
        while (urlRepository.existsByShortUrl(shortCode)) {
            uniqueId = counterService.getNextId("url-shortener");
            shortCode = encoder.encode(uniqueId);
        }
        
        return shortCode;
    }
}

@Component
public class Base62Encoder {
    private static final String ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private static final int BASE = ALPHABET.length();
    
    public String encode(long number) {
        if (number == 0) {
            return String.valueOf(ALPHABET.charAt(0));
        }
        
        StringBuilder result = new StringBuilder();
        while (number > 0) {
            result.insert(0, ALPHABET.charAt((int) (number % BASE)));
            number = number / BASE;
        }
        
        return result.toString();
    }
    
    public long decode(String encoded) {
        long result = 0;
        long power = 1;
        
        for (int i = encoded.length() - 1; i >= 0; i--) {
            char c = encoded.charAt(i);
            result += ALPHABET.indexOf(c) * power;
            power *= BASE;
        }
        
        return result;
    }
}

// Distributed counter using Redis
@Service 
public class RedisCounterService implements CounterService {
    
    @Autowired private StringRedisTemplate redisTemplate;
    
    @Override
    public long getNextId(String counterName) {
        return redisTemplate.opsForValue().increment("counter:" + counterName, 1);
    }
}
```

---

## 🎯 Complete Study Plan

### **Week 1-2: Database Fundamentals**
- [ ] Database scaling patterns (0 to 1B users)
- [ ] Replication strategies (Master-slave, Master-master)  
- [ ] Partitioning and sharding techniques
- [ ] CAP theorem and consistency models

### **Week 3-4: Distributed Systems**  
- [ ] Message queues comparison and implementation
- [ ] Caching strategies and cache patterns
- [ ] Load balancing and traffic management
- [ ] Service discovery and circuit breakers

### **Week 5-6: System Design Practice**
- [ ] URL Shortener complete implementation
- [ ] Chat system with WebSockets
- [ ] Social media feed design
- [ ] Rate limiting systems

### **Week 7-8: Advanced Topics**
- [ ] Event-driven architecture
- [ ] Microservices patterns  
- [ ] Global distribution strategies
- [ ] Performance optimization

---

**System Design Mastery Progress:**
- [ ] Fundamentals: 0/8 topics completed
- [ ] Implementation Projects: 0/6 systems built
- [ ] Advanced Patterns: 0/10 patterns mastered  
- [ ] Mock Design Interviews: 0/5 completed

**Last Updated:** August 2025  
**Next Focus:** [Database scaling implementation - hands-on practice]