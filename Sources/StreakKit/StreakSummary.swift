/// Boundary-rich results for occurrence calculations, unlike count-only ``StreakCounts``.
public struct StreakSummary<Value> {
    public let current: StreakSpan<Value>?
    public let longest: StreakSpan<Value>?
    /// Every maximal run, ordered from earliest to latest.
    public let allSpans: [StreakSpan<Value>]
    public var currentCount: Int { current?.count ?? 0 }
    public var longestCount: Int { longest?.count ?? 0 }
    public init(current: StreakSpan<Value>?, longest: StreakSpan<Value>?, allSpans: [StreakSpan<Value>] = []) {
        self.current = current; self.longest = longest; self.allSpans = allSpans
    }
    public static var empty: Self { .init(current: nil, longest: nil) }
}
extension StreakSummary: Sendable where Value: Sendable {}
extension StreakSummary: Equatable where Value: Equatable {}
extension StreakSummary: Hashable where Value: Hashable {}
extension StreakSummary: Codable where Value: Codable {}
