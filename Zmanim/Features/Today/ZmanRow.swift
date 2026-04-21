import SwiftUI
import ZmanimKit

struct ZmanRow: View {
    let zman: ComputedZman
    let timeFormat: TimeFormat
    let showsSeconds: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(zman.kind.displayName)
                    .font(.body.bold())
                Text(zman.opinion.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formattedTime)
                .font(.body.monospacedDigit())
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zman.kind.displayName), \(zman.opinion.displayName), \(formattedTime)")
    }

    private var formattedTime: String {
        let f = DateFormatter()
        switch (timeFormat, showsSeconds) {
        case (.twelveHour, true):      f.dateFormat = "h:mm:ss a"
        case (.twelveHour, false):     f.dateFormat = "h:mm a"
        case (.twentyFourHour, true):  f.dateFormat = "HH:mm:ss"
        case (.twentyFourHour, false): f.dateFormat = "HH:mm"
        }
        return f.string(from: zman.date)
    }
}
