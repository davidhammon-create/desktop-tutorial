import SwiftUI
import AppKit
import UniformTypeIdentifiers

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// ADMIN-ONLY -- Quellcode-Archiv & Live-Code-Ansicht
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// NUR HINZUGEFÜGT. Sichtbar ausschließlich für KontoStore.istAdmin.
// Zeigt den gesamten Suite-Code (aus Application-Support-Snapshot und/oder
// Projektwurzel), aktualisiert sich bei Dateiänderungen, listet PDF-Archive
// (u. a. bei Build-Fehlschlag erzeugt) und erlaubt Export/Öffnen.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

@Observable
@MainActor
final class AdminCodeArchivStore {
static let shared = AdminCodeArchivStore()

struct CodeDatei: Identifiable, Hashable {
  var id: String { relPath }
  var relPath: String
  var absoluteURL: URL
  var bytes: Int
  var modified: Date
  var kategorie: String
  var funktion: String
  var zeilen: Int
}

struct PdfArchiv: Identifiable, Hashable {
  var id: String { url.path }
  var url: URL
  var name: String
  var modified: Date
  var bytes: Int
  var istBuildFail: Bool
}

var dateien: [CodeDatei] = []
var pdfs: [PdfArchiv] = []
var ausgewaehlt: CodeDatei? = nil
var inhalt: String = ""
var filter: String = ""
var kategorieFilter: String = "Alle"
var statusZeile: String = ""
var projektPfad: String = ""
var snapshotPfad: String = ""
var letzteAktualisierung: Date? = nil

private var watcher: DispatchSourceFileSystemObject?
private var watchFD: Int32 = -1

private var supportRoot: URL {
  FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("FenlynineOS/CodeSnapshot", isDirectory: true)
}

var currentRoot: URL {
  supportRoot.appendingPathComponent("current", isDirectory: true)
}

var archivesRoot: URL {
  supportRoot.appendingPathComponent("archives", isDirectory: true)
}

var kategorien: [String] {
  let set = Set(dateien.map(\.kategorie))
  return ["Alle"] + set.sorted()
}

var gefiltert: [CodeDatei] {
  dateien.filter { d in
    let katOk = kategorieFilter == "Alle" || d.kategorie == kategorieFilter
    let q = filter.trimmingCharacters(in: .whitespacesAndNewlines)
    let qOk = q.isEmpty
      || d.relPath.localizedCaseInsensitiveContains(q)
      || d.funktion.localizedCaseInsensitiveContains(q)
    return katOk && qOk
  }
}

func starten() {
  try? FileManager.default.createDirectory(at: currentRoot, withIntermediateDirectories: true)
  try? FileManager.default.createDirectory(at: archivesRoot, withIntermediateDirectories: true)
  ladenProjektHinweis()
  aktualisieren()
  starteWatcher()
}

func stoppen() {
  watcher?.cancel()
  watcher = nil
  if watchFD >= 0 { close(watchFD); watchFD = -1 }
}

func aktualisieren() {
  ladenProjektHinweis()
  dateien = scanneCode()
  pdfs = scannePDFs()
 letzteAktualisierung = Date()
 statusZeile = "\(dateien.count) Dateien · \(pdfs.count) PDF-Archive · Snapshot: \(currentRoot.path)"
 if let sel = ausgewaehlt,
  let neu = dateien.first(where: { $0.relPath == sel.relPath }) {
   ladeInhalt(neu)
 }
}

func ladeInhalt(_ datei: CodeDatei) {
 ausgewaehlt = datei
 if let text = try? String(contentsOf: datei.absoluteURL, encoding: .utf8) {
   inhalt = text
 } else if let data = try? Data(contentsOf: datei.absoluteURL) {
   inhalt = String(decoding: data, as: UTF8.self)
 } else {
   inhalt = "/* Datei konnte nicht gelesen werden */"
 }
}

/// Synchronisiert Projektwurzel -> Application-Support-Snapshot (wenn erreichbar).
func snapshotJetztAktualisieren() {
 let fm = FileManager.default
 let root: URL?
 if !projektPfad.isEmpty, fm.fileExists(atPath: projektPfad) {
   root = URL(fileURLWithPath: projektPfad)
 } else if let detected = Self.findeProjektWurzel() {
   root = detected
   projektPfad = detected.path
   try? detected.path.write(to: supportRoot.appendingPathComponent("project_root.txt"), atomically: true, encoding: .utf8)
 } else {
   statusZeile = "Keine Projektwurzel gefunden -- zeige vorhandenen Snapshot."
   aktualisieren()
   return
 }
 guard let root else { return }

 let ziel = currentRoot
 try? fm.createDirectory(at: ziel, withIntermediateDirectories: true)
 for name in ["Package.swift", "Sources", "Configuration", "scripts"] {
   let src = root.appendingPathComponent(name)
   let dst = ziel.appendingPathComponent(name)
   guard fm.fileExists(atPath: src.path) else { continue }
   try? fm.removeItem(at: dst)
   try? fm.copyItem(at: src, to: dst)
 }
 statusZeile = "Snapshot aktualisiert aus \(root.path)"
 aktualisieren()
}

func oeffnePDF(_ pdf: PdfArchiv) {
 NSWorkspace.shared.open(pdf.url)
}

func oeffneArchivOrdner() {
 NSWorkspace.shared.open(archivesRoot)
}

func oeffneSnapshotOrdner() {
 NSWorkspace.shared.open(currentRoot)
}

func exportiereAusgewaehlteDatei() {
 guard let d = ausgewaehlt else { return }
 let panel = NSSavePanel()
 panel.nameFieldStringValue = (d.relPath as NSString).lastPathComponent
 panel.begin { antwort in
   guard antwort == .OK, let url = panel.url else { return }
   try? FileManager.default.copyItem(at: d.absoluteURL, to: url)
 }
}

// MARK: - Privat

private func ladenProjektHinweis() {
 snapshotPfad = currentRoot.path
 let marker = supportRoot.appendingPathComponent("project_root.txt")
 if let text = try? String(contentsOf: marker, encoding: .utf8) {
   projektPfad = text.trimmingCharacters(in: .whitespacesAndNewlines)
 } else if let found = Self.findeProjektWurzel() {
   projektPfad = found.path
 }
}

private static func findeProjektWurzel() -> URL? {
 // 1) Neben der .app (Developer-Layout)
 if let app = Bundle.main.bundleURL.deletingLastPathComponent() as URL? {
   let kandidaten = [
     app.appendingPathComponent("Sources"),
     app.deletingLastPathComponent().appendingPathComponent("Sources"),
   ]
   for k in kandidaten {
     let root = k.deletingLastPathComponent()
     if FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
       return root
     }
   }
 }
 // 2) Bekannter Workspace-Pfad (nur wenn vorhanden)
 let known = "/Users/davidniemann/Documents/Hågemmøn & Partner /lOS (LegalOS) - Laws/LegalOS-App"
 if FileManager.default.fileExists(atPath: known + "/Package.swift") {
   return URL(fileURLWithPath: known)
 }
 return nil
}

