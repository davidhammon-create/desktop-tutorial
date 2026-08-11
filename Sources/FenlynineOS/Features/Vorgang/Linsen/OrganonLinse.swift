import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// LINSE 5 -- ORGANON (Overlay, nicht Fundament)
// PDF Interface Design, Teil IV, Abb. 17
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Die einzige Linse, die sich über einen Vorgang legt, statt ihn
// zu zeigen. Und die einzige, deren Bildschirm eine Sperre enthalten
// muss, die du nicht wegdesignen kannst."
//
// § 87 Abs. 1 Nr. 6 BetrVG -- sichtbare Sperre.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct OrganonLinse: View {
let vorgangId: UUID
@Bindable var store: VorgangStore = .shared
@State private var ebene: OrganonEbene = .firma

enum OrganonEbene: String, CaseIterable, Identifiable {
  case firma = "Firmenebene"
  case abteilung = "Abteilungsebene"
  case person = "Personenebene"
  var id: String { rawValue }
}

private var vorgang: Vorgang? { store.vorgang(vorgangId) }

var body: some View {
  if let v = vorgang {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        ebenenWaehler
        if ebene == .person {
          gesperrtBlock
        } else {
          beteiligungsBlock(v)
        }
      }
      .padding(16)
    }
  } else {
    Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
  }
}

private var ebenenWaehler: some View {
  HStack(spacing: 8) {
    ForEach(OrganonEbene.allCases) { e in
      Button {
        ebene = e
      } label: {
        Text(e.rawValue)
          .font(.system(size: 12, weight: .semibold))
          .padding(.horizontal, 12).padding(.vertical, 6)
          .foregroundStyle(ebene == e ? .white : InterfacePalette.sekundaer)
          .background(RoundedRectangle(cornerRadius: 8).fill(ebene == e ? InterfacePalette.aktion.opacity(0.24) : InterfacePalette.Material.l2))
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(ebene == e ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1))
      }
      .buttonStyle(.plain)
    }
    Spacer()
  }
}

private func beteiligungsBlock(_ v: Vorgang) -> some View {
  InterfaceKarte(ebene: 2) {
    VStack(alignment: .leading, spacing: 10) {
      Text("BETEILIGUNGSSTRUKTUR -- UNBEDENKLICH")
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(InterfacePalette.berechnet)

      if let partei = v.parteien.first {
        VStack(alignment: .leading, spacing: 6) {
          Text(partei.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Premium.text)
          Text("n").foregroundStyle(InterfacePalette.sekundaer)
          HStack(spacing: 12) {
            konzernKnoten(name: "\(partei.name) DE", anteil: 100)
            konzernKnoten(name: "\(partei.name) NL", anteil: 94)
            konzernKnoten(name: "\(partei.name) IE", anteil: 100)
          }
        }
      }

      Divider().overlay(InterfacePalette.trennlinie)
      Text("\(v.parteien.first?.name ?? "Alpha") IE berührt Vorgang \(v.titel). -> § 42 AO relevant.")
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.8))
      Text("Quelle: Handelsregister · kein Personenbezug · keine Mitbestimmung")
        .font(.system(size: 10))
        .foregroundStyle(InterfacePalette.sekundaer)
    }
    .padding(14)
  }
}

private func konzernKnoten(name: String, anteil: Int) -> some View {
  VStack(spacing: 4) {
    Text(name).font(.system(size: 11, weight: .semibold)).foregroundStyle(Premium.text)
   Text("\(anteil) %").font(.system(size: 10, design: .monospaced)).foregroundStyle(InterfacePalette.sekundaer)
 }
 .padding(8)
 .frame(minWidth: 110)
 .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l3))
}

// Die sichtbare Sperre -- das Verkaufsargument
private var gesperrtBlock: some View {
 InterfaceKarte(ebene: 2) {
   VStack(alignment: .leading, spacing: 8) {
     HStack(spacing: 8) {
       Image(systemName: "lock.fill").foregroundStyle(InterfacePalette.kritisch)
       Text("PERSONENEBENE -- GESPERRT")
         .font(.system(size: 11, weight: .semibold))
         .kerning(0.4)
         .foregroundStyle(InterfacePalette.kritisch)
     }
     Text("§ 87 Abs. 1 Nr. 6 BetrVG")
       .font(.system(size: 13, weight: .bold, design: .monospaced))
       .foregroundStyle(Premium.text)
     Text("Individuelle Leistungsdaten sichtbar für Vorgesetzte = technische Überwachungseinrichtung -- unabhängig von der Absicht.")
       .font(.system(size: 12))
       .foregroundStyle(.white.opacity(0.75))
     Text("Freischaltung nur nach dokumentierter Betriebsvereinbarung.")
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(Premium.text)

     Button {
       // Placeholder -- echtes Upload-Feld
     } label: {
       HStack(spacing: 6) {
         Image(systemName: "doc.badge.plus")
         Text("Betriebsvereinbarung hinterlegen")
       }
       .font(.system(size: 12, weight: .semibold))
       .padding(.horizontal, 14).padding(.vertical, 8)
       .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.aktion.opacity(0.18)))
       .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.aktion.opacity(0.5), lineWidth: 1))
       .foregroundStyle(InterfacePalette.aktion)
     }
     .buttonStyle(.plain)
     .padding(.top, 4)
   }
   .padding(14)
 }
}
}

