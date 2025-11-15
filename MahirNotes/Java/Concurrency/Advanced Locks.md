# Java `finally` Block Explained

  

## ✅ What is `finally` in Java?

  

The `finally` block is part of the `try-catch-finally` construct and is used to define a **block of code that always executes**, **regardless of whether an exception was thrown or not**.

  

---

  

## ✅ Purpose of `finally`

  

- Ensure **cleanup** actions are performed.

- Common uses:

  - Closing resources (files, sockets, DB connections).

  - Releasing locks (`lock.unlock()`).

  - Resetting state.

  

---

  

## 🔁 Basic Syntax

  

```java

try {

    // Code that might throw an exception

} catch (ExceptionType e) {

    // Handle the exception

} finally {

    // This block always executes

}

```

  

---

  

## 🧪 Examples

  

### 1. Without exception

  

```java

try {

    System.out.println("Try block");

} finally {

    System.out.println("Finally block");

}

```

  

**Output:**

```

Try block

Finally block

```

  

---

  

### 2. With exception (caught)

  

```java

try {

    int a = 5 / 0;

} catch (ArithmeticException e) {

    System.out.println("Caught Exception");

} finally {

    System.out.println("Finally always runs");

}

```

  

**Output:**

```

Caught Exception

Finally always runs

```

  

---

  

### 3. With uncaught exception

  

```java

try {

    String s = null;

    s.length(); // NullPointerException

} finally {

    System.out.println("Still runs this");

}

```

  

**Output:**

```

Still runs this

Exception in thread "main" java.lang.NullPointerException

```

  

Even if the exception is not caught, the `finally` block still executes before the program crashes.

  

---

  

## 🔒 In Context of Locks

  

```java

lock.lock();

try {

    // Critical section

} finally {

    lock.unlock(); // Always releases the lock, even if exception occurs

}

```

  

This is **essential** for preventing deadlocks.

  

---

  

## ⚠️ Caveats

  

1. If `System.exit()` is called in the `try` block, `finally` **will not execute**.

2. If the JVM crashes (e.g., `kill -9`), the `finally` block also won’t run.

3. If there's a `return` in `try` or `catch`, `finally` still executes **before** the method returns.

  

```java

public int test() {

    try {

        return 1;

    } finally {

        System.out.println("Finally runs even before return");

    }

}

```

  

---

  

## 🧠 TL;DR

  

| Aspect         | Behavior                                |

|----------------|------------------------------------------|

| Always runs?   | ✅ Yes (even with exceptions or return)   |

| When skipped?  | ❌ If JVM crashes or `System.exit()`      |

| Common use     | ✅ Cleanup like unlocking, closing streams |

---

  

# 🔐 Understanding `ReentrantLock` in Java

  

## ✅ What is `ReentrantLock`?

  

A `ReentrantLock` is a mutual exclusion lock with extended capabilities compared to `synchronized`:

  

- **Reentrant**: The same thread can acquire the lock multiple times.

- Supports:

  - **Fairness** (`new ReentrantLock(true)`)

  - **Interruptibility**

  - **Multiple Conditions**

  - **Try locking**

  

---

  

## 🔁 Basic Usage

  

```java

ReentrantLock lock = new ReentrantLock();

  

lock.lock();

try {

    // critical section

} finally {

    lock.unlock();

}

```

  

Equivalent to `synchronized`, but more flexible and powerful.

  

---

  

## ⚙️ How it Works

  

### `lock()`

- Acquires the lock if available.

- If not, the thread waits in a queue (FIFO if fair).

- Thread blocks until it acquires the lock.

  

### `unlock()`

- Releases the lock.

- If other threads are waiting, one is selected to acquire it.

  

### Reentrancy

```java

lock.lock();  // First acquisition

lock.lock();  // Allowed — same thread

...

lock.unlock();

lock.unlock();  // Must match number of locks

```

  

---

  

## 🧠 Why Use `Condition`

  

With `synchronized`, only one wait/notify queue.

With `ReentrantLock`, you can use **multiple `Condition` queues**:

  

```java

Condition notFull = lock.newCondition();

Condition notEmpty = lock.newCondition();

```

  

- `await()` — wait on condition.

- `signal()` — wake one waiting thread on that condition.

- `signalAll()` — wake all threads on that condition.

  

---

  

## 🧪 Example: BoundedBlockingQueue

  

```java

class BoundedBlockingQueue {

    private Queue<Integer> queue = new LinkedList<>();

    private int capacity;

    private ReentrantLock lock = new ReentrantLock();

    private Condition notFull = lock.newCondition();

    private Condition notEmpty = lock.newCondition();

  

    public void enqueue(int element) throws InterruptedException {

        lock.lock();

        try {

            while (queue.size() == capacity) {

                notFull.await();

            }

            queue.offer(element);

            notEmpty.signal(); // notify one consumer

        } finally {

            lock.unlock();

        }

    }

  

    public int dequeue() throws InterruptedException {

        lock.lock();

        try {

            while (queue.isEmpty()) {

                notEmpty.await();

            }

            int item = queue.poll();

            notFull.signal(); // notify one producer

            return item;

        } finally {

            lock.unlock();

        }

    }

}

```

  

---

  

## ✅ `ReentrantLock` vs `synchronized`

  

| Feature                 | `synchronized`        | `ReentrantLock`            |

|-------------------------|------------------------|-----------------------------|

| Lock acquisition        | Implicit               | Explicit (`lock()`)        |

| Lock release            | Implicit               | Explicit (`unlock()`)      |

| Reentrancy              | ✅ Yes                 | ✅ Yes                     |

| Multiple conditions     | ❌ No                  | ✅ Yes                     |

| Fairness                | ❌ No                  | ✅ With constructor         |

| Try lock                | ❌ No                  | ✅ (`tryLock()`)            |

| Interruptible wait      | ❌ No                  | ✅ (`lockInterruptibly()`)  |

  

---

  

## ⚠️ Common Gotchas

  

- **Always use `unlock()` in `finally`** to avoid deadlocks.

- Fair locks may reduce throughput due to strict ordering.

- Prefer `synchronized` for simple use cases.