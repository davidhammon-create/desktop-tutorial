import SwiftUI

struct OrganonSearchView: View {
@Bindable var vm: OrganonViewModel
var onTreffer: () -> Void

var body: some View {
  HSplitView {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Organisation durchsuchen")
          .font(.title2.bold())
        Text("Facetten-Suche mit Kartenflug zum Treffer -- z. B. „Wer kann SAP-Migration und spricht Portugiesisch?"")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        TextField("Name, Rolle, Skill, Projekt, Standort…", text: $vm.suchFilter.query)
          .textFieldStyle(.roundedBorder)
          .onSubmit { vm.sucheAusfuehren() }

        Picker("Ebene", selection: $vm.ebenenKategorie) {
          ForEach(OrganonEbenenKategorie.allCases) { k in
            Text(k.bezeichnung).tag(k)
          }
        }
        .pickerStyle(.segmented)
        .onChange(of: vm.ebenenKategorie) { _, _ in vm.sucheAusfuehren() }

        Toggle("Nur verfügbare Kapazität", isOn: $vm.suchFilter.nurVerfuegbar)
          .font(.subheadline)
        Toggle("Nur Vakanzen", isOn: $vm.suchFilter.nurVakanzen)
          .font(.subheadline)

        if !vm.alleSkills.isEmpty {
          facettenSektion("Skills", optionen: vm.alleSkills, auswahl: $vm.suchFilter.skills)
        }
        if !vm.alleStandorte.isEmpty {
          facettenSektion("Standorte", optionen: vm.alleStandorte, auswahl: $vm.suchFilter.standorte)
        }

        HStack {
          Button("Suchen") { vm.sucheAusfuehren() }
            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
            .tint(FenlynineOSTheme.accent)
          Button("Zurücksetzen") {
            vm.suchFilter = OrganonSuchFilter()
            vm.suchTreffer = []
          }
          .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
        }

        Divider()

        beispielAbfragen
      }
      .padding(24)
    }
    .frame(minWidth: 320)

    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("\(vm.suchTreffer.isEmpty && vm.suchFilter.query.isEmpty ? vm.knoten.filter { $0.typ == .person }.count : vm.suchTreffer.count) Treffer")
            .font(.headline)
          Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)

        let liste: [OrganonKnoten] = {
          if !vm.suchTreffer.isEmpty || !vm.suchFilter.query.isEmpty {
            return vm.suchTreffer
          }
          switch vm.ebenenKategorie {
          case .struktur: return vm.organisationseinheiten
          case .personen: return vm.personen.filter { !$0.istVakanz }
          case .alles: return vm.personen.filter { !$0.istVakanz }
          }
        }()

        ForEach(liste) { kn in
          Button {
            vm.zuKnotenFliegen(kn)
            onTreffer()
          } label: {
            OrganonSuchTrefferKarte(knoten: kn, pfad: vm.pfadText(fuer: kn))
          }
          .buttonStyle(.plain)
          .padding(.horizontal, 20)
        }
      }
      .padding(.bottom, 20)
    }
    .frame(minWidth: 360)
  }
  .onAppear { vm.sucheAusfuehren() }
  .onChange(of: vm.suchFilter.query) { _, _ in vm.sucheAusfuehren() }
  .onChange(of: vm.suchFilter.skills) { _, _ in vm.sucheAusfuehren() }
  .onChange(of: vm.suchFilter.standorte) { _, _ in vm.sucheAusfuehren() }
 .onChange(of: vm.suchFilter.nurVerfuegbar) { _, _ in vm.sucheAusfuehren() }
}

private func facettenSektion(_ titel: String, optionen: [String], auswahl: Binding<Set<String>>) -> some View {
 VStack(alignment: .leading, spacing: 8) {
   Text(titel).font(.caption.bold()).foregroundStyle(.secondary)
   FlowLayout(spacing: 6) {
     ForEach(optionen, id: \.self) { opt in
       let aktiv = auswahl.wrappedValue.contains(opt)
       Button(opt) {
         if aktiv { auswahl.wrappedValue.remove(opt) }
         else { auswahl.wrappedValue.insert(opt) }
       }
       .font(.caption2)
       .padding(.horizontal, 10)
       .padding(.vertical, 5)
       .background {
         if aktiv {
           VisionOSGlasFlaeche.button(stil: .primaerBlau)
         } else {
           Capsule().fill(Color.secondary.opacity(0.08))
         }
       }
       .foregroundStyle(aktiv ? .white : .primary)
       .buttonStyle(.plain)
     }
   }
 }
}

