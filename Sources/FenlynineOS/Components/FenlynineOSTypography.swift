import SwiftUI
enum FenlynineOSFont {
    private static var apple: Bool { AppearanceStore.shared.istApple }
    static func sf(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static var largeTitle: Font { apple ? sf(34, weight: .bold) : sf(22, weight: .bold) }
    static var title2: Font { apple ? sf(22, weight: .bold) : sf(17, weight: .semibold) }
    static var title3: Font { apple ? sf(17, weight: .semibold) : sf(14, weight: .semibold) }
    static var headline: Font { apple ? sf(15, weight: .semibold) : sf(13, weight: .semibold) }
    static var body: Font { apple ? sf(13, weight: .regular) : sf(12, weight: .regular) }
    static var callout: Font { apple ? sf(12, weight: .regular) : sf(11, weight: .regular) }
    static var caption: Font { apple ? sf(12, weight: .regular) : sf(10, weight: .regular) }
    static var caption2: Font { apple ? sf(11, weight: .medium) : sf(9, weight: .medium) }
    static var widgetTitle: Font { apple ? sf(12, weight: .semibold) : sf(9, weight: .bold) }
    static var buttonLabel: Font { apple ? sf(13, weight: .semibold) : sf(11, weight: .semibold) }
    static var buttonLabelCompact: Font { apple ? sf(12, weight: .semibold) : sf(10, weight: .semibold) }
}
struct FenlynineOSSFTypographyModifier: ViewModifier {
    @Bindable private var appearance = AppearanceStore.shared
    func body(content: Content) -> some View {
        content.font(FenlynineOSFont.body)
            .environment(\.storeAppleChrome, appearance.istApple)
    }
}
private struct StoreAppleChromeKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    var storeAppleChrome: Bool {
        get { self[StoreAppleChromeKey.self] }
        set { self[StoreAppleChromeKey.self] = newValue }
    }
}
extension View {
    func fenlynineOSSFTypography() -> some View {
        modifier(FenlynineOSSFTypographyModifier())
    }
    func fenlynineOSSFTypographyOnly() -> some View {
        font(FenlynineOSFont.body)
    }
    func storeChartSurface(titel: String? = nil) -> some View {
        modifier(StoreChartSurfaceModifier(titel: titel))
    }
}
private struct StoreChartSurfaceModifier: ViewModifier {
    var titel: String?
    @Environment(\.storeAppleChrome) private var apple
    func body(content: Content) -> some View {
        Group {
            if apple {
                VStack(alignment: .leading, spacing: 10) {
                    if let titel {
                        Text(titel.uppercased())
                            .font(Store.eyebrow)
                            .foregroundStyle(Store.textTertiary)
                            .tracking(0.6)
                    }
                    content
                        .frame(maxWidth: .infinity, minHeight: 140)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
                        .fill(Store.canvasElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            } else {
                content
            }
        }
    }
}
