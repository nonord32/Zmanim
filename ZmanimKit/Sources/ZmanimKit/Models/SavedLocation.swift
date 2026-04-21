import Foundation
import SwiftData

/// A location the user has saved. Synced across devices via CloudKit.
@Model
public final class SavedLocation {
    public var name: String
    public var latitude: Double
    public var longitude: Double
    /// Elevation in meters. 0 unless the user overrides.
    public var elevation: Double
    /// IANA timezone identifier (e.g. "America/New_York").
    public var timeZoneIdentifier: String
    public var createdAt: Date
    public var lastUsedAt: Date
    /// If true, this is the currently selected location.
    public var isCurrent: Bool

    public init(
        name: String,
        latitude: Double,
        longitude: Double,
        elevation: Double = 0,
        timeZoneIdentifier: String,
        isCurrent: Bool = false
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timeZoneIdentifier = timeZoneIdentifier
        self.createdAt = .now
        self.lastUsedAt = .now
        self.isCurrent = isCurrent
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    public func resolved() -> ResolvedLocation {
        ResolvedLocation(
            name: name,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            timeZone: timeZone
        )
    }
}
