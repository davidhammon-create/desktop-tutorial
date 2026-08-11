import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// DER MOTOR -- EINER, NICHT FÜNF (Prozessarchitektur, Teil III · C)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Es sind nicht zwei Workflows. Es ist einer. Der Typ bestimmt die
// Schritte, Formeln und Pflichtfelder." (PDF S. 14)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Die 9 Schritte

enum VorgangSchritt: String, Codable, CaseIterable, Identifiable {
case problem
case kiAnalyse = "ki"
case optionen
case details
case vergleich
case argumente
case risiko
case fristen
case empfehlung

var id: String { rawValue }

var bezeichnung: String {
  switch self {
  case .problem: return "Problem"
  case .kiAnalyse: return "KI-Analyse"
  case .optionen: return "Optionen"
  case .details: return "Details"
  case .vergleich: return "Vergleich"
  case .argumente: return "Argumente"
  case .risiko: return "Risiko"
  case .fristen: return "Fristen"
  case .empfehlung: return "Empfehlung"
  }
}

var symbol: String {
  switch self {
  case .problem: return "questionmark.circle"
  case .kiAnalyse: return "sparkles"
  case .optionen: return "list.bullet.rectangle"
  case .details: return "square.and.pencil"
  case .vergleich: return "chart.bar.doc.horizontal"
  case .argumente: return "text.bubble"
  case .risiko: return "exclamationmark.triangle"
  case .fristen: return "calendar"
  case .empfehlung: return "checkmark.seal"
  }
}
}

// MARK: - Formel-Bausteine

enum FormelBaustein: String, Codable {
case ev // Erwartungswert
case rav // Risikoadjustierter Wert
case var95
case var99
case rpn
case sharpe
case kelly
case breakEven = "break_even"
case portfolioEV = "portfolio_ev"
case korrelation
case rvg
case gkg
}

// MARK: - Fristenlogik-Konfiguration

enum FristenLogik: String, Codable {
case bgbVerjaehrung // Streit -> §§ 195, 199 BGB
case ao   // Steuerrecht -> AO
case kschg // Kündigungsschutz -> § 4 KSchG
case vertragsfristen // Gestaltung
case portfolio // Programm-Übergreifend
}

// MARK: - Typkonfiguration (VORGANGSTYPEN, PDF S. 14-15)

struct VorgangsTypKonfiguration {
let typ: VorgangTyp
let schritte: [VorgangSchritt]
let formeln: [FormelBaustein]
let pflichtfelder: [String]
let fristenLogik: FristenLogik
let gebuehren: String
let basiertAuf: VorgangTyp? // z.B. verhandlung basiert_auf: streit
let ansicht: String // z.B. "kompakt_live" für Advocatus
let aufnahmeErlaubt: Bool // Advocatus IMMER false (§ 201 StGB)

/// Sichtbare Schritte in der aktuellen Ansicht (Advocatus: nur 2).
var sichtbareSchritte: [VorgangSchritt] {
  if typ == .verhandlung {
    return [.optionen, .empfehlung]
  }
  return schritte
}
}

// MARK: - Der Motor (Registry der Typen)

enum VorgangMotor {
static let streit = VorgangsTypKonfiguration(
 typ: .streit,
 schritte: VorgangSchritt.allCases,
 formeln: [.ev, .rav, .var95, .var99, .rpn, .sharpe, .breakEven],
 pflichtfelder: ["gegner", "streitwert", "gerichtsstand"],
 fristenLogik: .bgbVerjaehrung,
 gebuehren: "RVG_GKG",
 basiertAuf: nil,
 ansicht: "standard",
 aufnahmeErlaubt: false
)

static let gestaltung = VorgangsTypKonfiguration(
 typ: .gestaltung,
 schritte: VorgangSchritt.allCases,
 formeln: [.ev, .rav, .var95, .var99, .rpn, .sharpe, .kelly, .breakEven],
 pflichtfelder: ["vertragspartner", "volumen", "laufzeit"],
 fristenLogik: .vertragsfristen,
 gebuehren: "Honorar",
 basiertAuf: nil,
 ansicht: "standard",
 aufnahmeErlaubt: false
)

static let verhandlung = VorgangsTypKonfiguration(
 typ: .verhandlung,
 schritte: [.optionen, .empfehlung],
 formeln: [.ev, .rav],
 pflichtfelder: [],
 fristenLogik: .bgbVerjaehrung,
 gebuehren: "",
 basiertAuf: .streit,
 ansicht: "kompakt_live",
 aufnahmeErlaubt: false // § 201 StGB -- NIEMALS true, in keiner Version
)

static let programm = VorgangsTypKonfiguration(
 typ: .programm,
 schritte: [.problem, .optionen, .vergleich, .risiko, .empfehlung],
 formeln: [.kelly, .portfolioEV, .korrelation],
 pflichtfelder: ["ziel", "budget"],
 fristenLogik: .portfolio,
 gebuehren: "",
 basiertAuf: nil,
 ansicht: "portfolio",
 aufnahmeErlaubt: false
)

static func konfiguration(fuer typ: VorgangTyp) -> VorgangsTypKonfiguration {
 switch typ {
 case .streit: return streit
 case .gestaltung: return gestaltung
 case .verhandlung: return verhandlung
 case .programm: return programm
 }
}
}

