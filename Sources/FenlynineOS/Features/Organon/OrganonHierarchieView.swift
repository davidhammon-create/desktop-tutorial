import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// ORGANON HIERARCHIE -- klare Trennung Abteilung « Person
//
// Baum: Gesellschaft -> Abteilung/Dezernat -> Team -> Person
// Partner können direkt unter der Abteilung hängen; Associates unter Teams.
// parentId ist Quelle der Wahrheit; Berichtslinien werden gespiegelt.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct OrganonHierarchieView: View {
@Bindable var vm: OrganonViewModel
var onZurKarte: (() -> Void)?

var body: some View {
  HSplitView {
    linkeSeite
      .frame(minWidth: 380)
    rechteSeite
      .frame(minWidth: 320)
  }
  .onAppear {
    // Gesellschaft und erste Abteilungsebene aufklappen
    for w in OrganonStore.shared.wurzeln() {
      vm.aufgeklappt.insert(w.id)
      for k in vm.kinder(von: w.id) where k.typ == .bereich {
        vm.aufgeklappt.insert(k.id)
      }
    }
  }
}

// MARK: - Links: Baum

private var linkeSeite: some View {
  VStack(alignment: .leading, spacing: 0) {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Hierarchie")
          .font(.title2.bold())
        Text("Gesellschaft -> Abteilung -> Team -> Person")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Menu {
        Button("Abteilung anlegen") { vm.neueAbteilung() }
        Button("Team anlegen") { vm.neuesTeam(unter: nil) }
        Button("Person anlegen") { vm.neuePerson(unter: nil) }
        Divider()
        Button("Hierarchie reparieren") { vm.repariereHierarchie() }
      } label: {
        Label("Neu", systemImage: "plus.circle.fill")
          .font(.system(size: 12, weight: .semibold))
      }
      .menuStyle(.borderlessButton)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)

    // Legende
    HStack(spacing: 12) {
      legende(.bereich, "Abteilung")
      legende(.team, "Team")
      legende(.person, "Person")
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 10)

    Divider().opacity(0.3)

    ScrollView {
      LazyVStack(alignment: .leading, spacing: 2) {
        ForEach(OrganonStore.shared.wurzeln()) { wurzel in
          OrganonBaumZeile(knoten: wurzel, tiefe: 0, vm: vm)
        }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
    }
  }
}

private func legende(_ typ: OrganonKnotenTyp, _ text: String) -> some View {
  HStack(spacing: 4) {
    Circle().fill(typ.farbe).frame(width: 8, height: 8)
    Text(text).font(.caption2).foregroundStyle(.secondary)
  }
}

// MARK: - Rechts: Detail

