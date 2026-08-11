import SwiftUI
import AppKit

// MARK: - Organon Ops: Skills · Bearbeiten · Verknüpfungen · Export

struct OrganonSkillsMatrixView: View {
@Bindable var vm: OrganonViewModel

var body: some View {
  VStack(alignment: .leading, spacing: 16) {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Skills-Matrix")
          .font(.title2.bold())
        Text("Abdeckung über Personen -- Staffing-Hebel für Mandate.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text("\(vm.skillMatrixZeilen.count) Skills · \(vm.personen.filter { !$0.istVakanz }.count) Personen")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 20)
    .padding(.top, 16)

    if vm.skillMatrixZeilen.isEmpty {
      ContentUnavailableView("Keine Skills", systemImage: "person.badge.plus", description: Text("Personenprofile mit Skills anreichern."))
    } else {
      ScrollView([.horizontal, .vertical]) {
        LazyVStack(alignment: .leading, spacing: 10) {
          ForEach(vm.skillMatrixZeilen, id: \.skill) { zeile in
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text(zeile.skill)
                  .font(.headline)
                Spacer()
                Text("\(zeile.personen.count) Personen")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              FlowLayout(spacing: 8) {
                ForEach(zeile.personen, id: \.0.id) { pair in
                  Button {
                    vm.zuKnotenFliegen(pair.0)
                  } label: {
                    HStack(spacing: 6) {
                      Text(pair.0.name)
                        .font(.caption.weight(.semibold))
                      Text(pair.1.bezeichnung)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FenlynineOSTheme.accent.opacity(0.15), in: Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FenlynineOSTheme.glassFill, in: RoundedRectangle(cornerRadius: 8))
                  }
                  .buttonStyle(.plain)
                }
              }
            }
            .padding(14)
            .background(FenlynineOSTheme.glassFill.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
          }
        }
        .padding(.bottom, 24)
      }
    }
  }
}
}

struct OrganonVerknuepfungenView: View {
@Bindable var vm: OrganonViewModel
@State private var cases: [LegalCase] = []
@State private var mandanten: [Mandant] = []

var body: some View {
  ScrollView {
    VStack(alignment: .leading, spacing: 20) {
      Text("Verknüpfungen")
        .font(.title2.bold())
      Text("Personen mit Vorgängen, Lexara-Fällen und Mandanten verbinden -- daraus wird Kapazität und Verantwortung.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      if let kn = vm.ausgewaehlterKnoten {
        verknuepfungFuer(kn)
      } else {
        ContentUnavailableView("Knoten wählen", systemImage: "link", description: Text("Auf der Karte eine Person auswählen."))
      }
    }
    .padding(24)
  }
  .task {
    cases = (try? await Services.cases.list()) ?? []
   mandanten = (try? await Services.mandanten.list()) ?? []
 }
}

@ViewBuilder
private func verknuepfungFuer(_ kn: OrganonKnoten) -> some View {
 FenlynineOSCard {
   VStack(alignment: .leading, spacing: 12) {
     Label(kn.name, systemImage: kn.typ.symbol)
       .font(.headline)
     Text(kn.rolle ?? kn.typ.bezeichnung)
       .font(.caption)
       .foregroundStyle(.secondary)

     Divider()

     Text("Vorgänge").font(.subheadline.bold())
     let vorgaenge = vm.verknuepfteVorgaenge(fuer: kn)
     if vorgaenge.isEmpty {
       Text("Keine Verknüpfung -- unten zuordnen.")
         .font(.caption)
         .foregroundStyle(.secondary)
     } else {
       ForEach(vorgaenge) { v in
         HStack {
           Text(v.kurzId).font(.caption.monospaced())
           Text(v.titel).font(.caption).lineLimit(1)
           Spacer()
         }
       }
     }
     Menu("Vorgang zuordnen") {
       ForEach(VorgangStore.shared.vorgaenge.prefix(40)) { v in
         Button(v.titel) { vm.verknuepfeVorgang(v.id, an: kn.id) }
       }
     }

     Divider()
     Text("Lexara-Fälle").font(.subheadline.bold())
     let linkedCases = cases.filter { (kn.caseIds ?? []).contains($0.id ?? "") }
     if linkedCases.isEmpty {
       Text("Keine Fälle verknüpft.")
         .font(.caption)
         .foregroundStyle(.secondary)
     } else {
       ForEach(linkedCases, id: \.id) { c in
         Text(c.fallname).font(.caption)
       }
     }
     Menu("Fall zuordnen") {
       ForEach(cases.prefix(40), id: \.id) { c in
         Button(c.fallname) {
           if let id = c.id { vm.verknuepfeCase(id, an: kn.id) }
         }
       }
     }

     Divider()
     Text("Mandanten").font(.subheadline.bold())
     Menu("Mandant zuordnen") {
       ForEach(mandanten.prefix(40), id: \.id) { m in
         Button(m.anzeigename) {
           if let id = m.id { vm.verknuepfeMandant(id, an: kn.id) }
         }
       }
     }
     if let ids = kn.mandantIds, !ids.isEmpty {
       Text("\(ids.count) Mandant(en) verknüpft")
         .font(.caption)
         .foregroundStyle(.secondary)
     }

     Button("Kapazität aus Last berechnen") {
       vm.aktualisiereKapazitaetAusLast(fuer: kn.id)
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
   }
   .frame(maxWidth: .infinity, alignment: .leading)
 }
}
}

struct OrganonEditorView: View {
@Bindable var vm: OrganonViewModel
@State private var draft: OrganonKnoten?
@State private var skillName = ""
@State private var skillLevel: OrganonSkillLevel = .praxis
@State private var kantenTyp: OrganonKantenTyp = .fachlich

var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 16) {
     HStack {
       Text("Bearbeiten")
         .font(.title2.bold())
       Spacer()
       Button("Abteilung +") { vm.neueAbteilung() }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       Button("Team +") { vm.neuesTeam(unter: nil) }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       Button("Person +") { vm.neuePerson(unter: vm.ausgewaehlterKnoten?.id) }
         .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     }

     if let kn = draft ?? vm.ausgewaehlterKnoten {
       // Klare Typkennzeichnung
       HStack(spacing: 8) {
         Image(systemName: kn.typ.symbol).foregroundStyle(kn.typ.farbe)
         Text(kn.istOrganisationseinheit ? "Organisationseinheit bearbeiten" : "Personenprofil bearbeiten")
           .font(.subheadline.weight(.semibold))
         Spacer()
         Text(kn.typ.kurz)
           .font(.caption.weight(.bold))
           .padding(.horizontal, 8).padding(.vertical, 4)
           .background(kn.typ.farbe.opacity(0.15), in: Capsule())
           .foregroundStyle(kn.typ.farbe)
       }
       editorForm(kn)
     } else {
       ContentUnavailableView("Nichts ausgewählt", systemImage: "pencil", description: Text("In der Hierarchie oder auf der Karte wählen."))
     }

     Divider()
     exportBlock
   }
   .padding(24)
 }
 .onChange(of: vm.ausgewaehlterKnoten?.id) { _, _ in
   draft = vm.ausgewaehlterKnoten
 }
 .onAppear { draft = vm.ausgewaehlterKnoten }
}

