import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var editing: Habit?
    @State private var creating = false
    @State private var moodSheet = false
    @State private var shareFile: ShareFile?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                SealStageView()
                    .appearIn(0)

                if store.profile.onVacation {
                    VacationCard().appearIn(0.08)
                } else if store.todayTotal > 0 {
                    AdventureCard().appearIn(0.08)
                }

                if store.todayMood == nil {
                    MoodPromptCard { moodSheet = true }.appearIn(0.14)
                }

                if store.needsBackupNudge {
                    BackupNudgeCard {
                        if let url = try? BackupManager.makeFile(store: store) {
                            shareFile = ShareFile(url: url)
                            store.didExportBackup()
                        }
                    }
                    .appearIn(0.18)
                }

                habitsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.cream.ignoresSafeArea())
        .sheet(item: $editing) { h in
            HabitEditorView(habit: h).presentationCornerRadius(32)
        }
        .sheet(isPresented: $creating) {
            HabitEditorView(habit: nil).presentationCornerRadius(32)
        }
        .sheet(isPresented: $moodSheet) {
            MoodCheckInView().presentationDetents([.medium, .large]).presentationCornerRadius(32)
        }
        .sheet(item: $shareFile) { f in
            ActivityView(items: [f.url])
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(headerText)
                    .font(.rounded(21, .heavy))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.spring, value: store.remainingToday)
                Spacer()
                Button {
                    creating = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.oceanDeep))
                }
                .buttonStyle(BouncyStyle(scale: 0.85))
            }
            .padding(.horizontal, 4)

            if store.habits.isEmpty {
                EmptyHabitsCard { creating = true }
            }

            ForEach(Array(store.todayHabits.enumerated()), id: \.element.id) { i, h in
                HabitRow(habit: h, onEdit: { editing = h })
                    .appearIn(0.2 + Double(i) * 0.06)
            }

            if !store.otherHabits.isEmpty {
                Text("Ikke i dag")
                    .font(.rounded(15, .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
                ForEach(store.otherHabits, id: \.id) { h in
                    RestingHabitRow(habit: h) { editing = h }
                }
            }
        }
    }

    private var headerText: String {
        if store.todayTotal == 0 { return "Ingen vaner i dag" }
        if store.allDoneToday { return "Alt klaret i dag! 🎉" }
        let n = store.remainingToday
        return n == 1 ? "1 ting tilbage i dag" : "\(n) ting tilbage i dag"
    }
}

// MARK: - Sælens scene

struct SealStageView: View {
    @Environment(GameStore.self) private var store
    @State private var bounce = 0
    @State private var hearts = 0
    @State private var tapLine: String?

