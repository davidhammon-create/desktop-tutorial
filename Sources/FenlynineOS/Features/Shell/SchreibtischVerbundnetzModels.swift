import Foundation
import SwiftUI

// MARK: - Verbundnetz (Schreibtisch-Sonderfunktion -- additiv, ohne bestehende Module)

enum VerbundNetzKnotenTyp: String, Codable, CaseIterable {
case ausgangslage, analyse, dokument, aussage, vorlage, arbeitsschritt
case taktik, verhandlung, gericht, ziel

var bezeichnung: String {
  switch self {
  case .ausgangslage: return "Ausgangslage"
  case .analyse: return "Analyse"
  case .dokument: return "Dokument"
  case .aussage: return "Aussage"
  case .vorlage: return "Vorlage"
  case .arbeitsschritt: return "Arbeitsschritt"
  case .taktik: return "Taktik"
  case .verhandlung: return "Verhandlung"
  case .gericht: return "Gericht"
  case .ziel: return "Ziel"
  }
}

var symbol: String {
  switch self {
  case .ausgangslage: return "flag.fill"
  case .analyse: return "magnifyingglass"
  case .dokument: return "doc.text.fill"
  case .aussage: return "quote.bubble.fill"
  case .vorlage: return "doc.on.doc.fill"
  case .arbeitsschritt: return "arrow.right.circle.fill"
  case .taktik: return "scope"
  case .verhandlung: return "person.2.wave.2.fill"
  case .gericht: return "building.columns.fill"
  case .ziel: return "target"
  }
}

var farbe: Color {
  switch self {
  case .ausgangslage: return .gray
  case .analyse: return FenlynineOSTheme.accent
  case .dokument: return .blue
  case .aussage: return .purple
  case .vorlage: return .teal
  case .arbeitsschritt: return .orange
  case .taktik: return FenlynineOSTheme.warning
  case .verhandlung: return FenlynineOSTheme.danger
  case .gericht: return Color(red: 0.45, green: 0.62, blue: 0.95)
  case .ziel: return FenlynineOSTheme.success
  }
}
}

enum VerbundNetzKantenTyp: String, Codable, CaseIterable {
case fuehrt_zu, vorlage_fuer, knuepft_an, reaktion_auf, verzweigung

var bezeichnung: String {
  switch self {
  case .fuehrt_zu: return "führt zu"
  case .vorlage_fuer: return "Vorlage für"
  case .knuepft_an: return "knüpft an"
  case .reaktion_auf: return "Reaktion auf"
  case .verzweigung: return "Verzweigung"
  }
}

var farbe: Color {
  switch self {
  case .fuehrt_zu: return FenlynineOSTheme.accent.opacity(0.6)
  case .vorlage_fuer: return .teal.opacity(0.7)
  case .knuepft_an: return .purple.opacity(0.6)
  case .reaktion_auf: return FenlynineOSTheme.danger.opacity(0.75)
  case .verzweigung: return FenlynineOSTheme.warning.opacity(0.65)
  }
}
}

enum VerbundNetzSchrittStatus: String, Codable {
case wartend, aktiv, erledigt, blockiert

var bezeichnung: String {
  switch self {
  case .wartend: return "Wartend"
  case .aktiv: return "Aktiv"
  case .erledigt: return "Erledigt"
  case .blockiert: return "Blockiert"
  }
}
}

enum VerbundNetzPhase: String, CaseIterable, Codable {
case planung, umsetzung, verhandlung, gericht

var bezeichnung: String {
  switch self {
  case .planung: return "Planung"
  case .umsetzung: return "Umsetzung"
 case .verhandlung: return "Verhandlung"
 case .gericht: return "Gericht"
 }
}
}

struct VerbundNetzKnoten: Identifiable, Codable, Hashable {
var id: String
var titel: String
var typ: VerbundNetzKnotenTyp
var beschreibung: String
var modul: SchreibtischModul
var modulAktion: String
var tiefe: Int
var status: VerbundNetzSchrittStatus
var automatisiert: Bool
var kausalTrigger: String?

static func basis(id: String, titel: String) -> VerbundNetzKnoten {
 VerbundNetzKnoten(
   id: id,
   titel: titel,
   typ: .ausgangslage,
   beschreibung: "Ausgangspunkt des Verbundnetzes",
   modul: .lagebild,
   modulAktion: "Lage erfassen",
   tiefe: 0,
   status: .erledigt,
   automatisiert: false,
   kausalTrigger: nil
 )
}
}

