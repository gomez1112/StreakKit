# StreakKit

A small, dependency-free Swift package for calculating current and longest streaks from ordered values, generic occurrences, and calendar-day events.

StreakKit is designed for habit trackers, workout apps, reading apps, learning apps, games, attendance systems, and any feature where consecutive activity matters.

## Highlights

- Current and longest streak calculation
- Generic over any `Sequence`
- Unsorted and already-sorted input APIs
- Duplicate occurrence handling
- Calendar- and time-zone-aware daily streaks
- Correct calendar arithmetic across daylight-saving transitions
- Configurable current-streak semantics
- Earliest or latest tie-breaking for equal longest streaks
- Key-path and closure-based daily APIs
- Strict Swift 6 concurrency-compatible value types
- No third-party dependencies
- Test suite written with Swift Testing, not XCTest

## Requirements

- Swift 6.2 or later
- iOS 18 or later
- macOS 15 or later
- watchOS 11 or later
- tvOS 18 or later
- visionOS 2 or later

The package is compatible with projects targeting newer platform releases, including iOS 27 and Swift 6.3.

## Installation

In Xcode, choose **File → Add Package Dependencies**, then enter the repository URL where you publish this package.

To use it in another package:

```swift
.package(
    url: "https://github.com/your-name/StreakKit.git",
    from: "1.0.0"
)
```

Then add `StreakKit` to the target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["StreakKit"]
)
```

Import it where needed:

```swift
import StreakKit
```

## Quick start: habit completions

Given a completion model:

```swift
struct HabitCompletion {
    let completedAt: Date
}
```

Calculate its streak:

```swift
let summary = StreakCalculator.daily(
    habit.completions,
    date: \.completedAt
)

print(summary.currentCount)
print(summary.longestCount)
```

The default `.todayOrYesterday` rule keeps a streak active when the latest run contains today or ended yesterday.

## Public API overview

### 1. Ordered predicate streaks

Use `consecutiveMatches(in:matching:)` when the collection's existing order defines the streak.

```swift
let result = StreakCalculator.consecutiveMatches(
    in: [true, true, false, true, true, true],
    matching: { $0 }
)

result.current // 3
result.longest // 3
```

It also supports throwing predicates:

```swift
let result = try StreakCalculator.consecutiveMatches(
    in: values,
    matching: validateAndMatch
)
```

### 2. Generic unsorted occurrences

Use `calculate(from:...)` for sortable values when input may be unsorted.

```swift
let summary = StreakCalculator.calculate(
    from: [8, 2, 3, 4, 8, 9, 10, 15],
    sortedBy: <,
    areEquivalent: ==,
    areConsecutive: { previous, next in
        next == previous + 1
    }
)
```

The package sorts the values, removes adjacent equivalents, and detects maximal consecutive runs.

The sorting and equivalence closures must agree: equivalent values must become adjacent after sorting.

### 3. Generic pre-sorted occurrences

Use `calculate(assumingSorted:...)` when the source has already sorted the values.

```swift
let summary = StreakCalculator.calculate(
    assumingSorted: sortedLevels,
    areEquivalent: ==,
    areConsecutive: { previous, next in
        next == previous + 1
    }
)
```

This reduces the calculation from O(n log n) to O(n). The caller is responsible for supplying correctly sorted input.

### 4. Daily events with a date key path

Use this when every event represents a successful occurrence:

```swift
let summary = StreakCalculator.daily(
    completions,
    date: \.completedAt
)
```

### 5. Daily events with date and success key paths

Use this when records can represent success or failure:

```swift
struct DailyRecord {
    let recordedAt: Date
    let completed: Bool
}

