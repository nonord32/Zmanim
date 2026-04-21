import Foundation
import Observation
import ZmanimKit

@Observable
@MainActor
final class TodayViewModel {
    var selectedDate: Date = .now
    var location: ResolvedLocation?
    var displayConfigs: [ZmanDisplayConfig] = ZmanDisplayConfig.defaults
    var now: Date = .now

    private let engine = ZmanimEngine()
    private let hebrewCalendar = HebrewCalendarService()
    private let parshaService = ParshaService()
    private let dafYomiService = DafYomiService()
    private let sefiraService = SefiraService()

    // MARK: - Derived

    var zmanim: [ComputedZman] {
        guard let location else { return [] }
        let pairs = displayConfigs.filter(\.isEnabled).map { ($0.kind, $0.opinion) }
        return engine.zmanim(for: selectedDate, at: location, opinions: pairs)
    }

    var sortedZmanim: [ComputedZman] {
        // Preserve user's configured row order, not chronological order —
        // matches the Ultimate Zmanim UX where users want predictable row
        // positions for the zmanim they care about.
        let enabledOrder = displayConfigs.filter(\.isEnabled)
        let byPair: [String: ComputedZman] = Dictionary(uniqueKeysWithValues:
            zmanim.map { ("\($0.kind.rawValue)#\($0.opinion)", $0) }
        )
        return enabledOrder.compactMap { cfg in
            byPair["\(cfg.kind.rawValue)#\(cfg.opinion)"]
        }
    }

    var nextZman: ComputedZman? {
        zmanim.next(after: now)
    }

    var previousZman: ComputedZman? {
        zmanim.previous(at: now)
    }

    // MARK: - Calendar

    var hebrewDateString: String { hebrewCalendar.hebrewDateString(for: selectedDate) }
    var weekdayString: String { hebrewCalendar.weekdayString(for: selectedDate) }
    var parsha: String? { parshaService.parsha(for: selectedDate) }
    var dafYomi: String? { dafYomiService.daf(for: selectedDate) }
    var omerDay: Int? {
        sefiraService.omerDay(
            for: selectedDate,
            inTimeZone: location?.timeZone ?? .current
        )
    }

    // MARK: - Commands

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }

    func resetToToday() { selectedDate = .now }
}
