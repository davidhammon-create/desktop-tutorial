import Foundation
import FenlynineOSKern
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
enum FristenLogik: String, Codable {
case bgbVerjaehrung // Streit -> §§ 195, 199 BGB
case ao   // Steuerrecht -> AO
case kschg // Kündigungsschutz -> § 4 KSchG
case vertragsfristen // Gestaltung
case portfolio // Programm-Übergreifend
}
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
var sichtbareSchritte: [VorgangSchritt] {
  if typ == .verhandlung {
    return [.optionen, .empfehlung]
  }
  return schritte
}
}
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
enum Formelkaskade {
static func erwartungswert(_ o: VorgangOption) -> WertMitHerkunft {
 let p = o.chancen.pErfolg.wert
 let best = o.chancen.best.wert
 let worst = o.chancen.worst.wert
 let kosten = o.kosten.summe
 let ev = p * best + (1 - p) * worst - kosten
 let formel = "EV = \(fmt(p)) x \(fmt(best)) + \(fmt(1 - p)) x \(fmt(worst)) - \(fmt(kosten))"
 return .init(wert: ev, herkunft: .formel, quelle: formel)
}
static func rav(_ o: VorgangOption, ev: Double, diskont r: Double = 0.05) -> WertMitHerkunft {
 let t = Double(o.zeit.maxMonate) / 12.0
 let rav = ev / pow(1 + r, t)
 let formel = "RAV = EV / (1 + \(fmt(r)))^\(fmt(t)) = \(fmt(ev)) / \(fmt(pow(1 + r, t)))"
 return .init(wert: rav, herkunft: .formel, quelle: formel)
}
static func varAt(_ o: VorgangOption, quantil: Double = 0.95) -> WertMitHerkunft {
 let worst = o.chancen.worst.wert
 let kosten = o.kosten.summe
 let value = min(0, worst - kosten) * quantil
 return .init(wert: value, herkunft: .formel, quelle: "VaR\(Int(quantil*100)) » \(fmt(worst)) - \(fmt(kosten))")
}
static func breakEven(_ o: VorgangOption) -> WertMitHerkunft {
 let best = o.chancen.best.wert
 let worst = o.chancen.worst.wert
 let kosten = o.kosten.summe
 guard best != worst else { return .init(wert: 0, herkunft: .formel, quelle: "n/a") }
 let p = (kosten - worst) / (best - worst)
 return .init(wert: p, herkunft: .formel, quelle: "Pn = (kosten - worst) / (best - worst)")
}
static func sharpe(_ o: VorgangOption, ev: Double) -> WertMitHerkunft {
 let sigma = max(1, (o.chancen.best.wert - o.chancen.worst.wert) / 4.0)
 return .init(wert: ev / sigma, herkunft: .formel, quelle: "Sharpe = EV / s")
}
static func kelly(_ o: VorgangOption) -> WertMitHerkunft {
 let p = o.chancen.pErfolg.wert
 let worstAbs = max(1, abs(o.chancen.worst.wert))
 let b = o.chancen.best.wert / worstAbs
 let k = max(0, p - (1 - p) / max(b, 0.01))
 return .init(wert: k, herkunft: .formel, quelle: "Kelly = P - (1-P)/b, b = best/|worst|")
}
static func rpnGesamt(_ o: VorgangOption) -> Int {
 o.risiken.reduce(0) { $0 + $1.rpn }
}
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
static func portfolioEV(_ vorgaenge: [Vorgang]) -> (roh: Double, bereinigt: Double) {
 let evs = vorgaenge.flatMap { $0.optionen.compactMap { $0.bewertung.ev?.wert } }
 let roh = evs.reduce(0, +)
 let gruppen = Dictionary(grouping: vorgaenge, by: { $0.rechtsgebiet })
 let klumpen = gruppen.values.filter { $0.count > 2 }.count
 let bereinigt = roh * (1 - Double(klumpen) * 0.08)
 return (roh, bereinigt)
}
struct RvgErgebnis {
 let einfach: Double
 let verfahren: Double
 let termin: Double
 let auslagen: Double
 let ust: Double
 var gesamt: Double { verfahren + termin + auslagen + ust }
}
static func rvg(streitwert: Double) -> RvgErgebnis {
 let gerundet = (max(500, streitwert) * 100).rounded() / 100
 let sw = Decimal(string: String(format: "%.2f", gerundet)) ?? Decimal(500)
 guard let einfach = RVGTabelle.gebuehr(streitwert: sw) else {
   return .init(einfach: 0, verfahren: 0, termin: 0, auslagen: 0, ust: 0)
 }
 let einfachD = NSDecimalNumber(decimal: einfach).doubleValue
 let verfahren = einfach * Decimal(string: "1.3")!   // Nr. 3100 VV RVG
 let termin = einfach * Decimal(string: "1.2")!      // Nr. 3104 VV RVG
 let auslagen = min((verfahren + termin) * Decimal(string: "0.20")!, Decimal(20))  // Nr. 7002 VV RVG: 20 %, höchstens 20 €
 let ust = (verfahren + termin + auslagen) * Decimal(string: "0.19")!  // Nr. 7008 VV RVG
 return .init(einfach: einfachD,
              verfahren: NSDecimalNumber(decimal: verfahren).doubleValue,
              termin: NSDecimalNumber(decimal: termin).doubleValue,
              auslagen: NSDecimalNumber(decimal: auslagen).doubleValue,
              ust: NSDecimalNumber(decimal: ust).doubleValue)
}
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
static func verjaehrungBGB(entstehung: Date) -> VorgangFrist {
 let jahr = Calendar.current.component(.year, from: entstehung)
 let jahresende = Calendar.current.date(from: DateComponents(year: jahr, month: 12, day: 31)) ?? entstehung
 let datum = Calendar.current.date(byAdding: .year, value: 3, to: jahresende) ?? jahresende
 let tage = Calendar.current.dateComponents([.day], from: .init(), to: datum).day ?? 0
 return .init(
   datum: datum,
   art: "Regelverjährung § 195 BGB",
   kritisch: tage < 60,
   quelle: "§§ 195, 199 Abs. 1 BGB (Beginn mit Schluss des Jahres)"
 )
}
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
static func rangScore(_ o: VorgangOption, profil: MandantenProfil) -> Double {
        let ev = o.bewertung.ev?.wert ?? 0
        let rav = o.bewertung.rav?.wert ?? ev
        let varStrafe = min(0, o.bewertung.var95?.wert ?? 0)
        switch profil {
        case .risikoavers:
            return rav * 0.45 + ev * 0.20 + varStrafe * 0.35
        case .ausgewogen:
            return rav * (1 - profil.evGewicht) + ev * profil.evGewicht
        case .chancenorientiert:
            return ev * profil.evGewicht + rav * (1 - profil.evGewicht)
        }
    }
static func rangListe(_ optionen: [VorgangOption], profil: MandantenProfil) -> [VorgangOption] {
        optionen
            .filter { !$0.istVorgeschichte && $0.legalitaetsStatus != .rechtswidrig }
            .sorted { rangScore($0, profil: profil) > rangScore($1, profil: profil) }
    }
static func verworfene(_ optionen: [VorgangOption]) -> [VorgangOption] {
        optionen.filter { !$0.istVorgeschichte && $0.legalitaetsStatus == .rechtswidrig }
    }
static func portfolioKlumpen(_ vorgaenge: [Vorgang]) -> [String] {
        var hinweise: [String] = []
        let nachGebiet = Dictionary(grouping: vorgaenge, by: { $0.rechtsgebiet })
        for (g, vs) in nachGebiet where vs.count > 1 && !g.isEmpty {
            hinweise.append("\(vs.count)× \(g) — dieselbe Wette mehrfach")
        }
        let nachGegner = Dictionary(grouping: vorgaenge) { v -> String in
            v.parteien.first(where: { $0.rolle.lowercased().contains("gegner") })?.name ?? ""
        }
        for (n, vs) in nachGegner where vs.count > 1 && !n.isEmpty {
            hinweise.append("\(vs.count)× Gegner \(n)")
        }
        return hinweise
    }
static func nichtsTun(streitwert: Double) -> VorgangOption {
        VorgangOption(
            label: "D · Nichts tun",
            beschreibung: "Frist verstreichen lassen / Anspruch nicht verfolgen.",
            kosten: .init(anwalt: 0, gericht: 0, intern: 0, opportunitaet: 0),
            chancen: .init(
                pErfolg: .formel(0, "Nichts tun: P = 0"),
                best: .formel(0, "Kein Gewinn"),
                worst: .formel(-abs(streitwert), "Streitwert als entgangener Anspruch"),
                likely: .formel(-abs(streitwert), "P × 0 + 1 × (−Streitwert)")
            ),
            zeit: .init(minMonate: 0, maxMonate: 0),
            qualitativ: .init(reputation: -1, beziehung: 0, medien: 0, praezedenz: 0)
        )
    }
static func exportText(_ v: Vorgang) -> String {
        var z: [String] = [
            "FENLYNINE OS — VORGANG \(v.kurzId)",
            v.titel,
            "Typ: \(v.typ.bezeichnung) · Zustand: \(v.zustand.bezeichnung)",
            "Rechtsgebiet: \(v.rechtsgebiet.isEmpty ? "—" : v.rechtsgebiet)",
            "Volumen: \(InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false))",
            "Export: \(Date().formatted(date: .abbreviated, time: .shortened))",
            "",
            "PARTEIEN"
        ]
        if v.parteien.isEmpty { z.append("  (keine)") }
        for p in v.parteien { z.append("  \(p.rolle): \(p.name)") }
        z.append(""); z.append("SACHVERHALT"); z.append(v.beschreibung.isEmpty ? "  (leer)" : v.beschreibung)
        z.append(""); z.append("OPTIONEN")
        for o in v.aktiveOptionen {
            let ev = o.bewertung.ev.map { InterfaceZahl.waehrung($0.wert) } ?? "—"
            let rav = o.bewertung.rav.map { InterfaceZahl.waehrung($0.wert) } ?? "—"
            z.append("  \(o.label)  EV \(ev)  RAV \(rav)  P \(NexusAnzeige.band(o.chancen.pErfolg.wert)) · \(o.legalitaetsStatus.titel)")
            if o.bewertung.ev != nil { z.append("    \(o.bewertung.ev?.quelle ?? "")") }
        }
        if let e = v.empfehlung {
            z.append(""); z.append("EMPFEHLUNG")
            z.append("  \(e.begruendung)")
            if let g = e.gegenprobe { z.append("  Gegenprobe: \(g)") }
        }
        if let d = v.entscheidung {
            z.append(""); z.append("ENTSCHEIDUNG von \(d.wer) am \(d.wann.formatted(date: .abbreviated, time: .omitted))")
            if let g = d.abweichungGrund, !g.isEmpty { z.append("  Abweichung: \(g)") }
        }
        let rvg = rvg(streitwert: v.volumen)
        z.append(""); z.append("RVG (Anlage 2 KostBRÄG 2025)")
        z.append("  Einfache Gebühr: \(InterfaceZahl.waehrung(rvg.einfach, mitVorzeichen: false))")
        z.append("  Verfahren 1,3: \(InterfaceZahl.waehrung(rvg.verfahren, mitVorzeichen: false))")
        z.append("  Termin 1,2: \(InterfaceZahl.waehrung(rvg.termin, mitVorzeichen: false))")
        z.append("  Auslagen Nr. 7002 (20 %, max. 20 €): \(InterfaceZahl.waehrung(rvg.auslagen, mitVorzeichen: false))")
        z.append("  USt 19 %: \(InterfaceZahl.waehrung(rvg.ust, mitVorzeichen: false))")
        z.append("  Gesamt: \(InterfaceZahl.waehrung(rvg.gesamt, mitVorzeichen: false))")
        z.append(""); z.append("FRISTEN")
        if v.fristen.isEmpty { z.append("  (keine)") }
        for f in v.fristen { z.append("  \(f.art) · \(f.quelle)") }
        return z.joined(separator: "\n")
    }
static func auslagenPauschale(gebuehren: Double) -> Double {
        min(max(0, gebuehren) * 0.20, 20)
    }
static func gegenprobe(optionen: [VorgangOption]) -> String {
        let kopien = optionen.filter { !$0.istVorgeschichte }
        guard kopien.count >= 2,
              let bestIdx = kopien.indices.max(by: {
                  (kopien[$0].bewertung.rav?.wert ?? -.infinity) < (kopien[$1].bewertung.rav?.wert ?? -.infinity)
              }) else {
            return "Gegenprobe nicht möglich — weniger als zwei bewertete Optionen."
        }
        let name = kopien[bestIdx].label
        var alt = kopien[bestIdx]
        alt.chancen.pErfolg.wert = max(0.01, min(0.99, 1 - alt.chancen.pErfolg.wert))
        bewerte(&alt)
        let rest = kopien.enumerated()
            .filter { $0.offset != bestIdx }
            .compactMap { $0.element.bewertung.rav?.wert }
            .max() ?? -.infinity
        if (alt.bewertung.rav?.wert ?? 0) < rest {
            let zweit = kopien.enumerated()
                .filter { $0.offset != bestIdx }
                .max { ($0.element.bewertung.rav?.wert ?? 0) < ($1.element.bewertung.rav?.wert ?? 0) }?
                .element.label ?? "die nächste Option"
            return "Diese Empfehlung hängt an „\(name)“. Kehrt sich die Erfolgschance, führt „\(zweit)“."
        }
        return "Die Empfehlung „\(name)“ hält auch, wenn man ihre Erfolgschance umkehrt."
    }
static func qualitativInRPN(_ o: inout VorgangOption) {
        func zeile(_ titel: String, _ score: Int) {
            guard score < 0 else { return }
            if o.risiken.contains(where: { $0.titel == titel }) { return }
            o.risiken.append(.init(
                titel: titel,
                eintrittWahrscheinlichkeit: min(10, abs(score) * 2),
                auswirkung: 6,
                entdeckung: 5
            ))
        }
        zeile("Reputationsrisiko", o.qualitativ.reputation)
        zeile("Beziehungsrisiko", o.qualitativ.beziehung)
        zeile("Medienrisiko", o.qualitativ.medien)
        zeile("Präzedenzrisiko", o.qualitativ.praezedenz)
    }
private static func ranking(optionen: [VorgangOption], gewicht g: Double,
             szenario: (VorgangOption, Double) -> Double) -> [VorgangOption] {
 optionen.sorted { szenario($0, g) > szenario($1, g) }
}
private static func fmt(_ x: Double) -> String {
 String(format: "%.2f", x)
}
}
