import SwiftUI
import UIKit

/// Baggrunde/rum. Bruger bg_<id>.png fra Assets/Incoming hvis den findes – ellers kodet scene.
struct SceneBackground: View {
    let id: String

    var body: some View {
        if let img = incomingImage("bg_\(id)") {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            switch id {
            case "strand": BeachScene()
            case "isflage": IceScene()
            case "nordlys": AuroraScene()
            case "nyhavn": NyhavnScene()
            case "undervand": UnderwaterScene()
            case "ocean": OceanScene()
            default: CaveScene()
            }
        }
    }
}

/// Lille statisk forhåndsvisning til butikken.
struct ScenePreview: View {
    let id: String
    var body: some View {
        SceneBackground(id: id)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Hyggehulen (standard)

struct CaveScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xD9ECF5), Color(hex: 0xC4E1EE)], startPoint: .top, endPoint: .bottom)

                // rundt vindue
                ZStack {
                    Circle().fill(Color.white)
                    Circle().fill(LinearGradient(colors: [Color(hex: 0xBFE3F7), Color(hex: 0xE4F4FB)], startPoint: .top, endPoint: .bottom))
                        .padding(8)
                    AnimatedWaves(colors: [Theme.ocean.opacity(0.7)], amplitude: 3, speed: 0.7)
                        .frame(height: w * 0.1)
                        .offset(y: w * 0.09)
                        .clipShape(Circle().inset(by: 8))
                    Rectangle().fill(Color.white).frame(width: 6)
                    Rectangle().fill(Color.white).frame(height: 6)
                }
                .frame(width: w * 0.34, height: w * 0.34)
                .position(x: w * 0.3, y: h * 0.3)

                // svingende lampe
                SwingingLamp()
                    .frame(width: 60, height: h * 0.3)
                    .position(x: w * 0.72, y: h * 0.15)

                // gulv
                Ellipse()
                    .fill(LinearGradient(colors: [Theme.sand, Color(hex: 0xE3C99F)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 1.6, height: h * 0.55)
                    .position(x: w * 0.5, y: h * 1.0)

                // tæppe
                Ellipse()
                    .fill(Color(hex: 0xF4B9B2).opacity(0.55))
                    .frame(width: w * 0.62, height: h * 0.12)
                    .position(x: w * 0.5, y: h * 0.86)
            }
        }
    }
}

struct SwingingLamp: View {
    @State private var swing = false
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.inkSoft.opacity(0.5)).frame(width: 2)
            ZStack {
                Ellipse().fill(Theme.sun.opacity(0.35)).frame(width: 70, height: 30).blur(radius: 10).offset(y: 14)
                HumpShape().fill(Theme.sun).frame(width: 46, height: 14)
            }
        }
        .rotationEffect(.degrees(swing ? 4 : -4), anchor: .top)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { swing = true }
        }
    }
}

// MARK: - Havet (eventyr)

struct OceanScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xBFE4F6), Color(hex: 0xEAF6FB)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Theme.sun.opacity(0.85)).frame(width: 60).breathing(0.06, duration: 2.5)
                    .position(x: w * 0.8, y: h * 0.18)
                CloudView().frame(width: 90, height: 34).floating(4, duration: 3).position(x: w * 0.25, y: h * 0.16)
                CloudView().frame(width: 60, height: 24).floating(3, duration: 2.6).position(x: w * 0.6, y: h * 0.28)
                AnimatedWaves(colors: [Theme.ocean.opacity(0.6), Theme.ocean, Theme.oceanDeep.opacity(0.85)], amplitude: 9, speed: 1)
                    .frame(height: h * 0.55)
                    .position(x: w * 0.5, y: h * 0.8)
            }
        }
    }
}

struct CloudView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Capsule().fill(.white).frame(width: w, height: h * 0.6).offset(y: h * 0.2)
                Circle().fill(.white).frame(width: h * 0.8).offset(x: -w * 0.15, y: 0)
                Circle().fill(.white).frame(width: h).offset(x: w * 0.12, y: -h * 0.1)
            }
            .frame(width: w, height: h)
        }
        .opacity(0.9)
    }
}

// MARK: - Strand

struct BeachScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xFCE3C4), Color(hex: 0xCFEAF6)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Theme.sun).frame(width: 70).breathing(0.05, duration: 2.2)
                    .position(x: w * 0.78, y: h * 0.2)
                CloudView().frame(width: 80, height: 30).floating(3).position(x: w * 0.25, y: h * 0.18)
                AnimatedWaves(colors: [Theme.ocean.opacity(0.7), Theme.ocean], amplitude: 6, speed: 0.8)
                    .frame(height: h * 0.4)
                    .position(x: w * 0.5, y: h * 0.62)
                Ellipse().fill(Theme.sand).frame(width: w * 1.6, height: h * 0.5).position(x: w * 0.5, y: h * 1.0)
                Text("⛱️").font(.system(size: 44)).position(x: w * 0.15, y: h * 0.72)
                Text("🐚").font(.system(size: 20)).position(x: w * 0.86, y: h * 0.9)
            }
        }
    }
}

