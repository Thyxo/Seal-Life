import SwiftUI

// MARK: - Række med afkrydsning

struct HabitRow: View {
    @Environment(GameStore.self) private var store
    let habit: Habit
    var onEdit: () -> Void
    @State private var burst = 0

    var body: some View {
        let done = store.count(habit)
        let complete = done >= habit.timesPerDay
        HStack(spacing: 14) {
            Button(action: onEdit) {
                HStack(spacing: 14) {
                    Text(habit.icon)
                        .font(.system(size: 30))
                        .frame(width: 58, height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(complete ? Theme.mint.opacity(0.35) : Theme.sandLight)
                        )
                        .rotationEffect(.degrees(complete ? -8 : 0))
                        .scaleEffect(complete ? 0.92 : 1)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.name)
                            .font(.rounded(18, .heavy))
                            .foregroundStyle(complete ? Theme.inkSoft : Theme.ink)
                            .strikethrough(complete, color: Theme.inkSoft.opacity(0.6))
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            if habit.timesPerDay > 1 {
                                Text("\(done) af \(habit.timesPerDay)")
                                    .contentTransition(.numericText(value: Double(done)))
                            }
                            if habit.reminderEnabled {
                                Label(habit.reminderText, systemImage: "bell.fill")
                            }
                            Text("+\(Tuning.fishPerCompletion) 🐟")
                        }
                        .font(.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ZStack {
                CheckButton(done: done, target: habit.timesPerDay) {
                    let added = store.tap(habit)
                    if added { burst += 1 }
                }
                BurstView(trigger: burst, emojis: ["🐟", "✨", "💧"], count: 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: Theme.oceanDark.opacity(0.07), radius: 10, x: 0, y: 5)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: complete)
        .contextMenu {
            if done > 0 {
                Button { store.undo(habit) } label: { Label("Fortryd én", systemImage: "arrow.uturn.backward") }
            }
            Button(action: onEdit) { Label("Redigér", systemImage: "pencil") }
        }
    }
}

struct CheckButton: View {
    var done: Int
    var target: Int
    var action: () -> Void

    var body: some View {
        let complete = done >= target
        let progress = target > 0 ? Double(done) / Double(target) : 0
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(complete ? Theme.mintDark.opacity(0.6) : Theme.iceDark)
                    .offset(y: 4)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(complete ? Theme.mint : Theme.ice)
                if target > 1 && !complete {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.oceanDeep, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(13)
                    Text("\(done)")
                        .font(.rounded(15, .heavy))
                        .foregroundStyle(Theme.oceanDark)
                        .contentTransition(.numericText(value: Double(done)))
                }
                CheckMarkShape()
                    .trim(from: 0, to: complete ? 1 : 0)
                    .stroke(complete ? Color.white : Theme.iceDark,
                            style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
                    .padding(15)
                    .opacity(target > 1 && !complete ? 0 : 1)
                if target == 1 && !complete {
                    CheckMarkShape()
                        .stroke(Theme.iceDark, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .padding(15)
                }
            }
            .frame(width: 60, height: 60)
            .scaleEffect(complete ? 1.0 : 0.97)
        }
        .buttonStyle(BouncyStyle(scale: 0.86))
        .animation(.spring(response: 0.4, dampingFraction: 0.55), value: done)
        .animation(.easeOut(duration: 0.35), value: complete)
        .sensoryFeedback(trigger: done) { old, new in
            let fb: SensoryFeedback
            if new > old {
                fb = new >= target ? SensoryFeedback.success : SensoryFeedback.impact(weight: .medium)
            } else {
                fb = SensoryFeedback.impact(weight: .light)
            }
            return fb
        }
    }
}

struct RestingHabitRow: View {
    let habit: Habit
    var onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Text(habit.icon).font(.system(size: 22))
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.ice))
                Text(habit.name)
                    .font(.rounded(16, .bold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(WeekdayPicker.summary(habit.weekdays))
                    .font(.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.7)))
        }
        .buttonStyle(BouncyStyle(scale: 0.97))
    }
}

// MARK: - Opret / redigér vane

