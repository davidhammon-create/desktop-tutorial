import Foundation

/// Die 16 Bundesländer. Maßgeblich für § 193 BGB ist das Land des Erklärungsorts
/// (Sitz des Gerichts bzw. der Stelle, bei der die Erklärung eingehen muss),
/// nicht der Kanzleisitz.
public enum Bundesland: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case bw, by, be, bb, hb, hh, he, mv, ni, nw, rp, sl, sn, st, sh, th

    public var id: String { rawValue }

    /// Ausgeschriebener Name des Landes für die Anzeige.
    public var bezeichnung: String {
        switch self {
        case .bw: return "Baden-Württemberg"
        case .by: return "Bayern"
        case .be: return "Berlin"
        case .bb: return "Brandenburg"
        case .hb: return "Bremen"
        case .hh: return "Hamburg"
        case .he: return "Hessen"
        case .mv: return "Mecklenburg-Vorpommern"
        case .ni: return "Niedersachsen"
        case .nw: return "Nordrhein-Westfalen"
        case .rp: return "Rheinland-Pfalz"
        case .sl: return "Saarland"
        case .sn: return "Sachsen"
        case .st: return "Sachsen-Anhalt"
        case .sh: return "Schleswig-Holstein"
        case .th: return "Thüringen"
        }
    }
}
