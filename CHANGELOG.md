# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This project uses Semantic Versioning.

## [2.0.0] - 2026-08-17

### Added
- `StreakOptions`, grace days, weekday and times-per-week schedules.
- Day, week, month, and year `streak` granularity.
- `allSpans`, `Hashable`, and `Codable` result support.
- Linux/macOS CI, DocC documentation, and expanded calendar/property tests.

### Changed
- **Breaking:** Every `daily` overload replaces `calendar`, `now`, `currentRule`, `includeFutureDays`, and `longestTieBreak` parameters with `options: StreakOptions = .default`.
- **Breaking:** `StreakSpan.init(count:start:end:)` is failable.
- **Breaking:** `StreakSummary` stores `allSpans`; its initializer adds an optional `allSpans` argument.
- Daily span normalization uses period intervals and calendar-aware same-period comparison.
- Deployment floors are iOS 13, macOS 10.15, watchOS 6, tvOS 13, and visionOS 1.

[2.0.0]: https://github.com/gomez1112/StreakKit/compare/v1.0.0...v2.0.0
