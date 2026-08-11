import SwiftUI

// MARK: - Fall-Detail ViewModel

@Observable
final class CaseDetailViewModel {
var fall: LegalCase?
var argumente: [Argument] = []
var beweise: [Evidence] = []
var fristen: [Deadline] = []
var personen: [Person] = []
var dokumente: [LegalDocument] = []
var aufgaben: [CaseTask] = []
var timeline: [TimelineEvent] = []
var warnungen: [CaseWarning] = []
var gegnerVerhalten: [GegnerVerhalten] = []
var luecken: [LegalLoophole] = []
var caseId: String
var isLoading = false
var error: String?
var vollanalyse: VollanalyseErgebnis?
var kiFallanalyse: KIFallanalyseErgebnis? = nil
var analyseFehler: String? = nil
var analyseLaeuft = false
var kiMode: Bool = UserDefaults.standard.object(forKey: "lexara_ki_mode") as? Bool ?? true

struct KIFallanalyseErgebnis {
  var erfolgswahrscheinlichkeit: Int
  var begruendung: String
  var staerksteGegenargumente: [(titel: String, gefahr: String, schwere: String)]
  var kritischeSchwachstellen: [(titel: String, beschreibung: String)]
  var strategischeEmpfehlung: String
  var gegenmassnahmen: [(massnahme: String, ziel: String, rechtsgrundlage: String, aggressivitaet: String)]
}

init(caseId: String) {
  self.caseId = caseId
}

func toggleKiMode() {
  kiMode.toggle()
  UserDefaults.standard.set(kiMode, forKey: "lexara_ki_mode")
}

@MainActor
func laden() async {
  isLoading = true
  defer { isLoading = false }
  error = nil

  do {
    let f = try await Services.cases.get(id: caseId)
    async let args = Services.arguments.listForCase(caseId: caseId)
    async let evid = Services.evidence.listForCase(caseId: caseId)
    async let dead = Services.deadlines.listForCase(caseId: caseId)
    async let pers = Services.persons.listForCase(caseId: caseId)
    async let docs = Services.documents.listForCase(caseId: caseId)
    async let tasks = Services.tasks.listForCase(caseId: caseId)
    async let tl = Services.timelineEvents.listForCase(caseId: caseId)
    async let warns = Services.caseWarnings.listForCase(caseId: caseId)
    async let gv = Services.gegnerVerhalten.listForCase(caseId: caseId)

    let (a, e, d, p, doc, t, tl2, w, g) = try await (args, evid, dead, pers, docs, tasks, tl, warns, gv)

    fall = f
    argumente = a
    beweise = e
    fristen = d
    personen = p
    dokumente = doc
    aufgaben = t
    timeline = tl2
    warnungen = w
    gegnerVerhalten = g
    luecken = (try? await Services.legalLoopholes.listForCase(caseId: caseId)) ?? []
    vollanalyseBerechnen()
  } catch {
    self.error = error.localizedDescription
  }
}

@MainActor
func vollanalyseBerechnen() {
  guard let fall else { return }
  let args = argumente
  let evs = beweise
  let dead = fristen
  let pers = personen
  Task.detached {
    let ergebnis = LegalAlgorithmsService.computeVollanalyse(
      args: args,
      evidence: evs,
      deadlines: dead,
      persons: pers,
      caseData: fall
    )
    await MainActor.run { [weak self] in
      self?.vollanalyse = ergebnis
    }
 }
}

@MainActor
func vollstaendigeAnalyseStarten() async {
 guard let fall else { return }
 analyseLaeuft = true
 analyseFehler = nil
 defer { analyseLaeuft = false }

 vollanalyseBerechnen()

 guard kiMode else { return }

 let eigenA = argumente.filter { $0.side == .eigen }
 let gegnerA = argumente.filter { $0.side == .gegner }
 let versaeumt = fristen.filter { $0.status == .versaeumt }.count

 let prompt = """
 Du bist ein erfahrener Prozessanwalt auf Senior-Partner-Niveau. Gib klare Einschätzungen mit §§ und BGH/BVerfG-Urteilen.

 Fall: \(fall.fallname)
 Rechtsgebiet: \(fall.rechtsgebiet ?? "") | Instanz: \(fall.instanz.rawValue)
 Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")

 EIGENE ARGUMENTE:
 \(eigenA.map { "- \($0.title) (Stärke: \($0.strength)/10): \($0.description ?? "")" }.joined(separator: "\n"))

 GEGNERARGUMENTE:
 \(gegnerA.map { "- \($0.title) (Stärke: \($0.strength)/10): \($0.description ?? "")" }.joined(separator: "\n"))

 BEWEISE: \(beweise.prefix(10).map { "\($0.title) (\($0.type.rawValue), \($0.weight)/10)" }.joined(separator: ", "))
 FRISTEN: \(fristen.count) gesamt, \(versaeumt) versäumt
 Richter-Klägerquote: \(fall.richter_klaeger_rate.map { "\(Int($0))%" } ?? "50%")

 Enthalte: Erfolgswahrscheinlichkeit, 3 stärkste Gegenargumente, 2 kritische Schwachstellen, strategische Empfehlung, juristische Gegenmaßnahmen.
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "erfolgswahrscheinlichkeit": ["type": "number"],
       "begruendung": ["type": "string"],
       "staerkste_gegenargumente": ["type": "array", "items": ["type": "object", "properties": [
         "titel": ["type": "string"], "gefahr": ["type": "string"], "schwere": ["type": "string"]
       ]]],
       "kritische_schwachstellen": ["type": "array", "items": ["type": "object", "properties": [
         "titel": ["type": "string"], "beschreibung": ["type": "string"]
       ]]],
       "strategische_empfehlung": ["type": "string"],
       "gegenmassnahmen": ["type": "array", "items": ["type": "object", "properties": [
         "massnahme": ["type": "string"], "ziel": ["type": "string"],
         "rechtsgrundlage": ["type": "string"], "aggressivitaet": ["type": "string"]
       ]]]
     ]] as [String: Any],
     model: "claude_sonnet_4_6"
   )
   guard let d = result.dictValue else {
     analyseFehler = "KI-Analyse lieferte kein Ergebnis."
     return
   }
   let gegen = (d["staerkste_gegenargumente"] as? [[String: Any]] ?? []).map {
     (titel: $0["titel"] as? String ?? "", gefahr: $0["gefahr"] as? String ?? "", schwere: $0["schwere"] as? String ?? "mittel")
   }
   let schwach = (d["kritische_schwachstellen"] as? [[String: Any]] ?? []).map {
     (titel: $0["titel"] as? String ?? "", beschreibung: $0["beschreibung"] as? String ?? "")
   }
   let massnahmen = (d["gegenmassnahmen"] as? [[String: Any]] ?? []).map {
     (massnahme: $0["massnahme"] as? String ?? "", ziel: $0["ziel"] as? String ?? "",
     rechtsgrundlage: $0["rechtsgrundlage"] as? String ?? "", aggressivitaet: $0["aggressivitaet"] as? String ?? "")
   }
   kiFallanalyse = KIFallanalyseErgebnis(
     erfolgswahrscheinlichkeit: KIJson.intValue(d["erfolgswahrscheinlichkeit"]) ?? Int(fall.prognose ?? 50),
     begruendung: d["begruendung"] as? String ?? "",
     staerksteGegenargumente: gegen,
     kritischeSchwachstellen: schwach,
     strategischeEmpfehlung: d["strategische_empfehlung"] as? String ?? "",
     gegenmassnahmen: massnahmen
   )
   let ausgabe = (try? JSONSerialization.data(withJSONObject: d)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
   await KIProtokollService.log(
     caseId: caseId,
     kiName: "KI-Urteilsprognose & Strategie",
     eingabe: prompt,
     ausgabe: ausgabe,
     modell: "claude_sonnet_4_6"
   )
 } catch {
   analyseFehler = "KI-Analyse fehlgeschlagen: \(error.localizedDescription)"
 }
}

@MainActor
func fallSpeichern() async throws {
 guard let fall else { return }
 let updated = try await Services.cases.update(id: caseId, entity: fall)
 self.fall = updated
}
}

// MARK: - 11-Tab-Fall-Detailansicht

enum CaseTab: Int, CaseIterable, Identifiable {
case basisdaten = 0
case fallsubstanz = 1
case akteure = 2
case gegneranalyse = 3
case rechtlicheAnalyse = 4
case strategie = 5
case simulation = 6
case aktion = 7
case machtEinfluss = 8
case pfadgraf = 9
case abschluss = 10
case cockpit = 11
case kiProtokoll = 12

var id: Int { rawValue }

var bezeichnung: String {
 switch self {
 case .basisdaten: return "Fallakte"
 case .fallsubstanz: return "Substanz"
 case .akteure: return "Akteure & Fristen"
 case .gegneranalyse: return "Gegner"
 case .rechtlicheAnalyse: return "Recht & Compliance"
 case .strategie: return "Strategie"
 case .simulation: return "Simulation"
 case .aktion: return "Aktion"
 case .machtEinfluss: return "Macht & Einfluss"
 case .pfadgraf: return "Pfadgraf"
 case .abschluss: return "Abschluss"
 case .cockpit: return "Cockpit"
 case .kiProtokoll: return "KI-Protokoll"
 }
}

var symbol: String {
 switch self {
 case .basisdaten: return "info.circle"
 case .fallsubstanz: return "doc.text.magnifyingglass"
 case .akteure: return "person.2.fill"
 case .gegneranalyse: return "person.crop.circle.badge.exclamationmark"
 case .rechtlicheAnalyse: return "scale.3d"
 case .strategie: return "shield.lefthalf.filled"
 case .simulation: return "function"
 case .aktion: return "bolt.circle"
 case .machtEinfluss: return "crown.fill"
 case .pfadgraf: return "point.3.connected.trianglepath.dotted"
 case .abschluss: return "checkmark.seal"
 case .cockpit: return "gauge"
 case .kiProtokoll: return "brain"
 }
}
}

struct CaseDetailView: View {
let caseId: String
@Binding var faelleSichtbar: Bool
var onMandateOeffnen: (() -> Void)? = nil
@State private var viewModel: CaseDetailViewModel
@State private var selectedTab: CaseTab = .basisdaten
@State private var zeigeAnalyseStarten = false

init(
 caseId: String,
 faelleSichtbar: Binding<Bool> = .constant(false),
 onMandateOeffnen: (() -> Void)? = nil
) {
 self.caseId = caseId
 _faelleSichtbar = faelleSichtbar
 self.onMandateOeffnen = onMandateOeffnen
 _viewModel = State(initialValue: CaseDetailViewModel(caseId: caseId))
}

var body: some View {
 VStack(spacing: 0) {
   if let fall = viewModel.fall {
     HStack(spacing: 8) {
       Button {
         if let onMandateOeffnen {
           onMandateOeffnen()
         } else {
           withAnimation { faelleSichtbar = true }
         }
       } label: {
         Label("Mandate", systemImage: "folder.fill")
           .font(LexaraFiligranTokens.tabLabelAktiv)
       }
       .buttonStyle(.plain)
       .foregroundStyle(FenlynineOSTheme.accent)
       Spacer()
     }
     .padding(.horizontal, LexaraFiligranTokens.contentPadding)
     .padding(.top, 6)

     CaseTabBar(selectedTab: $selectedTab, fall: fall, viewModel: viewModel)
       .padding(.horizontal, LexaraFiligranTokens.contentPadding)
       .padding(.vertical, 6)

     Divider()

     CaseDetailHeader(fall: fall, viewModel: viewModel)
     CaseIntelligenceScoreView(fall: fall)
     Divider()

     MacVerticalScrollView(bottomInset: 100) {
       VStack(alignment: .leading, spacing: 12) {
         VerfahrensBegruendungView(viewModel: viewModel)
         tabInhalt
       }
       .padding(LexaraFiligranTokens.contentPadding)
       .frame(maxWidth: .infinity, alignment: .topLeading)
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
   } else if viewModel.isLoading {
     ProgressView("Fall wird geladen…")
       .frame(maxWidth: .infinity, maxHeight: .infinity)
   } else if let error = viewModel.error {
     ContentUnavailableView(
       "Fehler",
       systemImage: "exclamationmark.triangle",
       description: Text(error)
     )
   }
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
 .navigationTitle(viewModel.fall?.fallname ?? "Fall")
 .navigationSubtitle(viewModel.fall?.aktenzeichen ?? "")
 .toolbar(content: {
   CaseDetailToolbar(viewModel: viewModel, onAnalyse: {
     Task {
       await viewModel.vollstaendigeAnalyseStarten()
       if viewModel.kiFallanalyse != nil {
         zeigeAnalyseStarten = true
       }
     }
   })
 })
 .sheet(isPresented: $zeigeAnalyseStarten) {
   if let ki = viewModel.kiFallanalyse {
     KIFallanalyseSheet(ergebnis: ki)
   }
 }
 .task { await viewModel.laden() }
}

@ViewBuilder
private var tabInhalt: some View {
 switch selectedTab {
 case .basisdaten:
   TabFallakte(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .fallsubstanz:
   TabFallsubstanz(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .akteure:
   TabAkteureFristen(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .gegneranalyse:
   TabGegneranalyse(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .rechtlicheAnalyse:
   TabRechtlicheAnalyse(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .strategie:
   TabStrategiePrognose(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .simulation:
   TabSimulationCockpit(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .aktion:
   TabAktionVoll(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .machtEinfluss:
   TabMachtEinfluss(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .pfadgraf:
   TabPfadgraf(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .abschluss:
   TabAbschluss(viewModel: viewModel, kiMode: viewModel.kiMode)
 case .cockpit:
   TabCockpit(viewModel: viewModel)
 case .kiProtokoll:
   TabKIProtokoll(viewModel: viewModel)
 }
}
}

// MARK: - Fall-Header

struct CaseDetailHeader: View {
let fall: LegalCase
let viewModel: CaseDetailViewModel

var body: some View {
 FenlynineOSGlassBar {
   HStack(alignment: .center, spacing: 20) {
     VStack(alignment: .leading, spacing: 8) {
       HStack(spacing: 8) {
         Image(systemName: fall.status.symbol)
           .foregroundStyle(statusFarbe)
         Text(fall.status.rawValue)
           .font(.system(size: 11, weight: .bold))
           .foregroundStyle(statusFarbe)
         Text("·")
           .foregroundStyle(.tertiary)
         Text(fall.instanz.rawValue)
           .font(.system(size: 11))
           .foregroundStyle(.secondary)
         if let rg = fall.rechtsgebiet {
           Text("·")
             .foregroundStyle(.tertiary)
           Text(rg)
             .font(.system(size: 11, weight: .semibold))
             .foregroundStyle(FenlynineOSDesign.accent)
         }
       }

       Text(fall.fallname)
         .font(LexaraFiligranTokens.fallTitel)
         .lineLimit(2)

       if let gericht = fall.gericht {
         Label(gericht, systemImage: "building.columns.fill")
           .font(.caption)
           .foregroundStyle(.secondary)
       }
     }

     Spacer()

     HStack(spacing: 10) {
       if let prognose = fall.prognose {
         FenlynineOSMetricChip(
           titel: "Prognose",
           wert: "\(Int(prognose))%",
           farbe: prognose >= 65 ? .green : prognose >= 45 ? .orange : .red,
           transparenz: .fallPrognoseChip(prognose: prognose, vollanalyse: viewModel.vollanalyse)
         )
       }
       if let sw = fall.streitwert {
         FenlynineOSMetricChip(
           titel: "Streitwert",
           wert: sw.formatted(.currency(code: "EUR")),
           farbe: .blue,
           compact: true
         )
       }
       FenlynineOSMetricChip(titel: "Argumente", wert: "\(viewModel.argumente.count)", farbe: .indigo, compact: true)
       FenlynineOSMetricChip(titel: "Beweise", wert: "\(viewModel.beweise.count)", farbe: .teal, compact: true)
     }
   }
 }
}

private var statusFarbe: Color {
 switch fall.status {
 case .aktiv: return .green
 case .vorbereitung: return .blue
 case .abgeschlossen: return .gray
 case .ruhend: return .orange
 }
}
}

struct HeaderChip: View {
let titel: String
let wert: String
let farbe: Color

var body: some View {
 VStack(spacing: 2) {
   Text(wert)
     .font(.system(size: 14, weight: .bold))
     .foregroundStyle(farbe)
   Text(titel)
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
 }
 .padding(.horizontal, 12)
 .padding(.vertical, 8)
 .background(farbe.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
}
}

// MARK: - Tab-Leiste

struct CaseTabBar: View {
@Binding var selectedTab: CaseTab
let fall: LegalCase
let viewModel: CaseDetailViewModel

var body: some View {
 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 2) {
     ForEach(CaseTab.allCases) { tab in
       CaseTabButton(
         tab: tab,
         isSelected: selectedTab == tab,
         badge: badgeCount(for: tab)
       ) {
         withAnimation(.easeInOut(duration: 0.15)) {
           selectedTab = tab
         }
       }
     }
   }
 }
 .frame(height: LexaraFiligranTokens.tabBarHoehe)
}

private func badgeCount(for tab: CaseTab) -> Int? {
 switch tab {
 case .rechtlicheAnalyse:
   let criticals = viewModel.warnungen.filter { $0.severity == .kritisch && !$0.resolved }.count
   return criticals > 0 ? criticals : nil
 case .aktion:
   return viewModel.aufgaben.filter { $0.status == .offen }.count > 0
     ? viewModel.aufgaben.filter { $0.status == .offen }.count : nil
 default:
   return nil
 }
}
}

struct CaseTabButton: View {
let tab: CaseTab
let isSelected: Bool
let badge: Int?
let action: () -> Void

var body: some View {
 Button(action: action) {
   HStack(spacing: 4) {
     Image(systemName: tab.symbol)
       .font(LexaraFiligranTokens.tabIcon)
     Text(tab.bezeichnung)
       .font(isSelected ? LexaraFiligranTokens.tabLabelAktiv : LexaraFiligranTokens.tabLabel)
       .lineLimit(1)
     if let badge, badge > 0 {
       Text("\(badge)")
         .font(.system(size: 8, weight: .bold))
         .foregroundStyle(.white)
         .padding(.horizontal, 4)
         .padding(.vertical, 1)
         .background { VisionOSGlasFlaeche.button(stil: .primaerBlau) }
     }
   }
   .foregroundStyle(isSelected ? .white : FenlynineOSTheme.textSecondary)
   .padding(.horizontal, 8)
   .padding(.vertical, 5)
   .background {
     if isSelected {
       VisionOSGlasFlaeche.sidebarZeile(aktiv: true, cornerRadius: 8)
     } else {
       Color.clear
     }
   }
 }
 .buttonStyle(.plain)
}
}

// MARK: - Toolbar

struct CaseDetailToolbar: ToolbarContent {
let viewModel: CaseDetailViewModel
let onAnalyse: () -> Void
@State private var exportiert = false

var body: some ToolbarContent {
 ToolbarItemGroup(placement: .primaryAction) {
   // KI-Modus / Manuell Toggle (wie Original)
   Button {
     viewModel.toggleKiMode()
   } label: {
     Label(viewModel.kiMode ? "KI-Modus" : "Manuell", systemImage: viewModel.kiMode ? "brain.fill" : "hand.raised.fill")
   }
   .help(viewModel.kiMode ? "KI-Modus aktiv -- KI-Buttons verfügbar" : "Manuell-Modus -- KI-Buttons deaktiviert")

   Divider()

   // PDF-Export
   Button {
     Task { await pdfExportieren() }
   } label: {
     if exportiert {
       ProgressView().scaleEffect(0.7)
     } else {
       Image(systemName: "doc.richtext")
     }
   }
   .help("Fallbericht als PDF exportieren")

   // CSV-Export
   Button {
     Task { await csvExportieren() }
   } label: {
     Image(systemName: "tablecells")
   }
   .help("Falldaten als CSV exportieren")

   // Supabase-Export
   Button {
     Task { await supabaseExportieren() }
   } label: {
     Image(systemName: "icloud.and.arrow.up")
   }
   .help("Daten nach Supabase exportieren")

   Divider()

   if viewModel.analyseLaeuft {
     ProgressView().scaleEffect(0.7)
       .help("KI-Analyse läuft…")
   } else {
     Button {
       onAnalyse()
     } label: {
       Label("KI-Analyse", systemImage: "brain.fill")
     }
     .help(viewModel.kiMode ? "Algorithmus + KI-Fallanalyse starten" : "Nur algorithmische Analyse (Manuell-Modus)")
     .disabled(viewModel.fall == nil)
   }

   if let err = viewModel.analyseFehler {
     Image(systemName: "exclamationmark.triangle.fill")
       .foregroundStyle(.red)
       .help(err)
   }

   Button {
     Task { try? await viewModel.fallSpeichern() }
   } label: {
     Image(systemName: "square.and.arrow.down")
   }
   .help("Fall speichern")
 }
}

private func pdfExportieren() async {
 guard let fall = viewModel.fall else { return }
 exportiert = true
 defer { exportiert = false }
 if let url = try? await FunctionService.shared.exportCasePDF(caseId: fall.id ?? "") {
   NSWorkspace.shared.open(url)
 }
}

private func csvExportieren() async {
 guard let fall = viewModel.fall, let caseId = fall.id else { return }
 let args = viewModel.argumente
 let evs = viewModel.beweise
 let pers = viewModel.personen
 let dead = viewModel.fristen

 var lines: [String] = []
 lines.append("=== FALLDATEN ===")
 lines.append("Fallname,\(fall.fallname)")
 lines.append("Aktenzeichen,\(fall.aktenzeichen ?? "")")
 lines.append("Gericht,\(fall.gericht ?? "")")
 lines.append("Rechtsgebiet,\(fall.rechtsgebiet ?? "")")
 lines.append("Status,\(fall.status.rawValue)")
 lines.append("Prognose,\(fall.prognose.map { "\(Int($0))%" } ?? "")")
 lines.append("Streitwert,\(fall.streitwert.map { "\(Int($0))" } ?? "") EUR")
 lines.append("")
 lines.append("=== ARGUMENTE ===")
 lines.append("Titel,Seite,Stärke")
 args.forEach { lines.append("\"\($0.title)\",\($0.side.rawValue),\(Int($0.effectiveStrength))") }
 lines.append("")
 lines.append("=== BEWEISE ===")
 lines.append("Titel,Typ,Gewicht")
 evs.forEach { lines.append("\"\($0.title)\",\($0.type.rawValue),\(Int($0.effectiveWeight))") }
 lines.append("")
 lines.append("=== PERSONEN ===")
 lines.append("Name,Rolle")
 pers.forEach { lines.append("\"\($0.name)\",\($0.role.rawValue)") }
 lines.append("")
 lines.append("=== FRISTEN ===")
 lines.append("Titel,Fristtyp,Fälligkeitsdatum,Status")
 dead.forEach { lines.append("\"\($0.title)\",\($0.frist_type.rawValue),\($0.due_date.formatted(date: .abbreviated, time: .omitted)),\($0.status.rawValue)") }

 let csv = lines.joined(separator: "\n")
 let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
 let safeName = FenlynineOSSecurity.sanitizedFileName(fall.fallname)
 let fileURL = downloadsURL.appendingPathComponent("Fallbericht_\(safeName)_\(caseId).csv")
 let bom = "\u{FEFF}"
 try? (bom + csv).write(to: fileURL, atomically: true, encoding: .utf8)
 NSWorkspace.shared.open(fileURL)
}

private func supabaseExportieren() async {
 guard let caseId = viewModel.fall?.id else { return }
 do {
   _ = try await FunctionService.shared.exportToSupabase(caseId: caseId)
 } catch {
   // Export-Fehler werden bewusst still gelassen -- optionaler Cloud-Export
 }
}
}

// MARK: - KI-Fallanalyse Ergebnis-Sheet

struct KIFallanalyseSheet: View {
let ergebnis: CaseDetailViewModel.KIFallanalyseErgebnis
@Environment(\.dismiss) private var dismiss

var body: some View {
 NavigationStack {
   ScrollView {
     VStack(alignment: .leading, spacing: 16) {
       HStack(spacing: 16) {
         Text("\(ergebnis.erfolgswahrscheinlichkeit)%")
           .font(.system(size: 42, weight: .bold, design: .rounded))
           .foregroundStyle(ergebnis.erfolgswahrscheinlichkeit >= 60 ? .green : ergebnis.erfolgswahrscheinlichkeit >= 40 ? .orange : .red)
         VStack(alignment: .leading) {
           HStack(spacing: 4) {
             Text("KI-Erfolgswahrscheinlichkeit").font(.caption.bold())
             FenlynineOSTransparenzInfoButton(inhalt: .kiFallanalyse(ergebnis))
           }
           Text(ergebnis.begruendung).font(.caption).lineSpacing(3)
         }
       }

       if !ergebnis.staerksteGegenargumente.isEmpty {
         Text("Stärkste Gegenargumente").font(.headline)
         ForEach(Array(ergebnis.staerksteGegenargumente.enumerated()), id: \.offset) { _, g in
           VStack(alignment: .leading, spacing: 4) {
             Text("[\(g.schwere.uppercased())] \(g.titel)").font(.caption.bold())
             Text(g.gefahr).font(.caption2)
           }
           .padding(10)
           .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
         }
       }

       if !ergebnis.kritischeSchwachstellen.isEmpty {
         Text("Kritische Schwachstellen").font(.headline)
         ForEach(Array(ergebnis.kritischeSchwachstellen.enumerated()), id: \.offset) { _, s in
           VStack(alignment: .leading, spacing: 2) {
             Text(s.titel).font(.caption.bold())
             Text(s.beschreibung).font(.caption2)
           }
         }
       }

       if !ergebnis.strategischeEmpfehlung.isEmpty {
         KIProfilKarte(
           titel: "Strategische Empfehlung",
           inhalt: ergebnis.strategischeEmpfehlung,
           transparenz: .kiModul(
             titel: "Strategische Empfehlung",
             begruendung: ergebnis.begruendung,
             ausgabe: ergebnis.strategischeEmpfehlung
           )
         )
       }

       if !ergebnis.gegenmassnahmen.isEmpty {
         Text("Juristische Gegenmaßnahmen").font(.headline)
         ForEach(Array(ergebnis.gegenmassnahmen.enumerated()), id: \.offset) { _, m in
           Text("(cid:127) \(m.massnahme) (\(m.rechtsgrundlage)) -- \(m.ziel)")
             .font(.caption)
         }
       }
     }
     .padding(20)
   }
   .navigationTitle("KI-Fallanalyse")
   .toolbar {
     ToolbarItem(placement: .confirmationAction) {
       Button("Schließen") { dismiss() }
     }
   }
 }
 .frame(minWidth: 520, minHeight: 480)
}
}

