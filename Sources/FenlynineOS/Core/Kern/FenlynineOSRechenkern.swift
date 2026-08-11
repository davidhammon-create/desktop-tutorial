import Foundation

// MARK: - Deterministischer Rechenkern (PDF Teil 2 & 6 -- einmalig, alle Module)

enum FenlynineOSRechenkern {

struct OptionBerechnung: Codable, Hashable {
  var ev: Double
  var rav: Double
  var risk: Double
  var var95: Double
  var rpn: Double
  var sharpe: Double
  var kelly: Double
  var breakEven: Double
  var herleitung: [String]
}

struct TornadoEintrag: Identifiable, Hashable {
  let id = UUID()
  let parameter: String
  let deltaEV: Double
}

// EV = P(Erfolg)xGewinn + P(Misserfolg)xVerlust - Kosten
static func ev(pErfolg: Double, gewinn: Double, verlust: Double, kosten: Double) -> Double {
  let p = clamp(pErfolg)
  return p * gewinn + (1 - p) * verlust - kosten
}

// RAV = EV / (1+r)^t
static func rav(ev: Double, diskont: Double = 0.05, jahre: Double = 1) -> Double {
  ev / pow(1 + diskont, jahre)
}

// Risk = S(P_negativ x Verlust_negativ) + Kosten
static func risk(pNegativ: [Double], verlustNegativ: [Double], kosten: Double) -> Double {
  let n = min(pNegativ.count, verlustNegativ.count)
  var sum = kosten
  for i in 0..<n { sum += clamp(pNegativ[i]) * verlustNegativ[i] }
  return sum
}

// VaR » Quantil der Verlustverteilung
static func var95(verluste: [Double]) -> Double {
  guard !verluste.isEmpty else { return 0 }
  let sorted = verluste.sorted()
  let idx = Int(Double(sorted.count - 1) * 0.95)
  return sorted[min(idx, sorted.count - 1)]
}

// RPN = A x B x E
static func rpn(a: Int, b: Int, e: Int) -> Int { a * b * e }

// Sharpe = (EV - r_f) / s
static func sharpe(ev: Double, risikofrei: Double = 0.02, sigma: Double) -> Double {
  guard sigma > 0 else { return 0 }
  return (ev - risikofrei) / sigma
}

// Kelly = (pxb - q) / b
static func kelly(p: Double, gewinn: Double, verlust: Double) -> Double {
  guard gewinn > 0 else { return 0 }
  let b = gewinn / max(1, abs(verlust))
  let q = 1 - clamp(p)
  return (clamp(p) * b - q) / b
}

// P_break-even = (Verlust+Kosten)/(Gewinn+Verlust)
static func breakEven(gewinn: Double, verlust: Double, kosten: Double) -> Double {
  let denom = gewinn + abs(verlust)
  guard denom > 0 else { return 1 }
  return (abs(verlust) + kosten) / denom
}

static func berechneOption(
  pErfolg: Double, gewinn: Double, verlust: Double, kosten: Double,
  a: Int = 5, b: Int = 5, e: Int = 5, sigma: Double = 0.15
) -> OptionBerechnung {
  let evVal = ev(pErfolg: pErfolg, gewinn: gewinn, verlust: verlust, kosten: kosten)
  let ravVal = rav(ev: evVal)
  let riskVal = risk(pNegativ: [1 - pErfolg], verlustNegativ: [abs(verlust)], kosten: kosten)
  let varVal = var95(verluste: [abs(verlust) * (1 - pErfolg), kosten])
  let rpnVal = Double(rpn(a: a, b: b, e: e))
  let sharpeVal = sharpe(ev: evVal, sigma: sigma)
  let kellyVal = kelly(p: pErfolg, gewinn: gewinn, verlust: verlust)
  let beVal = breakEven(gewinn: gewinn, verlust: verlust, kosten: kosten)
  return OptionBerechnung(
    ev: evVal, rav: ravVal, risk: riskVal, var95: varVal,
    rpn: rpnVal, sharpe: sharpeVal, kelly: kellyVal, breakEven: beVal,
    herleitung: [
      "EV = \(fmt(pErfolg))x\(fmt(gewinn)) + \(fmt(1-pErfolg))x\(fmt(verlust)) - \(fmt(kosten)) = \(fmt(evVal))",
      "RAV = EV/(1+r) = \(fmt(ravVal))",
      "RPN = AxBxE = \(a)x\(b)x\(e) = \(rpn(a: a, b: b, e: e))",
      "Sharpe = \(fmt(sharpeVal))", "Kelly = \(fmt(kellyVal))", "Break-Even = \(fmt(beVal))"
    ]
  )
}

static func tornado(
 basis: OptionBerechnung,
 pErfolg: Double, gewinn: Double, verlust: Double, kosten: Double,
 delta: Double = 0.05
) -> [TornadoEintrag] {
 let bEV = basis.ev
 return [
   TornadoEintrag(parameter: "P(Erfolg)", deltaEV: ev(pErfolg: pErfolg + delta, gewinn: gewinn, verlust: verlust, kosten: kosten) - bEV),
   TornadoEintrag(parameter: "Gewinn", deltaEV: ev(pErfolg: pErfolg, gewinn: gewinn * 1.1, verlust: verlust, kosten: kosten) - bEV),
   TornadoEintrag(parameter: "Verlust", deltaEV: ev(pErfolg: pErfolg, gewinn: gewinn, verlust: verlust * 1.1, kosten: kosten) - bEV),
   TornadoEintrag(parameter: "Kosten", deltaEV: ev(pErfolg: pErfolg, gewinn: gewinn, verlust: verlust, kosten: kosten * 1.1) - bEV)
 ].sorted { abs($0.deltaEV) > abs($1.deltaEV) }
}

// Kanten-Effekte auf Knoten anwenden
static func wendeKanteAn(knoten: inout FenlynineOSKernKnoten, kante: FenlynineOSKernKante, quell: FenlynineOSKernKnoten) {
 switch kante.typ {
 case .aendert_p_erfolg:
   if let d = Double(kante.payload["delta"] ?? ""), var p = knoten.pErfolg {
     knoten.pErfolg = clamp(p + d)
   }
 case .erhoeht_risiko:
   if let d = Double(kante.payload["delta"] ?? "0.15") {
     knoten.a = min(10, (knoten.a ?? 5) + Int(d * 10))
     knoten.rpn = Double(rpn(a: knoten.a ?? 5, b: knoten.b ?? 5, e: knoten.e ?? 5))
   }
 case .senkt_risiko:
   knoten.a = max(1, (knoten.a ?? 5) - 1)
   knoten.rpn = Double(rpn(a: knoten.a ?? 5, b: knoten.b ?? 5, e: knoten.e ?? 5))
 case .begruendet, .widerlegt:
   if kante.typ == .widerlegt, var p = knoten.pErfolg { knoten.pErfolg = clamp(p - 0.05) }
   else if var p = knoten.pErfolg { knoten.pErfolg = clamp(p + 0.03) }
 case .verschiebt_frist:
   if let t = Int(kante.payload["tage"] ?? "0") { knoten.tageRestlauf = (knoten.tageRestlauf ?? 0) + t }
 case .bedingt, .uebergibt:
   knoten.status = .aktiv
 }
 _ = quell
 neuBerechnen(&knoten)
}

static func neuBerechnen(_ knoten: inout FenlynineOSKernKnoten) {
 guard knoten.typ == .option else {
   if knoten.typ == .risiko {
     knoten.rpn = Double(rpn(a: knoten.a ?? 5, b: knoten.b ?? 5, e: knoten.e ?? 5))
   }
   return
 }
 let p = knoten.pErfolg ?? 0.5
 let g = knoten.gewinn ?? 100_000
 let v = knoten.verlust ?? -50_000
 let k = knoten.kosten ?? 10_000
 let b = berechneOption(pErfolg: p, gewinn: g, verlust: v, kosten: k, a: knoten.a ?? 5, b: knoten.b ?? 5, e: knoten.e ?? 5)
 knoten.ev = b.ev; knoten.rav = b.rav; knoten.rpn = b.rpn
}

private static func clamp(_ v: Double) -> Double { min(1, max(0, v)) }
private static func fmt(_ v: Double) -> String { String(format: "%.2f", v) }
}

