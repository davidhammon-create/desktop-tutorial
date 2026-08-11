import SwiftUI
import Charts

// MARK: - Zeitleiste

struct ZeitleisteView: View {
@State private var fristen: [Deadline] = []
@State private var isLoading = false
@State private var selectedMonat = Date()

var fristenImMonat: [Deadline] {
  fristen.filter {
    Calendar.current.isDate($0.due_date, equalTo: selectedMonat, toGranularity: .month)
  }
  .sorted { $0.due_date < $1.due_date }
}

var body: some View {
  VStack(spacing: 0) {
    // Monats-Navigation
    HStack(spacing: 16) {
      Button {
        selectedMonat = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonat) ?? selectedMonat
      } label: {
        Image(systemName: "chevron.left")
      }
      Text(selectedMonat.formatted(.dateTime.month(.wide).year()))
        .font(.system(size: 16, weight: .semibold))
        .frame(minWidth: 160)
      Button {
        selectedMonat = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonat) ?? selectedMonat
      } label: {
        Image(systemName: "chevron.right")
      }
      Spacer()
      Button {
        selectedMonat = Date()
      } label: {
        Text("Heute")
          .font(.system(size: 12))
      }
      .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
    }
    .padding(16)

    Divider()

    if isLoading {
      ProgressView().frame(maxHeight: .infinity)
    } else if fristenImMonat.isEmpty {
      PlatzhalterView(nachricht: "Keine Fristen in diesem Monat")
    } else {
      List(fristenImMonat) { frist in
        FristenZeile(frist: frist, istVersaeumt: frist.istVersaeumt)
      }
      .listStyle(.plain)
    }
  }
  .fenlynineOSAdaptiveNavigationTitle("Zeitleiste & Fristen")
  .toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
      Button {
        exportieren()
      } label: {
        Label("Export", systemImage: "square.and.arrow.up")
      }
      .help("Als iCal exportieren")
    }
  }
  .task { await laden() }
}

private func laden() async {
  isLoading = true
  fristen = (try? await Services.deadlines.list()) ?? []
  isLoading = false
}

private func exportieren() {
  let ical = NotificationService.shared.icalDateiExportieren(fristen: fristen)
  let savePanel = NSSavePanel()
  savePanel.allowedContentTypes = [.init(filenameExtension: "ics")!]
  savePanel.nameFieldStringValue = "FenlynineOS_Fristen.ics"
  if savePanel.runModal() == .OK, let url = savePanel.url {
    try? ical.write(to: url, atomically: true, encoding: .utf8)
  }
}
}

// MARK: - Kanzlei-Cockpit

struct KanzleiCockpitView: View {
@State private var faelle: [LegalCase] = []
@State private var fristen: [Deadline] = []
@State private var isLoading = false

var body: some View {
  ScrollView {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
     KPIKarte(titel: "Gesamtfälle", wert: "\(faelle.count)", gesamt: "aktiv: \(faelle.filter { $0.status == .aktiv }.count)", symbol: "folder.fill", farbe: .blue)
     KPIKarte(titel: "Ø Prognose", wert: "\(Int(durchschnittPrognose))%", gesamt: "alle aktiven Fälle", symbol: "chart.line.uptrend.xyaxis", farbe: prognoseColor)
     KPIKarte(titel: "Gesamtstreitwert", wert: formatEuro(gesamtStreitwert), gesamt: "alle Fälle", symbol: "eurosign.circle", farbe: .green)
   }
   .padding(20)

   DashboardCard(titel: "Fallstatus-Verteilung (Kuchen)", symbol: "chart.pie.fill") {
     Chart(statusVerteilung, id: \.0) { seg in
       SectorMark(angle: .value("Anzahl", seg.1), innerRadius: .ratio(0.5))
         .foregroundStyle(statusFarbe(seg.0))
         .annotation(position: .overlay) {
           if seg.1 > 0 {
             Text("\(seg.1)").font(.caption2.bold()).foregroundStyle(.white)
           }
         }
     }
     .frame(height: 180)
   }
   .padding(.horizontal, 20)

   if !instanzVerteilung.isEmpty {
     DashboardCard(titel: "Fälle nach Instanz (Kuchen)", symbol: "building.columns") {
       Chart(instanzVerteilung, id: \.0) { seg in
         SectorMark(angle: .value("Anzahl", seg.1))
           .foregroundStyle(by: .value("Instanz", seg.0))
       }
       .frame(height: 180)
     }
     .padding(.horizontal, 20)
   }

   if !prognoseRanges.isEmpty {
     DashboardCard(titel: "Prognose-Verteilung (Balken)", symbol: "chart.bar.fill") {
       Chart(prognoseRanges, id: \.0) { seg in
         BarMark(x: .value("Anzahl", seg.1), y: .value("Bereich", seg.0))
           .foregroundStyle(seg.2)
           .cornerRadius(4)
       }
       .frame(height: 160)
     }
     .padding(.horizontal, 20)
   }

   if !fristenVerteilung.isEmpty {
     DashboardCard(titel: "Fristen-Status (Kuchen)", symbol: "calendar") {
       Chart(fristenVerteilung, id: \.0) { seg in
         SectorMark(angle: .value("Anzahl", seg.1), innerRadius: .ratio(0.45))
           .foregroundStyle(fristenFarbe(seg.0))
       }
       .frame(height: 160)
     }
     .padding(.horizontal, 20)
   }

   DashboardCard(titel: "Fälle nach Rechtsgebiet (Balken)", symbol: "scale.3d") {
     Chart(rechtsgebietVerteilung, id: \.0) { seg in
       BarMark(x: .value("Anzahl", seg.1), y: .value("Gebiet", seg.0))
         .foregroundStyle(FenlynineOSTheme.chartPrimary.gradient)
         .cornerRadius(4)
     }
     .frame(height: 200)
   }
   .padding(.horizontal, 20)
   .padding(.bottom, 20)
 }
 .fenlynineOSAdaptiveNavigationTitle("Kanzlei-Cockpit")
 .task { await laden() }
}

