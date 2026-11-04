import SwiftUI
import UserNotifications
import ActivityKit
import WidgetKit

/// Viser notifikationer også mens appen er åben (praktisk til test).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

/// Udviklermenu: test notifikationer, Live Activity, widget og sælens tilstande.
struct DeveloperView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var authStatus = "…"
    @State private var pending: [String] = []
    @State private var activityInfo = "…"
    @State private var log: [String] = []
    @State private var mood: Double = 50
    @State private var delay: Double = 5
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                liveActivitySection
                widgetSection
                sealSection
                infoSection
                if !log.isEmpty {
                    Section("Log") {
                        ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.system(size: 12, design: .monospaced))
                        }
                    }
                }
            }
            .navigationTitle("Udviklermenu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Færdig") { dismiss() }
                }
            }
            .onAppear {
                mood = store.profile.mood
                refresh()
            }
            .confirmationDialog("Start onboarding forfra?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Ja, vis onboarding", role: .destructive) {
                    dismiss()
                    store.debugResetOnboarding()
                }
            } message: {
                Text("Vaner og data bliver liggende. Du vælger bare farve og navn igen.")
            }
        }
    }

    // MARK: Notifikationer

    private var notificationsSection: some View {
        Section {
            row("Tilladelse", authStatus)
            Button("Bed om tilladelse") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                    DispatchQueue.main.async {
                        add("Tilladelse: \(ok ? "givet" : "afvist")")
                        refresh()
                    }
                }
            }
            VStack(alignment: .leading) {
                Text("Forsinkelse: \(Int(delay)) sek")
                Slider(value: $delay, in: 3...60, step: 1)
            }
            Button("Test: vane-påmindelse") {
                let habit = store.todayHabits.first?.name.lowercased() ?? "en lille vane"
                testNotification(title: "\(store.profile.name) 🦭",
                                 body: "Psst… \(habit) venter på dig. Helt uden stress.")
            }
            Button("Test: backup-påmindelse") {
                testNotification(title: "\(store.profile.name) 🦭",
                                 body: "Skal vi lave en lille backup? Det tager fem sekunder.")
            }
            Button("Test: postkort fra ferien") {
                testNotification(title: "Postkort fra Bornholm 💌",
                                 body: "Her er dejligt, men jeg savner dig lidt. Én vane, og jeg begynder at svømme hjem.")
            }
            Button("Planlæg alle påmindelser igen") {
                NotificationScheduler.reschedule(store: store)
                add("Påmindelser planlagt igen")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refresh() }
            }
            Button("Fjern alle ventende", role: .destructive) {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                add("Alle ventende fjernet")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { refresh() }
            }
            DisclosureGroup("Ventende (\(pending.count))") {
                ForEach(Array(pending.enumerated()), id: \.offset) { _, p in
                    Text(p).font(.system(size: 12))
                }
            }
        } header: {
            Text("Notifikationer")
        } footer: {
            Text("Lås telefonen efter du har trykket, eller bliv i appen – banneret vises begge steder.")
        }
    }

    private func testNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let req = UNNotificationRequest(identifier: "debug-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            DispatchQueue.main.async {
                add(err == nil ? "Notifikation om \(Int(delay)) sek" : "Fejl: \(err!.localizedDescription)")
            }
        }
    }

    // MARK: Live Activity

    private var liveActivitySection: some View {
        Section("Live Activity") {
            row("Status", activityInfo)
            Button("Start test-aktivitet") { startTestActivity() }
            Button("Næste skridt (+1 klaret)") { stepTestActivity() }
            Button("Synk med rigtige data") {
                LiveActivityManager.sync(store: store)
                add("Live Activity synket")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { refresh() }
            }
            Button("Afslut alle", role: .destructive) {
                Task {
                    for a in Activity<SealActivityAttributes>.activities {
                        await a.end(nil, dismissalPolicy: .immediate)
                    }
                    await MainActor.run {
                        add("Alle Live Activities afsluttet")
                        refresh()
                    }
                }
            }
        }
    }

    private func startTestActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            add("Live Activities er slået fra i Indstillinger")
            return
        }
        let attrs = SealActivityAttributes(sealName: store.profile.name, colorRaw: store.profile.colorRaw,
                                           dayKey: "debug")
        let state = SealActivityAttributes.ContentState(
            mood: store.profile.mood, moodStateRaw: store.moodState.rawValue,
            done: 1, total: 4, place: "Nyhavn", message: "Test: ved Nyhavn · 3 tilbage")
        do {
            _ = try Activity<SealActivityAttributes>.request(
                attributes: attrs, content: ActivityContent(state: state, staleDate: nil), pushType: nil)
            add("Test-aktivitet startet – lås telefonen for at se den")
        } catch {
            add("Fejl: \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refresh() }
    }

    private func stepTestActivity() {
        guard let a = Activity<SealActivityAttributes>.activities.first(where: { $0.attributes.dayKey == "debug" }) else {
            add("Ingen test-aktivitet kører")
            return
        }
        var s = a.content.state
        s.done = min(s.total, s.done + 1)
        let left = s.total - s.done
        s.message = left == 0 ? "Test: hjemme igen – alt klaret! 💙" : "Test: ved Nyhavn · \(left) tilbage"
        let newState = s
        Task {
            await a.update(ActivityContent(state: newState, staleDate: nil))
            await MainActor.run { add("Opdateret: \(newState.done)/\(newState.total)") }
        }
    }

    // MARK: Widget

    private var widgetSection: some View {
        Section("Widget") {
            Button("Skriv snapshot + genindlæs widgets") {
                store.writeSnapshot()
                WidgetCenter.shared.reloadAllTimelines()
                add("Widget genindlæst")
            }
            row("Ventende widget-afkrydsninger", "\(PendingQueue.load().count)")
        }
    }

    // MARK: Sælen

    private var sealSection: some View {
        Section {
            Picker("Vis tilstand", selection: Binding(
                get: { store.debugStateOverride?.rawValue ?? "" },
                set: { v in store.debugStateOverride = v.isEmpty ? nil : MoodState(rawValue: v) }
            )) {
                Text("Normal").tag("")
                ForEach(MoodState.allCases, id: \.rawValue) { s in
                    Text("\(s.emoji) \(s.displayName)").tag(s.rawValue)
                }
            }
            VStack(alignment: .leading) {
                Text("Humør: \(Int(mood))")
                Slider(value: $mood, in: 0...100, step: 1, onEditingChanged: { editing in
                    if !editing { store.debugSetMood(mood) }
                })
            }
            Button("Gør syg (0 i flere dage)") {
                store.debugSetDaysAtZero(Tuning.sickAfterDaysAtZero)
                mood = 0
            }
            Button("+100 fisk") { store.debugAddFish(100) }
            Button("Simulér en glemt dag") {
                store.debugSimulateMissedDay()
                mood = store.profile.mood
                add("Glemt dag: humør \(Int(store.profile.mood)), glemt i træk \(store.profile.missedStreak)")
            }
            Button(store.profile.onVacation ? "Hent hjem fra ferie" : "Send på ferie") {
                if store.profile.onVacation { store.debugEndVacation() } else { store.debugStartVacation() }
            }
            Button("Vis dagens historie") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { store.showStory = true }
            }
            Button("Vis velkommen hjem") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { store.showWelcomeHome = true }
            }
            Button("Nulstil alle tøj-justeringer") {
                FitStore.shared.replaceAll([:])
                store.syncOutside()
                add("Tøj-justeringer nulstillet")
            }
            Button("Start onboarding forfra", role: .destructive) { confirmReset = true }
        } header: {
            Text("Sælen")
        }
    }

    // MARK: Info

    private var infoSection: some View {
        Section("Info") {
            row("App Group", AppGroup.identifier ?? "–")
            row("Deling aktiv", AppGroup.isShared ? "ja" : "nej")
            row("Bundle", Bundle.main.bundleIdentifier ?? "–")
            row("Glemt i træk", "\(store.profile.missedStreak)")
            row("Hjem-streak (ferie)", "\(store.profile.returnStreak)")
            row("Dage på 0", "\(store.profile.daysAtZero)")
            row("Sidst behandlet", store.profile.lastProcessedDayKey)
            Text(AppGroup.containerURL.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    // MARK: Hjælpere

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        }
    }

    private func add(_ line: String) {
        let time = Date().formatted(date: .omitted, time: .standard)
        log.insert("\(time)  \(line)", at: 0)
        if log.count > 30 { log.removeLast() }
    }

    private func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let text: String
            switch settings.authorizationStatus {
            case .authorized: text = "givet"
            case .denied: text = "afvist"
            case .notDetermined: text = "ikke spurgt"
            case .provisional: text = "foreløbig"
            case .ephemeral: text = "midlertidig"
            @unknown default: text = "ukendt"
            }
            DispatchQueue.main.async { authStatus = text }
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let lines: [String] = reqs.map { r in
                var when = ""
                if let t = r.trigger as? UNCalendarNotificationTrigger, let d = t.nextTriggerDate() {
                    when = d.formatted(date: .abbreviated, time: .shortened)
                } else if let t = r.trigger as? UNTimeIntervalNotificationTrigger, let d = t.nextTriggerDate() {
                    when = d.formatted(date: .omitted, time: .standard)
                }
                return "\(when) · \(r.content.body)"
            }.sorted()
            DispatchQueue.main.async { pending = lines }
        }
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        let count = Activity<SealActivityAttributes>.activities.count
        activityInfo = "\(enabled ? "tilladt" : "slået fra") · \(count) aktive"
    }
}
