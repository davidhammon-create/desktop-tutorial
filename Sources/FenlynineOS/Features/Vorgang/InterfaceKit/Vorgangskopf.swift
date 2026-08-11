import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// VORGANGSKOPF (PDF Interface Design, Abb. 8)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Vier Zeilen, in jeder Linse byte-identisch:
// Zeile 1 · Wo bin ich -- Kommandofeld · Linse · Kontext
// Zeile 2 · Welche Sache -- Titel · Partei · Frist-Pille
// Zeile 3 · Wie weit -- Zustandsleiste
// Zeile 4 · Welche Sicht -- Linsenleiste
//
// „Deshalb fühlt sich der Linsenwechsel nicht wie Navigation an,
// sondern wie ein Objektivwechsel an derselben Kamera."
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Vorgangskopf: View {
let vorgang: Vorgang
@Binding var aktiveLinse: VorgangTyp
var pfadgrafAktiv: Bool = false
var onPfadgraf: (() -> Void)? = nil
let onKommandofeld: () -> Void
let onExport: () -> Void
let onZuPortfolio: () -> Void
let onTypWechsel: (VorgangTyp) -> Void

var body: some View {
  VStack(alignment: .leading, spacing: 10) {
    zeileNavigation
    zeileTitel
    zeileZustand
    zeileLinsen
  }
  .padding(.horizontal, 16)
  .padding(.vertical, 12)
  .background(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(InterfacePalette.Material.l1)
  )
  .overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .stroke(InterfacePalette.trennlinie, lineWidth: 1)
  )
}

// Zeile 1 -- Navigation
private var zeileNavigation: some View {
  HStack(spacing: 12) {
    Button(action: onKommandofeld) {
      HStack(spacing: 6) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 11, weight: .semibold))
        Text("nK Suchen")
          .font(.system(size: 11, weight: .semibold))
      }
      .foregroundStyle(InterfacePalette.sekundaer)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
    }
    .buttonStyle(.plain)

    Button(action: onExport) {
      Text("Export")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(InterfacePalette.sekundaer)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
    }
    .buttonStyle(.plain)

    Button(action: onZuPortfolio) {
      HStack(spacing: 4) {
        Image(systemName: "arrow.up")
        Text("Portfolio")
      }
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(InterfacePalette.aktion)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.aktion.opacity(0.12)))
    }
    .buttonStyle(.plain)

    Spacer()

    Text(vorgang.rechtsgebiet.isEmpty ? vorgang.kurzId : vorgang.rechtsgebiet + " · " + vorgang.kurzId)
      .font(.system(size: 11, weight: .medium))
      .foregroundStyle(InterfacePalette.sekundaer)
  }
}

// Zeile 2 -- Titel + Frist-Pille
private var zeileTitel: some View {
  HStack(alignment: .firstTextBaseline, spacing: 12) {
    Text(vorgang.titel)
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(Premium.text)

   if let partei = vorgang.parteien.first {
     Text(partei.name)
       .font(.system(size: 13))
       .foregroundStyle(InterfacePalette.sekundaer)
   }

   Spacer()

   if let kritische = vorgang.fristen.filter({ $0.tageBisAblauf < 14 }).first {
     fristPille(kritische)
   }
 }
}

private func fristPille(_ frist: VorgangFrist) -> some View {
 HStack(spacing: 6) {
   Image(systemName: "calendar")
     .font(.system(size: 10, weight: .semibold))
   Text("\(frist.art) · \(frist.tageBisAblauf) Tage")
     .font(.system(size: 11, weight: .semibold))
 }
 .foregroundStyle(InterfacePalette.kritisch)
 .padding(.horizontal, 10)
 .padding(.vertical, 5)
 .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.kritisch.opacity(0.14)))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.kritisch.opacity(0.35), lineWidth: 1))
}

// Zeile 3 -- Zustandsleiste
private var zeileZustand: some View {
 HStack(spacing: 0) {
   ForEach(Array(VorgangZustand.allCases.enumerated()), id: \.element.id) { idx, zustand in
     let erreicht = zustand.reihenfolge < vorgang.zustand.reihenfolge
     let aktiv = zustand == vorgang.zustand
     HStack(spacing: 4) {
       if erreicht {
         Image(systemName: "checkmark").font(.system(size: 8, weight: .bold))
       } else if aktiv {
         Circle().frame(width: 6, height: 6)
       } else {
         Circle().stroke(lineWidth: 1).frame(width: 5, height: 5)
       }
       Text(zustand.bezeichnung.uppercased())
         .font(.system(size: 9, weight: .semibold))
         .kerning(0.4)
     }
     .foregroundStyle(aktiv ? InterfacePalette.aktion : (erreicht ? InterfacePalette.berechnet : InterfacePalette.sekundaer))
     .help(zustand.bedingung + " · " + zustand.wasErlaubt)

     if idx < VorgangZustand.allCases.count - 1 {
       Text("›")
         .font(.system(size: 10))
         .foregroundStyle(InterfacePalette.sekundaer.opacity(0.5))
         .padding(.horizontal, 6)
     }
   }
   Spacer()
 }
}

