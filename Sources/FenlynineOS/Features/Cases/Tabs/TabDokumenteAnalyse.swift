import SwiftUI
import UniformTypeIdentifiers

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Tab: Dokumente & KI-Analyse
//
// Exaktes Äquivalent zu TabDokumenteAnalyse.jsx aus dem Original.
// Workflow:
// 1. Datei per Drag & Drop oder Picker auswählen
// 2. Upload -> LLMService.uploadFile() -> file_url
// 3. Document-Entity anlegen -> docId
// 4. analyzeDocument(docId:caseId:) -> 10-Schritte-KI-Analyse
// 5. Ergebnis zeigen: welche Tabs wurden befüllt
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Analyse-Schritt Mapping (wie das Original)

struct AnalyseSchritt: Identifiable {
let id: Int
let label: String
let wo: String
let felder: [String]
let hinweis: String
}

private let ANALYSE_SCHRITTE: [AnalyseSchritt] = [
AnalyseSchritt(id: 1, label: "Fallerfassung -- Basisdaten", wo: "Tab 1 › Basisdaten", felder: ["Gericht","Aktenzeichen","Rechtsgebiet","Instanz","Prozessziel","Streitwert"], hinweis: "Nur wenn Feld noch leer"),
AnalyseSchritt(id: 2, label: "Fallsubstanz", wo: "Tab 2 › Argumente & Beweise", felder: ["Argumente (eigen/gegner)","Beweise","Fristen mit Datum","Personen"], hinweis: "Beweise werden dem Dokument als Quelle zugeordnet"),
AnalyseSchritt(id: 3, label: "Gegneranalyse", wo: "Tab 3 › Gegner-Profil", felder: ["Gegner-Strategie","Taktiken","Schwachstellen"], hinweis: "Wird in Case.gegner_profil gespeichert"),
AnalyseSchritt(id: 4, label: "Rechtliche Analyse", wo: "Tab 4 › Compliance & §§", felder: ["Paragrafen","Präzedenzfälle","Compliance-Risiken"], hinweis: "Informiert Tab 4 inhaltlich"),
AnalyseSchritt(id: 5, label: "Strategie", wo: "Tab 5 › Fallnotizen", felder: ["Empfohlene Strategie","Stärken","Schwächen"], hinweis: "Wird als Notiz in Case.notes ergänzt"),
AnalyseSchritt(id: 6, label: "Risiko", wo: "Tab 6 › Risikoanalyse", felder: ["Risiko-Level","Risiken","Beweisrisiken"], hinweis: "Risiko-Zusammenfassung in Fallnotizen"),
AnalyseSchritt(id: 7, label: "Simulation", wo: "Tab 7 › Monte-Carlo", felder: ["Vergleichswert €","Prognose-Einfluss"], hinweis: "ki_berater_result.vergleichswert_eur"),
AnalyseSchritt(id: 8, label: "Aktion / Schriftsätze", wo: "Tab 8 › Aktion", felder: ["Nächste Schritte","Einzureichende Dokumente"], hinweis: "Handlungsempfehlungen in Notes + ki_berater_result"),
AnalyseSchritt(id: 9, label: "Cockpit", wo: "Tab 9 › Cockpit", felder: ["Prognose-Delta %"],   hinweis: "ki_berater_result.prognose_delta"),
AnalyseSchritt(id: 10, label: "Abschluss", wo: "Tab 10 › Abschluss", felder: ["Prozessziel erreichbar?","Vergleichsempfehlung"], hinweis: "ki_berater_result.vergleichsempfehlung"),
]

// MARK: - Pending File

