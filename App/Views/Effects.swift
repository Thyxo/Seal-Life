import SwiftUI

// MARK: - Bølger

struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat
    var frequency: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let step: CGFloat = 4
        var x: CGFloat = 0
        while x <= rect.width + step {
            let rel = Double(x / max(rect.width, 1))
            let y = amplitude + amplitude * CGFloat(sin(rel * frequency * 2 * .pi + phase))
            if x == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
            x += step
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

struct AnimatedWaves: View {
    var colors: [Color]
    var amplitude: CGFloat = 8
    var speed: Double = 1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate * speed
            ZStack(alignment: .top) {
                ForEach(Array(colors.enumerated()), id: \.offset) { i, c in
                    WaveShape(phase: t * (1 + Double(i) * 0.35) + Double(i) * 1.7,
                              amplitude: amplitude * (1 - CGFloat(i) * 0.12),
                              frequency: 1.1 + Double(i) * 0.35)
                        .fill(c)
                        .offset(y: CGFloat(i) * amplitude * 1.3)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Bobler, sne, svævende emoji

struct BubblesView: View {
    var count = 14
    var color: Color = .white

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            Canvas { g, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let seed = Double(i) * 12.9898 + 3
                    let speed = 16 + (sin(seed) * 0.5 + 0.5) * 30
                    let x0 = (sin(seed * 3.1) * 0.5 + 0.5) * size.width
                    let r = 3 + (cos(seed * 1.7) * 0.5 + 0.5) * 6
                    let travel = Double(size.height) + 40
                    let y = Double(size.height) + 20 - (t * speed + seed * 50).truncatingRemainder(dividingBy: travel)
                    let x = x0 + sin(t * 1.3 + seed) * 10
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    g.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.18)))
                    g.stroke(Path(ellipseIn: rect), with: .color(color.opacity(0.7)), lineWidth: 1.3)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SnowView: View {
    var count = 40

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            Canvas { g, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let seed = Double(i) * 7.31 + 1
                    let speed = 12 + (sin(seed * 2.3) * 0.5 + 0.5) * 22
                    let x0 = (sin(seed * 5.7) * 0.5 + 0.5) * size.width
                    let r = 1.5 + (cos(seed) * 0.5 + 0.5) * 2.5
                    let travel = Double(size.height) + 20
                    let y = (t * speed + seed * 80).truncatingRemainder(dividingBy: travel) - 10
                    let x = x0 + sin(t * 0.8 + seed) * 14
                    g.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.85)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct FloatingEmoji: View {
    var emoji: String
    var count = 5
    var speed: Double = 0.35

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            Canvas { g, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let resolved = g.resolve(Text(emoji).font(.system(size: 18)))
                for i in 0..<count {
                    let seed = Double(i) * 4.7 + 2
                    let phase = (t * speed + seed * 0.37).truncatingRemainder(dividingBy: 1)
                    let x = (sin(seed * 9.1) * 0.5 + 0.5) * Double(size.width) + sin(t * 2 + seed) * 8
                    let y = Double(size.height) * (1 - phase)
                    g.opacity = phase < 0.2 ? phase * 5 : (1 - phase) * 1.25
                    g.draw(resolved, at: CGPoint(x: x, y: y))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Partikel-eksplosion (fx fisk ved afkrydsning)

struct BurstParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let emoji: String
    let spin: Double
    let size: CGFloat
}

struct BurstView: View {
    var trigger: Int
    var emojis: [String] = ["🐟", "✨", "💙", "🐟"]
    var count = 10

    @State private var particles: [BurstParticle] = []
    @State private var fired = false

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .rotationEffect(.degrees(fired ? p.spin : 0))
                    .offset(x: fired ? CGFloat(cos(p.angle)) * p.distance : 0,
                            y: fired ? CGFloat(sin(p.angle)) * p.distance - 20 : 0)
                    .scaleEffect(fired ? 1.1 : 0.2)
                    .opacity(fired ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        fired = false
        particles = (0..<count).map { i in
            BurstParticle(angle: Double(i) / Double(count) * 2 * .pi + Double.random(in: -0.3...0.3),
                          distance: CGFloat.random(in: 45...90),
                          emoji: emojis.randomElement() ?? "✨",
                          spin: Double.random(in: -200...200),
                          size: CGFloat.random(in: 14...22))
        }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.95)) { fired = true }
        }
    }
}

// MARK: - Knapper

struct SoftButtonStyle: ButtonStyle {
    var color: Color = Theme.oceanDeep
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(18, .bold))
            .foregroundStyle(foreground)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(color.opacity(0.55))
                        .offset(y: 5)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(color)
                        .offset(y: configuration.isPressed ? 4 : 0)
                }
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BouncyStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Modifiers

struct AppearIn: ViewModifier {
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 22)
            .scaleEffect(shown ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(delay)) { shown = true }
            }
    }
}

