import SwiftUI

// Kodetegnede hatte til sælen. Hver hat tegnes centreret i sit eget koordinatsystem
// (centrum = ankerpunktet (0.5s, 0.13s) på sælen), med kanten omkring y = +0.04s…+0.07s.
// Ingen animationer, ingen billeder, kun bløde flade former.


enum HatDesigns {
    /// Nye butiksvarer (slot .hat).
    static let newItems: [ShopItem] = [
        ShopItem("beanie", "Hue med kvast", .hat, "🧶", Tuning.Price.beanie),
        ShopItem("sailorhat", "Sømandshue", .hat, "⚓", Tuning.Price.sailorHat),
        ShopItem("viking", "Vikinghjelm", .hat, "🪓", Tuning.Price.viking),
        ShopItem("froghat", "Frøhue", .hat, "🐸", Tuning.Price.frogHat),
        ShopItem("chefhat", "Kokkehue", .hat, "🧑‍🍳", Tuning.Price.chefHat),
        ShopItem("bunnyears", "Kaninører", .hat, "🐰", Tuning.Price.bunnyEars, season: 4),
    ]

    /// Returnerer en tegnet hat for id, eller nil hvis denne fil ikke tegner den.
    static func view(_ id: String, s: CGFloat) -> AnyView? {
        switch id {
        case "nissehue": return AnyView(NisseHatView(s: s))
        case "pumpkin": return AnyView(PumpkinHatView(s: s))
        case "cap": return AnyView(CapHatView(s: s))
        case "flower": return AnyView(FlowerHatView(s: s))
        case "bow": return AnyView(BowHatView(s: s))
        case "strawhat": return AnyView(StrawHatView(s: s))
        case "tophat": return AnyView(TopHatView(s: s))
        case "crown": return AnyView(CrownHatView(s: s))
        case "beanie": return AnyView(BeanieHatView(s: s))
        case "sailorhat": return AnyView(SailorHatView(s: s))
        case "viking": return AnyView(VikingHatView(s: s))
        case "froghat": return AnyView(FrogHatView(s: s))
        case "chefhat": return AnyView(ChefHatView(s: s))
        case "bunnyears": return AnyView(BunnyEarsHatView(s: s))
        default: return nil
        }
    }
}

// MARK: - Former

/// Øverste halvdel af en ellipse med flad bund (kuppel).
struct HatDomeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let k: CGFloat = 0.5523
        let rx: CGFloat = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.maxY - r.height * k),
                   control2: CGPoint(x: r.midX - rx * k, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.midX + rx * k, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.maxY - r.height * k))
        p.closeSubpath()
        return p
    }
}

/// Krone med tre bløde takker.
struct HatCrownShape: Shape {
    func path(in r: CGRect) -> Path {
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.04, y: r.minY + h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.3, y: r.minY + h * 0.55),
                       control: CGPoint(x: r.minX + w * 0.16, y: r.minY + h * 0.52))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY),
                       control: CGPoint(x: r.minX + w * 0.42, y: r.minY + h * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.7, y: r.minY + h * 0.55),
                       control: CGPoint(x: r.minX + w * 0.58, y: r.minY + h * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.96, y: r.minY + h * 0.2),
                       control: CGPoint(x: r.minX + w * 0.84, y: r.minY + h * 0.52))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Nissehue der knækker over mod højre med hængende spids.
struct HatElfShape: Shape {
    func path(in r: CGRect) -> Path {
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX + w * 0.04, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.90, y: r.minY + h * 0.55),
                   control1: CGPoint(x: r.minX + w * 0.08, y: r.minY + h * 0.15),
                   control2: CGPoint(x: r.minX + w * 0.60, y: r.minY - h * 0.12))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.64, y: r.minY + h * 0.38),
                       control: CGPoint(x: r.minX + w * 0.74, y: r.minY + h * 0.46))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.96, y: r.maxY),
                       control: CGPoint(x: r.minX + w * 0.70, y: r.minY + h * 0.70))
        p.closeSubpath()
        return p
    }
}