private var durchschnittPrognose: Double {
 let p = faelle.compactMap(\.prognose)
 return p.isEmpty ? 0 : p.reduce(0, +) / Double(p.count)
}

private var prognoseColor: Color {
 durchschnittPrognose >= 65 ? .green : durchschnittPrognose >= 45 ? .orange : .red
}

private var gesamtStreitwert: Double {
 faelle.compactMap(\.streitwert).reduce(0, +)
}

private var statusVerteilung: [(LegalCase.CaseStatus, Int)] {
 LegalCase.CaseStatus.allCases.map { status in (status, faelle.filter { $0.status == status }.count) }
}

private var rechtsgebietVerteilung: [(String, Int)] {
 let grouped = Dictionary(grouping: faelle.compactMap(\.rechtsgebiet), by: { $0 })
 return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }.prefix(8).map { $0 }
}

private var instanzVerteilung: [(String, Int)] {
 let grouped = Dictionary(grouping: faelle, by: { $0.instanz.rawValue })
 return grouped.map { ($0.key, $0.value.count) }.filter { $0.1 > 0 }
}

private var prognoseRanges: [(String, Int, Color)] {
 [
   ("0-25%", faelle.filter { ($0.prognose ?? 0) <= 25 }.count, .red),
   ("26-50%", faelle.filter { let p = $0.prognose ?? 0; return p > 25 && p <= 50 }.count, .gray),
   ("51-75%", faelle.filter { let p = $0.prognose ?? 0; return p > 50 && p <= 75 }.count, Color(white: 0.35)),
   ("76-100%", faelle.filter { ($0.prognose ?? 0) > 75 }.count, .green),
 ].filter { $0.1 > 0 }
}

private var fristenVerteilung: [(String, Int)] {
 let now = Date()
 let offen = fristen.filter { $0.status == .offen && $0.due_date >= now }.count
 let ueberfaellig = fristen.filter { $0.status == .offen && $0.due_date < now }.count
 let erledigt = fristen.filter { $0.status == .erledigt }.count
 let versaeumt = fristen.filter { $0.status == .versaeumt }.count
 return [
   ("Offen", offen),
   ("Überfällig", ueberfaellig),
   ("Erledigt", erledigt),
   ("Versäumt", versaeumt),
 ].filter { $0.1 > 0 }
}

private func fristenFarbe(_ name: String) -> Color {
 switch name {
 case "Offen": return .blue
 case "Überfällig": return .orange
 case "Erledigt": return .green
 case "Versäumt": return .red
 default: return .gray
 }
}

private func statusFarbe(_ status: LegalCase.CaseStatus) -> Color {
 switch status {
 case .aktiv: return .green
 case .vorbereitung: return .blue
 case .abgeschlossen: return .gray
 case .ruhend: return .orange
 }
}

private func laden() async {
 isLoading = true
 async let c = Services.cases.list()
 async let d = Services.deadlines.list()
 faelle = (try? await c) ?? []
 fristen = (try? await d) ?? []
 isLoading = false
}

