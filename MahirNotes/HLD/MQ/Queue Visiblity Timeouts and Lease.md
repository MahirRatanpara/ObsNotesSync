## Long-Running Task Pattern — System Design

### The Core Problem

When a user triggers something that takes seconds to minutes (PDF generation, video transcoding, sending bulk emails), you can't hold an HTTP connection open that long. The browser times out, the load balancer kills it, and the user stares at a spinner. So you decouple the request from the work.

### Core Architecture

The flow is straightforward. The **web server** receives the request, creates a job record in a **job status store** (a database), drops a message onto a **queue**, and immediately returns a job ID to the client. The client then polls (or listens via websocket) for status updates.

On the other side, **workers** pull messages from the queue, do the heavy lifting, and update the job status store as they progress. That's it — producer/consumer with a status tracker in between.

```
Client → Web Server → [creates job in DB] → Queue → Worker(s)
              ↓                                        ↓
         returns jobId                          updates job status in DB
              ↓
         Client polls GET /jobs/{id}
```

### When to Use It

Use this whenever the work takes more than a couple of seconds: report generation, video/image processing, data exports, sending batch notifications, ML inference on large inputs, or anything with external API calls that might be slow or flaky.

### The Queue + Worker Heartbeat Mechanism (Visibility Timeout & Lease Extension)

This is the most important reliability piece, so let me break it down carefully.

**Visibility Timeout (the "lease"):** When a worker pulls a message from the queue, the queue doesn't delete it. Instead, it _hides_ it from other workers for a fixed duration — say 30 seconds. This is the visibility timeout. Think of it as a lease: "You have 30 seconds to finish this. If I don't hear from you, I'll assume you're dead and give it to someone else."

**Why not just delete the message on pull?** Because if the worker crashes mid-processing, the message is lost forever. By keeping it hidden (not deleted), the queue acts as a safety net.

**The problem with a fixed timeout:** If your PDF takes 2 minutes to generate but the visibility timeout is 30 seconds, the queue thinks the worker died after 30s. It makes the message visible again, a second worker picks it up, and now two workers are generating the same PDF. That's wasteful and potentially dangerous.

**Heartbeat / Lease Extension — the solution:** The worker runs a background thread (or timer) that periodically tells the queue "I'm still alive, extend my lease." Concretely, every N seconds (the heartbeat interval), the worker calls something like `changeMessageVisibility(receiptHandle, newTimeout)` to push the visibility timeout forward.

Here's how it works in practice:

```
Time 0s   → Worker picks message. Visibility timeout = 30s.
Time 20s  → Heartbeat fires. Worker extends timeout to 30s from now (so, until T=50s).
Time 40s  → Heartbeat fires again. Extends to T=70s.
Time 55s  → Work finishes. Worker deletes message from queue, updates job status to COMPLETED.
```

**The heartbeat interval should be significantly less than the visibility timeout** — a common rule of thumb is heartbeat every `visibilityTimeout / 3` or so. If timeout is 30s, heartbeat every 10s. This gives you a buffer: if one heartbeat fails (network blip), you still have time before the lease expires.

**What happens on failure:**

|Scenario|What Happens|
|---|---|
|Worker crashes hard (OOM, killed)|Heartbeat stops → visibility timeout expires → message reappears → another worker picks it up|
|Worker hits a bug, throws exception|Worker catches it, does NOT delete message, stops heartbeating → same as above|
|Worker finishes successfully|Worker deletes the message from the queue → done|
|Heartbeat call itself fails once|No panic — next heartbeat will extend. You only lose the lease if ALL heartbeats fail until timeout expires|

This is why the pattern is self-healing: no coordinator needed, the queue's timeout mechanism handles recovery automatically.

### Job Status Tracking

Your job record in the DB typically moves through states: `PENDING → PROCESSING → COMPLETED / FAILED`. Workers update this as they go. The client polls `GET /jobs/{id}` and sees progress. You can add a `progress_percent` or `status_message` field for richer feedback.

### Key Tradeoffs

**Complexity vs reliability** — you're adding a queue, workers, a status store, and polling logic. That's a lot of moving parts for something that "just generates a PDF." But without it, one slow request can tie up your whole web server.

**At-least-once delivery** — most queues guarantee at-least-once, not exactly-once. Your message might get delivered twice (visibility timeout expired, worker was just slow). So your workers _must_ be idempotent.

**Latency vs throughput** — queues add latency. The user doesn't get an instant response. You're trading immediate feedback for system resilience and scalability.

### Common Deep Dives

**Retries & Dead Letter Queue (DLQ):** Each message has a receive count. If a worker fails to process it, it reappears and gets retried. After N failures (say 3), the queue moves it to a DLQ — a separate queue for poison messages. You monitor the DLQ, investigate manually or with alerting, and fix the root cause. This prevents one bad message from blocking your entire pipeline.

**Idempotency:** Since at-least-once means duplicates are possible, your worker must handle "process this PDF for order #123" being called twice without generating two PDFs or charging twice. Common approach: check a unique job key in your DB before doing work. If already completed, skip.

**Backpressure:** If producers enqueue faster than workers can consume, the queue grows unboundedly. You handle this by auto-scaling workers based on queue depth, setting max queue size and rejecting/throttling new jobs, or alerting when queue lag exceeds a threshold.

**Fast vs Slow Queues:** Not all jobs are equal. A thumbnail resize takes 2 seconds; a video transcode takes 10 minutes. If they share a queue, slow jobs starve fast ones. Split them into separate queues with separate worker pools. This way your fast-path stays fast.

### Concrete Example — PDF Report Generation

A user clicks "Export Monthly Report" in a dashboard.

The web server creates a job record `{id: "j-42", status: "PENDING", user_id: 7, report_type: "monthly"}`, pushes `{job_id: "j-42", params: {...}}` to the `pdf-jobs` queue, and returns `202 Accepted` with `{job_id: "j-42", poll_url: "/jobs/j-42"}`.

A worker picks it up. It starts a heartbeat thread (every 10s, extends visibility by 30s). It queries the database for report data, renders HTML, converts to PDF using something like Puppeteer, uploads the PDF to S3, then updates the job record to `{status: "COMPLETED", result_url: "s3://reports/j-42.pdf"}` and deletes the message from the queue.

The client, which has been polling every 2 seconds, sees `COMPLETED` and gets the download link.

If the worker crashes mid-render, the heartbeat stops, the message reappears after the visibility timeout, another worker picks it up, checks the job status (still `PROCESSING` but stale), resets it, and retries. Because it checks for an existing S3 file before uploading (idempotency), no duplicate PDFs are created.

---

That covers the full picture — the architecture gives you decoupling, the visibility timeout + heartbeat gives you failure recovery without a coordinator, and the deep-dive topics (DLQ, idempotency, backpressure, queue splitting) show you've thought about production realities.