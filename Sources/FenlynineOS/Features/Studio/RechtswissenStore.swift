import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// RECHTSWISSEN -- modellwechsel-sicherer Wissensspeicher
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Persistiert unter Application Support/FenlynineOS/Rechtswissen/
// Unabhängig vom KI-Anbieter (Claude / Ollama / später Apple Intelligence).
// Export: JSON + Markdown-Korpus für RAG / Prompt-Kontext.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct RechtswissenEintrag: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var titel: String
var zusammenfassung: String
var norm: String? // z.B. "§ 4 KSchG"
var rechtsgebiet: String?
var quelle: String // URL, "BGH", "REWIS", "Agent", …
var tags: [String] = []
var confidence: Double = 0.6 // 0…1
var erfasstAm: Date = .init()
var aktualisiertAm: Date = .init()
var herkunftModell: String? // nur Metadaten -- Wissen selbst ist modellfrei
var rohtext: String? // optional längerer Extrakt
var rechtsordnung: String? // "de" | "ch" | "no" | "jp" | "cn" | nil = allgemein

var rechtsordnungWert: Rechtsordnung? {
  rechtsordnung.flatMap(Rechtsordnung.init(rawValue:))
}

/// Prompt-freundliche Kurzform (für jedes LLM / Apple Intelligence)
var kontextBlock: String {
  var z = ["### \(titel)"]
  if let ro = rechtsordnungWert { z.append("Rechtsordnung: \(ro.flagge) \(ro.name)") }
  if let n = norm { z.append("Norm: \(n)") }
  if let r = rechtsgebiet { z.append("Gebiet: \(r)") }
  z.append(zusammenfassung)
  if let roh = rohtext, !roh.isEmpty { z.append(roh) }
  z.append("Quelle: \(quelle) · Konfidenz: \(Int(confidence * 100)) %")
  return z.joined(separator: "\n")
}
}

