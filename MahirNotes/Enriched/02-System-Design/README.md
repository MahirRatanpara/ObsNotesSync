# 🏗️ System Design - SDE2 Interview Master Guide

> **"Good system design is about making the right trade-offs at the right scale"**

---

## 📋 Quick Navigation

| **Core Concepts** | **Scalability Topics** | **Real Systems** |
|---|---|---|
| [Scalability Fundamentals](#scalability-fundamentals) | [Load Balancing](#load-balancing) | [Design Problems](#-design-problems) |
| [Database Design](#database-design) | [Caching Strategies](#caching-strategies) | [Case Studies](#-case-studies) |
| [Distributed Systems](#distributed-systems) | [Message Queues](#message-queues) | [Interview Framework](#-interview-framework) |
| [Microservices](#microservices-architecture) | [API Gateway](#api-gateway) | [Trade-offs Analysis](#-trade-offs-analysis) |

---

## 🎯 Interview Success Strategy

### 📚 **Phase 1: Fundamentals (Week 1-2)**
**Goal:** Master core building blocks and concepts
- ✅ Understand scalability principles (horizontal vs vertical)
- ✅ Database basics (SQL vs NoSQL, ACID vs BASE)
- ✅ Caching patterns and CDN concepts
- ✅ Load balancing and failover strategies

### 🔥 **Phase 2: Distributed Systems (Week 3-4)**  
**Goal:** Learn how components work together at scale
- ✅ CAP theorem and consistency models
- ✅ Partitioning and sharding strategies
- ✅ Message queues and event-driven architecture
- ✅ Service discovery and API gateway patterns

### 🚀 **Phase 3: Real System Design (Week 5-6)**
**Goal:** Practice designing complete systems end-to-end
- ✅ URL shortener, Chat system, Social media feed
- ✅ Video streaming, Search engine, Recommendation system
- ✅ Mock interviews and trade-off discussions
- ✅ Performance estimation and bottleneck analysis

---

## 🏗️ Core Concepts

### Scalability Fundamentals
**Key Topics:** Horizontal vs Vertical scaling, Load distribution, Bottleneck identification
**Interview Weight:** 🔥🔥🔥🔥🔥 (Very High)

[📖 Complete Guide →](./Scalability-Fundamentals.md)

---

### Database Design  
**Key Topics:** SQL vs NoSQL, Sharding, Replication, ACID properties, CAP theorem
**Interview Weight:** 🔥🔥🔥🔥🔥 (Very High)

[📖 Complete Guide →](./Database-Design.md)

---

### Caching Strategies
**Key Topics:** Cache-aside, Write-through, Write-behind, CDN, Redis patterns
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](Caching-Strategies.md)

---

### Load Balancing
**Key Topics:** Layer 4 vs Layer 7, Round-robin, Health checks, Session affinity
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Load-Balancing.md)

---

### Distributed Systems
**Key Topics:** Consensus algorithms, Distributed transactions, Event sourcing
**Interview Weight:** 🔥🔥🔥 (Medium-High)

[📖 Complete Guide →](./Distributed-Systems.md)

---

### Message Queues
**Key Topics:** Kafka, RabbitMQ, SQS, Event-driven architecture, Pub-Sub patterns
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Message-Queues.md)

---

### Microservices Architecture
**Key Topics:** Service decomposition, API Gateway, Service mesh, Circuit breakers
**Interview Weight:** 🔥🔥🔥🔥 (High)

[📖 Complete Guide →](./Microservices-Architecture.md)

---

### API Gateway
**Key Topics:** Rate limiting, Authentication, Request routing, Protocol translation
**Interview Weight:** 🔥🔥🔥 (Medium-High)

[📖 Complete Guide →](./API-Gateway.md)

---

## 🎯 Design Problems

### **🔥 Must-Practice Systems** #must-do

#### **Easy Level** (Foundation)
1. ✅ [Design URL Shortener](./Design-Problems/URL-Shortener.md) #must-do #faang
   - **Focus:** Database design, caching, base62 encoding
   - **Companies:** Google, Amazon, Microsoft
   - **Time Allotment:** 45 minutes

2. ✅ [Design Key-Value Store](./Design-Problems/Key-Value-Store.md) #must-do
   - **Focus:** Consistent hashing, replication, CAP theorem  
   - **Companies:** All FAANG
   - **Time Allotment:** 45 minutes

3. ✅ [Design Rate Limiter](./Design-Problems/Rate-Limiter.md) #must-do
   - **Focus:** Algorithms (token bucket, sliding window), Redis
   - **Companies:** Stripe, Twitter, API companies
   - **Time Allotment:** 30 minutes

#### **Medium Level** (Core Practice)
4. ✅ [Design Chat System](./Design-Problems/Chat-System.md) #must-do #faang
   - **Focus:** WebSockets, message ordering, online presence
   - **Companies:** Facebook, WhatsApp, Slack
   - **Time Allotment:** 60 minutes

5. ✅ [Design Notification System](./Design-Problems/Notification-System.md) #medium
   - **Focus:** Multi-channel delivery, reliability, rate limiting
   - **Companies:** Uber, Netflix, Airbnb
   - **Time Allotment:** 45 minutes

6. ✅ [Design Web Crawler](./Design-Problems/Web-Crawler.md) #medium
   - **Focus:** BFS/DFS, politeness, duplicate detection
   - **Companies:** Google, Bing search teams
   - **Time Allotment:** 60 minutes

7. ✅ [Design News Feed](./Design-Problems/News-Feed.md) #must-do #faang
   - **Focus:** Timeline generation (push vs pull), ranking algorithms
   - **Companies:** Facebook, Twitter, LinkedIn
   - **Time Allotment:** 60 minutes

#### **Hard Level** (Advanced Mastery)  
8. ✅ [Design YouTube](./Design-Problems/Video-Streaming.md) #hard #faang
   - **Focus:** Video encoding, CDN, storage optimization
   - **Companies:** YouTube, Netflix, TikTok
   - **Time Allotment:** 60 minutes

9. ✅ [Design Search Engine](./Design-Problems/Search-Engine.md) #hard
   - **Focus:** Web crawling, indexing, ranking algorithms  
   - **Companies:** Google, Bing, Elasticsearch
   - **Time Allotment:** 75 minutes

10. ✅ [Design Uber](./Design-Problems/Ride-Sharing.md) #hard #faang
    - **Focus:** Real-time matching, geolocation, pricing
    - **Companies:** Uber, Lyft, transportation
    - **Time Allotment:** 75 minutes

---

## 📊 Case Studies

### **🔵 Google Scale Systems** #google-scale
- **Search Engine:** PageRank, MapReduce, Distributed indexing
- **Gmail:** Storage optimization, Spam filtering, Real-time sync
- **Google Drive:** File synchronization, Conflict resolution, Versioning

### **🔶 Amazon Scale Systems** #amazon-scale  
- **E-commerce Platform:** Product catalog, Inventory management, Order processing
- **AWS S3:** Object storage, Durability guarantees, Global replication
- **Recommendation Engine:** Collaborative filtering, Real-time personalization

### **🔷 Meta Scale Systems** #meta-scale
- **Facebook Timeline:** News feed ranking, Content delivery, Real-time updates
- **WhatsApp Messaging:** End-to-end encryption, Message delivery, Presence system
- **Instagram:** Image processing, Story features, Social graph storage

### **🔴 Netflix Scale Systems** #netflix-scale
- **Video Streaming:** Content delivery, Adaptive bitrate, Regional CDN
- **Recommendation System:** Machine learning pipelines, A/B testing, Personalization
- **Chaos Engineering:** Fault tolerance, Service reliability, Auto-healing

---

## 🛠️ Interview Framework

### **📋 System Design Interview Process** #interview-process

#### **Step 1: Requirements Clarification (5-10 minutes)**
**Essential Questions to Ask:**
- What is the scale? (users, data volume, requests per second)
- What features are most critical?  
- What are the performance requirements? (latency, availability)
- Are there any constraints? (budget, technology stack)

**Example Template:**
```
"Let me clarify the requirements:
- How many users are we expecting? Daily/Monthly active users?
- What's the read/write ratio?
- Do we need real-time features?
- What's our availability target? 99.9%? 99.99%?
- Are there any compliance requirements?"
```

#### **Step 2: High-Level Architecture (10-15 minutes)**
**Design Process:**
1. Draw major components (client, load balancer, servers, database)
2. Show data flow between components
3. Identify key services and their responsibilities  
4. Discuss API design (REST endpoints, data models)

**Template Approach:**
```
Client → Load Balancer → API Gateway → Microservices → Database
                                    ↓
                                 Cache Layer
```

#### **Step 3: Deep Dive (15-20 minutes)**
**Focus Areas Based on System:**
- **Database schema** and data modeling
- **Caching strategy** and cache invalidation
- **Load balancing** and service discovery  
- **Message queues** and async processing
- **Security** and authentication

#### **Step 4: Scale and Optimize (10-15 minutes)**
**Scaling Strategies:**
- Identify bottlenecks
- Propose scaling solutions (horizontal scaling, sharding)
- Discuss monitoring and alerting
- Address failure scenarios and disaster recovery

#### **Step 5: Summary and Trade-offs (5 minutes)**
**Wrap-up Points:**
- Summarize key design decisions
- Discuss alternative approaches and their trade-offs
- Mention areas for future optimization
- Acknowledge limitations of current design

---

## ⚖️ Trade-offs Analysis

### **Common Design Decisions** #trade-offs

#### **SQL vs NoSQL**
| **SQL** | **NoSQL** |
|---------|-----------|
| ✅ ACID compliance | ✅ Horizontal scaling |
| ✅ Complex queries | ✅ Flexible schema |
| ✅ Data consistency | ✅ High availability |
| ❌ Vertical scaling limits | ❌ Eventual consistency |
| ❌ Schema rigidity | ❌ Limited query capabilities |

#### **Synchronous vs Asynchronous Processing**
| **Sync** | **Async** |
|----------|-----------|
| ✅ Immediate consistency | ✅ Better performance |
| ✅ Simpler error handling | ✅ Higher throughput |
| ✅ Easier debugging | ✅ Fault tolerance |
| ❌ Higher latency | ❌ Complex error handling |
| ❌ Reduced throughput | ❌ Eventual consistency |

#### **Microservices vs Monolith**
| **Microservices** | **Monolith** |
|-------------------|--------------|
| ✅ Independent scaling | ✅ Simpler deployment |
| ✅ Technology diversity | ✅ Easier debugging |
| ✅ Fault isolation | ✅ Better performance |
| ❌ Complex operations | ❌ Scaling limitations |
| ❌ Network overhead | ❌ Technology constraints |

---

## 📈 Performance Estimation

### **Back-of-Envelope Calculations** #estimation

#### **Storage Calculations**
```
Daily Active Users: 100M
Average data per user per day: 1KB
Daily storage: 100M × 1KB = 100GB/day
Annual storage: 100GB × 365 = 36TB/year

With 3x replication: 36TB × 3 = 108TB/year
```

#### **Bandwidth Calculations**  
```
Peak QPS: 100M users / 86400 seconds = 1,157 QPS
Peak with 3x factor: 3,471 QPS
Average response size: 1KB
Bandwidth: 3,471 × 1KB = 3.47 MB/s
```

#### **Database Sizing**
```
Users: 1B users
User data: 1KB per user = 1TB
Posts: 100M posts/day × 10KB = 1TB/day
With indexes (3x): 3TB/day
Monthly: 90TB, Yearly: 1PB
```

### **Latency Numbers Every Engineer Should Know**
| Operation | Latency |
|-----------|---------|
| L1 cache reference | 0.5 ns |
| Branch mispredict | 5 ns |
| L2 cache reference | 7 ns |
| Memory reference | 100 ns |
| SSD read | 150,000 ns |
| Network round trip | 500,000 ns |
| Disk read | 20,000,000 ns |

---

## 🧠 Common Mistakes to Avoid

### **❌ Interview Killers** #pitfalls

1. **Jumping to Solutions Too Quickly**
   - ❌ Starting to design before understanding requirements
   - ✅ Spend 10+ minutes on requirements clarification

2. **Ignoring Non-Functional Requirements**  
   - ❌ Only focusing on features, ignoring scale/performance
   - ✅ Always ask about QPS, data size, availability requirements

3. **Over-Engineering for Scale**
   - ❌ Designing for Google scale when building for 1000 users
   - ✅ Start simple, then scale based on actual requirements

4. **Not Considering Failure Scenarios**
   - ❌ Designing happy path only
   - ✅ Discuss what happens when components fail

5. **Poor Communication**
   - ❌ Drawing silently without explanation
   - ✅ Explain your thinking process as you design

### **🛡️ Recovery Strategies**

**When Stuck:**
- Go back to requirements and re-examine
- Start with a simple solution and build up
- Ask clarifying questions to buy time
- Draw what you know and build from there

**When Making Mistakes:**
- Acknowledge the issue when you realize it
- Explain the correct approach  
- Show how you'd fix the design
- Demonstrate learning and adaptability

---

## 📚 Study Resources

### **📖 Essential Books**
- *Designing Data-Intensive Applications* - Martin Kleppmann
- *System Design Interview* - Alex Xu (Volumes 1 & 2)  
- *Building Microservices* - Sam Newman
- *High Performance MySQL* - Baron Schwartz

### **🌐 Online Resources**
- [High Scalability](http://highscalability.com/) - Real system architectures
- [AWS Architecture Center](https://aws.amazon.com/architecture/) - Cloud design patterns
- [System Design Primer](https://github.com/donnemartin/system-design-primer) - GitHub repo
- [Grokking the System Design](https://www.educative.io/courses/grokking-the-system-design-interview) - Interactive course

### **🎥 Video Channels**
- [Gaurav Sen](https://www.youtube.com/c/GauravSensei) - System design concepts
- [Tech Dummies Narendra L](https://www.youtube.com/c/TechDummiesNarendraL) - Design problems
- [Success in Tech](https://www.youtube.com/c/SuccessInTech) - Interview prep
- [Engineering with Utsav](https://www.youtube.com/c/EngineeringWithUtsav) - Deep dives

### **🏢 Company Engineering Blogs**
- [Netflix Tech Blog](https://netflixtechblog.com/)
- [Uber Engineering](https://eng.uber.com/)  
- [Airbnb Engineering](https://medium.com/airbnb-engineering)
- [Pinterest Engineering](https://medium.com/pinterest-engineering)
- [Dropbox Tech Blog](https://dropbox.tech/)

---

## 🎓 Mastery Progression

**✅ Beginner (Can explain basic concepts)**
- [ ] Understand scaling principles and bottlenecks
- [ ] Know basic database concepts (SQL vs NoSQL)
- [ ] Can design simple systems (URL shortener)
- [ ] Familiar with caching and load balancing

**✅ Intermediate (Can design medium complexity systems)**
- [ ] Designed 5+ complete systems end-to-end
- [ ] Understand distributed system concepts (CAP, consistency)
- [ ] Can identify and address system bottlenecks
- [ ] Comfortable with trade-off discussions

**✅ Advanced (Can handle any system design interview)**
- [ ] Designed 15+ systems including complex ones
- [ ] Can estimate system capacity and performance  
- [ ] Deep understanding of real-world system architectures
- [ ] Can lead system design discussions confidently

---

**Study Progress Tracker:**
- [ ] Fundamental Concepts (0/8 topics mastered)
- [ ] Design Problems (0/10 systems designed)
- [ ] Case Studies (0/4 companies analyzed)
- [ ] Mock Interviews (0/5 completed)
- [ ] Trade-offs Analysis (0/3 categories covered)

**Last Updated:** August 2025  
**Next Review:** Weekly system design mock interview