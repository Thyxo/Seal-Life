import Foundation
import SwiftUI
import Observation

/// Brugerens finjustering af et stykke tøj (gemmes pr. ting, gælder for alle sælfarver).
struct ItemFit: Codable, Equatable {
    /// Forskydning som andel af sælens størrelse.
    var dx: Double = 0
    var dy: Double = 0
    var scale: Double = 1
    /// Grader.
    var rotation: Double = 0

    static let identity = ItemFit()
    var isIdentity: Bool { self == ItemFit.identity }
}

/// Gemmer justeringer som JSON i App Group-mappen, så widget og Live Activity viser det samme.
@Observable
final class FitStore {
    static let shared = FitStore()
    static let fileName = "fits.json"

    var fits: [String: ItemFit] = [:]

    private init() {
        reload()
    }

    private static var url: URL { AppGroup.containerURL.appendingPathComponent(fileName) }

    func reload() {
        guard let data = try? Data(contentsOf: Self.url),
              let decoded = try? JSONDecoder().decode([String: ItemFit].self, from: data) else { return }
        fits = decoded
    }

    func fit(_ id: String) -> ItemFit { fits[id] ?? .identity }

    func set(_ fit: ItemFit, for id: String) {
        if fit.isIdentity { fits.removeValue(forKey: id) } else { fits[id] = fit }
    }

    func replaceAll(_ new: [String: ItemFit]) {
        fits = new
        save()
    }

    func save() {
        if let data = try? JSONEncoder().encode(fits) {
            try? data.write(to: Self.url, options: .atomic)
        }
    }
}

extension View {
    /// Lægger brugerens justering på et stykke tøj.
    func fitted(_ fit: ItemFit, s: CGFloat) -> some View {
        self
            .scaleEffect(CGFloat(fit.scale))
            .rotationEffect(.degrees(fit.rotation))
            .offset(x: CGFloat(fit.dx) * s, y: CGFloat(fit.dy) * s)
    }
}
