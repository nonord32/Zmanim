import SwiftUI
import SwiftData
import ZmanimKit

struct NotificationRulesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query(sort: \NotificationRule.createdAt) private var rules: [NotificationRule]
    @State private var editingRule: NotificationRule?

    var body: some View {
        List {
            Section {
                Button("Add Notification") {
                    let rule = NotificationRule(
                        kind: .shkiatHachama,
                        opinion: .gra,
                        offsetSeconds: -15 * 60,
                        title: "15 min before Shkia"
                    )
                    context.insert(rule)
                    try? context.save()
                    editingRule = rule
                }
            }

            ForEach(rules) { rule in
                Button { editingRule = rule } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(rule.title).font(.body.bold())
                            Spacer()
                            Toggle("", isOn: toggleBinding(rule)).labelsHidden()
                        }
                        Text(summary(for: rule))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Notifications")
        .sheet(item: $editingRule) { rule in
            NotificationRuleEditor(rule: rule)
        }
        .task {
            _ = try? await appState.scheduler.requestAuthorization()
        }
        .onChange(of: rules.count) { _, _ in
            Task { await appState.rescheduleNotifications() }
        }
    }

    private func summary(for rule: NotificationRule) -> String {
        let minutes = abs(rule.offsetSeconds / 60)
        let direction = rule.offsetSeconds < 0 ? "before" : "after"
        let suffix = minutes == 0 ? "at \(rule.kind.displayName)" : "\(minutes) min \(direction) \(rule.kind.displayName)"
        return "\(suffix) (\(rule.opinion.displayName))"
    }

    private func toggleBinding(_ rule: NotificationRule) -> Binding<Bool> {
        Binding(
            get: { rule.isEnabled },
            set: { rule.isEnabled = $0
                   try? context.save()
                   Task { await appState.rescheduleNotifications() } }
        )
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(rules[i]) }
        try? context.save()
    }
}

struct NotificationRuleEditor: View {
    @Bindable var rule: NotificationRule
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $rule.title)
                }
                Section("Zman") {
                    Picker("Zman", selection: bindingKind) {
                        ForEach(ZmanKind.displayOrder, id: \.self) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    Picker("Opinion", selection: bindingOpinion) {
                        ForEach(ZmanOpinion.opinions(for: rule.kind), id: \.self) { o in
                            Text(o.displayName).tag(o)
                        }
                    }
                }
                Section("Offset (minutes)") {
                    Stepper(value: Binding(
                        get: { rule.offsetSeconds / 60 },
                        set: { rule.offsetSeconds = $0 * 60 }
                    ), in: -120...120) {
                        Text("\(rule.offsetSeconds / 60) min")
                    }
                }
            }
            .navigationTitle("Notification")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        Task { await appState.rescheduleNotifications() }
                        dismiss()
                    }
                }
            }
        }
    }

    private var bindingKind: Binding<ZmanKind> {
        Binding(get: { rule.kind }, set: { rule.kindRaw = $0.rawValue })
    }
    private var bindingOpinion: Binding<ZmanOpinion> {
        Binding(get: { rule.opinion },
                set: { rule.opinionData = (try? JSONEncoder().encode($0)) ?? Data() })
    }
}
