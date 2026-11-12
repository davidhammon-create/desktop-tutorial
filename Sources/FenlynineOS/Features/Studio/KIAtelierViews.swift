import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// KI-DARSTELLUNG -- Atelier-Stil (iCloud-Referenz)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Nur die ART der Darstellung, keine Bildinhalte:
// · Nummerierte Abschnitte
// · Label links · Wert rechts
// · Dünne Hairlines
// · Status-Badges (geschätzt / geplant / bestätigt)
// · Keine schweren Schatten
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum KIStatusBadge: String {
case geschaetzt = "geschätzt"
case geplant = "geplant"
case bestaetigt = "bestätigt"
case formel = "Formel"
case quelle = "Quelle"

var farbe: Color {
  switch self {
  case .geschaetzt: return Premium.proposed
  case .geplant: return Premium.action
  case .bestaetigt: return Premium.computed
  case .formel: return Premium.computed
  case .quelle: return Premium.mute
  }
}
}

struct KIStatusPille: View {
let badge: KIStatusBadge
var body: some View {
  Text(badge.rawValue)
    .font(.system(size: 10, weight: .semibold))
    .foregroundStyle(badge.farbe)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(Capsule().fill(badge.farbe.opacity(0.12)))
}
}

/// Label · Wert -- eine Zeile, Apple-Listenoptik
struct AtelierZeile: View {
let label: String
let wert: String
var badge: KIStatusBadge? = nil
var mono: Bool = false

var body: some View {
  HStack(alignment: .firstTextBaseline, spacing: 12) {
    Text(label)
      .font(.system(size: 13, weight: .regular))
      .foregroundStyle(Premium.text)
      .lineLimit(2)
    Spacer(minLength: 8)
    if let badge {
      KIStatusPille(badge: badge)
    }
    Text(wert)
      .font(.system(size: 13, weight: .semibold, design: mono ? .monospaced : .default))
      .monospacedDigit()
      .foregroundStyle(Premium.text)
      .multilineTextAlignment(.trailing)
  }
  .padding(.vertical, 8)
}
}

/// Nummerierter Abschnitt mit optionalen Zeilen
struct AtelierAbschnitt: View {
let nummer: Int
let titel: String
var untertitel: String? = nil
let zeilen: [(String, String, KIStatusBadge?)]

var body: some View {
  VStack(alignment: .leading, spacing: 0) {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text("\(nummer).")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Premium.text)
        .monospacedDigit()
      Text(titel)
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Premium.text)
      Spacer()
    }
    .padding(.bottom, 4)

    if let u = untertitel {
      Text(u)
        .font(.system(size: 12))
        .foregroundStyle(Premium.textSoft)
        .padding(.bottom, 6)
    }

    ForEach(Array(zeilen.enumerated()), id: \.offset) { idx, z in
     AtelierZeile(label: z.0, wert: z.1, badge: z.2, mono: true)
     if idx < zeilen.count - 1 {
       Divider().overlay(Premium.hairline)
     }
   }
 }
 .padding(.vertical, 4)
}
}

/// KI-Entscheidungs-/Vorschlagsblock -- der zentrale Darstellungsstil
struct KIEntscheidungsKarte: View {
let titel: String
var badge: KIStatusBadge = .geschaetzt
var abschnitte: [AtelierAbschnittDaten] = []
var hinweis: String? = nil
var onFragen: (() -> Void)? = nil

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack(alignment: .firstTextBaseline) {
     Text(titel)
       .font(.system(size: 17, weight: .bold))
       .foregroundStyle(Premium.text)
     Spacer()
     KIStatusPille(badge: badge)
   }

   ForEach(Array(abschnitte.enumerated()), id: \.offset) { idx, a in
     AtelierAbschnitt(nummer: idx + 1, titel: a.titel, untertitel: a.untertitel, zeilen: a.zeilen)
     if idx < abschnitte.count - 1 {
       Rectangle()
         .fill(Premium.hairline)
         .frame(height: 1)
         .padding(.vertical, 4)
     }
   }

   if let hinweis {
     Text(hinweis)
       .font(.system(size: 11))
       .foregroundStyle(Premium.textFaint)
       .padding(.top, 4)
   }

   if let onFragen {
     Divider().overlay(Premium.hairline)
     Button(action: onFragen) {
       HStack(spacing: 8) {
         Image(systemName: "plus")
           .font(.system(size: 12, weight: .medium))
         Text("KI fragen …")
           .font(.system(size: 13))
         Spacer()
       }
       .foregroundStyle(Premium.textSoft)
       .padding(.horizontal, 12)
       .padding(.vertical, 10)
       .overlay(
         RoundedRectangle(cornerRadius: 10, style: .continuous)
           .stroke(Premium.hairline, lineWidth: 1)
       )
     }
     .buttonStyle(.plain)
   }
 }
 .padding(16)
 .background(Premium.panel)
 .overlay(
   RoundedRectangle(cornerRadius: 12, style: .continuous)
     .stroke(Premium.hairline, lineWidth: 1)
 )
 .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
}
}

struct AtelierAbschnittDaten {
var titel: String
var untertitel: String? = nil
var zeilen: [(String, String, KIStatusBadge?)]
}

/// Kompakte Herkunftszeile für Zahlen (Atelier + Noir)
struct AtelierHerkunftZeile: View {
let label: String
let wert: WertMitHerkunft
var format: (Double) -> String = { InterfaceZahl.waehrung($0) }

var body: some View {
 AtelierZeile(
   label: label,
   wert: format(wert.wert),
   badge: badge(fuer: wert.herkunft),
   mono: true
 )
}

private func badge(fuer h: Herkunft) -> KIStatusBadge {
 switch h {
 case .formel: return .formel
 case .ki: return .geschaetzt
 case .mensch: return .bestaetigt
 case .quelle: return .quelle
 }
}
}

