import SwiftUI
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// DER BOHRER (PDF Interface Design, Teil III, Abb. 10)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Vier Klicks von der Empfehlung bis zur Person, die den Ausgangswert
// eingetippt hat. Kein Sprachmodell kann diesen Bildschirm bauen.
//
// Klick 0 -- geschlossen: Nur die Zahl mit Herkunftsmarke.
// Klick 1 -- Formel: Formel + Auflösung + Ergebnis.
// Klick 2 -- Eingabe: Blaue (Mensch-)Werte sind selbst Türen.
// Klick 3 -- KI-Detail: Grundlage, Modell, Zeitpunkt, Bestätigen.
// Klick 4 -- Wurzel: Wer / Wann / Feld / Schritt.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct WertBohrer: View {
let wert: WertMitHerkunft
let label: String
/// Optionaler „Kinder-Wert" -- wenn dieser Wert selbst wieder aus einer
/// Formel entstand, die auf zwei Eingaben zeigt, kann der Nutzer weiterbohren.
var kinder: [(String, WertMitHerkunft)] = []
/// Wird aufgerufen, wenn ein Mensch einen KI-Wert bestätigt oder überschreibt
/// (Bezeichnung des Kind-Werts, neuer Wert). Ohne Rückruf bleiben die Werte
/// reine Anzeige -- es erscheinen dann auch keine Knöpfe, die nichts tun.
var onAendern: ((String, WertMitHerkunft) -> Void)? = nil

@State private var ebene: Int = 0

var body: some View {
  VStack(alignment: .leading, spacing: 8) {
    Button {
      withAnimation(.easeInOut(duration: 0.18)) {
        ebene = ebene == 0 ? 1 : 0
      }
    } label: {
      HStack(spacing: 8) {
        Herkunftsmarke(herkunft: wert.herkunft, groesse: 9)
        Text(InterfaceZahl.waehrung(wert.wert))
          .font(.system(size: 18, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(farbe)
        Image(systemName: ebene == 0 ? "chevron.down" : "chevron.up")
          .font(.system(size: 9, weight: .semibold))
          .foregroundStyle(InterfacePalette.sekundaer)
        Spacer()
      }
    }
    .buttonStyle(.plain)

    if ebene >= 1 {
      bohrEbene1
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
  }
  .padding(12)
  .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l2))
}

private var farbe: Color {
  switch wert.herkunft {
  case .formel: return wert.wert < 0 ? InterfacePalette.kritisch : InterfacePalette.berechnet
  case .ki: return InterfacePalette.vorgeschlagen
  case .mensch: return InterfacePalette.aktion
  case .quelle: return InterfacePalette.sekundaer
  }
}

@ViewBuilder
private var bohrEbene1: some View {
  VStack(alignment: .leading, spacing: 8) {
    Text(label.uppercased())
      .font(.system(size: 10, weight: .semibold))
      .kerning(0.6)
      .foregroundStyle(InterfacePalette.sekundaer)

    Text(wert.quelle)
      .font(.system(size: 11, design: .monospaced))
      .foregroundStyle(.white.opacity(0.9))
      .textSelection(.enabled)

    if !kinder.isEmpty {
      Divider().overlay(InterfacePalette.trennlinie)
      VStack(alignment: .leading, spacing: 6) {
        ForEach(Array(kinder.enumerated()), id: \.offset) { _, kind in
          WertUnterZeile(label: kind.0, wert: kind.1,
                         onAendern: onAendern.map { f in { neu in f(kind.0, neu) } })
        }
      }
    }

    HStack(spacing: 8) {
      HerkunftsHinweis(herkunft: wert.herkunft)
      Spacer()
      if let wer = wert.wer {
        Text(wer)
          .font(.system(size: 10))
          .foregroundStyle(InterfacePalette.sekundaer)
      }
      Text(WertBohrer.zeit(wert.wann))
        .font(.system(size: 10))
        .monospacedDigit()
        .foregroundStyle(InterfacePalette.sekundaer)
    }
  }
 .padding(.top, 4)
}

private static let df: DateFormatter = {
 let f = DateFormatter()
 f.locale = Locale(identifier: "de_DE")
 f.dateFormat = "dd.MM.yyyy, HH:mm"
 return f
}()
private static func zeit(_ d: Date) -> String { df.string(from: d) }
}

// MARK: - Unter-Wert im Bohrer

