import Foundation

/// The single entry point for computing zmanim. All UI code must go through
/// this type. Built on our own `SolarCalculator` — no third-party dependencies.
///
/// Zmanim are pure functions of (date, location, opinion); never persist them.
public struct ZmanimEngine: Sendable {

    public init() {}

    // MARK: - Public API

    public func zmanim(
        for date: Date,
        at location: ResolvedLocation,
        opinions: [(ZmanKind, ZmanOpinion)]
    ) -> [ComputedZman] {
        opinions.compactMap { (kind, opinion) in
            guard let d = zman(kind: kind, opinion: opinion, date: date, at: location)
            else { return nil }
            return ComputedZman(kind: kind, opinion: opinion, date: d)
        }
    }

    public func zman(
        kind: ZmanKind,
        opinion: ZmanOpinion,
        date: Date,
        at location: ResolvedLocation
    ) -> Date? {
        let solar = SolarCalculator(
            latitude: location.latitude,
            longitude: location.longitude,
            elevation: location.elevation
        )

        // Noon in the location's timezone, so we pin calculations to the
        // right civil date regardless of the caller's tz.
        let noon = localNoon(of: date, in: location.timeZone)

        switch (kind, opinion) {

        // MARK: Alot HaShachar
        case (.alotHaShachar, .degrees(let d)):
            return solar.sunriseOffset(byDegrees: d, on: noon)
        case (.alotHaShachar, .minutes(let m)):
            return solar.seaLevelSunrise(on: noon)?.addingTimeInterval(TimeInterval(-m * 60))

        // MARK: Misheyakir
        case (.misheyakir, .degrees(let d)):
            return solar.sunriseOffset(byDegrees: d, on: noon)

        // MARK: Netz
        case (.netzHachama, _):
            return solar.sunrise(on: noon)

        // MARK: Sof Zman Shema / Tefila
        case (.sofZmanShema, .gra):
            return shaosZmaniyosGRA(on: noon, solar: solar, hours: 3)
        case (.sofZmanShema, .mogenAvraham):
            return shaosZmaniyosMA(on: noon, solar: solar, hours: 3)
        case (.sofZmanTefila, .gra):
            return shaosZmaniyosGRA(on: noon, solar: solar, hours: 4)
        case (.sofZmanTefila, .mogenAvraham):
            return shaosZmaniyosMA(on: noon, solar: solar, hours: 4)

        // MARK: Chatzot
        case (.chatzot, _):
            return solar.solarNoon(on: noon)

        // MARK: Mincha Gedola / Ketana / Plag (all GRA-based)
        case (.minchaGedola, _):
            return shaosZmaniyosGRA(on: noon, solar: solar, hours: 6.5)
        case (.minchaKetana, .degrees(16.1)):
            // Mincha Ketana with degree-based shaos (dawn-to-dusk = alos16.1 to tzais16.1)
            return shaosZmaniyosDegrees(on: noon, solar: solar, degrees: 16.1, hours: 9.5)
        case (.minchaKetana, _):
            return shaosZmaniyosGRA(on: noon, solar: solar, hours: 9.5)
        case (.plagHamincha, _):
            return shaosZmaniyosGRA(on: noon, solar: solar, hours: 10.75)

        // MARK: Shkia
        case (.shkiatHachama, _):
            return solar.sunset(on: noon)

        // MARK: Tzait
        case (.tzaitHakochavim, .degrees(let d)):
            return solar.sunsetOffset(byDegrees: d, on: noon)
        case (.tzaitHakochavim, .minutes(let m)),
             (.havdalah, .minutes(let m)):
            return solar.seaLevelSunset(on: noon)?.addingTimeInterval(TimeInterval(m * 60))
        case (.tzaitHakochavim, .threeStars),
             (.havdalah, .threeStars):
            // 3 stars convention: 8.5° below horizon post-sunset.
            return solar.sunsetOffset(byDegrees: 8.5, on: noon)
        case (.tzaitHakochavim, .rabbeinuTam),
             (.havdalah, .rabbeinuTam):
            return solar.seaLevelSunset(on: noon)?.addingTimeInterval(72 * 60)
        case (.havdalah, .degrees(let d)):
            return solar.sunsetOffset(byDegrees: d, on: noon)

        // MARK: Candle lighting
        case (.candleLighting, .minutes(let m)):
            return solar.seaLevelSunset(on: noon)?.addingTimeInterval(TimeInterval(-m * 60))

        default:
            return nil
        }
    }

    // MARK: - Shaos Zmaniyos helpers

    /// Hours of the proportional day from sunrise to sunset, per the Vilna
    /// Gaon. Day is divided into 12 equal parts; each is `shaah`.
    private func shaosZmaniyosGRA(on date: Date, solar: SolarCalculator, hours: Double) -> Date? {
        guard let sunrise = solar.seaLevelSunrise(on: date),
              let sunset = solar.seaLevelSunset(on: date) else { return nil }
        let shaah = sunset.timeIntervalSince(sunrise) / 12.0
        return sunrise.addingTimeInterval(hours * shaah)
    }

    /// Mogen Avraham: day stretched from alos (72 min before sunrise) to
    /// tzeis (72 min after sunset), divided into 12 shaos.
    private func shaosZmaniyosMA(on date: Date, solar: SolarCalculator, hours: Double) -> Date? {
        guard let sunrise = solar.seaLevelSunrise(on: date),
              let sunset = solar.seaLevelSunset(on: date) else { return nil }
        let alos = sunrise.addingTimeInterval(-72 * 60)
        let tzeis = sunset.addingTimeInterval(72 * 60)
        let shaah = tzeis.timeIntervalSince(alos) / 12.0
        return alos.addingTimeInterval(hours * shaah)
    }

    /// Degree-based shaos: day from sun at -X° before sunrise to sun at -X°
    /// after sunset. Used for e.g. Mincha Ketana at 16.1°.
    private func shaosZmaniyosDegrees(on date: Date,
                                      solar: SolarCalculator,
                                      degrees: Double,
                                      hours: Double) -> Date? {
        guard let dawn = solar.sunriseOffset(byDegrees: degrees, on: date),
              let dusk = solar.sunsetOffset(byDegrees: degrees, on: date) else { return nil }
        let shaah = dusk.timeIntervalSince(dawn) / 12.0
        return dawn.addingTimeInterval(hours * shaah)
    }

    /// Returns 12:00 local time on the same civil date that `date` falls on
    /// in the given timezone. Makes solar calculations stable regardless of
    /// which hour-of-day the caller passed in.
    private func localNoon(of date: Date, in tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps) ?? date
    }
}

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
