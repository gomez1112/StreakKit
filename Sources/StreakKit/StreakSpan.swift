/// A contiguous streak and its inclusive boundaries.
public struct StreakSpan<Value> {
    public let count: Int
    public let start: Value
    public let end: Value

    /// Creates a span, or returns `nil` when `count` is not positive.
    public init?(count: Int, start: Value, end: Value) {
        guard count > 0 else { return nil }
        self.count = count; self.start = start; self.end = end
    }

    internal init(validatedCount count: Int, start: Value, end: Value) {
        assert(count > 0)
        self.count = count; self.start = start; self.end = end
    }
}
extension StreakSpan: Sendable where Value: Sendable {}
extension StreakSpan: Equatable where Value: Equatable {}
extension StreakSpan: Hashable where Value: Hashable {}
extension StreakSpan: Codable where Value: Codable {}
