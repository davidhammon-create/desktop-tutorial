import Foundation

/// Fristversäumnis ist ein Zustand, keine Punktwertung: Eine versäumte Notfrist
/// senkt die Erfolgsaussicht nicht um einen Betrag, sondern beendet das Verfahren
/// (Rechtsmittel unzulässig; verbleibend nur die Wiedereinsetzung, § 233 ZPO).
public enum Fristzustand: Hashable, Sendable {
    case unauffaellig
    case kritisch(tageRest: Int)
    /// z. B. Schriftsatzfrist: verspäteter Vortrag wird oft noch zugelassen.
    case versaeumtHeilbar(norm: String)
    /// Notfrist (§ 224 ZPO) versäumt.
    case versaeumtFatal(norm: String, wiedereinsetzungMoeglich: Bool)

    /// Wirkung auf die Prognose -- kein Abschlag, sondern eine Aussage.
    public var wirkung: String {
        switch self {
        case .unauffaellig:
            return "keine"
        case .kritisch(let t):
            return "Frist läuft in \(t) Tagen ab -- Prognose unverändert, Handlungsdruck hoch"
        case .versaeumtHeilbar(let n):
            return "\(n) versäumt -- Vortrag ggf. noch zulässig, Prognose leicht belastet"
        case .versaeumtFatal(let n, let wieder):
            if wieder {
                return "\(n) als Notfrist versäumt -- Verfahren nur über Wiedereinsetzung "
                    + "(§ 233 ZPO) zu retten. Prognose bis zur Entscheidung darüber ausgesetzt."
            } else {
                return "\(n) als Notfrist versäumt, Wiedereinsetzung ausgeschlossen -- "
                    + "Rechtsmittel unzulässig."
            }
        }
    }

    /// Die Prognose wird nicht gedrückt, sondern angehalten. Eine Zahl,
    /// die den Zustand ignoriert, wäre irreführend.
    public var prognoseGueltig: Bool {
        if case .versaeumtFatal = self { return false }
        return true
    }
}
