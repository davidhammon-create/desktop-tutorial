import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// KIPPPUNKT-REGLER (PDF Interface Design, Abb. 11)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Der Regler zeigt nicht nur das Ergebnis, sondern wo es kippt."
// Aufwand: eine Schleife über 100 Positionen, Vorzeichenwechsel suchen.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct KipppunktRegler: View {
let titel: String
@Binding var wert: Double
var min: Double = 0.0
var max: Double = 1.0
/// Optional: Kipppunkt in [0,1], an dem die Führung wechselt.
let kipppunkt: Double?
var kipppunktBeschriftung: String?

var body: some View {
  VStack(alignment: .leading, spacing: 6) {
    HStack {
      Text(titel.uppercased())
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(InterfacePalette.sekundaer)
      Spacer()
      Text(InterfaceZahl.prozent(wert))
        .font(.system(size: 13, weight: .bold))
        .monospacedDigit()
        .foregroundStyle(Premium.text)
    }

    ZStack(alignment: .leading) {
      GeometryReader { geo in
        let breite = geo.size.width
        ZStack(alignment: .leading) {
          Capsule().fill(InterfacePalette.Material.l3).frame(height: 6)
          Capsule().fill(InterfacePalette.aktion).frame(width: Swift.max(6, wert * breite), height: 6)

          if let k = kipppunkt {
            Rectangle()
              .fill(InterfacePalette.vorgeschlagen)
              .frame(width: 2, height: 14)
              .offset(x: k * breite - 1, y: -4)
          }

          Circle()
            .fill(InterfacePalette.Material.l4)
            .overlay(Circle().stroke(InterfacePalette.aktion, lineWidth: 2))
            .frame(width: 16, height: 16)
            .offset(x: wert * breite - 8, y: -5)
        }
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { g in
              let neu = Swift.min(Swift.max(0, g.location.x / breite), 1.0)
              self.wert = min + neu * (max - min)
            }
        )
      }
      .frame(height: 20)
    }

    if let k = kipppunkt, let text = kipppunktBeschriftung {
      HStack(spacing: 6) {
        Herkunftsmarke(herkunft: .formel, groesse: 7)
        Text("Kippt bei \(InterfaceZahl.prozent(k)) · \(text)")
          .font(.system(size: 10))
          .foregroundStyle(InterfacePalette.vorgeschlagen)
      }
    }
  }
  .padding(12)
  .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l2))
}
}

// MARK: - Gewichtungs-Panel (mehrere Regler, normalisiert)

struct GewichtungsPanel: View {
@Binding var gewichte: [String: Double] // Summe = 1.0
let optionen: [VorgangOption]

var body: some View {
  VStack(alignment: .leading, spacing: 10) {
    Text("WAS ZÄHLT FÜR DEN MANDANTEN?")
      .font(.system(size: 10, weight: .semibold))
      .kerning(0.4)
      .foregroundStyle(InterfacePalette.sekundaer)

    ForEach(Array(gewichte.keys.sorted()), id: \.self) { key in
      let binding = Binding<Double>(
        get: { gewichte[key] ?? 0 },
        set: { neu in
          gewichte[key] = neu
          normalisiere(ausser: key)
        }
      )
     KipppunktRegler(
       titel: key,
       wert: binding,
       kipppunkt: kipppunktFuer(key),
       kipppunktBeschriftung: kipppunktText(fuer: key)
     )
   }

   HStack {
     Spacer()
     Text("Normalisiert sich automatisch auf 100 %.")
       .font(.system(size: 10))
       .foregroundStyle(InterfacePalette.sekundaer)
   }
 }
}

private func normalisiere(ausser key: String) {
 let rest = gewichte.filter { $0.key != key }
 let summeRest = rest.values.reduce(0, +)
 let neu = 1.0 - (gewichte[key] ?? 0)
 guard summeRest > 0 else { return }
 for k in rest.keys {
   gewichte[k] = (gewichte[k] ?? 0) / summeRest * max(0, neu)
 }
}

private func kipppunktFuer(_ key: String) -> Double? {
 Formelkaskade.kipppunkt(optionen: optionen) { option, gewicht in
   let ev = option.bewertung.ev?.wert ?? 0
   let risk = -Double(option.bewertung.rpnGesamt)
   switch key {
   case "Erwartungswert": return ev * (1 - gewicht) + risk * gewicht
   case "Risiko (niedrig)": return ev * (1 - gewicht) + risk * gewicht
   default: return ev
   }
 }
}

private func kipppunktText(fuer key: String) -> String? {
 guard kipppunktFuer(key) != nil else { return nil }
 return "Ranking wechselt hier."
}
}

