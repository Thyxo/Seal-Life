import Foundation
import UserNotifications
import ActivityKit
import SwiftData
import SwiftUI
import UIKit

// MARK: - Lokale notifikationer

enum NotificationScheduler {
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    static var maxPerDay: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "maxRemindersPerDay")
            return v == 0 ? Tuning.maxRemindersPerDay : v
        }
        set { UserDefaults.standard.set(newValue, forKey: "maxRemindersPerDay") }
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private struct Planned {
        let id: String
        let components: DateComponents
        let title: String
        let body: String
        let repeats: Bool
    }

    private static let lines: [String] = [
        "Jeg er lidt sulten. Har du tid til %@?",
        "Psst… %@ venter på dig. Helt uden stress.",
        "Jeg ligger her og vipper med luffen. Måske %@ nu?",
        "Hvis du klarer %@, deler jeg min fisk. Næsten.",
        "Lille sæl-påmindelse: %@. Du kan godt.",
    ]

    static func reschedule(store: GameStore) {
        let plan = buildPlan(store: store)
        let isOn = enabled
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map(\.identifier).filter { $0.hasPrefix("seal-") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            guard isOn else { return }
            for p in plan {
                let content = UNMutableNotificationContent()
                content.title = p.title
                content.body = p.body
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: p.components, repeats: p.repeats)
                center.add(UNNotificationRequest(identifier: p.id, content: content, trigger: trigger))
            }
        }
    }

    private static func buildPlan(store: GameStore) -> [Planned] {
        guard store.profile.onboarded else { return [] }
        let cal = Calendar.current
        let now = Date()
        let name = store.profile.name
        var result: [Planned] = []

        result.append(Planned(
            id: "seal-backup",
            components: DateComponents(hour: Tuning.backupReminderHour, weekday: Tuning.backupReminderWeekday),
            title: "\(name) 🦭",
            body: "Skal vi lave en lille backup? Det tager fem sekunder, og så er alle mine minder i sikkerhed.",
            repeats: true))

        for offset in 0..<Tuning.reminderDaysAhead {
            guard let date = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now)) else { continue }
            let key = DayKey.key(for: date)

            if store.profile.onVacation {
                // Ét blidt postkort om dagen i stedet for påmindelser.
                var c = cal.dateComponents([.year, .month, .day], from: date)
                c.hour = 18
                c.minute = 0
                if let d = cal.date(from: c), d > now {
                    result.append(Planned(id: "seal-vac-\(key)", components: c, title: "Postkort fra \(store.profile.vacationPlace) 💌",
                                          body: "Her er dejligt, men jeg savner dig lidt. Én vane, og jeg begynder at svømme hjem.",
                                          repeats: false))
                }
                continue
            }

            var due = store.scheduled(on: date).filter { $0.reminderEnabled }
            if offset == 0 {
                due = due.filter { store.count($0) < $0.timesPerDay }
            }
            let times = Array(Set(due.map(\.reminderMinutes))).sorted()
            var chosen: [Int]
            if times.count <= maxPerDay {
                chosen = times
            } else if maxPerDay == 1 {
                chosen = [times[0]]
            } else {
                chosen = [times[0], times[times.count - 1]]
            }
            for (i, minutes) in chosen.enumerated() {
                var c = cal.dateComponents([.year, .month, .day], from: date)
                c.hour = minutes / 60
                c.minute = minutes % 60
                guard let fire = cal.date(from: c), fire > now else { continue }
                // Nævn den vane der passer bedst til tidspunktet.
                let related = due.filter { abs($0.reminderMinutes - minutes) < 1 }
                let habitName = (related.first ?? due.first)?.name.lowercased() ?? "en lille vane"
                let line = lines[DayKey.stableHash(key + "\(i)") % lines.count]
                var body = String(format: line, habitName)
                if related.count > 1 { body += " (og \(related.count - 1) mere)" }
                result.append(Planned(id: "seal-\(key)-\(i)", components: c, title: "\(name) 🦭", body: body, repeats: false))
            }
        }
        return result
    }
}

