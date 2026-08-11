import SwiftUI
import Charts

// MARK: - Lagebild-Ansicht (Lexara / Strategos / Gesamt)

enum LagebildAnsicht: String, CaseIterable, Identifiable {
case lexara
case strategos
case kombiniert

var id: String { rawValue }

var label: String {
  switch self {
  case .lexara: return "Nur Lexara"
  case .strategos: return "Nur Strategos"
  case .kombiniert: return "Lexara + Strategos"
  }
}

var symbol: String {
  switch self {
  case .lexara: return "folder.fill"
  case .strategos: return "chart.line.uptrend.xyaxis"
  case .kombiniert: return "square.grid.2x2.fill"
  }
}
}

struct LagebildPanelLabels {
let lageTitel: String
let lageMetrik: String
let lageZiel: String
let radarTitel: String
let radarUntertitel: String
let strategienTitel: String
let risikoTitel: String
let schritteTitel: String
let zeitplanTitel: String
let letzteTitel: String

static func fuer(_ ansicht: LagebildAnsicht) -> LagebildPanelLabels {
  switch ansicht {
  case .lexara:
    return .init(
      lageTitel: "FALL-PROGNOSE",
      lageMetrik: "ERFOLGSWAHRSCHEINLICHKEIT",
      lageZiel: "VERFAHRENSZIEL",
      radarTitel: "SUBSTANZ-RADAR",
      radarUntertitel: "LEXARA -- ARGUMENTE & BEWEISE",
      strategienTitel: "VERFAHRENSSTRATEGIEN",
      risikoTitel: "VERFAHRENSRISIKEN",
      schritteTitel: "LEXARA-AUFGABEN",
      zeitplanTitel: "FRISTENPLAN",
      letzteTitel: "LEXARA-MANDATE"
    )
  case .strategos:
    return .init(
      lageTitel: "SZENARIO-ERFOLG",
      lageMetrik: "OPTIONSWAHRSCHEINLICHKEIT",
      lageZiel: "UNTERNEHMENSZIEL",
      radarTitel: "MACHTBALANCE",
      radarUntertitel: "STRATEGOS -- EXPOSURE & HEBEL",
      strategienTitel: "HANDLUNGSOPTIONEN",
      risikoTitel: "UNTERNEHMENSRISIKEN",
      schritteTitel: "STRATEGOS-MASSNAHMEN",
      zeitplanTitel: "UMSETZUNGSPLAN",
      letzteTitel: "STRATEGOS-SZENARIEN"
    )
  case .kombiniert:
    return .init(
      lageTitel: "GESAMT-LAGE",
      lageMetrik: "KOORDINIERTE PROGNOSE",
      lageZiel: "GESAMTZIEL",
      radarTitel: "KOORDINATIONS-RADAR",
      radarUntertitel: "LEXARA x STRATEGOS",
      strategienTitel: "STRATEGIE-MIX",
      risikoTitel: "RISIKO-AGGREGAT",
      schritteTitel: "NÄCHSTE SCHRITTE",
      zeitplanTitel: "GESAMT-ZEITPLAN",
      letzteTitel: "MANDATE & SZENARIEN"
    )
  }
}
}

struct LagebildSchritt: Identifiable {
let id = UUID()
let titel: String
let datum: Date?
let quelle: String
var caseId: String? = nil
var scenarioId: String? = nil
}

// MARK: - Dashboard ViewModel

