# Reliability Patterns — Index

[← Master Index](../../Master%20Index.md)

## Notes

| Note | What it covers |
|---|---|
| [Idempotent Consumers](Idempotent%20Consumers.md) | Every message queue delivers **at least once**. Duplicates are not an edge case — they are guaranteed. Handlin… |
| [Retries and Dead Letter Queues](Retries%20and%20Dead%20Letter%20Queues.md) | Retry logic is where well-intentioned code amplifies an outage. Getting backoff, classification, and the DLQ r… |
| [Transactional Outbox](Transactional%20Outbox.md) | The dual-write problem is unavoidable in any event-driven system: you must update your database **and** publis… |

