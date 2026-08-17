# StreakKit

A dependency-free Swift package for current, longest, and historical streaks over ordered values, generic occurrences, and calendar events.

## Requirements

Swift 6.2+, iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+, and visionOS 1+. Foundation-only StreakKit also supports Linux.

## Installation

In Xcode choose **File → Add Package Dependencies** and enter `https://github.com/gomez1112/StreakKit.git`, or add:

```swift
.package(url: "https://github.com/gomez1112/StreakKit.git", from: "2.0.0")
```

## Daily streaks

```swift
let summary = StreakCalculator.daily(completions, date: \.completedAt)
print(summary.currentCount, summary.longestCount)
```

Defaults use the current time and autoupdating calendar. Tests should pass deterministic options:

```swift
let options = StreakOptions(calendar: calendar, now: fixedNow)
let summary = StreakCalculator.daily(dates, options: options)
```

## Grace days and schedules

```swift
var options = StreakOptions(allowedGapDays: 1)
options.schedule = .weekdays([2, 3, 4, 5, 6])
let weekdayStreak = StreakCalculator.daily(dates, options: options)

options.schedule = .timesPerWeek(3)
let weeklyFrequency = StreakCalculator.daily(dates, options: options)
```

Grace days tolerate consecutive missing scheduled days. With `timesPerWeek`, `count` is qualifying weeks and boundaries are starts of weeks.

## Granularity

```swift
let monthly = StreakCalculator.streak(events, date: \.completedAt, granularity: .month, options: options)
```

Supported components are `.day`, `.weekOfYear`, `.month`, and `.year`. Week boundaries follow `Calendar.firstWeekday`.

## Generic and ordered APIs

Use `consecutiveMatches(in:matching:)` for predicate runs in existing order. Use `calculate(from:sortedBy:areEquivalent:areConsecutive:)` for unsorted generic values, or `calculate(assumingSorted:...)` for sorted input. Sorting must be a strict weak ordering; equivalence remains adjacency-based and never requires `Hashable`.

## Results

`StreakCounts` contains count-only predicate results. `StreakSummary` contains optional `current` and `longest` boundaries plus `allSpans` in chronological order. `StreakSpan` construction is failable for non-positive counts. All result types support `Codable` and `Hashable` when their values do.

## Calendars

Period normalization uses the supplied calendar and time zone. Calendar arithmetic handles DST, skipped civil dates, leap days, and non-Gregorian calendars. Apia's December 29 → 31, 2011 transition counts as consecutive because its calendar skipped December 30.

## Performance

| API | Time | Additional storage |
| --- | ---: | ---: |
| `consecutiveMatches` | O(n) | O(1) |
| `calculate(from:)`, unsorted calendar APIs | O(n log n) | O(n) |
| `calculate(assumingSorted:)`, `daily(assumingSorted:)` | O(n) | O(n) |

`allSpans` is collected during the existing scan and retains O(r) spans for r runs. Deduplication is adjacency-based, preserving support for non-`Hashable` elements.

## License

MIT. See `LICENSE`.