private func formatEuro(_ value: Double) -> String {
 let formatter = NumberFormatter()
 formatter.numberStyle = .currency
 formatter.currencyCode = "EUR"
 formatter.locale = Locale(identifier: "de_DE")
 formatter.maximumFractionDigits = 0
 return formatter.string(from: NSNumber(value: value)) ?? "--"
}
}

// MARK: - Kanzlei-Analytik (AIPerformanceDashboard)

struct KanzleiAnalytikView: View {
@State private var feedbacks: [AIPerformanceFeedback] = []
@State private var kiLogs: [KIUsageLog] = []
@State private var laden = true
@State private var fehler: String?
@State private var filterPeriode = "alle"
@State private var zeigeForm = false
@State private var formGesamt = 3
@State private var formPrognose = 3
@State private var formStrategie = 3
@State private var formBerater = 3
@State private var formErfolg = false
@State private var formKommentar = ""
@State private var selectedCaseId = ""
@State private var faelle: [LegalCase] = []

private var stats: (avg: Double, success: Double, count: Int)? {
 guard !feedbacks.isEmpty else { return nil }
 let ratings = feedbacks.map { Double($0.effektiveGesamtbewertung) }.filter { $0 > 0 }
 let avg = ratings.isEmpty ? 0 : ratings.reduce(0, +) / Double(ratings.count)
 let success = Double(feedbacks.filter { $0.fall_erfolgreich == true }.count) / Double(feedbacks.count) * 100
 return (avg, success, feedbacks.count)
}

private struct TrendPunkt: Identifiable {
 let id = UUID()
 let datum: String
 let bewertung: Double
}

private var trendDaten: [TrendPunkt] {
 let sorted = gefilterteFeedbacks.sorted { ($0.created_at ?? .distantPast) < ($1.created_at ?? .distantPast) }
 var grouped: [String: [Int]] = [:]
 for fb in sorted {
   guard let d = fb.created_at else { continue }
   let key = d.formatted(.dateTime.day().month().year())
   grouped[key, default: []].append(fb.effektiveGesamtbewertung)
 }
 return grouped.map { key, vals in
   TrendPunkt(datum: key, bewertung: Double(vals.reduce(0, +)) / Double(vals.count))
 }.sorted { $0.datum < $1.datum }
}

var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 20) {
     HStack {
       Text("KI-Analytik & Performance")
         .font(.title2.bold())
       Spacer()
       Button {
         zeigeForm.toggle()
       } label: {
         Label("Feedback", systemImage: "plus.circle")
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     }
     .padding(.horizontal, 20).padding(.top, 20)

     if let fehler {
       Text(fehler).font(.caption).foregroundStyle(.red).padding(.horizontal, 20)
     }

     if let s = stats {
       LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
         statKarte("Ø Bewertung", String(format: "%.1f/5", s.avg), .blue)
         statKarte("Erfolgsquote", String(format: "%.0f%%", s.success), .green)
         statKarte("Feedbacks", "\(s.count)", .purple)
       }
       .padding(.horizontal, 20)
     }

     Picker("Zeitraum", selection: $filterPeriode) {
       Text("Gesamt").tag("alle")
       Text("Monat").tag("month")
       Text("Quartal").tag("quarter")
     }
     .pickerStyle(.segmented)
     .padding(.horizontal, 20)

     if !trendDaten.isEmpty {
       DashboardCard(titel: "Bewertungsverlauf", symbol: "chart.xyaxis.line") {
         Chart(trendDaten) { punkt in
           LineMark(
             x: .value("Datum", punkt.datum),
             y: .value("Bewertung", punkt.bewertung)
           )
           .foregroundStyle(FenlynineOSTheme.chartPrimary)
           PointMark(
             x: .value("Datum", punkt.datum),
             y: .value("Bewertung", punkt.bewertung)
           )
         }
         .frame(height: 160)
       }
       .padding(.horizontal, 20)
     }

     if zeigeForm {
       feedbackForm
         .padding(.horizontal, 20)
     }

     if laden {
       ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
     } else if feedbacks.isEmpty {
       InfoHinweis(
         titel: "Noch kein Feedback",
         nachricht: "Bewerten Sie KI-Prognosen und Strategien nach Fallabschluss.",
         symbol: "star"
       )
       .padding(.horizontal, 20)
     } else {
       VStack(alignment: .leading, spacing: 10) {
         Text("Feedback-Einträge").font(.headline)
         ForEach(gefilterteFeedbacks, id: \.id) { fb in
           feedbackZeile(fb)
         }
       }
       .padding(.horizontal, 20)
     }

     if !kiLogs.isEmpty {
       VStack(alignment: .leading, spacing: 10) {
         Text("KI-Nutzungsprotokoll").font(.headline)
         ForEach(kiLogs.prefix(15), id: \.id) { log in
           HStack {
             VStack(alignment: .leading, spacing: 2) {
               Text(log.anzeigeFunktion).font(.caption.bold())
               Text(log.input_summary ?? "--").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
             }
             Spacer()
             if let r = log.rating {
               Text("\(r)H").font(.caption).foregroundStyle(.orange)
             }
           }
           .padding(10)
           .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
         }
       }
       .padding(.horizontal, 20)
     }

     Divider().padding(.horizontal, 20)

     AkteureAnalytikView()
       .padding(.horizontal, 20)
   }
   .padding(.bottom, 32)
 }
 .fenlynineOSAdaptiveNavigationTitle("Analytik")
 .task { await ladenDaten() }
}

