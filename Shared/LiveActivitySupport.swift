import Foundation
import AppIntents
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
        let state = LiveActivityContent.state(from: snap)
        for activity in Activity<SealActivityAttributes>.activities
        where activity.attributes.dayKey == snap.dayKey && activity.activityState == .active {
            await LiveActivityContent.apply(state, to: activity, sealName: snap.sealName)
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

    /// Bygger indholdet ud fra widget-snapshot (bruges af intenten, når appen ikke er åben).
    static func state(from snap: SealSnapshot) -> SealActivityAttributes.ContentState {
        let todays = snap.habits(on: Date())
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
                     place: snap.place, message: message, habits: habits)
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
