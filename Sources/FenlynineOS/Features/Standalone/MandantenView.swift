import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MANDANTENPORTAL -- strukturiert · CRM-stark · Legal-USPs
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Orientiert an Clio / RA-MICRO / KanzleiPilot -- plus:
// · Mandate-Radar (Fristen + Prognose je Mandant)
// · Vertraulichkeitsstufen & Kanal-Präferenz
// · Portal-Zugang-Flag ohne Klartext-Secrets
// · Aktivitäts-Timeline & One-Click-Update
// · Mandant « Fälle verknüpfen
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct MandantenView: View {
@State private var mandanten: [Mandant] = []
@State private var faelle: [LegalCase] = []
@State private var aktivitaeten: [MandantAktivitaet] = []
@State private var selectedId: String?
@State private var suchtext = ""
@State private var filterStatus: Mandant.MandantStatus? = nil
@State private var zeigeNeu = false
@State private var zeigeBearbeiten = false
@State private var laden = false
@State private var fehler: String?
@State private var tab = 0

private var gefiltert: [Mandant] {
  mandanten.filter { m in
    let statusOK = filterStatus == nil || m.status == filterStatus
    let q = suchtext.trimmingCharacters(in: .whitespaces).lowercased()
    guard !q.isEmpty else { return statusOK }
    let hay = [m.anzeigename, m.firma, m.email, m.ort, m.tags?.joined(separator: " ")]
      .compactMap { $0?.lowercased() }
      .joined(separator: " ")
    return statusOK && hay.contains(q)
  }
  .sorted { ($0.letzteAktivitaet ?? .distantPast) > ($1.letzteAktivitaet ?? .distantPast) }
}

private var selected: Binding<Mandant>? {
  guard let id = selectedId,
     let idx = mandanten.firstIndex(where: { $0.id == id }) else { return nil }
  return $mandanten[idx]
}

var body: some View {
  NavigationSplitView {
    VStack(spacing: 0) {
      portalKopf
      filterLeiste
      List(gefiltert, selection: $selectedId) { m in
        MandantListenZeile(mandant: m, fallAnzahl: faelleFuer(m).count)
          .tag(m.id ?? "")
          .contextMenu {
            Button("Bearbeiten") {
              selectedId = m.id
              zeigeBearbeiten = true
            }
            Button("Löschen", role: .destructive) {
              Task { await loesche(m) }
            }
          }
      }
      .listStyle(.plain)
    }
    .navigationSplitViewColumnWidth(min: 280, ideal: 300)
    .toolbar {
      ToolbarItem {
        Button { zeigeNeu = true } label: { Image(systemName: "plus") }
          .help("Neuen Mandanten anlegen")
      }
    }
  } detail: {
    if let binding = selected {
      MandantDetailView(
        mandant: binding,
        faelle: faelleFuer(binding.wrappedValue),
        alleFaelle: faelle,
        aktivitaeten: aktivitaeten.filter { $0.mandant_id == binding.wrappedValue.id },
        onSave: { m in Task { await speichere(m) } },
        onAktivitaet: { a in Task { await addAktivitaet(a) } },
        onLinkCase: { cid in Task { await verknuepfeFall(mandantId: binding.wrappedValue.id, caseId: cid) } }
      )
    } else {
      MandantLeerzustand(onNeu: { zeigeNeu = true })
    }
  }
  .fenlynineOSAdaptiveNavigationTitle("Mandantenportal")
  .task { await ladenAlles() }
  .sheet(isPresented: $zeigeNeu) {
    MandantEditorSheet(mandant: nil) { neu in
      Task { await anlegen(neu) }
    }
  }
  .sheet(isPresented: $zeigeBearbeiten) {
    if let binding = selected {
      MandantEditorSheet(mandant: binding.wrappedValue) { upd in
        Task { await speichere(upd) }
      }
   }
 }
}

private var portalKopf: some View {
 VStack(alignment: .leading, spacing: 6) {
   Text("MANDANTENPORTAL")
     .font(.system(size: 11, weight: .bold))
     .foregroundStyle(Premium.action)
     .tracking(0.8)
   Text("\(mandanten.count) Mandanten · \(mandanten.filter { $0.status == .aktiv }.count) aktiv")
     .font(.system(size: 11))
     .foregroundStyle(Premium.textSoft)
   HStack(spacing: 8) {
     kpiChip("\(offeneFristenCount)", "Fristen")
     kpiChip("\(mandanten.filter { $0.risikostufe == .kritisch || $0.risikostufe == .erhoeht }.count)", "Risiko")
     kpiChip("\(mandanten.filter { $0.portalZugangAktiv }.count)", "Portal")
   }
 }
 .padding(12)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(Premium.ink)
}

private var filterLeiste: some View {
 VStack(spacing: 8) {
   HStack {
     Image(systemName: "magnifyingglass").foregroundStyle(Premium.textFaint)
     TextField("Name, Firma, E-Mail, Tag…", text: $suchtext)
       .textFieldStyle(.plain)
   }
   .padding(8)
   .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))

   ScrollView(.horizontal, showsIndicators: false) {
     HStack(spacing: 6) {
       filterChip("Alle", aktiv: filterStatus == nil) { filterStatus = nil }
       ForEach(Mandant.MandantStatus.allCases, id: \.self) { s in
         filterChip(s.rawValue, aktiv: filterStatus == s) {
           filterStatus = filterStatus == s ? nil : s
         }
       }
     }
   }
 }
 .padding(.horizontal, 10)
 .padding(.vertical, 8)
 .background(Premium.void)
}