@Observable
final class RechtswissenStore {
static let shared = RechtswissenStore()

private(set) var eintraege: [RechtswissenEintrag] = []
private(set) var letzteAktualisierung: Date?
private(set) var agentStatus: String = "bereit"

func setzeAgentStatus(_ s: String) {
  agentStatus = s
}

private let speicherURL: URL
private let korpusURL: URL
private let metaURL: URL
private var speicherTask: Task<Void, Never>?

private init() {
  let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("FenlynineOS/Rechtswissen", isDirectory: true)
  try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  speicherURL = root.appendingPathComponent("wissen.json")
  korpusURL = root.appendingPathComponent("korpus_apple_intelligence.md")
  metaURL = root.appendingPathComponent("meta.json")
  laden()
  if eintraege.isEmpty { seedBasis() }
}

// MARK: - CRUD

func fuegeHinzu(_ e: RechtswissenEintrag) {
  // Deduplizierung über Norm + Titel
  if let idx = eintraege.firstIndex(where: {
    ($0.norm != nil && $0.norm == e.norm) || $0.titel.caseInsensitiveCompare(e.titel) == .orderedSame
  }) {
    var alt = eintraege[idx]
    alt.zusammenfassung = e.zusammenfassung
    alt.aktualisiertAm = .init()
    alt.confidence = max(alt.confidence, e.confidence)
    alt.quelle = e.quelle
    alt.herkunftModell = e.herkunftModell
    if let roh = e.rohtext { alt.rohtext = roh }
    if let ro = e.rechtsordnung { alt.rechtsordnung = ro }
    eintraege[idx] = alt
  } else {
    eintraege.insert(e, at: 0)
  }
  letzteAktualisierung = .init()
  scheduleSpeichern()
}

func suche(_ q: String) -> [RechtswissenEintrag] {
  let s = q.lowercased()
  guard !s.isEmpty else { return eintraege }
  return eintraege.filter {
    $0.titel.lowercased().contains(s)
      || $0.zusammenfassung.lowercased().contains(s)
     || ($0.norm?.lowercased().contains(s) ?? false)
     || $0.tags.contains { $0.lowercased().contains(s) }
 }
}

/// Kontext für JEDES Modell -- inkl. später Apple Intelligence
/// Priorisiert Einträge der aktiven Rechtsordnungen, ergänzt allgemeines Wissen.
func kontextFuerPrompt(limit: Int = 12, query: String? = nil) -> String {
 let pool = query.map { suche($0) } ?? eintraege
 let aktiv = Set(Rechtsordnung.aktiveAusDefaults.map(\.rawValue))
 let passend = pool.filter { $0.rechtsordnung == nil || aktiv.contains($0.rechtsordnung ?? "") }
 let top = Array(passend.prefix(limit))
 guard !top.isEmpty else { return "" }
 return """
 \(Rechtsordnung.promptKopf)

 # FenlynineOS Rechtswissen (lokal, modellunabhängig)
 Folgende Einträge stammen aus dem persistenten Rechtsradar und dem Rechtsdaten-Ordner.
 Bei Modellwechsel (Claude -> Ollama -> Apple Intelligence) bleiben sie erhalten.

 \(top.map(\.kontextBlock).joined(separator: "\n\n"))
 """
}

/// Export-Pfad für externe Tools / Apple Intelligence Import
var exportPfad: URL { korpusURL }

// MARK: - Persistenz

private func scheduleSpeichern() {
 speicherTask?.cancel()
 speicherTask = Task { [weak self] in
   try? await Task.sleep(for: .milliseconds(400))
   guard !Task.isCancelled else { return }
   await MainActor.run { self?.speichern() }
 }
}

private func speichern() {
 do {
   let enc = JSONEncoder()
   enc.outputFormatting = [.prettyPrinted, .sortedKeys]
   enc.dateEncodingStrategy = .iso8601
   try enc.encode(eintraege).write(to: speicherURL, options: .atomic)

   let korpus = """
   # FenlynineOS Rechtswissen-Korpus
   Generiert: \(ISO8601DateFormatter().string(from: Date()))
   Einträge: \(eintraege.count)
   Zweck: Persistentes Rechtswissen für beliebige KI-Modelle inkl. Apple Intelligence.

   \(eintraege.map(\.kontextBlock).joined(separator: "\n\n---\n\n"))
   """
   try korpus.data(using: .utf8)?.write(to: korpusURL, options: .atomic)

   let meta: [String: String] = [
     "count": "\(eintraege.count)",
     "updated": ISO8601DateFormatter().string(from: Date()),
     "format": "fenlynineos-rechtswissen-v1"
   ]
   try JSONEncoder().encode(meta).write(to: metaURL, options: .atomic)
   agentStatus = "gespeichert"
 } catch {
   agentStatus = "Speicherfehler: \(error.localizedDescription)"
 }
}

private func laden() {
 guard let data = try? Data(contentsOf: speicherURL) else { return }
 let dec = JSONDecoder()
 dec.dateDecodingStrategy = .iso8601
 eintraege = (try? dec.decode([RechtswissenEintrag].self, from: data)) ?? []
 letzteAktualisierung = .init()
}

private func seedBasis() {
 let basis: [RechtswissenEintrag] = [
   .init(titel: "Klagefrist Kündigungsschutz",
      zusammenfassung: "Die Klage muss innerhalb von drei Wochen nach Zugang der schriftlichen Kündigung erhoben werden.",
      norm: "§ 4 S. 1 KSchG", rechtsgebiet: "Arbeitsrecht", quelle: "Seed · Gesetz",
      tags: ["frist", "kündigung"], confidence: 1.0),
   .init(titel: "Regelverjährung",
      zusammenfassung: "Die regelmäßige Verjährungsfrist beträgt drei Jahre.",
      norm: "§ 195 BGB", rechtsgebiet: "Zivilrecht", quelle: "Seed · Gesetz",
      tags: ["verjährung"], confidence: 1.0),
   .init(titel: "Aufnahme nichtöffentlichen Wortes",
      zusammenfassung: "Unbefugte Aufnahme des nichtöffentlich gesprochenen Wortes ist strafbar. Advocatus darf kein Mikrofon haben.",
      norm: "§ 201 StGB", rechtsgebiet: "Strafrecht", quelle: "Seed · Gesetz",
      tags: ["advocatus", "datenschutz"], confidence: 1.0),
   .init(titel: "Technische Überwachungseinrichtung",
      zusammenfassung: "Mitbestimmungspflicht bei technischen Einrichtungen zur Verhaltens-/Leistungsüberwachung. Organon-Personenebene gesperrt bis Betriebsvereinbarung.",
      norm: "§ 87 Abs. 1 Nr. 6 BetrVG", rechtsgebiet: "Arbeitsrecht", quelle: "Seed · Gesetz",
      tags: ["organon", "betriebsrat"], confidence: 1.0),
   .init(titel: "Automatisierte Einzelentscheidung",
      zusammenfassung: "Recht auf menschliche Intervention und Erläuterung der Entscheidungslogik. Entscheidung nur durch Mensch; Bewertung nur durch Formel.",
      norm: "Art. 22 DSGVO", rechtsgebiet: "Datenschutz", quelle: "Seed · DSGVO",
      tags: ["ki", "haftung"], confidence: 1.0)
 ]
 eintraege = basis
 speichern()
}
}

