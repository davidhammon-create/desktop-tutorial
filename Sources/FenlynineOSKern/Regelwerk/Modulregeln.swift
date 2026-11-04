import Foundation

// MARK: - Modulregeln
//
// Hier darf der Wächter die App umbauen -- aber nur über `modellAendern` und nur
// Oberfläche, nie Falldaten. Jede Änderung ist umkehrbar, damit ein Fehlgriff
// des Wächters den Anwalt höchstens einen Klick kostet.

/// Sichtbares Modul wurde 90 Tage nicht benutzt.
public struct ModulUngenutztRegel: Regel {
    public let id = "modul.ungenutzt"
    public let version = "1.0"
    public let titel = "Modul seit 90 Tagen ungenutzt"
    public let schwere: Schwere = .hinweis
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        // Pflichtmodule sind ausgenommen: Dass sie selten gebraucht werden, heißt
        // nicht, dass man sie ausblenden darf.
        zustand.modul.filter { $0.sichtbar && !$0.istPflichtmodul && $0.benutzungenLetzte90Tage == 0 }.map { m in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Dieses Modul wurde seit 90 Tagen nicht benutzt und nimmt Platz in der Oberfläche ein. Weniger Ablenkung hilft, das Wichtige zu sehen. Ausblenden lässt sich jederzeit wieder rückgängig machen.",
                   objektId: m.id, belegstelle: "Nutzung der letzten 90 Tage",
                   korrektur: .modellAendern(aenderungId: "modul.ausblenden.\(m.id)",
                                             beschreibung: "Modul \(m.id) ausblenden, seit 90 Tagen ungenutzt",
                                             umkehrbar: true),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Pflichtmodul ist unsichtbar.
public struct ModulPflichtAusgeblendetRegel: Regel {
    public let id = "modul.pflicht.ausgeblendet"
    public let version = "1.0"
    public let titel = "Pflichtmodul ist ausgeblendet"
    public let schwere: Schwere = .kritisch
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        zustand.modul.filter { $0.istPflichtmodul && !$0.sichtbar }.map { m in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Ein Modul, das für die sorgfältige Kanzleiführung gebraucht wird, ist unsichtbar. Was man nicht sieht, wird nicht erledigt -- etwa eine Prüfung, die dort angestoßen wird. Es sollte sofort wieder eingeblendet werden.",
                   objektId: m.id, belegstelle: "Sichtbarkeit des Moduls",
                   korrektur: .modellAendern(aenderungId: "modul.einblenden.\(m.id)",
                                             beschreibung: "Pflichtmodul \(m.id) wieder einblenden",
                                             umkehrbar: true),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Häufig benutztes Modul steht weit hinten.
public struct ModulVielBenutztWeitHintenRegel: Regel {
    public let id = "modul.viel.benutzt.weit.hinten"
    public let version = "1.0"
    public let titel = "Häufig genutztes Modul steht weit hinten"
    public let schwere: Schwere = .hinweis
    public let norm: String? = nil

    /// Ab dieser Position (0 = ganz vorne) gilt ein Modul als "weit hinten".
    public let ersteHintenPosition = 5
    /// Ab so vielen Benutzungen in 90 Tagen gilt es als "häufig benutzt" (etwa jeden dritten Tag).
    public let mindestBenutzungen = 30

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        // Die Position ergibt sich aus der Reihenfolge der Module im Zustand:
        // `PruefbaresModul` hat kein eigenes Positionsfeld, und die Reihenfolge
        // entspricht der Anzeige. Nur sichtbare Module zählen, weil nur sie
        // tatsächlich Platz in der Leiste belegen.
        let sichtbare = zustand.modul.filter { $0.sichtbar }
        return sichtbare.enumerated().filter { position, m in
            position >= ersteHintenPosition && m.benutzungenLetzte90Tage >= mindestBenutzungen
        }.map { position, m in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Dieses Modul wird oft benutzt, steht aber an Position \(position + 1). Wer es täglich braucht, sucht es sonst jedes Mal. Weiter vorne spart es Zeit; die alte Reihenfolge lässt sich wiederherstellen.",
                   objektId: m.id, belegstelle: "Position und Nutzung der letzten 90 Tage",
                   korrektur: .modellAendern(aenderungId: "modul.nachVorne.\(m.id)",
                                             beschreibung: "Modul \(m.id) nach vorne verschieben, da häufig benutzt",
                                             umkehrbar: true),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}
