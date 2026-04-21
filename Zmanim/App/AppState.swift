import Foundation
import SwiftUI
import SwiftData
import Observation
import BackgroundTasks
import ZmanimKit

/// App-wide state not tied to any specific screen: current location, preferences,
/// scheduler. Injected into the view tree via `.environment`.
@Observable
@MainActor
public final class AppState {

    public var currentLocation: ResolvedLocation?
    public var preferredColorScheme: ColorScheme?
    public var accentColor: Color = Color(red: 1.0, green: 0.541, blue: 0.0) // #FF8A00
    public var travelBanner: TravelBanner?

    public let locationManager = LocationManager()
    public let scheduler = NotificationScheduler()
    public let engine = ZmanimEngine()

    private var container: ModelContainer?

    public init() {}

    public func bootstrap(container: ModelContainer) async {
        self.container = container
        loadPreferences()
        await resolveCurrentLocation()
        await rescheduleNotifications()
        locationManager.startTravelMode()
    }

    public func handleBackgroundRefresh() async {
        await rescheduleNotifications()
    }

    // MARK: - Preferences

    private func loadPreferences() {
        guard let context = container?.mainContext,
              let prefs = try? context.fetch(FetchDescriptor<UserPreferences>()).first
        else { return }
        switch prefs.appearance {
        case .light:  preferredColorScheme = .light
        case .dark:   preferredColorScheme = .dark
        case .system: preferredColorScheme = nil
        }
        if let parsed = Color(hex: prefs.accentColorHex) {
            accentColor = parsed
        }
    }

    // MARK: - Location resolution

    private func resolveCurrentLocation() async {
        guard let context = container?.mainContext else { return }
        let descriptor = FetchDescriptor<SavedLocation>(
            predicate: #Predicate { $0.isCurrent == true }
        )
        if let saved = try? context.fetch(descriptor).first {
            currentLocation = saved.resolved()
            return
        }
        // Fall back to GPS if we have permission.
        if locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways {
            if let loc = try? await locationManager.requestCurrentLocation(),
               let placemark = await locationManager.reverseGeocode(loc) {
                currentLocation = ResolvedLocation(
                    name: placemark.locality ?? "Current Location",
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    elevation: loc.altitude,
                    timeZone: placemark.timeZone ?? .current
                )
            }
        }
    }

    // MARK: - Notifications

    public func rescheduleNotifications() async {
        guard let context = container?.mainContext,
              let location = currentLocation else { return }
        let rules = (try? context.fetch(FetchDescriptor<NotificationRule>())) ?? []
        await scheduler.reschedule(rules: rules, location: location)
    }
}

public struct TravelBanner: Equatable, Sendable {
    public let detectedCity: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let rgb = UInt32(s, radix: 16) else { return nil }
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >>  8) & 0xFF) / 255.0,
            blue:  Double( rgb        & 0xFF) / 255.0
        )
    }
}
