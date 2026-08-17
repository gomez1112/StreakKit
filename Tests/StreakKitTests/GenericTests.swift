import Testing
@testable import StreakKit
@Suite("Generic occurrence streaks") struct GenericTests {
 @Test func randomizedAgreement() {
  var rng = LCRNG()
  for _ in 0..<100 { let input = (0..<50).map { _ in Int.random(in: 0..<30, using: &rng) }; let sorted = input.sorted(); let a = StreakCalculator.calculate(from: input, sortedBy: <, areEquivalent: ==, areConsecutive: { $1 == $0 + 1 }); let b = StreakCalculator.calculate(assumingSorted: sorted, areEquivalent: ==, areConsecutive: { $1 == $0 + 1 }); #expect(a == b) }
 }
 @Test func allRuns() { let r = StreakCalculator.calculate(from: [1,2,5,8,9], sortedBy: <, areEquivalent: ==, areConsecutive: { $1 == $0 + 1 }); #expect(r.allSpans.map(\.count) == [2,1,2]); #expect(r.allSpans.count == 3) }
}
