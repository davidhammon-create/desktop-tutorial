import SwiftUI

// MARK: - Opportunisma Pro · visionOS / macOS Professional
// Spatial glass, Apple-like materials, counsel-grade CI desk.
// Nur Standalone (`opportunismaProMode`). Strategos-Legacy bleibt unberührt.

enum OpportunismaPro {
// Spatial canvas -- soft space gradient feel
static let voidDeep = Color(red: 0.04, green: 0.05, blue: 0.08)
static let voidMid = Color(red: 0.08, green: 0.10, blue: 0.16)
static let voidLift = Color(red: 0.12, green: 0.14, blue: 0.22)

// Accents -- Apple system blue family (visionOS / macOS)
static let accent = Color(red: 0.20, green: 0.52, blue: 1.0)
static let accentSoft = Color(red: 0.20, green: 0.52, blue: 1.0).opacity(0.18)
static let accentLine = Color(red: 0.20, green: 0.52, blue: 1.0).opacity(0.45)
static let glow = Color(red: 0.45, green: 0.70, blue: 1.0).opacity(0.35)

static let signal = Color(red: 0.20, green: 0.78, blue: 0.55)
static let warn = Color(red: 1.0, green: 0.70, blue: 0.25)
static let danger = Color(red: 1.0, green: 0.35, blue: 0.38)

static let text = Color.white.opacity(0.94)
static let textSoft = Color.white.opacity(0.62)
static let textFaint = Color.white.opacity(0.38)
static let hairline = Color.white.opacity(0.14)

// Typography -- SF Pro, display with rounded for scores
static let hero = Font.system(size: 34, weight: .bold, design: .default)
static let display = Font.system(size: 26, weight: .semibold, design: .default)
static let title = Font.system(size: 18, weight: .semibold, design: .default)
static let section = Font.system(size: 12, weight: .semibold, design: .default)
static let body = Font.system(size: 14, weight: .regular, design: .default)
static let caption = Font.system(size: 12, weight: .medium, design: .default)
static let micro = Font.system(size: 10, weight: .semibold, design: .default)

static let radiusWindow: CGFloat = 26
static let radius: CGFloat = 18
static let radiusSm: CGFloat = 12
static let radiusPill: CGFloat = 100

static var stageShape: RoundedRectangle {
  RoundedRectangle(cornerRadius: radius, style: .continuous)
}

static var windowShape: RoundedRectangle {
  RoundedRectangle(cornerRadius: radiusWindow, style: .continuous)
}

// Aliases for older Pro code
static var canvas: Color { voidDeep }
static var stage: Color { voidMid.opacity(0.55) }
static var raised: Color { voidLift.opacity(0.65) }
static var rail: Color { voidDeep.opacity(0.85) }
static var copper: Color { accent }
static var copperSoft: Color { accentSoft }
static var copperLine: Color { accentLine }
}

// MARK: - Environment

private struct OpportunismaProModeKey: EnvironmentKey {
static let defaultValue = false
}

extension EnvironmentValues {
var opportunismaProMode: Bool {
  get { self[OpportunismaProModeKey.self] }
  set { self[OpportunismaProModeKey.self] = newValue }
}
}

// MARK: - Phasen