@ViewBuilder
private func editorForm(_ kn: OrganonKnoten) -> some View {
 let binding = Binding(
   get: { draft ?? kn },
   set: { draft = $0 }
 )

 FenlynineOSCard {
   VStack(alignment: .leading, spacing: 12) {
     TextField("Name", text: Binding(
       get: { binding.wrappedValue.name },
       set: { binding.wrappedValue.name = $0 }
     ))

     // Hierarchie-Zuordnung (für alle außer Gesellschaft)
     if kn.typ != .gesellschaft {
       VStack(alignment: .leading, spacing: 4) {
         Text("Übergeordnete Einheit").font(.caption.bold()).foregroundStyle(.secondary)
         Picker("Eltern", selection: Binding(
           get: { binding.wrappedValue.parentId ?? "" },
           set: { binding.wrappedValue.parentId = $0.isEmpty ? nil : $0 }
         )) {
           Text("-- nicht zugeordnet --").tag("")
           ForEach(moeglicheEltern(fuer: kn)) { eltern in
             Text("\(eltern.typ.kurz): \(eltern.name)").tag(eltern.id)
           }
         }
         Text(kn.istPerson
            ? "Personen hängen unter Team (Associates) oder direkt unter Abteilung (Partner)."
            : "Abteilungen unter Gesellschaft, Teams unter Abteilung.")
           .font(.caption2)
           .foregroundStyle(.tertiary)
       }
     }

     if kn.istOrganisationseinheit {
       // Nur Strukturfelder
       TextField("Kurzbeschreibung", text: Binding(
         get: { binding.wrappedValue.untertitel ?? "" },
         set: { binding.wrappedValue.untertitel = $0.isEmpty ? nil : $0 }
       ))
       TextField("Standort", text: Binding(
         get: { binding.wrappedValue.standort ?? "" },
         set: { binding.wrappedValue.standort = $0.isEmpty ? nil : $0 }
       ))
       TextField("Notizen zur Einheit", text: Binding(
         get: { binding.wrappedValue.notizen ?? "" },
         set: { binding.wrappedValue.notizen = $0.isEmpty ? nil : $0 }
       ), axis: .vertical)
       .lineLimit(2...4)
       Text("Berufsträger: \(binding.wrappedValue.mitarbeiterAnzahl ?? 0) (automatisch aus Hierarchie)")
         .font(.caption)
         .foregroundStyle(.secondary)
     } else {
       // Nur Personenfelder
       TextField("Rolle", text: Binding(
         get: { binding.wrappedValue.rolle ?? "" },
         set: { binding.wrappedValue.rolle = $0.isEmpty ? nil : $0 }
       ))
       TextField("Standort", text: Binding(
         get: { binding.wrappedValue.standort ?? "" },
         set: { binding.wrappedValue.standort = $0.isEmpty ? nil : $0 }
       ))
       TextField("E-Mail", text: Binding(
         get: { binding.wrappedValue.email ?? "" },
         set: { binding.wrappedValue.email = $0.isEmpty ? nil : $0 }
       ))
       TextField("Tätigkeitsclaim", text: Binding(
         get: { binding.wrappedValue.taetigkeitsclaim ?? "" },
         set: { binding.wrappedValue.taetigkeitsclaim = $0.isEmpty ? nil : $0 }
       ), axis: .vertical)
       .lineLimit(2...4)

       Picker("Kapazität", selection: Binding(
         get: { binding.wrappedValue.kapazitaet ?? .verfuegbar },
         set: { binding.wrappedValue.kapazitaet = $0 }
       )) {
         ForEach(OrganonKapazitaet.allCases, id: \.self) { Text($0.bezeichnung).tag($0) }
       }
       Toggle("Vakanz (offene Stelle)", isOn: Binding(
         get: { binding.wrappedValue.istVakanz },
         set: { binding.wrappedValue.istVakanz = $0 }
       ))

       TextField("Notizen", text: Binding(
         get: { binding.wrappedValue.notizen ?? "" },
         set: { binding.wrappedValue.notizen = $0.isEmpty ? nil : $0 }
       ), axis: .vertical)
       .lineLimit(3...6)

       TextField("Tags (Komma)", text: Binding(
         get: { (binding.wrappedValue.tags ?? []).joined(separator: ", ") },
         set: {
           binding.wrappedValue.tags = $0.split(separator: ",")
             .map { $0.trimmingCharacters(in: .whitespaces) }
             .filter { !$0.isEmpty }
         }
       ))

       Divider()
       Text("Skills").font(.subheadline.bold())
       HStack {
         TextField("Skill", text: $skillName)
         Picker("Level", selection: $skillLevel) {
           ForEach(OrganonSkillLevel.allCases, id: \.self) { Text($0.bezeichnung).tag($0) }
         }
         .frame(width: 120)
         Button("Hinzufügen") {
           guard !skillName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
           var kn2 = binding.wrappedValue
           var matrix = kn2.skillMatrix ?? []
           matrix.append(.init(name: skillName.trimmingCharacters(in: .whitespaces), level: skillLevel))
           kn2.skillMatrix = matrix
           kn2.skills = matrix.map(\.name)
           binding.wrappedValue = kn2
           skillName = ""
         }
       }
       FlowLayout(spacing: 6) {
         ForEach(binding.wrappedValue.skillMatrix ?? []) { s in
           Text("\(s.name) · \(s.level.bezeichnung)")
             .font(.caption2)
             .padding(.horizontal, 8)
             .padding(.vertical, 4)
             .background(Color.indigo.opacity(0.12), in: Capsule())
         }
       }

       Divider()
       Text("Fachliche Beziehungen (nicht Hierarchie)").font(.subheadline.bold())
       HStack {
         Picker("Typ", selection: $kantenTyp) {
           ForEach(OrganonKantenTyp.allCases.filter { $0 != .disziplinarisch }, id: \.self) {
             Text($0.bezeichnung).tag($0)
           }
         }
         Button(vm.neueKanteVonId == kn.id ? "Ziel auf Karte tippen…" : "Kante von hier") {
           vm.starteKantenModus(von: kn.id)
         }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       }
       Text("Berichtslinien entstehen automatisch aus der Hierarchie-Zuordnung.")
         .font(.caption2)
         .foregroundStyle(.tertiary)
     }

     HStack {
       Button("Speichern") {
         vm.speichereKnoten(binding.wrappedValue)
         draft = binding.wrappedValue
       }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
       Button("Löschen", role: .destructive) {
         vm.loescheAusgewaehlten()
         draft = nil
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     }
   }
   .frame(maxWidth: .infinity, alignment: .leading)
 }
}

private func moeglicheEltern(fuer kn: OrganonKnoten) -> [OrganonKnoten] {
 vm.knoten.filter {
   $0.id != kn.id && kn.typ.erlaubteElternTypen.contains($0.typ)
 }.sorted { $0.name < $1.name }
}

private var exportBlock: some View {
 FenlynineOSCard {
   VStack(alignment: .leading, spacing: 10) {
     Text("Export & Reset").font(.headline)
     HStack {
       Button("Markdown kopieren") { vm.kopiereExport("md") }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       Button("JSON kopieren") { vm.kopiereExport("json") }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       Button("Demo zurücksetzen", role: .destructive) { vm.resetDemo() }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     }
     if !vm.statusMeldung.isEmpty {
       Text(vm.statusMeldung).font(.caption).foregroundStyle(FenlynineOSTheme.success)
     }
   }
   .frame(maxWidth: .infinity, alignment: .leading)
 }
}
}

