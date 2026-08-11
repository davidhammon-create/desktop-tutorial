import SwiftUI

// MARK: - Organon Design-Modelle (PDF: 8 Rendering-Varianten)

enum FenlynineOSDesignModell: String, CaseIterable, Identifiable, Codable {
case nocturne = "modell1"
case appleLight = "modell2"
case visionOSDark = "modell3"
case metro = "modell4"
case bubbles = "modell5"
case orbit = "modell6"
case treemap = "modell7"
case corporateHell = "modell8"

var id: String { rawValue }

var nummer: Int {
  switch self {
  case .nocturne: 1; case .appleLight: 2; case .visionOSDark: 3; case .metro: 4
  case .bubbles: 5; case .orbit: 6; case .treemap: 7; case .corporateHell: 8
  }
}

var bezeichnung: String {
  switch self {
  case .nocturne: return "Nocturne"
  case .appleLight: return "Apple Light"
  case .visionOSDark: return "Apple Dark · visionOS"
  case .metro: return "Metro-Plan"
  case .bubbles: return "Bubbles"
  case .orbit: return "Orbit"
  case .treemap: return "Treemap"
  case .corporateHell: return "Corporate"
  }
}

var kurzbeschreibung: String {
  switch self {
  case .nocturne: return "Dunkler Canvas, Raster, Leucht-Rand"
  case .appleLight: return "Helles macOS/iOS, weiße Karten"
  case .visionOSDark: return "Glas auf Schwarz, Systemblau"
  case .metro: return "U-Bahn-Linien, Stationen"
  case .bubbles: return "Kreispackung, Größe = Team"
  case .orbit: return "Radial, Zentrum = Kanzlei"
  case .treemap: return "Kacheln, Fläche = Personal"
  case .corporateHell: return "Konzern-Übersicht, hell"
  }
}

var symbol: String {
  switch self {
  case .nocturne: return "moon.stars.fill"
  case .appleLight: return "sun.max.fill"
  case .visionOSDark: return "visionpro"
  case .metro: return "tram.fill"
  case .bubbles: return "circle.hexagongrid.fill"
  case .orbit: return "circle.circle"
  case .treemap: return "square.grid.3x3.fill"
  case .corporateHell: return "building.2.fill"
  }
}

var istHauptmodell: Bool { self == .visionOSDark }

var istArbeitsmodell: Bool {
  switch self {
  case .visionOSDark, .appleLight, .nocturne: return true
  default: return false
  }
}

var istPraesentationsmodell: Bool {
  switch self {
  case .metro, .bubbles, .orbit: return true
  default: return false
  }
}
}

// MARK: - Design-Tokens pro Modell

