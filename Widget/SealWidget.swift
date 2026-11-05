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
//
// Design: "Næste vane" (variant 2) med vandcirklen fra "Rejsen" (variant 3) som minimal.
// Se Design/DynamicIsland/index.html. Mål og regler fra Apples HIG (Live Activities):
// compact ≤ 52,33 pt pr. side, expanded 371 × 84–160 pt, koncentriske marginer, animationer ≤ 2 s.

/// Farver på sort baggrund i øen – én pr. vane, i rækkefølge.
enum IslandPalette {
    static let ocean = Color(hex: 0x6CC4F5)
    static let sun = Color(hex: 0xFFC94D)
    static let habits: [Color] = [Color(hex: 0x6FE0B0), ocean, Color(hex: 0xB9B0FF), sun, Color(hex: 0xFF8A8A)]
    static func color(_ index: Int) -> Color { habits[index % habits.count] }
}

struct SealLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SealActivityAttributes.self) { context in
            LiveActivityView(attributes: context.attributes, state: context.state)
                .padding(14)
                .activityBackgroundTint(Theme.oceanLight)
                .activitySystemActionForegroundColor(Theme.oceanDark)
        } dynamicIsland: { context in
            let s = context.state
            let color = SealColor(rawValue: context.attributes.colorRaw) ?? .gray
            let mood: MoodState = s.allDone ? .happy : (MoodState(rawValue: s.moodStateRaw) ?? .content)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SealFigure(color: color, state: mood, animated: false)
                        .frame(width: 38, height: 38)
                        .padding(.leading, 12)
                        .padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(s.remaining)")
                            .font(.rounded(22, .black))
                            .foregroundStyle(nextColor(s))
                            .contentTransition(.numericText(value: Double(s.remaining)))
                        Text(s.remaining == 1 ? "vane tilbage" : "vaner tilbage")
                            .font(.rounded(11, .bold))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        NextHabitTitle(state: s, sealName: context.attributes.sealName, dark: true)
                            .padding(.horizontal, 12)
                        SeaPanel(dark: true, corners: 34) {
                            HabitSegmentBar(state: s, dark: true)
                        }
                    }
                    .animation(.spring(duration: 0.6), value: s.done)
                }
            } compactLeading: {
                if let next = s.next, let idx = s.habitList.firstIndex(of: next) {
                    Text(next.icon)
                        .font(.system(size: 14))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(IslandPalette.color(idx)))
                        .id(next.id)
                        .transition(.push(from: .bottom))
                } else {
                    SealFigure(color: color, state: .happy, animated: false).frame(width: 26, height: 26)
                }
            } compactTrailing: {
                MiniBars(state: s)
                    .padding(.trailing, 4)
            } minimal: {
                WaterSeal(color: color, mood: mood, progress: s.progress)
                    .frame(width: 27, height: 27)
            }
            .contentMargins(.leading, 5, for: .compactLeading)
            .contentMargins(.all, 5, for: .minimal)
            .contentMargins(.all, 10, for: .expanded)
            .keylineTint(Theme.ocean)
        }
    }

    private func nextColor(_ s: SealActivityAttributes.ContentState) -> Color {
        guard let n = s.next, let i = s.habitList.firstIndex(of: n) else { return IslandPalette.ocean }
        return IslandPalette.color(i)
    }
}

// MARK: Byggeklodser

/// "NÆSTE  Læs 20 min" – glider op, når næste vane skifter.
struct NextHabitTitle: View {
    let state: SealActivityAttributes.ContentState
    let sealName: String
    let dark: Bool

    var body: some View {
        let fg: Color = dark ? .white : Theme.ink
        let soft: Color = dark ? .white.opacity(0.74) : Theme.inkSoft
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(state.next == nil ? "ALT KLARET" : "NÆSTE")
                .font(.rounded(10, .heavy))
                .tracking(1.2)
                .foregroundStyle(soft)
            Group {
                if let n = state.next {
                    Text(n.target > 1 ? "\(n.name) \(n.done)/\(n.target)" : n.name)
                } else {
                    Text("\(sealName) er hjemme 💙")
                }
            }
            .font(.rounded(18, .heavy))
            .foregroundStyle(fg)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .id(state.next?.id ?? "done")
            .transition(.push(from: .bottom))
        }
    }
}

/// Lyst havpanel med bølger i bunden – en indsat beholder, koncentrisk med øens hjørner.
struct SeaPanel<Content: View>: View {
    let dark: Bool
    let corners: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: corners,
                                           bottomTrailingRadius: corners, topTrailingRadius: 18,
                                           style: .continuous)
        let base: Color = dark ? IslandPalette.ocean : .white
        content
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    LinearGradient(colors: [base.opacity(dark ? 0.18 : 0.45), base.opacity(dark ? 0.38 : 0.75)],
                                   startPoint: .top, endPoint: .bottom)
                    WaveShape(level: 0.55, phase: 0)
                        .fill((dark ? Color(hex: 0x96D4F8) : Theme.oceanDeep).opacity(dark ? 0.38 : 0.22))
                        .frame(height: 17)
                    WaveShape(level: 0.35, phase: 0.5)
                        .fill((dark ? Color(hex: 0xBAE6FC) : Theme.oceanDeep).opacity(dark ? 0.6 : 0.38))
                        .frame(height: 17)
                }
            }
            .clipShape(shape)
    }
}

