import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Tab: Akteure & Fristen (2 Sub-Tabs, exakt wie Original)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct TabAkteureFristen: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var subTab = 0

var body: some View {
  VStack(spacing: 0) {
    Picker("", selection: $subTab) {
      Text("Personen & Beteiligte").tag(0)
      Text("Fristen & Termine").tag(1)
    }
    .pickerStyle(.segmented)
    .padding(.bottom, 16)

    if subTab == 0 {
      PersonenView(viewModel: viewModel, kiMode: kiMode)
    } else {
      FristenView(viewModel: viewModel, kiMode: kiMode)
    }
  }
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Personen-Verwaltung
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct PersonenView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var zeigeFormular = false
@State private var editiertPerson: Person? = nil
@State private var formDaten = PersonFormDaten()
@State private var speichert = false
@State private var personFehler: String?

var body: some View {
  VStack(spacing: 16) {
    if let err = personFehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }
    HStack {
      Label("Personen & Beteiligte", systemImage: "person.2.fill")
        .font(.title2.bold())
      Text("\(viewModel.personen.count) Personen")
        .font(.caption).foregroundStyle(.secondary)
      Spacer()
      Button {
        editiertPerson = nil
        formDaten = PersonFormDaten()
        zeigeFormular.toggle()
      } label: {
        Label("Person hinzufügen", systemImage: "person.badge.plus")
      }
      .buttonStyle(FenlynineOSGlassProminentButtonStyle())
      .controlSize(.small)
    }

    if zeigeFormular && editiertPerson == nil {
      PersonFormView(daten: $formDaten, onSpeichern: { await neuePersonSpeichern() }, onAbbrechen: { zeigeFormular = false })
    }

    if viewModel.personen.isEmpty && !zeigeFormular {
      InfoHinweis(titel: "Keine Personen erfasst", nachricht: "Fügen Sie Richter, Zeugen, Parteien, Sachverständige und andere Beteiligte hinzu.", symbol: "person.2")
    } else {
      ForEach(viewModel.personen) { person in
        PersonDetailKarte(
          person: person,
          bearbeiten: {
            editiertPerson = person
            formDaten = PersonFormDaten(from: person)
            zeigeFormular = true
          },
          loeschen: { Task { await personLoeschen(person) } }
        )
        if editiertPerson?.id == person.id && zeigeFormular {
          PersonFormView(
            daten: $formDaten,
            onSpeichern: { await personAktualisieren() },
            onAbbrechen: { zeigeFormular = false; editiertPerson = nil }
          )
          .transition(.opacity)
        }
      }
    }

    LexaraPersonenKIZusatzPanel(viewModel: viewModel, kiMode: kiMode)
  }
}

private func neuePersonSpeichern() async {
  speichert = true
  personFehler = nil
 let person = formDaten.toPerson(caseId: viewModel.caseId)
 do {
   let created = try await Services.persons.create(person)
   await MainActor.run {
     viewModel.personen.append(created)
     zeigeFormular = false
     formDaten = PersonFormDaten()
   }
 } catch {
   await MainActor.run { personFehler = error.localizedDescription }
 }
 speichert = false
}

private func personAktualisieren() async {
 guard let editId = editiertPerson?.id else { return }
 personFehler = nil
 let updated = formDaten.toPerson(caseId: viewModel.caseId)
 do {
   let saved = try await Services.persons.update(id: editId, entity: updated)
   await MainActor.run {
     if let idx = viewModel.personen.firstIndex(where: { $0.id == editId }) {
       viewModel.personen[idx] = saved
     }
     zeigeFormular = false
     editiertPerson = nil
   }
 } catch {
   await MainActor.run { personFehler = error.localizedDescription }
 }
}

private func personLoeschen(_ person: Person) async {
 guard let id = person.id else { return }
 try? await Services.persons.delete(id: id)
 await MainActor.run {
   viewModel.personen.removeAll { $0.id == id }
 }
}
}

// MARK: - Person Form Data

