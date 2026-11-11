import SwiftUI
struct FenlynineOSSchnellnavigation: View {
    @Binding var auswahl: SeitenleistenEintrag?
    @Environment(\.fenlynineOSGlasModus) private var glasModus
    private let module: [(SeitenleistenEintrag, String, String)] = [
        (.dashboard, "Start", "house.fill"),
        (.lexara, "Lexara", "folder.fill"),
        (.strategos, "Strategos", "shield.lefthalf.filled"),
        (.organon, "Organon", "point.3.connected.trianglepath.dotted"),
        (.opportunisma, "Opportunisma", "scope"),
        (.aufgaben, "Aufgaben", "checklist")
    ]
    var body: some View {
        HStack(spacing: 6) {
            ForEach(module, id: \.0) { eintrag, label, symbol in
                let aktiv = auswahl == eintrag
                Button {
                    withAnimation(.spring(duration: 0.25)) { auswahl = eintrag }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: symbol)
                            .font(.system(size: 11, weight: aktiv ? .bold : .regular))
                        Text(label)
                            .font(.system(size: 11, weight: aktiv ? .semibold : .regular))
                    }
                    .foregroundStyle(aktiv ? .white : FenlynineOSTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background {
                        if aktiv {
                            VisionOSGlasFlaeche.button(stil: .primaerBlau)
                        } else if glasModus == .vollstaendig {
                            Color.clear
                        } else {
                            Capsule().fill(Color.white.opacity(0.04))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(6)
        .background { schnellnavHintergrund }
    }
    @ViewBuilder
    private var schnellnavHintergrund: some View {
        switch glasModus {
        case .vollstaendig, .milchglasOverlay:
            Capsule()
                .fill(.regularMaterial)
                .overlay(Capsule().fill(VisionOSGlasFlaeche.basisDunkel.opacity(0.7)))
                .overlay(Capsule().fill(VisionOSGlasFlaeche.basisBlau))
                .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 0.6))
                .shadow(color: .black.opacity(0.45), radius: 20, y: 8)
        case .kein:
            Capsule().fill(FenlynineOSTheme.surfaceElevated)
        }
    }
    private func aktivFarbe(fuer eintrag: SeitenleistenEintrag) -> Color {
        if eintrag == .strategos { return FenlynineOSTheme.warning }
        return FenlynineOSTheme.accent
    }
}
struct FenlynineOSModulKontextLeiste: View {
    let eintrag: SeitenleistenEintrag
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: eintrag.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(eintrag.istKernmodul ? eintrag.kernmodulAkzentfarbe : FenlynineOSTheme.accent)
                .frame(width: 32, height: 32)
                .background(
                    (eintrag.istKernmodul ? eintrag.kernmodulAkzentfarbe : FenlynineOSTheme.accent).opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(eintrag.kernmodulName ?? eintrag.commandLabel)
                    .font(AppleUIKitTokens.headline)
                    .foregroundStyle(FenlynineOSTheme.textPrimary)
                if let sub = eintrag.commandSubtitle {
                    Text(sub)
                        .font(AppleUIKitTokens.caption2)
                        .foregroundStyle(FenlynineOSTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if eintrag.istKernmodul {
                Text("KERNMODUL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(eintrag.kernmodulAkzentfarbe)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(eintrag.kernmodulAkzentfarbe.opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .modifier(MilchglasLeistenHintergrund())
    }
}
struct MilchglasLeistenHintergrund: ViewModifier {
    @Environment(\.fenlynineOSGlasModus) private var glasModus
    func body(content: Content) -> some View {
        content.background {
            switch glasModus {
            case .vollstaendig:
                Rectangle().fill(.ultraThinMaterial)
            case .milchglasOverlay:
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.45))
                    .overlay(Rectangle().fill(AppleUIKitTokens.rauchglasTint))
            case .kein:
                Rectangle().fill(FenlynineOSTheme.surface)
            }
        }
    }
}
extension SeitenleistenEintrag {
    var glasModus: FenlynineOSGlasModus {
        switch self {
        case .strategos, .organon, .lageZentrale, .konfliktRadar, .durchlauf: return .kein
        default: return .vollstaendig
        }
    }
    var istKernmodulDirekt: Bool {
        switch self {
        case .lexara, .strategos, .opportunisma, .organon, .lageZentrale: return true
        default: return false
        }
    }
    var istKernmodul: Bool {
        switch self {
        case .lexara, .richterprofile, .zeitleiste, .dokumente,
             .strategos, .opportunisma, .sunTzu, .analytik, .organon,
             .lageZentrale, .konfliktRadar, .mandatsPipeline, .honorare,
             .entscheidungsjournal, .praxisProfil, .beaCheck, .berufspflicht:
            return true
        default:
            return false
        }
    }
    var kernmodulName: String? {
        switch self {
        case .lexara, .richterprofile, .zeitleiste, .dokumente, .mandatsPipeline: return "Lexara"
        case .strategos, .opportunisma, .sunTzu, .analytik, .entscheidungsjournal: return "Strategos"
        case .organon: return "Organon"
        case .lageZentrale, .konfliktRadar, .honorare, .praxisProfil, .beaCheck, .berufspflicht: return "Imperium"
        default: return nil
        }
    }
    var kernmodulAkzentfarbe: Color {
        switch self {
        case .lexara, .richterprofile, .zeitleiste, .dokumente, .mandatsPipeline:
            return FenlynineOSTheme.accent
        case .strategos, .opportunisma, .sunTzu, .analytik, .entscheidungsjournal:
            return FenlynineOSTheme.warning
        case .organon:
            return FenlynineOSTheme.accent
        case .lageZentrale, .konfliktRadar, .honorare, .praxisProfil, .beaCheck, .berufspflicht:
            return FenlynineOSTheme.success
        default:
            return FenlynineOSTheme.accent
        }
    }
}