// MARK: - Formel-Kaskade (der Burggraben -- PDF S. 27, Regel: nie KI!)

enum Formelkaskade {

/// EV = P x Gewinn + (1-P) x Verlust - Kosten
static func erwartungswert(_ o: VorgangOption) -> WertMitHerkunft {
 let p = o.chancen.pErfolg.wert
 let best = o.chancen.best.wert
 let worst = o.chancen.worst.wert
 let kosten = o.kosten.summe
 let ev = p * best + (1 - p) * worst - kosten
 let formel = "EV = \(fmt(p)) x \(fmt(best)) + \(fmt(1 - p)) x \(fmt(worst)) - \(fmt(kosten))"
 return .init(wert: ev, herkunft: .formel, quelle: formel)
}

/// RAV = EV / (1 + r)^t -- Diskontfaktor r = 0.05, t in Jahren.
static func rav(_ o: VorgangOption, ev: Double, diskont r: Double = 0.05) -> WertMitHerkunft {
 let t = Double(o.zeit.maxMonate) / 12.0
 let rav = ev / pow(1 + r, t)
 let formel = "RAV = EV / (1 + \(fmt(r)))^\(fmt(t)) = \(fmt(ev)) / \(fmt(pow(1 + r, t)))"
 return .init(wert: rav, herkunft: .formel, quelle: formel)
}

/// VaR -- sehr vereinfacht (95 %-Quantil » worst-case gewichtet).
static func varAt(_ o: VorgangOption, quantil: Double = 0.95) -> WertMitHerkunft {
 let worst = o.chancen.worst.wert
 let kosten = o.kosten.summe
 let value = min(0, worst - kosten) * quantil
 return .init(wert: value, herkunft: .formel, quelle: "VaR\(Int(quantil*100)) » \(fmt(worst)) - \(fmt(kosten))")
}

/// Break-Even Wahrscheinlichkeit -- ab welcher P(Erfolg) wird EV = 0?
static func breakEven(_ o: VorgangOption) -> WertMitHerkunft {
 let best = o.chancen.best.wert
 let worst = o.chancen.worst.wert
 let kosten = o.kosten.summe
 // P x best + (1-P) x worst - kosten = 0 -> P = (kosten - worst) / (best - worst)
 guard best != worst else { return .init(wert: 0, herkunft: .formel, quelle: "n/a") }
 let p = (kosten - worst) / (best - worst)
 return .init(wert: p, herkunft: .formel, quelle: "Pn = (kosten - worst) / (best - worst)")
}

/// Sharpe (grob) -- EV / s, wobei s » (best - worst)/4.
static func sharpe(_ o: VorgangOption, ev: Double) -> WertMitHerkunft {
 let sigma = max(1, (o.chancen.best.wert - o.chancen.worst.wert) / 4.0)
 return .init(wert: ev / sigma, herkunft: .formel, quelle: "Sharpe = EV / s")
}

/// Kelly-Anteil = P - (1-P)/b, b = best/|worst|
static func kelly(_ o: VorgangOption) -> WertMitHerkunft {
 let p = o.chancen.pErfolg.wert
 let worstAbs = max(1, abs(o.chancen.worst.wert))
 let b = o.chancen.best.wert / worstAbs
 let k = max(0, p - (1 - p) / max(b, 0.01))
 return .init(wert: k, herkunft: .formel, quelle: "Kelly = P - (1-P)/b, b = best/|worst|")
}

/// RPN-Summe der Risiken.
static func rpnGesamt(_ o: VorgangOption) -> Int {
 o.risiken.reduce(0) { $0 + $1.rpn }
}

/// Wendet die gesamte Kaskade auf eine Option an. NUR HIER!
/// (Der Rest des Systems liest, schreibt nicht.)
static func bewerte(_ option: inout VorgangOption) {
 let ev = erwartungswert(option)
 option.bewertung.ev = ev
 option.bewertung.rav = rav(option, ev: ev.wert)
 option.bewertung.var95 = varAt(option, quantil: 0.95)
 option.bewertung.var99 = varAt(option, quantil: 0.99)
 option.bewertung.sharpe = sharpe(option, ev: ev.wert)
 option.bewertung.kelly = kelly(option)
 option.bewertung.breakEven = breakEven(option)
 option.bewertung.rpnGesamt = rpnGesamt(option)
}

/// Portfolio-EV -- Summe der EVs mit einfacher Korrelationskorrektur.
static func portfolioEV(_ vorgaenge: [Vorgang]) -> (roh: Double, bereinigt: Double) {
 let evs = vorgaenge.flatMap { $0.optionen.compactMap { $0.bewertung.ev?.wert } }
 let roh = evs.reduce(0, +)
 // Sehr einfache Bereinigung: bei > 2 Vorgängen im selben Rechtsgebiet Klumpenrisiko-Abschlag.
 let gruppen = Dictionary(grouping: vorgaenge, by: { $0.rechtsgebiet })
 let klumpen = gruppen.values.filter { $0.count > 2 }.count
 let bereinigt = roh * (1 - Double(klumpen) * 0.08)
 return (roh, bereinigt)
}

// MARK: - RVG-Rechner (100 % Formel, PDF S. 12 Abb. 12)

struct RvgErgebnis {
 let verfahren: Double
 let termin: Double
 let auslagen: Double
 let ust: Double
 var gesamt: Double { verfahren + termin + auslagen + ust }
}

/// Sehr grobe RVG-Berechnung nach § 13 RVG (vereinfachte Tabelle).
static func rvg(streitwert: Double) -> RvgErgebnis {
 let sw = max(500, streitwert)
 // Grobe Näherung der Wertgebühr (§ 13 RVG)
 let einfach: Double
 switch sw {
 case ..<2_000: einfach = 149
 case ..<5_000: einfach = 334
 case ..<10_000: einfach = 614
 case ..<25_000: einfach = 964
 case ..<50_000: einfach = 1_534
 case ..<100_000: einfach = 2_197
 case ..<200_000: einfach = 3_167
 default: einfach = 4_137
 }
 let verfahren = einfach * 1.3
 let termin = einfach * 1.2
 let auslagen = 20.0 + (verfahren + termin) * 0.03
 let ust = (verfahren + termin + auslagen) * 0.19
 return .init(verfahren: verfahren, termin: termin, auslagen: auslagen, ust: ust)
}

// MARK: - Fristen (100 % Formel)

/// § 4 KSchG -- 3 Wochen ab Zugang.
static func klageFristKSchG(zugang: Date) -> VorgangFrist {
 let datum = Calendar.current.date(byAdding: .day, value: 21, to: zugang) ?? zugang
 let tage = Calendar.current.dateComponents([.day], from: .init(), to: datum).day ?? 0
 return .init(
   datum: datum,
   art: "Klagefrist § 4 KSchG",
   kritisch: tage < 14,
   quelle: "§ 4 S. 1 KSchG (3 Wochen ab Zugang)"
 )
}

/// § 195 BGB -- Regelverjährung 3 Jahre.
static func verjaehrungBGB(entstehung: Date) -> VorgangFrist {
 let datum = Calendar.current.date(byAdding: .year, value: 3, to: entstehung) ?? entstehung
 let tage = Calendar.current.dateComponents([.day], from: .init(), to: datum).day ?? 0
 return .init(
   datum: datum,
   art: "Regelverjährung § 195 BGB",
   kritisch: tage < 60,
   quelle: "§§ 195, 199 BGB"
 )
}

// MARK: - Kipppunkt-Analyse (PDF Abb. 11)

/// Sensitivitätsanalyse -- an welcher Reglerposition wechselt das Ranking?
/// Gibt Prozentwert (0..1) zurück, an dem das führende Element wechselt.
static func kipppunkt(optionen: [VorgangOption], gewichtungRoh: Double = 0.5,
         szenario: (VorgangOption, Double) -> Double) -> Double? {
 guard optionen.count >= 2 else { return nil }
 var last = ranking(optionen: optionen, gewicht: 0, szenario: szenario).first?.id
 var step = 0.01
 var g = 0.0
 while g <= 1.0 {
   let r = ranking(optionen: optionen, gewicht: g, szenario: szenario).first?.id
   if r != last { return g }
   last = r
   g += step
 }
 _ = step
 return nil
}

private static func ranking(optionen: [VorgangOption], gewicht g: Double,
             szenario: (VorgangOption, Double) -> Double) -> [VorgangOption] {
 optionen.sorted { szenario($0, g) > szenario($1, g) }
}

private static func fmt(_ x: Double) -> String {
 String(format: "%.2f", x)
}
}