private func scanneCode() -> [CodeDatei] {
 let root = currentRoot
 guard FileManager.default.fileExists(atPath: root.path) else { return [] }
 var result: [CodeDatei] = []
 let exts: Set<String> = ["swift", "plist", "entitlements", "sh", "md", "json", "html", "css", "txt", "yml", "yaml"]
 if let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) {
   for case let url as URL in enumerator {
     guard exts.contains(url.pathExtension.lowercased()) else { continue }
     let rel = url.path.replacingOccurrences(of: root.path + "/", with: "")
     let vals = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
     let zeilen: Int = {
       guard let t = try? String(contentsOf: url, encoding: .utf8) else { return 0 }
       return t.split(separator: "\n", omittingEmptySubsequences: false).count
     }()
     result.append(CodeDatei(
       relPath: rel,
       absoluteURL: url,
       bytes: vals?.fileSize ?? 0,
       modified: vals?.contentModificationDate ?? .distantPast,
       kategorie: Self.kategorie(fuer: rel),
       funktion: Self.funktion(fuer: rel),
       zeilen: zeilen
     ))
   }
 }
 return result.sorted { $0.relPath.localizedCaseInsensitiveCompare($1.relPath) == .orderedAscending }
}

private func scannePDFs() -> [PdfArchiv] {
 let root = archivesRoot
 guard let urls = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) else { return [] }
 return urls.filter { $0.pathExtension.lowercased() == "pdf" }.map { url in
   let vals = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
   let name = url.lastPathComponent
   return PdfArchiv(
     url: url,
     name: name,
     modified: vals?.contentModificationDate ?? .distantPast,
     bytes: vals?.fileSize ?? 0,
     istBuildFail: name.contains("build-fail")
   )
 }.sorted { $0.modified > $1.modified }
}

