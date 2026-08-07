# Patterns — Index

[← Master Index](Master%20Index.md)

## Notes

| Note | What it covers |
|---|---|
| [Handling Large Blobs](Handling%20Large%20Blobs.md) | Any design involving images, video, documents, or backups. The wrong answer — routing bytes through your appli… |
| [Managing Long-Running Tasks](Managing%20Long%20Running%20Tasks.md) | Video transcoding, report generation, bulk imports, ML inference — anything exceeding a request timeout needs … |
| [Multi-Step Processes and Saga](Multi%20Step%20Processes%20and%20Saga.md) | Once an operation spans several services, you can't wrap it in a database transaction. Every "book a flight, h… |
| [Rate Limiting](Rate%20Limiting.md) | Protects against abuse, cost overruns, and cascading failure. A standalone design question and a component of … |
| [Real-Time Updates](Real%20Time%20Updates.md) | Chat, notifications, live feeds, collaborative editing, dashboards, and multiplayer all reduce to "how does th… |
| [Scaling Reads](Scaling%20Reads.md) | Most systems are read-heavy, often 100:1 or worse. Read scaling is usually the first bottleneck you hit and th… |
| [Scaling Writes](Scaling%20Writes.md) | Much harder than scaling reads — you can't just add replicas, since every replica must apply every write. This… |