private func filterChip(_ t: String, aktiv: Bool, action: @escaping () -> Void) -> some View {
 Button(action: action) {
   Text(t).premiumChip(active: aktiv)
 }
 .buttonStyle(.plain)
}

private func kpiChip(_ v: String, _ l: String) -> some View {
 VStack(spacing: 1) {
   Text(v).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(Premium.text)
   Text(l).font(.system(size: 9)).foregroundStyle(Premium.textFaint)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 6)
 .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
 .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.hairline, lineWidth: 1))
}

private func faelleFuer(_ m: Mandant) -> [LegalCase] {
 let ids = Set(m.caseIds ?? [])
 return faelle.filter { c in
   if let id = c.id, ids.contains(id) { return true }
   if let name = c.mandant_name {
     return name.caseInsensitiveCompare(m.anzeigename) == .orderedSame
       || (m.firma.map { name.localizedCaseInsensitiveContains($0) } ?? false)
   }
   return false
 }
}

private var offeneFristenCount: Int {
 // Approximation: aktive Mandanten mit verknüpften Fällen
 mandanten.filter { $0.status == .aktiv && !($0.caseIds ?? []).isEmpty }.count
}

// MARK: - Persistence

private func ladenAlles() async {
 laden = true
 defer { laden = false }
 do {
   async let m = Services.mandanten.list()
   async let c = Services.cases.list()
   async let a = Services.mandantAktivitaeten.list()
   mandanten = try await m
   faelle = try await c
   aktivitaeten = try await a
   if selectedId == nil { selectedId = mandanten.first?.id }
   // Migration: Mandanten aus Fallnamen erzeugen
   if mandanten.isEmpty {
     await migriereAusFaellen()
   }
 } catch {
   fehler = error.localizedDescription
 }
}

private func migriereAusFaellen() async {
 var gesehen = Set<String>()
 for f in faelle {
   guard let name = f.mandant_name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { continue }
   let key = name.lowercased()
   guard !gesehen.contains(key) else {
     // case anhängen
     continue
   }
   gesehen.insert(key)
   var m = Mandant(anzeigename: name)
   m.status = .aktiv
   if let cid = f.id { m.caseIds = [cid] }
   m.uspMerkmale = ["Aus Fall migriert", "Mandate-Radar"]
   if let created = try? await Services.mandanten.create(m) {
     mandanten.append(created)
   }
 }
}

private func anlegen(_ m: Mandant) async {
 do {
   var neu = m
   neu.letzteAktivitaet = .init()
   neu.uspMerkmale = (neu.uspMerkmale ?? []) + ["Mandate-Radar", "Fristen-Push", "Vertraulichkeitsstufe"]
   let created = try await Services.mandanten.create(neu)
   mandanten.insert(created, at: 0)
   selectedId = created.id
   if let id = created.id {
     _ = try? await Services.mandantAktivitaeten.create(
       MandantAktivitaet(mandant_id: id, typ: "portal", titel: "Mandant angelegt", autor: "System")
     )
     aktivitaeten = (try? await Services.mandantAktivitaeten.list()) ?? aktivitaeten
   }
 } catch {
   fehler = error.localizedDescription
 }
}