// MARK: - Live Activity (lokal, ingen push)

enum LiveActivityManager {
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "liveActivityEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "liveActivityEnabled") }
    }

    static func sync(store: GameStore) {
        let attrs = SealActivityAttributes(sealName: store.profile.name, colorRaw: store.profile.colorRaw, dayKey: store.todayKey)
        let message: String
        if store.allDoneToday {
            message = "Hjemme igen – alt klaret! 💙"
        } else if store.todayDone == 0 {
            message = "Svømmer ud til \(store.adventurePlace.name)"
        } else {
            message = "Ved \(store.adventurePlace.name) · \(store.remainingToday) tilbage"
        }
        let state = SealActivityAttributes.ContentState(
            mood: store.profile.mood, moodStateRaw: store.moodState.rawValue,
            done: store.todayDone, total: store.todayTotal,
            place: store.adventurePlace.name, message: message)
        let shouldShow = enabled && store.profile.onboarded && store.todayTotal > 0 && !store.profile.onVacation
        let allDone = store.allDoneToday
        let today = store.todayKey

        Task {
            for a in Activity<SealActivityAttributes>.activities where a.attributes.dayKey != today || !shouldShow {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            guard shouldShow, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let content = ActivityContent(state: state, staleDate: nil)
            let current = Activity<SealActivityAttributes>.activities.first { a in
                a.attributes.dayKey == today && a.activityState == .active
            }
            if let current {
                if allDone {
                    await current.end(content, dismissalPolicy: .after(Date().addingTimeInterval(2 * 3600)))
                } else {
                    await current.update(content)
                }
            } else if !allDone {
                _ = try? Activity<SealActivityAttributes>.request(attributes: attrs, content: content, pushType: nil)
            }
        }
    }
}

// MARK: - Backup (JSON)

struct BackupFile: Codable {
    struct ProfileDTO: Codable {
        var name: String
        var colorRaw: String
        var mood: Double
        var fish: Int
        var owned: [String]
        var hat: String?
        var glasses: String?
        var neck: String?
        var background: String
        var lastProcessedDayKey: String
        var missedStreak: Int
        var onVacation: Bool
        var vacationPlace: String
        var returnStreak: Int
        var daysAtZero: Int
        var bonusDayKey: String
        var storySeenDayKey: String
        var moodFishDayKey: String
        var createdAt: Date
    }

    struct HabitDTO: Codable {
        var id: UUID
        var name: String
        var icon: String
        var weekdays: [Int]
        var timesPerDay: Int
        var reminderEnabled: Bool
        var reminderMinutes: Int
        var createdAt: Date
        var sortOrder: Int
        var archived: Bool
    }

    struct LogDTO: Codable {
        var habitID: UUID
        var dayKey: String
        var count: Int
    }

    struct MoodDTO: Codable {
        var dayKey: String
        var mood: Int
        var note: String
        var createdAt: Date
    }

    var app: String = "Saelliv"
    var version: Int = 1
    var exportedAt: Date
    var profile: ProfileDTO
    var habits: [HabitDTO]
    var logs: [LogDTO]
    var moods: [MoodDTO]
    /// Tøj-justeringer (findes kun i nyere backups).
    var fits: [String: ItemFit]? = nil
}

enum BackupError: LocalizedError {
    case unreadable
    var errorDescription: String? { "Filen kunne ikke læses som en Sælliv-backup." }
}