/// Et blødt horn: bred base i venstre side, spids øverst til højre.
struct HatHornShape: Shape {
    func path(in r: CGRect) -> Path {
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.minX + w * 0.9, y: r.minY + h * 0.95))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.45),
                       control: CGPoint(x: r.minX + w * 0.55, y: r.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

private func hatGradient(_ top: UInt32, _ bottom: UInt32) -> LinearGradient {
    LinearGradient(colors: [Color(hex: top), Color(hex: bottom)], startPoint: .top, endPoint: .bottom)
}

// MARK: - Nissehue

struct NisseHatView: View {
    let s: CGFloat
    private let fluff = Color(hex: 0xFBF8F3)

    var body: some View {
        ZStack {
            HatElfShape()
                .fill(hatGradient(0xEC8A86, 0xD9666C))
                .frame(width: s * 0.40, height: s * 0.30)
                .offset(y: -s * 0.07)
            Capsule().fill(Color.white.opacity(0.35))
                .frame(width: s * 0.025, height: s * 0.09)
                .rotationEffect(.degrees(20))
                .offset(x: -s * 0.1, y: -s * 0.04)
            Capsule().fill(fluff)
                .frame(width: s * 0.42, height: s * 0.075)
                .offset(y: s * 0.055)
            ForEach(0..<6, id: \.self) { i in
                Circle().fill(fluff)
                    .frame(width: s * 0.075, height: s * 0.075)
                    .offset(x: s * (-0.175 + 0.07 * CGFloat(i)), y: s * 0.048)
            }
            Capsule().fill(Theme.iceDark.opacity(0.35))
                .frame(width: s * 0.36, height: s * 0.012)
                .offset(y: s * 0.078)
            ZStack {
                Circle().fill(fluff).frame(width: s * 0.09, height: s * 0.09)
                Circle().fill(fluff).frame(width: s * 0.04, height: s * 0.04).offset(x: s * 0.035, y: -s * 0.02)
                Circle().fill(fluff).frame(width: s * 0.04, height: s * 0.04).offset(x: -s * 0.03, y: s * 0.03)
                Circle().fill(Color.white).frame(width: s * 0.025, height: s * 0.025).offset(x: -s * 0.015, y: -s * 0.018)
            }
            .offset(x: s * 0.16, y: -s * 0.055)
        }
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Græskarhat

struct PumpkinHatView: View {
    let s: CGFloat
    private let main = Color(hex: 0xF6B38A)
    private let dark = Color(hex: 0xE89A6E)

    var body: some View {
        ZStack {
            Ellipse().fill(dark)
                .frame(width: s * 0.17, height: s * 0.20)
                .offset(x: -s * 0.09, y: -s * 0.03)
            Ellipse().fill(dark)
                .frame(width: s * 0.17, height: s * 0.20)
                .offset(x: s * 0.09, y: -s * 0.03)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xF9C6A3), main], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.20, height: s * 0.22)
                .offset(y: -s * 0.035)
            Capsule().fill(dark.opacity(0.55))
                .frame(width: s * 0.012, height: s * 0.15)
                .offset(x: -s * 0.05, y: -s * 0.03)
            Capsule().fill(dark.opacity(0.55))
                .frame(width: s * 0.012, height: s * 0.15)
                .offset(x: s * 0.05, y: -s * 0.03)
            RoundedRectangle(cornerRadius: s * 0.012).fill(Color(hex: 0x9CBF86))
                .frame(width: s * 0.035, height: s * 0.06)
                .rotationEffect(.degrees(12))
                .offset(x: s * 0.005, y: -s * 0.155)
            Ellipse().fill(Theme.mint)
                .frame(width: s * 0.07, height: s * 0.035)
                .rotationEffect(.degrees(-25))
                .offset(x: s * 0.045, y: -s * 0.155)
            Capsule().fill(Color.white.opacity(0.55))
                .frame(width: s * 0.05, height: s * 0.018)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.05, y: -s * 0.1)
        }
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Kasket

struct CapHatView: View {
    let s: CGFloat
    private let dark = Color(hex: 0x5E9CC7)

    var body: some View {
        ZStack {
            HatDomeShape()
                .fill(hatGradient(0xA5CFEC, 0x7FB3D9))
                .frame(width: s * 0.36, height: s * 0.19)
                .offset(y: -s * 0.025)
            HatDomeShape()
                .stroke(dark.opacity(0.3), lineWidth: s * 0.008)
                .frame(width: s * 0.18, height: s * 0.19)
                .offset(y: -s * 0.025)
            Circle().fill(dark)
                .frame(width: s * 0.035, height: s * 0.035)
                .offset(y: -s * 0.115)
            Circle().fill(Theme.cream)
                .frame(width: s * 0.075, height: s * 0.075)
                .offset(y: -s * 0.025)
            Ellipse().fill(Theme.ocean)
                .frame(width: s * 0.035, height: s * 0.022)
                .offset(x: -s * 0.006, y: -s * 0.025)
            TriangleShape().fill(Theme.ocean)
                .frame(width: s * 0.022, height: s * 0.018)
                .rotationEffect(.degrees(-90))
                .offset(x: s * 0.018, y: -s * 0.025)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x6FA8D2), dark], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.40, height: s * 0.075)
                .offset(y: s * 0.065)
            Capsule().fill(Color.white.opacity(0.5))
                .frame(width: s * 0.05, height: s * 0.016)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.1, y: -s * 0.07)
        }
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Blomst

