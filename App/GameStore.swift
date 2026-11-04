import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@Observable
final class GameStore {
    @ObservationIgnored let container: ModelContainer
    @ObservationIgnored let context: ModelContext

    var profile: SealProfile
    var habits: [Habit] = []
    var todayCounts: [UUID: Int] = [:]
    var todayKey: String = DayKey.key()
    var todayMood: MoodEntry?

    /// UI-signaler
    var showStory = false
    var showWelcomeHome = false
    var rewardPulse = 0
    var dataVersion = 0

    init() {
        let schema = Schema([Habit.self, HabitLog.self, MoodEntry.self, SealProfile.self])
        let url = AppGroup.containerURL.appendingPathComponent("SealLife.store")
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let made: ModelContainer
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            made = c
        } else {
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            made = try! ModelContainer(for: schema, configurations: [mem])
        }
        let ctx = ModelContext(made)
        var found: SealProfile
        if let existing = try? ctx.fetch(FetchDescriptor<SealProfile>()).first {
            found = existing
        } else {
            found = SealProfile()
            ctx.insert(found)
            try? ctx.save()
        }
        container = made
        context = ctx
        profile = found
        reloadHabits()
        refreshToday()
    }

    // MARK: - Livscyklus

    func onForeground() {
        todayKey = DayKey.key()
        guard profile.onboarded else { return }
        applyPendingToggles()
        processElapsedDays()
        refreshToday()
        if allDoneToday && profile.storySeenDayKey != todayKey && !profile.onVacation {
            showStory = true
        }
        syncOutside()
    }

    func save() {
        try? context.save()
        dataVersion += 1
    }

    func reloadHabits() {
        let all = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        habits = all.filter { !$0.archived }
    }

    func refreshToday() {
        todayCounts = counts(for: todayKey)
        let k = todayKey
        todayMood = try? context.fetch(FetchDescriptor<MoodEntry>(predicate: #Predicate { $0.dayKey == k })).first
    }

    // MARK: - Opslag

    func counts(for key: String) -> [UUID: Int] {
        let k = key
        let logs = (try? context.fetch(FetchDescriptor<HabitLog>(predicate: #Predicate { $0.dayKey == k }))) ?? []
        var dict: [UUID: Int] = [:]
        for l in logs { dict[l.habitID, default: 0] += l.count }
        return dict
    }

    func allLogs() -> [String: [UUID: Int]] {
        let logs = (try? context.fetch(FetchDescriptor<HabitLog>())) ?? []
        var dict: [String: [UUID: Int]] = [:]
        for l in logs { dict[l.dayKey, default: [:]][l.habitID, default: 0] += l.count }
        return dict
    }

    func allMoods() -> [MoodEntry] {
        (try? context.fetch(FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\.dayKey)]))) ?? []
    }

    func scheduled(on date: Date) -> [Habit] {
        let wd = DayKey.weekday(date)
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return habits.filter { $0.weekdays.contains(wd) && cal.startOfDay(for: $0.createdAt) <= start }
    }

    var todayHabits: [Habit] { scheduled(on: Date()) }
    var otherHabits: [Habit] {
        let ids = Set(todayHabits.map(\.id))
        return habits.filter { !ids.contains($0.id) }
    }
    var todayTotal: Int { todayHabits.reduce(0) { $0 + $1.timesPerDay } }
    var todayDone: Int { todayHabits.reduce(0) { $0 + min(todayCounts[$1.id] ?? 0, $1.timesPerDay) } }
    var allDoneToday: Bool { todayTotal > 0 && todayDone >= todayTotal }
    var remainingToday: Int { max(0, todayTotal - todayDone) }

    func count(_ h: Habit) -> Int { todayCounts[h.id] ?? 0 }

    var moodState: MoodState {
        MoodState.from(mood: profile.mood, daysAtZero: profile.daysAtZero, onVacation: profile.onVacation)
    }

    var isNight: Bool {
        let h = Calendar.current.component(.hour, from: Date())
        return h >= Tuning.sleepHour || h < Tuning.wakeHour
    }

    /// Det sælen viser lige nu (sover om natten).
    var displayState: MoodState {
        if profile.onVacation { return .vacation }
        if isNight && (allDoneToday || todayTotal == 0) { return .sleeping }
        return moodState
    }

    var adventurePlace: AdventurePlace { Adventures.place(for: todayKey) }

    /// Er sælen ude at svømme lige nu?
    var isOnAdventure: Bool {
        !profile.onVacation && todayTotal > 0 && !allDoneToday && !isNight
    }

    var greeting: String {
        let name = profile.name
        if profile.onVacation {
            return "Hilsen fra \(profile.vacationPlace)! Klar en vane \(Tuning.vacationReturnStreak) dage i træk, så svømmer jeg hjem."
        }
        if displayState == .sleeping { return "Zzz… (\(name) drømmer om sild)" }
        if todayTotal == 0 { return "Fridag! Jeg ligger bare her og er rund." }
        if allDoneToday { return "Jeg er hjemme igen! Tak for i dag 💙" }
        switch moodState {
        case .sick: return "Jeg ligger under et tæppe. Én lille vane, og jeg får det bedre."
        case .sad: return "Jeg er lidt nede. Skal vi tage én lille ting sammen?"
        case .hungry: return "Min mave knurrer lidt… en vane eller to ville hjælpe."
        default:
            if todayDone == 0 { return "Jeg svømmer ud til \(adventurePlace.name)! Klar dagens vaner, så kommer jeg hjem med en historie." }
            return "Jeg er ved \(adventurePlace.name) nu. \(remainingToday) tilbage, så er jeg hjemme!"
        }
    }

    // MARK: - Onboarding

    func finishOnboarding(name: String, color: SealColor) {
        profile.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Sæl" : name.trimmingCharacters(in: .whitespaces)
        profile.color = color
        profile.onboarded = true
        profile.createdAt = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        profile.lastProcessedDayKey = DayKey.key(for: yesterday)
        if habits.isEmpty {
            addHabit(name: "Drik et glas vand", icon: "💧", weekdays: Array(1...7), times: 1, reminder: false, minutes: 540)
            addHabit(name: "Gå en lille tur", icon: "🚶", weekdays: Array(1...7), times: 1, reminder: true, minutes: 1020)
        }
        save()
        refreshToday()
        syncOutside()
    }

    // MARK: - Vaner

    func addHabit(name: String, icon: String, weekdays: [Int], times: Int, reminder: Bool, minutes: Int) {
        let order = (habits.map(\.sortOrder).max() ?? 0) + 1
        let h = Habit(name: name, icon: icon, weekdays: weekdays, timesPerDay: max(1, times),
                      reminderEnabled: reminder, reminderMinutes: minutes, sortOrder: order)
        context.insert(h)
        save()
        reloadHabits()
        syncOutside()
    }

    func updated(_ h: Habit) {
        save()
        reloadHabits()
        syncOutside()
    }

    func archive(_ h: Habit) {
        h.archived = true
        save()
        reloadHabits()
        syncOutside()
    }

    private func log(for id: UUID, dayKey: String) -> HabitLog {
        let k = dayKey
        let hid = id
        if let l = try? context.fetch(FetchDescriptor<HabitLog>(predicate: #Predicate { $0.dayKey == k && $0.habitID == hid })).first {
            return l
        }
        let l = HabitLog(habitID: id, dayKey: dayKey, count: 0)
        context.insert(l)
        return l
    }

    /// Tryk på afkrydsning: +1, eller fortryd én hvis vanen allerede er fuld.
    @discardableResult
    func tap(_ h: Habit) -> Bool {
        if count(h) >= h.timesPerDay {
            undo(h)
            return false
        }
        complete(h)
        return true
    }

    func complete(_ h: Habit, dayKey: String? = nil, sync: Bool = true) {
        let key = dayKey ?? todayKey
        let l = log(for: h.id, dayKey: key)
        guard l.count < h.timesPerDay else { return }
        let wasAllDone = allDoneToday
        l.count += 1
        if key == todayKey { todayCounts[h.id] = l.count }

        profile.fish += Tuning.fishPerCompletion
        profile.mood = min(Tuning.moodMax, profile.mood + Tuning.moodPerCompletion)
        if profile.mood > 0 { profile.daysAtZero = 0 }
        rewardPulse += 1

        if profile.onVacation, key == todayKey, profile.returnStreak + 1 >= Tuning.vacationReturnStreak {
            returnFromVacation()
        }

        if key == todayKey, !wasAllDone, allDoneToday, profile.bonusDayKey != todayKey {
            profile.bonusDayKey = todayKey
            profile.fish += Tuning.fishAllDoneBonus
            profile.mood = min(Tuning.moodMax, profile.mood + Tuning.moodAllDoneBonus)
            if profile.storySeenDayKey != todayKey && !profile.onVacation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { self.showStory = true }
            }
        }
        save()
        if sync { syncOutside() }
    }

    func undo(_ h: Habit, dayKey: String? = nil, sync: Bool = true) {
        let key = dayKey ?? todayKey
        let l = log(for: h.id, dayKey: key)
        guard l.count > 0 else { return }
        l.count -= 1
        if key == todayKey { todayCounts[h.id] = l.count }
        profile.fish = max(0, profile.fish - Tuning.fishPerCompletion)
        profile.mood = max(0, profile.mood - Tuning.moodPerCompletion)
        if key == todayKey, profile.bonusDayKey == todayKey, !allDoneToday {
            profile.bonusDayKey = ""
            profile.fish = max(0, profile.fish - Tuning.fishAllDoneBonus)
            profile.mood = max(0, profile.mood - Tuning.moodAllDoneBonus)
        }
        save()
        if sync { syncOutside() }
    }

    private func applyPendingToggles() {
        let pending = PendingQueue.drain()
        guard !pending.isEmpty else { return }
        for p in pending {
            guard let h = habits.first(where: { $0.id.uuidString == p.habitID }) else { continue }
            if p.delta > 0 { complete(h, dayKey: p.dayKey, sync: false) } else { undo(h, dayKey: p.dayKey, sync: false) }
        }
    }

    // MARK: - Dagsbehandling (blid humørmodel)

    func processElapsedDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        guard let last = DayKey.date(from: profile.lastProcessedDayKey) else {
            profile.lastProcessedDayKey = DayKey.key(for: yesterday)
            save()
            return
        }
        var day = cal.date(byAdding: .day, value: 1, to: last) ?? today
        var n = 0
        while day < today && n < 120 {
            processDay(day)
            day = cal.date(byAdding: .day, value: 1, to: day) ?? today
            n += 1
        }
        profile.lastProcessedDayKey = DayKey.key(for: yesterday)
        save()
    }

    private func processDay(_ date: Date) {
        let list = scheduled(on: date)
        guard !list.isEmpty else { return } // neutral dag
        let c = counts(for: DayKey.key(for: date))
        let total = list.reduce(0) { $0 + $1.timesPerDay }
        let done = list.reduce(0) { $0 + min(c[$1.id] ?? 0, $1.timesPerDay) }
        let anyDone = c.values.contains { $0 > 0 }

        if profile.onVacation {
            profile.returnStreak = anyDone ? profile.returnStreak + 1 : 0
            if profile.returnStreak >= Tuning.vacationReturnStreak { returnFromVacation() }
            return
        }

        var drop: Double
        if !anyDone {
            profile.missedStreak += 1
            drop = Tuning.moodMissedDayDrop
        } else {
            profile.missedStreak = 0
            let ratio = total > 0 ? Double(done) / Double(total) : 1
            drop = Tuning.moodPartialDayDropMax * (1 - ratio)
        }
        drop = min(drop, Tuning.moodMaxDailyDrop)
        profile.mood = max(0, profile.mood - drop)
        profile.daysAtZero = profile.mood <= 0 ? profile.daysAtZero + 1 : 0

        if profile.missedStreak >= Tuning.vacationAfterMissedDays {
            profile.onVacation = true
            profile.returnStreak = 0
            profile.vacationPlace = Adventures.vacationSpots[DayKey.stableHash(DayKey.key(for: date)) % Adventures.vacationSpots.count]
        }
    }

    private func returnFromVacation() {
        profile.onVacation = false
        profile.missedStreak = 0
        profile.returnStreak = 0
        profile.daysAtZero = 0
        profile.mood = max(profile.mood, Tuning.moodAfterVacation)
        showWelcomeHome = true
    }

    func markStorySeen() {
        profile.storySeenDayKey = todayKey
        save()
    }

    // MARK: - Humør-check-in

    func saveMood(_ choice: MoodChoice, note: String) {
        if let m = todayMood {
            m.mood = choice.rawValue
            m.note = note
        } else {
            let m = MoodEntry(dayKey: todayKey, mood: choice.rawValue, note: note)
            context.insert(m)
            todayMood = m
        }
        if profile.moodFishDayKey != todayKey {
            profile.moodFishDayKey = todayKey
            profile.fish += Tuning.fishMoodCheckIn
            rewardPulse += 1
        }
        save()
        syncOutside()
    }

    // MARK: - Butik

    func owns(_ item: ShopItem) -> Bool { item.price == 0 || profile.owned.contains(item.id) }

    func isEquipped(_ item: ShopItem) -> Bool {
        switch item.slot {
        case .hat: return profile.hat == item.id
        case .glasses: return profile.glasses == item.id
        case .neck: return profile.neck == item.id
        case .background: return profile.background == item.id
        }
    }

    func buy(_ item: ShopItem) -> Bool {
        guard !owns(item), item.isInSeason, profile.fish >= item.price else { return false }
        profile.fish -= item.price
        profile.owned.append(item.id)
        equip(item, force: true)
        return true
    }

    func equip(_ item: ShopItem, force: Bool = false) {
        let on = force || !isEquipped(item)
        switch item.slot {
        case .hat: profile.hat = on ? item.id : nil
        case .glasses: profile.glasses = on ? item.id : nil
        case .neck: profile.neck = on ? item.id : nil
        case .background: profile.background = on ? item.id : ShopCatalog.defaultBackground
        }
        save()
        syncOutside()
    }

    // MARK: - Synk til widget, notifikationer og Live Activity

    func syncOutside() {
        writeSnapshot()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationScheduler.reschedule(store: self)
        LiveActivityManager.sync(store: self)
    }

    func writeSnapshot() {
        let wh = habits.map { h in
            WidgetHabit(id: h.id.uuidString, name: h.name, icon: h.icon, weekdays: h.weekdays,
                        target: h.timesPerDay, done: todayCounts[h.id] ?? 0)
        }
        let snap = SealSnapshot(sealName: profile.name, colorRaw: profile.colorRaw, mood: profile.mood,
                                daysAtZero: profile.daysAtZero, onVacation: profile.onVacation,
                                vacationPlace: profile.vacationPlace, dayKey: todayKey, fish: profile.fish,
                                place: adventurePlace.name, hat: profile.hat, glasses: profile.glasses,
                                neck: profile.neck, habits: wh)
        snap.save()
    }

    // MARK: - Backup

    var needsBackupNudge: Bool {
        guard profile.onboarded else { return false }
        let ref = profile.lastBackup ?? profile.createdAt
        let days = Calendar.current.dateComponents([.day], from: ref, to: Date()).day ?? 0
        return days >= Tuning.backupNudgeAfterDays
    }

    func didExportBackup() {
        let first = profile.lastBackup.map { !Calendar.current.isDateInToday($0) } ?? true
        profile.lastBackup = Date()
        if first { profile.fish += Tuning.fishBackup }
        save()
    }
}
