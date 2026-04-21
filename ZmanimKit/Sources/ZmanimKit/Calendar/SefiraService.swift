import Foundation

/// Counts Sefirat Ha'Omer: days 1–49 from 16 Nisan through 5 Sivan.
/// Uses KosherCocoa's `JewishCalendar` under the hood indirectly via
/// Foundation's Hebrew calendar, which is sufficient for the day count.
public struct SefiraService: Sendable {

    public init() {}

    /// The current Omer day (1–49), or nil if outside the counting period.
    /// `reference` is interpreted in the location's timezone so "tonight's
    /// count" is surfaced correctly after Tzeit Hakochavim.
    public func omerDay(for reference: Date, inTimeZone tz: TimeZone) -> Int? {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = tz

        guard let year = cal.dateComponents([.year], from: reference).year else { return nil }

        // Day 1 of the Omer = 16 Nisan; day 49 = 5 Sivan. Foundation's Hebrew
        // calendar uses a month index that shifts in leap years, so look the
        // month up by localized name.
        guard let nisan16 = cal.date(from: DateComponents(
            year: year,
            month: nisanMonth(in: year, calendar: cal),
            day: 16
        )) else { return nil }

        let target = cal.startOfDay(for: reference)
        let start = cal.startOfDay(for: nisan16)
        let diff = cal.dateComponents([.day], from: start, to: target).day ?? -1

        let omerDay = diff + 1
        return (1...49).contains(omerDay) ? omerDay : nil
    }

    public func displayString(for day: Int) -> String {
        "Day \(day)"
    }

    // Foundation's Hebrew calendar uses Tishrei=1…Elul=12 (+ Adar II in leap
    // years as 13 between months 6 and 7, shifting). Nisan is always the 7th
    // "month-from-Tishrei"; in non-leap years that's month 7, in leap years
    // it's month 8. Easiest: find the month whose localized name is "Nisan".
    private func nisanMonth(in year: Int, calendar: Calendar) -> Int {
        for m in 1...13 {
            if let d = calendar.date(from: DateComponents(year: year, month: m, day: 1)) {
                let f = DateFormatter()
                f.calendar = calendar
                f.locale = Locale(identifier: "en_US@calendar=hebrew")
                f.dateFormat = "MMMM"
                if f.string(from: d) == "Nisan" { return m }
            }
        }
        return 7
    }
}
