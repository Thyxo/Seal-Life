import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "💧"
    /// Calendar-ugedage: 1 = søndag … 7 = lørdag
    var weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    var timesPerDay: Int = 1
    var reminderEnabled: Bool = false
    /// Minutter efter midnat
    var reminderMinutes: Int = 540
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var archived: Bool = false

    init(name: String, icon: String, weekdays: [Int], timesPerDay: Int,
         reminderEnabled: Bool, reminderMinutes: Int, sortOrder: Int, createdAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.weekdays = weekdays
        self.timesPerDay = timesPerDay
        self.reminderEnabled = reminderEnabled
        self.reminderMinutes = reminderMinutes
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var reminderText: String {
        String(format: "%02d:%02d", reminderMinutes / 60, reminderMinutes % 60)
    }
}

@Model
final class HabitLog {
    var habitID: UUID = UUID()
    var dayKey: String = ""
    var count: Int = 0

    init(habitID: UUID, dayKey: String, count: Int) {
        self.habitID = habitID
        self.dayKey = dayKey
        self.count = count
    }
}

@Model
final class MoodEntry {
    var dayKey: String = ""
    var mood: Int = 3
    var note: String = ""
    var createdAt: Date = Date()

    init(dayKey: String, mood: Int, note: String) {
        self.dayKey = dayKey
        self.mood = mood
        self.note = note
        self.createdAt = Date()
    }
}

@Model
final class SealProfile {
    var name: String = "Sæl"
    var colorRaw: String = "gray"
    var mood: Double = 70
    var fish: Int = 20
    var owned: [String] = ["hule"]
    var hat: String? = nil
    var glasses: String? = nil
    var neck: String? = nil
    var background: String = "hule"
    var onboarded: Bool = false
    var lastProcessedDayKey: String = ""
    var missedStreak: Int = 0
    var onVacation: Bool = false
    var vacationPlace: String = ""
    var returnStreak: Int = 0
    var daysAtZero: Int = 0
    var bonusDayKey: String = ""
    var storySeenDayKey: String = ""
    var moodFishDayKey: String = ""
    var lastBackup: Date? = nil
    var createdAt: Date = Date()

    init() {
        self.mood = Tuning.startMood
        self.fish = Tuning.startFish
    }

    var color: SealColor {
        get { SealColor(rawValue: colorRaw) ?? .gray }
        set { colorRaw = newValue.rawValue }
    }
}

enum MoodChoice: Int, CaseIterable, Identifiable {
    case awful = 1, meh, okay, good, great
    var id: Int { rawValue }
    var emoji: String {
        switch self {
        case .awful: return "😣"
        case .meh: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }
    var label: String {
        switch self {
        case .awful: return "Hårdt"
        case .meh: return "Meh"
        case .okay: return "Okay"
        case .good: return "Godt"
        case .great: return "Super"
        }
    }
    var sealReply: String {
        switch self {
        case .awful: return "Åh. Kom her, jeg er blød. Vi tager det helt roligt i dag."
        case .meh: return "Meh-dage er også dage. Jeg ligger ved siden af dig."
        case .okay: return "Okay er fint! Okay er faktisk min yndlingsfarve."
        case .good: return "Hurra! Jeg laver en lille glædesrulle for dig."
        case .great: return "SUPER?! Jeg klapper så meget med luffen, at jeg vælter."
        }
    }
}
