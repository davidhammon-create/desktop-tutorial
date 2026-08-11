import Foundation
import SwiftUI
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MANDATS-PIPELINE · HONORARE/ZEIT · ENTSCHEIDUNGSJOURNAL · beA
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum ImperiumPipelineStufe: String, CaseIterable, Identifiable, Codable {
case lead, konflikt, annahme, aktiv, abrechnung, archiv

var id: String { rawValue }

var titel: String {
  switch self {
  case .lead: return "Lead / Anfrage"
  case .konflikt: return "Konfliktcheck"
  case .annahme: return "Annahme / Vollmacht"
  case .aktiv: return "Aktiv in Arbeit"
  case .abrechnung: return "Abrechnung"
  case .archiv: return "Archiv"
  }
}

var symbol: String {
  switch self {
  case .lead: return "tray.and.arrow.down.fill"
  case .konflikt: return "exclamationmark.shield.fill"
  case .annahme: return "signature"
  case .aktiv: return "briefcase.fill"
  case .abrechnung: return "eurosign.circle.fill"
  case .archiv: return "archivebox.fill"
  }
}

var naechste: ImperiumPipelineStufe? {
  let all = Self.allCases
  guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
  return all[i + 1]
}
}

struct ImperiumPipelineAkte: Identifiable, Codable, Hashable {
var id: String
var fallId: String?
var titel: String
var mandant: String
var stufe: ImperiumPipelineStufe
var rechtsgebiet: String
var notiz: String
var erstellt: Date
var geaendert: Date
var praxis: ImperiumPraxisTyp
}

@MainActor
@Observable
final class ImperiumPipelineStore {
static let shared = ImperiumPipelineStore()
var akten: [ImperiumPipelineAkte] = []
private let key = "imperium_pipeline_v1"

private init() {
  akten = ImperiumDisk.load(key, as: [ImperiumPipelineAkte].self) ?? []
}

func speichern() { ImperiumDisk.save(akten, key: key) }

func neu(titel: String, mandant: String, rechtsgebiet: String, praxis: ImperiumPraxisTyp) {
  let a = ImperiumPipelineAkte(
    id: UUID().uuidString,
    fallId: nil,
    titel: titel,
    mandant: mandant,
    stufe: .lead,
    rechtsgebiet: rechtsgebiet,
    notiz: "",
    erstellt: .now,
    geaendert: .now,
    praxis: praxis
  )
  akten.insert(a, at: 0)
  speichern()
  ImperiumEntscheidungsJournal.shared.eintrag(
    typ: .prozess,
    titel: "Pipeline: \(titel)",
    detail: "Lead erfasst · \(mandant)",
    module: ["Pipeline", "Lexara"]
  )
}

func setzeStufe(_ id: String, _ stufe: ImperiumPipelineStufe) {
  guard let i = akten.firstIndex(where: { $0.id == id }) else { return }
  // Juristische Gate: Aktiv erst nach Mandatsannahme-Freigabe oder expliziter Annahme-Stufe
  if stufe == .aktiv {
    let titel = akten[i].titel
    let mandant = akten[i].mandant
    let freigegeben = ImperiumMandatsAnnahmeStore.shared.akten.contains {
      $0.istFreigegeben && (
       $0.titel.caseInsensitiveCompare(titel) == .orderedSame
         || $0.mandant.caseInsensitiveCompare(mandant) == .orderedSame
     )
   }
   if !freigegeben && akten[i].stufe != .annahme {
     // Erzwinge Umweg über Annahme
     akten[i].stufe = .konflikt
     akten[i].notiz = (akten[i].notiz.isEmpty ? "" : akten[i].notiz + "\n")
       + "Blockiert: Aktiv erst nach Konfliktcheck + Mandatsannahme-Gate (Berufspflicht-Desk)."
     akten[i].geaendert = .now
     speichern()
     ImperiumEntscheidungsJournal.shared.eintrag(
       typ: .prozess,
       titel: "Pipeline-Gate: \(titel)",
       detail: "Aktiv ohne Annahme-Freigabe verhindert -- Berufspraxis/Gap Map 2026",
       module: ["Pipeline", "Berufspflicht"]
     )
     return
   }
 }
 akten[i].stufe = stufe
 akten[i].geaendert = .now
 speichern()
}

func verknuepfeFall(_ id: String, fallId: String) {
 guard let i = akten.firstIndex(where: { $0.id == id }) else { return }
 akten[i].fallId = fallId
 akten[i].geaendert = .now
 if akten[i].stufe == .lead { akten[i].stufe = .konflikt }
 speichern()
}

func loesche(_ id: String) {
 akten.removeAll { $0.id == id }
 speichern()
}
}

