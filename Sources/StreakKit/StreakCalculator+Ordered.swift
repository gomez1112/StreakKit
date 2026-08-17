/// Generic streak calculation utilities.
public enum StreakCalculator {}
extension StreakCalculator {
    /// - Complexity: O(n) time and O(1) storage.
    public static func consecutiveMatches<S: Sequence>(in values: S, matching predicate: (S.Element) throws -> Bool) rethrows -> StreakCounts {
        var current = 0, longest = 0
        for value in values { if try predicate(value) { current += 1; longest = max(longest, current) } else { current = 0 } }
        return .init(current: current, longest: longest)
    }
}
