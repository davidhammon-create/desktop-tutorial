import Foundation

/// Eine Position im Verfahrensportfolio.
public protocol PortfolioPosition {
    var erwartungswert: Double { get }
    var streuung: Double { get }
    var rechtsgebiet: String? { get }
    var gegnerId: String? { get }
    var gericht: String? { get }
    var tragendeNorm: String? { get }
}

public enum Portfolio {

    private static func gleich(_ a: String?, _ b: String?) -> Bool {
        guard let a = a, let b = b else { return false }
        return a == b
    }

    /// Korrelation zweier Positionen aus gemeinsamen Merkmalen, gedeckelt auf 0,95.
    public static func korrelation(_ a: PortfolioPosition, _ b: PortfolioPosition) -> Double {
        var k = 0.0
        if gleich(a.rechtsgebiet, b.rechtsgebiet) { k += 0.25 }
        if gleich(a.gegnerId, b.gegnerId) { k += 0.35 }
        if gleich(a.gericht, b.gericht) { k += 0.20 }
        if gleich(a.tragendeNorm, b.tragendeNorm) { k += 0.40 }
        return min(k, 0.95)
    }

    /// Erwartungswert additiv; Varianz über die Doppelsumme mit Korrelationen.
    public static func kennzahlen(_ positionen: [PortfolioPosition]) -> (ev: Double, streuung: Double) {
        let ev = positionen.reduce(0.0) { $0 + $1.erwartungswert }
        var varianz = 0.0
        for (i, a) in positionen.enumerated() {
            for (j, b) in positionen.enumerated() {
                let rho = i == j ? 1.0 : korrelation(a, b)
                varianz += rho * a.streuung * b.streuung
            }
        }
        return (ev, varianz.squareRoot())
    }
}
