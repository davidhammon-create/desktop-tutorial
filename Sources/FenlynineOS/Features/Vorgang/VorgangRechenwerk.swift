import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// RECHENWERK -- erweiterte Mathematik neben der Formelkaskade
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Deterministisch (fester Seed), reproduzierbar, keine KI.
// Monte-Carlo-Verteilung · Zertitätsäquivalent (Risikonutzen) ·
// Vergleichskorridor (ZOPA) mit Ankerempfehlung · Fristrisiko.
// Jede Kennzahl trägt ihre Formel als Quelle (WertMitHerkunft).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum Rechenwerk {

// MARK: - Deterministischer Zufallsgenerator (reproduzierbar)

/// SplitMix64 -- fester Seed, damit identische Eingaben identische
/// Ergebnisse liefern (Anspruch „Formel", nicht „Zufall").
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

// MARK: - Monte-Carlo-Simulation

struct MonteCarloErgebnis {
  let laeufe: Int
  let p10: WertMitHerkunft // pessimistisches Dezil
  let median: WertMitHerkunft
  let p90: WertMitHerkunft // optimistisches Dezil
  let gewinnQuote: WertMitHerkunft // P(Ergebnis > 0)
  let zertitaet: WertMitHerkunft // Zertitätsäquivalent (risikoavers)
  let modell: String
}

/// Simuliert die Ergebnisverteilung einer Option.
///
/// Modell: Dreiecksverteilung X ~ Tri(worst, m, best) - Kosten,
/// deren Modus m so gewählt ist, dass E[X] dem Erwartungswert der
/// Formelkaskade entspricht (Konsistenz der beiden Rechenwege).
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
  // Modus aus Mittelwert-Konsistenz: E[Tri] = (a+m+b)/3
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

  // Zertitätsäquivalent mit exponentiellem Nutzen:
  // CE = -(1/l)·ln( E[ e^(-lX) ] ), l skaliert auf die Spannweite.
  let spann = max(1, b - a)
  let lambda = max(1e-9, risikoAversion) / spann
  var expSum = 0.0
  for x in proben { expSum += exp(-lambda * x) }
  let ce = proben.isEmpty ? 0 : -(1 / lambda) * log(expSum / Double(proben.count))

  let modell = "Tri(\(fmt(a)), \(fmt(m)), \(fmt(b))) - \(fmt(kosten)) · n=\(laeufe) · Seed fest"

  return MonteCarloErgebnis(
    laeufe: laeufe,
    p10: .formel(quantil(0.10), "P10 der Monte-Carlo-Verteilung · \(modell)"),
    median: .formel(quantil(0.50), "Median der Monte-Carlo-Verteilung · \(modell)"),
    p90: .formel(quantil(0.90), "P90 der Monte-Carlo-Verteilung · \(modell)"),
    gewinnQuote: .formel(quote, "P(X > 0) = \(gewinner)/\(laeufe) Simulationen"),
    zertitaet: .formel(ce, "CE = -(1/l)·ln E[e^(-lX)], l = \(String(format: "%.2g", lambda)) (risikoavers)"),
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

// MARK: - Vergleichskorridor (ZOPA)

struct Vergleichskorridor {
 /// Unter dieser Summe ist der Prozess (risikoadjustiert) besser.
 let untergrenze: WertMitHerkunft
 /// Geschätzte Schmerzgrenze der Gegenseite.
 let obergrenze: WertMitHerkunft
 /// Empfohlener Eröffnungsanker in der Verhandlung.
 let anker: WertMitHerkunft
 /// false = Korridor leer -> Vergleich derzeit unattraktiv.
 let existiert: Bool
}

/// Verhandlungskorridor aus eigener risikoadjustierter Sicht und
/// einer konservativen Schätzung der Gegenseite.
///
/// Untergrenze = Zertitätsäquivalent (unser Walk-away).
/// Obergrenze = P(Erfolg) x best + Kostenersparnis der Gegenseite
///     (Annahme: Gegner kalkuliert spiegelbildlich und
///     spart bei Einigung eigene Verfahrenskosten).
/// Anker = Untergrenze + 0,7 x Korridorbreite (Ankereffekt).
static func vergleichskorridor(_ o: VorgangOption, risikoAversion: Double = 0.5) -> Vergleichskorridor {
 let mc = monteCarlo(o, risikoAversion: risikoAversion)
 let p = o.chancen.pErfolg.wert
 let best = o.chancen.best.wert
 let kosten = o.kosten.summe

 let unten = mc.zertitaet.wert
 let oben = p * best + kosten
 let existiert = oben > unten

 let anker = existiert ? unten + 0.7 * (oben - unten) : unten

 return Vergleichskorridor(
   untergrenze: .formel(unten, "Walk-away = Zertitätsäquivalent (Monte-Carlo, risikoavers)"),
   obergrenze: .formel(oben, "Schmerzgrenze Gegner » P x best + Kostenersparnis = \(fmt(p)) x \(fmt(best)) + \(fmt(kosten))"),
   anker: .formel(anker, existiert
     ? "Anker = Untergrenze + 0,7 x Korridorbreite (Ankereffekt)"
     : "Kein Korridor -- Prozessfortsetzung dominiert derzeit"),
   existiert: existiert
 )
}

// MARK: - Fristen-Risikowert

/// Risiko-Score einer Frist (0-100): Nähe x Kritikalität.
/// Rein deterministisch -- Grundlage der Fristenwache-Sortierung.
static func fristRisiko(tageBisAblauf: Int, kritisch: Bool) -> WertMitHerkunft {
 let naehe: Double
 switch tageBisAblauf {
 case ..<0: naehe = 100
 case 0...3: naehe = 90
 case 4...7: naehe = 75
 case 8...14: naehe = 55
 case 15...30: naehe = 35
 default: naehe = 15
 }
 let score = min(100, naehe * (kritisch ? 1.25 : 1.0))
 return .formel(score, "Fristrisiko = Nähe(\(tageBisAblauf) T) x \(kritisch ? "1,25 (kritisch)" : "1,0")")
}

private static func fmt(_ x: Double) -> String {
 String(format: "%.2f", x)
}
}

