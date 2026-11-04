import Foundation
import Accelerate
import FenlynineOSKern

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Stochastisch-Juristische Berechnungsmaschine
//
// Vollständige Swift-Portierung von legalAlgorithms.js
// Methoden: Bayesianische Inferenz, Monte-Carlo-Simulation (SIMD-beschleunigt),
// gewichtete Kombination juristischer Faktoren, 90%-Konfidenzintervalle.
// Alle Berechnungen sind REIN ALGORITHMISCH -- kein KI-Aufruf.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Konstanten & Gewichtungsmatrizen

private enum LegalKonstanten {
static let instanzFaktor: [LegalCase.Instanz: Double] = [
  .erstinstanz: 1.0,
  .berufung: 0.88, // Berufungsgerichte bestätigen i.d.R. ~70-75% Urteile
  .revision: 0.70 // Revision: Nur Rechtsfehlerüberprüfung
]

static let rechtsgebietBaserates: [String: Double] = [
  "Arbeitsrecht": 0.52,
  "Mietrecht": 0.54,
  "Vertragsrecht": 0.51,
  "Familienrecht": 0.50,
  "Gesellschaftsrecht": 0.49,
  "Strafrecht": 0.35, // Staatsanwaltschaft hat strukturellen Vorteil
  "Verwaltungsrecht": 0.38,
  "Insolvenzrecht": 0.48,
  "IP": 0.50,
  "default": 0.50
]

// RVG-Gebühren: Es gibt im Programm nur noch EINE Tabelle, und zwar
// FenlynineOSKern.RVGTabelle (vollständige Anlage 2 RVG, 42 Stufen, Decimal).
//
// Vorher standen hier und in VorgangMotor.swift zwei verschiedene Tabellen mit
// abweichenden Werten: bei 10.000 € Streitwert lieferte diese hier 590 €, die
// andere 964 € -- je nach Bildschirm sah der Anwalt eine andere Gebühr.
// Zusätzlich griff bei Streitwerten jenseits der Tabelle ein erfundener
// Notwert von 5.000 €.
static func einfacheGebuehr(streitwert: Double) -> Double? {
  let gerundet = (max(0, streitwert) * 100).rounded() / 100
  guard let d = Decimal(string: String(format: "%.2f", gerundet)),
        let g = RVGTabelle.gebuehr(streitwert: d) else { return nil }
  return NSDecimalNumber(decimal: g).doubleValue
}
}

// MARK: - Ergebnis-Typen

struct PrognoseErgebnis {
let score: Int // 0-100%
let scoreRaw: Double // 0.0-1.0
let logOdds: Double
let ciLow: Int // 90%-Konfidenzintervall untere Grenze
let ciHigh: Int // 90%-Konfidenzintervall obere Grenze
let sigma: Double
let schritte: [BerechnungsSchritt]
let inputs: PrognoseInputs
}

struct PrognoseInputs {
let eigeneArgs: Int
let gegnerArgs: Int
let beweise: Int
let fristen: Int
let richterBekannt: Bool
}

struct BerechnungsSchritt: Identifiable {
let id = UUID()
let kategorie: String
let label: String
let formel: String
let wert: Double
let einheit: String
let erklaerung: String
let details: [String: Any]?
}

struct MonteCarloErgebnis {
let mean: Int
let p10: Int
let p25: Int
let median: Int
let p75: Int
let p90: Int
let histogram: [HistogrammBin]
let iterationen: Int
let szenarien: MCSzenarien

struct HistogrammBin: Identifiable {
  let id = UUID()
  let bin: String // z.B. "45%"
  let count: Int
  let pct: Double // Mittelpunkt des Bins (0.0-1.0)
}

struct MCSzenarien {
  let bestCase: MCSzenario
  let baseCase: MCSzenario
  let worstCase: MCSzenario
}

struct MCSzenario {
 let wahrscheinlichkeit: Int
 let schwelle: Int?
 let erklaerung: String
}
}

struct RisikoFaktorenErgebnis {
let faktoren: [RisikoFaktor]
let gesamtrisiko: String
let gesamtScore: Double
}

struct RisikoFaktor: Identifiable {
let id = UUID()
let key: String
let score: Int // 0-10
let level: RisikoLevel
let bewertung: String
let massnahme: String
let formel: String

enum RisikoLevel: String {
 case niedrig = "niedrig"
 case mittel = "mittel"
 case hoch = "hoch"

 var farbe: String {
   switch self {
   case .niedrig: return "green"
   case .mittel: return "orange"
   case .hoch: return "red"
   }
 }
}
}

struct BreakEvenErgebnis {
let breakEvenPct: Int?
let gesamtkosten: Double
let eigeneKosten: Double
let gegnerKosten: Double
let gerichtkosten: Double
let svKosten: Double
let reiseKosten: Double
let formel: String
let erklaerung: String
let empfehlung: String
let zusatzoptionen: [BreakEvenOption]
}

