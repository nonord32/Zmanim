import XCTest
@testable import ZmanimKit

/// Regression tests: known zmanim for fixed (date, location, opinion) tuples.
///
/// Reference values come from the screenshots the user shared — New Rochelle,
/// NY on 21 April 2026. Tolerance is 3 minutes; our NOAA implementation is
/// approximate vs. KosherJava's reference and may drift by 30-120 seconds.
final class ReferenceZmanimTests: XCTestCase {

    private let engine = ZmanimEngine()
    private let tolerance: TimeInterval = 180

    private let newRochelle = ResolvedLocation(
        name: "New Rochelle",
        latitude: 40.9115,
        longitude: -73.7824,
        elevation: 0,
        timeZone: TimeZone(identifier: "America/New_York")!
    )

    private let testDate: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 4
        c.day = 21
        c.hour = 12
        c.timeZone = TimeZone(identifier: "America/New_York")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    private func assertZman(
        _ kind: ZmanKind,
        opinion: ZmanOpinion,
        expected: String,
        line: UInt = #line
    ) {
        guard let actual = engine.zman(kind: kind, opinion: opinion, date: testDate, at: newRochelle) else {
            XCTFail("No zman returned for \(kind) \(opinion)", line: line)
            return
        }
        let f = DateFormatter()
        f.timeZone = newRochelle.timeZone
        f.dateFormat = "h:mm:ss a"
        guard let expectedDate = f.date(from: expected) else {
            XCTFail("Bad expected string \(expected)", line: line)
            return
        }
        // Lift expected back onto the same day in local tz.
        let cal = Calendar(identifier: .gregorian)
        var comps = cal.dateComponents(in: newRochelle.timeZone, from: testDate)
        let ecomps = cal.dateComponents(in: newRochelle.timeZone, from: expectedDate)
        comps.hour = ecomps.hour
        comps.minute = ecomps.minute
        comps.second = ecomps.second
        let expectedOnDay = cal.date(from: comps)!

        let delta = abs(actual.timeIntervalSince(expectedOnDay))
        XCTAssertLessThan(delta, tolerance,
                          "Expected \(kind)/\(opinion) ≈ \(expected), got \(f.string(from: actual)) (Δ=\(delta)s)",
                          line: line)
    }

    func testSofZmanShemaGRA()         { assertZman(.sofZmanShema,    opinion: .gra,           expected: "9:32:58 AM") }
    func testSofZmanShemaMogenAvraham(){ assertZman(.sofZmanShema,    opinion: .mogenAvraham,  expected: "8:56:58 AM") }
    func testSofZmanTefilaGRA()        { assertZman(.sofZmanTefila,   opinion: .gra,           expected: "10:39:20 AM") }
    func testSofZmanTefilaMA()         { assertZman(.sofZmanTefila,   opinion: .mogenAvraham,  expected: "10:15:20 AM") }
    func testChatzot()                 { assertZman(.chatzot,         opinion: .gra,           expected: "12:55:02 PM") }
    func testShkia()                   { assertZman(.shkiatHachama,   opinion: .gra,           expected: "7:42:08 PM") }
    func testTzait85Degrees()          { assertZman(.tzaitHakochavim, opinion: .degrees(8.5),  expected: "8:25:31 PM") }
    func testTzait72Minutes()          { assertZman(.tzaitHakochavim, opinion: .minutes(72),   expected: "8:54:08 PM") }
    func testMisheyakir11()            { assertZman(.misheyakir,      opinion: .degrees(11),   expected: "5:12:13 AM") }
    func testNetz()                    { assertZman(.netzHachama,     opinion: .gra,           expected: "6:09:42 AM") }
    func testAlot161()                 { assertZman(.alotHaShachar,   opinion: .degrees(16.1), expected: "4:41:31 AM") }
}