// Zeile 4 -- Linsenleiste
private var zeileLinsen: some View {
 HStack(spacing: 6) {
   ForEach(VorgangTyp.allCases) { typ in
     linsenChip(typ)
   }
   // Organon-Chip separat (immer sichtbar, aber wegdesignt)
   organonChip
   // Linse 6 -- Pfadgraf (Konzept.pdf: eigene Linse, nicht Modul)
   pfadgrafChip
   Spacer()
 }
}

private func linsenChip(_ typ: VorgangTyp) -> some View {
 let verfuegbar = istVerfuegbar(typ)
 let aktiv = !pfadgrafAktiv && aktiveLinse == typ
 return Button {
   guard verfuegbar else { return }
   if pfadgrafAktiv { onPfadgraf?() }
   aktiveLinse = typ
   // Typwechsel nur Streit « Gestaltung (Kaufmoment).
   // Verhandlung = Modus, Portfolio = Ebene darüber -- kein Typwechsel.
   if (typ == .streit || typ == .gestaltung), typ != vorgang.typ {
     onTypWechsel(typ)
   }
 } label: {
   HStack(spacing: 5) {
     Image(systemName: typ.linsenSymbol)
       .font(.system(size: 10, weight: .semibold))
     Text(typ.bezeichnung)
       .font(.system(size: 11, weight: .semibold))
   }
   .foregroundStyle(aktiv ? .white : (verfuegbar ? InterfacePalette.sekundaer : InterfacePalette.sekundaer.opacity(0.4)))
   .padding(.horizontal, 10)
   .padding(.vertical, 6)
   .background(RoundedRectangle(cornerRadius: 8).fill(aktiv ? InterfacePalette.aktion.opacity(0.28) : Color.clear))
   .overlay(RoundedRectangle(cornerRadius: 8).stroke(aktiv ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1))
 }
 .buttonStyle(.plain)
 .disabled(!verfuegbar)
 .help(verfuegbar ? typ.bezeichnung : sperrErklaerung(typ))
}

private var organonChip: some View {
 HStack(spacing: 5) {
   Image(systemName: "hexagon")
     .font(.system(size: 10))
   Text("Organon")
     .font(.system(size: 11, weight: .semibold))
 }
 .foregroundStyle(vorgang.organonKnotenId != nil ? .white : InterfacePalette.sekundaer.opacity(0.4))
 .padding(.horizontal, 10)
 .padding(.vertical, 6)
 .background(RoundedRectangle(cornerRadius: 8).fill(Color.clear))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
 .help(vorgang.organonKnotenId != nil ? "Mit Organon verknüpft" : "Organon ist optional -- Vorgang funktioniert ohne.")
}

private var pfadgrafChip: some View {
 Button {
   onPfadgraf?()
 } label: {
   HStack(spacing: 5) {
     Image(systemName: "point.3.connected.trianglepath.dotted")
       .font(.system(size: 10, weight: .semibold))
     Text("Pfadgraf")
       .font(.system(size: 11, weight: .semibold))
   }
   .foregroundStyle(pfadgrafAktiv ? .white : InterfacePalette.sekundaer)
   .padding(.horizontal, 10)
   .padding(.vertical, 6)
   .background(RoundedRectangle(cornerRadius: 8).fill(pfadgrafAktiv ? InterfacePalette.aktion.opacity(0.28) : Color.clear))
   .overlay(RoundedRectangle(cornerRadius: 8).stroke(pfadgrafAktiv ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1))
 }
 .buttonStyle(.plain)
 .help("Linse 6 -- Wegenetz: Zustände und Handlungen als DAG. Erzeugt die Optionsliste (Schritt 3).")
}

/// Verhandlung erst ab „entschieden" (PDF S. 21).
private func istVerfuegbar(_ typ: VorgangTyp) -> Bool {
 switch typ {
 case .verhandlung: return vorgang.zustand.reihenfolge >= VorgangZustand.entschieden.reihenfolge
 default: return true
 }
}

/// Grau lehrt die Kausalität (PDF S. 7): jede Sperre nennt eine Bedingung.
private func sperrErklaerung(_ typ: VorgangTyp) -> String {
 switch typ {
 case .verhandlung: return "Wird verfügbar, sobald eine Option gewählt ist."
 default: return ""
 }
}
}