    var body: some View {
        let state = store.displayState
        let sceneID = store.profile.onVacation ? "isflage" : (store.isOnAdventure ? "ocean" : store.profile.background)

        ZStack(alignment: .top) {
            SceneBackground(id: sceneID)
                .id(sceneID)
                .transition(.opacity)

            if store.isNight {
                Color(hex: 0x23305A).opacity(0.35).allowsHitTesting(false)
            }
            if Calendar.current.component(.month, from: Date()) == 12 {
                SnowView(count: 26)
            }

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                SpeechBubble(text: tapLine ?? store.greeting)
                    .frame(maxWidth: 290)
                    .id(tapLine ?? store.greeting)
                    .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                sealView(state: state)
            }
            .padding(.bottom, 8)
        }
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Theme.oceanDark.opacity(0.12), radius: 14, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.8), value: sceneID)
        .padding(.top, 4)
    }

    @ViewBuilder private func sealView(state: MoodState) -> some View {
        let p = store.profile
        ZStack {
            // Hjerterne ligger bag sælen og fader væk efter et par sekunder.
            HeartPuffView(trigger: hearts)
                .offset(y: -60)
            if store.profile.onVacation {
                PostcardView(place: p.vacationPlace)
                    .frame(width: 200, height: 160)
            } else {
                SealFigure(color: p.color, state: state, hat: p.hat, glasses: p.glasses, neck: p.neck)
                    .frame(width: 200, height: 200)
                    .modifier(SwimModifier(active: store.isOnAdventure))
                    .keyframeAnimator(initialValue: SquishValues(), trigger: bounce) { view, v in
                        view.scaleEffect(x: v.sx, y: v.sy, anchor: .bottom).offset(y: v.y)
                    } keyframes: { _ in
                        KeyframeTrack(\.sx) {
                            SpringKeyframe(1.14, duration: 0.12)
                            SpringKeyframe(0.95, duration: 0.15)
                            SpringKeyframe(1.0, duration: 0.3)
                        }
                        KeyframeTrack(\.sy) {
                            SpringKeyframe(0.84, duration: 0.12)
                            SpringKeyframe(1.08, duration: 0.15)
                            SpringKeyframe(1.0, duration: 0.3)
                        }
                        KeyframeTrack(\.y) {
                            CubicKeyframe(0, duration: 0.12)
                            CubicKeyframe(-30, duration: 0.18)
                            CubicKeyframe(0, duration: 0.25)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { tapSeal() }
                    .sensoryFeedback(.impact(weight: .light), trigger: bounce)
                BurstView(trigger: store.rewardPulse, emojis: ["🐟", "✨", "🐟"], count: 6)
                    .offset(y: -20)
            }
        }
        .onChange(of: store.rewardPulse) { _, _ in bounce += 1 }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text(store.displayState.emoji)
                Text(store.profile.name)
                    .font(.rounded(16, .heavy))
                    .foregroundStyle(Theme.ink)
                MoodMeter(mood: store.profile.mood)
                    .frame(width: 54, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.9)))

            Spacer()

            FishCounter(fish: store.profile.fish)
        }
        .padding(14)
    }

    private func tapSeal() {
        bounce += 1
        hearts += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tapLine = Adventures.tapLines.randomElement()
        }
        let current = tapLine
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if tapLine == current {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { tapLine = nil }
            }
        }
    }
}

struct SwimModifier: ViewModifier {
    var active: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if active {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let m = Tuning.Motion.self
                // Masken sidder på sælen selv (før den flyttes), så den aldrig bliver skåret af i siden.
                content
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                            LinearGradient(colors: [.black, .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                                .frame(height: 70)
                        }
                        .padding(.horizontal, -60)
                        .padding(.top, -60)
                    )
                    .rotationEffect(.degrees(sin(t * m.swimSpeed * 2.4) * m.swimRockDegrees))
                    .offset(x: CGFloat(sin(t * m.swimSpeed) * m.swimDistance),
                            y: CGFloat(sin(t * m.swimSpeed * 2.4)) * 4 + 30)
            }
        } else {
            content
        }
    }
}

struct MoodMeter: View {
    var mood: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ice)
                Capsule()
                    .fill(MoodState.from(mood: mood, daysAtZero: 0, onVacation: false).tint)
                    .frame(width: max(8, g.size.width * CGFloat(mood / 100)))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: mood)
    }
}

struct FishCounter: View {
    var fish: Int
    @State private var pop = 0

    var body: some View {
        HStack(spacing: 5) {
            Text("🐟")
                .rotationEffect(.degrees(pop % 2 == 0 ? 0 : -15))
            Text("\(fish)")
                .font(.rounded(17, .heavy))
                .foregroundStyle(Theme.oceanDark)
                .contentTransition(.numericText(value: Double(fish)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.9)))
        .keyframeAnimator(initialValue: CGFloat(1), trigger: pop) { view, s in
            view.scaleEffect(s)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(CGFloat(1.25), duration: 0.15)
                SpringKeyframe(CGFloat(1.0), duration: 0.35)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: fish)
        .onChange(of: fish) { _, _ in pop += 1 }
    }
}

struct PostcardView: View {
    var place: String
    @State private var tilt = false

