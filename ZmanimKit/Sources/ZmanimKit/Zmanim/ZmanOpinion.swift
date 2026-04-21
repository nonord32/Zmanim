import Foundation

/// A halachic opinion for computing a zman. Some opinions only apply to
/// specific kinds (e.g. Mogen Avraham applies to Sof Zman Shema/Tefila).
public enum ZmanOpinion: Codable, Sendable, Hashable {
    case gra                 // Vilna Gaon / GRA
    case mogenAvraham        // Mogen Avraham (shaos zmaniyos from Alot → Tzeis)
    case baalHaTanya         // Baal HaTanya
    case rabbeinuTam         // Rabbeinu Tam (Havdalah / Tzeis)
    case degrees(Double)     // Dawn / dusk at a given solar depression, e.g. 16.1°, 8.5°
    case minutes(Int)        // Fixed-minute offset from sunset/sunrise, e.g. 72, 90
    case threeStars          // Standard 3-stars Tzeis (≈ 3 medium stars visible)

    public var displayName: String {
        switch self {
        case .gra:            return "Vilna Gaon"
        case .mogenAvraham:   return "Mogen Avraham"
        case .baalHaTanya:    return "Gra/Baal Hatanya"
        case .rabbeinuTam:    return "Rabbeinu Tam"
        case .threeStars:     return "3 Stars"
        case .degrees(let d):
            let formatted = d.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(d))"
                : String(format: "%.1f", d)
            return "\(formatted) Degrees"
        case .minutes(let m): return "\(m) Minutes"
        }
    }
}

extension ZmanOpinion {
    /// Opinions valid for each `ZmanKind`. Used by the Settings editor.
    public static func opinions(for kind: ZmanKind) -> [ZmanOpinion] {
        switch kind {
        case .alotHaShachar:
            return [.degrees(16.1), .degrees(19.8), .minutes(72), .minutes(90), .minutes(120)]
        case .misheyakir:
            return [.degrees(10.2), .degrees(11), .degrees(11.5)]
        case .netzHachama, .shkiatHachama, .chatzot:
            return [.gra]
        case .sofZmanShema, .sofZmanTefila:
            return [.gra, .mogenAvraham]
        case .minchaGedola, .minchaKetana, .plagHamincha:
            return [.gra, .baalHaTanya, .degrees(16.1)]
        case .tzaitHakochavim:
            return [.threeStars, .degrees(8.5), .degrees(7.083), .minutes(72), .minutes(50), .rabbeinuTam]
        case .candleLighting:
            return [.minutes(18), .minutes(22), .minutes(40)]
        case .havdalah:
            return [.threeStars, .degrees(8.5), .rabbeinuTam, .minutes(72)]
        }
    }

    /// The default opinion set for a fresh install — matches what's shown in
    /// the screenshots the user shared.
    public static var defaultDisplay: [(ZmanKind, ZmanOpinion)] {
        [
            (.alotHaShachar,   .degrees(16.1)),
            (.misheyakir,      .degrees(11)),
            (.netzHachama,     .gra),
            (.sofZmanShema,    .mogenAvraham),
            (.sofZmanShema,    .gra),
            (.sofZmanTefila,   .mogenAvraham),
            (.sofZmanTefila,   .gra),
            (.chatzot,         .gra),
            (.minchaGedola,    .baalHaTanya),
            (.minchaKetana,    .degrees(16.1)),
            (.plagHamincha,    .baalHaTanya),
            (.candleLighting,  .minutes(18)),
            (.shkiatHachama,   .gra),
            (.tzaitHakochavim, .degrees(8.5)),
            (.tzaitHakochavim, .minutes(72)),
            (.havdalah,        .degrees(8.5))
        ]
    }
}