private var rechteSeite: some View {
  Group {
    if let kn = vm.ausgewaehlterKnoten {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Typ-Badge: Struktur vs Person
          HStack(spacing: 8) {
           Image(systemName: kn.typ.symbol)
             .font(.title2)
             .foregroundStyle(kn.typ.farbe)
           VStack(alignment: .leading, spacing: 2) {
             Text(kn.name)
               .font(.title3.bold())
             Text(kn.istOrganisationseinheit ? "Organisationseinheit" : "Natürliche Person")
               .font(.caption.weight(.semibold))
               .foregroundStyle(kn.istOrganisationseinheit ? kn.typ.farbe : FenlynineOSTheme.accent)
           }
           Spacer()
           Text(kn.typ.kurz)
             .font(.caption.weight(.bold))
             .padding(.horizontal, 10)
             .padding(.vertical, 5)
             .background(kn.typ.farbe.opacity(0.15), in: Capsule())
             .foregroundStyle(kn.typ.farbe)
         }

         // Brotkrumen
         if vm.hierarchiePfad.count > 1 {
           ScrollView(.horizontal, showsIndicators: false) {
             HStack(spacing: 4) {
               ForEach(Array(vm.hierarchiePfad.enumerated()), id: \.element.id) { idx, p in
                 if idx > 0 {
                   Image(systemName: "chevron.right")
                     .font(.system(size: 8, weight: .bold))
                     .foregroundStyle(.tertiary)
                 }
                 Button(p.name) {
                   vm.ausgewaehlterKnoten = p
                 }
                 .font(.caption)
                 .foregroundStyle(p.id == kn.id ? FenlynineOSTheme.accent : .secondary)
                 .buttonStyle(.plain)
               }
             }
           }
         }

         FenlynineOSCard {
           VStack(alignment: .leading, spacing: 10) {
             if kn.istOrganisationseinheit {
               strukturDetails(kn)
             } else {
               personenDetails(kn)
             }
           }
           .frame(maxWidth: .infinity, alignment: .leading)
         }

         // Verschieben
         FenlynineOSCard {
           VStack(alignment: .leading, spacing: 8) {
             Text("Hierarchie-Zuordnung")
               .font(.subheadline.bold())
             Text("Übergeordnete Einheit festlegen -- Berichtslinie wird automatisch synchronisiert.")
               .font(.caption)
               .foregroundStyle(.secondary)
             Menu {
               if kn.typ == .gesellschaft {
                 Text("Gesellschaft ist Wurzel")
               } else {
                 ForEach(moeglicheEltern(fuer: kn)) { eltern in
                   Button(vm.pfadText(fuer: eltern)) {
                     vm.verschiebe(kn.id, unter: eltern.id)
                   }
                 }
               }
             } label: {
               Label(
                 vm.elternName(fuer: kn).map { "Unter: \($0)" } ?? "Eltern wählen…",
                 systemImage: "arrow.triangle.branch"
               )
               .font(.system(size: 12, weight: .semibold))
             }
           }
           .frame(maxWidth: .infinity, alignment: .leading)
         }

         HStack(spacing: 10) {
           if kn.typ == .gesellschaft || kn.typ == .bereich {
             Button("Abteilung +") { vm.neueAbteilung(unter: kn.typ == .gesellschaft ? kn.id : kn.parentId) }
               .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
           }
           if kn.typ == .bereich {
             Button("Team +") { vm.neuesTeam(unter: kn.id) }
               .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
           }
           if kn.typ == .bereich || kn.typ == .team {
             Button("Person +") { vm.neuePerson(unter: kn.id) }
               .buttonStyle(FenlynineOSGlassProminentButtonStyle())
           }
           if let onZurKarte {
             Button("Auf Karte zeigen") {
               vm.zuKnotenFliegen(kn)
               onZurKarte()
             }
             .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
           }
         }
       }
       .padding(20)
     }
   } else {
     ContentUnavailableView(
       "Knoten wählen",
       systemImage: "arrow.triangle.branch",
       description: Text("Links eine Abteilung oder Person anklicken.")
     )
   }
 }
}

@ViewBuilder
private func strukturDetails(_ kn: OrganonKnoten) -> some View {
 detailZeile("Typ", kn.typ.bezeichnung)
 detailZeile("Standort", kn.standort ?? "--")
 detailZeile("Berufsträger", "\(kn.mitarbeiterAnzahl ?? vm.personenUnter(einheitId: kn.id).filter { !$0.istVakanz }.count)")
 let teams = vm.kinder(von: kn.id).filter { $0.typ == .team }
 let direktePersonen = vm.kinder(von: kn.id).filter { $0.typ == .person }
 if !teams.isEmpty {
   detailZeile("Teams", teams.map(\.name).joined(separator: ", "))
 }
 if !direktePersonen.isEmpty {
   detailZeile("Direkt zugeordnet", "\(direktePersonen.count) Person(en) -- z. B. Partner")
 }
 let last = vm.projektlast(fuer: kn.id)
 detailZeile("Aggregierte Last", "\(last) Mandate/Vorgänge unter dieser Einheit")
 Text("Hinweis: Aggregation auf Abteilungsebene -- keine individuelle Leistungsüberwachung.")
   .font(.caption2)
   .foregroundStyle(.tertiary)
}

@ViewBuilder
private func personenDetails(_ kn: OrganonKnoten) -> some View {
 detailZeile("Rolle", kn.rolle ?? "--")
 detailZeile("Gehört zu", vm.elternName(fuer: kn) ?? "nicht zugeordnet")
 if let eltern = kn.parentId.flatMap({ vm.knoten($0) }) {
   detailZeile("Einheitentyp", eltern.typ == .bereich ? "Direkt unter Abteilung (z. B. Partner)" : "Unter Team")
 }
 if let kap = kn.kapazitaet {
   detailZeile("Kapazität", kap.bezeichnung)
 }
 if kn.istVakanz {
   Text("Offene Stelle (Vakanz)")
     .font(.caption.weight(.semibold))
     .foregroundStyle(.orange)
 }
 if let claim = kn.taetigkeitsclaim {
   Text(claim).font(.caption).foregroundStyle(.secondary)
 }
 if !kn.effektiveSkills.isEmpty {
   FlowLayout(spacing: 6) {
     ForEach(kn.effektiveSkills.prefix(8), id: \.self) { s in
       Text(s)
         .font(.caption2)
         .padding(.horizontal, 8).padding(.vertical, 3)
         .background(Color.indigo.opacity(0.12), in: Capsule())
     }
   }
 }
}

