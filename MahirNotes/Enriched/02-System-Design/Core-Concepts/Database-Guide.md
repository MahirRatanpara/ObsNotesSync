# Complete Database Design Guide for System Design
*Comprehensive reference covering database selection, scaling patterns, and optimization strategies*

## 📚 Table of Contents

1. [Database Fundamentals](#database-fundamentals)
2. [SQL vs NoSQL Decision Matrix](#sql-vs-nosql-decision-matrix)
3. [Database Replication Strategies](#database-replication-strategies)
4. [Sharding and Partitioning](#sharding-and-partitioning)
5. [ACID Properties and Transactions](#acid-properties-and-transactions)
6. [CAP Theorem and Consistency Models](#cap-theorem-and-consistency-models)
7. [Database Performance Optimization](#database-performance-optimization)
8. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
9. [Database Security](#database-security)
10. [Modern Database Patterns](#modern-database-patterns)
11. [Interview Questions](#interview-questions)

---

## 🗄️ Database Fundamentals

### Database Types Overview

| Type | Examples | Use Cases | Strengths | Weaknesses |
|------|----------|-----------|-----------|------------|
| **Relational (RDBMS)** | PostgreSQL, MySQL, Oracle | OLTP, Complex queries, ACID transactions | Strong consistency, Complex queries, Mature tooling | Vertical scaling limits, Schema rigidity |
| **Document** | MongoDB, CouchDB, Amazon DocumentDB | Content management, Catalogs, User profiles | Flexible schema, Natural data modeling | Limited complex queries, Eventual consistency |
| **Key-Value** | Redis, DynamoDB, Riak | Caching, Session storage, Shopping carts | Simple model, High performance, Horizontal scaling | Limited query capabilities, No complex relationships |
| **Column-Family** | Cassandra, HBase, Amazon Redshift | Time-series, Analytics, IoT data | Write-optimized, Compression, Distributed | Complex data modeling, Eventually consistent |
| **Graph** | Neo4j, Amazon Neptune, ArangoDB | Social networks, Fraud detection, Recommendations | Relationship queries, Path finding | Specialized use cases, Complex operations |
| **Time-Series** | InfluxDB, TimescaleDB, OpenTSDB | Monitoring, Analytics, IoT sensors | Time-based queries, Compression, Retention policies | Limited general purpose use |
| **Search** | Elasticsearch, Solr, Amazon OpenSearch | Full-text search, Analytics, Logging | Text search, Real-time analytics, Faceted search | Not primary data store, Complex operations |

### Database Selection Framework

```java
@Component
public class DatabaseSelectionService {
    
    public DatabaseRecommendation recommendDatabase(ApplicationRequirements requirements) {
        
        // ACID requirements
        if (requirements.requiresStrictACID()) {
            return recommendRelationalDatabase(requirements);
        }
        
        // Scale requirements  
        if (requirements.getExpectedQPS() > 100_000) {
            return recommendDistributedDatabase(requirements);
        }
        
        // Data model requirements
        return switch (requirements.getDataModel()) {
            case STRUCTURED_RELATIONAL -> recommendRelationalDatabase(requirements);
            case SEMI_STRUCTURED -> recommendDocumentDatabase(requirements);
            case KEY_VALUE_PAIRS -> recommendKeyValueDatabase(requirements);
            case GRAPH_RELATIONSHIPS -> recommendGraphDatabase(requirements);
            case TIME_SERIES -> recommendTimeSeriesDatabase(requirements);
            default -> recommendHybridApproach(requirements);
        };
    }
    
    private DatabaseRecommendation recommendRelationalDatabase(ApplicationRequirements req) {
        if (req.getDataSize() < Size.TB_1 && req.getQPS() < 10_000) {
            return DatabaseRecommendation.builder()
                .primary("PostgreSQL")
                .reasoning("Single instance sufficient, strong ACID guarantees")
                .scalingStrategy(ScalingStrategy.VERTICAL_FIRST)
                .build();
        } else {
            return DatabaseRecommendation.builder()
                .primary("PostgreSQL")
                .secondaryPattern("Read Replicas")
                .reasoning("Master-slave with read scaling")
                .scalingStrategy(ScalingStrategy.READ_REPLICAS)
                .build();
        }
    }
    
    private DatabaseRecommendation recommendDocumentDatabase(ApplicationRequirements req) {
        return DatabaseRecommendation.builder()
            .primary("MongoDB")
            .reasoning("Flexible schema, natural object mapping")
            .scalingStrategy(ScalingStrategy.HORIZONTAL_SHARDING)
            .considerations(Arrays.asList(
                "Plan for eventual consistency",
                "Design for shard-friendly queries",
                "Consider replica sets for HA"
            ))
            .build();
    }
}
```

---

## ⚖️ SQL vs NoSQL Decision Matrix

### When to Choose SQL (RDBMS)

#### Strong Use Cases
- **Financial Systems**: Banking, payments, accounting
- **E-commerce**: Order management, inventory tracking
- **ERP Systems**: Complex business logic, reporting
- **Data Warehousing**: Complex analytical queries

```java
// Example: Financial transaction system requiring ACID
@Entity
@Table(name = "transactions")
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "from_account", nullable = false)
    private Long fromAccount;
    
    @Column(name = "to_account", nullable = false) 
    private Long toAccount;
    
    @Column(name = "amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;
    
    @Enumerated(EnumType.STRING)
    private TransactionStatus status;
    
    @CreationTimestamp
    private LocalDateTime createdAt;
}

@Service
@Transactional
public class TransferService {
    
    public void transferMoney(Long fromAccount, Long toAccount, BigDecimal amount) {
        // ACID transaction ensures consistency
        Account from = accountRepository.findByIdWithLock(fromAccount);
        Account to = accountRepository.findByIdWithLock(toAccount);
        
        if (from.getBalance().compareTo(amount) < 0) {
            throw new InsufficientFundsException();
        }
        
        // All operations succeed or fail together
        from.debit(amount);
        to.credit(amount);
        
        accountRepository.save(from);
        accountRepository.save(to);
        
        // Transaction log for audit
        Transaction transaction = new Transaction();
        transaction.setFromAccount(fromAccount);
        transaction.setToAccount(toAccount);
        transaction.setAmount(amount);
        transaction.setStatus(TransactionStatus.COMPLETED);
        
        transactionRepository.save(transaction);
    }
}
```

### When to Choose NoSQL

#### Document Databases (MongoDB, CouchDB)

```java
// Example: Content management system with flexible schema
@Document(collection = "articles")
public class Article {
    @Id
    private String id;
    
    private String title;
    private String content;
    private List<String> tags;
    private Author author;
    
    // Flexible schema - different article types can have different fields
    private Map<String, Object> metadata; // Custom fields per article type
    
    private LocalDateTime publishedAt;
    private LocalDateTime updatedAt;
    
    // Embedded comments (denormalized for read performance)
    private List<Comment> comments;
}

@Service
public class ArticleService {
    
    @Autowired
    private MongoTemplate mongoTemplate;
    
    // Complex queries with MongoDB
    public List<Article> findArticles(String searchTerm, List<String> tags, 
                                    LocalDateTime publishedAfter) {
        Criteria criteria = new Criteria();
        
        if (searchTerm != null) {
            criteria.orOperator(
                Criteria.where("title").regex(searchTerm, "i"),
                Criteria.where("content").regex(searchTerm, "i")
            );
        }
        
        if (tags != null && !tags.isEmpty()) {
            criteria.and("tags").in(tags);
        }
        
        if (publishedAfter != null) {
            criteria.and("publishedAt").gte(publishedAfter);
        }
        
        Query query = new Query(criteria)
            .with(Sort.by(Sort.Direction.DESC, "publishedAt"))
            .limit(50);
            
        return mongoTemplate.find(query, Article.class);
    }
    
    // Efficient updates with MongoDB
    public void addComment(String articleId, Comment comment) {
        Query query = new Query(Criteria.where("id").is(articleId));
        Update update = new Update()
            .push("comments", comment)
            .set("updatedAt", LocalDateTime.now());
            
        mongoTemplate.updateFirst(query, update, Article.class);
    }
}
```

#### Key-Value Databases (Redis, DynamoDB)

```java
// Example: Session management and caching
@Service
public class SessionService {
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    public void createSession(String sessionId, UserSession session) {
        String key = "session:" + sessionId;
        
        // Store session data with expiration
        redisTemplate.opsForValue().set(key, session, Duration.ofHours(24));
        
        // Add to user's active sessions set
        String userSessionsKey = "user_sessions:" + session.getUserId();
        redisTemplate.opsForSet().add(userSessionsKey, sessionId);
        redisTemplate.expire(userSessionsKey, Duration.ofDays(7));
    }
    
    public UserSession getSession(String sessionId) {
        String key = "session:" + sessionId;
        UserSession session = (UserSession) redisTemplate.opsForValue().get(key);
        
        if (session != null) {
            // Extend expiration on access
            redisTemplate.expire(key, Duration.ofHours(24));
        }
        
        return session;
    }
    
    public void invalidateUserSessions(Long userId) {
        String userSessionsKey = "user_sessions:" + userId;
        Set<Object> sessionIds = redisTemplate.opsForSet().members(userSessionsKey);
        
        if (sessionIds != null && !sessionIds.isEmpty()) {
            // Delete all user's sessions
            List<String> sessionKeys = sessionIds.stream()
                .map(sessionId -> "session:" + sessionId)
                .collect(Collectors.toList());
                
            redisTemplate.delete(sessionKeys);
            redisTemplate.delete(userSessionsKey);
        }
    }
}
```

#### Column-Family Databases (Cassandra, HBase)

```java
// Example: Time-series data for IoT sensors
@Table(keyspace = "iot_data", name = "sensor_readings")
public class SensorReading {
    
    @PartitionKey
    @Column(name = "sensor_id")
    private UUID sensorId;
    
    @ClusteringColumn
    @Column(name = "timestamp")
    private LocalDateTime timestamp;
    
    @Column(name = "temperature")
    private Double temperature;
    
    @Column(name = "humidity")
    private Double humidity;
    
    @Column(name = "pressure")
    private Double pressure;
    
    // Time-to-live for automatic cleanup
    private Integer ttl;
}

@Service
public class SensorDataService {
    
    @Autowired
    private CassandraTemplate cassandraTemplate;
    
    public void saveSensorReading(SensorReading reading) {
        // Set TTL to auto-delete old data (e.g., 30 days)
        reading.setTtl(30 * 24 * 3600); // 30 days in seconds
        
        cassandraTemplate.save(reading);
    }
    
    // Efficient time-range queries (leveraging clustering columns)
    public List<SensorReading> getSensorReadings(UUID sensorId, 
                                               LocalDateTime startTime,
                                               LocalDateTime endTime) {
        
        String cql = "SELECT * FROM sensor_readings WHERE sensor_id = ? " +
                    "AND timestamp >= ? AND timestamp <= ? ORDER BY timestamp DESC";
                    
        return cassandraTemplate.select(cql, SensorReading.class, 
            sensorId, startTime, endTime);
    }
    
    // Aggregation query for analytics
    public SensorStats getHourlyStats(UUID sensorId, LocalDateTime hour) {
        String cql = "SELECT AVG(temperature) as avg_temp, " +
                    "MAX(temperature) as max_temp, " +
                    "MIN(temperature) as min_temp, " +
                    "COUNT(*) as reading_count " +
                    "FROM sensor_readings WHERE sensor_id = ? " +
                    "AND timestamp >= ? AND timestamp < ?";
                    
        LocalDateTime nextHour = hour.plusHours(1);
        
        return cassandraTemplate.selectOne(cql, SensorStats.class, 
            sensorId, hour, nextHour);
    }
}
```

### Decision Matrix

| Requirement | SQL | Document | Key-Value | Column-Family | Graph |
|-------------|-----|----------|-----------|---------------|-------|
| **ACID Transactions** | ✅ Strong | ⚠️ Limited | ❌ None | ❌ None | ⚠️ Limited |
| **Complex Queries** | ✅ SQL | ⚠️ Good | ❌ Basic | ⚠️ Limited | ✅ Relationships |
| **Horizontal Scaling** | ⚠️ Complex | ✅ Easy | ✅ Easy | ✅ Native | ⚠️ Complex |
| **Schema Flexibility** | ❌ Rigid | ✅ Flexible | ✅ No Schema | ⚠️ Column-based | ⚠️ Graph-based |
| **Write Performance** | ⚠️ Good | ✅ High | ✅ Very High | ✅ Very High | ⚠️ Good |
| **Read Performance** | ✅ Excellent | ✅ Good | ✅ Very High | ✅ High | ✅ Path Queries |
| **Consistency** | ✅ Strong | ⚠️ Eventual | ⚠️ Eventual | ⚠️ Eventual | ✅ Strong |

---

## 🔄 Database Replication Strategies

### Master-Slave Replication

```java
@Configuration
public class MasterSlaveConfig {
    
    @Bean
    @Primary
    public DataSource masterDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://master-db:5432/mydb");
        config.setUsername("app_user");
        config.setPassword("master_password");
        config.setMaximumPoolSize(50);
        config.setConnectionTestQuery("SELECT 1");
        return new HikariDataSource(config);
    }
    
    @Bean
    public List<DataSource> slaveDataSources() {
        return Arrays.asList(
            createSlaveDataSource("slave-db-1:5432"),
            createSlaveDataSource("slave-db-2:5432"),
            createSlaveDataSource("slave-db-3:5432")
        );
    }
    
    @Bean
    public ReadOnlyDataSourceRouter readOnlyDataSourceRouter(List<DataSource> slaveDataSources) {
        return new LoadBalancedDataSourceRouter(slaveDataSources);
    }
}

@Service
@Transactional
public class UserService {
    
    @Autowired
    private DataSource masterDataSource;
    
    @Autowired  
    private ReadOnlyDataSourceRouter readOnlyDataSourceRouter;
    
    // Write operations go to master
    public User createUser(CreateUserRequest request) {
        try (Connection conn = masterDataSource.getConnection()) {
            PreparedStatement stmt = conn.prepareStatement(
                "INSERT INTO users (username, email, created_at) VALUES (?, ?, ?) RETURNING *");
            stmt.setString(1, request.getUsername());
            stmt.setString(2, request.getEmail());
            stmt.setTimestamp(3, Timestamp.valueOf(LocalDateTime.now()));
            
            ResultSet rs = stmt.executeQuery();
            return rs.next() ? mapToUser(rs) : null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to create user", e);
        }
    }
    
    // Read operations go to slaves with automatic failover
    @Transactional(readOnly = true)
    public List<User> searchUsers(String searchTerm, Pageable pageable) {
        DataSource readOnlyDataSource = readOnlyDataSourceRouter.getDataSource();
        
        try (Connection conn = readOnlyDataSource.getConnection()) {
            String sql = "SELECT * FROM users WHERE username ILIKE ? OR email ILIKE ? " +
                        "ORDER BY created_at DESC LIMIT ? OFFSET ?";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, "%" + searchTerm + "%");
            stmt.setString(2, "%" + searchTerm + "%");
            stmt.setInt(3, pageable.getPageSize());
            stmt.setInt(4, (int) pageable.getOffset());
            
            ResultSet rs = stmt.executeQuery();
            List<User> users = new ArrayList<>();
            while (rs.next()) {
                users.add(mapToUser(rs));
            }
            return users;
        } catch (SQLException e) {
            // Failover to master if slave is unavailable
            logger.warn("Slave database unavailable, failing over to master");
            return searchUsersOnMaster(searchTerm, pageable);
        }
    }
}

// Load balancer for read replicas
public class LoadBalancedDataSourceRouter implements ReadOnlyDataSourceRouter {
    
    private final List<DataSource> dataSources;
    private final AtomicInteger currentIndex = new AtomicInteger(0);
    private final Map<DataSource, Boolean> healthStatus = new ConcurrentHashMap<>();
    
    public LoadBalancedDataSourceRouter(List<DataSource> dataSources) {
        this.dataSources = dataSources;
        startHealthChecks();
    }
    
    @Override
    public DataSource getDataSource() {
        List<DataSource> healthyDataSources = dataSources.stream()
            .filter(ds -> healthStatus.getOrDefault(ds, true))
            .collect(Collectors.toList());
            
        if (healthyDataSources.isEmpty()) {
            throw new DataAccessException("No healthy read replicas available");
        }
        
        int index = currentIndex.getAndIncrement() % healthyDataSources.size();
        return healthyDataSources.get(index);
    }
    
    @Scheduled(fixedDelay = 30000) // Check every 30 seconds
    public void checkHealth() {
        dataSources.parallelStream().forEach(dataSource -> {
            boolean healthy = performHealthCheck(dataSource);
            healthStatus.put(dataSource, healthy);
        });
    }
    
    private boolean performHealthCheck(DataSource dataSource) {
        try (Connection conn = dataSource.getConnection()) {
            PreparedStatement stmt = conn.prepareStatement("SELECT 1");
            ResultSet rs = stmt.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            return false;
        }
    }
}
```

### Master-Master Replication

```java
@Configuration
public class MasterMasterConfig {
    
    @Bean
    public List<DataSource> masterDataSources() {
        return Arrays.asList(
            createMasterDataSource("master-1", "dc1"),
            createMasterDataSource("master-2", "dc2")
        );
    }
    
    @Bean
    public GeographicDataSourceRouter geoDataSourceRouter(List<DataSource> masters) {
        return new GeographicDataSourceRouter(masters);
    }
}

@Service
public class GeoDistributedUserService {
    
    @Autowired
    private GeographicDataSourceRouter geoRouter;
    
    public User createUser(CreateUserRequest request, String userLocation) {
        // Route to nearest master based on user location
        DataSource nearestMaster = geoRouter.getNearestMaster(userLocation);
        
        return executeOnMaster(nearestMaster, request);
    }
    
    // Handle replication conflicts
    @EventListener
    public void handleReplicationConflict(ReplicationConflictEvent event) {
        logger.warn("Replication conflict detected for user {}", event.getUserId());
        
        // Conflict resolution strategies:
        switch (event.getConflictType()) {
            case TIMESTAMP_BASED:
                resolveByLatestTimestamp(event);
                break;
            case MASTER_PRIORITY:
                resolveByMasterPriority(event);
                break;
            case MANUAL_REVIEW:
                queueForManualReview(event);
                break;
        }
    }
}
```

### Read Replicas with Lag Monitoring

```java
@Component
public class ReplicationMonitorService {
    
    @Autowired
    private List<DataSource> readReplicas;
    
    @Autowired
    private DataSource masterDataSource;
    
    private final MeterRegistry meterRegistry;
    
    @Scheduled(fixedRate = 60000) // Every minute
    public void monitorReplicationLag() {
        readReplicas.forEach(replica -> {
            try {
                Duration lag = measureReplicationLag(replica);
                
                // Record metrics
                meterRegistry.timer("database.replication.lag")
                    .record(lag);
                
                if (lag.toSeconds() > 30) {
                    // Alert if lag exceeds 30 seconds
                    alertService.sendAlert(
                        "High replication lag detected: " + lag.toSeconds() + " seconds",
                        AlertSeverity.WARNING
                    );
                }
                
                if (lag.toSeconds() > 300) {
                    // Remove from rotation if lag exceeds 5 minutes
                    dataSourceRouter.markAsUnhealthy(replica);
                }
                
            } catch (Exception e) {
                logger.error("Failed to measure replication lag", e);
                dataSourceRouter.markAsUnhealthy(replica);
            }
        });
    }
    
    private Duration measureReplicationLag(DataSource replica) throws SQLException {
        // Method 1: Compare LSN (Log Sequence Number)
        long masterLSN = getMasterLSN();
        long replicaLSN = getReplicaLSN(replica);
        
        // Method 2: Use timestamp markers
        Instant masterTimestamp = getLastMasterTimestamp();
        Instant replicaTimestamp = getLastReplicaTimestamp(replica);
        
        return Duration.between(replicaTimestamp, masterTimestamp);
    }
    
    private long getMasterLSN() throws SQLException {
        try (Connection conn = masterDataSource.getConnection()) {
            PreparedStatement stmt = conn.prepareStatement(
                "SELECT pg_current_wal_lsn()");
            ResultSet rs = stmt.executeQuery();
            return rs.next() ? rs.getLong(1) : 0;
        }
    }
}
```

---

## 🔀 Sharding and Partitioning

### Horizontal Sharding Strategies

#### Range-Based Sharding

```java
@Component
public class RangeBasedShardingStrategy implements ShardingStrategy {
    
    private final Map<String, DataSource> shards;
    private final List<ShardRange> shardRanges;
    
    public RangeBasedShardingStrategy() {
        this.shards = initializeShards();
        this.shardRanges = Arrays.asList(
            new ShardRange("shard1", 0L, 1000000L),
            new ShardRange("shard2", 1000001L, 2000000L),
            new ShardRange("shard3", 2000001L, 3000000L),
            new ShardRange("shard4", 3000001L, Long.MAX_VALUE)
        );
    }
    
    @Override
    public DataSource getShardForKey(Object key) {
        Long userId = (Long) key;
        
        ShardRange range = shardRanges.stream()
            .filter(r -> userId >= r.getMinValue() && userId <= r.getMaxValue())
            .findFirst()
            .orElseThrow(() -> new ShardingException("No shard found for user: " + userId));
            
        return shards.get(range.getShardId());
    }
    
    @Override
    public List<DataSource> getAllShardsForRange(Long minKey, Long maxKey) {
        return shardRanges.stream()
            .filter(range -> rangeOverlaps(range, minKey, maxKey))
            .map(range -> shards.get(range.getShardId()))
            .collect(Collectors.toList());
    }
    
    // Handle shard rebalancing when ranges become uneven
    public void rebalanceShards() {
        Map<String, Long> shardCounts = shards.keySet().stream()
            .collect(Collectors.toMap(
                shardId -> shardId,
                shardId -> countRecordsInShard(shards.get(shardId))
            ));
            
        // Identify hot shards (> 150% of average)
        double averageCount = shardCounts.values().stream()
            .mapToLong(Long::longValue)
            .average()
            .orElse(0.0);
            
        List<String> hotShards = shardCounts.entrySet().stream()
            .filter(entry -> entry.getValue() > averageCount * 1.5)
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());
            
        if (!hotShards.isEmpty()) {
            logger.warn("Hot shards detected: {}. Consider re-sharding.", hotShards);
            schedulingService.scheduleReSharding(hotShards);
        }
    }
}
```

#### Hash-Based Sharding

```java
@Component
public class ConsistentHashShardingStrategy implements ShardingStrategy {
    
    private final TreeMap<Long, String> ring = new TreeMap<>();
    private final Map<String, DataSource> shards;
    private final int virtualNodes = 150; // Virtual nodes per physical shard
    
    public ConsistentHashShardingStrategy(Map<String, DataSource> shards) {
        this.shards = shards;
        buildHashRing();
    }
    
    private void buildHashRing() {
        ring.clear();
        
        for (String shardId : shards.keySet()) {
            for (int i = 0; i < virtualNodes; i++) {
                String virtualNode = shardId + "#" + i;
                long hash = hashFunction(virtualNode);
                ring.put(hash, shardId);
            }
        }
        
        logger.info("Built consistent hash ring with {} virtual nodes", ring.size());
    }
    
    @Override
    public DataSource getShardForKey(Object key) {
        if (ring.isEmpty()) {
            throw new ShardingException("No shards available");
        }
        
        long hash = hashFunction(key.toString());
        Map.Entry<Long, String> entry = ring.ceilingEntry(hash);
        
        // Wrap around if needed
        if (entry == null) {
            entry = ring.firstEntry();
        }
        
        return shards.get(entry.getValue());
    }
    
    // Add new shard with minimal data movement
    public void addShard(String newShardId, DataSource dataSource) {
        shards.put(newShardId, dataSource);
        
        // Calculate which data needs to be moved
        Set<String> keysToMove = calculateKeysToMove(newShardId);
        
        // Perform data migration
        migrateData(keysToMove, dataSource);
        
        // Rebuild hash ring
        buildHashRing();
        
        logger.info("Added new shard {} and migrated {} keys", newShardId, keysToMove.size());
    }
    
    // Remove shard with data migration
    public void removeShard(String shardId) {
        if (!shards.containsKey(shardId)) {
            throw new ShardingException("Shard does not exist: " + shardId);
        }
        
        // Find target shards for data migration
        Map<String, List<String>> migrationPlan = planDataMigration(shardId);
        
        // Migrate data to other shards
        executeMigrationPlan(migrationPlan);
        
        // Remove from cluster
        shards.remove(shardId);
        buildHashRing();
        
        logger.info("Removed shard {} and migrated data", shardId);
    }
    
    private long hashFunction(String key) {
        // Use MurmurHash or FNV hash for better distribution
        return Hashing.murmur3_128().hashString(key, StandardCharsets.UTF_8).asLong();
    }
    
    private void migrateData(Set<String> keys, DataSource targetShard) {
        // Implement batch data migration with minimal downtime
        keys.parallelStream()
            .collect(Collectors.groupingBy(key -> key.hashCode() % 100)) // Group into batches
            .forEach((batchId, batchKeys) -> {
                try {
                    migrateBatch(batchKeys, targetShard);
                } catch (Exception e) {
                    logger.error("Failed to migrate batch {}", batchId, e);
                    throw new DataMigrationException("Migration failed", e);
                }
            });
    }
}
```

### Database Partitioning Implementation

```java
// Vertical Partitioning - Split by columns
@Entity
@Table(name = "user_core")
public class UserCore {
    @Id
    private Long userId;
    
    private String username;
    private String email;
    private LocalDateTime createdAt;
    private LocalDateTime lastLoginAt;
}

@Entity
@Table(name = "user_profile")  
public class UserProfile {
    @Id
    private Long userId;
    
    private String firstName;
    private String lastName;
    private String bio;
    private String avatarUrl;
    private LocalDate dateOfBirth;
}

@Entity
@Table(name = "user_preferences")
public class UserPreferences {
    @Id
    private Long userId;
    
    private String language;
    private String timezone;
    private boolean emailNotifications;
    private boolean pushNotifications;
    private Map<String, Object> customSettings;
}

// Horizontal Partitioning - Split by rows
@Service
public class PartitionedOrderService {
    
    private final Map<String, DataSource> datePartitions;
    
    // Route to partition based on order date
    public Order createOrder(CreateOrderRequest request) {
        String partitionKey = getPartitionKey(request.getOrderDate());
        DataSource partition = datePartitions.get(partitionKey);
        
        if (partition == null) {
            // Auto-create new partition for new month
            partition = createNewPartition(partitionKey);
            datePartitions.put(partitionKey, partition);
        }
        
        return executeOrderCreation(partition, request);
    }
    
    // Query across multiple partitions
    public List<Order> getOrderHistory(Long userId, LocalDate startDate, LocalDate endDate) {
        Set<String> relevantPartitions = getPartitionsForDateRange(startDate, endDate);
        
        List<CompletableFuture<List<Order>>> futures = relevantPartitions.stream()
            .map(partitionKey -> CompletableFuture.supplyAsync(() -> 
                queryPartition(datePartitions.get(partitionKey), userId, startDate, endDate)))
            .collect(Collectors.toList());
        
        return futures.stream()
            .flatMap(future -> future.join().stream())
            .sorted(Comparator.comparing(Order::getOrderDate).reversed())
            .collect(Collectors.toList());
    }
    
    private String getPartitionKey(LocalDate date) {
        return date.format(DateTimeFormatter.ofPattern("yyyy-MM"));
    }
    
    private Set<String> getPartitionsForDateRange(LocalDate start, LocalDate end) {
        Set<String> partitions = new HashSet<>();
        LocalDate current = start.withDayOfMonth(1); // Start of month
        
        while (!current.isAfter(end)) {
            partitions.add(getPartitionKey(current));
            current = current.plusMonths(1);
        }
        
        return partitions;
    }
    
    // Automated partition management
    @Scheduled(cron = "0 0 1 * * ?") // First day of each month
    public void managePartitions() {
        // Create new partition for current month
        String currentMonthKey = getPartitionKey(LocalDate.now());
        if (!datePartitions.containsKey(currentMonthKey)) {
            DataSource newPartition = createNewPartition(currentMonthKey);
            datePartitions.put(currentMonthKey, newPartition);
            logger.info("Created new partition for {}", currentMonthKey);
        }
        
        // Archive old partitions (older than 2 years)
        LocalDate archiveThreshold = LocalDate.now().minusYears(2);
        List<String> oldPartitions = datePartitions.keySet().stream()
            .filter(partitionKey -> {
                LocalDate partitionDate = LocalDate.parse(partitionKey + "-01");
                return partitionDate.isBefore(archiveThreshold);
            })
            .collect(Collectors.toList());
            
        for (String oldPartition : oldPartitions) {
            archivePartition(oldPartition);
            datePartitions.remove(oldPartition);
            logger.info("Archived partition {}", oldPartition);
        }
    }
}
```

---

## ⚡ ACID Properties and Transactions

### Transaction Management in Distributed Systems

```java
@Configuration
@EnableTransactionManagement
public class TransactionConfig {
    
    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
    
    // Distributed transaction manager for multiple data sources
    @Bean
    public JtaTransactionManager distributedTransactionManager() {
        JtaTransactionManager manager = new JtaTransactionManager();
        manager.setTransactionManager(atomikosTransactionManager());
        manager.setUserTransaction(atomikosUserTransaction());
        return manager;
    }
}

@Service
@Transactional
public class OrderTransactionService {
    
    @Autowired
    private OrderRepository orderRepository;
    
    @Autowired
    private PaymentService paymentService;
    
    @Autowired
    private InventoryService inventoryService;
    
    @Autowired
    private NotificationService notificationService;
    
    // ACID transaction example
    @Transactional(isolation = Isolation.READ_COMMITTED, 
                   propagation = Propagation.REQUIRED,
                   rollbackFor = Exception.class,
                   timeout = 30)
    public Order processOrder(CreateOrderRequest request) {
        try {
            // 1. Atomicity - All operations succeed or fail together
            Order order = createOrder(request);
            
            // 2. Consistency - Business rules are enforced
            validateOrderRules(order);
            
            // 3. Isolation - Concurrent transactions don't interfere
            reserveInventory(order.getItems());
            
            PaymentResult payment = processPayment(order);
            
            if (payment.isSuccessful()) {
                order.setStatus(OrderStatus.PAID);
                order.setPaymentId(payment.getPaymentId());
                
                // 4. Durability - Changes are persisted
                Order savedOrder = orderRepository.save(order);
                
                // Send notification (async, outside transaction)
                notificationService.sendOrderConfirmation(savedOrder.getId());
                
                return savedOrder;
            } else {
                throw new PaymentFailedException("Payment failed: " + payment.getErrorMessage());
            }
            
        } catch (Exception e) {
            // Transaction will be rolled back automatically
            logger.error("Order processing failed for request: {}", request, e);
            throw e;
        }
    }
    
    // Saga pattern for distributed transactions
    @Transactional
    public void processOrderSaga(CreateOrderRequest request) {
        SagaTransaction saga = sagaManager.createSaga("process-order");
        
        try {
            // Step 1: Create order
            saga.addStep(
                () -> orderService.createOrder(request),
                orderId -> orderService.cancelOrder(orderId)
            );
            
            // Step 2: Reserve inventory  
            saga.addStep(
                () -> inventoryService.reserveItems(request.getItems()),
                reservationId -> inventoryService.releaseReservation(reservationId)
            );
            
            // Step 3: Process payment
            saga.addStep(
                () -> paymentService.processPayment(request.getPaymentInfo()),
                paymentId -> paymentService.refundPayment(paymentId)
            );
            
            // Execute saga
            saga.execute();
            
        } catch (SagaExecutionException e) {
            // Saga will automatically compensate completed steps
            logger.error("Order saga failed: {}", e.getMessage(), e);
            throw new OrderProcessingException("Failed to process order", e);
        }
    }
}

// Custom transaction manager for complex scenarios
@Component
public class CustomTransactionManager {
    
    private final List<DataSource> dataSources;
    
    // Two-phase commit implementation
    public void executeDistributedTransaction(List<TransactionalOperation> operations) {
        Map<DataSource, Connection> connections = new HashMap<>();
        
        try {
            // Phase 1: Prepare
            for (TransactionalOperation operation : operations) {
                DataSource ds = operation.getDataSource();
                Connection conn = ds.getConnection();
                conn.setAutoCommit(false);
                connections.put(ds, conn);
                
                // Execute operation
                operation.execute(conn);
            }
            
            // Phase 2: Commit
            for (Connection conn : connections.values()) {
                conn.commit();
            }
            
        } catch (Exception e) {
            // Rollback all connections
            for (Connection conn : connections.values()) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    logger.error("Failed to rollback transaction", rollbackEx);
                }
            }
            throw new TransactionException("Distributed transaction failed", e);
        } finally {
            // Close all connections
            for (Connection conn : connections.values()) {
                try {
                    conn.close();
                } catch (SQLException e) {
                    logger.warn("Failed to close connection", e);
                }
            }
        }
    }
}
```

### Isolation Levels and Concurrency Control

```java
@Service
public class IsolationLevelDemoService {
    
    // Read Uncommitted - Allows dirty reads
    @Transactional(isolation = Isolation.READ_UNCOMMITTED)
    public List<Product> getProductsReadUncommitted() {
        // Can read uncommitted changes from other transactions
        // Fastest but allows dirty reads
        return productRepository.findAll();
    }
    
    // Read Committed - Prevents dirty reads
    @Transactional(isolation = Isolation.READ_COMMITTED)
    public BigDecimal calculateTotalRevenue() {
        // Can only read committed data
        // May see different values if read twice in same transaction (non-repeatable read)
        return orderRepository.sumTotalAmount();
    }
    
    // Repeatable Read - Prevents dirty and non-repeatable reads
    @Transactional(isolation = Isolation.REPEATABLE_READ)
    public void generateConsistentReport() {
        // Same query will return same results throughout transaction
        // But may see phantom rows (new insertions)
        
        List<Order> orders1 = orderRepository.findByStatus(OrderStatus.COMPLETED);
        
        // Some processing...
        processOrders(orders1);
        
        List<Order> orders2 = orderRepository.findByStatus(OrderStatus.COMPLETED);
        // orders1 and orders2 will have same existing rows
        // but orders2 may have additional new rows
    }
    
    // Serializable - Highest isolation level
    @Transactional(isolation = Isolation.SERIALIZABLE)  
    public void criticalFinancialOperation() {
        // Complete isolation - transactions appear to execute serially
        // Prevents dirty reads, non-repeatable reads, and phantom reads
        // Slowest performance due to locking
        
        Account account = accountRepository.findByIdWithLock(accountId);
        
        BigDecimal balance = account.getBalance();
        BigDecimal newBalance = balance.subtract(withdrawAmount);
        
        if (newBalance.compareTo(BigDecimal.ZERO) < 0) {
            throw new InsufficientFundsException();
        }
        
        account.setBalance(newBalance);
        accountRepository.save(account);
    }
    
    // Optimistic locking for high-concurrency scenarios
    @Entity
    @Table(name = "products")
    public class Product {
        @Id
        private Long id;
        
        private String name;
        private BigDecimal price;
        private Integer stockQuantity;
        
        @Version
        private Long version; // Optimistic locking
    }
    
    @Service
    public class OptimisticLockingService {
        
        @Retryable(value = OptimisticLockException.class, maxAttempts = 3)
        @Transactional
        public void updateProductStock(Long productId, Integer quantityChange) {
            Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));
                
            Integer currentStock = product.getStockQuantity();
            Integer newStock = currentStock + quantityChange;
            
            if (newStock < 0) {
                throw new InsufficientStockException();
            }
            
            product.setStockQuantity(newStock);
            
            try {
                productRepository.save(product); // Version check happens here
            } catch (OptimisticLockException e) {
                // Retry with @Retryable
                logger.warn("Optimistic lock conflict for product {}, retrying...", productId);
                throw e;
            }
        }
    }
    
    // Pessimistic locking for critical resources
    @Repository
    public interface AccountRepository extends JpaRepository<Account, Long> {
        
        @Lock(LockModeType.PESSIMISTIC_WRITE)
        @Query("SELECT a FROM Account a WHERE a.id = :id")
        Account findByIdWithLock(@Param("id") Long id);
        
        @Lock(LockModeType.PESSIMISTIC_READ)
        @Query("SELECT a FROM Account a WHERE a.userId = :userId")
        List<Account> findByUserIdWithReadLock(@Param("userId") Long userId);
    }
}
```

---

## ❓ Interview Questions

### Fundamental Database Questions

**Q: Explain when you would choose SQL vs NoSQL databases with specific examples.**

A: **SQL Database Use Cases:**

```java
// Financial System - Strong consistency required
@Entity
@Table(name = "bank_transactions")
public class BankTransaction {
    @Id
    private Long id;
    
    @Column(name = "from_account", nullable = false)
    private Long fromAccount;
    
    @Column(name = "to_account", nullable = false)
    private Long toAccount;
    
    @Column(name = "amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal amount;
    
    @Enumerated(EnumType.STRING)
    private TransactionStatus status;
}

@Service
@Transactional
public class BankingService {
    
    // ACID properties crucial for financial accuracy
    public void transferFunds(Long fromAccount, Long toAccount, BigDecimal amount) {
        Account from = accountRepository.findByIdWithLock(fromAccount);
        Account to = accountRepository.findByIdWithLock(toAccount);
        
        if (from.getBalance().compareTo(amount) < 0) {
            throw new InsufficientFundsException();
        }
        
        from.debit(amount);
        to.credit(amount);
        
        // Both operations succeed or both fail
        accountRepository.saveAll(Arrays.asList(from, to));
        
        // Create audit trail
        transactionRepository.save(new BankTransaction(fromAccount, toAccount, amount));
    }
}
```

**NoSQL Database Use Cases:**

```java
// Social Media - Flexible schema, high scale
@Document(collection = "user_posts")
public class SocialPost {
    @Id
    private String id;
    
    private String userId;
    private String content;
    private List<String> mediaUrls;
    private Map<String, Object> metadata; // Flexible schema
    
    private List<Comment> comments; // Embedded for read performance
    private Set<String> likedBy;
    private List<String> hashtags;
    
    private LocalDateTime createdAt;
}

@Service
public class SocialMediaService {
    
    // Handle massive scale with eventual consistency
    public void createPost(SocialPost post) {
        // Write to MongoDB - flexible schema
        socialPostRepository.save(post);
        
        // Update user's timeline asynchronously
        eventPublisher.publishEvent(new PostCreatedEvent(post));
        
        // Update hashtag trending data
        hashtagService.updateTrending(post.getHashtags());
    }
    
    // Complex aggregation queries
    public List<TrendingHashtag> getTrendingHashtags() {
        Aggregation aggregation = Aggregation.newAggregation(
            Aggregation.unwind("hashtags"),
            Aggregation.match(Criteria.where("createdAt").gte(LocalDateTime.now().minusDays(1))),
            Aggregation.group("hashtags").count().as("count"),
            Aggregation.sort(Sort.Direction.DESC, "count"),
            Aggregation.limit(10)
        );
        
        return mongoTemplate.aggregate(aggregation, "user_posts", TrendingHashtag.class)
            .getMappedResults();
    }
}
```

**Decision Matrix:**
- **SQL**: Complex transactions, reporting, strong consistency requirements
- **NoSQL Document**: Content management, catalogs, user profiles, flexible schema needs  
- **NoSQL Key-Value**: Caching, sessions, simple lookup patterns
- **NoSQL Column-Family**: Time-series data, analytics, write-heavy workloads
- **NoSQL Graph**: Social networks, recommendations, fraud detection

**Q: Design a database architecture that can handle 1M+ concurrent users.**

A: **Multi-tier Database Architecture:**

```java
// Tier 1: Caching Layer
@Configuration
public class CachingArchitecture {
    
    @Bean
    public CacheManager l1CacheManager() {
        // Application-level cache (Caffeine)
        return new CaffeineCacheManager();
    }
    
    @Bean
    public RedisClusterConfiguration redisCluster() {
        // Distributed cache cluster
        return new RedisClusterConfiguration()
            .clusterNode("redis-1", 6379)
            .clusterNode("redis-2", 6379)
            .clusterNode("redis-3", 6379);
    }
}

// Tier 2: Read Scaling  
@Configuration
public class ReadScalingConfig {
    
    @Bean
    public List<DataSource> readReplicas() {
        return IntStream.range(1, 11) // 10 read replicas
            .mapToObj(i -> createReadReplica("read-replica-" + i))
            .collect(Collectors.toList());
    }
    
    @Bean
    public LoadBalancer readLoadBalancer(List<DataSource> readReplicas) {
        return new WeightedRoundRobinLoadBalancer(readReplicas);
    }
}

// Tier 3: Write Scaling (Sharding)
@Service
public class ShardedWriteService {
    
    private final ConsistentHashRing shardRing;
    private final Map<String, DataSource> writeShards;
    
    public ShardedWriteService() {
        this.writeShards = createWriteShards(16); // 16 write shards
        this.shardRing = new ConsistentHashRing(writeShards.keySet());
    }
    
    public User createUser(CreateUserRequest request) {
        String userId = generateUserId();
        String shardId = shardRing.getShardId(userId);
        DataSource shard = writeShards.get(shardId);
        
        return executeUserCreation(shard, request);
    }
}

// Tier 4: Data Partitioning
@Service
public class DataPartitioningService {
    
    // Hot data (recent, frequently accessed)
    @Autowired
    private DataSource hotDataSource;
    
    // Warm data (older, less frequently accessed)
    @Autowired
    private DataSource warmDataSource;
    
    // Cold data (archived, rarely accessed)
    @Autowired
    private DataSource coldDataSource;
    
    public User getUser(Long userId) {
        // Try hot data first
        User user = findInHotData(userId);
        if (user != null) return user;
        
        // Try warm data
        user = findInWarmData(userId);
        if (user != null) {
            // Promote to hot data if accessed
            promoteToHotData(user);
            return user;
        }
        
        // Finally try cold data
        return findInColdData(userId);
    }
}
```

**Architecture Components:**

1. **Connection Pool Management**:
   ```java
   @Configuration
   public class ConnectionPoolConfig {
       
       @Bean
       public HikariDataSource masterDataSource() {
           HikariConfig config = new HikariConfig();
           config.setMaximumPoolSize(200); // Large pool for master
           config.setConnectionTimeout(5000); // 5 second timeout
           config.setIdleTimeout(300000); // 5 minutes idle timeout
           config.setMaxLifetime(1800000); // 30 minutes max lifetime
           return new HikariDataSource(config);
       }
   }
   ```

2. **Auto-scaling Strategy**:
   ```java
   @Component
   public class DatabaseAutoScaler {
       
       @EventListener
       public void handleHighLoad(DatabaseLoadEvent event) {
           if (event.getConnectionPoolUtilization() > 80) {
               // Add more read replicas
               addReadReplica();
           }
           
           if (event.getCpuUtilization() > 85) {
               // Scale up existing instances
               scaleUpInstances();
           }
           
           if (event.getQueriesPerSecond() > 50000) {
               // Add more shards
               addShard();
           }
       }
   }
   ```

**Capacity Planning:**
- **1M concurrent users** → ~100K active queries/sec
- **Read Replicas**: 10-15 replicas (10K queries/sec each)
- **Write Shards**: 16 shards (5K writes/sec each)
- **Cache Hit Ratio**: Target 95%+ to reduce database load
- **Connection Pools**: 200 connections per database instance

**Q: How would you handle database migrations in a microservices architecture?**

A: **Zero-downtime Migration Strategy:**

```java
// Phase 1: Backward Compatible Changes
@Entity
@Table(name = "users")
public class User {
    @Id
    private Long id;
    
    private String username;
    private String email;
    
    // New column - nullable for backward compatibility
    @Column(name = "phone_number", nullable = true)
    private String phoneNumber;
    
    // Old column - deprecated but still present
    @Column(name = "full_name")
    @Deprecated
    private String fullName;
    
    // New columns
    @Column(name = "first_name")
    private String firstName;
    
    @Column(name = "last_name") 
    private String lastName;
}

// Migration Service
@Service
public class DatabaseMigrationService {
    
    // Step 1: Add new columns (backward compatible)
    @MigrationStep(version = "1.1.0", phase = Phase.EXPAND)
    public void addNewColumns() {
        String sql = """
            ALTER TABLE users 
            ADD COLUMN phone_number VARCHAR(20),
            ADD COLUMN first_name VARCHAR(100),
            ADD COLUMN last_name VARCHAR(100)
            """;
        
        executeWithRetry(sql);
    }
    
    // Step 2: Dual write to old and new columns
    @Service
    public class UserServiceV1_1 {
        
        public User updateUser(Long userId, UpdateUserRequest request) {
            User user = userRepository.findById(userId).orElseThrow();
            
            // Write to both old and new columns during transition
            user.setFullName(request.getFirstName() + " " + request.getLastName());
            user.setFirstName(request.getFirstName());
            user.setLastName(request.getLastName());
            
            return userRepository.save(user);
        }
    }
    
    // Step 3: Background data migration
    @Async
    @MigrationStep(version = "1.1.0", phase = Phase.MIGRATE) 
    public void migrateExistingData() {
        int batchSize = 1000;
        int offset = 0;
        
        while (true) {
            List<User> users = userRepository.findUsersWithNullFirstName(
                PageRequest.of(offset / batchSize, batchSize));
                
            if (users.isEmpty()) break;
            
            users.parallelStream().forEach(user -> {
                if (user.getFullName() != null && user.getFirstName() == null) {
                    String[] parts = user.getFullName().split(" ", 2);
                    user.setFirstName(parts[0]);
                    user.setLastName(parts.length > 1 ? parts[1] : "");
                }
            });
            
            userRepository.saveAll(users);
            offset += batchSize;
            
            // Throttle to avoid overwhelming database
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }
    
    // Step 4: Remove old columns (after all services updated)
    @MigrationStep(version = "1.2.0", phase = Phase.CONTRACT)
    public void removeOldColumns() {
        // Only after confirming no services use full_name
        String sql = "ALTER TABLE users DROP COLUMN full_name";
        executeWithRetry(sql);
    }
}

// Service Version Management
@Component
public class ServiceVersionManager {
    
    private final Map<String, String> serviceVersions = new ConcurrentHashMap<>();
    
    public void updateServiceVersion(String serviceName, String version) {
        serviceVersions.put(serviceName, version);
        
        // Check if all services are ready for next migration phase
        if (allServicesSupport(version)) {
            migrationOrchestrator.proceedToNextPhase();
        }
    }
    
    public boolean canExecuteContractPhase() {
        // Ensure all services have been updated to use new schema
        return serviceVersions.values().stream()
            .allMatch(version -> Version.parse(version).isGreaterThan("1.1.0"));
    }
}

// Cross-service Migration Coordinator
@Component
public class MigrationOrchestrator {
    
    private final List<MicroserviceClient> services;
    
    public void coordinateMigration(String migrationId) {
        MigrationPlan plan = migrationPlanRepository.findById(migrationId);
        
        // Phase 1: Expand - Add new columns/tables
        executePhaseAcrossServices(plan.getExpandSteps());
        
        // Phase 2: Migrate - Dual write and backfill data
        executePhaseAcrossServices(plan.getMigrateSteps());
        
        // Wait for all services to confirm migration complete
        waitForServiceConfirmation(plan);
        
        // Phase 3: Contract - Remove old columns/tables
        executePhaseAcrossServices(plan.getContractSteps());
    }
    
    private void waitForServiceConfirmation(MigrationPlan plan) {
        boolean allConfirmed = false;
        int attempts = 0;
        
        while (!allConfirmed && attempts < 30) { // Max 5 minutes
            allConfirmed = services.stream()
                .allMatch(service -> service.isMigrationComplete(plan.getId()));
                
            if (!allConfirmed) {
                try {
                    Thread.sleep(10000); // Wait 10 seconds
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    throw new MigrationException("Migration interrupted");
                }
            }
            attempts++;
        }
        
        if (!allConfirmed) {
            throw new MigrationException("Not all services confirmed migration completion");
        }
    }
}
```

**Migration Best Practices:**

1. **Expand-Migrate-Contract Pattern**:
   - **Expand**: Add new schema elements (backward compatible)
   - **Migrate**: Dual write and backfill data
   - **Contract**: Remove old schema elements

2. **Feature Flags for Database Schema**:
   ```java
   @Service
   public class UserService {
       
       @Value("${feature.new-user-schema:false}")
       private boolean useNewSchema;
       
       public User createUser(CreateUserRequest request) {
           if (useNewSchema) {
               return createUserNewSchema(request);
           } else {
               return createUserLegacySchema(request);
           }
       }
   }
   ```

3. **Rollback Strategy**:
   - Always maintain ability to rollback
   - Keep old columns until rollback window expires
   - Version database schema changes
   - Test rollback procedures regularly

---

## 🏷️ Tags

#database #sql #nosql #replication #sharding #partitioning #acid #cap-theorem #performance #optimization #migrations #transactions #system-design #sde2

## 📚 Related Topics

- [[Scalability-Guide|Database Scaling Strategies]]
- [[Caching-Guide|Database Caching Patterns]]  
- [[Performance-Guide|Query Optimization]]
- [[Security-Guide|Database Security]]
- [[Monitoring-Guide|Database Monitoring]]