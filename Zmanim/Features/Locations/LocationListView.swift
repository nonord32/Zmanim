import SwiftUI
import SwiftData
import ZmanimKit

struct LocationListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedLocation.lastUsedAt, order: .reverse) private var locations: [SavedLocation]
    @State private var showingSearch = false

    var body: some View {
        List {
            Section {
                Button {
                    Task { await useCurrentLocation() }
                } label: {
                    Label("Use Current Location", systemImage: "location.fill")
                }
            }

            Section("Saved Locations") {
                ForEach(locations) { loc in
                    Button {
                        switchTo(loc)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(loc.name).font(.body)
                                Text(loc.timeZoneIdentifier).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if loc.isCurrent {
                                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingSearch = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingSearch) {
            LocationSearchView { result in
                addLocation(from: result)
                showingSearch = false
            }
        }
    }

    private func switchTo(_ loc: SavedLocation) {
        for l in locations { l.isCurrent = (l.persistentModelID == loc.persistentModelID) }
        loc.lastUsedAt = .now
        try? context.save()
        appState.currentLocation = loc.resolved()
        Task { await appState.rescheduleNotifications() }
    }

    private func addLocation(from result: LocationSearchResult) {
        let loc = SavedLocation(
            name: result.title,
            latitude: result.latitude,
            longitude: result.longitude,
            timeZoneIdentifier: result.timeZoneIdentifier
        )
        context.insert(loc)
        try? context.save()
        switchTo(loc)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(locations[i]) }
        try? context.save()
    }

    private func useCurrentLocation() async {
        appState.locationManager.requestWhenInUse()
        guard let cl = try? await appState.locationManager.requestCurrentLocation(),
              let placemark = await appState.locationManager.reverseGeocode(cl)
        else { return }
        let loc = SavedLocation(
            name: placemark.locality ?? "Current Location",
            latitude: cl.coordinate.latitude,
            longitude: cl.coordinate.longitude,
            elevation: cl.altitude,
            timeZoneIdentifier: placemark.timeZone?.identifier ?? TimeZone.current.identifier
        )
        context.insert(loc)
        try? context.save()
        switchTo(loc)
    }
}
