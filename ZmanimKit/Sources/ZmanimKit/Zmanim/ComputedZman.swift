import Foundation

/// A single zman computed for a specific date at a specific location.
public struct ComputedZman: Identifiable, Hashable, Sendable {
    public let kind: ZmanKind
    public let opinion: ZmanOpinion
    public let date: Date

    public var id: String {
        "\(kind.rawValue)#\(opinion)#\(date.timeIntervalSince1970)"
    }

    public init(kind: ZmanKind, opinion: ZmanOpinion, date: Date) {
        self.kind = kind
        self.opinion = opinion
        self.date = date
    }
}

public extension Array where Element == ComputedZman {
    /// Returns the next zman strictly after `reference`, or nil if today is done.
    func next(after reference: Date = .now) -> ComputedZman? {
        self.filter { $0.date > reference }
            .min(by: { $0.date < $1.date })
    }

    /// Returns the most recent zman at or before `reference`.
    func previous(at reference: Date = .now) -> ComputedZman? {
        self.filter { $0.date <= reference }
            .max(by: { $0.date < $1.date })
    }
}
