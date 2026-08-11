import Foundation
import SwiftUI
import CoreGraphics
import AppKit

// MARK: - Organon Datenmodell (operatives Organisationsnetz)

enum OrganonKnotenTyp: String, Codable, CaseIterable {
case gesellschaft, bereich, team, person

var symbol: String {
  switch self {
  case .gesellschaft: return "building.2.fill"
  case .bereich: return "building.columns.fill"
  case .team: return "person.3.fill"
  case .person: return "person.circle.fill"
  }
}

var bezeichnung: String {
  switch self {
  case .gesellschaft: return "Gesellschaft"
  case .bereich: return "Abteilung / Dezernat"
  case .team: return "Team"
  case .person: return "Person"
  }
}

/// Kurzlabel für UI-Chips (ohne „/").
var kurz: String {
  switch self {
  case .gesellschaft: return "Gesellschaft"
  case .bereich: return "Abteilung"
  case .team: return "Team"
  case .person: return "Person"
  }
}

/// Organisationseinheit (Struktur) vs. natürliche Person.
var istOrganisationseinheit: Bool {
  self != .person
}

var istPerson: Bool { self == .person }

/// Erlaubte Eltern-Typen in der disziplinarischen Hierarchie.
var erlaubteElternTypen: [OrganonKnotenTyp] {
  switch self {
  case .gesellschaft: return []
  case .bereich: return [.gesellschaft]
  case .team: return [.bereich]
  case .person: return [.team, .bereich] // Partner oft direkt unter Abteilung
  }
}

var hierarchieEbene: Int {
  switch self {
  case .gesellschaft: return 0
  case .bereich: return 1
  case .team: return 2
  case .person: return 3
  }
}

var farbe: Color {
  switch self {
  case .gesellschaft: return Color(red: 0.2, green: 0.35, blue: 0.55)
  case .bereich: return Color(red: 0.25, green: 0.45, blue: 0.7)
  case .team: return Color(red: 0.35, green: 0.55, blue: 0.45)
  case .person: return FenlynineOSTheme.accent
  }
}
}

enum OrganonKantenTyp: String, Codable, CaseIterable {
case disziplinarisch, fachlich, projekt, vertretung, mandat

var bezeichnung: String {
  switch self {
  case .disziplinarisch: return "Berichtslinie"
  case .fachlich: return "Fachliche Linie"
  case .projekt: return "Projekt"
  case .vertretung: return "Vertretung"
  case .mandat: return "Mandat"
  }
}

var farbe: Color {
  switch self {
  case .disziplinarisch: return .secondary
  case .fachlich: return .purple.opacity(0.7)
  case .projekt: return .orange
  case .vertretung: return .teal
  case .mandat: return FenlynineOSTheme.accent
  }
}
}

enum OrganonKapazitaet: String, Codable, CaseIterable {
case verfuegbar, ausgelastet, abwesend

var bezeichnung: String {
 switch self {
 case .verfuegbar: return "Verfügbar"
 case .ausgelastet: return "Ausgelastet"
 case .abwesend: return "Abwesend"
 }
}
var farbe: Color {
 switch self {
 case .verfuegbar: return .green
 case .ausgelastet: return .orange
 case .abwesend: return .gray
 }
}
}

enum OrganonSkillLevel: Int, Codable, CaseIterable, Comparable {
case kenner = 1, praxis = 2, experte = 3, lead = 4

var bezeichnung: String {
 switch self {
 case .kenner: return "Kenner"
 case .praxis: return "Praxis"
 case .experte: return "Experte"
 case .lead: return "Lead"
 }
}

static func < (lhs: OrganonSkillLevel, rhs: OrganonSkillLevel) -> Bool {
 lhs.rawValue < rhs.rawValue
}
}

struct OrganonSkill: Identifiable, Hashable, Codable {
var id: String
var name: String
var level: OrganonSkillLevel

init(id: String = UUID().uuidString, name: String, level: OrganonSkillLevel = .praxis) {
 self.id = id
 self.name = name
 self.level = level
}
}

enum OrganonZoomStufe: Int, CaseIterable {
case konzern = 1, bereich = 2, team = 3, person = 4

var bezeichnung: String {
 switch self {
 case .konzern: return "Kanzlei"
 case .bereich: return "Abteilungen"
 case .team: return "Teams"
 case .person: return "Personen"
 }
}
}

/// Fachliche Trennung: Struktur (Abteilungen) vs. Personen.
enum OrganonEbenenKategorie: String, CaseIterable, Identifiable {
case struktur, personen, alles

var id: String { rawValue }

var bezeichnung: String {
 switch self {
 case .struktur: return "Nur Abteilungen"
 case .personen: return "Nur Personen"
 case .alles: return "Alles"
 }
}
}

