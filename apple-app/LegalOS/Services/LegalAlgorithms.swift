//
//  LegalAlgorithms.swift
//  Stochastisch-Juristische Berechnungsmaschine – 1:1 Port von lib/legalAlgorithms.js
//  REIN ALGORITHMISCH (keine KI). KI-Aufrufe laufen über KIProvider.
//
//  Methoden: Bayesianische Inferenz, Monte-Carlo-Simulation,
//  gewichtete Kombination juristischer Faktoren, Konfidenzintervalle (90% CI).
//

import Foundation

// MARK: - Konstanten & Gewichtungsmatrizen

private let INSTANZ_FAKTOR: [String: Double] = [
    "Erstinstanz": 1.0,
    "Berufung":    0.88,
    "Revision":    0.70
]

private let RECHTSGEBIET_BASERATES: [String: Double] = [
    "Arbeitsrecht":       0.52,
    "Mietrecht":          0.54,
    "Vertragsrecht":      0.51,
    "Familienrecht":      0.50,
    "Gesellschaftsrecht": 0.49,
    "Strafrecht":         0.35,
    "Verwaltungsrecht":   0.38,
    "Insolvenzrecht":     0.48,
    "IP":                 0.50,
    "default":            0.50
]

private let BASE_WIN_RATE: Double = 0.51

// MARK: - Hilfsfunktionen

@inline(__always) private func clamp(_ v: Double, _ minV: Double = 0, _ maxV: Double = 1) -> Double {
    Swift.max(minV, Swift.min(maxV, v))
}
@inline(__always) private func avg(_ arr: [Double]) -> Double {
    guard !arr.isEmpty else { return 0 }
    return arr.reduce(0, +) / Double(arr.count)
}
@inline(__always) private func variance(_ arr: [Double]) -> Double {
    guard arr.count >= 2 else { return 0 }
    let m = avg(arr)
    return arr.reduce(0.0) { $0 + pow($1 - m, 2) } / Double(arr.count)
}
private func randn(_ mean: Double = 0, sd: Double = 1) -> Double {
    let u1 = Double.random(in: 1e-10...1)
    let u2 = Double.random(in: 0...1)
    return mean + sd * sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
}
@inline(__always) private func logistic(_ x: Double) -> Double { 1.0 / (1.0 + exp(-x)) }
@inline(__always) private func logit(_ p: Double) -> Double {
    let pc = clamp(p, 0.001, 0.999); return log(pc / (1 - pc))
}

private let rvgTabelle: [(maxStreitwert: Double, basisGebuehr: Double)] = [
    (500, 49), (1000, 88), (1500, 127), (2000, 166), (3000, 222), (4000, 278), (5000, 334),
    (13000, 590), (19000, 758), (25000, 986), (50000, 1474), (100000, 1981),
    (200000, 2737), (500000, 3894), (.infinity, 5000)
]
private func rvgGebuehr(streitwert: Double) -> Double {
    rvgTabelle.first { streitwert <= $0.maxStreitwert }?.basisGebuehr ?? 5000
}

