import Foundation
import SwiftData

public enum PersistenceConfig {
    /// Update this to match the App Group you configure in Xcode for the app
    /// and widget targets. If empty, the store lives in the app's sandbox
    /// (no widget sharing, no App Group needed).
    public static let appGroupIdentifier: String? = nil

    /// iCloud container identifier. `nil` disables CloudKit mirroring —
    /// required when building with a free Apple ID that can't provision
    /// iCloud containers.
    public static let cloudKitContainerIdentifier: String? = nil
}

public enum SharedModelContainer {

    public static func make() throws -> ModelContainer {
        let schema = Schema([
            SavedLocation.self,
            UserPreferences.self,
            NotificationRule.self
        ])

        let configuration: ModelConfiguration
        if let group = PersistenceConfig.appGroupIdentifier,
           let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("Zmanim.sqlite") {
            if let cloudID = PersistenceConfig.cloudKitContainerIdentifier {
                configuration = ModelConfiguration(
                    schema: schema,
                    url: storeURL,
                    cloudKitDatabase: .private(cloudID)
                )
            } else {
                configuration = ModelConfiguration(schema: schema, url: storeURL)
            }
        } else {
            // Sandbox-local store. Fine for single-target builds (free Apple ID).
            configuration = ModelConfiguration(schema: schema)
        }

        let container = try ModelContainer(for: schema, configurations: [configuration])
        Task { @MainActor in ensureSeed(container: container) }
        return container
    }

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
