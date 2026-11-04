import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// En lille kopi af appens tilstand, som widgetten kan læse (JSON i App Group-mappen).
struct WidgetHabit: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var icon: String
    var weekdays: [Int]
    var target: Int
    var done: Int
}

struct SealSnapshot: Codable {
    var sealName: String
    var colorRaw: String
    var mood: Double
    var daysAtZero: Int
    var onVacation: Bool
    var vacationPlace: String
    var dayKey: String
    var fish: Int
    var place: String
    var hat: String?
    var glasses: String?
    var neck: String?
    var habits: [WidgetHabit]

    static let fileName = "snapshot.json"

    var color: SealColor { SealColor(rawValue: colorRaw) ?? .gray }

    var moodState: MoodState {
        MoodState.from(mood: mood, daysAtZero: daysAtZero, onVacation: onVacation)
    }

    /// Vaner planlagt på en given dag, med dagens afkrydsninger hvis snapshot er fra samme dag.
    func habits(on date: Date) -> [WidgetHabit] {
        let wd = DayKey.weekday(date)
        let sameDay = DayKey.key(for: date) == dayKey
        return habits
            .filter { $0.weekdays.contains(wd) }
            .map { h in
                var c = h
                if !sameDay { c.done = 0 }
                return c
            }
    }

    static var placeholder: SealSnapshot {
        SealSnapshot(sealName: "Sæl", colorRaw: SealColor.gray.rawValue, mood: 75, daysAtZero: 0,
                     onVacation: false, vacationPlace: "", dayKey: DayKey.key(), fish: 20, place: "Nyhavn",
                     hat: nil, glasses: nil, neck: nil,
                     habits: [
                        WidgetHabit(id: "a", name: "Drik vand", icon: "💧", weekdays: Array(1...7), target: 1, done: 1),
                        WidgetHabit(id: "b", name: "Gåtur", icon: "🚶", weekdays: Array(1...7), target: 1, done: 0),
                        WidgetHabit(id: "c", name: "Læs lidt", icon: "📚", weekdays: Array(1...7), target: 1, done: 0),
                     ])
    }

    static var fileURL: URL { AppGroup.containerURL.appendingPathComponent(fileName) }

    static func load() -> SealSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SealSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: SealSnapshot.fileURL, options: .atomic)
    }

    /// Kaldes fra widgettens AppIntent: afkryds/fortryd og læg ændringen i kø til appen.
    static func toggleFromWidget(habitID: String) {
        guard var snap = load() else { return }
        let today = DayKey.key()
        if snap.dayKey != today {
            snap.dayKey = today
            for i in snap.habits.indices { snap.habits[i].done = 0 }
        }
        guard let i = snap.habits.firstIndex(where: { $0.id == habitID }) else { return }
        let delta = snap.habits[i].done >= snap.habits[i].target ? -1 : 1
        snap.habits[i].done = max(0, snap.habits[i].done + delta)
        snap.mood = min(Tuning.moodMax, max(0, snap.mood + Double(delta) * Tuning.moodPerCompletion))
        snap.fish = max(0, snap.fish + delta * Tuning.fishPerCompletion)
        snap.save()
        PendingQueue.append(PendingToggle(habitID: habitID, dayKey: today, delta: delta))
    }
}

struct PendingToggle: Codable {
    var habitID: String
    var dayKey: String
    var delta: Int
}

enum PendingQueue {
    static var fileURL: URL { AppGroup.containerURL.appendingPathComponent("pending.json") }

    static func load() -> [PendingToggle] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([PendingToggle].self, from: data)) ?? []
    }

    static func append(_ t: PendingToggle) {
        var list = load()
        list.append(t)
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    static func drain() -> [PendingToggle] {
        let list = load()
        try? FileManager.default.removeItem(at: fileURL)
        return list
    }
}

// MARK: - Live Activity

#if canImport(ActivityKit)
struct SealActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var mood: Double
        var moodStateRaw: String
        var done: Int
        var total: Int
        var place: String
        var message: String
    }

    var sealName: String
    var colorRaw: String
    var dayKey: String
}
#endif
