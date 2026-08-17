import Foundation
import Testing
@testable import StreakKit
@Suite("Result values") struct ResultTests {
 @Test func invalidSpan() { #expect(StreakSpan(count: 0, start: 1, end: 1) == nil); #expect(StreakSpan(count: -1, start: 1, end: 1) == nil) }
 @Test func codable() throws { let span = try #require(StreakSpan(count: 2, start: 1, end: 2)); let summary = StreakSummary(current: span, longest: span, allSpans: [span]); let encoder = JSONEncoder(); let decoder = JSONDecoder(); #expect(try decoder.decode(StreakSpan<Int>.self, from: encoder.encode(span)) == span); #expect(try decoder.decode(StreakSummary<Int>.self, from: encoder.encode(summary)) == summary); let counts = StreakCounts(current: 1, longest: 2); #expect(try decoder.decode(StreakCounts.self, from: encoder.encode(counts)) == counts) }
}
