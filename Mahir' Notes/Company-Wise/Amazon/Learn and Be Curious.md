# Learn and Be Curious - Amazon Interview Preparation

## STAR Stories

### Story 1: Learning Spark to Build a New Validation Engine

**Situation:**

In our compliance workflow, business users were performing data validations **manually** using spreadsheets and custom scripts for each dataset. This process took **nearly a full day** for every validation cycle, and every time a validation rule changed, the process had to be repeated from scratch. There was **no centralized validation engine**, and it was causing frequent delays in reporting timelines and high operational overhead. I recognized that the core problem wasn’t the rules themselves, but the **lack of an automated and scalable validation framework.**

**Task:**

I took ownership of creating a solution that would **automate** these validations, make them **scalable**, and allow business users to define or modify rules **without involving developers** — so iterations could happen quickly.

**Action (Learn & Be Curious Focus):**

To achieve true scalability, I realized the solution required **distributed data processing**, but I had never worked with Apache Spark before. So I **proactively self-learned Spark**, focusing on:
- Distributed execution concepts & DAG scheduling
- Partitioning and data distribution strategies
- Performance tuning via Spark UI
- Efficient join and aggregation patterns

Using this knowledge, I designed and implemented a **distributed validation engine** that:

- Processes large datasets **in parallel** using Spark
- Allows **business users to define validation rules via configuration** instead of code
- Automatically generates validation summaries and exception report
- Requires **no developer involvement to update or add rules**

**Result:**

This replaced a **manual, day-long validation process** with an **automated pipeline that completed in just a few minutes.**

Business teams could now run multiple validation cycles per day, leading to faster reporting, fewer manual errors, and significantly reduced operational effort.

---

### Story 2: Observability Initiative Driven by Curiosity

**Situation:**

Our platform had recurring performance issues, but we lacked good observability. We often found out about incidents only when business users raised complaints, which delayed response and created frustration.

  
**Task:**

Even though observability was not part of my assigned responsibilities, I wanted to proactively improve visibility so we could detect and diagnose issues earlier.

  **Action:**

I self-learned Prometheus, Grafana, and distributed tracing by exploring documentation and internal knowledge bases. I prototyped a monitoring stack and recreated past incidents to show how earlier detection would have been possible. After demonstrating this to product and support stakeholders, I collaborated with the infra team to roll it out—setting up dashboards, alerts, and SLIs aligned with what business users cared about (e.g., response time and error rate).

**Result:**

Mean Time to Detection improved by ~60%, troubleshooting time dropped ~40%, and several incidents were prevented proactively. The observability setup I introduced was later adopted as a reference by other teams.

---

### Story 3: Adapting During Cloud Migration

**Situation:** The organization migrated from on-prem to cloud to improve scalability. The existing job scheduler could not support cloud workflows.

**Task:** Design a cloud-based scheduler despite unfamiliarity with cloud-native tools.

**Action:** Learned GCP services, Kubernetes Engine, Cloud Composer, and Consul Gateway. Collaborated with architects and stakeholders. Designed and documented the scheduler. Conducted knowledge-training sessions.

**Result:** Achieved 99.9% uptime and reduced infrastructure cost by ~30%. The architecture became a reference pattern.

---

### Story 4: Redis Priority Queue Under Deadline

**Situation:** High-priority data workflows were delayed behind lower-priority jobs.

**Task:** Implement a priority-based job queue within six weeks, requiring Redis knowledge.

**Action:** Rapidly learned Redis sorted sets and queue patterns. Designed and implemented priority ranking, retries, and monitoring. Worked with business users to define priority tiers.

**Result:** Delivered ahead of deadline. Critical jobs ran within minutes instead of hours, and throughput improved ~35%. SLAs consistently met.

---

### Story 5: Staying Up-to-Date with Industry Trends

**Situation:** System outages were detected only after user reports. Industry trends showed organizations using modern observability.

**Task:** Evaluate new observability tech and propose improvements.

**Action:** Learned telemetry tools and patterns through hands-on practice. Built a proof-of-concept referencing real incidents. Presented cost-benefit proposal and implemented solution.

**Result:** Reduced MTTD by 60%, prevented outages proactively, saved ~15 hours/week, and inspired others to adopt a research-prototype-propose approach.

---

## Mapping Stories to Common Amazon Questions

|Question|Matching Stories|
|---|---|
|Time you had to learn something new|Story 1, Story 4|
|Proactively learned without being asked|Story 2, Story 5|
|Worked outside responsibility|Story 2, Story 5|
|Staying up-to-date with trends|Story 5|
|Built something new that didn’t exist|Story 1, Story 4|
|Dug deep into a problem|Story 2|
|Curiosity led to improvement|Story 2, Story 5|
|Learned complex system independently|Story 1, Story 3|
|Challenged status quo|Story 2, Story 5|
|Took initiative to improve system|Story 2, Story 5|

---

## Follow-Up Question Preparation

|Follow-Up Question|Response Focus|
|---|---|
|What motivated you to learn this?|Internal curiosity, desire to improve reliability and scalability.|
|How did you structure your learning?|Docs → hands-on PoC → controlled rollout → production.|
|How did you measure success?|Use metrics like SLA, time saved, throughput, error reduction.|
|How did you balance learning with deadlines?|Parallel learning + incremental development.|
|How did others react to your solution?|Training, documentation, adoption across teams.|
|What was most difficult to learn?|Mention one deep concept (e.g., Spark shuffle optimization).|
|How did business users benefit?|Faster delivery, fewer escalations, more predictable outcomes.|
|What would you do differently?|One high-value optimization or automation improvement.|

---