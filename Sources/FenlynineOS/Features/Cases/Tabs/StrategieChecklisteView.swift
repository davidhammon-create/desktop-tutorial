import SwiftUI
import Charts

// MARK: - Strategie-Checkliste (wie StrategieCheckliste.jsx)

struct StrategieChecklisteView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

struct CheckItem: Identifiable {
  let id: String
  var titel: String
  var zitat: String
  var kategorie: String
  var prioritaet: String
  var empfehlung: String?
  var norm: String?
  var quelle: String
  var kiGenerated: Bool = false
}

struct KISchritteResponse: Decodable {
  var schritte: [KISchritt]?
  struct KISchritt: Decodable {
    var titel: String?
    var prinzip: String?
    var quelle: String?
    var kategorie: String?
    var empfehlung: String?
    var norm: String?
    var lit: String?
    var rspr: String?
    var prioritaet: String?
    var risiko: String?
  }
}

@State private var checklist: [CheckItem] = []
@State private var checked: Set<String> = []
@State private var expanded: Set<String> = []
@State private var kiLaeuft = false
@State private var chartMode = 0
@State private var kiFehler: String?

private var prognose: Double { viewModel.fall?.prognose ?? 50 }
private var eigenArgs: [Argument] { viewModel.argumente.filter { $0.side == .eigen } }
private var gegnerArgs: [Argument] { viewModel.argumente.filter { $0.side == .gegner } }
private var progress: Int {
  guard !checklist.isEmpty else { return 0 }
  return Int(Double(checked.count) / Double(checklist.count) * 100)
}

var body: some View {
  VStack(spacing: 16) {
    if let err = kiFehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }
    // Header
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "shield.lefthalf.filled")
        .font(.title2)
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .background(Color.primary, in: RoundedRectangle(cornerRadius: 10))

      VStack(alignment: .leading, spacing: 6) {
        Text("Strategische Checkliste -- Sun Tzu & Machiavelli")
          .font(.subheadline.bold())
        Text("Geführte nächste Schritte basierend auf Fallergebnissen, Prognosen und strategischen Prinzipien.")
          .font(.caption).foregroundStyle(.secondary)
        HStack(spacing: 8) {
          ProgressView(value: Double(progress), total: 100)
            .tint(.green)
          Text("\(progress)%").font(.caption.bold())
          Text("\(checked.count)/\(checklist.count) erledigt").font(.caption2).foregroundStyle(.secondary)
        }
      }

      if kiMode {
        Button { Task { await kiSchritteErgaenzen() } } label: {
          if kiLaeuft {
            ProgressView().scaleEffect(0.7)
            Text("KI lädt…").font(.caption)
          } else {
            Label("KI-Schritte ergänzen", systemImage: "bolt.fill")
          }
        }
        .buttonStyle(FenlynineOSGlassProminentButtonStyle())
        .tint(.purple)
        .disabled(kiLaeuft)
      }
    }
    .padding(14)
    .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

    // Stats
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
      StatChip(label: "Prognose", wert: "\(Int(prognose))%", farbe: prognose >= 55 ? .green : prognose >= 40 ? .orange : .red)
      StatChip(label: "Eigene Args", wert: "\(eigenArgs.count)", farbe: .blue)
     StatChip(label: "Gegner Args", wert: "\(gegnerArgs.count)", farbe: .red)
     StatChip(label: "Beweise", wert: "\(viewModel.beweise.count)", farbe: .purple)
     StatChip(label: "Fristen versäumt", wert: "\(viewModel.fristen.filter { $0.status == .versaeumt }.count)", farbe: .orange)
     StatChip(label: "Richterquote", wert: "\(Int(viewModel.fall?.richter_klaeger_rate ?? 50))%", farbe: .gray)
   }

   // Chart
   VStack(alignment: .leading, spacing: 8) {
     Text("Strategische Visualisierung").font(.caption.bold())
     Picker("Visualisierung", selection: $chartMode) {
       Text("sin(t) Prognose").tag(0)
       Text("f(x)=mx+b").tag(1)
       Text("3D Argument-Feld").tag(2)
       Text("Radar-Profil").tag(3)
     }
     .pickerStyle(.segmented)

     switch chartMode {
     case 0:
       LexaraPrognoseWaveChart(prognose: prognose)
     case 1:
       LexaraLinearStrategieChart(argCount: eigenArgs.count, prognose: prognose)
     case 2:
       LexaraArgumentScatterChart(argumente: viewModel.argumente, beweise: viewModel.beweise)
     default:
       let radarData: [(label: String, value: Double)] = [
         ("Argumente", eigenArgs.isEmpty ? 0 : Double(eigenArgs.reduce(0) { $0 + $1.strength }) / Double(eigenArgs.count)),
         ("Beweise", min(10, Double(viewModel.beweise.count))),
         ("Prognose", prognose / 10),
         ("Fristen", max(0, 10 - Double(viewModel.fristen.filter { $0.status == .versaeumt }.count) * 2.5)),
         ("Richter", (viewModel.fall?.richter_klaeger_rate ?? 50) / 10),
         ("Gegner", gegnerArgs.isEmpty ? 0 : Double(gegnerArgs.reduce(0) { $0 + $1.strength }) / Double(gegnerArgs.count)),
       ]
       LexaraRadarChartView(data: radarData, maxValue: 10, fillColor: .indigo, strokeColor: .indigo)
         .frame(height: 260)
     }
   }
   .padding(12)
   .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))

   // Checkliste
   if checklist.isEmpty {
     ProgressView("Lade Checkliste…")
   } else {
     ForEach(checklist) { item in
       ChecklistRow(
         item: item,
         isChecked: checked.contains(item.id),
         isExpanded: expanded.contains(item.id),
         onToggle: {
           if checked.contains(item.id) { checked.remove(item.id) }
           else { checked.insert(item.id) }
         },
         onExpand: {
           if expanded.contains(item.id) { expanded.remove(item.id) }
           else { expanded.insert(item.id) }
         }
       )
     }
   }
 }
 .onAppear { buildChecklist() }
}

