import Foundation
import SwiftData

public enum TimeFormat: String, Codable, CaseIterable, Sendable {
    case twelveHour = "12"
    case twentyFourHour = "24"

    public var displayName: String {
        self == .twelveHour ? "12-hour" : "24-hour"
    }
}

public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

/// Singleton preferences document. Exactly one row ever exists; the shared
/// `ModelContainer` creates it on first launch.
@Model
public final class UserPreferences {
    public var timeFormat: TimeFormat
    public var showsSeconds: Bool
    public var appearance: AppearanceMode
    public var accentColorHex: String
    public var candleLightingMinutes: Int
    public var havdalahOpinionRaw: String
    public var travelModeEnabled: Bool
    public var iCloudSyncEnabled: Bool

    /// JSON-encoded `[ZmanDisplayConfig]` — which (kind, opinion) pairs to show
    /// and in what order. Stored as data so we don't have to model a second
    /// SwiftData entity for an ordered list.
    public var displayConfigData: Data

    public init(
        timeFormat: TimeFormat = .twelveHour,
        showsSeconds: Bool = true,
        appearance: AppearanceMode = .system,
        accentColorHex: String = "#FF8A00",
        candleLightingMinutes: Int = 18,
        havdalahOpinionRaw: String = "degrees:8.5",
        travelModeEnabled: Bool = true,
        iCloudSyncEnabled: Bool = true,
        displayConfigData: Data = Data()
    ) {
        self.timeFormat = timeFormat
        self.showsSeconds = showsSeconds
        self.appearance = appearance
        self.accentColorHex = accentColorHex
        self.candleLightingMinutes = candleLightingMinutes
        self.havdalahOpinionRaw = havdalahOpinionRaw
        self.travelModeEnabled = travelModeEnabled
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.displayConfigData = displayConfigData
    }

    public var displayConfigs: [ZmanDisplayConfig] {
        get {
            guard !displayConfigData.isEmpty,
                  let decoded = try? JSONDecoder().decode([ZmanDisplayConfig].self, from: displayConfigData)
            else {
                return ZmanDisplayConfig.defaults
            }
            return decoded
        }
        set {
            displayConfigData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
