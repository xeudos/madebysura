import ActivityKit
import SwiftUI
import WidgetKit

@main
struct IntervalWidgets: WidgetBundle {
    var body: some Widget { IntervalActivityWidget() }
}

struct IntervalActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(context.attributes.name.isEmpty ? "Interval" : context.attributes.name, systemImage: "timer")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    Text(status(context)).font(.caption.weight(.semibold)).foregroundStyle(accent(context))
                }
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(context.isStale ? "Open timer for current interval" : context.state.title)
                            .font(.headline).lineLimit(1)
                        Text("Round \(context.state.round)/\(context.state.rounds) · Set \(context.state.set)/\(context.state.sets)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    countdown(context).font(.system(size: 32, weight: .medium, design: .rounded)).frame(width: 110)
                }
            }.padding(16).activityBackgroundTint(Color(red: 0.08, green: 0.09, blue: 0.11))
                .activitySystemActionForegroundColor(.white).foregroundStyle(.white)
                .widgetURL(URL(string: "interval://session"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(status(context), systemImage: context.state.paused ? "pause.fill" : "timer")
                        .font(.caption.weight(.semibold)).foregroundStyle(accent(context))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context).font(.system(size: 25, weight: .semibold, design: .rounded)).frame(width: 95)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.isStale ? "Open timer" : context.state.title).lineLimit(1)
                        Spacer()
                        Text("\(context.state.round)/\(context.state.rounds) · Set \(context.state.set)")
                    }.font(.caption).padding(.top, 5)
                }
            } compactLeading: {
                Image(systemName: context.state.paused ? "pause.fill" : "timer").foregroundStyle(accent(context))
            } compactTrailing: {
                countdown(context).monospacedDigit().font(.caption.weight(.semibold)).frame(width: 54)
            } minimal: {
                Image(systemName: context.state.paused ? "pause.fill" : "timer").foregroundStyle(accent(context))
            }
            .widgetURL(URL(string: "interval://session")).keylineTint(accent(context))
        }
    }
    @ViewBuilder private func countdown(_ c: ActivityViewContext<TimerActivityAttributes>) -> some View {
        if c.state.finished { Image(systemName: "checkmark") }
        else if c.state.paused { Text(String(format: "%02d:%02d", c.state.remaining / 60, c.state.remaining % 60)) }
        else {
            Text(timerInterval: c.state.phaseStart...max(c.state.phaseStart, c.isStale ? c.state.sessionEnd : c.state.phaseEnd), countsDown: true)
                .monospacedDigit().minimumScaleFactor(0.6)
        }
    }
    private func status(_ c: ActivityViewContext<TimerActivityAttributes>) -> String {
        if c.state.finished { return "Complete" }
        if c.state.paused { return "Paused" }
        if c.isStale { return "Remaining" }
        return c.state.kind.capitalized
    }
    private func accent(_ c: ActivityViewContext<TimerActivityAttributes>) -> Color {
        switch c.state.kind {
        case "rest": return .pink
        case "prepare": return .orange
        case "cooldown": return .cyan
        default: return Color(red: 0.65, green: 0.91, blue: 0.63)
        }
    }
}
