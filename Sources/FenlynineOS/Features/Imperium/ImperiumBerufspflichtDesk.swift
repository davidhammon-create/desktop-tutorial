import Foundation
import SwiftUI
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// BERUFSPFLICHT-DESK -- aus Marktforschung & Juristenstimmen
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Quellen (Auswahl):
// · BGH Fristenkontrolle / gestufte Ausgangskontrolle (u.a. IV ZB 30/23,
// XI ZB 13/22, VIII ZB 103/18) -- allabendliche Endkontrolle
// · DAV-Vize Martin Schafhausen (LTO): ERV, Daten, e-Akte, Fristenkalender
// · beck-aktuell / OLG Celle u.a.: KI-Halluzinationen -> Endprüfung Pflicht
// · Prof. Dr. Volker Römermann: Legal Tech nur mit Berufsrecht/Haftung
// · Legal Tech Monitor 2025 / Bay. Anwaltverband: Prozess > Tool
// · Gap Map 2026: Intake darf ohne Conflict-Clear nicht öffnen
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum ImperiumBerufspflichtTab: String, CaseIterable, Identifiable {
case tagesablauf, fristenwache, mandatsannahme, wiedervorlage, kiPruefung, leitlinien

var id: String { rawValue }

var titel: String {
  switch self {
  case .tagesablauf: return "Tagesablauf"
  case .fristenwache: return "Fristenwache"
  case .mandatsannahme: return "Mandatsannahme"
  case .wiedervorlage: return "Wiedervorlage"
  case .kiPruefung: return "KI-Prüfung"
  case .leitlinien: return "Leitlinien"
  }
}

var symbol: String {
  switch self {
  case .tagesablauf: return "sun.max.fill"
  case .fristenwache: return "calendar.badge.exclamationmark"
  case .mandatsannahme: return "signature"
  case .wiedervorlage: return "arrow.uturn.forward.circle.fill"
  case .kiPruefung: return "eye.trianglebadge.exclamationmark"
  case .leitlinien: return "books.vertical.fill"
  }
}
}

// MARK: - Fristenwache (BGH Ausgangskontrolle)

enum ImperiumFristStufe: String, Codable, CaseIterable {
case notiert, inArbeit, versandfertig, abgesandt, kontrolliert

var label: String {
  switch self {
  case .notiert: return "Notiert"
  case .inArbeit: return "In Arbeit"
  case .versandfertig: return "Versandfertig"
  case .abgesandt: return "Abgesandt"
  case .kontrolliert: return "Endkontrolle OK"
  }
}
}

struct ImperiumFristWacheEintrag: Identifiable, Codable, Hashable {
var id: String
var titel: String
var akte: String
var faellig: Date
var typ: String
var stufe: ImperiumFristStufe
var gestrichenSichtbar: Bool // BGH: gestrichene Fristen müssen erkennbar bleiben
var notiz: String
var kontrolliertVon: String?
var kontrolliertAm: Date?
var erstellt: Date
}

struct ImperiumAusgangskontrolleProtokoll: Identifiable, Codable, Hashable {
var id: String
var datum: Date
var pruefer: String
var offeneCount: Int
var erledigtCount: Int
var bemerkung: String
var abgeschlossen: Bool
}

