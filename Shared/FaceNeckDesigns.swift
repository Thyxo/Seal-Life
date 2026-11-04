import SwiftUI

// Tegnede briller og hals-tilbehør til sælen.
// Briller-visninger har centrum i øjenhøjde (0.5s, 0.42s); hals-visninger har centrum i (0.5s, 0.69s).


enum FaceNeckDesigns {
    /// Nye butiksting (briller og hals).
    static let newItems: [ShopItem] = [
        ShopItem("heartglasses", "Hjertebriller", .glasses, "💕", Tuning.Price.heartglasses),
        ShopItem("starglasses", "Stjernebriller", .glasses, "⭐", Tuning.Price.starglasses),
        ShopItem("monocle", "Monokel", .glasses, "🧐", Tuning.Price.monocle),
        ShopItem("pearls", "Perlekæde", .neck, "📿", Tuning.Price.pearls),
        ShopItem("bowtie", "Butterfly", .neck, "🦋", Tuning.Price.bowtie),
        ShopItem("bandana", "Bandana", .neck, "🤠", Tuning.Price.bandana),
        ShopItem("lifebuoy", "Redningskrans", .neck, "🛟", Tuning.Price.lifebuoy),
    ]

    /// Tegnet visning for id, eller nil hvis denne fil ikke tegner den.
    static func view(_ id: String, s: CGFloat) -> AnyView? {
        switch id {
        case "nerdglasses": return AnyView(FNNerdGlassesView(s: s))
        case "goggles": return AnyView(FNGogglesView(s: s))
        case "heartglasses": return AnyView(FNHeartGlassesView(s: s))
        case "starglasses": return AnyView(FNStarGlassesView(s: s))
        case "monocle": return AnyView(FNMonocleView(s: s))
        case "bell": return AnyView(FNBellView(s: s))
        case "lei": return AnyView(FNLeiView(s: s))
        case "medal": return AnyView(FNMedalView(s: s))
        case "scarf_red":
            return AnyView(FNScarfView(s: s, main: Color(hex: 0xE88A8A), dark: Color(hex: 0xCF6E76), light: Color(hex: 0xF7C6C3)))
        case "scarf_blue":
            return AnyView(FNScarfView(s: s, main: Color(hex: 0x86ADE0), dark: Color(hex: 0x6890C6), light: Color(hex: 0xCADDF5)))
        case "pearls": return AnyView(FNPearlsView(s: s))
        case "bowtie": return AnyView(FNBowTieView(s: s))
        case "bandana": return AnyView(FNBandanaView(s: s))
        case "lifebuoy": return AnyView(FNLifebuoyView(s: s))
        default: return nil
        }
    }
}

// MARK: - Hjælpere

enum AccFNMath {
    /// Punkt på hals-buen (frame w × h centreret i 0,0): enderne ligger i y = -h/2, midten i y = +h/2.
    static func arcPoint(_ t: CGFloat, w: CGFloat, h: CGFloat) -> CGPoint {
        let x: CGFloat = -w / 2 + w * t
        let y: CGFloat = -h / 2 + 4 * h * t * (1 - t)
        return CGPoint(x: x, y: y)
    }

    /// Tangentens vinkel på hals-buen.
    static func arcAngle(_ t: CGFloat, w: CGFloat, h: CGFloat) -> Angle {
        let dy: Double = Double(4 * h * (1 - 2 * t))
        let dx: Double = Double(w)
        return Angle(radians: atan2(dy, dx))
    }

    /// Punkt på en cirkel (i ud af n), startende øverst.
    static func polar(_ i: Int, of n: Int, r: CGFloat) -> CGPoint {
        let a: Double = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(n)
        return CGPoint(x: r * CGFloat(cos(a)), y: r * CGFloat(sin(a)))
    }
}

/// Smil-formet bue (åben sti). Enderne i toppen af rammen, midten i bunden.
struct AccFNArcShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + 2 * r.height))
        return p
    }
}

