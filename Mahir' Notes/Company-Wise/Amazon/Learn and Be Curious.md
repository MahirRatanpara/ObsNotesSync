# Learn and Be Curious - Amazon Interview Preparation

## STAR Stories

### Story 1: Learning Spark to Build a New Validation Engine

**Situation:** Our regulatory and financial reporting relied heavily on accurate data, but data validation was fully manual. Analysts spent days verifying large datasets using SQL and spreadsheets, causing slow delivery and inconsistency.

**Task:** Design a scalable automated validation solution, even though no automated validation system existed.

**Action:** Researched distributed processing solutions and identified Apache Spark as suitable. Learned Spark from scratch through documentation, courses, and small proof-of-concepts. Designed a validation engine using Spark with configurable rules, parallel processing, and reporting outputs. Collaborated with business users to ensure rules matched domain requirements.

**Result:** Automated ~80% of validation, reducing processing time from days to hours. Enabled analysts to focus on analysis instead of manual checking. Improved consistency and reporting reliability. The solution became a standard component of the pipeline.

---

### Story 2: Observability Initiative Driven by Curiosity

**Situation:** Performance issues and outages occurred, but the team lacked visibility and often only discovered problems when business users reported them.

**Task:** Improve observability despite it not being part of the assigned role.

**Action:** Self-taught Prometheus, Grafana, and distributed tracing. Prototyped a monitoring stack and demonstrated how it could have caught past incidents earlier. Implemented dashboards and SLIs in collaboration with business stakeholders.

**Result:** Mean Time to Detection improved by ~60%, troubleshooting time reduced ~40%, and proactive incident prevention increased. The stack became a model for other teams.

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