struct ImperiumMandatsPipelineView: View {
@State private var store = ImperiumPipelineStore.shared
@State private var praxis = ImperiumPraxisStore.shared
@State private var titel = ""
@State private var mandant = ""
@State private var gebiet = ""

var body: some View {
 VStack(spacing: 0) {
   HStack {
     VStack(alignment: .leading, spacing: 4) {
       Text("Mandats-Pipeline")
         .font(.system(size: 18, weight: .bold))
         .foregroundStyle(Premium.text)
       Text("Lead -> Konflikt -> Annahme -> Arbeit -> Abrechnung -- der Prozess, den DATEV/RA-MICRO nicht strategisch führen.")
         .font(.system(size: 11))
         .foregroundStyle(Premium.textSoft)
     }
     Spacer()
   }
   .padding(16)
   .background(Premium.ink)

   HStack(alignment: .top, spacing: 0) {
     VStack(alignment: .leading, spacing: 10) {
       Text("Neuer Lead").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
       TextField("Mandatstitel", text: $titel).textFieldStyle(.roundedBorder)
       TextField("Mandant", text: $mandant).textFieldStyle(.roundedBorder)
       TextField("Rechtsgebiet", text: $gebiet).textFieldStyle(.roundedBorder)
       Button("Lead anlegen") {
         store.neu(
           titel: titel.isEmpty ? "Neues Mandat" : titel,
           mandant: mandant.isEmpty ? "--" : mandant,
           rechtsgebiet: gebiet,
           praxis: praxis.aktiv
         )
         titel = ""; mandant = ""; gebiet = ""
       }
       .buttonStyle(.borderedProminent)
       .tint(Premium.action)
       .disabled(titel.trimmingCharacters(in: .whitespaces).isEmpty && mandant.isEmpty)
       Spacer()
     }
     .padding(14)
     .frame(width: 260)
     .background(Premium.ink)

     ScrollView(.horizontal) {
       HStack(alignment: .top, spacing: 12) {
         ForEach(ImperiumPipelineStufe.allCases) { stufe in
           VStack(alignment: .leading, spacing: 8) {
             Label(stufe.titel, systemImage: stufe.symbol)
               .font(.system(size: 11, weight: .semibold))
               .foregroundStyle(Premium.textSoft)
             let items = store.akten.filter { $0.stufe == stufe }
             if items.isEmpty {
               Text("--")
                 .foregroundStyle(Premium.textFaint)
                 .frame(maxWidth: .infinity)
                 .padding(.vertical, 24)
             }
             ForEach(items) { a in
               pipelineKarte(a)
             }
           }
           .padding(12)
           .frame(width: 220, alignment: .topLeading)
           .background(RoundedRectangle(cornerRadius: 10).fill(Premium.well))
         }
       }
       .padding(14)
     }
   }
 }
 .background(Premium.void)
 .fenlynineOSAdaptiveNavigationTitle("Mandats-Pipeline")
}

private func pipelineKarte(_ a: ImperiumPipelineAkte) -> some View {
 VStack(alignment: .leading, spacing: 6) {
   Text(a.titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
   Text(a.mandant).font(.system(size: 10)).foregroundStyle(Premium.textSoft)
   if !a.rechtsgebiet.isEmpty {
     Text(a.rechtsgebiet).font(.system(size: 9)).foregroundStyle(Premium.textFaint)
   }
   Menu("Stufe") {
     ForEach(ImperiumPipelineStufe.allCases) { s in
       Button(s.titel) { store.setzeStufe(a.id, s) }
     }
     Divider()
     Button("Löschen", role: .destructive) { store.loesche(a.id) }
   }
   .font(.system(size: 10))
 }
 .padding(10)
 .background(RoundedRectangle(cornerRadius: 8).fill(Premium.void))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
}
}

// MARK: - Honorare & Zeit

struct ImperiumZeitEintrag: Identifiable, Codable, Hashable {
var id: String
var fallLabel: String
var beschreibung: String
var minuten: Int
var satz: Double
var datum: Date
var abrechenbar: Bool
}

@MainActor
@Observable
final class ImperiumHonorarStore {
static let shared = ImperiumHonorarStore()
var eintraege: [ImperiumZeitEintrag] = []
var stundensatz: Double = 280
var streitwert: Double = 50_000
private let key = "imperium_honorar_v1"

private init() {
 if let snap = ImperiumDisk.load(key, as: Snap.self) {
   eintraege = snap.eintraege
   stundensatz = snap.stundensatz
   streitwert = snap.streitwert
 }
}

func speichern() {
 ImperiumDisk.save(Snap(eintraege: eintraege, stundensatz: stundensatz, streitwert: streitwert), key: key)
}

func add(fall: String, text: String, minuten: Int) {
 eintraege.insert(
   ImperiumZeitEintrag(
     id: UUID().uuidString,
     fallLabel: fall,
     beschreibung: text,
     minuten: minuten,
     satz: stundensatz,
     datum: .now,
     abrechenbar: true
   ),
   at: 0
 )
 speichern()
}

var summeEUR: Double {
 eintraege.filter(\.abrechenbar).reduce(0) { $0 + Double($1.minuten) / 60.0 * $1.satz }
}

/// Grobe RVG-Orientierung (VV RVG Gebührenrahmen -- Schätzung, keine Abrechnung)
func rvgSchaetzung() -> (streitwert: Double, gebuehr: Double, hinweis: String) {
 let sw = max(streitwert, 500)
 // Vereinfachte Wertgebühr nach § 13 RVG (Näherung)
 let geb: Double
 switch sw {
 case ..<500: geb = 45
 case ..<2000: geb = 80 + (sw - 500) * 0.02
 case ..<10000: geb = 140 + (sw - 2000) * 0.015
 case ..<50000: geb = 260 + (sw - 10000) * 0.008
 case ..<500000: geb = 580 + (sw - 50000) * 0.003
 default: geb = 2000 + (sw - 500000) * 0.001
 }
 let gerundet = (geb * 10).rounded() / 10
 return (streitwert: sw, gebuehr: gerundet, hinweis: "Näherung §13 RVG -- keine verbindliche Abrechnung. VV-Faktoren (0,3-2,5) separat.")
}

private struct Snap: Codable {
 var eintraege: [ImperiumZeitEintrag]
 var stundensatz: Double
 var streitwert: Double
}
}

struct ImperiumHonorareZeitView: View {
@State private var store = ImperiumHonorarStore.shared
@State private var fall = ""
@State private var text = ""
@State private var minuten = 30

var body: some View {
 HStack(spacing: 0) {
   VStack(alignment: .leading, spacing: 14) {
     Text("Zeit & Honorar")
       .font(.system(size: 18, weight: .bold))
       .foregroundStyle(Premium.text)
     Text("Zeiterfassung + RVG-Orientierung -- komplementär zu DATEV, nicht Ersatz der Buchhaltung.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)

     LabeledContent("Stundensatz €") {
       TextField("", value: $store.stundensatz, format: .number)
         .textFieldStyle(.roundedBorder)
         .frame(width: 100)
         .onChange(of: store.stundensatz) { _, _ in store.speichern() }
     }
     LabeledContent("Streitwert €") {
       TextField("", value: $store.streitwert, format: .number)
         .textFieldStyle(.roundedBorder)
         .frame(width: 120)
         .onChange(of: store.streitwert) { _, _ in store.speichern() }
     }

     let r = store.rvgSchaetzung()
     VStack(alignment: .leading, spacing: 6) {
       Text("RVG-Orientierung")
         .font(.system(size: 10, weight: .bold))
         .foregroundStyle(Premium.textFaint)
       Text(String(format: "ca. %.0f € Gebührenrahmen (1,0)", r.gebuehr))
         .font(.system(size: 22, weight: .bold, design: .rounded))
         .foregroundStyle(Premium.action)
       Text(r.hinweis)
         .font(.system(size: 10))
         .foregroundStyle(Premium.textSoft)
     }
     .padding(12)
     .background(RoundedRectangle(cornerRadius: 10).fill(Premium.well))

     Text("Zeitbuchen")
       .font(.system(size: 10, weight: .bold))
       .foregroundStyle(Premium.textFaint)
     TextField("Fall / Akte", text: $fall).textFieldStyle(.roundedBorder)
     TextField("Tätigkeit", text: $text).textFieldStyle(.roundedBorder)
     Stepper("\(minuten) Min.", value: $minuten, in: 5...480, step: 5)
     Button("Buchen") {
       store.add(fall: fall.isEmpty ? "Allgemein" : fall, text: text.isEmpty ? "Arbeit" : text, minuten: minuten)
       text = ""
     }
     .buttonStyle(.borderedProminent)
     .tint(Premium.action)

     Text(String(format: "Abrechenbar: %.2f €", store.summeEUR))
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(Premium.computed)
     Spacer()
   }
   .padding(16)
   .frame(width: 320)
   .background(Premium.ink)

   List {
     ForEach(store.eintraege) { e in
       HStack {
         VStack(alignment: .leading, spacing: 4) {
           Text(e.fallLabel).font(.system(size: 12, weight: .semibold))
           Text(e.beschreibung).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
           Text(e.datum.formatted(date: .abbreviated, time: .shortened))
             .font(.system(size: 9)).foregroundStyle(Premium.textFaint)
         }
         Spacer()
         Text("\(e.minuten) min")
           .font(.system(size: 12, design: .monospaced))
         Text(String(format: "%.0f €", Double(e.minuten) / 60.0 * e.satz))
           .font(.system(size: 12, weight: .semibold))
           .foregroundStyle(Premium.action)
           .frame(width: 64, alignment: .trailing)
       }
       .listRowBackground(Premium.void)
     }
     .onDelete { idx in
       store.eintraege.remove(atOffsets: idx)
       store.speichern()
     }
   }
   .scrollContentBackground(.hidden)
 }
 .background(Premium.void)
 .fenlynineOSAdaptiveNavigationTitle("Honorare & Zeit")
}
}

// MARK: - Entscheidungsjournal

enum ImperiumJournalTyp: String, Codable, CaseIterable {
case strategie, compliance, prozess, opportunisma, organon, system

var label: String {
 switch self {
 case .strategie: return "Strategie"
 case .compliance: return "Compliance"
 case .prozess: return "Prozess"
 case .opportunisma: return "Opportunisma"
 case .organon: return "Organon"
 case .system: return "System"
 }
}
}

struct ImperiumJournalEintrag: Identifiable, Codable, Hashable {
var id: String
var typ: ImperiumJournalTyp
var titel: String
var detail: String
var module: [String]
var datum: Date
}

@MainActor
@Observable
final class ImperiumEntscheidungsJournal {
static let shared = ImperiumEntscheidungsJournal()
var eintraege: [ImperiumJournalEintrag] = []
private let key = "imperium_journal_v1"

private init() {
 eintraege = ImperiumDisk.load(key, as: [ImperiumJournalEintrag].self) ?? []
}

func eintrag(typ: ImperiumJournalTyp, titel: String, detail: String, module: [String]) {
 let e = ImperiumJournalEintrag(
   id: UUID().uuidString,
   typ: typ,
   titel: titel,
   detail: detail,
   module: module,
   datum: .now
 )
 eintraege.insert(e, at: 0)
 if eintraege.count > 400 { eintraege = Array(eintraege.prefix(400)) }
 ImperiumDisk.save(eintraege, key: key)
}

func exportMarkdown() -> String {
 var md = "# Entscheidungsjournal -- FenlynineOS Legal Suite\n\n"
 for e in eintraege.prefix(100) {
   md += "## \(e.titel)\n"
   md += "_\(e.datum.formatted()) · \(e.typ.label)_\n\n"
   md += "\(e.detail)\n\n"
   md += "Module: \(e.module.joined(separator: ", "))\n\n---\n\n"
 }
 return md
}
}

struct ImperiumEntscheidungsJournalView: View {
@State private var journal = ImperiumEntscheidungsJournal.shared
@State private var filter: ImperiumJournalTyp? = nil
@State private var exportHinweis = ""

private var liste: [ImperiumJournalEintrag] {
 guard let f = filter else { return journal.eintraege }
 return journal.eintraege.filter { $0.typ == f }
}

var body: some View {
 VStack(spacing: 0) {
   HStack {
     VStack(alignment: .leading, spacing: 4) {
       Text("Entscheidungsjournal")
         .font(.system(size: 18, weight: .bold))
         .foregroundStyle(Premium.text)
       Text("Auditierbare Spur strategischer Entscheidungen -- Moat gegenüber reinen Aktenprogrammen.")
         .font(.system(size: 11))
         .foregroundStyle(Premium.textSoft)
     }
     Spacer()
     Picker("Filter", selection: $filter) {
       Text("Alle").tag(Optional<ImperiumJournalTyp>.none)
       ForEach(ImperiumJournalTyp.allCases, id: \.self) { t in
         Text(t.label).tag(Optional(t))
       }
     }
     .pickerStyle(.menu)
     Button("Markdown export") {
       let md = journal.exportMarkdown()
       NSPasteboard.general.clearContents()
       NSPasteboard.general.setString(md, forType: .string)
       exportHinweis = "In Zwischenablage kopiert"
     }
     .buttonStyle(.bordered)
   }
   .padding(16)
   .background(Premium.ink)

   if !exportHinweis.isEmpty {
     Text(exportHinweis).font(.caption).foregroundStyle(Premium.computed).padding(6)
   }

   List {
     ForEach(liste) { e in
       VStack(alignment: .leading, spacing: 6) {
         HStack {
           Text(e.typ.label.uppercased())
             .font(.system(size: 9, weight: .bold))
             .foregroundStyle(Premium.action)
           Spacer()
           Text(e.datum.formatted(date: .abbreviated, time: .shortened))
             .font(.system(size: 10))
             .foregroundStyle(Premium.textFaint)
         }
         Text(e.titel).font(.system(size: 13, weight: .semibold)).foregroundStyle(Premium.text)
         Text(e.detail).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
         Text(e.module.joined(separator: " · "))
           .font(.system(size: 9))
           .foregroundStyle(Premium.textFaint)
       }
       .padding(.vertical, 4)
       .listRowBackground(Premium.void)
     }
   }
   .scrollContentBackground(.hidden)
 }
 .background(Premium.void)
 .fenlynineOSAdaptiveNavigationTitle("Entscheidungsjournal")
}
}

// MARK: - beA / Gerichts-Kommunikation Checkliste

struct ImperiumBeACheckItem: Identifiable, Codable, Hashable {
var id: String
var titel: String
var detail: String
var erledigt: Bool
}

@MainActor
@Observable
final class ImperiumBeAStore {
static let shared = ImperiumBeAStore()
var items: [ImperiumBeACheckItem] = []
private let key = "imperium_bea_v1"

private init() {
 if let loaded = ImperiumDisk.load(key, as: [ImperiumBeACheckItem].self), !loaded.isEmpty {
   items = loaded
 } else {
   items = Self.defaults
   speichern()
 }
}

func speichern() { ImperiumDisk.save(items, key: key) }

func toggle(_ id: String) {
 guard let i = items.firstIndex(where: { $0.id == id }) else { return }
 items[i].erledigt.toggle()
 speichern()
}

private static let defaults: [ImperiumBeACheckItem] = [
 .init(id: "cert", titel: "beA-Zertifikat gültig", detail: "BRAK-Karte / Softwarezertifikat prüfen", erledigt: false),
 .init(id: "vertretung", titel: "Vertretungsregelung", detail: "Urlaub / Krankheit -- Postfach-Zugang", erledigt: false),
 .init(id: "empfang", titel: "Eingangsüberwachung", detail: "Tägliche Abholung dokumentiert", erledigt: false),
 .init(id: "versand", titel: "Versandprotokoll", detail: "Schriftsatz + Anlagen + Sendeprotokoll ablegen", erledigt: false),
 .init(id: "frist", titel: "Fristen aus Eingängen", detail: "Jeder Eingang -> Zeitleiste", erledigt: false),
 .init(id: "safe", titel: "Safe-Kommunikation", detail: "Keine Mandantengeheimnisse unverschlüsselt", erledigt: false),
 .init(id: "export", titel: "Export in Akte", detail: "PDF/A + Metadaten in Lexara Dokumente", erledigt: false)
]
}

struct ImperiumBeAChecklisteView: View {
@State private var store = ImperiumBeAStore.shared

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   VStack(alignment: .leading, spacing: 6) {
     Text("beA & Gerichts-Kommunikation")
       .font(.system(size: 18, weight: .bold))
       .foregroundStyle(Premium.text)
     Text("Keine Pseudo-beA-API -- dafür eine belastbare Kanzlei-Checkliste, die RA-MICRO integriert, aber selten strategisch führt. FenlynineOS Legal Suite steuert den Prozess drumherum.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
     ProgressView(value: Double(store.items.filter(\.erledigt).count), total: Double(max(store.items.count, 1)))
       .tint(Premium.action)
   }
   .padding(16)
   .frame(maxWidth: .infinity, alignment: .leading)
   .background(Premium.ink)

   List {
     ForEach(store.items) { item in
       Button {
         store.toggle(item.id)
       } label: {
         HStack(alignment: .top, spacing: 12) {
           Image(systemName: item.erledigt ? "checkmark.circle.fill" : "circle")
             .foregroundStyle(item.erledigt ? Premium.computed : Premium.textFaint)
           VStack(alignment: .leading, spacing: 4) {
             Text(item.titel)
               .font(.system(size: 13, weight: .semibold))
               .foregroundStyle(Premium.text)
               .strikethrough(item.erledigt)
             Text(item.detail)
               .font(.system(size: 11))
               .foregroundStyle(Premium.textSoft)
           }
           Spacer()
         }
       }
       .buttonStyle(.plain)
       .listRowBackground(Premium.void)
     }
   }
   .scrollContentBackground(.hidden)
 }
 .background(Premium.void)
 .fenlynineOSAdaptiveNavigationTitle("beA-Checkliste")
}
}

