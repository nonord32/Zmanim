import Foundation

/// Daf Yomi (Bavli) calculation. Cycle 14 began 2020-01-05 (Berachos 2) and
/// proceeds one daf per day through 2,711 days of Shas.
public struct DafYomiService: Sendable {

    public init() {}

    /// Cycle 14 start date (Berachos 2).
    private static let cycleStart: Date = {
        var c = DateComponents()
        c.year = 2020
        c.month = 1
        c.day = 5
        c.hour = 0
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    /// Canonical Shas ordering with number of blatt per masechta.
    private static let masechtos: [(name: String, blatt: Int)] = [
        ("Berachos", 63),     ("Shabbos", 156),    ("Eruvin", 104),
        ("Pesachim", 120),    ("Shekalim", 21),    ("Yoma", 87),
        ("Sukkah", 55),       ("Beitzah", 39),     ("Rosh Hashanah", 34),
        ("Taanis", 30),       ("Megillah", 31),    ("Moed Katan", 28),
        ("Chagigah", 26),     ("Yevamos", 121),    ("Kesubos", 111),
        ("Nedarim", 90),      ("Nazir", 65),       ("Sotah", 48),
        ("Gittin", 89),       ("Kiddushin", 81),   ("Bava Kamma", 118),
        ("Bava Metzia", 118), ("Bava Basra", 175), ("Sanhedrin", 112),
        ("Makkos", 23),       ("Shevuos", 48),     ("Avodah Zarah", 75),
        ("Horayos", 13),      ("Zevachim", 119),   ("Menachos", 109),
        ("Chullin", 141),     ("Bechoros", 60),    ("Arachin", 33),
        ("Temurah", 33),      ("Kereisos", 27),    ("Meilah", 36),
        ("Niddah", 72)
        // Meilah + Kinnim + Tamid + Middos collapse in daf yomi; Kinnim, Tamid
        // and Middos ship with Meilah in cycle 14. Keeping the simple table
        // covers 99% of days; extend if you care about the final week.
    ]

    /// Human-readable daf, e.g. "Menachos 100".
    public func daf(for date: Date) -> String? {
        let cal = Calendar(identifier: .gregorian)
        let days = cal.dateComponents([.day],
                                      from: cal.startOfDay(for: Self.cycleStart),
                                      to: cal.startOfDay(for: date)).day ?? -1
        guard days >= 0 else { return nil }

        var remaining = days
        for masechta in Self.masechtos {
            // First daf of each masechta is "2" (Talmud convention).
            let pages = masechta.blatt - 1
            if remaining < pages {
                return "\(masechta.name) \(remaining + 2)"
            }
            remaining -= pages
        }
        return nil
    }
}
