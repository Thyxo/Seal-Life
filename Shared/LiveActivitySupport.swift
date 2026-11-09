import Foundation
import AppIntents
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Knap i Dynamic Island

/// Afkrydser næste vane direkte fra Dynamic Island / låseskærmen.
/// `LiveActivityIntent` kører i appens proces, så aktiviteten kan opdateres med det samme.
/// Ligger i Shared, så både app og widget kender den (Apples anbefaling).
struct CompleteHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Markér vane som klaret"
    static var description = IntentDescription("Afkrydser dagens næste vane fra Live Activity.")
    static var isDiscoverable: Bool = false

    @Parameter(title: "Vane-ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        guard let snap = SealSnapshot.completeFromLiveActivity(habitID: habitID) else { return .result() }
        await LiveActivityContent.refresh(from: snap)
        return .result()
    }
}

// MARK: - Afkryds/fortryd fra hjemmeskærms-widgetten (large)

/// Bruges af listen i large-widgetten. Som `LiveActivityIntent` kører den i appens proces,
/// så Live Activity'en også opdateres, når man afkrydser fra hjemmeskærmen.
struct ToggleHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Afkryds vane"
    static var description = IntentDescription("Afkrydser en vane for i dag.")
    static var isDiscoverable: Bool = false

    @Parameter(title: "Vane-ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        SealSnapshot.toggleFromWidget(habitID: habitID)
        if let snap = SealSnapshot.load() {
            await LiveActivityContent.refresh(from: snap)
        }
        return .result()
    }
}

// MARK: - Fælles opbygning og opdatering

enum LiveActivityContent {
    /// Hvor længe en færdig aktivitet bliver på låseskærmen (Apple anbefaler 15–30 min).
    static let dismissAfter: TimeInterval = 30 * 60

    /// Aktiviteter, der er ved at afslutte (så alerten kun kommer én gang).
    @MainActor private static var finishing = Set<String>()

    /// Opdaterer widgets og dagens Live Activity ud fra snapshot (efter et tryk i ø eller widget).
    static func refresh(from snap: SealSnapshot) async {
        WidgetCenter.shared.reloadAllTimelines()
        let state = state(from: snap)
        for activity in Activity<SealActivityAttributes>.activities
        where activity.attributes.dayKey == snap.dayKey && activity.activityState == .active {
            await apply(state, to: activity, sealName: snap.sealName)
        }
    }

    /// Bygger indholdet ud fra widget-snapshot (bruges af intents og af hjemmeskærms-widgetten).
    static func state(from snap: SealSnapshot, date: Date = Date()) -> SealActivityAttributes.ContentState {
        let todays = snap.habits(on: date)
        let habits = todays.map { LiveHabit(id: $0.id, name: $0.name, icon: $0.icon, target: $0.target, done: min($0.done, $0.target)) }
        let total = habits.reduce(0) { $0 + $1.target }
        let done = habits.reduce(0) { $0 + $1.done }
        let message: String
        if total > 0 && done >= total {
            message = "Hjemme igen – alt klaret! 💙"
        } else if done == 0 {
            message = "Svømmer ud til \(snap.place)"
        } else {
            message = "Ved \(snap.place) · \(total - done) tilbage"
        }
        return .init(mood: snap.mood, moodStateRaw: snap.moodState.rawValue, done: done, total: total,
                     place: snap.place, message: message, habits: habits,
                     style: LiveActivityStyle.current.rawValue)
    }

    /// Opdaterer aktiviteten. Når alt er klaret: kort alert (øen udvides), derefter afslut.
    static func apply(_ state: SealActivityAttributes.ContentState,
                      to activity: Activity<SealActivityAttributes>, sealName: String) async {
        let content = ActivityContent(state: state, staleDate: nil)
        guard state.allDone else {
            await activity.update(content)
            return
        }
        let isNew = await MainActor.run { finishing.insert(activity.id).inserted }
        guard isNew else { return }
        let alert = AlertConfiguration(title: "Alt klaret! 🎉",
                                       body: "\(sealName) er hjemme igen fra \(state.place).",
                                       sound: .default)
        await activity.update(content, alertConfiguration: alert)
        try? await Task.sleep(for: .seconds(4))
        await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(dismissAfter)))
        _ = await MainActor.run { finishing.remove(activity.id) }
    }
}
#endif