struct OrganonKnoten: Identifiable, Hashable, Codable {
var id: String
var typ: OrganonKnotenTyp
var name: String
var untertitel: String?
var parentId: String?
var posX: Double
var posY: Double
var mitarbeiterAnzahl: Int?
var standort: String?
var rolle: String?
var taetigkeitsclaim: String?
var verantwortungen: [String]?
var projekte: [String]?
var skills: [String]?
var skillMatrix: [OrganonSkill]?
var sprachen: [String]?
var kapazitaet: OrganonKapazitaet?
var ansprechthemen: [String]?
var istVakanz: Bool = false
var notizen: String?
var tags: [String]?
var email: String?
var vorgangIds: [String]?
var caseIds: [String]?
var mandantIds: [String]?

var position: CGPoint { CGPoint(x: posX, y: posY) }

/// Skills aus Matrix oder Legacy-Stringliste.
var effektiveSkills: [String] {
 if let m = skillMatrix, !m.isEmpty { return m.map(\.name) }
 return skills ?? []
}

var suchText: String {
 var parts = [name, untertitel, rolle, taetigkeitsclaim, standort, email, notizen].compactMap { $0 }
 parts += verantwortungen ?? []
 parts += projekte ?? []
 parts += effektiveSkills
 parts += sprachen ?? []
 parts += ansprechthemen ?? []
 parts += tags ?? []
 return parts.joined(separator: " ").lowercased()
}

var istOrganisationseinheit: Bool { typ.istOrganisationseinheit }
var istPerson: Bool { typ.istPerson }
}

struct OrganonKante: Identifiable, Hashable, Codable {
var id: String
var vonId: String
var zuId: String
var typ: OrganonKantenTyp
var label: String?
var notiz: String?
}

struct OrganonAuditEintrag: Identifiable, Codable, Hashable {
var id: String
var zeit: Date
var aktion: String
var detail: String

init(id: String = UUID().uuidString, zeit: Date = Date(), aktion: String, detail: String) {
 self.id = id
 self.zeit = zeit
 self.aktion = aktion
 self.detail = detail
}
}

struct OrganonGraphSnapshot: Codable {
var knoten: [OrganonKnoten]
var kanten: [OrganonKante]
var audit: [OrganonAuditEintrag]
}

struct OrganonSuchFilter: Equatable {
var query: String = ""
var skills: Set<String> = []
var standorte: Set<String> = []
var nurVerfuegbar: Bool = false
var nurVakanzen: Bool = false
var tags: Set<String> = []
}

enum OrganonOverlay: String, CaseIterable, Identifiable {
case vakanz, projektlast, kapazitaet

var id: String { rawValue }

var bezeichnung: String {
 switch self {
 case .vakanz: return "Vakanzen"
 case .projektlast: return "Projektlast"
 case .kapazitaet: return "Kapazität"
 }
}

var symbol: String {
 switch self {
 case .vakanz: return "person.crop.circle.badge.questionmark"
 case .projektlast: return "chart.bar.doc.horizontal"
 case .kapazitaet: return "gauge.with.dots.needle.33percent"
 }
}
}

// MARK: - Persistenter Store