@MainActor
@Observable
final class ImperiumFristenwacheStore {
static let shared = ImperiumFristenwacheStore()
var eintraege: [ImperiumFristWacheEintrag] = []
var protokolle: [ImperiumAusgangskontrolleProtokoll] = []
private let key = "imperium_fristenwache_v1"

private init() {
  if let snap = ImperiumDisk.load(key, as: Snap.self) {
    eintraege = snap.eintraege
    protokolle = snap.protokolle
  }
}

func speichern() {
 ImperiumDisk.save(Snap(eintraege: eintraege, protokolle: protokolle), key: key)
}

func neu(titel: String, akte: String, faellig: Date, typ: String) {
 eintraege.insert(
   .init(
     id: UUID().uuidString,
     titel: titel,
     akte: akte,
     faellig: faellig,
     typ: typ,
     stufe: .notiert,
     gestrichenSichtbar: false,
     notiz: "",
     kontrolliertVon: nil,
     kontrolliertAm: nil,
     erstellt: .now
   ),
   at: 0
 )
 speichern()
 ImperiumEntscheidungsJournal.shared.eintrag(
   typ: .compliance,
   titel: "Frist notiert: \(titel)",
   detail: "\(akte) · \(faellig.formatted(date: .abbreviated, time: .omitted))",
   module: ["Fristenwache", "Berufspflicht"]
 )
}

func setzeStufe(_ id: String, _ stufe: ImperiumFristStufe) {
 guard let i = eintraege.firstIndex(where: { $0.id == id }) else { return }
 eintraege[i].stufe = stufe
 if stufe == .kontrolliert {
   eintraege[i].kontrolliertAm = .now
   eintraege[i].kontrolliertVon = "Ausgangskontrolle"
 }
 speichern()
}

func streicheSichtbar(_ id: String) {
 guard let i = eintraege.firstIndex(where: { $0.id == id }) else { return }
 // BGH: Streichung darf Endkontrolle nicht unsichtbar machen
 eintraege[i].gestrichenSichtbar = true
 eintraege[i].notiz += (eintraege[i].notiz.isEmpty ? "" : "\n") + "Als erledigt markiert (sichtbar belassen) · \(Date.now.formatted())"
 speichern()
}

/// Allabendliche Ausgangskontrolle -- BGH-konformes Protokoll
func abendkontrolle(pruefer: String, bemerkung: String) {
 let offen = eintraege.filter {
   !$0.gestrichenSichtbar && $0.stufe != .kontrolliert && Calendar.current.isDateInToday($0.faellig)
     || (!$0.gestrichenSichtbar && $0.stufe != .abgesandt && $0.stufe != .kontrolliert && $0.faellig <= Date().addingTimeInterval(86400 * 2))
 }
 let erledigt = eintraege.filter { $0.stufe == .abgesandt || $0.stufe == .kontrolliert || $0.gestrichenSichtbar }
 let proto = ImperiumAusgangskontrolleProtokoll(
   id: UUID().uuidString,
   datum: .now,
   pruefer: pruefer.isEmpty ? "Sachbearbeitung" : pruefer,
   offeneCount: offen.count,
   erledigtCount: erledigt.count,
   bemerkung: bemerkung,
   abgeschlossen: true
 )
 protokolle.insert(proto, at: 0)
 for e in offen where e.stufe == .abgesandt || e.stufe == .versandfertig {
   setzeStufe(e.id, .kontrolliert)
 }
 speichern()
 ImperiumEntscheidungsJournal.shared.eintrag(
   typ: .compliance,
   titel: "Ausgangskontrolle \(proto.datum.formatted(date: .abbreviated, time: .shortened))",
   detail: "Prüfer \(proto.pruefer) · offen \(proto.offeneCount) · erledigt \(proto.erledigtCount) · \(bemerkung)",
   module: ["Fristenwache", "BGH-Ausgangskontrolle"]
 )
}

var heuteKritisch: [ImperiumFristWacheEintrag] {
 eintraege.filter {
   !$0.gestrichenSichtbar && $0.stufe != .kontrolliert
     && Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: $0.faellig)).day ?? 99 <= 3
 }
 .sorted { $0.faellig < $1.faellig }
}

private struct Snap: Codable {
 var eintraege: [ImperiumFristWacheEintrag]
 var protokolle: [ImperiumAusgangskontrolleProtokoll]
}
}

// MARK: - Mandatsannahme-Gate

enum ImperiumAnnahmeGate: String, Codable, CaseIterable {
case konfliktKlar, vollmacht, honorar, aufklaerung, datenschutz, freigabe

var titel: String {
 switch self {
 case .konfliktKlar: return "Interessenkonflikt geprüft / klar"
 case .vollmacht: return "Vollmacht / Mandatsvertrag"
 case .honorar: return "Honorarvereinbarung / RVG-Hinweis"
 case .aufklaerung: return "Aufklärung Risiken / Prozessaussichten"
 case .datenschutz: return "Datenschutz / Verschwiegenheit dokumentiert"
 case .freigabe: return "Mandatsannahme freigegeben"
 }
}

var hinweis: String {
 switch self {
 case .konfliktKlar: return "Gap Map 2026 / Berufspraxis: kein Matter-Open ohne Conflict-Clear."
 case .vollmacht: return "BRAO: Grundlage der Vertretung schriftlich absichern."
 case .honorar: return "Transparenz vor Tätigwerden -- Streitwert/Stundensatz."
 case .aufklaerung: return "Mandant muss Chancen/Risiken verstehen können."
 case .datenschutz: return "DSGVO + anwaltliche Verschwiegenheit."
 case .freigabe: return "Erst danach Pipeline -> Aktiv / Lexara-Akte öffnen."
 }
}
}

