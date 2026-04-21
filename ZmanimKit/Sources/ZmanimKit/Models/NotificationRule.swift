import Foundation
import SwiftData

/// A user-configured alert: "Notify me N minutes before/after <zman>".
/// Scheduled daily as local `UNNotificationRequest`s by `NotificationScheduler`.
@Model
public final class NotificationRule {
    public var id: UUID
    public var kindRaw: String
    /// JSON-encoded `ZmanOpinion` so the opinion's associated values (degrees,
    /// minutes) survive CloudKit sync cleanly.
    public var opinionData: Data
    /// Seconds offset from the zman. Negative = before, positive = after.
    public var offsetSeconds: Int
    public var title: String
    public var body: String
    public var isEnabled: Bool
    public var createdAt: Date

    public init(
        kind: ZmanKind,
        opinion: ZmanOpinion,
        offsetSeconds: Int,
        title: String,
        body: String = "",
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.opinionData = (try? JSONEncoder().encode(opinion)) ?? Data()
        self.offsetSeconds = offsetSeconds
        self.title = title
        self.body = body
        self.isEnabled = isEnabled
        self.createdAt = .now
    }

    public var kind: ZmanKind {
        ZmanKind(rawValue: kindRaw) ?? .shkiatHachama
    }

    public var opinion: ZmanOpinion {
        (try? JSONDecoder().decode(ZmanOpinion.self, from: opinionData)) ?? .gra
    }
}