private var gefilterteFeedbacks: [AIPerformanceFeedback] {
 guard filterPeriode != "alle" else { return feedbacks }
 let now = Date()
 return feedbacks.filter { fb in
   guard let d = fb.created_at else { return false }
   if filterPeriode == "month" {
     return Calendar.current.isDate(d, equalTo: now, toGranularity: .month)
   }
   if filterPeriode == "quarter" {
     let qNow = Calendar.current.component(.month, from: now) / 3
     let q = Calendar.current.component(.month, from: d) / 3
     return q == qNow && Calendar.current.component(.year, from: d) == Calendar.current.component(.year, from: now)
   }
   return true
 }
}

@ViewBuilder
private var feedbackForm: some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("Neues Performance-Feedback").font(.caption.bold())
   Picker("Fall", selection: $selectedCaseId) {
     Text("-- wählen --").tag("")
     ForEach(faelle) { f in
       Text(f.fallname).tag(f.id ?? "")
     }
   }
   HStack {
     sternePicker("Gesamt", wert: $formGesamt)
     sternePicker("Prognose", wert: $formPrognose)
     sternePicker("Strategie", wert: $formStrategie)
     sternePicker("KI-Berater", wert: $formBerater)
   }
   Toggle("Fall erfolgreich", isOn: $formErfolg)
   TextField("Kommentar (optional)", text: $formKommentar)
     .textFieldStyle(.roundedBorder)
   Button("Speichern") {
     Task { await speichernFeedback() }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(selectedCaseId.isEmpty)
 }
 .padding(14)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
}

private func sternePicker(_ label: String, wert: Binding<Int>) -> some View {
 VStack(spacing: 4) {
   Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
   Stepper("\(wert.wrappedValue)", value: wert, in: 1...5)
     .font(.caption)
 }
}

private func statKarte(_ titel: String, _ wert: String, _ farbe: Color) -> some View {
 VStack(spacing: 4) {
   Text(wert).font(.title2.bold()).foregroundStyle(farbe)
   Text(titel).font(.caption).foregroundStyle(.secondary)
 }
 .frame(maxWidth: .infinity)
 .padding(14)
 .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
}

private func feedbackZeile(_ fb: AIPerformanceFeedback) -> some View {
 HStack(alignment: .top) {
   VStack(alignment: .leading, spacing: 4) {
     Text(fb.case_name ?? fb.case_id ?? "Fall").font(.caption.bold())
     HStack(spacing: 8) {
       if let g = fb.gesamtbewertung ?? fb.bewertung {
         Text("Gesamt: \(g)/5").font(.caption2)
       }
       if fb.fall_erfolgreich == true {
         Text("3 Erfolg").font(.caption2).foregroundStyle(.green)
       }
     }
     if let k = fb.ki_feedback ?? fb.kommentar {
       Text(k).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
     }
   }
   Spacer()
   if let d = fb.created_at {
     Text(d.formatted(.dateTime.day().month())).font(.caption2).foregroundStyle(.tertiary)
   }
 }
 .padding(12)
 .background(.background, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.1)))
}

private func ladenDaten() async {
 laden = true
 fehler = nil
 do {
   async let fb = Services.aiPerformanceFeedback.list(sort: "-created_at")
   async let logs = Services.kiUsageLogs.list(sort: "-created_at", limit: 50)
   async let c = Services.cases.list()
   let feedbackData = try await fb
   let logData = try await logs
   let caseData = try await c
   await MainActor.run {
     feedbacks = feedbackData
     kiLogs = logData
     faelle = caseData
     laden = false
   }
 } catch {
   await MainActor.run {
     fehler = error.localizedDescription
     laden = false
   }
 }
}

