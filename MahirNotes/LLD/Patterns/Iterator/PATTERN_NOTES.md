# Iterator Pattern

## Overview
The Iterator pattern is a behavioral design pattern that provides a way to access elements of a collection sequentially without exposing its underlying representation (array, list, tree, etc.). It separates the traversal logic from the collection itself.

**Analogy**: Like a TV remote control - you can navigate through channels (next, previous) without knowing how the TV stores and organizes channel data internally. The remote provides a simple interface to traverse channels.

## When to Use

### Use Iterator Pattern When:
1. **Need to traverse a collection without exposing its internal structure**
   - Hide implementation details (array, linked list, tree, etc.)
   - Client shouldn't depend on internal representation
   - Can change internal structure without affecting clients

2. **Multiple traversal algorithms needed**
   - Forward, backward, skip-based traversal
   - Filtered traversal (only certain elements)
   - Different orderings (sorted, reverse, random)

3. **Want uniform interface for different collection types**
   - Same traversal code works with array, list, tree, etc.
   - Polymorphic iteration
   - Client code agnostic to collection type

4. **Multiple concurrent traversals needed**
   - Different iterators maintain independent positions
   - Can iterate through same collection multiple times simultaneously
   - Each iterator has its own state

5. **Reduce responsibility of collection class**
   - Collection focuses on storage
   - Iterator focuses on traversal
   - Single Responsibility Principle

### Don't Use When:
- Simple array access is sufficient
- Collection is very simple and won't change
- Only one traversal method ever needed
- Performance is critical (iterator adds overhead)

## Key Components

```
┌──────────────┐
│  Iterator    │ ←─── Iterator interface
├──────────────┤
│ +hasNext()   │
│ +next()      │
│ +remove()    │
└──────┬───────┘
       │
       │ implements
       │
┌──────▼────────────┐
│ConcreteIterator   │ ←─── Specific iterator
├───────────────────┤
│ -collection       │
│ -currentPosition  │
├───────────────────┤
│ +hasNext()        │
│ +next()           │
└───────────────────┘
       ▲
       │ creates
       │
┌──────┴───────┐
│  Collection  │ ←─── Collection interface
├──────────────┤
│ +iterator()  │
└──────┬───────┘
       │
       │ implements
       │
┌──────▼────────────┐
│ConcreteCollection │ ←─── Specific collection
├───────────────────┤
│ -items[]          │
├───────────────────┤
│ +iterator()       │
│ +add()            │
│ +remove()         │
└───────────────────┘
```

1. **Iterator**: Interface for traversing elements
2. **ConcreteIterator**: Implements traversal algorithm
3. **Collection**: Interface for creating iterators
4. **ConcreteCollection**: Returns appropriate iterator

## Benefits

### 1. **Hides Internal Representation**
```java
// Client doesn't know if it's array, list, tree, etc.
Iterator<Book> iterator = library.iterator();
while (iterator.hasNext()) {
    Book book = iterator.next();
    // Don't care about internal structure
}
```

### 2. **Single Responsibility Principle**
```java
// Collection: Manages storage
class BookCollection {
    void add(Book book) { }
    void remove(Book book) { }
}

// Iterator: Manages traversal
class BookIterator {
    boolean hasNext() { }
    Book next() { }
}
```

### 3. **Multiple Simultaneous Traversals**
```java
Iterator<Book> it1 = library.iterator();
Iterator<Book> it2 = library.iterator();

// Two independent traversals
Book book1 = it1.next();
Book book2 = it2.next(); // Different position
```

### 4. **Uniform Interface for Different Collections**
```java
// Same iteration code works with different collections
void printBooks(Collection<Book> books) {
    for (Book book : books) { // Uses iterator internally
        System.out.println(book);
    }
}

printBooks(arrayList);
printBooks(linkedList);
printBooks(treeSet);
```

### 5. **Different Traversal Strategies**
```java
// Forward iterator
Iterator<Book> forward = library.forwardIterator();

// Backward iterator
Iterator<Book> backward = library.backwardIterator();

// Filtered iterator
Iterator<Book> fiction = library.filteredIterator(book -> book.isFiction());
```

## Implementation Example

### Scenario: Book Collection

