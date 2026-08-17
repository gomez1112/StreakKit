import Testing
@testable import StreakKit
@Suite("Ordered predicate streaks") struct OrderedTests {
 @Test func counts() { #expect(StreakCalculator.consecutiveMatches(in: [true,true,false,true]) { $0 } == .init(current: 1, longest: 2)) }
 @Test func empty() { #expect(StreakCalculator.consecutiveMatches(in: [Int]()) { _ in true } == .init(current: 0, longest: 0)) }
}
