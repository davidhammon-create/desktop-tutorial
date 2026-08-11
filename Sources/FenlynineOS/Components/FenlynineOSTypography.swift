import SwiftUI

// MARK: - San Francisco (programmweit, inkl. Strategos Schriftart)

enum FenlynineOSFont {
/// SF Pro auf macOS -- explizit system/default Design
static func sf(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
  .system(size: size, weight: weight, design: .default)
}

static let largeTitle = sf(22, weight: .bold)
static let title2 = sf(17, weight: .semibold)
static let title3 = sf(14, weight: .semibold)
static let headline = sf(13, weight: .semibold)
static let body = sf(12, weight: .regular)
static let callout = sf(11, weight: .regular)
static let caption = sf(10, weight: .regular)
static let caption2 = sf(9, weight: .medium)
static let widgetTitle = sf(9, weight: .bold)
static let buttonLabel = sf(11, weight: .semibold)
static let buttonLabelCompact = sf(10, weight: .semibold)
}

struct FenlynineOSSFTypographyModifier: ViewModifier {
func body(content: Content) -> some View {
  content.font(FenlynineOSFont.body)
}
}

extension View {
/// San Francisco als Standard-Schrift (programmweit)
func fenlynineOSSFTypography() -> some View {
  modifier(FenlynineOSSFTypographyModifier())
}

/// Nur Schriftart SF für Legacy-Module (z. B. Strategos) -- Layout unverändert
func fenlynineOSSFTypographyOnly() -> some View {
  font(FenlynineOSFont.body)
}
}