struct PendingFile: Identifiable {
let id = UUID()
let url: URL
var isUploading = false

var name: String { url.lastPathComponent }
var size: Int64 { (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0 }
var mimeType: String {
  UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
}
}

// MARK: - Haupt-View

struct TabDokumenteAnalyse: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

@State private var isDragOver = false
@State private var pendingFiles: [PendingFile] = []
@State private var analyzingDocId: String? = nil
@State private var analyseErgebnisse: [String: AnyCodable] = [:]
@State private var zeigeErklarung = false
@State private var fehler: String? = nil
@State private var letzteStats: AnalyzeStats? = nil

private var caseId: String { viewModel.caseId }

var body: some View {
  VStack(alignment: .leading, spacing: 16) {
    // Drop-Zone / Datei-Auswahl
    DropZoneView(
      isDragOver: $isDragOver,
      pendingFiles: $pendingFiles,
      kiMode: kiMode,
      onDropURLs: { urls in
        pendingFiles += urls.map { PendingFile(url: $0) }
      },
      onAnalyzeAll: { Task { await alleHochladenUndAnalysieren() } },
      onRemovePending: { id in pendingFiles.removeAll { $0.id == id } }
    )

    // KI-Erklärungs-Panel (aufklappbar)
    KIErklaerungsPanel(expanded: $zeigeErklarung)

    // Fehler
    if let err = fehler {
      HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
        Text(err).font(.caption).foregroundStyle(.red)
        Spacer()
        Button("OK") { fehler = nil }.buttonStyle(.plain)
      }
      .padding(10)
      .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    if let stats = letzteStats {
      HStack(spacing: 12) {
       Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
       Text("Analyse übernommen: \(stats.argumente ?? 0) Argumente · \(stats.beweise ?? 0) Beweise · \(stats.fristen ?? 0) Fristen · \(stats.personen ?? 0) Personen · \(stats.verknuepfungen ?? 0) Verknüpfungen")
         .font(.caption)
         .foregroundStyle(.secondary)
     }
     .padding(10)
     .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
   }

   // Dokumente-Liste
   if viewModel.dokumente.isEmpty && pendingFiles.isEmpty {
     platzhalter
   } else {
     dokumenteListe
   }

   // Gesamtabdeckung
   if !viewModel.dokumente.isEmpty {
     GesamtAbdeckungView(
       dokumente: viewModel.dokumente,
       ergebnisse: analyseErgebnisse
     )
   }
 }
 .onDrop(of: [UTType.fileURL, UTType.item], isTargeted: $isDragOver) { providers in
   handleDrop(providers)
   return true
 }
 .task { hydrateErgebnisse() }
 .onChange(of: viewModel.dokumente.count) { _, _ in hydrateErgebnisse() }
}

private func hydrateErgebnisse() {
 var merged = analyseErgebnisse
 for dok in viewModel.dokumente {
   guard let id = dok.id else { continue }
   if merged[id] == nil, let raw = dok.ai_raw {
     merged[id] = raw
   }
 }
 if merged.count != analyseErgebnisse.count || merged.keys.contains(where: { analyseErgebnisse[$0] == nil }) {
   analyseErgebnisse = merged
 }
}

// MARK: - Sub-Views

private var platzhalter: some View {
 VStack(spacing: 8) {
   Image(systemName: "doc.badge.plus")
     .font(.system(size: 36))
     .foregroundStyle(.secondary)
   Text("Noch keine Dokumente")
     .font(.system(size: 13))
     .foregroundStyle(.secondary)
   Text("Ziehen Sie Dateien hier rein oder benutzen Sie die Drop-Zone oben.")
     .font(.caption)
     .foregroundStyle(.tertiary)
     .multilineTextAlignment(.center)
 }
 .frame(maxWidth: .infinity)
 .padding(40)
}

private var dokumenteListe: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Text("\(viewModel.dokumente.count) Dokument(e)")
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(.secondary)
     Spacer()
     let nichtAnalysiert = viewModel.dokumente.filter { analyseErgebnisse[$0.id ?? ""] == nil && $0.ai_summary == nil }
     if !nichtAnalysiert.isEmpty && kiMode {
       Button {
         Task { await alleAnalysieren() }
       } label: {
         Label("Alle analysieren", systemImage: "wand.and.stars")
           .font(.system(size: 11, weight: .medium))
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       .controlSize(.small)
     }
   }

   ForEach(viewModel.dokumente) { dok in
     DokumentKarte(
       dokument: dok,
       analyseLaeuft: analyzingDocId == dok.id,
       ergebnis: analyseErgebnisse[dok.id ?? ""],
       kiMode: kiMode,
       onAnalysieren: { Task { await dokumentAnalysieren(dok) } },
       onLoeschen: { Task { await dokumentLoeschen(dok) } }
     )
   }
 }
}

// MARK: - Aktionen

private func alleHochladenUndAnalysieren() async {
 for pending in pendingFiles {
   await hochladenUndAnalysieren(pending)
 }
}

