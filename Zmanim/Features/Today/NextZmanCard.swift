import SwiftUI
import ZmanimKit

/// Hero card at the top of the Today screen showing the next upcoming zman
/// with a live countdown and progress ring.
struct NextZmanCard: View {
    let zman: ComputedZman
    let now: Date
    let previous: ComputedZman?

    private var timeRemaining: TimeInterval {
        max(0, zman.date.timeIntervalSince(now))
    }

    private var progress: Double {
        guard let previous, zman.date > previous.date else { return 0 }
        let total = zman.date.timeIntervalSince(previous.date)
        let elapsed = now.timeIntervalSince(previous.date)
        return max(0, min(1, elapsed / total))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(.secondary.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.9), value: progress)
                Image(systemName: icon(for: zman.kind))
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Next")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(zman.kind.displayName)
                    .font(.headline)
                Text(zman.opinion.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(zman.date, style: .time)
                    .font(.title3.monospacedDigit())
                Text(countdownString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var countdownString: String {
        let total = Int(timeRemaining)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "in %d:%02d:%02d", h, m, s) }
        return String(format: "in %d:%02d", m, s)
    }

    private func icon(for kind: ZmanKind) -> String {
        switch kind {
        case .alotHaShachar, .misheyakir, .netzHachama:   return "sunrise.fill"
        case .sofZmanShema, .sofZmanTefila:               return "book.fill"
        case .chatzot, .minchaGedola, .minchaKetana:      return "sun.max.fill"
        case .plagHamincha, .shkiatHachama:               return "sunset.fill"
        case .candleLighting:                             return "flame.fill"
        case .tzaitHakochavim, .havdalah:                 return "moon.stars.fill"
        }
    }
}