private func speichere(_ m: Mandant) async {
 guard let id = m.id else { return }
 do {
   var upd = m
   upd.letzteAktivitaet = .init()
   let saved = try await Services.mandanten.update(id: id, entity: upd)
   if let idx = mandanten.firstIndex(where: { $0.id == id }) {
     mandanten[idx] = saved
   }
 } catch {
   fehler = error.localizedDescription
 }
}

private func loesche(_ m: Mandant) async {
 guard let id = m.id else { return }
 do {
   try await Services.mandanten.delete(id: id)
   mandanten.removeAll { $0.id == id }
   if selectedId == id { selectedId = mandanten.first?.id }
 } catch {
   fehler = error.localizedDescription
 }
}

private func addAktivitaet(_ a: MandantAktivitaet) async {
 do {
   let created = try await Services.mandantAktivitaeten.create(a)
   aktivitaeten.insert(created, at: 0)
   if let idx = mandanten.firstIndex(where: { $0.id == a.mandant_id }) {
     mandanten[idx].letzteAktivitaet = .init()
     _ = try? await Services.mandanten.update(id: a.mandant_id, entity: mandanten[idx])
   }
 } catch {
   fehler = error.localizedDescription
 }
}

private func verknuepfeFall(mandantId: String?, caseId: String) async {
 guard let mandantId,
    let idx = mandanten.firstIndex(where: { $0.id == mandantId }) else { return }
 var m = mandanten[idx]
 var ids = m.caseIds ?? []
 if !ids.contains(caseId) { ids.append(caseId) }
 m.caseIds = ids
 await speichere(m)
}
}

// MARK: - Listenzeile

private struct MandantListenZeile: View {
let mandant: Mandant
let fallAnzahl: Int

var body: some View {
 HStack(spacing: 10) {
   ZStack {
     Circle().fill(Premium.action.opacity(0.15)).frame(width: 34, height: 34)
     Text(String(mandant.anzeigename.prefix(1)).uppercased())
       .font(.system(size: 13, weight: .bold))
       .foregroundStyle(Premium.action)
   }
   VStack(alignment: .leading, spacing: 2) {
     Text(mandant.anzeigename)
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(Premium.text)
       .lineLimit(1)
     HStack(spacing: 6) {
       Text(mandant.status.rawValue)
         .font(.system(size: 10, weight: .medium))
         .foregroundStyle(statusFarbe)
       if let firma = mandant.firma {
         Text(firma).font(.system(size: 10)).foregroundStyle(Premium.textFaint).lineLimit(1)
       }
     }
   }
   Spacer()
   VStack(alignment: .trailing, spacing: 2) {
     Text("\(fallAnzahl)")
       .font(.system(size: 12, weight: .bold, design: .monospaced))
       .foregroundStyle(Premium.text)
     Text("Fälle").font(.system(size: 9)).foregroundStyle(Premium.textFaint)
   }
 }
 .padding(.vertical, 3)
}

private var statusFarbe: Color {
 switch mandant.status {
 case .aktiv: return Premium.computed
 case .lead: return Premium.action
 case .ruhend: return Premium.proposed
 case .beendet: return Premium.mute
 }
}
}

private struct MandantLeerzustand: View {
let onNeu: () -> Void
var body: some View {
 VStack(spacing: 14) {
   Image(systemName: "person.crop.circle.badge.plus")
     .font(.system(size: 40))
     .foregroundStyle(Premium.action)
   Text("Mandantenportal")
     .font(.system(size: 20, weight: .semibold))
     .foregroundStyle(Premium.text)
   Text("Legen Sie Mandanten an, verknüpfen Sie Mandate, steuern Sie Updates und Vertraulichkeit -- ein Radar für die gesamte Mandantschaft.")
     .font(.system(size: 12))
     .foregroundStyle(Premium.textSoft)
     .multilineTextAlignment(.center)
     .frame(maxWidth: 420)
   Button("Ersten Mandanten anlegen", action: onNeu)
     .buttonStyle(.borderedProminent)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .background(Premium.void)
}
}

// MARK: - Detail

struct MandantDetailView: View {
@Binding var mandant: Mandant
let faelle: [LegalCase]
let alleFaelle: [LegalCase]
let aktivitaeten: [MandantAktivitaet]
let onSave: (Mandant) -> Void
let onAktivitaet: (MandantAktivitaet) -> Void
let onLinkCase: (String) -> Void

@State private var tab = 0
@State private var updateText = ""
@State private var updateEmail = ""
@State private var sende = false
@State private var hinweis: String?
@State private var linkCaseId = ""

var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 16) {
     header
     Picker("", selection: $tab) {
       Text("Übersicht").tag(0)
       Text("Mandate").tag(1)
       Text("Kommunikation").tag(2)
       Text("Timeline").tag(3)
       Text("Zugang").tag(4)
     }
     .pickerStyle(.segmented)

     switch tab {
     case 0: uebersicht
     case 1: mandate
     case 2: kommunikation
     case 3: timeline
     default: zugang
     }
   }
   .padding(20)
 }
 .background(Premium.void)
 .onAppear {
   updateEmail = mandant.email ?? ""
 }
}