private func appendDemoKISchritte(to items: inout [CheckItem]) {
 guard let schritte = viewModel.fall?.ki_berater_result?.dictValue?["strategie_checkliste_schritte"] as? [[String: Any]] else { return }
 for (i, s) in schritte.enumerated() {
   items.append(CheckItem(
     id: "ki_demo_\(i)",
     titel: s["titel"] as? String ?? "KI-Schritt",
     zitat: s["prinzip"] as? String ?? "",
     kategorie: s["kategorie"] as? String ?? "KI",
     prioritaet: s["prioritaet"] as? String ?? "mittel",
     empfehlung: s["empfehlung"] as? String ?? "",
     norm: s["norm"] as? String ?? "",
     quelle: s["quelle"] as? String ?? "suntzu",
     kiGenerated: true
   ))
 }
}

private func buildChecklist() {
 var items: [CheckItem] = []
 let versaeumt = viewModel.fristen.filter { $0.status == .versaeumt }.count

 items.append(CheckItem(
   id: "st1", titel: "Kenne deinen Feind, kenne dich selbst",
   zitat: "Wer den Feind und sich selbst kennt, wird in hundert Schlachten nicht scheitern.",
   kategorie: "Analyse", prioritaet: "hoch",
   empfehlung: "Vollständige Gegneranalyse und eigene Schwachstellen dokumentieren.",
   norm: "§ 138 ZPO, § 282 ZPO", quelle: "suntzu"
 ))

 if prognose < 45 {
   items.append(CheckItem(
     id: "st_risiko", titel: "Ressourcenschonung -- Vergleich prüfen",
     zitat: "Ein langer Krieg nützt niemandem.",
     kategorie: "Kosten", prioritaet: "kritisch",
     empfehlung: "Bei Prognose <45% Vergleichsoptionen und Kosten-Nutzen-Analyse priorisieren.",
     norm: "§§ 91 ff. ZPO", quelle: "suntzu"
   ))
 }

 if versaeumt > 0 {
   items.append(CheckItem(
     id: "st_frist", titel: "Fristen-Schaden begrenzen",
     zitat: "Reagiere auf Veränderungen schneller als der Gegner erwartet.",
     kategorie: "Prozess", prioritaet: "kritisch",
     empfehlung: "\(versaeumt) versäumte Frist(en) -- Wiedereinsetzung oder Schadensbegrenzung prüfen.",
     norm: "§ 233 ZPO", quelle: "suntzu"
   ))
 }

 if gegnerArgs.count > eigenArgs.count {
   items.append(CheckItem(
     id: "mv1", titel: "Angriff auf Schwachstellen",
     zitat: "Greife Stärke nicht frontal an -- schlage bei der Schwäche.",
     kategorie: "Taktik", prioritaet: "hoch",
     empfehlung: "Gegner hat mehr Argumente -- gezielt schwächste Gegnerargumente angreifen.",
     norm: "§ 138 ZPO", quelle: "machiavelli"
   ))
 }

 items.append(CheckItem(
   id: "mv_koalition", titel: "Streitverkündung prüfen",
   zitat: "Man soll niemals glauben, man könne immer sichere Entschlüsse fassen.",
   kategorie: "Netzwerk", prioritaet: "mittel",
   empfehlung: "§ 72 ZPO: Streitverkündung an mögliche Regress-Schuldner prüfen.",
   norm: "§ 72 ZPO", quelle: "machiavelli"
 ))

 appendDemoKISchritte(to: &items)
 checklist = items
}

