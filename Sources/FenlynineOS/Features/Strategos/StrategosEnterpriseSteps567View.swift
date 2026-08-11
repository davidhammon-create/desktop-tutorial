import SwiftUI
import Charts
import AppKit

// MARK: - Step 5 Handlungsoptionen (Step4HandlungsOptionen.jsx)

struct StrategosEnterpriseStep5HandlungsView: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void

@State private var opts: [String: Any]?
@State private var zielZustand = ""
@State private var zeitraum = "12 Monate"
@State private var generating = false
@State private var fehler: String?

private let zeitraumOptionen = ["3 Monate", "6 Monate", "12 Monate", "18 Monate", "24 Monate", "36 Monate", "5 Jahre"]

var body: some View {
  VStack(spacing: 18) {
    header("Handlungsoptionen & Entscheidungsszenarien", sub: "Von A nach C · Gegner-Antizipation · Operativer Handlungsbaum", color: .green)

    if let err = fehler { Text(err).font(.caption).foregroundStyle(.red) }

    VStack(alignment: .leading, spacing: 10) {
      Text("Zieldefinition (Von A nach C)").font(.caption.bold())
      TextField("Gewünschter Zielzustand (Punkt C)…", text: $zielZustand, axis: .vertical)
        .lineLimit(2...4).textFieldStyle(.roundedBorder).font(.caption)
        .onChange(of: zielZustand) { _, _ in Task { await saveMeta() } }
      Picker("Zeitrahmen", selection: $zeitraum) {
        ForEach(zeitraumOptionen, id: \.self) { Text($0).tag($0) }
      }
      .onChange(of: zeitraum) { _, _ in Task { await saveMeta() } }
    }
    .padding(14)
    .background(.background, in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))

    HStack {
      VStack(alignment: .leading) {
        Text("KI-Handlungsoptionen generieren").font(.subheadline.bold())
        Text("3-7 Optionen · BJR-Schutz · Gegner-Antizipation").font(.caption2).foregroundStyle(.secondary)
      }
      Spacer()
      Button { Task { await generate() } } label: {
        if generating { ProgressView().scaleEffect(0.7); Text("Generiert…") }
        else { Label(opts != nil ? "Neu generieren" : "Optionen ermitteln", systemImage: "sparkles") }
      }
      .buttonStyle(FenlynineOSGlassProminentButtonStyle()).tint(.green)
      .disabled(generating)
    }
    .padding(14)
    .background(Color.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

    if let o = opts {
      let optionen = o["optionen"] as? [[String: Any]] ?? []
      let illegalCount = optionen.filter { ($0["ist_illegal"] as? Bool) == true }.count
      if illegalCount > 0 {
        Label("Enthält \(illegalCount) illegale(n) Weg(e) -- nur zur Risikoaufklärung", systemImage: "exclamationmark.triangle.fill")
          .font(.caption).foregroundStyle(.red)
          .padding(10).background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
      }
      ForEach(Array(optionen.enumerated()), id: \.offset) { i, opt in
        let letter = String(UnicodeScalar(65 + min(i, 25))!)
        handlungsOptionPanel(letter: letter, opt: opt, gegner: (o["gegner_szenarien"] as? [[String: Any]])?.indices.contains(i) == true ? (o["gegner_szenarien"] as? [[String: Any]])?[i] : nil)
      }
      if let emp = o["empfohlene_option"] as? String {
        empfehlungsKarte(emp: emp, begruendung: o["beguendung"] as? String, faktoren: o["kritische_erfolgsfaktoren"] as? [String], vermeiden: o["wege_die_vermieden_werden_sollten"] as? [String])
      }
    }
  }
  .onAppear { hydrate() }
}

