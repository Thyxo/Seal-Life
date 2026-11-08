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

// ToggleHabitIntent og CompleteHabitIntent ligger i Shared/LiveActivitySupport.swift.

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
                    SeaBackground()
                }
        }
        .configurationDisplayName("Sælen")
        .description("Se sælens humør og afkryds dagens vaner.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Design: samme stil som Dynamic Island (Design/DynamicIsland/index.html, afsnittet "Hjemmeskærm").
// Mål fra Apples HIG: small 158, medium 338 × 158, large 338 × 354 pt, 16 pt standardmargin.

/// Hav-baggrund med bølger i bunden. Lys eller mørk efter systemets udseende.
struct SeaBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack(alignment: .bottom) {
            LinearGradient(colors: dark ? [Color(hex: 0x0D2131), Color(hex: 0x0F2E45), Color(hex: 0x123A57)]
                                        : [Color(hex: 0xEEF7FC), Color(hex: 0xD6ECF8), Color(hex: 0xC6E3F4)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            WaveShape(level: 0.6, phase: 0)
                .fill(dark ? Color(hex: 0x96D4F8).opacity(0.18) : Theme.oceanDeep.opacity(0.20))
                .frame(height: 40)
            WaveShape(level: 0.38, phase: 0.5)
                .fill(dark ? Color(hex: 0xBAE6FC).opacity(0.30) : Theme.oceanDeep.opacity(0.34))
                .frame(height: 40)
        }
    }
}

struct SealWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    let entry: SealEntry

    private var snap: SealSnapshot { entry.snapshot }
    private var state: SealActivityAttributes.ContentState { LiveActivityContent.state(from: snap, date: entry.date) }
    private var dark: Bool { scheme == .dark }
    private var fg: Color { dark ? .white : Theme.ink }
    private var soft: Color { dark ? .white.opacity(0.74) : Theme.inkSoft }
    private var mood: MoodState { state.allDone && !snap.onVacation ? .happy : snap.moodState }

    var body: some View {
        if snap.onVacation || state.habitList.isEmpty {
            restView
        } else {
            switch family {
            case .systemSmall: small
            case .systemLarge: large
            default: medium
            }
        }
    }

    // MARK: Byggeklodser

    private func color(of h: LiveHabit) -> Color {
        IslandPalette.color(state.habitList.firstIndex(of: h) ?? 0)
    }

    private var nextColor: Color {
        if let n = state.next { return dark ? color(of: n) : Theme.oceanDark }
        return dark ? IslandPalette.ocean : Theme.oceanDark
    }

    private func water(_ size: CGFloat) -> some View {
        WaterSeal(color: snap.color, mood: mood, progress: state.progress)
            .frame(width: size, height: size)
    }

    private var remaining: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(state.remaining)")
                .font(.rounded(22, .black))
                .foregroundStyle(nextColor)
                .contentTransition(.numericText(value: Double(state.remaining)))
                .widgetAccentable()
            Text("tilbage")
                .font(.rounded(11, .bold))
                .foregroundStyle(soft)
        }
    }

    private var eyebrow: some View {
        Text(state.next == nil ? "ALT KLARET" : "NÆSTE")
            .font(.rounded(10, .heavy))
            .tracking(1.2)
            .foregroundStyle(soft)
    }

    private func nextName(_ size: CGFloat) -> some View {
        Text(state.next?.name ?? "\(snap.sealName) er hjemme 💙")
            .font(.rounded(size, .heavy))
            .foregroundStyle(fg)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .id(state.next?.id ?? "done")
            .transition(.push(from: .bottom))
    }

    // MARK: Small: vandcirkel, næste vane og én knap

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                water(48)
                Spacer(minLength: 4)
                remaining
            }
            VStack(alignment: .leading, spacing: 2) {
                eyebrow
                nextName(15)
            }
            .padding(.top, 7)
            Spacer(minLength: 4)
            if let n = state.next {
                Button(intent: CompleteHabitIntent(habitID: n.id)) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy))
                        Text("\(n.icon) Klaret").font(.rounded(13.5, .black)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(Color(hex: 0x0B0B0B))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Capsule().fill(color(of: n)))
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(duration: 0.6), value: state.done)
    }

    // MARK: Medium: som den udvidede ø

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                water(56)
                VStack(alignment: .leading, spacing: 2) {
                    eyebrow
                    nextName(18)
                    Text("\(snap.sealName) · \(state.allDone ? "hjemme igen" : "mod \(snap.place)")")
                        .font(.rounded(11, .bold))
                        .foregroundStyle(soft)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                remaining
            }
            Spacer(minLength: 6)
            HabitSegmentBar(state: state, dark: dark)
        }
        .animation(.spring(duration: 0.6), value: state.done)
    }

    // MARK: Large: status og liste med afkrydsning (som Påmindelser)

    private var large: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                water(64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(snap.sealName).font(.rounded(20, .heavy)).foregroundStyle(fg)
                    Text("\(mood.displayName) · \(state.allDone ? "hjemme fra" : "mod") \(snap.place)")
                        .font(.rounded(11, .bold)).foregroundStyle(soft).lineLimit(1)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(state.done)/\(state.total)")
                        .font(.rounded(22, .black))
                        .foregroundStyle(dark ? IslandPalette.ocean : Theme.oceanDark)
                        .contentTransition(.numericText(value: Double(state.done)))
                        .widgetAccentable()
                    Text("i dag").font(.rounded(11, .bold)).foregroundStyle(soft)
                }
            }
            VStack(spacing: 4) {
                ForEach(state.habitList.prefix(6)) { h in
                    row(h)
                }
            }
            .padding(.top, 14)
            Spacer(minLength: 6)
            Text("🐟 \(snap.fish) fisk · \(state.allDone ? "\(snap.sealName) er hjemme med en historie" : "Klar resten, så kommer \(snap.sealName) hjem")")
                .font(.rounded(11, .bold))
                .foregroundStyle(soft)
                .lineLimit(1)
                .padding(.bottom, 18)
        }
        .animation(.spring(duration: 0.6), value: state.done)
    }

    private func row(_ h: LiveHabit) -> some View {
        let c = color(of: h)
        return HStack(spacing: 9) {
            Text(h.icon).font(.system(size: 15)).frame(width: 18)
            Text(h.name)
                .font(.rounded(13.5, .heavy))
                .foregroundStyle(h.isDone ? soft : fg)
                .strikethrough(h.isDone)
                .lineLimit(1)
            Spacer(minLength: 4)
            if h.target > 1 && !h.isDone {
                Text("\(h.done)/\(h.target)")
                    .font(.rounded(11, .heavy))
                    .foregroundStyle(dark ? c : Theme.oceanDark)
            }
            Button(intent: ToggleHabitIntent(habitID: h.id)) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(h.isDone ? c : Color.clear)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(c, lineWidth: 2)
                    if h.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x0B0B0B))
                    }
                }
                .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .frame(height: 32)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(dark ? Color.white.opacity(0.08) : Color.white.opacity(0.62)))
    }

    // MARK: Ferie / fridag

    private var statusText: String {
        if snap.onVacation { return "På ferie 🏝️" }
        return "Fridag 🌿"
    }

    private var restView: some View {
        VStack(spacing: 6) {
            water(family == .systemSmall ? 72 : 84)
            Text(snap.sealName).font(.rounded(15, .heavy)).foregroundStyle(fg)
            Text(statusText).font(.rounded(12, .bold)).foregroundStyle(soft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
