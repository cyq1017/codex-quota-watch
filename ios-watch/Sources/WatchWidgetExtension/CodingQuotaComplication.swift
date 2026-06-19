import SwiftUI
import WidgetKit

struct CodingQuotaComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchSnapshot
}

struct CodingQuotaComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CodingQuotaComplicationEntry {
        CodingQuotaComplicationEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CodingQuotaComplicationEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CodingQuotaComplicationEntry>) -> Void) {
        let now = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now)
            ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry(at: now)], policy: .after(refreshDate)))
    }

    private func entry(at date: Date = Date()) -> CodingQuotaComplicationEntry {
        CodingQuotaComplicationEntry(date: date, snapshot: SharedUsageStore.shared.load())
    }
}

struct CodingQuotaComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CodingQuotaComplicationEntry

    var body: some View {
        let summary = WidgetQuotaSummary(snapshot: entry.snapshot)
        switch family {
        case .accessoryRectangular:
            rectangular(summary)
        case .accessoryInline:
            inline(summary)
        case .accessoryCorner:
            corner(summary)
        default:
            circular(summary)
        }
    }

    private func rectangular(_ summary: WidgetQuotaSummary) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(.green)
                Text("Codex")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                Spacer(minLength: 2)
                Text(summary.updatedLabel.replacingOccurrences(of: "刷新 ", with: ""))
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            quotaRow(label: "5h", window: summary.fiveHour, tint: .green)
            quotaRow(
                label: "7d",
                window: summary.sevenDay ?? unavailableWindow,
                tint: .cyan
            )
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private func quotaRow(label: String, window: WidgetQuotaWindow, tint: Color) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 22, alignment: .leading)
                .layoutPriority(1)
            ProgressView(value: window.progress)
                .progressViewStyle(.linear)
                .tint(color(for: window.tone, fallback: tint))
            Text(window.percentLabel)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(color(for: window.tone, fallback: tint))
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func circular(_ summary: WidgetQuotaSummary) -> some View {
        Gauge(value: summary.fiveHour.progress) {
            Image(systemName: "terminal.fill")
        } currentValueLabel: {
            Text(summary.fiveHour.percentLabel.replacingOccurrences(of: "%", with: ""))
                .font(.system(.body, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(color(for: summary.fiveHour.tone, fallback: .green))
        .containerBackground(for: .widget) { Color.clear }
    }

    private func corner(_ summary: WidgetQuotaSummary) -> some View {
        Text(summary.fiveHour.percentLabel)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .widgetLabel {
                Gauge(value: summary.fiveHour.progress) {
                    Text("5h")
                }
                .gaugeStyle(.accessoryLinear)
                .tint(color(for: summary.fiveHour.tone, fallback: .green))
            }
            .containerBackground(for: .widget) { Color.clear }
    }

    private func inline(_ summary: WidgetQuotaSummary) -> some View {
        let sevenDay = summary.sevenDay?.percentLabel ?? "--%"
        return Label("5h \(summary.fiveHour.percentLabel) · 7d \(sevenDay)", systemImage: "terminal.fill")
            .containerBackground(for: .widget) { Color.clear }
    }

    private var unavailableWindow: WidgetQuotaWindow {
        WidgetQuotaWindow(title: "7 天", bucket: nil, fallback: .placeholder(status: "not_configured"))
    }

    private func color(for tone: WidgetQuotaTone, fallback: Color) -> Color {
        switch tone {
        case .normal:
            return fallback
        case .warning:
            return .orange
        case .critical:
            return .red
        case .unavailable:
            return .secondary
        }
    }
}

struct CodingQuotaComplication: Widget {
    static let kind = "CodingQuotaComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: CodingQuotaComplicationProvider()) { entry in
            CodingQuotaComplicationView(entry: entry)
        }
        .configurationDisplayName("Codex Quota")
        .description("在表盘上显示 Codex 5 小时和 7 天剩余额度。")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct CodingQuotaComplicationBundle: WidgetBundle {
    var body: some Widget {
        CodingQuotaComplication()
    }
}
