# 🏗️ Complete LLD System Design Examples

#must-do #faang #system-design #lld #interview-prep

## 📚 Table of Contents

### **Game Systems**
- [Tic Tac Toe Game](#-tic-tac-toe-game) - Turn-based game with strategy validation
- [Vending Machine](#-vending-machine) - State machine with inventory management

### **Booking Systems** 
- [Movie Ticket Booking System](#-movie-ticket-booking-system) - Multi-theater booking platform
- [Hotel Reservation System](#-hotel-reservation-system) - Room booking with pricing

### **E-commerce Systems**
- [Online Shopping Cart](#-online-shopping-cart) - Cart management with pricing
- [Inventory Management](#-inventory-management) - Stock tracking and notifications

### **Social Systems**
- [Chat System](#-chat-system) - Real-time messaging with groups
- [Social Media Feed](#-social-media-feed) - Timeline generation and caching

### **Utility Systems**
- [File System](#-distributed-file-system) - Hierarchical storage system
- [Cache System](#-lru-cache-system) - Memory-efficient caching
- [URL Shortener](#-url-shortener) - Short URL generation service

---

## 🎮 Tic Tac Toe Game

### 📋 Requirements Analysis
- **Functional**: 2-player turn-based game, 3x3 grid, win/draw detection, move validation
- **Non-functional**: Extensible to NxN, different win strategies, undo/redo support

### 🎯 Design Patterns Used
- **Strategy Pattern** - Different winning strategies
- **State Pattern** - Game states (InProgress, Won, Draw)
- **Command Pattern** - Move history for undo/redo
- **Factory Pattern** - Player creation

### 💻 Complete Implementation

```java
// Core game entities
class Position {
    private final int row;
    private final int col;
    
    public Position(int row, int col) {
        this.row = row;
        this.col = col;
    }
    
    public int getRow() { return row; }
    public int getCol() { return col; }
    
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof Position)) return false;
        Position position = (Position) obj;
        return row == position.row && col == position.col;
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(row, col);
    }
    
    @Override
    public String toString() {
        return String.format("(%d,%d)", row, col);
    }
}

enum Symbol {
    X, O, EMPTY;
    
    @Override
    public String toString() {
        return this == EMPTY ? " " : name();
    }
}

enum GameState {
    IN_PROGRESS, WON, DRAW
}

// Player abstraction
abstract class Player {
    protected final String name;
    protected final Symbol symbol;
    
    public Player(String name, Symbol symbol) {
        this.name = name;
        this.symbol = symbol;
    }
    
    public abstract Position makeMove(Board board);
    
    public String getName() { return name; }
    public Symbol getSymbol() { return symbol; }
}

class HumanPlayer extends Player {
    private final Scanner scanner;
    
    public HumanPlayer(String name, Symbol symbol) {
        super(name, symbol);
        this.scanner = new Scanner(System.in);
    }
    
    @Override
    public Position makeMove(Board board) {
        System.out.printf("%s (%s), enter your move (row col): ", name, symbol);
        try {
            int row = scanner.nextInt();
            int col = scanner.nextInt();
            return new Position(row, col);
        } catch (InputMismatchException e) {
            scanner.nextLine(); // Clear invalid input
            System.out.println("Invalid input! Please enter numbers.");
            return makeMove(board); // Retry
        }
    }
}

class AIPlayer extends Player {
    private final Random random;
    
    public AIPlayer(String name, Symbol symbol) {
        super(name, symbol);
        this.random = new Random();
    }
    
    @Override
    public Position makeMove(Board board) {
        // Simple AI: find first empty position
        List<Position> availableMoves = board.getAvailableMoves();
        if (availableMoves.isEmpty()) {
            throw new IllegalStateException("No moves available");
        }
        
        Position move = availableMoves.get(random.nextInt(availableMoves.size()));
        System.out.printf("AI %s (%s) plays at %s%n", name, symbol, move);
        return move;
    }
}

// Board management
class Board {
    private final int size;
    private final Symbol[][] grid;
    private int filledCells;
    
    public Board(int size) {
        this.size = size;
        this.grid = new Symbol[size][size];
        this.filledCells = 0;
        initializeBoard();
    }
    
    private void initializeBoard() {
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                grid[i][j] = Symbol.EMPTY;
            }
        }
    }
    
    public boolean makeMove(Position position, Symbol symbol) {
        if (!isValidMove(position)) {
            return false;
        }
        
        grid[position.getRow()][position.getCol()] = symbol;
        filledCells++;
        return true;
    }
    
    public boolean isValidMove(Position position) {
        if (position.getRow() < 0 || position.getRow() >= size ||
            position.getCol() < 0 || position.getCol() >= size) {
            return false;
        }
        return grid[position.getRow()][position.getCol()] == Symbol.EMPTY;
    }
    
    public List<Position> getAvailableMoves() {
        List<Position> moves = new ArrayList<>();
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                if (grid[i][j] == Symbol.EMPTY) {
                    moves.add(new Position(i, j));
                }
            }
        }
        return moves;
    }
    
    public boolean isFull() {
        return filledCells == size * size;
    }
    
    public Symbol getSymbol(Position position) {
        return grid[position.getRow()][position.getCol()];
    }
    
    public int getSize() { return size; }
    
    public void display() {
        System.out.println("Current Board:");
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                System.out.print(" " + grid[i][j] + " ");
                if (j < size - 1) System.out.print("|");
            }
            System.out.println();
            if (i < size - 1) {
                for (int j = 0; j < size; j++) {
                    System.out.print("---");
                    if (j < size - 1) System.out.print("+");
                }
                System.out.println();
            }
        }
        System.out.println();
    }
    
    // Create a copy for game state management
    public Board copy() {
        Board copy = new Board(size);
        for (int i = 0; i < size; i++) {
            System.arraycopy(grid[i], 0, copy.grid[i], 0, size);
        }
        copy.filledCells = this.filledCells;
        return copy;
    }
}

// Win condition strategies
interface WinningStrategy {
    boolean checkWin(Board board, Symbol symbol, Position lastMove);
}

class StandardWinningStrategy implements WinningStrategy {
    @Override
    public boolean checkWin(Board board, Symbol symbol, Position lastMove) {
        return checkRow(board, symbol, lastMove) ||
               checkColumn(board, symbol, lastMove) ||
               checkDiagonal(board, symbol, lastMove);
    }
    
    private boolean checkRow(Board board, Symbol symbol, Position lastMove) {
        int row = lastMove.getRow();
        for (int col = 0; col < board.getSize(); col++) {
            if (board.getSymbol(new Position(row, col)) != symbol) {
                return false;
            }
        }
        return true;
    }
    
    private boolean checkColumn(Board board, Symbol symbol, Position lastMove) {
        int col = lastMove.getCol();
        for (int row = 0; row < board.getSize(); row++) {
            if (board.getSymbol(new Position(row, col)) != symbol) {
                return false;
            }
        }
        return true;
    }
    
    private boolean checkDiagonal(Board board, Symbol symbol, Position lastMove) {
        int size = board.getSize();
        
        // Main diagonal (top-left to bottom-right)
        if (lastMove.getRow() == lastMove.getCol()) {
            boolean mainDiagonal = true;
            for (int i = 0; i < size; i++) {
                if (board.getSymbol(new Position(i, i)) != symbol) {
                    mainDiagonal = false;
                    break;
                }
            }
            if (mainDiagonal) return true;
        }
        
        // Anti-diagonal (top-right to bottom-left)
        if (lastMove.getRow() + lastMove.getCol() == size - 1) {
            boolean antiDiagonal = true;
            for (int i = 0; i < size; i++) {
                if (board.getSymbol(new Position(i, size - 1 - i)) != symbol) {
                    antiDiagonal = false;
                    break;
                }
            }
            if (antiDiagonal) return true;
        }
        
        return false;
    }
}

// Move command for undo/redo functionality
class Move {
    private final Player player;
    private final Position position;
    private final LocalDateTime timestamp;
    
    public Move(Player player, Position position) {
        this.player = player;
        this.position = position;
        this.timestamp = LocalDateTime.now();
    }
    
    public Player getPlayer() { return player; }
    public Position getPosition() { return position; }
    public LocalDateTime getTimestamp() { return timestamp; }
}

// Main game controller
class TicTacToeGame {
    private final Board board;
    private final List<Player> players;
    private final WinningStrategy winningStrategy;
    private final List<Move> moveHistory;
    private int currentPlayerIndex;
    private GameState gameState;
    private Player winner;
    
    public TicTacToeGame(int boardSize, List<Player> players, WinningStrategy strategy) {
        if (players.size() != 2) {
            throw new IllegalArgumentException("Exactly 2 players required");
        }
        
        this.board = new Board(boardSize);
        this.players = new ArrayList<>(players);
        this.winningStrategy = strategy;
        this.moveHistory = new ArrayList<>();
        this.currentPlayerIndex = 0;
        this.gameState = GameState.IN_PROGRESS;
        this.winner = null;
    }
    
    public void startGame() {
        System.out.println("=== TIC TAC TOE GAME STARTED ===");
        System.out.printf("Players: %s (%s) vs %s (%s)%n", 
            players.get(0).getName(), players.get(0).getSymbol(),
            players.get(1).getName(), players.get(1).getSymbol());
        
        board.display();
        
        while (gameState == GameState.IN_PROGRESS) {
            playTurn();
        }
        
        displayGameResult();
    }
    
    private void playTurn() {
        Player currentPlayer = players.get(currentPlayerIndex);
        System.out.printf("--- Turn %d: %s's move ----%n", 
            moveHistory.size() + 1, currentPlayer.getName());
        
        Position move;
        boolean validMove = false;
        
        do {
            move = currentPlayer.makeMove(board);
            validMove = board.makeMove(move, currentPlayer.getSymbol());
            
            if (!validMove) {
                System.out.println("Invalid move! Try again.");
            }
        } while (!validMove);
        
        // Record the move
        moveHistory.add(new Move(currentPlayer, move));
        board.display();
        
        // Check win condition
        if (winningStrategy.checkWin(board, currentPlayer.getSymbol(), move)) {
            gameState = GameState.WON;
            winner = currentPlayer;
        } else if (board.isFull()) {
            gameState = GameState.DRAW;
        } else {
            // Switch to next player
            currentPlayerIndex = (currentPlayerIndex + 1) % players.size();
        }
    }
    
    private void displayGameResult() {
        System.out.println("=== GAME OVER ===");
        if (gameState == GameState.WON) {
            System.out.printf("🎉 Winner: %s (%s)%n", winner.getName(), winner.getSymbol());
        } else {
            System.out.println("🤝 Game ended in a draw!");
        }
        
        System.out.printf("Total moves: %d%n", moveHistory.size());
        System.out.println("Move history:");
        for (int i = 0; i < moveHistory.size(); i++) {
            Move move = moveHistory.get(i);
            System.out.printf("%d. %s played at %s%n", 
                i + 1, move.getPlayer().getName(), move.getPosition());
        }
    }
    
    // Getters for game state
    public GameState getGameState() { return gameState; }
    public Player getWinner() { return winner; }
    public List<Move> getMoveHistory() { return Collections.unmodifiableList(moveHistory); }
}

// Factory for creating different types of games and players
class GameFactory {
    public static TicTacToeGame createHumanVsAIGame() {
        List<Player> players = Arrays.asList(
            new HumanPlayer("You", Symbol.X),
            new AIPlayer("Computer", Symbol.O)
        );
        return new TicTacToeGame(3, players, new StandardWinningStrategy());
    }
    
    public static TicTacToeGame createTwoPlayerGame() {
        List<Player> players = Arrays.asList(
            new HumanPlayer("Player 1", Symbol.X),
            new HumanPlayer("Player 2", Symbol.O)
        );
        return new TicTacToeGame(3, players, new StandardWinningStrategy());
    }
    
    public static TicTacToeGame createCustomGame(int boardSize) {
        List<Player> players = Arrays.asList(
            new HumanPlayer("Player 1", Symbol.X),
            new HumanPlayer("Player 2", Symbol.O)
        );
        return new TicTacToeGame(boardSize, players, new StandardWinningStrategy());
    }
}

// Main application
class TicTacToeApp {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        
        System.out.println("Welcome to Tic Tac Toe!");
        System.out.println("1. Human vs AI");
        System.out.println("2. Human vs Human");
        System.out.println("3. Custom board size");
        System.out.print("Choose game mode: ");
        
        int choice = scanner.nextInt();
        TicTacToeGame game;
        
        switch (choice) {
            case 1:
                game = GameFactory.createHumanVsAIGame();
                break;
            case 2:
                game = GameFactory.createTwoPlayerGame();
                break;
            case 3:
                System.out.print("Enter board size (3-10): ");
                int size = Math.max(3, Math.min(10, scanner.nextInt()));
                game = GameFactory.createCustomGame(size);
                break;
            default:
                game = GameFactory.createHumanVsAIGame();
        }
        
        game.startGame();
        scanner.close();
    }
}
```

### ⚠️ Areas for Improvement
- **Strategy Pattern for Win Conditions** - Support different win rules (4-in-a-row, corners, etc.)
- **Observer Pattern** - Notify UI components of game state changes
- **Memento Pattern** - Save/load game states
- **Tournament Mode** - Multiple games with scoring

### 🎯 Interview Questions
1. **Q**: How would you extend this to support different board sizes?
   **A**: Current design already supports NxN boards via constructor parameter.

2. **Q**: How to add undo functionality?
   **A**: Store board states or use Command pattern to reverse moves.

3. **Q**: How to make it multiplayer online?
   **A**: Add network layer, separate game state from UI, use observer pattern for updates.

---

## 🎬 Movie Ticket Booking System

### 📋 Requirements Analysis
- **Functional**: Search movies by city, book seats, payment processing, booking confirmation
- **Non-functional**: Handle concurrent bookings, seat locking, scalable architecture

### 🎯 Design Patterns Used
- **Repository Pattern** - Data access abstraction
- **Factory Pattern** - Booking creation
- **Strategy Pattern** - Pricing strategies
- **Observer Pattern** - Booking notifications
- **State Pattern** - Booking states

### 💻 Complete Implementation

```java
// Core entities
class City {
    private final String id;
    private final String name;
    private final String state;
    
    public City(String id, String name, String state) {
        this.id = id;
        this.name = name;
        this.state = state;
    }
    
    // Getters
    public String getId() { return id; }
    public String getName() { return name; }
    public String getState() { return state; }
    
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof City)) return false;
        City city = (City) obj;
        return Objects.equals(id, city.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

class Movie {
    private final String id;
    private final String title;
    private final String description;
    private final int durationMinutes;
    private final String genre;
    private final String rating; // PG, PG-13, R, etc.
    private final LocalDate releaseDate;
    
    public Movie(String id, String title, String description, int durationMinutes, 
                String genre, String rating, LocalDate releaseDate) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.durationMinutes = durationMinutes;
        this.genre = genre;
        this.rating = rating;
        this.releaseDate = releaseDate;
    }
    
    // Getters
    public String getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public int getDurationMinutes() { return durationMinutes; }
    public String getGenre() { return genre; }
    public String getRating() { return rating; }
    public LocalDate getReleaseDate() { return releaseDate; }
    
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof Movie)) return false;
        Movie movie = (Movie) obj;
        return Objects.equals(id, movie.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

class Theater {
    private final String id;
    private final String name;
    private final String address;
    private final City city;
    private final List<Screen> screens;
    
    public Theater(String id, String name, String address, City city) {
        this.id = id;
        this.name = name;
        this.address = address;
        this.city = city;
        this.screens = new ArrayList<>();
    }
    
    public void addScreen(Screen screen) {
        screens.add(screen);
    }
    
    // Getters
    public String getId() { return id; }
    public String getName() { return name; }
    public String getAddress() { return address; }
    public City getCity() { return city; }
    public List<Screen> getScreens() { return Collections.unmodifiableList(screens); }
}

class Screen {
    private final String id;
    private final String name;
    private final int totalSeats;
    private final List<Seat> seats;
    private final Theater theater;
    
    public Screen(String id, String name, Theater theater) {
        this.id = id;
        this.name = name;
        this.theater = theater;
        this.seats = new ArrayList<>();
        this.totalSeats = initializeSeats();
    }
    
    private int initializeSeats() {
        // Standard theater layout: 10 rows, 20 seats per row
        int seatCount = 0;
        for (char row = 'A'; row <= 'J'; row++) {
            for (int seatNum = 1; seatNum <= 20; seatNum++) {
                SeatType type = (row >= 'A' && row <= 'C') ? SeatType.PREMIUM :
                               (row >= 'D' && row <= 'G') ? SeatType.REGULAR : SeatType.ECONOMY;
                String seatId = row + String.valueOf(seatNum);
                seats.add(new Seat(seatId, row, seatNum, type));
                seatCount++;
            }
        }
        return seatCount;
    }
    
    // Getters
    public String getId() { return id; }
    public String getName() { return name; }
    public int getTotalSeats() { return totalSeats; }
    public List<Seat> getSeats() { return Collections.unmodifiableList(seats); }
    public Theater getTheater() { return theater; }
}

enum SeatType {
    PREMIUM(15.0), REGULAR(10.0), ECONOMY(8.0);
    
    private final double basePrice;
    
    SeatType(double basePrice) {
        this.basePrice = basePrice;
    }
    
    public double getBasePrice() { return basePrice; }
}

class Seat {
    private final String id;
    private final char row;
    private final int number;
    private final SeatType type;
    
    public Seat(String id, char row, int number, SeatType type) {
        this.id = id;
        this.row = row;
        this.number = number;
        this.type = type;
    }
    
    // Getters
    public String getId() { return id; }
    public char getRow() { return row; }
    public int getNumber() { return number; }
    public SeatType getType() { return type; }
    
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof Seat)) return false;
        Seat seat = (Seat) obj;
        return Objects.equals(id, seat.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
    
    @Override
    public String toString() {
        return id;
    }
}

class Show {
    private final String id;
    private final Movie movie;
    private final Screen screen;
    private final LocalDateTime startTime;
    private final LocalDateTime endTime;
    private final Map<Seat, SeatBookingStatus> seatAvailability;
    private final BigDecimal basePriceMultiplier;
    
    public Show(String id, Movie movie, Screen screen, LocalDateTime startTime, BigDecimal basePriceMultiplier) {
        this.id = id;
        this.movie = movie;
        this.screen = screen;
        this.startTime = startTime;
        this.endTime = startTime.plusMinutes(movie.getDurationMinutes());
        this.basePriceMultiplier = basePriceMultiplier;
        this.seatAvailability = new ConcurrentHashMap<>();
        
        // Initialize all seats as available
        for (Seat seat : screen.getSeats()) {
            seatAvailability.put(seat, SeatBookingStatus.AVAILABLE);
        }
    }
    
    public synchronized boolean lockSeats(List<Seat> seats, String userId) {
        // Check if all seats are available
        for (Seat seat : seats) {
            if (seatAvailability.get(seat) != SeatBookingStatus.AVAILABLE) {
                return false;
            }
        }
        
        // Lock all seats
        for (Seat seat : seats) {
            seatAvailability.put(seat, SeatBookingStatus.LOCKED);
        }
        
        // Schedule unlock after timeout (5 minutes)
        scheduleUnlock(seats, userId);
        return true;
    }
    
    public synchronized boolean bookSeats(List<Seat> seats) {
        // Check if all seats are locked or available
        for (Seat seat : seats) {
            SeatBookingStatus status = seatAvailability.get(seat);
            if (status != SeatBookingStatus.LOCKED && status != SeatBookingStatus.AVAILABLE) {
                return false;
            }
        }
        
        // Book all seats
        for (Seat seat : seats) {
            seatAvailability.put(seat, SeatBookingStatus.BOOKED);
        }
        return true;
    }
    
    public List<Seat> getAvailableSeats() {
        return seatAvailability.entrySet().stream()
            .filter(entry -> entry.getValue() == SeatBookingStatus.AVAILABLE)
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());
    }
    
    public BigDecimal calculatePrice(List<Seat> seats, PricingStrategy pricingStrategy) {
        return pricingStrategy.calculatePrice(seats, this);
    }
    
    private void scheduleUnlock(List<Seat> seats, String userId) {
        // In production, use proper scheduler like Quartz or Spring Scheduler
        new Timer().schedule(new TimerTask() {
            @Override
            public void run() {
                synchronized(Show.this) {
                    for (Seat seat : seats) {
                        if (seatAvailability.get(seat) == SeatBookingStatus.LOCKED) {
                            seatAvailability.put(seat, SeatBookingStatus.AVAILABLE);
                        }
                    }
                }
                System.out.printf("Unlocked seats for user %s in show %s%n", userId, id);
            }
        }, 5 * 60 * 1000); // 5 minutes
    }
    
    // Getters
    public String getId() { return id; }
    public Movie getMovie() { return movie; }
    public Screen getScreen() { return screen; }
    public LocalDateTime getStartTime() { return startTime; }
    public LocalDateTime getEndTime() { return endTime; }
    public BigDecimal getBasePriceMultiplier() { return basePriceMultiplier; }
}

enum SeatBookingStatus {
    AVAILABLE, LOCKED, BOOKED
}

// Pricing strategies
interface PricingStrategy {
    BigDecimal calculatePrice(List<Seat> seats, Show show);
}

class StandardPricingStrategy implements PricingStrategy {
    @Override
    public BigDecimal calculatePrice(List<Seat> seats, Show show) {
        BigDecimal totalPrice = BigDecimal.ZERO;
        
        for (Seat seat : seats) {
            BigDecimal seatPrice = BigDecimal.valueOf(seat.getType().getBasePrice())
                .multiply(show.getBasePriceMultiplier());
            totalPrice = totalPrice.add(seatPrice);
        }
        
        return totalPrice;
    }
}

class WeekendPricingStrategy implements PricingStrategy {
    private static final BigDecimal WEEKEND_MULTIPLIER = new BigDecimal("1.2");
    
    @Override
    public BigDecimal calculatePrice(List<Seat> seats, Show show) {
        BigDecimal basePrice = new StandardPricingStrategy().calculatePrice(seats, show);
        
        DayOfWeek dayOfWeek = show.getStartTime().getDayOfWeek();
        if (dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY) {
            return basePrice.multiply(WEEKEND_MULTIPLIER);
        }
        
        return basePrice;
    }
}

class PrimePricingStrategy implements PricingStrategy {
    private static final BigDecimal PRIME_TIME_MULTIPLIER = new BigDecimal("1.5");
    
    @Override
    public BigDecimal calculatePrice(List<Seat> seats, Show show) {
        BigDecimal basePrice = new StandardPricingStrategy().calculatePrice(seats, show);
        
        int hour = show.getStartTime().getHour();
        if (hour >= 18 && hour <= 21) { // Prime time 6 PM - 9 PM
            return basePrice.multiply(PRIME_TIME_MULTIPLIER);
        }
        
        return basePrice;
    }
}

// Booking system
class User {
    private final String id;
    private final String name;
    private final String email;
    private final String phone;
    
    public User(String id, String name, String email, String phone) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.phone = phone;
    }
    
    // Getters
    public String getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
}

enum BookingStatus {
    PENDING, CONFIRMED, CANCELLED, FAILED
}

class Booking {
    private final String id;
    private final User user;
    private final Show show;
    private final List<Seat> seats;
    private final BigDecimal totalAmount;
    private final LocalDateTime bookingTime;
    private BookingStatus status;
    
    public Booking(String id, User user, Show show, List<Seat> seats, BigDecimal totalAmount) {
        this.id = id;
        this.user = user;
        this.show = show;
        this.seats = new ArrayList<>(seats);
        this.totalAmount = totalAmount;
        this.bookingTime = LocalDateTime.now();
        this.status = BookingStatus.PENDING;
    }
    
    public void confirm() {
        this.status = BookingStatus.CONFIRMED;
    }
    
    public void cancel() {
        this.status = BookingStatus.CANCELLED;
    }
    
    public void fail() {
        this.status = BookingStatus.FAILED;
    }
    
    // Getters
    public String getId() { return id; }
    public User getUser() { return user; }
    public Show getShow() { return show; }
    public List<Seat> getSeats() { return Collections.unmodifiableList(seats); }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public LocalDateTime getBookingTime() { return bookingTime; }
    public BookingStatus getStatus() { return status; }
}

// Repository interfaces for data access
interface MovieRepository {
    List<Movie> findMoviesByCity(City city);
    Movie findById(String movieId);
    void save(Movie movie);
}

interface TheaterRepository {
    List<Theater> findTheatersByCity(City city);
    Theater findById(String theaterId);
    void save(Theater theater);
}

interface ShowRepository {
    List<Show> findShowsByMovieAndCity(Movie movie, City city, LocalDate date);
    Show findById(String showId);
    void save(Show show);
}

interface BookingRepository {
    void save(Booking booking);
    Booking findById(String bookingId);
    List<Booking> findByUser(User user);
}

// In-memory repository implementations
class InMemoryMovieRepository implements MovieRepository {
    private final Map<String, Movie> movies = new ConcurrentHashMap<>();
    private final Map<City, List<Movie>> moviesByCity = new ConcurrentHashMap<>();
    
    @Override
    public List<Movie> findMoviesByCity(City city) {
        return moviesByCity.getOrDefault(city, new ArrayList<>());
    }
    
    @Override
    public Movie findById(String movieId) {
        return movies.get(movieId);
    }
    
    @Override
    public void save(Movie movie) {
        movies.put(movie.getId(), movie);
    }
    
    public void addMovieToCity(Movie movie, City city) {
        save(movie);
        moviesByCity.computeIfAbsent(city, k -> new ArrayList<>()).add(movie);
    }
}

// Main booking service
class MovieBookingService {
    private final MovieRepository movieRepository;
    private final TheaterRepository theaterRepository;
    private final ShowRepository showRepository;
    private final BookingRepository bookingRepository;
    private final PricingStrategy pricingStrategy;
    
    public MovieBookingService(MovieRepository movieRepository, TheaterRepository theaterRepository,
                              ShowRepository showRepository, BookingRepository bookingRepository,
                              PricingStrategy pricingStrategy) {
        this.movieRepository = movieRepository;
        this.theaterRepository = theaterRepository;
        this.showRepository = showRepository;
        this.bookingRepository = bookingRepository;
        this.pricingStrategy = pricingStrategy;
    }
    
    public List<Movie> searchMovies(City city) {
        return movieRepository.findMoviesByCity(city);
    }
    
    public List<Show> getShows(Movie movie, City city, LocalDate date) {
        return showRepository.findShowsByMovieAndCity(movie, city, date);
    }
    
    public BookingResult bookTickets(String userId, String showId, List<String> seatIds) {
        Show show = showRepository.findById(showId);
        if (show == null) {
            return new BookingResult(false, "Show not found", null);
        }
        
        // Convert seat IDs to seat objects
        List<Seat> requestedSeats = show.getScreen().getSeats().stream()
            .filter(seat -> seatIds.contains(seat.getId()))
            .collect(Collectors.toList());
        
        if (requestedSeats.size() != seatIds.size()) {
            return new BookingResult(false, "Some seats not found", null);
        }
        
        // Lock seats first
        if (!show.lockSeats(requestedSeats, userId)) {
            return new BookingResult(false, "Seats not available", null);
        }
        
        try {
            // Calculate price
            BigDecimal totalAmount = show.calculatePrice(requestedSeats, pricingStrategy);
            
            // Create booking
            String bookingId = "BK_" + System.currentTimeMillis();
            User user = new User(userId, "User " + userId, userId + "@email.com", "123-456-7890");
            Booking booking = new Booking(bookingId, user, show, requestedSeats, totalAmount);
            
            // Process payment (mock)
            boolean paymentSuccess = processPayment(totalAmount);
            
            if (paymentSuccess) {
                // Book seats and confirm booking
                if (show.bookSeats(requestedSeats)) {
                    booking.confirm();
                    bookingRepository.save(booking);
                    return new BookingResult(true, "Booking confirmed", booking);
                } else {
                    booking.fail();
                    return new BookingResult(false, "Failed to book seats", null);
                }
            } else {
                booking.fail();
                return new BookingResult(false, "Payment failed", null);
            }
            
        } catch (Exception e) {
            return new BookingResult(false, "Booking failed: " + e.getMessage(), null);
        }
    }
    
    private boolean processPayment(BigDecimal amount) {
        // Mock payment processing
        try {
            Thread.sleep(1000); // Simulate payment processing time
            return true; // Always successful in demo
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }
}

class BookingResult {
    private final boolean success;
    private final String message;
    private final Booking booking;
    
    public BookingResult(boolean success, String message, Booking booking) {
        this.success = success;
        this.message = message;
        this.booking = booking;
    }
    
    // Getters
    public boolean isSuccess() { return success; }
    public String getMessage() { return message; }
    public Booking getBooking() { return booking; }
}
```

### 🎯 Interview Questions
1. **Q**: How do you handle concurrent seat booking?
   **A**: Use seat locking with timeout, synchronized methods, and database transactions.

2. **Q**: How to scale this system for millions of users?
   **A**: Use distributed caching, database sharding, microservices architecture, and queue-based processing.

3. **Q**: How to handle different pricing for different times/dates?
   **A**: Strategy pattern with multiple pricing implementations (weekends, prime time, holidays).

---

## 🏪 Vending Machine

### 📋 Requirements Analysis
- **Functional**: Accept coins, select products, dispense items, return change
- **Non-functional**: Handle invalid selections, out of stock, insufficient funds

### 🎯 Design Patterns Used
- **State Pattern** - Machine states (Idle, HasMoney, Dispensing, OutOfStock)
- **Strategy Pattern** - Different payment methods
- **Command Pattern** - User actions (InsertCoin, SelectProduct, etc.)

### 💻 Implementation

```java
// Product and inventory management
class Product {
    private final String id;
    private final String name;
    private final BigDecimal price;
    private final int calories;
    
    public Product(String id, String name, BigDecimal price, int calories) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.calories = calories;
    }
    
    // Getters
    public String getId() { return id; }
    public String getName() { return name; }
    public BigDecimal getPrice() { return price; }
    public int getCalories() { return calories; }
    
    @Override
    public String toString() {
        return String.format("%s - $%.2f (%d cal)", name, price, calories);
    }
}

class InventoryItem {
    private final Product product;
    private int quantity;
    private final int maxQuantity;
    
    public InventoryItem(Product product, int quantity, int maxQuantity) {
        this.product = product;
        this.quantity = quantity;
        this.maxQuantity = maxQuantity;
    }
    
    public boolean isAvailable() {
        return quantity > 0;
    }
    
    public boolean dispense() {
        if (quantity > 0) {
            quantity--;
            return true;
        }
        return false;
    }
    
    public void restock(int amount) {
        quantity = Math.min(quantity + amount, maxQuantity);
    }
    
    // Getters
    public Product getProduct() { return product; }
    public int getQuantity() { return quantity; }
    public int getMaxQuantity() { return maxQuantity; }
}

class Inventory {
    private final Map<String, InventoryItem> items;
    
    public Inventory() {
        this.items = new HashMap<>();
        initializeInventory();
    }
    
    private void initializeInventory() {
        // Sample products
        Product coke = new Product("A1", "Coca Cola", new BigDecimal("1.50"), 140);
        Product pepsi = new Product("A2", "Pepsi", new BigDecimal("1.50"), 150);
        Product water = new Product("B1", "Water", new BigDecimal("1.00"), 0);
        Product chips = new Product("C1", "Potato Chips", new BigDecimal("2.00"), 160);
        
        items.put("A1", new InventoryItem(coke, 10, 15));
        items.put("A2", new InventoryItem(pepsi, 8, 15));
        items.put("B1", new InventoryItem(water, 12, 20));
        items.put("C1", new InventoryItem(chips, 5, 10));
    }
    
    public InventoryItem getItem(String productId) {
        return items.get(productId);
    }
    
    public List<InventoryItem> getAllItems() {
        return new ArrayList<>(items.values());
    }
    
    public boolean isProductAvailable(String productId) {
        InventoryItem item = items.get(productId);
        return item != null && item.isAvailable();
    }
    
    public void restockAll() {
        for (InventoryItem item : items.values()) {
            item.restock(item.getMaxQuantity());
        }
    }
}

// State pattern implementation
interface VendingMachineState {
    void insertCoin(VendingMachine machine, BigDecimal amount);
    void selectProduct(VendingMachine machine, String productId);
    void dispenseProduct(VendingMachine machine);
    void returnChange(VendingMachine machine);
    void cancel(VendingMachine machine);
}

class IdleState implements VendingMachineState {
    @Override
    public void insertCoin(VendingMachine machine, BigDecimal amount) {
        machine.addBalance(amount);
        System.out.printf("Inserted $%.2f. Current balance: $%.2f%n", 
            amount, machine.getCurrentBalance());
        machine.setState(machine.getHasMoneyState());
    }
    
    @Override
    public void selectProduct(VendingMachine machine, String productId) {
        System.out.println("Please insert coins first.");
    }
    
    @Override
    public void dispenseProduct(VendingMachine machine) {
        System.out.println("Please select a product first.");
    }
    
    @Override
    public void returnChange(VendingMachine machine) {
        System.out.println("No money to return.");
    }
    
    @Override
    public void cancel(VendingMachine machine) {
        System.out.println("No transaction to cancel.");
    }
}

class HasMoneyState implements VendingMachineState {
    @Override
    public void insertCoin(VendingMachine machine, BigDecimal amount) {
        machine.addBalance(amount);
        System.out.printf("Inserted $%.2f. Total balance: $%.2f%n", 
            amount, machine.getCurrentBalance());
    }
    
    @Override
    public void selectProduct(VendingMachine machine, String productId) {
        InventoryItem item = machine.getInventory().getItem(productId);
        
        if (item == null) {
            System.out.println("Invalid product selection.");
            return;
        }
        
        if (!item.isAvailable()) {
            System.out.printf("Product %s is out of stock.%n", item.getProduct().getName());
            machine.setState(machine.getOutOfStockState());
            return;
        }
        
        BigDecimal productPrice = item.getProduct().getPrice();
        if (machine.getCurrentBalance().compareTo(productPrice) < 0) {
            BigDecimal needed = productPrice.subtract(machine.getCurrentBalance());
            System.out.printf("Insufficient funds. Need $%.2f more.%n", needed);
            return;
        }
        
        machine.setSelectedProduct(productId);
        machine.setState(machine.getDispensingState());
        machine.getCurrentState().dispenseProduct(machine);
    }
    
    @Override
    public void dispenseProduct(VendingMachine machine) {
        System.out.println("Please select a product first.");
    }
    
    @Override
    public void returnChange(VendingMachine machine) {
        BigDecimal balance = machine.getCurrentBalance();
        if (balance.compareTo(BigDecimal.ZERO) > 0) {
            System.out.printf("Returning $%.2f%n", balance);
            machine.resetBalance();
        }
        machine.setState(machine.getIdleState());
    }
    
    @Override
    public void cancel(VendingMachine machine) {
        returnChange(machine);
    }
}

class DispensingState implements VendingMachineState {
    @Override
    public void insertCoin(VendingMachine machine, BigDecimal amount) {
        System.out.println("Please wait, dispensing product...");
    }
    
    @Override
    public void selectProduct(VendingMachine machine, String productId) {
        System.out.println("Already dispensing. Please wait.");
    }
    
    @Override
    public void dispenseProduct(VendingMachine machine) {
        String productId = machine.getSelectedProduct();
        InventoryItem item = machine.getInventory().getItem(productId);
        
        if (item != null && item.dispense()) {
            BigDecimal productPrice = item.getProduct().getPrice();
            machine.deductBalance(productPrice);
            
            System.out.printf("Dispensed: %s%n", item.getProduct().getName());
            
            // Return change if any
            BigDecimal remaining = machine.getCurrentBalance();
            if (remaining.compareTo(BigDecimal.ZERO) > 0) {
                System.out.printf("Change returned: $%.2f%n", remaining);
                machine.resetBalance();
            }
            
            machine.setSelectedProduct(null);
            machine.setState(machine.getIdleState());
        } else {
            System.out.println("Failed to dispense product.");
            machine.setState(machine.getOutOfStockState());
        }
    }
    
    @Override
    public void returnChange(VendingMachine machine) {
        System.out.println("Cannot return change while dispensing.");
    }
    
    @Override
    public void cancel(VendingMachine machine) {
        System.out.println("Cannot cancel while dispensing.");
    }
}

class OutOfStockState implements VendingMachineState {
    @Override
    public void insertCoin(VendingMachine machine, BigDecimal amount) {
        System.out.println("Machine is out of stock. Please select a different product or get refund.");
        machine.addBalance(amount);
    }
    
    @Override
    public void selectProduct(VendingMachine machine, String productId) {
        InventoryItem item = machine.getInventory().getItem(productId);
        if (item != null && item.isAvailable()) {
            machine.setState(machine.getHasMoneyState());
            machine.getCurrentState().selectProduct(machine, productId);
        } else {
            System.out.println("Selected product is also out of stock.");
        }
    }
    
    @Override
    public void dispenseProduct(VendingMachine machine) {
        System.out.println("No products available to dispense.");
    }
    
    @Override
    public void returnChange(VendingMachine machine) {
        BigDecimal balance = machine.getCurrentBalance();
        if (balance.compareTo(BigDecimal.ZERO) > 0) {
            System.out.printf("Refunding $%.2f due to out of stock%n", balance);
            machine.resetBalance();
        }
        machine.setState(machine.getIdleState());
    }
    
    @Override
    public void cancel(VendingMachine machine) {
        returnChange(machine);
    }
}

// Main vending machine class
class VendingMachine {
    private final Inventory inventory;
    private BigDecimal currentBalance;
    private String selectedProduct;
    
    // States
    private final VendingMachineState idleState;
    private final VendingMachineState hasMoneyState;
    private final VendingMachineState dispensingState;
    private final VendingMachineState outOfStockState;
    
    private VendingMachineState currentState;
    
    public VendingMachine() {
        this.inventory = new Inventory();
        this.currentBalance = BigDecimal.ZERO;
        
        // Initialize states
        this.idleState = new IdleState();
        this.hasMoneyState = new HasMoneyState();
        this.dispensingState = new DispensingState();
        this.outOfStockState = new OutOfStockState();
        
        this.currentState = idleState;
    }
    
    // Public interface methods
    public void insertCoin(BigDecimal amount) {
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            System.out.println("Invalid coin amount.");
            return;
        }
        currentState.insertCoin(this, amount);
    }
    
    public void selectProduct(String productId) {
        currentState.selectProduct(this, productId);
    }
    
    public void returnChange() {
        currentState.returnChange(this);
    }
    
    public void cancel() {
        currentState.cancel(this);
    }
    
    public void displayProducts() {
        System.out.println("\n=== Available Products ===");
        for (InventoryItem item : inventory.getAllItems()) {
            String status = item.isAvailable() ? 
                String.format("(%d available)", item.getQuantity()) : "(OUT OF STOCK)";
            System.out.printf("%s: %s %s%n", 
                item.getProduct().getId(), item.getProduct(), status);
        }
        System.out.printf("Current balance: $%.2f%n", currentBalance);
        System.out.println("========================\n");
    }
    
    public void restock() {
        inventory.restockAll();
        System.out.println("Machine restocked!");
        if (currentState == outOfStockState) {
            setState(currentBalance.compareTo(BigDecimal.ZERO) > 0 ? hasMoneyState : idleState);
        }
    }
    
    // State management
    public void setState(VendingMachineState state) {
        this.currentState = state;
    }
    
    // Balance management
    public void addBalance(BigDecimal amount) {
        currentBalance = currentBalance.add(amount);
    }
    
    public void deductBalance(BigDecimal amount) {
        currentBalance = currentBalance.subtract(amount);
    }
    
    public void resetBalance() {
        currentBalance = BigDecimal.ZERO;
    }
    
    // Getters
    public VendingMachineState getCurrentState() { return currentState; }
    public VendingMachineState getIdleState() { return idleState; }
    public VendingMachineState getHasMoneyState() { return hasMoneyState; }
    public VendingMachineState getDispensingState() { return dispensingState; }
    public VendingMachineState getOutOfStockState() { return outOfStockState; }
    public Inventory getInventory() { return inventory; }
    public BigDecimal getCurrentBalance() { return currentBalance; }
    public String getSelectedProduct() { return selectedProduct; }
    
    public void setSelectedProduct(String selectedProduct) {
        this.selectedProduct = selectedProduct;
    }
}

// Demo application
class VendingMachineApp {
    public static void main(String[] args) {
        VendingMachine machine = new VendingMachine();
        Scanner scanner = new Scanner(System.in);
        
        System.out.println("=== VENDING MACHINE SIMULATOR ===");
        System.out.println("Commands: insert <amount>, select <product_id>, change, cancel, display, restock, quit");
        
        while (true) {
            System.out.print("> ");
            String input = scanner.nextLine().trim();
            String[] parts = input.split("\\s+");
            
            try {
                switch (parts[0].toLowerCase()) {
                    case "insert":
                        if (parts.length > 1) {
                            BigDecimal amount = new BigDecimal(parts[1]);
                            machine.insertCoin(amount);
                        } else {
                            System.out.println("Usage: insert <amount>");
                        }
                        break;
                        
                    case "select":
                        if (parts.length > 1) {
                            machine.selectProduct(parts[1].toUpperCase());
                        } else {
                            System.out.println("Usage: select <product_id>");
                        }
                        break;
                        
                    case "change":
                        machine.returnChange();
                        break;
                        
                    case "cancel":
                        machine.cancel();
                        break;
                        
                    case "display":
                        machine.displayProducts();
                        break;
                        
                    case "restock":
                        machine.restock();
                        break;
                        
                    case "quit":
                        System.out.println("Thank you for using the vending machine!");
                        scanner.close();
                        return;
                        
                    default:
                        System.out.println("Unknown command. Available commands: insert, select, change, cancel, display, restock, quit");
                }
            } catch (NumberFormatException e) {
                System.out.println("Invalid amount format.");
            } catch (Exception e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }
}
```

### 🎯 Interview Questions
1. **Q**: How would you add credit card payment support?
   **A**: Use Strategy pattern for payment methods, add PaymentProcessor interface with different implementations.

2. **Q**: How to handle power failures?
   **A**: Implement persistence layer to save machine state, add recovery mechanism on startup.

3. **Q**: How to support different product categories?
   **A**: Add Category enum to Product, implement category-based pricing and organization.

---

## 📊 Complexity Summary

| **System** | **Time Complexity** | **Space Complexity** | **Patterns Used** |
|------------|--------------------|--------------------|------------------|
| Tic Tac Toe | O(n²) per move | O(n²) | Strategy, State, Command, Factory |
| Movie Booking | O(n) seat selection | O(m×n) theaters×seats | Repository, Factory, Strategy, Observer |
| Vending Machine | O(1) operations | O(n) products | State, Strategy, Command |

### 🔗 Cross-References
- [[Complete Design Patterns Guide]] - Pattern implementations
- [[System Design Patterns]] - Scalability considerations  
- [[Database Design]] - Data persistence strategies
- [[Concurrency Patterns]] - Thread safety in booking systems

---

*Tags: #lld #system-design #design-patterns #java #concurrency #interview-prep*