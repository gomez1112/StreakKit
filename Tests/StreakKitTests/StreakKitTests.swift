import Foundation
import Testing
@testable import StreakKit

@Suite("Ordered predicate streaks")
struct OrderedPredicateStreakTests {
    @Test("Empty input returns zero counts")
    func emptyInput() {
        let result = StreakCalculator.consecutiveMatches(in: [Int]()) { _ in true }
        #expect(result == .init(current: 0, longest: 0))
    }

    @Test("Current is the run at the end")
    func endingRun() {
        let result = StreakCalculator.consecutiveMatches(
            in: [true, true, false, true, true, true],
            matching: { $0 }
        )
        #expect(result.current == 3)
        #expect(result.longest == 3)
    }

    @Test("Longest can occur before the current run")
    func earlierLongestRun() {
        let result = StreakCalculator.consecutiveMatches(
            in: [1, 2, 3, 0, 1],
            matching: { $0 > 0 }
        )
        #expect(result.current == 1)
        #expect(result.longest == 3)
    }

    @Test("Throwing predicates propagate errors")
    func throwingPredicate() {
        enum SampleError: Error { case rejected }

        #expect(throws: SampleError.self) {
            try StreakCalculator.consecutiveMatches(in: [1, 2, 3]) { value in
                if value == 2 { throw SampleError.rejected }
                return true
            }
        }
    }
}

@Suite("Generic occurrence streaks")
struct GenericOccurrenceStreakTests {
    @Test("Unsorted input is sorted and deduplicated")
    func sortingAndDeduplication() {
        let result = StreakCalculator.calculate(
            from: [8, 2, 3, 4, 8, 9, 10, 15],
            sortedBy: <,
            areEquivalent: ==,
            areConsecutive: { $1 == $0 + 1 }
        )

        #expect(result.current == .init(count: 1, start: 15, end: 15))
        #expect(result.longest == .init(count: 3, start: 2, end: 4))
    }

    @Test("Latest tie break selects the newest maximum run")
    func latestTieBreak() {
        let result = StreakCalculator.calculate(
            from: [2, 3, 4, 8, 9, 10],
            sortedBy: <,
            areEquivalent: ==,
            areConsecutive: { $1 == $0 + 1 },
            longestTieBreak: .latest
        )

        #expect(result.longest == .init(count: 3, start: 8, end: 10))
    }

    @Test("Current run can be rejected")
    func currentQualification() {
        let result = StreakCalculator.calculate(
            from: [1, 2, 5, 6],
            sortedBy: <,
            areEquivalent: ==,
            areConsecutive: { $1 == $0 + 1 },
            currentRunQualifies: { _, end in end == 5 }
        )

        #expect(result.current == nil)
        #expect(result.longestCount == 2)
    }

    @Test("Assuming-sorted variant matches sorting variant")
    func assumingSortedMatches() {
        let sorted = [1, 1, 2, 3, 7, 8]

        let regular = StreakCalculator.calculate(
            from: sorted,
            sortedBy: <,
            areEquivalent: ==,
            areConsecutive: { $1 == $0 + 1 }
        )
        let optimized = StreakCalculator.calculate(
            assumingSorted: sorted,
            areEquivalent: ==,
            areConsecutive: { $1 == $0 + 1 }
        )

        #expect(regular == optimized)
    }

    @Test("Empty generic input has no spans")
    func emptyGenericInput() {
        let result = StreakCalculator.calculate(
            from: [Int](),
            sortedBy: <,
            areEquivalent: ==,
            areConsecutive: { $1 == $0 + 1 }
        )

        #expect(result == .empty)
    }
}

@Suite("Daily streaks")
struct DailyStreakTests {
    struct Event: Sendable {
        let date: Date
        let succeeded: Bool
    }

    private let calendar = makeCalendar()

    @Test("Key-path overload counts successful event days")
    func keyPathOverload() {
        let now = date(2026, 7, 22, hour: 12)
        let events = [
            Event(date: date(2026, 7, 19, hour: 8), succeeded: true),
            Event(date: date(2026, 7, 20, hour: 18), succeeded: true),
            Event(date: date(2026, 7, 21, hour: 9), succeeded: true)
        ]

        let result = StreakCalculator.daily(
            events,
            date: \.date,
            calendar: calendar,
            now: now
        )

        #expect(result.currentCount == 3)
        #expect(result.longestCount == 3)
    }

    @Test("Boolean key path excludes failed records")
    func successKeyPath() {
        let now = date(2026, 7, 22, hour: 12)
        let events = [
            Event(date: date(2026, 7, 20), succeeded: true),
            Event(date: date(2026, 7, 21), succeeded: false),
            Event(date: date(2026, 7, 22), succeeded: true)
        ]

        let result = StreakCalculator.daily(
            events,
            date: \.date,
            matching: \.succeeded,
            calendar: calendar,
            now: now
        )

        #expect(result.currentCount == 1)
        #expect(result.longestCount == 1)
    }