@ViewBuilder
private func handlungsOptionPanel(letter: String, opt: [String: Any], gegner: [String: Any]?) -> some View {
  let illegal = (opt["ist_illegal"] as? Bool) == true
  let col: Color = illegal ? .red : letter == "A" ? .green : letter == "B" ? .orange : .blue
  VStack(alignment: .leading, spacing: 10) {
    HStack {
      Text("Option \(letter): \(opt["name"] as? String ?? "Handlungsoption")").font(.caption.bold())
      if illegal {
        Text("ILLEGAL").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2)
          .background(Color.red).foregroundStyle(.white).clipShape(Capsule())
      }
      Spacer()
      if let e = opt["erfolg_pct"] as? Double {
        Text("\(Int(e))%").font(.title3.bold()).foregroundStyle(col)
      }
    }
    if illegal {
      Text("Diese Option verstößt gegen geltendes Recht -- ausschließlich zur Information.")
        .font(.caption2).foregroundStyle(.red)
    }
    if let b = opt["beschreibung"] as? String { Text(b).font(.caption) }
    if let v = opt["juristische_vorteile"] as? [String], !v.isEmpty {
      Text("Vorteile: \(v.joined(separator: "; "))").font(.caption2).foregroundStyle(.green)
    }
    if let n = opt["juristische_nachteile"] as? [String], !n.isEmpty {
     Text("Nachteile: \(n.joined(separator: "; "))").font(.caption2).foregroundStyle(.red)
   }
   if let folgen = opt["folgen"] as? [String: Any] {
     Text("Folgen K/M/L: \(folgen["kurzfristig"] as? String ?? "") | \(folgen["mittelfristig"] as? String ?? "") | \(folgen["langfristig"] as? String ?? "")")
       .font(.caption2)
   }
   if let baum = opt["handlungsbaum"] as? [[String: Any]], !baum.isEmpty {
     Text("Handlungsbaum").font(.caption2.bold())
     ForEach(Array(baum.prefix(5).enumerated()), id: \.offset) { idx, h in
       Text("\(idx + 1). \(h["schritt"] as? String ?? "")").font(.caption2)
     }
   }
   if let strafen = opt["strafen"] as? String, !strafen.isEmpty {
     Text("Strafen: \(strafen)").font(.caption2).foregroundStyle(.red)
   }
   if let g = gegner, let reaktion = g["reaktion"] as? String {
     Text("Gegner-Reaktion: \(reaktion)").font(.caption2).foregroundStyle(.orange)
   }
 }
 .padding(14)
 .background(col.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(col.opacity(illegal ? 0.4 : 0.2), lineWidth: illegal ? 2 : 1))
}

@ViewBuilder
private func empfehlungsKarte(emp: String, begruendung: String?, faktoren: [String]?, vermeiden: [String]?) -> some View {
 VStack(alignment: .leading, spacing: 8) {
   Label("Empfohlen: \(emp)", systemImage: "checkmark.seal.fill").font(.subheadline.bold()).foregroundStyle(.green)
   if let b = begruendung { Text(b).font(.caption) }
   if let f = faktoren {
     Text("Erfolgsfaktoren").font(.caption2.bold())
     ForEach(f, id: \.self) { Text("(cid:127) \($0)").font(.caption2) }
   }
   if let v = vermeiden {
     Text("Zu vermeiden").font(.caption2.bold()).foregroundStyle(.red)
     ForEach(v, id: \.self) { Text("n \($0)").font(.caption2).foregroundStyle(.red) }
   }
 }
 .padding(14)
 .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
}

private func hydrate() {
 if let h = szenario.ki_analyse?.dictValue?["handlungsoptionen"] as? [String: Any] {
   opts = h
 }
 zielZustand = szenario.ki_analyse?.dictValue?["ziel_zustand"] as? String ?? ""
 zeitraum = szenario.ki_analyse?.dictValue?["zeitraum"] as? String ?? "12 Monate"
}

private func saveMeta() async {
 var ki = szenario.ki_analyse?.dictValue ?? [:]
 ki["ziel_zustand"] = zielZustand
 ki["zeitraum"] = zeitraum
 await onSave(["ki_analyse": ki])
}

