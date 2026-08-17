import Foundation
import Testing
@testable import StreakKit
@Suite("Granularity") struct GranularityTests {
 struct Event { let at: Date }
 @Test(arguments: [1,2]) func weekStarts(firstWeekday: Int) { let c = calendar(firstWeekday: firstWeekday); let es = [Event(at: date(2026,7,5,in:c)), Event(at: date(2026,7,12,in:c))]; let r = StreakCalculator.streak(es, date: \.at, granularity: .weekOfYear, options: options(c, now: es.last!.at, rule: .mostRecentRecordedDay)); #expect(r.longestCount == 2) }
 @Test(arguments: [Calendar.Component.month, .year]) func larger(component: Calendar.Component) { let c = calendar(); let es = [Event(at: date(2025,12,1,in:c)), Event(at: date(2026,1,1,in:c))]; let r = StreakCalculator.streak(es, date: \.at, granularity: component, options: options(c, now: es.last!.at, rule: .mostRecentRecordedDay)); #expect(r.longestCount >= 1) }
}