struct FlowerHatView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Ellipse().fill(Theme.mint)
                .frame(width: s * 0.09, height: s * 0.045)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.085, y: s * 0.06)
            Ellipse().fill(Theme.mint)
                .frame(width: s * 0.09, height: s * 0.045)
                .rotationEffect(.degrees(30))
                .offset(x: s * 0.085, y: s * 0.06)
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(hatGradient(0xFBD6E1, 0xF4A9BF))
                    .frame(width: s * 0.10, height: s * 0.12)
                    .offset(y: -s * 0.06)
                    .rotationEffect(.degrees(Double(i) * 72.0))
            }
            Circle().fill(Theme.sun)
                .frame(width: s * 0.08, height: s * 0.08)
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(Color(hex: 0xF9DDA0))
                    .frame(width: s * 0.014, height: s * 0.014)
                    .offset(y: -s * 0.02)
                    .rotationEffect(.degrees(Double(i) * 72.0 + 36.0))
            }
            Capsule().fill(Color.white.opacity(0.6))
                .frame(width: s * 0.04, height: s * 0.014)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.05, y: -s * 0.08)
        }
        .rotationEffect(.degrees(-12))
        .offset(x: s * 0.13, y: s * 0.02)
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Sløjfe

struct BowHatView: View {
    let s: CGFloat
    private let pink = Color(hex: 0xF4A7B9)
    private let dark = Color(hex: 0xE38EA4)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.02).fill(dark)
                .frame(width: s * 0.045, height: s * 0.11)
                .rotationEffect(.degrees(20))
                .offset(x: -s * 0.03, y: s * 0.06)
            RoundedRectangle(cornerRadius: s * 0.02).fill(dark)
                .frame(width: s * 0.045, height: s * 0.11)
                .rotationEffect(.degrees(-20))
                .offset(x: s * 0.03, y: s * 0.06)
            Ellipse().fill(pink)
                .frame(width: s * 0.16, height: s * 0.12)
                .rotationEffect(.degrees(-14))
                .offset(x: -s * 0.085)
            Ellipse().fill(pink)
                .frame(width: s * 0.16, height: s * 0.12)
                .rotationEffect(.degrees(14))
                .offset(x: s * 0.085)
            Ellipse().fill(dark.opacity(0.55))
                .frame(width: s * 0.06, height: s * 0.045)
                .offset(x: -s * 0.055, y: s * 0.005)
            Ellipse().fill(dark.opacity(0.55))
                .frame(width: s * 0.06, height: s * 0.045)
                .offset(x: s * 0.055, y: s * 0.005)
            RoundedRectangle(cornerRadius: s * 0.022).fill(dark)
                .frame(width: s * 0.06, height: s * 0.07)
            Capsule().fill(Color.white.opacity(0.6))
                .frame(width: s * 0.045, height: s * 0.014)
                .rotationEffect(.degrees(-25))
                .offset(x: -s * 0.11, y: -s * 0.03)
        }
        .rotationEffect(.degrees(8))
        .offset(x: s * 0.07, y: s * 0.01)
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Stråhat

