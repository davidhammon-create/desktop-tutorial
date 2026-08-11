import SwiftUI

// MARK: - Step 2 Rechtsgebiet-Analyse (1:1 Step2Situation.jsx)

struct StrategosEnterpriseStep2View: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void

@State private var sit: [String: Any] = ["module": []]
@State private var analyzing = false
@State private var fehler: String?
@State private var quantifyKey: String?

private var rechtsgebiete: [String] {
  szenario.unternehmenskontext?.dictValue?["rechtsgebiete"] as? [String] ?? []
}

var body: some View {
  VStack(spacing: 18) {
    VStack(spacing: 4) {
      Text("Schritt 2 · Enterprise").font(.caption.bold()).foregroundStyle(.orange)
      Text("Situationsanalyse").font(.title2.bold())
      Text("KI-Tiefenanalyse pro Rechtsgebiet").font(.caption).foregroundStyle(.secondary)
    }

    if let err = fehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }

    if let module = sit["module"] as? [[String: Any]], !module.isEmpty {
      gesamtBewertung(sit)
    }

    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text((sit["module"] as? [[String: Any]])?.isEmpty == false ? "Analyse aktualisieren" : "Analyse starten")
          .font(.subheadline.bold())
        Text("\(rechtsgebiete.count) Rechtsgebiet(e) · Claude Sonnet").font(.caption2).foregroundStyle(.secondary)
      }
      Spacer()
      Button {
        Task { await runAnalysis() }
      } label: {
        if analyzing { ProgressView().scaleEffect(0.7); Text("Analysiert…") }
        else { Label("KI-Analyse starten", systemImage: "sparkles") }
      }
      .buttonStyle(FenlynineOSGlassProminentButtonStyle())
      .tint(.orange)
      .disabled(analyzing || rechtsgebiete.isEmpty)
    }
    .padding(14)
    .background(.background, in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))

    if rechtsgebiete.isEmpty {
      Text("n Bitte in Schritt 1 Rechtsgebiete wählen (oder Step 0 Dokumente analysieren).")
        .font(.caption).foregroundStyle(.orange)
    }

    if let module = sit["module"] as? [[String: Any]] {
      ForEach(Array(module.enumerated()), id: \.offset) { _, m in
        modulPanel(m)
      }
    }
  }
  .onAppear { hydrate() }
}

@ViewBuilder
private func gesamtBewertung(_ sit: [String: Any]) -> some View {
  VStack(alignment: .leading, spacing: 12) {
    Text("KI-Gesamtbewertung").font(.caption.bold())
    HStack(alignment: .top, spacing: 16) {
      if let g = sit["gesamt_risiko"] as? Double {
        VStack {
          Text("\(Int(g))").font(.title.bold())
            .foregroundStyle(g >= 7 ? .red : g >= 4 ? .orange : .green)
          Text("/10").font(.caption2)
        }
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("Top-3 Kritisch").font(.caption2.bold()).foregroundStyle(.secondary)
        ForEach((sit["kritische_punkte"] as? [String] ?? []).prefix(3), id: \.self) { p in
          Label(p, systemImage: "exclamationmark.triangle.fill")
            .font(.caption2).foregroundStyle(.red)
        }
      }
      if let exp = sit["gesamt_exposure_eur"] as? Double, exp > 0 {
        VStack {
          Text(String(format: "%.1fM€", exp / 1_000_000)).font(.title3.bold()).foregroundStyle(.red)
          Text("Gesamt-Exposure").font(.caption2)
        }
      }
    }
    if let zeit = sit["zeitachse"] as? [[String: Any]], !zeit.isEmpty {
      Text("Zeitachse").font(.caption2.bold()).foregroundStyle(.secondary)
      ForEach(Array(zeit.enumerated()), id: \.offset) { _, z in
        HStack {
          Text(z["wann"] as? String ?? "--").font(.caption2.bold()).foregroundStyle(.orange).frame(width: 80, alignment: .leading)
         Text(z["was_muss_entschieden_sein"] as? String ?? "").font(.caption2)
       }
     }
   }
 }
 .padding(14)
 .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
}