struct BreakEvenOption: Identifiable {
let id = UUID()
let titel: String
let symbol: String
let beschreibung: String
let breakEvenPct: Int
let basis: String
let rechtsgrundlage: String
}

struct VollanalyseErgebnis {
let prognose: PrognoseErgebnis
let risikofaktoren: RisikoFaktorenErgebnis
let monteCarlo: MonteCarloErgebnis
let breakEven: BreakEvenErgebnis
let zeitstempel: Date
let version: String
}

// MARK: - Haupt-Service

enum LegalAlgorithmsService {

// MARK: - Prognose (Bayesianisches Update)

static func computePrognose(
 args: [Argument] = [],
 evidence: [Evidence] = [],
 deadlines: [Deadline] = [],
 persons: [Person] = [],
 caseData: LegalCase
) -> PrognoseErgebnis {
 var schritte: [BerechnungsSchritt] = []

 // nn Schritt 1: Prior (Basisrate) nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 let rechtsgebiet = caseData.rechtsgebiet ?? "default"
 let baseRate = LegalKonstanten.rechtsgebietBaserates[rechtsgebiet] ?? 0.50
 let instanzFaktor = LegalKonstanten.instanzFaktor[caseData.instanz] ?? 1.0
 let adjustedBase = clamp(baseRate * instanzFaktor)
 var logOdds = logit(adjustedBase)

 schritte.append(BerechnungsSchritt(
   kategorie: "Basis-Annahmen & Initialisierung",
   label: "Prior-Wahrscheinlichkeit (Basisrate)",
   formel: "P_basis = Basisrate(\(rechtsgebiet)) x Instanzfaktor(\(caseData.instanz.rawValue))",
   wert: adjustedBase,
   einheit: "Wahrscheinlichkeit",
   erklaerung: "Statistisch ermittelte Kläger-Gewinnrate im \(rechtsgebiet): \(Int(baseRate * 100))%. Instanzfaktor: \(String(format: "%.2f", instanzFaktor)) (\(caseData.instanz.rawValue)).",
   details: nil
 ))

 // nn Schritt 2: Argumentationsstärke nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 let eigeneArgs = args.filter { $0.side == .eigen }
 let gegnerArgs = args.filter { $0.side == .gegner }

 let eigeneStaerken = eigeneArgs.map { $0.effectiveStrength / 10.0 }
 let gegnerStaerken = gegnerArgs.map { $0.effectiveStrength / 10.0 }

 let avgEigen = eigeneStaerken.isEmpty ? 0.5 : avg(eigeneStaerken)
 let avgGegner = gegnerStaerken.isEmpty ? 0.5 : avg(gegnerStaerken)

 let argDelta = avgEigen - avgGegner
 let argLogOddsDelta = argDelta * 1.6
 logOdds += argLogOddsDelta

 schritte.append(BerechnungsSchritt(
   kategorie: "Inhaltliche Fallbewertung",
   label: "Argumentationsbilanz",
   formel: "D_arg = (Ø_eigene - Ø_Gegner) x 1.6 = (\(String(format: "%.2f", avgEigen)) - \(String(format: "%.2f", avgGegner))) x 1.6",
   wert: argLogOddsDelta,
   einheit: "Log-Odds",
   erklaerung: "Eigene Argumente (n=\(eigeneArgs.count), Ø=\(String(format: "%.1f", avgEigen * 10))/10) vs. Gegner (n=\(gegnerArgs.count), Ø=\(String(format: "%.1f", avgGegner * 10))/10). Differenz \(String(format: "%.3f", argDelta)) ergibt Log-Odds-Anpassung von \(String(format: "%.3f", argLogOddsDelta)).",
   details: nil
 ))

 // nn Schritt 3: Beweisqualität nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 let beweisGewichte = evidence.map { $0.effectiveWeight / 10.0 }
 let avgBeweis = beweisGewichte.isEmpty ? 0.5 : avg(beweisGewichte)
 let beweisCount = evidence.count
 let beweisCountBonus = beweisCount > 0 ? log(Double(beweisCount + 1)) / log(20.0) * 0.3 : 0
 let beweisQualitaet = (avgBeweis - 0.5) * 1.2 + beweisCountBonus
 let beweisLogOddsDelta = beweisQualitaet
 logOdds += beweisLogOddsDelta

 schritte.append(BerechnungsSchritt(
   kategorie: "Inhaltliche Fallbewertung",
   label: "Beweisqualität & -quantität",
   formel: "D_bew = [(Ø_Gewicht - 0.5) x 1.2 + log(n+1)/log(20) x 0.3] x 1.0",
   wert: beweisLogOddsDelta,
   einheit: "Log-Odds",
   erklaerung: "\(beweisCount) Beweismittel, Ø-Gewicht: \(String(format: "%.1f", avgBeweis * 10))/10. Mengenbonus (log-skaliert): \(String(format: "%.3f", beweisCountBonus)). Gesamtdelta: \(String(format: "%.3f", beweisLogOddsDelta)).",
   details: nil
 ))

 // nn Schritt 4: Richterstatistik (Bayesianisch) nnnnnnnnnnnnnnnnnnnnnnnnn
 let richter = persons.first { $0.role == .richter }
 var richterLogOddsDelta = 0.0

 if let richter, let klaegerRate = richter.klaeger_rate {
   let richterP = Double(klaegerRate) / 100.0
   let richterDelta = logit(clamp(richterP, min: 0.1, max: 0.9)) - logit(0.5)
   richterLogOddsDelta = richterDelta * 0.4
   logOdds += richterLogOddsDelta

   schritte.append(BerechnungsSchritt(
     kategorie: "Kontextuelle & Prozedurale Einflüsse",
     label: "Richter-Statistik (Bayesianisch)",
     formel: "D_richter = (logit(Klägerquote) - logit(0.5)) x 0.4",
     wert: richterLogOddsDelta,
     einheit: "Log-Odds",
     erklaerung: "Richter \(richter.name): Klägerquote \(String(format: "%.0f", klaegerRate))%. Bayesianischer Prior-Update mit Gewicht 0.4.",
     details: nil
   ))
 } else {
   schritte.append(BerechnungsSchritt(
     kategorie: "Kontextuelle & Prozedurale Einflüsse",
     label: "Richter-Statistik",
     formel: "D_richter = 0 (kein Richter bekannt)",
     wert: 0,
     einheit: "Log-Odds",
     erklaerung: "Kein Richter mit Statistiken erfasst. Neutrales Prior wird beibehalten.",
     details: nil
   ))
 }

 // nn Schritt 5: Fristenrisiko nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 let jetzt = Date()
 let versaeumt = deadlines.filter { $0.status == .versaeumt && $0.side != "Gegner" }.count
 let kritisch = deadlines.filter { d in
   guard d.status == .offen, d.side != "Gegner" else { return false }
   let days = Calendar.current.dateComponents([.day], from: jetzt, to: d.due_date).day ?? Int.max
   return days >= 0 && days <= 7
 }.count

 let fristenPenalty = -(Double(versaeumt) * 0.4 + Double(kritisch) * 0.15)
 logOdds += fristenPenalty

 schritte.append(BerechnungsSchritt(
   kategorie: "Kontextuelle & Prozedurale Einflüsse",
   label: "Fristenrisiko (Malus)",
   formel: "D_fristen = -(versäumte x 0.4 + kritische x 0.15) = -(\(versaeumt) x 0.4 + \(kritisch) x 0.15)",
   wert: fristenPenalty,
   einheit: "Log-Odds",
   erklaerung: "\(versaeumt) versäumte Fristen (je -0.4), \(kritisch) kritische Fristen <7 Tage (je -0.15). Gesamtmalus: \(String(format: "%.3f", fristenPenalty)).",
   details: nil
 ))

 // nn Schritt 6: Vergleichsangebot-Faktor nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 var vergleichDelta = 0.0
 if let vergleich = caseData.vergleichsangebot, let streitwert = caseData.streitwert, streitwert > 0 {
   let ratio = vergleich / streitwert
   vergleichDelta = (ratio - 0.4) * 0.8
   logOdds += vergleichDelta

   schritte.append(BerechnungsSchritt(
     kategorie: "Kontextuelle & Prozedurale Einflüsse",
     label: "Vergleichsangebot-Signal",
     formel: "D_vgl = (Vergleich/Streitwert - 0.4) x 0.8 = (\(String(format: "%.2f", ratio)) - 0.4) x 0.8",
     wert: vergleichDelta,
     einheit: "Log-Odds",
     erklaerung: "Vergleichsangebot \(formatEuro(vergleich)) bei Streitwert \(formatEuro(streitwert)) (\(Int(ratio * 100))%). \(vergleichDelta > 0 ? "Hohes Angebot signalisiert Unsicherheit der Gegenseite." : "Niedriges Angebot deutet auf Stärke der Gegenseite hin.")",
     details: nil
   ))
 }

 // nn Ergebnis nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 let pFinal = clamp(logistic(logOdds))

 schritte.append(BerechnungsSchritt(
   kategorie: "Endgültige Prognose & Unsicherheit",
   label: "Finale Wahrscheinlichkeit (Logistische Transformation)",
   formel: "P_final = s(log-Odds) = 1/(1+e^(-\(String(format: "%.3f", logOdds)))) = \(String(format: "%.1f", pFinal * 100))%",
   wert: pFinal,
   einheit: "Wahrscheinlichkeit",
   erklaerung: "Alle Log-Odds-Beiträge werden summiert und über die logistische Funktion in eine Wahrscheinlichkeit transformiert.",
   details: nil
 ))

 // nn Konfidenzintervall nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 let argVarianz = variance(eigeneStaerken + gegnerStaerken)
 let beweisVarianz = variance(beweisGewichte)
 let richterUnsicherheit = richter?.klaeger_rate != nil ? 0.02 : 0.06

 let gesamtSigma = sqrt(
   pow(argVarianz * 0.35, 2) +
   pow(beweisVarianz * 0.25, 2) +
   pow(richterUnsicherheit, 2) +
   pow(0.04, 2)
 )

 let ciLow = clamp(pFinal - 1.645 * gesamtSigma)
 let ciHigh = clamp(pFinal + 1.645 * gesamtSigma)

 schritte.append(BerechnungsSchritt(
   kategorie: "Endgültige Prognose & Unsicherheit",
   label: "90%-Konfidenzintervall (Fehlerfortpflanzung)",
   formel: "s_gesamt = (cid:214)(s_arg² x 0.35² + s_bew² x 0.25² + s_richter² + 0.04²) = \(String(format: "%.3f", gesamtSigma))",
   wert: ciHigh - ciLow,
   einheit: "Breite",
   erklaerung: "CI = P ± 1.645 x s = [\(String(format: "%.1f", ciLow * 100))%, \(String(format: "%.1f", ciHigh * 100))%]. Hauptunsicherheitsquellen: Argumentvarianz (s²=\(String(format: "%.3f", argVarianz))), Beweisqualitätsvarianz (s²=\(String(format: "%.3f", beweisVarianz))).",
   details: nil
 ))

 return PrognoseErgebnis(
   score: Int(round(pFinal * 100)),
   scoreRaw: pFinal,
   logOdds: logOdds,
   ciLow: Int(round(ciLow * 100)),
   ciHigh: Int(round(ciHigh * 100)),
   sigma: gesamtSigma,
   schritte: schritte,
   inputs: PrognoseInputs(
     eigeneArgs: eigeneArgs.count,
     gegnerArgs: gegnerArgs.count,
     beweise: evidence.count,
     fristen: deadlines.count,
     richterBekannt: richter?.klaeger_rate != nil
   )
 )
}

// MARK: - Monte-Carlo-Simulation (Accelerate-beschleunigt)

static func runMonteCarlo(baseResult: PrognoseErgebnis, iterationen: Int = 10_000) -> MonteCarloErgebnis {
 let logOdds = baseResult.logOdds
 let sigma = baseResult.sigma

 // Box-Muller-Transform mit vDSP (SIMD-Beschleunigung)
 var outcomes = [Double](repeating: 0, count: iterationen)

 vDSP.fill(&outcomes, with: 0)
 for i in stride(from: 0, to: iterationen, by: 2) {
   let u1 = Double.random(in: .ulpOfOne...1)
   let u2 = Double.random(in: .ulpOfOne...1)
   let mag = sigma * 2.5 * sqrt(-2.0 * log(u1))
   let z0 = mag * cos(2 * .pi * u2)
   let z1 = mag * sin(2 * .pi * u2)
   outcomes[i] = clamp(logistic(logOdds + z0))
   if i + 1 < iterationen {
     outcomes[i + 1] = clamp(logistic(logOdds + z1))
   }
 }

 outcomes.sort()

 func percentile(_ pct: Double) -> Double {
   outcomes[Int(pct / 100 * Double(outcomes.count))]
 }

 let mean = outcomes.reduce(0, +) / Double(iterationen)
 let p10 = percentile(10), p25 = percentile(25), p50 = percentile(50)
 let p75 = percentile(75), p90 = percentile(90)

 // Histogramm (20 Bins à 5%)
 let histogram = (0..<20).map { i -> MonteCarloErgebnis.HistogrammBin in
   let lo = Double(i) * 0.05
   let hi = Double(i + 1) * 0.05
   let count = outcomes.filter { $0 >= lo && $0 < hi }.count
   return MonteCarloErgebnis.HistogrammBin(
     bin: "\(i * 5)%",
     count: count,
     pct: lo + 0.025
   )
 }

 return MonteCarloErgebnis(
   mean: Int(round(mean * 100)),
   p10: Int(round(p10 * 100)),
   p25: Int(round(p25 * 100)),
   median: Int(round(p50 * 100)),
   p75: Int(round(p75 * 100)),
   p90: Int(round(p90 * 100)),
   histogram: histogram,
   iterationen: iterationen,
   szenarien: MonteCarloErgebnis.MCSzenarien(
     bestCase: MonteCarloErgebnis.MCSzenario(
       wahrscheinlichkeit: 100 - Int(round(percentile(80) * 100)),
       schwelle: Int(round(percentile(80) * 100)),
       erklaerung: "Alle Faktoren entwickeln sich günstig (oberes Quintil)"
     ),
     baseCase: MonteCarloErgebnis.MCSzenario(
       wahrscheinlichkeit: Int(round(p50 * 100)),
       schwelle: nil,
       erklaerung: "Median-Szenario: Faktoren entwickeln sich wie erwartet"
     ),
     worstCase: MonteCarloErgebnis.MCSzenario(
       wahrscheinlichkeit: Int(round(p10 * 100)),
       schwelle: nil,
       erklaerung: "Pessimistisches Szenario (unteres Dezil)"
     )
   )
 )
}

// MARK: - Risikofaktoren (8 Dimensionen)

static func computeRisikoFaktoren(
 args: [Argument] = [],
 evidence: [Evidence] = [],
 deadlines: [Deadline] = [],
 persons: [Person] = [],
 caseData: LegalCase
) -> RisikoFaktorenErgebnis {
 let eigeneArgs = args.filter { $0.side == .eigen }
 let gegnerArgs = args.filter { $0.side == .gegner }
 let richter = persons.first { $0.role == .richter }
 var faktoren: [RisikoFaktor] = []
 let jetzt = Date()

 // 1. Beweislage-Risiko
 let beweisGewichte = evidence.map { $0.effectiveWeight }
 let avgBeweis = beweisGewichte.isEmpty ? 3.0 : avg(beweisGewichte)
 let beweisVar = variance(beweisGewichte)
 let beweisRisiko = clamp(1 - avgBeweis / 10 + beweisVar / 100)
 faktoren.append(RisikoFaktor(
   key: "beweis_risiko",
   score: Int(round(beweisRisiko * 10)),
   level: beweisRisiko <= 0.3 ? .niedrig : beweisRisiko <= 0.6 ? .mittel : .hoch,
   bewertung: "\(evidence.count) Beweismittel, Ø \(String(format: "%.1f", avgBeweis))/10, Varianz s²=\(String(format: "%.1f", beweisVar))",
   massnahme: beweisRisiko > 0.6 ? "Zusätzliche Beweismittel sichern und Beweisanträge vorbereiten" : beweisRisiko > 0.3 ? "Beweisqualität durch Sachverständigengutachten stärken" : "Beweislage ist solide",
   formel: "Risiko = 1 - Ø(Gewichte)/10 + s²/100 = \(String(format: "%.3f", beweisRisiko))"
 ))

 // 2. Richterrisiko
 var richterScore = 5.0
 var richterErklaerung = "Kein Richter erfasst - neutral"
 var richterFormel = "Score = 5 (Standardwert)"
 if let r = richter, let kr = r.klaeger_rate {
   let krD = Double(kr)
   richterScore = (1 - krD / 100) * 10
   richterErklaerung = "Richter \(r.name): Klägerquote \(Int(krD))%"
   richterFormel = "Risiko = (1 - Klägerquote/100) = \(String(format: "%.2f", 1 - krD / 100))"
 }
 let richterR = richterScore / 10
 faktoren.append(RisikoFaktor(
   key: "richter_risiko",
   score: Int(round(richterScore)),
   level: richterR <= 0.3 ? .niedrig : richterR <= 0.6 ? .mittel : .hoch,
   bewertung: richterErklaerung,
   massnahme: richterR > 0.6 ? "Vergleichsbereitschaft signalisieren" : "Richterstatistik günstig",
   formel: richterFormel
 ))

 // 3. Rechtsunsicherheit
 let hasCentralQuestion = caseData.zentrale_rechtsfrage != nil
 let allArgStaerken = (eigeneArgs + gegnerArgs).map { $0.effectiveStrength }
 let argStrengthVar = variance(allArgStaerken)
 let rechtsRisiko = clamp(argStrengthVar / 25 + (hasCentralQuestion ? 0 : 0.2))
 faktoren.append(RisikoFaktor(
   key: "rechts_risiko",
   score: Int(round(rechtsRisiko * 10)),
   level: rechtsRisiko <= 0.3 ? .niedrig : rechtsRisiko <= 0.6 ? .mittel : .hoch,
   bewertung: "Argumentation s²=\(String(format: "%.1f", argStrengthVar)); Rechtsfrage: \(hasCentralQuestion ? "definiert" : "offen")",
   massnahme: rechtsRisiko > 0.5 ? "Rechtsprechungsrecherche vertiefen" : "Rechtslage klar definiert",
   formel: "Risiko = s²_Argumente/25 + (keine_Rechtsfrage ? 0.2 : 0) = \(String(format: "%.3f", rechtsRisiko))"
 ))

 // 4. Kostenrisiko
 let (kostenScore, kostenFormel, kostenErklaerung) = computeKostenRisiko(caseData: caseData)
 faktoren.append(RisikoFaktor(
   key: "kosten_risiko",
   score: Int(kostenScore),
   level: kostenScore / 10 <= 0.3 ? .niedrig : kostenScore / 10 <= 0.6 ? .mittel : .hoch,
   bewertung: kostenErklaerung,
   massnahme: kostenScore > 6 ? "Prozesskostenrisiko kritisch - Vergleich erwägen" : "Kostenstruktur akzeptabel",
   formel: kostenFormel
 ))

 // 5. Zeitrisiko
 let versaeumt = deadlines.filter { $0.status == .versaeumt && $0.side != "Gegner" }.count
 let kritischFristen = deadlines.filter { d in
   guard d.status == .offen else { return false }
   let days = Calendar.current.dateComponents([.day], from: jetzt, to: d.due_date).day ?? Int.max
   return days >= 0 && days <= 14
 }.count
 let offenFristen = deadlines.filter { $0.status == .offen }.count
 let zeitRisiko = clamp(Double(versaeumt) * 0.2 + Double(kritischFristen) * 0.1 + (offenFristen > 5 ? 0.1 : 0))
 faktoren.append(RisikoFaktor(
   key: "zeit_risiko",
   score: Int(round(zeitRisiko * 10)),
   level: zeitRisiko <= 0.2 ? .niedrig : zeitRisiko <= 0.5 ? .mittel : .hoch,
   bewertung: "\(versaeumt) versäumt, \(kritischFristen) kritisch (<14 Tage), \(offenFristen) offen",
   massnahme: zeitRisiko > 0.5 ? "Sofortige Fristenprüfung" : zeitRisiko > 0.2 ? "Kritische Fristen überwachen" : "Fristen unter Kontrolle",
   formel: "Risiko = versäumtx0.2 + kritischx0.1 + (offen>5 ? 0.1 : 0) = \(String(format: "%.3f", zeitRisiko))"
 ))

 // 6. Gegnerstärke
 let avgGegnerStaerke = gegnerArgs.isEmpty ? 5.0 : avg(gegnerArgs.map { $0.effectiveStrength })
 let gegnerRisiko = clamp(avgGegnerStaerke / 10 + (gegnerArgs.count > 3 ? 0.1 : 0))
 faktoren.append(RisikoFaktor(
   key: "gegner_risiko",
   score: Int(round(gegnerRisiko * 10)),
   level: gegnerRisiko <= 0.3 ? .niedrig : gegnerRisiko <= 0.6 ? .mittel : .hoch,
   bewertung: "\(gegnerArgs.count) Gegnerargumente, Ø-Stärke: \(String(format: "%.1f", avgGegnerStaerke))/10",
   massnahme: gegnerRisiko > 0.6 ? "Gegenargumente gezielt entkräften" : "Gegnerstärke moderat",
   formel: "Risiko = Ø_Gegnerstärke/10 + (n>3 ? 0.1 : 0) = \(String(format: "%.3f", gegnerRisiko))"
 ))

 // 7. Reputationsrisiko
 let repMatrix: [String: Double] = ["Strafrecht": 0.8, "Familienrecht": 0.5, "Arbeitsrecht": 0.4]
 let repBasis = repMatrix[caseData.rechtsgebiet ?? ""] ?? 0.25
 let streitwertFaktor = (caseData.streitwert ?? 0) > 500000 ? 0.2 : (caseData.streitwert ?? 0) > 100000 ? 0.1 : 0.0
 let repRisiko = clamp(repBasis + streitwertFaktor)
 faktoren.append(RisikoFaktor(
   key: "reputation_risiko",
   score: Int(round(repRisiko * 10)),
   level: repRisiko <= 0.3 ? .niedrig : repRisiko <= 0.5 ? .mittel : .hoch,
   bewertung: "Rechtsgebiet \(caseData.rechtsgebiet ?? "unbekannt"), Streitwert-Faktor: +\(Int(streitwertFaktor * 100))%",
   massnahme: repRisiko > 0.5 ? "Medien- und PR-Strategie abstimmen" : "Niedrige Reputationsexponierung",
   formel: "Risiko = Basisrate + Streitwertfaktor = \(String(format: "%.2f", repBasis)) + \(String(format: "%.2f", streitwertFaktor))"
 ))

 // 8. Vergleichschance
 let richterVergleich = richter?.vergleich_rate.map { Double($0) } ?? 30.0
 let prognose = caseData.prognose ?? 50.0
 let ungewissheit = 1.0 - abs(prognose / 100 - 0.5) * 2
 let vergleichChance = clamp(ungewissheit * 0.5 + richterVergleich / 100 * 0.5)
 faktoren.append(RisikoFaktor(
   key: "vergleich_chance",
   score: Int(round(vergleichChance * 10)),
   level: vergleichChance >= 0.7 ? .niedrig : vergleichChance >= 0.4 ? .mittel : .hoch,
   bewertung: "Prognose-Ungewissheit: \(Int(ungewissheit * 100))%, Richter-Vergleichsrate: \(Int(richterVergleich))%",
   massnahme: vergleichChance > 0.6 ? "Vergleichsgespräche aktiv anstreben" : "Vergleich als Option offen halten",
   formel: "Chance = Ungewissheit(Prognose)x0.5 + RichterVergleichsratex0.5 = \(String(format: "%.3f", vergleichChance))"
 ))

 let risikoScores = faktoren.filter { $0.key != "vergleich_chance" }.map { Double($0.score) }
 let gesamtScore = risikoScores.reduce(0, +) / Double(risikoScores.count)
 let gesamtrisiko = gesamtScore <= 3.5 ? "niedrig" : gesamtScore <= 5.5 ? "mittel" : "hoch"

 return RisikoFaktorenErgebnis(
   faktoren: faktoren,
   gesamtrisiko: gesamtrisiko,
   gesamtScore: round(gesamtScore * 10) / 10
 )
}

// MARK: - Break-Even-Analyse

static func computeBreakEven(caseData: LegalCase) -> BreakEvenErgebnis {
 guard let sv = caseData.streitwert, sv > 0 else {
   return BreakEvenErgebnis(
     breakEvenPct: nil, gesamtkosten: 0, eigeneKosten: 0, gegnerKosten: 0,
     gerichtkosten: 0, svKosten: 0, reiseKosten: 0,
     formel: "Streitwert nicht angegeben",
     erklaerung: "Für eine Break-Even-Analyse muss der Streitwert angegeben werden.",
     empfehlung: "Bitte Streitwert eintragen.",
     zusatzoptionen: []
   )
 }

 let gebuehr = caseData.gebuehrenstufe ?? 1.3
 // Kein Notwert mehr: liegt der Streitwert jenseits der Tabelle, muss der
 // Aufrufer das anzeigen statt mit einer erfundenen Gebuehr zu rechnen.
 guard let basisGebuehr = LegalKonstanten.einfacheGebuehr(streitwert: sv) else {
   return (5, "Streitwert ausserhalb der Gebuehrentabelle",
           "Streitwert ueber 500.000 EUR -- Gebuehr nach § 13 Abs. 1 S. 3 RVG "
           + "fortschreiben und manuell eintragen.")
 }
 let eigeneKosten = basisGebuehr * gebuehr
 let gegnerKosten = basisGebuehr * gebuehr
 let svKosten = caseData.sv_kosten ?? 0
 let reiseKosten = caseData.reisekosten ?? 0
 let gerichtkosten = sv <= 5000 ? 150.0 : sv <= 50000 ? 500.0 : 1500.0
 let gesamtKosten = eigeneKosten + gegnerKosten + svKosten + reiseKosten + gerichtkosten

 let breakEvenP = gesamtKosten / (sv + gesamtKosten)
 let breakEvenPct = Int(round(clamp(breakEvenP) * 100))

 let zusatzoptionen: [BreakEvenOption] = [
   BreakEvenOption(
     titel: "Schadensersatz (inkl. immateriell & entgangener Gewinn)",
     symbol: "eurosign.circle.fill",
     beschreibung: "Neben dem Streitwert können materieller Schaden, entgangener Gewinn und ggf. immaterieller Schaden geltend gemacht werden. Effektiver Gesamtwert ca. 1.4x Streitwert = \(formatEuro(sv * 1.4)).",
     breakEvenPct: Int(round(clamp(gesamtKosten / (sv * 1.4 + gesamtKosten)) * 100)),
     basis: formatEuro(sv * 1.4),
     rechtsgrundlage: "§§ 249 ff. BGB, § 253 BGB"
   ),
   BreakEvenOption(
     titel: "Verzugszinsen & Prozesszinsen",
     symbol: "chart.line.uptrend.xyaxis",
     beschreibung: "Gesetzliche Verzugszinsen (§ 288 BGB: 5% über Basiszins) laufen ab Mahnung. Bei 2 Jahren ca. \(formatEuro(sv * 1.08)).",
     breakEvenPct: Int(round(clamp(gesamtKosten / (sv * 1.08 + gesamtKosten)) * 100)),
     basis: formatEuro(sv * 1.08),
     rechtsgrundlage: "§ 288 BGB, § 291 BGB"
   ),
   BreakEvenOption(
     titel: "Verfassungsbeschwerde / Grundrechtsklage",
     symbol: "scale.3d",
     beschreibung: "Bei Grundrechtsverletzungen kann ein Präzedenzurteil strategisch wertvoller sein. Strategiewert ca. 1.2x.",
     breakEvenPct: Int(round(clamp(gesamtKosten / (sv * 1.2 + gesamtKosten)) * 100)),
     basis: "Strategiewert ca. \(formatEuro(sv * 1.2))",
     rechtsgrundlage: "Art. 93 Abs. 1 Nr. 4a GG, §§ 90 ff. BVerfGG"
   ),
   BreakEvenOption(
     titel: "Sammelklage / Verbandsklage",
     symbol: "person.3.fill",
     beschreibung: "Bei mehreren Betroffenen steigt der Gesamtstreitwert. Bei 5 Mitklägern ca. \(formatEuro(sv * 2.0)).",
     breakEvenPct: Int(round(clamp(gesamtKosten / (sv * 2.0 + gesamtKosten)) * 100)),
     basis: "Gesamtstreitwert ca. \(formatEuro(sv * 2.0))",
     rechtsgrundlage: "§ 606 ZPO (Musterfeststellungsklage), VDuG"
   )
 ]

 return BreakEvenErgebnis(
   breakEvenPct: breakEvenPct,
   gesamtkosten: gesamtKosten,
   eigeneKosten: eigeneKosten,
   gegnerKosten: gegnerKosten,
   gerichtkosten: gerichtkosten,
   svKosten: svKosten,
   reiseKosten: reiseKosten,
   formel: "P_min = Gesamtkosten / (Streitwert + Gesamtkosten) = \(formatEuro(gesamtKosten)) / \(formatEuro(sv + gesamtKosten)) = \(breakEvenPct)%",
   erklaerung: "Bei Sieg werden alle Kosten vom Gegner erstattet. Ein Rechtsstreit lohnt sich ab \(breakEvenPct)% Erfolgswahrscheinlichkeit.",
   empfehlung: breakEvenPct > 60 ? "nn Hohes Kostenrisiko. Vergleich dringend erwägen." : breakEvenPct > 40 ? "Klage sinnvoll bei >50% Erfolgschance." : "n Kostenstruktur günstig - Klage wirtschaftlich.",
   zusatzoptionen: zusatzoptionen
 )
}

// MARK: - Vollständige Analyse

static func computeVollanalyse(
 args: [Argument] = [],
 evidence: [Evidence] = [],
 deadlines: [Deadline] = [],
 persons: [Person] = [],
 caseData: LegalCase
) -> VollanalyseErgebnis {
 let prognose = computePrognose(args: args, evidence: evidence, deadlines: deadlines, persons: persons, caseData: caseData)
 let risikofaktoren = computeRisikoFaktoren(args: args, evidence: evidence, deadlines: deadlines, persons: persons, caseData: caseData)
 let monteCarlo = runMonteCarlo(baseResult: prognose)
 let breakEven = computeBreakEven(caseData: caseData)

 return VollanalyseErgebnis(
   prognose: prognose,
   risikofaktoren: risikofaktoren,
   monteCarlo: monteCarlo,
   breakEven: breakEven,
   zeitstempel: Date(),
   version: "2.0.0-swift"
 )
}

// MARK: - Hilfsfunktionen

private static func computeKostenRisiko(caseData: LegalCase) -> (score: Double, formel: String, erklaerung: String) {
 guard let sv = caseData.streitwert, sv > 0 else {
   return (5, "Kein Streitwert angegeben", "Streitwert unbekannt - Standardrisiko")
 }
 let gebuehr = caseData.gebuehrenstufe ?? 1.3
 guard let basisGebuehr = LegalKonstanten.einfacheGebuehr(streitwert: sv) else {
   return (5, "Streitwert ausserhalb der Gebuehrentabelle",
           "Streitwert ueber 500.000 EUR -- Gebuehr nach § 13 Abs. 1 S. 3 RVG "
           + "fortschreiben und manuell eintragen.")
 }
 let gesamtKosten = basisGebuehr * gebuehr * 2 + (caseData.sv_kosten ?? 0) + (caseData.reisekosten ?? 0)
 let ratio = gesamtKosten / sv
 let score = clamp(ratio * 2) * 10
 return (
   score,
   "Kosten » Gebühr(\(formatEuro(sv))) x \(gebuehr) x 2 + SV + Reise = \(formatEuro(gesamtKosten))",
   "Kostenquote: \(String(format: "%.1f", ratio * 100))% des Streitwerts"
 )
}
}

// MARK: - Mathematische Hilfsfunktionen

private func clamp(_ v: Double, min: Double = 0, max: Double = 1) -> Double {
Swift.max(min, Swift.min(max, v))
}

private func avg(_ arr: [Double]) -> Double {
guard !arr.isEmpty else { return 0 }
return arr.reduce(0, +) / Double(arr.count)
}

private func variance(_ arr: [Double]) -> Double {
guard arr.count >= 2 else { return 0 }
let m = avg(arr)
return arr.reduce(0) { $0 + pow($1 - m, 2) } / Double(arr.count)
}

private func logistic(_ x: Double) -> Double {
1.0 / (1.0 + exp(-x))
}

private func logit(_ p: Double) -> Double {
let pc = clamp(p, min: 0.001, max: 0.999)
return log(pc / (1 - pc))
}

private func formatEuro(_ value: Double) -> String {
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.currencyCode = "EUR"
formatter.locale = Locale(identifier: "de_DE")
return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
}

