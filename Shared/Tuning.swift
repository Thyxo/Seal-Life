import Foundation

/// Alle justerbare tal i appen samlet ét sted.
/// Ret frit – appen bruger kun disse værdier.
enum Tuning {

    // MARK: - Humør (0–100)

    static let moodMax: Double = 100
    /// Humør ved start (ny sæl).
    static let startMood: Double = 70
    /// Stigning pr. udført afkrydsning.
    static let moodPerCompletion: Double = 5
    /// Ekstra stigning når alle dagens vaner er klaret.
    static let moodAllDoneBonus: Double = 6
    /// Fald for en dag med planlagte vaner, hvor intet blev afkrydset.
    static let moodMissedDayDrop: Double = 9
    /// Maks. fald for en delvist klaret dag (skaleres efter hvor meget der manglede).
    static let moodPartialDayDropMax: Double = 4
    /// Humøret falder aldrig mere end dette på én dag (ingen bratte fald).
    static let moodMaxDailyDrop: Double = 12

    // MARK: - Tilstande

    static let happyThreshold: Double = 80     // glad: 80+
    static let contentThreshold: Double = 50   // tilfreds: 50–79
    static let hungryThreshold: Double = 25    // sulten: 25–49
    // trist: 1–24 (alt over 0)
    /// Antal dage på 0, før sælen bliver "syg".
    static let sickAfterDaysAtZero = 2

    // MARK: - Ferie

    /// Antal planlagte dage i træk helt uden afkrydsning, før sælen tager på ferie.
    static let vacationAfterMissedDays = 7
    /// Antal dage i træk med mindst én afkrydsning, før sælen kommer hjem.
    static let vacationReturnStreak = 3
    /// Humør sælen har, når den kommer hjem fra ferie (mindst).
    static let moodAfterVacation: Double = 55

    // MARK: - Fisk (valuta)

    static let startFish = 20
    static let fishPerCompletion = 3
    static let fishAllDoneBonus = 5
    static let fishMoodCheckIn = 1
    static let fishBackup = 2

    // MARK: - Notifikationer

    /// Standard: maks. samlede påmindelser pr. dag (kan ændres til 1 i appen).
    static let maxRemindersPerDay = 2
    /// Hvor mange dage frem påmindelser planlægges.
    static let reminderDaysAhead = 7
    /// Ugentlig backup-påmindelse (1 = søndag … 7 = lørdag).
    static let backupReminderWeekday = 1
    static let backupReminderHour = 11
    /// Vis backup-kort på hjemmeskærmen, når sidste backup er ældre end dette (dage).
    static let backupNudgeAfterDays = 6

    // MARK: - Dagsrytme

    /// Fra dette klokkeslæt sover sælen (visning).
    static let sleepHour = 22
    /// Til dette klokkeslæt sover sælen (visning).
    static let wakeHour = 6

    // MARK: - Bevægelse (sælens idle – lavere = roligere)

    enum Motion {
        /// Vejrtrækning: svingninger pr. sekund (radianer/sek) og styrke.
        static let breatheSpeed: Double = 1.1
        static let breatheSpeedSleeping: Double = 0.7
        static let breatheAmount: Double = 0.012
        /// Hop når sælen er glad (andel af størrelsen) og tempo.
        static let happyHopHeight: Double = 0.018
        static let happyHopSpeed: Double = 1.5
        /// Lille op/ned-vuggen i andre tilstande.
        static let bobHeight: Double = 0.006
        static let bobSpeed: Double = 0.9
        /// Vuggen fra side til side (grader) og tempo.
        static let swayDegrees: Double = 1.2
        static let swaySpeed: Double = 0.7
        /// Luffe-vinken (grader) og tempo.
        static let flipperDegrees: Double = 5
        static let flipperDegreesHappy: Double = 9
        static let flipperSpeed: Double = 1.1
        static let flipperSpeedHappy: Double = 1.8
        /// Blink hvert N. sekund.
        static let blinkEvery: Double = 5.5
        /// Svømning på eventyr: vandret afstand (pt) og tempo.
        static let swimDistance: Double = 22
        static let swimSpeed: Double = 0.35
        static let swimRockDegrees: Double = 4
        /// Hjerter ved tryk: antal og hvor længe de svæver (sek).
        static let tapHearts = 3
        static let heartLifetime: Double = 2.6
        /// Fælles dæmper for baggrundsbevægelser (bølger, skyer, bobler). 1 = som før, lavere = roligere.
        static let ambientSpeed: Double = 0.55
        /// Fælles dæmper for hvor meget ting svæver/ånder.
        static let ambientAmount: Double = 0.65
    }

    // MARK: - Tilbehør (placering på sælen, andel af sælens størrelse)

    enum Accessory {
        static let hatY: Double = 0.13
        static let glassesY: Double = 0.42
        static let neckY: Double = 0.69
        /// Grænser i tøj-editoren.
        static let maxOffset: Double = 0.3
        static let minScale: Double = 0.4
        static let maxScale: Double = 2.0
    }

    // MARK: - Priser i butikken (fisk)

    enum Price {
        static let nissehue = 40
        static let pumpkin = 35
        static let tophat = 60
        static let cap = 30
        static let strawhat = 45
        static let crown = 120
        static let flower = 25
        static let bow = 25

        static let sunglasses = 50
        static let nerdglasses = 35
        static let goggles = 40

        static let scarfRed = 45
        static let scarfBlue = 45
        static let medal = 80
        static let lei = 40
        static let bell = 30

        static let bgBeach = 90
        static let bgIce = 70
        static let bgNyhavn = 140
        static let bgAurora = 160
        static let bgUnderwater = 120

        // Nyt tøj
        static let beanie = 40
        static let sailorHat = 45
        static let viking = 90
        static let frogHat = 55
        static let chefHat = 35
        static let bunnyEars = 50
        static let heartglasses = 45
        static let starglasses = 60
        static let monocle = 75

        static let pearls = 90
        static let bowtie = 45
        static let bandana = 35
        static let lifebuoy = 55
    }
}