enum OpportunismaPhase: String, CaseIterable, Identifiable {
case start, lage, strategie, feld, hebel, umsetzung, intelligence, delivery

var id: String { rawValue }

var titel: String {
  switch self {
  case .start: return "Einstieg"
  case .lage: return "Lagebild"
  case .strategie: return "Strategie"
  case .feld: return "Spielfeld"
  case .hebel: return "Hebel"
  case .umsetzung: return "Umsetzung"
  case .intelligence: return "Intelligence"
  case .delivery: return "Delivery"
  }
}

var untertitel: String {
  switch self {
  case .start: return "Journey · Briefing · Playbooks · Fragebogen"
  case .lage: return "Position · Radar · Überblick"
  case .strategie: return "Züge · Netze · Szenarien · War Room"
  case .feld: return "Wettbewerb · Stakeholder · Akteure"
  case .hebel: return "Ressourcen · Narrativ · Einfluss"
 case .umsetzung: return "Plan · Risiko · Dossier"
 case .intelligence: return "Feed · Chancen · Action Board"
 case .delivery: return "Weekly Brief · Export Studio"
 }
}

var symbol: String {
 switch self {
 case .start: return "flag.fill"
 case .lage: return "viewfinder"
 case .strategie: return "arrow.triangle.branch"
 case .feld: return "person.3.fill"
 case .hebel: return "slider.horizontal.3"
 case .umsetzung: return "checklist"
 case .intelligence: return "sparkles"
 case .delivery: return "paperplane.fill"
 }
}

var tabs: [OpportunismaTab] {
 switch self {
 case .start: return [.journey, .briefing, .playbooks, .fragebogen, .strategosLink]
 case .lage: return [.uebersicht, .hegemonogramm]
 case .strategie: return [.machtStrategie, .entscheidungsnetz, .szenarien, .warRoom]
 case .feld: return [.gegneranalyse, .netzwerk, .zielpersonen]
 case .hebel: return [.ressourcen, .narrativ, .influence]
 case .umsetzung: return [.zeitplan, .risiken, .dossier]
 case .intelligence: return [.actionBoard, .chancen, .feed]
 case .delivery: return [.weeklyBrief, .exportStudio]
 }
}

static func phase(fuer tab: OpportunismaTab) -> OpportunismaPhase {
 for p in allCases where p.tabs.contains(tab) { return p }
 return .lage
}
}

// MARK: - Glass surfaces

struct OpportunismaGlassPanel: ViewModifier {
var elevated: Bool = false
var corner: CGFloat = OpportunismaPro.radius

func body(content: Content) -> some View {
 let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
 content
   .background {
     shape
       .fill(.ultraThinMaterial)
       .overlay(shape.fill(Color.white.opacity(elevated ? 0.07 : 0.04)))
       .overlay(
         shape.fill(
           LinearGradient(
             colors: [Color.white.opacity(0.12), Color.clear],
             startPoint: .topLeading,
             endPoint: .bottomTrailing
           )
         )
       )
       .overlay(shape.stroke(Color.white.opacity(0.18), lineWidth: 0.8))
       .shadow(color: .black.opacity(elevated ? 0.35 : 0.18), radius: elevated ? 28 : 12, y: elevated ? 12 : 5)
   }
}
}

extension View {
func opportunismaGlass(elevated: Bool = false, corner: CGFloat = OpportunismaPro.radius) -> some View {
 modifier(OpportunismaGlassPanel(elevated: elevated, corner: corner))
}
}

struct OpportunismaSpatialBackground: View {
var body: some View {
 ZStack {
   LinearGradient(
     colors: [OpportunismaPro.voidDeep, OpportunismaPro.voidMid, OpportunismaPro.voidDeep],
     startPoint: .topLeading,
     endPoint: .bottomTrailing
   )
   // Soft orbs -- visionOS depth without purple bias
   Circle()
     .fill(OpportunismaPro.accent.opacity(0.18))
     .frame(width: 420, height: 420)
     .blur(radius: 90)
     .offset(x: -220, y: -180)
   Circle()
     .fill(Color.cyan.opacity(0.10))
     .frame(width: 360, height: 360)
     .blur(radius: 80)
     .offset(x: 280, y: 220)
   Circle()
     .fill(Color.white.opacity(0.04))
     .frame(width: 500, height: 500)
     .blur(radius: 100)
     .offset(x: 40, y: -40)
 }
 .ignoresSafeArea()
}
}

// MARK: - Chrome primitives

struct OpportunismaProSection<Content: View>: View {
let titel: String
var untertitel: String? = nil
var accent: Color = OpportunismaPro.accent
@ViewBuilder var content: () -> Content

var body: some View {
 VStack(alignment: .leading, spacing: 14) {
   HStack(alignment: .firstTextBaseline, spacing: 10) {
     Capsule()
       .fill(accent)
       .frame(width: 3, height: 20)
       .shadow(color: accent.opacity(0.6), radius: 6, y: 0)
     VStack(alignment: .leading, spacing: 3) {
       Text(titel)
         .font(OpportunismaPro.title)
         .foregroundStyle(OpportunismaPro.text)
       if let untertitel {
         Text(untertitel)
           .font(OpportunismaPro.caption)
           .foregroundStyle(OpportunismaPro.textSoft)
       }
     }
     Spacer(minLength: 0)
   }
   content()
 }
 .padding(20)
 .frame(maxWidth: .infinity, alignment: .leading)
 .opportunismaGlass(elevated: true)
}
}

