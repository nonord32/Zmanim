import Foundation

/// One row in the user's "which zmanim do I see" list. Order matters — the
/// array index is the row position on the Today screen.
public struct ZmanDisplayConfig: Codable, Hashable, Sendable, Identifiable {
    public var kind: ZmanKind
    public var opinion: ZmanOpinion
    public var isEnabled: Bool

    public var id: String { "\(kind.rawValue)#\(opinion)" }

    public init(kind: ZmanKind, opinion: ZmanOpinion, isEnabled: Bool = true) {
        self.kind = kind
        self.opinion = opinion
        self.isEnabled = isEnabled
    }

    public static var defaults: [ZmanDisplayConfig] {
        ZmanOpinion.defaultDisplay.map { ZmanDisplayConfig(kind: $0.0, opinion: $0.1) }
    }
}
