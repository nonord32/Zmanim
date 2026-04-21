import SwiftUI
import ZmanimKit

struct CalendarSection: View {
    @Bindable var viewModel: TodayViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        row(label: "Hebrew Date", sublabel: viewModel.weekdayString, value: viewModel.hebrewDateString)

        if let location = viewModel.location {
            NavigationLink {
                LocationListView()
            } label: {
                row(label: "Location",
                    sublabel: location.timeZone.localizedName(for: .generic, locale: .current) ?? location.timeZone.identifier,
                    value: location.name)
            }
        }

        if let parsha = viewModel.parsha {
            row(label: "Parasha", value: parsha)
        }

        if let daf = viewModel.dafYomi {
            row(label: "Daf Yomi", value: daf)
        }

        if let omer = viewModel.omerDay {
            row(label: "Sefirat Ha'Omer",
                sublabel: omerStateLabel(),
                value: "Day \(omer)")
        }
    }

    private func omerStateLabel() -> String {
        // "Before Tzait Hakochavim" until Tzait; after that, "Day N" applies
        // to the outgoing day. For v1 just show the before/after label based
        // on location + time.
        guard let location = viewModel.location else { return "" }
        let engine = ZmanimEngine()
        guard let tzait = engine.zman(kind: .tzaitHakochavim,
                                      opinion: .degrees(8.5),
                                      date: viewModel.selectedDate,
                                      at: location) else { return "" }
        return viewModel.now < tzait ? "Before Tzait Hakochavim" : "After Tzait Hakochavim"
    }

    @ViewBuilder
    private func row(label: String, sublabel: String? = nil, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.body.bold())
                if let sublabel, !sublabel.isEmpty {
                    Text(sublabel).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