    var body: some View {
        VStack(spacing: 6) {
            Text("💌").font(.system(size: 34))
            Text("Hilsen fra")
                .font(.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text(place.isEmpty ? "ferien" : place)
                .font(.rounded(22, .heavy))
                .foregroundStyle(Theme.oceanDark)
            Text("🏝️ 🦭 🕶️").font(.system(size: 18))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .foregroundStyle(Theme.ocean))
        )
        .rotationEffect(.degrees(tilt ? 4 : -4))
        .floating(5, duration: 2.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) { tilt = true }
        }
    }
}

// MARK: - Kort

struct AdventureCard: View {
    @Environment(GameStore.self) private var store
    @State private var boat = false

    var body: some View {
        let place = store.adventurePlace
        let progress = store.todayTotal > 0 ? Double(store.todayDone) / Double(store.todayTotal) : 0
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(store.allDoneToday ? "🏠" : place.emoji)
                    .font(.system(size: 28))
                    .rotationEffect(.degrees(boat ? 5 : -5))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { boat = true }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.allDoneToday ? "Hjemme igen!" : "Dagens eventyr")
                        .font(.rounded(13, .bold))
                        .foregroundStyle(Theme.inkSoft)
                    Text(store.allDoneToday ? "\(store.profile.name) har en historie" : place.name)
                        .font(.rounded(19, .heavy))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                if store.allDoneToday {
                    Button("Hør den") { store.showStory = true }
                        .font(.rounded(15, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.mintDark))
                        .buttonStyle(BouncyStyle())
                        .breathing(0.03)
                }
            }
            ZStack {
                WaveProgressBar(progress: progress, tint: store.allDoneToday ? Theme.mintDark : Theme.oceanDeep)
                Text("\(store.todayDone) / \(store.todayTotal)")
                    .font(.rounded(14, .heavy))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText(value: Double(store.todayDone)))
                    .animation(.spring, value: store.todayDone)
            }
        }
        .card(Theme.oceanLight)
    }
}

struct VacationCard: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let need = Tuning.vacationReturnStreak
        let have = min(need, store.profile.returnStreak + (store.todayDone > 0 ? 1 : 0))
        VStack(alignment: .leading, spacing: 10) {
            Text("\(store.profile.name) er på ferie ☀️")
                .font(.rounded(19, .heavy))
                .foregroundStyle(Theme.ink)
            Text("Ingen fare – sæler elsker ferie. Klar mindst én vane \(need) dage i træk, så svømmer \(store.profile.name) hjem igen.")
                .font(.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 10) {
                ForEach(0..<need, id: \.self) { i in
                    Circle()
                        .fill(i < have ? Theme.mintDark : Theme.iceDark)
                        .frame(width: 22, height: 22)
                        .overlay(Text(i < have ? "✓" : "").font(.rounded(12, .heavy)).foregroundStyle(.white))
                        .scaleEffect(i < have ? 1.1 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(Double(i) * 0.1), value: have)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Theme.sandLight)
    }
}

struct MoodPromptCard: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                HStack(spacing: -6) {
                    ForEach(MoodChoice.allCases) { m in
                        Text(m.emoji).font(.system(size: 22))
                    }
                }
                .floating(2, duration: 1.8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hvordan har du det?")
                        .font(.rounded(17, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Et hurtigt tjek – kun for dig")
                        .font(.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
            .card()
        }
        .buttonStyle(BouncyStyle(scale: 0.97))
    }
}

struct BackupNudgeCard: View {
    var action: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Text("💾").font(.system(size: 30)).floating(3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lille backup?")
                    .font(.rounded(17, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Sideloadede apps udløber efter 7 dage. Gem mine minder et sikkert sted.")
                    .font(.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button("Gem", action: action)
                .font(.rounded(15, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(Theme.oceanDeep))
                .buttonStyle(BouncyStyle())
        }
        .card(Theme.sandLight)
    }
}

struct EmptyHabitsCard: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("🌱").font(.system(size: 40)).breathing(0.08)
                Text("Lav din første vane")
                    .font(.rounded(18, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Noget helt lille er perfekt. Fx et glas vand.")
                    .font(.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .card()
        }
        .buttonStyle(BouncyStyle(scale: 0.97))
    }
}
