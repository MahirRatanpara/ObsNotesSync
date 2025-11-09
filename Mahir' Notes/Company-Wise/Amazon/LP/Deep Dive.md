
**S (Situation):**

In our distributed microservices landscape, we started seeing intermittent production failures where certain user requests were timing out or returning inconsistent responses. However, when we looked at logs across services, it was extremely difficult to trace a single request through the system because **each microservice generated logs independently with no shared identifier**.

  

**T (Task):**

I needed to **diagnose the issue end-to-end**, determine which service or interaction was causing inconsistent behavior, and establish a **repeatable way to trace execution across services** — without stopping production or rewriting core business logic.

  

**A (Action):**

To dive deep, I focused on structured investigation:

1. **Mapped the request flow** across all services to identify where context was being lost.

2. Analyzed the logs and noticed that each hop generated a _new transaction ID_, breaking traceability.

3. Formed a hypothesis that **lack of correlation context** was the root cause preventing us from isolating failures.


  

To validate and solve this:

- I designed a **lightweight Correlation ID propagation library** that:

- Generated a request ID at the system boundary,

- Injected it into **HTTP headers and message topics**,

- Automatically extracted and forwarded it in downstream calls.


- I integrated the correlation ID into **our logging frameworks**, so logs were automatically tagged — no business logic changes required.

- Added **centralized log search dashboards**, enabling one-click tracing of an entire request lifecycle.


  

**R (Result):**

- We could now **trace any request across all microservices in seconds**, instead of manually searching across logs.

- **Debugging time reduced from hours to minutes**, significantly improving MTTR.

- This became the **standard operational tracing approach** across the platform.

- On-call stress and firefighting reduced dramatically, improving reliability and confidence during incidents.