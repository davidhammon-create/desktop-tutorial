import Foundation
import AppKit
import CryptoKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// UPDATE-SYSTEM -- stetige Neuerungen ohne App-Store-Zwang
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Manifest (JSON) lokal oder per URL. Publish-Skript legt Releases ab.
// Installation: signed .app / .zip -> Quarantäne lösen -> ersetzen -> Neustart.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct UpdateManifest: Codable, Equatable {
var version: String
var build: Int
var releasedAt: Date?
var minSystemVersion: String?
var downloadURL: String
var sha256: String?
var notes: String
var mandatory: Bool?

var notesZeilen: [String] {
  notes
    .components(separatedBy: .newlines)
    .map { $0.trimmingCharacters(in: .whitespaces) }
    .filter { !$0.isEmpty }
}
}

enum UpdateStatus: Equatable {
case idle
case checking
case upToDate
case available(UpdateManifest)
case downloading(Double)
case installing
case failed(String)
}

@Observable
@MainActor
final class UpdateService {
static let shared = UpdateService()

private(set) var status: UpdateStatus = .idle
private(set) var letzterCheck: Date?
private(set) var installierterHinweis: String?

/// Override-URL (z. B. eigener Server). Leer = lokale Kandidaten.
var feedURLString: String {
  get { UserDefaults.standard.string(forKey: "fenlynineos_update_feed_url") ?? "" }
  set { UserDefaults.standard.set(newValue, forKey: "fenlynineos_update_feed_url") }
}

var aktuelleVersion: String {
  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
}

var aktuellerBuild: Int {
  let raw = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
  return Int(raw) ?? 1
}

private init() {}

// MARK: - Check

func pruefen(automatisch: Bool = false) async {
  if case .downloading = status { return }
  if case .installing = status { return }
  status = .checking
  do {
    guard let manifest = try await ladeManifest() else {
      status = .upToDate
      letzterCheck = .init()
      return
    }
    letzterCheck = .init()
    if istNeuer(manifest) {
      status = .available(manifest)
      if !automatisch {
        installierterHinweis = "Version \(manifest.version) (Build \(manifest.build)) verfügbar"
      }
    } else {
      status = .upToDate
    }
  } catch {
    status = .failed(error.localizedDescription)
  }
}

func installierenFallsVerfuegbar() async {
  guard case .available(let m) = status else { return }
  await installiere(m)
}

// MARK: - Install

func installiere(_ manifest: UpdateManifest) async {
 status = .downloading(0.05)
 do {
   let paket = try await ladePaket(von: manifest) { [weak self] p in
     Task { @MainActor in self?.status = .downloading(p) }
   }
   status = .installing
   try ersetzeApp(mit: paket)
   status = .upToDate
   installierterHinweis = "Update \(manifest.version) installiert -- Neustart empfohlen"
   frageNeustart()
 } catch {
   status = .failed(error.localizedDescription)
 }
}

// MARK: - Manifest laden

private func ladeManifest() async throws -> UpdateManifest? {
 let kandidaten = feedKandidaten()
 var letzterFehler: Error?
 for url in kandidaten {
   do {
     let data: Data
     if url.isFileURL {
       data = try Data(contentsOf: url)
     } else {
       let (d, resp) = try await URLSession.shared.data(from: url)
       guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
         throw URLError(.badServerResponse)
       }
       data = d
     }
     let dec = JSONDecoder()
     dec.dateDecodingStrategy = .iso8601
     return try dec.decode(UpdateManifest.self, from: data)
   } catch {
     letzterFehler = error
     continue
   }
 }
 if let letzterFehler { throw letzterFehler }
 return nil
}

