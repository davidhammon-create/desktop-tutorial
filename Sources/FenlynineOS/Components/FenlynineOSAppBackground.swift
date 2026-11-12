import SwiftUI
enum FenlynineOSHintergrundStil: String, CaseIterable, Identifiable, Codable {
    case ambient
    case bigSurTag
    case bigSurNacht
    case schwarz
    case spaceGrey
    var id: String { rawValue }
    var bezeichnung: String {
        switch self {
        case .ambient: return "Warmes Ambient"
        case .bigSurTag: return "Big Sur — Tag"
        case .bigSurNacht: return "Big Sur — Nacht"
        case .schwarz: return "Schwarz"
        case .spaceGrey: return "Space Grey"
        }
    }
    var symbol: String {
        switch self {
        case .ambient: return "sun.haze.fill"
        case .bigSurTag: return "sun.max.fill"
        case .bigSurNacht: return "moon.stars.fill"
        case .schwarz: return "circle.fill"
        case .spaceGrey: return "square.fill"
        }
    }
    var vorschauFarbe: Color {
        switch self {
        case .ambient: return Color(red: 0.08, green: 0.09, blue: 0.12)
        case .bigSurTag: return Color(red: 0.12, green: 0.35, blue: 0.62)
        case .bigSurNacht: return Color(red: 0.02, green: 0.05, blue: 0.14)
        case .schwarz: return .black
        case .spaceGrey: return Color(red: 0.11, green: 0.11, blue: 0.12)
        }
    }
}
struct FenlynineOSAppBackground: View {
    @Bindable private var design = FenlynineOSDesignStore.shared
    var body: some View {
        ZStack {
            hintergrundInhalt
            if FenlynineOSDesignStore.shared.nutztVisionOSBlau {
                Rectangle()
                    .fill(.regularMaterial)
                    .opacity(0.42)
                    .overlay(Color.black.opacity(0.08))
            }
        }
        .ignoresSafeArea()
    }
    @ViewBuilder
    private var hintergrundInhalt: some View {
        switch design.aktiverHintergrund {
        case .ambient:
            FenlynineOSVisionOSAmbientBackground()
        case .bigSurTag:
            bildHintergrund("BigSurDay")
        case .bigSurNacht:
            bildHintergrund("BigSurNight")
        case .schwarz:
            Color.black
        case .spaceGrey:
            Color(red: 0.11, green: 0.11, blue: 0.12)
        }
    }
    @ViewBuilder
    private func bildHintergrund(_ name: String, overlay: Double = 0.18) -> some View {
        GeometryReader { geo in
            Image(name, bundle: .module)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(Color.black.opacity(overlay))
        }
    }
}
struct FenlynineOSVisionOSAmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.06),
                    Color(red: 0.04, green: 0.04, blue: 0.05),
                    Color(red: 0.08, green: 0.09, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(red: 0.85, green: 0.55, blue: 0.25).opacity(0.14))
                .frame(width: 720, height: 720)
                .blur(radius: 150)
                .offset(x: -280, y: -200)
            Circle()
                .fill(AppleUIKitTokens.systemBlue.opacity(0.10))
                .frame(width: 560, height: 560)
                .blur(radius: 120)
                .offset(x: 320, y: 240)
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: 60, y: 100)
        }
    }
}
typealias FenlynineOSVisionOSBackground = FenlynineOSAppBackground
struct FenlynineOSHintergrundPicker: View {
    @Bindable var store: FenlynineOSDesignStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hintergrund")
                .font(.headline)
            Text("Big-Sur-Landschaften, Schwarz oder Space Grey — Glas-Panels bleiben lesbar.")
                .font(.caption)
                .foregroundStyle(FenlynineOSTheme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(FenlynineOSHintergrundStil.allCases) { stil in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            store.setzeHintergrund(stil)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                if stil == .bigSurTag {
                                    Image("BigSurDay", bundle: .module)
                                        .resizable()
                                        .scaledToFill()
                                } else if stil == .bigSurNacht {
                                    Image("BigSurNight", bundle: .module)
                                        .resizable()
                                        .scaledToFill()
                                } else if stil == .ambient {
                                    FenlynineOSVisionOSAmbientBackground()
                                } else {
                                    stil.vorschauFarbe
                                }
                            }
                            .frame(height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        store.aktiverHintergrund == stil
                                            ? AppleUIKitTokens.systemBlue
                                            : Color.white.opacity(0.12),
                                        lineWidth: store.aktiverHintergrund == stil ? 2 : 0.5
                                    )
                            )
                            HStack(spacing: 4) {
                                Image(systemName: stil.symbol)
                                    .font(.system(size: 9))
                                Text(stil.bezeichnung)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(
                                store.aktiverHintergrund == stil
                                    ? AppleUIKitTokens.systemBlue
                                    : FenlynineOSTheme.textSecondary
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