struct OpportunismaProChip: View {
let titel: String
var aktiv: Bool = false
var action: () -> Void

var body: some View {
 Button(action: action) {
   Text(titel)
     .font(OpportunismaPro.caption)
     .foregroundStyle(aktiv ? .white : OpportunismaPro.textSoft)
     .padding(.horizontal, 14)
     .padding(.vertical, 8)
     .background {
       if aktiv {
         Capsule().fill(OpportunismaPro.accent)
           .shadow(color: OpportunismaPro.accent.opacity(0.35), radius: 10, y: 3)
       } else {
         Capsule().fill(.thinMaterial)
           .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.6))
       }
     }
     .contentShape(Capsule())
 }
 .buttonStyle(.plain)
}
}

struct OpportunismaProPrimaryButton: ButtonStyle {
func makeBody(configuration: Configuration) -> some View {
 configuration.label
   .font(OpportunismaPro.caption.weight(.semibold))
   .foregroundStyle(.white)
   .padding(.horizontal, 16)
   .padding(.vertical, 10)
   .background {
     Capsule()
       .fill(OpportunismaPro.accent.opacity(configuration.isPressed ? 0.75 : 1))
       .shadow(color: OpportunismaPro.accent.opacity(0.4), radius: configuration.isPressed ? 4 : 12, y: 4)
   }
   .scaleEffect(configuration.isPressed ? 0.97 : 1)
   .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
}
}

struct OpportunismaProGhostButton: ButtonStyle {
func makeBody(configuration: Configuration) -> some View {
 configuration.label
   .font(OpportunismaPro.caption.weight(.semibold))
   .foregroundStyle(OpportunismaPro.text)
   .padding(.horizontal, 14)
   .padding(.vertical, 9)
   .background {
     Capsule()
       .fill(.thinMaterial)
       .overlay(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.08 : 0.04)))
       .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 0.6))
   }
   .scaleEffect(configuration.isPressed ? 0.97 : 1)
}
}

struct OpportunismaProScoreRing: View {
let wert: Int
var label: String = "Position"

var body: some View {
 ZStack {
   Circle()
     .stroke(Color.white.opacity(0.1), lineWidth: 8)
   Circle()
     .trim(from: 0, to: CGFloat(min(100, max(0, wert))) / 100)
     .stroke(
       AngularGradient(
         colors: [OpportunismaPro.accent.opacity(0.35), OpportunismaPro.accent, OpportunismaPro.signal],
         center: .center
       ),
       style: StrokeStyle(lineWidth: 8, lineCap: .round)
     )
     .rotationEffect(.degrees(-90))
     .shadow(color: OpportunismaPro.accent.opacity(0.45), radius: 8, y: 0)
   VStack(spacing: 1) {
     Text("\(wert)")
       .font(.system(size: 22, weight: .bold, design: .rounded))
       .foregroundStyle(OpportunismaPro.text)
     Text(label.uppercased())
       .font(OpportunismaPro.micro)
       .foregroundStyle(OpportunismaPro.textFaint)
       .tracking(0.8)
   }
 }
 .frame(width: 78, height: 78)
}
}

struct OpportunismaProMetricTile: View {
let label: String
let value: String
var hint: String? = nil
var tone: Color = OpportunismaPro.accent

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text(label.uppercased())
     .font(OpportunismaPro.micro)
     .foregroundStyle(OpportunismaPro.textFaint)
     .tracking(0.7)
   Text(value)
     .font(.system(size: 28, weight: .bold, design: .rounded))
     .foregroundStyle(OpportunismaPro.text)
   if let hint {
     Text(hint)
       .font(OpportunismaPro.caption)
       .foregroundStyle(tone)
   }
 }
 .padding(16)
 .frame(maxWidth: .infinity, alignment: .leading)
 .opportunismaGlass(corner: OpportunismaPro.radiusSm)
}
}

