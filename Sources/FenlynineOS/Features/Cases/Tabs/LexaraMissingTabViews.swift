#if false
// Excluded: duplicate definitions elsewhere in target
import SwiftUI
import Charts

// MARK: - Fehlende Lexara-Haupttabs (Verdrahtung bestehender Module)

struct TabStrategie: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

var body: some View {
  VStack(spacing: 20) {
    if let fall = viewModel.fall {
      AlgorithmPrognoseKarte(
        fall: fall,
        argumente: viewModel.argumente,
        beweise: viewModel.beweise,
        fristen: viewModel.fristen
      )
    }
    TabPrognoseVergleichView(viewModel: viewModel, kiMode: kiMode)
  }
}
}

struct TabSimulation: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

private var vollanalyse: VollanalyseErgebnis? {
  viewModel.vollanalyse ?? computedVollanalyse
}

private var computedVollanalyse: VollanalyseErgebnis? {
  guard let fall = viewModel.fall else { return nil }
  return LegalAlgorithmsService.computeVollanalyse(
    args: viewModel.argumente,
    evidence: viewModel.beweise,
    deadlines: viewModel.fristen,
    persons: viewModel.personen,
    caseData: fall
  )
}

var body: some View {
  VStack(spacing: 20) {
    if let mc = vollanalyse?.monteCarlo {
      MonteCarloLexaraPanel(ergebnis: mc, prognose: vollanalyse?.prognose)
    } else {
      ProgressView("Monte-Carlo-Berechnung…")
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    TabRisiko(viewModel: viewModel)
  }
}
}