private func speichernFeedback() async {
 let entity = AIPerformanceFeedback(
   case_id: selectedCaseId,
   gesamtbewertung: formGesamt,
   prognose_rating: formPrognose,
   strategie_rating: formStrategie,
   ki_berater_rating: formBerater,
   ki_feedback: formKommentar.isEmpty ? nil : formKommentar,
   fall_erfolgreich: formErfolg
 )
 do {
   _ = try await Services.aiPerformanceFeedback.create(entity)
   zeigeForm = false
   await ladenDaten()
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - Fall-spezifisches KI-Performance-Feedback (AIPerformanceDashboard pro Fall)

struct CaseAIPerformanceSection: View {
let caseId: String
let fallname: String

@State private var feedbacks: [AIPerformanceFeedback] = []
@State private var kiLogs: [KIUsageLog] = []
@State private var laden = true
@State private var gesamt = 3
@State private var kommentar = ""
@State private var erfolg = false
@State private var speichern = false

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   Label("KI-Performance-Feedback", systemImage: "star.fill")
     .font(.headline)

   if laden {
     ProgressView().scaleEffect(0.8)
   } else {
     if feedbacks.isEmpty {
       Text("Noch kein Feedback für diesen Fall.").font(.caption).foregroundStyle(.secondary)
     } else {
       ForEach(feedbacks.prefix(3), id: \.id) { fb in
         HStack {
           Text("\(fb.effektiveGesamtbewertung)/5").font(.caption.bold())
           Text(fb.ki_feedback ?? fb.kommentar ?? "--").font(.caption2).lineLimit(1)
           Spacer()
         }
       }
     }

     HStack {
       Stepper("Gesamt: \(gesamt)", value: $gesamt, in: 1...5)
       Toggle("Erfolg", isOn: $erfolg)
     }
     TextField("Feedback…", text: $kommentar)
       .textFieldStyle(.roundedBorder)
       .font(.caption)
     Button {
       Task { await speichernFeedback() }
     } label: {
       if speichern { ProgressView().scaleEffect(0.7) }
       else { Text("Feedback speichern") }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .controlSize(.small)

     if !kiLogs.isEmpty {
       Text("KI-Logs: \(kiLogs.count) Einträge").font(.caption2).foregroundStyle(.secondary)
     }
   }
 }
 .padding(14)
 .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
 .task { await laden() }
}

private func laden() async {
 laden = true
 defer { laden = false }
 feedbacks = (try? await Services.aiPerformanceFeedback.filter(["case_id": caseId])) ?? []
 kiLogs = (try? await Services.kiUsageLogs.filter(["case_id": caseId])) ?? []
}

private func speichernFeedback() async {
 speichern = true
 defer { speichern = false }
 let entity = AIPerformanceFeedback(
   case_id: caseId,
   case_name: fallname,
   gesamtbewertung: gesamt,
   ki_feedback: kommentar.isEmpty ? nil : kommentar,
   fall_erfolgreich: erfolg
 )
 _ = try? await Services.aiPerformanceFeedback.create(entity)
 kommentar = ""
 await laden()
}
}

// MARK: - KI-Compliance

struct KIComplianceView: View {
var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 20) {
     Text("KI-Compliance & EU AI Act")
       .font(.title2.bold())
       .padding(.horizontal, 20)
       .padding(.top, 20)

     VStack(alignment: .leading, spacing: 12) {
       ComplianceAbschnitt(
         titel: "Transparenzpflicht (Art. 13 EU AI Act)",
         status: .erfuellt,
         beschreibung: "FenlynineOS gibt bei jeder KI-Antwort vollständige Auskunft über Berechnungsgrundlagen, verwendete Daten und Methodiken. Jeder Berechnungsschritt ist dokumentiert und nachvollziehbar."
       )
       ComplianceAbschnitt(
         titel: "Menschliche Kontrolle (Art. 14 EU AI Act)",
         status: .erfuellt,
         beschreibung: "Der Anwalt trifft alle juristischen Entscheidungen. FenlynineOS unterstützt nur, gibt Empfehlungen und zeigt Optionen. Keine autonomen Entscheidungen."
       )
       ComplianceAbschnitt(
         titel: "Genauigkeit & Robustheit (Art. 15 EU AI Act)",
         status: .teilweise,
         beschreibung: "Algorithmische Berechnungen (Monte-Carlo, Bayesian) sind präzise dokumentiert. KI-Textanalysen können variieren -- Qualitätssicherung durch menschliche Prüfung empfohlen."
       )
       ComplianceAbschnitt(
         titel: "DSGVO-Compliance",
         status: .erfuellt,
         beschreibung: "Datenspeicherung erfolgt ausschließlich beim Mandanten (Base44 Backend). Keine unberechtigte Weitergabe. Row-Level-Security für alle Entitäten."
       )
     }
     .padding(.horizontal, 20)
   }
 }
 .fenlynineOSAdaptiveNavigationTitle("KI-Compliance")
}
}

