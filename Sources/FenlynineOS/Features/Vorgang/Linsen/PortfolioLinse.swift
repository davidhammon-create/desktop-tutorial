import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// LINSE 4 -- PORTFOLIO (Oportun)
// PDF Interface Design, Teil IV, Abb. 16
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Die einzige Linse, die nicht auf einen Vorgang schaut, sondern
// auf alle. Hier ergibt Kelly zum ersten Mal wirklich Sinn."
//
// Beantwortet drei Fragen:
// (cid:127) Wohin mit dem Geld?
// (cid:127) Was hängt zusammen?
// (cid:127) Was zuerst?
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct PortfolioLinse: View {
@Bindable var store: VorgangStore = .shared
@State private var budget: Double = 2_400_000

private var portfolio: [Vorgang] {
  store.vorgaenge.filter { $0.zustand.reihenfolge >= VorgangZustand.bewertet.reihenfolge && $0.typ != .verhandlung }
}

var body: some View {
  ScrollView {
    VStack(alignment: .leading, spacing: 14) {
      kopf
      kellyAllokation
      korrelationsWarnung
      reihenfolge
    }
    .padding(16)
  }
}

private var kopf: some View {
  HStack {
    VStack(alignment: .leading, spacing: 4) {
      Text("PORTFOLIO Q3 2026 -- \(portfolio.count) VORGÄNGE")
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(InterfacePalette.sekundaer)
      Text("Budget: " + InterfaceZahl.waehrung(budget, mitVorzeichen: false))
        .font(.system(size: 22, weight: .bold))
        .monospacedDigit()
        .foregroundStyle(Premium.text)
    }
    Spacer()
    let ev = Formelkaskade.portfolioEV(portfolio)
    VStack(alignment: .trailing, spacing: 4) {
      Text("EV KORRELATIONSBEREINIGT")
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(InterfacePalette.sekundaer)
      HStack(spacing: 8) {
        Herkunftsmarke(herkunft: .formel, groesse: 8)
        Text(InterfaceZahl.waehrung(ev.bereinigt))
          .font(.system(size: 22, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(ev.bereinigt >= 0 ? InterfacePalette.berechnet : InterfacePalette.kritisch)
      }
    }
  }
}

private var kellyAllokation: some View {
  InterfaceKarte(ebene: 2) {
    VStack(alignment: .leading, spacing: 8) {
      Text("KELLY-ALLOKATION ÜBER ALLE VORGÄNGE")
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(InterfacePalette.sekundaer)

      ForEach(portfolio) { v in
        let kelly = v.optionen.filter { !$0.istVorgeschichte }.first?.bewertung.kelly?.wert ?? 0
        let anteil = kelly * budget
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 2) {
            Text(v.titel)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Premium.text)
            Text(v.typ.moduleName + " · " + v.rechtsgebiet)
              .font(.system(size: 10))
              .foregroundStyle(InterfacePalette.sekundaer)
          }
          Spacer()
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule().fill(InterfacePalette.Material.l3).frame(height: 6)
              Capsule().fill(InterfacePalette.aktion).frame(width: min(geo.size.width, geo.size.width * kelly), height: 6)
            }
          }
          .frame(width: 160, height: 8)
          HStack(spacing: 6) {
            Herkunftsmarke(herkunft: .formel, groesse: 7)
            Text(InterfaceZahl.waehrung(anteil, mitVorzeichen: false))
              .font(.system(size: 12, weight: .medium, design: .monospaced))
              .monospacedDigit()
              .foregroundStyle(Premium.text)
             .frame(width: 100, alignment: .trailing)
         }
       }
     }

     HStack {
       Text("Nicht allokiert (Reserve)").font(.system(size: 11)).foregroundStyle(InterfacePalette.sekundaer)
       Spacer()
       let allokiert = portfolio.reduce(0.0) { s, v in
         s + (v.optionen.first?.bewertung.kelly?.wert ?? 0) * budget
       }
       Text(InterfaceZahl.waehrung(max(0, budget - allokiert), mitVorzeichen: false))
         .font(.system(size: 12, design: .monospaced))
         .monospacedDigit()
         .foregroundStyle(InterfacePalette.sekundaer)
     }
     .padding(.top, 6)
   }
   .padding(12)
 }
}

private var korrelationsWarnung: some View {
 let klumpen = Dictionary(grouping: portfolio, by: \.rechtsgebiet).filter { $0.value.count > 2 }
 return Group {
   if !klumpen.isEmpty {
     InterfaceKarte(ebene: 2) {
       VStack(alignment: .leading, spacing: 6) {
         HStack(spacing: 6) {
           Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(InterfacePalette.vorgeschlagen)
           Text("KORRELATIONSWARNUNG").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.vorgeschlagen)
         }
         ForEach(Array(klumpen), id: \.key) { rg, vs in
           Text("\(vs.count) Vorgänge im Rechtsgebiet \(rg) -- Klumpenrisiko.")
             .font(.system(size: 12))
             .foregroundStyle(Premium.text)
         }
         Text("Diese Zahl entsteht nur, wenn alle Vorgänge dasselbe Datenmodell teilen.")
           .font(.system(size: 10))
           .foregroundStyle(InterfacePalette.sekundaer)
       }
       .padding(12)
     }
   } else {
     EmptyView()
   }
 }
}

private var reihenfolge: some View {
 InterfaceKarte(ebene: 2) {
   VStack(alignment: .leading, spacing: 6) {
     Text("REIHENFOLGE -- WAS ZUERST?")
       .font(.system(size: 10, weight: .semibold))
       .kerning(0.4)
       .foregroundStyle(InterfacePalette.sekundaer)

     let sortiert = portfolio.sorted { ($0.optionen.first?.bewertung.rav?.wert ?? 0) > ($1.optionen.first?.bewertung.rav?.wert ?? 0) }
     ForEach(Array(sortiert.enumerated()), id: \.element.id) { idx, v in
       HStack {
         Text("\(idx + 1).").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(InterfacePalette.sekundaer)
         Text(v.titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
         Spacer()
         if let rav = v.optionen.first?.bewertung.rav {
           WertBadge(wert: rav, groesseText: 12, fett: false)
         }
       }
     }
   }
   .padding(12)
 }
}
}

