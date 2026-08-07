# Java Modules (JPMS)

## Why It Matters

Java 9's biggest change, and the source of most 8 → 17 migration pain. Application adoption is low, but the JDK itself is modular — so you hit it whether or not you use it.

## The Problem It Solved

**Before Java 9, the classpath was a flat, unordered list of jars.**

| Problem | Detail |
|---|---|
| **JAR hell** | Two versions of a library, first-on-classpath wins, silently |
| **No encapsulation** | Every `public` class was accessible to everyone |
| **No dependency declaration** | Missing jars failed at runtime, not startup |
| **Monolithic JRE** | ~60 MB minimum, even for a tiny application |
| **JDK internals were reachable** | `sun.misc.Unsafe` used everywhere |

**"Public" meant "public to the entire world."** A library couldn't have an internal package that was public for its own use but hidden from consumers — the fundamental gap JPMS closed.

## module-info.java

```java
module com.myapp.orders {
    requires com.myapp.common;              // dependency
    requires transitive java.sql;           // consumers get java.sql too
    requires static lombok;                 // compile-time only

    exports com.myapp.orders.api;           // public to everyone
    exports com.myapp.orders.spi to com.myapp.plugins;   // qualified export

    opens com.myapp.orders.model;           // REFLECTION allowed at runtime
    opens com.myapp.orders.dto to com.fasterxml.jackson.databind;

    provides OrderService with DefaultOrderService;   // service provider
    uses PaymentGateway;                              // service consumer
}
```

| Directive | Meaning |
|---|---|
| `requires` | I depend on this module |
| **`requires transitive`** | **My consumers also get it** — implied readability |
| `requires static` | Compile-time only, optional at runtime |
| `exports` | This package is publicly accessible |
| `exports ... to` | **Qualified** — only these modules |
| **`opens`** | **Deep reflection permitted at runtime** |
| `provides ... with` | Service implementation |
| `uses` | Service consumer via `ServiceLoader` |

## exports vs opens — The Key Distinction

| | `exports` | `opens` |
|---|---|---|
| Compile-time access to public API | **Yes** | No |
| Runtime **reflection** into private members | **No** | **Yes** |
| Use for | Your public API | **Frameworks that reflect** — Jackson, Hibernate, Spring |

**`exports` alone does not permit `setAccessible(true)`.** That's the single most common JPMS confusion.

```
InaccessibleObjectException: Unable to make field private java.lang.String
  com.app.User.name accessible: module com.app does not "opens com.app" to
  module com.fasterxml.jackson.databind
```

**The fix is `opens`, not `exports`** — and preferably a qualified `opens ... to`, so only the framework gets reflective access rather than everyone.

**`open module` opens every package** — the pragmatic escape hatch when you're modularising an application that uses several reflective frameworks.

## Strong Encapsulation of the JDK

**The main source of 8 → 17 migration pain.**

Since Java 9 (warnings) and Java 16 (enforced by default), reflective access into JDK internals fails:

```
java.lang.reflect.InaccessibleObjectException: Unable to make field
  private final byte[] java.lang.String.value accessible
```

**Escape hatches:**
```bash
--add-opens java.base/java.lang=ALL-UNNAMED       # reflection
--add-exports java.base/sun.nio.ch=ALL-UNNAMED    # compile/link access
```

**These are a migration bridge, not a solution.** Each release closes more, and JDK 24 permanently disabled the Security Manager as part of the same tightening.

**`sun.misc.Unsafe` is the canonical casualty.** Its replacements: **`VarHandle`** for atomic and ordered memory access, and the **Foreign Function & Memory API** for off-heap memory.

## Classpath vs Module Path

| | Classpath | Module path |
|---|---|---|
| Jars become | The **unnamed module** | Named modules |
| Encapsulation | **None** — everything readable | Enforced |
| Split packages | Allowed | **Forbidden** |

**Two migration concepts:**

- **Automatic module** — a plain jar placed on the *module path*. Its name derives from `Automatic-Module-Name` in the manifest (or, badly, from the filename). It reads everything and exports everything.
- **Unnamed module** — anything on the classpath. Reads all modules; named modules cannot read *it*.

