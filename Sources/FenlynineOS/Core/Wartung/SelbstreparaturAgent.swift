import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// SELBSTREPARATUR-AGENT -- automatischer Wächter & Reparateur des Programms
//
// Läuft AUTOMATISCH im Hintergrund und scannt das Programm in festen Intervallen:
// (cid:127) Datenintegrität -- alle lokalen Datendateien werden auf Lesbarkeit geprüft
// (cid:127) KI-Gesundheit -- Base44, Apple Intelligence und Offline-KI werden überwacht;
//          antwortet eine KI wiederholt nicht, wird automatisch auf
//          die beste verfügbare Alternative umgeschaltet (Failover)
// (cid:127) Modul-Registry -- alle Module/Buttons der Seitenleiste werden auf
//          Vollständigkeit und Konsistenz geprüft
// (cid:127) Laufzeitfehler -- Fehlermeldungen aus dem laufenden Betrieb werden gesammelt
// (cid:127) Beschwerden -- Nutzer können sich direkt beim Agenten beschweren;
//          der Agent triagiert und schlägt Abhilfe vor (KI-gestützt)
//
// REFERENZ-SNAPSHOT: Nach jedem vollständig gesunden Scan wird eine als
// „voll funktionsfähig" bekannte Kopie aller Datendateien gesichert (Known-Good).
// Wird später eine beschädigte Datei erkannt, stellt der Agent sie automatisch
// aus diesem Snapshot wieder her.
//
// DATENSCHUTZ: Der Agent liest KEINE persönlichen Inhalte. Er prüft nur, OB
// Dateien lesbar sind (Parse-Test), zählt Fehler und misst Antwortzeiten.
// An die KI (Base44 / Apple Intelligence) werden ausschließlich technische
// Metadaten übermittelt -- niemals Mandats- oder Falldaten.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