private var beispielAbfragen: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("Beispielabfragen").font(.caption.bold()).foregroundStyle(.secondary)
   ForEach(beispiele, id: \.self) { b in
     Button(b) {
       vm.suchFilter = OrganonSuchFilter(query: b)
       vm.sucheAusfuehren()
     }
     .font(.caption)
     .foregroundStyle(FenlynineOSTheme.accent)
     .buttonStyle(.plain)
   }
 }
}

private var beispiele: [String] {
 ["DSGVO", "Portugiesisch", "M&A", "Wirtschaftsstrafrecht", "Grid Technologies", "Exportkontrolle"]
}
}

struct OrganonSuchTrefferKarte: View {
let knoten: OrganonKnoten
var pfad: String = ""

var body: some View {
 FenlynineOSCard {
   HStack(spacing: 12) {
     Image(systemName: knoten.typ.symbol)
       .font(.title2)
       .foregroundStyle(knoten.typ.farbe)
       .frame(width: 36)
     VStack(alignment: .leading, spacing: 4) {
       HStack(spacing: 6) {
         Text(knoten.name).font(.subheadline.weight(.semibold))
         Text(knoten.typ.kurz)
           .font(.system(size: 9, weight: .bold))
           .foregroundStyle(knoten.typ.farbe)
           .padding(.horizontal, 6).padding(.vertical, 2)
           .background(knoten.typ.farbe.opacity(0.12), in: Capsule())
       }
       if !pfad.isEmpty {
         Text(pfad).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
       }
       if knoten.istPerson, let rolle = knoten.rolle {
         Text(rolle).font(.caption).foregroundStyle(.secondary)
       }
       if knoten.istOrganisationseinheit {
         Text("\(knoten.mitarbeiterAnzahl ?? 0) Berufsträger")
           .font(.caption).foregroundStyle(.secondary)
       }
       if let claim = knoten.taetigkeitsclaim {
         Text(claim).font(.caption2).foregroundStyle(.tertiary).lineLimit(2)
       }
       if let skills = knoten.skills?.prefix(3) {
         HStack(spacing: 4) {
           ForEach(Array(skills), id: \.self) { s in
             Text(s).font(.system(size: 9)).padding(.horizontal, 6).padding(.vertical, 2)
               .background(Color.indigo.opacity(0.1), in: Capsule())
           }
         }
       }
     }
     Spacer()
     Image(systemName: "arrow.right.circle.fill")
       .foregroundStyle(FenlynineOSTheme.accent.opacity(0.6))
   }
 }
}
}

struct OrganonProfilListeView: View {
@Bindable var vm: OrganonViewModel

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   HStack {
     VStack(alignment: .leading, spacing: 2) {
       Text("Personen")
         .font(.title2.bold())
       Text("Nur natürliche Personen -- Abteilungen siehe Hierarchie-Tab.")
         .font(.caption)
         .foregroundStyle(.secondary)
     }
     Spacer()
     Text("\(vm.personen.filter { !$0.istVakanz }.count) Personen · \(vm.vakanzen.count) Vakanzen")
       .font(.caption)
       .foregroundStyle(.secondary)
   }
   .padding(.horizontal, 24)
   .padding(.vertical, 14)

   ScrollView {
     LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
       ForEach(vm.personen) { kn in
         Button {
           vm.ausgewaehlterKnoten = kn
         } label: {
           FenlynineOSCard {
             VStack(alignment: .leading, spacing: 10) {
               HStack {
                 Image(systemName: kn.istVakanz ? "person.crop.circle.badge.questionmark" : "person.circle.fill")
                   .font(.title)
                   .foregroundStyle(kn.istVakanz ? .orange : FenlynineOSTheme.accent)
                 VStack(alignment: .leading) {
                   Text(kn.name).font(.headline)
                   if let rolle = kn.rolle {
                     Text(rolle).font(.caption).foregroundStyle(.secondary)
                   }
                 }
                 Spacer()
                 if let kap = kn.kapazitaet {
                   Circle().fill(kap.farbe).frame(width: 10, height: 10)
                 }
               }
               Text(vm.pfadText(fuer: kn))
                 .font(.caption2)
                 .foregroundStyle(.tertiary)
                 .lineLimit(1)
               if let claim = kn.taetigkeitsclaim {
                 Text(claim).font(.caption).foregroundStyle(.secondary).lineLimit(2)
               }
               if let skills = kn.skills?.prefix(4) {
                 HStack(spacing: 4) {
                   ForEach(Array(skills), id: \.self) { s in
                     Text(s).font(.system(size: 9))
                       .padding(.horizontal, 6).padding(.vertical, 2)
                       .background(Color.indigo.opacity(0.1), in: Capsule())
                   }
                 }
               }
             }
             .frame(maxWidth: .infinity, alignment: .leading)
           }
         }
         .buttonStyle(.plain)
       }
     }
     .padding(24)
   }
 }
}
}

