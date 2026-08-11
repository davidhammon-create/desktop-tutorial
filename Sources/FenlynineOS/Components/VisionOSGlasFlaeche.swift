import SwiftUI

// MARK: - visionOS Glas-Flächen (FenlynineOS Vision Redesign PDF)

enum VisionOSGlasFlaeche {
static let basisDunkel = Color.black.opacity(0.18)
static let basisHell = Color.white.opacity(0.06)
static let basisBlau = AppleUIKitTokens.systemBlue.opacity(0.06)
static let basisWidget = AppleUIKitTokens.kachelFill

/// Fumé-Rauchglas: Material + sehr leichte Tönung
@ViewBuilder
private static func fumeGlas<S: Shape>(_ shape: S) -> some View {
  shape
    .fill(.thinMaterial)
    .overlay(shape.fill(AppleUIKitTokens.glasFume))
    .overlay(shape.fill(basisHell.opacity(0.05)))
}

// MARK: Äußeres Hauptpanel

@ViewBuilder
static func hauptPanel(cornerRadius: CGFloat = AppleUIKitTokens.radiusPanelOuter) -> some View {
  let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  fumeGlas(shape)
    .overlay(shape.fill(AppleUIKitTokens.panelOuterFill.opacity(0.55)))
    .overlay(visionOSRimLight(cornerRadius: cornerRadius))
    .overlay(shape.stroke(Color.white.opacity(0.14), lineWidth: 0.75))
    .shadow(color: .black.opacity(0.32), radius: 32, y: 14)
}

@ViewBuilder
static func kachel(cornerRadius: CGFloat = AppleUIKitTokens.radiusKachel, elevated: Bool = false) -> some View {
  let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  fumeGlas(shape)
    .overlay(
      shape.fill(
        LinearGradient(
          colors: [Color.white.opacity(0.05), Color.clear],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    )
    .overlay(shape.stroke(AppleUIKitTokens.kachelBorder, lineWidth: 0.6))
    .shadow(
      color: .black.opacity(elevated ? 0.22 : 0.10),
      radius: elevated ? 12 : 5,
      y: elevated ? 5 : 2
    )
}

@ViewBuilder
static func karte(cornerRadius: CGFloat = AppleUIKitTokens.radiusKachel, elevated: Bool = false) -> some View {
  kachel(cornerRadius: cornerRadius, elevated: elevated)
}

@ViewBuilder
static func widget(cornerRadius: CGFloat = AppleUIKitTokens.radiusKachel, elevated: Bool = false) -> some View {
  kachel(cornerRadius: cornerRadius, elevated: elevated)
}

@ViewBuilder
static func schwebendesFenster(cornerRadius: CGFloat = AppleUIKitTokens.radiusPanelOuter) -> some View {
  hauptPanel(cornerRadius: cornerRadius)
}

// MARK: Glas-Button

@ViewBuilder
static func button(stil: VisionOSGlasButtonStil) -> some View {
  switch stil {
  case .primaerBlau:
    Capsule()
      .fill(MacOSSettingsTokens.selectionBlue)
      .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
      .shadow(color: MacOSSettingsTokens.selectionBlue.opacity(0.25), radius: 6, y: 2)
  case .sekundaer:
    Capsule()
      .fill(.thinMaterial)
      .overlay(Capsule().fill(basisDunkel.opacity(0.30)))
      .overlay(Capsule().fill(basisHell.opacity(0.04)))
      .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 0.55))
      .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
  case .ghost:
    Capsule()
      .fill(.thinMaterial.opacity(0.35))
      .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
  }
}

@ViewBuilder
static func floatingPill(vertical: Bool = false) -> some View {
  Capsule()
    .fill(.thinMaterial)
    .overlay(Capsule().fill(basisDunkel.opacity(0.22)))
    .overlay(Capsule().fill(basisBlau))
    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.65))
    .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
}

@ViewBuilder
static func seitenleiste(cornerRadius: CGFloat = 28) -> some View {
 let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
 fumeGlas(shape)
   .overlay(shape.fill(basisDunkel.opacity(0.12)))
   .overlay(shape.stroke(Color.white.opacity(0.14), lineWidth: 0.65))
   .shadow(color: .black.opacity(0.30), radius: 28, y: 10)
}

@ViewBuilder
static func leiste() -> some View {
 Rectangle()
   .fill(.thinMaterial)
   .overlay(Rectangle().fill(basisDunkel.opacity(0.18)))
   .overlay(Rectangle().fill(basisBlau))
}

@ViewBuilder
static func sidebarZeile(aktiv: Bool, cornerRadius: CGFloat = 12) -> some View {
 if aktiv {
   Capsule()
     .fill(.thinMaterial)
     .overlay(Capsule().fill(AppleUIKitTokens.systemBlue.opacity(0.26)))
     .overlay(Capsule().stroke(AppleUIKitTokens.systemBlue.opacity(0.45), lineWidth: 0.6))
 } else {
   RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
     .fill(Color.clear)
 }
}

@ViewBuilder
static func adaptivePanel(cornerRadius: CGFloat = AppleUIKitTokens.radiusKachel, elevated: Bool = false) -> some View {
 if FenlynineOSDesignStore.shared.nutztVisionOSBlau {
   kachel(cornerRadius: cornerRadius, elevated: elevated)
 } else {
   RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
     .fill(FenlynineOSTheme.surface)
     .overlay(
       RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
         .stroke(FenlynineOSTheme.border, lineWidth: 1)
     )
 }
}
}

struct FenlynineOSVisionOSStilModifier: ViewModifier {
let aktiv: Bool
func body(content: Content) -> some View {
 if aktiv {
   content
     .environment(\.fenlynineOSGlasModus, .vollstaendig)
     .environment(\.fenlynineOSVisionOSChrome, true)
     .tint(AppleUIKitTokens.systemBlue)
 } else { content }
}
}

extension View {
func fenlynineOSVisionOSStil(aktiv: Bool = true) -> some View {
 modifier(FenlynineOSVisionOSStilModifier(aktiv: aktiv))
}

func fenlynineOSAdaptivePanel(cornerRadius: CGFloat = AppleUIKitTokens.radiusKachel, elevated: Bool = false) -> some View {
 background { VisionOSGlasFlaeche.adaptivePanel(cornerRadius: cornerRadius, elevated: elevated) }
}

/// PDF: Inhalt in äußerem Glas-Panel (Weiß 10 %)
func fenlynineOSVisionHauptPanel(abstand: CGFloat = 20) -> some View {
 padding(abstand)
   .background { VisionOSGlasFlaeche.hauptPanel() }
   .clipShape(RoundedRectangle(cornerRadius: AppleUIKitTokens.radiusPanelOuter, style: .continuous))
}
}