struct AccFNStarShape: Shape {
    var points: Int = 5
    var inner: CGFloat = 0.48

    func path(in r: CGRect) -> Path {
        var p = Path()
        let outerR: CGFloat = min(r.width, r.height) / 2
        let innerR: CGFloat = outerR * inner
        let cx: CGFloat = r.midX
        let cy: CGFloat = r.midY + outerR * 0.08
        let count: Int = points * 2
        for i in 0..<count {
            let a: Double = -Double.pi / 2 + Double(i) * Double.pi / Double(points)
            let rad: CGFloat = (i % 2 == 0) ? outerR : innerR
            let pt = CGPoint(x: cx + rad * CGFloat(cos(a)), y: cy + rad * CGFloat(sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct AccFNHeartShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.32),
                   control1: CGPoint(x: r.minX + w * 0.30, y: r.maxY - h * 0.18),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.62))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.22),
                   control1: CGPoint(x: r.minX, y: r.minY - h * 0.02),
                   control2: CGPoint(x: r.midX - w * 0.05, y: r.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.32),
                   control1: CGPoint(x: r.midX + w * 0.05, y: r.minY - h * 0.02),
                   control2: CGPoint(x: r.maxX, y: r.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.62),
                   control2: CGPoint(x: r.maxX - w * 0.30, y: r.maxY - h * 0.18))
        p.closeSubpath()
        return p
    }
}

struct AccFNBellShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let lipY: CGFloat = r.maxY - h * 0.12
        p.move(to: CGPoint(x: r.minX, y: lipY))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.24, y: r.minY + h * 0.22),
                       control: CGPoint(x: r.minX + w * 0.16, y: r.minY + h * 0.60))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.24, y: r.minY + h * 0.22),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.14))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: lipY),
                       control: CGPoint(x: r.maxX - w * 0.16, y: r.minY + h * 0.60))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: lipY),
                       control: CGPoint(x: r.midX, y: r.maxY + h * 0.06))
        p.closeSubpath()
        return p
    }
}

/// Højre vinge af en butterfly (venstre fås med scaleEffect(x: -1)).
struct AccFNBowWingShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.midY - h * 0.18))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.08),
                       control: CGPoint(x: r.minX + w * 0.5, y: r.minY - h * 0.08))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY - h * 0.08),
                       control: CGPoint(x: r.maxX + w * 0.14, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY + h * 0.18),
                       control: CGPoint(x: r.minX + w * 0.5, y: r.maxY + h * 0.08))
        p.closeSubpath()
        return p
    }
}

struct AccFNBandanaShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 0.25))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.05, y: r.maxY - h * 0.05),
                       control: CGPoint(x: r.maxX - w * 0.18, y: r.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.05, y: r.maxY - h * 0.05),
                       control: CGPoint(x: r.midX, y: r.maxY + h * 0.04))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY),
                       control: CGPoint(x: r.minX + w * 0.18, y: r.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

/// Hængende kæde: fra øverste venstre hjørne til nederste højre, med et lille hæng.
struct AccFNChainShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.minX + r.width * 0.15, y: r.maxY + r.height * 0.15))
        return p
    }
}

/// Lille hvid glans, samme stil som solbrillerne.
struct FNShine: View {
    let w: CGFloat
    let h: CGFloat
    var body: some View {
        Capsule().fill(Color.white.opacity(0.65))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(-25))
    }
}

/// Bånd langs hals-buen.
struct FNArcBand: View {
    let w: CGFloat
    let h: CGFloat
    let lineWidth: CGFloat
    let color: Color
    var body: some View {
        AccFNArcShape()
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: w, height: h)
    }
}

// MARK: - Briller

struct FNNerdGlassesView: View {
    let s: CGFloat
    private var frameColor: Color { Color(hex: 0x9A7B6C) }

    private var lens: some View {
        ZStack {
            Circle().fill(Color(hex: 0xDCEEF8).opacity(0.28))
            Circle().stroke(frameColor, lineWidth: s * 0.012)
            FNShine(w: s * 0.045, h: s * 0.011).offset(x: -s * 0.035, y: -s * 0.04)
        }
        .frame(width: s * 0.16, height: s * 0.16)
    }

