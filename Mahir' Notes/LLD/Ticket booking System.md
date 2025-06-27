
## Rough Flow:

![[Pasted image 20250626225215.png]]

## Objects identified:

- User
- City (Location)
- Movie
- Theater
- **Screens**
- Show
- Seat
- Booking
- Payment

## First Draft of Design:

![[Pasted image 20250626233913.png]]

**Flaws in the design, the missing part of the requirements:

- Here the movies are not linked with the Location directly, and our requirement suggests to have movie as a searchable resource with respect to Location
- Theater does not have a location but each location has list of theaters, which is not ideal for out use case
- We have not talked about the CRUD operation anywhere like adding a movie or adding a show for a movie in theater
- We should also look at aspect of adding a service which user can coordinate with to initiate the booking.
- Theater does not have a list of screens as well and only coupled via show, but there can be empty screens as well right
- Also we forgot to managed already booked seats
- Booking is also not covering the seats which we have booked

## Design Considerations: 

- Here the movie is tied up the the bottom layer of design which is show and also the initial layer which is location
- Also the theater need to be in a city but we need a city wise list of theaters as well (theater and shows) which can come up when a particular movie is selected in a city.

## Solve the Gap:

1. Introduce Movie Repository which can store the City vs Movie Mapping to store to make movie List via City, and also supports CRUD
2. Introduce Theater Repository to store Theaters in a City, which decouples the City from theater and adds CRUD operations.
3. Add a booking service which can be called to obtain the List of movies in City, List of shows with that movie in a city, initiate the booking and finalize the booking.
4. Add List of Screens in theater to support the Screens independent of any show.
5. Adding information related to booked seats in the Seats class to filter out the available seats, and also add Seats information in the Booking to make more sense.

## Final Design:

![[Movie Booking System.drawio.png]]