private func hochladenUndAnalysieren(_ pending: PendingFile) async {
 guard let idx = pendingFiles.firstIndex(where: { $0.id == pending.id }) else { return }
 pendingFiles[idx].isUploading = true

 do {
   try FenlynineOSSecurity.validateFileSize(at: pending.url)
   let data = try Data(contentsOf: pending.url)
   let fileUrl = try await LLMService.shared.uploadFile(
     data: data,
     fileName: FenlynineOSSecurity.sanitizedMultipartFileName(pending.name),
     mimeType: pending.mimeType
   )

   var dok = LegalDocument(case_id: caseId, title: pending.name)
   dok.file_url = fileUrl
   dok.file_type = pending.mimeType
   let erstelltes = try await Services.documents.create(dok)

   await MainActor.run {
     viewModel.dokumente.append(erstelltes)
     pendingFiles.removeAll { $0.id == pending.id }
   }

   await dokumentAnalysieren(erstelltes)

 } catch {
   await MainActor.run {
     pendingFiles.removeAll { $0.id == pending.id }
     fehler = "Upload fehlgeschlagen: \(error.localizedDescription)"
   }
 }
}

private func dokumentAnalysieren(_ dok: LegalDocument, retryCount: Int = 0) async {
 guard let docId = dok.id else { return }
 await MainActor.run { analyzingDocId = docId; fehler = nil }

 do {
   let result = try await FunctionService.shared.analyzeDocument(
     docId: docId,
     caseId: caseId
   )
   if let res = result.result {
     await MainActor.run {
       analyseErgebnisse[docId] = res
       letzteStats = result.stats
     }
     await viewModel.laden()
     await MainActor.run { hydrateErgebnisse() }
   }
 } catch {
   let msg = error.localizedDescription
   let isRateLimit = msg.lowercased().contains("rate limit") || msg.contains("429")
   if isRateLimit && retryCount < 3 {
     let delay = UInt64(pow(2.0, Double(retryCount)) * 3_000_000_000)
     try? await Task.sleep(nanoseconds: delay)
     await dokumentAnalysieren(dok, retryCount: retryCount + 1)
     return
   }
   await MainActor.run {
     analyseErgebnisse[docId] = AnyCodable(["error": isRateLimit ? "Rate-Limit -- bitte kurz warten und erneut versuchen." : msg])
     fehler = "Analyse fehlgeschlagen: \(msg)"
   }
 }

 await MainActor.run { analyzingDocId = nil }
}

private func alleAnalysieren() async {
 for dok in viewModel.dokumente {
   guard let id = dok.id, analyseErgebnisse[id] == nil, dok.ai_summary == nil else { continue }
   await dokumentAnalysieren(dok)
 }
}

private func dokumentLoeschen(_ dok: LegalDocument) async {
 guard let id = dok.id else { return }
 try? await Services.documents.delete(id: id)
 await MainActor.run {
   viewModel.dokumente.removeAll { $0.id == id }
   analyseErgebnisse.removeValue(forKey: id)
 }
}

// MARK: - Drag & Drop

private func handleDrop(_ providers: [NSItemProvider]) {
 for provider in providers {
   provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
     if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
       DispatchQueue.main.async {
         self.pendingFiles.append(PendingFile(url: url))
       }
     }
   }
 }
}
}

// MARK: - Drop-Zone