```java
// Iterator Interface
interface Iterator<T> {
    boolean hasNext();
    T next();
}

// Collection Interface
interface IterableCollection<T> {
    Iterator<T> createIterator();
}

// Concrete Collection
class BookCollection implements IterableCollection<Book> {
    private Book[] books;
    private int size;
    private int capacity;

    public BookCollection(int capacity) {
        this.capacity = capacity;
        this.books = new Book[capacity];
        this.size = 0;
    }

    public void addBook(Book book) {
        if (size < capacity) {
            books[size++] = book;
        }
    }

    public int getSize() {
        return size;
    }

    public Book getBookAt(int index) {
        if (index >= 0 && index < size) {
            return books[index];
        }
        return null;
    }

    @Override
    public Iterator<Book> createIterator() {
        return new BookIterator(this);
    }
}

// Concrete Iterator
class BookIterator implements Iterator<Book> {
    private BookCollection collection;
    private int currentPosition;

    public BookIterator(BookCollection collection) {
        this.collection = collection;
        this.currentPosition = 0;
    }

    @Override
    public boolean hasNext() {
        return currentPosition < collection.getSize();
    }

    @Override
    public Book next() {
        if (!hasNext()) {
            throw new NoSuchElementException();
        }
        return collection.getBookAt(currentPosition++);
    }
}

// Product Class
class Book {
    private String title;
    private String author;

    public Book(String title, String author) {
        this.title = title;
        this.author = author;
    }

    @Override
    public String toString() {
        return "\"" + title + "\" by " + author;
    }
}

// Client Code
public class Main {
    public static void main(String[] args) {
        BookCollection library = new BookCollection(5);
        library.addBook(new Book("1984", "George Orwell"));
        library.addBook(new Book("To Kill a Mockingbird", "Harper Lee"));
        library.addBook(new Book("The Great Gatsby", "F. Scott Fitzgerald"));

        // Using iterator
        System.out.println("Books in library:");
        Iterator<Book> iterator = library.createIterator();
        while (iterator.hasNext()) {
            Book book = iterator.next();
            System.out.println(book);
        }

        // Multiple simultaneous iterations
        Iterator<Book> it1 = library.createIterator();
        Iterator<Book> it2 = library.createIterator();

        System.out.println("\nFirst from it1: " + it1.next());
        System.out.println("First from it2: " + it2.next());
        System.out.println("Second from it1: " + it1.next());
        // Both maintain independent positions
    }
}
```

## Advanced Variations

### 1. Reverse Iterator

```java
class ReverseBookIterator implements Iterator<Book> {
    private BookCollection collection;
    private int currentPosition;

    public ReverseBookIterator(BookCollection collection) {
        this.collection = collection;
        this.currentPosition = collection.getSize() - 1;
    }

    @Override
    public boolean hasNext() {
        return currentPosition >= 0;
    }

    @Override
    public Book next() {
        if (!hasNext()) {
            throw new NoSuchElementException();
        }
        return collection.getBookAt(currentPosition--);
    }
}

// Add to BookCollection:
public Iterator<Book> createReverseIterator() {
    return new ReverseBookIterator(this);
}
```

### 2. Filtered Iterator

```java
class FilteredBookIterator implements Iterator<Book> {
    private BookCollection collection;
    private int currentPosition;
    private Predicate<Book> filter;

    public FilteredBookIterator(BookCollection collection, Predicate<Book> filter) {
        this.collection = collection;
        this.filter = filter;
        this.currentPosition = 0;
        findNext(); // Position at first matching element
    }

    private void findNext() {
        while (currentPosition < collection.getSize()) {
            Book book = collection.getBookAt(currentPosition);
            if (filter.test(book)) {
                break;
            }
            currentPosition++;
        }
    }

    @Override
    public boolean hasNext() {
        return currentPosition < collection.getSize();
    }

    @Override
    public Book next() {
        if (!hasNext()) {
            throw new NoSuchElementException();
        }
        Book book = collection.getBookAt(currentPosition++);
        findNext(); // Move to next matching element
        return book;
    }
}
```

### 3. Java's Built-in Iterator (with remove)

```java
class ModifiableBookIterator implements Iterator<Book> {
    private BookCollection collection;
    private int currentPosition;
    private boolean canRemove;

    @Override
    public boolean hasNext() {
        return currentPosition < collection.getSize();
    }

    @Override
    public Book next() {
        if (!hasNext()) {
            throw new NoSuchElementException();
        }
        canRemove = true;
        return collection.getBookAt(currentPosition++);
    }

    @Override
    public void remove() {
        if (!canRemove) {
            throw new IllegalStateException("next() not called");
        }
        collection.removeAt(currentPosition - 1);
        currentPosition--;
        canRemove = false;
    }
}
```