@Observable
final class HomeViewModel {
var faelle: [LegalCase] = []
var aufgaben: [CaseTask] = []
var fristen: [Deadline] = []
var dokumente: [LegalDocument] = []
var szenarien: [StrategosScenario] = []
var isLoading = false
var error: String?

var aktiveFaelle: Int { faelle.filter { $0.status == .aktiv }.count }
var kritischeFristen: [Deadline] { fristen.filter { $0.istKritisch && !$0.istVersaeumt } }
var versaeumt: [Deadline] { fristen.filter { $0.istVersaeumt } }
var durchschnittlichePrognose: Double {
 let p = faelle.compactMap(\.prognose)
 return p.isEmpty ? 50 : p.reduce(0, +) / Double(p.count)
}
var offeneAufgaben: Int { aufgaben.filter { $0.status == .offen || $0.status == .inBearbeitung }.count }
var intelligenceCount: Int { faelle.filter { $0.ki_berater_result != nil }.count }
var simulationCount: Int { szenarien.filter { !$0.abgeschlossen }.count }

var prognoseStufe: String {
 let p = durchschnittlichePrognose
 if p >= 70 { return "HOCH" }
 if p >= 45 { return "MITTEL" }
 return "NIEDRIG"
}

var machtBalance: [String: Double] {
 let prognose = durchschnittlichePrognose
 let timing = max(0, 100 - Double(kritischeFristen.count + versaeumt.count) * 15)
 let ressourcen = max(20, 100 - Double(offeneAufgaben) * 8)
 let beweise = min(100, Double(dokumente.count) * 6 + 20)
 let argumente = min(100, Double(faelle.count) * 12 + Double(aktiveFaelle) * 5)
 let oeffentlichkeit = faelle.contains { ($0.streitwert ?? 0) > 100_000 } ? 65.0 : 40.0
 return [
   "Recht": prognose,
   "Beweise": beweise,
   "Argumente": argumente,
   "Ressourcen": ressourcen,
   "Timing": timing,
   "Öffentliche Wahrnehmung": oeffentlichkeit
 ]
}

var freigegebeneDokumente: Int { dokumente.filter { !$0.vertraulich }.count }

var aktiveStrategien: [(name: String, pct: Int)] {
 let total = max(1, faelle.count)
 let verteidigung = faelle.filter { $0.status == .vorbereitung || ($0.prognose ?? 50) < 45 }.count
 let angriff = faelle.filter { ($0.prognose ?? 0) >= 65 && $0.status == .aktiv }.count
 let verhandlung = faelle.filter { ($0.vergleichsangebot ?? 0) > 0 }.count
 let erledigt = aufgaben.filter { $0.status == .erledigt }.count
 let risiko = max(40, 100 - Int(durchschnittlichePrognose * 0.25) - kritischeFristen.count * 5)
 let compliance = aufgaben.isEmpty ? 0 : Int(Double(erledigt) / Double(aufgaben.count) * 100)
 return [
   ("Verteidigung & Absicherung", min(100, verteidigung * 100 / total + 40)),
   ("Angriff & Durchsetzung", min(100, angriff * 100 / total + 30)),
   ("Einfluss & Verhandlung", min(100, verhandlung * 100 / total + 50)),
   ("Reputation & Narrative", min(100, Int(durchschnittlichePrognose))),
   ("Risiko & Schadensbegrenzung", max(compliance, risiko))
 ]
}

var risikoItems: [(label: String, level: FenlynineOSRiskDot.Level)] {
 let prognose = durchschnittlichePrognose
 return [
   ("Gegenseite", prognose < 45 ? .hoch : prognose < 60 ? .mittel : .niedrig),
   ("Öffentlichkeit", faelle.contains { ($0.streitwert ?? 0) > 200_000 } ? .mittel : .niedrig),
   ("Zeitdruck", !kritischeFristen.isEmpty ? .mittel : versaeumt.isEmpty ? .niedrig : .hoch),
   ("Beweisrisiken", !versaeumt.isEmpty ? .hoch : dokumente.count < faelle.count ? .mittel : .niedrig),
   ("Kostenrisiken", faelle.contains { ($0.streitwert ?? 0) > 500_000 } ? .mittel : .niedrig)
 ]
}

var naechsteSchritte: [CaseTask] {
 aufgaben
   .filter { $0.status == .offen || $0.status == .inBearbeitung }
   .sorted { ($0.due_date ?? .distantFuture) < ($1.due_date ?? .distantFuture) }
}

private static let ganttPhasenNamen = ["Analyse", "Vorbereitung", "Durchsetzung", "Verhandlung", "Abschluss"]

var ganttPhasen: [(name: String, start: Date, end: Date)] {
 let cal = Calendar.current
 let now = Date()
 let sorted = fristen.filter { $0.status == .offen }.sorted { $0.due_date < $1.due_date }
 guard !sorted.isEmpty else {
   return Self.ganttPhasenNamen.enumerated().map { i, name in
     let start = cal.date(byAdding: .month, value: i, to: now) ?? now
     let end = cal.date(byAdding: .month, value: i + 1, to: now) ?? start
     return (name, start, end)
   }
 }
 var result: [(String, Date, Date)] = []
 var cursor = now
 for (i, f) in sorted.prefix(5).enumerated() {
   let name = Self.ganttPhasenNamen[min(i, Self.ganttPhasenNamen.count - 1)]
   result.append((name, cursor, f.due_date))
   cursor = f.due_date
 }
 return result
}

struct PrognoseSegment: Identifiable {
 let id = UUID()
 let bereich: String
 let count: Int
 let farbe: Color
}

struct StatusSegment: Identifiable {
 let id = UUID()
 let status: LegalCase.CaseStatus
 let count: Int
}

struct FristenTag: Identifiable {
 let id = UUID()
 let datum: Date
 let anzahl: Int
}

var prognoseVerteilung: [PrognoseSegment] {
 [
   PrognoseSegment(bereich: "< 30%", count: faelle.filter { ($0.prognose ?? 50) < 30 }.count, farbe: FenlynineOSTheme.chartPrimary.opacity(0.45)),
   PrognoseSegment(bereich: "30-50%", count: faelle.filter { let p = $0.prognose ?? 50; return p >= 30 && p < 50 }.count, farbe: FenlynineOSTheme.chartPrimary.opacity(0.65)),
   PrognoseSegment(bereich: "50-70%", count: faelle.filter { let p = $0.prognose ?? 50; return p >= 50 && p < 70 }.count, farbe: FenlynineOSTheme.chartPrimary),
   PrognoseSegment(bereich: "> 70%", count: faelle.filter { ($0.prognose ?? 50) >= 70 }.count, farbe: FenlynineOSTheme.chartSecondary)
 ]
}

var fristenKalender: [FristenTag] {
 let jetzt = Date()
 let kalender = Calendar.current
 return (0..<14).compactMap { offset -> FristenTag? in
   guard let datum = kalender.date(byAdding: .day, value: offset, to: jetzt) else { return nil }
   let count = fristen.filter { f in kalender.isDate(f.due_date, inSameDayAs: datum) && f.status == .offen }.count
   return FristenTag(datum: datum, anzahl: count)
 }
}

@MainActor
func laden() async {
 isLoading = true
 defer { isLoading = false }
 error = nil
 do {
   async let f = Services.cases.list()
   async let a = Services.tasks.list()
   async let fr = Services.deadlines.list()
   async let d = Services.documents.list()
   async let s = Services.strategosScenarios.list()
   let (loadedFaelle, loadedAufgaben, loadedFristen, loadedDocs, loadedSzen) = try await (f, a, fr, d, s)
   faelle = loadedFaelle
   aufgaben = loadedAufgaben
   fristen = loadedFristen
   dokumente = loadedDocs
   szenarien = loadedSzen
 } catch {
   self.error = error.localizedDescription
 }
}

// MARK: - Strategos-Aggregation

var offeneSzenarien: [StrategosScenario] { szenarien.filter { !$0.abgeschlossen } }

var strategosErfolgsIndex: Double {
 let werte = offeneSzenarien.compactMap { sz -> Double? in
   if let r = sz.situationsanalyse?.dictValue?["gesamt_risiko"] as? Double {
     return max(20, min(95, 100 - r * 8))
   }
   if let r = sz.situationsanalyse?.dictValue?["gesamt_risiko"] as? Int {
     return max(20, min(95, 100 - Double(r) * 8))
   }
   if let opts = sz.ki_analyse?.dictValue?["handlungsoptionen"] as? [String: Any],
    let optionen = opts["optionen"] as? [[String: Any]] {
     let pcts = optionen.compactMap { KIJson.intValue($0["erfolg_pct"]) }
     if !pcts.isEmpty { return Double(pcts.reduce(0, +)) / Double(pcts.count) }
   }
   return 58
 }
 return werte.isEmpty ? 58 : werte.reduce(0, +) / Double(werte.count)
}

var strategosMachtBalance: [String: Double] {
 var balance: [String: Double] = [
   "Vertrag": 62, "Compliance": 70, "Finanzen": 55,
   "Politik": 48, "Operativ": 65, "Reputation": 60
 ]
 for sz in offeneSzenarien.prefix(3) {
   if let module = sz.situationsanalyse?.dictValue?["module"] as? [[String: Any]] {
     for m in module {
       let rg = m["rechtsgebiet"] as? String ?? "Vertrag"
       let score = KIJson.numberValue(m["risiko_score"]) ?? 5
       balance[rg.prefix(12).description, default: 50] = max(25, 100 - score * 10)
     }
   }
   if let exp = sz.finanzdaten?.dictValue?["exposure"] as? Double {
     balance["Finanzen"] = max(30, min(90, 100 - exp / 10_000))
   }
 }
 return balance
}

var strategosHandlungsoptionen: [(name: String, pct: Int)] {
 offeneSzenarien.flatMap { sz -> [(String, Int)] in
   guard let opts = sz.ki_analyse?.dictValue?["handlungsoptionen"] as? [String: Any],
      let optionen = opts["optionen"] as? [[String: Any]] else { return [] }
   return optionen.compactMap { o in
     guard let name = o["name"] as? String else { return nil }
     return (name, KIJson.intValue(o["erfolg_pct"]) ?? 50)
   }
 }
}

var strategosRisikoItems: [(label: String, level: FenlynineOSRiskDot.Level)] {
 var items: [(String, FenlynineOSRiskDot.Level)] = []
 for sz in offeneSzenarien.prefix(4) {
   if let krit = sz.situationsanalyse?.dictValue?["kritische_punkte"] as? [String] {
     for k in krit.prefix(2) {
       items.append((k, .mittel))
     }
   }
   if let exp = sz.finanzdaten?.dictValue?["exposure"] as? Double, exp > 300_000 {
     items.append(("Exposure \(Int(exp / 1000))k€", .hoch))
   }
 }
 if items.isEmpty {
   items = [
     ("Vertragsrisiko", .mittel), ("Compliance", .niedrig),
     ("Finanzexposure", .mittel), ("Umsetzung", .niedrig)
   ]
 }
 return Array(items.prefix(5))
}

var strategosMassnahmen: [LagebildSchritt] {
 offeneSzenarien.flatMap { sz -> [LagebildSchritt] in
   var schritte: [LagebildSchritt] = []
   if let plan = sz.aktionsplan?.dictValue?["massnahmen"] as? [[String: Any]] {
     for m in plan.prefix(3) {
       schritte.append(LagebildSchritt(
         titel: m["titel"] as? String ?? "Maßnahme",
         datum: nil,
         quelle: "Strategos",
         scenarioId: sz.id
       ))
     }
   }
   if let sofort = sz.ki_analyse?.dictValue?["umsetzungsplan"] as? [String: Any],
    let liste = sofort["umsetzung_sofort"] as? [String] {
     for s in liste.prefix(2) {
       schritte.append(LagebildSchritt(
         titel: s,
         datum: nil,
         quelle: "Strategos",
         scenarioId: sz.id
       ))
     }
   }
   return schritte
 }
}

var strategosGanttPhasen: [(name: String, start: Date, end: Date)] {
 let cal = Calendar.current
 let now = Date()
 var phasen: [(String, Date, Date)] = []
 for (i, sz) in offeneSzenarien.prefix(3).enumerated() {
   let step = sz.enterprise_step
   let name = "\(sz.titel.prefix(24))…"
   let start = cal.date(byAdding: .month, value: i, to: now) ?? now
   let end = cal.date(byAdding: .month, value: i + max(1, step / 2), to: now) ?? start
   phasen.append((name, start, end))
 }
 if phasen.isEmpty {
   return Self.ganttPhasenNamen.enumerated().map { i, name in
     let start = cal.date(byAdding: .month, value: i, to: now) ?? now
     let end = cal.date(byAdding: .month, value: i + 1, to: now) ?? start
     return (name, start, end)
   }
 }
 return phasen
}

// MARK: - Ansichtsabhängige Werte

func hauptPrognose(fuer ansicht: LagebildAnsicht) -> Double {
 switch ansicht {
 case .lexara: return durchschnittlichePrognose
 case .strategos: return strategosErfolgsIndex
 case .kombiniert: return (durchschnittlichePrognose + strategosErfolgsIndex) / 2
 }
}

func prognoseStufe(fuer ansicht: LagebildAnsicht) -> String {
 let p = hauptPrognose(fuer: ansicht)
 if p >= 70 { return "HOCH" }
 if p >= 45 { return "MITTEL" }
 return "NIEDRIG"
}

func machtBalance(fuer ansicht: LagebildAnsicht) -> [String: Double] {
 switch ansicht {
 case .lexara: return machtBalance
 case .strategos: return strategosMachtBalance
 case .kombiniert:
   let lex = machtBalance
   let strat = strategosMachtBalance
   return [
     "Verfahren": lex["Recht"] ?? 50,
     "Beweise": lex["Beweise"] ?? 50,
     "Vertrag": strat["Vertrag"] ?? 50,
     "Finanzen": strat["Finanzen"] ?? 50,
     "Timing": lex["Timing"] ?? 50,
     "Unternehmen": strat["Operativ"] ?? 50
   ]
 }
}

func strategien(fuer ansicht: LagebildAnsicht) -> [(name: String, pct: Int)] {
 switch ansicht {
 case .lexara: return aktiveStrategien
 case .strategos:
   let opts = strategosHandlungsoptionen
   return opts.isEmpty ? [("Enterprise-Analyse", 58), ("Vertragsoptionen", 52)] : Array(opts.prefix(5))
 case .kombiniert:
   let mix = aktiveStrategien.prefix(3) + strategosHandlungsoptionen.prefix(3).map { ($0.name, $0.pct) }
   return mix.isEmpty ? aktiveStrategien : Array(mix)
 }
}

func risikoListe(fuer ansicht: LagebildAnsicht) -> [(label: String, level: FenlynineOSRiskDot.Level)] {
 switch ansicht {
 case .lexara: return risikoItems
 case .strategos: return strategosRisikoItems
 case .kombiniert:
   var seen = Set<String>()
   return (risikoItems + strategosRisikoItems).filter { seen.insert($0.label).inserted }.prefix(6).map { $0 }
 }
}

func schritteListe(fuer ansicht: LagebildAnsicht) -> [LagebildSchritt] {
 switch ansicht {
 case .lexara:
   return naechsteSchritte.map {
     LagebildSchritt(
       titel: $0.title,
       datum: $0.due_date,
       quelle: "Lexara",
       caseId: $0.case_id
     )
   }
 case .strategos: return strategosMassnahmen
 case .kombiniert:
   let lex = naechsteSchritte.prefix(3).map {
     LagebildSchritt(
       titel: $0.title,
       datum: $0.due_date,
       quelle: "Lexara",
       caseId: $0.case_id
     )
   }
   return lex + strategosMassnahmen.prefix(3)
 }
}

func gantt(fuer ansicht: LagebildAnsicht) -> [(name: String, start: Date, end: Date)] {
 switch ansicht {
 case .lexara: return ganttPhasen
 case .strategos: return strategosGanttPhasen
 case .kombiniert:
   return Array((ganttPhasen.prefix(3) + strategosGanttPhasen.prefix(3)))
 }
}

/// KPI-Karten: Werte aus echten Fall-/Szenario-Daten, keine Platzhalter-Prozente
func aktiveMandateKPI(fuer ansicht: LagebildAnsicht) -> (wert: String, trend: Double?, trendLabel: String) {
 switch ansicht {
 case .lexara, .kombiniert:
   let aktiv = aktiveFaelle
   guard aktiv > 0 else { return ("0", nil, "") }
   let anteil = faelle.isEmpty ? 0 : Double(aktiv) / Double(faelle.count) * 100
   return ("\(aktiv)", anteil, "Aktiv")
 case .strategos:
   let n = offeneSzenarien.count
   guard n > 0 else { return ("0", nil, "") }
   return ("\(n)", strategosErfolgsIndex, "Offen")
 }
}

func kritischeFristenKPI(fuer ansicht: LagebildAnsicht) -> (wert: String, trend: Double?, trendLabel: String) {
 let n = kritischeFristen.count + (ansicht == .strategos ? 0 : versaeumt.count)
 guard n > 0 else { return ("0", nil, "") }
 let dringlichkeit = min(100, Double(n) * 18 + Double(versaeumt.count) * 25)
 return ("\(n)", -dringlichkeit, versaeumt.isEmpty ? "Dringend" : "Überfällig")
}

func prognoseAkzent(fuer ansicht: LagebildAnsicht) -> Color {
 let p = hauptPrognose(fuer: ansicht)
 if p >= 70 { return LagebildHRTokens.successGreen }
 if p >= 45 { return LagebildHRTokens.primaryBlue }
 return LagebildHRTokens.alertRed
}
}

