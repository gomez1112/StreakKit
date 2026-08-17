import Foundation
public enum StreakTieBreak: Sendable, Equatable { case earliest, latest }
public enum CurrentDailyStreakRule: Sendable, Equatable { case mustIncludeToday, todayOrYesterday, mostRecentRecordedDay }

/// Calendar streak configuration. Use explicit values for deterministic tests.
public struct StreakOptions: Sendable, Equatable {
    public var calendar: Calendar
    public var now: Date
    public var currentRule: CurrentDailyStreakRule
    public var includeFutureDays: Bool
    public var longestTieBreak: StreakTieBreak
    public var allowedGapDays: Int
    public var schedule: StreakSchedule
    public init(calendar: Calendar = .autoupdatingCurrent, now: Date = Date(), currentRule: CurrentDailyStreakRule = .todayOrYesterday, includeFutureDays: Bool = false, longestTieBreak: StreakTieBreak = .earliest, allowedGapDays: Int = 0, schedule: StreakSchedule = .daily) {
        self.calendar = calendar; self.now = now; self.currentRule = currentRule; self.includeFutureDays = includeFutureDays; self.longestTieBreak = longestTieBreak; self.allowedGapDays = max(0, allowedGapDays); self.schedule = schedule
    }
    /// Captures the autoupdating calendar and current instant on each access.
    public static var `default`: Self { .init() }
}