private func feedKandidaten() -> [URL] {
 var list: [URL] = []
 // Remote-Feed nur bei expliziter Freigabe (Standard: AUS -- kein stilles Binary-Replace)
 if FenlynineOSSicherheitsHaertung.remoteUpdatesErlaubt,
  let s = feedURLString.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
  let u = URL(string: s),
  u.scheme == "https" || u.isFileURL {
   list.append(u)
 }
 // Immer: nur lokale Manifeste (kein Netzwerk)
 let home = FileManager.default.homeDirectoryForCurrentUser
 let laws = URL(fileURLWithPath: "/Users/davidniemann/Documents/Hågemmøn & Partner /lOS (LegalOS) - Laws/LegalOS-App")
 list.append(contentsOf: [
   laws.appendingPathComponent("updates/manifest.json"),
   home.appendingPathComponent("Library/Application Support/FenlynineOS/Updates/manifest.json"),
   home.appendingPathComponent("Downloads/FenlynineOS-Updates/manifest.json")
 ])
 return list
}

private func istNeuer(_ m: UpdateManifest) -> Bool {
 if m.build > aktuellerBuild { return true }
 return vergleicheVersion(m.version, aktuelleVersion) > 0
}

/// -1 / 0 / 1
private func vergleicheVersion(_ a: String, _ b: String) -> Int {
 let pa = a.split(separator: ".").compactMap { Int($0) }
 let pb = b.split(separator: ".").compactMap { Int($0) }
 let n = max(pa.count, pb.count)
 for i in 0..<n {
   let x = i < pa.count ? pa[i] : 0
   let y = i < pb.count ? pb[i] : 0
   if x != y { return x < y ? -1 : 1 }
 }
 return 0
}

// MARK: - Download

private func ladePaket(von manifest: UpdateManifest, progress: @escaping (Double) -> Void) async throws -> URL {
 guard let url = URL(string: manifest.downloadURL) else {
   throw UpdateFehler.ungueltigeURL
 }

 let ziel = FileManager.default.temporaryDirectory
   .appendingPathComponent("FenlynineOS-Update-\(manifest.version)-\(UUID().uuidString.prefix(6))", isDirectory: true)
 try FileManager.default.createDirectory(at: ziel, withIntermediateDirectories: true)

 if url.isFileURL {
   progress(0.4)
   let name = url.lastPathComponent
   let dest = ziel.appendingPathComponent(name)
   if FileManager.default.fileExists(atPath: dest.path) {
     try FileManager.default.removeItem(at: dest)
   }
   try FileManager.default.copyItem(at: url, to: dest)
   progress(0.9)
   if let expected = manifest.sha256?.lowercased(), !expected.isEmpty {
     let hash = try sha256Hex(of: dest)
     guard hash == expected else { throw UpdateFehler.hashMismatch }
   }
   return dest
 }

 // Netzwerk-Download: nur mit expliziter Freigabe + Pflicht-SHA256
 guard FenlynineOSSicherheitsHaertung.remoteUpdatesErlaubt else {
   throw UpdateFehler.fehlgeschlagen("Remote-Updates sind deaktiviert (Sicherheit). Nur lokale Pakete.")
 }
 guard url.scheme == "https" else {
   throw UpdateFehler.fehlgeschlagen("Remote-Updates nur über HTTPS.")
 }
 guard let expected = manifest.sha256?.lowercased(), !expected.isEmpty else {
   throw UpdateFehler.fehlgeschlagen("Remote-Update ohne SHA-256-Prüfsumme abgelehnt.")
 }

 let (tempURL, resp) = try await URLSession.shared.download(from: url)
 progress(0.85)
 guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
   throw URLError(.badServerResponse)
 }
 let name = url.lastPathComponent.isEmpty ? "FenlynineOS-Update.zip" : url.lastPathComponent
 let dest = ziel.appendingPathComponent(name)
 try? FileManager.default.removeItem(at: dest)
 try FileManager.default.moveItem(at: tempURL, to: dest)
 let hash = try sha256Hex(of: dest)
 guard hash == expected else { throw UpdateFehler.hashMismatch }
 progress(1.0)
 return dest
}