**A named module cannot depend on the classpath.** This is the migration wall: to modularise your code, every dependency must be at least an automatic module. One un-migrated library blocks you.

**Split packages are forbidden** — two modules cannot contain the same package. This broke several older libraries that had spread one package across multiple jars.

## jlink — Custom Runtimes

```bash
jlink --add-modules com.myapp.orders \
      --output custom-runtime \
      --compress=2 --no-header-files --strip-debug
```

**Produces a self-contained runtime with only the modules you need** — often 30–40 MB instead of a full 300 MB JDK.

**This is JPMS's most concrete practical win**, especially for containers where image size matters. It requires fully modular dependencies, which is why many projects can't use it.

**`jdeps`** analyses dependencies and reports JDK-internal API usage — the first tool to run when planning a migration.

## ServiceLoader

The module-aware plugin mechanism:

```java
// Provider module
provides PaymentGateway with StripeGateway;

// Consumer module
uses PaymentGateway;

// Consumer code
ServiceLoader.load(PaymentGateway.class)
             .stream().map(Provider::get).toList();
```

Cleaner than classpath scanning, and it works without reflection into implementation packages. Used by the JDK for JDBC drivers, charsets and logging backends.

## The Honest Assessment

**Adoption in application code is low.** Most Spring Boot applications run on the classpath with no `module-info.java`, and that is a perfectly reasonable choice.

| Where it succeeded | Where it didn't |
|---|---|
| **The JDK itself** — modular, `jlink`-able | Application code — friction outweighs benefit |
| Libraries adding `Automatic-Module-Name` | Full library modularisation |
| **Strong encapsulation of internals** | Replacing build-tool dependency management |
| `jlink` for small runtimes | Solving versioning — **JPMS does not do versions** |

**JPMS does not solve version conflicts.** You still cannot have two versions of the same module — arguably the biggest thing people expected from it. Maven and Gradle still own dependency resolution.

**In an interview:** know what `opens` versus `exports` means, know why `--add-opens` exists, and be able to say that adoption is limited and that's a legitimate engineering choice. **Claiming everyone should modularise is the wrong answer.**

## Migration Path

1. **Run on a newer JDK with the classpath unchanged** — usually most of the work
2. Run `jdeps` to find JDK-internal usage
3. Replace `Unsafe`, `sun.*` and similar with supported APIs
4. Add `--add-opens` where a framework needs reflection
5. Add `Automatic-Module-Name` to your own jars (cheap, helps consumers)
6. **Only then**, if you want `jlink`, add `module-info.java` bottom-up

**Steps 1–5 deliver almost all the value.** Step 6 is optional and often not worth it.

## Common Mistakes

- Using `exports` when the framework needs `opens`
- Expecting JPMS to solve version conflicts
- Adding `module-info.java` before dependencies are ready
- Split packages across modules
- Treating `--add-opens` as permanent
- Assuming a classpath application must be modularised
- Forgetting that automatic module names derived from filenames are unstable

## Related Topics

- [Java Version Guide 8 to 25](Java%20Version%20Guide%208%20to%2025.md)
- [Class Loading](../JVM%20and%20Memory/Class%20Loading.md)
- [Bytecode Reflection and Method Handles](../JVM%20and%20Memory/Bytecode%20Reflection%20and%20Method%20Handles.md)

## Revision Summary

JPMS added real encapsulation: `exports` grants compile-time access to public API, `opens` grants runtime reflective access, and they are not interchangeable. Strong encapsulation of JDK internals is the main 8 → 17 migration pain, bridged by `--add-opens`. `jlink` produces small runtimes. Application adoption is low, and that's a defensible choice.

## Quick Recall

- **`exports` = compile-time API; `opens` = runtime reflection** — not the same
- Frameworks like Jackson and Hibernate need **`opens`**
- `requires transitive` gives your consumers the dependency too
- **Strong encapsulation breaks `sun.misc.Unsafe`** → `VarHandle` and FFM API
- `--add-opens` / `--add-exports` are **migration bridges, not fixes**
- Named modules **cannot read the classpath**; split packages are forbidden
- **`jlink` gives a 30–40 MB runtime** — the concrete win
- **JPMS does not solve versioning**
- Low application adoption is a legitimate choice