struct DropZoneView: View {
@Binding var isDragOver: Bool
@Binding var pendingFiles: [PendingFile]
var kiMode: Bool = true
let onDropURLs: ([URL]) -> Void
let onAnalyzeAll: () -> Void
let onRemovePending: (UUID) -> Void

var body: some View {
 VStack(spacing: 8) {
   if pendingFiles.isEmpty {
     emptyZone
   } else {
     pendingZone
   }
 }
 .animation(.easeInOut(duration: 0.2), value: pendingFiles.isEmpty)
}

private var emptyZone: some View {
 VStack(spacing: 8) {
   Image(systemName: "arrow.down.doc.fill")
     .font(.system(size: 28))
     .foregroundStyle(isDragOver ? .green : .secondary)
   Text("Dateien hier ablegen oder")
     .font(.system(size: 13))
     .foregroundStyle(.secondary)
   Button("Datei auswählen") { selectFiles() }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     .controlSize(.small)
   Text("PDF, Word, Pages, Numbers, JPEG, PNG, MP4, MOV -- alle Formate")
     .font(.caption2)
     .foregroundStyle(.tertiary)
 }
 .frame(maxWidth: .infinity)
 .padding(28)
 .background(
   RoundedRectangle(cornerRadius: 10)
     .stroke(isDragOver ? Color.green : Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
 )
 .background(isDragOver ? Color.green.opacity(0.04) : Color.gray.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
}

private var pendingZone: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Text("\(pendingFiles.count) Datei(en) bereit")
       .font(.system(size: 12, weight: .semibold))
     Spacer()
     Button("+ Weitere") { selectFiles() }
       .buttonStyle(.plain)
       .font(.system(size: 11))
       .foregroundStyle(.blue)
     if kiMode {
       Button {
         onAnalyzeAll()
       } label: {
         Label("Alle hochladen & analysieren", systemImage: "wand.and.stars.inverse")
           .font(.system(size: 11, weight: .semibold))
       }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
       .controlSize(.small)
     }
   }

   ForEach(pendingFiles) { pending in
     HStack(spacing: 8) {
       Image(systemName: dateisymbol(pending.mimeType))
         .font(.system(size: 13))
         .foregroundStyle(.blue)
       Text(pending.name)
         .font(.system(size: 12))
         .lineLimit(1)
       Text(formatSize(pending.size))
         .font(.caption2)
         .foregroundStyle(.secondary)
       Spacer()
       if pending.isUploading {
         ProgressView().scaleEffect(0.6)
       } else {
         Button {
           onRemovePending(pending.id)
         } label: {
           Image(systemName: "xmark.circle.fill")
             .foregroundStyle(.secondary)
         }
         .buttonStyle(.plain)
       }
     }
     .padding(.horizontal, 8)
     .padding(.vertical, 4)
   }
 }
 .padding(12)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.15), lineWidth: 1))
}

private func selectFiles() {
 let panel = NSOpenPanel()
 panel.canChooseFiles = true
 panel.canChooseDirectories = false
 panel.allowsMultipleSelection = true
 panel.allowedContentTypes = [.pdf, .png, .jpeg, .movie, .video, .plainText, .data]
 if panel.runModal() == .OK {
   onDropURLs(panel.urls)
 }
}

private func dateisymbol(_ mime: String) -> String {
 if mime.hasPrefix("image/") { return "photo.fill" }
 if mime.hasPrefix("video/") { return "film.fill" }
 if mime.contains("pdf") { return "doc.richtext.fill" }
 if mime.contains("word") || mime.contains("document") { return "doc.text.fill" }
 return "doc.fill"
}

private func formatSize(_ bytes: Int64) -> String {
 if bytes < 1024 { return "\(bytes) B" }
 if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
 return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
}
}

// MARK: - Dokument-Karte

