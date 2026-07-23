import Foundation

/// Determines which streak wins when multiple runs share the maximum length.
public enum StreakTieBreak: Sendable, Equatable {
    /// Retains the oldest maximum-length run.
    case earliest

    /// Retains the newest maximum-length run.
    case latest
}

/// The rules used to determine whether a daily streak is currently active.
public enum CurrentDailyStreakRule: Sendable, Equatable {
    /// The current run must contain today.
    case mustIncludeToday

    /// The current run may contain today or end yesterday.
    ///
    /// This is typically the most natural rule for habit tracking because the
    /// user still has the remainder of today to complete the activity.
    case todayOrYesterday

    /// Always treats the newest recorded run as current, regardless of age.
    case mostRecentRecordedDay
}

/// Count-only results for streaks evaluated in an existing sequence order.
public struct StreakCounts: Sendable, Equatable {
    /// The matching run at the end of the input sequence.
    public let current: Int

    /// The longest matching run anywhere in the input sequence.
    public let longest: Int

    public init(current: Int, longest: Int) {
        self.current = current
        self.longest = longest
    }
}

/// A contiguous streak and its inclusive boundaries.
public struct StreakSpan<Value> {
    /// The number of unique occurrences in the streak.
    public let count: Int

    /// The first occurrence in the streak.
    public let start: Value

    /// The final occurrence in the streak.
    public let end: Value

    public init(count: Int, start: Value, end: Value) {
        precondition(count > 0, "A streak span must contain at least one value.")
        self.count = count
        self.start = start
        self.end = end
    }
}

extension StreakSpan: Sendable where Value: Sendable {}
extension StreakSpan: Equatable where Value: Equatable {}

/// The current and longest streaks for occurrence-based calculations.
public struct StreakSummary<Value> {
    /// The latest run when it satisfies the configured current-run rule.
    public let current: StreakSpan<Value>?

    /// The longest run found in the input.
    public let longest: StreakSpan<Value>?

    /// The current streak length, or zero when no run qualifies as current.
    public var currentCount: Int { current?.count ?? 0 }

    /// The longest streak length, or zero when the input is empty.
    public var longestCount: Int { longest?.count ?? 0 }

    public init(current: StreakSpan<Value>?, longest: StreakSpan<Value>?) {
        self.current = current
        self.longest = longest
    }

    /// An empty result containing no current or longest streak.
    public static var empty: Self {
        .init(current: nil, longest: nil)
    }
}

extension StreakSummary: Sendable where Value: Sendable {}
extension StreakSummary: Equatable where Value: Equatable {}

/// Generic utilities for calculating ordered, occurrence-based, and daily streaks.
public enum StreakCalculator {
    // MARK: Ordered values

    /// Counts consecutive values matching a predicate in the sequence's existing order.
    ///
    /// - Parameters:
    ///   - values: Values in the order that should define the streak.
    ///   - predicate: Returns `true` when an element belongs to a streak.
    /// - Returns: Current and longest streak counts.
    /// - Complexity: O(n) time and O(1) additional storage.
    public static func consecutiveMatches<S: Sequence>(
        in values: S,
        matching predicate: (S.Element) throws -> Bool
    ) rethrows -> StreakCounts {
        var runningCount = 0
        var longestCount = 0

        for value in values {
            if try predicate(value) {
                runningCount += 1
                longestCount = max(longestCount, runningCount)
            } else {
                runningCount = 0
            }
        }

        return .init(current: runningCount, longest: longestCount)
    }

    // MARK: Unsorted generic occurrences

