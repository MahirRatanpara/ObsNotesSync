# Date and Time API

## Why It Matters

`java.time` is one of the best-designed parts of the JDK, and timezone handling is a classic source of production bugs. Also a common "have you used modern Java?" probe, since a lot of code still uses `Date`.

## Why the Old API Was Replaced

`java.util.Date` and `Calendar` were replaced in Java 8 because:

| Problem | Detail |
|---|---|
| **Mutable** | So not thread-safe and unusable as a map key |
| **Zero-indexed months** | `Calendar.JANUARY == 0` — endless off-by-one bugs |
| `Date` isn't a date | It's a millisecond instant, despite the name |
| Year offset | `Date(2024, ...)` meant year 3924 in the deprecated constructor |
| **`SimpleDateFormat` is not thread-safe** | A shared static instance silently corrupts output under load |
| Poor timezone handling | Implicit defaults everywhere |

**`SimpleDateFormat` sharing is the classic production bug** — it holds mutable parsing state, so a shared static instance under concurrency produces garbage dates or throws. Every `java.time` formatter is immutable and thread-safe.

## The Core Types

| Type | Represents | Has a zone | Use for |
|---|---|---|---|
| **`LocalDate`** | 2026-08-07 | No | Birthdays, holidays |
| **`LocalTime`** | 14:30:00 | No | Opening hours |
| **`LocalDateTime`** | Both, **no zone** | **No** | Wall-clock time, no instant |
| **`ZonedDateTime`** | Both **+ zone** | Yes | User-facing local time |
| `OffsetDateTime` | Both **+ UTC offset** | Fixed offset | APIs, ISO-8601 wire format |
| **`Instant`** | A point on the timeline (UTC) | Implicitly UTC | **Timestamps, logging, storage** |
| `Duration` | Time-based amount (seconds/nanos) | — | Elapsed time |
| `Period` | Date-based amount (y/m/d) | — | Calendar differences |
| `YearMonth`, `MonthDay` | Partials | — | Card expiry, anniversaries |

**All are immutable and thread-safe.**

## The Critical Distinction

**`LocalDateTime` is not a moment in time.**

```java
LocalDateTime.of(2026, 3, 29, 2, 30);   // may not exist — DST spring-forward
```

It's a wall-clock reading with no zone, so it can be ambiguous (during a DST fall-back hour) or non-existent (during spring-forward).

**`Instant` is an unambiguous point on the timeline.** Same instant everywhere; only its *rendering* differs by zone.

**The rule:**

| Store / transmit | Display |
|---|---|
| **`Instant`** (or UTC) | Convert to `ZonedDateTime` at the edge |

**Never store `LocalDateTime` for an event that happened.** You'll be unable to say when it actually occurred.

**The exception:** a *future* scheduled event in local terms — "the meeting is at 09:00 Tokyo time" — should store `LocalDateTime` plus a zone ID, not an `Instant`. If the timezone rules change before then (which governments do), an `Instant` would be wrong while the local time remains correct. **This nuance is a strong signal.**

## Conversions

```java
Instant now = Instant.now();

ZonedDateTime tokyo = now.atZone(ZoneId.of("Asia/Tokyo"));
LocalDateTime local = tokyo.toLocalDateTime();
Instant back        = tokyo.toInstant();

LocalDate today = LocalDate.now(ZoneId.of("Asia/Kolkata"));  // pass the zone EXPLICITLY
```

**`LocalDate.now()` without a zone uses the system default** — so a nightly job produces a different "today" depending on which server runs it. **Always pass an explicit `ZoneId`** in server code.

**Use region IDs, not fixed offsets:** `ZoneId.of("Europe/London")`, not `ZoneOffset.of("+01:00")`. Region IDs carry DST rules; fixed offsets don't.

## Manipulation

```java
LocalDate d = LocalDate.of(2026, 8, 7);

d.plusDays(10);  d.minusMonths(2);  d.withDayOfMonth(1);   // all return NEW objects
d.with(TemporalAdjusters.lastDayOfMonth());
d.with(TemporalAdjusters.next(DayOfWeek.MONDAY));
d.with(TemporalAdjusters.firstInMonth(DayOfWeek.FRIDAY));
```

**All operations return new instances** — immutable, so `d.plusDays(1)` alone does nothing.

**`TemporalAdjusters` covers most calendar arithmetic** without hand-rolled loops, and you can write custom ones.

## Duration vs Period

```java
Duration.ofHours(2);                        // exact time — 7,200 seconds
Period.ofMonths(1);                         // calendar concept — varies in length

Duration.between(instant1, instant2);       // time-based
Period.between(date1, date2);               // date-based
ChronoUnit.DAYS.between(date1, date2);      // a single unit as a long
```

**`Period.ofDays(1)` is not `Duration.ofHours(24)`.** On a DST transition day, one calendar day is 23 or 25 hours.

```java
zdt.plus(Period.ofDays(1));      // same wall-clock time tomorrow — may be 23 or 25 hours
zdt.plus(Duration.ofDays(1));    // exactly 24 hours later — may be a different wall time
```

**This is the DST bug people ship.** "Same time tomorrow" needs `Period`; "24 hours from now" needs `Duration`.

## Formatting and Parsing

