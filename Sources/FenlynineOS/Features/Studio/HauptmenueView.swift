import SwiftUI
import AppKit
enum Hauptprogramm: String, CaseIterable, Identifiable {
    case fenlynineOS
    case missionControl
    case fenlynineOSiOS
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .fenlynineOS:    return AppDefaults.produktNameVoll
        case .missionControl: return "FenlynineOS Mission Control"
        case .fenlynineOSiOS: return "FenlynineOS Mobil"
        }
    }
    var untertitel: String {
        switch self {
        case .fenlynineOS:    return "Produktion · Vorgänge · Formeln · Linsen"
        case .missionControl: return "Redesign · Mission Control · radikale UX"
        case .fenlynineOSiOS: return "Mobil · Saal · Fristen · Daumenbedienung"
        }
    }
    var symbol: String {
        switch self {
        case .fenlynineOS:    return "scale.3d"
        case .missionControl: return "square.grid.3x3.fill"
        case .fenlynineOSiOS: return "iphone"
        }
    }
    var akzent: Color {
        switch self {
        case .fenlynineOS:    return Premium.action
        case .missionControl: return Color(red: 0.45, green: 0.35, blue: 0.95)
        case .fenlynineOSiOS: return Premium.computed
        }
    }
    var verbindungsText: String {
        switch self {
        case .fenlynineOS:
            return "Schreibt Vorgänge, Formeln und Rechtswissen. Ist die Quelle der Wahrheit."
        case .missionControl:
            return "Liest dieselbe Architektur-Idee (Vorgang als Kern), eigene Oberfläche. Öffnet als separates App-Bundle."
        case .fenlynineOSiOS:
            return "Für den Gerichtssaal und unterwegs. Nutzt denselben Rechtswissen-Korpus (Export/Sync)."
        }
    }
}
struct HauptmenueView: View {
    @Bindable private var appearance = AppearanceStore.shared
    @Bindable private var wissen = RechtswissenStore.shared
    let onOeffneFenlynineOS: () -> Void
    let onTutorial: () -> Void
    @State private var statusHinweis: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                kopf
                programme
                bruecke
                wissenLeiste
                unten
            }
            .padding(32)
            .frame(maxWidth: 880)
            .frame(maxWidth: .infinity)
        }
        .background {
            if appearance.istApple { Store.canvas } else { Premium.void }
        }
        .fenlynineOSAppearance()
    }
    private var kopf: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appearance.istApple {
                HStack {
                    StorePageHeader(
                        eyebrow: "FenlynineOS",
                        titel: "Account",
                        untertitel: "Drei Programme · ein Wissensrücken · eine Bedienlogik"
                    )
                    Spacer()
                    AppearanceToggle()
                }
                Text("Wähle das Werkzeug. Der Vorgang und das Rechtswissen bleiben erhalten.")
                    .font(Store.caption)
                    .foregroundStyle(Store.textSecondary)
            } else {
                HStack {
                    Text("FENLYNINEOS LEGAL SUITE")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Premium.action)
                        .tracking(1.5)
                    Spacer()
                    AppearanceToggle()
                }
                Text("Drei Programme · ein Wissensrücken · eine Bedienlogik")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Premium.textSoft)
                Text("Wähle das Werkzeug. Der Vorgang und das Rechtswissen bleiben erhalten.")
                    .font(.system(size: 12))
                    .foregroundStyle(Premium.textFaint)
            }
        }
    }
    private var programme: some View {
        VStack(spacing: 10) {
            ForEach(Hauptprogramm.allCases) { p in
                Button {
                    starte(p)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: p.symbol)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(p.akzent)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(p.akzent.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.titel)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Premium.text)
                            Text(p.untertitel)
                                .font(.system(size: 12))
                                .foregroundStyle(Premium.textSoft)
                            Text(p.verbindungsText)
                                .font(.system(size: 11))
                                .foregroundStyle(Premium.textFaint)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Premium.textFaint)
                    }
                    .padding(16)
                    .background(Premium.panel)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Premium.hairline, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
    private var bruecke: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WIE SIE ZUSAMMENHÄNGEN")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(Premium.textFaint)
            KIEntscheidungsKarte(
                titel: "Gemeinsamer Rücken",
                badge: .bestaetigt,
                abschnitte: [
                    .init(titel: "Vorgang", untertitel: "Ein Objekt in FenlynineOS",
                          zeilen: [
                            ("Typ · Zustand · Optionen", "geteilt", .formel),
                            ("Bewertung", "nur Formelkaskade", .formel)
                          ]),
                    .init(titel: "Rechtswissen", untertitel: "Radar speichert lokal",
                          zeilen: [
                            ("Korpus", "\(wissen.eintraege.count) Einträge", .bestaetigt),
                            ("Modellwechsel", "bleibt erhalten", .bestaetigt)
                          ])
                ],
                hinweis: "FenlynineOS und iOS konsumieren denselben Wissenskorpus — kein Abtippen."
            )
        }
    }
    private var wissenLeiste: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(RechtsradarAgent.shared.laeuft ? Premium.computed : Premium.mute)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text("Rechtsradar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Text(wissen.agentStatus)
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
            }
            Spacer()
            Button(RechtsradarAgent.shared.laeuft ? "Pausieren" : "Starten") {
                if RechtsradarAgent.shared.laeuft {
                    RechtsradarAgent.shared.stoppen()
                } else {
                    RechtsradarAgent.shared.starten()
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Premium.action)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action.opacity(0.1)))
        }
        .padding(14)
        .background(Premium.panel)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Premium.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private var unten: some View {
        HStack {
            Button {
                onTutorial()
            } label: {
                Label("Tutorial · Bedienung", systemImage: "book.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Premium.action)
            }
            .buttonStyle(.plain)
            Spacer()
            if let s = statusHinweis {
                Text(s)
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.proposed)
            }
            Button {
                onOeffneFenlynineOS()
            } label: {
                Text("Studio öffnen")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Premium.onAction)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [])
        }
    }
    private func starte(_ p: Hauptprogramm) {
        switch p {
        case .fenlynineOS:
            onOeffneFenlynineOS()
        case .missionControl:
            if oeffneApp(namen: ["FenlynineOS.app", "FenlynineOS"], suchPfade: FenlynineOSAppLocator.missionControlKandidaten) {
                statusHinweis = "FenlynineOS Mission Control gestartet"
            } else {
                statusHinweis = "FenlynineOS.app nicht gefunden — bitte bauen oder in Downloads prüfen"
            }
        case .fenlynineOSiOS:
            if oeffneApp(namen: ["LegalOS-iOS", "FenlynineOS-iOS"], suchPfade: FenlynineOSAppLocator.iOSHinweise) {
                statusHinweis = "iOS-Projekt geöffnet"
            } else {
                NSWorkspace.shared.open(wissen.exportPfad.deletingLastPathComponent())
                statusHinweis = "Rechtswissen-Ordner geöffnet — für iOS-Sync / Apple Intelligence"
            }
        }
    }
    private func oeffneApp(namen: [String], suchPfade: [URL]) -> Bool {
        for url in suchPfade {
            if FileManager.default.fileExists(atPath: url.path) {
                return NSWorkspace.shared.open(url)
            }
        }
        let homes = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"),
            Bundle.main.bundleURL.deletingLastPathComponent()
        ]
        for home in homes {
            for name in namen {
                let u = home.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: u.path) {
                    return NSWorkspace.shared.open(u)
                }
            }
        }
        return false
    }
}
enum FenlynineOSAppLocator {
    static var missionControlKandidaten: [URL] {
        let sibling = Bundle.main.bundleURL.deletingLastPathComponent()
        return [
            sibling.appendingPathComponent("FenlynineOS.app"),
            sibling.appendingPathComponent("LegalOS.app"),
            URL(fileURLWithPath: "/Applications/FenlynineOS.app"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/FenlynineOS.app"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/FenlynineOS.app")
        ]
    }
    static var iOSHinweise: [URL] {
        let sibling = Bundle.main.bundleURL.deletingLastPathComponent()
        return [
            sibling.appendingPathComponent("LegalOS-iOS"),
            sibling.appendingPathComponent("../LegalOS-iOS"),
            sibling.appendingPathComponent("FenlynineOS-iOS"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/Hågemmøn & Partner /lOS (LegalOS) - Laws/LegalOS-iOS")
        ]
    }
}
