> Java is always pass-by-value. For wrapper classes like `Integer`, the value being passed is a copy of the reference. Since wrappers are immutable, reassigning or “changing” them inside a method does not affect the original variable.


```
void update(Integer x) {
    x = 20;
}

public static void main(String[] args) {
    Integer a = 10;
    update(a);
    System.out.println(a); // 10
}
```