struct ImperiumMandatsAnnahmeAkte: Identifiable, Codable, Hashable {
var id: String
var titel: String
var mandant: String
var caseFlags: [String: Bool] // gate rawValue -> erledigt
var notiz: String
var erstellt: Date
var freigegebenAm: Date?

var fortschritt: Double {
 let keys = ImperiumAnnahmeGate.allCases.map(\.rawValue)
 let done = keys.filter { caseFlags[$0] == true }.count
 return Double(done) / Double(max(keys.count, 1))
}

var istFreigegeben: Bool {
 ImperiumAnnahmeGate.allCases.allSatisfy { caseFlags[$0.rawValue] == true }
}
}

@MainActor
@Observable
final class ImperiumMandatsAnnahmeStore {
static let shared = ImperiumMandatsAnnahmeStore()
var akten: [ImperiumMandatsAnnahmeAkte] = []
private let key = "imperium_mandatsannahme_v1"

private init() {
 akten = ImperiumDisk.load(key, as: [ImperiumMandatsAnnahmeAkte].self) ?? []
}

func speichern() { ImperiumDisk.save(akten, key: key) }

func neu(titel: String, mandant: String) {
 var flags: [String: Bool] = [:]
 for g in ImperiumAnnahmeGate.allCases { flags[g.rawValue] = false }
 akten.insert(
   .init(id: UUID().uuidString, titel: titel, mandant: mandant, caseFlags: flags, notiz: "", erstellt: .now, freigegebenAm: nil),
   at: 0
 )
 speichern()
}

func toggle(id: String, gate: ImperiumAnnahmeGate) {
 guard let i = akten.firstIndex(where: { $0.id == id }) else { return }
 let cur = akten[i].caseFlags[gate.rawValue] ?? false
 akten[i].caseFlags[gate.rawValue] = !cur
 if akten[i].istFreigegeben {
   akten[i].freigegebenAm = .now
   ImperiumEntscheidungsJournal.shared.eintrag(
     typ: .prozess,
     titel: "Mandat freigegeben: \(akten[i].titel)",
     detail: akten[i].mandant,
     module: ["Mandatsannahme", "Pipeline"]
   )
   // Pipeline-Sync: Lead -> Annahme
   if let pipe = ImperiumPipelineStore.shared.akten.first(where: {
     $0.titel.caseInsensitiveCompare(akten[i].titel) == .orderedSame
       || $0.mandant.caseInsensitiveCompare(akten[i].mandant) == .orderedSame
   }) {
     ImperiumPipelineStore.shared.setzeStufe(pipe.id, .annahme)
   }
 }
 speichern()
}
}

// MARK: - Wiedervorlage

struct ImperiumWiedervorlage: Identifiable, Codable, Hashable {
var id: String
var titel: String
var akte: String
var faellig: Date
var erledigt: Bool
var grund: String
}

@MainActor
@Observable
final class ImperiumWiedervorlageStore {
static let shared = ImperiumWiedervorlageStore()
var items: [ImperiumWiedervorlage] = []
private let key = "imperium_wiedervorlage_v1"

private init() {
 items = ImperiumDisk.load(key, as: [ImperiumWiedervorlage].self) ?? []
}

func speichern() { ImperiumDisk.save(items, key: key) }

func neu(titel: String, akte: String, faellig: Date, grund: String) {
 items.insert(.init(id: UUID().uuidString, titel: titel, akte: akte, faellig: faellig, erledigt: false, grund: grund), at: 0)
 speichern()
}

func toggle(_ id: String) {
 guard let i = items.firstIndex(where: { $0.id == id }) else { return }
 items[i].erledigt.toggle()
 speichern()
}

var offenHeute: [ImperiumWiedervorlage] {
 items.filter { !$0.erledigt && $0.faellig <= Date().addingTimeInterval(86400) }
   .sorted { $0.faellig < $1.faellig }
}
}

// MARK: - KI-Prüfprotokoll (Human-in-the-loop)

enum ImperiumKICheck: String, Codable, CaseIterable {
case fundstellen, normen, sachverhalt, stil, geheimnis, endfreigabe

var titel: String {
 switch self {
 case .fundstellen: return "Rechtsprechungs-/Fundstellen geprüft (keine Halluzination)"
 case .normen: return "Normzitate gegen aktuelle Fassung geprüft"
 case .sachverhalt: return "Sachverhalt nur aus Akte / Mandantenangaben"
 case .stil: return "Schriftsatz/Stil kanzleiüblich, kein Blind-Copy"
 case .geheimnis: return "Keine Mandantengeheimnisse in externe KI ohne Freigabe"
 case .endfreigabe: return "Anwaltliche Endprüfung / Unterschrift"
 }
}

var quelle: String {
 switch self {
 case .fundstellen: return "OLG Celle / LG Frankfurt / AG Köln -- erfundene Zitate"
 case .normen: return "beck-aktuell: LLM „ Rechtsprechungsdatenbank"
 case .sachverhalt: return "Berufspflicht: eigenverantwortliche Mandatsführung"
 case .stil: return "Römermann / Berufsrecht: persönliche Leistung"
 case .geheimnis: return "BRAO Verschwiegenheit · DSGVO"
 case .endfreigabe: return "Anwaltliche Letztverantwortung -- nicht delegierbar an KI"
 }
}
}