struct VerbundNetzKante: Identifiable, Codable, Hashable {
var id: String
var vonId: String
var zuId: String
var typ: VerbundNetzKantenTyp
var kausalitaet: String
}

struct VerbundNetzSnapshot: Codable {
var basisSituation: String
var ziel: String
var knoten: [VerbundNetzKnoten]
var kanten: [VerbundNetzKante]
var phase: VerbundNetzPhase
var letzteAnalyse: String?
}

// MARK: - Radiales Spinnennetz-Layout

enum VerbundNetzLayout {
static let knotenRadius: CGFloat = 34

static func positionen(knoten: [VerbundNetzKnoten], in groesse: CGSize) -> [String: CGPoint] {
 guard !knoten.isEmpty else { return [:] }
 let cx = groesse.width / 2
 let cy = groesse.height / 2
 let basisRadius = min(groesse.width, groesse.height) * 0.14
 let ringAbstand = min(groesse.width, groesse.height) * 0.11

 var byDepth: [Int: [VerbundNetzKnoten]] = [:]
 for k in knoten { byDepth[k.tiefe, default: []].append(k) }
 for d in byDepth.keys { byDepth[d]?.sort { $0.titel < $1.titel } }

 var result: [String: CGPoint] = [:]
 for (tiefe, gruppe) in byDepth {
   let n = max(gruppe.count, 1)
   let radius = tiefe == 0 ? 0 : basisRadius + CGFloat(tiefe) * ringAbstand
   for (i, k) in gruppe.enumerated() {
     if tiefe == 0 {
       result[k.id] = CGPoint(x: cx, y: cy)
     } else {
       let winkel = (Double(i) / Double(n)) * 2 * .pi - .pi / 2
       result[k.id] = CGPoint(
         x: cx + radius * CGFloat(cos(winkel)),
         y: cy + radius * CGFloat(sin(winkel))
       )
     }
   }
 }
 return result
}
}

// MARK: - Zentraler Store (verbunden mit Schreibtisch-Fenstern)