@Observable
final class OrganonStore {
static let shared = OrganonStore()

private let persistKey = "organon_graph_v1"
private var saveTask: Task<Void, Never>?

var knoten: [OrganonKnoten] = []
var kanten: [OrganonKante] = []
var audit: [OrganonAuditEintrag] = []

private init() {
 laden()
 if knoten.isEmpty {
   let demo = OrganonDemoData.laden()
   knoten = demo.knoten.map { Self.anreichernSkills($0) }
   kanten = demo.kanten
   protokolliere("Seed", "Demo-Organisation geladen")
   speichern()
 }
 repariereHierarchie(still: true)
 aktualisiereMitarbeiterZahlen()
}

private static func anreichernSkills(_ kn: OrganonKnoten) -> OrganonKnoten {
 var k = kn
 if (k.skillMatrix == nil || k.skillMatrix?.isEmpty == true), let skills = k.skills, !skills.isEmpty {
   k.skillMatrix = skills.map { OrganonSkill(name: $0, level: .praxis) }
 }
 return k
}

func scheduleSpeichern() {
 saveTask?.cancel()
 saveTask = Task { @MainActor in
   try? await Task.sleep(for: .milliseconds(400))
   guard !Task.isCancelled else { return }
   speichern()
 }
}

func speichern() {
 let snap = OrganonGraphSnapshot(knoten: knoten, kanten: kanten, audit: Array(audit.prefix(200)))
 if let data = try? JSONEncoder().encode(snap) {
   UserDefaults.standard.set(data, forKey: persistKey)
 }
}

private func laden() {
 guard let data = UserDefaults.standard.data(forKey: persistKey),
    let snap = try? JSONDecoder().decode(OrganonGraphSnapshot.self, from: data) else { return }
 knoten = snap.knoten.map { Self.anreichernSkills($0) }
 kanten = snap.kanten
 audit = snap.audit
}

func protokolliere(_ aktion: String, _ detail: String) {
 audit.insert(.init(aktion: aktion, detail: detail), at: 0)
 if audit.count > 200 { audit = Array(audit.prefix(200)) }
}

func setzeKnoten(_ kn: OrganonKnoten) {
 var kn = kn
 // Ungültige Eltern-Zuordnung ablehnen -> parentId korrigieren
 if let pid = kn.parentId, let eltern = knoten.first(where: { $0.id == pid }) {
   if !kn.typ.erlaubteElternTypen.contains(eltern.typ) {
     kn.parentId = naechsterGueltigerElternId(fuer: kn.typ, ab: pid)
   }
 }
 if let i = knoten.firstIndex(where: { $0.id == kn.id }) {
   knoten[i] = kn
   protokolliere("Aktualisiert", "\(kn.typ.kurz): \(kn.name)")
 } else {
   knoten.append(kn)
   protokolliere("Angelegt", "\(kn.typ.kurz): \(kn.name)")
 }
 syncBerichtslinie(fuer: kn.id)
 aktualisiereMitarbeiterZahlen()
 scheduleSpeichern()
}

func loescheKnoten(_ id: String) {
 let geloescht = knoten.first { $0.id == id }
 let name = geloescht?.name ?? id
 let neuerEltern = geloescht?.parentId
 // Kinder an den Großeltern umhängen -- nie verwaisen lassen
 for i in knoten.indices where knoten[i].parentId == id {
   knoten[i].parentId = neuerEltern
 }
 knoten.removeAll { $0.id == id }
 kanten.removeAll { $0.vonId == id || $0.zuId == id }
 // Berichtslinien der umgehängten Kinder neu setzen
 for kn in knoten where kn.parentId == neuerEltern {
   syncBerichtslinie(fuer: kn.id)
 }
 aktualisiereMitarbeiterZahlen()
 protokolliere("Gelöscht", "\(geloescht?.typ.kurz ?? "?"): \(name)")
 scheduleSpeichern()
}

/// parentId ist Quelle der Wahrheit -> disziplinarische Kante wird gespiegelt.
func syncBerichtslinie(fuer knotenId: String) {
 guard let kn = knoten.first(where: { $0.id == knotenId }) else { return }
 // Alte Berichtslinien ZU diesem Knoten entfernen
 kanten.removeAll { $0.zuId == knotenId && $0.typ == .disziplinarisch }
 guard let pid = kn.parentId else { return }
 let bereits = kanten.contains { $0.vonId == pid && $0.zuId == knotenId && $0.typ == .disziplinarisch }
 if !bereits {
   kanten.append(OrganonKante(
     id: "bl-\(knotenId)",
     vonId: pid,
     zuId: knotenId,
     typ: .disziplinarisch,
     label: "Berichtslinie"
   ))
 }
}

/// Behebt Inkonsistenzen zwischen parentId und Berichtslinien (parentId gewinnt).
func repariereHierarchie(still: Bool = false) {
 var geaendert = 0
 for kn in knoten {
   let alt = kanten.filter { $0.zuId == kn.id && $0.typ == .disziplinarisch }
   if let pid = kn.parentId {
     if alt.count != 1 || alt.first?.vonId != pid {
       syncBerichtslinie(fuer: kn.id)
       geaendert += 1
     }
   } else if !alt.isEmpty {
     // Kein parentId, aber Kante -- parentId aus Kante übernehmen
     if let von = alt.first?.vonId,
      let eltern = knoten.first(where: { $0.id == von }),
      kn.typ.erlaubteElternTypen.contains(eltern.typ),
      let i = knoten.firstIndex(where: { $0.id == kn.id }) {
       knoten[i].parentId = von
       syncBerichtslinie(fuer: kn.id)
       geaendert += 1
     }
   }
 }
 aktualisiereMitarbeiterZahlen()
 if geaendert > 0 {
   if !still { protokolliere("Hierarchie", "\(geaendert) Knoten repariert") }
   scheduleSpeichern()
 }
}

/// Mitarbeiterzahl der Organisationseinheiten aus direkten/indirekten Personen ableiten.
func aktualisiereMitarbeiterZahlen() {
 let personenUnter: (String) -> Int = { [self] rootId in
   var count = 0
   var queue = [rootId]
   var gesehen = Set<String>()
   while let id = queue.first {
     queue.removeFirst()
     guard gesehen.insert(id).inserted else { continue }
     for kind in knoten where kind.parentId == id {
       if kind.typ == .person, !kind.istVakanz { count += 1 }
       else if kind.typ.istOrganisationseinheit { queue.append(kind.id) }
     }
   }
   return count
 }
 for i in knoten.indices where knoten[i].typ.istOrganisationseinheit {
   knoten[i].mitarbeiterAnzahl = personenUnter(knoten[i].id)
   if knoten[i].typ != .gesellschaft {
     let n = knoten[i].mitarbeiterAnzahl ?? 0
     knoten[i].untertitel = "\(n) Berufsträger"
   }
 }
}

private func naechsterGueltigerElternId(fuer typ: OrganonKnotenTyp, ab startId: String) -> String? {
 var aktuell = startId
 var schutz = 0
 while schutz < 8 {
   schutz += 1
   guard let kn = knoten.first(where: { $0.id == aktuell }) else { return nil }
   if typ.erlaubteElternTypen.contains(kn.typ) { return kn.id }
   guard let next = kn.parentId else { return nil }
   aktuell = next
 }
 return nil
}

func kinder(von parentId: String) -> [OrganonKnoten] {
 knoten.filter { $0.parentId == parentId }
   .sorted { lhs, rhs in
     if lhs.typ.hierarchieEbene != rhs.typ.hierarchieEbene {
       return lhs.typ.hierarchieEbene < rhs.typ.hierarchieEbene
     }
     return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
   }
}

func pfad(zu id: String) -> [OrganonKnoten] {
 var result: [OrganonKnoten] = []
 var aktuell = knoten.first { $0.id == id }
 var schutz = 0
 while let kn = aktuell, schutz < 12 {
   result.insert(kn, at: 0)
   aktuell = kn.parentId.flatMap { pid in knoten.first { $0.id == pid } }
   schutz += 1
 }
 return result
}

func wurzeln() -> [OrganonKnoten] {
 knoten.filter { $0.parentId == nil }
   .sorted { $0.name < $1.name }
}

func setzeKante(_ k: OrganonKante) {
 if let i = kanten.firstIndex(where: { $0.id == k.id }) {
   kanten[i] = k
 } else {
   kanten.append(k)
   protokolliere("Kante", "\(k.typ.bezeichnung): \(k.vonId) -> \(k.zuId)")
 }
 scheduleSpeichern()
}

func loescheKante(_ id: String) {
 kanten.removeAll { $0.id == id }
 protokolliere("Kante entfernt", id)
 scheduleSpeichern()
}

func resetAufDemo() {
 let demo = OrganonDemoData.laden()
 knoten = demo.knoten.map { Self.anreichernSkills($0) }
 kanten = demo.kanten
 audit = []
 protokolliere("Reset", "Demo-Organisation wiederhergestellt")
 speichern()
}

func exportJSON() -> String {
 let snap = OrganonGraphSnapshot(knoten: knoten, kanten: kanten, audit: audit)
 let enc = JSONEncoder()
 enc.outputFormatting = [.prettyPrinted, .sortedKeys]
 guard let data = try? enc.encode(snap), let s = String(data: data, encoding: .utf8) else { return "{}" }
 return s
}

func exportMarkdown() -> String {
 var lines = ["# Organon -- Organisationshierarchie", ""]
 let abt = knoten.filter { $0.typ == .bereich }.count
 let tm = knoten.filter { $0.typ == .team }.count
 let pers = knoten.filter { $0.typ == .person && !$0.istVakanz }.count
 lines.append("Abteilungen: \(abt) · Teams: \(tm) · Personen: \(pers) · Kanten: \(kanten.count)")
 lines.append("")
 func dump(_ id: String, tiefe: Int) {
   guard let kn = knoten.first(where: { $0.id == id }) else { return }
   let pad = String(repeating: " ", count: tiefe)
   let mark = kn.istPerson ? "n" : (kn.typ == .bereich ? "n" : (kn.typ == .team ? "n" : "n"))
   lines.append("\(pad)- \(mark) **\(kn.name)** (\(kn.typ.kurz))")
   if let r = kn.rolle { lines.append("\(pad) - Rolle: \(r)") }
   if kn.istOrganisationseinheit {
     lines.append("\(pad) - Berufsträger: \(kn.mitarbeiterAnzahl ?? 0)")
   }
   if !kn.effektiveSkills.isEmpty {
     lines.append("\(pad) - Skills: \(kn.effektiveSkills.joined(separator: ", "))")
   }
   for kind in kinder(von: id) {
     dump(kind.id, tiefe: tiefe + 1)
   }
 }
 for w in wurzeln() { dump(w.id, tiefe: 0) }
 return lines.joined(separator: "\n")
}
}