struct ImperiumKIPruefProtokoll: Identifiable, Codable, Hashable {
var id: String
var bezug: String
var modul: String
var checks: [String: Bool]
var erstellt: Date
var freigegeben: Bool

var vollständig: Bool {
 ImperiumKICheck.allCases.allSatisfy { checks[$0.rawValue] == true }
}
}

@MainActor
@Observable
final class ImperiumKIPruefStore {
static let shared = ImperiumKIPruefStore()
var protokolle: [ImperiumKIPruefProtokoll] = []
private let key = "imperium_ki_pruef_v1"

private init() {
 protokolle = ImperiumDisk.load(key, as: [ImperiumKIPruefProtokoll].self) ?? []
}

func speichern() { ImperiumDisk.save(protokolle, key: key) }

func neu(bezug: String, modul: String) {
 var c: [String: Bool] = [:]
 for k in ImperiumKICheck.allCases { c[k.rawValue] = false }
 protokolle.insert(
   .init(id: UUID().uuidString, bezug: bezug, modul: modul, checks: c, erstellt: .now, freigegeben: false),
   at: 0
 )
 speichern()
}

func toggle(id: String, check: ImperiumKICheck) {
 guard let i = protokolle.firstIndex(where: { $0.id == id }) else { return }
 protokolle[i].checks[check.rawValue] = !(protokolle[i].checks[check.rawValue] ?? false)
 protokolle[i].freigegeben = protokolle[i].vollständig
 if protokolle[i].freigegeben {
   ImperiumEntscheidungsJournal.shared.eintrag(
     typ: .compliance,
     titel: "KI-Endprüfung OK: \(protokolle[i].bezug)",
     detail: protokolle[i].modul,
     module: ["KI-Prüfung", "Berufspflicht"]
   )
 }
 speichern()
}
}

// MARK: - Leitlinien (für UI)

struct ImperiumLeitlinie: Identifiable {
let id = UUID()
let titel: String
let quelle: String
let text: String
}

enum ImperiumLeitlinienKatalog {
static let alle: [ImperiumLeitlinie] = [
 .init(
   titel: "Gestufte Ausgangskontrolle",
   quelle: "BGH (u.a. IV ZB 30/23, XI ZB 13/22)",
   text: "Am Abend jedes Arbeitstages muss eine beauftragte Kraft anhand des Fristenkalenders selbstständig prüfen, ob fristwahrende Schriftsätze gefertigt, abgesandt oder versandfertig sind -- und mit dem Kalender übereinstimmen. Gestrichene Fristen müssen erkennbar bleiben."
 ),
 .init(
   titel: "KI liefert Vorarbeit, keine Entscheidung",
   quelle: "beck-aktuell 2026 · OLG Celle / LG Frankfurt Halluzinationsfälle",
   text: "Sprachmodelle sind keine Rechtsprechungsdatenbank. Fundstellen und Normen müssen gegen verlässliche Quellen geprüft werden. Ungeprüfte Übernahme ist haftungsrelevant."
 ),
 .init(
   titel: "Persönliche anwaltliche Leistung",
   quelle: "Prof. Dr. Volker Römermann · BRAO/RDG",
   text: "Legal Tech ist zulässig, wenn Verschwiegenheit, Datenschutz und persönliche Leistungspflichten gewahrt bleiben. Haftung bleibt beim Anwalt."
 ),
 .init(
   titel: "Elektronischer Rechtsverkehr & Justiz-Flickenteppich",
   quelle: "DAV-Vize Martin Schafhausen (LTO) · DAV PM 49/25",
   text: "Die Anwaltschaft kommuniziert digital; die Justiz hinkt nach. Kanzleisoftware muss Fristen, Versandnachweise und Aktenführung so führen, dass Medienbrüche nicht zu Fristverlust führen."
 ),
 .init(
   titel: "Prozess vor Tool",
   quelle: "Legal Tech Monitor 2025 · Bay. Anwaltverband/Noerr-Umfrage",
   text: "KI-Budgets ohne Workflow scheitern. Intake, Konflikt, Fristen, Prüfung und Dokumentation müssen vor dem Modell stehen."
 ),
 .init(
   titel: "Matter-Open nur nach Conflict-Clear",
   quelle: "Legal Technology Gap Map 2026",
   text: "Moderne Kanzlei-OS blockieren Mandatsanlage, bis Interessenkonflikte geklärt sind -- nicht erst hinterher."
 )
]
}

