import SwiftUI
enum MacOSSettingsTokens {
    private static var atelier: Bool { AppearanceStore.shared.istAtelier }
    static let selectionBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let selectionBlueHover = Color(red: 0.0, green: 0.42, blue: 0.92)
    static var groupFill: Color {
        atelier ? Color.black.opacity(0.04) : Color(white: 0.16).opacity(0.72)
    }
    static var groupStroke: Color {
        atelier ? Color.black.opacity(0.10) : Color.white.opacity(0.08)
    }
    static var rowHover: Color {
        atelier ? Color.black.opacity(0.04) : Color.white.opacity(0.05)
    }
    static var subtitle: Color {
        atelier ? Color(red: 0.32, green: 0.33, blue: 0.36) : Color.white.opacity(0.48)
    }
    static var chevron: Color {
        atelier ? Color.black.opacity(0.35) : Color.white.opacity(0.28)
    }
    static var title: Color {
        atelier ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color.white.opacity(0.96)
    }
    static let sidebarWidth: CGFloat = 248
    static let squircleRadius: CGFloat = 7
    static let squircleSize: CGFloat = 28
    static let groupRadius: CGFloat = 10
    static let rowRadius: CGFloat = 6
    static let rowPaddingH: CGFloat = 8
    static let rowPaddingV: CGFloat = 6
}
extension SeitenleistenEintrag {
    var macSettingsSymbol: String {
        switch self {
        case .dashboard: return "house.fill"
        case .schreibtisch: return "rectangle.3.group.fill"
        case .vorgaenge: return "square.stack.3d.up.fill"
        case .lexara: return "folder.fill"
        case .richterprofile: return "person.text.rectangle.fill"
        case .aufgaben: return "checklist"
        case .zeitleiste: return "calendar"
        case .cockpit: return "gauge.with.dots.needle.33percent"
        case .analytik: return "chart.bar.xaxis"
        case .strategos: return "shield.lefthalf.filled"
        case .opportunisma: return "scope"
        case .kiChat: return "bubble.left.and.bubble.right.fill"
        case .plattformAgent: return "cpu.fill"
        case .sunTzu: return "scope"
        case .mandanten: return "person.crop.circle.badge.checkmark"
        case .organon: return "point.3.connected.trianglepath.dotted"
        case .compliance: return "checkmark.shield.fill"
        case .dokumente: return "doc.text.fill"
        case .einstellungen: return "gearshape.fill"
        case .lageZentrale: return "rectangle.3.group.bubble.left.fill"
        case .konfliktRadar: return "exclamationmark.shield.fill"
        case .mandatsPipeline: return "arrow.triangle.branch"
        case .honorare: return "eurosign.circle.fill"
        case .entscheidungsjournal: return "book.closed.fill"
        case .praxisProfil: return "person.crop.rectangle.stack.fill"
        case .beaCheck: return "envelope.badge.shield.half.filled"
        case .berufspflicht: return "scalemass.fill"
        case .adminZentrale: return "person.2.badge.gearshape.fill"
        case .jurisdiktionen: return "globe.europe.africa.fill"
        case .selbstreparatur: return "wrench.and.screwdriver.fill"
        case .enterpriseRadar: return "dot.radiowaves.left.and.right"
        case .durchlauf: return "signpost.right.fill"
        }
    }
    var macSettingsIconColor: Color {
        switch self {
        case .dashboard: return Color(white: 0.55)
        case .schreibtisch: return Color(red: 0.45, green: 0.62, blue: 0.95)
        case .vorgaenge: return Color(red: 0.04, green: 0.52, blue: 1.0)
        case .lexara: return MacOSSettingsTokens.selectionBlue
        case .richterprofile: return Color(red: 1.0, green: 0.55, blue: 0.2)
        case .aufgaben: return Color(white: 0.62)
        case .zeitleiste: return Color(red: 1.0, green: 0.35, blue: 0.32)
        case .cockpit: return Color(red: 0.55, green: 0.45, blue: 0.95)
        case .analytik: return Color(red: 0.35, green: 0.78, blue: 0.45)
        case .strategos: return Color(red: 0.95, green: 0.65, blue: 0.2)
        case .opportunisma: return Color(red: 0.25, green: 0.78, blue: 0.85)
        case .kiChat: return Color(red: 0.30, green: 0.85, blue: 0.55)
        case .plattformAgent: return Color(red: 0.65, green: 0.5, blue: 0.95)
        case .sunTzu: return Color(red: 0.95, green: 0.75, blue: 0.25)
        case .mandanten: return Color(red: 0.35, green: 0.72, blue: 0.95)
        case .organon: return Color(red: 0.45, green: 0.55, blue: 0.95)
        case .compliance: return Color(red: 0.30, green: 0.85, blue: 0.55)
        case .dokumente: return MacOSSettingsTokens.selectionBlue
        case .einstellungen: return Color(white: 0.55)
        case .lageZentrale: return Color(red: 0.2, green: 0.55, blue: 0.75)
        case .konfliktRadar: return Color(red: 0.9, green: 0.35, blue: 0.25)
        case .mandatsPipeline: return Color(red: 0.35, green: 0.65, blue: 0.55)
        case .honorare: return Color(red: 0.2, green: 0.65, blue: 0.4)
        case .entscheidungsjournal: return Color(red: 0.55, green: 0.45, blue: 0.35)
        case .praxisProfil: return Color(red: 0.4, green: 0.5, blue: 0.7)
        case .beaCheck: return Color(red: 0.25, green: 0.45, blue: 0.7)
        case .berufspflicht: return Color(red: 0.55, green: 0.35, blue: 0.25)
        case .adminZentrale: return Color(red: 0.85, green: 0.35, blue: 0.45)
        case .jurisdiktionen: return Color(red: 0.2, green: 0.55, blue: 0.85)
        case .selbstreparatur: return Color(red: 0.9, green: 0.55, blue: 0.2)
        case .enterpriseRadar: return Color(red: 0.95, green: 0.55, blue: 0.15)
        case .durchlauf: return Color(red: 0.20, green: 0.48, blue: 0.78)
        }
    }
}
struct MacOSSettingsSquircleIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = MacOSSettingsTokens.squircleSize
    var body: some View {
        RoundedRectangle(cornerRadius: MacOSSettingsTokens.squircleRadius, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}
struct MacOSSettingsSidebarRow: View {
    let titel: String
    var untertitel: String? = nil
    let symbol: String
    let iconColor: Color
    let isSelected: Bool
    var kompakt: Bool = false
    var body: some View {
        HStack(spacing: 10) {
            MacOSSettingsSquircleIcon(symbol: symbol, color: iconColor)
            if !kompakt {
                VStack(alignment: .leading, spacing: 1) {
                    Text(titel)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : MacOSSettingsTokens.title)
                        .lineLimit(2)
                    if let untertitel {
                        Text(untertitel)
                            .font(.system(size: 11))
                            .foregroundStyle(MacOSSettingsTokens.subtitle)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MacOSSettingsTokens.rowPaddingH)
        .padding(.vertical, MacOSSettingsTokens.rowPaddingV)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: MacOSSettingsTokens.rowRadius, style: .continuous)
                    .fill(MacOSSettingsTokens.selectionBlue)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: MacOSSettingsTokens.rowRadius, style: .continuous))
    }
}
struct MacOSSettingsDeviceRow: View {
    let symbol: String
    let iconColor: Color
    let titel: String
    var untertitel: String = ""
    var isSelected: Bool = false
    var showChevron: Bool = true
    var body: some View {
        HStack(spacing: 12) {
            MacOSSettingsSquircleIcon(symbol: symbol, color: iconColor, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white : MacOSSettingsTokens.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !untertitel.isEmpty {
                    Text(untertitel)
                        .font(.system(size: 11))
                        .foregroundStyle(MacOSSettingsTokens.subtitle)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MacOSSettingsTokens.chevron)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MacOSSettingsTokens.selectionBlue.opacity(0.35))
            }
        }
        .contentShape(Rectangle())
    }
}
struct MacOSSettingsGroupedList<Content: View>: View {
    var titel: String? = nil
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let titel {
                Text(titel.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MacOSSettingsTokens.subtitle)
                    .padding(.horizontal, 4)
            }
            VStack(spacing: 0) {
                content()
            }
            .background {
                RoundedRectangle(cornerRadius: MacOSSettingsTokens.groupRadius, style: .continuous)
                    .fill(MacOSSettingsTokens.groupFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: MacOSSettingsTokens.groupRadius, style: .continuous)
                            .stroke(MacOSSettingsTokens.groupStroke, lineWidth: 0.5)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: MacOSSettingsTokens.groupRadius, style: .continuous))
        }
    }
}
struct MacOSSettingsGroupDivider: View {
    var body: some View {
        Divider()
            .overlay(MacOSSettingsTokens.groupStroke)
            .padding(.leading, 56)
    }
}
struct MacOSSettingsSearchField: View {
    @Binding var text: String
    var placeholder: String = "Suchen"
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MacOSSettingsTokens.subtitle)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .foregroundStyle(MacOSSettingsTokens.title)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppearanceStore.shared.istAtelier ? Color.black.opacity(0.05) : Color.white.opacity(0.08))
        }
    }
}
struct MacOSSettingsSelectionButtonStyle: ButtonStyle {
    var isSelected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if isSelected || configuration.isPressed {
                    RoundedRectangle(cornerRadius: MacOSSettingsTokens.rowRadius, style: .continuous)
                        .fill(
                            configuration.isPressed && !isSelected
                                ? MacOSSettingsTokens.selectionBlueHover
                                : MacOSSettingsTokens.selectionBlue
                        )
                }
            }
            .opacity(configuration.isPressed && !isSelected ? 0.9 : 1)
    }
}
struct MacOSSettingsPrimaryButton: View {
    let titel: String
    var symbol: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(titel)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(MacOSSettingsTokens.selectionBlue)
            }
        }
        .buttonStyle(.plain)
    }
}
extension View {
    func macOSSettingsGroupBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: MacOSSettingsTokens.groupRadius, style: .continuous)
                .fill(MacOSSettingsTokens.groupFill)
                .overlay(
                    RoundedRectangle(cornerRadius: MacOSSettingsTokens.groupRadius, style: .continuous)
                        .stroke(MacOSSettingsTokens.groupStroke, lineWidth: 0.5)
                )
        }
    }
}