private func kiSchritteErgaenzen() async {
 guard let fall = viewModel.fall else { return }
 kiLaeuft = true
 kiFehler = nil
 defer { kiLaeuft = false }

 let prompt = """
 Du bist ein Senior-Prozessanwalt. Analysiere diesen Fall und gib eine präzise Sun-Tzu & Machiavelli-basierte Strategiecheckliste aus.

 Fall: \(fall.fallname) | Rechtsgebiet: \(fall.rechtsgebiet ?? "") | Instanz: \(fall.instanz.rawValue)
 Prognose: \(Int(prognose))%
 Eigene Argumente: \(eigenArgs.count) | Gegnerargumente: \(gegnerArgs.count)
 Beweise: \(viewModel.beweise.count) | Fristen versäumt: \(viewModel.fristen.filter { $0.status == .versaeumt }.count)
 Richterquote: \(fall.richter_klaeger_rate ?? 50)%

 Erstelle GENAU 4 strategische Handlungsschritte für den nächsten Monat mit Maßnahme, Prinzip, Norm, Priorität.
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "schritte": [
       "type": "array",
       "items": [
         "type": "object",
         "properties": [
           "titel": ["type": "string"],
           "prinzip": ["type": "string"],
           "quelle": ["type": "string", "enum": ["suntzu", "machiavelli"]],
           "kategorie": ["type": "string"],
           "empfehlung": ["type": "string"],
           "norm": ["type": "string"],
           "prioritaet": ["type": "string", "enum": ["kritisch", "hoch", "mittel"]],
           "risiko": ["type": "string"]
         ]
       ]
     ]
   ]
 ]

 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: schema,
     model: "claude_sonnet_4_6",
     logCaseId: viewModel.caseId,
     logKiName: "Strategie-Checkliste -- KI-Schritte"
   )
   let schritteRaw = KIJson.array(in: d, keys: "schritte", "steps", "items")
   guard !schritteRaw.isEmpty else {
     await MainActor.run { kiFehler = "KI lieferte keine Schritte." }
     return
   }
   let kiItems = schritteRaw.enumerated().map { i, s in
     CheckItem(
       id: "ki_\(i)",
       titel: KIJson.string(in: s, keys: "titel", "title") ?? "KI-Schritt \(i + 1)",
       zitat: KIJson.string(in: s, keys: "prinzip", "zitat") ?? "",
       kategorie: KIJson.string(in: s, keys: "kategorie", "category") ?? "Taktik",
       prioritaet: KIJson.string(in: s, keys: "prioritaet", "priority") ?? "mittel",
       empfehlung: KIJson.string(in: s, keys: "empfehlung", "recommendation"),
       norm: KIJson.string(in: s, keys: "norm"),
       quelle: KIJson.string(in: s, keys: "quelle", "source") ?? "suntzu",
       kiGenerated: true
     )
   }
   await MainActor.run { checklist.append(contentsOf: kiItems) }
   if var fallUpd = viewModel.fall {
     let saved = try await KIResultStore.mergeBeraterSubKey(
       caseId: viewModel.caseId,
       fall: &fallUpd,
       key: "strategie_checkliste_schritte",
       value: schritteRaw
     )
     await MainActor.run { viewModel.fall = saved }
   }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}
}

private struct StatChip: View {
let label: String
let wert: String
let farbe: Color

var body: some View {
 VStack(spacing: 2) {
   Text(wert).font(.headline.bold()).foregroundStyle(farbe)
   Text(label).font(.system(size: 8)).multilineTextAlignment(.center).foregroundStyle(.secondary)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 8)
 .background(farbe.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
}
}

private struct ChecklistRow: View {
let item: StrategieChecklisteView.CheckItem
let isChecked: Bool
let isExpanded: Bool
let onToggle: () -> Void
let onExpand: () -> Void

var body: some View {
 VStack(spacing: 0) {
   HStack(alignment: .top, spacing: 10) {
     Button(action: onToggle) {
       Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
         .foregroundStyle(isChecked ? .green : .secondary)
     }
     .buttonStyle(.plain)

     VStack(alignment: .leading, spacing: 4) {
       HStack(spacing: 6) {
         Text(item.titel).font(.caption.bold())
           .strikethrough(isChecked)
           .foregroundStyle(isChecked ? .secondary : .primary)
         if item.kiGenerated {
           Text("KI").font(.system(size: 8, weight: .bold))
             .padding(.horizontal, 4).padding(.vertical, 1)
             .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
         }
         Text(item.prioritaet.uppercased()).font(.system(size: 8, weight: .bold))
           .padding(.horizontal, 4).padding(.vertical, 1)
           .background(prioritaetFarbe.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
       }
       Text(item.zitat).font(.caption2).italic().foregroundStyle(.secondary)
       if let e = item.empfehlung {
         Text(e).font(.caption2)
       }
     }

     Spacer()
     Button(action: onExpand) {
       Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.caption2)
     }
     .buttonStyle(.plain)
   }
   .padding(12)

   if isExpanded, let norm = item.norm {
     Text("Norm: \(norm)").font(.caption2).foregroundStyle(.secondary)
       .padding(.horizontal, 12).padding(.bottom, 10)
   }
 }
 .background(Color.gray.opacity(isChecked ? 0.02 : 0.04), in: RoundedRectangle(cornerRadius: 10))
}

private var prioritaetFarbe: Color {
 switch item.prioritaet {
 case "kritisch": return .red
 case "hoch": return .orange
 default: return .gray
 }
}
}