// MARK: - Hauptansicht

struct ImperiumBerufspflichtDeskView: View {
@State private var tab: ImperiumBerufspflichtTab = .tagesablauf
@State private var fristen = ImperiumFristenwacheStore.shared
@State private var annahme = ImperiumMandatsAnnahmeStore.shared
@State private var wvl = ImperiumWiedervorlageStore.shared
@State private var ki = ImperiumKIPruefStore.shared
@State private var praxis = ImperiumPraxisStore.shared

var body: some View {
 VStack(spacing: 0) {
   header
   Picker("", selection: $tab) {
     ForEach(ImperiumBerufspflichtTab.allCases) { t in
       Label(t.titel, systemImage: t.symbol).tag(t)
     }
   }
   .pickerStyle(.segmented)
   .padding(12)
   .background(Premium.ink)

   Group {
     switch tab {
     case .tagesablauf: tagesablauf
     case .fristenwache: fristenwache
     case .mandatsannahme: mandatsannahme
     case .wiedervorlage: wiedervorlage
     case .kiPruefung: kiPruefung
     case .leitlinien: leitlinien
     }
   }
   .frame(maxWidth: .infinity, maxHeight: .infinity)
 }
 .background(Premium.void)
 .fenlynineOSAdaptiveNavigationTitle("Berufspflicht-Desk")
}

private var header: some View {
 HStack {
   VStack(alignment: .leading, spacing: 4) {
     Text("Berufspflicht-Desk")
       .font(.system(size: 18, weight: .bold))
       .foregroundStyle(Premium.text)
     Text("BGH-Fristen · Mandatsannahme · KI-Endprüfung · \(praxis.aktiv.titel)")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   }
   Spacer()
   Label("\(fristen.heuteKritisch.count) kritische Fristen", systemImage: "exclamationmark.triangle.fill")
     .font(.system(size: 11, weight: .semibold))
     .foregroundStyle(fristen.heuteKritisch.isEmpty ? Premium.computed : Color.orange)
 }
 .padding(16)
 .background(Premium.ink)
}

// MARK: Tagesablauf

private var tagesablauf: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 14) {
     Text("Anwaltlicher Tagesrhythmus")
       .font(.system(size: 14, weight: .semibold))
       .foregroundStyle(Premium.text)
     Text("Morgen: Lage & Fristen · Arbeit: Akte/Strategie · Abend: Ausgangskontrolle (BGH).")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)

     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
       deskKarte("Lagezentrale", "Gesamtbild Mandate & Konflikte", "rectangle.3.group.bubble.left.fill", .lageZentrale)
       deskKarte("KonfliktRadar", "Vor jeder Annahme", "exclamationmark.shield.fill", .konfliktRadar)
       deskKarte("Fristenwache", "\(fristen.heuteKritisch.count) in 3 Tagen", "calendar.badge.exclamationmark", nil) {
         tab = .fristenwache
       }
       deskKarte("Wiedervorlage", "\(wvl.offenHeute.count) fällig", "arrow.uturn.forward.circle.fill", nil) {
         tab = .wiedervorlage
       }
       deskKarte("KI-Prüfung", "\(ki.protokolle.filter(\.freigegeben).count) freigegeben", "eye.trianglebadge.exclamationmark", nil) {
         tab = .kiPruefung
       }
       deskKarte("beA-Check", "Gerichts-Post-Prozess", "envelope.badge.shield.half.filled", .beaCheck)
     }

     VStack(alignment: .leading, spacing: 8) {
       Text("Heute kritisch")
         .font(.system(size: 12, weight: .semibold))
       if fristen.heuteKritisch.isEmpty {
         Text("Keine kritischen Fristen in den nächsten 3 Tagen.")
           .font(.system(size: 11))
           .foregroundStyle(Premium.computed)
       } else {
         ForEach(fristen.heuteKritisch.prefix(8)) { e in
           HStack {
             Text(e.faellig.formatted(date: .abbreviated, time: .omitted))
               .font(.system(size: 10, design: .monospaced))
               .foregroundStyle(Color.orange)
             Text(e.titel).font(.system(size: 12)).foregroundStyle(Premium.text)
             Spacer()
             Text(e.stufe.label).font(.system(size: 10)).foregroundStyle(Premium.textFaint)
           }
         }
       }
     }
     .padding(14)
     .background(RoundedRectangle(cornerRadius: 10).fill(Premium.ink))
   }
   .padding(16)
 }
}

