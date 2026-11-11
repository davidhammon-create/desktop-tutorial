import SwiftUI
enum Store {
    static let canvas = Color.black
    static let canvasElevated = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let selection = Color.white.opacity(0.12)
    static let text = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.38)
    static let accent = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
    static let pillFill = Color.white.opacity(0.14)
    static let pillStroke = Color.white.opacity(0.08)
    static let searchFill = Color.white.opacity(0.08)
    static let sidebarWidth: CGFloat = 220
    static let radiusCard: CGFloat = 16
    static let radiusHero: CGFloat = 20
    static let radiusIcon: CGFloat = 14
    static let contentInset: CGFloat = 28
    static let sectionGap: CGFloat = 28
    static let titleLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let titleSection = Font.system(size: 22, weight: .bold, design: .default)
    static let heroTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .default)
    static let eyebrow = Font.system(size: 11, weight: .semibold, design: .default)
    static let body = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let sidebar = Font.system(size: 13, weight: .medium, design: .default)
    static let pill = Font.system(size: 13, weight: .semibold, design: .default)
}
struct StoreSearchField: View {
    @Binding var text: String
    var placeholder: String = "Suchen"
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Store.textTertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Store.caption)
                .foregroundStyle(Store.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Store.searchFill)
        )
    }
}
struct StoreSidebarRow: View {
    let symbol: String
    let titel: String
    var badge: Int? = nil
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(selected ? Store.accent : Store.text)
                    .frame(width: 20)
                Text(titel)
                    .font(Store.sidebar)
                    .foregroundStyle(Store.text)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Store.text)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? Store.selection : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
struct StoreProfilFuss: View {
    var initials: String
    var name: String
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.14))
                Text(initials)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Store.text)
            }
            .frame(width: 28, height: 28)
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Store.text)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
}
struct StorePillButton: View {
    let titel: String
    var prominent: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(titel)
                .font(Store.pill)
                .foregroundStyle(prominent ? .black : Store.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(prominent ? Color.white : Store.pillFill)
                )
        }
        .buttonStyle(.plain)
    }
}
struct StoreSectionHeader: View {
    let titel: String
    var link: String? = nil
    var onLink: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titel)
                .font(Store.titleSection)
                .foregroundStyle(Store.text)
            Spacer()
            if let link, let onLink {
                Button(link, action: onLink)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Store.accent)
                    .buttonStyle(.plain)
            }
        }
    }
}
struct StorePageHeader: View {
    var eyebrow: String? = nil
    let titel: String
    var untertitel: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(Store.eyebrow)
                    .foregroundStyle(Store.accent)
                    .tracking(0.6)
            }
            Text(titel)
                .font(Store.titleLarge)
                .foregroundStyle(Store.text)
            if let untertitel {
                Text(untertitel)
                    .font(Store.body)
                    .foregroundStyle(Store.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct StoreAppZeile: View {
    let symbol: String
    let iconColor: Color
    let titel: String
    let untertitel: String?
    let pillTitel: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: Store.radiusIcon, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.85), iconColor.opacity(0.45)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: symbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(titel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Store.text)
                        .lineLimit(1)
                    if let untertitel {
                        Text(untertitel)
                            .font(Store.caption)
                            .foregroundStyle(Store.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(pillTitel)
                    .font(Store.pill)
                    .foregroundStyle(Store.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Store.pillFill))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
struct StoreHeroCard: View {
    var eyebrow: String
    var titel: String
    var text: String
    var gradient: [Color]
    var symbol: String
    var height: CGFloat = 190
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: Store.radiusHero, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(eyebrow.uppercased())
                        .font(Store.eyebrow)
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(0.8)
                    Text(titel)
                        .font(Store.heroTitle)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                    Text(text)
                        .font(Store.body)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                }
                .padding(22)
                Spacer(minLength: 8)
                Image(systemName: symbol)
                    .font(.system(size: 72, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.trailing, 24)
                    .padding(.bottom, 18)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Store.radiusHero, style: .continuous))
    }
}
struct StoreMediaCard: View {
    var eyebrow: String
    var titel: String
    var text: String
    var gradient: [Color]
    var symbol: String
    var action: (() -> Void)? = nil
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: symbol)
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(height: 120)
                Text(eyebrow.uppercased())
                    .font(Store.eyebrow)
                    .foregroundStyle(Store.textTertiary)
                    .tracking(0.7)
                Text(titel)
                    .font(Store.cardTitle)
                    .foregroundStyle(Store.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(text)
                    .font(Store.caption)
                    .foregroundStyle(Store.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
struct StoreWidget<Content: View>: View {
    var titel: String? = nil
    var untertitel: String? = nil
    var symbol: String? = nil
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if titel != nil || symbol != nil {
                HStack(spacing: 10) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Store.accent)
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Store.accent.opacity(0.18)))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let titel {
                            Text(titel)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Store.text)
                        }
                        if let untertitel {
                            Text(untertitel)
                                .font(Store.caption)
                                .foregroundStyle(Store.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
                .fill(Store.canvasElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
struct StoreSparkline: View {
    var values: [Double]
    var tint: Color = Store.accent
    var body: some View {
        GeometryReader { geo in
            let vals = values.isEmpty ? [0.2, 0.35, 0.3, 0.55, 0.5, 0.7, 0.65, 0.85] : values
            let maxV = max(vals.max() ?? 1, 0.001)
            let minV = min(vals.min() ?? 0, maxV - 0.001)
            let span = maxV - minV
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                for (i, v) in vals.enumerated() {
                    let x = w * CGFloat(i) / CGFloat(max(vals.count - 1, 1))
                    let y = h - CGFloat((v - minV) / span) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            Path { path in
                for (i, v) in vals.enumerated() {
                    let x = w * CGFloat(i) / CGFloat(max(vals.count - 1, 1))
                    let y = h - CGFloat((v - minV) / span) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                if let last = vals.indices.last {
                    let x = w
                    let y = h - CGFloat((vals[last] - minV) / span) * h
                    path.addLine(to: CGPoint(x: x, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
            }
            .fill(
                LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom)
            )
        }
        .frame(height: 120)
    }
}
struct StoreBarStrip: View {
    var values: [(label: String, value: Double, color: Color)]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(row.label)
                            .font(Store.caption)
                            .foregroundStyle(Store.textSecondary)
                        Spacer()
                        Text(String(format: "%.0f%%", row.value * 100))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Store.text)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(row.color)
                                .frame(width: max(6, geo.size.width * CGFloat(min(max(row.value, 0), 1))))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }
}
struct StoreCanvasBackground: View {
    var body: some View { Store.canvas.ignoresSafeArea() }
}
extension View {
    func storeSidebarMaterial() -> some View {
        self.background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.black.opacity(0.35)))
        )
    }
    func storeModulWidget(titel: String, untertitel: String? = nil, symbol: String? = nil) -> some View {
        StoreWidget(titel: titel, untertitel: untertitel, symbol: symbol) { self }
    }
}
