import Foundation
import SwiftUI
enum PfadgrafRichtung: String, Codable, CaseIterable, Identifiable {
    case vorwaerts = "Vorwärts"
    case rueckwaerts = "Rückwärts"
    case gemischt = "Gemischt"
    var id: String { rawValue }
    var frage: String {
        switch self {
        case .vorwaerts:   return "Vorwärts: Nur A ist bekannt — was lässt sich mit den vorliegenden Ressourcen erreichen?"
        case .rueckwaerts: return "Rückwärts: Ziel Z steht fest — welche Wege führen dorthin, welcher ist der beste?"
        case .gemischt:     return "Gemischt: A und Z fest, Mitte offen — mehrere konkurrierende Wege zum selben Ziel."
        }
    }
}
enum PfadgrafLayout: String, Codable, CaseIterable, Identifiable {
    case vertikal = "Vertikal"
    case horizontal = "Horizontal"
    case zeitachse = "Zeitachse"
    var id: String { rawValue }
    var fortschrittsHinweis: String {
        switch self {
        case .vertikal:    return "Fortschritt oben → unten · Knoten ziehen zum Verschieben"
        case .horizontal:  return "Fortschritt links → rechts · Knoten ziehen zum Verschieben"
        case .zeitachse:   return "X = Kalendertage · Fristen als Sperrlinien · Knoten ziehbar"
        }
    }
    var erklaerung: String {
        switch self {
        case .vertikal:
            return "Vertikal: ideal für Instanzenzüge und Eskalation. Jede Ebene ist ein Schritt weiter vom Ist-Zustand A."
        case .horizontal:
            return "Horizontal: ideal für Verhandlung und Strategiepapiere. Derselbe Graf, nur gedreht — Daten bleiben gleich."
        case .zeitachse:
            return "Zeitachse: Abstände = Dauer, nicht Schrittzahl. Liegt ein Pfad hinter einer Fristlinie, ist er nicht gangbar."
        }
    }
}
enum PfadgrafOptimierung: String, Codable, CaseIterable, Identifiable {
    case erwartungswert = "Erwartungswert"
    case kosten = "Kosten"
    case dauer = "Dauer"
    case erfolg = "Erfolgswahrscheinlichkeit"
    var id: String { rawValue }
}
enum PfadgrafKnotenTyp: String, Codable, CaseIterable, Identifiable {
    case ist = "Ist-Zustand"                 // A — gefüllt
    case geplant = "Geplanter Zustand"       // B — offen
    case fremd = "Fremdbestimmt"             // G — gestrichelte Kontur
    case ziel = "Zielzustand"                // Z — doppelte Kontur
    var id: String { rawValue }
    var kurz: String {
        switch self {
        case .ist:     return "Ist"
        case .geplant: return "Geplant"
        case .fremd:   return "Fremd"
        case .ziel:    return "Ziel"
        }
    }
}
enum PfadgrafKnotenStatus: String, Codable, CaseIterable, Identifiable {
    case offen = "offen"
    case erreicht = "erreicht"
    case verfallen = "verfallen"
    var id: String { rawValue }
}
enum PfadgrafKantenArt: String, Codable, CaseIterable, Identifiable {
    case empfohlen = "Empfohlen"       // volle Strichstärke
    case moeglich = "Möglich"          // normale Linie
    case bedingt = "Bedingt"           // gestrichelt
    case fremd = "Fremd"               // gepunktet
    var id: String { rawValue }
}
enum PfadgrafSteuerung: String, Codable, CaseIterable, Identifiable {
    case eigen = "eigen"
    case fremd = "fremd"
    case zufall = "Zufall"
    var id: String { rawValue }
}
struct PfadgrafRessourcen: Codable, Hashable {
    var budget: Double = 0          // €
    var zeitTage: Double = 0
    var personal: Double = 0        // Personen-Tage o. ä.
    var rechtspositionen: [String] = []
    var informationen: [String] = []
}
struct PfadgrafKnoten: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kennung: String                 // A, B, C … überschreibbar
    var typ: PfadgrafKnotenTyp = .geplant
    var bezeichnung: String = ""        // max. 40 Zeichen für Zeichnung
    var ressourcen: PfadgrafRessourcen = .init()
    var beschraenkungen: [String] = []
    var eigenwert: Double = 0           // Wertbeitrag des Zustands selbst
    var fristId: UUID? = nil            // Verknüpfung Schritt 8
    var fruehestesDatum: Date? = nil    // für Zeitachsenmodus
    var status: PfadgrafKnotenStatus = .offen
    var istSammelknoten: Bool = false
    var kinderIds: [UUID] = []
    var zusammengeklappt: Bool = false
    var manuellX: Double? = nil
    var manuellY: Double? = nil
    var hatManuellePosition: Bool { manuellX != nil && manuellY != nil }
}
struct PfadgrafKante: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var von: UUID
    var nach: UUID
    var handlung: String = ""
    var kosten: Double = 0
    var dauerMinTage: Int = 0
    var dauerMaxTage: Int = 0
    var pErfolg: Double = 0.5
    var verbrauch: PfadgrafRessourcen = .init()
    var voraussetzung: String = ""      // steuert gestrichelte Darstellung
    var grundlage: String = ""          // Norm, Vertragsklausel, Präzedenz
    var steuerung: PfadgrafSteuerung = .eigen
    var art: PfadgrafKantenArt = .moeglich
    var istSchleife: Bool = false
    var schleifeMax: Int = 0
}
struct Pfadgraf: Codable, Hashable {
    var id: UUID = UUID()
    var knoten: [PfadgrafKnoten] = []
    var kanten: [PfadgrafKante] = []
    var startKnotenId: UUID? = nil
    var zielKnotenIds: [UUID] = []          // mehrere Ziele / Zielkorridor
    var layout: PfadgrafLayout = .vertikal
    var richtung: PfadgrafRichtung = .gemischt
    var optimierung: PfadgrafOptimierung = .erwartungswert
    var kantenKennzahl: PfadgrafKantenKennzahl = .keine
    var hervorgehobenerPfadIds: [UUID] = [] // Kanten-IDs
    var version: Int = 1
}
enum PfadgrafKantenKennzahl: String, Codable, CaseIterable, Identifiable {
    case keine = "—"
    case kosten = "Kosten"
    case dauer = "Dauer"
    case p = "p(Erfolg)"
    var id: String { rawValue }
}
struct PfadgrafPfad: Identifiable, Hashable {
    var id: UUID = UUID()
    var knotenIds: [UUID]
    var kantenIds: [UUID]
    var p: Double
    var kosten: Double
    var dauerTage: Double
    var eigenwerteSumme: Double
    var zielWert: Double
    var ev: Double
    var gangbar: Bool
    var sperrGrund: String? = nil
}
struct PfadgrafAuswertung {
    var pfade: [PfadgrafPfad] = []          // Top-N nach Optimierung
    var allePfadAnzahl: Int = 0
    var engpassKnotenIds: [UUID] = []
    var redundanzgrad: Int = 0
    var optionswerte: [UUID: Double] = [:]  // je Knoten
    var knotenWerte: [UUID: Double] = [:]   // Minimax / max / Erwartungswert
    var verstosse: [PfadgrafVerstoss] = []
    var empfohlenerPfadId: UUID? = nil
}
struct PfadgrafVerstoss: Identifiable, Hashable {
    var id: UUID = UUID()
    var schwere: Schwere
    var text: String
    enum Schwere: String { case sperre, warnung }
}
struct PfadgrafLayoutPunkt: Hashable {
    var knotenId: UUID
    var x: CGFloat
    var y: CGFloat
    var ebene: Int
    var spur: Int
}
struct PfadgrafLayoutErgebnis {
    var punkte: [PfadgrafLayoutPunkt] = []
    var breite: CGFloat = 600
    var hoehe: CGFloat = 400
    var fristLinien: [(tage: Double, label: String)] = []
}
