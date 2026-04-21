import Foundation
import SwiftData

public enum PersistenceConfig {
    /// Update this to match the App Group you configure in Xcode for the app
    /// and widget targets.
    public static let appGroupIdentifier = "group.com.example.zmanim"

    /// Update this to match your iCloud container identifier.
    public static let cloudKitContainerIdentifier = "iCloud.com.example.zmanim"
}

public enum SharedModelContainer {

    /// A SwiftData container shared between the app and the widget, with
    /// CloudKit mirroring. Safe to call from either target — both sides see
    /// the same on-disk store via the App Group.
    public static func make() throws -> ModelContainer {
        let schema = Schema([
            SavedLocation.self,
            UserPreferences.self,
            NotificationRule.self
        ])

        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: PersistenceConfig.appGroupIdentifier)?
            .appendingPathComponent("Zmanim.sqlite")
        else {
            throw NSError(
                domain: "ZmanimKit",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "App Group \(PersistenceConfig.appGroupIdentifier) not available. Configure it on both the app and widget targets."]
            )
        }

        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .private(PersistenceConfig.cloudKitContainerIdentifier)
        )

        let container = try ModelContainer(for: schema, configurations: [configuration])
        ensureSeed(container: container)
        return container
    }

    /// Guarantee exactly one `UserPreferences` row exists.
    @MainActor
    private static func ensureSeed(container: ModelContainer) {
        let context = container.mainContext
        let fetch = FetchDescriptor<UserPreferences>()
        if let existing = try? context.fetch(fetch), existing.isEmpty {
            let prefs = UserPreferences()
            prefs.displayConfigs = ZmanDisplayConfig.defaults
            context.insert(prefs)
            try? context.save()
        }
    }
}
