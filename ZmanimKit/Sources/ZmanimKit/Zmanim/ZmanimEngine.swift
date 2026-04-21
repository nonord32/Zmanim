import Foundation
import CoreLocation
import KosherCocoa

/// The single entry point for computing zmanim. All UI code must go through
/// this type. Wraps `KosherCocoa.ComplexZmanimCalendar` so we can swap the
/// underlying math library (e.g. to `kosher-swift`) without touching UI.
///
/// Zmanim are pure functions of (date, location, opinion); never persist them.
public struct ZmanimEngine: Sendable {

    public init() {}

    // MARK: - Public API

    /// Compute every configured (kind, opinion) pair for a single date at a location.
    public func zmanim(
        for date: Date,
        at location: ResolvedLocation,
        opinions: [(ZmanKind, ZmanOpinion)]
    ) -> [ComputedZman] {
        let calendar = makeCalendar(date: date, location: location)
        return opinions.compactMap { (kind, opinion) in
            guard let d = compute(kind: kind, opinion: opinion, calendar: calendar, date: date, location: location)
            else { return nil }
            return ComputedZman(kind: kind, opinion: opinion, date: d)
        }
    }

    /// Compute a single zman.
    public func zman(
        kind: ZmanKind,
        opinion: ZmanOpinion,
        date: Date,
        at location: ResolvedLocation
    ) -> Date? {
        let calendar = makeCalendar(date: date, location: location)
        return compute(kind: kind, opinion: opinion, calendar: calendar, date: date, location: location)
    }

    // MARK: - KosherCocoa wiring

    private func makeCalendar(date: Date, location: ResolvedLocation) -> ComplexZmanimCalendar {
        let geo = GeoLocation(
            name: location.name,
            latitude: location.latitude,
            longitude: location.longitude,
            elevation: location.elevation,
            timeZone: location.timeZone
        )
        let cal = ComplexZmanimCalendar(location: geo)
        cal.workingDate = date
        return cal
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func compute(
        kind: ZmanKind,
        opinion: ZmanOpinion,
        calendar cal: ComplexZmanimCalendar,
        date: Date,
        location: ResolvedLocation
    ) -> Date? {
        switch (kind, opinion) {

        // MARK: Alot HaShachar
        case (.alotHaShachar, .degrees(16.1)):
            return cal.alosHashachar()
        case (.alotHaShachar, .degrees(19.8)):
            return cal.alos19Point8Degrees()
        case (.alotHaShachar, .minutes(72)):
            return cal.alos72()
        case (.alotHaShachar, .minutes(90)):
            return cal.alos90()
        case (.alotHaShachar, .minutes(120)):
            return cal.alos120()
        case (.alotHaShachar, .degrees(let d)):
            return cal.sunriseOffsetByDegrees(90 + d)

        // MARK: Misheyakir
        case (.misheyakir, .degrees(10.2)):
            return cal.misheyakir10Point2Degrees()
        case (.misheyakir, .degrees(11)):
            return cal.misheyakir11Degrees()
        case (.misheyakir, .degrees(11.5)):
            return cal.misheyakir11Point5Degrees()
        case (.misheyakir, .degrees(let d)):
            return cal.sunriseOffsetByDegrees(90 + d)

        // MARK: Netz
        case (.netzHachama, _):
            return cal.seaLevelSunrise() ?? cal.sunrise()

        // MARK: Sof Zman Shema
        case (.sofZmanShema, .gra):
            return cal.sofZmanShmaGra()
        case (.sofZmanShema, .mogenAvraham):
            return cal.sofZmanShmaMogenAvraham()

        // MARK: Sof Zman Tefila
        case (.sofZmanTefila, .gra):
            return cal.sofZmanTfilaGra()
        case (.sofZmanTefila, .mogenAvraham):
            return cal.sofZmanTfilaMogenAvraham()

        // MARK: Chatzot
        case (.chatzot, _):
            return cal.chatzos()

        // MARK: Mincha Gedola
        case (.minchaGedola, .gra), (.minchaGedola, .baalHaTanya):
            return cal.minchaGedola()
        case (.minchaGedola, .degrees(16.1)):
            return cal.minchaGedola16Point1Degrees()

        // MARK: Mincha Ketana
        case (.minchaKetana, .gra), (.minchaKetana, .baalHaTanya):
            return cal.minchaKetana()
        case (.minchaKetana, .degrees(16.1)):
            return cal.minchaKetana16Point1Degrees()

        // MARK: Plag Hamincha
        case (.plagHamincha, .gra), (.plagHamincha, .baalHaTanya):
            return cal.plagHamincha()
        case (.plagHamincha, .degrees(16.1)):
            return cal.plagHamincha16Point1Degrees()

        // MARK: Shkia
        case (.shkiatHachama, _):
            return cal.seaLevelSunset() ?? cal.sunset()

        // MARK: Tzait
        case (.tzaitHakochavim, .threeStars):
            return cal.tzais()
        case (.tzaitHakochavim, .degrees(8.5)):
            return cal.tzaisGeonim8Point5Degrees()
        case (.tzaitHakochavim, .degrees(7.083)):
            return cal.tzaisGeonim7Point083Degrees()
        case (.tzaitHakochavim, .degrees(let d)):
            return cal.sunsetOffsetByDegrees(90 + d)
        case (.tzaitHakochavim, .minutes(72)):
            return cal.tzais72()
        case (.tzaitHakochavim, .minutes(50)):
            return cal.tzais50()
        case (.tzaitHakochavim, .rabbeinuTam):
            return cal.tzais72()

        // MARK: Candle lighting (sunset − N minutes)
        case (.candleLighting, .minutes(let m)):
            guard let sunset = cal.seaLevelSunset() ?? cal.sunset() else { return nil }
            return sunset.addingTimeInterval(TimeInterval(-m * 60))

        // MARK: Havdalah
        case (.havdalah, .threeStars):
            return cal.tzais()
        case (.havdalah, .degrees(8.5)):
            return cal.tzaisGeonim8Point5Degrees()
        case (.havdalah, .rabbeinuTam):
            return cal.tzais72()
        case (.havdalah, .minutes(72)):
            return cal.tzais72()

        default:
            return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}

/// Snapshot of a location ready for calculation. Built from either a
/// `SavedLocation` (SwiftData) or a `CLLocation` (current GPS).
public struct ResolvedLocation: Hashable, Sendable {
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let timeZone: TimeZone

    public init(
        name: String,
        latitude: Double,
        longitude: Double,
        elevation: Double,
        timeZone: TimeZone
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timeZone = timeZone
    }
}
