import SwiftUI

// MARK: - Glas-Modus (visionOS vollständig vs. Milchglas-Overlay auf Kernmodulen)

private struct FenlynineOSGlasModusKey: EnvironmentKey {
static let defaultValue: FenlynineOSGlasModus = .vollstaendig
}

private struct FenlynineOSVisionOSChromeKey: EnvironmentKey {
static let defaultValue = false
}

extension EnvironmentValues {
var fenlynineOSGlasModus: FenlynineOSGlasModus {
  get { self[FenlynineOSGlasModusKey.self] }
  set { self[FenlynineOSGlasModusKey.self] = newValue }
}

var fenlynineOSVisionOSChrome: Bool {
  get { self[FenlynineOSVisionOSChromeKey.self] }
  set { self[FenlynineOSVisionOSChromeKey.self] = newValue }
}

var fenlynineOSMilchglasOverlay: Bool {
  fenlynineOSGlasModus == .milchglasOverlay
}
}

extension SeitenleistenEintrag {
var nutztVisionOSChrome: Bool { glasModus == .vollstaendig }
}

// MARK: - Glas-Oberfläche (visionOS Milchglas)

struct VisionOSGlassSurface: ViewModifier {
var cornerRadius: CGFloat = 28
var elevated: Bool = true
@Environment(\.fenlynineOSGlasModus) private var glasModus

func body(content: Content) -> some View {
  switch glasModus {
  case .vollstaendig, .milchglasOverlay:
    content
      .background {
        VisionOSGlasFlaeche.karte(cornerRadius: cornerRadius, elevated: elevated)
      }
  case .kein:
    content
  }
}
}

extension View {
func visionOSGlass(cornerRadius: CGFloat = 28, elevated: Bool = true) -> some View {
  modifier(VisionOSGlassSurface(cornerRadius: cornerRadius, elevated: elevated))
}

func fenlynineOSModuleChrome(for eintrag: SeitenleistenEintrag) -> some View {
  environment(\.fenlynineOSGlasModus, eintrag.glasModus)
    .environment(\.fenlynineOSVisionOSChrome, eintrag.nutztVisionOSChrome)
    .modifier(FenlynineOSGlasModusSync())
}

/// Programmweite visionOS-Glas-Chrome (Theme, Buttons, Farben).
func fenlynineOSProgramGlasChrome() -> some View {
  modifier(FenlynineOSProgramGlasChromeModifier())
}
}

// MARK: - Glas-Modus -> DesignStore (programmweiter Farbumschalter)

struct FenlynineOSGlasModusSync: ViewModifier {
@Environment(\.fenlynineOSGlasModus) private var glasModus
@Environment(\.fenlynineOSFensterModus) private var fensterModus

func body(content: Content) -> some View {
  content
    .onAppear {
      // Modulfenster dürfen den globalen Design-Store nicht umschalten
      guard !fensterModus else { return }
      FenlynineOSDesignStore.shared.aktiverGlasModus = glasModus
    }
    .onChange(of: glasModus) { _, neu in
      guard !fensterModus else { return }
      FenlynineOSDesignStore.shared.aktiverGlasModus = neu
    }
}
}

struct FenlynineOSProgramGlasChromeModifier: ViewModifier {
@Bindable private var appearance = AppearanceStore.shared

func body(content: Content) -> some View {
  // Atelier: kein dunkles Milchglas -- sonst weiße/helle Texte unlesbar
  let glas: FenlynineOSGlasModus = appearance.istAtelier ? .kein : .vollstaendig
  content
    .environment(\.fenlynineOSGlasModus, glas)
    .environment(\.fenlynineOSVisionOSChrome, !appearance.istAtelier)
    .modifier(FenlynineOSGlasModusSync())
   .tint(FenlynineOSTheme.accent)
}
}

func visionOSRimLight(cornerRadius: CGFloat) -> some View {
RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
 .stroke(
   LinearGradient(
     colors: [.white.opacity(0.38), .white.opacity(0.08), .white.opacity(0.04)],
     startPoint: .topLeading,
     endPoint: .bottomTrailing
   ),
   lineWidth: 0.6
 )
}

// MARK: - Buttons

struct VisionOSPillButton: View {
enum Stil { case primaer, sekundaer, destruktiv, ghost }

let titel: String
var symbol: String? = nil
var stil: Stil = .primaer
let action: () -> Void

var body: some View {
 Button(action: action) {
   HStack(spacing: 6) {
     if let symbol {
       Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
     }
     Text(titel)
       .font(.system(size: 13, weight: .semibold))
   }
   .padding(.horizontal, 18)
   .padding(.vertical, 10)
   .foregroundStyle(vordergrund)
   .background { hintergrundShape }
   .overlay(Capsule().stroke(rahmen, lineWidth: stil == .ghost ? 0.5 : 0))
 }
 .buttonStyle(.plain)
}

@ViewBuilder
private var hintergrundShape: some View {
 switch stil {
 case .primaer:
   Capsule().fill(AppleUIKitTokens.systemBlue.opacity(0.35))
     .overlay(Capsule().fill(.thinMaterial))
     .overlay(Capsule().stroke(AppleUIKitTokens.systemBlue.opacity(0.5), lineWidth: 0.6))
 case .sekundaer:
   Capsule().fill(.regularMaterial)
     .overlay(Capsule().fill(VisionOSGlasFlaeche.basisDunkel))
     .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.6))
 case .ghost:
   Capsule().fill(Color.white.opacity(0.04))
 case .destruktiv:
   Capsule().fill(Color.red.opacity(0.12))
 }
}

