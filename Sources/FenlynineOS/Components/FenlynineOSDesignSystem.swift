import SwiftUI

// MARK: - Karten & visionOS-Glas

struct FenlynineOSCard<Content: View>: View {
var padding: CGFloat = FenlynineOSDesign.cardPadding
var elevated: Bool = true
@ViewBuilder let content: Content
@Environment(\.fenlynineOSGlasModus) private var glasModus

private var effektiverGlasModus: FenlynineOSGlasModus {
  if glasModus != .kein { return glasModus }
  return FenlynineOSDesignStore.shared.nutztVisionOSBlau ? .vollstaendig : .kein
}

var body: some View {
  content
    .padding(padding)
    .background { kartenHintergrund }
    .shadow(
      color: elevated ? FenlynineOSDesign.cardShadow : .clear,
      radius: schattenRadius,
      y: schattenY
    )
}

private var schattenRadius: CGFloat {
  switch effektiverGlasModus {
  case .vollstaendig: return elevated ? 24 : 8
  case .milchglasOverlay: return elevated ? 14 : 4
  case .kein: return FenlynineOSTheme.useGlass ? 20 : 12
  }
}

private var schattenY: CGFloat {
  switch effektiverGlasModus {
  case .vollstaendig: return elevated ? 12 : 4
  case .milchglasOverlay: return elevated ? 6 : 2
  case .kein: return FenlynineOSTheme.useGlass ? 10 : 6
  }
}

@ViewBuilder
private var kartenHintergrund: some View {
  let radius = effektiverGlasModus != .kein ? AppleUIKitTokens.radiusCard : FenlynineOSDesign.cornerRadiusLarge
  switch effektiverGlasModus {
  case .vollstaendig, .milchglasOverlay:
    VisionOSGlasFlaeche.karte(cornerRadius: radius, elevated: elevated)
  case .kein:
    if FenlynineOSTheme.useGlass {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(FenlynineOSTheme.glassFill)
        )
        .overlay(
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(FenlynineOSTheme.glassBorder, lineWidth: 0.5)
        )
    } else {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(FenlynineOSTheme.cardGradient)
        .overlay(
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(FenlynineOSTheme.border, lineWidth: 1)
        )
    }
  }
}
}

struct CommandPanel<Content: View>: View {
let titel: String
var maxHoehe: CGFloat? = AppleUIKitTokens.widgetMaxHeight
@ViewBuilder let content: Content
@Environment(\.fenlynineOSGlasModus) private var glasModus

private var effektiverGlasModus: FenlynineOSGlasModus {
  if glasModus != .kein { return glasModus }
  return FenlynineOSDesignStore.shared.nutztVisionOSBlau ? .vollstaendig : .kein
}

var body: some View {
  switch effektiverGlasModus {
  case .vollstaendig, .milchglasOverlay:
    VisionOSGlasWidget(titel: titel, maxHoehe: maxHoehe) { content }
  case .kein:
    FenlynineOSCard {
      VStack(alignment: .leading, spacing: 14) {
        Text(titel)
          .font(AppleUIKitTokens.widgetTitle)
          .foregroundStyle(FenlynineOSTheme.gold)
          .tracking(AppleUIKitTokens.widgetTitleTracking)
        content
      }
    }
    .frame(maxHeight: maxHoehe, alignment: .topLeading)
  }
}
}

struct FenlynineOSGlassBar<Content: View>: View {
@ViewBuilder let content: Content
@Environment(\.fenlynineOSGlasModus) private var glasModus

var body: some View {
 content
   .padding(.horizontal, 20)
   .padding(.vertical, 14)
   .background { leistenHintergrund }
   .overlay(alignment: .bottom) { FenlynineOSTheme.border.frame(height: 0.5) }
}

@ViewBuilder
private var leistenHintergrund: some View {
 if FenlynineOSDesignStore.shared.nutztVisionOSBlau || glasModus != .kein {
   VisionOSGlasFlaeche.leiste()
 } else if FenlynineOSTheme.useGlass {
   Rectangle().fill(.ultraThinMaterial)
 } else {
   Rectangle().fill(FenlynineOSTheme.surface)
 }
}
}

struct FenlynineOSSectionHeader: View {
let titel: String
var untertitel: String? = nil
var symbol: String? = nil

var body: some View {
 HStack(spacing: 8) {
   if let symbol {
     Image(systemName: symbol)
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(FenlynineOSDesignStore.shared.nutztVisionOSBlau ? FenlynineOSTheme.accent : FenlynineOSTheme.gold)
   }
   VStack(alignment: .leading, spacing: 2) {
     Text(titel)
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(FenlynineOSTheme.textPrimary)
     if let untertitel {
       Text(untertitel)
         .font(.caption2)
         .foregroundStyle(FenlynineOSTheme.textSecondary)
     }
   }
   Spacer()
 }
}
}

