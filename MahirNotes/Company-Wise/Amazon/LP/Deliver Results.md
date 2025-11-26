
# Tell me about a time when you worked on a project with a tight deadline

**S (Situation):**

We were migrating very large on-prem datasets to GCP, but the process required engineers to manually segregate data, trigger transfers in batches, and monitor failures. As migration volumes increased, this manual workflow caused multi-day delays. Leadership committed to a major customer go-live in **under two weeks**, and the existing process clearly couldn’t scale.

**T (Task):**

I was responsible for delivering an automated migration scheduler that could segment data, run transfers reliably, and drastically cut manual effort — all within that tight deadline.

**A (Action):**

I prioritised the highest-impact automation pieces. I designed a scheduler that:

- **Automatically chunked and classified datasets**, removing all manual segregation.

- Used a Redis-backed state machine for **parallel, resumable, and idempotent uploads**.

- Added **smart retries** and checkpoints to eliminate manual restarts.

- Included a lightweight priority mechanism so urgent customer jobs weren’t blocked by large bulk migrations.

To accelerate validation, I built a synthetic data load generator to stress-test the system end-to-end without waiting for real datasets.


**R (Result):**

We delivered the scheduler **before the deadline**, reduced manual effort by **over 80%**, and increased migration reliability from ~70% to **99%+**. The customer onboarded successfully, and the automated scheduler became the standard for all future migrations.


# Describe a challenging project you worked on and why it was challenging.

SAME STAR as above, just add
Why?

- Large dataset migrations

- Heavy manual overhead

- Need to automate end-to-end workflow

- Airflow-based scheduling design

- Tight 2-week deadline

- High reliability requirement (99%+)

- Customer onboarding dependency


# How Do You Prioritize?


**S (Situation):**

While building an Airflow-based scheduler to automate migration of large on-prem datasets to GCP, we had **less than two weeks** and a long list of competing tasks: dataset chunking, DAG orchestration, retries, state management, monitoring, throughput tuning, and partial-failure handling. Without strong prioritization, we risked missing a major customer onboarding.

**T (Task):**

I needed to define a clear priority order so we could deliver a **reliable end-to-end migration flow** within the deadline.

**A (Action):**

I followed a simple framework: **1) unblock the pipeline, 2) protect correctness, 3) optimize last.**

1. **Unblock the pipeline:**

I first prioritized tasks that were absolute blockers — automatic dataset chunking and parallel upload orchestration — because without them the scheduler couldn’t run end-to-end. These became the top items for Day 1–3.

1. **Protect correctness & reliability:**

Next, I prioritized idempotent retries, checkpointing, and consistency checks. These ensured partial uploads didn’t corrupt data. I treated reliability as higher priority than performance.

1. **Optimize & enhance:**

Only after the core pipeline was stable did I prioritize enhancements like priorities for urgent jobs, observability, and tuning Airflow concurrency.

To save time, I deprioritized UI work and full-fledged dashboards and instead built quick CLI-based progress logs for the MVP.
  

**R (Result):**

This prioritization approach let us deliver the scheduler **ahead of the deadline**, with **99%+ successful migration rates** and an **80% reduction** in manual operational overhead.


# Win-Win Negotiation (Operational Cost vs Performance)

**S (Situation):**

One of our high-throughput data services was running on an over-provisioned cluster because Product insisted on extremely low latency targets. However, our cloud bill had grown nearly **40% above budget**, and the Platform team wanted us to scale down aggressively. Both teams had opposing goals — Product wanted performance; Platform wanted cost reduction.

  
**T (Task):**

I took ownership of finding a middle ground where we could reduce cloud spend **without compromising user experience**.

**A (Action):**

I proposed a **data-driven win-win approach**:

- First, I analyzed actual traffic patterns and discovered that peak load only lasted about **15–20% of the day**, but we were running at peak capacity 24/7.

- I redesigned the service to use **autoscaling with controlled warm pools**, ensuring latency stayed within SLA even during sudden spikes.

- For non-critical batch processing, I moved parts of the workload to **spot instances** with checkpointing so interruptions didn’t affect correctness.

- I then negotiated with Product to relax the latency requirement by **8–10 ms** in low-traffic hours, which gave us room to scale down more aggressively.

- Finally, I created a dashboard showing latency vs cost trade-offs so decisions were transparent to both sides.

**R (Result):**

We reduced infrastructure costs by **30%** while maintaining all customer-facing SLAs. Product didn’t see any degradation in user experience, and Platform hit their budget goals — a clear win-win outcome.