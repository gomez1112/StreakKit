import Foundation
import Testing
@testable import StreakKit
@Suite("Calendar edge cases") struct CalendarTests {
 @Test func randomizedDailyMatchesNaiveReference() {
  let c = calendar(); let origin = date(2026,1,1,in:c); var rng = LCRNG()
  for _ in 0..<100 {
   let input = (0..<60).compactMap { _ -> Date? in
    guard Bool.random(using: &rng) else { return nil }
    return c.date(byAdding: .day, value: Int.random(in: 0..<40, using: &rng), to: origin)
   }.shuffled(using: &rng)
   let normalized = Array(Set(input.map { c.startOfDay(for: $0) })).sorted()
   var naive: [Int] = []; var run = 0; var previous: Date?
   for day in normalized {
    if let previous, let expected = c.date(byAdding: .day, value: 1, to: previous), c.isDate(expected, inSameDayAs: day) { run += 1 }
    else { if run > 0 { naive.append(run) }; run = 1 }
    previous = day
   }
   if run > 0 { naive.append(run) }
   let result = StreakCalculator.daily(input, options: options(c, now: c.date(byAdding: .day, value: 50, to: origin)!, rule: .mostRecentRecordedDay))
   #expect(result.allSpans.map(\.count) == naive)
  }
 }
 @Test(arguments: [("America/Sao_Paulo", 2018, 11, 3, 3), ("Pacific/Apia", 2011, 12, 29, 2)]) func transitions(zone: String, year: Int, month: Int, first: Int, count: Int) throws {
  let c = calendar(zone: zone); let dates = count == 3 ? [date(year,month,first,in:c),date(year,month,first+1,in:c),date(year,month,first+2,in:c)] : [date(year,month,first,in:c),date(year,month,31,in:c)]
  let result = StreakCalculator.daily(dates, options: options(c, now: dates.last!, rule: .mustIncludeToday)); #expect(result.longestCount == dates.count)
 }
 @Test(arguments: [Calendar.Identifier.islamicUmmAlQura, .hebrew]) func nonGregorian(id: Calendar.Identifier) { let c = calendar(id); let start = Date(timeIntervalSince1970: 1_800_000_000); let dates = (0..<4).compactMap { c.date(byAdding: .day, value: $0, to: start) }; #expect(StreakCalculator.daily(dates, options: options(c, now: dates.last!)).longestCount == 4) }
 @Test func leapDay() { let c = calendar(); let dates = [date(2028,2,28,in:c),date(2028,2,29,in:c),date(2028,3,1,in:c)]; #expect(StreakCalculator.daily(dates, options: options(c, now: dates.last!)).longestCount == 3) }
 @Test func validSortedInput() { let c = calendar(); let dates = [date(2028,1,1,in:c),date(2028,1,2,in:c)]; #expect(StreakCalculator.daily(assumingSorted: dates, options: options(c, now: dates.last!)).longestCount == 2) }
}
