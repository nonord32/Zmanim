import WidgetKit
import SwiftUI
import ZmanimKit

struct TodayZmanimWidget: Widget {
    let kind: String = "TodayZmanimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZmanimProvider()) { entry in
            TodayZmanimWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Zmanim")
        .description("A compact list of today's zmanim.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct TodayZmanimWidgetView: View {
    let entry: ZmanimEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.location?.name ?? "Zmanim")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(entry.zmanim.prefix(6)) { z in
                HStack {
                    Text(z.kind.displayName).font(.caption)
                    Text(z.opinion.displayName).font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text(z.date, style: .time).font(.caption.monospacedDigit())
                }
            }
        }
    }
}
