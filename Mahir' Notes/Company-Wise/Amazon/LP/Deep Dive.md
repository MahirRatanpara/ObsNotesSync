
# Story - 1

**Situation**
We had multiple Spark jobs running on a shared YARN cluster. During peak traffic hours, some of our high-priority jobs that powered customer-facing dashboards were getting delayed by 30 to 60 minutes. The delays were inconsistent, so they caused downstream SLA misses and were difficult to root-cause.

**Task:**  
I was responsible for identifying the reason behind these delays and ensuring that the high-priority jobs always ran on time — without adding additional hardware capacity.

**Action:**  
I started by reviewing the Spark job logic and DAGs, but there were no recent changes and no performance degradation. I then looked into executor and container logs to check for memory or shuffle bottlenecks, but resource consumption was stable.

Next, I reviewed historical Spark UI timelines and noticed the processing time was still fast — the delay was happening _before_ jobs even began execution. That led me to analyze the YARN ResourceManager and queue metrics. I discovered that during peak hours, the queue that hosted our high-priority jobs was getting saturated by long-running, lower-priority batch workloads. So the root cause was **YARN queue starvation**, not Spark performance.

To solve this, I designed a **priority-based job dispatching layer**. I used Redis Sorted Sets to maintain job priority, built a lightweight scheduler that only submitted jobs when their priority tier had guaranteed resource headroom, and added monitoring dashboards and alerts to track queue capacity.

**Result:**  
This reduced high-priority job wait time from 30–60 minutes to consistently under 5 minutes. SLA reliability improved, customer dashboards stabilized, and the Redis-based scheduling approach was later adopted as a standard across other pipelines in the team.


# Story - 2

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