@Observable
final class SchreibtischVerbundnetzStore {
static let shared = SchreibtischVerbundnetzStore()

var basisSituation = ""
var ziel = ""
var knoten: [VerbundNetzKnoten] = []
var kanten: [VerbundNetzKante] = []
var ausgewaehlterId: String?
var phase: VerbundNetzPhase = .planung
var verhandlungsSituation = ""
var laedt = false
var fehler: String?
var letzteAnalyse: String?
var automatisierungLaeuft = false

private let persistKey = "schreibtisch_verbundnetz_v1"

init() { laden() }

var ausgewaehlterKnoten: VerbundNetzKnoten? {
 guard let id = ausgewaehlterId else { return nil }
 return knoten.first { $0.id == id }
}

var aktiveKnoten: [VerbundNetzKnoten] {
 knoten.filter { $0.status == .aktiv }
}

var fortschritt: Double {
 guard !knoten.isEmpty else { return 0 }
 let erledigt = knoten.filter { $0.status == .erledigt }.count
 return Double(erledigt) / Double(knoten.count)
}

var hatNetz: Bool { !knoten.isEmpty }

// MARK: - Algorithmische Automatisierung

func initialisiereArbeitskette() {
 guard !knoten.isEmpty else { return }
 for i in knoten.indices {
   if knoten[i].tiefe == 0 {
     knoten[i].status = .erledigt
   } else {
     knoten[i].status = .wartend
   }
 }
 for k in knoten where k.tiefe == 1 {
   aktiviere(k.id)
 }
 phase = .planung
 speichern()
}

func naechsterSchrittAusfuehren() -> VerbundNetzKnoten? {
 guard let aktiv = aktiveKnoten.sorted(by: { $0.tiefe < $1.tiefe }).first else { return nil }
 markiereErledigt(aktiv.id)
 aktualisierePhase()
 speichern()
 return aktiv
}

func automatisiereBereiteSchritte() -> [VerbundNetzKnoten] {
 var ausgefuehrt: [VerbundNetzKnoten] = []
 automatisierungLaeuft = true
 defer { automatisierungLaeuft = false }

 while let naechster = aktiveKnoten.sorted(by: { $0.tiefe < $1.tiefe }).first(where: { $0.automatisiert }) {
   markiereErledigt(naechster.id)
   ausgefuehrt.append(naechster)
 }
 aktualisierePhase()
 speichern()
 return ausgefuehrt
}

func markiereErledigt(_ id: String) {
 guard let idx = knoten.firstIndex(where: { $0.id == id }) else { return }
 knoten[idx].status = .erledigt
 aktiviereAbhaengige(von: id)
}

func aktiviere(_ id: String) {
 guard let idx = knoten.firstIndex(where: { $0.id == id }) else { return }
 if alleElternErledigt(id) {
   knoten[idx].status = .aktiv
 }
}

func aktiviereAbhaengige(von id: String) {
 let kinder = kanten.filter { $0.vonId == id }.map(\.zuId)
 for kindId in kinder { aktiviere(kindId) }
}

func alleElternErledigt(_ id: String) -> Bool {
 let eltern = kanten.filter { $0.zuId == id }.map(\.vonId)
 if eltern.isEmpty { return true }
 return eltern.allSatisfy { elternId in
   knoten.first(where: { $0.id == elternId })?.status == .erledigt
 }
}

func aktualisierePhase() {
 if knoten.contains(where: { $0.typ == .gericht && $0.status == .aktiv }) {
   phase = .gericht
 } else if knoten.contains(where: { $0.typ == .verhandlung && $0.status == .aktiv }) {
   phase = .verhandlung
 } else if knoten.contains(where: { $0.status == .aktiv && $0.tiefe > 1 }) {
   phase = .umsetzung
 } else {
   phase = .planung
 }
}

func uebernehmeNetz(knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], analyse: String?) {
 self.knoten = knoten
 self.kanten = kanten
 self.letzteAnalyse = analyse
 self.fehler = nil
 initialisiereArbeitskette()
 ausgewaehlterId = knoten.first(where: { $0.tiefe == 1 })?.id ?? knoten.first?.id
}

func fuegeTaktikAnpassungHinzu(knoten neuKnoten: [VerbundNetzKnoten], kanten neuKanten: [VerbundNetzKante]) {
 var ids = Set(knoten.map(\.id))
 for k in neuKnoten where !ids.contains(k.id) {
   knoten.append(k)
   ids.insert(k.id)
 }
 var kantenIds = Set(kanten.map(\.id))
 for k in neuKanten where !kantenIds.contains(k.id) {
   kanten.append(k)
   kantenIds.insert(k.id)
 }
 for k in neuKnoten where k.status == .aktiv { aktiviere(k.id) }
 aktualisierePhase()
 speichern()
}

func zuruecksetzen() {
 knoten = []
 kanten = []
 ausgewaehlterId = nil
 phase = .planung
 verhandlungsSituation = ""
 letzteAnalyse = nil
 fehler = nil
 speichern()
}

// MARK: - Persistenz

func speichern() {
 let snap = VerbundNetzSnapshot(
   basisSituation: basisSituation,
   ziel: ziel,
   knoten: knoten,
   kanten: kanten,
   phase: phase,
   letzteAnalyse: letzteAnalyse
 )
 if let data = try? JSONEncoder().encode(snap) {
   UserDefaults.standard.set(data, forKey: persistKey)
 }
}

private func laden() {
 guard let data = UserDefaults.standard.data(forKey: persistKey),
    let snap = try? JSONDecoder().decode(VerbundNetzSnapshot.self, from: data) else { return }
 basisSituation = snap.basisSituation
 ziel = snap.ziel
 knoten = snap.knoten
 kanten = snap.kanten
 phase = snap.phase
 letzteAnalyse = snap.letzteAnalyse
}
}