struct StrawHatView: View {
    let s: CGFloat
    private let straw = Color(hex: 0xF0DCA8)
    private let strawDark = Color(hex: 0xD9BE82)

    var body: some View {
        ZStack {
            Ellipse().fill(hatGradient(0xF5E5BA, 0xE9D198))
                .frame(width: s * 0.52, height: s * 0.13)
                .offset(y: s * 0.05)
            Ellipse().stroke(strawDark.opacity(0.5), lineWidth: s * 0.007)
                .frame(width: s * 0.44, height: s * 0.095)
                .offset(y: s * 0.05)
            HatDomeShape().fill(straw)
                .frame(width: s * 0.28, height: s * 0.17)
                .offset(y: -s * 0.025)
            HatDomeShape().stroke(strawDark.opacity(0.35), lineWidth: s * 0.007)
                .frame(width: s * 0.18, height: s * 0.12)
                .offset(y: -s * 0.025)
            RoundedRectangle(cornerRadius: s * 0.01).fill(Theme.ocean)
                .frame(width: s * 0.28, height: s * 0.04)
                .offset(y: s * 0.035)
            Ellipse().fill(Theme.oceanDeep)
                .frame(width: s * 0.05, height: s * 0.035)
                .rotationEffect(.degrees(-20))
                .offset(x: s * 0.085, y: s * 0.03)
            Ellipse().fill(Theme.oceanDeep)
                .frame(width: s * 0.05, height: s * 0.035)
                .rotationEffect(.degrees(20))
                .offset(x: s * 0.125, y: s * 0.03)
            Circle().fill(Theme.oceanDark)
                .frame(width: s * 0.022, height: s * 0.022)
                .offset(x: s * 0.105, y: s * 0.032)
            Capsule().fill(Color.white.opacity(0.5))
                .frame(width: s * 0.05, height: s * 0.016)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.07, y: -s * 0.07)
        }
        .frame(width: s * 0.55, height: s * 0.4)
    }
}

// MARK: - Høj hat

struct TopHatView: View {
    let s: CGFloat
    private let grey = Color(hex: 0x4A4F5A)

    var body: some View {
        ZStack {
            Capsule().fill(grey)
                .frame(width: s * 0.40, height: s * 0.06)
                .offset(y: s * 0.05)
            RoundedRectangle(cornerRadius: s * 0.03)
                .fill(hatGradient(0x5C626E, 0x474C57))
                .frame(width: s * 0.26, height: s * 0.24)
                .offset(y: -s * 0.065)
            Ellipse().fill(Color(hex: 0x6A707C))
                .frame(width: s * 0.25, height: s * 0.045)
                .offset(y: -s * 0.18)
            Rectangle().fill(Theme.sand)
                .frame(width: s * 0.26, height: s * 0.045)
                .offset(y: s * 0.015)
            Circle().fill(Theme.blush)
                .frame(width: s * 0.03, height: s * 0.03)
                .offset(x: s * 0.085, y: s * 0.015)
            Capsule().fill(Color.white.opacity(0.22))
                .frame(width: s * 0.022, height: s * 0.13)
                .offset(x: -s * 0.08, y: -s * 0.08)
        }
        .rotationEffect(.degrees(-5))
        .frame(width: s * 0.5, height: s * 0.45)
    }
}

// MARK: - Krone

struct CrownHatView: View {
    let s: CGFloat
    private let ball = Color(hex: 0xFBE3A4)

