import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// VORGANGSANSICHT -- der Hauptbildschirm (PDF Interface Design S. 7)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Oben: Vorgangskopf (byte-identisch in jeder Linse).
// Unten: die aktive Linse (Streit / Gestaltung / Verhandlung / Portfolio / Organon).
//
// Enthält den TYPWECHSEL -- der Kaufmoment (PDF Abb. 18):
// „Nichts wurde neu eingegeben. Ein Feld hat sich geändert."
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct VorgangAnsichtView: View {
let vorgangId: UUID
@Bindable var store: VorgangStore = .shared
@State private var aktiveLinse: VorgangTyp = .streit
@State private var pfadgrafAktiv = false
@State private var zeigeTypWechsel = false
@State private var zeigeOrganon = false
@State private var kommandofeldOffen = false
@Environment(\.dismiss) private var dismiss

private var vorgang: Vorgang? { store.vorgang(vorgangId) }

var body: some View {
  VStack(spacing: 12) {
    if let v = vorgang {
      Vorgangskopf(
        vorgang: v,
        aktiveLinse: $aktiveLinse,
        pfadgrafAktiv: pfadgrafAktiv,
        onPfadgraf: { pfadgrafAktiv.toggle() },
        onKommandofeld: { kommandofeldOffen = true },
        onExport: { exportiere(v) },
        onZuPortfolio: { pfadgrafAktiv = false; aktiveLinse = .programm },
        onTypWechsel: { neuerTyp in
          if neuerTyp != v.typ {
            zeigeTypWechsel = true
          }
        }
      )
      .padding(.horizontal, 12)
      .padding(.top, 12)

      Group {
        if pfadgrafAktiv {
          PfadgrafLinse(vorgangId: v.id)
        } else {
          aktueller_linsen_inhalt(v)
        }
      }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
    }
  }
  .background(InterfacePalette.Material.l0)
  .onAppear {
    if let v = vorgang { aktiveLinse = v.typ }
  }
  .sheet(isPresented: $zeigeTypWechsel) { typWechselSheet }
  .sheet(isPresented: $kommandofeldOffen) {
    Kommandofeld(onOeffnen: { _ in }, aktuellerVorgang: vorgang)
      .presentationBackground(.clear)
  }
  .toolbar {
    ToolbarItem(placement: .cancellationAction) {
      Button("Schließen") { dismiss() }
    }
  }
}

@ViewBuilder
private func aktueller_linsen_inhalt(_ v: Vorgang) -> some View {
  switch aktiveLinse {
  case .streit: StreitLinse(vorgangId: v.id)
  case .gestaltung: GestaltungLinse(vorgangId: v.id)
  case .verhandlung: VerhandlungLinse(vorgangId: v.id)
  case .programm: PortfolioLinse()
  }
}

// MARK: - Typwechsel-Sheet (der Kaufmoment)

private var typWechselSheet: some View {
  VStack(alignment: .leading, spacing: 14) {
    Text("Typ wechseln")
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(Premium.text)
    Text("Ein Feld ändert sich. Alle Parteien, Optionen, Argumente und Formeln bleiben erhalten -- als Vorgeschichte lesbar.")
      .font(.system(size: 12))
      .foregroundStyle(InterfacePalette.sekundaer)

    if let v = vorgang {
      HStack(spacing: 12) {
        typKarte(v.typ, aktiv: true, title: "Bisher")
        Image(systemName: "arrow.right").foregroundStyle(InterfacePalette.aktion)
        typKarte(aktiveLinse, aktiv: false, title: "Neu")
      }
   }

   InterfaceKarte(ebene: 2) {
     VStack(alignment: .leading, spacing: 6) {
       Text("WAS BLEIBT").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.berechnet)
       bleibtZeile("Parteien", InterfacePalette.berechnet)
       bleibtZeile("Optionen (als Vorgeschichte)", InterfacePalette.berechnet)
       bleibtZeile("Argumente", InterfacePalette.berechnet)
       bleibtZeile("Normen & Fristen", InterfacePalette.berechnet)
       bleibtZeile("RPN-Tabelle", InterfacePalette.berechnet)
       Divider().overlay(InterfacePalette.trennlinie)
       Text("WAS NEU HINZUKOMMT").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.aktion)
       Text("Zustand fällt zurück auf »strukturiert« -- Options-Bewertung wird neu berechnet.")
         .font(.system(size: 11))
         .foregroundStyle(.white.opacity(0.75))
     }
     .padding(12)
   }

   HStack {
     Spacer()
     Button("Abbrechen") { zeigeTypWechsel = false }
       .buttonStyle(.plain)
       .foregroundStyle(InterfacePalette.sekundaer)
       .padding(.horizontal, 12).padding(.vertical, 6)
     Button {
       if let v = vorgang {
         store.typWechseln(v.id, zu: aktiveLinse)
       }
       zeigeTypWechsel = false
     } label: {
       Text("Typwechsel bestätigen")
         .font(.system(size: 12, weight: .semibold))
         .padding(.horizontal, 14).padding(.vertical, 7)
         .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.aktion))
         .foregroundStyle(Premium.text)
     }
     .buttonStyle(.plain)
   }
 }
 .padding(20)
 .frame(width: 500)
 .background(InterfacePalette.Material.l1)
}

private func typKarte(_ t: VorgangTyp, aktiv: Bool, title: String) -> some View {
 VStack(spacing: 6) {
   Text(title.uppercased())
     .font(.system(size: 9, weight: .semibold))
     .kerning(0.4)
     .foregroundStyle(InterfacePalette.sekundaer)
   HStack(spacing: 6) {
     Image(systemName: t.linsenSymbol).font(.system(size: 12))
     Text(t.bezeichnung).font(.system(size: 13, weight: .semibold))
   }
   .foregroundStyle(Premium.text)
   .padding(10)
   .background(RoundedRectangle(cornerRadius: 8).fill(aktiv ? InterfacePalette.Material.l2 : InterfacePalette.aktion.opacity(0.2)))
 }
}

private func bleibtZeile(_ text: String, _ farbe: Color) -> some View {
 HStack(spacing: 8) {
   Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(farbe)
   Text(text).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
   Spacer()
 }
}

private func exportiere(_ v: Vorgang) {
 // Placeholder für PDF-Export (nutzt bestehende Export-Services asynchron)
 print("[VorgangAnsichtView] Export angefragt für \(v.kurzId)")
}
}

