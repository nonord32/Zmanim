import Foundation
import CoreLocation
import Observation

/// Thin `@Observable` wrapper around `CLLocationManager`. Two modes:
///   - Foreground: one-shot high-accuracy fix (for "Use current location").
///   - Travel: `startMonitoringSignificantLocationChanges` for background
///     detection of moves between cities, with low battery impact.
@Observable
@MainActor
public final class LocationManager: NSObject {

    public private(set) var authorizationStatus: CLAuthorizationStatus
    public private(set) var currentLocation: CLLocation?
    public private(set) var lastError: Error?
    /// The most recent placemark from reverse geocoding.
    public private(set) var currentPlacemark: CLPlacemark?

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var oneShotContinuation: CheckedContinuation<CLLocation, Error>?

    public override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    public func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    /// One-shot fix. Throws if the user denies or if CLLocationManager errors.
    public func requestCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            if let existing = oneShotContinuation {
                existing.resume(throwing: CancellationError())
            }
            self.oneShotContinuation = continuation
            manager.requestLocation()
        }
    }

    public func startTravelMode() {
        guard authorizationStatus == .authorizedAlways else { return }
        manager.startMonitoringSignificantLocationChanges()
    }

    public func stopTravelMode() {
        manager.stopMonitoringSignificantLocationChanges()
    }

    public func reverseGeocode(_ location: CLLocation) async -> CLPlacemark? {
        try? await geocoder.reverseGeocodeLocation(location).first
    }
}

extension LocationManager: CLLocationManagerDelegate {

    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in self.authorizationStatus = status }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = loc
            self.currentPlacemark = await reverseGeocode(loc)
            if let cont = self.oneShotContinuation {
                self.oneShotContinuation = nil
                cont.resume(returning: loc)
            }
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error
            if let cont = self.oneShotContinuation {
                self.oneShotContinuation = nil
                cont.resume(throwing: error)
            }
        }
    }
}
