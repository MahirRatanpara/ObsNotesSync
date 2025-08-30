

### 💡 Use Case: Immutable Meal Plan Generator with Fluent API


### 🧩 Problem Statement  

Design a `Meal` class that supports the building of complex, immutable objects representing daily meal plans. Use a fluent builder interface to construct combinations.

  

Constraints:

- `Meal` is immutable.

- Support validation (e.g., max 2 desserts, 1 drink).

- Builder should support chaining and enforce valid build sequences.

  

### 🧱 Class Scaffolding

```java

class Meal {

    private final List<String> mainCourse;

    private final String drink;

    private final List<String> desserts;

    // Getters

  

    static class Builder {

        // fluent methods like addMainCourse(), setDrink(), addDessert(), build()

    }

}

```

  

### 🧠 Hints

- Use private constructor in `Meal`.

- Use nested `Builder` class.

- Apply validation logic inside `build()`.

  

### ✅ Expected Output

```

Meal: Pasta, Coke, IceCream, Brownie

```

  

