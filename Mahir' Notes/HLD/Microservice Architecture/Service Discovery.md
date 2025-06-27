# 🧭 Service Discovery - Complete Guide

## 📌 What is Service Discovery?

Service discovery is the mechanism by which applications dynamically discover network locations (IP: port) of services they depend on — especially critical in microservices where services are created/destroyed dynamically.

Service discovery lets a service (say Service A) locate another service (say Service B) **without hardcoding IPs/ports**. It typically consists of:
- **Service Registry**: A database where all services register their availability and health.
- **Service Clients**: Services use this registry to look up the address of other services.

---

## 🧱 Components

| Component| Role |
|------------------|------|
| **API Gateway**  | Entry point for client requests. Routes to internal services. |
| **Load Balancer**| Distributes traffic across multiple service instances. |
| **Service Registry** | Tracks active services and their IP:port (e.g., Eureka, Consul, Cloud Map). |
| **Network Routing/IPs** | Actual transport-level addresses used by clients/services. |

---

## 🔄 Types of Service Discovery

### 🔹 Client-Side Service Discovery
- Client queries the service registry and picks an instance.
- Client performs load balancing.

**Example:** Netflix Ribbon + Eureka  
**Flow:**
```
Client → Service Registry → Pick instance → Direct request to service
```

---

### 🔹 Server-Side Service Discovery
- Client sends request to API Gateway or Load Balancer.
- Gateway/LB queries registry and forwards request to a healthy instance.

**Example:** Spring Cloud Gateway + Eureka  
**Flow:**
```
Client → API Gateway → Service Registry → Pick instance → Service
```

---

# 🛠️API Gateway and Service Discovery

### 🔹 Flow (Spring Cloud Gateway + Eureka)
1. Services register with Eureka.
2. Gateway registers itself and subscribes to registry.
3. Client calls `/users/123`
4. Gateway routes using URI like `lb://user-service`.
5. Gateway queries Eureka → gets instance list.
6. Picks one and forwards request.

### 🔹 Example Config

```yaml
# application.yml (Gateway)
spring:
  cloud:
gateway:
  routes:
- id: user-service
  uri: lb://user-service
  predicates:
- Path=/users/**
eureka:
  client:
service-url:
  defaultZone: http://localhost:8761/eureka/
```

---

# 📘 Load Balancing with Eureka in Spring Boot

## 🔍 Who Does the Load Balancing?

In a Spring Boot + Eureka setup:

- The **client application itself** does the load balancing.
- It uses:
  - ✅ **Spring Cloud LoadBalancer** (modern)
  - 🟡 Or **Netflix Ribbon** (deprecated/legacy)

> Eureka only gives a **list of available servers**. It does **not** balance traffic itself.

---

## ⚙️ How Does It Work?

### Example: Calling `order-service`

1. **You make a request using a service name**:
   ```http
   GET http://order-service/api/orders
   ```

2. **Eureka responds with instances**:
   ```text
   - http://10.0.0.1:8080
   - http://10.0.0.2:8080
   - http://10.0.0.3:8080
   ```

3. **Spring Cloud LoadBalancer picks one**:
   - Default strategy: **Round Robin**
   - Other options:
 - Random
 - Weighted
 - Custom logic (e.g. health, metadata)

4. **Request is sent to the chosen instance**:
   ```http
   GET http://10.0.0.2:8080/api/orders
   ```

---

## 🔩 What Does Spring Use Under the Hood?

- `ServiceInstanceListSupplier` → gets list from Eureka
- `ReactorServiceInstanceLoadBalancer` → chooses 1 server
- `LoadBalancerClientFilter` (for WebClient) → rewrites the request

---

## ✅ Summary Table

| Question | Answer   |
|----------------------------------|----------------------------------------------------------------------|
| **Who does load balancing?** | The client app (using Spring Cloud LoadBalancer)|
| **How does it work?**| Eureka gives a list, client picks one server using a strategy   |
| **What happens next?**   | Request is sent directly to the selected server |

---

## 🧠 Analogy: Food Court

- Eureka = someone who gives you a list of open pizza counters.
- You = client app.
- Load balancer = how you choose which counter to go to (round robin, random, etc.).
- You eat = request sent to selected server.

---

## 🛠️ Code Example (WebClient)

```java
@Autowired
private WebClient.Builder webClientBuilder;

public Mono<String> callOrderService() {
return webClientBuilder
.baseUrl("http://order-service") // Service name, not IP
.build()
.get()
.uri("/api/orders")
.retrieve()
.bodyToMono(String.class);
}
```

Spring Cloud automatically:
- Talks to Eureka
- Gets the list of instances
- Picks one using load balancing
- Sends the request
- 
Now let’s talk about how **API Gateway** fits into this picture, and how **load balancing works differently** in that case.

---

## 🧭 API Gateway + Eureka: Load Balancing Explained

When you use **Spring Cloud Gateway** with **Eureka**, **Gateway acts as a smart entry point** for all external requests — clients call the Gateway, and Gateway forwards requests to internal services.

### 🧩 Flow: Client → Gateway → Service

1. 🔐 Client sends request to **API Gateway**

`GET http://api-gateway/order-service/api/orders`

1. 🌐 API Gateway looks up `order-service` in **Eureka**

2. 🎯 Gateway **load balances** across available instances of `order-service`

3. 📦 Gateway forwards request to one of the chosen instances


---

## 🧠 Who Does Load Balancing in This Case?

👉 **The API Gateway does the load balancing.**

You (the client or external user) don't need to know which server it hits — the Gateway takes care of:
- Looking up services from Eureka
- Applying a load-balancing strategy (like Round Robin)
- Forwarding requests to a chosen instance

---

## 🔩 How Does Gateway Do It?

Spring Cloud Gateway integrates with:
- **Spring Cloud DiscoveryClient** → gets list of instances from Eureka
- **Spring Cloud LoadBalancer** → applies the strategy (e.g., round robin)

The routes are usually defined like this:

### application.yml (in API Gateway)
spring:
  cloud:
    gateway:
      routes:
        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/order-service/**


- `lb://order-service` tells Gateway: “Use LoadBalancer + Eureka”

- It auto-load-balances across `order-service` instances


---

## ✅ Summary: Service-to-Service vs API Gateway

| Feature                      | Service-to-Service         | API Gateway                         |
| ---------------------------- | -------------------------- | ----------------------------------- |
| **Who calls the service?**   | Internal microservice      | External client                     |
| **Who does load balancing?** | The calling service itself | The API Gateway                     |
| **Eureka used by?**          | Each microservice          | Gateway (and services, optionally)  |
| **Load balancer type**       | Spring Cloud LoadBalancer  | Spring Cloud Gateway + LoadBalancer |

---

Let me know if you want this part added to the `.md` file too, or if you'd like a diagram for both flows!