private func deskKarte(_ titel: String, _ sub: String, _ symbol: String, _ ziel: SeitenleistenEintrag?, action: (() -> Void)? = nil) -> some View {
 Button {
   if let action { action() }
   else if let ziel {
     NotificationCenter.default.post(name: .navigateToSidebar, object: ziel.rawValue)
   }
 } label: {
   HStack(alignment: .top, spacing: 10) {
     Image(systemName: symbol).foregroundStyle(Premium.action)
     VStack(alignment: .leading, spacing: 4) {
       Text(titel).font(.system(size: 13, weight: .semibold)).foregroundStyle(Premium.text)
       Text(sub).font(.system(size: 10)).foregroundStyle(Premium.textSoft)
     }
     Spacer()
   }
   .padding(12)
   .background(RoundedRectangle(cornerRadius: 10).fill(Premium.ink))
   .overlay(RoundedRectangle(cornerRadius: 10).stroke(Premium.hairline, lineWidth: 1))
 }
 .buttonStyle(.plain)
}

// MARK: Fristenwache

private var fristenwache: some View {
 HStack(spacing: 0) {
   VStack(alignment: .leading, spacing: 10) {
     Text("Neue Frist").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
     FristNeuForm(store: fristen)
     Divider()
     Text("Ausgangskontrolle (Abend)").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
     AusgangskontrolleForm(store: fristen)
     Spacer()
   }
   .padding(14)
   .frame(width: 280)
   .background(Premium.ink)

   List {
     Section("Aktive Fristen") {
       ForEach(fristen.eintraege.filter { !$0.gestrichenSichtbar || true }) { e in
         VStack(alignment: .leading, spacing: 6) {
           HStack {
             Text(e.titel).font(.system(size: 12, weight: .semibold))
             if e.gestrichenSichtbar {
               Text("GESTRICHEN (sichtbar)")
                 .font(.system(size: 8, weight: .bold))
                 .foregroundStyle(Color.orange)
             }
             Spacer()
             Text(e.faellig.formatted(date: .abbreviated, time: .omitted))
               .font(.system(size: 10, design: .monospaced))
           }
           Text("\(e.akte) · \(e.typ)").font(.system(size: 10)).foregroundStyle(Premium.textSoft)
           HStack {
             Menu(e.stufe.label) {
               ForEach(ImperiumFristStufe.allCases, id: \.self) { s in
                 Button(s.label) { fristen.setzeStufe(e.id, s) }
               }
             }
             Button("Als erledigt (sichtbar)") { fristen.streicheSichtbar(e.id) }
               .font(.system(size: 10))
           }
         }
         .listRowBackground(Premium.void)
       }
     }
     Section("Protokolle Ausgangskontrolle") {
       ForEach(fristen.protokolle.prefix(20)) { p in
         VStack(alignment: .leading, spacing: 4) {
           Text(p.datum.formatted(date: .abbreviated, time: .shortened))
             .font(.system(size: 11, weight: .semibold))
           Text("Prüfer \(p.pruefer) · offen \(p.offeneCount) · erledigt \(p.erledigtCount)")
             .font(.system(size: 10))
             .foregroundStyle(Premium.textSoft)
           if !p.bemerkung.isEmpty {
             Text(p.bemerkung).font(.system(size: 10)).foregroundStyle(Premium.textFaint)
           }
         }
         .listRowBackground(Premium.void)
       }
     }
   }
   .scrollContentBackground(.hidden)
 }
}

// MARK: Mandatsannahme

private var mandatsannahme: some View {
 HStack(spacing: 0) {
   MandatsNeuForm(store: annahme)
     .padding(14)
     .frame(width: 260)
     .background(Premium.ink)

   List {
     ForEach(annahme.akten) { a in
       VStack(alignment: .leading, spacing: 8) {
         HStack {
           Text(a.titel).font(.system(size: 13, weight: .semibold))
           Spacer()
           if a.istFreigegeben {
             Label("Freigegeben", systemImage: "checkmark.seal.fill")
               .font(.system(size: 10, weight: .bold))
               .foregroundStyle(Premium.computed)
           } else {
             Text("\(Int(a.fortschritt * 100))%")
               .font(.system(size: 10, design: .monospaced))
               .foregroundStyle(Premium.action)
           }
         }
         Text(a.mandant).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
         ProgressView(value: a.fortschritt).tint(Premium.action)
         ForEach(ImperiumAnnahmeGate.allCases, id: \.self) { g in
           Button {
             annahme.toggle(id: a.id, gate: g)
           } label: {
             HStack(alignment: .top) {
               Image(systemName: (a.caseFlags[g.rawValue] == true) ? "checkmark.circle.fill" : "circle")
                 .foregroundStyle((a.caseFlags[g.rawValue] == true) ? Premium.computed : Premium.textFaint)
               VStack(alignment: .leading, spacing: 2) {
                 Text(g.titel).font(.system(size: 11, weight: .medium)).foregroundStyle(Premium.text)
                 Text(g.hinweis).font(.system(size: 9)).foregroundStyle(Premium.textFaint)
               }
             }
           }
           .buttonStyle(.plain)
         }
       }
       .padding(.vertical, 6)
       .listRowBackground(Premium.void)
     }
   }
   .scrollContentBackground(.hidden)
 }
}

