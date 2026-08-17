# Migrating from 1.x

Replace loose daily arguments with one options value:

```swift
let options = StreakOptions(calendar: calendar, now: fixedDate)
let result = StreakCalculator.daily(dates, options: options)
```

Handle `StreakSpan(count:start:end:)` as a failable initializer. `StreakSummary.allSpans` now exposes every maximal run at O(n) additional retained span storage.