private func starteWatcher() {
 stoppen()
 let path = currentRoot.path
 watchFD = open(path, O_EVTONLY)
 guard watchFD >= 0 else { return }
 let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: watchFD, eventMask: [.write, .rename, .delete, .extend], queue: .main)
 src.setEventHandler { [weak self] in
   self?.aktualisieren()
 }
 src.setCancelHandler { [weak self] in
   if let fd = self?.watchFD, fd >= 0 { close(fd) }
   self?.watchFD = -1
 }
 watcher = src
 src.resume()
}

static func kategorie(fuer rel: String) -> String {
 let r = rel
 if r.hasPrefix("Configuration/") || r.hasPrefix("scripts/") || r == "Package.swift" || r.contains("FenlynineOSApp.swift") {
   return "00 Einstieg / Build / Config"
 }
 if r.contains("/Core/Models/") { return "01 Core · Modelle" }
 if r.contains("/Core/Base44/") { return "02 Core · Base44 / KI" }
 if r.contains("/Core/Konto/") || r.contains("/Core/Auth/") || r.contains("/Core/Security/") {
   return "03 Core · Konto / Auth / Security"
 }
 if r.contains("/Core/") { return "04 Core · Services / Local / Kern" }
 if r.contains("/Components/") { return "05 Components / Design" }
 if r.contains("/Features/Shell/") { return "06 Shell / Einstellungen" }
 if r.contains("/Features/Cases/Tabs/Macht") || r.contains("Kausalstrang") || r.contains("/Features/Imperium/") {
   return "08 Macht & Einfluss / Kausalstrang"
 }
 if r.contains("/Pfadgraf/") { return "09 Pfadgraf (Wegenetz)" }
 if r.contains("/Features/Cases/") { return "07 Lexara / Cases" }
 if r.contains("/Features/Vorgang/") { return "10 Vorgang / Linsen" }
 if r.contains("/Features/Strategos/") { return "11 Strategos" }
 if r.contains("/Features/Opportunisma/") { return "12 Opportunisma" }
 if r.contains("/Features/Studio/") || r.contains("/Features/Organon/") { return "13 Studio / Organon" }
 if r.contains("/Features/") { return "14 Weitere Features" }
 if r.contains("/Resources/") { return "15 Resources" }
 return "99 Sonstige"
}

static func funktion(fuer rel: String) -> String {
 let n = (rel as NSString).lastPathComponent.lowercased()
 var h: [String] = []
 if n.contains("model") { h.append("Datenmodell") }
 if n.contains("engine") || n.contains("motor") || n.contains("formel") || n.contains("algorithm") { h.append("Rechen-/Simulations-Engine") }
 if n.contains("view") || n.hasPrefix("tab") || n.contains("linse") || n.contains("canvas") { h.append("SwiftUI UI/UX") }
 if n.contains("store") || n.contains("service") || n.contains("client") { h.append("Service/Persistenz/API") }
 if n.contains("einstellung") || n.contains("config") { h.append("Einstellungen/Konfiguration") }
 if n.hasSuffix(".sh") { h.append("Build-/Start-Skript") }
 if n.hasSuffix(".plist") || n.hasSuffix(".entitlements") { h.append("App-Metadaten/Berechtigungen") }
 if n.contains("auth") || n.contains("konto") { h.append("Auth/Konto") }
 if n.contains("llm") || n.contains("ki") || n.contains("base44") { h.append("KI-Anbindung") }
 if h.isEmpty { h.append("Modulbestandteil FenlynineOS") }
 return h.joined(separator: " · ")
}
}

// MARK: - View (nur Admin)

