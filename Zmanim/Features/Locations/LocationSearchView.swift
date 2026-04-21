import SwiftUI
import ZmanimKit

struct LocationSearchView: View {
    let onSelect: (LocationSearchResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [LocationSearchResult] = []
    private let search = LocationSearch()

    var body: some View {
        NavigationStack {
            List(results) { result in
                Button {
                    onSelect(result)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title).font(.body)
                        Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $query, prompt: "Search for a city")
            .onChange(of: query) { _, new in
                Task { results = await search.search(new) }
            }
            .navigationTitle("Add Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