struct ComplianceAbschnitt: View {
let titel: String
let status: ComplianceStatus
let beschreibung: String

enum ComplianceStatus {
 case erfuellt, teilweise, ausstehend

 var symbol: String {
   switch self {
   case .erfuellt: return "checkmark.shield.fill"
   case .teilweise: return "exclamationmark.shield.fill"
   case .ausstehend: return "xmark.shield.fill"
   }
 }

 var farbe: Color {
   switch self {
   case .erfuellt: return .green
   case .teilweise: return .orange
   case .ausstehend: return .red
   }
 }

 var text: String {
   switch self {
   case .erfuellt: return "Erfüllt"
   case .teilweise: return "Teilweise erfüllt"
   case .ausstehend: return "Ausstehend"
   }
 }
}

var body: some View {
 FenlynineOSCard(elevated: false) {
   HStack(alignment: .top, spacing: 14) {
     Image(systemName: status.symbol)
       .font(.system(size: 22))
       .foregroundStyle(status.farbe)

     VStack(alignment: .leading, spacing: 4) {
       HStack {
         Text(titel)
           .font(.system(size: 13, weight: .semibold))
         Spacer()
         Text(status.text)
           .font(.caption2.bold())
           .foregroundStyle(status.farbe)
           .padding(.horizontal, 8)
           .padding(.vertical, 3)
           .background(status.farbe.opacity(0.15), in: Capsule())
       }
       Text(beschreibung)
         .font(.system(size: 12))
         .foregroundStyle(FenlynineOSTheme.textSecondary)
     }
   }
 }
}
}

// MARK: - Onboarding

enum OnboardingFokus: Hashable {
case appId, baseUrl, email, passwort, name, kanzlei
}

// MARK: - Verbindungsstatus (immer sichtbar)

struct OnboardingVerbindungsStatusView: View {
let appId: String
let baseUrl: String
let schritt: Int

private var istBereit: Bool { !appId.trimmingCharacters(in: .whitespaces).isEmpty }

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack {
     Label("Aktuelle Base44-Verbindung", systemImage: "link.circle.fill")
       .font(.headline)
     Spacer()
     Text("Schritt \(schritt + 1) von 2")
       .font(.caption.weight(.medium))
       .padding(.horizontal, 8)
       .padding(.vertical, 4)
       .background(Color.secondary.opacity(0.15))
       .clipShape(Capsule())
   }

   verbindungsZeile(label: "App-ID", wert: appId, leerHinweis: "Noch nicht eingetragen")
   verbindungsZeile(label: "Base-URL", wert: baseUrl, leerHinweis: "https://app.base44.com")

   HStack(spacing: 8) {
     Image(systemName: istBereit ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
       .foregroundStyle(istBereit ? .green : .orange)
     Text(istBereit
       ? "Verbindung konfiguriert -- Anmeldung möglich"
       : "App-ID fehlt -- bitte in Schritt 1 eintragen")
       .font(.caption)
       .foregroundStyle(istBereit ? .green : .orange)
   }

   if let url = URL(string: baseUrl), !baseUrl.isEmpty {
     Link(destination: url) {
       Label("Base44-App im Browser öffnen", systemImage: "safari")
         .font(.caption)
     }
   }
 }
 .padding(16)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(Color(nsColor: .controlBackgroundColor))
 .overlay(
   RoundedRectangle(cornerRadius: 10)
     .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
 )
 .clipShape(RoundedRectangle(cornerRadius: 10))
}

@ViewBuilder
private func verbindungsZeile(label: String, wert: String, leerHinweis: String) -> some View {
 VStack(alignment: .leading, spacing: 2) {
   Text(label)
     .font(.caption.weight(.semibold))
     .foregroundStyle(.secondary)
   Text(wert.trimmingCharacters(in: .whitespaces).isEmpty ? leerHinweis : wert)
     .font(.system(.body, design: .monospaced))
     .textSelection(.enabled)
     .lineLimit(2)
     .foregroundStyle(wert.trimmingCharacters(in: .whitespaces).isEmpty ? .tertiary : .primary)
 }
}
}

// MARK: - Anleitung (Schritt-spezifisch)

struct OnboardingAnleitungView: View {
let schritt: Int
let istRegistrierung: Bool

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   Label("So geht's", systemImage: "questionmark.circle")
     .font(.subheadline.weight(.semibold))

