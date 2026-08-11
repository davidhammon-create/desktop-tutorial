import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// LINSE 2 -- GESTALTUNG (Strategos)
// PDF Interface Design, Teil IV, Abb. 13 · 14
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Noch ist nichts passiert. Es gibt keine Gegenseite, nur Möglichkeiten
// und Folgen. Diese Linse hat als einzige einen Richtungsschalter."
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum GestaltungRichtung: String, CaseIterable, Identifiable {
case vorwaerts
case rueckwaerts
case gemischt
var id: String { rawValue }
var label: String {
  switch self {
  case .vorwaerts: return "-> Vorwärts"
  case .rueckwaerts: return "<- Rückwärts"
  case .gemischt: return "n Gemischt"
  }
}
}

struct GestaltungLinse: View {
let vorgangId: UUID
@Bindable var store: VorgangStore = .shared
@State private var richtung: GestaltungRichtung = .vorwaerts
@State private var zielzustand: String = "Steuerlast unter 18 % -- ohne RPN > 100"

private var vorgang: Vorgang? { store.vorgang(vorgangId) }

var body: some View {
  if let v = vorgang {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        richtungsSchalter
        if richtung == .rueckwaerts {
          zielBlock
          pfadeAnalyse(v)
        } else {
          optionenReihe(v)
        }
      }
      .padding(16)
    }
  } else {
    Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
  }
}

private var richtungsSchalter: some View {
  HStack(spacing: 8) {
    ForEach(GestaltungRichtung.allCases) { r in
      Button {
        richtung = r
      } label: {
        Text(r.label)
          .font(.system(size: 12, weight: .semibold))
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .foregroundStyle(richtung == r ? .white : InterfacePalette.sekundaer)
          .background(RoundedRectangle(cornerRadius: 8).fill(richtung == r ? InterfacePalette.aktion.opacity(0.24) : InterfacePalette.Material.l2))
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(richtung == r ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1))
      }
      .buttonStyle(.plain)
    }
    Spacer()
  }
}

private var zielBlock: some View {
  InterfaceKarte(ebene: 2) {
    VStack(alignment: .leading, spacing: 6) {
      Text("ZIELZUSTAND -- WAS SOLL AM ENDE WAHR SEIN?")
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(InterfacePalette.sekundaer)
      TextField("Ziel", text: $zielzustand, axis: .vertical)
        .textFieldStyle(.plain)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Premium.text)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l3))
    }
    .padding(12)
  }
}

private func pfadeAnalyse(_ v: Vorgang) -> some View {
  VStack(alignment: .leading, spacing: 8) {
    Text("PFADE ZUM ZIEL -- RÜCKWÄRTS GERECHNET")
      .font(.system(size: 10, weight: .semibold))
      .kerning(0.4)
      .foregroundStyle(InterfacePalette.sekundaer)

    ForEach(Array(v.optionen.filter { !$0.istVorgeschichte }.enumerated()), id: \.element.id) { idx, o in
      let erreicht = zielErreicht(o)
      InterfaceKarte(ebene: 2) {
       HStack(spacing: 12) {
         Text("Pfad \(idx + 1)")
           .font(.system(size: 12, weight: .semibold))
           .foregroundStyle(InterfacePalette.sekundaer)
         VStack(alignment: .leading, spacing: 4) {
           Text(o.label)
             .font(.system(size: 13, weight: .semibold))
             .foregroundStyle(Premium.text)
           Text(erreicht ? "erreichbar" : "verfehlt Ziel")
             .font(.system(size: 11))
             .foregroundStyle(erreicht ? InterfacePalette.berechnet : InterfacePalette.kritisch)
         }
         Spacer()
         if let ev = o.bewertung.ev {
           WertBadge(wert: ev, groesseText: 16, fett: true)
         }
       }
       .padding(12)
     }
   }
 }
}

private func optionenReihe(_ v: Vorgang) -> some View {
 VStack(alignment: .leading, spacing: 8) {
   LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
     ForEach(v.optionen.filter { !$0.istVorgeschichte }) { o in
       optionKarte(o, empfohlen: v.empfehlung?.optionId == o.id)
     }
   }

   if !v.optionen.contains(where: { $0.istVorgeschichte }) == false {
     VStack(alignment: .leading, spacing: 6) {
       Divider().overlay(InterfacePalette.trennlinie)
       Text("VORGESCHICHTE (alte Optionen nach Typwechsel)")
         .font(.system(size: 10, weight: .semibold))
         .kerning(0.4)
         .foregroundStyle(InterfacePalette.sekundaer)
       ForEach(v.optionen.filter(\.istVorgeschichte)) { o in
         HStack {
           Text(o.label).font(.system(size: 12)).foregroundStyle(InterfacePalette.sekundaer)
           Spacer()
           if let ev = o.bewertung.ev {
             Text(InterfaceZahl.waehrung(ev.wert))
               .font(.system(size: 12, design: .monospaced))
               .foregroundStyle(InterfacePalette.sekundaer)
           }
         }
       }
     }
   }
 }
}

private func optionKarte(_ o: VorgangOption, empfohlen: Bool) -> some View {
 InterfaceKarte(ebene: 2) {
   VStack(alignment: .leading, spacing: 10) {
     HStack {
       if empfohlen {
         Text("EMPFOHLEN")
           .font(.system(size: 9, weight: .bold))
           .kerning(0.6)
           .foregroundStyle(InterfacePalette.berechnet)
           .padding(.horizontal, 6).padding(.vertical, 2)
           .background(RoundedRectangle(cornerRadius: 4).fill(InterfacePalette.berechnet.opacity(0.14)))
       }
       Text(o.label)
         .font(.system(size: 13, weight: .semibold))
         .foregroundStyle(Premium.text)
       Spacer()
     }

     if let ev = o.bewertung.ev {
       Text("ERWARTUNGSWERT")
         .font(.system(size: 9, weight: .semibold))
         .kerning(0.4)
         .foregroundStyle(InterfacePalette.sekundaer)
       WertBadge(wert: ev, groesseText: 24, fett: true)
     }

     VStack(spacing: 3) {
       if let s = o.bewertung.sharpe { WertZeile(label: "Sharpe", wert: s, format: { InterfaceZahl.dezimal($0, stellen: 2) }) }
       if let k = o.bewertung.kelly { WertZeile(label: "Kelly", wert: k, format: { InterfaceZahl.prozent($0) }) }
       HStack {
         Text("Kosten").font(.system(size: 11, weight: .semibold)).foregroundStyle(InterfacePalette.sekundaer)
         Spacer()
         Text(InterfaceZahl.waehrung(o.kosten.summe, mitVorzeichen: false)).font(.system(size: 12, design: .monospaced)).monospacedDigit().foregroundStyle(Premium.text)
       }
       HStack {
         Text("RPN krit.").font(.system(size: 11, weight: .semibold)).foregroundStyle(InterfacePalette.sekundaer)
         Spacer()
         Text("\(o.risiken.filter(\.kritisch).count)")
           .font(.system(size: 12, design: .monospaced))
           .monospacedDigit()
           .foregroundStyle(o.risiken.contains(where: \.kritisch) ? InterfacePalette.kritisch : .white)
       }
       WertZeile(label: "P(Erfolg)", wert: o.chancen.pErfolg, format: { InterfaceZahl.prozent($0) })
     }
   }
   .padding(12)
 }
}

private func zielErreicht(_ o: VorgangOption) -> Bool {
 // Sehr grob: EV > 0 und keine kritischen Risiken
 (o.bewertung.ev?.wert ?? 0) > 0 && !o.risiken.contains(where: \.kritisch)
}
}