@ViewBuilder
private func modulPanel(_ m: [String: Any]) -> some View {
 let rg = m["rechtsgebiet"] as? String ?? "?"
 let score = Int(m["risiko_score"] as? Double ?? 0)
 let col: Color = score >= 7 ? .red : score >= 4 ? .orange : .green

 VStack(alignment: .leading, spacing: 10) {
   HStack {
     Text(StrategosRechtsgebiete.label(for: rg)).font(.subheadline.bold())
     Spacer()
     Text("\(score)/10").font(.caption.bold()).foregroundStyle(col)
   }
   ForEach(m["findings"] as? [String] ?? [], id: \.self) { f in
     Text("(cid:127) \(f)").font(.caption2)
   }
   if let normen = m["normen"] as? [String], !normen.isEmpty {
     Text("Normen: \(normen.joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary)
   }
   if let q = m["quantifizierung"] as? [String: Any] {
     HStack {
       quantChip("Eintritt", "\(Int(q["eintritt_pct"] as? Double ?? 0))%")
       quantChip("Schaden", "\(Int(q["schaden_eur"] as? Double ?? 0))€")
       quantChip("Reputation", q["reputation"] as? String ?? "--")
     }
   } else {
     Button {
       Task { await quantifyModule(m) }
     } label: {
       if quantifyKey == rg { ProgressView().scaleEffect(0.7); Text("Berechnet…") }
       else { Label("Quantifizieren", systemImage: "function") }
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     .controlSize(.small)
     .disabled(quantifyKey != nil)
   }
 }
 .padding(14)
 .background(col.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(col.opacity(0.15)))
}

private func quantChip(_ label: String, _ value: String) -> some View {
 VStack(spacing: 2) {
   Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
   Text(value).font(.caption2.bold())
 }
 .padding(.horizontal, 8).padding(.vertical, 4)
 .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
}

private func hydrate() {
 if let dict = szenario.situationsanalyse?.dictValue {
   sit = dict
 }
}

private func runAnalysis() async {
 analyzing = true
 fehler = nil
 defer { analyzing = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String ?? ""

 let prompt = """
 Du bist Senior-Partner einer internationalen Großkanzlei. Führe eine vollständige mehrdimensionale Risikoanalyse durch.

 UNTERNEHMEN: \(ctx["unternehmen_name"] as? String ?? szenario.titel) (\(ctx["rechtsform"] as? String ?? "--"), \(ctx["branche"] as? String ?? "--"))
 SACHVERHALT: \(ctx["sachverhalt_lang"] as? String ?? "--")
 GEGNER: \(ctx["gegner_name"] as? String ?? "--") (\(ctx["gegner_rolle"] as? String ?? "--"))
 RECHTSGEBIETE: \(rechtsgebiete.joined(separator: ", "))
 \(briefing.isEmpty ? "" : "KI-BRIEFING: \(String(briefing.prefix(800)))")

 Für JEDES Rechtsgebiet: risiko_score, findings (4-6 mit §§), fristen, normen, querverbindungen, formel_ergebnisse.
 Gesamtbewertung: gesamt_risiko, kritische_punkte, gesamt_exposure_eur, zeitachse, jurisdiktions_warnungen.
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "module": ["type": "array", "items": ["type": "object", "properties": [
       "rechtsgebiet": ["type": "string"], "risiko_score": ["type": "number"],
       "findings": ["type": "array", "items": ["type": "string"]],
       "fristen": ["type": "array", "items": ["type": "object"]],
       "normen": ["type": "array", "items": ["type": "string"]],
       "querverbindungen": ["type": "array", "items": ["type": "string"]],
       "formel_ergebnisse": ["type": "array", "items": ["type": "object"]]
     ]]],
     "gesamt_risiko": ["type": "number"],
     "kritische_punkte": ["type": "array", "items": ["type": "string"]],
     "gesamt_exposure_eur": ["type": "number"],
     "zeitachse": ["type": "array", "items": ["type": "object"]],
     "jurisdiktions_warnungen": ["type": "array", "items": ["type": "string"]]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   guard let dict = try? KIJson.requireObject(response, kontext: "Situationsanalyse") else {
     await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
     return
   }
   await MainActor.run {
     sit = dict
     szenario.situationsanalyse = AnyCodable(dict)
   }
   await onSave(["situationsanalyse": dict])
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func quantifyModule(_ m: [String: Any]) async {
 let rg = m["rechtsgebiet"] as? String ?? ""
 quantifyKey = rg
 defer { quantifyKey = nil }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let prompt = """
 Quantifiziere das Risiko für \(rg).
 Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--"), Umsatz \(ctx["umsatz"] as? Double ?? 0)€
 Findings: \((m["findings"] as? [String] ?? []).joined(separator: " | "))
 Normen: \((m["normen"] as? [String] ?? []).joined(separator: ", "))
 Berechne: eintritt_pct, schaden_eur, reputation, praezedenz.
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "eintritt_pct": ["type": "number"], "schaden_eur": ["type": "number"],
     "reputation": ["type": "string"], "praezedenz": ["type": "string"]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   guard let quant = try? KIJson.requireObject(response, kontext: "Risiko-Quantifizierung") else {
     await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
     return
   }
   var updated = sit
   var modules = updated["module"] as? [[String: Any]] ?? []
   modules = modules.map { mod in
     guard mod["rechtsgebiet"] as? String == rg else { return mod }
     var u = mod
     u["quantifizierung"] = quant
     return u
   }
   updated["module"] = modules
   await onSave(["situationsanalyse": updated])
   await MainActor.run {
     sit = updated
     szenario.situationsanalyse = AnyCodable(updated)
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - Rechtsgebiet-Metadaten (Auszug aus strategosRechtsgebiete.js)

enum StrategosRechtsgebiete {
static let allKeys: [(key: String, label: String)] = [
 ("patentrecht", "Patentrecht"),
 ("urheberrecht", "Urheberrecht"),
 ("markenrecht", "Markenrecht"),
 ("kartellrecht_gwb", "Kartellrecht (GWB)"),
 ("vertragsrecht_buergerliches_recht", "Vertragsrecht (BGB)"),
 ("handelsrecht", "Handelsrecht"),
 ("gesellschaftsrecht", "Gesellschaftsrecht"),
 ("arbeitsrecht", "Arbeitsrecht"),
 ("steuerrecht", "Steuerrecht"),
 ("datenschutz_dsgvo", "Datenschutz (DSGVO)"),
 ("compliance_ordnungswidrigkeiten", "Compliance / OWiG"),
 ("strafrecht_wirtschaftsstrafrecht", "Wirtschaftsstrafrecht"),
 ("insolvenzrecht", "Insolvenzrecht")
]

static func label(for key: String) -> String {
 allKeys.first { $0.key == key }?.label ?? key.replacingOccurrences(of: "_", with: " ").capitalized
}
}

