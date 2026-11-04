import Foundation

/// Wie selbstständig darf der Wächter handeln?
public enum Autonomie: Int, Codable, CaseIterable, Comparable, Sendable {
    /// Nur Befunde sammeln und protokollieren.
    case beobachten = 0
    /// Befunde mit Korrekturvorschlag anzeigen; der Mensch entscheidet.
    case vorschlagen = 1
    /// Folgenlose Korrekturen (siehe `Korrektur.darfAutomatischLaufen`) selbst ausführen.
    case selbstheilend = 2

    public static func < (links: Autonomie, rechts: Autonomie) -> Bool {
        links.rawValue < rechts.rawValue
    }

    public var bezeichnung: String {
        switch self {
        case .beobachten: return "Beobachten"
        case .vorschlagen: return "Vorschlagen"
        case .selbstheilend: return "Selbstheilend"
        }
    }

    public var erklaerung: String {
        switch self {
        case .beobachten:
            return "Der Wächter prüft und schreibt auf, was ihm auffällt. Er ändert nichts."
        case .vorschlagen:
            return "Der Wächter zeigt Ihnen, was auffällt, und schlägt eine Lösung vor. Sie entscheiden, ob sie umgesetzt wird."
        case .selbstheilend:
            return "Der Wächter erledigt kleine, folgenlose Dinge selbst (Hinweise, Markierungen, Neuberechnungen, umkehrbare Einstellungen). Alles andere legt er Ihnen vor."
        }
    }

    /// Empfohlene Voreinstellung: `.vorschlagen`.
    ///
    /// Warum nicht `.beobachten`? Dann bliebe der Nutzen liegen: Der Anwalt sieht
    /// den Befund, muss die Lösung aber selbst erfinden. Warum nicht
    /// `.selbstheilend`? Weil Vertrauen verdient werden muss: Eine Kanzlei sollte
    /// zuerst einige Wochen sehen, was der Wächter vorschlägt, und erst dann
    /// bewusst entscheiden, ihm die folgenlosen Handgriffe zu überlassen. Die
    /// Stufe `.selbstheilend` ist deshalb eine Entscheidung der Kanzlei, nie eine
    /// Voreinstellung. (Auch auf dieser Stufe bleibt der Wächter durch den Typ
    /// `Korrektur` begrenzt -- die Stufe erweitert nicht, WAS er kann, sondern nur,
    /// OB er vorher fragt.)
    public static let empfohlen: Autonomie = .vorschlagen
}

/// Was der Wächter anfassen darf und was nie.
///
/// ACHTUNG: Diese Listen sind DOKUMENTATION für Prüfer und Versicherer. Sie
/// setzen nichts durch. Durchgesetzt wird die Grenze durch den Typ `Korrektur`:
/// Es gibt dort keinen Fall, der Falldaten schreiben könnte, und die
/// Eingabetypen (`Pruefbare*`) enthalten keine solchen Inhalte. Die Listen
/// beschreiben, was aus dieser Konstruktion folgt -- sie sind die lesbare
/// Fassung der Garantie, nicht ihr Mechanismus.
public enum Sperren {
    /// Was der Wächter NIEMALS anfasst.
    public static let niemals: [String] = [
        "Das Datum einer Frist",
        "Den Erledigungsvermerk einer Notfrist",
        "Werte, die ein Mensch bestätigt hat",
        "Mandatsinhalte (Namen, Angaben zu Mandanten, Korrespondenz)",
        "Inhalte von Dokumenten und Schriftsätzen",
        "Alles, was die Kanzlei verlässt (Versand, Veröffentlichung, Übermittlung)"
    ]

    /// Was der Wächter verändern oder anlegen darf.
    public static let erlaubt: [String] = [
        "Sichtbarkeit und Reihenfolge von Modulen",
        "Navigationszonen",
        "Ablaufschritte",
        "Pflichtfelder",
        "Designdichte",
        "Hinweise",
        "Markierungen",
        "Neuberechnungen (mit neuem Beleg, ohne etwas zu überschreiben)"
    ]
}