struct DokumentKarte: View {
let dokument: LegalDocument
let analyseLaeuft: Bool
let ergebnis: AnyCodable?
var kiMode: Bool = true
let onAnalysieren: () -> Void
let onLoeschen: () -> Void

@State private var aufgeklappt = false

private var istAnalysiert: Bool { ergebnis != nil || dokument.ai_summary != nil }
private var hatFehler: Bool {
 if let dict = ergebnis?.dictValue { return dict["error"] != nil }
 return false
}

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   // Kopfzeile
   HStack(spacing: 10) {
     Image(systemName: dateisymbol)
       .font(.system(size: 14))
       .foregroundStyle(.blue)
       .frame(width: 20)

     VStack(alignment: .leading, spacing: 2) {
       Text(dokument.title)
         .font(.system(size: 13, weight: .medium))
         .lineLimit(1)
       Text(dokument.file_type ?? "Unbekannter Typ")
         .font(.caption2)
         .foregroundStyle(.secondary)
     }

     Spacer()

     // Status-Button
     if analyseLaeuft {
       ProgressView()
         .scaleEffect(0.7)
       Text("KI analysiert…")
         .font(.caption2)
         .foregroundStyle(.secondary)
     } else if hatFehler {
       if kiMode {
         Button("Wiederholen") { onAnalysieren() }
           .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
           .controlSize(.mini)
           .tint(.red)
       }
     } else if istAnalysiert {
       Button {
         withAnimation { aufgeklappt.toggle() }
       } label: {
         Label("Ergebnis", systemImage: aufgeklappt ? "chevron.up" : "chevron.down")
           .font(.caption2.bold())
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       .controlSize(.mini)
       .tint(.green)
     } else if kiMode {
       Button("Analysieren") { onAnalysieren() }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
         .controlSize(.mini)
     }

     if let urlString = dokument.file_url,
      FenlynineOSSecurity.isSafeHTTPSURL(urlString),
      let url = URL(string: urlString) {
       Button {
         NSWorkspace.shared.open(url)
       } label: {
         Image(systemName: "arrow.up.right.square")
           .font(.caption)
       }
       .buttonStyle(.plain)
       .foregroundStyle(.blue)
     }

     Button { onLoeschen() } label: {
       Image(systemName: "trash")
         .font(.caption)
         .foregroundStyle(.secondary)
     }
     .buttonStyle(.plain)
     .help("Dokument löschen")
   }
   .padding(12)

   // Aufgeklapptes Ergebnis
   if aufgeklappt, istAnalysiert {
     Divider()
     AnalyseErgebnisView(
       ergebnis: ergebnis,
       zusammenfassung: dokument.ai_summary
     )
     .padding(12)
   }
 }
 .background(.background, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(
   istAnalysiert ? Color.green.opacity(0.2) : Color.gray.opacity(0.15),
   lineWidth: 1
 ))
}

private var dateisymbol: String {
 let mt = dokument.file_type ?? ""
 if mt.hasPrefix("image/") { return "photo.fill" }
 if mt.hasPrefix("video/") { return "film.fill" }
 if mt.contains("pdf") { return "doc.richtext.fill" }
 return "doc.fill"
}
}

// MARK: - Analyse-Ergebnis

struct AnalyseErgebnisView: View {
let ergebnis: AnyCodable?
let zusammenfassung: String?

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   if let zf = zusammenfassung, !zf.isEmpty {
     Text(zf)
       .font(.system(size: 12))
       .foregroundStyle(.secondary)
       .padding(8)
       .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
   }

   // Schritte-Fortschritt
   let befuellt = ANALYSE_SCHRITTE.filter { schritt in
     ergebnisHatSchritt(schritt.id)
   }

   if !befuellt.isEmpty {
     VStack(alignment: .leading, spacing: 6) {
       Text("\(befuellt.count)/10 Schritte befüllt")
         .font(.caption.bold())
         .foregroundStyle(.green)

       // Fortschrittsbalken
       HStack(spacing: 2) {
         ForEach(ANALYSE_SCHRITTE) { schritt in
           RoundedRectangle(cornerRadius: 2)
             .fill(ergebnisHatSchritt(schritt.id) ? Color.green : Color.gray.opacity(0.2))
             .frame(height: 6)
             .help("Schritt \(schritt.id): \(schritt.label)")
         }
       }

       // Befüllte Schritte
       ForEach(befuellt) { schritt in
         VStack(alignment: .leading, spacing: 4) {
           HStack(spacing: 6) {
             Image(systemName: "checkmark.circle.fill")
               .font(.caption2)
               .foregroundStyle(.green)
             Text("\(schritt.id). \(schritt.label)")
               .font(.caption)
             Text("-> \(schritt.wo)")
               .font(.caption2)
               .foregroundStyle(.secondary)
           }
           ForEach(schrittDetailZeilen(schritt.id), id: \.self) { zeile in
             Text(zeile).font(.caption2).foregroundStyle(.secondary)
               .padding(.leading, 20)
           }
         }
       }
     }
   }

   if let luecken = ergebnis?.dictValue?["informationsluecken"] as? [[String: Any]], !luecken.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Text("Informationslücken").font(.caption2.bold()).foregroundStyle(.orange)
       ForEach(Array(luecken.prefix(5).enumerated()), id: \.offset) { _, l in
         Text("(cid:127) \(l["schritt"] as? String ?? ""): \(l["hinweis"] as? String ?? "")")
           .font(.caption2).foregroundStyle(.secondary)
       }
     }
     .padding(8)
     .background(Color.orange.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
   }
 }
}

