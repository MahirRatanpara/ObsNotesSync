# BookMyShow LLD Interview - Comprehensive Baseline


---

## Phase 1: Problem Presentation (0-5 mins)

### **Interviewer**:

"Good afternoon! Today we'll be designing a movie ticket booking system similar to BookMyShow. You'll have about 75 minutes to work through this problem.

The basic idea is: users should be able to search for movies, see show timings, select seats, and book tickets. We'll start with the low-level design and then discuss some high-level aspects.

Before we dive in, take a few minutes to gather requirements and clarify any assumptions. Go ahead."

---

## Phase 2: Requirement Gathering (5-10 mins)

### **Candidate**:

"Thank you! Let me start by understanding the scope and requirements. I'll ask a few clarifying questions:

**Functional Requirements - Clarifications:**

1. Should the system support multiple cities and theaters?
2. Do we need to handle different show timings for the same movie at different theaters?
3. Should users be able to select specific seats or just quantity?
4. Do we need payment integration, or can we assume payments are handled externally?
5. Should we support cancellations and refunds?
6. Do we need user authentication and profiles?
7. Should theaters/admins be able to add movies and shows?

**Non-Functional Requirements - Assumptions:**

1. The system should handle high concurrency during popular movie releases
2. Seat booking should prevent double-booking (consistency is critical)
3. System should be available and responsive
4. We should support thousands of concurrent users"

### **Interviewer**:

"Great questions! Let me clarify:

- Yes, multiple cities and theaters
- Yes, multiple shows per movie per theater
- Users must select specific seats from a seat layout
- For now, assume a simplified payment - just mark payment as 'PENDING' or 'CONFIRMED'
- Let's skip cancellations for now to keep scope manageable
- Yes, basic user authentication (users have accounts)
- Yes, theater admins can add movies and shows

Focus primarily on the booking flow - search, seat selection, and booking confirmation. The concurrency aspect is very important here."

### **Candidate**:

"Perfect, thank you for the clarifications. Let me summarize the requirements:

**Functional Requirements:**

1. User registration and authentication
2. Browse movies by city
3. View theaters showing a specific movie
4. View show timings for a movie at a theater
5. View seat layout and availability for a show
6. Select seats and temporarily hold them
7. Complete booking with payment
8. View booking history
9. Theater admin can add movies, shows, and manage theaters

**Non-Functional Requirements:**

1. High availability and low latency for search operations
2. Strong consistency for seat booking (no double-booking)
3. Handle thousands of concurrent users
4. Scalable to support multiple cities and theaters

**Assumptions:**

1. Seat hold expires after 10 minutes if not confirmed
2. Each theater has multiple screens
3. Each screen has a specific seat layout
4. Seats can be of different types (REGULAR, PREMIUM, RECLINER)
5. Prices vary by seat type and show timing"

### **Interviewer**:

"Excellent summary. The seat hold expiry is a good catch - we'll discuss that when we get to concurrency. Proceed with the design."

---

## Phase 3: User Journey Mapping (10-15 mins)

### **Candidate**:

"Let me identify the key actors and their user journeys:

**Actors:**

1. **Customer/User** - Books tickets
2. **Theater Admin** - Manages theater, screens, shows
3. **System Admin** - Manages movies, cities (out of scope for now)

**Primary User Journey - Ticket Booking:**

```
1. User logs in
2. User selects city → Mumbai
3. User searches for movie → "Oppenheimer"
4. System shows list of theaters and show timings
5. User selects: PVR Phoenix, Screen 3, 7:00 PM show
6. System displays seat layout with availability
7. User selects seats: A5, A6
8. System places temporary hold on seats (10 min timer)
9. User proceeds to payment
10. Payment confirmed
11. System confirms booking, releases hold, marks seats as BOOKED
12. User receives booking confirmation
```

**Critical Paths:**

- **Happy Path**: Search → Select → Hold → Pay → Confirm
- **Concurrent Booking**: Two users select same seats simultaneously
- **Timeout Path**: User doesn't complete payment within 10 minutes, seats released
- **Payment Failure**: Payment fails, seats released

**Admin Journey:**

```
1. Theater admin logs in
2. Admin adds/updates theater information
3. Admin adds screens to theater with seat layout
4. Admin creates shows (movie + screen + timing + pricing)
```

### **Interviewer**:
"Good. I notice you mentioned a 10-minute hold. How will you track this? We'll get into implementation details later, but keep this in mind."

### **Candidate**:
"Yes, we'll need to track the hold with a timestamp and have a mechanism to expire and release seats. I'll address this in the concurrency section and also in the HLD section where we discuss Redis-based hold management."

---

## Phase 4: Entity & Data Modeling (15-35 mins)

### **Candidate**:
"Let me identify the core entities and their relationships, then map them to database tables.

### **Step 1: Core Entities (Java/OOP Perspective)**

**1. User**
```java
class User {
    Long userId;
    String name;
    String email;
    String phoneNumber;
    String passwordHash;
    LocalDateTime createdAt;
}
```

**2. City**
```java
class City {
    Long cityId;
    String cityName;
    String state;
}
```

**3. Theater**
```java
class Theater {
    Long theaterId;
    String theaterName;
    Long cityId; // FK to City
    String address;
    List<Screen> screens;
}
```

**4. Screen**
```java
class Screen {
    Long screenId;
    Long theaterId; // FK to Theater
    String screenName; // "Screen 1", "IMAX Screen"
    int totalSeats;
    SeatLayout seatLayout;
}
```

**5. Seat**
```java
class Seat {
    Long seatId;
    Long screenId; // FK to Screen
    String seatNumber; // "A5", "B12"
    SeatType seatType; // REGULAR, PREMIUM, RECLINER
    int rowNumber;
    int columnNumber;
}

enum SeatType {
    REGULAR, PREMIUM, RECLINER
}
```

**6. Movie**
```java
class Movie {
    Long movieId;
    String movieName;
    String description;
    String language;
    int durationMinutes;
    String genre;
    LocalDate releaseDate;
}
```

**7. Show**
```java
class Show {
    Long showId;
    Long movieId; // FK to Movie
    Long screenId; // FK to Screen
    LocalDateTime showTime;
    LocalDateTime showEndTime;
    ShowStatus status; // SCHEDULED, ONGOING, COMPLETED, CANCELLED
}

enum ShowStatus {
    SCHEDULED, ONGOING, COMPLETED, CANCELLED
}
```

**8. ShowSeat**
```java
class ShowSeat {
    Long showSeatId;
    Long showId; // FK to Show
    Long seatId; // FK to Seat
    SeatStatus status; // AVAILABLE, LOCKED, BOOKED
    BigDecimal price;
    Long lockedByUserId; // null if not locked
    LocalDateTime lockedAt; // null if not locked
}

enum SeatStatus {
    AVAILABLE, LOCKED, BOOKED
}
```

**9. Booking**
```java
class Booking {
    Long bookingId;
    Long userId; // FK to User
    Long showId; // FK to Show
    List<ShowSeat> bookedSeats;
    BookingStatus status; // PENDING, CONFIRMED, CANCELLED
    BigDecimal totalAmount;
    LocalDateTime bookingTime;
    LocalDateTime expiryTime;
}

enum BookingStatus {
    PENDING, CONFIRMED, CANCELLED, EXPIRED
}
```

**10. Payment**
```java
class Payment {
    Long paymentId;
    Long bookingId; // FK to Booking
    BigDecimal amount;
    PaymentStatus status; // PENDING, COMPLETED, FAILED
    String paymentMethod;
    LocalDateTime paymentTime;
    String transactionId;
}

enum PaymentStatus {
    PENDING, COMPLETED, FAILED, REFUNDED
}
```


**Critical Relationship - Seat vs ShowSeat:**
```java
// Seat - Physical infrastructure (static, reusable)
class Seat {
    Long seatId;
    Long screenId;
    String seatNumber; // "A5"
    SeatType seatType; // REGULAR, PREMIUM, RECLINER
}

// ShowSeat - Ephemeral state for specific show (dynamic)
class ShowSeat {
    Long showSeatId;
    Long showId;
    Long seatId; // References physical seat
    SeatStatus status; // AVAILABLE, LOCKED, BOOKED
    BigDecimal price; // Can vary by show (matinee vs evening)
    Long lockedByUserId;
    LocalDateTime lockedAt;
}
````

**Why this separation?**

- **Seat**: Represents physical infrastructure - created once, reused for every show
- **ShowSeat**: Represents seat availability for a specific show - tracks who locked it, when, and at what price
- Without this, we'd duplicate seat info for every show or couldn't track per-show state

**Relationships:**

- City **1 → N** Theater
- Theater **1 → N** Screen
- Screen **1 → N** Seat (physical seats)
- Movie **1 → N** Show
- Screen **1 → N** Show (different timings)
- Show **1 → N** ShowSeat
- Seat **1 → N** ShowSeat (same physical seat across multiple shows)
- User **1 → N** Booking
- Booking **M → N** ShowSeat (via booking_seats join table)"

### **Interviewer**:

"Good separation of Seat and ShowSeat. Now, what database are you planning to use and why?"

### **Candidate**:

"I'm choosing **MySQL** as the primary database.

**Why MySQL?**

1. **ACID guarantees**: Seat booking requires strong consistency - no double-booking tolerated
2. **Complex queries**: Need to join across theaters, shows, seats, bookings
3. **Well-defined schema**: Our domain has clear relationships
4. **Transaction support**: Critical for atomic seat locking and booking creation
5. **Mature ecosystem**: Battle-tested for booking systems

**Why NOT alternatives?**

- **PostgreSQL**: Similar to MySQL, either works. MySQL has slightly better read performance for our use case
- **MongoDB**: NoSQL is flexible but we don't need schema flexibility; we need ACID and joins
- **Cassandra**: Write-optimized, eventual consistency - wrong fit for booking (need strong consistency)

Now let me design the schema."

### **Step 2: Database Schema Design**

### **Candidate**:

"I'll show critical tables in full detail, then summarize others.

#### **Critical Table 1: show_seats** (Core of booking system)

```sql
show_seats (
    show_seat_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    show_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    status ENUM('AVAILABLE', 'LOCKED', 'BOOKED') DEFAULT 'AVAILABLE',
    price DECIMAL(10, 2) NOT NULL,
    locked_by_user_id BIGINT,
    locked_at TIMESTAMP NULL,
    FOREIGN KEY (show_id) REFERENCES shows(show_id),
    FOREIGN KEY (seat_id) REFERENCES seats(seat_id),
    FOREIGN KEY (locked_by_user_id) REFERENCES users(user_id),
    UNIQUE KEY unique_show_seat (show_id, seat_id),
    INDEX idx_show_status (show_id, status),
    INDEX idx_locked_user (locked_by_user_id, locked_at)
)
```

**Index Justification:**

- `idx_show_status`: **Most critical query** - "Get all AVAILABLE seats for show X"
    - Without this: Full table scan of millions of rows
    - With this: Instant lookup using composite index
- `idx_locked_user`: Used by lock expiry cleanup job - "Find all seats locked by user Y that expired"
- `unique_show_seat`: Prevents duplicate entries (same seat appearing twice in a show)

#### **Critical Table 2: bookings**

```sql
bookings (
    booking_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    show_id BIGINT NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'CANCELLED', 'EXPIRED') DEFAULT 'PENDING',
    total_amount DECIMAL(10, 2) NOT NULL,
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_time TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (show_id) REFERENCES shows(show_id),
    INDEX idx_user_bookings (user_id, booking_time),
    INDEX idx_show_bookings (show_id),
    INDEX idx_expiry (expiry_time),
    INDEX idx_status (status)
)
```

**Index Justification:**

- `idx_user_bookings`: "Show me all bookings for user X" - user's booking history page
- `idx_expiry`: Background job query - "Find all PENDING bookings that expired"
- `idx_status`: Analytics query - "How many confirmed bookings today?"

#### **Critical Table 3: users**

```sql
users (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_phone (phone_number)
)
```

**Index Justification:**

- `idx_email`, `idx_phone`: Login queries - "Find user by email" or "Find user by phone"
- UNIQUE constraints prevent duplicate registrations

#### **Other Tables (Summary)**

**shows**

```
shows (show_id, movie_id, screen_id, show_time, show_end_time, status)
INDEXES: idx_movie_show_time (movie_id, show_time), idx_screen_show_time (screen_id, show_time)
CONSTRAINT: unique_screen_time (screen_id, show_time) -- prevents double-booking of screen
```

**theaters, screens, seats, cities, movies, payments, booking_seats**

```
theaters (theater_id, theater_name, city_id, address)
screens (screen_id, theater_id, screen_name, total_seats)
seats (seat_id, screen_id, seat_number, seat_type, row_number, column_number)
  CONSTRAINT: unique_seat_per_screen (screen_id, seat_number)