private func generate() async {
 generating = true
 fehler = nil
 defer { generating = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String ?? ""

 let prompt = """
 Senior-Partner Top-Kanzlei (Sun Tzu + Machiavelli + Harvard).
 Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--") (\(ctx["rechtsform"] as? String ?? "--"))
 Sachverhalt: \(ctx["sachverhalt_lang"] as? String ?? "--")
 Gegner: \(ctx["gegner_name"] as? String ?? "--")
 Rechtsgebiete: \((ctx["rechtsgebiete"] as? [String] ?? []).joined(separator: ", "))
 ZIELZUSTAND: \(zielZustand)
 Zeitraum: \(zeitraum)
 Risiko: \(sit["gesamt_risiko"] as? Double ?? 0)/10
 \(briefing.isEmpty ? "" : "KI-BRIEFING: \(String(briefing.prefix(1500)))")

 Erstelle 3-7 Handlungsoptionen (legal + illegal mit ist_illegal=true).
 Pro Option: name, beschreibung, kernstrategie, ist_illegal, strafen, juristische_vorteile/nachteile, folgen, reaktionsszenarien, handlungsbaum, erfolg_pct, risiko_pct, rechtliche_basis.
 Plus gegner_szenarien, empfohlene_option, begruendung, kritische_erfolgsfaktoren, wege_die_vermieden_werden_sollten.
 """

 let optionSchema: [String: Any] = [
   "type": "object",
   "properties": [
     "name": ["type": "string"], "beschreibung": ["type": "string"],
     "kernstrategie": ["type": "string"], "erfolg_pct": ["type": "number"],
     "risiko_pct": ["type": "number"], "ist_illegal": ["type": "boolean"],
     "strafen": ["type": "string"],
     "juristische_vorteile": ["type": "array", "items": ["type": "string"]],
     "juristische_nachteile": ["type": "array", "items": ["type": "string"]],
     "folgen": ["type": "object"],
     "handlungsbaum": ["type": "array", "items": ["type": "object"]],
     "rechtliche_basis": ["type": "string"]
   ] as [String: Any]
 ] as [String: Any]

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "optionen": ["type": "array", "items": optionSchema],
     "gegner_szenarien": ["type": "array", "items": ["type": "object"]],
     "empfohlene_option": ["type": "string"],
     "beguendung": ["type": "string"],
     "kritische_erfolgsfaktoren": ["type": "array", "items": ["type": "string"]],
     "wege_die_vermieden_werden_sollten": ["type": "array", "items": ["type": "string"]]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   guard let dict = try? KIJson.requireObject(response, kontext: "Handlungsoptionen") else {
     await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
     return
   }
   var ki = szenario.ki_analyse?.dictValue ?? [:]
   ki["handlungsoptionen"] = dict
   ki["ziel_zustand"] = zielZustand
   ki["zeitraum"] = zeitraum
   await onSave(["ki_analyse": ki])
   await MainActor.run { opts = dict }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - Step 6 Quantitative Analyse (Step5QuantitativeAnalyse.jsx)

struct StrategosEnterpriseStep6QuantView: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void

@State private var fin: [String: Double] = [:]
@State private var result: [String: Any]?
@State private var analysing = false
@State private var fehler: String?

private let finanzFelder: [(key: String, label: String)] = [
 ("transaktionswert", "Transaktionswert / Streitwert (€)"),
 ("kosten_legal", "Kosten Option A -- Legal (€)"),
 ("kosten_aggressiv", "Kosten Option B -- Aggressiv (€)"),
 ("erwarteter_gewinn", "Erwarteter Gewinn Best Case (€)"),
 ("potentielle_strafe", "Potentielle Strafe / Buße (€)"),
 ("reputationsschaden", "Reputationsschaden (€)"),
 ("zeitkosten", "Zeitkosten (€)"),
 ("schiedsverfahren_kosten", "Schiedsverfahrenskosten (€)")
]

var body: some View {
 VStack(spacing: 18) {
   header("Quantitative Risiko- & Kosten-Nutzen-Analyse", sub: "EV · Monte Carlo · Sensitivität · Bußgeld-Worst-Case", color: .purple)

   if let err = fehler { Text(err).font(.caption).foregroundStyle(.red) }

   VStack(alignment: .leading, spacing: 10) {
     Text("Finanzeingaben (optional)").font(.caption.bold())
     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
       ForEach(finanzFelder, id: \.key) { f in
         VStack(alignment: .leading, spacing: 4) {
           Text(f.label).font(.caption2).foregroundStyle(.secondary)
           TextField("0", value: Binding(
             get: { fin[f.key] ?? 0 },
             set: { fin[f.key] = $0; Task { await saveFin() } }
           ), format: .number)
           .textFieldStyle(.roundedBorder).font(.caption)
         }
       }
     }
   }
   .padding(14)
   .background(.background, in: RoundedRectangle(cornerRadius: 12))

   Button { Task { await runAnalysis() } } label: {
     if analysing { ProgressView().scaleEffect(0.7); Text("Berechnet…") }
     else { Label(result != nil ? "Neu berechnen" : "Analyse starten", systemImage: "function") }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle()).tint(.purple)
   .disabled(analysing)

   if let r = result {
     quantErgebnis(r)
   }
 }
 .onAppear { hydrate() }
}

@ViewBuilder
private func quantErgebnis(_ r: [String: Any]) -> some View {
 if let opts = r["optionen_bewertung"] as? [[String: Any]], !opts.isEmpty {
   Text("Optionen-Vergleich").font(.caption.bold())
   ForEach(Array(opts.enumerated()), id: \.offset) { _, o in
     HStack {
       Text("Option \(o["option"] as? String ?? "?")").font(.caption.bold())
       Spacer()
       Text("EV: \(Int(o["ev_eur"] as? Double ?? 0))€").font(.caption2)
       Text("RAV: \(Int(o["rav_eur"] as? Double ?? 0))€").font(.caption2).foregroundStyle(.green)
       Text("fl\(Int(o["downside_risk_eur"] as? Double ?? 0))€").font(.caption2).foregroundStyle(.red)
     }
     .padding(8).background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
   }
   if #available(macOS 14.0, *) {
     let chartData = opts.compactMap { o -> (name: String, ev: Double)? in
       guard let opt = o["option"] as? String else { return nil }
       return (name: "Opt \(opt)", ev: (o["ev_eur"] as? Double ?? 0) / 1000)
     }
     Chart(chartData, id: \.name) { row in
       BarMark(x: .value("Opt", row.name), y: .value("EV k€", row.ev))
         .foregroundStyle(.purple)
     }
     .frame(height: 140)
   }
 }
 if let mc = r["monte_carlo"] as? [String: Any] {
   Text("Monte-Carlo (3 Szenarien)").font(.caption.bold()).padding(.top, 8)
   HStack(spacing: 12) {
     monteCarloKarte("Optimistisch", mc["optimistisch"] as? [String: Any], .green)
     monteCarloKarte("Base", mc["base"] as? [String: Any], .blue)
     monteCarloKarte("Pessimistisch", mc["pessimistisch"] as? [String: Any], .red)
   }
 }
 if let sens = r["sensitivitaet"] as? [[String: Any]] {
   Text("Sensitivität").font(.caption.bold()).padding(.top, 8)
   ForEach(Array(sens.prefix(6).enumerated()), id: \.offset) { _, s in
     HStack {
       Text(s["parameter"] as? String ?? "").font(.caption2)
       Spacer()
       Text("\(s["richtung"] as? String ?? "") \(Int(s["einfluss_pct"] as? Double ?? 0))%")
         .font(.caption2.bold())
     }
   }
 }
 if let ind = r["indirekte_kosten"] as? [String: Any], let ges = ind["gesamt_indirekt_eur"] as? Double {
   Text("Indirekte Kosten gesamt: \(Int(ges))€").font(.caption).foregroundStyle(.red)
 }
 if let buss = r["bussgeld_worst_cases"] as? [[String: Any]] {
   ForEach(Array(buss.prefix(4).enumerated()), id: \.offset) { _, b in
     Text("\(b["rechtsgebiet"] as? String ?? ""): max \(Int(b["max_eur"] as? Double ?? 0))€ -- \(b["norm"] as? String ?? "")")
       .font(.caption2)
   }
 }
 if let fazit = r["gesamtfazit"] as? String {
   Text(fazit).font(.caption).padding(10).background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
 }
}

