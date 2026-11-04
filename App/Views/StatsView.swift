import SwiftUI

struct StatsEngine {
    let habits: [Habit]
    let logs: [String: [UUID: Int]]
    let cal = Calendar.current
    let today = Calendar.current.startOfDay(for: Date())

    func isScheduled(_ h: Habit, _ d: Date) -> Bool {
        h.weekdays.contains(DayKey.weekday(d)) && cal.startOfDay(for: h.createdAt) <= d
    }

    func isComplete(_ h: Habit, _ d: Date) -> Bool {
        (logs[DayKey.key(for: d)]?[h.id] ?? 0) >= h.timesPerDay
    }

    private func days(from start: Date) -> [Date] {
        var list: [Date] = []
        var d = max(cal.startOfDay(for: start), cal.date(byAdding: .day, value: -400, to: today) ?? today)
        while d <= today {
            list.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? today.addingTimeInterval(86400)
        }
        return list
    }

    func streak(_ h: Habit) -> (current: Int, best: Int) {
        var run = 0, best = 0
        for d in days(from: h.createdAt) where isScheduled(h, d) {
            if isComplete(h, d) {
                run += 1
                best = max(best, run)
            } else if d != today {
                run = 0
            }
        }
        return (run, best)
    }

    /// Samlet: dage med planlagte vaner, hvor mindst én blev klaret.
    func overall() -> (current: Int, best: Int) {
        guard let first = habits.map(\.createdAt).min() else { return (0, 0) }
        var run = 0, best = 0
        for d in days(from: first) {
            let sched = habits.filter { isScheduled($0, d) }
            if sched.isEmpty { continue }
            let any = (logs[DayKey.key(for: d)]?.values.contains { $0 > 0 }) ?? false
            if any {
                run += 1
                best = max(best, run)
            } else if d != today {
                run = 0
            }
        }
        return (run, best)
    }

    func ratio(_ d: Date) -> Double? {
        let sched = habits.filter { isScheduled($0, d) }
        guard !sched.isEmpty else { return nil }
        let c = logs[DayKey.key(for: d)] ?? [:]
        let total = sched.reduce(0) { $0 + $1.timesPerDay }
        let done = sched.reduce(0) { $0 + min(c[$1.id] ?? 0, $1.timesPerDay) }
        return total > 0 ? Double(done) / Double(total) : nil
    }

    var totalCompletions: Int {
        logs.values.reduce(0) { $0 + $1.values.reduce(0, +) }
    }

    func lastDays(_ n: Int) -> [Date] {
        (0..<n).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }
}

struct StatsView: View {
    @Environment(GameStore.self) private var store
    @State private var appeared = false

    var body: some View {
        let _ = store.dataVersion
        let engine = StatsEngine(habits: store.habits, logs: store.allLogs())
        let overall = engine.overall()
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistik")
                    .font(.rounded(32, .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    StatTile(emoji: "🌊", value: overall.current, label: "dage i træk")
                        .appearIn(0.02)
                    StatTile(emoji: "🏆", value: overall.best, label: "rekord")
                        .appearIn(0.08)
                    StatTile(emoji: "✅", value: engine.totalCompletions, label: "i alt")
                        .appearIn(0.14)
                }

                heatmap(engine).appearIn(0.18)
                week(engine).appearIn(0.24)
                moods.appearIn(0.3)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Pr. vane")
                        .font(.rounded(19, .heavy))
                        .foregroundStyle(Theme.ink)
                    if store.habits.isEmpty {
                        Text("Ingen vaner endnu.")
                            .font(.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    ForEach(Array(store.habits.enumerated()), id: \.element.id) { i, h in
                        let s = engine.streak(h)
                        HStack(spacing: 12) {
                            Text(h.icon).font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.sandLight))
                            Text(h.name)
                                .font(.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Spacer()
                            Label("\(s.current)", systemImage: "water.waves")
                                .font(.rounded(15, .heavy))
                                .foregroundStyle(Theme.oceanDeep)
                            Label("\(s.best)", systemImage: "trophy.fill")
                                .font(.rounded(15, .heavy))
                                .foregroundStyle(Theme.sun)
                        }
                        .card()
                        .appearIn(0.34 + Double(i) * 0.05)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.cream.ignoresSafeArea())
        .onAppear { appeared = true }
    }

    private func heatmap(_ engine: StatsEngine) -> some View {
        let days = engine.lastDays(30)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Sidste 30 dage")
                .font(.rounded(19, .heavy))
                .foregroundStyle(Theme.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    HeatCell(ratio: engine.ratio(d), isToday: i == days.count - 1, delay: Double(i) * 0.018)
                }
            }
            HStack(spacing: 6) {
                Text("Mindre").font(.rounded(11, .semibold)).foregroundStyle(Theme.inkSoft)
                ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { r in
                    RoundedRectangle(cornerRadius: 4).fill(HeatCell.color(r)).frame(width: 14, height: 14)
                }
                Text("Mere").font(.rounded(11, .semibold)).foregroundStyle(Theme.inkSoft)
            }
        }
        .card()
    }