struct Shimmer: ViewModifier {
    @State private var x: CGFloat = -0.6

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { g in
                    LinearGradient(colors: [.clear, .white.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: g.size.width * 0.35)
                        .offset(x: x * g.size.width)
                }
                .mask(content)
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { x = 1.3 }
            }
    }
}

struct Wiggle: ViewModifier {
    var active: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([0.0, -6.0, 6.0, -3.0, 0.0]) { view, angle in
                view.rotationEffect(.degrees(angle))
            } animation: { _ in .easeInOut(duration: 0.12) }
        } else {
            content
        }
    }
}

struct Breathing: ViewModifier {
    var amount: CGFloat = 0.04
    var duration: Double = 1.6
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1 + amount : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

struct Floating: ViewModifier {
    var distance: CGFloat = 6
    var duration: Double = 2.2
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .offset(y: on ? -distance : distance)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

extension View {
    func appearIn(_ delay: Double = 0) -> some View { modifier(AppearIn(delay: delay)) }
    func shimmer() -> some View { modifier(Shimmer()) }
    func breathing(_ amount: CGFloat = 0.04, duration: Double = 1.6) -> some View { modifier(Breathing(amount: amount, duration: duration)) }
    func floating(_ distance: CGFloat = 6, duration: Double = 2.2) -> some View { modifier(Floating(distance: distance, duration: duration)) }

    func card(_ color: Color = .white, radius: CGFloat = 26) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .shadow(color: Theme.oceanDark.opacity(0.08), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Skrivemaskine-tekst

struct TypewriterText: View {
    let text: String
    var font: Font = .rounded(16, .medium)
    var color: Color = Theme.ink
    @State private var shown = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text).opacity(0)
            Text(String(text.prefix(shown)))
        }
        .font(font)
        .foregroundStyle(color)
        .task(id: text) {
            shown = 0
            for i in 0...text.count {
                shown = i
                try? await Task.sleep(nanoseconds: 22_000_000)
            }
        }
    }
}

// MARK: - Taleboble

struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            TypewriterText(text: text, font: .rounded(15, .semibold))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            TriangleShape()
                .fill(.white)
                .frame(width: 18, height: 10)
                .rotationEffect(.degrees(180))
        }
        .shadow(color: Theme.oceanDark.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Afkrydsnings-flueben

struct CheckMarkShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.18, y: r.minY + r.height * 0.55))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.42, y: r.minY + r.height * 0.78))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.84, y: r.minY + r.height * 0.26))
        return p
    }
}

// MARK: - Fremgangsbjælke med bølge

struct WaveProgressBar: View {
    var progress: Double
    var tint: Color = Theme.oceanDeep
    var height: CGFloat = 26

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, g.size.width * min(1, max(0, progress))))
                    .opacity(progress > 0 ? 1 : 0)
                    .overlay(
                        AnimatedWaves(colors: [Color.white.opacity(0.25)], amplitude: 3, speed: 2)
                            .offset(y: height * 0.35)
                            .clipShape(Capsule())
                    )
                    .shimmer()
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
    }
}
