import WidgetKit
import SwiftUI
import SwiftData
import ZmanimKit

struct ZmanimEntry: TimelineEntry {
    let date: Date
    let zmanim: [ComputedZman]
    let location: ResolvedLocation?

    var next: ComputedZman? { zmanim.next(after: date) }
    var previous: ComputedZman? { zmanim.previous(at: date) }
}

/// Pulls current location + display config from the shared SwiftData store,
/// computes zmanim for today, emits a timeline with one entry per remaining
/// zman so each row update refreshes the widget.
struct ZmanimProvider: TimelineProvider {

    func placeholder(in context: Context) -> ZmanimEntry {
        ZmanimEntry(date: .now, zmanim: [], location: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ZmanimEntry) -> Void) {
        completion(buildEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZmanimEntry>) -> Void) {
        let now = Date()
        let today = buildEntry(for: now)
        var entries: [ZmanimEntry] = [today]

        // Emit an entry each time a zman passes so the widget re-renders.
        let upcoming = today.zmanim.filter { $0.date > now }.map(\.date).sorted()
        for tick in upcoming.prefix(6) {
            entries.append(buildEntry(for: tick.addingTimeInterval(1)))
        }

        // Refresh again after midnight for the new day's zmanim.
        let midnight = Calendar.current.date(
            bySettingHour: 0, minute: 5, second: 0,
            of: Calendar.current.date(byAdding: .day, value: 1, to: now)!
        ) ?? now.addingTimeInterval(24 * 3600)
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }

    private func buildEntry(for date: Date) -> ZmanimEntry {
        guard let container = try? SharedModelContainer.make() else {
            return ZmanimEntry(date: date, zmanim: [], location: nil)
        }

        let context = ModelContext(container)
        let savedLocations = (try? context.fetch(FetchDescriptor<SavedLocation>(
            predicate: #Predicate { $0.isCurrent == true }
        ))) ?? []
        guard let saved = savedLocations.first else {
            return ZmanimEntry(date: date, zmanim: [], location: nil)
        }
        let location = saved.resolved()

        let prefs = (try? context.fetch(FetchDescriptor<UserPreferences>()).first)
        let pairs = (prefs?.displayConfigs ?? ZmanDisplayConfig.defaults)
            .filter(\.isEnabled)
            .map { ($0.kind, $0.opinion) }

        let zmanim = ZmanimEngine().zmanim(for: date, at: location, opinions: pairs)
        return ZmanimEntry(date: date, zmanim: zmanim, location: location)
    }
}
