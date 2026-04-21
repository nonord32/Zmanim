import SwiftUI
import SwiftData
import ZmanimKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var preferences: [UserPreferences]

    var body: some View {
        Form {
            if let prefs = preferences.first {
                Section("Time format") {
                    Picker("Time format", selection: bindingTimeFormat(prefs)) {
                        ForEach(TimeFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    Toggle("Show seconds", isOn: bindingShowsSeconds(prefs))
                }

                Section("Appearance") {
                    Picker("Theme", selection: bindingAppearance(prefs)) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                }

                Section("Shabbat") {
                    Stepper(value: bindingCandles(prefs), in: 10...60, step: 2) {
                        Text("Candle lighting: \(prefs.candleLightingMinutes) min before sunset")
                    }
                }

                Section("Travel Mode") {
                    Toggle("Auto-detect location changes", isOn: bindingTravel(prefs))
                        .disabled(false)
                }

                Section("iCloud") {
                    Toggle("Sync across devices", isOn: bindingCloud(prefs))
                }

                Section {
                    NavigationLink("Zmanim to display") {
                        ZmanOpinionsEditor(preferences: prefs)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    // MARK: - Bindings (each setting writes through to SwiftData on change)

    private func bindingTimeFormat(_ p: UserPreferences) -> Binding<TimeFormat> {
        Binding(get: { p.timeFormat }, set: { p.timeFormat = $0; try? context.save() })
    }
    private func bindingShowsSeconds(_ p: UserPreferences) -> Binding<Bool> {
        Binding(get: { p.showsSeconds }, set: { p.showsSeconds = $0; try? context.save() })
    }
    private func bindingAppearance(_ p: UserPreferences) -> Binding<AppearanceMode> {
        Binding(get: { p.appearance }, set: { p.appearance = $0; try? context.save() })
    }
    private func bindingCandles(_ p: UserPreferences) -> Binding<Int> {
        Binding(get: { p.candleLightingMinutes }, set: { p.candleLightingMinutes = $0; try? context.save() })
    }
    private func bindingTravel(_ p: UserPreferences) -> Binding<Bool> {
        Binding(get: { p.travelModeEnabled }, set: { p.travelModeEnabled = $0; try? context.save() })
    }
    private func bindingCloud(_ p: UserPreferences) -> Binding<Bool> {
        Binding(get: { p.iCloudSyncEnabled }, set: { p.iCloudSyncEnabled = $0; try? context.save() })
    }
}