struct HabitEditorView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let habit: Habit?

    @State private var name = ""
    @State private var icon = "💧"
    @State private var weekdays: Set<Int> = Set(1...7)
    @State private var times = 1
    @State private var reminder = false
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var confirmRemove = false
    @State private var iconBounce = 0

    static let icons = ["💧", "🚶", "🧘", "📚", "🥦", "🛏️", "🦷", "💊", "🏃", "🧹", "✍️", "🎵",
                        "☀️", "🌙", "🍎", "🚿", "🧴", "📵", "🌿", "🐟", "🚲", "🧠", "❤️", "🫖"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text(icon)
                        .font(.system(size: 64))
                        .frame(width: 110, height: 110)
                        .background(Circle().fill(Theme.sandLight))
                        .keyframeAnimator(initialValue: CGFloat(1), trigger: iconBounce) { v, s in
                            v.scaleEffect(s)
                        } keyframes: { _ in
                            KeyframeTrack {
                                SpringKeyframe(CGFloat(1.25), duration: 0.12)
                                SpringKeyframe(CGFloat(1.0), duration: 0.4)
                            }
                        }
                        .padding(.top, 8)

                    TextField("Hvad vil du gøre?", text: $name)
                        .font(.rounded(20, .bold))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))

                    section("Ikon") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(Self.icons, id: \.self) { e in
                                Button {
                                    icon = e
                                    iconBounce += 1
                                } label: {
                                    Text(e).font(.system(size: 26))
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(icon == e ? Theme.oceanLight : Theme.ice)
                                        )
                                        .scaleEffect(icon == e ? 1.08 : 1)
                                }
                                .buttonStyle(BouncyStyle())
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: icon)
                    }

                    section("Hvilke dage?") {
                        WeekdayPicker(selection: $weekdays)
                    }

                    section("Hvor mange gange om dagen?") {
                        HStack {
                            stepButton("minus") { times = max(1, times - 1) }
                            Text("\(times)")
                                .font(.rounded(28, .heavy))
                                .foregroundStyle(Theme.ink)
                                .frame(minWidth: 60)
                                .contentTransition(.numericText(value: Double(times)))
                                .animation(.spring, value: times)
                            stepButton("plus") { times = min(12, times + 1) }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    section("Påmindelse") {
                        VStack(spacing: 10) {
                            Toggle(isOn: $reminder.animation(.spring)) {
                                Text("Mind mig blidt om det")
                                    .font(.rounded(16, .semibold))
                                    .foregroundStyle(Theme.ink)
                            }
                            .tint(Theme.oceanDeep)
                            if reminder {
                                DatePicker("Tidspunkt", selection: $time, displayedComponents: .hourAndMinute)
                                    .font(.rounded(16, .semibold))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                Text("Sælen sender højst \(NotificationScheduler.maxPerDay) påmindelser om dagen i alt.")
                                    .font(.rounded(12, .medium))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }

                    Button(habit == nil ? "Tilføj vane" : "Gem") { saveHabit() }
                        .buttonStyle(SoftButtonStyle(color: canSave ? Theme.oceanDeep : Theme.iceDark))
                        .disabled(!canSave)

                    if habit != nil {
                        Button("Slip vanen fri") { confirmRemove = true }
                            .font(.rounded(15, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.bottom, 20)
                    }
                }
                .padding(20)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle(habit == nil ? "Ny vane" : "Redigér vane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Luk") { dismiss() }
                }
            }
            .confirmationDialog("Slip vanen fri?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Ja, slip den fri", role: .destructive) {
                    if let habit { store.archive(habit) }
                    dismiss()
                }
            } message: {
                Text("Den forsvinder fra listen. Det er helt okay at ændre planer.")
            }
        }
        .onAppear(perform: load)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !weekdays.isEmpty
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.rounded(15, .bold))
                .foregroundStyle(Theme.inkSoft)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Theme.oceanDark)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.oceanLight))
        }
        .buttonStyle(BouncyStyle(scale: 0.85))
    }

    private func load() {
        guard let h = habit else { return }
        name = h.name
        icon = h.icon
        weekdays = Set(h.weekdays)
        times = h.timesPerDay
        reminder = h.reminderEnabled
        time = Calendar.current.date(bySettingHour: h.reminderMinutes / 60, minute: h.reminderMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    private func saveHabit() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let minutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let h = habit {
            h.name = cleanName
            h.icon = icon
            h.weekdays = weekdays.sorted()
            h.timesPerDay = times
            h.reminderEnabled = reminder
            h.reminderMinutes = minutes
            store.updated(h)
        } else {
            store.addHabit(name: cleanName, icon: icon, weekdays: weekdays.sorted(), times: times, reminder: reminder, minutes: minutes)
        }
        dismiss()
    }
}

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    static let days: [(Int, String)] = [(2, "M"), (3, "T"), (4, "O"), (5, "T"), (6, "F"), (7, "L"), (1, "S")]

    static func summary(_ weekdays: [Int]) -> String {
        let set = Set(weekdays)
        if set.count == 7 { return "Hver dag" }
        if set == Set([2, 3, 4, 5, 6]) { return "Hverdage" }
        if set == Set([1, 7]) { return "Weekend" }
        let names = [2: "man", 3: "tir", 4: "ons", 5: "tor", 6: "fre", 7: "lør", 1: "søn"]
        return days.filter { set.contains($0.0) }.compactMap { names[$0.0] }.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.days.count, id: \.self) { i in
                let d = Self.days[i]
                let on = selection.contains(d.0)
                Button {
                    if on { selection.remove(d.0) } else { selection.insert(d.0) }
                } label: {
                    Text(d.1)
                        .font(.rounded(16, .heavy))
                        .foregroundStyle(on ? .white : Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(Circle().fill(on ? Theme.oceanDeep : Theme.ice))
                        .scaleEffect(on ? 1.05 : 1)
                }
                .buttonStyle(BouncyStyle(scale: 0.85))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selection)
    }
}