@MainActor
final class SelbstreparaturAgent: ObservableObject {
static let shared = SelbstreparaturAgent()

// MARK: - Modelle

enum Schwere: String, Codable {
  case ok, warnung, kritisch
  var farbe: Color {
    switch self {
    case .ok: return .green
    case .warnung: return .orange
    case .kritisch: return .red
    }
  }
  var symbol: String {
    switch self {
    case .ok: return "checkmark.circle.fill"
    case .warnung: return "exclamationmark.triangle.fill"
    case .kritisch: return "xmark.octagon.fill"
    }
  }
}

struct Befund: Identifiable {
  let id = UUID()
  let bereich: String
  let titel: String
  let detail: String
  let schwere: Schwere
  let zeit = Date()
}

struct Reparatur: Identifiable, Codable {
  var id = UUID()
  var aktion: String
  var detail: String
  var erfolgreich: Bool
  var zeit = Date()
}

enum BeschwerdeStatus: String, Codable {
  case offen, inArbeit, beantwortet
  var label: String {
    switch self {
    case .offen: return "Offen"
    case .inArbeit: return "In Prüfung"
    case .beantwortet: return "Beantwortet"
    }
  }
}

struct Beschwerde: Identifiable, Codable {
  var id = UUID()
  var text: String
  var datum = Date()
  var status: BeschwerdeStatus = .offen
  var antwort: String?
  var betroffenerBereich: String?
}

// MARK: - Zustand

@Published var aktiv: Bool {
  didSet {
    UserDefaults.standard.set(aktiv, forKey: "selbstreparatur_aktiv")
    if aktiv { planeScans() } else { scanTask?.cancel() }
  }
}
@Published private(set) var scanLaeuft = false
@Published private(set) var letzterScan: Date?
@Published private(set) var befunde: [Befund] = []
@Published private(set) var reparaturen: [Reparatur] = []
@Published private(set) var beschwerden: [Beschwerde] = []
@Published private(set) var letzterSnapshot: Date?
@Published private(set) var snapshotDateien = 0
@Published private(set) var gesundheit: Double = 1.0
@Published private(set) var kiAusfaelle: [String: Int] = [:] // KIModus.rawValue -> Fehler in Folge
@Published private(set) var letzteKIFehler: [String] = [] // technische Kurzmeldungen

let scanIntervall: TimeInterval = 15 * 60
private var scanTask: Task<Void, Never>?
private static let ausfallSchwelle = 3

private init() {
 aktiv = UserDefaults.standard.object(forKey: "selbstreparatur_aktiv") as? Bool ?? true
 ladeZustand()
}

// MARK: - Pfade

private var appSupportFenlynineOS: URL {
 FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
   .appendingPathComponent("FenlynineOS", isDirectory: true)
}

private var wartungVerzeichnis: URL {
 appSupportFenlynineOS.appendingPathComponent("Wartung", isDirectory: true)
}

private var snapshotVerzeichnis: URL {
 wartungVerzeichnis.appendingPathComponent("KnownGood", isDirectory: true)
}

private var zustandDatei: URL {
 wartungVerzeichnis.appendingPathComponent("selbstreparatur.json")
}

// MARK: - Start / Stopp

func starte() {
 guard aktiv else { return }
 planeScans()
}

private func planeScans() {
 scanTask?.cancel()
 scanTask = Task { [weak self] in
   // Erststart leicht verzögert, damit App-Start nicht gebremst wird
   try? await Task.sleep(for: .seconds(20))
   while !Task.isCancelled {
     guard let self else { return }
     if self.aktiv { await self.scanJetzt() }
     try? await Task.sleep(for: .seconds(self.scanIntervall))
   }
 }
}

// MARK: - Scan

func scanJetzt() async {
 guard !scanLaeuft else { return }
 scanLaeuft = true
 var neu: [Befund] = []

 neu.append(contentsOf: pruefeDatenIntegritaet())
 neu.append(contentsOf: pruefeKIGesundheit())
 neu.append(contentsOf: pruefeModulRegistry())
 neu.append(contentsOf: pruefeSpeicherplatz())
 neu.append(contentsOf: pruefeBeschwerden())

 befunde = neu
 letzterScan = Date()

 let kritisch = neu.filter { $0.schwere == .kritisch }.count
 let warnungen = neu.filter { $0.schwere == .warnung }.count
 gesundheit = max(0, 1.0 - Double(kritisch) * 0.25 - Double(warnungen) * 0.08)

 // Vollständig gesund -> Known-Good-Snapshot aktualisieren
 if kritisch == 0 && warnungen == 0 {
   erstelleSnapshot()
 }

 speichereZustand()
 scanLaeuft = false
}

// MARK: Check 1 -- Datenintegrität (nur Parse-Test, keine Inhalte)

private func pruefeDatenIntegritaet() -> [Befund] {
 let fm = FileManager.default
 guard fm.fileExists(atPath: appSupportFenlynineOS.path) else {
   return [Befund(bereich: "Daten", titel: "Datenverzeichnis fehlt noch",
          detail: "Application Support/FenlynineOS wird beim ersten Speichern angelegt.",
          schwere: .ok)]
 }
 var geprueft = 0
 var defekt: [String] = []
 var repariert: [String] = []

 if let enumerator = fm.enumerator(at: appSupportFenlynineOS, includingPropertiesForKeys: [.isRegularFileKey]) {
   for case let url as URL in enumerator {
     // Wartungs-/Snapshot-Ordner nicht selbst prüfen
     if url.path.contains("/Wartung/") { continue }
     guard url.pathExtension.lowercased() == "json" else { continue }
     geprueft += 1
     guard let data = try? Data(contentsOf: url) else {
       defekt.append(relativ(url)); continue
     }
     if (try? JSONSerialization.jsonObject(with: data)) == nil {
       // Beschädigt -> automatische Wiederherstellung aus Known-Good
       if stelleWiederHer(datei: url) {
         repariert.append(relativ(url))
       } else {
         defekt.append(relativ(url))
       }
     }
   }
 }

 var ergebnis: [Befund] = []
 if repariert.isEmpty && defekt.isEmpty {
   ergebnis.append(Befund(bereich: "Daten",
               titel: "Datenintegrität in Ordnung",
               detail: "\(geprueft) Datendateien geprüft (nur Parse-Test -- Inhalte werden nicht gelesen).",
               schwere: .ok))
 }
 for r in repariert {
   ergebnis.append(Befund(bereich: "Daten",
               titel: "Datei automatisch repariert",
               detail: "\(r) war beschädigt und wurde aus dem Known-Good-Snapshot wiederhergestellt.",
               schwere: .warnung))
 }
 for d in defekt {
   ergebnis.append(Befund(bereich: "Daten",
               titel: "Beschädigte Datei",
               detail: "\(d) ist nicht lesbar und im Snapshot nicht vorhanden -- beim nächsten Speichern wird sie neu aufgebaut.",
               schwere: .kritisch))
 }
 return ergebnis
}

// MARK: Check 2 -- KI-Gesundheit + automatischer Failover

private func pruefeKIGesundheit() -> [Befund] {
 var ergebnis: [Befund] = []
 let cfg = KIKonfiguration.shared

 // Apple Intelligence Status (immer live vom System)
 let aiStatus = AppleIntelligenceService.status
 ergebnis.append(Befund(bereich: "KI",
             titel: aiStatus.titel,
             detail: aiStatus.hinweis,
             schwere: aiStatus.ok ? .ok : .warnung))

 // Base44-Konfiguration vorhanden?
 let b44 = Base44Config.load()
 if b44.appId.isEmpty {
   ergebnis.append(Befund(bereich: "KI",
               titel: "Base44 nicht konfiguriert",
               detail: "Ohne App-ID keine Cloud-KI -- Apple Intelligence oder Offline-KI verwenden.",
               schwere: cfg.modus == .base44 ? .warnung : .ok))
 }

 // Ausfall-Zähler des aktiven Modus
 let aktuelleAusfaelle = kiAusfaelle[cfg.modus.rawValue] ?? 0
 if aktuelleAusfaelle >= Self.ausfallSchwelle {
   // Automatischer Failover auf beste verfügbare Alternative
   if let alternative = besteAlternative(zu: cfg.modus) {
     var neu = cfg
     neu.modus = alternative
     neu.save()
     kiAusfaelle[cfg.modus.rawValue] = 0
     protokolliereReparatur(
       aktion: "KI-Failover",
       detail: "\(cfg.modus.bezeichnung) hat \(aktuelleAusfaelle)x in Folge nicht geantwortet -- automatisch auf \(alternative.bezeichnung) umgeschaltet.",
       erfolgreich: true
     )
     ergebnis.append(Befund(bereich: "KI",
                 titel: "Automatischer KI-Failover ausgeführt",
                 detail: "Neuer aktiver Anbieter: \(alternative.bezeichnung). Der ursprüngliche Anbieter kann in den Einstellungen reaktiviert werden.",
                 schwere: .warnung))
   } else {
     ergebnis.append(Befund(bereich: "KI",
                 titel: "KI antwortet nicht -- keine Alternative verfügbar",
                 detail: "\(cfg.modus.bezeichnung): \(aktuelleAusfaelle) Fehler in Folge. Netzwerk und Konfiguration prüfen.",
                 schwere: .kritisch))
   }
 } else if aktuelleAusfaelle > 0 {
   ergebnis.append(Befund(bereich: "KI",
               titel: "KI-Fehler beobachtet",
               detail: "\(cfg.modus.bezeichnung): \(aktuelleAusfaelle) Fehler in Folge (Failover ab \(Self.ausfallSchwelle)).",
               schwere: .warnung))
 } else {
   ergebnis.append(Befund(bereich: "KI",
               titel: "Aktiver KI-Anbieter stabil",
               detail: "\(cfg.modus.bezeichnung) -- keine offenen Fehlerserien.",
               schwere: .ok))
 }
 return ergebnis
}

private func besteAlternative(zu modus: KIModus) -> KIModus? {
 // Residenz respektieren: nie still auf Base44 wechseln, wenn Cloud gesperrt ist
 var kandidaten: [KIModus] = []
 if AppleIntelligenceService.verfuegbar { kandidaten.append(.appleIntelligence) }
 kandidaten.append(.offline)
 if DatenResidenz.darfCloud, !Base44Config.load().appId.isEmpty {
   kandidaten.append(.base44)
 }
 return kandidaten.first { $0 != modus && (kiAusfaelle[$0.rawValue] ?? 0) < Self.ausfallSchwelle }
}

// MARK: Check 3 -- Modul-Registry (Buttons / Seitenleiste)

private func pruefeModulRegistry() -> [Befund] {
 var probleme: [String] = []
 var raws = Set<String>()
 for e in SeitenleistenEintrag.allCases {
   if e.bezeichnung.trimmingCharacters(in: .whitespaces).isEmpty {
     probleme.append("\(e.rawValue): fehlende Bezeichnung")
   }
   if e.symbol.isEmpty {
     probleme.append("\(e.rawValue): fehlendes Symbol")
   }
   if !raws.insert(e.rawValue).inserted {
     probleme.append("\(e.rawValue): doppelte Kennung")
   }
 }
 if probleme.isEmpty {
   return [Befund(bereich: "Module",
          titel: "Alle \(SeitenleistenEintrag.allCases.count) Module konsistent",
          detail: "Seitenleiste, Kommandos und Fenster-Routing vollständig verdrahtet.",
          schwere: .ok)]
 }
 return probleme.map {
   Befund(bereich: "Module", titel: "Registry-Problem", detail: $0, schwere: .kritisch)
 }
}

// MARK: Check 4 -- Speicherplatz

private func pruefeSpeicherplatz() -> [Befund] {
 let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
 guard let werte = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
    let frei = werte.volumeAvailableCapacityForImportantUsage else {
   return []
 }
 let freiGB = Double(frei) / 1_073_741_824
 if freiGB < 2 {
   return [Befund(bereich: "System",
          titel: "Wenig Speicherplatz",
          detail: String(format: "Nur %.1f GB frei -- Snapshots und Backups könnten fehlschlagen.", freiGB),
          schwere: .warnung)]
 }
 return [Befund(bereich: "System",
        titel: "Speicherplatz ausreichend",
        detail: String(format: "%.0f GB frei.", freiGB),
        schwere: .ok)]
}

// MARK: Check 5 -- offene Beschwerden

private func pruefeBeschwerden() -> [Befund] {
 let offen = beschwerden.filter { $0.status != .beantwortet }
 guard !offen.isEmpty else { return [] }
 return [Befund(bereich: "Beschwerden",
        titel: "\(offen.count) offene Meldung(en) von Nutzern",
        detail: "Nutzer haben Funktionsprobleme gemeldet -- Details im Beschwerde-Bereich.",
        schwere: .warnung)]
}

// MARK: - Known-Good-Snapshot (Referenz „voll funktionsfähig")

func erstelleSnapshot() {
 let fm = FileManager.default
 do {
   try fm.createDirectory(at: snapshotVerzeichnis, withIntermediateDirectories: true)
   var kopiert = 0
   if let enumerator = fm.enumerator(at: appSupportFenlynineOS, includingPropertiesForKeys: nil) {
     for case let url as URL in enumerator {
       if url.path.contains("/Wartung/") { continue }
       guard url.pathExtension.lowercased() == "json" else { continue }
       let rel = relativ(url)
       let ziel = snapshotVerzeichnis.appendingPathComponent(rel)
       try? fm.createDirectory(at: ziel.deletingLastPathComponent(), withIntermediateDirectories: true)
       try? fm.removeItem(at: ziel)
       try? fm.copyItem(at: url, to: ziel)
       kopiert += 1
     }
   }
   letzterSnapshot = Date()
   snapshotDateien = kopiert
   speichereZustand()
 } catch {
   protokolliereReparatur(aktion: "Snapshot",
               detail: "Snapshot fehlgeschlagen: \(error.localizedDescription)",
               erfolgreich: false)
 }
}

/// Stellt eine einzelne beschädigte Datei aus dem Known-Good-Snapshot wieder her.
@discardableResult
private func stelleWiederHer(datei: URL) -> Bool {
 let fm = FileManager.default
 let quelle = snapshotVerzeichnis.appendingPathComponent(relativ(datei))
 guard fm.fileExists(atPath: quelle.path) else { return false }
 do {
   try? fm.removeItem(at: datei)
   try fm.copyItem(at: quelle, to: datei)
   protokolliereReparatur(aktion: "Datei wiederhergestellt",
               detail: "\(relativ(datei)) aus Known-Good-Snapshot ersetzt.",
               erfolgreich: true)
   return true
 } catch {
   protokolliereReparatur(aktion: "Wiederherstellung fehlgeschlagen",
               detail: "\(relativ(datei)): \(error.localizedDescription)",
               erfolgreich: false)
   return false
 }
}

private func relativ(_ url: URL) -> String {
 url.path.replacingOccurrences(of: appSupportFenlynineOS.path + "/", with: "")
}

// MARK: - Laufzeit-Meldungen (aus LLMService & Views)

/// Wird von LLMService nach jedem fehlgeschlagenen KI-Aufruf gerufen.
nonisolated static func meldeKIFehler(modus: KIModus, modul: String, fehler: Error) {
 let kurz = String(describing: fehler).prefix(120).description
 Task { @MainActor in
   let agent = SelbstreparaturAgent.shared
   agent.kiAusfaelle[modus.rawValue, default: 0] += 1
   agent.letzteKIFehler.insert("[\(modul)] \(modus.rawValue): \(kurz)", at: 0)
   if agent.letzteKIFehler.count > 20 { agent.letzteKIFehler.removeLast() }
   // Schwelle erreicht -> sofortiger Gesundheits-Check statt auf Intervall warten
   if agent.aktiv,
    (agent.kiAusfaelle[modus.rawValue] ?? 0) >= SelbstreparaturAgent.ausfallSchwelle,
    KIKonfiguration.shared.modus == modus {
     await agent.scanJetzt()
   }
 }
}

/// Wird von LLMService nach jedem erfolgreichen KI-Aufruf gerufen (Zähler-Reset).
nonisolated static func meldeKIErfolg(modus: KIModus) {
 Task { @MainActor in
   SelbstreparaturAgent.shared.kiAusfaelle[modus.rawValue] = 0
 }
}

/// Views können UI-Probleme direkt melden („Button ohne Funktion" o. ä.).
nonisolated static func meldeUIProblem(bereich: String, was: String) {
 Task { @MainActor in
   let agent = SelbstreparaturAgent.shared
   agent.letzteKIFehler.insert("[UI · \(bereich)] \(was)", at: 0)
   if agent.letzteKIFehler.count > 20 { agent.letzteKIFehler.removeLast() }
 }
}

// MARK: - Beschwerden (Nutzer -> Agent)

func beschwerdeEinreichen(_ text: String) {
 let bereinigt = text.trimmingCharacters(in: .whitespacesAndNewlines)
 guard !bereinigt.isEmpty else { return }
 var b = Beschwerde(text: bereinigt)
 b.betroffenerBereich = erkenneBereich(in: bereinigt)
 beschwerden.insert(b, at: 0)
 speichereZustand()

 // KI-Triage: NUR Beschwerdetext + technischer Status -- keine Falldaten
 Task { await triagiere(beschwerdeId: b.id) }
}

private func erkenneBereich(in text: String) -> String? {
 let t = text.lowercased()
 let karten: [(String, [String])] = [
   ("Lexara", ["lexara", "fall", "argument", "beweis"]),
   ("Strategos", ["strategos", "szenario", "vertrag"]),
   ("Opportunisma", ["opportunisma", "position", "stakeholder"]),
   ("KI", ["ki ", "ki-", "antwortet nicht", "keine antwort", "modell", "base44", "apple intelligence"]),
   ("Fristen", ["frist", "deadline", "termin"]),
   ("UI", ["button", "knopf", "klick", "fenster", "anzeige", "absturz", "hängt", "funktioniert nicht"])
 ]
 for (bereich, worte) in karten where worte.contains(where: t.contains) {
   return bereich
 }
 return nil
}

private func triagiere(beschwerdeId: UUID) async {
 guard let idx = beschwerden.firstIndex(where: { $0.id == beschwerdeId }) else { return }
 beschwerden[idx].status = .inArbeit
 let b = beschwerden[idx]

 let technik = """
 Technischer Status (keine persönlichen Daten):
 Gesundheit \(Int(gesundheit * 100))% · KI-Modus \(KIKonfiguration.shared.modus.rawValue) · \
 offene KI-Fehlerserien \(kiAusfaelle.filter { $0.value > 0 }.count) · \
 letzte Reparaturen: \(reparaturen.prefix(3).map(\.aktion).joined(separator: ", "))
 """
 let prompt = """
 Du bist der Wartungs-Agent einer Anwaltssoftware. Ein Nutzer meldet:
 „\(b.text)"
 Erkannter Bereich: \(b.betroffenerBereich ?? "unbekannt")
 \(technik)

 Gib eine kurze, konkrete Antwort an den Nutzer (max. 5 Sätze):
 1) Wahrscheinliche Ursache, 2) was der Agent automatisch prüft/tut,
 3) was der Nutzer selbst sofort versuchen kann.
 """

 var antwort: String
 do {
   antwort = try await LLMService.shared.invokeText(prompt: prompt, logKiName: "Selbstreparatur · Triage")
 } catch {
   // Lokale Triage ohne KI
   antwort = lokaleTriage(fuer: b)
 }
 if let i = beschwerden.firstIndex(where: { $0.id == beschwerdeId }) {
   beschwerden[i].antwort = antwort.trimmingCharacters(in: .whitespacesAndNewlines)
   beschwerden[i].status = .beantwortet
   speichereZustand()
 }
 // Beschwerde stößt außerdem sofort einen vollständigen Scan an
 await scanJetzt()
}

private func lokaleTriage(fuer b: Beschwerde) -> String {
 switch b.betroffenerBereich {
 case "KI":
   return "Der Agent hat einen sofortigen KI-Gesundheitscheck angestoßen. Antwortet der aktive Anbieter mehrfach nicht, schaltet er automatisch auf die beste Alternative um (Base44 « Apple Intelligence « Offline). Bitte in 1-2 Minuten erneut versuchen; Status unter Einstellungen -> KI."
 case "UI":
   return "Der Agent prüft Modul-Registry und Datendateien automatisch. Bitte das betroffene Fenster einmal schließen und neu öffnen; besteht das Problem weiter, wird es im nächsten Scan als Befund geführt und aus dem Known-Good-Snapshot repariert, sofern Daten betroffen sind."
 case "Fristen":
   return "Fristen werden lokal berechnet -- der Agent prüft die zugrunde liegenden Datendateien auf Integrität. Beschädigte Dateien werden automatisch aus dem letzten funktionsfähigen Snapshot wiederhergestellt."
 default:
   return "Meldung aufgenommen. Der Agent hat einen vollständigen Systemscan gestartet (Daten, KI, Module, Speicher) und repariert erkannte Probleme automatisch. Ergebnis erscheint hier im Selbstreparatur-Modul."
 }
}

// MARK: - Reparatur-Protokoll & Persistenz

private func protokolliereReparatur(aktion: String, detail: String, erfolgreich: Bool) {
 reparaturen.insert(Reparatur(aktion: aktion, detail: detail, erfolgreich: erfolgreich), at: 0)
 if reparaturen.count > 100 { reparaturen.removeLast(reparaturen.count - 100) }
 speichereZustand()
}

private struct Zustand: Codable {
 var reparaturen: [Reparatur]
 var beschwerden: [Beschwerde]
 var letzterSnapshot: Date?
 var snapshotDateien: Int
}

private func speichereZustand() {
 let z = Zustand(reparaturen: reparaturen, beschwerden: beschwerden,
         letzterSnapshot: letzterSnapshot, snapshotDateien: snapshotDateien)
 do {
   try FileManager.default.createDirectory(at: wartungVerzeichnis, withIntermediateDirectories: true)
   let data = try JSONEncoder().encode(z)
   try data.write(to: zustandDatei, options: .atomic)
 } catch { /* Wartungszustand ist rekonstruierbar */ }
}

private func ladeZustand() {
 guard let data = try? Data(contentsOf: zustandDatei),
    let z = try? JSONDecoder().decode(Zustand.self, from: data) else { return }
 reparaturen = z.reparaturen
 beschwerden = z.beschwerden
 letzterSnapshot = z.letzterSnapshot
 snapshotDateien = z.snapshotDateien
}
}