struct PersonFormDaten {
var name = ""
var rolle: Person.Rolle = .zeuge
var organisation = ""
var aussagen = 0
var widersprueche = 0
var glaubwuerdigkeit = 100.0
var klaeger_rate = 50.0
var vergleich_rate = 30.0
var dauer_monate = 12
var notizen = ""

init() {}

init(from p: Person) {
 name = p.name
 rolle = p.role
 organisation = p.organization ?? ""
 aussagen = p.aussagen ?? 0
 widersprueche = p.widersprueche ?? 0
 glaubwuerdigkeit = Double(p.glaubwuerdigkeit ?? 100)
 klaeger_rate = Double(p.klaeger_rate ?? 50)
 vergleich_rate = Double(p.vergleich_rate ?? 30)
 dauer_monate = p.dauer_monate ?? 12
 notizen = p.notizen ?? ""
}

func toPerson(caseId: String) -> Person {
 var p = Person(case_id: caseId, name: name)
 p.role = rolle
 p.organization = organisation.isEmpty ? nil : organisation
 p.aussagen = aussagen
 p.widersprueche = widersprueche
 p.glaubwuerdigkeit = Int(glaubwuerdigkeit)
 p.klaeger_rate = Int(klaeger_rate)
 p.vergleich_rate = Int(vergleich_rate)
 p.dauer_monate = dauer_monate
 p.notizen = notizen.isEmpty ? nil : notizen
 return p
}
}

struct PersonFormView: View {
@Binding var daten: PersonFormDaten
let onSpeichern: () async -> Void
let onAbbrechen: () -> Void
@State private var speichert = false

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
     VStack(alignment: .leading, spacing: 4) {
       Text("Name *").font(.caption).foregroundStyle(.secondary)
       TextField("Vollständiger Name", text: $daten.name)
         .textFieldStyle(.roundedBorder)
     }
     VStack(alignment: .leading, spacing: 4) {
       Text("Rolle").font(.caption).foregroundStyle(.secondary)
       Picker("Rolle", selection: $daten.rolle) {
         ForEach(Person.Rolle.allCases, id: \.self) {
           Text($0.rawValue).tag($0)
         }
       }
       .labelsHidden()
     }
   }

   VStack(alignment: .leading, spacing: 4) {
     Text("Organisation / Kanzlei").font(.caption).foregroundStyle(.secondary)
     TextField("Optional", text: $daten.organisation)
       .textFieldStyle(.roundedBorder)
   }

   // Statistiken (relevant für Richter/Zeugen)
   LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
     StatFeld(label: "Aussagen", wert: $daten.aussagen)
     StatFeld(label: "Widersprüche", wert: $daten.widersprueche)
     StatFeld(label: "Dauer (Monate)", wert: $daten.dauer_monate)
   }

   LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
     SliderFeld(label: "Glaubwürdigkeit %", wert: $daten.glaubwuerdigkeit, in: 0...100)
     SliderFeld(label: "Kläger-Rate %", wert: $daten.klaeger_rate, in: 0...100)
     SliderFeld(label: "Vergleichs-Rate %", wert: $daten.vergleich_rate, in: 0...100)
   }

   VStack(alignment: .leading, spacing: 4) {
     Text("Notizen").font(.caption).foregroundStyle(.secondary)
     TextField("Beobachtungen, Besonderheiten…", text: $daten.notizen, axis: .vertical)
       .lineLimit(2...4)
       .textFieldStyle(.roundedBorder)
   }

   HStack {
     Spacer()
     Button("Abbrechen", action: onAbbrechen).buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     Button(speichert ? "…" : "Speichern") {
       speichert = true
       Task { await onSpeichern(); speichert = false }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(daten.name.isEmpty || speichert)
   }
 }
 .padding(14)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.12), lineWidth: 1))
}
}

struct StatFeld: View {
let label: String
@Binding var wert: Int

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(label).font(.caption2).foregroundStyle(.secondary)
   TextField("0", value: $wert, format: .number)
     .textFieldStyle(.roundedBorder)
 }
}
}

struct SliderFeld: View {
let label: String
@Binding var wert: Double
let `in`: ClosedRange<Double>

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   Text("\(label): \(Int(wert))").font(.caption2).foregroundStyle(.secondary)
   Slider(value: $wert, in: self.in, step: 5)
 }
}
}

// MARK: - Person Detail Karte

