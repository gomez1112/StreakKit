# Calendars, time zones, and DST

StreakKit normalizes events with `Calendar.dateInterval(of:for:)` and compares periods with calendar arithmetic, never fixed 86,400-second intervals. This handles spring/fall DST, São Paulo's historical missing midnight, leap days, and variable Hebrew and Umm al-Qura month lengths.

Apia skipped December 30, 2011. Its calendar advances directly from December 29 to December 31, so StreakKit treats those civil dates as consecutive. Week periods depend on the supplied calendar's `firstWeekday`; set it explicitly for deterministic week boundaries.
