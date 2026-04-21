import WidgetKit
import SwiftUI
import ZmanimKit

struct NextZmanWidget: Widget {
    let kind: String = "NextZmanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZmanimProvider()) { entry in
            NextZmanWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Zman")
        .description("The next upcoming zman with a live countdown.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct NextZmanWidgetView: View {
    let entry: ZmanimEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:    circular
        case .accessoryInline:      inline
        case .accessoryRectangular: rectangular
        case .systemSmall:          small
        default:                    medium
        }
    }

    @ViewBuilder
    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let z = entry.next {
                Text(z.kind.displayName).font(.caption.bold())
                Text(z.opinion.displayName).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(z.date, style: .timer)
                    .font(.title3.monospacedDigit())
                Text(z.date, style: .time)
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                Text("No zmanim").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let z = entry.next {
                HStack {
                    Text(z.kind.displayName).font(.headline)
                    Spacer()
                    Text(z.date, style: .time).font(.headline.monospacedDigit())
                }
                Text(z.opinion.displayName).font(.caption).foregroundStyle(.secondary)
                Text(z.date, style: .timer).font(.title2.monospacedDigit())
            }
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        VStack(alignment: .leading) {
            if let z = entry.next {
                Text(z.kind.displayName).font(.headline)
                Text(z.date, style: .time).font(.caption.monospacedDigit())
                Text(z.date, style: .timer).font(.caption2)
            }
        }
    }

    @ViewBuilder
    private var circular: some View {
        ZStack {
            if let z = entry.next {
                Text(z.date, style: .timer)
                    .font(.caption2.monospacedDigit())
            } else {
                Image(systemName: "sun.max.fill")
            }
        }
    }

    @ViewBuilder
    private var inline: some View {
        if let z = entry.next {
            Text("\(z.kind.displayName) \(z.date.formatted(date: .omitted, time: .shortened))")
        } else {
            Text("No upcoming zman")
        }
    }
}