private func monteCarloKarte(_ titel: String, _ v: [String: Any]?, _ farbe: Color) -> some View {
 VStack(spacing: 4) {
   Text(titel).font(.caption2.bold()).foregroundStyle(farbe)
   Text("\(Int((v?["wert_eur"] as? Double ?? 0) / 1000))k€").font(.headline)
   Text("P=\(Int(v?["wahrscheinlichkeit_pct"] as? Double ?? 0))%").font(.caption2)
 }
 .frame(maxWidth: .infinity)
 .padding(10)
 .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
}

private func hydrate() {
 if let f = szenario.finanzdaten?.dictValue {
   for (k, v) in f {
     if let n = v as? Double { fin[k] = n }
     else if let n = v as? Int { fin[k] = Double(n) }
   }
 }
 result = szenario.ki_analyse?.dictValue?["quant_analyse"] as? [String: Any]
}

private func saveFin() async {
 var dict: [String: Any] = [:]
 for (k, v) in fin where v != 0 { dict[k] = v }
 await onSave(["finanzdaten": dict])
 await MainActor.run { szenario.finanzdaten = AnyCodable(dict) }
}

private func runAnalysis() async {
 analysing = true
 fehler = nil
 defer { analysing = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let opts = szenario.ki_analyse?.dictValue?["handlungsoptionen"] as? [String: Any] ?? [:]
 let finStr = fin.filter { $0.value != 0 }.map { "\($0.key): \($0.value)€" }.joined(separator: "\n")

 let prompt = """
 Quantitativer Risikoanalyst + Senior-Anwalt. EV, RAV, Downside, RPN, Monte Carlo (3 Szenarien), Break-Even, Sensitivität, indirekte Kosten, Bußgeld-Worst-Cases.
 Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--"), Umsatz: \(ctx["umsatz"] as? Double ?? 0)€
 Rechtsgebiete: \((ctx["rechtsgebiete"] as? [String] ?? []).joined(separator: ", "))
 Finanzen:\n\(finStr.isEmpty ? "Keine Eingaben" : finStr)
 Handlungsoptionen: \(String(describing: opts).prefix(800))
 Risiko: \(sit["gesamt_risiko"] as? Double ?? 0)/10, Exposure: \(sit["gesamt_exposure_eur"] as? Double ?? 0)€
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "optionen_bewertung": ["type": "array", "items": ["type": "object"]],
     "monte_carlo": ["type": "object"],
     "sensitivitaet": ["type": "array", "items": ["type": "object"]],
     "indirekte_kosten": ["type": "object"],
     "bussgeld_worst_cases": ["type": "array", "items": ["type": "object"]],
     "empfohlene_option": ["type": "string"],
     "gesamtfazit": ["type": "string"],
     "steuer_fristen": ["type": "array", "items": ["type": "object"]]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   guard let dict = try? KIJson.requireObject(response, kontext: "Handlungsoptionen") else {
     await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
     return
   }
   var ki = szenario.ki_analyse?.dictValue ?? [:]
   ki["quant_analyse"] = dict
   await onSave(["ki_analyse": ki])
   await MainActor.run { result = dict }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - Step 7 Umsetzungsplan (Step6UmsetzungsPlan.jsx)

struct StrategosEnterpriseStep7UmsetzungView: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void

@State private var plan: [String: Any]?
@State private var generating = false
@State private var creatingLexara = false
@State private var lexaraCreated: [String: Any]?
@State private var fehler: String?

var body: some View {
 VStack(spacing: 18) {
   header("Handlungsempfehlung & Umsetzungsplan", sub: "Roadmap · Monitoring · Schiedsempfehlung · LEXARA-Export", color: .pink)

   if let err = fehler { Text(err).font(.caption).foregroundStyle(.red) }

   HStack {
     Button { Task { await generate() } } label: {
       if generating { ProgressView().scaleEffect(0.7); Text("Generiert…") }
       else { Label(plan != nil ? "Neu generieren" : "Plan erstellen", systemImage: "sparkles") }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle()).tint(.pink)
     .disabled(generating)
     if plan != nil {
       Button("Export (.txt)") { exportReport() }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     }
   }

   if let p = plan {
     if let sum = p["executive_summary"] as? String {
       VStack(alignment: .leading, spacing: 6) {
         Text("Executive Summary").font(.caption.bold())
         Text(sum).font(.caption)
       }
       .padding(14).background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
     }
     horizonBlock("Sofort (0-30 Tage)", items: p["umsetzung_sofort"] as? [[String: Any]], color: .red)
     horizonBlock("Mittelfristig (6-12 Monate)", items: p["umsetzung_mittelfristig"] as? [[String: Any]], color: .orange)
     horizonBlock("Langfristig", items: p["umsetzung_langfristig"] as? [[String: Any]], color: .green)
     if let z = p["zeitstrahl"] as? [[String: Any]] {
       Text("Kritischer Zeitstrahl").font(.caption.bold())
       ForEach(Array(z.enumerated()), id: \.offset) { _, item in
         HStack(alignment: .top) {
           Text(item["datum"] as? String ?? "--").font(.caption2.bold()).foregroundStyle(.blue).frame(width: 80, alignment: .leading)
           VStack(alignment: .leading) {
             Text(item["ereignis"] as? String ?? "").font(.caption)
             if let k = item["konsequenz_versaeumnis"] as? String {
               Text("Versäumnis: \(k)").font(.caption2).foregroundStyle(.red)
             }
           }
         }
       }
     }
     if let mon = p["monitoring_indikatoren"] as? [[String: Any]] {
       Text("Monitoring").font(.caption.bold())
       ForEach(Array(mon.enumerated()), id: \.offset) { _, m in
         Text("(cid:127) \(m["indikator"] as? String ?? "") -- \(m["schwellenwert"] as? String ?? "")").font(.caption2)
       }
     }
     lexaraExportSection(p)
   }
 }
 .onAppear { hydrate() }
}

@ViewBuilder
private func horizonBlock(_ titel: String, items: [[String: Any]]?, color: Color) -> some View {
 if let items, !items.isEmpty {
   VStack(alignment: .leading, spacing: 8) {
     Text(titel).font(.caption.bold()).foregroundStyle(color)
     ForEach(Array(items.enumerated()), id: \.offset) { i, m in
       Text("\(i + 1). \(m["massnahme"] as? String ?? "") · \(m["frist"] as? String ?? m["zeitraum"] as? String ?? "")")
         .font(.caption2)
     }
   }
   .padding(12).background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
 }
}

@ViewBuilder
private func lexaraExportSection(_ p: [String: Any]) -> some View {
 VStack(alignment: .leading, spacing: 10) {
   Text("LEXARA-Integration").font(.caption.bold())
   if let info = lexaraCreated {
     Label("Fall erstellt: \(info["case_name"] as? String ?? "")", systemImage: "checkmark.circle.fill")
       .font(.caption).foregroundStyle(.green)
   } else {
     if let checklist = p["lexara_checkliste"] as? [String] {
       ForEach(checklist, id: \.self) { Text("-> \($0)").font(.caption2) }
     }
     Button {
       Task { await createLexaraCase() }
     } label: {
       if creatingLexara { ProgressView().scaleEffect(0.7); Text("Erstellt…") }
       else { Label("Als LEXARA-Fall exportieren", systemImage: "scale.3d") }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(creatingLexara)
   }
 }
 .padding(14)
 .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
}

private func hydrate() {
 plan = szenario.ki_analyse?.dictValue?["umsetzungsplan"] as? [String: Any]
 lexaraCreated = szenario.ki_analyse?.dictValue?["lexara_case_created"] as? [String: Any]
}

private func generate() async {
 generating = true
 fehler = nil
 defer { generating = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let quant = szenario.ki_analyse?.dictValue?["quant_analyse"] as? [String: Any] ?? [:]
 let opts = szenario.ki_analyse?.dictValue?["handlungsoptionen"] as? [String: Any] ?? [:]
 let emp = szenario.strategos_empfehlung?.dictValue ?? [:]

 let prompt = """
 Strategos Senior-Berater: Finaler operativer Umsetzungsplan.
 Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--")
 Sachverhalt: \(ctx["sachverhalt_lang"] as? String ?? "--")
 Risiko: \(sit["gesamt_risiko"] as? Double ?? 0)/10
 Empfohlene Option: \(quant["empfohlene_option"] as? String ?? opts["empfohlene_option"] as? String ?? "--")
 Top-Hebel: \((emp["groesste_hebel"] as? [String] ?? []).prefix(3).joined(separator: " · "))

 Liefere: umsetzung_sofort, umsetzung_mittelfristig, umsetzung_langfristig, monitoring_indikatoren, zeitstrahl, schiedsverfahren_empfehlung, compliance_dokumentation, lexara_checkliste, executive_summary.
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "umsetzung_sofort": ["type": "array", "items": ["type": "object"]],
     "umsetzung_mittelfristig": ["type": "array", "items": ["type": "object"]],
     "umsetzung_langfristig": ["type": "array", "items": ["type": "object"]],
     "monitoring_indikatoren": ["type": "array", "items": ["type": "object"]],
     "zeitstrahl": ["type": "array", "items": ["type": "object"]],
     "schiedsverfahren_empfehlung": ["type": "object"],
     "compliance_dokumentation": ["type": "array", "items": ["type": "object"]],
     "lexara_checkliste": ["type": "array", "items": ["type": "string"]],
     "executive_summary": ["type": "string"]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   guard let dict = try? KIJson.requireObject(response, kontext: "Handlungsoptionen") else {
     await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
     return
   }
   var ki = szenario.ki_analyse?.dictValue ?? [:]
   ki["umsetzungsplan"] = dict
   await onSave(["ki_analyse": ki])
   await MainActor.run { plan = dict }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func createLexaraCase() async {
 creatingLexara = true
 fehler = nil
 defer { creatingLexara = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let quant = szenario.ki_analyse?.dictValue?["quant_analyse"] as? [String: Any] ?? [:]
 let opts = szenario.ki_analyse?.dictValue?["handlungsoptionen"] as? [String: Any] ?? [:]
 let fin = szenario.finanzdaten?.dictValue ?? [:]

 var fall = LegalCase.neu(fallname: "[STRATEGOS] \(szenario.titel)")
 fall.rechtsgebiet = (ctx["rechtsgebiete"] as? [String])?.joined(separator: ", ") ?? szenario.rechtsgebiet
 fall.status = .vorbereitung
 fall.instanz = .erstinstanz
 fall.zentrale_rechtsfrage = String((ctx["sachverhalt_lang"] as? String ?? "").prefix(200))
 if let risk = sit["gesamt_risiko"] as? Double {
   fall.prognose = max(0, 100 - risk * 10)
 }
 fall.streitwert = fin["transaktionswert"] as? Double ?? sit["gesamt_exposure_eur"] as? Double
 fall.notes = """
 [Aus STRATEGOS migriert]
 Sachverhalt: \(ctx["sachverhalt_lang"] as? String ?? "--")
 Gegner: \(ctx["gegner_name"] as? String ?? "--")
 Empfehlung: \(quant["empfohlene_option"] as? String ?? opts["empfohlene_option"] as? String ?? "--")
 """
 fall.ki_berater_result = AnyCodable([
   "strategos_scenario_id": szenario.id ?? "",
   "empfohlene_option": quant["empfohlene_option"] ?? opts["empfohlene_option"] ?? "",
   "gesamt_risiko": sit["gesamt_risiko"] ?? 0,
   "exposure_eur": sit["gesamt_exposure_eur"] ?? 0
 ] as [String: Any])

 do {
   let created = try await Services.cases.create(fall)
   let info: [String: Any] = [
     "case_id": created.id ?? "",
     "case_name": created.fallname,
     "created_at": ISO8601DateFormatter().string(from: Date())
   ]
   var ki = szenario.ki_analyse?.dictValue ?? [:]
   ki["lexara_case_created"] = info
   var ctxUpd = ctx
   ctxUpd["lexara_case_id"] = created.id ?? ""
   await onSave(["ki_analyse": ki, "unternehmenskontext": ctxUpd])
   await MainActor.run { lexaraCreated = info }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func exportReport() {
 guard let p = plan else { return }
 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 var lines = [
   "STRATEGOS -- UMSETZUNGSPLAN",
   "Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--")",
   "Szenario: \(szenario.titel)",
   "",
   p["executive_summary"] as? String ?? ""
 ]
 let text = lines.joined(separator: "\n")
 NSPasteboard.general.clearContents()
 NSPasteboard.general.setString(text, forType: .string)
 let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
   .appendingPathComponent("Strategos_Umsetzungsplan_\(ISO8601DateFormatter().string(from: Date()).prefix(10)).txt")
 try? text.write(to: url, atomically: true, encoding: .utf8)
}
}

// MARK: - Shared header

private func header(_ titel: String, sub: String, color: Color) -> some View {
VStack(spacing: 4) {
 Text("Strategos Enterprise").font(.caption2.bold()).foregroundStyle(color)
 Text(titel).font(.title2.bold())
 Text(sub).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
}
}

