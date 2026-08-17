import Foundation
@testable import StreakKit

func calendar(_ identifier: Calendar.Identifier = .gregorian, zone: String = "UTC", firstWeekday: Int? = nil) -> Calendar {
    var value = Calendar(identifier: identifier); value.locale = Locale(identifier: "en_US_POSIX")
    value.timeZone = TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0)!
    if let firstWeekday { value.firstWeekday = firstWeekday }
    return value
}
func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12, in calendar: Calendar = calendar()) -> Date {
    calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}
func options(_ calendar: Calendar, now: Date, rule: CurrentDailyStreakRule = .todayOrYesterday, gaps: Int = 0, schedule: StreakSchedule = .daily) -> StreakOptions {
    .init(calendar: calendar, now: now, currentRule: rule, allowedGapDays: gaps, schedule: schedule)
}
struct LCRNG: RandomNumberGenerator { var state: UInt64 = 0x12345678; mutating func next() -> UInt64 { state = 6364136223846793005 &* state &+ 1; return state } }