    var body: some View {
        ZStack {
            Capsule().fill(frameColor).frame(width: s * 0.045, height: s * 0.012).offset(x: -s * 0.215, y: -s * 0.025)
            Capsule().fill(frameColor).frame(width: s * 0.045, height: s * 0.012).offset(x: s * 0.215, y: -s * 0.025)
            lens.offset(x: -s * 0.115)
            lens.offset(x: s * 0.115)
            HumpShape()
                .stroke(frameColor, style: StrokeStyle(lineWidth: s * 0.012, lineCap: .round))
                .frame(width: s * 0.07, height: s * 0.016)
                .offset(y: -s * 0.012)
        }
        .frame(width: s * 0.48, height: s * 0.2)
    }
}

struct FNGogglesView: View {
    let s: CGFloat
    private var rim: Color { Color(hex: 0x8CC6E6) }
    private var strap: Color { Color(hex: 0x76AFD6) }

    private var lens: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xCDEBF8).opacity(0.55))
            Ellipse().stroke(rim, lineWidth: s * 0.024)
            FNShine(w: s * 0.05, h: s * 0.013).offset(x: -s * 0.035, y: -s * 0.03)
        }
        .frame(width: s * 0.165, height: s * 0.135)
    }

    var body: some View {
        ZStack {
            Capsule().fill(strap).frame(width: s * 0.72, height: s * 0.036)
            Capsule().fill(Color.white.opacity(0.25)).frame(width: s * 0.70, height: s * 0.008).offset(y: -s * 0.008)
            lens.offset(x: -s * 0.115)
            lens.offset(x: s * 0.115)
            Capsule().fill(rim).frame(width: s * 0.075, height: s * 0.022)
        }
        .frame(width: s * 0.72, height: s * 0.18)
    }
}

struct FNHeartGlassesView: View {
    let s: CGFloat
    private var rim: Color { Color(hex: 0xE386A2) }

    private var lens: some View {
        ZStack {
            AccFNHeartShape().fill(Color(hex: 0xF7AFC4).opacity(0.78))
            AccFNHeartShape().stroke(rim, style: StrokeStyle(lineWidth: s * 0.012, lineJoin: .round))
            FNShine(w: s * 0.04, h: s * 0.011).offset(x: -s * 0.035, y: -s * 0.025)
        }
        .frame(width: s * 0.165, height: s * 0.145)
    }

    var body: some View {
        ZStack {
            Capsule().fill(rim).frame(width: s * 0.04, height: s * 0.012).offset(x: -s * 0.215, y: -s * 0.03)
            Capsule().fill(rim).frame(width: s * 0.04, height: s * 0.012).offset(x: s * 0.215, y: -s * 0.03)
            lens.offset(x: -s * 0.115)
            lens.offset(x: s * 0.115)
            HumpShape()
                .stroke(rim, style: StrokeStyle(lineWidth: s * 0.012, lineCap: .round))
                .frame(width: s * 0.06, height: s * 0.014)
                .offset(y: -s * 0.025)
        }
        .frame(width: s * 0.48, height: s * 0.2)
    }
}

struct FNStarGlassesView: View {
    let s: CGFloat
    private var rim: Color { Color(hex: 0xE9BC58) }

    private var lens: some View {
        ZStack {
            AccFNStarShape().fill(Color(hex: 0xF8DF8E).opacity(0.75))
            AccFNStarShape().stroke(rim, style: StrokeStyle(lineWidth: s * 0.012, lineJoin: .round))
            FNShine(w: s * 0.035, h: s * 0.01).offset(x: -s * 0.025, y: -s * 0.012)
        }
        .frame(width: s * 0.18, height: s * 0.18)
    }

