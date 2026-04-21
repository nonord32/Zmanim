import AppIntents
import WidgetKit

/// Triggered by a tap on an interactive widget button (iOS 17+) to force a
/// timeline refresh. Useful after changing location from within the widget.
struct RefreshZmanimIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Zmanim"

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