struct OrganonAuditView: View {
@Bindable var vm: OrganonViewModel

var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 16) {
     Text("Änderungsprotokoll")
       .font(.title2.bold())
     Text("Audit der Organisationsstruktur -- Betriebsrats-tauglich, keine Leistungsüberwachung.")
       .font(.subheadline)
       .foregroundStyle(.secondary)

     if vm.audit.isEmpty {
       Text("Noch keine Änderungen protokolliert.")
         .foregroundStyle(.secondary)
     } else {
       ForEach(vm.audit) { e in
         HStack(alignment: .top) {
           VStack(alignment: .leading, spacing: 2) {
             Text(e.aktion).font(.subheadline.bold())
             Text(e.detail).font(.caption).foregroundStyle(.secondary)
           }
           Spacer()
           Text(e.zeit.formatted(date: .abbreviated, time: .shortened))
             .font(.caption2)
             .foregroundStyle(.tertiary)
         }
         .padding(.vertical, 6)
         Divider()
       }
     }
   }
   .padding(24)
 }
}
}

struct OrganonKapazitaetView: View {
@Bindable var vm: OrganonViewModel

private var personen: [OrganonKnoten] {
 vm.personen.filter { !$0.istVakanz }
}

var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 16) {
     HStack {
       VStack(alignment: .leading, spacing: 4) {
         Text("Kapazitätsplanung")
           .font(.title2.bold())
         Text("Verfügbar · Ausgelastet · Abwesend -- Staffing gegen Mandate und Pipeline.")
           .font(.subheadline)
           .foregroundStyle(.secondary)
       }
       Spacer()
       Button("Aus Last aktualisieren") {
         for p in personen { vm.aktualisiereKapazitaetAusLast(fuer: p.id) }
       }
       .buttonStyle(.bordered)
     }

     HStack(spacing: 12) {
       kapTile("Verfügbar", personen.filter { ($0.kapazitaet ?? .verfuegbar) == .verfuegbar }.count, FenlynineOSTheme.success)
       kapTile("Ausgelastet", personen.filter { $0.kapazitaet == .ausgelastet }.count, FenlynineOSTheme.warning)
       kapTile("Abwesend", personen.filter { $0.kapazitaet == .abwesend }.count, FenlynineOSTheme.textSecondary)
     }

     ForEach(personen) { p in
       HStack {
         VStack(alignment: .leading, spacing: 2) {
           Text(p.name).font(.headline)
           Text(p.rolle ?? p.untertitel ?? "--")
             .font(.caption)
             .foregroundStyle(.secondary)
           Text("Last: \(p.vorgangIds?.count ?? 0) Vorgänge · \(p.caseIds?.count ?? 0) Fälle")
             .font(.caption2)
             .foregroundStyle(.tertiary)
         }
         Spacer()
         Picker("", selection: Binding(
           get: { p.kapazitaet ?? .verfuegbar },
           set: { neu in
             guard var kn = vm.knoten.first(where: { $0.id == p.id }) else { return }
             kn.kapazitaet = neu
             vm.speichereKnoten(kn)
           }
         )) {
           ForEach(OrganonKapazitaet.allCases, id: \.self) { Text($0.bezeichnung).tag($0) }
         }
         .labelsHidden()
         .frame(width: 140)
       }
       .padding(12)
       .background(FenlynineOSTheme.glassFill.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
     }
   }
   .padding(20)
 }
}

private func kapTile(_ t: String, _ n: Int, _ c: Color) -> some View {
 VStack(spacing: 4) {
   Text("\(n)").font(.title.bold()).foregroundStyle(c)
   Text(t).font(.caption).foregroundStyle(.secondary)
 }
 .frame(maxWidth: .infinity)
 .padding(12)
 .background(c.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
}
}