private func schrittDetailZeilen(_ num: Int) -> [String] {
 guard let dict = ergebnis?.dictValue else { return [] }
 switch num {
 case 1:
   let bd = dict["basisdaten"] as? [String: Any] ?? [:]
   var lines: [String] = []
   if let v = bd["gericht"] as? String, !v.isEmpty { lines.append("Gericht: \(v)") }
   if let v = bd["aktenzeichen"] as? String, !v.isEmpty { lines.append("AZ: \(v)") }
   if let v = bd["rechtsgebiet"] as? String, !v.isEmpty { lines.append("Rechtsgebiet: \(v)") }
   if let v = dict["streitwert"] as? Double, v > 0 { lines.append("Streitwert: \(Int(v)) €") }
   return lines
 case 2:
   let args = dict["argumente"] as? [[String: Any]] ?? []
   let bew = dict["beweise"] as? [[String: Any]] ?? []
   let fri = dict["fristen"] as? [[String: Any]] ?? []
   let per = dict["personen"] as? [[String: Any]] ?? []
   var lines: [String] = []
   if !args.isEmpty { lines.append("\(args.count) Argumente") }
   if !bew.isEmpty { lines.append("\(bew.count) Beweise") }
   if !fri.isEmpty { lines.append("\(fri.count) Fristen") }
   if !per.isEmpty { lines.append("\(per.count) Personen") }
   lines += args.prefix(3).compactMap { $0["titel"] as? String }.map { "3 \($0)" }
   lines += bew.prefix(2).compactMap { $0["titel"] as? String }.map { "n \($0)" }
   return lines
 case 3:
   let g = dict["schritt3_gegneranalyse"] as? [String: Any] ?? [:]
   return (g["taktiken"] as? [String] ?? []).prefix(3).map { "n \($0)" }
 case 4:
   let g = dict["schritt4_rechtliche_analyse"] as? [String: Any] ?? [:]
   return (g["relevante_paragrafen"] as? [String] ?? []).prefix(4).map { "§ \($0)" }
 case 5:
   if let s = (dict["schritt5_strategie"] as? [String: Any])?["empfohlene_strategie"] as? String {
     return [String(s.prefix(120))]
   }
   return []
 case 6:
   let g = dict["schritt6_risiko"] as? [String: Any] ?? [:]
   return (g["risiken"] as? [String] ?? []).prefix(3).map { "n \($0)" }
 case 7:
   let g = dict["schritt7_simulation"] as? [String: Any] ?? [:]
   var lines: [String] = []
   if let s = g["prognose_einfluss"] as? String, !s.isEmpty { lines.append(s) }
   if let v = g["vergleichswert_eur"] as? Double, v > 0 { lines.append("Vergleich: \(Int(v)) €") }
   return lines
 case 8:
   let g = dict["schritt8_aktion"] as? [String: Any] ?? [:]
   return (g["naechste_schritte"] as? [String] ?? []).prefix(3).map { "-> \($0)" }
 case 9:
   let g = dict["schritt9_cockpit"] as? [String: Any] ?? [:]
   if let d = g["prognose_delta_pct"] as? Double { return ["Prognose D: \(Int(d))%"] }
   return []
 case 10:
   let g = dict["schritt10_abschluss"] as? [String: Any] ?? [:]
   return [g["vergleichsempfehlung"] as? String].compactMap { $0 }
 default:
   return []
 }
}

private func ergebnisHatSchritt(_ num: Int) -> Bool {
 guard let dict = ergebnis?.dictValue else { return false }
 switch num {
 case 1: return dict["basisdaten"] != nil || dict["streitwert"] != nil
 case 2: return (dict["argumente"] as? [Any]).map { !$0.isEmpty } ?? false ||
         (dict["beweise"] as? [Any]).map { !$0.isEmpty } ?? false
 case 3: return (dict["schritt3_gegneranalyse"] as? [String: Any])?["zusammenfassung"] != nil
 case 4: return (dict["schritt4_rechtliche_analyse"] as? [String: Any])?["zusammenfassung"] != nil
 case 5: return (dict["schritt5_strategie"] as? [String: Any])?["empfohlene_strategie"] != nil
 case 6: return (dict["schritt6_risiko"] as? [String: Any])?["zusammenfassung"] != nil
 case 7: return (dict["schritt7_simulation"] as? [String: Any])?["prognose_einfluss"] != nil
 case 8: return (dict["schritt8_aktion"] as? [String: Any])?["zusammenfassung"] != nil
 case 9: return (dict["schritt9_cockpit"] as? [String: Any])?["zusammenfassung"] != nil
 case 10: return (dict["schritt10_abschluss"] as? [String: Any])?["zusammenfassung"] != nil
 default: return false
 }
}
}

