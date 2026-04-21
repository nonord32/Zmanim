import Foundation

/// Every zman the app knows about. Stable raw values — persisted in SwiftData
/// and App Group UserDefaults, so do not renumber existing cases.
public enum ZmanKind: String, CaseIterable, Codable, Sendable, Hashable {
    case alotHaShachar
    case misheyakir
    case netzHachama
    case sofZmanShema
    case sofZmanTefila
    case chatzot
    case minchaGedola
    case minchaKetana
    case plagHamincha
    case shkiatHachama
    case tzaitHakochavim
    case candleLighting
    case havdalah

    public var displayName: String {
        switch self {
        case .alotHaShachar:   return "Alot HaShachar"
        case .misheyakir:      return "Misheyakir"
        case .netzHachama:     return "Netz Hachama"
        case .sofZmanShema:    return "Sof Zman Shema"
        case .sofZmanTefila:   return "Sof Zman Tefila"
        case .chatzot:         return "Chatzot"
        case .minchaGedola:    return "Mincha Gedola"
        case .minchaKetana:    return "Mincha Ketana"
        case .plagHamincha:    return "Plag Hamincha"
        case .shkiatHachama:   return "Shki'at Hachama"
        case .tzaitHakochavim: return "Tzait Hakochavim"
        case .candleLighting:  return "Candle Lighting"
        case .havdalah:        return "Havdalah"
        }
    }

    /// The default ordering for the Today list.
    public static let displayOrder: [ZmanKind] = [
        .alotHaShachar,
        .misheyakir,
        .netzHachama,
        .sofZmanShema,
        .sofZmanTefila,
        .chatzot,
        .minchaGedola,
        .minchaKetana,
        .plagHamincha,
        .candleLighting,
        .shkiatHachama,
        .tzaitHakochavim,
        .havdalah
    ]
}