// MARK: - Isflage

struct IceScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xE6F1F8), Color(hex: 0xD2E7F2)], startPoint: .top, endPoint: .bottom)
                AnimatedWaves(colors: [Theme.ocean.opacity(0.6), Theme.oceanDeep.opacity(0.7)], amplitude: 7, speed: 0.6)
                    .frame(height: h * 0.45)
                    .position(x: w * 0.5, y: h * 0.8)
                Ellipse()
                    .fill(LinearGradient(colors: [.white, Theme.ice], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.95, height: h * 0.22)
                    .position(x: w * 0.5, y: h * 0.88)
                    .floating(3, duration: 3)
                if Calendar.current.component(.month, from: Date()) == 12 { SnowView(count: 30) }
            }
        }
    }
}

// MARK: - Nordlys

struct AuroraScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x23305A), Color(hex: 0x3E5A86)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<3, id: \.self) { i in
                        WaveShape(phase: t * 0.4 + Double(i) * 2, amplitude: 18, frequency: 1.2)
                            .fill(LinearGradient(colors: [Color(hex: i == 1 ? 0xB59CF0 : 0x8EF0C4).opacity(0.55), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: h * 0.35)
                            .blur(radius: 12)
                            .position(x: w * 0.5, y: h * (0.25 + 0.08 * Double(i)))
                    }
                    ForEach(0..<14, id: \.self) { i in
                        let tw = 0.4 + 0.6 * abs(sin(t * 1.3 + Double(i)))
                        Circle().fill(.white.opacity(tw))
                            .frame(width: 3, height: 3)
                            .position(x: w * CGFloat((sin(Double(i) * 7.7) * 0.5 + 0.5)),
                                      y: h * CGFloat(0.05 + 0.4 * (cos(Double(i) * 3.3) * 0.5 + 0.5)))
                    }
                    Ellipse().fill(Color(hex: 0xEAF2F8)).frame(width: w * 1.6, height: h * 0.45).position(x: w * 0.5, y: h * 1.02)
                }
            }
        }
    }
}

// MARK: - Nyhavn

struct NyhavnScene: View {
    private let houses: [UInt32] = [0xF6C177, 0xEF9A8A, 0x9CC9E3, 0xF3DE8A, 0xA8D5BA, 0xE7A6C6]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let hw = w / CGFloat(houses.count)
            ZStack {
                LinearGradient(colors: [Color(hex: 0xDDEFF8), Color(hex: 0xF5EEDF)], startPoint: .top, endPoint: .bottom)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<houses.count, id: \.self) { i in
                        VStack(spacing: 0) {
                            TriangleShape().fill(Color(hex: 0xB86B5A)).frame(width: hw, height: hw * 0.45)
                            ZStack {
                                Rectangle().fill(Color(hex: houses[i]))
                                VStack(spacing: 8) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        HStack(spacing: 6) {
                                            RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.8)).frame(width: 9, height: 12)
                                            RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.8)).frame(width: 9, height: 12)
                                        }
                                    }
                                }
                            }
                            .frame(width: hw, height: h * (0.32 + 0.05 * CGFloat(i % 3)))
                        }
                    }
                }
                .position(x: w * 0.5, y: h * 0.42)
                AnimatedWaves(colors: [Theme.oceanDeep.opacity(0.7), Theme.ocean], amplitude: 5, speed: 0.7)
                    .frame(height: h * 0.4)
                    .position(x: w * 0.5, y: h * 0.82)
                Text("⛵").font(.system(size: 38)).floating(4, duration: 2).position(x: w * 0.8, y: h * 0.66)
            }
        }
    }
}

// MARK: - Under vandet

struct UnderwaterScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x9FD4EE), Color(hex: 0x4E8DBE)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle()
                            .fill(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 30, height: h)
                            .rotationEffect(.degrees(18 + sin(t * 0.5 + Double(i)) * 4))
                            .position(x: w * (0.15 + 0.25 * CGFloat(i)), y: h * 0.4)
                    }
                    ForEach(0..<5, id: \.self) { i in
                        Capsule().fill(Color(hex: 0x7CC4A0))
                            .frame(width: 10, height: h * 0.28)
                            .rotationEffect(.degrees(sin(t * 1.2 + Double(i)) * 10), anchor: .bottom)
                            .position(x: w * (0.08 + 0.21 * CGFloat(i)), y: h * 0.86)
                    }
                    Ellipse().fill(Theme.sand).frame(width: w * 1.6, height: h * 0.3).position(x: w * 0.5, y: h * 1.04)
                    Text("🐠").font(.system(size: 26))
                        .position(x: w * CGFloat(0.5 + 0.4 * sin(t * 0.3)), y: h * 0.3)
                    BubblesView(count: 10)
                }
            }
        }
    }
}