    /// Calculates streaks from occurrences that may be unsorted.
    ///
    /// The method sorts the input, removes adjacent equivalent occurrences,
    /// divides the unique values into maximal runs, and returns the latest
    /// qualifying run together with the longest run.
    ///
    /// `areInIncreasingOrder` and `areEquivalent` must be mutually consistent:
    /// equivalent values must become adjacent after sorting.
    ///
    /// - Complexity: O(n log n) time and O(n) storage.
    public static func calculate<S: Sequence>(
        from occurrences: S,
        sortedBy areInIncreasingOrder: (S.Element, S.Element) -> Bool,
        areEquivalent: (S.Element, S.Element) -> Bool,
        areConsecutive: (S.Element, S.Element) -> Bool,
        currentRunQualifies: (_ start: S.Element, _ end: S.Element) -> Bool = { _, _ in true },
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<S.Element> {
        calculate(
            assumingSorted: occurrences.sorted(by: areInIncreasingOrder),
            areEquivalent: areEquivalent,
            areConsecutive: areConsecutive,
            currentRunQualifies: currentRunQualifies,
            longestTieBreak: longestTieBreak
        )
    }

    // MARK: Pre-sorted generic occurrences

    /// Calculates streaks from occurrences already sorted in ascending order.
    ///
    /// Use this overload when the data source has already sorted values, such
    /// as a SwiftData fetch using a `SortDescriptor`.
    ///
    /// The caller must guarantee that occurrences are sorted and equivalent
    /// occurrences are adjacent. Incorrect ordering produces incorrect results.
    ///
    /// - Complexity: O(n) time and O(n) storage for deduplication.
    public static func calculate<S: Sequence>(
        assumingSorted occurrences: S,
        areEquivalent: (S.Element, S.Element) -> Bool,
        areConsecutive: (S.Element, S.Element) -> Bool,
        currentRunQualifies: (_ start: S.Element, _ end: S.Element) -> Bool = { _, _ in true },
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<S.Element> {
        var uniqueOccurrences: [S.Element] = []
        uniqueOccurrences.reserveCapacity(occurrences.underestimatedCount)

        for occurrence in occurrences {
            if let previous = uniqueOccurrences.last,
               areEquivalent(previous, occurrence) {
                continue
            }

            uniqueOccurrences.append(occurrence)
        }

        guard !uniqueOccurrences.isEmpty else {
            return .empty
        }

        var currentRunStartIndex = 0

        // Nonempty input guarantees an initial one-element run at index zero.
        var longestRunStartIndex = 0
        var longestRunEndIndex = 0

        func considerRun(endingAt endIndex: Int) {
            let candidateCount = endIndex - currentRunStartIndex + 1
            let longestCount = longestRunEndIndex - longestRunStartIndex + 1
            let winsTie = candidateCount == longestCount && longestTieBreak == .latest

            if candidateCount > longestCount || winsTie {
                longestRunStartIndex = currentRunStartIndex
                longestRunEndIndex = endIndex
            }
        }

        if uniqueOccurrences.count > 1 {
            for index in 1..<uniqueOccurrences.count {
                let previous = uniqueOccurrences[index - 1]
                let next = uniqueOccurrences[index]

                if !areConsecutive(previous, next) {
                    considerRun(endingAt: index - 1)
                    currentRunStartIndex = index
                }
            }
        }

        let lastIndex = uniqueOccurrences.count - 1
        considerRun(endingAt: lastIndex)

        let longest = StreakSpan(
            count: longestRunEndIndex - longestRunStartIndex + 1,
            start: uniqueOccurrences[longestRunStartIndex],
            end: uniqueOccurrences[longestRunEndIndex]
        )

        let currentRunStart = uniqueOccurrences[currentRunStartIndex]
        let currentRunEnd = uniqueOccurrences[lastIndex]
        let current: StreakSpan<S.Element>?

        if currentRunQualifies(currentRunStart, currentRunEnd) {
            current = StreakSpan(
                count: lastIndex - currentRunStartIndex + 1,
                start: currentRunStart,
                end: currentRunEnd
            )
        } else {
            current = nil
        }

        return .init(current: current, longest: longest)
    }

    // MARK: Daily events using key paths

    /// Calculates a daily streak where every event represents a success.
    ///
    /// Use this overload when an event exposes a direct `Date` property.
    public static func daily<S: Sequence>(
        _ events: S,
        date dateKeyPath: KeyPath<S.Element, Date>,
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now,
        currentRule: CurrentDailyStreakRule = .todayOrYesterday,
        includeFutureDays: Bool = false,
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<Date> {
        daily(
            events,
            date: { $0[keyPath: dateKeyPath] },
            matching: { _ in true },
            calendar: calendar,
            now: now,
            currentRule: currentRule,
            includeFutureDays: includeFutureDays,
            longestTieBreak: longestTieBreak
        )
    }

    /// Calculates a daily streak using key paths for both date and success.
    ///
    /// Use this overload when records may represent successful or unsuccessful events.
    public static func daily<S: Sequence>(
        _ events: S,
        date dateKeyPath: KeyPath<S.Element, Date>,
        matching successKeyPath: KeyPath<S.Element, Bool>,
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now,
        currentRule: CurrentDailyStreakRule = .todayOrYesterday,
        includeFutureDays: Bool = false,
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<Date> {
        daily(
            events,
            date: { $0[keyPath: dateKeyPath] },
            matching: { $0[keyPath: successKeyPath] },
            calendar: calendar,
            now: now,
            currentRule: currentRule,
            includeFutureDays: includeFutureDays,
            longestTieBreak: longestTieBreak
        )
    }

    // MARK: Fully flexible daily events

    /// Calculates a calendar-day streak using custom date and success extraction.
    ///
    /// The implementation handles unsorted input, duplicate events on one day,
    /// future records, custom calendars, time zones, and daylight-saving changes.
    /// Returned span boundaries are normalized with `Calendar.startOfDay(for:)`.
    public static func daily<S: Sequence>(
        _ events: S,
        date: (S.Element) -> Date,
        matching isSuccessful: (S.Element) -> Bool,
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now,
        currentRule: CurrentDailyStreakRule = .todayOrYesterday,
        includeFutureDays: Bool = false,
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<Date> {
        let today = calendar.startOfDay(for: now)

        let successfulDays = events.lazy
            .filter(isSuccessful)
            .map { calendar.startOfDay(for: date($0)) }
            .filter { includeFutureDays || $0 <= today }

        return calculate(
            from: successfulDays,
            sortedBy: <,
            areEquivalent: ==,
            areConsecutive: { previous, next in
                calendar.date(byAdding: .day, value: 1, to: previous) == next
            },
            currentRunQualifies: { start, end in
                qualifiesAsCurrent(
                    start: start,
                    end: end,
                    today: today,
                    calendar: calendar,
                    rule: currentRule
                )
            },
            longestTieBreak: longestTieBreak
        )
    }

    // MARK: Daily dates

    /// Calculates a daily streak from a sequence containing dates directly.
    public static func daily<S: Sequence>(
        _ dates: S,
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now,
        currentRule: CurrentDailyStreakRule = .todayOrYesterday,
        includeFutureDays: Bool = false,
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<Date> where S.Element == Date {
        daily(
            dates,
            date: { $0 },
            matching: { _ in true },
            calendar: calendar,
            now: now,
            currentRule: currentRule,
            includeFutureDays: includeFutureDays,
            longestTieBreak: longestTieBreak
        )
    }

    /// Calculates a daily streak from dates already sorted in ascending order.
    ///
    /// Normalization can theoretically alter ordering if the caller mixes dates
    /// interpreted under incompatible assumptions. In normal use, all dates must
    /// belong to the supplied calendar and its time zone.
    public static func daily<S: Sequence>(
        assumingSorted dates: S,
        calendar: Calendar = .autoupdatingCurrent,
        now: Date = .now,
        currentRule: CurrentDailyStreakRule = .todayOrYesterday,
        includeFutureDays: Bool = false,
        longestTieBreak: StreakTieBreak = .earliest
    ) -> StreakSummary<Date> where S.Element == Date {
        let today = calendar.startOfDay(for: now)
        let normalizedDays = dates.lazy
            .map { calendar.startOfDay(for: $0) }
            .filter { includeFutureDays || $0 <= today }

        return calculate(
            assumingSorted: normalizedDays,
            areEquivalent: ==,
            areConsecutive: { previous, next in
                calendar.date(byAdding: .day, value: 1, to: previous) == next
            },
            currentRunQualifies: { start, end in
                qualifiesAsCurrent(
                    start: start,
                    end: end,
                    today: today,
                    calendar: calendar,
                    rule: currentRule
                )
            },
            longestTieBreak: longestTieBreak
        )
    }

    private static func qualifiesAsCurrent(
        start: Date,
        end: Date,
        today: Date,
        calendar: Calendar,
        rule: CurrentDailyStreakRule
    ) -> Bool {
        switch rule {
        case .mustIncludeToday:
            return start <= today && today <= end

        case .todayOrYesterday:
            if start <= today && today <= end {
                return true
            }

            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                return false
            }

            return end == yesterday

        case .mostRecentRecordedDay:
            return true
        }
    }
}
