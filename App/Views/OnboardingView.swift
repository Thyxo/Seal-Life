import SwiftUI

struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var step = 0
    @State private var color: SealColor = .gray
    @State private var name = ""
    @State private var popped = false
    @State private var bounce = 0
    @FocusState private var nameFocused: Bool

    private let suggestions = ["Bølle", "Sild", "Plet", "Molly", "Bobby", "Luffe", "Søren"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.oceanLight, Theme.cream], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            BubblesView(count: 12).ignoresSafeArea()

            VStack(spacing: 0) {
                progressDots.padding(.top, 12)
                Spacer(minLength: 8)
                sealStage
                Spacer(minLength: 8)
                Group {
                    switch step {
                    case 0: welcome
                    case 1: colorStep
                    default: nameStep
                    }
                }
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) { popped = true }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.oceanDeep : Theme.iceDark)
                    .frame(width: i == step ? 26 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
    }

    private var sealStage: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.6)).frame(width: 250).breathing(0.03, duration: 2.4)
            SealFigure(color: color, state: step == 2 && !name.isEmpty ? .happy : .content)
                .frame(width: 210, height: 210)
                .keyframeAnimator(initialValue: SquishValues(), trigger: bounce) { view, v in
                    view.scaleEffect(x: v.sx, y: v.sy, anchor: .bottom).offset(y: v.y)
                } keyframes: { _ in
                    KeyframeTrack(\.sx) {
                        SpringKeyframe(1.12, duration: 0.12)
                        SpringKeyframe(0.96, duration: 0.15)
                        SpringKeyframe(1.0, duration: 0.3)
                    }
                    KeyframeTrack(\.sy) {
                        SpringKeyframe(0.86, duration: 0.12)
                        SpringKeyframe(1.08, duration: 0.15)
                        SpringKeyframe(1.0, duration: 0.3)
                    }
                    KeyframeTrack(\.y) {
                        CubicKeyframe(0, duration: 0.12)
                        CubicKeyframe(-26, duration: 0.18)
                        CubicKeyframe(0, duration: 0.25)
                    }
                }
                .onTapGesture { bounce += 1 }
            AnimatedWaves(colors: [Theme.ocean.opacity(0.5), Theme.ocean.opacity(0.8)], amplitude: 6, speed: 1.2)
                .frame(width: 280, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .offset(y: 118)
                .opacity(step == 0 ? 1 : 0)
        }
        .scaleEffect(popped ? 1 : 0.3)
        .offset(y: popped ? 0 : 120)
        .opacity(popped ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: color)
    }

    private var welcome: some View {
        VStack(spacing: 14) {
            Text("Hej! 👋")
                .font(.rounded(34, .heavy))
                .foregroundStyle(Theme.ink)
            Text("Jeg er en lille sæl, der gerne vil bo hos dig. Når du passer på dig selv, passer du også lidt på mig.")
                .font(.rounded(17, .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            Button("Hej sæl!") { next() }
                .buttonStyle(SoftButtonStyle())
                .padding(.top, 8)
        }
    }

    private var colorStep: some View {
        VStack(spacing: 16) {
            Text("Hvordan ser jeg ud?")
                .font(.rounded(28, .heavy))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 12) {
                ForEach(SealColor.allCases) { c in
                    Button {
                        color = c
                        bounce += 1
                    } label: {
                        VStack(spacing: 6) {
                            SealFigure(color: c, state: .content, animated: false)
                                .frame(width: 70, height: 70)
                            Text(c.displayName).font(.rounded(14, .bold)).foregroundStyle(Theme.ink)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(color == c ? Theme.oceanDeep : .clear, lineWidth: 3)
                                )
                        )
                        .scaleEffect(color == c ? 1.05 : 1)
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: color)
                    }
                    .buttonStyle(BouncyStyle())
                }
            }
            Button("Sådan!") { next() }
                .buttonStyle(SoftButtonStyle())
        }
    }

    private var nameStep: some View {
        VStack(spacing: 14) {
            Text("Hvad hedder jeg?")
                .font(.rounded(28, .heavy))
                .foregroundStyle(Theme.ink)
            TextField("Giv mig et navn", text: $name)
                .font(.rounded(22, .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                .focused($nameFocused)
                .submitLabel(.done)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { s in
                        Button(s) {
                            name = s
                            bounce += 1
                        }
                        .font(.rounded(15, .bold))
                        .foregroundStyle(Theme.oceanDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.oceanLight))
                        .buttonStyle(BouncyStyle())
                    }
                }
            }
            Button(name.isEmpty ? "Vælg et navn" : "Velkommen, \(name)!") {
                nameFocused = false
                NotificationScheduler.requestAuthorization()
                withAnimation { store.finishOnboarding(name: name, color: color) }
            }
            .buttonStyle(SoftButtonStyle(color: name.isEmpty ? Theme.iceDark : Theme.oceanDeep))
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func next() {
        bounce += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step += 1 }
    }
}

struct SquishValues {
    var sx: CGFloat = 1
    var sy: CGFloat = 1
    var y: CGFloat = 0
}
