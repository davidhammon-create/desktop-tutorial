import Foundation

/// Ein einzelner Prüflauf, gesiegelt mit einem Hash und verkettet mit dem Vorgänger.
public struct Prueflauf: Codable, Identifiable {
    public let id: UUID
    public let gestartetAm: Date
    public let beendetAm: Date
    /// Wie viele Regeln wurden geprüft? Zählt für den Negativnachweis.
    public let anzahlRegeln: Int
    public let befunde: [Befund]
    public let autonomie: Autonomie
    public let ausgefuehrteKorrekturen: [Korrektur]
    /// Hash des vorherigen Laufs (oder `Pruefprotokoll.anfangshash` beim ersten).
    public let vorgaengerHash: String
    /// Hash über alle übrigen Felder dieses Laufs; leer, wenn er sich nicht bilden ließ.
    public let eigenerHash: String

    /// Erstellt den Lauf und berechnet den eigenen Hash selbst. Man kann also
    /// keinen Lauf mit frei gewähltem Hash erzeugen -- nur einen, der stimmt.
    public init(id: UUID = UUID(),
                gestartetAm: Date,
                beendetAm: Date,
                anzahlRegeln: Int,
                befunde: [Befund],
                autonomie: Autonomie,
                ausgefuehrteKorrekturen: [Korrektur],
                vorgaengerHash: String) {
        self.id = id
        self.gestartetAm = gestartetAm
        self.beendetAm = beendetAm
        self.anzahlRegeln = anzahlRegeln
        self.befunde = befunde
        self.autonomie = autonomie
        self.ausgefuehrteKorrekturen = ausgefuehrteKorrekturen
        self.vorgaengerHash = vorgaengerHash
        // Scheitert die Hashbildung, bleibt der Hash leer; dann fällt der Lauf
        // bei der Prüfung durch, statt unbemerkt als gültig zu gelten.
        self.eigenerHash = Prueflauf.berechneHash(
            id: id, gestartetAm: gestartetAm, beendetAm: beendetAm,
            anzahlRegeln: anzahlRegeln, befunde: befunde, autonomie: autonomie,
            ausgefuehrteKorrekturen: ausgefuehrteKorrekturen,
            vorgaengerHash: vorgaengerHash) ?? ""
    }

    /// Alles außer dem eigenen Hash, in kanonischer Form hashbar.
    private struct Inhalt: Encodable {
        let id: UUID
        let gestartetAm: Date
        let beendetAm: Date
        let anzahlRegeln: Int
        let befunde: [Befund]
        let autonomie: Autonomie
        let ausgefuehrteKorrekturen: [Korrektur]
        let vorgaengerHash: String
    }

    private static func berechneHash(id: UUID,
                                     gestartetAm: Date,
                                     beendetAm: Date,
                                     anzahlRegeln: Int,
                                     befunde: [Befund],
                                     autonomie: Autonomie,
                                     ausgefuehrteKorrekturen: [Korrektur],
                                     vorgaengerHash: String) -> String? {
        let inhalt = Inhalt(id: id, gestartetAm: gestartetAm, beendetAm: beendetAm,
                            anzahlRegeln: anzahlRegeln, befunde: befunde,
                            autonomie: autonomie,
                            ausgefuehrteKorrekturen: ausgefuehrteKorrekturen,
                            vorgaengerHash: vorgaengerHash)
        // Gleiches Muster wie beim Rechenbeleg: kanonisch serialisiert, SHA256.
        return try? Rechenkern.hash(inhalt)
    }

    /// Stimmt der gespeicherte Hash mit dem Inhalt überein?
    public var hashStimmt: Bool {
        guard !eigenerHash.isEmpty,
              let neu = Prueflauf.berechneHash(
                id: id, gestartetAm: gestartetAm, beendetAm: beendetAm,
                anzahlRegeln: anzahlRegeln, befunde: befunde, autonomie: autonomie,
                ausgefuehrteKorrekturen: ausgefuehrteKorrekturen,
                vorgaengerHash: vorgaengerHash) else { return false }
        return neu == eigenerHash
    }
}

/// Die Kette aller Prüfläufe. Jeder Lauf trägt den Hash seines Vorgängers; wer
/// nachträglich einen Lauf ändert oder entfernt, bricht die Kette -- und das
/// lässt sich jederzeit feststellen.
public final class Pruefprotokoll {
    /// Vorgängerhash des allerersten Laufs.
    public static let anfangshash = "anfang"

