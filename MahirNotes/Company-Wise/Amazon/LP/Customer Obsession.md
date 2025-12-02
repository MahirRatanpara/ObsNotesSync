# **1) Tell me about a time you solved a pain point for customers.**

**STAR — 120 seconds**

**S:**  
Our critical Spark-driven data pipeline was delivering outputs unpredictably and sometimes silently failing. The internal ML team that depended on those datasets for daily model training was constantly blocked. They escalated repeatedly because they needed predictable and trustworthy data to start their workday.

**T:**  
I owned restoring predictability and removing silent failures entirely.

**A:**  
I started by meeting the ML team instead of immediately diving into code. They explained that unpredictability was more frustrating than the delay itself — they had no way to know whether the pipeline was progressing or stuck.  
This customer insight influenced my solution heavily.

I deep-dived into Spark UI timelines, memory behavior, and our Akka-based orchestration layer. I discovered that our in-memory priority queue became a bottleneck during high job volume, and failures inside Akka Streams went unnoticed due to missing correlationId/MDC propagation.

I redesigned the scheduling layer using a Redis Sorted Set for durability and throughput. I added full correlationId propagation across Akka HTTP services, implemented structured logs, and built a health-check endpoint the ML team could query in seconds.

I deployed via a shadow pipeline and iterated based on feedback.

**R:**  
Within two weeks:

- SLA improved consistently to 6:30 AM
    
- Silent failures dropped to zero
    
- Failure detection improved from hours to minutes
    
- The ML team reduced manual monitoring by ~70%
    

This solved their biggest pain point and restored trust in our platform.

---

# **2) Tell me about a time you dealt with a demanding customer.**

**STAR — 100 seconds**

**S:**  
The ML team was heavily impacted by delays in our Spark pipeline and escalated almost daily. Their deliverables to leadership depended on reliable data, so they were understandably demanding.

**T:**  
I had to handle their expectations professionally while actually fixing the underlying issues.

**A:**  
I began by proactively engaging with them every morning to understand the exact blockers instead of waiting for escalations. They emphasized unpredictability and lack of transparency.  
I translated their urgency into technical priorities.

I designed a Redis-based scheduler to remove bottlenecks and implemented a unified correlationId propagation layer in Akka HTTP so every request could be traced end-to-end. I also provided them a health-check endpoint and early-access logs tailored to their workflow.

I over-communicated progress, ran a shadow pipeline, and validated results with them daily, which reduced friction significantly.

**R:**  
Instead of being “demanding,” their tone shifted to collaborative. Once the system stabilized and SLA became consistently 6:30 AM, they said it was the first time in months they didn’t have to monitor our pipeline manually.

---

# **3) Tell me about a time you used customer feedback to drive innovation.**

**STAR — 110 seconds**

**S:**  
Our Spark pipeline delays were causing issues, but during feedback sessions, the ML team revealed something deeper: what really bothered them was **lack of visibility**, not just delays.

**T:**  
My goal was not only to fix performance issues but to innovate a visibility solution they never had.

**A:**  
The customer feedback made me realize we needed end-to-end traceability.  
I built:

- Full **correlationId propagation** across our Akka HTTP services
    
- Structured logs tied to those IDs
    
- A health-check endpoint that let them validate job completion instantly
    
- Improved Spark stage logging integrated with those IDs
    

I also redesigned the scheduling layer using Redis, but the real innovation came from building a customer-centric observability ecosystem.

**R:**  
Failure detection time fell from ~3 hours to under 5 minutes.  
The ML team gained complete transparency and stopped needing manual checks.  
Our observability design became a template adopted by two other internal teams.

---

# **4) Tell me about one of your projects where you put the customer first.**

**STAR — 100 seconds**

**S:**  
A critical Spark job used by an ML team was missing SLAs and causing downstream incidents.

**T:**  
I had to prioritize customer needs over ongoing engineering roadmap tasks.

**A:**  
I paused other planned work and met the ML team to understand what actually mattered to them: predictability, visibility, and eliminating silent failures.  
I adjusted our engineering priorities accordingly.

This led me to design:

- A Redis Sorted Set scheduler to guarantee consistent execution
    
- CorrelationId propagation and structured logs for traceability
    
- A self-serve health-check endpoint
    
- A shadow pipeline rollout plan designed around _their_ usage patterns
    

Every decision was based not on engineering convenience but on reducing their operational pain.

**R:**  
SLA improved by hours, they could start training earlier, and their daily manual effort dropped drastically. The team explicitly appreciated that the solution was built around their needs, not just technical patchwork.

---

# **5) Tell me about a time you went above and beyond for a customer.**

**STAR — 110 seconds**

**S:**  
Our Spark pipeline became unstable, causing severe disruption for the ML team. They needed reliability urgently.

**T:**  
Beyond fixing the technical issues, I wanted to give them true peace of mind.

**A:**  
I ran a **shadow pipeline for a full week**, manually validated early morning outputs, and sent them proactive updates before they even checked.  
I tuned the pipeline daily — adjusting Spark executor configs, improving job scheduling, refining logs — based on even minor feedback they shared.

I also implemented additional features they didn’t ask for but deeply needed: structured logs, correlationId propagation, and a self-serve health-check UI.

**R:**  
They had zero failures during rollout week, SLA stabilized, and manual oversight dropped almost completely. They later told me this was the first time they could “fully trust the system without babysitting it.”