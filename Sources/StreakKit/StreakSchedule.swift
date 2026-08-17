/// Defines the days or weekly frequency on which activity is expected.
public enum StreakSchedule: Sendable, Equatable {
    case daily
    /// Calendar weekday numbers (`1` is Sunday).
    case weekdays(Set<Int>)
    /// A week succeeds after this many distinct successful days; span counts are weeks.
    case timesPerWeek(Int)
}
