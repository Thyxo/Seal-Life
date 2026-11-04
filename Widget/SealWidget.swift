import WidgetKit
import SwiftUI
import AppIntents
import ActivityKit

@main
struct SealWidgetBundle: WidgetBundle {
    var body: some Widget {
        SealWidget()
        SealLiveActivity()
    }
}

// MARK: - AppIntent: afkryds direkte fra widgetten

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Afkryds vane"
    static var description = IntentDescription("Afkrydser en vane for i dag.")

    @Parameter(title: "Vane-ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        SealSnapshot.toggleFromWidget(habitID: habitID)
        return .result()
    }
}

// MARK: - Tidslinje

struct SealEntry: TimelineEntry {
    let date: Date
    let snapshot: SealSnapshot
}

struct SealProvider: TimelineProvider {
    func placeholder(in context: Context) -> SealEntry {
        SealEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SealEntry) -> Void) {
        completion(SealEntry(date: Date(), snapshot: SealSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SealEntry>) -> Void) {
        let snap = SealSnapshot.load() ?? .placeholder
        let now = Date()
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        let entries = [SealEntry(date: now, snapshot: snap), SealEntry(date: midnight, snapshot: snap)]
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
    }
}

// MARK: - Widget

struct SealWidget: Widget {
    let kind = "SealWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SealProvider()) { entry in
            SealWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Theme.oceanLight, Theme.cream], startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Sælen")
        .description("Se sælens humør og afkryds dagens vaner.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SealWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SealEntry

    private var snap: SealSnapshot { entry.snapshot }
    private var todays: [WidgetHabit] { snap.habits(on: entry.date) }
    private var remaining: [WidgetHabit] { todays.filter { $0.done < $0.target } }
    private var doneCount: Int { todays.reduce(0) { $0 + min($1.done, $1.target) } }
    private var totalCount: Int { todays.reduce(0) { $0 + $1.target } }

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemLarge: large
        default: medium
        }
    }

    private var seal: some View {
        SealFigure(color: snap.color, state: snap.moodState, hat: snap.hat, glasses: snap.glasses,
                   neck: snap.neck, animated: false)
    }

    private var moodBar: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(.white)
                Capsule().fill(snap.moodState.tint)
                    .frame(width: max(6, g.size.width * CGFloat(snap.mood / 100)))
            }
        }
        .frame(height: 7)
    }

    private var statusText: String {
        if snap.onVacation { return "På ferie 🏝️" }
        if totalCount == 0 { return "Fridag 🌿" }
        if remaining.isEmpty { return "Alt klaret! 💙" }
        return "\(remaining.count) tilbage"
    }

    private var small: some View {
        VStack(spacing: 4) {
            seal.frame(width: 84, height: 84)
            Text(snap.sealName)
                .font(.rounded(14, .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            moodBar.padding(.horizontal, 8)
            Text(statusText)
                .font(.rounded(12, .bold))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var medium: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                seal.frame(width: 92, height: 92)
                moodBar.frame(width: 80)
                Text("\(snap.moodState.emoji) \(snap.moodState.displayName)")
                    .font(.rounded(11, .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
            habitList(limit: 3)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                seal.frame(width: 110, height: 110)
                VStack(alignment: .leading, spacing: 6) {
                    Text(snap.sealName)
                        .font(.rounded(22, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("\(snap.moodState.emoji) \(snap.moodState.displayName)")
                        .font(.rounded(14, .bold))
                        .foregroundStyle(Theme.inkSoft)
                    moodBar
                    Text("🐟 \(snap.fish)")
                        .font(.rounded(14, .heavy))
                        .foregroundStyle(Theme.oceanDark)
                }
            }
            habitList(limit: 6)
        }
    }

    private func habitList(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(statusText)
                .font(.rounded(14, .heavy))
                .foregroundStyle(Theme.ink)
            if todays.isEmpty {
                Text(snap.onVacation ? "Klar en vane i appen, så svømmer jeg hjem." : "Ingen vaner i dag.")
                    .font(.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            ForEach(Array(sorted.prefix(limit))) { h in
                Button(intent: ToggleHabitIntent(habitID: h.id)) {
                    HStack(spacing: 8) {
                        Text(h.icon).font(.system(size: 16))
                        Text(h.name)
                            .font(.rounded(13, .bold))
                            .foregroundStyle(h.done >= h.target ? Theme.inkSoft : Theme.ink)
                            .strikethrough(h.done >= h.target)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if h.target > 1 && h.done < h.target {
                            Text("\(h.done)/\(h.target)")
                                .font(.rounded(11, .heavy))
                                .foregroundStyle(Theme.oceanDark)
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(h.done >= h.target ? Theme.mint : Color.white)
                            if h.done >= h.target {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.6)))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sorted: [WidgetHabit] {
        todays.sorted { a, b in
            let ad = a.done >= a.target, bd = b.done >= b.target
            return ad == bd ? false : !ad
        }
    }
}

// MARK: - Live Activity

struct SealLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SealActivityAttributes.self) { context in
            LiveActivityView(attributes: context.attributes, state: context.state)
                .padding(14)
                .activityBackgroundTint(Theme.oceanLight)
                .activitySystemActionForegroundColor(Theme.oceanDark)
        } dynamicIsland: { context in
            let st = MoodState(rawValue: context.state.moodStateRaw) ?? .content
            let color = SealColor(rawValue: context.attributes.colorRaw) ?? .gray
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SealFigure(color: color, state: st, animated: false).frame(width: 52, height: 52)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.done)/\(context.state.total)")
                        .font(.rounded(20, .heavy))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.message)
                        .font(.rounded(14, .semibold))
                        .foregroundStyle(.white)
                }
            } compactLeading: {
                Text("🦭")
            } compactTrailing: {
                Text("\(context.state.done)/\(context.state.total)")
                    .font(.rounded(13, .heavy))
                    .foregroundStyle(Theme.ocean)
            } minimal: {
                Text("🦭")
            }
        }
    }
}

struct LiveActivityView: View {
    let attributes: SealActivityAttributes
    let state: SealActivityAttributes.ContentState

    var body: some View {
        let st = MoodState(rawValue: state.moodStateRaw) ?? .content
        let color = SealColor(rawValue: attributes.colorRaw) ?? .gray
        let progress = state.total > 0 ? Double(state.done) / Double(state.total) : 0
        HStack(spacing: 14) {
            SealFigure(color: color, state: st, animated: false)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(attributes.sealName)
                        .font(.rounded(17, .heavy))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(state.done)/\(state.total)")
                        .font(.rounded(17, .heavy))
                        .foregroundStyle(Theme.oceanDark)
                }
                Text(state.message)
                    .font(.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white)
                        Capsule().fill(Theme.oceanDeep)
                            .frame(width: max(8, g.size.width * CGFloat(progress)))
                    }
                }
                .frame(height: 9)
            }
        }
    }
}
