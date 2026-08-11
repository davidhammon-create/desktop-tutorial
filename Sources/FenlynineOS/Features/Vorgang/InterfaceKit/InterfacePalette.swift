import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// INTERFACE-PALETTE (aus FenlynineOS Interface Design.pdf, Teil II)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Folgt AppearanceStore: Noir = OLED, Atelier = hell lesbar.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum InterfacePalette {

private static var atelier: Bool { AppearanceStore.shared.istAtelier }

// Grundfläche
static var grund: Color {
  atelier ? Premium.void : Color(red: 0.0, green: 0.0, blue: 0.0)
}
static var flaeche: Color {
  atelier ? Premium.ink : Color(red: 0.11, green: 0.11, blue: 0.12)
}
static var rille: Color {
  atelier ? Premium.well : Color(red: 0.17, green: 0.17, blue: 0.18)
}

// Bedeutungsfarben
static let aktion = Color(red: 0.04, green: 0.52, blue: 1.0)
static var berechnet: Color {
  atelier ? Color(red: 0.14, green: 0.60, blue: 0.30) : Color(red: 0.19, green: 0.82, blue: 0.35)
}
static var vorgeschlagen: Color {
  atelier ? Color(red: 0.90, green: 0.48, blue: 0.08) : Color(red: 1.0, green: 0.62, blue: 0.04)
}
static var kritisch: Color {
  atelier ? Color(red: 0.86, green: 0.20, blue: 0.18) : Color(red: 1.0, green: 0.27, blue: 0.23)
}

static var sekundaer: Color {
  atelier ? Premium.textSoft : Color(red: 0.56, green: 0.56, blue: 0.58)
}

/// Hairline / Divider -- immer sichtbar auf aktueller Fläche
static var trennlinie: Color {
  atelier ? Color.black.opacity(0.10) : Color.white.opacity(0.08)
}

enum Material {
  private static var atelier: Bool { AppearanceStore.shared.istAtelier }

  static var l0: Color { atelier ? Premium.void : Color(red: 0.00, green: 0.00, blue: 0.00) }
  static var l1: Color { atelier ? Premium.ink : Color(red: 0.078, green: 0.078, blue: 0.086) }
  static var l2: Color { atelier ? Premium.panel : Color(red: 0.11, green: 0.11, blue: 0.12) }
  static var l3: Color { atelier ? Premium.well : Color(red: 0.17, green: 0.17, blue: 0.18) }
  static var l4: Color { atelier ? Premium.lift : Color(red: 0.227, green: 0.227, blue: 0.235) }

  static let radius0: CGFloat = 10
  static let radius1: CGFloat = 9
  static let radius2: CGFloat = 8
  static let radius3: CGFloat = 7
  static let radius4: CGFloat = 6
}

static func farbe(fuer h: Herkunft) -> Color {
  switch h {
  case .formel: return berechnet
  case .ki: return vorgeschlagen
  case .mensch: return aktion
  case .quelle: return sekundaer
  }
}
}

// MARK: - Zahlenformatierung mit Vorzeichen-Regel

enum InterfaceZahl {

static func waehrung(_ wert: Double, mitVorzeichen: Bool = true) -> String {
  let sign: String
  if !mitVorzeichen || wert == 0 { sign = "" }
  else if wert > 0 { sign = "+" }
  else { sign = "\u{2212}" }
  let f = NumberFormatter()
  f.numberStyle = .decimal
  f.locale = Locale(identifier: "de_DE")
  f.maximumFractionDigits = 0
  let betrag = f.string(from: NSNumber(value: abs(wert))) ?? "\(abs(wert))"
  return "\(sign)\(betrag) €"
}

static func prozent(_ wert: Double) -> String {
  let f = NumberFormatter()
  f.numberStyle = .percent
  f.locale = Locale(identifier: "de_DE")
  f.maximumFractionDigits = 0
  return f.string(from: NSNumber(value: wert)) ?? "\(Int(wert*100)) %"
}

static func dezimal(_ wert: Double, stellen: Int = 2) -> String {
  String(format: "%.\(stellen)f", wert).replacingOccurrences(of: ".", with: ",")
}
}

// MARK: - Karten-Ebene (L2)

struct InterfaceKarte<Inhalt: View>: View {
var ebene: Int = 2
var radius: CGFloat?
@ViewBuilder var inhalt: () -> Inhalt

private var farbe: Color {
 switch ebene {
 case 0: return InterfacePalette.Material.l0
 case 1: return InterfacePalette.Material.l1
 case 2: return InterfacePalette.Material.l2
 case 3: return InterfacePalette.Material.l3
 default: return InterfacePalette.Material.l4
 }
}

private var r: CGFloat {
 radius ?? {
   switch ebene {
   case 0: return InterfacePalette.Material.radius0
   case 1: return InterfacePalette.Material.radius1
   case 2: return InterfacePalette.Material.radius2
   case 3: return InterfacePalette.Material.radius3
   default: return InterfacePalette.Material.radius4
   }
 }()
}

var body: some View {
 inhalt()
   .background(
     RoundedRectangle(cornerRadius: r, style: .continuous).fill(farbe)
   )
   .overlay(
     RoundedRectangle(cornerRadius: r, style: .continuous)
       .stroke(InterfacePalette.trennlinie, lineWidth: 1)
   )
}
}