```java
// Reusable, immutable, THREAD-SAFE
static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

String s = dateTime.format(FMT);
LocalDateTime dt = LocalDateTime.parse("2026-08-07 14:30", FMT);

// Prefer ISO for machine interchange
Instant.parse("2026-08-07T14:30:00Z");
DateTimeFormatter.ISO_INSTANT;

// Localised for display
DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(Locale.UK);
```

**Pattern letters that catch people:**

| Pattern | Means |
|---|---|
| `yyyy` | **Calendar year** — what you want |
| **`YYYY`** | **Week-based year** — differs near New Year |
| `MM` | Month |
| **`mm`** | **Minute** |
| `DD` | Day of **year** |
| `dd` | Day of month |
| `HH` | Hour 0–23 |
| `hh` | Hour 1–12 |

**`YYYY` versus `yyyy` produces a bug that only appears in late December** — 2026-12-29 formats as year 2027 with `YYYY`. It has caused real production incidents.

## Time Zones and DST

```java
ZoneId.of("America/New_York");           // region — carries DST rules
ZoneId.getAvailableZoneIds();
```

**Ambiguous and non-existent local times:**

```java
// Spring forward — 02:30 doesn't exist
ZonedDateTime.of(gapLocalDateTime, zone);      // silently SHIFTS forward

// Fall back — 01:30 happens twice
zdt.withEarlierOffsetAtOverlap();
zdt.withLaterOffsetAtOverlap();
```

**`ZonedDateTime.of` resolves gaps and overlaps silently.** If correctness matters, use `ZoneRules.getValidOffsets()` to detect the situation explicitly rather than accepting the default resolution.

**The timezone database changes several times a year** as governments alter DST rules. The JDK ships tzdata; keep the JVM patched, or use the TZUpdater tool.

## Storing in a Database

| Column type | Maps to | Use |
|---|---|---|
| `TIMESTAMP WITH TIME ZONE` (`timestamptz`) | **`Instant` / `OffsetDateTime`** | **Events — always** |
| `TIMESTAMP` (without zone) | `LocalDateTime` | Wall-clock only |
| `DATE` | `LocalDate` | Birthdays |
| `TIME` | `LocalTime` | Opening hours |

**Always use `timestamptz` for events.** A naive `TIMESTAMP` is meaningless without knowing which zone it was written in — and that knowledge lives nowhere.

**JDBC 4.2+ maps `java.time` directly** — no `java.sql.Timestamp` conversion needed. `setObject(1, instant)` works.

## Clock — For Testable Code

```java
class OrderService {
    private final Clock clock;                       // inject it
    OrderService(Clock clock) { this.clock = clock; }
    void placeOrder() { order.setCreatedAt(Instant.now(clock)); }
}

// Production
new OrderService(Clock.systemUTC());
// Test
new OrderService(Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC));
```

**`Instant.now()` scattered through the code is untestable.** Injecting a `Clock` makes time a dependency you control — and it's the standard answer to "how do you unit-test time-dependent logic?"

## Measuring Elapsed Time

```java
long start = System.nanoTime();          // MONOTONIC — correct for durations
doWork();
long elapsedNanos = System.nanoTime() - start;
```

**Never measure elapsed time with `System.currentTimeMillis()` or `Instant.now()`** — both are wall-clock and can jump backwards on an NTP correction, producing negative durations. See [Clocks and Ordering](../../09%20Distributed%20Systems/Time%20and%20Ordering/Clocks%20and%20Ordering.md).

## Common Mistakes

- `Date`, `Calendar` or `SimpleDateFormat` in new code
- **Sharing a `SimpleDateFormat` across threads**
- Storing `LocalDateTime` for events that happened
- `LocalDate.now()` without a zone in server code
- **`YYYY` instead of `yyyy`**
- `Duration.ofDays(1)` where `Period.ofDays(1)` was meant
- Fixed offsets instead of region IDs
- `TIMESTAMP` without zone in the database
- `Instant.now()` inline instead of an injected `Clock`
- Measuring elapsed time with wall-clock

## Related Topics

- [Types, Primitives and Autoboxing](Types%2C%20Primitives%20and%20Autoboxing.md)
- [Immutability and Defensive Copying](../OOP/Immutability%20and%20Defensive%20Copying.md)
- [Clocks and Ordering](../../09%20Distributed%20Systems/Time%20and%20Ordering/Clocks%20and%20Ordering.md)
- [Data Modelling and Schema Design](../../05%20Databases/Fundamentals/Data%20Modelling%20and%20Schema%20Design.md)

## Revision Summary

`java.time` types are immutable and thread-safe, unlike `Date` and `SimpleDateFormat`. Store events as `Instant` and render as `ZonedDateTime` at the edge; store future local appointments as local time plus a zone ID. `Period` is calendar-based and `Duration` is exact — they differ across DST. Inject a `Clock` for testability and use `System.nanoTime` for elapsed time.

## Quick Recall

- **`Instant` for events; `LocalDateTime` has no zone and is not a moment**
- Future local appointments → **local time + zone ID**, not an Instant
- **Always pass an explicit `ZoneId`** in server code
- Region IDs, not fixed offsets
- **`Period` ≠ `Duration` across DST** — 23 or 25 hour days
- **`YYYY` is week-based year** — a December-only bug
- `mm` is minutes, `MM` is months
- **`SimpleDateFormat` is not thread-safe**; `DateTimeFormatter` is
- Store as **`timestamptz`**
- **Inject a `Clock`**; use `System.nanoTime` for durations
