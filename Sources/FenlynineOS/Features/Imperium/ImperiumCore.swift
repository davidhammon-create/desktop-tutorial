import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// IMPERIUM CORE -- Praxisprofil, Persistenz, Querschnitt
// Moat: lokale, fachrichtungsadaptive Kanzlei-OS-Schicht
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum ImperiumPraxisTyp: String, CaseIterable, Identifiable, Codable {
case allgemein
case wirtschaft
case strafrecht
case patent
case syndikus
case arbeitsrecht
case familienrecht
case insolvenz
case datenschutzIT
case ma

var id: String { rawValue }

var titel: String {
  switch self {
  case .allgemein: return "Allgemeine Praxis"
  case .wirtschaft: return "Wirtschafts- & Gesellschaftsrecht"
  case .strafrecht: return "Strafverteidigung"
  case .patent: return "Patent- & IP-Recht"
  case .syndikus: return "Syndikus / Inhouse"
  case .arbeitsrecht: return "Arbeitsrecht"
  case .familienrecht: return "Familienrecht"
  case .insolvenz: return "Insolvenz & Restrukturierung"
  case .datenschutzIT: return "Datenschutz & IT"
  case .ma: return "M&A / Transaktionen"
  }
}

var symbol: String {
  switch self {
  case .allgemein: return "building.columns"
  case .wirtschaft: return "building.2"
  case .strafrecht: return "hand.raised.fill"
  case .patent: return "lightbulb.fill"
  case .syndikus: return "briefcase.fill"
  case .arbeitsrecht: return "person.badge.clock"
  case .familienrecht: return "person.2.fill"
  case .insolvenz: return "chart.line.downtrend.xyaxis"
  case .datenschutzIT: return "lock.shield.fill"
  case .ma: return "arrow.left.arrow.right"
  }
}

var kurz: String {
  switch self {
  case .allgemein: return "Querschnitt · Mandate aller Art"
  case .wirtschaft: return "GmbH · Haftung · Verträge · Kartell"
  case .strafrecht: return "Akteneinsicht · Verteidigung · Haft"
  case .patent: return "Verletzung · Lizenz · EPÜ · DPMA"
  case .syndikus: return "Governance · Risiko · Board"
  case .arbeitsrecht: return "Kündigung · BetrVG · Vergütung"
  case .familienrecht: return "Scheidung · Unterhalt · Sorge"
  case .insolvenz: return "InsO · Anfechtung · Eigenverwaltung"
  case .datenschutzIT: return "DSGVO · TOMs · Vorfälle"
  case .ma: return "DD · SPA · Closing · W&I"
  }
}

/// Lexara-Rechtsgebiet-IDs, die in diesem Praxisprofil priorisiert werden
var priorisierteRechtsgebietIds: [String] {
  switch self {
  case .allgemein: return []
  case .wirtschaft: return ["gesellschaftsrecht", "handelsrecht", "kartellrecht", "compliance_owig"]
  case .strafrecht: return ["strafrecht", "wirtschaftsstrafrecht", "ordnungswidrigkeiten"]
  case .patent: return ["patentrecht", "markenrecht", "urheberrecht"]
  case .syndikus: return ["gesellschaftsrecht", "datenschutz", "compliance_owig", "arbeitsrecht"]
  case .arbeitsrecht: return ["arbeitsrecht", "tarifrecht", "sozialrecht"]
  case .familienrecht: return ["familienrecht", "erbrecht"]
  case .insolvenz: return ["insolvenzrecht", "gesellschaftsrecht", "handelsrecht"]
  case .datenschutzIT: return ["datenschutz", "urheberrecht", "markenrecht"]
  case .ma: return ["gesellschaftsrecht", "kartellrecht", "bank_kapitalmarkt"]
  }
}

var checklisten: [ImperiumChecklistenPunkt] {
  ImperiumPraxisPlaybooks.punkte(fuer: self)
}
}

struct ImperiumChecklistenPunkt: Identifiable, Codable, Hashable {
var id: String
var titel: String
var detail: String
var erledigt: Bool
var modulHinweis: String?
}