   if schritt == 0 {
     anleitungPunkt("1", "Öffnen Sie Ihre App auf base44.com im Browser.")
     anleitungPunkt("2", "App-ID: steht in der Adresszeile zwischen /apps/ und /editor/ -- z. B. abc123def456")
     anleitungPunkt("3", "Base-URL: die Domain Ihrer App, z. B. https://ihre-app.base44.app -- oder https://app.base44.com")
     anleitungPunkt("4", "Beides hier eintragen, dann „Weiter".")
   } else if istRegistrierung {
     anleitungPunkt("(cid:127)", "Neues Base44-Konto für diese App anlegen.")
     anleitungPunkt("(cid:127)", "E-Mail + Passwort selbst wählen -- es gibt keinen Demo-Login.")
     anleitungPunkt("(cid:127)", "Base44 kann eine Bestätigungs-E-Mail (OTP) schicken -- danach erneut anmelden.")
   } else {
     anleitungPunkt("(cid:127)", "E-Mail + Passwort = Ihr Base44-Benutzerkonto für diese App.")
     anleitungPunkt("(cid:127)", "Gleiche Zugangsdaten wie in der Web-Version Ihrer FenlynineOS-App im Browser.")
     anleitungPunkt("(cid:127)", "Kein festes Demo-Passwort -- nur Ihr eigenes Konto.")
     anleitungPunkt("(cid:127)", "Noch kein Konto? Unten „Neu? Konto erstellen".")
   }
 }
 .padding(14)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(Color.blue.opacity(0.06))
 .clipShape(RoundedRectangle(cornerRadius: 10))
}

private func anleitungPunkt(_ nummer: String, _ text: String) -> some View {
 HStack(alignment: .top, spacing: 8) {
   Text(nummer)
     .font(.caption.weight(.bold))
     .foregroundStyle(.blue)
     .frame(width: 16, alignment: .leading)
   Text(text)
     .font(.caption)
     .foregroundStyle(.secondary)
     .fixedSize(horizontal: false, vertical: true)
 }
}
}

struct OnboardingView: View {
@EnvironmentObject var authManager: AuthManager
@AppStorage("onboarding_schritt") private var schritt = 0
@State private var email = ""
@State private var passwort = ""
@State private var name = ""
@State private var kanzlei = ""
@State private var appId = ""
@State private var baseUrl = ""
@State private var fehler: String?
@State private var isLoading = false
@State private var istRegistrierung = false
@FocusState private var fokus: OnboardingFokus?

var body: some View {
 ScrollView {
   VStack(spacing: 20) {
     VStack(spacing: 8) {
       Image(systemName: "scale.3d")
         .font(.system(size: 52, weight: .thin))
         .foregroundStyle(.blue)
       Text(AppDefaults.produktNameVoll)
         .font(.system(size: 26, weight: .bold, design: .rounded))
         .multilineTextAlignment(.center)
       Text(AppDefaults.produktUntertitel)
         .font(.subheadline)
         .foregroundStyle(.secondary)
     }
     .padding(.top, 24)

     OnboardingVerbindungsStatusView(appId: appId, baseUrl: baseUrl, schritt: schritt)

     OnboardingAnleitungView(schritt: schritt, istRegistrierung: istRegistrierung)

     Group {
       switch schritt {
       case 0:
         OnboardingAPISchritt(appId: $appId, baseUrl: $baseUrl, fokus: $fokus, weiter: {
           Task { await configSpeichernUndWeiter() }
         })
       case 1:
         OnboardingLoginSchritt(
           email: $email, passwort: $passwort, name: $name, kanzlei: $kanzlei,
           istRegistrierung: $istRegistrierung, fehler: $fehler, isLoading: $isLoading,
           fokus: $fokus,
           onZurueck: { schritt = 0; fokus = .appId },
           onLogin: anmelden
         )
       default:
         EmptyView()
       }
     }
   }
   .frame(maxWidth: 480)
   .frame(maxWidth: .infinity)
   .padding(.horizontal, 32)
   .padding(.bottom, 40)
 }
 .onAppear {
   let config = Base44Config.load()
   if appId.isEmpty { appId = config.appId }
   if baseUrl.isEmpty { baseUrl = config.appBaseUrl.isEmpty ? "https://app.base44.com" : config.appBaseUrl }
   if fehler == nil { fehler = authManager.error }
   DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
     fokus = schritt == 0 ? .appId : .email
     FenlynineOSAppDelegate.aktiviereHauptfenster()
   }
 }
 .onChange(of: schritt) { _, neu in
   DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
     fokus = neu == 0 ? .appId : .email
   }
 }
 .onChange(of: authManager.error) { _, neu in
   if let neu { fehler = neu }
 }
}