    var body: some View {
        ZStack {
            lens.offset(x: -s * 0.115)
            lens.offset(x: s * 0.115)
            Capsule().fill(rim).frame(width: s * 0.05, height: s * 0.013).offset(y: -s * 0.005)
            Circle().fill(Color(hex: 0xF4A9BE)).frame(width: s * 0.022, height: s * 0.022).offset(x: -s * 0.2, y: -s * 0.07)
            Circle().fill(Color(hex: 0xA9D6EE)).frame(width: s * 0.018, height: s * 0.018).offset(x: s * 0.2, y: -s * 0.075)
        }
        .frame(width: s * 0.46, height: s * 0.2)
    }
}

struct FNMonocleView: View {
    let s: CGFloat
    private var gold: Color { Color(hex: 0xD9B062) }

    var body: some View {
        ZStack {
            AccFNChainShape()
                .stroke(gold, style: StrokeStyle(lineWidth: s * 0.008, lineCap: .round, dash: [s * 0.012, s * 0.009]))
                .frame(width: s * 0.12, height: s * 0.13)
                .offset(x: s * 0.2, y: s * 0.135)
            Circle().fill(gold).frame(width: s * 0.02, height: s * 0.02).offset(x: s * 0.26, y: s * 0.2)
            Circle().fill(Color(hex: 0xE4F1F8).opacity(0.3))
                .frame(width: s * 0.15, height: s * 0.15)
                .offset(x: s * 0.115)
            Circle().stroke(gold, lineWidth: s * 0.013)
                .frame(width: s * 0.15, height: s * 0.15)
                .offset(x: s * 0.115)
            Circle().fill(gold).frame(width: s * 0.018, height: s * 0.018).offset(x: s * 0.165, y: s * 0.055)
            FNShine(w: s * 0.045, h: s * 0.011).offset(x: s * 0.08, y: -s * 0.04)
        }
        .frame(width: s * 0.46, height: s * 0.2)
    }
}

// MARK: - Hals

struct FNBellView: View {
    let s: CGFloat
    private var ribbon: Color { Color(hex: 0xE58080) }

