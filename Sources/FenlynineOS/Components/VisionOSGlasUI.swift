import SwiftUI
enum VisionOSGlasButtonStil {
    case primaerBlau   // Milchglas + blauer Schimmer
    case sekundaer     // Dunkles Frostglas
    case ghost         // Nur Rand
}
struct VisionOSGlasButton: View {
    let titel: String
    var symbol: String? = nil
    var stil: VisionOSGlasButtonStil = .sekundaer
    var volleBreite: Bool = false
    var kompakt: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(kompakt ? AppleUIKitTokens.buttonLabelCompact : AppleUIKitTokens.buttonLabel)
                }
                Text(titel)
                    .font(kompakt ? AppleUIKitTokens.buttonLabelCompact : AppleUIKitTokens.buttonLabel)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, kompakt ? AppleUIKitTokens.buttonPaddingHCompact : AppleUIKitTokens.buttonPaddingH)
            .padding(.vertical, kompakt ? AppleUIKitTokens.buttonPaddingVCompact : AppleUIKitTokens.buttonPaddingV)
            .frame(maxWidth: volleBreite ? .infinity : nil)
            .background { VisionOSGlasFlaeche.button(stil: stil) }
        }
        .buttonStyle(VisionOSGlasButtonStyle())
    }
    private var foreground: Color {
        switch stil {
        case .primaerBlau: return .white
        case .sekundaer, .ghost: return FenlynineOSTheme.textPrimary
        }
    }
}
struct VisionOSGlasIconButton: View {
    let symbol: String
    var aktiv: Bool = false
    var groesse: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: groesse * 0.38, weight: .semibold))
                .foregroundStyle(aktiv ? .white : FenlynineOSTheme.textPrimary.opacity(0.85))
                .frame(width: groesse, height: groesse)
                .background {
                    Circle()
                        .fill(.thinMaterial)
                        .overlay(Circle().fill(
                            aktiv
                                ? AppleUIKitTokens.systemBlue.opacity(0.42)
                                : VisionOSGlasFlaeche.basisDunkel.opacity(0.55)
                        ))
                        .overlay(Circle().stroke(
                            aktiv ? AppleUIKitTokens.systemBlue.opacity(0.65) : Color.white.opacity(0.18),
                            lineWidth: 0.7
                        ))
                }
        }
        .buttonStyle(VisionOSGlasButtonStyle())
    }
}
struct VisionOSGlasButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
struct FenlynineOSGlassProminentButtonStyle: ButtonStyle {
    @Environment(\.fenlynineOSGlasModus) private var glasModus
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppleUIKitTokens.buttonLabel)
            .padding(.horizontal, AppleUIKitTokens.buttonPaddingH)
            .padding(.vertical, AppleUIKitTokens.buttonPaddingV)
            .foregroundStyle(Premium.onAction)
            .background { hintergrund(configuration: configuration) }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
    @ViewBuilder
    private func hintergrund(configuration: Configuration) -> some View {
        if glasModus == .kein {
            Capsule().fill(Premium.action.opacity(configuration.isPressed ? 0.75 : 1))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(MacOSSettingsTokens.selectionBlue.opacity(configuration.isPressed ? 0.85 : 1))
        }
    }
}
struct FenlynineOSGlassBorderedButtonStyle: ButtonStyle {
    @Environment(\.fenlynineOSGlasModus) private var glasModus
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppleUIKitTokens.buttonLabelCompact)
            .padding(.horizontal, AppleUIKitTokens.buttonPaddingHCompact)
            .padding(.vertical, AppleUIKitTokens.buttonPaddingVCompact)
            .foregroundStyle(FenlynineOSTheme.textPrimary)
            .background {
                if glasModus == .kein {
                    Capsule()
                        .fill(Premium.well.opacity(configuration.isPressed ? 0.55 : 1))
                        .overlay(Capsule().stroke(FenlynineOSTheme.border, lineWidth: 1))
                } else {
                    VisionOSGlasFlaeche.button(stil: .sekundaer)
                }
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
extension ButtonStyle where Self == FenlynineOSGlassProminentButtonStyle {
    static var fenlynineOSGlassProminent: FenlynineOSGlassProminentButtonStyle { .init() }
}
extension ButtonStyle where Self == FenlynineOSGlassBorderedButtonStyle {
    static var fenlynineOSGlassBordered: FenlynineOSGlassBorderedButtonStyle { .init() }
}
struct VisionOSGlasWidget<Content: View>: View {
    var titel: String? = nil
    var padding: CGFloat = AppleUIKitTokens.widgetPadding
    var maxHoehe: CGFloat? = AppleUIKitTokens.widgetMaxHeight
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: AppleUIKitTokens.widgetSpacing) {
            if let titel {
                Text(titel.uppercased())
                    .font(AppleUIKitTokens.widgetTitle)
                    .foregroundStyle(FenlynineOSTheme.accent.opacity(0.9))
                    .tracking(AppleUIKitTokens.widgetTitleTracking)
            }
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: maxHoehe, alignment: .topLeading)
        .background { VisionOSGlasFlaeche.widget(cornerRadius: AppleUIKitTokens.radiusWidget) }
        .clipShape(RoundedRectangle(cornerRadius: AppleUIKitTokens.radiusWidget, style: .continuous))
    }
}
struct VisionOSGlasHauptfenster<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(20)
            .background {
                VisionOSGlasFlaeche.schwebendesFenster(cornerRadius: AppleUIKitTokens.radiusWindow)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppleUIKitTokens.radiusWindow, style: .continuous))
    }
}
struct VisionOSBottomNavPill: View {
    @Binding var auswahl: SeitenleistenEintrag?
    let eintraege: [(SeitenleistenEintrag, String, String)]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(eintraege, id: \.0) { eintrag, label, symbol in
                let aktiv = auswahl == eintrag
                Button {
                    withAnimation(.spring(duration: 0.28, bounce: 0.2)) { auswahl = eintrag }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: aktiv ? .bold : .regular))
                        Text(label)
                            .font(.system(size: 9, weight: aktiv ? .semibold : .regular))
                    }
                    .foregroundStyle(aktiv ? .white : FenlynineOSTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        if aktiv {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MacOSSettingsTokens.selectionBlue)
                        } else {
                            Color.clear
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background { VisionOSGlasFlaeche.floatingPill() }
        .shadow(color: .black.opacity(0.5), radius: 32, y: 14)
    }
}
struct VisionOSIconRail: View {
    @Binding var auswahl: SeitenleistenEintrag?
    let eintraege: [SeitenleistenEintrag]
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "scale.3d")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FenlynineOSTheme.accent)
                .padding(.bottom, 8)
            ForEach(eintraege) { eintrag in
                VisionOSGlasIconButton(
                    symbol: eintrag.symbol,
                    aktiv: auswahl == eintrag,
                    groesse: 42
                ) {
                    withAnimation(.spring(duration: 0.25)) { auswahl = eintrag }
                }
                .help(eintrag.commandLabel)
            }
            Spacer(minLength: 8)
            VisionOSGlasIconButton(symbol: "gearshape.fill", groesse: 38) {
                auswahl = .einstellungen
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background { VisionOSGlasFlaeche.floatingPill(vertical: true) }
        .shadow(color: .black.opacity(0.48), radius: 28, y: 10)
    }
}
struct VisionOSGlasSegmentedPicker<Selection: Hashable>: View {
    let optionen: [(Selection, String, String)]
    @Binding var auswahl: Selection
    var body: some View {
        HStack(spacing: 4) {
            ForEach(optionen, id: \.0) { opt in
                let aktiv = auswahl == opt.0
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { auswahl = opt.0 }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: opt.2).font(.system(size: 10))
                        Text(opt.1).font(.system(size: 11, weight: aktiv ? .semibold : .regular))
                    }
                    .foregroundStyle(aktiv ? .white : FenlynineOSTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        if aktiv {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(MacOSSettingsTokens.selectionBlue)
                        } else {
                            Color.clear
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background { VisionOSGlasFlaeche.floatingPill() }
    }
}
struct VisionOSSidebarOrnament: View {
    @Binding var auswahl: SeitenleistenEintrag?
    @Binding var menueAusgeklappt: Bool
    private let schnellIcons: [SeitenleistenEintrag] = [
        .dashboard, .lexara, .analytik, .aufgaben, .kiChat
    ]
    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(duration: 0.30)) { menueAusgeklappt.toggle() }
            } label: {
                Image(systemName: "scale.3d")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FenlynineOSTheme.accent)
                    .frame(width: AppleUIKitTokens.ornamentIconGroesse, height: AppleUIKitTokens.ornamentIconGroesse)
            }
            .buttonStyle(.plain)
            .help(menueAusgeklappt ? "Menü schließen" : "Vollständiges Menü")
            ForEach(schnellIcons) { eintrag in
                VisionOSGlasIconButton(
                    symbol: eintrag.symbol,
                    aktiv: auswahl == eintrag,
                    groesse: AppleUIKitTokens.ornamentIconGroesse
                ) {
                    withAnimation(.spring(duration: 0.25)) {
                        auswahl = eintrag
                        menueAusgeklappt = false
                    }
                }
                .help(eintrag.commandLabel)
            }
            Spacer(minLength: 8)
            VisionOSGlasIconButton(symbol: "gearshape.fill", groesse: 40) {
                auswahl = .einstellungen
                menueAusgeklappt = false
            }
            .help("Einstellungen")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background { VisionOSGlasFlaeche.floatingPill(vertical: true) }
        .shadow(color: .black.opacity(0.45), radius: 28, y: 10)
    }
}
struct VisionOSSidebarGlasMenue: View {
    @Binding var auswahl: SeitenleistenEintrag?
    @Binding var istSichtbar: Bool
    @EnvironmentObject var authManager: AuthManager
    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(duration: 0.28)) { istSichtbar = false }
                }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FENLYNINEOS MOBIL")
                            .font(AppleUIKitTokens.title3)
                            .foregroundStyle(FenlynineOSTheme.textPrimary)
                        Text("Koordinationszentrale")
                            .font(AppleUIKitTokens.caption2)
                            .foregroundStyle(FenlynineOSTheme.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.28)) { istSichtbar = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(FenlynineOSTheme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background { VisionOSGlasFlaeche.button(stil: .ghost) }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(SeitenleistenKoordinationsGruppe.allCases) { gruppe in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(gruppe.titel)
                                    .font(AppleUIKitTokens.widgetTitle)
                                    .foregroundStyle(gruppe.accent)
                                    .tracking(AppleUIKitTokens.widgetTitleTracking)
                                    .padding(.horizontal, 20)
                                ForEach(gruppe.eintraege) { eintrag in
                                    VisionOSSidebarMenueZeile(
                                        eintrag: eintrag,
                                        aktiv: auswahl == eintrag
                                    ) {
                                        auswahl = eintrag
                                        withAnimation(.spring(duration: 0.28)) { istSichtbar = false }
                                    }
                                }
                                if gruppe.zeigtMarkenTrennerDanach {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.10))
                                        .frame(height: 1)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                SidebarFooter()
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background { VisionOSGlasFlaeche.hauptPanel(cornerRadius: 28) }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.leading, AppleUIKitTokens.ornamentBreite + 12)
            .padding(.vertical, 20)
            .shadow(color: .black.opacity(0.50), radius: 40, y: 16)
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
}
struct VisionOSSidebarMenueZeile: View {
    let eintrag: SeitenleistenEintrag
    let aktiv: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().fill(aktiv ? AppleUIKitTokens.systemBlue.opacity(0.35) : Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 0.6))
                        .frame(width: 36, height: 36)
                    Image(systemName: eintrag.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(aktiv ? .white : FenlynineOSTheme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(eintrag.commandLabel)
                        .font(AppleUIKitTokens.caption.weight(aktiv ? .semibold : .regular))
                        .foregroundStyle(FenlynineOSTheme.textPrimary)
                        .lineLimit(2)
                    if let sub = eintrag.commandSubtitle {
                        Text(sub)
                            .font(.system(size: 9))
                            .foregroundStyle(FenlynineOSTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if eintrag == .compliance {
                    Text("!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background { VisionOSGlasFlaeche.button(stil: .primaerBlau) }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background {
                if aktiv {
                    VisionOSGlasFlaeche.sidebarZeile(aktiv: true, cornerRadius: 14)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