cities (city_id, city_name, state)
movies (movie_id, movie_name, description, language, duration_minutes, genre, release_date)
payments (payment_id, booking_id, amount, status, payment_method, transaction_id)
booking_seats (booking_seat_id, booking_id, show_seat_id) -- Many-to-many join table
```

### **Overall Index Strategy**

**Principle**: Index columns that appear in:

1. WHERE clauses of frequent queries
2. JOIN conditions
3. ORDER BY / GROUP BY clauses

**Trade-off**: Indexes speed up reads but slow down writes. For booking systems, read performance (seat availability) is more critical than write performance."

### **Interviewer**:

"Good indexing rationale. I see you have `locked_at` timestamp in `show_seats`. We'll discuss the lock expiry mechanism in detail during concurrency. Move to APIs."

---

> [!note] **📚 Educational Note: Entity Modeling & Database Design**
> 
> **OOP vs Relational Mapping:**
> 
> - Java classes use **composition** (Booking has List<ShowSeat\>
> - Database uses **foreign keys + join tables** (booking_seats table)
> - Many-to-many relationships always need junction tables in SQL
> 
> **Why MySQL for Booking Systems:**
> 
> - ACID transactions prevent race conditions
> - SELECT ... FOR UPDATE provides row-level locking
> - Strong consistency over eventual consistency
> 
> **Index Selection Strategy:**
> 
> - Profile your queries first (use EXPLAIN in MySQL)
> - Composite indexes: Order matters! `(show_id, status)` ≠ `(status, show_id)`
> - Don't over-index: Each index adds write overhead
> 
> **📚 STUDY**: Database normalization (1NF, 2NF, 3NF) and when to denormalize for performance

---

## Phase 5: API Design (35-45 mins)

### **Candidate**:

"Let me design the REST APIs. I'll show detailed examples for GET and POST, and brief definitions for others.

### **Detailed Example 1: GET Request**

```http
GET /api/v1/shows/{showId}/seats

Headers:
  Authorization: Bearer <jwt_token>

Response: 200 OK
{
  "showId": 1001,
  "movieName": "Oppenheimer",
  "theaterName": "PVR Phoenix",
  "screenName": "Screen 3",
  "showTime": "2024-07-15T19:00:00",
  "seatLayout": [
    {
      "showSeatId": 10001,
      "seatNumber": "A1",
      "seatType": "REGULAR",
      "row": 1,
      "column": 1,
      "status": "AVAILABLE",
      "price": 250.00
    },
    {
      "showSeatId": 10002,
      "seatNumber": "A2",
      "seatType": "REGULAR",
      "row": 1,
      "column": 2,
      "status": "BOOKED",
      "price": 250.00
    },
    {
      "showSeatId": 10003,
      "seatNumber": "A3",
      "seatType": "PREMIUM",
      "row": 1,
      "column": 3,
      "status": "LOCKED",
      "price": 400.00
    }
    // ... rest of seats
  ]
}

Status Codes:
- 200 OK: Success
- 404 Not Found: Show doesn't exist
- 401 Unauthorized: Invalid/missing token
```

**Why return full seat layout?**

- Frontend needs to render seat map with colors (green=available, red=booked, yellow=locked)
- This response structure is part of our discussion because it shapes the UI

### **Detailed Example 2: POST Request (Critical for Concurrency)**

```http
POST /api/v1/shows/{showId}/seats/lock

Headers:
  Authorization: Bearer <jwt_token>
  X-Idempotency-Key: <client-generated-uuid>

Request Body:
{
  "showSeatIds": [10001, 10002, 10003]
}

Response: 200 OK
{
  "bookingId": 8001,
  "status": "PENDING",
  "lockedSeats": [
    {
      "showSeatId": 10001,
      "seatNumber": "A1",
      "price": 250.00
    },
    {
      "showSeatId": 10002,
      "seatNumber": "A2",
      "price": 250.00
    }
  ],
  "totalAmount": 500.00,
  "expiryTime": "2024-07-15T14:35:00",
  "message": "Seats locked for 10 minutes"
}

Response: 409 CONFLICT (Some seats unavailable)
{
  "error": "SEATS_UNAVAILABLE",
  "message": "Some seats are no longer available",
  "unavailableSeats": [10003],
  "availableAlternatives": [10005, 10006]
}

Status Codes:
- 200 OK: Seats successfully locked
- 400 Bad Request: Invalid seat IDs or empty list
- 401 Unauthorized: Invalid token
- 404 Not Found: Show doesn't exist
- 409 Conflict: Seats already locked/booked
- 429 Too Many Requests: Rate limit exceeded
- 500 Internal Server Error: System error
```

**Key Design Decisions:**

1. **Idempotency-Key header**: Prevents duplicate bookings if user clicks "Book" multiple times
2. **409 Conflict**: Specific status for concurrency issues
3. **Returns bookingId immediately**: Creates PENDING booking, easier to track
4. **ExpiryTime in response**: Client can show countdown timer

### **Brief API Definitions**

``` http
# Search & Browse APIs
GET /api/v1/movies?cityId={cityId}&date={date}
  → Returns list of movies playing in a city on given date

GET /api/v1/movies/{movieId}/shows?cityId={cityId}&date={date}
  → Returns theaters and show timings for a movie

# Booking Management APIs
POST /api/v1/bookings/{bookingId}/confirm
  → Processes payment and confirms booking
  → Request: { paymentMethod, paymentDetails }
  → Response: { bookingId, status, transactionId }

GET /api/v1/users/{userId}/bookings?status={status}&page={page}
  → Returns user's booking history with pagination

DELETE /api/v1/bookings/{bookingId}/cancel
  → Cancels a booking (if within cancellation window)

# Admin APIs
POST /api/v1/admin/shows
  → Creates a new show
  → Request: { movieId, screenId, showTime, pricing }
  → Response: { showId, totalSeats }

PUT /api/v1/admin/shows/{showId}
  → Updates show details (time, status)
```


### **Interviewer**:
"I notice your lock API returns a `bookingId` immediately. Why create a booking in PENDING state rather than just locking seats?"

### **Candidate**:
"Great question! There are two design choices:

**Option 1: Lock seats only (no booking record)**
- Just update `show_seats` with `locked_by_user_id`
- Create booking only on payment confirmation

**Option 2: Create PENDING booking immediately** (my choice)

I chose Option 2 because:
1. **Tracking & Analytics**: We can track abandoned bookings ("60% of users abandon at payment step")
2. **User Experience**: User can navigate away and return to their pending booking
3. **Idempotency**: If app crashes, user can retrieve bookingId and continue
4. **Audit Trail**: Complete record of all booking attempts
5. **Clearer State Machine**: PENDING → CONFIRMED/EXPIRED vs just seat locks

**Trade-off**: Slightly more DB writes, but benefits outweigh cost."

### **Interviewer**:
"Fair reasoning. How do you handle idempotency if a user clicks 'Book' multiple times due to network lag?"

### **Candidate**:
"I use an **idempotency key** in the request header:

**How it works:**
1. Client generates UUID on button click: `X-Idempotency-Key: uuid-1234`
2. Server checks: "Have I seen this key before?"
3. If yes: Return cached response (don't create duplicate booking)
4. If no: Process request, cache response with key for 24 hours

**Storage:**
```sql
idempotency_keys (
    idempotency_key VARCHAR(100) PRIMARY KEY,
    request_hash VARCHAR(64),
    response_body TEXT,
    status_code INT,
    created_at TIMESTAMP,
    INDEX idx_created_at (created_at) -- for cleanup job
)
````

**Cleanup**: Background job deletes keys older than 24 hours."

### **Interviewer**:

"Perfect. That's production-grade thinking. Let's talk about concurrency."

---

