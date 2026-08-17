/// Count-only results for predicate streaks in sequence order, unlike boundary-rich ``StreakSummary``.
public struct StreakCounts: Sendable, Equatable, Hashable, Codable {
    public let current: Int
    public let longest: Int
    public init(current: Int, longest: Int) { self.current = current; self.longest = longest }
}
