import Foundation

extension StreakCalculator {
    /// Calculates streaks at day, week, month, or year granularity.
    /// Week boundaries follow `options.calendar.firstWeekday`. For `.timesPerWeek`, counts and boundaries represent qualifying weeks.
    /// - Complexity: O(n log n) time and O(n) storage.
    public static func streak<S: Sequence>(_ events: S, date: KeyPath<S.Element, Date>, granularity: Calendar.Component, options: StreakOptions = .default) -> StreakSummary<Date> {
        streak(events, date: { $0[keyPath: date] }, matching: { _ in true }, granularity: granularity, options: options)
    }

    public static func daily<S: Sequence>(_ events: S, date: KeyPath<S.Element, Date>, options: StreakOptions = .default) -> StreakSummary<Date> {
        streak(events, date: date, granularity: .day, options: options)
    }
    public static func daily<S: Sequence>(_ events: S, date: KeyPath<S.Element, Date>, matching: KeyPath<S.Element, Bool>, options: StreakOptions = .default) -> StreakSummary<Date> {
        streak(events, date: { $0[keyPath: date] }, matching: { $0[keyPath: matching] }, granularity: .day, options: options)
    }
    /// - Complexity: O(n log n) time and O(n) storage.
    public static func daily<S: Sequence>(_ events: S, date: (S.Element) -> Date, matching: (S.Element) -> Bool, options: StreakOptions = .default) -> StreakSummary<Date> {
        streak(events, date: date, matching: matching, granularity: .day, options: options)
    }
    public static func daily<S: Sequence>(_ dates: S, options: StreakOptions = .default) -> StreakSummary<Date> where S.Element == Date {
        streak(dates, date: { $0 }, matching: { _ in true }, granularity: .day, options: options)
    }
    /// Input must be chronologically non-decreasing.
    /// - Complexity: O(n) time and O(n) storage.
    public static func daily<S: Sequence>(assumingSorted dates: S, options: StreakOptions = .default) -> StreakSummary<Date> where S.Element == Date {
        let calendar = options.calendar
        let values = dates.map { calendar.dateInterval(of: .day, for: $0)?.start ?? calendar.startOfDay(for: $0) }
        #if DEBUG
        if zip(values, values.dropFirst()).contains(where: { $0 > $1 }) { assertionFailure("daily(assumingSorted:) requires dates in non-decreasing chronological order after normalization.") }
        #endif
        return calculatePeriods(values, granularity: .day, options: options, assumingSorted: true)
    }

    private static func streak<S: Sequence>(_ events: S, date: (S.Element) -> Date, matching: (S.Element) -> Bool, granularity: Calendar.Component, options: StreakOptions) -> StreakSummary<Date> {
        guard [.day, .weekOfYear, .month, .year].contains(granularity) else {
            assertionFailure("Supported streak granularities are day, weekOfYear, month, and year.")
            return .empty
        }
        let calendar = options.calendar
        let periods = events.lazy.filter(matching).compactMap { calendar.dateInterval(of: granularity, for: date($0))?.start }
        return calculatePeriods(Array(periods), granularity: granularity, options: options, assumingSorted: false)
    }

    private static func calculatePeriods(_ raw: [Date], granularity: Calendar.Component, options: StreakOptions, assumingSorted: Bool) -> StreakSummary<Date> {
        let calendar = options.calendar
        let today = calendar.dateInterval(of: granularity, for: options.now)?.start ?? calendar.startOfDay(for: options.now)
        var periods = raw.filter { options.includeFutureDays || $0 <= today }
        if !assumingSorted { periods.sort() }
        if case let .timesPerWeek(threshold) = options.schedule, granularity == .day {
            guard threshold > 0 else { return .empty }
            let days = periods.reduce(into: [Date]()) { if $0.last != $1 { $0.append($1) } }
            var weeks: [(Date, Int)] = []
            for day in days {
                guard let week = calendar.dateInterval(of: .weekOfYear, for: day)?.start else { continue }
                if weeks.last?.0 == week { weeks[weeks.count - 1].1 += 1 } else { weeks.append((week, 1)) }
            }
            periods = weeks.filter { $0.1 >= threshold }.map(\.0)
            return genericPeriods(periods, component: .weekOfYear, options: options)
        }
        return genericPeriods(periods, component: granularity, options: options)
    }

    private static func genericPeriods(_ periods: [Date], component: Calendar.Component, options: StreakOptions) -> StreakSummary<Date> {
        let calendar = options.calendar
        let nowPeriod = calendar.dateInterval(of: component, for: options.now)?.start ?? calendar.startOfDay(for: options.now)
        return calculate(from: periods, sortedBy: <, areEquivalent: ==, areConsecutive: { previous, next in
            if component == .day, case let .weekdays(weekdays) = options.schedule {
                var cursor = previous; var missed = 0
                while let following = calendar.date(byAdding: .day, value: 1, to: cursor), following < next {
                    if weekdays.contains(calendar.component(.weekday, from: following)) { missed += 1 }
                    if missed > options.allowedGapDays { return false }
                    cursor = following
                }
                return calendar.dateComponents([.day], from: cursor, to: next).day == 1
            }
            guard let expected = calendar.date(byAdding: component, value: 1, to: previous) else { return false }
            if calendar.isDate(expected, equalTo: next, toGranularity: component) { return true }
            guard component == .day, options.allowedGapDays > 0 else { return false }
            let distance = calendar.dateComponents([.day], from: previous, to: next).day ?? Int.max
            return distance > 0 && distance <= options.allowedGapDays + 1
        }, currentRunQualifies: { start, end in qualifies(start: start, end: end, today: nowPeriod, component: component, options: options) }, longestTieBreak: options.longestTieBreak)
    }

    private static func qualifies(start: Date, end: Date, today: Date, component: Calendar.Component, options: StreakOptions) -> Bool {
        switch options.currentRule {
        case .mustIncludeToday: return start <= today && today <= end
        case .mostRecentRecordedDay: return true
        case .todayOrYesterday:
            if start <= today && today <= end { return true }
            guard let previous = options.calendar.date(byAdding: component, value: -1, to: today) else { return false }
            return options.calendar.isDate(end, equalTo: previous, toGranularity: component)
        }
    }
}