/// Bjælke med ét felt pr. vane. Det aktuelle felt er den eneste knap (Apple: helst ét interaktivt element).
struct HabitSegmentBar: View {
    let state: SealActivityAttributes.ContentState
    let dark: Bool

    var body: some View {
        let list = state.habitList
        HStack(spacing: 4) {
            ForEach(Array(list.enumerated()), id: \.element.id) { i, h in
                let shape = UnevenRoundedRectangle(topLeadingRadius: i == 0 ? 19 : 8, bottomLeadingRadius: i == 0 ? 19 : 8,
                                                   bottomTrailingRadius: i == list.count - 1 ? 19 : 8,
                                                   topTrailingRadius: i == list.count - 1 ? 19 : 8, style: .continuous)
                let c = IslandPalette.color(i)
                if h.id == state.next?.id {
                    Button(intent: CompleteHabitIntent(habitID: h.id)) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy))
                            Text("\(h.icon) Klaret").font(.rounded(14, .black)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(Color(hex: 0x0B0B0B))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(shape.fill(c))
                    }
                    .buttonStyle(.plain)
                    .layoutPriority(1)
                    .frame(minWidth: 96)
                } else if h.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(dark ? c : Theme.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(shape.fill(c.opacity(dark ? 0.3 : 0.55)))
                } else {
                    Text(h.icon)
                        .font(.system(size: 14))
                        .opacity(0.55)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(shape.fill(dark ? Color.white.opacity(0.11) : Theme.ink.opacity(0.08)))
                }
            }
        }
        .frame(height: 38)
    }
}

/// Små streger i compact: farvede = klaret, lys = næste.
struct MiniBars: View {
    let state: SealActivityAttributes.ContentState

    var body: some View {
        let list = Array(state.habitList.prefix(7))
        HStack(spacing: 3) {
            ForEach(Array(list.enumerated()), id: \.element.id) { i, h in
                Capsule()
                    .fill(h.isDone ? IslandPalette.color(i)
                          : (h.id == state.next?.id ? Color.white.opacity(0.55) : Color.white.opacity(0.18)))
                    .frame(width: 4, height: 15)
            }
        }
    }
}

/// Sælen i en cirkel, hvor vandet stiger med dagens fremskridt (fra variant "Rejsen").
struct WaterSeal: View {
    let color: SealColor
    let mood: MoodState
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(IslandPalette.ocean.opacity(0.14))
                SealFigure(color: color, state: mood, animated: false)
                    .frame(width: d * 0.8, height: d * 0.8)
                    .offset(y: -d * 0.04)
                WaveShape(level: 0.2 + 0.3 * progress, phase: 0)
                    .fill(Color(hex: 0x3E9BD6).opacity(0.88))
            }
            .frame(width: d, height: d)
            .clipShape(Circle())
            .animation(.spring(duration: 0.9), value: progress)
        }
    }
}

/// Bølge, der fylder `level` (0–1) af højden nedefra. Animerbar.
struct WaveShape: Shape {
    var level: Double
    var phase: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let y: CGFloat = rect.maxY - rect.height * CGFloat(level)
        let amp: CGFloat = max(1.5, rect.height * 0.07)
        let waves: Double = 2
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: y))
        let steps = 24
        for k in 1...steps {
            let t = Double(k) / Double(steps)
            let x: CGFloat = rect.minX + rect.width * CGFloat(t)
            let a: Double = (t * waves + phase) * 2 * Double.pi
            p.addLine(to: CGPoint(x: x, y: y + CGFloat(sin(a)) * amp))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: Låseskærm (lys, 14 pt marginer)

struct LiveActivityView: View {
    let attributes: SealActivityAttributes
    let state: SealActivityAttributes.ContentState

    var body: some View {
        let color = SealColor(rawValue: attributes.colorRaw) ?? .gray
        let mood: MoodState = state.allDone ? .happy : (MoodState(rawValue: state.moodStateRaw) ?? .content)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                WaterSeal(color: color, mood: mood, progress: state.progress)
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.sealName).font(.rounded(15, .heavy)).foregroundStyle(Theme.ink)
                    Text(state.message).font(.rounded(11, .bold)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(state.remaining)")
                        .font(.rounded(22, .black))
                        .foregroundStyle(Theme.oceanDark)
                        .contentTransition(.numericText(value: Double(state.remaining)))
                    Text(state.remaining == 1 ? "vane tilbage" : "vaner tilbage")
                        .font(.rounded(11, .bold)).foregroundStyle(Theme.inkSoft)
                }
            }
            if !state.habitList.isEmpty {
                NextHabitTitle(state: state, sealName: attributes.sealName, dark: false)
                SeaPanel(dark: false, corners: 14) {
                    HabitSegmentBar(state: state, dark: false)
                }
            }
        }
        .animation(.spring(duration: 0.6), value: state.done)
    }
}
