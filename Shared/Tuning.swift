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
    }
}
