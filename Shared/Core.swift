import Foundation
import SwiftUI
import UIKit

// MARK: - Dag-nøgler

enum DayKey {
    static func key(for date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(from key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func weekday(_ date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    /// Stabil hash (Swifts hashValue ændrer sig mellem kørsler).
    static func stableHash(_ s: String) -> Int {
        var h = 5381
        for u in s.unicodeScalars {
            h = (h &* 33 &+ Int(u.value)) & 0x7fffffff
        }
        return h
    }
}

// MARK: - App Group (læses ved runtime – AltStore/SideStore kan omskrive ID'et)

enum AppGroup {
    static let identifier: String? = resolve()

    static var containerURL: URL {
        if let id = identifier,
           let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
            return url
        }
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    static var isShared: Bool {
        guard let id = identifier else { return false }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil
    }

    private static func candidates() -> [String] {
        var list: [String] = []
        let info = Bundle.main.infoDictionary ?? [:]
        if let alt = info["ALTAppGroups"] as? [String] { list.append(contentsOf: alt) }
        if let own = info["SealAppGroup"] as? String { list.append(own) }
        if var bid = Bundle.main.bundleIdentifier {
            if Bundle.main.bundleURL.pathExtension == "appex" {
                var parts = bid.split(separator: ".").map(String.init)
                if parts.count > 1 { parts.removeLast() }
                bid = parts.joined(separator: ".")
            }
            list.append("group." + bid)
        }
        return list
    }

    private static func resolve() -> String? {
        let list = candidates()
        for id in list where FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil {
            return id
        }
        return list.first
    }
}

// MARK: - Farver

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {
    static let ocean = Color(hex: 0x8FC6E6)
    static let oceanDeep = Color(hex: 0x5E9CC7)
    static let oceanDark = Color(hex: 0x3F7AA6)
    static let oceanLight = Color(hex: 0xD3EBF7)
    static let ice = Color(hex: 0xEAF0F4)
    static let iceDark = Color(hex: 0xC8D4DD)
    static let sand = Color(hex: 0xEED9B6)
    static let sandLight = Color(hex: 0xF8EDD9)
    static let cream = Color(hex: 0xFFF8EC)
    static let ink = Color(hex: 0x3E4C59)
    static let inkSoft = Color(hex: 0x7F8C97)
    static let eye = Color(hex: 0x2A2F38)
    static let blush = Color(hex: 0xF6A9A3)
    static let mint = Color(hex: 0x8FD3B6)
    static let mintDark = Color(hex: 0x5FB896)
    static let sun = Color(hex: 0xF7C873)
    static let lavender = Color(hex: 0xC8C3EC)
    static let rose = Color(hex: 0xF08C8C)
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Sælens farve og humør

enum SealColor: String, Codable, CaseIterable, Identifiable {
    case gray, brown, white

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gray: return "Grå"
        case .brown: return "Brun"
        case .white: return "Hvid pup"
        }
    }

    var body: Color {
        switch self {
        case .gray: return Color(hex: 0xC6C8D4)
        case .brown: return Color(hex: 0xC9A98C)
        case .white: return Color(hex: 0xF4F2EC)
        }
    }

    var bodyLight: Color {
        switch self {
        case .gray: return Color(hex: 0xDCDDE6)
        case .brown: return Color(hex: 0xDDC2A8)
        case .white: return Color(hex: 0xFFFFFF)
        }
    }

    var spot: Color {
        switch self {
        case .gray: return Color(hex: 0xA3A5B5)
        case .brown: return Color(hex: 0xA5835F)
        case .white: return Color(hex: 0xE3DFD5)
        }
    }

    var belly: Color {
        switch self {
        case .gray: return Color(hex: 0xEDEDF3)
        case .brown: return Color(hex: 0xF2E5D6)
        case .white: return Color(hex: 0xFFFFFF)
        }
    }

    var flipper: Color {
        switch self {
        case .gray: return Color(hex: 0xA2A4B4)
        case .brown: return Color(hex: 0x9F7E62)
        case .white: return Color(hex: 0xDAD5CA)
        }
    }
}

enum MoodState: String, Codable, CaseIterable {
    case happy, content, hungry, sad, sick, vacation, sleeping

    var displayName: String {
        switch self {
        case .happy: return "Glad"
        case .content: return "Tilfreds"
        case .hungry: return "Sulten"
        case .sad: return "Trist"
        case .sick: return "Syg"
        case .vacation: return "På ferie"
        case .sleeping: return "Sover"
        }
    }

    var emoji: String {
        switch self {
        case .happy: return "😄"
        case .content: return "🙂"
        case .hungry: return "🐟"
        case .sad: return "🥺"
        case .sick: return "🤒"
        case .vacation: return "🏝️"
        case .sleeping: return "😴"
        }
    }

    var tint: Color {
        switch self {
        case .happy: return Theme.mint
        case .content: return Theme.ocean
        case .hungry: return Theme.sun
        case .sad: return Theme.lavender
        case .sick: return Color(hex: 0xB9D8A8)
        case .vacation: return Theme.sand
        case .sleeping: return Theme.lavender
        }
    }

    static func from(mood: Double, daysAtZero: Int, onVacation: Bool) -> MoodState {
        if onVacation { return .vacation }
        if mood >= Tuning.happyThreshold { return .happy }
        if mood >= Tuning.contentThreshold { return .content }
        if mood >= Tuning.hungryThreshold { return .hungry }
        if mood >= 1 { return .sad }
        return daysAtZero >= Tuning.sickAfterDaysAtZero ? .sick : .sad
    }
}

/// Valgfrit billede fra Assets/Incoming (ellers nil → kodet placeholder).
func incomingImage(_ name: String) -> UIImage? {
    UIImage(named: name)
}