private func formatEuro(_ v: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal; nf.locale = Locale(identifier: "de_DE")
    nf.maximumFractionDigits = 0
    return (nf.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " €"
}

// MARK: - Eingabe + Strukturen

public struct PrognoseInput {
    public var args:      [Argument]
    public var evidence:  [Evidence]
    public var deadlines: [Deadline]
    public var persons:   [Person]
    public var caseData:  Case?
    public init(args: [Argument] = [], evidence: [Evidence] = [],
                deadlines: [Deadline] = [], persons: [Person] = [],
                caseData: Case? = nil) {
        self.args = args; self.evidence = evidence
        self.deadlines = deadlines; self.persons = persons
        self.caseData = caseData
    }
}

public struct CalculationStep: Identifiable, Hashable {
    public let id = UUID()
    public var kategorie: String, label: String, formel: String
    public var wert: Double
    public var einheit: String?
    public var erklaerung: String
}

public struct PrognoseInputCounts: Hashable {
    public var eigeneArgs: Int, gegnerArgs: Int, beweise: Int, fristen: Int
    public var richterBekannt: Bool
}

public struct PrognoseResult: Hashable {
    public var score: Int, scoreRaw: Double, logOdds: Double
    public var ciLow: Int, ciHigh: Int, sigma: Double
    public var steps: [CalculationStep]
    public var inputs: PrognoseInputCounts
}

public enum RisikoLevel: String, Hashable { case niedrig, mittel, hoch }

public struct RisikoFaktor: Identifiable, Hashable {
    public let id = UUID()
    public var key: String, score: Int, level: RisikoLevel
    public var bewertung: String, massnahme: String, formel: String
}
public struct RisikoResult: Hashable {
    public var faktoren: [RisikoFaktor]
    public var gesamtrisiko: RisikoLevel
    public var gesamtScore: Double
}

public struct MonteCarloHistogramBin: Identifiable, Hashable {
    public let id = UUID()
    public var bin: String, count: Int, pct: Double
}
public struct MonteCarloScenario: Hashable {
    public var wahrscheinlichkeit: Int, schwelle: Int?, erklaerung: String
}
public struct MonteCarloResult: Hashable {
    public var mean: Int, p10: Int, p25: Int, median: Int, p75: Int, p90: Int
    public var histogram: [MonteCarloHistogramBin], iterations: Int
    public var bestCase: MonteCarloScenario, baseCase: MonteCarloScenario, worstCase: MonteCarloScenario
}

public struct ZusatzOption: Identifiable, Hashable {
    public let id = UUID()
    public var titel: String, symbol: String, beschreibung: String
    public var breakEvenPct: Int, basis: String, rechtsgrundlage: String
}
public struct BreakEvenResult: Hashable {
    public var breakEvenPct: Int?, gesamtkosten: Int
    public var eigeneKosten: Int, gegnerKosten: Int, gerichtkosten: Int
    public var svKosten: Int, reiseKosten: Int
    public var formel: String, erklaerung: String, empfehlung: String
    public var zusatzoptionen: [ZusatzOption]
}

public struct VollanalyseResult: Hashable {
    public var prognose: PrognoseResult
    public var risikofaktoren: RisikoResult
    public var monteCarlo: MonteCarloResult
    public var breakEven: BreakEvenResult
    public var timestamp: Date
    public var version: String
}

// MARK: - LegalAlgorithms

public enum LegalAlgorithms {

    // ─── computePrognose ──────────────────────────────────────────────
    public static func computePrognose(_ input: PrognoseInput) -> PrognoseResult {
        var steps: [CalculationStep] = []
        let cd = input.caseData

        // Schritt 1: Prior
        let rechtsgebiet = cd?.rechtsgebiet ?? "default"
        let baseRate = RECHTSGEBIET_BASERATES[rechtsgebiet] ?? RECHTSGEBIET_BASERATES["default"]!
        let instanzKey = cd?.instanz.rawValue ?? "Erstinstanz"
        let instanzFaktor = INSTANZ_FAKTOR[instanzKey] ?? 1.0
        let adjustedBase = clamp(baseRate * instanzFaktor)
        steps.append(.init(
            kategorie: "Basis-Annahmen & Initialisierung",
            label: "Prior-Wahrscheinlichkeit (Basisrate)",
            formel: "P_basis = Basisrate(\(rechtsgebiet)) × Instanzfaktor(\(instanzKey))",
            wert: adjustedBase, einheit: nil,
            erklaerung: "Statistische Kläger-Gewinnrate im \(rechtsgebiet): \(Int(baseRate * 100))%. Instanzfaktor: \(String(format: "%.2f", instanzFaktor))."
        ))
        var logOdds = logit(adjustedBase)

        // Schritt 2: Argumente
        let eigene = input.args.filter { $0.side == .eigen }
        let gegner = input.args.filter { $0.side == .gegner }
        let eS = eigene.map { ($0.kiStrength ?? $0.strength ?? 5) / 10 }
        let gS = gegner.map { ($0.kiStrength ?? $0.strength ?? 5) / 10 }
        let aE = eS.isEmpty ? 0.5 : avg(eS)
        let aG = gS.isEmpty ? 0.5 : avg(gS)
        let argDelta = aE - aG
        let argLOD = argDelta * 1.6
        logOdds += argLOD
        steps.append(.init(
            kategorie: "Inhaltliche Fallbewertung",
            label: "Argumentationsbilanz",
            formel: "Δ_arg = (Ø_eigen - Ø_gegner) × 1.6 = (\(String(format: "%.2f", aE)) - \(String(format: "%.2f", aG))) × 1.6",
            wert: argLOD, einheit: "Log-Odds",
            erklaerung: "Eigene (n=\(eigene.count), Ø=\(String(format: "%.1f", aE * 10))/10) vs. Gegner (n=\(gegner.count), Ø=\(String(format: "%.1f", aG * 10))/10)."
        ))

        // Schritt 3: Beweise
        let bG = input.evidence.map { ($0.kiWeight ?? $0.weight ?? 5) / 10 }
        let aB = bG.isEmpty ? 0.5 : avg(bG)
        let bC = input.evidence.count
        let bCB = bC > 0 ? log(Double(bC + 1)) / log(20) * 0.3 : 0
        let bQ  = (aB - 0.5) * 1.2 + bCB
        let bLOD = bQ * 1.0
        logOdds += bLOD
        steps.append(.init(
            kategorie: "Inhaltliche Fallbewertung",
            label: "Beweisqualität & -quantität",
            formel: "Δ_bew = [(Ø_Gewicht - 0.5) × 1.2 + log(n+1)/log(20) × 0.3] × 1.0",
            wert: bLOD, einheit: "Log-Odds",
            erklaerung: "\(bC) Beweismittel, Ø \(String(format: "%.1f", aB * 10))/10. Mengenbonus: \(String(format: "%.3f", bCB))."
        ))

        // Schritt 4: Richter
        let richter = input.persons.first { $0.role == .richter }
        var rLOD: Double = 0
        if let r = richter, let kr = r.klaegerRate {
            let rP = kr / 100
            let rD = logit(clamp(rP, 0.1, 0.9)) - logit(0.5)
            rLOD = rD * 0.4
            logOdds += rLOD
            steps.append(.init(
                kategorie: "Kontextuelle & Prozedurale Einflüsse",
                label: "Richter-Statistik (Bayesianisch)",
                formel: "Δ_richter = (logit(Klägerquote) - logit(0.5)) × 0.4",
                wert: rLOD, einheit: "Log-Odds",
                erklaerung: "Richter \(r.name): Klägerquote \(Int(kr))%. Bayes-Update Gewicht 0.4."
            ))
        } else {
            steps.append(.init(
                kategorie: "Kontextuelle & Prozedurale Einflüsse",
                label: "Richter-Statistik",
                formel: "Δ_richter = 0 (kein Richter bekannt)",
                wert: 0, einheit: "Log-Odds",
                erklaerung: "Kein Richter mit Statistiken erfasst."
            ))
        }

        // Schritt 5: Fristen
        let now = Date()
        let versaeumt = input.deadlines.filter { $0.status == .versaeumt && $0.side != .gegner }.count
        let kritisch  = input.deadlines.filter {
            guard $0.status == .offen, $0.side != .gegner else { return false }
            let d = $0.dueDate.timeIntervalSince(now) / 86400
            return d >= 0 && d <= 7
        }.count
        let fP = -(Double(versaeumt) * 0.4 + Double(kritisch) * 0.15)
        logOdds += fP
        steps.append(.init(
            kategorie: "Kontextuelle & Prozedurale Einflüsse",
            label: "Fristenrisiko (Malus)",
            formel: "Δ_fristen = -(versäumte × 0.4 + kritische × 0.15)",
            wert: fP, einheit: "Log-Odds",
            erklaerung: "\(versaeumt) versäumt, \(kritisch) kritisch <7 Tage."
        ))

        // Schritt 6: Vergleichsangebot
        if let cd = cd, let v = cd.vergleichsangebot, let sv = cd.streitwert, sv > 0 {
            let r = v / sv
            let vD = (r - 0.4) * 0.8
            logOdds += vD
            steps.append(.init(
                kategorie: "Kontextuelle & Prozedurale Einflüsse",
                label: "Vergleichsangebot-Signal",
                formel: "Δ_vgl = (Vergleich/Streitwert - 0.4) × 0.8",
                wert: vD, einheit: "Log-Odds",
                erklaerung: "\(formatEuro(v)) bei Streitwert \(formatEuro(sv)) (\(Int(r * 100))%). \(vD > 0 ? "Hohes Angebot signalisiert Unsicherheit." : "Niedriges Angebot deutet auf Stärke der Gegenseite hin.")"
            ))
        }

        // Final
        let pF = clamp(logistic(logOdds))
        steps.append(.init(
            kategorie: "Endgültige Prognose & Unsicherheit",
            label: "Finale Wahrscheinlichkeit (Logistische Transformation)",
            formel: "P_final = σ(log-Odds) = \(String(format: "%.1f", pF * 100))%",
            wert: pF, einheit: nil,
            erklaerung: "Summe aller Log-Odds, durch logistische Funktion in Wahrscheinlichkeit transformiert."
        ))

        // CI
        let argVar = variance(eS + gS)
        let bewVar = variance(bG)
        let rUns: Double = (richter?.klaegerRate != nil) ? 0.02 : 0.06
        let sigma = sqrt(pow(argVar * 0.35, 2) + pow(bewVar * 0.25, 2) + pow(rUns, 2) + pow(0.04, 2))
        let cL = clamp(pF - 1.645 * sigma)
        let cH = clamp(pF + 1.645 * sigma)
        steps.append(.init(
            kategorie: "Endgültige Prognose & Unsicherheit",
            label: "90%-Konfidenzintervall (Fehlerfortpflanzung)",
            formel: "σ = √(σ_arg² × 0.35² + σ_bew² × 0.25² + σ_richter² + 0.04²)",
            wert: sigma, einheit: nil,
            erklaerung: "CI = P ± 1.645 × σ = [\(String(format: "%.1f", cL * 100))%, \(String(format: "%.1f", cH * 100))%]"
        ))

        return PrognoseResult(
            score: Int((pF * 100).rounded()), scoreRaw: pF, logOdds: logOdds,
            ciLow: Int((cL * 100).rounded()), ciHigh: Int((cH * 100).rounded()),
            sigma: sigma, steps: steps,
            inputs: PrognoseInputCounts(
                eigeneArgs: eigene.count, gegnerArgs: gegner.count,
                beweise: input.evidence.count, fristen: input.deadlines.count,
                richterBekannt: richter?.klaegerRate != nil
            )
        )
    }

    // ─── runMonteCarlo ──────────────────────────────────────────────────
    public static func runMonteCarlo(baseResult: PrognoseResult, iterations: Int = 5_000) -> MonteCarloResult {
        var outcomes: [Double] = []; outcomes.reserveCapacity(iterations)
        for _ in 0..<iterations {
            outcomes.append(clamp(logistic(randn(baseResult.logOdds, sd: baseResult.sigma * 2.5))))
        }
        outcomes.sort()
        func p(_ pct: Double) -> Double {
            outcomes[max(0, min(outcomes.count - 1, Int((pct / 100) * Double(outcomes.count))))]
        }
        let mean = avg(outcomes)
        let p10 = p(10), p25 = p(25), p50 = p(50), p75 = p(75), p90 = p(90), p80 = p(80)
        var hist: [MonteCarloHistogramBin] = []
        for i in 0..<20 {
            let lo = Double(i) * 0.05, hi = (Double(i) + 1) * 0.05
            let c = outcomes.filter { $0 >= lo && $0 < hi }.count
            hist.append(.init(bin: "\(Int((lo * 100).rounded()))%", count: c, pct: lo + 0.025))
        }
        return MonteCarloResult(
            mean: Int((mean * 100).rounded()),
            p10:  Int((p10  * 100).rounded()),
            p25:  Int((p25  * 100).rounded()),
            median: Int((p50 * 100).rounded()),
            p75:  Int((p75  * 100).rounded()),
            p90:  Int((p90  * 100).rounded()),
            histogram: hist, iterations: iterations,
            bestCase:  .init(wahrscheinlichkeit: 100 - Int((p80 * 100).rounded()),
                             schwelle: Int((p80 * 100).rounded()),
                             erklaerung: "Alle Faktoren entwickeln sich günstig (oberes Quintil)"),
            baseCase:  .init(wahrscheinlichkeit: Int((p50 * 100).rounded()), schwelle: nil,
                             erklaerung: "Median-Szenario: Faktoren entwickeln sich wie erwartet"),
            worstCase: .init(wahrscheinlichkeit: Int((p10 * 100).rounded()), schwelle: nil,
                             erklaerung: "Pessimistisches Szenario (unteres Dezil)")
        )
    }

    // ─── computeRisikoFaktoren – 8 Dimensionen ────────────────────────
    public static func computeRisikoFaktoren(_ input: PrognoseInput) -> RisikoResult {
        let eigene = input.args.filter { $0.side == .eigen }
        let gegner = input.args.filter { $0.side == .gegner }
        let richter = input.persons.first { $0.role == .richter }
        let cd = input.caseData
        var faktoren: [RisikoFaktor] = []

        // 1. Beweis
        let bG = input.evidence.map { $0.kiWeight ?? $0.weight ?? 5 }
        let aB = bG.isEmpty ? 3 : avg(bG)
        let bV = variance(bG)
        let bR = clamp(1 - aB / 10 + bV / 100)
        let bS = Int((bR * 10).rounded())
        faktoren.append(.init(key: "beweis_risiko", score: bS,
            level: bS <= 3 ? .niedrig : (bS <= 6 ? .mittel : .hoch),
            bewertung: "\(input.evidence.count) Beweismittel, Ø \(String(format: "%.1f", aB))/10, σ²=\(String(format: "%.1f", bV))",
            massnahme: bS > 6 ? "Zusätzliche Beweismittel sichern" : (bS > 3 ? "Beweisqualität via Sachverständigengutachten stärken" : "Beweislage solide"),
            formel: "Risiko = 1 - Ø/10 + σ²/100 = \(String(format: "%.3f", bR))"))

        // 2. Richter
        var rS = 5; var rE = "Kein Richter erfasst – neutral"
        var rF = "Score = 5 (Standardwert)"
        if let r = richter {
            let kr = r.klaegerRate ?? 50
            let vr = r.vergleichRate ?? 30
            rS = Int((clamp(1 - kr / 100) * 10).rounded())
            rE = "Richter \(r.name): Klägerquote \(Int(kr))%, Vergleich \(Int(vr))%"
            rF = "Risiko = (1 - Klägerquote/100) = \(String(format: "%.2f", 1 - kr / 100))"
        }
        faktoren.append(.init(key: "richter_risiko", score: rS,
            level: rS <= 3 ? .niedrig : (rS <= 6 ? .mittel : .hoch),
            bewertung: rE,
            massnahme: rS > 6 ? "Vergleichsbereitschaft signalisieren" : "Richterstatistik günstig",
            formel: rF))

        // 3. Recht
        let hC = !(cd?.zentraleRechtsfrage?.isEmpty ?? true)
        let aV = variance((eigene + gegner).map { $0.kiStrength ?? $0.strength ?? 5 })
        let recR = clamp(aV / 25 + (hC ? 0 : 0.2))
        let recS = Int((recR * 10).rounded())
        faktoren.append(.init(key: "rechts_risiko", score: recS,
            level: recS <= 3 ? .niedrig : (recS <= 6 ? .mittel : .hoch),
            bewertung: "Argumentation σ²=\(String(format: "%.1f", aV)); zentrale Rechtsfrage: \(hC ? "definiert" : "offen")",
            massnahme: recS > 5 ? "Rechtsprechungsrecherche vertiefen" : "Rechtslage klar definiert",
            formel: "Risiko = σ²/25 + (keine_Rechtsfrage ? 0.2 : 0) = \(String(format: "%.3f", recR))"))

        // 4. Kosten
        var kS = 5; var kF = "Kein Streitwert angegeben"
        var kE = "Streitwert unbekannt – Standardrisiko"
        if let sv = cd?.streitwert, sv > 0 {
            let g = cd?.gebuehrenstufe ?? 1.3
            let basis = rvgGebuehr(streitwert: sv)
            let gK = basis * g * 2 + (cd?.svKosten ?? 0) + (cd?.reisekosten ?? 0)
            let r = gK / sv
            kS = Int((clamp(r * 2) * 10).rounded())
            kF = "Kosten ≈ \(formatEuro(basis)) × \(g) × 2 + SV + Reise = \(formatEuro(gK))"
            kE = "Kostenquote: \(String(format: "%.1f", r * 100))% des Streitwerts"
        }
        faktoren.append(.init(key: "kosten_risiko", score: kS,
            level: kS <= 3 ? .niedrig : (kS <= 6 ? .mittel : .hoch),
            bewertung: kE,
            massnahme: kS > 6 ? "Prozesskostenrisiko kritisch – Vergleich erwägen" : "Kostenstruktur akzeptabel",
            formel: kF))

        // 5. Zeit
        let now = Date()
        let v = input.deadlines.filter { $0.status == .versaeumt && $0.side != .gegner }.count
        let o = input.deadlines.filter { $0.status == .offen }.count
        let k = input.deadlines.filter {
            guard $0.status == .offen else { return false }
            let d = $0.dueDate.timeIntervalSince(now) / 86400
            return d >= 0 && d <= 14
        }.count
        let zR = clamp(Double(v) * 0.2 + Double(k) * 0.1 + (o > 5 ? 0.1 : 0))
        let zS = Int((zR * 10).rounded())
        faktoren.append(.init(key: "zeit_risiko", score: zS,
            level: zS <= 2 ? .niedrig : (zS <= 5 ? .mittel : .hoch),
            bewertung: "\(v) versäumt, \(k) kritisch (<14 T), \(o) offen",
            massnahme: zS > 5 ? "Sofortige Fristenprüfung – Wiedereinsetzung" : (zS > 2 ? "Kritische Fristen überwachen" : "Fristen unter Kontrolle"),
            formel: "Risiko = v×0.2 + k×0.1 + (o>5 ? 0.1 : 0) = \(String(format: "%.3f", zR))"))

        // 6. Gegner
        let aGS = gegner.isEmpty ? 5 : avg(gegner.map { $0.kiStrength ?? $0.strength ?? 5 })
        let gR = clamp(aGS / 10 + (gegner.count > 3 ? 0.1 : 0))
        let gS = Int((gR * 10).rounded())
        faktoren.append(.init(key: "gegner_risiko", score: gS,
            level: gS <= 3 ? .niedrig : (gS <= 6 ? .mittel : .hoch),
            bewertung: "\(gegner.count) Gegnerargumente, Ø \(String(format: "%.1f", aGS))/10",
            massnahme: gS > 6 ? "Gegenargumente entkräften, Kontranarrative entwickeln" : "Gegnerstärke moderat",
            formel: "Risiko = Ø/10 + (n>3 ? 0.1 : 0) = \(String(format: "%.3f", gR))"))

        // 7. Reputation
        let repM: [String: Double] = ["Strafrecht": 0.8, "Familienrecht": 0.5, "Arbeitsrecht": 0.4, "default": 0.25]
        let repB = repM[cd?.rechtsgebiet ?? "default"] ?? repM["default"]!
        let svF: Double = (cd?.streitwert ?? 0) > 500_000 ? 0.2 : ((cd?.streitwert ?? 0) > 100_000 ? 0.1 : 0)
        let repR = clamp(repB + svF)
        let repS = Int((repR * 10).rounded())
        faktoren.append(.init(key: "reputation_risiko", score: repS,
            level: repS <= 3 ? .niedrig : (repS <= 5 ? .mittel : .hoch),
            bewertung: "Rechtsgebiet \(cd?.rechtsgebiet ?? "unbekannt"), SW-Faktor +\(Int(svF * 100))%",
            massnahme: repS > 5 ? "Medien-/PR-Strategie abstimmen" : "Niedrige Exponierung",
            formel: "Risiko = \(repB) + \(svF) = \(String(format: "%.2f", repR))"))

        // 8. Vergleichschance
        let vR = richter?.vergleichRate ?? 30
        let pProz = cd?.prognose ?? 50
        let unG = 1 - abs(pProz / 100 - 0.5) * 2
        let vC = clamp(unG * 0.5 + vR / 100 * 0.5)
        let vS = Int((vC * 10).rounded())
        faktoren.append(.init(key: "vergleich_chance", score: vS,
            level: vS >= 7 ? .niedrig : (vS >= 4 ? .mittel : .hoch),
            bewertung: "Ungewissheit: \(Int(unG * 100))%, Vergleichsrate Richter: \(Int(vR))%",
            massnahme: vS > 6 ? "Vergleichsgespräche aktiv anstreben" : (vS > 3 ? "Vergleich offen halten" : "Geringe Vergleichswahrscheinlichkeit"),
            formel: "Chance = U×0.5 + Vergl.×0.5 = \(String(format: "%.3f", vC))"))

        let scores = faktoren.filter { $0.key != "vergleich_chance" }.map { Double($0.score) }
        let g = avg(scores)
        let lvl: RisikoLevel = g <= 3.5 ? .niedrig : (g <= 5.5 ? .mittel : .hoch)
        return RisikoResult(faktoren: faktoren, gesamtrisiko: lvl,
                            gesamtScore: (g * 10).rounded() / 10)
    }

    // ─── computeBreakEven ─────────────────────────────────────────────
    public static func computeBreakEven(caseData: Case?) -> BreakEvenResult? {
        guard let cd = caseData, let sv = cd.streitwert, sv > 0 else { return nil }
        let g = cd.gebuehrenstufe ?? 1.3
        let basis = rvgGebuehr(streitwert: sv)
        let eK = basis * g, gK = basis * g
        let svK = cd.svKosten ?? 0, rK = cd.reisekosten ?? 0
        let geK: Double = sv <= 5000 ? 150 : (sv <= 50_000 ? 500 : 1500)
        let total = eK + gK + svK + rK + geK
        let bP = total / (sv + total)
        let bePct = Int((clamp(bP) * 100).rounded())

        let svS = sv * 1.4, beS = Int((clamp(total / (svS + total)) * 100).rounded())
        let svV = sv * 1.08, beV = Int((clamp(total / (svV + total)) * 100).rounded())
        let vfW = sv * 1.2, beVf = Int((clamp(total / (vfW + total)) * 100).rounded())
        let smW = sv * 2.0, beSm = Int((clamp(total / (smW + total)) * 100).rounded())

        let zusatz: [ZusatzOption] = [
            .init(titel: "Schadensersatz (inkl. immateriell & entgangener Gewinn)",
                  symbol: "💰",
                  beschreibung: "Materieller + immaterieller Schaden + entgangener Gewinn. Effektiver Wert ca. 1.4× = \(formatEuro(svS)).",
                  breakEvenPct: beS, basis: formatEuro(svS),
                  rechtsgrundlage: "§§ 249 ff. BGB, § 253 BGB"),
            .init(titel: "Verzugszinsen & Prozesszinsen",
                  symbol: "📈",
                  beschreibung: "Verzugszinsen (5% / 9% über Basiszins) ab Mahnung. Bei 2 J. ≈ \(formatEuro(svV)).",
                  breakEvenPct: beV, basis: formatEuro(svV),
                  rechtsgrundlage: "§ 288 BGB, § 291 BGB"),
            .init(titel: "Verfassungsbeschwerde / Grundrechtsklage",
                  symbol: "⚖️",
                  beschreibung: "Bei Grundrechtsverletzung. Strategiewert 1.2× = \(formatEuro(vfW)).",
                  breakEvenPct: beVf, basis: "Strategiewert ca. \(formatEuro(vfW))",
                  rechtsgrundlage: "Art. 93 Abs. 1 Nr. 4a GG, §§ 90 ff. BVerfGG"),
            .init(titel: "Sammelklage / Verbandsklage (mehrere Betroffene)",
                  symbol: "👥",
                  beschreibung: "Mehrere Mandanten bündeln Streitwerte. Bei 5 Mitklägern ≈ \(formatEuro(smW)).",
                  breakEvenPct: beSm, basis: "Gesamtstreitwert ca. \(formatEuro(smW))",
                  rechtsgrundlage: "§ 606 ZPO, VDuG")
        ]
        let empf = bePct > 60 ? "⚠️ Hohes Kostenrisiko. Vergleich dringend erwägen."
                : bePct > 40 ? "Klage sinnvoll bei >50% Erfolgschance."
                : "✅ Kostenstruktur günstig – Klage wirtschaftlich."

        return BreakEvenResult(
            breakEvenPct: bePct,
            gesamtkosten: Int(total.rounded()),
            eigeneKosten: Int(eK.rounded()), gegnerKosten: Int(gK.rounded()),
            gerichtkosten: Int(geK), svKosten: Int(svK), reiseKosten: Int(rK),
            formel: "P_min = \(Int(total)) / \(Int(sv + total)) = \(bePct)%",
            erklaerung: "Bei Sieg werden alle Kosten vom Gegner erstattet. Klage lohnt ab \(bePct)%.",
            empfehlung: empf, zusatzoptionen: zusatz
        )
    }

    // ─── computeVollanalyse ───────────────────────────────────────────
    public static func computeVollanalyse(_ input: PrognoseInput) -> VollanalyseResult? {
        let p = computePrognose(input)
        let r = computeRisikoFaktoren(input)
        let mc = runMonteCarlo(baseResult: p)
        guard let be = computeBreakEven(caseData: input.caseData) else { return nil }
        return VollanalyseResult(prognose: p, risikofaktoren: r, monteCarlo: mc, breakEven: be,
                                 timestamp: Date(), version: "1.2.0")
    }

    // ─── Backwards-compatible Helpers ─────────────────────────────────
    public static func prognose(arguments: [Argument]) -> Double {
        let e = arguments.filter { $0.side == .eigen }
        let g = arguments.filter { $0.side == .gegner }
        let eS = e.reduce(0.0) { $0 + ($1.kiStrength ?? $1.strength ?? 5) }
        let gS = g.reduce(0.0) { $0 + ($1.kiStrength ?? $1.strength ?? 5) }
        let total = eS + gS
        guard total > 0 else { return 50 }
        return min(95, max(5, eS / total * 100))
    }
    public static func prognoseMitFristen(base: Double, deadlines: [Deadline]) -> Double {
        let v = deadlines.filter { $0.status == .versaeumt && $0.side == .eigene }.count
        return max(5, base - Double(v) * 8)
    }
    public static func argumentScore(_ arg: Argument, evidence: [Evidence]) -> Double {
        let eW = evidence.filter { $0.argumentId == arg.id }.map { $0.kiWeight ?? $0.weight ?? 5 }.reduce(0, +)
        let base = arg.kiStrength ?? arg.strength ?? 5
        let bonus = min(3, eW / 10)
        let pen = arg.isContradiction ? 2.0 : 0
        return max(0, min(10, base + bonus - pen))
    }
    public struct VergleichEmpfehlung: Hashable {
        public let prozessErwartet: Double, vergleichErwartet: Double, empfehlung: String
    }
    public static func vergleichsEmpfehlung(streitwert: Double, gebuehren: Double,
                                            svKosten: Double, reisekosten: Double,
                                            prognosePct: Double,
                                            vergleichsangebot: Double?) -> VergleichEmpfehlung {
        let g = prognosePct / 100
        let pE = (streitwert * g) - (gebuehren + svKosten + reisekosten) * (1 - g)
        let v = vergleichsangebot ?? (streitwert * 0.5)
        let emp: String
        if v > pE * 1.05 { emp = "Vergleich annehmen (höherer Erwartungswert)." }
        else if pE > v * 1.15 { emp = "Prozess weiterführen (deutlich höherer Erwartungswert)." }
        else { emp = "Erwartungswerte ähnlich – Risikoabwägung mit Mandant." }
        return .init(prozessErwartet: pE, vergleichErwartet: v, empfehlung: emp)
    }
    public static func fristStatus(_ d: Deadline, today: Date = Date()) -> String {
        if d.status == .erledigt { return "Erledigt" }
        if d.status == .versaeumt { return "Versäumt" }
        let diff = Calendar.current.dateComponents([.day], from: today, to: d.dueDate).day ?? 0
        if diff < 0 { return "Überfällig" }
        if diff < 3 { return "Kritisch" }
        if diff < 14 { return "Demnächst" }
        return "Geplant"
    }
}