## Real-World Use Cases

### 1. **Java Collections Framework**
```java
List<String> list = new ArrayList<>();
Iterator<String> iterator = list.iterator();
while (iterator.hasNext()) {
    System.out.println(iterator.next());
}

// Enhanced for-loop uses iterator internally
for (String item : list) {
    System.out.println(item);
}
```

### 2. **Database Result Sets**
```java
ResultSet rs = statement.executeQuery("SELECT * FROM users");
while (rs.next()) { // Iterator pattern
    String name = rs.getString("name");
}
```

### 3. **File System Traversal**
```java
DirectoryStream<Path> stream = Files.newDirectoryStream(dir);
for (Path file : stream) { // Uses iterator
    System.out.println(file);
}
```

### 4. **Social Media Feeds**
```java
Iterator<Post> feed = socialMedia.getFeedIterator();
while (feed.hasNext()) {
    Post post = feed.next();
    display(post);
}
```

### 5. **Pagination**
```java
class PaginatedIterator<T> implements Iterator<T> {
    private int currentPage = 0;
    private List<T> currentBatch;

    public T next() {
        if (currentBatch.isEmpty()) {
            currentBatch = fetchNextPage(currentPage++);
        }
        return currentBatch.remove(0);
    }
}
```

## Comparison with Other Patterns

| Pattern | Purpose | Key Difference |
|---------|---------|----------------|
| **Iterator** | Sequential access to collection | Traversal logic |
| **Visitor** | Perform operations on elements | Operation logic |
| **Composite** | Tree structures | Hierarchical access |
| **Memento** | Save/restore state | State management |

### Iterator vs Visitor

**Iterator:**
```java
// Focuses on TRAVERSAL
Iterator<Book> it = library.iterator();
while (it.hasNext()) {
    Book book = it.next(); // Just traverse
}
```

**Visitor:**
```java
// Focuses on OPERATION
library.accept(new PrintVisitor()); // Performs operation on all
```

## Common Pitfalls

### 1. **Modifying Collection During Iteration**
```java
// Bad: ConcurrentModificationException
List<String> list = new ArrayList<>(Arrays.asList("a", "b", "c"));
for (String item : list) {
    if (item.equals("b")) {
        list.remove(item); // ❌ Modifies during iteration
    }
}

// Good: Use iterator's remove
Iterator<String> it = list.iterator();
while (it.hasNext()) {
    if (it.next().equals("b")) {
        it.remove(); // ✅ Safe removal
    }
}
```

### 2. **Not Checking hasNext()**
```java
// Bad: May throw NoSuchElementException
Iterator<Book> it = library.iterator();
Book book = it.next(); // What if empty?

// Good: Always check
if (it.hasNext()) {
    Book book = it.next();
}
```

### 3. **Reusing Exhausted Iterator**
```java
// Bad: Iterator exhausted, won't work again
Iterator<Book> it = library.iterator();
while (it.hasNext()) { it.next(); } // Consumes all

while (it.hasNext()) { // Never enters, exhausted
    it.next();
}

// Good: Create new iterator
Iterator<Book> newIt = library.iterator();
```

### 4. **Iterator State Not Independent**
```java
// Bad: Shared state between iterators
class BadIterator {
    private static int position = 0; // Shared!
}

// Good: Each iterator has own state
class GoodIterator {
    private int position = 0; // Instance variable
}
```

### 5. **Exposing Collection's Internal Structure**
```java
// Bad: Returns internal array
public Book[] getBooks() {
    return books; // Exposes internal structure
}

// Good: Returns iterator
public Iterator<Book> iterator() {
    return new BookIterator(this);
}
```

## Design Decisions

### Should Iterator Support remove()?

**With remove():**
```java
interface Iterator<T> {
    boolean hasNext();
    T next();
    void remove(); // Optional operation
}
```
- ✅ Can modify collection during iteration
- ❌ More complex implementation
- ❌ Not always needed

**Without remove():**
```java
interface Iterator<T> {
    boolean hasNext();
    T next();
}
```
- ✅ Simpler, read-only
- ✅ Immutable iteration
- ❌ Can't remove during iteration