    var body: some View {
        ZStack {
            HatCrownShape()
                .fill(hatGradient(0xF9DE95, 0xF0C46A))
                .frame(width: s * 0.34, height: s * 0.18)
                .offset(y: -s * 0.02)
            Circle().fill(ball).frame(width: s * 0.04, height: s * 0.04)
                .offset(x: -s * 0.156, y: -s * 0.074)
            Circle().fill(ball).frame(width: s * 0.045, height: s * 0.045)
                .offset(y: -s * 0.11)
            Circle().fill(ball).frame(width: s * 0.04, height: s * 0.04)
                .offset(x: s * 0.156, y: -s * 0.074)
            Ellipse().fill(Theme.lavender)
                .frame(width: s * 0.035, height: s * 0.045)
                .offset(y: -s * 0.025)
            RoundedRectangle(cornerRadius: s * 0.015).fill(Color(hex: 0xE8B65C))
                .frame(width: s * 0.35, height: s * 0.05)
                .offset(y: s * 0.045)
            Circle().fill(Theme.rose).frame(width: s * 0.032, height: s * 0.032)
                .offset(y: s * 0.045)
            Circle().fill(Theme.ocean).frame(width: s * 0.026, height: s * 0.026)
                .offset(x: -s * 0.09, y: s * 0.045)
            Circle().fill(Theme.mint).frame(width: s * 0.026, height: s * 0.026)
                .offset(x: s * 0.09, y: s * 0.045)
            Capsule().fill(Color.white.opacity(0.55))
                .frame(width: s * 0.045, height: s * 0.014)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.09, y: -s * 0.0)
        }
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Hue med kvast (ny)

struct BeanieHatView: View {
    let s: CGFloat
    private let cuff = Color(hex: 0xADA6DE)

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF6C6D0))
                .frame(width: s * 0.09, height: s * 0.09)
                .offset(y: -s * 0.15)
            HatDomeShape()
                .fill(hatGradient(0xD8D4F3, 0xC8C3EC))
                .frame(width: s * 0.36, height: s * 0.20)
                .overlay {
                    HStack(spacing: s * 0.035) {
                        ForEach(0..<7, id: \.self) { _ in
                            Capsule().fill(Color.white.opacity(0.25))
                                .frame(width: s * 0.012, height: s * 0.2)
                        }
                    }
                }
                .clipShape(HatDomeShape())
                .offset(y: -s * 0.04)
            RoundedRectangle(cornerRadius: s * 0.03).fill(cuff)
                .frame(width: s * 0.38, height: s * 0.07)
                .offset(y: s * 0.055)
            HStack(spacing: s * 0.025) {
                ForEach(0..<10, id: \.self) { _ in
                    Capsule().fill(Color.white.opacity(0.28))
                        .frame(width: s * 0.01, height: s * 0.05)
                }
            }
            .offset(y: s * 0.055)
            Circle().fill(Color.white.opacity(0.6))
                .frame(width: s * 0.025, height: s * 0.025)
                .offset(x: -s * 0.015, y: -s * 0.165)
            Capsule().fill(Color.white.opacity(0.5))
                .frame(width: s * 0.05, height: s * 0.016)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.09, y: -s * 0.08)
        }
        .frame(width: s * 0.5, height: s * 0.42)
    }
}

// MARK: - Sømandshue (ny)

struct SailorHatView: View {
    let s: CGFloat
    private let navy = Theme.oceanDark

