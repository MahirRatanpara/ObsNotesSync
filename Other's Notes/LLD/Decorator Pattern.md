
>**Decorator** is a structural design pattern that lets you attach new behaviors to objects by placing these objects inside special wrapper objects that contain the behaviors.
>
>**Example**: 
>	- A Coffee store, with the base being a Simple Coffee and decorators being Milk, Extra Sugar, Cream etc.
>	- A Pizza store, having a base pizza and different toppings as decorators.
>	
>**Resources**: https://refactoring.guru/design-patterns/decorator


![[Pasted image 20250126184345.png]]


---

![[Pasted image 20250126222526.png]]



## Applicability


- Use the Decorator pattern when you need to be able to assign extra behaviors to objects at runtime without breaking the code that uses these objects.
- Use the pattern when it’s awkward or not possible to extend an object’s behavior using inheritance.
	- Many programming languages have the `final` keyword that can be used to prevent further extension of a class. For a final class, the only way to reuse the existing behavior would be to wrap the class with your own wrapper, using the Decorator pattern.

---

## How to Implement

1. Make sure your business domain can be represented as a primary component with multiple optional layers over it.
    
2. Figure out what methods are common to both the primary component and the optional layers. Create a component interface and declare those methods there.
    
3. Create a concrete component class and define the base behavior in it.
    
4. Create a base decorator class. It should have a field for storing a reference to a wrapped object. The field should be declared with the component interface type to allow linking to concrete components as well as decorators. The base decorator must delegate all work to the wrapped object.
    
5. Make sure all classes implement the component interface.
    
6. Create concrete decorators by extending them from the base decorator. A concrete decorator must execute its behavior before or after the call to the parent method (which always delegates to the wrapped object).
    
7. The client code must be responsible for creating decorators and composing them in the way the client needs.


---