private func detailZeile(_ k: String, _ v: String) -> some View {
 HStack(alignment: .top) {
   Text(k)
     .font(.caption)
     .foregroundStyle(.secondary)
     .frame(width: 120, alignment: .leading)
   Text(v)
     .font(.caption.weight(.medium))
     .fixedSize(horizontal: false, vertical: true)
 }
}

private func moeglicheEltern(fuer kn: OrganonKnoten) -> [OrganonKnoten] {
 vm.knoten.filter { kandidat in
   kandidat.id != kn.id
     && kn.typ.erlaubteElternTypen.contains(kandidat.typ)
     // Keine Zyklen: kandidat darf nicht unter kn hängen
     && !OrganonStore.shared.pfad(zu: kandidat.id).contains(where: { $0.id == kn.id })
 }
 .sorted { $0.name < $1.name }
}
}

// MARK: - Baumzeile

struct OrganonBaumZeile: View {
let knoten: OrganonKnoten
let tiefe: Int
@Bindable var vm: OrganonViewModel

private var kinder: [OrganonKnoten] { vm.kinder(von: knoten.id) }
private var istAufgeklappt: Bool { vm.aufgeklappt.contains(knoten.id) }
private var istAusgewaehlt: Bool { vm.ausgewaehlterKnoten?.id == knoten.id }

var body: some View {
 VStack(alignment: .leading, spacing: 1) {
   Button {
     vm.ausgewaehlterKnoten = knoten
   } label: {
     HStack(spacing: 6) {
       Color.clear.frame(width: CGFloat(tiefe) * 16)

       if !kinder.isEmpty {
         Button {
           if istAufgeklappt { vm.aufgeklappt.remove(knoten.id) }
           else { vm.aufgeklappt.insert(knoten.id) }
         } label: {
           Image(systemName: istAufgeklappt ? "chevron.down" : "chevron.right")
             .font(.system(size: 9, weight: .bold))
             .foregroundStyle(.secondary)
             .frame(width: 14)
         }
         .buttonStyle(.plain)
       } else {
         Color.clear.frame(width: 14)
       }

       Image(systemName: knoten.typ.symbol)
         .font(.system(size: 12))
         .foregroundStyle(knoten.typ.farbe)
         .frame(width: 18)

       VStack(alignment: .leading, spacing: 1) {
         HStack(spacing: 6) {
           Text(knoten.name)
             .font(.system(size: 12, weight: istAusgewaehlt ? .bold : .medium))
             .lineLimit(1)
           if knoten.istVakanz {
             Text("Vakanz")
               .font(.system(size: 9, weight: .bold))
               .foregroundStyle(.orange)
           }
         }
         Text(unterzeile)
           .font(.system(size: 10))
           .foregroundStyle(.secondary)
           .lineLimit(1)
       }

       Spacer(minLength: 4)

       Text(knoten.typ.kurz)
         .font(.system(size: 9, weight: .semibold))
         .foregroundStyle(knoten.typ.farbe)
         .padding(.horizontal, 6)
         .padding(.vertical, 2)
         .background(knoten.typ.farbe.opacity(0.12), in: Capsule())
     }
     .padding(.horizontal, 8)
     .padding(.vertical, 6)
     .background(
       RoundedRectangle(cornerRadius: 8, style: .continuous)
         .fill(istAusgewaehlt ? knoten.typ.farbe.opacity(0.12) : Color.clear)
     )
     .contentShape(Rectangle())
   }
   .buttonStyle(.plain)

   if istAufgeklappt {
     ForEach(kinder) { kind in
       OrganonBaumZeile(knoten: kind, tiefe: tiefe + 1, vm: vm)
     }
   }
 }
}

private var unterzeile: String {
 if knoten.istOrganisationseinheit {
   let n = knoten.mitarbeiterAnzahl ?? vm.personenUnter(einheitId: knoten.id).filter { !$0.istVakanz }.count
   let t = kinder.filter { $0.typ == .team }.count
   if knoten.typ == .bereich {
     return "\(n) Berufsträger · \(t) Team(s)"
   }
   return "\(n) Berufsträger"
 }
 return knoten.rolle ?? "Person"
}
}

