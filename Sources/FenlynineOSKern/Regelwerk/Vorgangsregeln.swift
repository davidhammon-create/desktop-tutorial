import Foundation

// MARK: - Vorgangsregeln
//
// Prüfen, ob ein Mandat sauber geführt ist. Wie überall im Regelwerk sehen die
// Regeln nur Ja/Nein-Angaben, nie Parteien, Beträge oder Texte.

/// Prognose ohne Begründung der Annahmen.
public struct PrognoseOhneBegruendungRegel: Regel {
    public let id = "vorgang.prognose.ohne.begruendung"
    public let version = "1.0"
    public let titel = "Prognose ohne Begründung der Annahmen"
    public let schwere: Schwere = .ernst
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        zustand.vorgaenge.filter { $0.prognoseVorhanden && !$0.hatAnnahmenBegruendung }.map { v in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Es gibt eine Prognose, aber nicht, worauf sie beruht. Eine Zahl ohne Herkunft kann niemand überprüfen -- weder die Kollegin noch der Mandant noch ein Gericht.",
                   objektId: v.id, belegstelle: "Annahmen der Prognose",
                   korrektur: .feldErgaenzen(objektId: v.id, feld: "annahmenBegruendung", vorschlag: "Annahmen der Prognose kurz begründen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Mandat ohne Interessenkonfliktprüfung.
public struct VorgangOhneKonfliktpruefungRegel: Regel {
    public let id = "vorgang.ohne.konfliktpruefung"
    public let version = "1.0"
    public let titel = "Mandat ohne Interessenkonfliktprüfung"
    public let schwere: Schwere = .kritisch
    public let norm: String? = "§ 43a Abs. 4 BRAO"

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        zustand.vorgaenge.filter { !$0.konfliktpruefungErfolgt }.map { v in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Für dieses Mandat wurde nicht geprüft, ob die Kanzlei widerstreitende Interessen vertritt. Ein Verstoß gegen das Verbot der Vertretung widerstreitender Interessen kann berufsrechtliche Folgen haben und das Mandat selbst gefährden.",
                   objektId: v.id, belegstelle: "Konfliktprüfung",
                   korrektur: .pruefungAnfordern(objektId: v.id, frage: "Bitte die Interessenkonfliktprüfung für dieses Mandat durchführen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Streitwert gesetzt, aber kein Kostenrisiko berechnet.
public struct VorgangOhneKostenrisikoRegel: Regel {
    public let id = "vorgang.ohne.kostenrisiko"
    public let version = "1.0"
    public let titel = "Kostenrisiko nicht berechnet"
    public let schwere: Schwere = .auffaellig
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        zustand.vorgaenge.filter { $0.streitwertGesetzt && !$0.kostenrisikoBerechnet }.map { v in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Der Streitwert steht fest, das Kostenrisiko wurde aber nicht berechnet. Der Mandant kann dann nicht informiert entscheiden, was ihn ein verlorener Prozess kosten würde.",
                   objektId: v.id, belegstelle: "Kostenrisiko",
                   korrektur: .neuBerechnen(objektId: v.id, grund: "Streitwert vorhanden, Kostenrisiko fehlt"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Streitwert fehlt.
public struct VorgangOhneStreitwertRegel: Regel {
    public let id = "vorgang.ohne.streitwert"
    public let version = "1.0"
    public let titel = "Streitwert fehlt"
    public let schwere: Schwere = .auffaellig
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        zustand.vorgaenge.filter { !$0.streitwertGesetzt }.map { v in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Ohne Streitwert lassen sich Gebühren und Kostenrisiko nicht berechnen. Das fällt sonst erst bei der Abrechnung auf -- oft zu spät, um den Mandanten vorab aufzuklären.",
                   objektId: v.id, belegstelle: "Feld Streitwert",
                   korrektur: .feldErgaenzen(objektId: v.id, feld: "streitwert", vorschlag: "Streitwert eintragen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}
