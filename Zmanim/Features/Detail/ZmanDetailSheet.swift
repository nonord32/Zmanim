import SwiftUI
import SwiftData
import ZmanimKit

struct ZmanDetailSheet: View {
    let zman: ComputedZman
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(zman.kind.displayName).font(.title2.bold())
                        Text(zman.opinion.displayName).font(.subheadline).foregroundStyle(.secondary)
                        Text(zman.date.formatted(date: .abbreviated, time: .standard))
                            .font(.title3.monospacedDigit())
                            .padding(.top, 6)
                    }
                    .padding(.vertical, 8)
                }

                Section("Source") {
                    Text(sourceText)
                }

                Section {
                    Button {
                        createNotificationRule(offset: -15 * 60)
                    } label: {
                        Label("Notify me 15 min before", systemImage: "bell")
                    }
                    Button {
                        createNotificationRule(offset: 0)
                    } label: {
                        Label("Notify me at this time", systemImage: "bell.fill")
                    }
                }
            }
            .navigationTitle("Zman")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var sourceText: String {
        switch (zman.kind, zman.opinion) {
        case (.sofZmanShema, .gra):
            return "End of the third shaah zmanis after Netz, per the Vilna Gaon — day measured sunrise to sunset."
        case (.sofZmanShema, .mogenAvraham):
            return "End of the third shaah zmanis after Alos, per the Mogen Avraham — day measured Alos to Tzeis (72 min)."
        case (.shkiatHachama, _):
            return "Sea-level sunset at the configured latitude/longitude."
        default:
            return "Computed from NOAA Solar Position Algorithm plus standard shaos zmaniyos math."
        }
    }

    private func createNotificationRule(offset: Int) {
        let rule = NotificationRule(
            kind: zman.kind,
            opinion: zman.opinion,
            offsetSeconds: offset,
            title: offset == 0
                ? zman.kind.displayName
                : "\(abs(offset)/60) min before \(zman.kind.displayName)"
        )
        context.insert(rule)
        try? context.save()
        Task { await appState.rescheduleNotifications() }
        dismiss()
    }
}