// MARK: - Rechtsradar-Agent (stetige Suche / Aufnahme)

@Observable
@MainActor
final class RechtsradarAgent {
static let shared = RechtsradarAgent()

private var task: Task<Void, Never>?
private(set) var laeuft = false
var intervallSekunden: Double = 180

func starten() {
 guard task == nil else { return }
 laeuft = true
 RechtswissenStore.shared.setzeAgentStatus("Radar aktiv")
 task = Task { [weak self] in
   while let self, !Task.isCancelled {
     await self.zyklus()
     try? await Task.sleep(for: .seconds(self.intervallSekunden))
   }
 }
}

func stoppen() {
 task?.cancel()
 task = nil
 laeuft = false
 RechtswissenStore.shared.setzeAgentStatus("Radar pausiert")
}

func zyklus() async {
 let store = RechtswissenStore.shared
 let aktive = RechtsordnungManager.shared.aktiveSortiert
 store.setzeAgentStatus("sucht … (\(aktive.map(\.flagge).joined()))")

 // 1) Fristen aus laufenden Vorgängen sichern
 for v in VorgangStore.shared.vorgaenge {
   for f in v.fristen where !f.quelle.isEmpty {
     store.fuegeHinzu(.init(
       titel: f.art,
       zusammenfassung: "Frist aus Vorgang \(v.kurzId): \(f.art). Quelle: \(f.quelle).",
       norm: f.quelle.contains("§") ? f.quelle : nil,
       rechtsgebiet: v.rechtsgebiet.isEmpty ? nil : v.rechtsgebiet,
       quelle: "Vorgang \(v.kurzId)",
       tags: ["frist", v.typ.rawValue],
       confidence: 0.9,
       herkunftModell: nil
     ))
   }
 }

 // 2) Rechtsdaten-Ordner: neue lokale Dateien importieren
 RechtsdatenOrdner.shared.importiere()

 // 3) Kern-Wissen + Fristen-Pakete + Funktions-Union je aktiver Rechtsordnung
 for r in aktive { seedeRechtsordnung(r) }
 seedeFunktionsUnion()

 // 4) KI-Erweiterung je aktiver Rechtsordnung
 for r in aktive { await kiErweiterung(fuer: r) }

 // 5) Radar-Funde in den Ordner spiegeln (auch außerhalb der App nutzbar)
 RechtsdatenOrdner.shared.exportiereRadarFunde()

 // 6) PowerOS-Datenbank: ständige Sammlung persistieren (SQLite + Spiegel)
 PowerOSDatenbank.shared.synchronisiere()
 PowerOSDatenbank.shared.protokolliere(
   aktion: "Radar-Zyklus",
   details: "\(store.eintraege.count) Einträge · Rechtsordnungen: \(aktive.map(\.name).joined(separator: ", ")) · KI: \(KIKonfiguration.shared.modus.rawValue)"
 )

 store.setzeAgentStatus("aktualisiert · \(store.eintraege.count) Einträge · \(aktive.map(\.flagge).joined())")
}

/// Kuratiertes Kernwissen + Kernfristen einer Rechtsordnung in den Radar legen.
private func seedeRechtsordnung(_ r: Rechtsordnung) {
 let store = RechtswissenStore.shared
 for impuls in r.radarImpulse {
   store.fuegeHinzu(.init(
     titel: impuls.titel,
     zusammenfassung: impuls.text,
     norm: impuls.norm,
     rechtsgebiet: nil,
     quelle: "Radar · \(r.name)",
     tags: ["radar", r.rawValue],
     confidence: 0.9,
     rechtsordnung: r.rawValue
   ))
 }
 for frist in r.fristenPakete {
   store.fuegeHinzu(.init(
     titel: "\(frist.titel) (\(r.name))",
     zusammenfassung: frist.beschreibung + (frist.tage.map { " · ~\($0) Tage" } ?? ""),
     norm: frist.norm,
     rechtsgebiet: "Fristen",
     quelle: "Radar · Fristenpaket \(r.name)",
     tags: ["frist", r.rawValue],
     confidence: 0.95,
     rechtsordnung: r.rawValue
   ))
 }
 let geb = r.gebuehrenModell
 store.fuegeHinzu(.init(
   titel: "\(geb.titel) (\(r.name))",
   zusammenfassung: geb.beschreibung,
   norm: geb.norm,
   rechtsgebiet: "Vergütung",
   quelle: "Radar · Gebührenmodell \(r.name)",
   tags: ["gebühren", r.rawValue],
   confidence: 0.9,
   rechtsordnung: r.rawValue
 ))
}

/// Funktions-Union: Werkzeuge aus einer Rechtsordnung stehen überall bereit.
private func seedeFunktionsUnion() {
 for paket in Rechtsordnung.funktionsUnion {
   RechtswissenStore.shared.fuegeHinzu(.init(
     titel: "Werkzeug: \(paket.funktion)",
     zusammenfassung: "\(paket.beschreibung) Übertragbarkeit: \(paket.uebertragbar)",
     norm: nil,
     rechtsgebiet: "Funktions-Union",
     quelle: "Union · Ursprung \(paket.ursprung.flagge) \(paket.ursprung.name)",
     tags: ["union", paket.ursprung.rawValue],
     confidence: 0.9
   ))
 }
}

private func kiErweiterung(fuer r: Rechtsordnung) async {
 do {
   let prompt = """
   Rechtsordnung: \(r.name). \(r.kiSprachHinweis)
   Amtliche Quellen: \(r.amtlicheQuellen.joined(separator: ", ")).
   Nenne KURZ 2 aktuelle oder grundlegende Rechtsinformationen dieser Rechtsordnung \
   (Norm + 1 Satz auf Deutsch), relevant für Anwaltssoftware \
   (Arbeitsrecht, Zivilprozess, Datenschutz, Fristen). \
   Format je Zeile: NORM|TITEL|SATZ
   Keine Einleitung.
   """
   let antwort = try await LLMService.shared.invokeText(prompt: prompt, webContext: false)
   for zeile in antwort.split(separator: "\n") where zeile.contains("|") {
     let teile = zeile.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
     guard teile.count >= 3 else { continue }
     RechtswissenStore.shared.fuegeHinzu(.init(
       titel: teile[1],
       zusammenfassung: teile[2],
       norm: teile[0],
       rechtsgebiet: nil,
       quelle: "Radar · KI · \(r.name)",
       tags: ["radar", "ki", r.rawValue],
       confidence: 0.55,
       herkunftModell: "aktuelles-modell",
       rechtsordnung: r.rawValue
     ))
   }
 } catch {
   // Offline / kein Key -- kuratiertes Wissen reicht
 }
}
}

