# Java Streams: Laziness, Pulling, and Custom Stream Implementation – Full Discussion

  

## ❓ Question 1: What do we mean when we say Streams are not stored in memory in Java? How does it work then actually?

  

When we say **Streams are not stored in memory in Java**, we mean that:

  

> **Streams don't hold or store data themselves.**  

> They **operate on data** (like a sequence of elements from a collection, array, or I/O channel), **process it one element at a time**, and **do not cache** or retain all elements in memory.

  

---

  

### 🔍 So how do Java Streams work then?

  

Java Streams are **pipelines of operations** that are:

  

1. **Lazily evaluated** – nothing happens until a *terminal operation* is triggered.

2. **Pull-based** – each element is pulled through the pipeline one at a time.

  

---

  

### 📌 Example:

```java

List<Integer> list = Arrays.asList(1, 2, 3, 4, 5);

  

int sum = list.stream()

              .filter(x -> x % 2 == 1)

              .map(x -> x * x)

              .reduce(0, Integer::sum);

```

  

#### What happens internally:

  

1. `stream()` creates a stream view of the list.

2. The operations `filter`, `map`, and `reduce` are chained.

3. No actual processing is done until `reduce()` is called.

4. Then, elements are:

   - Pulled **one by one**

   - Passed through `filter` → `map` → `reduce`

   - Without the whole list being loaded into any internal buffer.

  

---

  

### 🔄 Contrast with Collections:

  

- A `List` **stores** all elements in memory.

- A `Stream` just **provides a way to access/transform elements**, *without storing them*.

  

---

  

### 🧠 Why is this useful?

  

- **Memory-efficient**: Stream operations can work on infinite data (like lines of a file).

- **Composable**: You can chain many operations without creating intermediate collections.

- **Parallelizable**: Java streams can run in parallel easily with `.parallelStream()`.

  

---

  

### ✅ Summary:

  

> Java Streams **do not store data**.  

> They **operate over data sources** (like collections or I/O), **process elements one at a time**, and **do not retain elements** in memory unless you explicitly collect them (e.g., using `.collect(Collectors.toList())`).

  

---

  

## ❓ Question 2: But how does this pulling happen?

  

Java Streams use a **pull-based model**, where each pipeline stage **pulls data from the previous stage** one element at a time.

  

---

  

### ✅ Key components that make this work:

  

1. **Spliterator** (source of data)

2. **Pipeline stages** (intermediate operations like `filter`, `map`)

3. **Sink** (where the data ends up — typically inside terminal operations like `reduce`, `collect`, etc.)

  

---

  

### 📦 Think of the Stream like an assembly line:

  

```

[Source] → [filter] → [map] → [reduce/collect/etc.]

```

  

Now imagine that **`reduce` pulls one item**:

- It asks `map` for one item.

- `map` asks `filter` for one item.

- `filter` asks the source (via the Spliterator) for one item.

- Once the item is pulled, it flows forward through the pipeline.

  

---

  

### 👇 Step-by-step pulling in action:

  

```java

Stream<Integer> s = List.of(1, 2, 3, 4).stream()

    .filter(x -> x % 2 == 0)

    .map(x -> x * 10);

```

  

Terminal operation:

```java

s.findFirst();

```

  

#### Internally:

1. `findFirst()` needs one value.

2. It asks `map` for one element.

3. `map` asks `filter` for one.

4. `filter` uses the `Spliterator` of the `List` to pull the first value (`1`).

5. `filter` sees 1 is odd → skips it → pulls next (`2`) → passes it forward.

6. `map` receives `2` → maps it to `20`.

7. `findFirst()` gets `20` → done.

  

➡️ **Only 2 elements were actually touched**, and **no intermediate collections were created**.

  

---

  

## 🛠 Internal Classes Involved:

  

- **`Spliterator<T>`** – source abstraction used to pull elements from collections, arrays, etc.

- **`AbstractPipeline`** – internal class representing each stage in the pipeline.

- **`Sink<T>`** – each stage wraps downstream operations using `begin()`, `accept()`, `end()`, etc.

  

Each intermediate stage wraps the downstream `Sink` and transforms the data as it flows through.

  

---

  

## ❓ Question 3: Can you explain the significance of the term "lazy"?

  