struct PersonDetailKarte: View {
let person: Person
let bearbeiten: () -> Void
let loeschen: () -> Void
@State private var aufgeklappt = false

var rollefarbe: Color {
 switch person.role {
 case .richter: return .purple
 case .zeuge: return .blue
 case .sachverstaendiger: return .green
 case .partei: return .orange
 case .anwalt: return .gray
 case .gegner: return .red
 default:   return .teal
 }
}

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   HStack(spacing: 10) {
     Image(systemName: "person.fill")
       .font(.system(size: 13))
       .foregroundStyle(rollefarbe)
       .frame(width: 20)

     VStack(alignment: .leading, spacing: 2) {
       HStack(spacing: 6) {
         Text(person.role.rawValue)
           .font(.caption2.bold())
           .padding(.horizontal, 6).padding(.vertical, 2)
           .background(rollefarbe.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
           .foregroundStyle(rollefarbe)
         Text(person.name)
           .font(.system(size: 13, weight: .semibold))
       }
       if let org = person.organization, !org.isEmpty {
         Text(org).font(.caption2).foregroundStyle(.secondary)
       }
     }

     Spacer()

     // Kennzahlen
     if let krate = person.klaeger_rate, krate > 0 {
       VStack(spacing: 1) {
         Text("\(krate)%").font(.system(size: 11, weight: .bold)).foregroundStyle(.blue)
         Text("Kläger").font(.caption2).foregroundStyle(.secondary)
       }
     }
     if let vrate = person.vergleich_rate, vrate > 0 {
       VStack(spacing: 1) {
         Text("\(vrate)%").font(.system(size: 11, weight: .bold)).foregroundStyle(.green)
         Text("Vergleich").font(.caption2).foregroundStyle(.secondary)
       }
     }

     Button { withAnimation { aufgeklappt.toggle() } } label: {
       Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
         .font(.caption).foregroundStyle(.secondary)
     }
     .buttonStyle(.plain)

     Button { bearbeiten() } label: {
       Image(systemName: "pencil").font(.caption).foregroundStyle(.blue)
     }
     .buttonStyle(.plain)

     Button { loeschen() } label: {
       Image(systemName: "trash").font(.caption).foregroundStyle(.secondary)
     }
     .buttonStyle(.plain)
   }
   .padding(12)

   if aufgeklappt {
     Divider().padding(.horizontal, 12)
     VStack(alignment: .leading, spacing: 8) {
       LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
         if let v = person.aussagen { KennzahlPill(label: "Aussagen", wert: "\(v)") }
         if let v = person.widersprueche, v > 0 { KennzahlPill(label: "Widersprüche", wert: "\(v)", farbe: .red) }
         if let v = person.glaubwuerdigkeit { KennzahlPill(label: "Glaubw.", wert: "\(v)%", farbe: v >= 70 ? .green : v >= 40 ? .orange : .red) }
         if let v = person.dauer_monate { KennzahlPill(label: "Ø Dauer", wert: "\(v) Mo.") }
       }
       if let n = person.notizen, !n.isEmpty {
         Text(n).font(.system(size: 12)).foregroundStyle(.secondary)
       }
     }
     .padding(12)
   }
 }
 .background(.background, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(rollefarbe.opacity(0.15), lineWidth: 1))
}
}