let summary = StreakCalculator.daily(
    records,
    date: \.recordedAt,
    matching: \.completed
)
```

Failed records are excluded. A day without a successful record naturally breaks the streak.

### 6. Daily events with custom closures

Use the closure API when date extraction or success requires custom logic:

```swift
let summary = StreakCalculator.daily(
    workouts,
    date: { workout in
        workout.finishedAt ?? workout.startedAt
    },
    matching: { workout in
        workout.finishedAt != nil && workout.minutes >= 20
    }
)
```

### 7. Daily date values

When you already have dates:

```swift
let summary = StreakCalculator.daily(completionDates)
```

### 8. Pre-sorted daily dates

When dates are already sorted:

```swift
let summary = StreakCalculator.daily(
    assumingSorted: completionDates
)
```

## Result types

### `StreakCounts`

Returned by `consecutiveMatches`:

```swift
public struct StreakCounts {
    public let current: Int
    public let longest: Int
}
```

### `StreakSummary<Value>`

Returned by generic occurrence and daily calculations:

```swift
summary.current
summary.longest
summary.currentCount
summary.longestCount
```

Each nonempty span contains:

```swift
span.count
span.start
span.end
```

Example:

```swift
if let longest = summary.longest {
    print("Longest: \(longest.count)")
    print("From: \(longest.start)")
    print("Through: \(longest.end)")
}
```

## Current daily streak rules

### `.todayOrYesterday`

The latest run is current when it contains today or ends yesterday. This is the default and is typically best for habit tracking.

```swift
currentRule: .todayOrYesterday
```

### `.mustIncludeToday`

The latest run is current only when it contains today.

```swift
currentRule: .mustIncludeToday
```

### `.mostRecentRecordedDay`

The newest recorded run is returned as current even when it is old.

```swift
currentRule: .mostRecentRecordedDay
```

This is useful when “current” means “most recent run,” not “currently active streak.”

## Longest streak tie-breaking

When two runs share the maximum length:

```swift
longestTieBreak: .earliest
```

retains the older run, while:

```swift
longestTieBreak: .latest
```

retains the newer run.

## Future dates

Future days are ignored by default:

```swift
includeFutureDays: false
```

They can be included explicitly:

```swift
includeFutureDays: true
```

Current-run qualification examines the complete final span. Therefore, a future date extending a run beyond today does not incorrectly erase a streak that contains today. A future-only run does not qualify under `.todayOrYesterday` or `.mustIncludeToday`.

For ordinary habit completion data, keeping future dates disabled is recommended. Scheduled activities and completed activities should normally be represented separately.

## Calendars and time zones

`Date` represents an instant, not a human calendar day. StreakKit uses the supplied `Calendar` to normalize events and advance by calendar days.

```swift
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "America/New_York")!

let summary = StreakCalculator.daily(
    completions,
    date: \.completedAt,
    calendar: calendar
)
```

Pass the calendar whose time zone defines the user's streak day. Calendar arithmetic is used instead of adding 86,400 seconds, preserving correct behavior across daylight-saving transitions.

## Deterministic testing with `now`

Avoid relying on the real clock in tests:

```swift
let summary = StreakCalculator.daily(
    dates,
    calendar: calendar,
    now: fixedNow
)
```

This makes current-streak results deterministic.

## SwiftData example

Store completion history rather than persisted streak counts:

```swift
import SwiftData

@Model
final class Habit {
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    init(name: String) {
        self.name = name
        completions = []
    }
}

@Model
final class HabitCompletion {
    var completedAt: Date
    var habit: Habit?

    init(completedAt: Date = .now, habit: Habit? = nil) {
        self.completedAt = completedAt
        self.habit = habit
    }
}
```

Calculate derived values:

```swift
let summary = StreakCalculator.daily(
    habit.completions,
    date: \.completedAt
)

let currentStreak = summary.currentCount
let longestStreak = summary.longestCount
```

Do not normally persist `currentStreak` and `longestStreak`. They can become stale when completions are inserted, removed, imported, restored, or reinterpreted under another time zone.

## Performance

| API | Time | Additional storage |
| --- | ---: | ---: |
| `consecutiveMatches` | O(n) | O(1) |
| `calculate(from:)` | O(n log n) | O(n) |
| `calculate(assumingSorted:)` | O(n) | O(n) |
| Unsorted daily APIs | O(n log n) | O(n) |
| `daily(assumingSorted:)` | O(n) | O(n) |

Deduplication uses an array so generic elements do not need to conform to `Hashable`.

## Testing

The package uses Swift Testing exclusively.

Run the suite with:

```bash
swift test
```

Run an optimized build and tests with:

```bash
swift test -c release
```

The test suite covers:

- empty input
- current and longest ordered runs
- throwing predicates
- unsorted generic values
- duplicate values
- earliest and latest tie-breaking
- current-run qualification
- key-path and closure-based daily APIs
- failed records
- duplicate events on one day
- today, yesterday, and stale semantics
- future-date behavior
- pre-sorted variants
- spring and fall daylight-saving transitions

## Design notes

- Daily completion boundaries are normalized using `Calendar.startOfDay(for:)`.
- Missing successful days break a daily streak; failed records do not need to be stored.
- Generic equivalence is adjacency-based after sorting to preserve O(n log n) behavior without requiring `Hashable`.
- `StreakSummary.empty` represents empty input with no current or longest span.
- `StreakSpan` requires a positive count.

## License

MIT License. See `LICENSE`.
