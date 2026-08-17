# Choosing an API

Use ``StreakCalculator/consecutiveMatches(in:matching:)`` for runs in existing sequence order. Use `calculate(from:sortedBy:areEquivalent:areConsecutive:currentRunQualifies:longestTieBreak:)` for generic unsorted occurrences, or its `assumingSorted` counterpart to avoid sorting. Use `daily` for calendar-day habits and ``StreakCalculator/streak(_:date:granularity:options:)`` for day, week, month, or year periods.

Set ``StreakOptions/schedule`` to `weekdays` for scheduled days or `timesPerWeek` for weekly frequency. Set ``StreakOptions/allowedGapDays`` for grace days. Under `timesPerWeek`, span counts are qualifying weeks and boundaries are each week's first day.
