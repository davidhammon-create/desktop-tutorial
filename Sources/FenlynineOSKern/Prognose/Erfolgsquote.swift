import Foundation

/// Erfolgsquote als Beta-Verteilung. Zwei Zahlen genügen -- und sie tragen ihre
/// eigene Unsicherheit mit sich. Eine öffentliche Statistik der Klägererfolgsquoten
/// existiert nicht; die Quote entsteht daher ausschließlich aus eigenen Verfahren.
public struct Erfolgsquote: Codable, Hashable, Sendable {
    /// Erfolge + Prior.
    public private(set) var alpha: Double
    /// Misserfolge + Prior.
    public private(set) var beta: Double

    public init(alpha: Double, beta: Double) {
        self.alpha = alpha
        self.beta = beta
    }

    /// Jeffreys-Prior (0,5 / 0,5): der übliche uninformative Startpunkt für
    /// Anteilswerte. Bei null Fällen ergibt sich exakt 50 % mit maximaler Streuung --
    /// die Quote "weiß" dann nichts und sagt das auch.
    public static func neu() -> Erfolgsquote {
        Erfolgsquote(alpha: 0.5, beta: 0.5)
    }

    /// Verbucht einen abgeschlossenen Fall. Teilerfolge (Vergleich = 0,5) zählen
    /// anteilig, damit ein Vergleich weder als Sieg noch als Niederlage verfälscht wird.
    public mutating func beobachte(erfolg: Double) {
        let e = min(1, max(0, erfolg))
        alpha += e
        beta += (1 - e)
    }

    public var erwartungswert: Double { alpha / (alpha + beta) }

    /// Zahl der echten Beobachtungen (ohne die beiden Prior-Halbfälle).
    public var fallzahl: Double { max(0, alpha + beta - 1) }

    /// Standardabweichung der Beta-Verteilung -- die ehrliche Fehlerangabe.
    public var streuung: Double {
        let n = alpha + beta
        return (alpha * beta / (n * n * (n + 1))).squareRoot()
    }

    /// Anzeige nur, wenn die Streuung klein genug ist. Faustregel: erst wenn das
    /// Intervall schmaler als etwa 20 Punkte ist, ist die Zahl eine Aussage.
    public var darfAngezeigtWerden: Bool { streuung < 0.05 }

    /// Klartext statt Scheingenauigkeit -- immer mit Grundgesamtheit. Verweigert
    /// die Aussage, solange die Datenlage sie nicht trägt.
    public var text: String {
        let n = Int(fallzahl.rounded())
        guard darfAngezeigtWerden else {
            return "Noch zu wenige eigene Fälle (\(n)) für eine belastbare Quote."
        }
        // Stufen zu 5: feinere Angaben wären bei dieser Streuung nur Rauschen.
        let p = Int((erwartungswert * 100 / 5).rounded()) * 5
        let s = Int((streuung * 200).rounded())
        return "\(p) % ± \(s) Punkte, aus \(n) eigenen Verfahren."
    }
}