enum BackupManager {
    static func makeFile(store: GameStore) throws -> URL {
        let p = store.profile
        let profile = BackupFile.ProfileDTO(
            name: p.name, colorRaw: p.colorRaw, mood: p.mood, fish: p.fish, owned: p.owned,
            hat: p.hat, glasses: p.glasses, neck: p.neck, background: p.background,
            lastProcessedDayKey: p.lastProcessedDayKey, missedStreak: p.missedStreak,
            onVacation: p.onVacation, vacationPlace: p.vacationPlace, returnStreak: p.returnStreak,
            daysAtZero: p.daysAtZero, bonusDayKey: p.bonusDayKey, storySeenDayKey: p.storySeenDayKey,
            moodFishDayKey: p.moodFishDayKey, createdAt: p.createdAt)
        let habits = ((try? store.context.fetch(FetchDescriptor<Habit>())) ?? []).map {
            BackupFile.HabitDTO(id: $0.id, name: $0.name, icon: $0.icon, weekdays: $0.weekdays,
                                timesPerDay: $0.timesPerDay, reminderEnabled: $0.reminderEnabled,
                                reminderMinutes: $0.reminderMinutes, createdAt: $0.createdAt,
                                sortOrder: $0.sortOrder, archived: $0.archived)
        }
        let logs = ((try? store.context.fetch(FetchDescriptor<HabitLog>())) ?? [])
            .filter { $0.count > 0 }
            .map { BackupFile.LogDTO(habitID: $0.habitID, dayKey: $0.dayKey, count: $0.count) }
        let moods = store.allMoods().map {
            BackupFile.MoodDTO(dayKey: $0.dayKey, mood: $0.mood, note: $0.note, createdAt: $0.createdAt)
        }
        let file = BackupFile(exportedAt: Date(), profile: profile, habits: habits, logs: logs, moods: moods,
                              fits: FitStore.shared.fits)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(file)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Saelliv-backup-\(DayKey.key()).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func restore(from url: URL, store: GameStore) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let file = try? dec.decode(BackupFile.self, from: data) else { throw BackupError.unreadable }

        let ctx = store.context
        try ctx.delete(model: Habit.self)
        try ctx.delete(model: HabitLog.self)
        try ctx.delete(model: MoodEntry.self)

        for h in file.habits {
            let m = Habit(name: h.name, icon: h.icon, weekdays: h.weekdays, timesPerDay: h.timesPerDay,
                          reminderEnabled: h.reminderEnabled, reminderMinutes: h.reminderMinutes,
                          sortOrder: h.sortOrder, createdAt: h.createdAt)
            m.id = h.id
            m.archived = h.archived
            ctx.insert(m)
        }
        for l in file.logs { ctx.insert(HabitLog(habitID: l.habitID, dayKey: l.dayKey, count: l.count)) }
        for m in file.moods {
            let e = MoodEntry(dayKey: m.dayKey, mood: m.mood, note: m.note)
            e.createdAt = m.createdAt
            ctx.insert(e)
        }

        let p = store.profile
        let d = file.profile
        p.name = d.name
        p.colorRaw = d.colorRaw
        p.mood = d.mood
        p.fish = d.fish
        p.owned = d.owned
        p.hat = d.hat
        p.glasses = d.glasses
        p.neck = d.neck
        p.background = d.background
        p.lastProcessedDayKey = d.lastProcessedDayKey
        p.missedStreak = d.missedStreak
        p.onVacation = d.onVacation
        p.vacationPlace = d.vacationPlace
        p.returnStreak = d.returnStreak
        p.daysAtZero = d.daysAtZero
        p.bonusDayKey = d.bonusDayKey
        p.storySeenDayKey = d.storySeenDayKey
        p.moodFishDayKey = d.moodFishDayKey
        p.createdAt = d.createdAt
        p.onboarded = true
        p.lastBackup = Date()

        if let fits = file.fits { FitStore.shared.replaceAll(fits) }

        try ctx.save()
        store.reloadHabits()
        store.onForeground()
        store.refreshToday()
        store.dataVersion += 1
    }
}

// MARK: - Del-ark

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct ShareFile: Identifiable {
    let id = UUID()
    let url: URL
}
