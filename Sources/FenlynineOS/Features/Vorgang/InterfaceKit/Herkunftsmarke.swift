import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// HERKUNFTSMARKE (PDF Interface Design, Teil II, Abb. 4)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Das wichtigste Element des gesamten Interfaces ist zwei Millimeter groß
// und sitzt links neben jeder Zahl."
//
// l gefüllt = Formel (deterministisch, grün)
// n Ring = KI-Vorschlag (unbestätigt, orange)
// l blau = Mensch (bestätigt, haftbar)
// l grau = Quelle (Gesetz, unveränderlich)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Herkunftsmarke: View {
let herkunft: Herkunft
var groesse: CGFloat = 8

var body: some View {
  Group {
    switch herkunft {
    case .formel:
      Circle().fill(InterfacePalette.berechnet)
    case .ki:
      Circle().stroke(InterfacePalette.vorgeschlagen, lineWidth: 1.5)
    case .mensch:
      Circle().fill(InterfacePalette.aktion)
    case .quelle:
      Circle().fill(InterfacePalette.sekundaer)
    }
  }
  .frame(width: groesse, height: groesse)
  .help(herkunft.kurz + " · " + herkunft.beschreibung)
}
}

// MARK: - Zahl mit Herkunft (das Standard-Zahlen-Element)

struct WertBadge: View {
let wert: WertMitHerkunft
var format: (Double) -> String = { InterfaceZahl.waehrung($0) }
var groesseText: CGFloat = 20
var fett: Bool = true

var body: some View {
  HStack(spacing: 6) {
    Herkunftsmarke(herkunft: wert.herkunft, groesse: 8)
    Text(format(wert.wert))
      .font(.system(size: groesseText, weight: fett ? .bold : .medium, design: .default))
      .monospacedDigit()
      .foregroundStyle(farbe)
  }
}

private var farbe: Color {
  switch wert.herkunft {
  case .formel: return wert.wert < 0 ? InterfacePalette.kritisch : InterfacePalette.berechnet
  case .ki: return InterfacePalette.vorgeschlagen
  case .mensch: return .white
  case .quelle: return InterfacePalette.sekundaer
  }
}
}

// MARK: - Kompakter Wert (Beschriftung + Zahl)

struct WertZeile: View {
let label: String
let wert: WertMitHerkunft
var format: (Double) -> String = { InterfaceZahl.waehrung($0) }

var body: some View {
  HStack {
    Text(label)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(InterfacePalette.sekundaer)
      .kerning(0.4)
    Spacer()
    WertBadge(wert: wert, format: format, groesseText: 13, fett: false)
  }
}
}

// MARK: - Herkunfts-Filter (PDF Abb. 5)

struct HerkunftsFilter: View {
@Binding var aktiv: Herkunft?
let zaehler: [Herkunft: Int]

var body: some View {
  HStack(spacing: 12) {
    ForEach(Herkunft.allCases) { h in
      Button {
        if aktiv == h { aktiv = nil } else { aktiv = h }
      } label: {
        HStack(spacing: 6) {
          Herkunftsmarke(herkunft: h)
          Text(h.kurz)
            .font(.system(size: 11, weight: .medium))
           .foregroundStyle(.white.opacity(aktiv == nil || aktiv == h ? 1 : 0.4))
         Text("· \(zaehler[h] ?? 0)")
           .font(.system(size: 11))
           .monospacedDigit()
           .foregroundStyle(InterfacePalette.sekundaer)
       }
       .padding(.horizontal, 10)
       .padding(.vertical, 6)
       .background(
         RoundedRectangle(cornerRadius: 8)
           .fill(aktiv == h ? InterfacePalette.trennlinie : Color.clear)
       )
     }
     .buttonStyle(.plain)
   }
 }
}
}