> [!note] **📚 Educational Note: REST API Design**
> 
> **HTTP Method Semantics:**
> 
> - GET: Read data (idempotent, cacheable)
> - POST: Create new resource (not idempotent by default)
> - PUT: Update entire resource (idempotent)
> - PATCH: Update partial resource
> - DELETE: Remove resource (idempotent)
> 
> **Status Code Selection:**
> 
> - 2xx: Success (200 OK, 201 Created, 204 No Content)
> - 4xx: Client errors (400 Bad Request, 401 Unauthorized, 404 Not Found, 409 Conflict)
> - 5xx: Server errors (500 Internal Server Error, 503 Service Unavailable)
> - Use **409 Conflict** specifically for race conditions and concurrency issues
> 
> **Idempotency:**
> 
> - Critical for POST/PUT/DELETE to handle retries safely
> - Client generates unique key per operation
> - Server deduplicates based on key
> - TTL-based cleanup prevents unbounded growth
> 
> **Pagination:**
> 
> - Never return unbounded lists
> - Use `page` + `limit` or cursor-based pagination
> - Include metadata: `totalPages`, `totalRecords`, `hasNext`

---

## Phase 6: Concurrency Deep Dive (45-60 mins)

### **Interviewer**:

"Alright, this is critical. Here's the scenario:

**Coldplay concert tickets go on sale at 12:00 PM. There are 100 seats. 10,000 users hit your system simultaneously at 12:00:00. Many are trying to book the same premium seats.**

What's the core problem and how do you solve it?"

### **Candidate**:

"This is the classic **race condition in booking systems**. Let me break it down.

### **The Core Problem: Non-Atomic Check-and-Set**

**Race Condition Scenario:**

```
Time    User A                          User B
----    ------                          ------
T1      GET seat availability           
        → Sees seat A5 AVAILABLE        
                                        GET seat availability
                                        → Sees seat A5 AVAILABLE
T2      POST lock seats [A5]            
        → Checks: A5 is AVAILABLE ✓      
        → Updates: A5 = LOCKED (User A)          
                                        POST lock seats [A5]
                                        → Checks: A5 is AVAILABLE ✓ (stale!)
                                        → Updates: A5 = LOCKED (User B)
T3      Both users think they locked A5! ❌
        System shows A5 locked to both!
        Payment will fail for one user (bad UX)
```

**Root Cause**: The operations "check if available" and "set to locked" are **not atomic**. Between check and set, another user can modify the seat state.

Now let me present multiple solutions, with trade-offs for each."

### **Solution 1: Pessimistic Locking (Database Row Locks)**

### **Candidate**:

"**Concept**: Lock the database rows during the transaction so no other transaction can read or modify them. This makes check-and-set atomic at the database level.

**How It Works:**

1. Transaction starts
2. `SELECT ... FOR UPDATE` acquires **exclusive row locks** on specified seats
3. While locks are held, no other transaction can read these rows (with FOR UPDATE)
4. Check seat availability within the same transaction
5. Update seats if available
6. Commit transaction → releases all locks

**Why It Prevents Double-Booking:**

- User A locks seat A5 rows in DB
- User B's query waits (blocked) until User A's transaction completes
- When User B's transaction finally runs, it sees A5 as LOCKED
- User B gets 409 Conflict error

**Pseudocode:**

```java
@Transactional(isolation = Isolation.SERIALIZABLE)
public BookingResponse lockSeats(Long showId, List<Long> seatIds, Long userId) {
    // Step 1: Acquire locks
    String sql = "SELECT * FROM show_seats " +
                 "WHERE show_seat_id IN (:seatIds) AND show_id = :showId " +
                 "FOR UPDATE";  // ← This acquires exclusive locks
    
    List<ShowSeat> seats = executeQuery(sql);
    
    // Step 2: Check availability (still holding locks)
    for (ShowSeat seat : seats) {
        if (seat.getStatus() != AVAILABLE) {
            rollback();
            throw new SeatUnavailableException();
        }
    }
    
    // Step 3: Update seats (still holding locks)
    for (ShowSeat seat : seats) {
        seat.setStatus(LOCKED);
        seat.setLockedByUserId(userId);
        seat.setLockedAt(now());
    }
    save(seats);
    
    // Step 4: Create booking
    Booking booking = createBooking(userId, showId, seats);
    save(booking);
    
    // Step 5: Commit → releases locks
    commit();
    return new BookingResponse(booking);
}
```

**Trade-offs:**

✅ **Pros:**

- Guarantees consistency - impossible to double-book
- Simple to implement
- No retry logic needed
- Database handles locking automatically

❌ **Cons:**

- **Throughput bottleneck**: Users wait in queue for locks
- Long transaction time = long lock hold time
- Risk of **deadlocks** if lock acquisition order differs across transactions
- Doesn't scale well to 10,000 concurrent requests (massive queuing)

**When to Use:** Moderate concurrency (100-500 concurrent users), strong consistency required."

### **Interviewer**:

"Good analysis. But you mentioned deadlocks. Can you explain when that happens?"

### **Candidate**:

"Absolutely. **Deadlock scenario:**

```
User A's Transaction              User B's Transaction
--------------------              --------------------
Lock seat A5 (acquired)           
                                  Lock seat B3 (acquired)
Now try to lock B3 (waiting...)   
                                  Now try to lock A5 (waiting...)
→ Deadlock! Both waiting forever
```

**Prevention:**

- Always acquire locks in **consistent order** (e.g., ascending seat_id)
- Use database deadlock detection (MySQL rolls back one transaction)
- Set lock timeout (fail fast rather than wait forever)

**Example with ordered locking:**

````java
// Always sort seat IDs before locking
List<Long> sortedSeatIds = seatIds.stream()
    .sorted()
    .collect(Collectors.toList());

String sql = "SELECT * FROM show_seats " +
             "WHERE show_seat_id IN (:sortedSeatIds) " +
             "ORDER BY show_seat_id " + // ← Ensures consistent lock order
             "FOR UPDATE";
```"

### **Interviewer**:
"Good. But with 10,000 users, pessimistic locking will cause massive queuing. What's an alternative?"

### **Solution 2: Optimistic Locking (Version-Based Concurrency Control)**

### **Candidate**:
"**Concept**: Don't lock rows. Instead, use a **version number**. If the version changed between read and write, someone else modified the row - abort and retry.

**How It Works:**
1. Read seat data with current version number
2. Check availability (no locks held)
3. Try to update with version check in WHERE clause
4. If 0 rows updated → version changed → someone else updated → retry
5. If 1 row updated → success!

**Schema Change:**
```sql
ALTER TABLE show_seats ADD COLUMN version INT DEFAULT 0;
````

**Pseudocode:**

```java
public BookingResponse lockSeatsOptimistic(Long showId, List<Long> seatIds, Long userId) {
    int maxRetries = 3;
    int attempt = 0;
    
    while (attempt < maxRetries) {
        try {
            // Step 1: Read seats with current version (no locks)
            List<ShowSeat> seats = findByIds(seatIds);
            
            // Step 2: Check availability
            for (ShowSeat seat : seats) {
                if (seat.getStatus() != AVAILABLE) {
                    throw new SeatUnavailableException();
                }
            }
            
            // Step 3: Try to update with version check
            for (ShowSeat seat : seats) {
                int oldVersion = seat.getVersion();
                
                int rowsUpdated = executeUpdate(
                    "UPDATE show_seats " +
                    "SET status = 'LOCKED', locked_by_user_id = ?, " +
                    "    locked_at = ?, version = version + 1 " +
                    "WHERE show_seat_id = ? " +
                    "  AND version = ? " +           // ← Version check!
                    "  AND status = 'AVAILABLE'",    // ← Double-check status
                    userId, now(), seat.getId(), oldVersion
                );
                
                if (rowsUpdated == 0) {
                    // Version mismatch! Someone else updated this seat.
                    throw new OptimisticLockException();
                }
            }
            
            // Step 4: Create booking
            Booking booking = createBooking(userId, showId, seats);
            return new BookingResponse(booking);
            
        } catch (OptimisticLockException e) {
            attempt++;
            if (attempt >= maxRetries) {
                throw new ConcurrencyException(
                    "Seats unavailable due to high demand. Please try again."
                );
            }
            // Exponential backoff
            sleep(Math.pow(2, attempt) * 100); // 200ms, 400ms, 800ms
        }
    }
}
```

**Why It Prevents Double-Booking:**

- User A reads seat A5 with version=5
- User B reads seat A5 with version=5
- User A updates: `WHERE version=5` → succeeds, version becomes 6
- User B updates: `WHERE version=5` → fails (version is now 6), 0 rows updated
- User B retries, sees A5 is LOCKED, gets error

**Trade-offs:**

✅ **Pros:**

- **No locks** → higher throughput, no waiting
- Works well for low-to-moderate contention
- No deadlock risk
- Multiple users can read simultaneously

❌ **Cons:**

- **Retry loop complexity** → code more complex
- Under high contention, many retries = wasted work
- Some users get "try again" errors (degraded UX)
- Doesn't guarantee fairness (first user might fail, last user might succeed)

**When to Use:** Read-heavy workloads, low contention, acceptable to show "try again" errors."

---

> [!note] **📚 STUDY: Transaction Isolation Levels**
> 
> **Isolation Levels** (from weakest to strongest):
> 
> - **READ UNCOMMITTED**: Can see uncommitted changes from other transactions (dirty reads)
> - **READ COMMITTED**: Can only see committed changes, but data can change between reads (non-repeatable reads)
> - **REPEATABLE READ**: Same data returned in multiple reads within a transaction, but new rows can appear (phantom reads)
> - **SERIALIZABLE**: Strongest isolation, as if transactions ran serially
> 
> **For Booking Systems**: Use **SERIALIZABLE** with pessimistic locking to prevent all concurrency anomalies.
> 
> **SELECT ... FOR UPDATE:**
> 
> - Acquires exclusive (write) locks on selected rows
> - Other `SELECT ... FOR UPDATE` queries wait
> - Normal SELECT queries may still read (depends on isolation level)
> - Locks released when transaction commits or rolls back
> - Use `SKIP LOCKED` to skip locked rows (useful for job queues)
> 
> **Optimistic Locking:**
> 
> - Based on assumption: Conflicts are rare
> - Version can be timestamp or counter
> - Application handles retry logic
> - No database-level waiting

