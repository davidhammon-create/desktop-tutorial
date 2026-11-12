import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Offline-First Cache (JSON-basiert, kein SwiftData-Dependency nötig)
//
// Speichert alle Entitäten als JSON in Application Support.
// Wird automatisch bei jedem Fetch befüllt und bei Verbindungsproblemen
// als Fallback verwendet.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

actor CacheStore {

static let shared = CacheStore()

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()
private let baseURL: URL

// Zeitstempel letzter Sync je Entitättyp
private var syncTimestamps: [String: Date] = [:]

// In-Memory-Spiegel für schnellen Zugriff
private var faelleCache: [LegalCase] = []
private var aufgabenCache: [CaseTask] = []
private var fristenCache: [Deadline] = []
private var judgeProfileCache: [JudgeProfile] = []

private init() {
  let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
  baseURL = appSupport.appendingPathComponent("FenlynineOS/Cache", isDirectory: true)
  try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

  encoder.dateEncodingStrategy = .iso8601
  decoder.dateDecodingStrategy = .iso8601

  // Cache beim Start laden
  Task { await ladeAlles() }
}

// MARK: - Persitieren

private func dateipfad(fuer schluessel: String) -> URL {
  baseURL.appendingPathComponent("\(schluessel).json")
}

func speichern<T: Encodable>(_ entities: [T], schluessel: String) async {
  do {
    let data = try encoder.encode(entities)
    try data.write(to: dateipfad(fuer: schluessel), options: .atomic)
    syncTimestamps[schluessel] = Date()
  } catch { }
}

func laden<T: Decodable>(schluessel: String) async -> [T] {
  let pfad = dateipfad(fuer: schluessel)
  guard let data = try? Data(contentsOf: pfad) else { return [] }
  return (try? decoder.decode([T].self, from: data)) ?? []
}

// MARK: - Typ-sichere Accessor

func faelleSpeichern(_ faelle: [LegalCase]) async {
  faelleCache = faelle
  await speichern(faelle, schluessel: "faelle")
}

func faelleLaden() async -> [LegalCase] {
  if !faelleCache.isEmpty { return faelleCache }
  let cached: [LegalCase] = await laden(schluessel: "faelle")
  faelleCache = cached
  return cached
}

func aufgabenSpeichern(_ aufgaben: [CaseTask]) async {
  aufgabenCache = aufgaben
  await speichern(aufgaben, schluessel: "aufgaben")
}

func aufgabenLaden() async -> [CaseTask] {
  if !aufgabenCache.isEmpty { return aufgabenCache }
  let cached: [CaseTask] = await laden(schluessel: "aufgaben")
  aufgabenCache = cached
  return cached
}

func fristenSpeichern(_ fristen: [Deadline]) async {
  fristenCache = fristen
  await speichern(fristen, schluessel: "fristen")
}

func fristenLaden() async -> [Deadline] {
  if !fristenCache.isEmpty { return fristenCache }
  let cached: [Deadline] = await laden(schluessel: "fristen")
  fristenCache = cached
  return cached
}

func judgeProfileSpeichern(_ profile: [JudgeProfile]) async {
  judgeProfileCache = profile
 await speichern(profile, schluessel: "judgeProfiles")
}

func judgeProfileLaden() async -> [JudgeProfile] {
 if !judgeProfileCache.isEmpty { return judgeProfileCache }
 let cached: [JudgeProfile] = await laden(schluessel: "judgeProfiles")
 judgeProfileCache = cached
 return cached
}

// MARK: - Cache-Alter prüfen

func istVeraltet(schluessel: String, maxAlterMinuten: Int = 30) -> Bool {
 guard let letzterSync = syncTimestamps[schluessel] else { return true }
 return Date().timeIntervalSince(letzterSync) > Double(maxAlterMinuten * 60)
}

// MARK: - Alles löschen

func leeren() async {
 faelleCache = []
 aufgabenCache = []
 fristenCache = []
 judgeProfileCache = []
 syncTimestamps = [:]

 let keys = ["faelle", "aufgaben", "fristen", "judgeProfiles"]
 for key in keys {
   try? FileManager.default.removeItem(at: dateipfad(fuer: key))
 }
}

// MARK: - Alle beim Start laden

private func ladeAlles() async {
 faelleCache = await laden(schluessel: "faelle")
 aufgabenCache = await laden(schluessel: "aufgaben")
 fristenCache = await laden(schluessel: "fristen")
 judgeProfileCache = await laden(schluessel: "judgeProfiles")
}
}

// MARK: - Sync-Manager (Netzwerk-zuerst, Cache als Fallback)

@MainActor
final class SyncManager: ObservableObject {

static let shared = SyncManager()
private init() {}

@Published var istOnline = true
@Published var letzterSync: Date?
@Published var syncLaeuft = false

// Vollständiger Sync aller Entitäten
func vollSync() async {
 syncLaeuft = true
 defer { syncLaeuft = false }

 do {
   // Fälle
   let faelle = try await Services.cases.list()
   await CacheStore.shared.faelleSpeichern(faelle)

   // Aufgaben
   let aufgaben = try await Services.tasks.list()
   await CacheStore.shared.aufgabenSpeichern(aufgaben)

   // Fristen (alle aktiven)
   let fristen = try await Services.deadlines.list()
   await CacheStore.shared.fristenSpeichern(fristen)

   // Richterprofile
   let profile = try await Services.judgeProfiles.list()
   await CacheStore.shared.judgeProfileSpeichern(profile)

   letzterSync = Date()
   istOnline = true

   // Spotlight-Index aktualisieren
   NotificationService.shared.alleFaelleIndexieren(faelle: faelle)

   // Fristen-Alarme neu planen
   await NotificationService.shared.alleAlarmeNeuPlanen(fristen: fristen)

   // Badge aktualisieren
   let kritisch = fristen.filter { $0.istKritisch && $0.status == .offen }.count
   NotificationService.shared.badgeAktualisieren(kritischeFristen: kritisch)

 } catch {
   istOnline = false
 }
}

// Cached-Zuerst: lädt aus Cache, triggert Hintergrund-Sync
func faelleHolen() async -> [LegalCase] {
 let cached = await CacheStore.shared.faelleLaden()
 if !cached.isEmpty {
   Task { await vollSync() }
   return cached
 }
 // Kein Cache -> netzwerk
 do {
   let frisch = try await Services.cases.list()
   await CacheStore.shared.faelleSpeichern(frisch)
   return frisch
 } catch {
   return []
 }
}

// Sync-Status Anzeige
var syncStatusText: String {
 if syncLaeuft { return "Synchronisiere…" }
 if let ts = letzterSync {
   let minuten = Int(Date().timeIntervalSince(ts) / 60)
   if minuten < 1 { return "Gerade aktualisiert" }
   if minuten < 60 { return "Vor \(minuten) Min. aktualisiert" }
   return "Vor \(minuten / 60) Std. aktualisiert"
 }
 return istOnline ? "Nicht synchronisiert" : "Offline"
}

var syncStatusFarbe: String {
 if syncLaeuft { return "blue" }
 if !istOnline { return "orange" }
 if letzterSync == nil { return "gray" }
 return "green"
}
}