struct KennzahlPill: View {
let label: String
let wert: String
var farbe: Color = .secondary

var body: some View {
 VStack(spacing: 2) {
   Text(wert).font(.system(size: 13, weight: .bold)).foregroundStyle(farbe)
   Text(label).font(.caption2).foregroundStyle(.secondary)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 6)
 .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Fristen-Verwaltung (mit KI-Fristenerkennung wie Original)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct FristenView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var zeigeFormular = false
@State private var zeigeReferenz = false
@State private var formDaten = FristFormDaten()
@State private var kiAnalyse = false
@State private var kiErgebnis: KIFristenErgebnis? = nil
@State private var speichert = false
@State private var fristFehler: String?

struct KIFristenErgebnis {
 var fristen: [KIFrist]
 var verfassungsverstoss: Bool
 var verfassungsBegruendung: String?
 var empfehlung: String?
}

struct KIFrist: Identifiable {
 let id = UUID()
 var titel: String
 var frist_type: String
 var paragraph: String
 var due_date: String
 var beschreibung: String?
 var prioritaet: String?
 var verfassungsrelevanz: Bool
}

private let fristTypen = [
 "Berufungsfrist","Berufungsbegründung","Revisionsfrist","Klagebegründung",
 "Schriftsatzfrist","Widerspruch Mahnbescheid","Einspruch Versäumnisurteil",
 "eV-Antragsfrist","Verjährungsfrist","Klagefrist KSchG","BR-Anzeige §102 BetrVG",
 "Vollstreckungsfristen","Sonstige"
]

private let referenzDaten: [(String, String, String, String)] = [
 ("Berufungsfrist","§517 ZPO","1 Monat","~60-100%"),
 ("Berufungsbegründung","§520 ZPO","2 Monate","~40-70%"),
 ("Revisionsfrist","§548 ZPO","1 Monat","~100%"),
 ("Klagebegründung","§276 ZPO","Richterlich","~20-50%"),
 ("Widerspruch Mahnbescheid","§694 ZPO","2 Wochen","~80-100%"),
 ("Einspruch Versäumnisurteil","§339 ZPO","2 Wochen","~90-100%"),
 ("Verjährungsfrist","§§195ff. BGB","3 Jahre","~100%"),
 ("Klagefrist KSchG","§4 KSchG","3 Wochen","~100%"),
 ("BR-Anzeige §102 BetrVG","§102 BetrVG","1 Woche","+40%"),
]

var body: some View {
 VStack(spacing: 16) {
   if let err = fristFehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }
   // Header
   HStack {
     Label("Fristenmanagement", systemImage: "clock.badge.exclamationmark")
       .font(.title2.bold())
     Spacer()
     Button {
       Task { await kiFristenErkennen() }
     } label: {
       if kiAnalyse {
         ProgressView().scaleEffect(0.7)
         Text("KI analysiert…").font(.caption)
       } else {
         Label("KI-Fristen erkennen", systemImage: "wand.and.stars.inverse")
       }
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     .controlSize(.small)
     .disabled(kiAnalyse || !kiMode)

     Button {
       formDaten = FristFormDaten()
       zeigeFormular.toggle()
     } label: {
       Label("Frist", systemImage: "plus")
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .controlSize(.small)
   }

   // Farblegende
   HStack(spacing: 12) {
     ForEach([("green", "> 14 Tage"), ("orange", "3-14 Tage"), ("red", "< 3 Tage!"), ("gray", "Versäumt")], id: \.1) { farbe, text in
       HStack(spacing: 4) {
         Circle().fill(Color(farbe)).frame(width: 8, height: 8)
         Text(text).font(.caption2).foregroundStyle(.secondary)
       }
     }
     Spacer()
   }

   // Formular
   if zeigeFormular {
     FristFormView(daten: $formDaten, fristTypen: fristTypen, onSpeichern: { await fristSpeichern() }, onAbbrechen: { zeigeFormular = false })
   }

   // KI-Ergebnis
   if let ki = kiErgebnis {
     KIFristenErgebnisView(
       ergebnis: ki,
       onImport: { frist in Task { await kiFristImportieren(frist) } },
       onImportAlle: { Task { await alleKIFristenImportieren(ki.fristen) } },
       onSchliessen: { kiErgebnis = nil }
     )
   }

   // Fristen-Liste
   let offene = viewModel.fristen.filter { $0.status == .offen }.sorted { $0.due_date < $1.due_date }
   let erledigte = viewModel.fristen.filter { $0.status == .erledigt }
   let versaeumte = viewModel.fristen.filter { $0.status == .versaeumt }

   if viewModel.fristen.isEmpty && !zeigeFormular {
     InfoHinweis(titel: "Keine Fristen erfasst", nachricht: "Nutzen Sie die KI-Fristenerkennung oder fügen Sie Fristen manuell hinzu.", symbol: "clock")
   } else {
     // Offene Fristen
     if !offene.isEmpty {
       VStack(alignment: .leading, spacing: 6) {
         Text("Offen (\(offene.count))")
           .font(.system(size: 12, weight: .semibold))
           .foregroundStyle(.secondary)
         ForEach(offene) { frist in
           FristKarte(frist: frist, onStatus: { status in
             Task { await fristStatusAendern(frist, status: status) }
           }, onLoeschen: { Task { await fristLoeschen(frist) } })
         }
       }
     }

     // Fristen-Zeitleiste
     if !viewModel.fristen.isEmpty {
       FristenZeitleiste(fristen: viewModel.fristen.sorted { $0.due_date < $1.due_date })
     }

     // Erledigte
     if !erledigte.isEmpty {
       DisclosureGroup("Erledigt (\(erledigte.count))") {
         ForEach(erledigte) { frist in
           FristKarte(frist: frist, onStatus: { status in
             Task { await fristStatusAendern(frist, status: status) }
           }, onLoeschen: { Task { await fristLoeschen(frist) } })
         }
       }
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(.secondary)
     }

     // Versäumte
     if !versaeumte.isEmpty {
       DisclosureGroup("Versäumt (\(versaeumte.count))") {
         ForEach(versaeumte) { frist in
           FristKarte(frist: frist, onStatus: { status in
             Task { await fristStatusAendern(frist, status: status) }
           }, onLoeschen: { Task { await fristLoeschen(frist) } })
         }
       }
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(.red)
     }
   }

   // Referenz-Tabelle
   FristenReferenzView(daten: referenzDaten, expanded: $zeigeReferenz)
 }
}

// MARK: - Aktionen

private func fristSpeichern() async {
 speichert = true
 fristFehler = nil
 let frist = formDaten.toDeadline(caseId: viewModel.caseId)
 do {
   let created = try await Services.deadlines.create(frist)
   await MainActor.run {
     viewModel.fristen.append(created)
     zeigeFormular = false
     formDaten = FristFormDaten()
   }
 } catch {
   await MainActor.run { fristFehler = error.localizedDescription }
 }
 speichert = false
}

private func fristStatusAendern(_ frist: Deadline, status: Deadline.FristStatus) async {
 guard let id = frist.id else { return }
 var updated = frist
 updated.status = status
 if let saved = try? await Services.deadlines.update(id: id, entity: updated) {
   await MainActor.run {
     if let idx = viewModel.fristen.firstIndex(where: { $0.id == id }) {
       viewModel.fristen[idx] = saved
     }
   }
 }
}

private func fristLoeschen(_ frist: Deadline) async {
 guard let id = frist.id else { return }
 try? await Services.deadlines.delete(id: id)
 await MainActor.run { viewModel.fristen.removeAll { $0.id == id } }
}

private func kiFristImportieren(_ kiFrist: KIFrist) async {
 var frist = Deadline(case_id: viewModel.caseId, title: kiFrist.titel, due_date: ISO8601DateFormatter().date(from: kiFrist.due_date) ?? Date())
 frist.frist_type = .sonstige
 frist.paragraph = kiFrist.paragraph.isEmpty ? nil : kiFrist.paragraph
 do {
   let created = try await Services.deadlines.create(frist)
   await MainActor.run { viewModel.fristen.append(created) }
 } catch {
   await MainActor.run { fristFehler = error.localizedDescription }
 }
}

private func alleKIFristenImportieren(_ fristen: [KIFrist]) async {
 for f in fristen { await kiFristImportieren(f) }
 await MainActor.run { kiErgebnis = nil }
}

private func kiFristenErkennen() async {
 guard let fall = viewModel.fall else { return }
 kiAnalyse = true
 fristFehler = nil
 defer { kiAnalyse = false }

 let heute = ISO8601DateFormatter().string(from: Date()).prefix(10)
 let dokSummaries = viewModel.dokumente.compactMap(\.ai_summary).prefix(3).joined(separator: "\n")
 let argTitel = viewModel.argumente.prefix(10).map { $0.title }.joined(separator: "; ")

 let prompt = """
 Du bist ein erfahrener Rechtsanwalt in Deutschland. Analysiere den folgenden Sachverhalt und erkenne ALLE relevanten Fristen:

 FALL: \(fall.fallname)
 Rechtsgebiet: \(fall.rechtsgebiet ?? "unbekannt")
 Instanz: \(fall.instanz.rawValue)
 Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
 Prozessziel: \(fall.prozessziel ?? "")
 Argumente: \(argTitel)
 Dokumenteninhalt: \(dokSummaries)
 Heute: \(heute)

 Erkenne alle relevanten Fristen:
 - Rechtsmittelfristen (Berufung §517 ZPO, Revision §548 ZPO, Einspruch §339 ZPO)
 - Verjährungsfristen (§§195ff. BGB)
 - Verwaltungsrechtliche Fristen (Widerspruch, Anfechtungsklage)
 - Verfassungsbeschwerde (§93 BVerfGG: 1 Monat)
 - Spezifische Fristen je nach Rechtsgebiet

 Prüfe auch: Liegen Grundrechtsverletzungen vor (Art. 1, 2, 13, 103, 104 GG)?
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "fristen": ["type": "array", "items": [
           "type": "object", "properties": [
             "title": ["type": "string"],
             "frist_type": ["type": "string"],
             "paragraph": ["type": "string"],
             "due_date": ["type": "string"],
             "beschreibung": ["type": "string"],
             "prioritaet": ["type": "string"],
             "verfassungsrelevanz": ["type": "boolean"]
           ]
         ] as [String: Any]],
         "verfassungsverstoss_erkannt": ["type": "boolean"],
         "verfassungsverstoss_begruendung": ["type": "string"],
         "empfehlung": ["type": "string"]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6",
     logCaseId: viewModel.caseId,
     logKiName: "KI-Fristenerkennung"
   )

   let dict = try KIJson.requireObject(result, kontext: "Fristenerkennung")
   let fristenArr = dict["fristen"] as? [[String: Any]] ?? []
   let kiFristen = fristenArr.map { f in
     KIFrist(
       titel: f["title"] as? String ?? "",
       frist_type: f["frist_type"] as? String ?? "Sonstige",
       paragraph: f["paragraph"] as? String ?? "",
       due_date: f["due_date"] as? String ?? "",
       beschreibung: f["beschreibung"] as? String,
       prioritaet: f["prioritaet"] as? String,
       verfassungsrelevanz: f["verfassungsrelevanz"] as? Bool ?? false
     )
   }.filter { !$0.titel.isEmpty }

   await MainActor.run {
     kiErgebnis = KIFristenErgebnis(
       fristen: kiFristen,
       verfassungsverstoss: dict["verfassungsverstoss_erkannt"] as? Bool ?? false,
       verfassungsBegruendung: dict["verfassungsverstoss_begruendung"] as? String,
       empfehlung: dict["empfehlung"] as? String
     )
   }
 } catch {
   await MainActor.run { fristFehler = error.localizedDescription }
 }
}
}

// MARK: - Frist Formular Daten

struct FristFormDaten {
var titel = ""
var typ: Deadline.FristTyp = .sonstige
var paragraph = ""
var faelligkeitsDatum = Date().addingTimeInterval(60 * 60 * 24 * 30)
var verantwortlich = ""
var seite = "Eigene"

func toDeadline(caseId: String) -> Deadline {
 var d = Deadline(case_id: caseId, title: titel, due_date: faelligkeitsDatum)
 d.frist_type = typ
 d.paragraph = paragraph.isEmpty ? nil : paragraph
 return d
}
}

struct FristFormView: View {
@Binding var daten: FristFormDaten
let fristTypen: [String]
let onSpeichern: () async -> Void
let onAbbrechen: () -> Void
@State private var speichert = false

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
     VStack(alignment: .leading, spacing: 4) {
       Text("Titel *").font(.caption).foregroundStyle(.secondary)
       TextField("Fristbezeichnung", text: $daten.titel)
         .textFieldStyle(.roundedBorder)
     }
     VStack(alignment: .leading, spacing: 4) {
       Text("Fristtyp").font(.caption).foregroundStyle(.secondary)
       Picker("Typ", selection: $daten.typ) {
         ForEach(Deadline.FristTyp.allCases, id: \.self) {
           Text($0.rawValue).tag($0)
         }
       }
       .labelsHidden()
     }
   }

   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
     VStack(alignment: .leading, spacing: 4) {
       Text("Paragraph (§)").font(.caption).foregroundStyle(.secondary)
       TextField("z.B. § 517 ZPO", text: $daten.paragraph)
         .textFieldStyle(.roundedBorder)
     }
     VStack(alignment: .leading, spacing: 4) {
       Text("Fälligkeitsdatum *").font(.caption).foregroundStyle(.secondary)
       DatePicker("", selection: $daten.faelligkeitsDatum, displayedComponents: .date)
         .labelsHidden()
     }
   }

   VStack(alignment: .leading, spacing: 4) {
     Text("Verantwortlich").font(.caption).foregroundStyle(.secondary)
     TextField("Name oder Abteilung", text: $daten.verantwortlich)
       .textFieldStyle(.roundedBorder)
   }

   HStack {
     Spacer()
     Button("Abbrechen", action: onAbbrechen).buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     Button(speichert ? "…" : "Frist speichern") {
       speichert = true
       Task { await onSpeichern(); speichert = false }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(daten.titel.isEmpty || speichert)
   }
 }
 .padding(14)
 .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.12), lineWidth: 1))
}
}

// MARK: - Frist Karte

struct FristKarte: View {
let frist: Deadline
let onStatus: (Deadline.FristStatus) -> Void
let onLoeschen: () -> Void

private var tageVerbleibend: Int {
 Calendar.current.dateComponents([.day], from: Date(), to: frist.due_date).day ?? 0
}

private var ampelfarbe: Color {
 if frist.status == .versaeumt { return .gray }
 if frist.status == .erledigt { return .green }
 if tageVerbleibend < 0 { return .red }
 if tageVerbleibend < 3 { return .red }
 if tageVerbleibend < 14 { return .orange }
 return .green
}

var body: some View {
 HStack(spacing: 12) {
   // Ampel-Punkt
   Circle()
     .fill(ampelfarbe)
     .frame(width: 10, height: 10)
     .padding(.top, 2)

   VStack(alignment: .leading, spacing: 3) {
     HStack(spacing: 6) {
       Text(frist.title)
         .font(.system(size: 13, weight: .medium))
       if let para = frist.paragraph, !para.isEmpty {
         Text(para).font(.caption2).foregroundStyle(.blue)
       }
       Spacer()
       Text(frist.due_date.formatted(date: .abbreviated, time: .omitted))
         .font(.caption).foregroundStyle(.secondary)
     }
     HStack(spacing: 8) {
       Text(frist.frist_type.rawValue)
         .font(.caption2).foregroundStyle(.secondary)
       if frist.status == .offen {
         if tageVerbleibend < 0 {
           Text("Überfällig!")
             .font(.caption2.bold()).foregroundStyle(.red)
         } else {
           Text("\(tageVerbleibend) Tage")
             .font(.caption2.bold()).foregroundStyle(ampelfarbe)
         }
       }
     }
   }

   // Aktionen
   if frist.status != .erledigt {
     Button {
       onStatus(.erledigt)
     } label: {
       Label("Erledigt", systemImage: "checkmark.circle.fill")
         .font(.system(size: 11))
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     .controlSize(.mini)
     .tint(.green)
   }

   if frist.status == .offen {
     Button {
       onStatus(.versaeumt)
     } label: {
       Image(systemName: "xmark.circle")
         .font(.caption)
     }
     .buttonStyle(.plain)
     .foregroundStyle(.red.opacity(0.7))
   }

   Button { onLoeschen() } label: {
     Image(systemName: "trash").font(.caption).foregroundStyle(.secondary)
   }
   .buttonStyle(.plain)
 }
 .padding(.vertical, 8)
 .padding(.horizontal, 12)
 .background(.background, in: RoundedRectangle(cornerRadius: 8))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(ampelfarbe.opacity(0.2), lineWidth: 1))
}
}

// MARK: - Fristen Zeitleiste

struct FristenZeitleiste: View {
let fristen: [Deadline]

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Label("Fristen-Zeitleiste", systemImage: "calendar")
     .font(.system(size: 12, weight: .semibold))
     .foregroundStyle(.secondary)

   ScrollView(.horizontal, showsIndicators: false) {
     HStack(alignment: .top, spacing: 0) {
       ForEach(fristen) { frist in
         let tage = Calendar.current.dateComponents([.day], from: Date(), to: frist.due_date).day ?? 0
         let farbe: Color = frist.status == .erledigt ? .green : frist.status == .versaeumt ? .gray : tage < 0 ? .red : tage < 14 ? .orange : .blue

         VStack(spacing: 4) {
           Text(frist.due_date.formatted(.dateTime.day().month(.abbreviated)))
             .font(.system(size: 9))
             .foregroundStyle(.secondary)
           Circle().fill(farbe).frame(width: 10, height: 10)
           Text(frist.title)
             .font(.system(size: 9))
             .lineLimit(2)
             .multilineTextAlignment(.center)
             .frame(width: 60)
             .foregroundStyle(farbe)
         }
         .frame(width: 70)

         if frist.id != fristen.last?.id {
           Rectangle()
             .fill(Color.gray.opacity(0.2))
             .frame(width: 10, height: 1)
             .padding(.top, 20)
         }
       }
     }
     .padding(.vertical, 4)
   }
 }
 .padding(10)
 .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}
}

// MARK: - KI Fristen Ergebnis

struct KIFristenErgebnisView: View {
let ergebnis: FristenView.KIFristenErgebnis
let onImport: (FristenView.KIFrist) -> Void
let onImportAlle: () -> Void
let onSchliessen: () -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack {
     Label("KI-Fristenerkennung -- \(ergebnis.fristen.count) Fristen erkannt", systemImage: "wand.and.stars")
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(.purple)
     Spacer()
     Button { onSchliessen() } label: {
       Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
     }
     .buttonStyle(.plain)
   }

   // Verfassungsverstoß-Warnung
   if ergebnis.verfassungsverstoss, let begruendung = ergebnis.verfassungsBegruendung {
     HStack(alignment: .top, spacing: 8) {
       Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
       VStack(alignment: .leading, spacing: 2) {
         Text("Verfassungsverstoß erkannt!").font(.caption.bold()).foregroundStyle(.red)
         Text(begruendung).font(.caption)
       }
     }
     .padding(10)
     .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
   }

   // KI-Empfehlung
   if let empf = ergebnis.empfehlung, !empf.isEmpty {
     HStack(alignment: .top, spacing: 6) {
       Image(systemName: "lightbulb.fill").foregroundStyle(.yellow).font(.caption)
       Text(empf).font(.caption)
     }
   }

   // Fristen-Liste
   ForEach(ergebnis.fristen) { f in
     HStack(spacing: 10) {
       VStack(alignment: .leading, spacing: 2) {
         HStack(spacing: 6) {
           if f.verfassungsrelevanz {
             Text("VERFASSUNG").font(.system(size: 9, weight: .bold))
               .padding(.horizontal, 4).padding(.vertical, 1)
               .background(Color.red, in: RoundedRectangle(cornerRadius: 3))
               .foregroundStyle(.white)
           }
           if f.prioritaet == "kritisch" {
             Text("KRITISCH").font(.system(size: 9, weight: .bold))
               .padding(.horizontal, 4).padding(.vertical, 1)
               .background(Color.orange, in: RoundedRectangle(cornerRadius: 3))
               .foregroundStyle(.white)
           }
           Text(f.titel).font(.system(size: 12, weight: .medium))
         }
         HStack(spacing: 6) {
           if !f.paragraph.isEmpty {
             Text(f.paragraph).font(.caption2).foregroundStyle(.blue)
           }
           if !f.due_date.isEmpty {
             Text("Fällig: \(f.due_date)").font(.caption2).foregroundStyle(.secondary)
           }
         }
         if let beschr = f.beschreibung, !beschr.isEmpty {
           Text(beschr).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
         }
       }
       Spacer()
       Button {
         onImport(f)
       } label: {
         Label("Import", systemImage: "plus.circle.fill")
           .font(.system(size: 11, weight: .semibold))
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       .controlSize(.mini)
       .tint(.purple)
     }
     .padding(8)
     .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
   }

   if !ergebnis.fristen.isEmpty {
     Button {
       onImportAlle()
     } label: {
       Label("Alle \(ergebnis.fristen.count) Fristen importieren", systemImage: "arrow.down.circle.fill")
         .font(.system(size: 12, weight: .semibold))
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .tint(.purple)
   }
 }
 .padding(14)
 .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.15), lineWidth: 1))
}
}

// MARK: - Fristen Referenz

struct FristenReferenzView: View {
let daten: [(String, String, String, String)]
@Binding var expanded: Bool

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   Button {
     withAnimation { expanded.toggle() }
   } label: {
     HStack {
       Image(systemName: "book.fill").foregroundStyle(.blue)
       Text("Fristentypen-Referenz").font(.caption.bold())
       Spacer()
       Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption2)
     }
     .foregroundStyle(.secondary)
     .padding(10)
   }
   .buttonStyle(.plain)

   if expanded {
     VStack(spacing: 0) {
       HStack {
         Text("Fristtyp").frame(maxWidth: .infinity, alignment: .leading)
         Text("Paragraph").frame(width: 80, alignment: .leading)
         Text("Dauer").frame(width: 70, alignment: .leading)
         Text("Prognoseabzug").frame(width: 80, alignment: .trailing)
       }
       .font(.caption2.bold())
       .foregroundStyle(.secondary)
       .padding(.horizontal, 10)
       .padding(.bottom, 4)

       ForEach(daten, id: \.0) { typ, para, dauer, prog in
         HStack {
           Text(typ).frame(maxWidth: .infinity, alignment: .leading)
           Text(para).frame(width: 80, alignment: .leading)
           Text(dauer).frame(width: 70, alignment: .leading)
           Text(prog).frame(width: 80, alignment: .trailing)
         }
         .font(.caption2)
         .padding(.horizontal, 10)
         .padding(.vertical, 4)
         .background(Color.gray.opacity(0.02), in: RoundedRectangle(cornerRadius: 4))
       }
     }
     .padding([.horizontal, .bottom], 10)
   }
 }
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
}
}