struct FenlynineOSMetricChip: View {
let titel: String
let wert: String
let farbe: Color
var compact: Bool = false
var transparenz: TransparenzInhalt? = nil

var body: some View {
 VStack(spacing: compact ? 2 : 4) {
   HStack(spacing: 3) {
     Text(wert)
       .font(AppleUIKitTokens.kpiWert)
       .foregroundStyle(farbe)
       .lineLimit(1)
       .minimumScaleFactor(0.7)
     if let t = transparenz {
       FenlynineOSTransparenzInfoButton(inhalt: t)
     }
   }
   Text(titel)
     .font(.system(size: 8, weight: .semibold))
     .foregroundStyle(FenlynineOSTheme.textSecondary)
     .textCase(.uppercase)
     .tracking(0.5)
 }
 .padding(.horizontal, compact ? 10 : 12)
 .padding(.vertical, compact ? 6 : 8)
 .background(farbe.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(farbe.opacity(0.25), lineWidth: 1))
}
}

struct FenlynineOSPrognoseRing: View {
let wert: Int
var groesse: CGFloat = 44
var showLabel: Bool = true
var transparenz: TransparenzInhalt? = nil

var body: some View {
 ZStack(alignment: .topTrailing) {
   ZStack {
     Circle().stroke(FenlynineOSTheme.border, lineWidth: groesse > 50 ? 8 : 4)
     Circle()
       .trim(from: 0, to: CGFloat(min(wert, 100)) / 100)
       .stroke(farbe, style: StrokeStyle(lineWidth: groesse > 50 ? 8 : 4, lineCap: .round))
       .rotationEffect(.degrees(-90))
     if showLabel {
       VStack(spacing: 0) {
         Text("\(wert)%")
           .font(.system(size: groesse * 0.22, weight: .bold))
           .foregroundStyle(FenlynineOSTheme.textPrimary)
         if groesse > 80 {
           Text(stufe)
             .font(.system(size: groesse * 0.1, weight: .bold))
             .foregroundStyle(farbe)
         }
       }
     }
   }
   .frame(width: groesse, height: groesse)
   if let t = transparenz {
     FenlynineOSTransparenzInfoButton(inhalt: t)
       .offset(x: 4, y: -4)
   }
 }
}

private var stufe: String {
 if wert >= 70 { return "HOCH" }
 if wert >= 45 { return "MITTEL" }
 return "NIEDRIG"
}

private var farbe: Color {
 if FenlynineOSDesignStore.shared.nutztVisionOSBlau { return FenlynineOSTheme.chartPrimary }
 if wert >= 70 { return FenlynineOSTheme.success }
 if wert >= 45 { return FenlynineOSTheme.warning }
 return FenlynineOSTheme.danger
}
}

struct FenlynineOSGoldProgressBar: View {
let wert: Double
var hoehe: CGFloat = 6

var body: some View {
 if FenlynineOSDesignStore.shared.nutztVisionOSBlau {
   VisionOSLeavesProgressBar(wert: wert, hoehe: hoehe)
 } else {
   GeometryReader { geo in
     ZStack(alignment: .leading) {
       Capsule().fill(Color.white.opacity(0.10))
       Capsule()
         .fill(FenlynineOSTheme.goldGradient)
         .frame(width: geo.size.width * CGFloat(min(max(wert, 0), 100) / 100))
     }
   }
   .frame(height: hoehe)
 }
}
}

struct FenlynineOSPrimaryButtonStyle: ButtonStyle {
var tint: Color = FenlynineOSTheme.accent
@Environment(\.fenlynineOSGlasModus) private var glasModus

func makeBody(configuration: Configuration) -> some View {
 configuration.label
   .font(AppleUIKitTokens.buttonLabel)
   .padding(.horizontal, AppleUIKitTokens.buttonPaddingH)
   .padding(.vertical, AppleUIKitTokens.buttonPaddingV)
   .foregroundStyle(.white)
   .background {
     if glasModus != .kein {
       RoundedRectangle(cornerRadius: 6, style: .continuous)
         .fill(MacOSSettingsTokens.selectionBlue.opacity(configuration.isPressed ? 0.85 : 1))
     } else {
       Capsule().fill(tint.opacity(configuration.isPressed ? 0.75 : 1))
     }
   }
   .opacity(configuration.isPressed ? 0.88 : 1)
   .scaleEffect(configuration.isPressed ? 0.97 : 1)
}
}