### 🚀 What does **"lazy"** mean in Java Streams?

  

> **Lazy evaluation** means that operations are **not executed immediately**, but **only when needed**, and **only as much as needed**.

  

---

  

### ⚙️ Example: Lazy vs Eager

  

#### Eager Evaluation (like a for-loop)

```java

List<String> result = new ArrayList<>();

for (String name : names) {

    if (name.startsWith("A")) {

        result.add(name.toUpperCase());

    }

}

```

  

---

  

#### Lazy Evaluation with Stream

```java

Stream<String> stream = names.stream()

    .filter(name -> {

        System.out.println("Filtering: " + name);

        return name.startsWith("A");

    })

    .map(name -> {

        System.out.println("Mapping: " + name);

        return name.toUpperCase();

    });

  

// No output yet — only pipeline is defined

  

List<String> result = stream.collect(Collectors.toList());

```

  

> Output only appears when `collect()` is called.

  

---

  

## ✅ Why Laziness is Important

  

- **Memory-efficient**

- **Performance-optimized**

- **Short-circuiting**

- **Works with infinite streams**

  

---

  

## ❓ Question 4: So is Stream just a view/iterator?

  

> A Java Stream is conceptually **like a view or an enhanced iterator**.

  

But also:

  

- Not indexable

- Single-use

- Declarative

- Lazy and composable

- Supports parallelism and infinite data sources

  

---

  

## ❓ Question 5: How can I implement my own lazy stream?

  

### Functional Interfaces:

```java

@FunctionalInterface

interface Mapper<T, R> {

    R apply(T input);

}

  

@FunctionalInterface

interface Filter<T> {

    boolean test(T input);

}

  

@FunctionalInterface

interface Consumer<T> {

    void accept(T input);

}

```

  

---

  

### LazyStream class:

```java

public class LazyStream<T> {

    private final Iterable<T> source;

    private final List<Filter<T>> filters = new ArrayList<>();

    private final List<Mapper<?, ?>> mappers = new ArrayList<>();

  

    public LazyStream(Iterable<T> source) {

        this.source = source;

    }

  

    public LazyStream<T> filter(Filter<T> predicate) {

        filters.add(predicate);

        return this;

    }

  

    public <R> LazyStream<R> map(Mapper<T, R> mapper) {

        LazyStream<R> newStream = new LazyStream<>(() -> new LazyIterator<>(this.iterator(), mapper));

        return newStream;

    }

  

    public void forEach(Consumer<T> action) {

        for (T item : this) {

            action.accept(item);

        }

    }

  

    public Iterator<T> iterator() {

        return new LazyIterator<>(source.iterator(), filters);

    }

}

```

  

---

  

### LazyIterator class:

```java

class LazyIterator<T> implements Iterator<T> {

    private final Iterator<T> source;

    private final List<Filter<T>> filters;

    private T nextItem;

    private boolean hasNextComputed = false;

  

    public LazyIterator(Iterator<T> source, List<Filter<T>> filters) {

        this.source = source;

        this.filters = filters;

    }

  

    @Override

    public boolean hasNext() {

        if (hasNextComputed) return nextItem != null;

  

        while (source.hasNext()) {

            T item = source.next();

            boolean passed = true;

            for (Filter<T> f : filters) {

                if (!f.test(item)) {

                    passed = false;

                    break;

                }

            }

            if (passed) {

                nextItem = item;

                hasNextComputed = true;

                return true;

            }

        }

  

        nextItem = null;

        hasNextComputed = true;

        return false;

    }

  

    @Override

    public T next() {

        if (!hasNextComputed) hasNext();

        hasNextComputed = false;

        return nextItem;

    }

}

```

  

---

  

### Example Usage:

```java

public class Main {

    public static void main(String[] args) {

        List<Integer> nums = Arrays.asList(1, 2, 3, 4, 5, 6);

  

        LazyStream<Integer> stream = new LazyStream<>(nums);

  

        stream.filter(n -> n % 2 == 0)

              .forEach(n -> System.out.println("Even: " + n));

    }

}

```

  

---

  

## ✅ Summary

  

- Java Streams are **pull-based**, **lazy**, **single-use**, and **composable**.

- You can build your own stream-like engine using iterators and higher-order functions.