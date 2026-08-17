import Foundation
import Testing
@testable import StreakKit
@Suite("Schedules and grace") struct ScheduleTests {
 @Test(arguments: [(0,2),(1,3),(2,3)]) func grace(gaps: Int, expected: Int) { let c = calendar(); let ds = [date(2026,1,1,in:c),date(2026,1,3,in:c),date(2026,1,4,in:c)]; let r = StreakCalculator.daily(ds, options: options(c, now: ds.last!, rule: .mostRecentRecordedDay, gaps: gaps)); #expect(r.longestCount == expected) }
 @Test func weekdayWeekend() { let c = calendar(); let ds = [date(2026,7,3,in:c),date(2026,7,6,in:c)]; let r = StreakCalculator.daily(ds, options: options(c, now: ds.last!, schedule: .weekdays([2,3,4,5,6]))); #expect(r.longestCount == 2) }
 @Test func frequency() { let c = calendar(firstWeekday: 2); let ds = [date(2026,7,6,in:c),date(2026,7,7,in:c),date(2026,7,13,in:c)]; let r = StreakCalculator.daily(ds, options: options(c, now: ds.last!, rule: .mostRecentRecordedDay, schedule: .timesPerWeek(2))); #expect(r.longestCount == 1); #expect(r.allSpans.count == 1) }
}
