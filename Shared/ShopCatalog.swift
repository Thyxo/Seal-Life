import Foundation

enum ItemSlot: String, Codable, CaseIterable, Identifiable {
    case hat, glasses, neck, background

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hat: return "Hatte"
        case .glasses: return "Briller"
        case .neck: return "Halsen"
        case .background: return "Steder"
        }
    }

    var icon: String {
        switch self {
        case .hat: return "🎩"
        case .glasses: return "🕶️"
        case .neck: return "🧣"
        case .background: return "🏝️"
        }
    }
}

struct ShopItem: Identifiable, Hashable {
    let id: String
    let name: String
    let slot: ItemSlot
    let emoji: String
    let price: Int
    /// Hvis sat: kan kun købes i denne måned (1–12).
    let seasonMonth: Int?

    init(_ id: String, _ name: String, _ slot: ItemSlot, _ emoji: String, _ price: Int, season: Int? = nil) {
        self.id = id
        self.name = name
        self.slot = slot
        self.emoji = emoji
        self.price = price
        self.seasonMonth = season
    }

    var isSeasonal: Bool { seasonMonth != nil }

    var isInSeason: Bool {
        guard let m = seasonMonth else { return true }
        return Calendar.current.component(.month, from: Date()) == m
    }

    var seasonName: String {
        switch seasonMonth {
        case 12: return "December"
        case 10: return "Oktober"
        case 4: return "April"
        default: return "Sæson"
        }
    }
}

enum ShopCatalog {
    static let defaultBackground = "hule"

    static let items: [ShopItem] = [
        // Hatte
        ShopItem("nissehue", "Nissehue", .hat, "🎅", Tuning.Price.nissehue, season: 12),
        ShopItem("pumpkin", "Græskarhat", .hat, "🎃", Tuning.Price.pumpkin, season: 10),
        ShopItem("cap", "Kasket", .hat, "🧢", Tuning.Price.cap),
        ShopItem("flower", "Blomst", .hat, "🌸", Tuning.Price.flower),
        ShopItem("bow", "Sløjfe", .hat, "🎀", Tuning.Price.bow),
        ShopItem("strawhat", "Stråhat", .hat, "👒", Tuning.Price.strawhat),
        ShopItem("tophat", "Høj hat", .hat, "🎩", Tuning.Price.tophat),
        ShopItem("crown", "Krone", .hat, "👑", Tuning.Price.crown),
        // Briller
        ShopItem("sunglasses", "Solbriller", .glasses, "🕶️", Tuning.Price.sunglasses),
        ShopItem("nerdglasses", "Læsebriller", .glasses, "👓", Tuning.Price.nerdglasses),
        ShopItem("goggles", "Svømmebriller", .glasses, "🥽", Tuning.Price.goggles),
        // Hals
        ShopItem("scarf_red", "Rødt halstørklæde", .neck, "🧣", Tuning.Price.scarfRed),
        ShopItem("scarf_blue", "Blåt halstørklæde", .neck, "🧣", Tuning.Price.scarfBlue),
        ShopItem("bell", "Juleklokke", .neck, "🔔", Tuning.Price.bell, season: 12),
        ShopItem("lei", "Blomsterkrans", .neck, "🌺", Tuning.Price.lei),
        ShopItem("medal", "Medalje", .neck, "🏅", Tuning.Price.medal),
        // Baggrunde / rum
        ShopItem("hule", "Hyggehulen", .background, "🏠", 0),
        ShopItem("isflage", "Isflagen", .background, "🧊", Tuning.Price.bgIce),
        ShopItem("strand", "Amager Strand", .background, "🏖️", Tuning.Price.bgBeach),
        ShopItem("undervand", "Under vandet", .background, "🐠", Tuning.Price.bgUnderwater),
        ShopItem("nyhavn", "Nyhavn", .background, "⛵", Tuning.Price.bgNyhavn),
        ShopItem("nordlys", "Nordlys", .background, "🌌", Tuning.Price.bgAurora),
    ] + HatDesigns.newItems + FaceNeckDesigns.newItems

    static func item(_ id: String?) -> ShopItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    static func items(in slot: ItemSlot) -> [ShopItem] {
        items.filter { $0.slot == slot }
    }
}