// MARK: Wiedervorlage

private var wiedervorlage: some View {
 HStack(spacing: 0) {
   WvlNeuForm(store: wvl)
     .padding(14)
     .frame(width: 260)
     .background(Premium.ink)
   List {
     ForEach(wvl.items) { item in
       Button { wvl.toggle(item.id) } label: {
         HStack {
           Image(systemName: item.erledigt ? "checkmark.circle.fill" : "circle")
             .foregroundStyle(item.erledigt ? Premium.computed : Premium.textFaint)
           VStack(alignment: .leading, spacing: 2) {
             Text(item.titel).font(.system(size: 12, weight: .semibold)).strikethrough(item.erledigt)
             Text("\(item.akte) · \(item.grund)").font(.system(size: 10)).foregroundStyle(Premium.textSoft)
           }
           Spacer()
           Text(item.faellig.formatted(date: .abbreviated, time: .omitted))
             .font(.system(size: 10, design: .monospaced))
         }
       }
       .buttonStyle(.plain)
       .listRowBackground(Premium.void)
     }
   }
   .scrollContentBackground(.hidden)
 }
}

// MARK: KI-Prüfung

private var kiPruefung: some View {
 HStack(spacing: 0) {
   VStack(alignment: .leading, spacing: 10) {
     Text("Neues Prüfprotokoll")
       .font(.system(size: 10, weight: .bold))
       .foregroundStyle(Premium.textFaint)
     KIPruefNeuForm(store: ki)
     Text("Ohne vollständige Checks darf KI-Output nicht in die Akte.")
       .font(.system(size: 10))
       .foregroundStyle(Premium.textSoft)
     Spacer()
   }
   .padding(14)
   .frame(width: 260)
   .background(Premium.ink)

   List {
     ForEach(ki.protokolle) { p in
       VStack(alignment: .leading, spacing: 8) {
         HStack {
           Text(p.bezug).font(.system(size: 12, weight: .semibold))
           Spacer()
           if p.freigegeben {
             Label("Freigegeben", systemImage: "checkmark.seal.fill")
               .font(.system(size: 10)).foregroundStyle(Premium.computed)
           }
         }
         Text(p.modul).font(.system(size: 10)).foregroundStyle(Premium.textSoft)
         ForEach(ImperiumKICheck.allCases, id: \.self) { c in
           Button { ki.toggle(id: p.id, check: c) } label: {
             HStack(alignment: .top) {
               Image(systemName: (p.checks[c.rawValue] == true) ? "checkmark.circle.fill" : "circle")
                 .foregroundStyle((p.checks[c.rawValue] == true) ? Premium.computed : Premium.textFaint)
               VStack(alignment: .leading, spacing: 2) {
                 Text(c.titel).font(.system(size: 11)).foregroundStyle(Premium.text)
                 Text(c.quelle).font(.system(size: 9)).foregroundStyle(Premium.textFaint)
               }
             }
           }
           .buttonStyle(.plain)
         }
       }
       .padding(.vertical, 4)
       .listRowBackground(Premium.void)
     }
   }
   .scrollContentBackground(.hidden)
 }
}

// MARK: Leitlinien

private var leitlinien: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 12) {
     Text("Was Juristen und Gerichte verlangen")
       .font(.system(size: 14, weight: .semibold))
       .foregroundStyle(Premium.text)
     ForEach(ImperiumLeitlinienKatalog.alle) { l in
       VStack(alignment: .leading, spacing: 6) {
         Text(l.titel).font(.system(size: 13, weight: .semibold)).foregroundStyle(Premium.text)
         Text(l.quelle).font(.system(size: 10, weight: .medium)).foregroundStyle(Premium.action)
         Text(l.text).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
       }
       .padding(14)
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(RoundedRectangle(cornerRadius: 10).fill(Premium.ink))
     }
   }
   .padding(16)
 }
}
}