---

### **Solution 3: Distributed Locking with Redis**

### **Candidate**:

"**When Needed**: If we're running multiple application instances or using a distributed database with replicas, database-level locks aren't sufficient.

**Concept**: Use a centralized lock service (Redis) to coordinate across multiple app servers. Only one app server can acquire the lock for a set of seats at a time.

**Architecture:**

```
User A → App Server 1 ──┐
                         ├──→ Redis (Lock Manager) → MySQL
User B → App Server 2 ──┘
```

**How Distributed Lock Works (Redlock Algorithm):**

1. Generate unique lock key for seat combination
2. Try to set key in Redis with `SET key value NX PX milliseconds`
    - `NX`: Set only if key doesn't exist (acquire lock)
    - `PX`: Auto-expire after timeout (prevents deadlock if server crashes)
3. If successful, lock acquired → proceed with booking
4. After booking, delete the key (release lock)

**Pseudocode:**

```java
public BookingResponse lockSeatsDistributed(Long showId, List<Long> seatIds, Long userId) {
    // Step 1: Generate lock key (sorted seat IDs to ensure same key for same seats)
    String lockKey = "show:" + showId + ":seats:" + sortedSeatIds(seatIds);
    String lockValue = UUID.randomUUID().toString(); // To verify ownership later
    long lockTimeout = 5000; // 5 seconds
    
    try {
        // Step 2: Try to acquire distributed lock
        boolean acquired = redis.setIfAbsent(lockKey, lockValue, lockTimeout, MILLISECONDS);
        
        if (!acquired) {
            throw new ConcurrencyException("Another user is booking these seats");
        }
        
        // Step 3: Lock acquired - now safe to check and update DB
        List<ShowSeat> seats = findByIds(seatIds);
        
        for (ShowSeat seat : seats) {
            if (seat.getStatus() != AVAILABLE) {
                throw new SeatUnavailableException();
            }
        }
        
        // Step 4: Update seats
        for (ShowSeat seat : seats) {
            seat.setStatus(LOCKED);
            seat.setLockedByUserId(userId);
            seat.setLockedAt(now());
        }
        save(seats);
        
        // Step 5: Create booking
        Booking booking = createBooking(userId, showId, seats);
        return new BookingResponse(booking);
        
    } finally {
        // Step 6: Release lock (only if we own it)
        String currentValue = redis.get(lockKey);
        if (lockValue.equals(currentValue)) {
            redis.delete(lockKey);
        }
    }
}
```

**Why It Prevents Double-Booking:**

- User A acquires lock on `show:1001:seats:A5,A6`
- User B tries to acquire same lock → fails (key already exists)
- User B either waits and retries, or gets immediate error
- Lock auto-expires after 5 seconds (prevents deadlock if App Server 1 crashes)

**Trade-offs:**

✅ **Pros:**

- Works across **distributed systems** (multiple app servers, DB replicas)
- Auto-expiry prevents deadlocks from crashed servers
- Explicit timeout control
- Can use Redlock algorithm for high availability (locks across multiple Redis nodes)

❌ **Cons:**

- **Dependency on Redis** (single point of failure without Redis Cluster)
- Network latency to Redis
- Lock timeout too short → lose lock mid-transaction
- Lock timeout too long → users wait unnecessarily
- Added infrastructure complexity

**When to Use:** Multi-instance application, distributed database, need global coordination."

---

