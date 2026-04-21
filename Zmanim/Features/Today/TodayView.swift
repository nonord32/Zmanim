import SwiftUI
import SwiftData
import ZmanimKit

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]

    @State private var viewModel = TodayViewModel()
    @State private var tickingNow: Date = .now
    @State private var selectedZman: ComputedZman?

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            if let next = viewModel.nextZman {
                Section { NextZmanCard(zman: next, now: viewModel.now, previous: viewModel.previousZman) }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Today's Calendar") {
                CalendarSection(viewModel: viewModel)
            }

            Section("Today's Zmanim") {
                ForEach(viewModel.sortedZmanim) { zman in
                    Button { selectedZman = zman } label: {
                        ZmanRow(zman: zman, timeFormat: timeFormat, showsSeconds: showsSeconds)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section { dateFooter }
                .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .onAppear { sync() }
        .onChange(of: appState.currentLocation) { _, _ in sync() }
        .onChange(of: preferences.first?.displayConfigData) { _, _ in sync() }
        .onReceive(tick) { date in
            viewModel.now = date
        }
        .sheet(item: $selectedZman) { zman in
            ZmanDetailSheet(zman: zman)
        }
        .gesture(
            DragGesture(minimumDistance: 40).onEnded { value in
                if value.translation.width < -40 { viewModel.goToNextDay() }
                if value.translation.width >  40 { viewModel.goToPreviousDay() }
            }
        )
    }

    private var timeFormat: TimeFormat { preferences.first?.timeFormat ?? .twelveHour }
    private var showsSeconds: Bool { preferences.first?.showsSeconds ?? true }

    private func sync() {
        viewModel.location = appState.currentLocation
        if let prefs = preferences.first {
            viewModel.displayConfigs = prefs.displayConfigs
        }
    }

    // MARK: - Footer

    private var dateFooter: some View {
        HStack {
            Button(action: viewModel.goToPreviousDay) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Button(viewModel.selectedDate.formatted(date: .long, time: .omitted)) {
                viewModel.resetToToday()
            }
            .foregroundStyle(appState.accentColor)
            .font(.headline)
            Spacer()
            Button(action: viewModel.goToNextDay) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.vertical, 4)
    }
}