private func configSpeichernUndWeiter() async {
 fehler = nil
 var config = Base44Config.load()
 if !appId.isEmpty { config.appId = appId.trimmingCharacters(in: .whitespaces) }
 let url = baseUrl.trimmingCharacters(in: .whitespaces)
 config.appBaseUrl = url.isEmpty ? "https://app.base44.com" : url
 baseUrl = config.appBaseUrl
 await Base44Client.shared.updateConfig(config)
 schritt = 1
 fokus = .email
}

private func anmelden() async {
 isLoading = true
 fehler = nil
 authManager.error = nil

 var config = Base44Config.load()
 if !appId.isEmpty { config.appId = appId.trimmingCharacters(in: .whitespaces) }
 let url = baseUrl.trimmingCharacters(in: .whitespaces)
 if !url.isEmpty { config.appBaseUrl = url }
 await Base44Client.shared.updateConfig(config)

 if config.appId.isEmpty {
   fehler = "Base44 App-ID fehlt. Bitte „Zurück" und App-ID eintragen."
   isLoading = false
   return
 }

 do {
   if istRegistrierung {
     try await authManager.register(email: email, password: passwort, name: name, kanzlei: kanzlei.isEmpty ? nil : kanzlei)
   } else {
     try await authManager.login(email: email, password: passwort)
   }
 } catch {
   fehler = error.localizedDescription
   if let authErr = authManager.error { fehler = authErr }
 }
 isLoading = false
}
}

struct OnboardingAPISchritt: View {
@Binding var appId: String
@Binding var baseUrl: String
var fokus: FocusState<OnboardingFokus?>.Binding
let weiter: () -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Schritt 1 -- Base44-Verbindung")
     .font(.headline)

   Form {
     TextField("App-ID", text: $appId)
       .focused(fokus, equals: .appId)
       .textFieldStyle(.roundedBorder)
     TextField("Base-URL", text: $baseUrl)
       .focused(fokus, equals: .baseUrl)
       .textFieldStyle(.roundedBorder)
   }
   .formStyle(.grouped)
   .frame(minHeight: 120)

   HStack {
     Spacer()
     Button("Weiter zur Anmeldung") { weiter() }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
       .keyboardShortcut(.return)
   }
 }
}
}

struct OnboardingLoginSchritt: View {
@Binding var email: String
@Binding var passwort: String
@Binding var name: String
@Binding var kanzlei: String
@Binding var istRegistrierung: Bool
@Binding var fehler: String?
@Binding var isLoading: Bool
var fokus: FocusState<OnboardingFokus?>.Binding
let onZurueck: () -> Void
let onLogin: () async -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Button {
     onZurueck()
   } label: {
     Label("Zurück zu App-ID & URL", systemImage: "chevron.left")
   }
   .buttonStyle(.plain)
   .foregroundStyle(.secondary)
   .keyboardShortcut(.cancelAction)

   Text(istRegistrierung ? "Schritt 2 -- Konto erstellen" : "Schritt 2 -- Anmelden")
     .font(.headline)

   if let fehler {
     Label(fehler, systemImage: "exclamationmark.triangle")
       .font(.caption)
       .foregroundStyle(.red)
   }

   Form {
     TextField("E-Mail (Ihr Base44-Konto)", text: $email)
       .focused(fokus, equals: .email)
       .textFieldStyle(.roundedBorder)
     SecureField("Passwort", text: $passwort)
       .focused(fokus, equals: .passwort)
       .textFieldStyle(.roundedBorder)
     if istRegistrierung {
       TextField("Vollständiger Name", text: $name)
         .focused(fokus, equals: .name)
         .textFieldStyle(.roundedBorder)
       TextField("Kanzlei / Organisation (optional)", text: $kanzlei)
         .focused(fokus, equals: .kanzlei)
         .textFieldStyle(.roundedBorder)
     }
   }
   .formStyle(.grouped)
   .frame(minHeight: istRegistrierung ? 180 : 100)

   Button {
     Task { await onLogin() }
   } label: {
     if isLoading {
       ProgressView().scaleEffect(0.8)
     } else {
       Text(istRegistrierung ? "Konto erstellen & anmelden" : "Anmelden")
         .frame(maxWidth: .infinity)
     }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(email.isEmpty || passwort.isEmpty || isLoading)
   .keyboardShortcut(.return)

   Button(istRegistrierung ? "Bereits ein Konto? Anmelden" : "Neu? Konto erstellen") {
     istRegistrierung.toggle()
     fokus.wrappedValue = .email
   }
   .buttonStyle(.plain)
   .font(.caption)
 }
}
}