enum ImperiumPraxisPlaybooks {
static func punkte(fuer typ: ImperiumPraxisTyp) -> [ImperiumChecklistenPunkt] {
  switch typ {
 case .allgemein:
   return base([
     ("intake", "Mandatsannahme dokumentiert", "Vollmacht, Interessenkonflikt, Honorarvereinbarung"),
     ("akten", "Aktenzeichen & Ablage", "Physisch/digital konsistent"),
     ("frist", "Erste Fristen erfasst", "Zeitleiste / Kalender")
   ])
 case .wirtschaft:
   return base([
     ("hrb", "Registerauszug aktuell", "HRB / Gesellschafterliste"),
     ("vertrag", "Vertragsmatrix", "Hauptverträge + Nebenabreden"),
     ("haftung", "Haftungsachsen", "GF / Organ / D&O prüfen")
   ])
 case .strafrecht:
   return base([
     ("akte", "Akteneinsicht beantragt", "StPO · Vollständigkeit prüfen"),
     ("haft", "Haft-/Untersuchungshaft-Lage", "Fristen, Anträge"),
     ("verteidigung", "Verteidigungsstrategie", "Einlassung / Schweigen / Vergleich")
   ])
 case .patent:
   return base([
     ("anspruch", "Anspruchssatz analysiert", "Merkmalsanalyse"),
     ("stand", "Stand der Technik", "Rechercheprotokoll"),
     ("forum", "Forum & Zuständigkeit", "DPMA / EPA / LG")
   ])
 case .syndikus:
   return base([
     ("governance", "Freigabe-Pfad", "Legal -> Business -> Board"),
     ("risiko", "Risikoregister-Eintrag", "Impact x Likelihood"),
     ("extern", "External-Counsel-Brief", "Scope & Budget")
   ])
 case .arbeitsrecht:
   return base([
     ("kschg", "KSchG / Wartezeit", "Anwendbarkeit prüfen"),
     ("anhoerung", "Anhörung / Beteiligung", "Betriebsrat falls einschlägig"),
     ("fristklage", "Klagefrist 3 Wochen", "§ 4 KSchG")
   ])
 case .familienrecht:
   return base([
     ("unterlagen", "Einkommensunterlagen", "Beide Seiten"),
     ("sorge", "Sorgerecht / Umgang", "Kindeswohl-Fokus"),
     ("vermoegen", "Vermögensübersicht", "Zugewinn / Güterstand")
   ])
 case .insolvenz:
   return base([
     ("insolvenzreife", "Insolvenzreife prüfen", "Zahlungsunfähigkeit / Überschuldung"),
     ("antrag", "Antragsfrist Organe", "Haftungsrisiko GF"),
     ("masse", "Masse & Gläubiger", "Tabelle vorbereiten")
   ])
 case .datenschutzIT:
   return base([
     ("art33", "Meldepflicht geprüft", "72h Art. 33 DSGVO"),
     ("tom", "TOM-Status", "Technisch-organisatorische Maßnahmen"),
     ("avv", "AV-Verträge", "Auftragsverarbeiter")
   ])
 case .ma:
   return base([
     ("dd", "Due-Diligence-Plan", "Legal / Tax / Commercial"),
     ("spa", "SPA-Issues-List", "W&I, MAC, Earn-out"),
     ("closing", "Closing-Checklist", "Conditions precedent")
   ])
 }
}

private static func base(_ items: [(String, String, String)]) -> [ImperiumChecklistenPunkt] {
 items.map {
   ImperiumChecklistenPunkt(id: $0.0, titel: $0.1, detail: $0.2, erledigt: false, modulHinweis: nil)
 }
}
}

@MainActor
@Observable
final class ImperiumPraxisStore {
static let shared = ImperiumPraxisStore()

var aktiv: ImperiumPraxisTyp = .allgemein
var checklistenStand: [String: [ImperiumChecklistenPunkt]] = [:]
var kanzleiName: String = "Meine Kanzlei"
var schwerpunkte: [ImperiumPraxisTyp] = [.wirtschaft, .arbeitsrecht]

private let key = "imperium_praxis_v1"

private init() { laden() }

func laden() {
 guard let data = UserDefaults.standard.data(forKey: key),
    let snap = try? JSONDecoder().decode(Snap.self, from: data) else {
   for t in ImperiumPraxisTyp.allCases {
     checklistenStand[t.rawValue] = ImperiumPraxisPlaybooks.punkte(fuer: t)
   }
   return
 }
 aktiv = snap.aktiv
 checklistenStand = snap.checklistenStand
 kanzleiName = snap.kanzleiName
 schwerpunkte = snap.schwerpunkte
 for t in ImperiumPraxisTyp.allCases where checklistenStand[t.rawValue] == nil {
   checklistenStand[t.rawValue] = ImperiumPraxisPlaybooks.punkte(fuer: t)
 }
}

func speichern() {
 let snap = Snap(aktiv: aktiv, checklistenStand: checklistenStand, kanzleiName: kanzleiName, schwerpunkte: schwerpunkte)
 if let data = try? JSONEncoder().encode(snap) {
   UserDefaults.standard.set(data, forKey: key)
 }
}

func setzeAktiv(_ t: ImperiumPraxisTyp) {
 aktiv = t
 speichern()
}

func toggleCheck(typ: ImperiumPraxisTyp, id: String) {
 guard var list = checklistenStand[typ.rawValue],
    let i = list.firstIndex(where: { $0.id == id }) else { return }
 list[i].erledigt.toggle()
 checklistenStand[typ.rawValue] = list
 speichern()
}

func fortschritt(fuer typ: ImperiumPraxisTyp) -> Double {
 let list = checklistenStand[typ.rawValue] ?? []
 guard !list.isEmpty else { return 0 }
 return Double(list.filter(\.erledigt).count) / Double(list.count)
}

private struct Snap: Codable {
 var aktiv: ImperiumPraxisTyp
 var checklistenStand: [String: [ImperiumChecklistenPunkt]]
 var kanzleiName: String
 var schwerpunkte: [ImperiumPraxisTyp]
}
}

// MARK: - Persistenz-Helfer

enum ImperiumDisk {
static func load<T: Decodable>(_ key: String, as: T.Type) -> T? {
 guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
 return try? JSONDecoder().decode(T.self, from: data)
}

static func save<T: Encodable>(_ value: T, key: String) {
 if let data = try? JSONEncoder().encode(value) {
   UserDefaults.standard.set(data, forKey: key)
 }
}
}

