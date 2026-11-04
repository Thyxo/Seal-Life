import SwiftUI
import UIKit

/// Sælen. Bruger billeder fra Assets/Incoming hvis de findes (seal_<farve>_<tilstand>.png),
/// ellers tegnes den med SwiftUI-former. Alle bevægelser er kodet.
struct SealFigure: View {
    var color: SealColor
    var state: MoodState
    var hat: String? = nil
    var glasses: String? = nil
    var neck: String? = nil
    var animated: Bool = true

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Group {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                        SealCanvas(color: color, state: state, hat: hat, glasses: glasses, neck: neck,
                                   s: s, t: ctx.date.timeIntervalSinceReferenceDate, animated: true)
                    }
                } else {
                    SealCanvas(color: color, state: state, hat: hat, glasses: glasses, neck: neck,
                               s: s, t: 0, animated: false)
                }
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Små former

struct HumpShape: Shape { // ∩
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height))
        return p
    }
}

struct CupShape: Shape { // ∪
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY + r.height))
        return p
    }
}

struct MouthWShape: Shape { // ω
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.25, y: r.maxY * 1.0 + r.height))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.75, y: r.maxY * 1.0 + r.height))
        return p
    }
}

struct SantaHatShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX * 0.92, y: r.minY + r.height * 0.12),
                       control: CGPoint(x: r.minX + r.width * 0.25, y: r.minY - r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX * 0.9, y: r.maxY),
                       control: CGPoint(x: r.maxX * 0.8, y: r.midY))
        p.closeSubpath()
        return p
    }
}

struct TriangleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Selve tegningen

struct SealCanvas: View {
    let color: SealColor
    let state: MoodState
    let hat: String?
    let glasses: String?
    let neck: String?
    let s: CGFloat
    let t: Double
    let animated: Bool