struct AdminCodeArchivView: View {
@State private var store = AdminCodeArchivStore.shared
@ObservedObject private var konto = KontoStore.shared

var body: some View {
 Group {
   if konto.istAdmin {
     inhalt
   } else {
     ContentUnavailableView(
       "Nur für Administratoren",
       systemImage: "lock.shield",
       description: Text("Dieser Reiter ist ausschließlich für Administrator-Konten sichtbar.")
     )
     .padding(40)
   }
 }
 .onAppear { if konto.istAdmin { store.starten() } }
 .onDisappear { store.stoppen() }
}

private var inhalt: some View {
 VStack(alignment: .leading, spacing: 12) {
   header
   HSplitView {
     dateiListe
       .frame(minWidth: 320, idealWidth: 380)
     codeAnsicht
       .frame(minWidth: 420)
   }
   .frame(minHeight: 520)
   pdfArchivLeiste
 }
 .padding(16)
}

private var header: some View {
 VStack(alignment: .leading, spacing: 6) {
   HStack {
     Label("Quellcode (Admin)", systemImage: "chevron.left.forwardslash.chevron.right")
       .font(.system(size: 16, weight: .bold))
     Spacer()
     Button("Snapshot aktualisieren") { store.snapshotJetztAktualisieren() }
     Button("Neu laden") { store.aktualisieren() }
     Button("Snapshot-Ordner") { store.oeffneSnapshotOrdner() }
     Button("PDF-Archiv-Ordner") { store.oeffneArchivOrdner() }
   }
   Text(store.statusZeile)
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
   if !store.projektPfad.isEmpty {
     Text("Projektwurzel: \(store.projektPfad)")
       .font(.system(size: 10).monospaced())
       .foregroundStyle(.secondary)
   }
   Text("Jeder Build-Fehlschlag legt automatisch ein PDF mit dem gesamten Code unter archives/ ab. Der Live-Code aktualisiert sich, sobald Dateien im Snapshot geändert werden.")
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
 }
}

private var dateiListe: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     TextField("Suche Pfad / Funktion…", text: Binding(
       get: { store.filter },
       set: { store.filter = $0 }
     ))
     .textFieldStyle(.roundedBorder)
     Picker("Kategorie", selection: Binding(
       get: { store.kategorieFilter },
       set: { store.kategorieFilter = $0 }
     )) {
       ForEach(store.kategorien, id: \.self) { k in
         Text(k).tag(k)
       }
     }
     .frame(width: 220)
   }
   List(selection: Binding(
     get: { store.ausgewaehlt },
     set: { if let d = $0 { store.ladeInhalt(d) } }
   )) {
     ForEach(store.gefiltert) { d in
       VStack(alignment: .leading, spacing: 2) {
         Text(d.relPath)
           .font(.system(size: 11, weight: .semibold).monospaced())
           .lineLimit(2)
         Text("\(d.kategorie) · \(d.funktion) · \(d.zeilen) Zeilen")
           .font(.system(size: 9))
           .foregroundStyle(.secondary)
           .lineLimit(2)
       }
       .tag(d)
     }
   }
   .listStyle(.inset)
 }
}

private var codeAnsicht: some View {
 VStack(alignment: .leading, spacing: 6) {
   HStack {
     if let d = store.ausgewaehlt {
       Text(d.relPath)
         .font(.system(size: 11, weight: .bold).monospaced())
       Spacer()
       Text("\(d.zeilen) Zeilen · \(ByteCountFormatter.string(fromByteCount: Int64(d.bytes), countStyle: .file))")
         .font(.system(size: 10))
         .foregroundStyle(.secondary)
       Button("Exportieren…") { store.exportiereAusgewaehlteDatei() }
     } else {
       Text("Datei wählen")
         .foregroundStyle(.secondary)
       Spacer()
     }
   }
   ScrollView {
     Text(store.inhalt.isEmpty ? "-- kein Inhalt --" : store.inhalt)
       .font(.system(size: 10, design: .monospaced))
       .textSelection(.enabled)
       .frame(maxWidth: .infinity, alignment: .topLeading)
       .padding(8)
   }
   .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
   .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
 }
}

private var pdfArchivLeiste: some View {
 VStack(alignment: .leading, spacing: 6) {
   Text("PDF-ARCHIVE (inkl. Build-Fehlschläge)")
     .font(.system(size: 10, weight: .bold))
     .foregroundStyle(.secondary)
   if store.pdfs.isEmpty {
     Text("Noch keine PDF-Archive. Export-Skript oder fehlgeschlagener Build legt welche ab.")
       .font(.system(size: 10))
       .foregroundStyle(.secondary)
   } else {
     ScrollView(.horizontal, showsIndicators: false) {
       HStack(spacing: 8) {
         ForEach(store.pdfs) { pdf in
           Button {
             store.oeffnePDF(pdf)
           } label: {
             VStack(alignment: .leading, spacing: 2) {
               HStack(spacing: 4) {
                 Image(systemName: "doc.richtext")
                 Text(pdf.name)
                   .font(.system(size: 10, weight: .semibold))
                   .lineLimit(1)
               }
               Text(pdf.modified.formatted(date: .abbreviated, time: .shortened))
                 .font(.system(size: 9))
                 .foregroundStyle(.secondary)
               if pdf.istBuildFail {
                 Text("BUILD-FAIL")
                   .font(.system(size: 8, weight: .bold))
                   .foregroundStyle(.red)
               }
             }
             .padding(8)
             .frame(width: 260, alignment: .leading)
             .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
           }
           .buttonStyle(.plain)
         }
       }
     }
   }
 }
}
}