// MARK: - Command Dashboard (FENLYNINEOS MOBIL)

struct HomeView: View {
var inVisionPanel: Bool = true
@State private var viewModel = HomeViewModel()
@State private var ansicht: LagebildAnsicht = .kombiniert
@EnvironmentObject var appState: AppState
@EnvironmentObject var authManager: AuthManager
@Environment(\.fenlynineOSFensterModus) private var fensterModus
@State private var zeigeFallAnalyse = false

private var labels: LagebildPanelLabels { LagebildPanelLabels.fuer(ansicht) }

private var tagesgruß: String {
 let h = Calendar.current.component(.hour, from: Date())
 if h < 12 { return "Guten Morgen" }
 if h < 18 { return "Guten Tag" }
 return "Guten Abend"
}

var body: some View {
 MacVerticalScrollView {
   VStack(spacing: fensterModus ? 10 : LagebildHRTokens.gridSpacing) {
     hrHeader
     hrTopRow
     if !fensterModus {
       hrMiddleRow
       hrBottomRow
     }
     CommandDashboardFooter(
       intelligenceCount: viewModel.intelligenceCount,
       dokumentCount: viewModel.dokumente.count,
       freigegebenCount: viewModel.freigegebeneDokumente,
       simulationCount: max(viewModel.simulationCount, 1),
       onIntelligence: { appState.navigateToSidebar(.analytik) },
       onDokumente: { appState.navigateToSidebar(.dokumente) },
       onSimulationen: { appState.navigateToSidebar(.strategos) }
     )
     if !fensterModus {
       letzteSection
     }
   }
   .padding(fensterModus ? 10 : 16)
   .frame(maxWidth: .infinity, alignment: .topLeading)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .navigationTitle(inVisionPanel || fensterModus ? "" : "Lagebild & Übersicht")
 .toolbar {
   ToolbarItem(placement: .primaryAction) {
     VisionOSGlasButton(titel: "Fall-Analyse", symbol: "brain.head.profile", stil: .primaerBlau, kompakt: true) {
       zeigeFallAnalyse = true
     }
   }
   ToolbarItem(placement: .primaryAction) {
     VisionOSGlasIconButton(symbol: "arrow.clockwise", groesse: 36) {
       Task { await viewModel.laden() }
     }
   }
 }
 .sheet(isPresented: $zeigeFallAnalyse) {
   FallAnalyseModalView(faelle: viewModel.faelle)
 }
 .task { await viewModel.laden() }
 .refreshable { await viewModel.laden() }
 .overlay {
   if viewModel.isLoading {
     ProgressView()
       .tint(LagebildHRTokens.primaryBlue)
       .padding(20)
       .background { VisionOSGlasFlaeche.widget(cornerRadius: 20, elevated: false) }
   }
 }
}

// MARK: - HR-Layout (Bild 3)

private var hrHeader: some View {
 HStack(alignment: .center, spacing: 12) {
   VStack(alignment: .leading, spacing: 2) {
     Text("\(tagesgruß),")
       .font(LagebildHRTokens.welcomeGreeting)
       .foregroundStyle(LagebildHRTokens.textSecondary)
     Text(authManager.userName.uppercased())
       .font(LagebildHRTokens.welcomeName)
       .foregroundStyle(LagebildHRTokens.textPrimary)
       .lineLimit(2)
       .fixedSize(horizontal: false, vertical: true)
   }
   Spacer(minLength: 8)
   VisionOSGlasSegmentedPicker(
     optionen: LagebildAnsicht.allCases.map { ($0, $0.label, $0.symbol) },
     auswahl: $ansicht
   )
   .frame(maxWidth: 340)
   HStack(spacing: 10) {
     ZStack(alignment: .topTrailing) {
       Image(systemName: "bell.fill")
         .font(.system(size: 13))
         .foregroundStyle(LagebildHRTokens.textSecondary)
       if !viewModel.kritischeFristen.isEmpty {
         Circle()
           .fill(LagebildHRTokens.alertRed)
           .frame(width: 6, height: 6)
           .offset(x: 2, y: -2)
       }
     }
     Circle()
       .fill(LagebildHRTokens.primaryBlue.opacity(0.35))
       .frame(width: 32, height: 32)
       .overlay {
         Text(String(authManager.userName.prefix(1)).uppercased())
           .font(.system(size: 13, weight: .bold))
           .foregroundStyle(.white)
       }
   }
 }
 .padding(.bottom, 4)
}

private var hrTopRow: some View {
 HStack(alignment: .top, spacing: LagebildHRTokens.gridSpacing) {
   strategischeLagePanel
     .frame(maxWidth: .infinity)
   aktiveStrategienPanel
     .frame(maxWidth: .infinity)
   VStack(spacing: LagebildHRTokens.gridSpacing) {
     let mandateKPI = viewModel.aktiveMandateKPI(fuer: ansicht)
     let fristenKPI = viewModel.kritischeFristenKPI(fuer: ansicht)
     LagebildHRKPIMiniCard(
       titel: ansicht == .strategos ? "Offene Szenarien" : "Aktive Mandate",
       wert: mandateKPI.wert,
       trend: mandateKPI.trend,
       trendLabel: mandateKPI.trendLabel,
       action: { appState.navigateToSidebar(ansicht == .strategos ? .strategos : .lexara) }
     )
     LagebildHRKPIMiniCard(
       titel: "Kritische Fristen",
       wert: fristenKPI.wert,
       trend: fristenKPI.trend,
       trendLabel: fristenKPI.trendLabel,
       action: { appState.navigateToSidebar(.zeitleiste) }
     )
   }
   .frame(width: LagebildHRTokens.kpiCardWidth)
 }
}

private var hrMiddleRow: some View {
 HStack(alignment: .top, spacing: LagebildHRTokens.gridSpacing) {
   naechsteSchrittePanel
     .frame(maxWidth: .infinity)
   machtbalancePanel
     .frame(maxWidth: .infinity)
   risikoanalysePanel
     .frame(maxWidth: .infinity)
 }
}

private var hrBottomRow: some View {
 zeitplanPanel
}

private var strategischeLagePanel: some View {
 let prognose = Int(viewModel.hauptPrognose(fuer: ansicht))
 return LagebildHRWidget(titel: labels.lageTitel, minHoehe: 168) {
   HStack(alignment: .top, spacing: 12) {
     FenlynineOSPrognoseRing(wert: prognose, groesse: 72)
     VStack(alignment: .leading, spacing: 6) {
       Text(labels.lageMetrik)
         .font(LagebildHRTokens.widgetMeta)
         .foregroundStyle(LagebildHRTokens.textSecondary)
         .lineLimit(2)
         .fixedSize(horizontal: false, vertical: true)
       Text(viewModel.prognoseStufe(fuer: ansicht))
         .font(LagebildHRTokens.widgetValue)
         .foregroundStyle(LagebildHRTokens.primaryBlue)
       LagebildHRProgressRow(
         label: labels.lageZiel,
         wert: viewModel.hauptPrognose(fuer: ansicht),
         suffix: "\(prognose)%"
       )
       LagebildHRProgressRow(
         label: "Offene Aufgaben",
         wert: min(100, Double(viewModel.offeneAufgaben) * 12),
         farbe: viewModel.offeneAufgaben > 5 ? LagebildHRTokens.alertRed : LagebildHRTokens.successGreen,
         suffix: "\(viewModel.offeneAufgaben)"
       )
     }
   }
   HStack(spacing: 8) {
     MacOSSettingsPrimaryButton(titel: "Fall-Analyse", symbol: "brain.head.profile") {
       zeigeFallAnalyse = true
     }
     Button { appState.navigateToSidebar(.lexara) } label: {
       Text("Mandate")
         .font(.system(size: 13, weight: .medium))
         .foregroundStyle(.white)
         .padding(.horizontal, 14)
         .padding(.vertical, 6)
         .background {
           RoundedRectangle(cornerRadius: 6, style: .continuous)
             .fill(Color.white.opacity(0.10))
             .overlay(
               RoundedRectangle(cornerRadius: 6, style: .continuous)
                 .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
             )
         }
     }
     .buttonStyle(.plain)
   }
   .padding(.top, 4)
 }
}

private var machtbalancePanel: some View {
 LagebildHRWidget(titel: labels.radarTitel, minHoehe: 200) {
   Text(labels.radarUntertitel)
     .font(LagebildHRTokens.listMeta)
     .foregroundStyle(LagebildHRTokens.textSecondary)
     .lineLimit(2)
     .fixedSize(horizontal: false, vertical: true)
   MachtbalanceRadarChart(values: viewModel.machtBalance(fuer: ansicht))
     .frame(minHeight: 140)
 }
}

private var aktiveStrategienPanel: some View {
 LagebildHRWidget(titel: labels.strategienTitel, minHoehe: 168) {
   VStack(spacing: 8) {
     ForEach(viewModel.strategien(fuer: ansicht), id: \.name) { s in
       LagebildHRProgressRow(
         label: s.name,
         wert: Double(s.pct),
         farbe: strategieFarbe(pct: s.pct),
         suffix: "\(s.pct)%"
       )
     }
   }
 }
}

private func strategieFarbe(pct: Int) -> Color {
 if pct >= 70 { return LagebildHRTokens.successGreen }
 if pct >= 45 { return LagebildHRTokens.primaryBlue }
 return LagebildHRTokens.alertRed
}

private var risikoanalysePanel: some View {
 LagebildHRWidget(titel: labels.risikoTitel) {
   VStack(alignment: .leading, spacing: 8) {
     ForEach(viewModel.risikoListe(fuer: ansicht), id: \.label) { item in
       HStack {
         Text(item.label)
           .font(LagebildHRTokens.listTitle)
           .foregroundStyle(LagebildHRTokens.textPrimary)
           .lineLimit(2)
           .fixedSize(horizontal: false, vertical: true)
         Spacer(minLength: 4)
         FenlynineOSRiskDot(level: item.level)
       }
     }
     Button {
       if ansicht == .strategos {
         appState.navigateToSidebar(.strategos)
       } else if let id = viewModel.faelle.first?.id {
         appState.navigateToCase(id)
       } else {
         appState.navigateToSidebar(.lexara)
       }
     } label: {
       Text(ansicht == .strategos ? "Strategos öffnen" : "Details anzeigen")
         .font(.system(size: 10, weight: .semibold))
         .foregroundStyle(LagebildHRTokens.primaryBlue)
     }
     .buttonStyle(.plain)
     .padding(.top, 2)
   }
 }
}

private var naechsteSchrittePanel: some View {
 LagebildHRWidget(titel: labels.schritteTitel) {
   VStack(alignment: .leading, spacing: 2) {
     let schritte = viewModel.schritteListe(fuer: ansicht)
     if schritte.isEmpty {
       Text("Keine offenen Schritte")
         .font(LagebildHRTokens.listMeta)
         .foregroundStyle(LagebildHRTokens.textSecondary)
         .padding(.vertical, 8)
     } else {
       ForEach(schritte.prefix(5)) { schritt in
         LagebildHRSchrittZeile(
           titel: schritt.titel,
           meta: schritt.datum?.formatted(date: .abbreviated, time: .omitted) ?? schritt.quelle,
           quelle: schritt.quelle,
           onOeffnen: {
             if let caseId = schritt.caseId, !caseId.isEmpty {
               appState.navigateToCase(caseId)
             } else if schritt.quelle == "Strategos" {
               appState.navigateToSidebar(.strategos)
             } else {
               appState.navigateToSidebar(.aufgaben)
             }
           }
         )
       }
     }
     Button {
       appState.navigateToSidebar(ansicht == .strategos ? .strategos : .aufgaben)
     } label: {
       Text(ansicht == .strategos ? "Maßnahmen in Strategos" : "Aufgaben öffnen")
         .font(.system(size: 10, weight: .semibold))
         .foregroundStyle(LagebildHRTokens.primaryBlue)
     }
     .buttonStyle(.plain)
     .padding(.top, 4)
   }
 }
}

private var zeitplanPanel: some View {
 LagebildHRWidget(titel: labels.zeitplanTitel) {
   ZeitplanGanttChart(phasen: viewModel.gantt(fuer: ansicht))
     .frame(minHeight: 96)
   Button {
     appState.navigateToSidebar(ansicht == .strategos ? .strategos : .zeitleiste)
   } label: {
     Text(ansicht == .strategos ? "Umsetzungsplan" : "Fristen & Termine")
       .font(.system(size: 10, weight: .semibold))
       .foregroundStyle(LagebildHRTokens.primaryBlue)
   }
   .buttonStyle(.plain)
   .padding(.top, 4)
 }
}

private var letzteSection: some View {
 LagebildHRWidget(titel: labels.letzteTitel) {
   switch ansicht {
   case .lexara:
     letzteFaelleListe
   case .strategos:
     letzteSzenarienListe
   case .kombiniert:
     VStack(spacing: 10) {
       if !viewModel.faelle.isEmpty {
         Text("Lexara").font(.caption2.bold()).foregroundStyle(FenlynineOSTheme.accent)
         letzteFaelleListe
       }
       if !viewModel.offeneSzenarien.isEmpty {
         Text("Strategos").font(.caption2.bold()).foregroundStyle(FenlynineOSTheme.accentSecondary)
           .padding(.top, 6)
         letzteSzenarienListe
       }
     }
   }
 }
}

@ViewBuilder
private var letzteFaelleListe: some View {
 if viewModel.faelle.isEmpty {
   PlatzhalterView(nachricht: "Keine Fälle -- Mandat anlegen")
 } else {
   VStack(spacing: 6) {
     ForEach(viewModel.faelle.prefix(ansicht == .kombiniert ? 3 : 5)) { fall in
       FallZeilenKarte(fall: fall)
         .contentShape(Rectangle())
         .onTapGesture { appState.navigateToCase(fall.id ?? "") }
     }
   }
 }
}

@ViewBuilder
private var letzteSzenarienListe: some View {
 if viewModel.offeneSzenarien.isEmpty {
   PlatzhalterView(nachricht: "Keine Szenarien -- Strategos öffnen", symbol: "chart.line.uptrend.xyaxis")
 } else {
   VStack(spacing: 6) {
     ForEach(viewModel.offeneSzenarien.prefix(5)) { sz in
       Button { appState.navigateToSidebar(.strategos) } label: {
         HStack(spacing: 12) {
           Image(systemName: "chart.line.uptrend.xyaxis")
             .foregroundStyle(FenlynineOSTheme.accent)
           VStack(alignment: .leading, spacing: 2) {
             Text(sz.titel)
               .font(.system(size: 12, weight: .medium))
               .foregroundStyle(FenlynineOSTheme.textPrimary)
               .lineLimit(1)
             Text(sz.modus.rawValue.capitalized)
               .font(.caption2)
               .foregroundStyle(FenlynineOSTheme.textSecondary)
           }
           Spacer()
           Image(systemName: "chevron.right")
             .font(.caption2)
             .foregroundStyle(FenlynineOSTheme.textTertiary)
         }
         .padding(10)
         .background { VisionOSGlasFlaeche.karte(cornerRadius: 12, elevated: false) }
       }
       .buttonStyle(.plain)
     }
   }
 }
}
}

// MARK: - Legacy-Komponenten (weiter genutzt in anderen Views)

struct DashboardHeaderView: View {
let viewModel: HomeViewModel
@EnvironmentObject var authManager: AuthManager
var body: some View { EmptyView() }
}

struct KPIKartenReihe: View {
let viewModel: HomeViewModel
var body: some View { EmptyView() }
}

struct KPIKarte: View {
let titel: String
let wert: String
let gesamt: String
let symbol: String
let farbe: Color

var body: some View {
 VisionOSKPICard(titel: titel, wert: wert, gesamt: gesamt, symbol: symbol, farbe: farbe)
}
}

struct PrognosePieChart: View {
let viewModel: HomeViewModel
var body: some View {
 DashboardCard(titel: "Prognoseverteilung", symbol: "chart.pie.fill") {
   if viewModel.faelle.isEmpty {
     PlatzhalterView(nachricht: "Keine Fälle")
   } else {
     Chart(viewModel.prognoseVerteilung) { segment in
       SectorMark(angle: .value("Anzahl", segment.count), innerRadius: .ratio(0.55), angularInset: 2)
         .foregroundStyle(segment.farbe)
     }
     .frame(height: 160)
   }
 }
}
}

struct FristenBarChart: View {
let viewModel: HomeViewModel
var body: some View {
 DashboardCard(titel: "Fristen", symbol: "calendar") {
   Chart(viewModel.fristenKalender) { tag in
     BarMark(x: .value("Datum", tag.datum, unit: .day), y: .value("Fristen", tag.anzahl))
       .foregroundStyle(FenlynineOSTheme.chartPrimary)
   }
   .frame(height: 160)
 }
}
}

struct StatusVerteilungChart: View {
let viewModel: HomeViewModel
var body: some View { EmptyView() }
}

struct KritischeFristenListe: View {
let viewModel: HomeViewModel
var body: some View { EmptyView() }
}

struct FristenZeile: View {
let frist: Deadline
let istVersaeumt: Bool
var body: some View {
 HStack(spacing: 8) {
   Circle().fill(istVersaeumt ? FenlynineOSTheme.danger : FenlynineOSTheme.warning).frame(width: 8, height: 8)
   Text(frist.title).font(.system(size: 12)).foregroundStyle(FenlynineOSTheme.textPrimary).lineLimit(1)
   Spacer()
   Text(frist.due_date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(FenlynineOSTheme.textSecondary)
 }
}
}

struct LetzteFaelleListe: View {
let viewModel: HomeViewModel
var body: some View { EmptyView() }
}

struct FallZeilenKarte: View {
let fall: LegalCase
@Environment(\.fenlynineOSVisionOSChrome) private var chrome

var body: some View {
 HStack(spacing: 12) {
   Image(systemName: fall.status.symbol)
     .foregroundStyle(statusFarbe)
     .frame(width: 20)
   VStack(alignment: .leading, spacing: 2) {
     Text(fall.fallname)
       .font(.system(size: 12, weight: .medium))
       .foregroundStyle(FenlynineOSTheme.textPrimary)
       .lineLimit(1)
     HStack(spacing: 6) {
       if let az = fall.aktenzeichen {
         Text(az).font(.caption2).foregroundStyle(FenlynineOSTheme.textSecondary)
       }
       if let rg = fall.rechtsgebiet {
         Text(rg)
           .font(.caption2)
           .foregroundStyle(FenlynineOSTheme.accent)
           .padding(.horizontal, 5)
           .padding(.vertical, 1)
           .background(FenlynineOSTheme.accent.opacity(0.14), in: Capsule())
       }
     }
   }
   Spacer()
   if let p = fall.prognose {
     Text("\(Int(p))%")
       .font(.system(size: 12, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.accent)
   }
   Image(systemName: "chevron.right")
     .font(.caption2)
     .foregroundStyle(FenlynineOSTheme.textTertiary)
 }
 .padding(12)
 .background {
   VisionOSGlasFlaeche.karte(cornerRadius: 16, elevated: false)
 }
}

private var statusFarbe: Color {
 switch fall.status {
 case .aktiv: return FenlynineOSTheme.success
 case .vorbereitung: return FenlynineOSTheme.accent
 case .abgeschlossen: return FenlynineOSTheme.textTertiary
 case .ruhend: return FenlynineOSTheme.warning
 }
}
}

struct DashboardCard<Content: View>: View {
let titel: String
let symbol: String
@ViewBuilder let content: Content
var body: some View {
 CommandPanel(titel: titel.uppercased()) { content }
}
}

struct PlatzhalterView: View {
let nachricht: String
var symbol: String = "tray"
var body: some View {
 VStack(spacing: 8) {
   Image(systemName: symbol).font(.title3).foregroundStyle(FenlynineOSTheme.textTertiary)
   Text(nachricht).font(.caption).foregroundStyle(FenlynineOSTheme.textTertiary)
 }
 .frame(maxWidth: .infinity, minHeight: 60)
}
}