> [!note] **📚 STUDY: Redis Distributed Locks (Redlock Algorithm)**
> 
> **Why Redis for Locking?**
> 
> - In-memory → very fast (sub-millisecond)
> - Atomic operations (`SET NX PX`)
> - TTL (time-to-live) for auto-expiry
> - Single-threaded → no race conditions within Redis
> 
> **Redlock Algorithm (High Availability):**
> 
> - Use multiple Redis instances (e.g., 5 nodes)
> - Try to acquire lock from majority (3 out of 5)
> - If majority acquired → lock successful
> - If minority acquired → release all and fail
> - Protects against single Redis node failure
> 
> **Lock Ownership:**
> 
> - Store unique value (UUID) with lock
> - When releasing, check if value matches (prevent releasing someone else's lock)
> 
> **TTL Selection:**
> 
> - Too short: Might lose lock mid-operation
> - Too long: Others wait unnecessarily if holder crashes
> - Typical: 5-30 seconds for booking operations
> 
> **Lua Script for Atomic Release:**
> 
> ```lua
> if redis.call("GET", KEYS[1]) == ARGV[1] then
>     return redis.call("DEL", KEYS[1])
> else
>     return 0
> end
> ```
> 
> Ensures check-and-delete is atomic

---

### **Solution 4: Queue-Based Approach (Async Processing)**

### **Candidate**:

"**When Needed**: For **extreme concurrency** (Coldplay concert scenario - 1M users), where even distributed locks cause contention.

**Concept**: Don't process bookings synchronously. Queue all booking requests and process them serially or in controlled batches. This **eliminates concurrency** entirely by design.

**Architecture:**

```
Users (1M) → API Gateway → Kafka Queue (booking-requests topic)
                                ↓
                          Consumer Workers (controlled parallelism)
                                ↓
                            MySQL (no contention!)
```

**How It Works:**

1. User clicks "Book Now" → API immediately returns "Processing..."
2. Request placed in Kafka queue with timestamp (FIFO ordering)
3. Consumer workers process requests one-by-one (or in batches per show)
4. No two workers process same show simultaneously → zero contention
5. User notified via WebSocket/SSE when booking succeeds or fails

**Conceptual Flow:**

```java
// Producer (API Service)
public BookingResponse queueBookingRequest(Long showId, List<Long> seatIds, Long userId) {
    String requestId = UUID.randomUUID().toString();
    
    // Create booking request event
    BookingRequest request = new BookingRequest(requestId, userId, showId, seatIds, timestamp());
    
    // Publish to Kafka
    kafka.send("booking-requests", request);
    
    // Return immediately with request ID
    return new BookingResponse(requestId, "PROCESSING", 
        "Your booking is being processed. You'll be notified shortly.");
}

// Consumer (Worker Service)
@KafkaListener(topics = "booking-requests")
public void processBooking(BookingRequest request) {
    // Process serially - no concurrency issues!
    List<ShowSeat> seats = findByIds(request.getSeatIds());
    
    // Check availability
    for (ShowSeat seat : seats) {
        if (seat.getStatus() != AVAILABLE) {
            notifyUser(request.getUserId(), "FAILED", "Seats no longer available");
            return;
        }
    }
    
    // Update seats
    for (ShowSeat seat : seats) {
        seat.setStatus(LOCKED);
        seat.setLockedByUserId(request.getUserId());
        seat.setLockedAt(now());
    }
    save(seats);
    
    // Create booking
    Booking booking = createBooking(request);
    notifyUser(request.getUserId(), "SUCCESS", booking);
}
```

**Configuration for Fairness:**

- **1 partition per show** in Kafka (all requests for Show X go to same partition)
- **1 consumer per partition** (ensures serial processing per show)
- **Multiple partitions** for different shows (parallel processing across shows)

**Trade-offs:**

✅ **Pros:**

- **Zero contention** - requests processed serially
- System remains responsive under extreme load
- Can prioritize requests (VIP users first)
- Easy to scale workers independently
- Natural backpressure mechanism

❌ **Cons:**

- **No immediate confirmation** - async UX
- More complex architecture (Kafka, workers, notifications)
- Users might book unavailable seats (eventual consistency)
- Need WebSocket/SSE for real-time updates
- Queue delay under high load

**When to Use:** Extreme traffic spikes (millions of users), when eventual consistency is acceptable."

---

> [!note] **📚 STUDY: Message Queue Patterns**
> 
> **Why Kafka for Booking Requests?**
> 
> - **Ordering guarantees**: Within a partition, messages are processed in order
> - **Partitioning**: Route all requests for Show X to same partition → serial processing
> - **Durability**: Messages persisted to disk, not lost on crash
> - **Scalability**: Add more partitions for parallel processing
> 
> **Queue vs Database for Concurrency:**
> 
> - Queue: Serializes requests naturally (single consumer per partition)
> - Database: Requires locks to handle concurrency
> 
> **Kafka Consumer Groups:**
> 
> - Multiple consumers in same group → each gets different partitions
> - For our use case: 1 consumer per partition for Show X
> 
> **Backpressure:**
> 
> - Queue grows → more latency, but system doesn't crash
> - Alternative: Reject requests when queue too long
> 
> **Trade-off: Consistency vs Availability:**
> 
> - Synchronous (locks): Immediate consistency, lower availability under load
> - Asynchronous (queue): High availability, eventual consistency

---

### **Interviewer**:

"Excellent! You've covered multiple approaches. Now, for the BookMyShow scenario with 10,000 concurrent users and 100 seats, which approach would you recommend?"

### **Candidate**:

"I'd use a **hybrid approach**: **Pessimistic Locking + Redis for Hold Management + Rate Limiting + Virtual Waiting Room for spikes**.

### **Recommended Strategy:**

**Phase 1: Normal Load (<1000 concurrent users)**

- **Pessimistic Locking** (SELECT FOR UPDATE) for seat booking
- Even with 1000 users, only 100-200 will hit the lock API simultaneously
- Others are still searching, browsing, deciding

**Phase 2: High Load (1000-5000 users) - Redis Hold Management**

- Use **Redis for 10-minute seat holds** instead of DB timestamps
- Automatic expiry via TTL (no background cleanup job needed at scale)
- Details in HLD section

**Phase 3: Extreme Load (>5000 users) - Virtual Waiting Room**

- **Queue users before they hit the booking system**
- Controlled admission rate (500 users/min)
- Show queue position to users
- Details in HLD section

**Why This Hybrid?**

1. ✅ **Pessimistic locking sufficient** for actual seat locking (only few hundred hit this API)
2. ✅ **Rate limiting** prevents API abuse (max 5 booking attempts per user per minute)
3. ✅ **Caching** reduces DB load (seat availability cached 2 seconds)
4. ✅ **Virtual waiting room** protects system during traffic spikes (Coldplay concert)

**Why NOT other solutions?**

- **Optimistic locking**: Too many retries under extreme contention → degraded UX
- **Distributed locks**: Single MySQL instance, don't need distributed coordination yet
- **Queue-based**: Users expect immediate confirmation for tickets, not "you'll be notified"

**Expected Performance:**

- 95th percentile latency: <500ms for lock API
- Throughput: 500 booking requests/second
- Seat lock success rate: 60-70% during peaks (others get 409 Conflict, which is correct behavior)

**The key insight**: Not everyone will get seats, and that's expected. Our job is to ensure **fairness** and **prevent double-booking**, not to satisfy every user."

### **Interviewer**:

"Very pragmatic. One more question - you mentioned Redis for hold management. How exactly does that work, and how do you handle lock expiry at scale?"

### **Candidate**:

"Great question! I'll cover this in detail in the HLD section where we discuss Redis architecture. But the key idea:

**Redis for Seat Holds (Alternative to DB Timestamps):**

- Store: `show:1001:seat:A5 → {userId: 501, lockTime: timestamp}` with TTL=600 seconds
- Automatic expiry after 10 minutes (Redis deletes key)
- On payment confirmation: Delete key + update DB seat status to BOOKED
- If Redis down: Fallback to DB-based timestamp approach

This is much more scalable than background cleanup jobs for millions of seats. We'll explore this in detail shortly."

---

> [!note] **📚 Educational Note: Choosing Concurrency Strategy**
> 
> **Decision Framework:**
> 
> |Contention Level|Strategy|Example|
> |---|---|---|
> |Low (<100 concurrent)|Optimistic Locking|Small theater, weekday show|
> |Moderate (100-1000)|Pessimistic Locking|Normal operations|
> |High (1000-10000)|Pessimistic + Rate Limiting + Caching|Friday night, popular movie|
> |Extreme (>10000)|Virtual Waiting Room + Queue|Coldplay concert, iPhone launch|
> 
> **Key Principles:**
> 
> - **Start simple**: Pessimistic locking for MVP
> - **Measure first**: Profile actual contention before optimizing
> - **Hybrid is best**: Combine multiple strategies for different load scenarios
> - **Fail gracefully**: 409 Conflict is better than double-booking
> 
> **Java Locks vs SQL Locks:**
> 
> - **Java Locks** (`synchronized`, `ReentrantLock`): Only work within a single JVM instance
> - **SQL Locks** (`SELECT FOR UPDATE`): Work across multiple app instances
> - For booking systems, always use **SQL locks** or **distributed locks** (Redis)

---

## Phase 7: Design Patterns (Integrated Discussion)

### **Interviewer**:

"Good work on concurrency. Now, where would you apply design patterns in this system?"

### **Candidate**:

"I'll highlight key patterns where they solve real problems:

### **1. Strategy Pattern - Payment Processing**

**Problem**: Support multiple payment methods (Credit Card, UPI, Wallet, Net Banking) with different processing logic.

**Solution:**

```java
// Strategy Interface
interface PaymentStrategy {
    PaymentResult processPayment(BigDecimal amount, PaymentDetails details);
}

// Concrete Strategies
class CreditCardStrategy implements PaymentStrategy {
    PaymentResult processPayment(BigDecimal amount, PaymentDetails details) {
        // Credit card flow: validate, 3D secure, charge
    }
}

class UPIStrategy implements PaymentStrategy {
    PaymentResult processPayment(BigDecimal amount, PaymentDetails details) {
        // UPI flow: generate QR, poll status, handle timeout
    }
}

// Context
class PaymentService {
    PaymentResult processPayment(Booking booking, String method, PaymentDetails details) {
        PaymentStrategy strategy = getStrategy(method); // Factory returns strategy
        return strategy.processPayment(booking.getTotalAmount(), details);
    }
}
```

**Benefit**: Easy to add new payment methods (Crypto, Buy Now Pay Later) without modifying existing code.

### **2. Factory Pattern - Notification Creation**

**Problem**: Create different types of notifications (Email, SMS, Push) based on user preferences.

```java
interface NotificationSender {
    void send(User user, Booking booking);
}

class NotificationFactory {
    static NotificationSender create(NotificationType type) {
        return switch (type) {
            case EMAIL -> new EmailNotificationSender();
            case SMS -> new SMSNotificationSender();
            case PUSH -> new PushNotificationSender();
        };
    }
}
```

### **3. Observer Pattern - Booking Confirmation Events**

**Problem**: When booking confirmed, trigger multiple actions (send email, SMS, update analytics, log).

```java
interface BookingObserver {
    void onBookingConfirmed(Booking booking);
}

class BookingService {
    private List<BookingObserver> observers = List.of(
        new EmailNotificationObserver(),
        new SMSNotificationObserver(),
        new AnalyticsObserver(),
        new AuditLogObserver()
    );
    
    void confirmBooking(Long bookingId) {
        Booking booking = updateBookingStatus(bookingId, CONFIRMED);
        
        // Notify all observers
        observers.forEach(observer -> observer.onBookingConfirmed(booking));
    }
}
```

**Benefit**: Decouples booking logic from side effects. Easy to add new observers.

### **4. Singleton Pattern - Connection Pool**

```java
class DatabaseConnectionPool {
    private static DatabaseConnectionPool instance;
    
    private DatabaseConnectionPool() {
        // Initialize HikariCP with max connections
    }
    
    static synchronized DatabaseConnectionPool getInstance() {
        if (instance == null) instance = new DatabaseConnectionPool();
        return instance;
    }
}
```

**Note**: In production, use dependency injection instead of Singleton for testability."

### **Interviewer**:

"Good. These patterns are applied contextually, not forced. Let's move to high-level design."

---

## Phase 8: Scaling & HLD Considerations (60-70 mins)

### **Interviewer**:

"We've nailed the low-level design. Now let's zoom out. If this system needs to handle **10 million users across India** with **thousands of bookings per second**, how would you scale it?"

### **Candidate**:

"Let me break down the scaling strategy into key areas.

---

## 8.1 Database Strategy [DEEP]

### **Database Choice: MySQL vs Alternatives**

|Database|Pros|Cons|Fit for BookMyShow?|
|---|---|---|---|
|**MySQL**|ACID, complex joins, row-level locks, mature|Vertical scaling limits|✅ **BEST** - Need ACID + joins|
|**PostgreSQL**|Better JSON, advanced features|Similar to MySQL|✅ Also good|
|**MongoDB**|Flexible schema, horizontal scaling|No ACID across documents, poor joins|❌ Need strong consistency|
|**Cassandra**|Massive write throughput, AP system|Eventual consistency, no joins|❌ Need strong consistency|
|**DynamoDB**|Managed, auto-scaling|Expensive, limited queries|⚠️ Possible but complex|

**Our Choice: MySQL**

- **Reason 1**: Seat booking requires **ACID transactions** (atomicity critical)
- **Reason 2**: Complex queries with JOINs (theaters + shows + seats + bookings)
- **Reason 3**: `SELECT ... FOR UPDATE` provides row-level locking
- **Reason 4**: Mature ecosystem, battle-tested for booking systems (airlines use it)

### **Scaling MySQL: Sharding + Read Replicas**

**Strategy 1: Read Replicas (Read-Write Split)**

```
Master DB (Write Operations)
   ├─→ Replica 1 (Read) - Seat availability queries
   ├─→ Replica 2 (Read) - Movie listings, theater info
   └─→ Replica 3 (Read) - User bookings, search
```

**Read Operations** (90% of traffic):

- Search movies: Go to replicas
- Get seat availability: Go to replicas (acceptable 1-2 sec replication lag)
- View booking history: Go to replicas

**Write Operations** (10% of traffic):

- Seat locking: Go to master
- Booking creation: Go to master
- Payment confirmation: Go to master

**Replication Lag Handling:**

- Lag typically 1-2 seconds
- For critical reads (after write), use master: `SELECT ... FROM show_seats USE MASTER`
- For non-critical reads, tolerate stale data

**Strategy 2: Horizontal Partitioning (Sharding by City)**

**Why Shard by City?**

- Users book tickets **in their city** (no cross-city queries)
- Reduces DB size per shard
- Geographic distribution → lower latency

**Sharding Scheme:**

```
Shard 1: Mumbai, Pune, Nashik        (West India DB)
Shard 2: Delhi, Noida, Gurgaon       (North India DB)
Shard 3: Bangalore, Hyderabad, Chennai (South India DB)
Shard 4: Kolkata, Bhubaneswar        (East India DB)
```

**Shard Routing Logic:**

```java
class ShardResolver {
    DataSource getDataSource(Long cityId) {
        // Hash cityId to shard
        int shardId = cityId % TOTAL_SHARDS;
        return shardRegistry.get(shardId);
    }
}

// Usage
DataSource ds = shardResolver.getDataSource(user.getCityId());
BookingRepository repo = new BookingRepository(ds);
repo.createBooking(booking);
```

**Challenge: Cross-Shard Queries**

- Example: "Show me all bookings for User X across all cities"
- Solution: **Scatter-Gather** pattern:
    1. Query all shards in parallel
    2. Merge results at application layer
    3. Cache aggregated results

**Global Tables (Not Sharded):**

- `users` table: Replicate to all shards (or use separate user DB)
- `movies` table: Replicate to all shards (movies are global)

### **Interviewer**:

"What if a user books tickets in Mumbai today and Delhi tomorrow? Do you need to maintain user session across shards?"

### **Candidate**:

"Great question! The user's **session/authentication** is separate from **booking data**.

**Approach:**

1. **User authentication**: Centralized (single user service, JWT tokens)
2. **Booking data**: Sharded by city (stored in city-specific shard)
3. **User profile**: Replicated to all shards OR separate user DB

**Flow:**

- User logs in → JWT token issued (contains userId)
- User selects Mumbai → routes to Mumbai shard
- User books in Delhi tomorrow → routes to Delhi shard
- View all bookings → scatter-gather across shards, merge results

**Alternative:** Use a **routing table** (maps userId → list of shards where user has bookings) to optimize scatter-gather."

---

## 8.2 Caching Strategy [DEEP]

### **Multi-Layer Caching Architecture**

```
Request Flow:
User → CDN → API Gateway Cache → Application Cache (Redis) → Database
```

**Layer 1: CDN (Cloudflare / AWS CloudFront)**

- **What to cache**: Static assets (images, CSS, JS), movie posters, theater images
- **TTL**: 24 hours (assets rarely change)
- **Benefit**: 90% reduction in origin requests, low latency globally

**Layer 2: API Gateway Cache (Kong / AWS API Gateway)**

```http
GET /api/v1/movies?cityId=1&date=2024-07-15
Cache-Control: public, max-age=3600  # Cache for 1 hour
```

- **What to cache**: Movie listings, theater info (changes infrequently)
- **TTL**: 1 hour
- **Benefit**: Reduces backend load for frequently accessed endpoints

**Layer 3: Application Cache (Redis)**

```java
// Cache seat availability with SHORT TTL
public SeatAvailability getSeats(Long showId) {
    String cacheKey = "show:" + showId + ":seats";
    
    // Try cache first
    String cached = redis.get(cacheKey);
    if (cached != null) {
        return deserialize(cached);
    }
    
    // Cache miss - fetch from DB
    SeatAvailability data = fetchFromDB(showId);
    
    // Cache for 2 seconds (balance freshness vs load)
    redis.setex(cacheKey, 2, serialize(data));
    
    return data;
}
```

**What to Cache:**

- ✅ Seat availability (2-second TTL) - changes frequently but tolerable staleness
- ✅ Movie listings (1-hour TTL)
- ✅ Theater info (24-hour TTL)
- ❌ Seat lock status (must be real-time)
- ❌ Payment status (must be consistent)

### **Cache Patterns**

**1. Cache-Aside (Lazy Loading)** - Our choice for seat availability

```
Read: Check cache → Miss → Load from DB → Store in cache
Write: Update DB → Invalidate cache
```

**2. Write-Through** - For theater/movie data

```
Write: Update cache → Update DB (synchronously)
Read: Always from cache
```

**3. Write-Behind (Write-Back)** - For analytics data

```
Write: Update cache → Async write to DB later
Read: From cache
```

**Our Choice**: **Cache-Aside** for most data, **Write-Through** for critical metadata.

### **Cache Invalidation Strategy**

**Problem**: How to keep cache and DB in sync?

**Solution 1: Time-Based (TTL)**

- Set expiry time on cache keys
- Trade-off: Simple, but may serve stale data until expiry
- Good for: Movie listings, theater info

**Solution 2: Event-Driven Invalidation**

```java
@EventListener
void onBookingConfirmed(BookingConfirmedEvent event) {
    // Invalidate seat availability cache for this show
    redis.del("show:" + event.getShowId() + ":seats");
}
```

- Trade-off: More complex, but ensures freshness
- Good for: Seat availability

**Solution 3: Versioned Keys**

```java
String cacheKey = "show:" + showId + ":seats:v" + version;
```

- On update, increment version
- Old version auto-expires, new version populated
- Avoids race conditions during invalidation

### **Cache Stampede Problem**

**Problem**: Cache expires → 10,000 concurrent requests → all hit DB simultaneously → DB overload

**Solution: Probabilistic Early Expiration**

```java
public Data getWithProbabilisticExpiry(String key, int ttl) {
    CacheEntry entry = redis.get(key);
    
    if (entry == null) {
        return loadFromDBAndCache(key, ttl);
    }
    
    // Refresh cache probabilistically before expiry
    double timeSinceCreation = now() - entry.timestamp;
    double probability = timeSinceCreation / ttl;
    
    if (Math.random() < probability) {
        // Refresh cache in background
        asyncRefreshCache(key, ttl);
    }
    
    return entry.data;
}
```

**Alternative: Mutex/Lock on Cache Miss**

```java
if (!redis.exists(key)) {
    if (redis.setNX("lock:" + key, "locked", 5)) { // Only one thread gets lock
        data = loadFromDB(key);
        redis.set(key, data, ttl);
        redis.del("lock:" + key);
    } else {
        Thread.sleep(100); // Wait for other thread to populate cache
        return redis.get(key);
    }
}
```

### **Eviction Policies**

When Redis memory is full:

- **LRU (Least Recently Used)**: Evict least recently accessed keys - **Our choice**
- **LFU (Least Frequently Used)**: Evict least frequently accessed keys
- **TTL-based**: Evict keys closest to expiry
- **Allkeys-random**: Evict random keys (not recommended)

---

> [!note] **📚 STUDY: Caching Patterns & Cache Stampede**
> 
> **Cache-Aside vs Write-Through:**
> 
> - **Cache-Aside**: Application manages cache explicitly. Cache miss → load from DB
> - **Write-Through**: Cache acts as proxy. Write goes through cache to DB
> 
> **Cache Stampede (Thundering Herd):**
> 
> - Many requests hit DB simultaneously when cache expires
> - Solutions: Early expiration, mutex on cache miss, background refresh
> 
> **Eviction Policies:**
> 
> - LRU: Good for general-purpose caching
> - LFU: Good when some keys are accessed much more than others
> - Volatile-LRU: Only evict keys with TTL set
> 
> **Redis vs Memcached:**
> 
> - Redis: Persistent, complex data structures (sorted sets, lists), pub-sub
> - Memcached: Pure in-memory, simpler, slightly faster for get/set
> - BookMyShow: Choose **Redis** for TTL and data structure support

---

## 8.3 Rate Limiting [BRIEF]

**Why Needed**: Prevent API abuse, DDoS attacks, ensure fair usage

**Algorithm Choice: Token Bucket**

**How Token Bucket Works:**

1. Bucket has capacity (e.g., 100 tokens)
2. Tokens refill at constant rate (e.g., 10 tokens/second)
3. Each request consumes 1 token
4. If no tokens available → reject request (429 Too Many Requests)

**Why Token Bucket?**

- ✅ Handles burst traffic (100 requests instantly if bucket full)
- ✅ Smooth sustained rate (10 req/s)
- ✅ Simple to implement

**Alternative: Sliding Window**

- Track request count in rolling time window
- More memory-intensive but more accurate

**Where to Implement**: API Gateway (Kong, AWS API Gateway)

**Rate Limits:**

```yaml
rules:
  - endpoint: /api/v1/shows/*/seats/lock
    limit: 5 requests per minute per user
  - endpoint: /api/v1/movies
    limit: 100 requests per minute per user
  - endpoint: /api/v1/bookings
    limit: 10 requests per minute per user
```

---

## 8.4 Load Balancing [BRIEF]

**Layer 4 vs Layer 7 Load Balancer**

|Feature|Layer 4 (Transport)|Layer 7 (Application)|
|---|---|---|
|**Operates on**|IP + Port (TCP/UDP)|HTTP headers, URL, cookies|
|**Speed**|Faster (less processing)|Slower (inspects payload)|
|**Routing**|Based on IP/port only|Based on URL path, headers|
|**Use Case**|General load balancing|API routing, canary deployments|
|**Example**|AWS NLB, HAProxy (L4)|AWS ALB, NGINX (L7)|

**Our Choice: Layer 7 (AWS ALB / NGINX)**

**Why?**

- Need to route based on URL path (`/api/v1/bookings` → booking service)
- Can add custom headers (X-User-ID) for routing
- SSL termination at load balancer
- Health checks based on HTTP response

**Load Balancer Placement:**

```
User → L7 Load Balancer (ALB)
         ├→ Booking Service (Instances 1-10)
         ├→ Search Service (Instances 1-5)
         └→ Payment Service (Instances 1-3)
```

**Algorithm**: Round-robin with health checks (remove unhealthy instances)

---

## 8.5 Monitoring & Security [BRIEF]

**Key Metrics to Monitor:**

- Request rate (per endpoint)
- Error rate (4xx, 5xx)
- Latency (p50, p95, p99)
- Database connection pool utilization
- Cache hit rate
- Queue depth (if using Kafka)

**Tools**: Prometheus + Grafana, Datadog, New Relic

**Security:**

- HTTPS (TLS 1.3) for all traffic
- JWT for authentication, RBAC for authorization
- SQL injection prevention (parameterized queries, ORM)
- Rate limiting per user and per IP
- PCI DSS compliance for payment handling

---

## 8.6 Problem-Specific Architectural Components [DEEP]

### **Component 1: Redis for Seat Hold Management**

### **Interviewer**:

"You mentioned 10-minute seat holds. For a Coldplay concert with millions of requests, how do you track hold expiry efficiently? Background cleanup jobs won't scale."

### **Candidate**:

"Excellent question! At scale, **DB-based timestamp checks are inefficient**. We need **Redis with TTL-based auto-expiry**.

**Problem with DB Approach:**

- Background job runs every 1 minute: `UPDATE show_seats SET status=AVAILABLE WHERE locked_at < NOW() - 10 MINUTES`
- With 1M concurrent locks, this scans millions of rows
- High CPU usage, locks entire table

**Solution: Redis for Hold Management**

**Architecture:**

```
User → App Server → Redis (Hold Management) → MySQL (Persistent State)
```

**Redis Data Structure:**

```redis
# Hold a seat (10-minute TTL)
SET show:1001:seat:A5 '{"userId":501,"lockTime":"2024-07-15T14:25:00"}' EX 600

# Check if seat is held
GET show:1001:seat:A5  # Returns value if held, NULL if available

# Release hold (on payment confirmation)
DEL show:1001:seat:A5
```

**How It Works:**

1. **Lock seats**: Store in Redis with 600-second TTL
2. **Redis auto-expires**: After 10 minutes, key deleted automatically (no background job!)
3. **Check availability**: If key doesn't exist in Redis → seat available
4. **Confirm booking**: Delete Redis key + update MySQL status to BOOKED

**Consistency Strategy: Redis + MySQL**

- **Redis**: Source of truth for "who has lock right now"
- **MySQL**: Source of truth for "confirmed bookings"
- On payment confirmation: Atomic delete from Redis + update MySQL

**Fallback: Redis Down**

```java
public boolean isSeatAvailable(Long showId, Long seatId) {
    try {
        // Primary: Check Redis
        String hold = redis.get("show:" + showId + ":seat:" + seatId);
        return hold == null;
    } catch (RedisException e) {
        // Fallback: Check MySQL
        ShowSeat seat = db.findById(seatId);
        return seat.getStatus() == AVAILABLE;
    }
}
```

**Trade-offs:**

✅ **Pros:**

- Automatic expiry (no background job)
- Sub-millisecond reads (Redis in-memory)
- Scales to millions of holds
- Natural TTL mechanism

❌ **Cons:**

- Redis is now critical dependency
- Need Redis persistence (AOF/RDB) to prevent data loss
- Consistency challenge if Redis and MySQL diverge

**Redis High Availability:**

- Use **Redis Sentinel** (automatic failover) or **Redis Cluster** (sharding)
- Replicate to 2-3 nodes

**Why This Scales:**

- No table scans
- No background jobs
- Redis handles millions of keys with TTL efficiently"

### **Interviewer**:

"Good! What if payment takes 3 minutes and user's lock expires during payment?"

### **Candidate**:

"Excellent edge case!

**Problem**: User locked seats at T0, started payment at T9:30, lock expires at T10, payment completes at T12 → lock already released!

**Solution 1: Extend Lock on Payment Initiation**

```java
public void initiatePayment(Long bookingId) {
    Booking booking = findById(bookingId);
    
    // Extend Redis TTL to +5 minutes
    for (ShowSeat seat : booking.getSeats()) {
        redis.expire("show:" + seat.getShowId() + ":seat:" + seat.getSeatId(), 900); // 15 min total
    }
    
    // Proceed with payment
    paymentGateway.charge(booking);
}
```

**Solution 2: Grace Period Check**

```java
public void confirmBooking(Long bookingId) {
    Booking booking = findById(bookingId);
    
    // Check if booking expired within last 2 minutes (grace period)
    if (booking.getExpiryTime().isAfter(now().minus(2, MINUTES))) {
        // Allow confirmation even if lock expired recently
        confirmPayment(booking);
    } else {
        throw new BookingExpiredException();
    }
}
```

**Solution 3: DB Lock Status as Final Authority**

- Redis TTL is for user convenience (release quickly)
- MySQL booking status is final authority
- If payment completes, check MySQL booking status, ignore Redis"

---

### **Component 2: Virtual Waiting Room / Queue System**

### **Interviewer**:

"Coldplay concert tickets go on sale. 1 million users hit your site at 12:00:00 sharp. Your servers will crash. How do you handle this?"

### **Candidate**:

"This is the **traffic spike protection** problem. We need a **Virtual Waiting Room** to queue users before they enter the booking system.

**Concept: Admission Control**

- Users don't directly hit booking service
- They join a virtual queue
- System admits users at controlled rate (e.g., 500 users/min)
- Prevents system overload

**Architecture:**

```
User → Virtual Waiting Room (Queue) → Admission Control → Booking System
```

**Implementation Options:**

**Option 1: Cloudflare Waiting Room (Managed Service)**

- Cloudflare provides this as a service
- Automatically queues users when traffic exceeds threshold
- Shows queue position and estimated wait time
- No code changes needed

**Option 2: Custom Queue (Redis-Based)**

**Data Structure:**

```redis
# Sorted set: timestamp as score
ZADD waiting-room:show:1001 1689424800.123 "user:501"
ZADD waiting-room:show:1001 1689424800.456 "user:502"

# Get queue position
ZRANK waiting-room:show:1001 "user:501"  # Returns position (0-indexed)

# Admit next 100 users
ZPOPMIN waiting-room:show:1001 100
```

**Flow:**

1. User arrives → check if system under load
2. If under load → add to Redis sorted set (score = timestamp)
3. Show user their queue position: "You are #12,451 in line. Estimated wait: 15 minutes"
4. Admission worker pops users from queue at controlled rate (500/min)
5. Issue signed JWT token to admitted users
6. User with valid token can access booking system

**Admission Worker (Background Job):**

```java
@Scheduled(fixedRate = 60000) // Run every minute
public void admitUsersFromQueue() {
    int admissionRate = 500; // 500 users per minute
    
    // Pop 500 users from queue (FIFO)
    List<String> userIds = redis.zPopMin("waiting-room:show:1001", admissionRate);
    
    for (String userId : userIds) {
        // Issue signed token valid for 10 minutes
        String token = jwtService.generateAdmissionToken(userId, 10);
        
        // Notify user (WebSocket / SSE)
        notificationService.notifyUser(userId, "Your turn! Token: " + token);
    }
}
```

**User Experience:**

```
User sees:
┌────────────────────────────────────┐
│ You're in the waiting room         │
│ Position: #12,451                  │
│ Estimated wait: 15 minutes         │
│ (Auto-refresh every 10 seconds)    │
└────────────────────────────────────┘

After admission:
┌────────────────────────────────────┐
│ It's your turn!                    │
│ You have 10 minutes to book        │
│ [Proceed to Booking] →             │
└────────────────────────────────────┘
```

**Token Validation:**

```java
@PreAuthorize("hasAdmissionToken")
public BookingResponse lockSeats(Long showId, List<Long> seatIds) {
    String token = request.getHeader("X-Admission-Token");
    
    if (!jwtService.validateToken(token)) {
        throw new UnauthorizedException("Please rejoin waiting room");
    }
    
    // Proceed with seat locking
}
```

**Queue Position Updates (Real-Time):**

- Use **Server-Sent Events (SSE)** to push position updates to users
- Every 10 seconds, send updated position: "You are #8,234 in line"

**Trade-offs:**

✅ **Pros:**

- Protects system from overload (controlled admission)
- Fair queuing (FIFO)
- Transparent to users (know their position)
- Can prioritize VIP users (separate queue)

❌ **Cons:**

- Poor user experience (waiting)
- Adds complexity (queue management)
- Need real-time communication (SSE/WebSocket)
- Token management overhead

**When to Enable:**

- Traffic threshold (e.g., >5000 concurrent users)
- High-demand shows (Coldplay, IPL final)
- Disable for normal shows

**Hybrid Approach:**

- Normal shows: Direct access
- High-demand shows: Virtual waiting room
- Decision based on real-time traffic monitoring"

### **Interviewer**:

"Smart! What about bots trying to book all tickets?"

### **Candidate**:

"Great catch! We need **bot protection**:

1. **CAPTCHA**: Google reCAPTCHA v3 (invisible, scores bot likelihood)
2. **Rate limiting**: Max 5 booking attempts per IP per minute
3. **Device fingerprinting**: Track browser fingerprint, flag suspicious patterns
4. **Behavioral analysis**: Human users click around, bots are direct
5. **Waiting room**: Slows down bots (they can't bypass queue)

**Combined with waiting room**: Even if bots join queue, they wait like everyone else (no advantage)."

---

### **Component 3: Real-Time Seat Updates (SSE)**

### **Interviewer**:

"When User A books a seat, User B's screen should update immediately without refreshing. How do you implement this?"

### **Candidate**:

"We need **push-based communication** from server to client.

**Options:**

|Technology|Pros|Cons|Fit?|
|---|---|---|---|
|**Server-Sent Events (SSE)**|Simple, HTTP-based, auto-reconnect|One-way (server → client)|✅ Perfect for seat updates|
|**WebSockets**|Bi-directional, low latency|Complex, sticky sessions needed|⚠️ Overkill for read-only updates|
|**Long Polling**|Works everywhere|High latency, inefficient|❌ Too slow|

**Our Choice: Server-Sent Events (SSE)**

**Why SSE?**

- Seat updates are **one-way** (server → client) - no need for bi-directional
- Built on HTTP (works through firewalls, proxies)
- Auto-reconnect on connection drop
- Simpler than WebSocket

**Architecture:**

```
User Browser ←─ SSE Connection ─→ SSE Service (Node.js)
                                      ↑
                                   Redis Pub-Sub
                                      ↑
                              Booking Service (on booking confirm)
```

**Implementation:**

**Backend: Publish Events**

```java
// When booking confirmed
@EventListener
void onBookingConfirmed(BookingConfirmedEvent event) {
    for (ShowSeat seat : event.getSeats()) {
        // Publish to Redis pub-sub
        SeatUpdateEvent update = new SeatUpdateEvent(
            event.getShowId(),
            seat.getSeatNumber(),
            "BOOKED"
        );
        redis.publish("seat-updates:" + event.getShowId(), serialize(update));
    }
}
```

**SSE Service (Node.js): Subscribe and Push**

```javascript
// SSE service subscribes to Redis
redis.subscribe('seat-updates:*');

redis.on('message', (channel, message) => {
    const showId = channel.split(':')[1];
    const update = JSON.parse(message);
    
    // Push to all clients watching this show
    clients.get(showId).forEach(client => {
        client.res.write(`data: ${message}\n\n`);
    });
});

// SSE endpoint
app.get('/sse/shows/:showId/seats', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    // Add client to show's listener list
    clients.get(req.params.showId).push({ res });
    
    // Send heartbeat every 30 seconds
    const heartbeat = setInterval(() => {
        res.write(': heartbeat\n\n');
    }, 30000);
    
    // Cleanup on disconnect
    req.on('close', () => {
        clearInterval(heartbeat);
        removeClient(req.params.showId, res);
    });
});
```

**Frontend: Subscribe to Updates**

```javascript
const eventSource = new EventSource('/sse/shows/1001/seats');

eventSource.onmessage = (event) => {
    const update = JSON.parse(event.data);
    // Update: Seat A5 status changed to BOOKED
    updateSeatUI(update.seatNumber, update.status);
};

eventSource.onerror = () => {
    // Auto-reconnect handled by browser
};
```

**Scaling SSE Connections:**

- Use **Node.js** for SSE (high concurrency, event-driven)
- Use **sticky sessions** at load balancer (user stays on same SSE server)
- Use **Redis Pub-Sub** to broadcast across SSE servers

**Connection Limits:**

- Each SSE server can handle ~10,000 concurrent connections
- For 100,000 users watching same show: 10 SSE servers needed
- Use auto-scaling based on connection count

**Trade-offs:**

✅ **Pros:**

- Real-time updates (sub-second latency)
- Better UX (no manual refresh)
- Simple protocol (HTTP-based)

❌ **Cons:**

- Persistent connections (resource intensive)
- Need dedicated SSE servers
- Sticky sessions at load balancer

**Fallback: Polling**

- If SSE not supported (old browsers): poll every 5 seconds
- `GET /api/v1/shows/1001/seats?lastUpdated=timestamp`"

---

### **Component 4: Payment Gateway Resilience**

### **Interviewer**:

"Payment gateway has 5-second timeout and sometimes fails. How do you handle this without degrading UX?"

### **Candidate**:

"Payment gateways are **external dependencies** - unreliable by nature. We need **resilience patterns**.

**Circuit Breaker Pattern:**

**Concept**: Track payment gateway failures. If too many failures, "open circuit" (fail fast) instead of waiting for timeout.

**States:**

1. **CLOSED**: Normal operation, requests go through
2. **OPEN**: Too many failures, requests fail immediately (no call to gateway)
3. **HALF_OPEN**: After timeout, allow 1 test request. If succeeds → CLOSED, if fails → OPEN

**Implementation (Resilience4j):**

```java
@CircuitBreaker(name = "paymentGateway", fallbackMethod = "paymentFallback")
public PaymentResult processPayment(Booking booking) {
    return paymentGateway.charge(booking.getTotalAmount());
}

// Fallback method
public PaymentResult paymentFallback(Booking booking, Exception e) {
    // Mark payment as PENDING, will retry later
    return new PaymentResult("PENDING", "Payment gateway unavailable. Will retry.");
}
```

**Configuration:**

```yaml
resilience4j.circuitbreaker:
  paymentGateway:
    failureRateThreshold: 50%        # Open circuit if >50% fail
    waitDurationInOpenState: 60s     # Stay open for 60 seconds
    slidingWindowSize: 10            # Track last 10 requests
```

**Retry Strategy:**

```java
@Retry(name = "paymentRetry", fallbackMethod = "paymentFallback")
@CircuitBreaker(name = "paymentGateway")
public PaymentResult processPayment(Booking booking) {
    return paymentGateway.charge(booking.getTotalAmount());
}
```

**Retry Configuration:**

```yaml
resilience4j.retry:
  paymentRetry:
    maxAttempts: 3
    waitDuration: 1s
    retryExceptions:
      - java.net.SocketTimeoutException
      - PaymentGatewayException
```

**Async Payment with Webhooks:**

```java
// Step 1: Initiate payment (non-blocking)
public PaymentResult initiatePayment(Booking booking) {
    String transactionId = paymentGateway.initiatePayment(booking);
    
    // Mark booking as PAYMENT_PENDING
    booking.setStatus(PAYMENT_PENDING);
    booking.setTransactionId(transactionId);
    save(booking);
    
    return new PaymentResult("PENDING", transactionId);
}

// Step 2: Payment gateway calls webhook when done
@PostMapping("/webhooks/payment")
public void paymentWebhook(@RequestBody PaymentWebhookEvent event) {
    Booking booking = findByTransactionId(event.getTransactionId());
    
    if (event.getStatus() == "SUCCESS") {
        booking.setStatus(CONFIRMED);
        booking.getSeats().forEach(seat -> seat.setStatus(BOOKED));
        notifyUser(booking.getUserId(), "Booking confirmed!");
    } else {
        booking.setStatus(CANCELLED);
        releaseSeats(booking.getSeats());
        notifyUser(booking.getUserId(), "Payment failed. Seats released.");
    }
    
    save(booking);
}
```

**Idempotency for Webhooks:**

- Payment gateway may call webhook multiple times
- Use `transactionId` to detect duplicates
- Store processed webhook IDs in DB

**User Experience:**

```
User clicks "Pay" →
  "Processing payment..."
  
After 2 seconds →
  "Payment is being processed. You'll receive confirmation via email shortly."
  
Webhook arrives →
  Email sent: "Booking confirmed! Booking ID: BMS123456"
```

**Trade-offs:**

✅ **Pros:**

- System remains responsive even if gateway slow
- Graceful degradation (fallback to async)
- Circuit breaker prevents cascading failures

❌ **Cons:**

- Async flow = delayed confirmation
- Need webhook endpoint
- Idempotency complexity"

---

### **Component 5: Search Service Architecture**

### **Interviewer**:

"Users search 'Sci-fi movies in Mumbai this weekend'. MySQL joins across movies, theaters, shows will be slow at scale. How do you optimize?"

### **Candidate**:

"Search queries are **read-heavy and complex** - not MySQL's strength. We need a **dedicated search engine**.

**Problem with MySQL:**

- Full-text search (`LIKE '%sci-fi%'`) scans entire table
- Joins across movies, theaters, shows = slow
- Relevance ranking difficult

**Solution: ElasticSearch for Search, MySQL for Transactions**

**Architecture:**

```
Search Query → API → ElasticSearch (search index) → Returns movie IDs
Booking Flow → API → MySQL (transactional data)
```

**Data Sync Strategy:**

```
MySQL (Source of Truth)
   ↓ (Change Data Capture)
ElasticSearch (Search Index)
```

**Sync Options:**

**Option 1: Dual Writes** (Simple but risky)

```java
public void createShow(Show show) {
    // Write to MySQL
    showRepository.save(show);
    
    // Write to ElasticSearch
    elasticsearchService.indexShow(show);
}
```

Problem: If ElasticSearch write fails, data inconsistent

**Option 2: Debezium CDC (Change Data Capture)** (Recommended)

- Debezium reads MySQL binlog (transaction log)
- Publishes changes to Kafka
- ElasticSearch connector consumes Kafka and indexes
- Guaranteed eventual consistency

**ElasticSearch Index Structure:**

```json
{
  "mappings": {
    "properties": {
      "movieId": { "type": "long" },
      "movieName": { "type": "text", "analyzer": "standard" },
      "genre": { "type": "keyword" },
      "language": { "type": "keyword" },
      "theaters": {
        "type": "nested",
        "properties": {
          "theaterId": { "type": "long" },
          "theaterName": { "type": "text" },
          "cityName": { "type": "keyword" },
          "showTimes": { "type": "date" }
        }
      }
    }
  }
}
```

**Search Query (ElasticSearch DSL):**

```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "genre": "sci-fi" } },
        { "nested": {
            "path": "theaters",
            "query": {
              "bool": {
                "must": [
                  { "term": { "theaters.cityName": "mumbai" } },
                  { "range": {
                      "theaters.showTimes": {
                        "gte": "2024-07-13",
                        "lte": "2024-07-14"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}
```

**Relevance Ranking:**

- Boost recent releases
- Boost popular movies (based on booking count)
- Personalize based on user history

**Trade-offs:**

✅ **Pros:**

- Sub-second search (full-text + filters)
- Relevance ranking
- Scales to millions of documents
- Faceted search (filter by genre, language, rating)

❌ **Cons:**

- Eventual consistency (ES may lag MySQL by seconds)
- Additional infrastructure
- More complex data pipeline

**When to Use:**

- Complex search queries
- Full-text search needed
- Read-heavy workload"

---

## Phase 9: Wrap-Up & Performance Assessment (70-75 mins)

### **Interviewer**:

"Excellent work! We've covered a comprehensive design. Let me summarize your performance:

### **Strengths:**

- ✅ Excellent requirement gathering and clarification
- ✅ Thoughtful data modeling (Seat vs ShowSeat separation was key)
- ✅ Comprehensive concurrency analysis with multiple solutions
- ✅ Realistic scaling strategy - not over-engineered
- ✅ Problem-specific components (Redis holds, waiting room, SSE) show deep understanding
- ✅ Clear trade-off analysis for every design decision
- ✅ Production-grade thinking (idempotency, circuit breakers, cache stampede)

### **Areas for Improvement:**

- ⚠️ Could have been more concise in some sections (time management)
- ⚠️ Could have mentioned monitoring/alerting metrics earlier

### **Score Breakdown:**

- **Correctness / Solution Quality**: 9/10 - Production-ready, addresses all requirements
- **Communication & Clarity**: 9/10 - Clear explanations, structured approach
- **Depth of Thought / Edge Cases**: 10/10 - Covered concurrency, expiry, failures, bot protection
- **Extensibility & Patterns**: 8/10 - Good use of patterns where needed
- **Time Management**: 7/10 - Covered everything but could pace better

**Overall Assessment**: **Strong Hire**

You demonstrated:

- Deep understanding of distributed systems
- Practical trade-off analysis
- Domain-specific problem-solving (booking systems)
- Production-grade considerations

Do you have any questions?"

### **Candidate**:

"Thank you! A few questions:

1. For the HLD components (Redis holds, waiting room, SSE), how much detail is expected in a 75-minute interview?
2. If I had to choose 2-3 areas to go deeper, what would you recommend?
3. What's the typical expectation for concurrency discussion at SDE-2 level?"

### **Interviewer**:

"Great questions!

1. **HLD depth**: In 75 minutes, you won't cover ALL components in detail. Pick 2-3 based on interviewer interest. If they ask about high traffic → dive into waiting room. If they ask about real-time → dive into SSE. Follow their lead.
    
2. **Priority areas**:
    
    - Concurrency (mandatory - 80% of design rounds test this)
    - Database schema + indexes (fundamental)
    - One HLD component relevant to problem (e.g., waiting room for BookMyShow)
3. **SDE-2 concurrency expectation**:
    
    - Must know pessimistic vs optimistic locking
    - Should understand distributed locks (Redis)
    - Bonus: Queue-based approach
    - Must articulate trade-offs clearly

Good luck with your interviews!"

---

## Key Takeaways

### **What Made This Interview Strong:**

1. **Structured Approach**: Requirements → Journey → Entities → DB → APIs → Concurrency → HLD
2. **Depth in Critical Areas**: Concurrency got 4 solutions, caching got deep dive
3. **Problem-Specific Thinking**: Redis holds, waiting room, SSE - all specific to BookMyShow's challenges
4. **Trade-off Analysis**: Every solution had pros/cons clearly articulated
5. **Production Considerations**: Idempotency, circuit breakers, bot protection

### **Common Mistakes to Avoid:**

❌ Jumping to code before requirements  
❌ Not discussing concurrency deeply enough  
❌ Generic HLD without problem-specific components  
❌ Ignoring trade-offs  
❌ Over-engineering (microservices for everything)

### **Practice Checklist:**

- [ ] Master concurrency patterns (pessimistic, optimistic, distributed locks, queue)
- [ ] Practice 5-6 similar problems (Parking Lot, Swiggy, Flight Booking, Uber, Chat System)
- [ ] Study database sharding strategies
- [ ] Understand caching layers and invalidation
- [ ] Learn one domain deeply (booking systems, real-time systems, or social networks)
- [ ] Practice explaining trade-offs out loud
- [ ] Time yourself (75 minutes per problem)