private var vordergrund: Color {
 switch stil {
 case .primaer: return .white
 case .destruktiv: return Color(red: 1, green: 0.35, blue: 0.32)
 case .sekundaer, .ghost: return FenlynineOSTheme.textPrimary
 }
}

private var rahmen: Color {
 switch stil {
 case .ghost: return .white.opacity(0.18)
 case .sekundaer: return .white.opacity(0.12)
 default: return .clear
 }
}
}

struct VisionOSIconButton: View {
let symbol: String
var farbe: Color = FenlynineOSTheme.accent
var groesse: CGFloat = 36
let action: () -> Void
@Environment(\.fenlynineOSGlasModus) private var glasModus

var body: some View {
 Button(action: action) {
   Image(systemName: symbol)
     .font(.system(size: groesse * 0.38, weight: .semibold))
     .foregroundStyle(.white)
     .frame(width: groesse, height: groesse)
     .background {
       if glasModus != .kein {
         Circle()
           .fill(.thinMaterial)
           .overlay(Circle().fill(farbe.opacity(0.38)))
           .overlay(Circle().stroke(farbe.opacity(0.55), lineWidth: 0.7))
       } else {
         Circle().fill(farbe)
       }
     }
     .shadow(color: farbe.opacity(glasModus != .kein ? 0.22 : 0.35), radius: 8, y: 4)
 }
 .buttonStyle(.plain)
}
}

// MARK: - Segmented Control (Glas-Pille)

struct VisionOSSegmentedPicker<Selection: Hashable>: View {
let optionen: [(Selection, String, String)]
@Binding var auswahl: Selection

var body: some View {
 HStack(spacing: 4) {
   ForEach(optionen, id: \.0) { opt in
     Button {
       withAnimation(.easeInOut(duration: 0.2)) { auswahl = opt.0 }
     } label: {
       HStack(spacing: 5) {
         Image(systemName: opt.2).font(.system(size: 10))
         Text(opt.1).font(.system(size: 11, weight: auswahl == opt.0 ? .semibold : .regular))
       }
       .foregroundStyle(auswahl == opt.0 ? .white : FenlynineOSTheme.textSecondary)
       .padding(.horizontal, 12)
       .padding(.vertical, 7)
       .background {
         if auswahl == opt.0 {
           VisionOSGlasFlaeche.button(stil: .primaerBlau)
         } else {
           Color.clear
         }
       }
     }
     .buttonStyle(.plain)
   }
 }
 .padding(4)
 .background { VisionOSGlasFlaeche.floatingPill() }
}
}

// MARK: - Listen-Zeile

struct VisionOSListRow<Trailing: View>: View {
let symbol: String
var symbolFarbe: Color = FenlynineOSTheme.accent
let titel: String
var untertitel: String? = nil
@ViewBuilder var trailing: () -> Trailing

var body: some View {
 HStack(spacing: 12) {
   Image(systemName: symbol)
     .font(.system(size: 14, weight: .semibold))
     .foregroundStyle(.white)
     .frame(width: 32, height: 32)
     .background {
       RoundedRectangle(cornerRadius: 8, style: .continuous)
         .fill(.thinMaterial)
         .overlay(
           RoundedRectangle(cornerRadius: 8, style: .continuous)
             .fill(symbolFarbe.opacity(0.42))
         )
         .overlay(
           RoundedRectangle(cornerRadius: 8, style: .continuous)
             .stroke(symbolFarbe.opacity(0.55), lineWidth: 0.6)
         )
     }
   VStack(alignment: .leading, spacing: 2) {
     Text(titel).font(.subheadline.weight(.medium)).foregroundStyle(FenlynineOSTheme.textPrimary)
     if let untertitel {
       Text(untertitel).font(.caption).foregroundStyle(FenlynineOSTheme.textSecondary)
     }
   }
   Spacer()
   trailing()
 }
 .padding(.horizontal, 14)
 .padding(.vertical, 10)
 .visionOSGlass(cornerRadius: 16, elevated: false)
}
}

// MARK: - KPI-Karte (Cockpit)

struct VisionOSKPICard: View {
let titel: String
let wert: String
let gesamt: String
let symbol: String
let farbe: Color

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack {
     Image(systemName: symbol)
       .font(.title3)
       .foregroundStyle(farbe)
     Spacer()
     Image(systemName: "arrow.up.right")
       .font(.caption2)
       .foregroundStyle(FenlynineOSTheme.textTertiary)
   }
   Text(wert)
     .font(AppleUIKitTokens.kpiWert)
     .foregroundStyle(FenlynineOSTheme.textPrimary)
   Text(titel)
     .font(AppleUIKitTokens.kpiTitel)
     .foregroundStyle(FenlynineOSTheme.textSecondary)
   Text(gesamt)
     .font(AppleUIKitTokens.caption2)
     .foregroundStyle(FenlynineOSTheme.textTertiary)
 }
 .padding(AppleUIKitTokens.widgetPadding)
 .frame(maxWidth: .infinity, minHeight: AppleUIKitTokens.widgetKPIHeight, maxHeight: AppleUIKitTokens.widgetKPIHeight, alignment: .leading)
 .visionOSGlass(cornerRadius: AppleUIKitTokens.radiusWidget)
}
}

// MARK: - Modul-Hintergrund

struct FenlynineOSModuleBackground: ViewModifier {
let glasModus: FenlynineOSGlasModus

func body(content: Content) -> some View {
 ZStack {
   if glasModus != .kein {
     FenlynineOSAppBackground()
   } else {
     FenlynineOSTheme.background.ignoresSafeArea()
   }
   content
 }
 .preferredColorScheme(glasModus != .kein ? .dark : FenlynineOSTheme.preferredScheme)
 .tint(FenlynineOSTheme.accent)
}
}

