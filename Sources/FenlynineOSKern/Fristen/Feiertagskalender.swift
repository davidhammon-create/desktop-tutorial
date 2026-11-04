import Foundation

/// Gesetzliche Feiertage nach den Feiertagsgesetzen der Länder.
///
/// Wartungshinweis: Die Zuordnung ist einmal jährlich (Dezember) zu prüfen;
/// die Länder ändern ihre Feiertagsgesetze (z. B. Frauentag in BE und MV).
///
/// Bewusst konservativ: Feiertage, die nur auf Gemeindeebene gelten
/// (Fronleichnam in SN/TH, Mariä Himmelfahrt in BY, Augsburger Friedensfest),
/// werden nicht berücksichtigt. Ein zu früh angesetztes Fristende ist
/// unschädlich, ein zu spätes nicht.
public struct Feiertagskalender {

    /// Gregorianischer Kalender in fester Zeitzone (Europa/Berlin), Wochenbeginn Montag.
    /// Verhindert Sommerzeit- und Zeitzonenfehler bei reinen Datumsrechnungen.
    public static let kalender: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        c.firstWeekday = 2          // Montag
        return c
    }()

    /// Erzeugt das Datum (00:00 Uhr Berliner Zeit) für Jahr, Monat, Tag.
    public static func tag(_ jahr: Int, _ monat: Int, _ tag: Int) -> Date {
        kalender.date(from: DateComponents(year: jahr, month: monat, day: tag))!
    }

    /// Ostersonntag nach Meeus/Jones/Butcher (gregorianisch, ohne Tabelle).
    public static func ostersonntag(jahr y: Int) -> Date {
        let a = y % 19
        let b = y / 100
        let c = y % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let monat = (h + l - 7 * m + 114) / 31
        let tagImMonat = ((h + l - 7 * m + 114) % 31) + 1
        return tag(y, monat, tagImMonat)
    }

    /// Verschiebt ein Datum um eine Anzahl Kalendertage.
    private static func plus(_ tage: Int, _ datum: Date) -> Date {
        kalender.date(byAdding: .day, value: tage, to: datum)!
    }

    /// Buß- und Bettag: Mittwoch vor dem 23. November. Gesetzlicher Feiertag nur in Sachsen.
    public static func bussUndBettag(jahr: Int) -> Date {
        var d = tag(jahr, 11, 22)
        while kalender.component(.weekday, from: d) != 4 {   // 4 = Mittwoch
            d = plus(-1, d)
        }
        return d
    }

    /// Alle gesetzlichen Feiertage eines Jahres im angegebenen Land (Datum -> Name).
    public static func feiertage(jahr: Int, land: Bundesland) -> [Date: String] {
        let ostern = ostersonntag(jahr: jahr)
        var f: [Date: String] = [
            tag(jahr, 1, 1):    "Neujahr",
            plus(-2, ostern):   "Karfreitag",
            plus(1, ostern):    "Ostermontag",
            tag(jahr, 5, 1):    "Tag der Arbeit",
            plus(39, ostern):   "Christi Himmelfahrt",
            plus(50, ostern):   "Pfingstmontag",
            tag(jahr, 10, 3):   "Tag der Deutschen Einheit",
            tag(jahr, 12, 25):  "1. Weihnachtstag",
            tag(jahr, 12, 26):  "2. Weihnachtstag"
        ]

        // Heilige Drei Könige
        if [Bundesland.bw, .by, .st].contains(land) {
            f[tag(jahr, 1, 6)] = "Heilige Drei Könige"
        }
        // Internationaler Frauentag
        if [Bundesland.be, .mv].contains(land) {
            f[tag(jahr, 3, 8)] = "Internationaler Frauentag"
        }
        // Fronleichnam (SN/TH nur in einzelnen Gemeinden -> bewusst nicht enthalten)
        if [Bundesland.bw, .by, .he, .nw, .rp, .sl].contains(land) {
            f[plus(60, ostern)] = "Fronleichnam"
        }
        // Mariä Himmelfahrt (BY nur in überwiegend katholischen Gemeinden -> nur SL)
        if land == .sl {
            f[tag(jahr, 8, 15)] = "Mariä Himmelfahrt"
        }
        // Weltkindertag
        if land == .th {
            f[tag(jahr, 9, 20)] = "Weltkindertag"
        }
        // Reformationstag
        if [Bundesland.bb, .mv, .sn, .st, .th, .hb, .hh, .ni, .sh].contains(land) {
            f[tag(jahr, 10, 31)] = "Reformationstag"
        }
        // Allerheiligen
        if [Bundesland.bw, .by, .nw, .rp, .sl].contains(land) {
            f[tag(jahr, 11, 1)] = "Allerheiligen"
        }
        // Buß- und Bettag
        if land == .sn {
            f[bussUndBettag(jahr: jahr)] = "Buß- und Bettag"
        }

        return f
    }

    /// Name des Feiertags, falls das Datum im Land ein gesetzlicher Feiertag ist, sonst nil.
    public static func istFeiertag(_ datum: Date, land: Bundesland) -> String? {
        let jahr = kalender.component(.year, from: datum)
        let tagOhneZeit = kalender.startOfDay(for: datum)
        return feiertage(jahr: jahr, land: land)[tagOhneZeit]
    }

    /// Samstag oder Sonntag.
    public static func istWochenende(_ datum: Date) -> Bool {
        let wt = kalender.component(.weekday, from: datum)
        return wt == 1 || wt == 7            // 1 = Sonntag, 7 = Samstag
    }

    /// § 193 BGB / § 222 Abs. 2 ZPO: Fällt das Datum auf Samstag, Sonntag oder einen
    /// Feiertag am Erklärungsort, tritt der nächste Werktag an seine Stelle.
    /// Rückgabe: (Werktag, Grund der Verschiebung oder nil, wenn keine Verschiebung nötig war).
    public static func naechsterWerktag(_ datum: Date, land: Bundesland) -> (Date, String?) {
        var d = kalender.startOfDay(for: datum)
        var grund: String? = nil
        while true {
            if istWochenende(d) {
                let name = kalender.component(.weekday, from: d) == 7 ? "Samstag" : "Sonntag"
                grund = grund ?? name
            } else if let name = istFeiertag(d, land: land) {
                grund = grund ?? name
            } else {
                return (d, grund)
            }
            d = plus(1, d)
        }
    }
}
