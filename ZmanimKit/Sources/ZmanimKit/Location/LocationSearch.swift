import Foundation
import MapKit
import CoreLocation

public struct LocationSearchResult: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String
}

/// Searches cities via `MKLocalSearch` and resolves their timezone.
public actor LocationSearch {

    public init() {}

    public func search(_ query: String) async -> [LocationSearchResult] {
        guard query.trimmingCharacters(in: .whitespaces).count >= 2 else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            var results: [LocationSearchResult] = []
            for item in response.mapItems.prefix(10) {
                guard let placemark = item.placemark as MKPlacemark? else { continue }
                let coord = placemark.coordinate
                let tz = placemark.timeZone?.identifier ?? TimeZone.current.identifier
                let subtitleParts = [placemark.locality,
                                     placemark.administrativeArea,
                                     placemark.country].compactMap { $0 }
                results.append(LocationSearchResult(
                    title: item.name ?? placemark.name ?? "Unknown",
                    subtitle: subtitleParts.joined(separator: ", "),
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    timeZoneIdentifier: tz
                ))
            }
            return results
        } catch {
            return []
        }
    }
}