    private let sperre = NSLock()
    private var kette: [Prueflauf]

    /// Lädt ein bestehendes Protokoll (z. B. aus dem Speicher). Ob es unversehrt
    /// ist, sagt `istUnversehrt()` -- das Laden selbst prüft nichts weg.
    public init(laeufe: [Prueflauf] = []) {
        self.kette = laeufe
    }

    public var laeufe: [Prueflauf] {
        sperre.lock()
        defer { sperre.unlock() }
        return kette
    }

    /// Hash, den der nächste Lauf als `vorgaengerHash` tragen muss.
    public var letzterHash: String {
        sperre.lock()
        defer { sperre.unlock() }
        return kette.last?.eigenerHash ?? Pruefprotokoll.anfangshash
    }

    /// Hängt einen Lauf an. Abgelehnt (false) wird, was nicht an das Ende der
    /// Kette passt oder dessen eigener Hash nicht stimmt.
    @discardableResult
    public func anhaengen(_ lauf: Prueflauf) -> Bool {
        sperre.lock()
        defer { sperre.unlock() }
        let erwartet = kette.last?.eigenerHash ?? Pruefprotokoll.anfangshash
        guard lauf.vorgaengerHash == erwartet, lauf.hashStimmt else { return false }
        kette.append(lauf)
        return true
    }

    /// Ist die ganze Kette lückenlos und unverändert?
    public func istUnversehrt() -> Bool {
        let momentaufnahme = laeufe
        var erwartet = Pruefprotokoll.anfangshash
        for lauf in momentaufnahme {
            guard lauf.vorgaengerHash == erwartet, lauf.hashStimmt else { return false }
            erwartet = lauf.eigenerHash
        }
        return true
    }

    /// Der letzte Lauf, der an dem gegebenen Kalendertag (deutsche Zeit) begann.
    public func laufFuer(tag: Date) -> Prueflauf? {
        let kalender = Pruefprotokoll.kalender
        return laeufe.last { kalender.isDate($0.gestartetAm, inSameDayAs: tag) }
    }

    /// Der Satz, der beweist, dass an einem Tag NICHTS Ernstes vorlag.
    ///
    /// Das ist der Beweis der ABWESENHEIT von Problemen zu einem bestimmten
    /// Zeitpunkt. Im Haftungsfall und bei der Wiedereinsetzung nach § 233 ZPO
    /// zählt genau das: dass man belegen kann, wie sorgfältig organisiert und
    /// geprüft wurde, und dass an jenem Tag nichts auffiel -- nicht nur, dass
    /// man später ein Problem behoben hat. Kanzleisoftware zeigt sonst, was
    /// offen ist; sie belegt nicht, was geprüft war und in Ordnung ist.
    ///
    /// Gibt `nil` zurück, wenn es an dem Tag keinen Lauf gab ODER die Kette
    /// beschädigt ist -- ein Nachweis aus einem manipulierbaren Protokoll wäre
    /// keiner. Maßgeblich ist der letzte Lauf des Tages.
    public func negativnachweis(fuer tag: Date) -> String? {
        guard istUnversehrt(), let lauf = laufFuer(tag: tag) else { return nil }

        let anzahlErnst = lauf.befunde.filter { $0.schwere >= .ernst }.count

        let formatierer = DateFormatter()
        formatierer.locale = Locale(identifier: "de_DE")
        formatierer.timeZone = Pruefprotokoll.kalender.timeZone
        formatierer.dateFormat = "dd.MM.yyyy"
        let datum = formatierer.string(from: tag)

        let pruefungen = lauf.anzahlRegeln == 1 ? "Prüfung" : "Prüfungen"
        let liefen = lauf.anzahlRegeln == 1 ? "lief" : "liefen"
        let befunde = anzahlErnst == 1 ? "Befund" : "Befunde"

        return "Am \(datum) \(liefen) \(lauf.anzahlRegeln) \(pruefungen), "
            + "\(anzahlErnst) \(befunde) der Schwere ernst oder kritisch. "
            + "Protokollkette unversehrt."
    }

    /// Feste Zeitzone, damit "derselbe Tag" auf jedem Gerät derselbe Tag ist.
    private static var kalender: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "Europe/Berlin") ?? TimeZone(secondsFromGMT: 3600) ?? .current
        return k
    }
}
