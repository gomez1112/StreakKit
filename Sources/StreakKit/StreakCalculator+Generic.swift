extension StreakCalculator {
    /// `areInIncreasingOrder` must be a strict weak ordering (for example `<`, never `<=`).
    /// - Complexity: O(n log n) time and O(n) storage.
    public static func calculate<S: Sequence>(from occurrences: S, sortedBy order: (S.Element, S.Element) -> Bool, areEquivalent: (S.Element, S.Element) -> Bool, areConsecutive: (S.Element, S.Element) -> Bool, currentRunQualifies: (S.Element, S.Element) -> Bool = { _, _ in true }, longestTieBreak: StreakTieBreak = .earliest) -> StreakSummary<S.Element> {
        calculate(assumingSorted: occurrences.sorted(by: order), areEquivalent: areEquivalent, areConsecutive: areConsecutive, currentRunQualifies: currentRunQualifies, longestTieBreak: longestTieBreak)
    }

    /// - Complexity: O(n) time and O(n) storage.
    public static func calculate<S: Sequence>(assumingSorted occurrences: S, areEquivalent: (S.Element, S.Element) -> Bool, areConsecutive: (S.Element, S.Element) -> Bool, currentRunQualifies: (S.Element, S.Element) -> Bool = { _, _ in true }, longestTieBreak: StreakTieBreak = .earliest) -> StreakSummary<S.Element> {
        var values: [S.Element] = []
        for value in occurrences where values.last.map({ !areEquivalent($0, value) }) ?? true { values.append(value) }
        guard !values.isEmpty else { return .empty }
        var starts = 0; var spans: [StreakSpan<S.Element>] = []
        func append(_ end: Int) { spans.append(.init(validatedCount: end - starts + 1, start: values[starts], end: values[end])) }
        for index in values.indices.dropFirst() where !areConsecutive(values[index - 1], values[index]) { append(index - 1); starts = index }
        append(values.count - 1)
        let longest = spans.dropFirst().reduce(spans[0]) { best, candidate in candidate.count > best.count || (candidate.count == best.count && longestTieBreak == .latest) ? candidate : best }
        let last = spans[spans.count - 1]
        return .init(current: currentRunQualifies(last.start, last.end) ? last : nil, longest: longest, allSpans: spans)
    }
}
