import Foundation

/// Weekly parsha lookup. KosherCocoa does not expose parsha directly, so this
/// uses a compact precomputed table keyed by (Hebrew year, Shabbat-of-year
/// ordinal). For v1 we keep a pragmatic in-app table covering the next few
/// years; beyond that we fall back to "—" and surface a banner prompting the
/// user to update the app.
public struct ParshaService: Sendable {

    public init() {}

    /// Returns the parsha read on the Shabbat of the week containing `date`.
    /// `date` can be any day of the week; we normalize to the upcoming Shabbat.
    public func parsha(for date: Date) -> String? {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1 // Sunday
        let weekday = cal.component(.weekday, from: date)
        // Roll forward to Saturday (weekday 7)
        let delta = (7 - weekday + 7) % 7
        guard let shabbat = cal.date(byAdding: .day, value: delta, to: date) else { return nil }

        let key = ParshaTable.key(for: shabbat)
        return ParshaTable.entries[key]
    }
}

/// Precomputed parshiot for the next few years. Entries use an ISO-8601 date
/// string for the Shabbat (yyyy-MM-dd) as the key. Extend annually.
///
/// NOTE: This is a stub. Before shipping, populate via a build-time script
/// that reads from Hebcal (`hebcal -s -y YYYY`) or a static JSON bundle.
/// See `ZmanimKit/Resources/parshiot.json` (TODO).
enum ParshaTable {
    static func key(for shabbat: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: shabbat)
    }

    static let entries: [String: String] = [
        // Stub entries for Diaspora 5786. Replace with a generated table.
        "2026-04-25": "Acharei Mot - Kedoshim",
        "2026-05-02": "Emor",
        "2026-05-09": "Behar - Bechukotai",
        "2026-05-16": "Bamidbar",
        "2026-05-23": "Nasso"
    ]
}