**Best Practice**: Provide remove() only if collection is modifiable and it makes sense.

### Internal vs External Iterator?

**External Iterator (Pull):**
```java
// Client controls iteration
Iterator<Book> it = library.iterator();
while (it.hasNext()) {
    Book book = it.next();
    // Client decides when to advance
}
```
- ✅ More control
- ✅ Can pause/resume
- ✅ Multiple simultaneous iterations

**Internal Iterator (Push):**
```java
// Collection controls iteration
library.forEach(book -> {
    System.out.println(book); // Collection calls lambda
});
```
- ✅ Simpler for client
- ✅ Can optimize internally
- ❌ Less control

**Java supports both**: `Iterator` (external) and `forEach` (internal)

## Interview Questions to Expect

### 1. **What is the Iterator pattern?**
**Answer**: A behavioral pattern that provides sequential access to elements of a collection without exposing its underlying representation. It separates traversal logic from the collection.

### 2. **When would you use Iterator?**
**Answer**:
- Need to traverse collection without exposing structure
- Multiple traversal algorithms needed
- Want uniform interface for different collections
- Need multiple concurrent traversals

### 3. **What are the benefits?**
**Answer**:
- Hides internal representation
- Single Responsibility (storage vs traversal)
- Multiple simultaneous iterations
- Uniform interface for different collections
- Different traversal strategies

### 4. **What's the difference between Enumeration and Iterator in Java?**
**Answer**:
- **Enumeration**: Legacy, only hasMoreElements() and nextElement()
- **Iterator**: Modern, adds remove() method and better naming
- Iterator is preferred

### 5. **How does for-each loop work?**
**Answer**: For-each loop (`for (T item : collection)`) uses iterator internally. The collection must implement `Iterable` interface which provides `iterator()` method.

### 6. **What happens if you modify collection during iteration?**
**Answer**: Most Java collections throw `ConcurrentModificationException`. Use iterator's `remove()` method for safe removal during iteration.

### 7. **Can you have multiple iterators on same collection?**
**Answer**: Yes, each iterator maintains its own state (position). They can traverse independently without interfering.

### 8. **Iterator vs Visitor pattern?**
**Answer**:
- **Iterator**: Focuses on traversal, client performs operations
- **Visitor**: Focuses on operations, encapsulates operation logic
- Use Iterator for traversal, Visitor for applying operations

## Advantages vs Disadvantages

### Advantages
- ✅ Hides implementation details
- ✅ Single Responsibility Principle
- ✅ Multiple simultaneous iterations
- ✅ Uniform traversal interface
- ✅ Different traversal algorithms
- ✅ Open/Closed Principle (add new iterators)

### Disadvantages
- ❌ Overkill for simple collections
- ❌ Performance overhead
- ❌ More classes to maintain
- ❌ Can be less efficient than direct access
- ❌ Doesn't support bidirectional traversal well (need additional methods)

## Key Takeaways

1. **Purpose**: Provide sequential access without exposing structure
2. **When**: Complex collections, need encapsulation, multiple traversals
3. **How**: Separate Iterator object maintains traversal state
4. **Remember**: Separates storage from traversal
5. **Trade-off**: Encapsulation vs simplicity/performance

## Summary

The Iterator pattern is ideal when:
- ✅ Need to traverse collections without exposing internals
- ✅ Want multiple concurrent traversals
- ✅ Need different traversal strategies
- ✅ Want uniform interface across collection types

Remember: Iterator is about **traversal**. It separates "how to store" from "how to traverse". Java's `Iterator` interface and for-each loops are implementations of this pattern. Don't modify collections during iteration unless using iterator's `remove()` method.

## Pattern Checklist

When implementing Iterator:
- [ ] Define Iterator interface (hasNext, next)
- [ ] Define Collection interface (createIterator)
- [ ] Implement ConcreteIterator with traversal logic
- [ ] Iterator maintains current position
- [ ] Implement ConcreteCollection
- [ ] Collection creates and returns iterator
- [ ] Each iterator instance has independent state
- [ ] Consider implementing remove() if needed
- [ ] Handle edge cases (empty collection, exhausted iterator)
- [ ] Throw NoSuchElementException when next() called on exhausted iterator
- [ ] Consider supporting multiple iterator types (forward, reverse, filtered)
- [ ] Don't expose collection's internal structure
