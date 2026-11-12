import Foundation

// MARK: - Systemregeln
//
// Prüfen die Herkunft belegter Werte (Zinssätze, Tabellen, Beträge der Rechenkerne).
// Geprüft wird nie der Wert selbst, nur ob er nachvollziehbar und aktuell ist.

/// Belegter Wert ist älter als 13 Monate.
public struct WertVeraltetRegel: Regel {
    public let id = "wert.veraltet"
    public let version = "1.0"
    public let titel = "Belegter Wert ist veraltet"
    public let schwere: Schwere = .ernst
    public let norm: String? = nil

    /// Warum 13 statt 12 Monate: Viele Werte werden jährlich aktualisiert. Ein
    /// Monat Toleranz verhindert Fehlalarme direkt vor der Jahresaktualisierung,
    /// ein ganzes Jahr ohne Abruf ist aber sicher zu alt.
    public let maximaleAlterMonate = 13

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        let grenze = Regelkalender.kalender.date(byAdding: .month, value: -maximaleAlterMonate, to: zustand.heute)
        return zustand.belegteWerte.filter { w in
            if w.istVeraltet { return true }
            if let abruf = w.abgerufenAm, let g = grenze { return abruf < g }
            return false
        }.map { w in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Dieser Wert wurde zuletzt vor mehr als \(maximaleAlterMonate) Monaten aus seiner Quelle abgerufen. Es wird mit überholten Zahlen gerechnet, ohne dass es jemand merkt.",
                   objektId: w.id, belegstelle: "Abrufdatum der Quelle",
                   korrektur: .pruefungAnfordern(objektId: w.id, frage: "Bitte den Wert in der Quelle prüfen und aktualisieren"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Belegter Wert ohne Quellenangabe.
public struct WertOhneQuelleRegel: Regel {
    public let id = "wert.ohne.quelle"
    public let version = "1.0"
    public let titel = "Wert ohne Quellenangabe"
    public let schwere: Schwere = .ernst
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        zustand.belegteWerte.filter { !$0.quelleGenannt }.map { w in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Für diesen Wert ist keine Quelle genannt. Ohne Quelle lässt sich weder nachprüfen, ob er stimmt, noch gegenüber Dritten belegen, woher er stammt.",
                   objektId: w.id, belegstelle: "Quellenangabe",
                   korrektur: .feldErgaenzen(objektId: w.id, feld: "quelle", vorschlag: "Quelle des Werts angeben"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}
