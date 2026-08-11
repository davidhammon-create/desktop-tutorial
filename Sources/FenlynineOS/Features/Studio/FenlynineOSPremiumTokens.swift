import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// FENLYNINEOS PREMIUM -- ein Design-System für das ganze Produkt
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Filigran · Apple-nah · Noir (OLED) ODER Atelier (hell).
// Farben folgen AppearanceStore.shared -- Views, die den Store
// beobachten (Studio-Shell), invalidieren den Baum beim Umschalten.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum Premium {
private static var atelier: Bool { AppearanceStore.shared.istAtelier }

// Flächen
static var void: Color {
  atelier ? Color(red: 0.975, green: 0.975, blue: 0.98) : Color(red: 0.02, green: 0.02, blue: 0.025)
}
static var ink: Color {
  atelier ? Color.white : Color(red: 0.06, green: 0.06, blue: 0.07)
}
static var panel: Color {
  atelier ? Color.white : Color(red: 0.09, green: 0.09, blue: 0.10)
}
static var well: Color {
  atelier ? Color(red: 0.94, green: 0.94, blue: 0.95) : Color(red: 0.13, green: 0.13, blue: 0.14)
}
static var lift: Color {
  atelier ? Color(red: 0.92, green: 0.92, blue: 0.93) : Color(red: 0.18, green: 0.18, blue: 0.19)
}

// Bedeutung (nie zwei Rollen pro Farbe)
static let action = Color(red: 0.04, green: 0.52, blue: 1.0)
static var computed: Color {
  atelier ? Color(red: 0.14, green: 0.60, blue: 0.30) : Color(red: 0.19, green: 0.82, blue: 0.35)
}
static var proposed: Color {
  atelier ? Color(red: 0.90, green: 0.48, blue: 0.08) : Color(red: 1.0, green: 0.62, blue: 0.04)
}
static var critical: Color {
  atelier ? Color(red: 0.86, green: 0.20, blue: 0.18) : Color(red: 1.0, green: 0.27, blue: 0.23)
}
static var mute: Color {
  atelier ? Color(red: 0.55, green: 0.55, blue: 0.58) : Color(red: 0.55, green: 0.55, blue: 0.58)
}

// Text -- Atelier bewusst dunkler für Lesbarkeit auf Weiß
static var text: Color {
  atelier ? Color(red: 0.05, green: 0.05, blue: 0.07) : Color.white.opacity(0.96)
}
static var textSoft: Color {
  atelier ? Color(red: 0.26, green: 0.27, blue: 0.30) : Color.white.opacity(0.72)
}
static var textFaint: Color {
  atelier ? Color(red: 0.40, green: 0.41, blue: 0.44) : Color.white.opacity(0.48)
}
/// Immer weiß -- nur auf farbigen Aktionsflächen (Buttons)
static let onAction = Color.white

// Radii
static let rOuter: CGFloat = 14
static let rCard: CGFloat = 10
static let rChip: CGFloat = 7
static let rDot: CGFloat = 5

static var hairline: Color {
  atelier ? Color.black.opacity(0.08) : Color.white.opacity(0.07)
}

// Aliase für Appearance-Extension (Kompatibilität)
static var voidLive: Color { void }
static var inkLive: Color { ink }
static var panelLive: Color { panel }
static var wellLive: Color { well }
static var liftLive: Color { lift }
static var textLive: Color { text }
static var textSoftLive: Color { textSoft }
static var textFaintLive: Color { textFaint }
static var hairlineLive: Color { hairline }
static var actionLive: Color { action }
static var computedLive: Color { computed }
static var proposedLive: Color { proposed }
static var criticalLive: Color { critical }
}

// MARK: - Surface modifiers

struct PremiumPanel: ViewModifier {
var elevated: Bool = false
func body(content: Content) -> some View {
  content
    .background(
      RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
        .fill(elevated ? Premium.lift : Premium.panel)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
        .stroke(Premium.hairline, lineWidth: 1)
    )
}
}

