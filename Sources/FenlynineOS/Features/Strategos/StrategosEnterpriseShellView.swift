import SwiftUI
import AppKit

extension Notification.Name {
static let strategosOeffneOpportunisma = Notification.Name("strategosOeffneOpportunisma")
}

// MARK: - Strategos Enterprise Shell (8 Schritte, 1:1 EnterpriseShell.jsx)

struct StrategosEnterpriseShellView: View {
let initialSzenario: StrategosScenario
@State private var szenario: StrategosScenario
@State private var step: Int
@State private var showExport = false
@State private var showEinschaetzungen = false
@State private var showOpportunisma = false

private struct EnterpriseStep: Identifiable {
  let num: Int
  let label: String
  let sub: String
  let color: Color
  var id: Int { num }
}

private let steps: [EnterpriseStep] = [
  EnterpriseStep(num: 0, label: "Dokumente & KI-Briefing", sub: "Upload · Extraktion · Automatisch befüllen", color: .purple),
  EnterpriseStep(num: 1, label: "Kontext & Situation", sub: "Unternehmen · Sachverhalt · Rechtsgebiete", color: .blue),
  EnterpriseStep(num: 2, label: "Rechtsgebiet-Analyse", sub: "KI-Tiefenanalyse pro Rechtsgebiet", color: .orange),
  EnterpriseStep(num: 3, label: "Vertragsanalyse", sub: "Klausel-Risiko · Szenarioprojektion", color: .blue),
  EnterpriseStep(num: 4, label: "Patentanalyse", sub: "Schutzbereich · FTO · Strategische Optionen", color: .orange),
  EnterpriseStep(num: 5, label: "Handlungsoptionen", sub: "Von A nach C · Gegner-Antizipation", color: .green),
  EnterpriseStep(num: 6, label: "Quantitative Analyse", sub: "EV · Monte Carlo · Bußgeld-Worst-Case", color: .purple),
  EnterpriseStep(num: 7, label: "Umsetzungsplan", sub: "Roadmap · Monitoring · LEXARA-Export", color: .pink)
]

init(szenario: StrategosScenario) {
  self.initialSzenario = szenario
  _szenario = State(initialValue: szenario)
  let maxStep = 7
  _step = State(initialValue: min(max(0, szenario.enterprise_step), maxStep))
}

@Environment(\.fenlynineOSFensterModus) private var fensterModus
@Environment(\.fenlynineOSVergleichSpalte) private var vergleichSpalte

/// Schreibtisch-Kachel, Pop-out und Vergleich: eine Spalte + Schritt-Menü.
private var kompaktFenstermodus: Bool { fensterModus || vergleichSpalte }

var body: some View {
  Group {
    if kompaktFenstermodus {
      VStack(alignment: .leading, spacing: 0) {
        kompaktSchrittLeiste
        kompaktWerkzeugLeiste
        Divider().overlay(Premium.hairline)
        ScrollView {
          kompaktInhalt
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
      }
    } else {
      HStack(alignment: .top, spacing: 20) {
        ScrollView {
          sidebar
        }
        .frame(width: 228)
        ScrollView {
          content
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .padding(20)
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .onReceive(NotificationCenter.default.publisher(for: .strategosOeffneOpportunisma)) { _ in
    showOpportunisma = true
    showExport = false
    showEinschaetzungen = false
  }
}

private var kompaktSchrittLeiste: some View {
  HStack(spacing: 8) {
    Picker("Schritt", selection: Binding(
      get: { step },
      set: { navigate($0) }
    )) {
      ForEach(steps) { s in
        Text("\(s.num) · \(s.label)").tag(s.num)
      }
    }
    .labelsHidden()
    .pickerStyle(.menu)
    .frame(maxWidth: 280)

   Spacer(minLength: 0)

   if step > 0 {
     Button("<- Zurück") { navigate(step - 1) }
       .buttonStyle(.bordered)
       .controlSize(.small)
   }
   if step < steps.count - 1 {
     Button("Weiter ->") { navigate(step + 1) }
       .buttonStyle(.borderedProminent)
       .controlSize(.small)
   } else if step == steps.count - 1 {
     Button("n Neu") { navigate(1) }
       .buttonStyle(.borderedProminent)
       .controlSize(.small)
   }
 }
 .padding(.horizontal, 10)
 .padding(.vertical, 8)
 .background(Premium.ink.opacity(0.7))
}

private var kompaktWerkzeugLeiste: some View {
 HStack(spacing: 6) {
   Button {
     showEinschaetzungen.toggle()
     if showEinschaetzungen { showExport = false; showOpportunisma = false }
   } label: {
     Label(showEinschaetzungen ? "Analyse" : "Einschätzungen", systemImage: "book.closed")
   }
   .buttonStyle(.bordered)
   .controlSize(.small)
   .tint(showEinschaetzungen ? .blue : nil)

   Button {
     showExport.toggle()
     if showExport { showEinschaetzungen = false; showOpportunisma = false }
   } label: {
     Label(showExport ? "Analyse" : "Export", systemImage: "square.and.arrow.up")
   }
   .buttonStyle(.bordered)
   .controlSize(.small)
   .tint(showExport ? .blue : nil)

   Button {
     showOpportunisma.toggle()
     if showOpportunisma { showExport = false; showEinschaetzungen = false }
   } label: {
     Label("Opportunisma", systemImage: "chart.line.uptrend.xyaxis")
   }
   .buttonStyle(.bordered)
   .controlSize(.small)
   .tint(showOpportunisma ? .red : nil)

   Spacer(minLength: 0)
 }
 .padding(.horizontal, 10)
 .padding(.vertical, 6)
 .background(Premium.well.opacity(0.85))
}

@ViewBuilder
private var kompaktInhalt: some View {
 if showOpportunisma {
   StrategosOpportunismaReiterView(szenario: szenario)
     .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
 } else if showEinschaetzungen {
   StrategosRechtlicheEinschaetzungenView(szenario: szenario)
 } else if showExport {
   StrategosNotionExportView(szenario: szenario)
 } else {
   stepContent.padding(.bottom, 24)
 }
}

private var sidebar: some View {
 VStack(alignment: .leading, spacing: 0) {
   VStack(alignment: .leading, spacing: 4) {
     Text("Strategos Enterprise").font(.caption2.bold()).foregroundStyle(.secondary)
     Text(szenario.titel).font(.caption.bold()).lineLimit(1)
     if let rg = szenario.unternehmenskontext?.dictValue?["rechtsgebiete"] as? [String], !rg.isEmpty {
       Text("\(rg.count) Rechtsgebiet(e)").font(.caption2).foregroundStyle(.tertiary)
     } else {
       Text("Präventive Entscheidungsintelligenz").font(.caption2).foregroundStyle(.tertiary)
     }
   }
   .padding(.bottom, 12)

   sidebarPhase("AUFKLÄRUNG", steps: steps.filter { $0.num <= 2 })
   sidebarPhase("VERTRAG & IP", steps: steps.filter { $0.num >= 3 && $0.num <= 4 })
   sidebarPhase("STRATEGIE", steps: steps.filter { $0.num >= 5 })

   opportunismaReiterButton

   HStack(spacing: 6) {
     if step > 0 {
       Button("<- Zurück") { navigate(step - 1) }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small)
     }
     if step < steps.count - 1 {
       Button("Weiter ->") { navigate(step + 1) }
         .buttonStyle(FenlynineOSGlassProminentButtonStyle()).controlSize(.small)
     } else if step == steps.count - 1 {
       Button("n Neu starten") { navigate(1) }
         .buttonStyle(FenlynineOSGlassProminentButtonStyle()).controlSize(.small)
         .tint(.green)
     }
   }
   .padding(.top, 8)

   Button {
     showEinschaetzungen.toggle()
     if showEinschaetzungen { showExport = false; showOpportunisma = false }
   } label: {
     Label(showEinschaetzungen ? "<- Zurück zur Analyse" : "Rechtliche Einschätzungen", systemImage: "book.closed")
       .font(.caption)
   }
   .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
   .controlSize(.small)
   .frame(maxWidth: .infinity)
   .padding(.top, 10)

   Button {
     showExport.toggle()
     if showExport { showEinschaetzungen = false; showOpportunisma = false }
   } label: {
     Label(showExport ? "<- Zurück zur Analyse" : "Notion-Export / Übersicht", systemImage: "square.and.arrow.up")
       .font(.caption)
   }
   .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
   .controlSize(.small)
   .frame(maxWidth: .infinity)
   .padding(.top, 6)

   if let current = steps.first(where: { $0.num == step }) {
     VStack(alignment: .leading, spacing: 4) {
       Text("Dieser Schritt").font(.caption2.bold()).foregroundStyle(.secondary)
       Text(current.label).font(.caption.bold()).foregroundStyle(current.color)
       Text(current.sub).font(.caption2).foregroundStyle(.tertiary)
     }
     .padding(10)
     .frame(maxWidth: .infinity, alignment: .leading)
     .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
     .padding(.top, 14)
   }
 }
}

@ViewBuilder
private var content: some View {
 if showOpportunisma {
   StrategosOpportunismaReiterView(szenario: szenario)
     .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
 } else if showEinschaetzungen {
   StrategosRechtlicheEinschaetzungenView(szenario: szenario)
 } else if showExport {
   StrategosNotionExportView(szenario: szenario)
 } else {
   ScrollView {
     stepContent.padding(.bottom, 24)
   }
 }
}

@ViewBuilder
private var stepContent: some View {
 switch step {
 case 0:
   StrategosStep0DocIntelligenzView(
     szenario: $szenario,
     onSave: { patch in await applyPatch(patch) },
     onProceed: { navigate(1) }
   )
 case 1:
   StrategosEnterpriseStep1View(szenario: $szenario, onSave: { patch in await applyPatch(patch) })
 case 2:
   StrategosEnterpriseStep2View(szenario: $szenario, onSave: { patch in await applyPatch(patch) })
 case 3:
   StrategosEnterpriseVertragsStep(
     szenario: $szenario,
     onSave: { patch in await applyPatch(patch) },
     onOpenOpportunisma: openOpportunisma
   )
 case 4:
   StrategosEnterprisePatentStep(szenario: $szenario, onSave: { patch in await applyPatch(patch) })
 case 5:
   StrategosEnterpriseStep5HandlungsView(szenario: $szenario, onSave: { patch in await applyPatch(patch) })
 case 6:
   StrategosEnterpriseStep6QuantView(szenario: $szenario, onSave: { patch in await applyPatch(patch) })
 case 7:
   StrategosEnterpriseStep7UmsetzungView(szenario: $szenario, onSave: { patch in await applyPatch(patch) })
 default:
   EmptyView()
 }
}

@ViewBuilder
private func sidebarPhase(_ titel: String, steps phaseSteps: [EnterpriseStep]) -> some View {
 VStack(alignment: .leading, spacing: 2) {
   Text(titel)
     .font(.system(size: 8, weight: .bold))
     .foregroundStyle(.tertiary)
     .padding(.top, 6)
     .padding(.horizontal, 4)
   ForEach(phaseSteps) { s in
     stepButton(s)
   }
 }
}

private func stepButton(_ s: EnterpriseStep) -> some View {
 let active = step == s.num
 let done = stepDone(s.num)
 return Button {
   navigate(s.num)
   showExport = false
   showEinschaetzungen = false
   showOpportunisma = false
 } label: {
   HStack(spacing: 10) {
     ZStack {
       RoundedRectangle(cornerRadius: 8)
         .fill(done ? s.color : active ? s.color.opacity(0.2) : Color.gray.opacity(0.08))
         .frame(width: 26, height: 26)
       if done {
         Image(systemName: "checkmark").font(.caption2.bold()).foregroundStyle(.white)
       } else {
         Text("\(s.num)").font(.caption2.bold()).foregroundStyle(active ? s.color : .secondary)
       }
     }
     VStack(alignment: .leading, spacing: 1) {
       Text(s.label).font(.caption.bold())
         .foregroundStyle(active ? s.color : done ? .primary : .secondary)
         .lineLimit(1)
       Text(s.sub).font(.system(size: 9)).foregroundStyle(.tertiary).lineLimit(1)
     }
     Spacer(minLength: 0)
   }
   .padding(.horizontal, 10).padding(.vertical, 8)
   .background(active ? s.color.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
   .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? s.color.opacity(0.3) : Color.clear))
 }
 .buttonStyle(.plain)
}

private var opportunismaReiterButton: some View {
 VStack(alignment: .leading, spacing: 2) {
   Text("OPTIONAL")
     .font(.system(size: 8, weight: .bold))
     .foregroundStyle(.tertiary)
     .padding(.top, 10)
     .padding(.horizontal, 4)
   Button {
     showOpportunisma.toggle()
     if showOpportunisma {
       showExport = false
       showEinschaetzungen = false
     }
   } label: {
     HStack(spacing: 10) {
       ZStack {
         RoundedRectangle(cornerRadius: 8, style: .continuous)
           .fill(showOpportunisma ? Color.red.opacity(0.22) : Color.gray.opacity(0.08))
           .frame(width: 26, height: 26)
         Image(systemName: "chart.line.uptrend.xyaxis")
           .font(.caption2.bold())
           .foregroundStyle(showOpportunisma ? .red : .secondary)
       }
       VStack(alignment: .leading, spacing: 2) {
         HStack(spacing: 5) {
           Text("Opportunisma")
             .font(.caption.bold())
             .foregroundStyle(showOpportunisma ? .red : .primary)
           Text("OPTIONAL")
             .font(.system(size: 7, weight: .black))
             .foregroundStyle(.orange)
             .padding(.horizontal, 5)
             .padding(.vertical, 2)
             .background(Color.orange.opacity(0.15), in: Capsule())
         }
         Text("Fragebogen · Lagebild · Module")
           .font(.system(size: 9))
           .foregroundStyle(.tertiary)
           .lineLimit(1)
       }
       Spacer(minLength: 0)
     }
     .padding(.horizontal, 10)
     .padding(.vertical, 8)
     .background(showOpportunisma ? Color.red.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
     .overlay(
       RoundedRectangle(cornerRadius: 10, style: .continuous)
         .stroke(showOpportunisma ? Color.red.opacity(0.35) : Color.clear)
     )
   }
   .buttonStyle(.plain)
 }
}

private func stepDone(_ num: Int) -> Bool {
 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let ki = szenario.ki_analyse?.dictValue ?? [:]
 switch num {
 case 0: return szenario.ki_kontext?.dictValue?["analyse"] != nil
 case 1: return ctx.keys.count > 3
 case 2: return (sit["module"] as? [Any])?.isEmpty == false
 case 3: return ki["vertrags_analyse"] != nil
 case 4: return ki["patent_analyse"] != nil
 case 5: return ki["handlungsoptionen"] != nil
 case 6: return ki["quant_analyse"] != nil
 case 7: return ki["umsetzungsplan"] != nil
 default: return false
 }
}

private func navigate(_ n: Int) {
 showOpportunisma = false
 step = max(0, min(n, steps.count - 1))
 szenario.enterprise_step = step
 Task { await persistScenario() }
}

private func openOpportunisma() {
 showOpportunisma = true
 showExport = false
 showEinschaetzungen = false
}

private func applyPatch(_ patch: [String: Any]) async {
 if let ctx = patch["unternehmenskontext"] as? [String: Any] {
   szenario.unternehmenskontext = AnyCodable(ctx)
 }
 if let ki = patch["ki_kontext"] as? [String: Any] {
   szenario.ki_kontext = AnyCodable(ki)
 }
 if let sit = patch["situationsanalyse"] as? [String: Any] {
   szenario.situationsanalyse = AnyCodable(sit)
 }
 if let kiA = patch["ki_analyse"] as? [String: Any] {
   var existing = szenario.ki_analyse?.dictValue ?? [:]
   for (k, v) in kiA { existing[k] = v }
   szenario.ki_analyse = AnyCodable(existing)
 }
 if let v = patch["szenario_typ"] as? String { szenario.szenario_typ = v }
 if let v = patch["rechtsgebiet"] as? String { szenario.rechtsgebiet = v }
 if let v = patch["fragestellung"] as? String { szenario.fragestellung = v }
 if let v = patch["ausgangslage"] as? String { szenario.ausgangslage = v }
 if let fin = patch["finanzdaten"] as? [String: Any] {
   szenario.finanzdaten = AnyCodable(fin)
 }
 await persistScenario()
}

private func persistScenario() async {
 guard let id = szenario.id else { return }
 _ = try? await Services.strategosScenarios.update(id: id, entity: szenario)
}
}

// MARK: - Enterprise KI-Schritte 3 & 4

struct StrategosEnterpriseVertragsStep: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void
var onOpenOpportunisma: (() -> Void)? = nil
@State private var laeuft = false
@State private var fehler: String?
@State private var notiz = ""
@State private var zielFokus = "compliance"

private let zielOptionen: [(id: String, label: String)] = [
 ("compliance", "Vertrag einhalten"),
 ("schadenersatz", "Schadenersatz maximieren"),
 ("wettbewerb", "Wettbewerbsposition"),
 ("ressourcen", "Ressourcen/Steuer optimieren (legal)"),
 ("politik", "Politik & Lobby")
]

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   StrategosSchrittHeader(
     nummer: 3,
     titel: "Vertragsanalyse",
     beschreibung: "Klausel-Risiko · Kausalverhalten · Opportunisma-Entscheidungspfade"
   )

   strategosSteuerung

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   let docCount = StrategosOpportunismaVertragsService.dokumentURLs(fuer: szenario).count
   if docCount == 0 {
     Text("Hinweis: Keine gültigen Datei-Anhänge -- Analyse nutzt KI-Briefing & Kontext aus Schritt 0/1. PDFs in Schritt 0 erneut hochladen für Vollanalyse.")
       .font(.caption2).foregroundStyle(.orange)
   } else {
     Text("\(docCount) Dokument(e) für KI-Analyse verknüpft").font(.caption2).foregroundStyle(.secondary)
   }

   LabeledTextArea("Zusätzliche Notizen", text: $notiz, minHeight: 80)

   Button {
     Task { await analyse() }
   } label: {
     if laeuft { ProgressView().scaleEffect(0.7); Text("Analysiert…") }
     else { Label("Vertragsanalyse + Opportunisma-Kausalität (KI)", systemImage: "doc.text.magnifyingglass") }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(laeuft)

   if let r = szenario.ki_analyse?.dictValue?["vertrags_analyse"] as? [String: Any] {
     StrategosKIResultCard(titel: "Vertragsanalyse-Ergebnis", dict: r)
     StrategosVertragsAnalyseFormateView(vertrag: r)
     StrategosOpportunismaVertragsPanel(
       vertrag: r,
       szenario: szenario,
       onOpenOpportunismaTab: { tab in
         UserDefaults.standard.set(tab.rawValue, forKey: "opportunisma_initial_tab")
         onOpenOpportunisma?()
       }
     )
   }
 }
 .onAppear {
   let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
   zielFokus = ctx["opportunisma_ziel_fokus"] as? String
     ?? ctx["pragmatista_ziel_fokus"] as? String
     ?? "compliance"
 }
}

private var strategosSteuerung: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("Analyse-Steuerung").font(.caption.bold()).foregroundStyle(.secondary)
   HStack(spacing: 8) {
     Text("Ziel-Fokus:").font(.caption2).foregroundStyle(.secondary)
     Picker("", selection: $zielFokus) {
       ForEach(zielOptionen, id: \.id) { o in
         Text(o.label).tag(o.id)
       }
     }
     .labelsHidden()
     .frame(maxWidth: 280)
   }
   Text("Opportunisma bewertet Klauseln, Termine und Entscheidungspfade für das Unternehmen -- nicht für Einzelpersonen.")
     .font(.caption2).foregroundStyle(.tertiary)
 }
 .padding(12)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

private func analyse() async {
 laeuft = true
 fehler = nil
 defer { laeuft = false }

 var sz = szenario
 var ctx = sz.unternehmenskontext?.dictValue ?? [:]
 ctx["opportunisma_ziel_fokus"] = zielFokus
 sz.unternehmenskontext = AnyCodable(ctx)

 let notizVoll = notiz + "\nZiel-Fokus: \(zielOptionen.first { $0.id == zielFokus }?.label ?? zielFokus)"

 do {
   let dict = try await StrategosOpportunismaVertragsService.analysiereVertrag(szenario: sz, notiz: notizVoll)
   await onSave([
     "unternehmenskontext": ctx,
     "ki_analyse": ["vertrags_analyse": dict, "vertrags_notiz": notiz, "vertrags_ziel_fokus": zielFokus]
   ])
   await MainActor.run { szenario.unternehmenskontext = AnyCodable(ctx) }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct StrategosEnterprisePatentStep: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void
@State private var laeuft = false
@State private var fehler: String?

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   StrategosSchrittHeader(nummer: 4, titel: "Patentanalyse", beschreibung: "Schutzbereich · FTO · Strategische Optionen")
   if let err = fehler { Text(err).font(.caption).foregroundStyle(.red) }
   Button {
     Task { await analyse() }
   } label: {
     if laeuft { ProgressView().scaleEffect(0.7) }
     else { Label("Patent-/IP-Analyse starten (KI)", systemImage: "lightbulb.fill") }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(laeuft)
   if let r = szenario.ki_analyse?.dictValue?["patent_analyse"] as? [String: Any] {
     StrategosKIResultCard(titel: "Patentanalyse-Ergebnis", dict: r)
   }
 }
}

private func analyse() async {
 laeuft = true
 fehler = nil
 defer { laeuft = false }
 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String ?? ""

 let prompt = """
 Patent-/IP-Senior-Anwalt: FTO-Analyse, Schutzbereich, strategische Optionen.
 Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--"), Branche: \(ctx["branche"] as? String ?? "--")
 Briefing: \(String(briefing.prefix(3000)))
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "fto_status": ["type": "string"],
     "schutzrechte": ["type": "array", "items": ["type": "object"]],
     "risiken": ["type": "array", "items": ["type": "string"]],
     "strategische_optionen": ["type": "array", "items": ["type": "object"]],
     "empfehlung": ["type": "string"]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   guard let dict = try? KIJson.requireObject(response, kontext: "Patentanalyse") else {
     await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
     return
   }
   await onSave(["ki_analyse": ["patent_analyse": dict]])
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct StrategosKIResultCard: View {
let titel: String
let dict: [String: Any]

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text(titel)
     .font(.caption.bold())
     .foregroundStyle(Premium.text)
   if let emp = dict["empfehlung"] as? String ?? dict["gesamtrisiko"] as? String {
     Text(emp)
       .font(.caption)
       .foregroundStyle(Premium.text)
   }
   if let klauseln = dict["klauseln"] as? [[String: Any]], !klauseln.isEmpty {
     ForEach(Array(klauseln.prefix(5).enumerated()), id: \.offset) { _, k in
       Text("(cid:127) \(k["kurzbeschreibung"] as? String ?? k["klausel_typ"] as? String ?? "Klausel")")
         .font(.caption2)
         .foregroundStyle(Premium.textSoft)
     }
   }
 }
 .padding(12)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(Premium.well, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Premium.hairline, lineWidth: 1))
}
}

struct StrategosRechtlicheEinschaetzungenView: View {
let szenario: StrategosScenario

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("Rechtliche Einschätzungen").font(.title3.bold())
   if let va = szenario.ki_analyse?.dictValue?["vertrags_analyse"] as? [String: Any] {
     StrategosKIResultCard(titel: "Vertragsanalyse", dict: va)
     StrategosVertragsAnalyseFormateView(vertrag: va)
     StrategosOpportunismaVertragsPanel(vertrag: va, szenario: szenario)
   }
   if let p = szenario.ki_analyse?.dictValue?["patent_analyse"] as? [String: Any] {
     StrategosKIResultCard(titel: "Patentanalyse", dict: p)
   }
   if let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String {
     Text("KI-Basis-Briefing").font(.caption.bold())
     Text(briefing).font(.caption2)
   }
   if szenario.ki_analyse == nil && szenario.ki_kontext == nil {
     Text("Noch keine Analysen vorhanden.").font(.caption).foregroundStyle(.secondary)
   }
 }
}
}

struct StrategosNotionExportView: View {
let szenario: StrategosScenario
@State private var exportiert = false

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("Notion-Export / Übersicht").font(.title3.bold())
   Text("Exportiert alle Szenario-Daten als Markdown für Notion oder andere Tools.")
     .font(.caption).foregroundStyle(.secondary)
   Button(exportiert ? "3 In Zwischenablage" : "Markdown exportieren") {
     let md = buildMarkdown()
     NSPasteboard.general.clearContents()
     NSPasteboard.general.setString(md, forType: .string)
     exportiert = true
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   ScrollView {
     Text(buildMarkdown()).font(.caption2.monospaced()).textSelection(.enabled)
   }
   .frame(maxHeight: 300)
 }
}

private func buildMarkdown() -> String {
 var lines = ["# Strategos: \(szenario.titel)", ""]
 if let frage = szenario.fragestellung { lines += ["**Fragestellung:** \(frage)", ""] }
 if let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String {
   lines += ["## KI-Briefing", briefing, ""]
 }
 if let emp = szenario.strategos_empfehlung?.dictValue?["text"] as? String {
   lines += ["## Empfehlung", emp, ""]
 }
 return lines.joined(separator: "\n")
}
}

