# JVM and Memory — Index

[← Master Index](../../Master%20Index.md)

## Notes

| Note | What it covers |
|---|---|
| [Bytecode, Reflection and Method Handles](Bytecode%20Reflection%20and%20Method%20Handles.md) | Every framework you use — Spring, Hibernate, Jackson, Mockito, JUnit — is built on these. Explaining how `@Aut… |
| [Class Loading](Class%20Loading.md) | Explains `NoClassDefFoundError` vs `ClassNotFoundException`, why the holder singleton is thread-safe, and how … |
| [JIT and Escape Analysis](JIT%20and%20Escape%20Analysis.md) | Explains why Java performance approaches C for hot code, why microbenchmarks lie, and why "objects are always … |
| [JVM Architecture and Memory Areas](JVM%20Architecture%20and%20Memory%20Areas.md) | Explains OutOfMemoryError variants, StackOverflowError, and why some objects are cheap. Standard mid-to-senior… |
| [Java Memory Leaks](Java%20Memory%20Leaks.md) | Java has garbage collection, so people assume leaks are impossible. They're just a different shape: **an unint… |
| [Java Memory Model (JMM)](Java%20Memory%20Model.md) | Every concurrency bug that isn't a race condition is a **visibility** bug. The JMM defines when one thread's w… |
| [Reference Types and Cleaners](Reference%20Types%20and%20Cleaners.md) | The four reference strengths are how you build caches that don't leak and cleanup that actually runs. Also the… |