// MARK: - Humør-check-in

struct MoodCheckInView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var choice: MoodChoice?
    @State private var note = ""
    @State private var saved = false

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Theme.iceDark).frame(width: 44, height: 5).padding(.top, 10)
            Text(saved ? (choice?.sealReply ?? "") : "Hvordan har du det i dag?")
                .font(.rounded(saved ? 18 : 24, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .id(saved)
                .transition(.scale.combined(with: .opacity))

            if saved {
                SealFigure(color: store.profile.color, state: .happy, hat: store.profile.hat,
                           glasses: store.profile.glasses, neck: store.profile.neck)
                    .frame(width: 150, height: 150)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else {
                HStack(spacing: 8) {
                    ForEach(MoodChoice.allCases) { m in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { choice = m }
                        } label: {
                            VStack(spacing: 4) {
                                Text(m.emoji)
                                    .font(.system(size: choice == m ? 46 : 36))
                                    .modifier(Wiggle(active: choice == m))
                                Text(m.label)
                                    .font(.rounded(12, .bold))
                                    .foregroundStyle(choice == m ? Theme.oceanDark : Theme.inkSoft)
                            }
                            .frame(maxWidth: .infinity, minHeight: 86)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(choice == m ? Theme.oceanLight : .white)
                            )
                        }
                        .buttonStyle(BouncyStyle())
                    }
                }
                .padding(.horizontal)
                .sensoryFeedback(.selection, trigger: choice)

                TextField("Valgfri note…", text: $note, axis: .vertical)
                    .font(.rounded(16, .medium))
                    .lineLimit(1...4)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
                    .padding(.horizontal)
            }

            Spacer(minLength: 0)

            Button(saved ? "Tak, sæl 💙" : "Gem") {
                if saved {
                    dismiss()
                } else if let c = choice {
                    store.saveMood(c, note: note)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { saved = true }
                }
            }
            .buttonStyle(SoftButtonStyle(color: choice == nil ? Theme.iceDark : Theme.oceanDeep))
            .disabled(choice == nil)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            if let m = store.todayMood {
                choice = MoodChoice(rawValue: m.mood)
                note = m.note
            }
        }
    }
}

// MARK: - Historien når sælen kommer hjem

struct StoryView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var shown = false

    var body: some View {
        let place = store.adventurePlace
        ZStack {
            LinearGradient(colors: [Theme.oceanLight, Theme.cream], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            FloatingEmoji(emoji: "✨", count: 8, speed: 0.25)
            VStack(spacing: 18) {
                Spacer()
                Text("\(place.emoji) \(place.name)")
                    .font(.rounded(16, .heavy))
                    .foregroundStyle(Theme.oceanDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white))
                    .scaleEffect(shown ? 1 : 0.3)
                    .opacity(shown ? 1 : 0)
                SealFigure(color: store.profile.color, state: .happy, hat: store.profile.hat,
                           glasses: store.profile.glasses, neck: store.profile.neck)
                    .frame(width: 220, height: 220)
                    .scaleEffect(shown ? 1 : 0.5)
                    .rotationEffect(.degrees(shown ? 0 : -20))
                Text("\(store.profile.name) er hjemme!")
                    .font(.rounded(28, .heavy))
                    .foregroundStyle(Theme.ink)
                if shown {
                    TypewriterText(text: Adventures.story(for: store.todayKey), font: .rounded(18, .medium), color: Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Text("+\(Tuning.fishAllDoneBonus) 🐟 bonus for en klaret dag")
                        .font(.rounded(15, .bold))
                        .foregroundStyle(Theme.oceanDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.mint.opacity(0.4)))
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                Button("Aww, tak!") {
                    store.markStorySeen()
                    dismiss()
                }
                .buttonStyle(SoftButtonStyle(color: Theme.mintDark))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.15)) { shown = true }
        }
        .onDisappear { store.markStorySeen() }
        .sensoryFeedback(.success, trigger: shown)
    }
}

struct WelcomeHomeView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            SealFigure(color: store.profile.color, state: .happy, hat: store.profile.hat,
                       glasses: store.profile.glasses, neck: store.profile.neck)
                .frame(width: 170, height: 170)
                .padding(.top, 24)
            Text("Jeg er hjemme igen! 🏠")
                .font(.rounded(26, .heavy))
                .foregroundStyle(Theme.ink)
            Text("Ferien var dejlig, men det bedste var at svømme hjem til dig.")
                .font(.rounded(16, .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Velkommen hjem!") { dismiss() }
                .buttonStyle(SoftButtonStyle())
                .padding(.horizontal, 24)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.cream.ignoresSafeArea())
    }
}
