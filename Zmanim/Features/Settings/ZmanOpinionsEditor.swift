import SwiftUI
import ZmanimKit

struct ZmanOpinionsEditor: View {
    @Environment(\.modelContext) private var context
    @Bindable var preferences: UserPreferences
    @State private var configs: [ZmanDisplayConfig]

    init(preferences: UserPreferences) {
        self.preferences = preferences
        _configs = State(initialValue: preferences.displayConfigs)
    }

    var body: some View {
        List {
            ForEach($configs, id: \.id) { $config in
                HStack {
                    Toggle(isOn: $config.isEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(config.kind.displayName).font(.body)
                            Text(config.opinion.displayName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onMove { configs.move(fromOffsets: $0, toOffset: $1) }

            Section {
                Button("Reset to defaults") {
                    configs = ZmanDisplayConfig.defaults
                    save()
                }
            }
        }
        .navigationTitle("Zmanim to display")
        .toolbar { EditButton() }
        .onDisappear { save() }
    }

    private func save() {
        preferences.displayConfigs = configs
        try? context.save()
    }
}