// MARK: - Kleine Formulare

private struct FristNeuForm: View {
@Bindable var store: ImperiumFristenwacheStore
@State private var titel = ""
@State private var akte = ""
@State private var typ = "Schriftsatzfrist"
@State private var faellig = Date().addingTimeInterval(86400 * 14)

var body: some View {
 VStack(spacing: 8) {
   TextField("Fristtitel", text: $titel).textFieldStyle(.roundedBorder)
   TextField("Akte", text: $akte).textFieldStyle(.roundedBorder)
   TextField("Typ", text: $typ).textFieldStyle(.roundedBorder)
   DatePicker("Fällig", selection: $faellig, displayedComponents: .date)
   Button("Notieren") {
     store.neu(titel: titel.isEmpty ? "Frist" : titel, akte: akte.isEmpty ? "--" : akte, faellig: faellig, typ: typ)
     titel = ""; akte = ""
   }
   .buttonStyle(.borderedProminent)
   .tint(Premium.action)
 }
}
}

private struct AusgangskontrolleForm: View {
@Bindable var store: ImperiumFristenwacheStore
@State private var pruefer = ""
@State private var bemerkung = ""

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   TextField("Prüfer / Bürokraft", text: $pruefer).textFieldStyle(.roundedBorder)
   TextField("Bemerkung", text: $bemerkung).textFieldStyle(.roundedBorder)
   Button("Abendkontrolle abschließen") {
     store.abendkontrolle(pruefer: pruefer, bemerkung: bemerkung)
     bemerkung = ""
   }
   .buttonStyle(.borderedProminent)
   .tint(Premium.action)
   Text("Protokolliert die BGH-geforderte Endkontrolle und schreibt ins Entscheidungsjournal.")
     .font(.system(size: 9))
     .foregroundStyle(Premium.textFaint)
 }
}
}

private struct MandatsNeuForm: View {
@Bindable var store: ImperiumMandatsAnnahmeStore
@State private var titel = ""
@State private var mandant = ""

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("Neue Annahmeakte").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
   TextField("Mandat", text: $titel).textFieldStyle(.roundedBorder)
   TextField("Mandant", text: $mandant).textFieldStyle(.roundedBorder)
   Button("Anlegen") {
     store.neu(titel: titel.isEmpty ? "Neues Mandat" : titel, mandant: mandant.isEmpty ? "--" : mandant)
     titel = ""; mandant = ""
   }
   .buttonStyle(.borderedProminent)
   .tint(Premium.action)
   Text("Ohne alle Gates -> keine Freigabe. Konflikt zuerst im KonfliktRadar.")
     .font(.system(size: 9))
     .foregroundStyle(Premium.textFaint)
   Button("KonfliktRadar öffnen") {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.konfliktRadar.rawValue)
   }
   .font(.system(size: 11))
 }
}
}

private struct WvlNeuForm: View {
@Bindable var store: ImperiumWiedervorlageStore
@State private var titel = ""
@State private var akte = ""
@State private var grund = "Nachfassen"
@State private var faellig = Date().addingTimeInterval(86400 * 7)

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("Neue Wiedervorlage").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
   TextField("Titel", text: $titel).textFieldStyle(.roundedBorder)
   TextField("Akte", text: $akte).textFieldStyle(.roundedBorder)
   TextField("Grund", text: $grund).textFieldStyle(.roundedBorder)
   DatePicker("Fällig", selection: $faellig, displayedComponents: .date)
   Button("Anlegen") {
     store.neu(titel: titel.isEmpty ? "Wiedervorlage" : titel, akte: akte.isEmpty ? "--" : akte, faellig: faellig, grund: grund)
     titel = ""
   }
   .buttonStyle(.borderedProminent)
   .tint(Premium.action)
 }
}
}

private struct KIPruefNeuForm: View {
@Bindable var store: ImperiumKIPruefStore
@State private var bezug = ""
@State private var modul = "Lexara"

var body: some View {
 VStack(spacing: 8) {
   TextField("Bezug (Schriftsatz / Analyse)", text: $bezug).textFieldStyle(.roundedBorder)
   TextField("Modul", text: $modul).textFieldStyle(.roundedBorder)
   Button("Protokoll starten") {
     store.neu(bezug: bezug.isEmpty ? "KI-Output" : bezug, modul: modul)
     bezug = ""
   }
   .buttonStyle(.borderedProminent)
   .tint(Premium.action)
 }
}
}