    private static let spots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (0.33, 0.20, 0.075, 0.045), (0.46, 0.15, 0.06, 0.04), (0.61, 0.19, 0.08, 0.05),
        (0.72, 0.29, 0.05, 0.075), (0.25, 0.33, 0.05, 0.075), (0.53, 0.26, 0.05, 0.035),
        (0.39, 0.29, 0.04, 0.03), (0.80, 0.46, 0.04, 0.075), (0.19, 0.50, 0.04, 0.075),
        (0.68, 0.12, 0.045, 0.03), (0.28, 0.62, 0.04, 0.06), (0.75, 0.63, 0.045, 0.06),
    ]

    private var breathe: CGFloat {
        guard animated else { return 0 }
        return CGFloat(sin(t * (state == .sleeping ? 1.1 : 2.0)))
    }

    private var hop: CGFloat {
        guard animated else { return 0 }
        switch state {
        case .happy: return -CGFloat(max(0, sin(t * 3.0))) * s * 0.04
        case .content, .vacation: return CGFloat(sin(t * 1.4)) * s * 0.01
        default: return 0
        }
    }

    private var sway: Double {
        guard animated else { return 0 }
        switch state {
        case .happy: return sin(t * 3.0) * 3
        case .sad, .sick: return sin(t * 0.8) * 1.5
        default: return sin(t * 1.2) * 1.5
        }
    }

    private var blink: CGFloat {
        guard animated else { return 1 }
        let p = t.truncatingRemainder(dividingBy: 4.3)
        return p < 0.13 ? 0.1 : 1
    }

    private var flipperAngle: Double {
        guard animated else { return 0 }
        switch state {
        case .happy: return sin(t * 7) * 16
        case .sick, .sad, .sleeping: return sin(t * 1.0) * 2
        default: return sin(t * 1.8) * 6
        }
    }

    private var bodyImage: UIImage? {
        if let img = incomingImage("seal_\(color.rawValue)_\(state.rawValue)") { return img }
        if color == .gray { return incomingImage("seal_\(state.rawValue)") }
        return nil
    }

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: s * x, y: s * y) }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: s * (0.66 - 0.04 * abs(hop) / max(s * 0.04, 1)), height: s * 0.08)
                .position(pt(0.5, 0.94))

            ZStack {
                if let img = bodyImage {
                    Image(uiImage: img).resizable().scaledToFit().frame(width: s, height: s)
                } else {
                    drawnSeal
                }
                accessoryLayer
            }
            .frame(width: s, height: s)
            .scaleEffect(x: 1 + 0.012 * breathe, y: 1 - 0.02 * breathe, anchor: .bottom)
            .rotationEffect(.degrees(sway), anchor: .bottom)
            .offset(y: hop)

            extras
        }
        .frame(width: s, height: s)
    }

    // MARK: Krop

    private var drawnSeal: some View {
        ZStack {
            Ellipse().fill(color.flipper)
                .frame(width: s * 0.22, height: s * 0.11)
                .rotationEffect(.degrees(-18 + flipperAngle * 0.3))
                .position(pt(0.80, 0.89))

            Ellipse()
                .fill(LinearGradient(colors: [color.bodyLight, color.body], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.76, height: s * 0.80)
                .position(pt(0.5, 0.52))

            ForEach(0..<Self.spots.count, id: \.self) { i in
                let sp = Self.spots[i]
                Ellipse().fill(color.spot.opacity(0.75))
                    .frame(width: s * sp.2, height: s * sp.3)
                    .position(pt(sp.0, sp.1))
            }

            Ellipse().fill(color.belly)
                .frame(width: s * 0.50, height: s * 0.46)
                .position(pt(0.5, 0.66))

            Ellipse().fill(color.belly)
                .frame(width: s * 0.30, height: s * 0.16)
                .position(pt(0.5, 0.535))

            face

            Ellipse().fill(color.flipper)
                .frame(width: s * 0.16, height: s * 0.25)
                .rotationEffect(.degrees(28 + flipperAngle), anchor: .top)
                .position(pt(0.21, 0.76))
            Ellipse().fill(color.flipper)
                .frame(width: s * 0.16, height: s * 0.25)
                .rotationEffect(.degrees(-28 - flipperAngle), anchor: .top)
                .position(pt(0.79, 0.76))
        }
        .frame(width: s, height: s)
    }

    // MARK: Ansigt

    private var face: some View {
        ZStack {
            Ellipse().fill(Theme.blush.opacity(state == .sick ? 0.2 : 0.5))
                .frame(width: s * 0.085, height: s * 0.045).position(pt(0.30, 0.50))
            Ellipse().fill(Theme.blush.opacity(state == .sick ? 0.2 : 0.5))
                .frame(width: s * 0.085, height: s * 0.045).position(pt(0.70, 0.50))

            if state == .sick {
                Ellipse().fill(Color(hex: 0x9CCB8A).opacity(0.25))
                    .frame(width: s * 0.5, height: s * 0.25).position(pt(0.5, 0.45))
            }

            eye(x: 0.385)
            eye(x: 0.615)

            if state == .sad {
                Capsule().fill(Theme.eye.opacity(0.7))
                    .frame(width: s * 0.07, height: s * 0.014)
                    .rotationEffect(.degrees(-18)).position(pt(0.37, 0.36))
                Capsule().fill(Theme.eye.opacity(0.7))
                    .frame(width: s * 0.07, height: s * 0.014)
                    .rotationEffect(.degrees(18)).position(pt(0.63, 0.36))
                let drop = animated ? CGFloat((t * 0.5).truncatingRemainder(dividingBy: 1)) : 0.3
                Ellipse().fill(Theme.ocean)
                    .frame(width: s * 0.03, height: s * 0.045)
                    .position(pt(0.62, 0.47 + 0.08 * drop))
                    .opacity(Double(1 - drop))
            }

            Ellipse().fill(Theme.eye)
                .frame(width: s * 0.06, height: s * 0.038)
                .position(pt(0.5, 0.505))

            mouth
        }
        .frame(width: s, height: s)
    }

    private func eye(x: CGFloat) -> some View {
        Group {
            switch state {
            case .happy, .vacation:
                HumpShape()
                    .stroke(Theme.eye, style: StrokeStyle(lineWidth: s * 0.022, lineCap: .round))
                    .frame(width: s * 0.09, height: s * 0.035)
            case .sleeping:
                CupShape()
                    .stroke(Theme.eye, style: StrokeStyle(lineWidth: s * 0.02, lineCap: .round))
                    .frame(width: s * 0.085, height: s * 0.025)
            case .sick:
                Capsule().fill(Theme.eye)
                    .frame(width: s * 0.08, height: s * 0.018)
            default:
                ZStack {
                    Circle().fill(Theme.eye)
                    Circle().fill(Color.white)
                        .frame(width: s * 0.026, height: s * 0.026)
                        .offset(x: -s * 0.013, y: -s * 0.014)
                }
                .frame(width: s * (state == .sad ? 0.075 : 0.085), height: s * (state == .sad ? 0.075 : 0.085))
                .scaleEffect(x: 1, y: blink)
            }
        }
        .position(pt(x, state == .sad ? 0.43 : 0.42))
    }

    @ViewBuilder private var mouth: some View {
        switch state {
        case .happy:
            Ellipse().fill(Theme.rose)
                .frame(width: s * 0.035, height: s * 0.04)
                .position(pt(0.5, 0.565))
            MouthWShape()
                .stroke(Theme.eye, style: StrokeStyle(lineWidth: s * 0.014, lineCap: .round))
                .frame(width: s * 0.09, height: s * 0.02)
                .position(pt(0.5, 0.535))
        case .hungry:
            let chew = animated ? CGFloat(0.8 + 0.25 * sin(t * 4)) : 1
            Ellipse().fill(Theme.rose.opacity(0.9))
                .frame(width: s * 0.04, height: s * 0.045 * chew)
                .position(pt(0.5, 0.56))
        case .sad, .sick:
            HumpShape()
                .stroke(Theme.eye, style: StrokeStyle(lineWidth: s * 0.013, lineCap: .round))
                .frame(width: s * 0.06, height: s * 0.015)
                .position(pt(0.5, 0.56))
        default:
            MouthWShape()
                .stroke(Theme.eye, style: StrokeStyle(lineWidth: s * 0.014, lineCap: .round))
                .frame(width: s * 0.09, height: s * 0.02)
                .position(pt(0.5, 0.535))
        }
    }

    // MARK: Tilbehør

    @ViewBuilder private var accessoryLayer: some View {
        if let n = ShopCatalog.item(neck) {
            AccessoryView(item: n, s: s).position(pt(0.5, 0.69))
        }
        if let g = ShopCatalog.item(glasses ?? (state == .vacation ? "sunglasses" : nil)) {
            AccessoryView(item: g, s: s).position(pt(0.5, 0.42))
        }
        if let h = ShopCatalog.item(hat) {
            AccessoryView(item: h, s: s).position(pt(0.5, 0.13))
        }
    }

    // MARK: Ekstra (Zzz, termometer, tankeboble)

    @ViewBuilder private var extras: some View {
        switch state {
        case .sleeping:
            ForEach(0..<3, id: \.self) { i in
                let phase = animated ? (t * 0.4 + Double(i) / 3).truncatingRemainder(dividingBy: 1) : Double(i) / 3
                Text("z")
                    .font(.system(size: s * (0.07 + 0.04 * CGFloat(phase)), weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.oceanDeep)
                    .opacity(1 - phase)
                    .position(pt(0.72 + 0.12 * CGFloat(phase), 0.25 - 0.2 * CGFloat(phase)))
            }
        case .sick:
            Text("🌡️")
                .font(.system(size: s * 0.1))
                .rotationEffect(.degrees(-35 + (animated ? sin(t * 2) * 5 : 0)))
                .position(pt(0.6, 0.6))
        case .hungry:
            let bob = animated ? CGFloat(sin(t * 2)) * s * 0.01 : 0
            ZStack {
                Circle().fill(Color.white).frame(width: s * 0.03).position(pt(0.76, 0.24))
                Circle().fill(Color.white).frame(width: s * 0.045).position(pt(0.81, 0.17))
                Circle().fill(Color.white).frame(width: s * 0.16).position(pt(0.88, 0.07))
                Text("🐟").font(.system(size: s * 0.085)).position(pt(0.88, 0.07))
            }
            .offset(y: bob)
        default:
            EmptyView()
        }
    }
}

// MARK: - Tilbehør-visning

struct AccessoryView: View {
    let item: ShopItem
    let s: CGFloat

    var body: some View {
        if let img = incomingImage("acc_\(item.id)") {
            Image(uiImage: img).resizable().scaledToFit().frame(width: width)
        } else {
            drawn
        }
    }

    private var width: CGFloat {
        switch item.slot {
        case .hat: return s * 0.42
        case .glasses: return s * 0.46
        case .neck: return s * 0.6
        case .background: return s * 0.3
        }
    }

    @ViewBuilder private var drawn: some View {
        switch item.id {
        case "nissehue":
            ZStack {
                SantaHatShape().fill(Color(hex: 0xE46A6A))
                    .frame(width: s * 0.4, height: s * 0.26)
                Capsule().fill(Color.white)
                    .frame(width: s * 0.42, height: s * 0.07)
                    .offset(y: s * 0.12)
                Circle().fill(Color.white)
                    .frame(width: s * 0.08)
                    .offset(x: s * 0.17, y: -s * 0.1)
            }
            .offset(y: -s * 0.02)
        case "sunglasses":
            ZStack {
                HStack(spacing: s * 0.05) {
                    RoundedRectangle(cornerRadius: s * 0.035).fill(Color.black.opacity(0.85))
                        .frame(width: s * 0.15, height: s * 0.1)
                    RoundedRectangle(cornerRadius: s * 0.035).fill(Color.black.opacity(0.85))
                        .frame(width: s * 0.15, height: s * 0.1)
                }
                Capsule().fill(Color.black.opacity(0.85)).frame(width: s * 0.08, height: s * 0.015)
                Capsule().fill(Color.white.opacity(0.6))
                    .frame(width: s * 0.05, height: s * 0.012)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -s * 0.12, y: -s * 0.02)
            }
        case "scarf_red", "scarf_blue":
            let c = item.id == "scarf_red" ? Color(hex: 0xE88080) : Color(hex: 0x7FA9E0)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.04).fill(c)
                    .frame(width: s * 0.1, height: s * 0.2)
                    .rotationEffect(.degrees(8))
                    .offset(x: s * 0.13, y: s * 0.09)
                Capsule().fill(c).frame(width: s * 0.56, height: s * 0.09)
                HStack(spacing: s * 0.06) {
                    ForEach(0..<5, id: \.self) { _ in
                        Capsule().fill(Color.white.opacity(0.5)).frame(width: s * 0.02, height: s * 0.07)
                    }
                }
            }
        default:
            Text(item.emoji)
                .font(.system(size: item.slot == .glasses ? s * 0.2 : s * 0.24))
        }
    }
}