    private func week(_ engine: StatsEngine) -> some View {
        let days = engine.lastDays(7)
        let names = [1: "S", 2: "M", 3: "T", 4: "O", 5: "T", 6: "F", 7: "L"]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Ugen")
                .font(.rounded(19, .heavy))
                .foregroundStyle(Theme.ink)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    VStack(spacing: 6) {
                        WeekBar(ratio: engine.ratio(d) ?? 0, hasPlan: engine.ratio(d) != nil, delay: Double(i) * 0.06)
                            .frame(height: 110)
                        Text(names[DayKey.weekday(d)] ?? "")
                            .font(.rounded(13, .bold))
                            .foregroundStyle(i == days.count - 1 ? Theme.oceanDark : Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .card()
    }

    private var moods: some View {
        let entries = Array(store.allMoods().suffix(14))
        return VStack(alignment: .leading, spacing: 10) {
            Text("Humør-dagbog")
                .font(.rounded(19, .heavy))
                .foregroundStyle(Theme.ink)
            if entries.isEmpty {
                Text("Når du laver et humør-tjek, dukker det op her.")
                    .font(.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(entries.enumerated()), id: \.offset) { i, e in
                            VStack(spacing: 4) {
                                Text(MoodChoice(rawValue: e.mood)?.emoji ?? "🙂").font(.system(size: 28))
                                Text(shortDate(e.dayKey))
                                    .font(.rounded(11, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.ice))
                            .appearIn(Double(i) * 0.03)
                        }
                    }
                }
                if let last = entries.last, !last.note.isEmpty {
                    Text("“\(last.note)”")
                        .font(.rounded(14, .medium))
                        .foregroundStyle(Theme.ink)
                        .italic()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func shortDate(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 3, let d = Int(parts[2]), let m = Int(parts[1]) else { return key }
        return "\(d)/\(m)"
    }
}

struct StatTile: View {
    let emoji: String
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 26)).floating(3, duration: 2)
            Text("\(value)")
                .font(.rounded(26, .heavy))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: Double(value)))
            Text(label)
                .font(.rounded(12, .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
            .shadow(color: Theme.oceanDark.opacity(0.07), radius: 8, x: 0, y: 4))
    }
}

struct HeatCell: View {
    let ratio: Double?
    let isToday: Bool
    let delay: Double
    @State private var shown = false

    static func color(_ r: Double?) -> Color {
        guard let r else { return Theme.ice }
        if r <= 0 { return Theme.iceDark.opacity(0.6) }
        return Theme.oceanDeep.opacity(0.3 + 0.7 * r)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Self.color(ratio))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isToday ? Theme.sun : .clear, lineWidth: 2)
            )
            .scaleEffect(shown ? 1 : 0.1)
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) { shown = true }
            }
    }
}

struct WeekBar: View {
    let ratio: Double
    let hasPlan: Bool
    let delay: Double
    @State private var grow = false

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                Capsule().fill(Theme.ice)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.ocean, Theme.oceanDeep], startPoint: .top, endPoint: .bottom))
                    .frame(height: grow ? max(hasPlan && ratio > 0 ? 14 : 0, g.size.height * CGFloat(ratio)) : 0)
                if ratio >= 1 {
                    Text("⭐️").font(.system(size: 12)).offset(y: grow ? -g.size.height + 14 : 0).opacity(grow ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(delay)) { grow = true }
        }
    }
}