    var body: some View {
        ZStack {
            HatDomeShape()
                .fill(hatGradient(0xFFFFFF, 0xE6EDF2))
                .frame(width: s * 0.30, height: s * 0.15)
                .offset(y: -s * 0.02)
            ZStack {
                Circle().stroke(navy, lineWidth: s * 0.007)
                    .frame(width: s * 0.018, height: s * 0.018)
                    .offset(y: -s * 0.028)
                Capsule().fill(navy)
                    .frame(width: s * 0.008, height: s * 0.045)
                Capsule().fill(navy)
                    .frame(width: s * 0.03, height: s * 0.007)
                    .offset(y: -s * 0.012)
                CupShape().stroke(navy, style: StrokeStyle(lineWidth: s * 0.007, lineCap: .round))
                    .frame(width: s * 0.04, height: s * 0.008)
                    .offset(y: s * 0.016)
            }
            .offset(y: -s * 0.03)
            Capsule().fill(Color.white)
                .frame(width: s * 0.40, height: s * 0.075)
                .offset(y: s * 0.055)
            Capsule().stroke(Theme.iceDark, lineWidth: s * 0.006)
                .frame(width: s * 0.40, height: s * 0.075)
                .offset(y: s * 0.055)
            Capsule().fill(navy.opacity(0.85))
                .frame(width: s * 0.34, height: s * 0.012)
                .offset(y: s * 0.055)
            Capsule().fill(Color.white.opacity(0.9))
                .frame(width: s * 0.045, height: s * 0.014)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.08, y: -s * 0.06)
        }
        .rotationEffect(.degrees(-7))
        .frame(width: s * 0.5, height: s * 0.4)
    }
}

// MARK: - Vikinghjelm (ny)

struct VikingHatView: View {
    let s: CGFloat
    private let horn = Color(hex: 0xF6EEDC)
    private let band = Color(hex: 0xD9BC8C)

    var body: some View {
        ZStack {
            HatHornShape().fill(horn)
                .frame(width: s * 0.13, height: s * 0.14)
                .offset(x: s * 0.20, y: -s * 0.06)
            HatHornShape().fill(horn)
                .frame(width: s * 0.13, height: s * 0.14)
                .scaleEffect(x: -1, y: 1)
                .offset(x: -s * 0.20, y: -s * 0.06)
            HatDomeShape()
                .fill(hatGradient(0xDCE0E7, 0xB9BFCA))
                .frame(width: s * 0.34, height: s * 0.19)
                .offset(y: -s * 0.025)
            Capsule().fill(band)
                .frame(width: s * 0.04, height: s * 0.17)
                .offset(y: -s * 0.03)
            RoundedRectangle(cornerRadius: s * 0.02).fill(band)
                .frame(width: s * 0.36, height: s * 0.05)
                .offset(y: s * 0.05)
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(Theme.cream)
                    .frame(width: s * 0.016, height: s * 0.016)
                    .offset(x: s * (-0.14 + 0.07 * CGFloat(i)), y: s * 0.05)
            }
            Capsule().fill(Color.white.opacity(0.6))
                .frame(width: s * 0.05, height: s * 0.016)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.09, y: -s * 0.07)
        }
        .frame(width: s * 0.6, height: s * 0.4)
    }
}

// MARK: - Frøhue (ny)

struct FrogHatView: View {
    let s: CGFloat
    private let green = Color(hex: 0x9ED9BD)

    private func frogEye() -> some View {
        ZStack {
            Circle().fill(green).frame(width: s * 0.10, height: s * 0.10)
            Circle().fill(Color.white).frame(width: s * 0.07, height: s * 0.07)
            Circle().fill(Theme.eye).frame(width: s * 0.04, height: s * 0.04)
                .offset(y: s * 0.005)
            Circle().fill(Color.white).frame(width: s * 0.014, height: s * 0.014)
                .offset(x: -s * 0.008, y: -s * 0.006)
        }
    }

    var body: some View {
        ZStack {
            frogEye().offset(x: -s * 0.09, y: -s * 0.115)
            frogEye().offset(x: s * 0.09, y: -s * 0.115)
            HatDomeShape()
                .fill(hatGradient(0xB0E2CA, 0x8FD3B6))
                .frame(width: s * 0.36, height: s * 0.18)
                .offset(y: -s * 0.02)
            Ellipse().fill(Theme.blush.opacity(0.6))
                .frame(width: s * 0.05, height: s * 0.025)
                .offset(x: -s * 0.1, y: -s * 0.01)
            Ellipse().fill(Theme.blush.opacity(0.6))
                .frame(width: s * 0.05, height: s * 0.025)
                .offset(x: s * 0.1, y: -s * 0.01)
            CupShape().stroke(Theme.mintDark, style: StrokeStyle(lineWidth: s * 0.01, lineCap: .round))
                .frame(width: s * 0.07, height: s * 0.012)
                .offset(y: -s * 0.025)
            Capsule().fill(Theme.mintDark.opacity(0.8))
                .frame(width: s * 0.38, height: s * 0.05)
                .offset(y: s * 0.065)
        }
        .frame(width: s * 0.5, height: s * 0.42)
    }
}

