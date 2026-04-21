import XCTest
@testable import ZmanimKit

final class CalendarServiceTests: XCTestCase {

    private let testDate: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 4
        c.day = 21
        c.timeZone = TimeZone(identifier: "America/New_York")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    func testHebrewDate() {
        let s = HebrewCalendarService().hebrewDateString(for: testDate)
        XCTAssertEqual(s, "4 Iyar 5786")
    }

    func testWeekday() {
        XCTAssertEqual(HebrewCalendarService().weekdayString(for: testDate), "Tuesday")
    }

    func testSefiraDay19() {
        let day = SefiraService().omerDay(
            for: testDate,
            inTimeZone: TimeZone(identifier: "America/New_York")!
        )
        XCTAssertEqual(day, 19)
    }

    func testDafYomi() {
        // Screenshot shows Menachos 100 on 2026-04-21.
        XCTAssertEqual(DafYomiService().daf(for: testDate), "Menachos 100")
    }

    func testParsha() {
        XCTAssertEqual(ParshaService().parsha(for: testDate), "Acharei Mot - Kedoshim")
    }
}