struct PremiumChip: ViewModifier {
var active: Bool
var tint: Color = Premium.action
func body(content: Content) -> some View {
 content
   .font(.system(size: 11, weight: .semibold))
   .foregroundStyle(active ? (AppearanceStore.shared.istAtelier ? Premium.action : Color.white) : Premium.textSoft)
   .padding(.horizontal, 10)
   .padding(.vertical, 6)
   .background(
     RoundedRectangle(cornerRadius: Premium.rChip, style: .continuous)
       .fill(active ? tint.opacity(AppearanceStore.shared.istAtelier ? 0.12 : 0.22) : Color.clear)
   )
   .overlay(
     RoundedRectangle(cornerRadius: Premium.rChip, style: .continuous)
       .stroke(active ? tint.opacity(0.55) : Premium.hairline, lineWidth: 1)
   )
}
}

// MARK: - Rauchglas (visionOS-Fumé für das Studio)

/// Frosted-Glass-Fläche im Apple-/visionOS-Stil -- Material + Tönung +
/// Rim-Light. Funktioniert in Noir (dunkel) und Atelier (hell).
struct PremiumGlas: ViewModifier {
var radius: CGFloat = Premium.rCard
var elevated: Bool = false

func body(content: Content) -> some View {
 let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
 let atelier = AppearanceStore.shared.istAtelier
 content
   .background(
     shape
       .fill(.ultraThinMaterial)
       .overlay(shape.fill(atelier ? Color.white.opacity(0.55) : Color.white.opacity(0.045)))
       .overlay(
         shape.fill(
           LinearGradient(
             colors: [Color.white.opacity(atelier ? 0.35 : 0.07), Color.clear],
             startPoint: .topLeading, endPoint: .bottomTrailing
           )
         )
       )
   )
   .overlay(shape.stroke(atelier ? Color.black.opacity(0.09) : Color.white.opacity(0.13), lineWidth: 0.75))
   .clipShape(shape)
   .shadow(
     color: .black.opacity(elevated ? (atelier ? 0.10 : 0.35) : (atelier ? 0.05 : 0.18)),
     radius: elevated ? 18 : 8,
     y: elevated ? 8 : 3
   )
}
}

/// Glas-Leiste (Rail, Topbar, Seitenlisten) -- kantenlos, Material-basiert.
struct PremiumGlasLeiste: ViewModifier {
func body(content: Content) -> some View {
 let atelier = AppearanceStore.shared.istAtelier
 content
   .background(
     Rectangle()
       .fill(.ultraThinMaterial)
       .overlay(Rectangle().fill(atelier ? Color.white.opacity(0.5) : Color.black.opacity(0.22)))
   )
}
}

/// Aurora-Hintergrund: sehr dezente Farbtiefe, damit das Rauchglas
/// etwas zu brechen hat (Apple-typische Bühne, keine Ablenkung).
struct PremiumAurora: View {
var body: some View {
 let atelier = AppearanceStore.shared.istAtelier
 ZStack {
   Premium.void
   RadialGradient(
     colors: [Premium.action.opacity(atelier ? 0.06 : 0.10), .clear],
     center: .init(x: 0.15, y: 0.1), startRadius: 0, endRadius: 700
   )
   RadialGradient(
     colors: [Color(red: 0.85, green: 0.65, blue: 0.25).opacity(atelier ? 0.045 : 0.06), .clear],
     center: .init(x: 0.9, y: 0.85), startRadius: 0, endRadius: 800
   )
   RadialGradient(
     colors: [Color(red: 0.45, green: 0.3, blue: 0.85).opacity(atelier ? 0.03 : 0.05), .clear],
     center: .init(x: 0.75, y: 0.05), startRadius: 0, endRadius: 600
   )
 }
 .ignoresSafeArea()
}
}

extension View {
func premiumPanel(elevated: Bool = false) -> some View {
 modifier(PremiumPanel(elevated: elevated))
}
func premiumChip(active: Bool, tint: Color = Premium.action) -> some View {
 modifier(PremiumChip(active: active, tint: tint))
}
/// Rauchglas-Karte im visionOS-Stil.
func premiumGlas(radius: CGFloat = Premium.rCard, elevated: Bool = false) -> some View {
 modifier(PremiumGlas(radius: radius, elevated: elevated))
}
/// Glas-Leiste für Rails/Topbars/Sidebars.
func premiumGlasLeiste() -> some View {
 modifier(PremiumGlasLeiste())
}
}

extension InterfacePalette {
static func syncFromPremium() {}
}