    @Test("Multiple completions on one day count once")
    func duplicateDays() {
        let now = date(2026, 7, 22, hour: 20)
        let dates = [
            date(2026, 7, 21, hour: 8),
            date(2026, 7, 21, hour: 19),
            date(2026, 7, 22, hour: 7)
        ]

        let result = StreakCalculator.daily(dates, calendar: calendar, now: now)
        #expect(result.currentCount == 2)
        #expect(result.longestCount == 2)
    }

    @Test("Today-or-yesterday keeps yesterday alive")
    func yesterdayRemainsCurrent() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [date(2026, 7, 19), date(2026, 7, 20), date(2026, 7, 21)]

        let result = StreakCalculator.daily(
            dates,
            calendar: calendar,
            now: now,
            currentRule: .todayOrYesterday
        )

        #expect(result.currentCount == 3)
    }

    @Test("Must-include-today rejects a streak ending yesterday")
    func mustIncludeToday() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [date(2026, 7, 20), date(2026, 7, 21)]

        let result = StreakCalculator.daily(
            dates,
            calendar: calendar,
            now: now,
            currentRule: .mustIncludeToday
        )

        #expect(result.current == nil)
        #expect(result.longestCount == 2)
    }

    @Test("Stale runs remain historical but are not current")
    func staleRun() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [date(2026, 7, 17), date(2026, 7, 18), date(2026, 7, 19)]

        let result = StreakCalculator.daily(dates, calendar: calendar, now: now)
        #expect(result.currentCount == 0)
        #expect(result.longestCount == 3)
    }

    @Test("Future extension does not erase a run containing today")
    func futureExtensionSemanticFix() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [
            date(2026, 7, 21),
            date(2026, 7, 22),
            date(2026, 7, 23)
        ]

        let result = StreakCalculator.daily(
            dates,
            calendar: calendar,
            now: now,
            includeFutureDays: true
        )

        #expect(result.currentCount == 3)
        #expect(result.current?.start == calendar.startOfDay(for: dates[0]))
        #expect(result.current?.end == calendar.startOfDay(for: dates[2]))
    }

    @Test("Future-only run does not qualify under today-or-yesterday")
    func futureOnlyRun() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [date(2026, 7, 23), date(2026, 7, 24)]

        let result = StreakCalculator.daily(
            dates,
            calendar: calendar,
            now: now,
            includeFutureDays: true
        )

        #expect(result.current == nil)
        #expect(result.longestCount == 2)
    }

    @Test("Most-recent-recorded-day returns an old run")
    func mostRecentHistoricalRun() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [date(2026, 1, 1), date(2026, 1, 2)]

        let result = StreakCalculator.daily(
            dates,
            calendar: calendar,
            now: now,
            currentRule: .mostRecentRecordedDay
        )

        #expect(result.currentCount == 2)
    }

    @Test("Future days are ignored by default")
    func ignoresFutureByDefault() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [date(2026, 7, 22), date(2026, 7, 23)]

        let result = StreakCalculator.daily(dates, calendar: calendar, now: now)
        #expect(result.currentCount == 1)
        #expect(result.longestCount == 1)
    }

    @Test("Assuming-sorted daily overload matches regular daily overload")
    func sortedDailyOverload() {
        let now = date(2026, 7, 22, hour: 12)
        let dates = [
            date(2026, 7, 19, hour: 8),
            date(2026, 7, 20, hour: 8),
            date(2026, 7, 20, hour: 17),
            date(2026, 7, 21, hour: 8)
        ]

        let regular = StreakCalculator.daily(dates, calendar: calendar, now: now)
        let optimized = StreakCalculator.daily(
            assumingSorted: dates,
            calendar: calendar,
            now: now
        )

        #expect(regular == optimized)
    }

    @Test("Calendar arithmetic handles spring DST transition")
    func springDST() {
        let dates = [
            date(2026, 3, 7, hour: 23),
            date(2026, 3, 8, hour: 23),
            date(2026, 3, 9, hour: 23)
        ]
        let now = date(2026, 3, 9, hour: 23)

        let result = StreakCalculator.daily(dates, calendar: calendar, now: now)
        #expect(result.currentCount == 3)
        #expect(result.longestCount == 3)
    }

    @Test("Calendar arithmetic handles fall DST transition")
    func fallDST() {
        let dates = [
            date(2026, 10, 31, hour: 23),
            date(2026, 11, 1, hour: 23),
            date(2026, 11, 2, hour: 23)
        ]
        let now = date(2026, 11, 2, hour: 23)

        let result = StreakCalculator.daily(dates, calendar: calendar, now: now)
        #expect(result.currentCount == 3)
        #expect(result.longestCount == 3)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 12
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}

private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
}
