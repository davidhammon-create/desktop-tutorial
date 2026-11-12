import SwiftUI

// MARK: - FenlynineOS Vision Redesign (PDF Juli 2026)

enum AppleUIKitTokens {
// MARK: Typografie -- SF Pro (filigran, Vision-Referenz)
static let largeTitle = FenlynineOSFont.largeTitle
static let title2 = FenlynineOSFont.title2
static let title3 = FenlynineOSFont.title3
static let headline = FenlynineOSFont.headline
static let body = FenlynineOSFont.body
static let callout = FenlynineOSFont.callout
static let caption = FenlynineOSFont.caption
static let caption2 = FenlynineOSFont.caption2
static let widgetTitle = FenlynineOSFont.widgetTitle
static let buttonLabel = FenlynineOSFont.buttonLabel
static let buttonLabelCompact = FenlynineOSFont.buttonLabelCompact
static let kpiWert = FenlynineOSFont.sf(17, weight: .bold)
static let kpiTitel = FenlynineOSFont.sf(10, weight: .semibold)

static let widgetTitleTracking: CGFloat = 0.5
static let buttonPaddingH: CGFloat = 14
static let buttonPaddingV: CGFloat = 7
static let buttonPaddingHCompact: CGFloat = 10
static let buttonPaddingVCompact: CGFloat = 5

// MARK: Panel-Kaskade (PDF Seite 9)
/// Äußeres Glas-Panel: Weiß 10 %, Radius 36
static let panelOuterFill = Color.white.opacity(0.06)
static let radiusPanelOuter: CGFloat = 36
/// Innere Kacheln: sehr transparentes Rauchglas (Fumé)
static let kachelFill = Color.black.opacity(0.20)
static let kachelBorder = Color.white.opacity(0.16)
static let radiusKachel: CGFloat = 20

// MARK: Widget-Maße
static let widgetPadding: CGFloat = 12
static let widgetSpacing: CGFloat = 10
static let widgetGridSpacing: CGFloat = 10
static let widgetMaxHeight: CGFloat = 200
static let widgetChartMaxHeight: CGFloat = 240
static let widgetKPIHeight: CGFloat = 120

// Legacy-Aliase
static let radiusWidget: CGFloat = radiusKachel
static let radiusCard: CGFloat = radiusKachel
static let radiusButton: CGFloat = 999
static let radiusSheet: CGFloat = 28
static let radiusWindow: CGFloat = radiusPanelOuter

// MARK: Glas-Schichten
static let milchglasMaterial: Material = .regularMaterial
static let rauchglasMaterial: Material = .thinMaterial
static let milchglasTint: Color = .white.opacity(0.06)
static let rauchglasTint: Color = .white.opacity(0.04)
static let rimLightTop: Color = .white.opacity(0.32)
static let rimLightBottom: Color = .white.opacity(0.05)
static let glasBasisDunkel: Color = Color(white: 0.10).opacity(0.28)
static let glasFume: Color = Color.black.opacity(0.22)

// MARK: Semantische Farben (PDF: Blau=Aktion, Grün/Orange/Rot=Status)
static let pureBlack = Color.black
static let systemBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
static let systemGreen = Color(red: 0.30, green: 0.85, blue: 0.55)
static let systemOrange = Color(red: 1.0, green: 0.75, blue: 0.20)
static let systemRed = Color(red: 1.0, green: 0.35, blue: 0.32)

static let shadowFloating = Color.black.opacity(0.45)
static let shadowSoft = Color.black.opacity(0.22)

// MARK: Navigation
static let ornamentBreite: CGFloat = 76
static let ornamentIconGroesse: CGFloat = 38
}

/// Lexara -- filigrane Maße (alles proportional kleiner, nichts abschneiden)
enum LexaraFiligranTokens {
static let fallTitel = Font.system(size: 17, weight: .semibold)
static let tabLabel = Font.system(size: 10, weight: .medium)
static let tabLabelAktiv = Font.system(size: 10, weight: .semibold)
static let tabIcon = Font.system(size: 9, weight: .semibold)
static let listenZeile = Font.system(size: 11, weight: .medium)
static let listenMeta = Font.system(size: 9, weight: .regular)
static let contentPadding: CGFloat = 12
static let tabBarHoehe: CGFloat = 32
static let workflowBreite: CGFloat = 188
static let workflowEingeklappt: CGFloat = 40
}

/// Lagebild HR-Dashboard (Bild 3 -- Vision Pro Referenz, Farben 1:1)
enum LagebildHRTokens {
static let primaryBlue = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
static let successGreen = Color(red: 0.20, green: 0.84, blue: 0.42) // › grün
static let alertRed = Color(red: 1.0, green: 0.27, blue: 0.23) // fl rot / Clock Out
static let textPrimary = Color.white
static let textSecondary = Color.white.opacity(0.55)
static let textTertiary = Color.white.opacity(0.38)
static let widgetFill = Color.black.opacity(0.18)
static let widgetBorder = Color.white.opacity(0.14)
static let trackFill = Color.white.opacity(0.10)

static let welcomeGreeting = Font.system(size: 11, weight: .regular)
static let welcomeName = Font.system(size: 22, weight: .bold)
static let widgetTitle = Font.system(size: 9, weight: .bold)
static let widgetValue = Font.system(size: 18, weight: .bold)
static let widgetMeta = Font.system(size: 10, weight: .medium)
static let listTitle = Font.system(size: 11, weight: .semibold)
static let listMeta = Font.system(size: 9, weight: .regular)
static let kpiValue = Font.system(size: 16, weight: .bold)
static let kpiLabel = Font.system(size: 9, weight: .semibold)
static let trendLabel = Font.system(size: 9, weight: .semibold)

static let gridSpacing: CGFloat = 10
static let widgetPadding: CGFloat = 12
static let widgetRadius: CGFloat = 20
static let kpiCardWidth: CGFloat = 148

/// Filigrane Widget-Grafik (variabel nach Kontext)
static let progressHoehe: CGFloat = 3
static let progressHoeheKompakt: CGFloat = 2.5
static let ganttHoehe: CGFloat = 5
static let radarStrich: CGFloat = 0.55
static let radarDatenStrich: CGFloat = 1.0
static let schrittIconGroesse: CGFloat = 22
static let linkButtonFont = Font.system(size: 9, weight: .medium)
static let pillButtonFont = Font.system(size: 9, weight: .semibold)
static let pillPaddingH: CGFloat = 10
static let pillPaddingV: CGFloat = 4
}

enum FenlynineOSGlasModus: Equatable {
case vollstaendig
case milchglasOverlay
case kein
}

