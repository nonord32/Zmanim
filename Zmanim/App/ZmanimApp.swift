import SwiftUI
import SwiftData
import BackgroundTasks
import ZmanimKit

@main
struct ZmanimApp: App {

    @State private var appState = AppState()
    private let container: ModelContainer

    init() {
        do {
            self.container = try SharedModelContainer.make()
        } catch {
            fatalError("Failed to bring up SwiftData store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(container)
                .preferredColorScheme(appState.preferredColorScheme)
                .tint(appState.accentColor)
                .task { await appState.bootstrap(container: container) }
        }
        .backgroundTask(.appRefresh("com.example.zmanim.refresh")) {
            await appState.handleBackgroundRefresh()
        }
    }
}
