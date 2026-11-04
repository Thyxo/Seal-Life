import Foundation

struct AdventurePlace {
    let name: String
    let emoji: String
    let stories: [String]
}

enum Adventures {
    static let places: [AdventurePlace] = [
        AdventurePlace(name: "Amager Strand", emoji: "🏖️", stories: [
            "Jeg lå på en sten ved Amager Strand og lod, som om jeg var en sten. Et barn sagde \"hej sten\". Dagens største succes.",
            "En vinterbader hilste på mig. Vi var enige om, at vandet var \"friskt\". Han hylede. Det gjorde jeg ikke.",
            "Jeg byggede et sandslot. Det var mest en bunke. Men en meget stolt bunke.",
        ]),
        AdventurePlace(name: "Nyhavn", emoji: "⛵", stories: [
            "I Nyhavn vinkede jeg til en kanalbåd, og fjorten turister tog billeder. Jeg er nok berømt nu.",
            "Jeg fulgte en duft af pølser hele vejen langs kajen. Den endte ved en måge. Vi deler ikke.",
            "Jeg talte de farvede huse. Jeg nåede til gul og glemte så resten. Det var en dejlig dag.",
        ]),
        AdventurePlace(name: "Øresund", emoji: "🌉", stories: [
            "Jeg svømmede halvvejs til Sverige og tænkte: nej, det er langt. Så jeg vendte om og fik en sild.",
            "Under Øresundsbroen lyder bilerne som torden. Jeg lod som om, det var en koncert for mig.",
        ]),
        AdventurePlace(name: "en isflage", emoji: "🧊", stories: [
            "Jeg fandt en isflage, der var præcis sæl-formet. Jeg lå der hele formiddagen. Perfekt pasform.",
            "En isflage og jeg drev stille rundt. Vi sagde ikke så meget. Det var dejligt.",
        ]),
        AdventurePlace(name: "Den Lille Havfrue", emoji: "🧜‍♀️", stories: [
            "Jeg sagde hej til Den Lille Havfrue. Hun svarede ikke, men jeg tror, hun syntes om mig.",
            "Jeg sad ved siden af Den Lille Havfrue og poserede. Nogen tog et billede. Jeg kom med på billedet. Med vilje.",
        ]),
        AdventurePlace(name: "Grenen ved Skagen", emoji: "🌊", stories: [
            "Ved Grenen havde jeg en luffe i hvert hav. Det kildede to gange.",
            "Skagen-lyset er så smukt, at jeg glemte at spise. I næsten fem minutter.",
        ]),
        AdventurePlace(name: "Vadehavet", emoji: "🦭", stories: [
            "I Vadehavet mødte jeg mine kusiner. De snakkede kun om sild. Jeg elskede hvert sekund.",
            "Vi lå i en lang række på en sandbanke og lavede ingenting. Professionelt.",
        ]),
        AdventurePlace(name: "Kronborg", emoji: "🏰", stories: [
            "Ved Kronborg hørte jeg nogen sige \"at være eller ikke være\". Jeg valgte at være. Med en fisk.",
        ]),
        AdventurePlace(name: "Fanø", emoji: "🪁", stories: [
            "På Fanø fløj der drager over stranden. Jeg prøvede at flyve med. Det gik… vådt.",
        ]),
        AdventurePlace(name: "Limfjorden", emoji: "🦪", stories: [
            "I Limfjorden mødte jeg en østers. Den var meget lukket som person.",
            "Jeg fandt en flaskepost! Der stod bare \"hej\". Jeg skrev \"hej\" tilbage i tankerne.",
        ]),
    ]

    static let vacationSpots = ["Bornholm", "Færøerne", "Grønland", "Lofoten", "Svalbard", "Island"]

    static func place(for key: String) -> AdventurePlace {
        places[DayKey.stableHash(key) % places.count]
    }

    static func story(for key: String) -> String {
        let p = place(for: key)
        return p.stories[DayKey.stableHash(key + "-story") % p.stories.count]
    }

    static let tapLines = [
        "Hihi, det kilder!",
        "Blub!",
        "Har du en fisk? Bare spørger.",
        "Du er god til det her, ved du det?",
        "*vipper stolt med luffen*",
        "Jeg er 80% spæk og 20% kærlighed.",
        "Jeg øver mig i at være rund. Det går godt.",
        "Pas på dig selv i dag, okay?",
    ]
}