struct FenlynineOSDesignTokens {
let background: Color
let surface: Color
let surfaceElevated: Color
let glassFill: Color
let glassBorder: Color
let border: Color
let borderAccent: Color
let accent: Color
let accentSecondary: Color
let brand: Color
let brandLight: Color
let brandDark: Color
let textPrimary: Color
let textSecondary: Color
let textTertiary: Color
let success: Color
let warning: Color
let danger: Color
let cornerRadius: CGFloat
let cornerRadiusLarge: CGFloat
let cardShadow: Color
let useGlass: Bool
let useGrid: Bool
let glowOnSelection: Bool
let preferredScheme: ColorScheme
let organonStil: OrganonKartenStil

var accentGradient: LinearGradient {
 LinearGradient(colors: [accentSecondary, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
}

var brandGradient: LinearGradient {
 LinearGradient(colors: [brandLight, brand, brandDark], startPoint: .topLeading, endPoint: .bottomTrailing)
}

var cardGradient: LinearGradient {
 LinearGradient(colors: [surfaceElevated, surface], startPoint: .top, endPoint: .bottom)
}

var sidebarSelected: LinearGradient {
 LinearGradient(colors: [accent.opacity(0.28), accent.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
}

static func fuer(_ modell: FenlynineOSDesignModell) -> FenlynineOSDesignTokens {
 switch modell {
 case .nocturne: return nocturne
 case .appleLight: return appleLight
 case .visionOSDark: return visionOSDark
 case .metro: return visionOSDark.angepasst(accent: Color(red: 0.95, green: 0.55, blue: 0.1), organonStil: .metro)
 case .bubbles: return visionOSDark.angepasst(accent: Color(red: 0.35, green: 0.78, blue: 0.95), organonStil: .bubbles)
 case .orbit: return visionOSDark.angepasst(accent: Color(red: 0.75, green: 0.45, blue: 0.95), organonStil: .orbit)
 case .treemap: return visionOSDark.angepasst(accent: Color(red: 0.4, green: 0.72, blue: 0.55), organonStil: .treemap)
 case .corporateHell: return corporateHell
 }
}

func angepasst(accent: Color, organonStil: OrganonKartenStil) -> FenlynineOSDesignTokens {
 FenlynineOSDesignTokens(
   background: background, surface: surface, surfaceElevated: surfaceElevated,
   glassFill: glassFill, glassBorder: glassBorder, border: border, borderAccent: borderAccent,
   accent: accent, accentSecondary: accent.opacity(0.7),
   brand: brand, brandLight: brandLight, brandDark: brandDark,
   textPrimary: textPrimary, textSecondary: textSecondary, textTertiary: textTertiary,
   success: success, warning: warning, danger: danger,
   cornerRadius: cornerRadius, cornerRadiusLarge: cornerRadiusLarge,
   cardShadow: cardShadow, useGlass: useGlass, useGrid: useGrid,
   glowOnSelection: glowOnSelection, preferredScheme: preferredScheme,
   organonStil: organonStil
 )
}

// Modell 3 -- Apple Dark / visionOS (HAUPTMODELL)
static let visionOSDark = FenlynineOSDesignTokens(
 background: Color(red: 0.04, green: 0.04, blue: 0.05),
 surface: Color.white.opacity(0.06),
 surfaceElevated: Color.white.opacity(0.09),
 glassFill: Color.white.opacity(0.08),
 glassBorder: Color.white.opacity(0.16),
 border: Color.white.opacity(0.1),
 borderAccent: Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.35),
 accent: AppleUIKitTokens.systemBlue,
 accentSecondary: Color(red: 0.35, green: 0.68, blue: 1.0),
 brand: Color(red: 0.82, green: 0.68, blue: 0.38),
 brandLight: Color(red: 0.92, green: 0.82, blue: 0.55),
 brandDark: Color(red: 0.55, green: 0.42, blue: 0.18),
 textPrimary: .white,
 textSecondary: Color.white.opacity(0.62),
 textTertiary: Color.white.opacity(0.38),
 success: Color(red: 0.3, green: 0.85, blue: 0.55),
 warning: Color(red: 1.0, green: 0.75, blue: 0.2),
 danger: Color(red: 1.0, green: 0.35, blue: 0.32),
 cornerRadius: 14,
 cornerRadiusLarge: 22,
 cardShadow: Color.black.opacity(0.45),
 useGlass: true,
 useGrid: false,
 glowOnSelection: false,
 preferredScheme: .dark,
 organonStil: .visionOS
)

// Modell 2 -- Apple Light
static let appleLight = FenlynineOSDesignTokens(
 background: Color(red: 0.95, green: 0.95, blue: 0.97),
 surface: Color.white,
 surfaceElevated: Color.white,
 glassFill: Color.white.opacity(0.85),
 glassBorder: Color.black.opacity(0.08),
 border: Color.black.opacity(0.08),
 borderAccent: Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.25),
 accent: Color(red: 0.0, green: 0.48, blue: 1.0),
 accentSecondary: Color(red: 0.35, green: 0.62, blue: 1.0),
 brand: Color(red: 0.72, green: 0.58, blue: 0.28),
 brandLight: Color(red: 0.85, green: 0.75, blue: 0.45),
 brandDark: Color(red: 0.45, green: 0.32, blue: 0.12),
 textPrimary: Color(red: 0.08, green: 0.08, blue: 0.1),
 textSecondary: Color.black.opacity(0.55),
 textTertiary: Color.black.opacity(0.35),
 success: Color(red: 0.2, green: 0.72, blue: 0.38),
 warning: Color(red: 0.95, green: 0.62, blue: 0.05),
 danger: Color(red: 0.92, green: 0.25, blue: 0.22),
 cornerRadius: 12,
 cornerRadiusLarge: 18,
 cardShadow: Color.black.opacity(0.08),
 useGlass: true,
 useGrid: false,
 glowOnSelection: false,
 preferredScheme: .light,
 organonStil: .appleLight
)

// Modell 1 -- Nocturne (Prototyp)
static let nocturne = FenlynineOSDesignTokens(
 background: Color(red: 0.04, green: 0.04, blue: 0.05),
 surface: Color(red: 0.08, green: 0.08, blue: 0.09),
 surfaceElevated: Color(red: 0.11, green: 0.11, blue: 0.12),
 glassFill: Color(red: 0.1, green: 0.1, blue: 0.11),
 glassBorder: Color(red: 0.78, green: 0.65, blue: 0.35).opacity(0.35),
 border: Color.white.opacity(0.08),
 borderAccent: Color(red: 0.95, green: 0.82, blue: 0.25).opacity(0.5),
 accent: Color(red: 0.95, green: 0.82, blue: 0.25),
 accentSecondary: Color(red: 0.82, green: 0.68, blue: 0.38),
 brand: Color(red: 0.82, green: 0.68, blue: 0.38),
 brandLight: Color(red: 0.92, green: 0.82, blue: 0.55),
 brandDark: Color(red: 0.55, green: 0.42, blue: 0.18),
 textPrimary: .white,
 textSecondary: Color.white.opacity(0.55),
 textTertiary: Color.white.opacity(0.35),
 success: Color(red: 0.35, green: 0.78, blue: 0.45),
 warning: Color(red: 0.95, green: 0.75, blue: 0.25),
 danger: Color(red: 0.92, green: 0.32, blue: 0.28),
 cornerRadius: 10,
 cornerRadiusLarge: 12,
 cardShadow: Color.black.opacity(0.4),
 useGlass: false,
 useGrid: true,
 glowOnSelection: true,
 preferredScheme: .dark,
 organonStil: .nocturne
)

// Modell 8 -- Corporate Hell
static let corporateHell = FenlynineOSDesignTokens(
 background: Color(red: 0.97, green: 0.97, blue: 0.98),
 surface: Color.white,
 surfaceElevated: Color(red: 0.99, green: 0.99, blue: 1.0),
 glassFill: Color.white,
 glassBorder: Color(red: 0.2, green: 0.45, blue: 0.85).opacity(0.15),
 border: Color.black.opacity(0.06),
 borderAccent: Color(red: 0.15, green: 0.4, blue: 0.8).opacity(0.3),
 accent: Color(red: 0.15, green: 0.4, blue: 0.8),
 accentSecondary: Color(red: 0.35, green: 0.58, blue: 0.92),
 brand: Color(red: 0.15, green: 0.4, blue: 0.8),
 brandLight: Color(red: 0.35, green: 0.58, blue: 0.92),
 brandDark: Color(red: 0.1, green: 0.28, blue: 0.6),
 textPrimary: Color(red: 0.1, green: 0.12, blue: 0.18),
 textSecondary: Color.black.opacity(0.5),
 textTertiary: Color.black.opacity(0.32),
 success: Color(red: 0.15, green: 0.65, blue: 0.35),
 warning: Color(red: 0.9, green: 0.55, blue: 0.05),
 danger: Color(red: 0.85, green: 0.2, blue: 0.18),
 cornerRadius: 8,
 cornerRadiusLarge: 12,
 cardShadow: Color.black.opacity(0.06),
 useGlass: false,
 useGrid: false,
 glowOnSelection: false,
 preferredScheme: .light,
 organonStil: .corporate
)
}

enum OrganonKartenStil {
case visionOS, appleLight, nocturne, metro, bubbles, orbit, treemap, corporate
}

// MARK: - Globaler Design-Store

@Observable
final class FenlynineOSDesignStore {
static let shared = FenlynineOSDesignStore()

private let speicherKey = "fenlynineos_design_modell"
private let hintergrundKey = "fenlynineos_hintergrund"

/// Programmweiter Glas-Schalter -- synchronisiert aus `fenlynineOSGlasModus` Environment.
/// `.kein` nur in Strategos -> Gold/Legacy bleibt erhalten.
var aktiverGlasModus: FenlynineOSGlasModus = .vollstaendig

var nutztVisionOSBlau: Bool { aktiverGlasModus != .kein }

var aktiverHintergrund: FenlynineOSHintergrundStil {
 didSet {
   UserDefaults.standard.set(aktiverHintergrund.rawValue, forKey: hintergrundKey)
 }
}

var aktivesModell: FenlynineOSDesignModell {
 didSet {
   UserDefaults.standard.set(aktivesModell.rawValue, forKey: speicherKey)
   tokens = FenlynineOSDesignTokens.fuer(aktivesModell)
 }
}

var tokens: FenlynineOSDesignTokens

private init() {
 let raw = UserDefaults.standard.string(forKey: speicherKey)
 let modell = FenlynineOSDesignModell(rawValue: raw ?? "") ?? .visionOSDark
 aktivesModell = modell
 tokens = FenlynineOSDesignTokens.fuer(modell)

 let hRaw = UserDefaults.standard.string(forKey: hintergrundKey)
 aktiverHintergrund = FenlynineOSHintergrundStil(rawValue: hRaw ?? "") ?? .ambient
}

func setzeModell(_ modell: FenlynineOSDesignModell) {
 aktivesModell = modell
}

func setzeHintergrund(_ stil: FenlynineOSHintergrundStil) {
 aktiverHintergrund = stil
}
}

// MARK: - Theme-Bridge (bestehende API bleibt kompatibel)

enum FenlynineOSTheme {
private static var t: FenlynineOSDesignTokens { FenlynineOSDesignStore.shared.tokens }
private static var blau: Bool { FenlynineOSDesignStore.shared.nutztVisionOSBlau }
/// Atelier (hell) überschreibt dunkle Token -- sonst bleibt Text weiß auf weiß.
private static var atelier: Bool { AppearanceStore.shared.istAtelier }

static var background: Color { atelier ? Premium.void : t.background }
static var surface: Color {
 if atelier { return Premium.panel }
 return blau ? Color.white.opacity(0.06) : t.surface
}
static var surfaceElevated: Color {
 if atelier { return Premium.lift }
 return blau ? Color.white.opacity(0.09) : t.surfaceElevated
}
static var glassFill: Color { atelier ? Premium.panel.opacity(0.92) : t.glassFill }
static var glassBorder: Color { atelier ? Premium.hairline : t.glassBorder }
static var border: Color { atelier ? Premium.hairline : t.border }
static var borderGold: Color { blau ? t.accent.opacity(0.35) : t.borderAccent }
static var gold: Color { blau ? t.accent : t.brand }
static var goldLight: Color { blau ? t.accentSecondary : t.brandLight }
static var goldDark: Color { blau ? t.accent.opacity(0.85) : t.brandDark }
static var brand: Color { gold }
static var accent: Color { atelier ? Premium.action : t.accent }
static var accentSecondary: Color { t.accentSecondary }
static var chartPrimary: Color { accent }
static var chartSecondary: Color { t.accentSecondary }
static var chartLine: Color { accent }
static var chartFill: Color { accent.opacity(0.22) }
static var textPrimary: Color { atelier ? Premium.text : t.textPrimary }
static var textSecondary: Color { atelier ? Premium.textSoft : t.textSecondary }
static var textTertiary: Color { atelier ? Premium.textFaint : t.textTertiary }
static var success: Color { atelier ? Premium.computed : t.success }
static var warning: Color { atelier ? Premium.proposed : t.warning }
static var danger: Color { atelier ? Premium.critical : t.danger }
static var goldGradient: LinearGradient { blau ? t.accentGradient : t.brandGradient }
static var brandGradient: LinearGradient { goldGradient }
static var sidebarSelected: LinearGradient { t.sidebarSelected }
static var cardGradient: LinearGradient { t.cardGradient }
static var useGlass: Bool { atelier ? false : (t.useGlass || blau) }
static var preferredScheme: ColorScheme {
 if atelier { return .light }
 return blau ? .dark : t.preferredScheme
}
}

enum FenlynineOSDesign {
private static var t: FenlynineOSDesignTokens { FenlynineOSDesignStore.shared.tokens }

static var cornerRadius: CGFloat { t.cornerRadius }
static var cornerRadiusLarge: CGFloat { t.cornerRadiusLarge }
static let cardPadding: CGFloat = AppleUIKitTokens.widgetPadding
static let sectionSpacing: CGFloat = 16
static var accent: Color { t.accent }
static var accentGradient: LinearGradient { t.accentGradient }
static var heroGradient: LinearGradient { t.sidebarSelected }
static var subtleBorder: Color { t.border }
static var cardShadow: Color { t.cardShadow }
}