private struct WertUnterZeile: View {
let label: String
let wert: WertMitHerkunft
var onAendern: ((WertMitHerkunft) -> Void)? = nil
@State private var offen = false
@State private var bearbeitet = false
@State private var eingabe = ""

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   Button {
     offen.toggle()
   } label: {
     HStack(spacing: 6) {
       Herkunftsmarke(herkunft: wert.herkunft, groesse: 7)
       Text(label)
         .font(.system(size: 11))
         .foregroundStyle(.white.opacity(0.7))
       Spacer()
       Text(InterfaceZahl.dezimal(wert.wert))
         .font(.system(size: 12, weight: .medium, design: .monospaced))
         .monospacedDigit()
         .foregroundStyle(farbeText)
       Image(systemName: offen ? "chevron.up" : "chevron.down")
         .font(.system(size: 9))
         .foregroundStyle(InterfacePalette.sekundaer)
     }
   }
   .buttonStyle(.plain)

   if offen {
     VStack(alignment: .leading, spacing: 4) {
       Text(wert.quelle)
         .font(.system(size: 10, design: .monospaced))
         .foregroundStyle(.white.opacity(0.75))
       if wert.herkunft == .ki {
         HStack(spacing: 8) {
           if let onAendern {
             // Bestätigen macht aus dem KI-Vorschlag eine menschliche Angabe:
             // derselbe Wert, aber mit Name und Zeitpunkt der Prüfung.
             RoundedButton(text: "Bestätigen", farbe: InterfacePalette.aktion) {
               var neu = WertMitHerkunft.mensch(wert.wert, name: NSFullUserName())
               neu.quelle = "Bestätigt (KI-Vorschlag: \(wert.quelle))"
               onAendern(neu)
             }
             RoundedButton(text: "Überschreiben", farbe: InterfacePalette.sekundaer) {
               eingabe = InterfaceZahl.dezimal(wert.wert)
               bearbeitet = true
             }
           }
           RoundedButton(text: "Quelle kopieren", farbe: InterfacePalette.berechnet) {
             NSPasteboard.general.clearContents()
             NSPasteboard.general.setString(wert.quelle, forType: .string)
           }
         }
         if bearbeitet, let onAendern {
           HStack(spacing: 6) {
             TextField("Neuer Wert", text: $eingabe)
               .textFieldStyle(.roundedBorder)
               .frame(width: 120)
               .onSubmit { uebernehme(onAendern) }
             RoundedButton(text: "Übernehmen", farbe: InterfacePalette.aktion) { uebernehme(onAendern) }
             RoundedButton(text: "Abbrechen", farbe: InterfacePalette.sekundaer) { bearbeitet = false }
           }
         }
       }
       if let wer = wert.wer {
         Text("Eingegeben von \(wer)")
           .font(.system(size: 10))
           .foregroundStyle(InterfacePalette.sekundaer)
       }
     }
     .padding(.leading, 14)
     .transition(.opacity)
   }
 }
}

private func uebernehme(_ onAendern: (WertMitHerkunft) -> Void) {
 let text = eingabe.trimmingCharacters(in: .whitespaces)
   .replacingOccurrences(of: ".", with: "")
   .replacingOccurrences(of: ",", with: ".")
   .replacingOccurrences(of: "%", with: "")
 guard let zahl = Double(text) else { return }
 var neu = WertMitHerkunft.mensch(zahl, name: NSFullUserName())
 neu.quelle = "Manuell überschrieben (KI-Vorschlag war \(InterfaceZahl.dezimal(wert.wert)))"
 onAendern(neu)
 bearbeitet = false
}

private var farbeText: Color {
 switch wert.herkunft {
 case .formel: return InterfacePalette.berechnet
 case .ki: return InterfacePalette.vorgeschlagen
 case .mensch: return InterfacePalette.aktion
 case .quelle: return InterfacePalette.sekundaer
 }
}
}

private struct RoundedButton: View {
let text: String
let farbe: Color
let action: () -> Void

var body: some View {
 Button(action: action) {
   Text(text)
     .font(.system(size: 10, weight: .semibold))
     .padding(.horizontal, 10)
     .padding(.vertical, 5)
     .background(RoundedRectangle(cornerRadius: 6).fill(farbe.opacity(0.18)))
     .overlay(RoundedRectangle(cornerRadius: 6).stroke(farbe.opacity(0.35), lineWidth: 1))
     .foregroundStyle(farbe)
 }
 .buttonStyle(.plain)
}
}

// MARK: - Herkunfts-Hinweis (Legende in der Aufklappung)

private struct HerkunftsHinweis: View {
let herkunft: Herkunft

var body: some View {
 HStack(spacing: 6) {
   Herkunftsmarke(herkunft: herkunft, groesse: 7)
   Text(herkunft.beschreibung)
     .font(.system(size: 10))
     .foregroundStyle(InterfacePalette.sekundaer)
 }
}
}

