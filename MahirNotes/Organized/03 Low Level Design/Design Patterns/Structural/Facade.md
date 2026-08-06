# Facade

## Why It Matters

The simplest structural pattern, and the one that most often describes what a well-designed service layer actually is.

## Core Idea

A single simplified interface over a complex subsystem. The facade doesn't hide the subsystem — clients can still use it directly — it just provides an easier default path.

```java
class VideoConverter {                     // facade
    private final AudioMixer mixer = new AudioMixer();
    private final CodecFactory codecs = new CodecFactory();
    private final BitrateReader reader = new BitrateReader();

    public File convert(File source, String targetFormat) {
        Codec src = codecs.extract(source);
        Codec dst = codecs.forFormat(targetFormat);
        Buffer buf = reader.read(source, src);
        Buffer converted = reader.convert(buf, dst);
        return mixer.fix(converted);
    }
}

new VideoConverter().convert(file, "mp4");   // one call instead of five classes
```

## What It Buys

| Benefit | Detail |
|---|---|
| **Reduced coupling** | Clients depend on one class, not five |
| Simplified use | The common workflow is one method |
| Easier refactoring | Subsystem internals can change behind the facade |
| Clear layer boundary | A natural seam between application and infrastructure |

## Facade vs Adapter vs Mediator

| | Facade | Adapter | Mediator |
|---|---|---|---|
| Wraps | **Many** classes | **One** class | Many **peers** |
| Interface | New, simpler | Converted to an expected one | New, coordinating |
| Subsystem awareness | Subsystem doesn't know the facade | Adaptee doesn't know the adapter | **Peers know the mediator** |
| Direction | One-way (client → subsystem) | One-way | **Two-way** |

**Facade vs Mediator is the subtle one:** a facade is unidirectional and the subsystem is unaware of it; a mediator coordinates peers that hold references back to it.

## Common Real Examples

- `javax.faces.context.FacesContext`
- SLF4J over logging backends
- Spring's `JdbcTemplate` over raw JDBC (open/prepare/execute/map/close/handle-exceptions)
- A service layer over repositories, validators, and clients
- SDK clients over raw HTTP APIs

**`JdbcTemplate` is the best example to give** — it replaces roughly 20 lines of boilerplate and exception handling with one call.

## Design Rules

1. **The facade should not become a god object.** If it grows past a handful of cohesive operations, split it into several facades by use case.
2. **Don't forbid direct subsystem access.** Advanced clients may need it; a facade is a convenience, not a wall.
3. **Keep it thin.** Orchestration only. Once it accumulates business rules and state, it's a service, and should be named and tested as one.

## When To Use

- A subsystem requires a fixed multi-step sequence
- You want a clear boundary between layers
- Clients only need a small fraction of the subsystem's capability
- You're wrapping a third-party library to limit its blast radius

## Limitations

- Can grow into a god class
- Adds a layer that may hide capability clients genuinely need
- Overuse produces facades over facades

## Common Questions

- *Facade vs Adapter?* — simplify many vs make one compatible.
- *Does a facade hide the subsystem?* — no; it provides an easier route, not an exclusive one.
- *Is a service layer a facade?* — often yes, when it only orchestrates.
- *Facade vs Mediator?* — unidirectional and unaware vs bidirectional coordination.

## Common Mistakes

- Growing into a god class with dozens of unrelated methods
- Putting business logic in it
- Forcing all access through it and blocking legitimate advanced use
- Creating a facade over a subsystem with only one class — that's just indirection

## Related Topics

- [Adapter](Adapter.md)
- [Mediator](../Behavioural/Mediator.md)
- [API Gateway](../../../08%20Microservices/API%20Gateway.md)

## Revision Summary

One simple entry point over a complex subsystem. Reduces coupling and marks a layer boundary. Keep it thin and orchestration-only; don't block direct access. `JdbcTemplate` is the canonical example.

## Quick Recall

- Simplifies many classes into one interface
- Doesn't forbid direct access
- Orchestration only, no business logic
- Facade unidirectional; Mediator bidirectional
- `JdbcTemplate`, SLF4J, SDK clients