private func ersetzeApp(mit paket: URL) throws {
 let bundle = Bundle.main.bundleURL
 guard bundle.pathExtension == "app" else {
   throw UpdateFehler.keinAppBundle
 }

 let neueApp: URL
 if paket.pathExtension == "app" {
   neueApp = paket
 } else if paket.pathExtension.lowercased() == "zip" {
   let entpackt = paket.deletingLastPathComponent().appendingPathComponent("extracted", isDirectory: true)
   try? FileManager.default.removeItem(at: entpackt)
   try FileManager.default.createDirectory(at: entpackt, withIntermediateDirectories: true)
   try unzip(paket, nach: entpackt)
   guard let gefunden = findeApp(in: entpackt) else { throw UpdateFehler.keinAppImPaket }
   neueApp = gefunden
 } else {
   throw UpdateFehler.unbekanntesPaket
 }

 // Quarantäne / erweiterte Attribute entfernen
 _ = try? shell(["/usr/bin/xattr", "-cr", neueApp.path])

 let backup = bundle.deletingLastPathComponent()
   .appendingPathComponent("FenlynineOS.backup-\(Int(Date().timeIntervalSince1970)).app")
 try FileManager.default.copyItem(at: bundle, to: backup)

 // Atomarer Tausch über Staging
 let staging = bundle.deletingLastPathComponent()
   .appendingPathComponent("FenlynineOS.staging-\(UUID().uuidString.prefix(6)).app")
 try? FileManager.default.removeItem(at: staging)
 try FileManager.default.copyItem(at: neueApp, to: staging)
 _ = try? shell(["/usr/bin/xattr", "-cr", staging.path])

 // Signatur optional ad-hoc, falls vorhanden
 _ = try? shell(["/usr/bin/codesign", "--force", "--sign", "-", "--timestamp=none", staging.path])

 try FileManager.default.removeItem(at: bundle)
 try FileManager.default.moveItem(at: staging, to: bundle)
}

private func frageNeustart() {
 let alert = NSAlert()
 alert.messageText = "Update installiert"
 alert.informativeText = "FenlynineOS Legal Suite neu starten, damit die neue Version läuft?"
 alert.addButton(withTitle: "Jetzt neu starten")
 alert.addButton(withTitle: "Später")
 if alert.runModal() == .alertFirstButtonReturn {
   let app = Bundle.main.bundleURL
   NSWorkspace.shared.openApplication(at: app, configuration: .init()) { _, _ in
     DispatchQueue.main.async { NSApp.terminate(nil) }
   }
 }
}

// MARK: - Helpers

private func findeApp(in dir: URL) -> URL? {
 let fm = FileManager.default
 if let kids = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
   if let app = kids.first(where: { $0.pathExtension == "app" }) { return app }
   for k in kids where k.hasDirectoryPath {
     if let nested = findeApp(in: k) { return nested }
   }
 }
 return nil
}

private func unzip(_ zip: URL, nach dest: URL) throws {
 try shell(["/usr/bin/unzip", "-qo", zip.path, "-d", dest.path])
}

@discardableResult
private func shell(_ args: [String]) throws -> String {
 let p = Process()
 p.executableURL = URL(fileURLWithPath: args[0])
 p.arguments = Array(args.dropFirst())
 let out = Pipe()
 let err = Pipe()
 p.standardOutput = out
 p.standardError = err
 try p.run()
 p.waitUntilExit()
 if p.terminationStatus != 0 {
   let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "shell fehlgeschlagen"
   throw UpdateFehler.shell(msg)
 }
 return String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

private func sha256Hex(of url: URL) throws -> String {
 let data = try Data(contentsOf: url)
 return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}
}

enum UpdateFehler: LocalizedError {
case ungueltigeURL
case hashMismatch
case keinAppBundle
case keinAppImPaket
case unbekanntesPaket
case shell(String)
case fehlgeschlagen(String)

var errorDescription: String? {
 switch self {
 case .ungueltigeURL: return "Ungültige Download-URL"
 case .hashMismatch: return "Prüfsumme stimmt nicht -- Abbruch"
 case .keinAppBundle: return "Nicht aus einem .app-Bundle gestartet"
 case .keinAppImPaket: return "Keine .app im Update-Paket"
 case .unbekanntesPaket: return "Paket muss .app oder .zip sein"
 case .shell(let m): return m
 case .fehlgeschlagen(let m): return m
 }
}
}

private extension String {
var nilIfEmpty: String? { isEmpty ? nil : self }
}