    private var bell: some View {
        ZStack {
            AccFNBellShape()
                .fill(LinearGradient(colors: [Color(hex: 0xF9DE90), Color(hex: 0xE2AD52)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: s * 0.11, height: s * 0.11)
            Capsule().fill(Color(hex: 0xD39A40).opacity(0.8))
                .frame(width: s * 0.08, height: s * 0.009)
                .offset(y: s * 0.025)
            Circle().fill(Color(hex: 0xC48C38))
                .frame(width: s * 0.028, height: s * 0.028)
                .offset(y: s * 0.05)
            FNShine(w: s * 0.03, h: s * 0.01).offset(x: -s * 0.022, y: -s * 0.015)
        }
    }

    var body: some View {
        ZStack {
            FNArcBand(w: s * 0.60, h: s * 0.06, lineWidth: s * 0.05, color: ribbon)
            FNArcBand(w: s * 0.58, h: s * 0.06, lineWidth: s * 0.01, color: Color(hex: 0xF4B3B3))
                .offset(y: -s * 0.013)
            Circle().stroke(Color(hex: 0xE2AD52), lineWidth: s * 0.008)
                .frame(width: s * 0.03, height: s * 0.03)
                .offset(y: s * 0.05)
            bell.offset(y: s * 0.105)
            Ellipse().fill(Color(hex: 0x8CC7A1))
                .frame(width: s * 0.05, height: s * 0.024)
                .rotationEffect(.degrees(-25))
                .offset(x: -s * 0.035, y: s * 0.045)
            Ellipse().fill(Color(hex: 0x8CC7A1))
                .frame(width: s * 0.05, height: s * 0.024)
                .rotationEffect(.degrees(25))
                .offset(x: s * 0.035, y: s * 0.045)
            Circle().fill(Color(hex: 0xE46A6A)).frame(width: s * 0.02, height: s * 0.02).offset(y: s * 0.04)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNFlowerView: View {
    let d: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(color)
                    .frame(width: d * 0.5, height: d * 0.5)
                    .offset(x: AccFNMath.polar(i, of: 5, r: d * 0.26).x,
                            y: AccFNMath.polar(i, of: 5, r: d * 0.26).y)
            }
            Circle().fill(Color(hex: 0xFBE6A0)).frame(width: d * 0.3, height: d * 0.3)
            Circle().fill(Color.white.opacity(0.55)).frame(width: d * 0.1, height: d * 0.1).offset(x: -d * 0.04, y: -d * 0.04)
        }
        .frame(width: d, height: d)
    }
}

struct FNLeiView: View {
    let s: CGFloat
    private static let palette: [Color] = [
        Color(hex: 0xF6B3C8), Color(hex: 0xF8CBA2), Color(hex: 0xCDB9EC), Color(hex: 0xF7E09C),
    ]
    private var w: CGFloat { s * 0.58 }
    private var h: CGFloat { s * 0.07 }

    private func point(_ i: Int, of n: Int) -> CGPoint {
        AccFNMath.arcPoint(CGFloat(i) / CGFloat(n), w: w, h: h)
    }

    var body: some View {
        ZStack {
            FNArcBand(w: w, h: h, lineWidth: s * 0.01, color: Color(hex: 0x9CCB9A))
            ForEach(0..<8, id: \.self) { i in
                Ellipse().fill(Color(hex: 0xA6D4A4))
                    .frame(width: s * 0.05, height: s * 0.022)
                    .rotationEffect(.degrees(Double(i % 2 == 0 ? 35 : -35)))
                    .offset(x: point(2 * i + 1, of: 16).x, y: point(2 * i + 1, of: 16).y + s * 0.018)
            }
            ForEach(0..<9, id: \.self) { i in
                FNFlowerView(d: s * 0.085, color: Self.palette[i % 4])
                    .rotationEffect(.degrees(Double(i) * 17))
                    .offset(x: point(i, of: 8).x, y: point(i, of: 8).y)
            }
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNMedalView: View {
    let s: CGFloat
    private var blue: Color { Color(hex: 0x86A9DE) }

    private func ribbonPiece(_ angle: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.008).fill(blue)
            Capsule().fill(Color.white.opacity(0.7)).frame(width: s * 0.012)
        }
        .frame(width: s * 0.045, height: s * 0.1)
        .rotationEffect(.degrees(angle))
    }

    private var medal: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xF9DE90), Color(hex: 0xE2AD52)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Color(hex: 0xD49E45), lineWidth: s * 0.008)
                .frame(width: s * 0.09, height: s * 0.09)
            AccFNStarShape().fill(Color(hex: 0xFCEBB4))
                .frame(width: s * 0.055, height: s * 0.055)
            FNShine(w: s * 0.03, h: s * 0.009).offset(x: -s * 0.03, y: -s * 0.03)
        }
        .frame(width: s * 0.12, height: s * 0.12)
    }

    var body: some View {
        ZStack {
            FNArcBand(w: s * 0.58, h: s * 0.06, lineWidth: s * 0.035, color: blue)
            ribbonPiece(-22).offset(x: -s * 0.025, y: s * 0.05)
            ribbonPiece(22).offset(x: s * 0.025, y: s * 0.05)
            medal.offset(y: s * 0.13)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNScarfView: View {
    let s: CGFloat
    let main: Color
    let dark: Color
    let light: Color

    private var w: CGFloat { s * 0.62 }
    private var h: CGFloat { s * 0.07 }
    private var ribs: Int { 15 }

    private func ribT(_ i: Int) -> CGFloat {
        (CGFloat(i) + 0.5) / CGFloat(ribs)
    }

    /// Hængende ende med striber og frynser.
    private func tail(length: CGFloat, color: Color) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: s * 0.03).fill(color)
                .frame(width: s * 0.1, height: length)
            VStack(spacing: s * 0.025) {
                Capsule().fill(light).frame(width: s * 0.1, height: s * 0.016)
                Capsule().fill(light).frame(width: s * 0.1, height: s * 0.016)
            }
            .padding(.bottom, s * 0.035)
            HStack(spacing: s * 0.012) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule().fill(dark).frame(width: s * 0.013, height: s * 0.035)
                }
            }
            .offset(y: s * 0.025)
        }
        .frame(width: s * 0.1, height: length)
    }

    var body: some View {
        ZStack {
            tail(length: s * 0.17, color: dark)
                .rotationEffect(.degrees(-8))
                .offset(x: s * 0.055, y: s * 0.11)
            tail(length: s * 0.22, color: main)
                .rotationEffect(.degrees(6))
                .offset(x: s * 0.14, y: s * 0.13)
            FNArcBand(w: w, h: h, lineWidth: s * 0.095, color: main)
            FNArcBand(w: w * 0.96, h: h, lineWidth: s * 0.012, color: light.opacity(0.6))
                .offset(y: -s * 0.03)
            ForEach(0..<15, id: \.self) { i in
                Capsule().fill(dark.opacity(0.4))
                    .frame(width: s * 0.013, height: s * 0.07)
                    .rotationEffect(AccFNMath.arcAngle(ribT(i), w: w, h: h))
                    .offset(x: AccFNMath.arcPoint(ribT(i), w: w, h: h).x,
                            y: AccFNMath.arcPoint(ribT(i), w: w, h: h).y)
            }
            Ellipse().fill(main)
                .frame(width: s * 0.11, height: s * 0.085)
                .offset(x: s * 0.1, y: s * 0.035)
            Ellipse().stroke(dark.opacity(0.45), lineWidth: s * 0.008)
                .frame(width: s * 0.07, height: s * 0.05)
                .offset(x: s * 0.1, y: s * 0.035)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNPearlsView: View {
    let s: CGFloat
    private var w: CGFloat { s * 0.58 }
    private var h: CGFloat { s * 0.07 }
    private var count: Int { 15 }

    private func point(_ i: Int) -> CGPoint {
        AccFNMath.arcPoint(CGFloat(i) / CGFloat(count - 1), w: w, h: h)
    }

    private func pearl(_ d: CGFloat, tint: Color) -> some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color.white, tint],
                                         center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: d * 0.75))
            Circle().fill(Color.white.opacity(0.9))
                .frame(width: d * 0.22, height: d * 0.22)
                .offset(x: -d * 0.18, y: -d * 0.18)
        }
        .frame(width: d, height: d)
    }

    var body: some View {
        ZStack {
            FNArcBand(w: w, h: h, lineWidth: s * 0.006, color: Color(hex: 0xDCCFC0))
            ForEach(0..<15, id: \.self) { i in
                pearl(s * 0.042, tint: Color(hex: 0xE9DED0))
                    .offset(x: point(i).x, y: point(i).y)
            }
            Capsule().fill(Color(hex: 0xDCCFC0)).frame(width: s * 0.006, height: s * 0.025).offset(y: s * 0.05)
            pearl(s * 0.06, tint: Color(hex: 0xF2C2CF))
                .scaleEffect(x: 1, y: 1.15)
                .offset(y: s * 0.08)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNBowTieView: View {
    let s: CGFloat
    private var main: Color { Color(hex: 0xB9A7E8) }
    private var dark: Color { Color(hex: 0x9C89D4) }

    private var wing: some View {
        ZStack {
            AccFNBowWingShape().fill(main)
            Circle().fill(Color.white.opacity(0.7)).frame(width: s * 0.016, height: s * 0.016)
                .offset(x: s * 0.02, y: -s * 0.018)
            Circle().fill(Color.white.opacity(0.7)).frame(width: s * 0.016, height: s * 0.016)
                .offset(x: s * 0.035, y: s * 0.02)
            Circle().fill(Color.white.opacity(0.7)).frame(width: s * 0.012, height: s * 0.012)
                .offset(x: -s * 0.015, y: s * 0.005)
        }
        .frame(width: s * 0.12, height: s * 0.11)
    }

    var body: some View {
        ZStack {
            FNArcBand(w: s * 0.58, h: s * 0.06, lineWidth: s * 0.018, color: dark.opacity(0.85))
            wing.offset(x: s * 0.07, y: s * 0.035)
            wing.scaleEffect(x: -1, y: 1).offset(x: -s * 0.07, y: s * 0.035)
            RoundedRectangle(cornerRadius: s * 0.016).fill(dark)
                .frame(width: s * 0.048, height: s * 0.062)
                .offset(y: s * 0.035)
            FNShine(w: s * 0.02, h: s * 0.007).offset(x: -s * 0.008, y: s * 0.02)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNBandanaView: View {
    let s: CGFloat
    private var main: Color { Color(hex: 0x9FD8C3) }
    private var dark: Color { Color(hex: 0x7CC1A8) }
    private static let dots: [(CGFloat, CGFloat, CGFloat)] = [
        (-0.11, 0.035, 0.02), (-0.04, 0.05, 0.016), (0.04, 0.05, 0.02), (0.11, 0.035, 0.016),
        (-0.06, 0.1, 0.018), (0.02, 0.11, 0.02), (0.07, 0.095, 0.014), (-0.015, 0.165, 0.016),
    ]

    var body: some View {
        ZStack {
            AccFNBandanaShape().fill(main)
                .frame(width: s * 0.44, height: s * 0.26)
                .offset(y: s * 0.125)
            ForEach(0..<8, id: \.self) { i in
                Circle().fill(Color.white.opacity(0.8))
                    .frame(width: s * Self.dots[i].2, height: s * Self.dots[i].2)
                    .offset(x: s * Self.dots[i].0, y: s * Self.dots[i].1)
            }
            FNArcBand(w: s * 0.60, h: s * 0.06, lineWidth: s * 0.032, color: dark)
            Ellipse().fill(dark).frame(width: s * 0.04, height: s * 0.03).offset(x: -s * 0.29, y: -s * 0.025)
            Ellipse().fill(dark).frame(width: s * 0.04, height: s * 0.03).offset(x: s * 0.29, y: -s * 0.025)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}

struct FNLifebuoyView: View {
    let s: CGFloat
    private var rope: Color { Color(hex: 0xDDBF92) }
    private var red: Color { Color(hex: 0xEE8C8C) }

    private var buoy: some View {
        ZStack {
            Circle().stroke(Color.white, lineWidth: s * 0.036)
            ForEach(0..<4, id: \.self) { i in
                Circle().trim(from: 0, to: 0.125)
                    .stroke(red, style: StrokeStyle(lineWidth: s * 0.036, lineCap: .butt))
                    .rotationEffect(.degrees(Double(i) * 90 - 22.5))
            }
            Circle().stroke(Color(hex: 0xC6D0D8), lineWidth: s * 0.004)
                .frame(width: s * 0.146, height: s * 0.146)
            Circle().stroke(Color(hex: 0xC6D0D8), lineWidth: s * 0.004)
                .frame(width: s * 0.074, height: s * 0.074)
            FNShine(w: s * 0.03, h: s * 0.009).offset(x: -s * 0.04, y: -s * 0.045)
        }
        .frame(width: s * 0.11, height: s * 0.11)
    }

    var body: some View {
        ZStack {
            FNArcBand(w: s * 0.58, h: s * 0.06, lineWidth: s * 0.02, color: rope)
            AccFNArcShape()
                .stroke(Color(hex: 0xC4A170), style: StrokeStyle(lineWidth: s * 0.006, lineCap: .round,
                                                                   dash: [s * 0.014, s * 0.01]))
                .frame(width: s * 0.58, height: s * 0.06)
            Circle().stroke(rope, lineWidth: s * 0.008)
                .frame(width: s * 0.026, height: s * 0.026)
                .offset(y: s * 0.045)
            buoy.offset(y: s * 0.11)
        }
        .frame(width: s * 0.66, height: s * 0.4)
    }
}
