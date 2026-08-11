import SwiftUI

// MARK: - Opportunisma Design (Dark Command Center · rot -- angeglichen an FenlynineOS)

enum OpportunismaTheme {
static let cornerRadius: CGFloat = 10
static let cornerRadiusSmall: CGFloat = 8

static let bg = Color(red: 0.04, green: 0.04, blue: 0.05)
static let card = Color(red: 0.08, green: 0.08, blue: 0.09)
static let cardElevated = Color(red: 0.11, green: 0.11, blue: 0.12)
static let ink = Color.white
static let gray = Color.white.opacity(0.55)
static let grayLight = Color.white.opacity(0.12)
static let line = Color.white.opacity(0.08)
static let red = Color(red: 0.92, green: 0.12, blue: 0.15)
static let redDark = Color(red: 0.65, green: 0.05, blue: 0.08)
static let sidebarBg = Color(red: 0.06, green: 0.06, blue: 0.07)
static let sidebarActive = red

static let headerFont = Font.system(size: 22, weight: .bold, design: .default)
static let widgetTitle = Font.system(size: 11, weight: .bold)
static let captionFont = Font.system(size: 9, weight: .medium)

static var cardShape: RoundedRectangle {
  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
}

static var buttonShape: RoundedRectangle {
  RoundedRectangle(cornerRadius: cornerRadiusSmall, style: .continuous)
}
}

struct OpportunismaBackground: ViewModifier {
func body(content: Content) -> some View {
  content.background(OpportunismaTheme.bg)
}
}

extension View {
func opportunismaBackground() -> some View {
  modifier(OpportunismaBackground())
}

func pragCardStyle(border: Color = OpportunismaTheme.line, elevated: Bool = false) -> some View {
  background(
    elevated ? OpportunismaTheme.cardElevated : OpportunismaTheme.card,
    in: OpportunismaTheme.cardShape
  )
  .overlay(OpportunismaTheme.cardShape.stroke(border, lineWidth: 1))
}

func pragSidebarSelection(_ selected: Bool) -> some View {
  background(
    selected ? OpportunismaTheme.sidebarActive : Color.clear,
    in: OpportunismaTheme.buttonShape
  )
}
}

struct PragPrimaryButtonStyle: ButtonStyle {
var prominent: Bool = true

func makeBody(configuration: Configuration) -> some View {
  configuration.label
    .font(.system(size: 10, weight: .bold))
    .foregroundStyle(prominent ? Color.white : OpportunismaTheme.red)
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .background(
      prominent ? OpportunismaTheme.red.opacity(configuration.isPressed ? 0.85 : 1) : OpportunismaTheme.red.opacity(0.12),
      in: OpportunismaTheme.buttonShape
    )
    .overlay(
      OpportunismaTheme.buttonShape
        .stroke(prominent ? Color.clear : OpportunismaTheme.red.opacity(0.35), lineWidth: 1)
    )
}
}

