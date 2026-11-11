import Foundation
enum Rechenwerk {
    struct DeterministischerGenerator: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }
    struct MonteCarloErgebnis {
        let laeufe: Int
        let p01: WertMitHerkunft
        let p05: WertMitHerkunft
        let p10: WertMitHerkunft          // pessimistisches Dezil
        let median: WertMitHerkunft
        let p90: WertMitHerkunft          // optimistisches Dezil
        let mittel: WertMitHerkunft
        let std: WertMitHerkunft
        let gewinnQuote: WertMitHerkunft  // P(Ergebnis > 0)
        let zertitaet: WertMitHerkunft    // Zertitätsäquivalent (risikoavers)
        let var95: WertMitHerkunft        // 5%-Quantil der Verteilung, nicht Worst+Kosten
        let var99: WertMitHerkunft
        let sharpe: WertMitHerkunft       // nach MC, gedeckelt bei 3
        let modell: String
    }
    static func monteCarlo(
        _ o: VorgangOption,
        laeufe: Int = 5_000,
        risikoAversion: Double = 0.5
    ) -> MonteCarloErgebnis {
        let p = o.chancen.pErfolg.wert
        let best = o.chancen.best.wert
        let worst = o.chancen.worst.wert
        let kosten = o.kosten.summe
        let a = min(worst, best)
        let b = max(worst, best)
        let zielMittel = p * best + (1 - p) * worst
        let m = min(max(3 * zielMittel - a - b, a), b)
        var rng = DeterministischerGenerator(
            seed: 0x4A49_4C4F_5321 &+ UInt64(bitPattern: Int64((best + worst + kosten).rounded()))
        )
        var proben: [Double] = []
        proben.reserveCapacity(laeufe)
        for _ in 0..<laeufe {
            proben.append(triangular(a: a, m: m, b: b, using: &rng) - kosten)
        }
        proben.sort()
        func quantil(_ q: Double) -> Double {
            guard !proben.isEmpty else { return 0 }
            let idx = min(proben.count - 1, max(0, Int(q * Double(proben.count - 1))))
            return proben[idx]
        }
        let gewinner = proben.lazy.filter { $0 > 0 }.count
        let quote = proben.isEmpty ? 0 : Double(gewinner) / Double(proben.count)
        let spann = max(1, b - a)
        let lambda = max(1e-9, risikoAversion) / spann
        var expSum = 0.0
        for x in proben { expSum += exp(-lambda * x) }
        let ce = proben.isEmpty ? 0 : -(1 / lambda) * log(expSum / Double(proben.count))
        let modell = "Tri(\(fmt(a)), \(fmt(m)), \(fmt(b))) − \(fmt(kosten)) · n=\(laeufe) · Seed fest"
        let p01v = quantil(0.01)
        let p05v = quantil(0.05)
        let mittelV = proben.isEmpty ? 0 : proben.reduce(0, +) / Double(proben.count)
        let var_ = proben.reduce(0.0) { $0 + pow($1 - mittelV, 2) } / Double(max(1, proben.count))
        let stdV = sqrt(var_)
        let sharpeRoh = stdV > 1 ? mittelV / stdV : 0
        let sharpeCap = min(3, max(-3, sharpeRoh))
        return MonteCarloErgebnis(
            laeufe: laeufe,
            p01: .formel(p01v, "P01 der Monte-Carlo-Verteilung · \(modell)"),
            p05: .formel(p05v, "P05 der Monte-Carlo-Verteilung · \(modell)"),
            p10: .formel(quantil(0.10), "P10 der Monte-Carlo-Verteilung · \(modell)"),
            median: .formel(quantil(0.50), "Median der Monte-Carlo-Verteilung · \(modell)"),
            p90: .formel(quantil(0.90), "P90 der Monte-Carlo-Verteilung · \(modell)"),
            mittel: .formel(mittelV, "Mittel der Monte-Carlo-Verteilung · \(modell)"),
            std: .formel(stdV, "σ der Monte-Carlo-Verteilung"),
            gewinnQuote: .formel(quote, "P(X > 0) = \(gewinner)/\(laeufe) Simulationen"),
            zertitaet: .formel(ce, "CE = −(1/λ)·ln E[e^(−λX)], λ = \(String(format: "%.2g", lambda)) (risikoavers)"),
            var95: .formel(p05v, "VaR 95 % = 5%-Quantil der MC-Verteilung (nicht Worst+Kosten)"),
            var99: .formel(p01v, "VaR 99 % = 1%-Quantil der MC-Verteilung (nicht Worst+Kosten)"),
            sharpe: .formel(sharpeCap, "Sharpe = Mittel/σ nach Monte-Carlo, Deckel 3 (roh \(String(format: "%.2f", sharpeRoh)))"),
            modell: modell
        )
    }
    private static func triangular(a: Double, m: Double, b: Double, using rng: inout DeterministischerGenerator) -> Double {
        guard b > a else { return a }
        let u = Double(rng.next() >> 11) / Double(1 << 53)
        let fc = (m - a) / (b - a)
        if u < fc {
            return a + ((u * (b - a) * (m - a)).squareRoot())
        } else {
            return b - (((1 - u) * (b - a) * (b - m)).squareRoot())
        }
    }
    struct Vergleichskorridor {
        let untergrenze: WertMitHerkunft
        let obergrenze: WertMitHerkunft
        let anker: WertMitHerkunft
        let existiert: Bool
    }
    static func vergleichskorridor(_ o: VorgangOption, risikoAversion: Double = 0.5) -> Vergleichskorridor {
        let mc = monteCarlo(o, risikoAversion: risikoAversion)
        let p = o.chancen.pErfolg.wert
        let best = o.chancen.best.wert
        let kosten = o.kosten.summe
        let unten = mc.zertitaet.wert
        let oben = p * best + kosten
        let existiert = oben > unten
        let anker = existiert ? (unten + oben) / 2 : unten
        return Vergleichskorridor(
            untergrenze: .formel(unten, "BATNA = Zertitätsäquivalent (Walk-away)"),
            obergrenze: .formel(oben, "Schmerzgrenze Gegner ≈ P × best + Kostenersparnis = \(fmt(p)) × \(fmt(best)) + \(fmt(kosten))"),
            anker: .formel(anker, existiert
                ? "ZOPA-Mitte = (BATNA + Schmerzgrenze) / 2 — kein 70-%-Anker"
                : "Kein Einigungsbereich: Prozessieren ist besser als jeder Vergleich in diesem Band"),
            existiert: existiert
        )
    }
    static func fristRisiko(tageBisAblauf: Int, kritisch: Bool) -> WertMitHerkunft {
        let naehe: Double
        switch tageBisAblauf {
        case ..<0:    naehe = 100
        case 0...3:   naehe = 90
        case 4...7:   naehe = 75
        case 8...14:  naehe = 55
        case 15...30: naehe = 35
        default:      naehe = 15
        }
        let score = min(100, naehe * (kritisch ? 1.25 : 1.0))
        return .formel(score, "Fristrisiko = Nähe(\(tageBisAblauf) T) × \(kritisch ? "1,25 (kritisch)" : "1,0")")
    }
    private static func fmt(_ x: Double) -> String {
        String(format: "%.2f", x)
    }
}