private var header: some View {
 HStack(alignment: .top) {
   VStack(alignment: .leading, spacing: 6) {
     Text(mandant.anzeigename)
       .font(.system(size: 22, weight: .semibold))
       .foregroundStyle(Premium.text)
     HStack(spacing: 8) {
       badge(mandant.typ.rawValue, Premium.action)
       badge(mandant.status.rawValue, Premium.computed)
       badge(mandant.risikostufe.rawValue, mandant.risikostufe == .kritisch ? Premium.critical : Premium.proposed)
       badge(mandant.vertraulichkeit.rawValue, Premium.mute)
     }
     if let firma = mandant.firma {
       Text(firma).font(.system(size: 12)).foregroundStyle(Premium.textSoft)
     }
   }
   Spacer()
   Button("Speichern") { onSave(mandant) }
     .buttonStyle(.borderedProminent)
 }
}

private var uebersicht: some View {
 VStack(alignment: .leading, spacing: 12) {
   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
     statKarte("Mandate", "\(faelle.count)")
     statKarte("Ø Prognose", prognoseText)
     statKarte("Kanal", mandant.preferredChannel.rawValue)
   }
   card("Kontaktdaten") {
     formRow("E-Mail", $mandant.email.orEmpty)
     formRow("Telefon", $mandant.telefon.orEmpty)
     formRow("Mobil", $mandant.mobil.orEmpty)
     formRow("Adresse", $mandant.adresse.orEmpty)
     HStack {
       formRow("PLZ", $mandant.plz.orEmpty)
       formRow("Ort", $mandant.ort.orEmpty)
     }
   }
   card("USPs dieses Portals") {
     let usp = mandant.uspMerkmale ?? ["Mandate-Radar", "Fristen-Push", "Vertraulichkeitsstufe", "Kanal-Routing"]
     FlowChips(items: usp)
     Text("Anders als klassische Kanzlei-CRMs: Mandant, Mandate und Fristen in einem Radar -- mit Vertraulichkeitsstufen und Portal-Zugang ohne Secrets im Klartext.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   }
   card("Interne Notizen") {
     TextEditor(text: $mandant.notizen.orEmpty)
       .font(.system(size: 12))
       .frame(minHeight: 80)
       .foregroundStyle(Premium.text)
   }
 }
}

private var mandate: some View {
 VStack(alignment: .leading, spacing: 12) {
   card("Verknüpfte Mandate") {
     if faelle.isEmpty {
       Text("Noch keine Fälle verknüpft.").foregroundStyle(Premium.textFaint)
     } else {
       ForEach(faelle) { f in
         HStack {
           VStack(alignment: .leading, spacing: 2) {
             Text(f.fallname).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
             Text([f.aktenzeichen, f.rechtsgebiet, f.status.rawValue].compactMap { $0 }.joined(separator: " · "))
               .font(.system(size: 10)).foregroundStyle(Premium.textFaint)
           }
           Spacer()
           Text(f.prognose.map { "\(Int($0))%" } ?? "--")
             .font(.system(size: 12, weight: .bold, design: .monospaced))
             .foregroundStyle(Premium.action)
         }
         .padding(.vertical, 4)
       }
     }
   }
   card("Fall verknüpfen") {
     Picker("Fall", selection: $linkCaseId) {
       Text("-- wählen --").tag("")
       ForEach(alleFaelle.filter { c in !(mandant.caseIds ?? []).contains(c.id ?? "") }) { f in
         Text(f.fallname).tag(f.id ?? "")
       }
     }
     Button("Verknüpfen") {
       guard !linkCaseId.isEmpty else { return }
       onLinkCase(linkCaseId)
       linkCaseId = ""
     }
     .buttonStyle(.bordered)
   }
 }
}

private var kommunikation: some View {
 VStack(alignment: .leading, spacing: 12) {
   card("Mandanten-Update senden") {
     TextField("Empfänger-E-Mail", text: $updateEmail)
       .textFieldStyle(.roundedBorder)
     TextEditor(text: $updateText)
       .frame(minHeight: 100)
     HStack {
       Picker("Kanal", selection: $mandant.preferredChannel) {
         ForEach(Mandant.MandantKanal.allCases, id: \.self) { Text($0.rawValue).tag($0) }
       }
       Spacer()
       Button {
         Task { await sendeUpdate() }
       } label: {
         if sende { ProgressView() } else { Text("Update senden") }
       }
       .buttonStyle(.borderedProminent)
       .disabled(updateText.trimmingCharacters(in: .whitespaces).isEmpty || sende)
     }
     if let hinweis { Text(hinweis).font(.caption).foregroundStyle(Premium.computed) }
   }
 }
}

private var timeline: some View {
 VStack(alignment: .leading, spacing: 10) {
   card("Aktivität") {
     if aktivitaeten.isEmpty {
       Text("Noch keine Einträge.").foregroundStyle(Premium.textFaint)
     } else {
       ForEach(aktivitaeten.sorted(by: { $0.zeitpunkt > $1.zeitpunkt })) { a in
         HStack(alignment: .top, spacing: 10) {
           Circle().fill(Premium.action).frame(width: 6, height: 6).padding(.top, 5)
           VStack(alignment: .leading, spacing: 2) {
             Text(a.titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
             if let d = a.detail { Text(d).font(.system(size: 11)).foregroundStyle(Premium.textSoft) }
             Text(a.zeitpunkt.formatted(date: .abbreviated, time: .shortened))
               .font(.system(size: 10)).foregroundStyle(Premium.textFaint)
           }
         }
       }
     }
     Button("Notiz hinzufügen") {
       guard let id = mandant.id else { return }
       onAktivitaet(MandantAktivitaet(
         mandant_id: id,
         typ: "notiz",
         titel: "Interne Notiz",
         detail: mandant.notizen,
         autor: "Nutzer"
       ))
     }
     .buttonStyle(.bordered)
   }
 }
}

private var zugang: some View {
 VStack(alignment: .leading, spacing: 12) {
   card("Portal-Zugang") {
     Toggle("Portal-Zugang aktiv", isOn: $mandant.portalZugangAktiv)
     TextField("PIN-/Zugangshinweis (kein Klartext-Secret)", text: $mandant.portalPinHinweis.orEmpty)
       .textFieldStyle(.roundedBorder)
     Text("USP: Zugang wird als Flag geführt -- Secrets gehören in den Schlüsselbund / IdP, nicht in die Akte.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   }
   card("Steuerung") {
     Picker("Risiko", selection: $mandant.risikostufe) {
       ForEach(Mandant.MandantRisiko.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     Picker("Vertraulichkeit", selection: $mandant.vertraulichkeit) {
       ForEach(Mandant.MandantVertraulichkeit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     Picker("Status", selection: $mandant.status) {
       ForEach(Mandant.MandantStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     Button("Änderungen speichern") { onSave(mandant) }
       .buttonStyle(.borderedProminent)
   }
 }
}

private var prognoseText: String {
 let vals = faelle.compactMap(\.prognose)
 guard !vals.isEmpty else { return "--" }
 return "\(Int(vals.reduce(0, +) / Double(vals.count)))%"
}

private func sendeUpdate() async {
 sende = true
 defer { sende = false }
 let caseId = faelle.first?.id ?? ""
 do {
   if !caseId.isEmpty {
     try await FunctionService.shared.sendMandantUpdate(
       caseId: caseId,
       message: "An: \(updateEmail)\n\n\(updateText)"
     )
   }
   if let id = mandant.id {
     onAktivitaet(MandantAktivitaet(
       mandant_id: id,
       typ: "update",
       titel: "Update an \(updateEmail)",
       detail: updateText,
       case_id: caseId.isEmpty ? nil : caseId,
       autor: "Nutzer"
     ))
   }
   hinweis = "Update protokolliert" + (caseId.isEmpty ? " (lokal)" : " & versendet")
   updateText = ""
   onSave(mandant)
 } catch {
   hinweis = error.localizedDescription
 }
}

private func badge(_ t: String, _ c: Color) -> some View {
 Text(t)
   .font(.system(size: 10, weight: .semibold))
   .foregroundStyle(c)
   .padding(.horizontal, 8).padding(.vertical, 3)
   .background(Capsule().fill(c.opacity(0.12)))
}

private func statKarte(_ l: String, _ v: String) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(l.uppercased()).font(.system(size: 9, weight: .semibold)).foregroundStyle(Premium.textFaint)
   Text(v).font(.system(size: 18, weight: .semibold)).foregroundStyle(Premium.text)
 }
 .padding(12)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(RoundedRectangle(cornerRadius: 10).fill(Premium.panel))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Premium.hairline, lineWidth: 1))
}

private func card<Content: View>(_ titel: String, @ViewBuilder _ content: () -> Content) -> some View {
 VStack(alignment: .leading, spacing: 10) {
   Text(titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.textSoft)
   content()
 }
 .padding(14)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(RoundedRectangle(cornerRadius: 12).fill(Premium.panel))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Premium.hairline, lineWidth: 1))
}

private func formRow(_ label: String, _ text: Binding<String>) -> some View {
 VStack(alignment: .leading, spacing: 3) {
   Text(label).font(.system(size: 10)).foregroundStyle(Premium.textFaint)
   TextField(label, text: text)
     .textFieldStyle(.roundedBorder)
 }
}
}

private struct FlowChips: View {
let items: [String]
var body: some View {
 HStack {
   ForEach(items, id: \.self) { t in
     Text(t)
       .font(.system(size: 10, weight: .semibold))
       .foregroundStyle(Premium.action)
       .padding(.horizontal, 8).padding(.vertical, 4)
       .background(Capsule().fill(Premium.action.opacity(0.12)))
   }
 }
}
}

// MARK: - Editor

struct MandantEditorSheet: View {
let mandant: Mandant?
let onSave: (Mandant) -> Void
@Environment(\.dismiss) private var dismiss

@State private var draft: Mandant

init(mandant: Mandant?, onSave: @escaping (Mandant) -> Void) {
 self.mandant = mandant
 self.onSave = onSave
 _draft = State(initialValue: mandant ?? Mandant(anzeigename: ""))
}

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Text(mandant == nil ? "Neuer Mandant" : "Mandant bearbeiten")
       .font(.headline)
     Spacer()
     Button("Abbrechen") { dismiss() }
     Button("Speichern") {
       onSave(draft)
       dismiss()
     }
     .buttonStyle(.borderedProminent)
     .disabled(draft.anzeigename.trimmingCharacters(in: .whitespaces).isEmpty)
   }
   .padding()

   Form {
     TextField("Anzeigename *", text: $draft.anzeigename)
     TextField("Firma", text: $draft.firma.orEmpty)
     Picker("Typ", selection: $draft.typ) {
       ForEach(Mandant.MandantTyp.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     Picker("Status", selection: $draft.status) {
       ForEach(Mandant.MandantStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     TextField("E-Mail", text: $draft.email.orEmpty)
     TextField("Telefon", text: $draft.telefon.orEmpty)
     TextField("Ansprechpartner", text: $draft.ansprechpartner.orEmpty)
     Picker("Bevorzugter Kanal", selection: $draft.preferredChannel) {
       ForEach(Mandant.MandantKanal.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     Picker("Risiko", selection: $draft.risikostufe) {
       ForEach(Mandant.MandantRisiko.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
     Picker("Vertraulichkeit", selection: $draft.vertraulichkeit) {
       ForEach(Mandant.MandantVertraulichkeit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }
   }
   .formStyle(.grouped)
 }
 .frame(width: 520, height: 560)
}
}

// Needed so `$mandant.email.orEmpty` works with struct fields via Binding
private extension Binding where Value == String? {
var orEmpty: Binding<String> {
 Binding<String>(
   get: { wrappedValue ?? "" },
   set: { wrappedValue = $0.isEmpty ? nil : $0 }
 )
}
}