// MARK: - Gesamtabdeckung

struct GesamtAbdeckungView: View {
let dokumente: [LegalDocument]
let ergebnisse: [String: AnyCodable]

var body: some View {
 let abdeckung = ANALYSE_SCHRITTE.filter { schritt in
   dokumente.contains { dok in
     let res = ergebnisse[dok.id ?? ""]
     return schrittBefuelltInDoc(schritt.id, result: res)
   }
 }

 if !abdeckung.isEmpty {
   VStack(alignment: .leading, spacing: 8) {
     Text("Gesamtabdeckung -- \(abdeckung.count)/10 Schritte aus Dokumenten befüllt")
       .font(.caption.bold())
       .foregroundStyle(.secondary)

     HStack(spacing: 2) {
       ForEach(ANALYSE_SCHRITTE) { schritt in
         RoundedRectangle(cornerRadius: 2)
           .fill(abdeckung.contains(where: { $0.id == schritt.id }) ? Color.green : Color.gray.opacity(0.2))
           .frame(height: 8)
           .help("Schritt \(schritt.id): \(schritt.label)")
       }
     }
   }
   .padding(12)
   .background(Color.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 }
}

private func schrittBefuelltInDoc(_ num: Int, result: AnyCodable?) -> Bool {
 guard let dict = result?.dictValue else { return false }
 switch num {
 case 1: return dict["basisdaten"] != nil
 case 2: return (dict["argumente"] as? [Any]).map { !$0.isEmpty } ?? false
 case 3: return (dict["schritt3_gegneranalyse"] as? [String: Any]) != nil
 case 4: return (dict["schritt4_rechtliche_analyse"] as? [String: Any]) != nil
 case 5: return (dict["schritt5_strategie"] as? [String: Any]) != nil
 case 6: return (dict["schritt6_risiko"] as? [String: Any]) != nil
 case 7: return (dict["schritt7_simulation"] as? [String: Any]) != nil
 case 8: return (dict["schritt8_aktion"] as? [String: Any]) != nil
 case 9: return (dict["schritt9_cockpit"] as? [String: Any]) != nil
 case 10: return (dict["schritt10_abschluss"] as? [String: Any]) != nil
 default: return false
 }
}
}

// MARK: - KI Erklärungs-Panel

struct KIErklaerungsPanel: View {
@Binding var expanded: Bool

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   Button {
     withAnimation { expanded.toggle() }
   } label: {
     HStack {
       Image(systemName: "info.circle")
         .foregroundStyle(.blue)
       Text("Was macht die KI-Analyse genau?")
         .font(.system(size: 12, weight: .medium))
       Text("-- Welche Daten aus dem Dokument werden in welchem Schritt eingetragen")
         .font(.caption)
         .foregroundStyle(.secondary)
       Spacer()
       Image(systemName: expanded ? "chevron.up" : "chevron.down")
         .font(.caption)
         .foregroundStyle(.secondary)
     }
   }
   .buttonStyle(.plain)
   .padding(10)

   if expanded {
     Divider()
     VStack(alignment: .leading, spacing: 6) {
       ForEach(ANALYSE_SCHRITTE) { schritt in
         HStack(alignment: .top, spacing: 8) {
           Text("\(schritt.id)")
             .font(.system(size: 10, weight: .bold))
             .foregroundStyle(.white)
             .frame(width: 16, height: 16)
             .background(Color.blue, in: Circle())
           VStack(alignment: .leading, spacing: 2) {
             Text(schritt.label)
               .font(.caption.bold())
             Text("-> \(schritt.wo)")
               .font(.caption2)
               .foregroundStyle(.secondary)
             Text("n \(schritt.hinweis)")
               .font(.caption2)
               .foregroundStyle(.tertiary)
           }
         }
       }
     }
     .padding(10)
   }
 }
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.1), lineWidth: 1))
}
}

