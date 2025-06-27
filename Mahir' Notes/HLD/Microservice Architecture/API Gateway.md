
API Gateway is the layer which accepts the client request and **route them to correct backend service on API endpoint.**

![[Pasted image 20250617225005.png]]


## How is it different from the Load Balancers?

Load balancer's job is to distribute traffic as evenly as possible between the multiple instances of the (same) microservice, but it does not take any decision of routing based on the API endpoint like API gateway does.

| Feature   | **API Gateway**                                       | **Load Balancer**                              |
| --------- | ----------------------------------------------------- | ---------------------------------------------- |
| Main Role | API management, request routing, authentication, etc. | Distribute traffic across servers              |
| Focus     | Application-layer (mostly HTTP/S)                     | Transport and network-layer traffic (L4 or L7) |
![[Pasted image 20250617225541.png]]

A **load balancer** works at the **instance level**, not service level. That means:
- It distributes traffic **only between instances of the same service**.
- It assumes **all targets behind it do the same job** and can handle any request equally.


API Gateway routes the traffic to the particular service's LB based on the API client is trying to access.

![[Pasted image 20250617232759.png]]



# What benefit does API gateway bring?
# OR
#  Why Use an API Gateway Instead of Direct Microservice Access

## ✅ Benefits of Using an API Gateway

## 1. API Composition:

**API Composition** is the practice of **aggregating data from multiple microservices into a single response** for the client.

### ❌ Problem Without Composition:

In a microservices setup, data often lives in separate services:

- `/user/{id}` → User Service
- `/user/{id}/orders` → Order Service
- `/user/{id}/recommendations` → Recommendation Service

A frontend client (e.g. mobile app) would have to make **multiple HTTP calls** to collect data. This leads to:
- Increased **latency**
- More **round-trips**
- More **complex frontend code**

Client ──▶ /dashboard/123 (hits API Gateway)

### **API Gateway:**
- Calls /user/123 (User Service)
- Calls /user/123/orders (Order Service)
- Calls /user/123/recommendations (Recommendation Service)
- Aggregates all responses
- Returns unified JSON to client

![[Pasted image 20250617233710.png]]

**Other Benefit:** Based on the type of device we want to Aggregate different amount of the information like in case of mobile we can limit the data we are fetching from the backend services and thereby aggregating the only required amount of data by frontend, while in case of web we can extend the API calls logic to add more diverse call and aggregating more information.
![[Pasted image 20250617233642.png]]

### 🔐 **2. Centralized Security (Authentication & Authorization)**
- Handles OAuth, JWT, API Key validation in one place
- Prevents duplication of security logic in every microservice
- Keeps authentication logic decoupled from business logic
![[Pasted image 20250617233724.png]]

### 🔁 **3. Routing & Abstraction**
- Routes requests based on URL paths, methods, or headers
  - `/users/**` → User Service
  - `/orders/**` → Order Service
- Hides internal microservice structure from clients
- Simplifies client logic

**Advantages:**
- This way if client does not directly access the API of our internal services, there are reduced changes of attacks like DDoS (which we can handle directly on the API Gateway layer)
- API Gateway abstracts away backend topology.
	- You can **restructure services** without breaking the client.
	- Services can be refactored, renamed, or even split/merged behind the scenes.

### 📉 **4. Rate Limiting & Throttling**
- Protects backend services from being overwhelmed
- Enables user-level or token-level throttling
- Helps mitigate DDoS or burst traffic issues
![[Pasted image 20250617234506.png]]

### 🧰 **4. Request/Response Transformation**
- Modify headers, payloads, or status codes
- Enables backward compatibility (e.g., v1 ↔ v2 APIs)
- Simplifies versioning strategy

### 📊 **5. Monitoring & Logging**
- Centralized logging of all API traffic
- Easier debugging and alerting
- Enables distributed tracing (Zipkin, Jaeger, etc.)

### 🧱 **6. [[Service Discovery]]
- Auto-routes to healthy service instances
- Works with Consul, Eureka, Kubernetes, etc.
- No need for clients to track instance IPs

### 🔄 **7. API Versioning**
- Allows routing different versions to different services
- Deprecated versions can be blocked centrally
- Clients don’t need to know internals of versioning logic

---

## 🔻 Risks of Direct Client → Microservice Communication

| Problem                         | Consequence                                    |
|----------------------------------|------------------------------------------------|
| Auth handled in each service     | Redundant, error-prone, inconsistent           |
| Microservices exposed            | Harder to secure, risk of attack               |
| Tight client-service coupling    | Changes in service URLs break clients         |
| Lack of monitoring               | Hard to trace or debug issues                 |
| Poor scalability                 | Hard to scale and maintain independently      |

---

## ✅ Conclusion

> You **can** call microservices directly from clients, but **you shouldn’t** in production.

- Use an **API Gateway** as the single entry point to your system.
- Improves **security**, **maintainability**, **scalability**, and **observability**.

---

## 💡 Recommended Tools by Stack

- **Spring Boot** → [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)
- **AWS** → [AWS API Gateway](https://aws.amazon.com/api-gateway/)
- **Kubernetes** → [NGINX Ingress + API Gateway] or [Kong Gateway](https://konghq.com/)
- **Cloud Native** → [Kong], [Traefik], [Ambassador], [Gloo Edge]
