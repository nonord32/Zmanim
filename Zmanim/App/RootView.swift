import SwiftUI
import ZmanimKit

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            TodayView()
                .navigationTitle("Zmanim")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            NotificationRulesView()
                        } label: {
                            Image(systemName: "bell")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                }
                .overlay(alignment: .top) { travelBanner }
        }
    }

    @ViewBuilder
    private var travelBanner: some View {
        if let banner = appState.travelBanner {
            TravelBannerView(banner: banner)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding()
        }
    }
}

struct TravelBannerView: View {
    @Environment(AppState.self) private var appState
    let banner: TravelBanner

    var body: some View {
        HStack {
            Image(systemName: "location.fill")
            VStack(alignment: .leading) {
                Text("You seem to be in \(banner.detectedCity)").font(.subheadline.bold())
                Text("Switch zmanim to this location?").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Switch") { /* TODO: switch to this location */ }
                .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
