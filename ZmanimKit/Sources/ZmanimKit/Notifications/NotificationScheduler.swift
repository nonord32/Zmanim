import Foundation
import UserNotifications

/// Schedules local notifications for every enabled `NotificationRule` across
/// the next `horizonDays` days. Re-runs on: app launch, location change,
/// settings change, and daily `BGAppRefreshTask`.
public struct NotificationScheduler: Sendable {

    public let horizonDays: Int
    public let center: UNUserNotificationCenter
    public let engine: ZmanimEngine

    public init(
        horizonDays: Int = 14,
        center: UNUserNotificationCenter = .current(),
        engine: ZmanimEngine = ZmanimEngine()
    ) {
        self.horizonDays = horizonDays
        self.center = center
        self.engine = engine
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Rebuild the pending notification set. Removes everything we scheduled
    /// (identified by prefix) and replaces with fresh requests.
    public func reschedule(
        rules: [NotificationRule],
        location: ResolvedLocation,
        now: Date = .now
    ) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
                          .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ours)

        let calendar = Calendar(identifier: .gregorian)
        for dayOffset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            for rule in rules where rule.isEnabled {
                guard let zmanDate = engine.zman(
                    kind: rule.kind,
                    opinion: rule.opinion,
                    date: day,
                    at: location
                ) else { continue }
                let fireDate = zmanDate.addingTimeInterval(TimeInterval(rule.offsetSeconds))
                guard fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = rule.title
                content.body = rule.body.isEmpty
                    ? defaultBody(for: rule, at: zmanDate)
                    : rule.body
                content.sound = .default

                let comps = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: fireDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "\(Self.identifierPrefix)\(rule.id)-\(dayOffset)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

                try? await center.add(request)
            }
        }
    }

    private func defaultBody(for rule: NotificationRule, at zmanDate: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        let minutes = abs(rule.offsetSeconds / 60)
        let side = rule.offsetSeconds < 0 ? "before" : "after"
        if minutes == 0 {
            return "\(rule.kind.displayName) at \(f.string(from: zmanDate))"
        }
        return "\(minutes) min \(side) \(rule.kind.displayName) (\(f.string(from: zmanDate)))"
    }

    public static let identifierPrefix = "zmanim.rule."
}
