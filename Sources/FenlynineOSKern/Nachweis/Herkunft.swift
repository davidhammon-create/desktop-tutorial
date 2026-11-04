import Foundation

/// Woher stammt eine Zahl oder Aussage? Die Marke macht sichtbar, wofür jemand
/// haftet und was nur ein unbestätigter Vorschlag ist.
public enum Herkunft: String, Codable, CaseIterable, Hashable, Sendable {
    case formel
    case ki
    case mensch
    case quelle

    /// Kurzbezeichnung für die Marke in der Oberfläche.
    public var kurz: String {
        switch self {
        case .formel: return "Formel"
        case .ki: return "KI"
        case .mensch: return "Mensch"
        case .quelle: return "Quelle"
        }
    }

    public var beschreibung: String {
        switch self {
        case .formel:
            return "Deterministisch berechnet: gleiche Eingabe, gleiches Ergebnis."
        case .ki:
            return "Unbestätigter Vorschlag einer KI -- erst nach Prüfung durch einen Menschen verwertbar."
        case .mensch:
            return "Von einer Person gesetzt oder bestätigt; diese Person steht dafür ein."
        case .quelle:
            return "Aus einer Rechtsquelle (Gesetz, Verordnung, Gebührentabelle) übernommen."
        }
    }
}