struct MonteCarloLexaraPanel: View {
let ergebnis: MonteCarloErgebnis
let prognose: PrognoseErgebnis?

var body: some View {
  VStack(alignment: .leading, spacing: 14) {
    Label("Monte Carlo & Risiko", systemImage: "dice.fill")
      .font(.title2.bold())

    HStack(spacing: 16) {
      mcStat("Median", wert: ergebnis.median, farbe: .blue)
      mcStat("P10", wert: ergebnis.p10, farbe: .red)
      mcStat("P90", wert: ergebnis.p90, farbe: .green)
      mcStat("Mittel", wert: ergebnis.mean, farbe: .orange)
    }

    Text("\(ergebnis.iterationen.formatted()) Simulationen · Best Case \(ergebnis.szenarien.bestCase.wahrscheinlichkeit)% · Worst Case \(ergebnis.szenarien.worstCase.wahrscheinlichkeit)%")
      .font(.caption2)
      .foregroundStyle(.secondary)

    Chart(ergebnis.histogram) { bin in
      BarMark(x: .value("Bin", bin.bin), y: .value("Count", bin.count))
        .foregroundStyle(.orange.gradient)
    }
    .frame(height: 140)

    if let p = prognose {
      Text("Bayes-Prognose: \(p.score)% · 90%-KI [\(p.ciLow)-\(p.ciHigh)]% · s \(String(format: "%.1f", p.sigma * 100))pp")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
  .padding(14)
  .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
}

private func mcStat(_ titel: String, wert: Int, farbe: Color) -> some View {
  VStack(spacing: 2) {
    Text("\(wert)%").font(.title3.bold()).foregroundStyle(farbe)
    Text(titel).font(.caption2).foregroundStyle(.secondary)
  }
 .frame(maxWidth: .infinity)
}
}

struct TabGegneranalyse: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var subTab = 0

var body: some View {
 VStack(spacing: 0) {
   Picker("", selection: $subTab) {
     Text("KI-Berater").tag(0)
     Text("Profil & Simulation").tag(1)
   }
   .pickerStyle(.segmented)
   .padding(.bottom, 16)

   if subTab == 0 {
     TabKIBeraterView(viewModel: viewModel, kiMode: kiMode)
   } else {
     GegnerProfilSimulationView(viewModel: viewModel, kiMode: kiMode)
   }
 }
}
}

struct TabRechtlicheAnalyse: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var laeuft = false
@State private var fehler: String?

var body: some View {
 VStack(spacing: 20) {
   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   if let ki = viewModel.fall?.ki_berater_result?.dictValue {
     rechtlicheEinordnungPanel(ki)
     issueSpottingPanel(ki)
   }

   compliancePanel

   if kiMode {
     Button {
       Task { await issueSpottingStarten() }
     } label: {
       if laeuft {
         ProgressView().scaleEffect(0.7)
         Text("KI analysiert…")
       } else {
         Label("Issue Spotting (KI)", systemImage: "wand.and.stars")
       }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(laeuft)
   }
 }
 .onAppear { /* ki_berater_result wird oben angezeigt */ }
}

@ViewBuilder
private func rechtlicheEinordnungPanel(_ ki: [String: Any]) -> some View {
 if let re = ki["rechtliche_einordnung"] as? [String: Any] {
   VStack(alignment: .leading, spacing: 8) {
     Label("Rechtliche Einordnung", systemImage: "scale.3d").font(.headline)
     if let schema = re["pruefungsschema"] as? String {
       Text("Prüfungsschema: \(schema)").font(.caption)
     }
     if let ansprueche = re["anspruchsgrundlagen"] as? [String], !ansprueche.isEmpty {
       Text("Anspruchsgrundlagen: \(ansprueche.joined(separator: " · "))").font(.caption2)
     }
     if let schwach = re["kritische_schwachstellen"] as? [String], !schwach.isEmpty {
       Text("Schwachstellen: \(schwach.joined(separator: "; "))").font(.caption2).foregroundStyle(.orange)
     }
   }
   .padding(14)
   .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 }
}

@ViewBuilder
private func issueSpottingPanel(_ ki: [String: Any]) -> some View {
 let issues = ki["issue_spotting"] as? [[String: Any]] ?? []
 if !issues.isEmpty {
   VStack(alignment: .leading, spacing: 8) {
     Label("Issue Spotting", systemImage: "exclamationmark.triangle.fill").font(.headline)
     ForEach(Array(issues.enumerated()), id: \.offset) { _, item in
       HStack(alignment: .top) {
         Text(item["prioritaet"] as? String ?? "mittel")
           .font(.caption2.bold())
           .padding(.horizontal, 6).padding(.vertical, 2)
           .background(Color.orange.opacity(0.15), in: Capsule())
         VStack(alignment: .leading, spacing: 2) {
           Text(item["risiko"] as? String ?? "").font(.caption.bold())
           Text(item["empfehlung"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
         }
       }
     }
   }
   .padding(14)
   .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 }
}

private var compliancePanel: some View {
 VStack(alignment: .leading, spacing: 8) {
   Label("Compliance & Warnungen", systemImage: "shield.checkered").font(.headline)
   let offen = viewModel.warnungen.filter { !$0.resolved }
   if offen.isEmpty {
     Text("Keine offenen Compliance-Warnungen.").font(.caption).foregroundStyle(.secondary)
   } else {
     ForEach(offen) { w in
       HStack {
         Text(w.severity.rawValue.capitalized).font(.caption2.bold())
           .foregroundStyle(w.severity == .kritisch ? .red : .orange)
         Text(w.title).font(.caption)
       }
     }
   }
   if let cc = viewModel.fall?.ki_berater_result?.dictValue?["compliance_check"] as? [String: Any],
    let status = cc["status"] as? String {
     Text("KI-Compliance: \(status)").font(.caption2).foregroundStyle(.green)
   }
 }
 .padding(14)
 .background(Color.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

private func issueSpottingStarten() async {
 guard var fall = viewModel.fall else { return }
 laeuft = true
 fehler = nil
 defer { laeuft = false }

 let prompt = """
 Issue Spotting für Fall \(fall.fallname) (\(fall.rechtsgebiet ?? "")):
 Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "--")
 Argumente: \(viewModel.argumente.map(\.title).joined(separator: "; "))
 Identifiziere Risiken mit Kategorie, Priorität und Empfehlung.
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "issue_spotting": ["type": "array", "items": ["type": "object", "properties": [
           "risiko": ["type": "string"], "kategorie": ["type": "string"],
           "empfehlung": ["type": "string"], "prioritaet": ["type": "string"]
         ]]]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6",
     logCaseId: viewModel.caseId,
     logKiName: "Issue Spotting"
   )
   let dict = try KIJson.requireObject(result, kontext: "Issue Spotting")
   let saved = try await KIResultStore.mergeBeraterSubKey(
     caseId: viewModel.caseId,
     fall: &fall,
     key: "issue_spotting",
     value: dict["issue_spotting"] ?? []
   )
   await MainActor.run { viewModel.fall = saved }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct TabFallakte: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

@State private var fallname = ""
@State private var aktenzeichen = ""
@State private var gericht = ""
@State private var rechtsgebiet = ""
@State private var prozessziel = ""
@State private var zentraleRechtsfrage = ""
@State private var mandantName = ""
@State private var prognose = 50.0
@State private var streitwert = ""
@State private var notes = ""
@State private var speichert = false
@State private var gespeichert = false
@State private var fehler: String?

var body: some View {
 VStack(spacing: 16) {
   Label("Fallakte -- Basisdaten", systemImage: "info.circle.fill")
     .font(.title2.bold())
     .frame(maxWidth: .infinity, alignment: .leading)

   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
     fallFeld("Fallname", text: $fallname)
     fallFeld("Aktenzeichen", text: $aktenzeichen)
     fallFeld("Gericht", text: $gericht)
     fallFeld("Rechtsgebiet", text: $rechtsgebiet)
     fallFeld("Mandant", text: $mandantName)
     fallFeld("Streitwert (€)", text: $streitwert)
   }

   fallFeld("Prozessziel", text: $prozessziel)
   fallFeld("Zentrale Rechtsfrage", text: $zentraleRechtsfrage)

   VStack(alignment: .leading, spacing: 4) {
     Text("Manuelle Prognose: \(Int(prognose))%").font(.caption)
     Slider(value: $prognose, in: 0...100, step: 1)
   }

   TextField("Notizen", text: $notes, axis: .vertical)
     .lineLimit(3...6)
     .textFieldStyle(.roundedBorder)

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   Button(gespeichert ? "3 Gespeichert" : "Fallakte speichern") {
     Task { await speichern() }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(speichert || fallname.isEmpty)

   if !viewModel.dokumente.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Text("Dokumente (\(viewModel.dokumente.count))").font(.headline)
       ForEach(viewModel.dokumente) { doc in
         HStack {
           Text(doc.title).font(.caption)
           Spacer()
           Text(doc.kategorie.rawValue).font(.caption2).foregroundStyle(.secondary)
         }
       }
     }
     .padding(12)
     .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
   }
 }
 .onAppear { hydrate() }
 .onChange(of: viewModel.fall?.id) { _, _ in hydrate() }
}

private func fallFeld(_ label: String, text: Binding<String>) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(label).font(.caption).foregroundStyle(.secondary)
   TextField(label, text: text).textFieldStyle(.roundedBorder)
 }
}

private func hydrate() {
 guard let f = viewModel.fall else { return }
 fallname = f.fallname
 aktenzeichen = f.aktenzeichen ?? ""
 gericht = f.gericht ?? ""
 rechtsgebiet = f.rechtsgebiet ?? ""
 prozessziel = f.prozessziel ?? ""
 zentraleRechtsfrage = f.zentrale_rechtsfrage ?? ""
 mandantName = f.mandant_name ?? ""
 prognose = f.prognose ?? 50
 streitwert = f.streitwert.map { String(Int($0)) } ?? ""
 notes = f.notes ?? ""
}

private func speichern() async {
 guard var f = viewModel.fall else { return }
 speichert = true
 fehler = nil
 defer { speichert = false }
 f.fallname = fallname
 f.aktenzeichen = aktenzeichen.isEmpty ? nil : aktenzeichen
 f.gericht = gericht.isEmpty ? nil : gericht
 f.rechtsgebiet = rechtsgebiet.isEmpty ? nil : rechtsgebiet
 f.prozessziel = prozessziel.isEmpty ? nil : prozessziel
 f.zentrale_rechtsfrage = zentraleRechtsfrage.isEmpty ? nil : zentraleRechtsfrage
 f.mandant_name = mandantName.isEmpty ? nil : mandantName
 f.prognose = prognose
 f.streitwert = Double(streitwert.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "."))
 f.notes = notes.isEmpty ? nil : notes
 do {
   let saved = try await Services.cases.update(id: viewModel.caseId, entity: f)
   await MainActor.run {
     viewModel.fall = saved
     gespeichert = true
     viewModel.vollanalyseBerechnen()
   }
   try? await Task.sleep(nanoseconds: 2_000_000_000)
   await MainActor.run { gespeichert = false }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct TabCockpit: View {
let viewModel: CaseDetailViewModel

var body: some View {
 VStack(spacing: 20) {
   VerhandlungsCockpit(viewModel: viewModel, kiMode: viewModel.kiMode)
   if let v = viewModel.vollanalyse {
     BreakEvenView(ergebnis: v.breakEven)
   }
 }
}
}

struct TabKIProtokoll: View {
let viewModel: CaseDetailViewModel
@State private var logs: [KIUsageLog] = []
@State private var laeuft = false

var body: some View {
 VStack(spacing: 16) {
   Label("KI-Protokoll", systemImage: "brain.head.profile")
     .font(.title2.bold())
     .frame(maxWidth: .infinity, alignment: .leading)

   if laeuft {
     ProgressView()
   } else if logs.isEmpty {
     InfoHinweis(titel: "Noch keine KI-Aufrufe", nachricht: "Starten Sie KI-Analysen in den Lexara-Reitern -- alle Aufrufe werden hier protokolliert.", symbol: "brain")
   } else {
     ForEach(logs) { log in
       VStack(alignment: .leading, spacing: 4) {
         HStack {
           Text(log.ki_function).font(.caption.bold())
           Spacer()
           Text(log.model ?? "--").font(.caption2).foregroundStyle(.secondary)
         }
         Text(log.output ?? "").font(.caption2).foregroundStyle(.secondary).lineLimit(4)
         if let ts = log.created_at {
           Text(ts.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.tertiary)
         }
       }
       .padding(10)
       .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
     }
   }
 }
 .task { await laden() }
}

private func laden() async {
 laeuft = true
 defer { laeuft = false }
 let all = (try? await Services.kiUsageLogs.list()) ?? []
 await MainActor.run {
   logs = all.filter { $0.case_id == viewModel.caseId }.sorted {
     ($0.created_at ?? .distantPast) > ($1.created_at ?? .distantPast)
   }
 }
}
}

struct TabAktion: View {
let viewModel: CaseDetailViewModel

var body: some View {
 VStack(spacing: 16) {
   HStack {
     Label("Aktionsplan & Aufgaben", systemImage: "bolt.circle.fill")
       .font(.title2.bold())
     Spacer()
     Text("\(viewModel.aufgaben.filter { $0.status == .offen }.count) offen")
       .font(.caption.bold())
       .foregroundStyle(.orange)
   }

   if viewModel.aufgaben.isEmpty {
     InfoHinweis(titel: "Keine Aufgaben", nachricht: "Legen Sie Aufgaben im Mandantenportal oder über Fristen an.", symbol: "checklist")
   } else {
     ForEach(viewModel.aufgaben) { task in
       HStack {
         Image(systemName: task.status == .erledigt ? "checkmark.circle.fill" : "circle")
           .foregroundStyle(task.status == .erledigt ? .green : .secondary)
         VStack(alignment: .leading, spacing: 2) {
           Text(task.title).font(.caption.bold())
           if let faellig = task.due_date {
             Text(faellig.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
           }
         }
         Spacer()
         Text(task.status.rawValue).font(.caption2)
       }
       .padding(10)
       .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
     }
   }
 }
}
}

#endif

