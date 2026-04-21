import Foundation

/// Wrapper around Foundation's built-in Hebrew calendar, formatted for display.
public struct HebrewCalendarService: Sendable {

    public init() {}

    private var hebrewCalendar: Calendar {
        var c = Calendar(identifier: .hebrew)
        c.locale = Locale(identifier: "en_US")
        return c
    }

    /// e.g. "4 Iyar 5786"
    public func hebrewDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = hebrewCalendar
        formatter.locale = Locale(identifier: "en_US@calendar=hebrew")
        formatter.dateFormat = "d MMMM y"
        return formatter.string(from: date)
    }

    /// e.g. "Tuesday"
    public func weekdayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// Returns the Hebrew year, month (1-13), and day for a date.
    public func components(for date: Date) -> (year: Int, month: Int, day: Int) {
        let comps = hebrewCalendar.dateComponents([.year, .month, .day], from: date)
        return (comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// True if the given date falls on Shabbat.
    public func isShabbat(_ date: Date) -> Bool {
        Calendar(identifier: .gregorian).component(.weekday, from: date) == 7
    }

    /// True if the given date is Erev Shabbat (Friday) and candle-lighting applies.
    public func isErevShabbat(_ date: Date) -> Bool {
        Calendar(identifier: .gregorian).component(.weekday, from: date) == 6
    }
}