// MARK: - Kokkehue (ny)

struct ChefHatView: View {
    let s: CGFloat

    private func puffs(_ c: Color, _ grow: CGFloat) -> some View {
        ZStack {
            Circle().fill(c).frame(width: s * (0.14 + grow), height: s * (0.14 + grow))
                .offset(x: -s * 0.08, y: -s * 0.07)
            Circle().fill(c).frame(width: s * (0.14 + grow), height: s * (0.14 + grow))
                .offset(x: s * 0.08, y: -s * 0.07)
            Circle().fill(c).frame(width: s * (0.13 + grow), height: s * (0.13 + grow))
                .offset(x: -s * 0.04, y: -s * 0.14)
            Circle().fill(c).frame(width: s * (0.13 + grow), height: s * (0.13 + grow))
                .offset(x: s * 0.045, y: -s * 0.145)
            Circle().fill(c).frame(width: s * (0.15 + grow), height: s * (0.15 + grow))
                .offset(y: -s * 0.09)
        }
    }

    var body: some View {
        ZStack {
            puffs(Theme.iceDark, 0.012)
            puffs(Color.white, 0)
            RoundedRectangle(cornerRadius: s * 0.02).fill(Color(hex: 0xF6F8FA))
                .frame(width: s * 0.26, height: s * 0.08)
                .offset(y: s * 0.035)
            RoundedRectangle(cornerRadius: s * 0.02).stroke(Theme.iceDark, lineWidth: s * 0.006)
                .frame(width: s * 0.26, height: s * 0.08)
                .offset(y: s * 0.035)
            HStack(spacing: s * 0.045) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule().fill(Theme.iceDark.opacity(0.7))
                        .frame(width: s * 0.008, height: s * 0.055)
                }
            }
            .offset(y: s * 0.035)
            Capsule().fill(Theme.oceanLight)
                .frame(width: s * 0.05, height: s * 0.016)
                .rotationEffect(.degrees(-30))
                .offset(x: -s * 0.09, y: -s * 0.12)
        }
        .frame(width: s * 0.5, height: s * 0.42)
    }
}

// MARK: - Kaninører (ny, april)

struct BunnyEarsHatView: View {
    let s: CGFloat
    private let band = Color(hex: 0xF4B6C6)

    private func ear() -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xFBF1F4))
                .frame(width: s * 0.09, height: s * 0.22)
            Ellipse().fill(Color(hex: 0xF7C2CF))
                .frame(width: s * 0.045, height: s * 0.15)
                .offset(y: s * 0.012)
        }
    }

    var body: some View {
        ZStack {
            ear()
                .rotationEffect(.degrees(-12))
                .offset(x: -s * 0.08, y: -s * 0.075)
            ear()
                .rotationEffect(.degrees(28))
                .offset(x: s * 0.10, y: -s * 0.065)
            HumpShape()
                .stroke(band, style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                .frame(width: s * 0.40, height: s * 0.05)
                .offset(y: s * 0.07)
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(Color.white)
                        .frame(width: s * 0.025, height: s * 0.025)
                        .offset(y: -s * 0.016)
                        .rotationEffect(.degrees(Double(i) * 72.0))
                }
                Circle().fill(Theme.sun)
                    .frame(width: s * 0.02, height: s * 0.02)
            }
            .offset(x: -s * 0.13, y: s * 0.07)
            Capsule().fill(Color.white.opacity(0.8))
                .frame(width: s * 0.014, height: s * 0.05)
                .rotationEffect(.degrees(-12))
                .offset(x: -s * 0.09, y: -s * 0.13)
        }
        .frame(width: s * 0.5, height: s * 0.45)
    }
}
