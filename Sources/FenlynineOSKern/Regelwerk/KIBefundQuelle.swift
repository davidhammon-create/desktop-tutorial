import Foundation

// MARK: - KI-Schicht
//
// Die KI ist eine Ergänzung, nie eine Voraussetzung; fällt sie aus, prüft das
// deterministische Regelwerk weiter. Sie schlägt nur vor -- sie stellt nichts
// fest, entscheidet nichts und führt nichts aus.

/// Was die KI überhaupt zu sehen bekommt. Es gibt hier keine Namen, keine Texte,
/// keine Beträge und keine Dokumentinhalte -- nur Strukturmerkmale und Zählwerte.
/// Eine KI, die nur das sieht, KANN keine Mandatsdaten preisgeben.
public struct KIEingabe: Codable {
    public var anzahlFristenOffen: Int
    public var anzahlNotfristen: Int
    public var anzahlBefundeNachSchwere: [String: Int]
    /// Modul-id -> Benutzungen in den letzten 90 Tagen.
    public var modulnutzung: [String: Int]
    /// Schritt-id -> Abbrüche.
    public var ablaufAbbrueche: [String: Int]
    public var durchschnittlicheSchritteBisAbschluss: Double
    public var kernversion: String

    public init(anzahlFristenOffen: Int,
                anzahlNotfristen: Int,
                anzahlBefundeNachSchwere: [String: Int],
                modulnutzung: [String: Int],
                ablaufAbbrueche: [String: Int],
                durchschnittlicheSchritteBisAbschluss: Double,
                kernversion: String) {
        self.anzahlFristenOffen = anzahlFristenOffen
        self.anzahlNotfristen = anzahlNotfristen
        self.anzahlBefundeNachSchwere = anzahlBefundeNachSchwere
        self.modulnutzung = modulnutzung
        self.ablaufAbbrueche = ablaufAbbrueche
        self.durchschnittlicheSchritteBisAbschluss = durchschnittlicheSchritteBisAbschluss
        self.kernversion = kernversion
    }
}

/// Ein Vorschlag der KI. Er ist ein Vorschlag und bleibt einer: Die Korrektur ist
/// ein Wert des geschlossenen Typs `Korrektur`, mehr kann die KI nicht ausdrücken.
public struct KIVorschlag: Codable, Identifiable {
    public var id: UUID
    public var titel: String
    public var begruendung: String
    public var korrektur: Korrektur?
    /// Selbsteinschätzung der KI, 0...1.
    public var zuversicht: Double
    /// Welches KI-Modell den Vorschlag gemacht hat -- für das Protokoll.
    public var modell: String

    public init(id: UUID = UUID(),
                titel: String,
                begruendung: String,
                korrektur: Korrektur? = nil,
                zuversicht: Double,
                modell: String) {
        self.id = id
        self.titel = titel
        self.begruendung = begruendung
        self.korrektur = korrektur
        // Außerhalb 0...1 ist unsinnig; begrenzen, statt der KI blind zu glauben.
        self.zuversicht = min(1, max(0, zuversicht))
        self.modell = modell
    }
}

public protocol KIBefundQuelle {
    func vorschlaege(zu eingabe: KIEingabe) async throws -> [KIVorschlag]
}

/// Standardimplementierung ohne KI: liefert nichts.
///
/// Die KI ist eine Ergänzung, nie eine Voraussetzung; fällt sie aus, prüft das
/// deterministische Regelwerk weiter. Damit funktioniert die App ohne KI vollständig.
public struct KeineKI: KIBefundQuelle {
    public init() {}

    public func vorschlaege(zu eingabe: KIEingabe) async throws -> [KIVorschlag] {
        []
    }
}

/// Wandelt KI-Vorschläge in Befunde um.
///
/// Immer `.hinweis` und immer mit Kennzeichnung im Titel: Ein KI-Vorschlag ist
/// nie eine Feststellung und darf in der Oberfläche nicht wie das Ergebnis einer
/// geprüften Regel aussehen. Der Anwalt soll auf einen Blick sehen, was
/// nachgerechnet wurde und was nur eine Vermutung ist.
public func alsBefunde(_ v: [KIVorschlag]) -> [Befund] {
    v.map { vorschlag in
        Befund(regelId: "ki.vorschlag",
               regelVersion: vorschlag.modell,
               schwere: .hinweis,
               titel: "KI-Vorschlag: \(vorschlag.titel)",
               erklaerung: "Dies ist ein Vorschlag einer KI (\(vorschlag.modell)), keine geprüfte Feststellung. Begründung: \(vorschlag.begruendung)",
               objektId: nil,
               belegstelle: nil,
               korrektur: vorschlag.korrektur,
               norm: nil,
               // Entscheidend: Dieses Kennzeichen hält den Vorschlag von der
               // Automatik fern. Ohne es könnte ein Sprachmodell über eine für
               // sich genommen harmlose Korrektur Wirkung entfalten, ohne dass
               // ein Mensch zugestimmt hat. Die KI darf vorschlagen --
               // drücken muss ein Mensch.
               ausKI: true)
    }
}