struct FenlynineOSCommandButton: View {
let titel: String
let action: () -> Void
@Environment(\.fenlynineOSGlasModus) private var glasModus

private var effektiverGlasModus: FenlynineOSGlasModus {
 if glasModus != .kein { return glasModus }
 return FenlynineOSDesignStore.shared.nutztVisionOSBlau ? .vollstaendig : .kein
}

var body: some View {
 if effektiverGlasModus != .kein {
   VisionOSGlasButton(titel: titel, stil: .primaerBlau, volleBreite: true, action: action)
 } else {
   Button(action: action) {
     Text(titel)
       .font(.system(size: 10, weight: .bold))
       .tracking(0.8)
       .foregroundStyle(FenlynineOSTheme.gold)
       .frame(maxWidth: .infinity)
       .padding(.vertical, 8)
       .overlay(RoundedRectangle(cornerRadius: 6).stroke(FenlynineOSTheme.borderGold, lineWidth: 1))
   }
   .buttonStyle(.plain)
 }
}
}

struct FenlynineOSKIStatusBadge: View {
enum Status { case bereit, laeuft, fehler, deaktiviert }
let status: Status
var text: String? = nil

var body: some View {
 HStack(spacing: 5) {
   Circle().fill(farbe).frame(width: 6, height: 6)
   Text(text ?? label)
     .font(.system(size: 10, weight: .semibold))
 }
 .foregroundStyle(farbe)
 .padding(.horizontal, 8)
 .padding(.vertical, 4)
 .background(farbe.opacity(0.12), in: Capsule())
}

private var label: String {
 switch status {
 case .bereit: return "KI bereit"
 case .laeuft: return "KI analysiert…"
 case .fehler: return "KI-Fehler"
 case .deaktiviert: return "Manuell"
 }
}

private var farbe: Color {
 switch status {
 case .bereit: return FenlynineOSTheme.success
 case .laeuft: return FenlynineOSTheme.warning
 case .fehler: return FenlynineOSTheme.danger
 case .deaktiviert: return FenlynineOSTheme.textSecondary
 }
}
}

struct FenlynineOSHeroBanner: View {
let titel: String
var untertitel: String? = nil
var badge: String? = nil

var body: some View {
 HStack {
   VStack(alignment: .leading, spacing: 8) {
     if let badge {
       Text(badge.uppercased())
         .font(.system(size: 9, weight: .bold))
         .tracking(2)
         .foregroundStyle(FenlynineOSTheme.gold)
     }
     Text(titel.uppercased())
       .font(.system(size: 26, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.textPrimary)
     if let untertitel {
       Text(untertitel)
         .font(.system(size: 13))
         .foregroundStyle(FenlynineOSTheme.textSecondary)
     }
   }
   Spacer()
 }
}
}

struct FenlynineOSRiskDot: View {
enum Level: String { case hoch = "HOCH", mittel = "MITTEL", niedrig = "NIEDRIG" }
let level: Level

private var farbe: Color {
 switch level {
 case .hoch: return AppleUIKitTokens.systemRed
 case .mittel: return AppleUIKitTokens.systemOrange
 case .niedrig: return AppleUIKitTokens.systemGreen
 }
}

var body: some View {
 HStack(spacing: 4) {
   Circle().fill(farbe).frame(width: 7, height: 7)
   Text(level.rawValue)
     .font(.system(size: 9, weight: .bold))
     .foregroundStyle(FenlynineOSTheme.textSecondary)
 }
}
}

// MARK: - App-Hintergrund Modifier

struct FenlynineOSCommandBackground: ViewModifier {
@Environment(\.fenlynineOSGlasModus) private var glasModus

func body(content: Content) -> some View {
 ZStack {
   if FenlynineOSDesignStore.shared.nutztVisionOSBlau || glasModus != .kein {
     FenlynineOSAppBackground()
   } else if FenlynineOSDesignStore.shared.tokens.useGlass && FenlynineOSDesignStore.shared.aktivesModell == .visionOSDark {
     FenlynineOSAppBackground()
   } else {
     FenlynineOSTheme.background.ignoresSafeArea()
   }
   content
 }
 .preferredColorScheme(FenlynineOSDesignStore.shared.nutztVisionOSBlau ? .dark : FenlynineOSTheme.preferredScheme)
 .tint(FenlynineOSTheme.accent)
}
}

extension View {
func fenlynineOSCommandBackground() -> some View {
 modifier(FenlynineOSCommandBackground())
}
}

