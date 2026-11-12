import SwiftUI
import AppKit
private struct FenlynineOSFensterModusKey: EnvironmentKey {
    static let defaultValue = false
}
private struct FenlynineOSVergleichSpalteKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    var fenlynineOSFensterModus: Bool {
        get { self[FenlynineOSFensterModusKey.self] }
        set { self[FenlynineOSFensterModusKey.self] = newValue }
    }
    var fenlynineOSVergleichSpalte: Bool {
        get { self[FenlynineOSVergleichSpalteKey.self] }
        set { self[FenlynineOSVergleichSpalteKey.self] = newValue }
    }
}
struct FenlynineOSAdaptiveNavigationTitle: ViewModifier {
    let title: String
    @Environment(\.fenlynineOSFensterModus) private var fensterModus
    @Environment(\.fenlynineOSVergleichSpalte) private var vergleichSpalte
    func body(content: Content) -> some View {
        content.navigationTitle((fensterModus || vergleichSpalte) ? "" : title)
    }
}
extension View {
    func fenlynineOSAdaptiveNavigationTitle(_ title: String) -> some View {
        modifier(FenlynineOSAdaptiveNavigationTitle(title: title))
    }
}
struct ModulFensterSchluessel: Hashable, Codable {
    var modul: String
    var instanz: Int
    var eintrag: SeitenleistenEintrag {
        SeitenleistenEintrag(rawValue: modul) ?? .lexara
    }
}
final class ModulFensterRegister {
    static let shared = ModulFensterRegister()
    private var stand: [String: Int] = [:]
    func naechsterSchluessel(fuer eintrag: SeitenleistenEintrag) -> ModulFensterSchluessel {
        let n = (stand[eintrag.rawValue] ?? 0) + 1
        stand[eintrag.rawValue] = n
        return ModulFensterSchluessel(modul: eintrag.rawValue, instanz: n)
    }
    func naechsteVergleichsnummer() -> Int {
        let n = (stand["__vergleich"] ?? 0) + 1
        stand["__vergleich"] = n
        return n
    }
}
enum ModulFensterKennung {
    static let modul = "fenlynineos-modul"
    static let vergleich = "fenlynineos-vergleich"
}
struct ModulInhalt: View {
    let eintrag: SeitenleistenEintrag
    var eigeneNavigation: Bool = true
    @Environment(\.fenlynineOSFensterModus) private var fensterModus
    @Environment(\.fenlynineOSVergleichSpalte) private var vergleichSpalte
    @ObservedObject private var kontoStore = KontoStore.shared
    var body: some View {
        let inhalt = Group {
            if !kontoStore.darf(eintrag) {
                AboGateView(eintrag: eintrag)
            } else {
            switch eintrag {
            case .lexara: CaseListView()
            case .vorgaenge: VorgaengeModulInhalt()
            case .strategos: StrategosView().fenlynineOSSFTypographyOnly()
            case .schreibtisch: SchreibtischView()
            case .dashboard: HomeView(inVisionPanel: false)
            case .opportunisma: OpportunismaView()
            case .cockpit: KanzleiAnalytikView()
            case .kiChat: FallAssistentView()
            case .compliance: KIComplianceView()
            case .aufgaben: AufgabenView()
            case .dokumente: DokumenteUebersichtView()
            case .richterprofile: RichterProfileView()
            case .zeitleiste: ZeitleisteView()
            case .analytik: KanzleiAnalytikView()
            case .sunTzu: FenylawStrategiesView()
            case .mandanten: MandantenView()
            case .plattformAgent: PlattformAgentView()
            case .organon: OrganonView()
            case .einstellungen: EinstellungenView()
            case .lageZentrale: ImperiumLageZentraleView()
            case .konfliktRadar: ImperiumKonfliktRadarView()
            case .mandatsPipeline: ImperiumMandatsPipelineView()
            case .honorare: ImperiumHonorareZeitView()
            case .entscheidungsjournal: ImperiumEntscheidungsJournalView()
            case .praxisProfil: ImperiumPraxisProfilView()
            case .beaCheck: ImperiumBeAChecklisteView()
            case .berufspflicht: ImperiumBerufspflichtDeskView()
            case .adminZentrale: AdminZentraleView()
            case .jurisdiktionen: JurisdiktionenView()
            case .selbstreparatur: SelbstreparaturView()
            case .enterpriseRadar: EnterpriseRadarView()
            case .durchlauf: DurchlaufView()
            default: CaseListView()
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        if vergleichSpalte || !eigeneNavigation {
            inhalt
        } else {
            NavigationStack { inhalt }
        }
    }
}
/// Vorgänge als eigenständiger Modulinhalt (Liste und geöffneter Vorgang).
/// Ohne diese Ansicht zeigte ein "Vorgänge"-Fenster die Fallliste von Lexara.
struct VorgaengeModulInhalt: View {
    @State private var offenerVorgangId: UUID?
    var body: some View {
        if let id = offenerVorgangId {
            StudioVorgangHost(vorgangId: id, onZurueck: { offenerVorgangId = nil })
        } else {
            StudioVorgangListe(onOeffnen: { offenerVorgangId = $0 })
        }
    }
}
struct ModulFensterAnsicht: View {
    let schluessel: ModulFensterSchluessel
    @Bindable private var appearance = AppearanceStore.shared
    private var eintrag: SeitenleistenEintrag { schluessel.eintrag }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                kopf
                Divider().overlay(Premium.hairline)
                ModulInhalt(eintrag: eintrag, eigeneNavigation: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
            }
            .background(Premium.void)
        }
        .environment(\.fenlynineOSFensterModus, true)
        .environment(\.fenlynineOSVergleichSpalte, false)
        .environment(\.fenlynineOSGlasModus, .kein)
        .environment(\.fenlynineOSVisionOSChrome, false)
        .fenlynineOSAppearance()
        .frame(minWidth: 640, minHeight: 480)
        .onAppear { haerteUndTitel() }
        .onChange(of: appearance.modus) { _, _ in haerteUndTitel() }
    }
    private func haerteUndTitel() {
        DispatchQueue.main.async {
            let soll = "\(eintrag.bezeichnung) — FenlynineOS Legal Suite"
            let prefix = "\(FenlynineOSFensterKennung.modulPrefix).\(eintrag.rawValue)."
            for w in NSApp.windows {
                let id = w.identifier?.rawValue ?? ""
                if id.hasPrefix(prefix) {
                    FenlynineOSMacWindowChrome.haerteModulFenster(w)
                    // Den Sperrhinweis im Titel gesperrter Module nicht überschreiben.
                    if !w.title.contains("gesperrt") { w.title = soll }
                } else if FenlynineOSFensterKennung.istModulOderVergleich(w) {
                    FenlynineOSMacWindowChrome.haerteModulFenster(w)
                }
            }
        }
    }
    private var kopf: some View {
        HStack(spacing: 10) {
            Image(systemName: eintrag.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Premium.action)
            VStack(alignment: .leading, spacing: 1) {
                Text(eintrag.bezeichnung)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Premium.text)
                if let sub = eintrag.commandSubtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundStyle(Premium.textFaint)
                        .lineLimit(1)
                }
            }
            if schluessel.instanz > 1 {
                Text("Fenster \(schluessel.instanz)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Premium.textFaint)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Premium.well))
            }
            Spacer()
            Button {
                ModulFensterHost.shared.oeffneModul(eintrag)
            } label: {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Premium.textSoft)
                    .frame(width: 28, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Zweites Fenster dieses Moduls")
            Button {
                ModulFensterHost.shared.oeffneVergleich()
            } label: {
                Image(systemName: "rectangle.split.3x1")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Premium.textSoft)
                    .frame(width: 28, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Vergleichsfenster öffnen")
            AppearanceToggle()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Premium.ink)
        .contentShape(Rectangle())
    }
}
struct VergleichsFensterAnsicht: View {
    let nummer: Int
    @Bindable private var appearance = AppearanceStore.shared
    @State private var links: SeitenleistenEintrag = .lexara
    @State private var mitte: SeitenleistenEintrag = .strategos
    @State private var rechts: SeitenleistenEintrag = .opportunisma
    @State private var dritteSpalte = false // Standard: 2 Spalten — weniger Verzerrung
    var body: some View {
        VStack(spacing: 0) {
            kopf
            Divider().overlay(Premium.hairline)
            GeometryReader { geo in
                let spalten = dritteSpalte ? 3 : 2
                let gap: CGFloat = 1
                let w = max(200, floor((geo.size.width - gap * CGFloat(spalten - 1)) / CGFloat(spalten)))
                HStack(spacing: gap) {
                    spalte(auswahl: $links, breite: w, hoehe: geo.size.height)
                    Rectangle().fill(Premium.hairline).frame(width: gap)
                    spalte(auswahl: $mitte, breite: w, hoehe: geo.size.height)
                    if dritteSpalte {
                        Rectangle().fill(Premium.hairline).frame(width: gap)
                        spalte(auswahl: $rechts, breite: w, hoehe: geo.size.height)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            .clipped()
        }
        .background(Premium.void)
        .environment(\.fenlynineOSFensterModus, true)
        .environment(\.fenlynineOSVergleichSpalte, true)
        .environment(\.fenlynineOSGlasModus, .kein)
        .environment(\.fenlynineOSVisionOSChrome, false)
        .fenlynineOSAppearance()
        .frame(minWidth: 820, minHeight: 480)
        .onAppear { haerteUndTitel() }
    }
    private func haerteUndTitel() {
        DispatchQueue.main.async {
            let soll = "Vergleich \(nummer) — FenlynineOS Legal Suite"
            for w in NSApp.windows where (w.identifier?.rawValue ?? "").hasPrefix(FenlynineOSFensterKennung.vergleichPrefix) {
                FenlynineOSMacWindowChrome.haerteModulFenster(w)
                w.title = soll
            }
            if let key = NSApp.keyWindow, (key.identifier?.rawValue ?? "").hasPrefix(FenlynineOSFensterKennung.vergleichPrefix) {
                key.title = soll
            }
        }
    }
    private var kopf: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.split.3x1")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Premium.action)
            Text("Vergleich \(nummer)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Premium.text)
            Text("Module nebeneinander · Auswahl je Spalte")
                .font(.system(size: 10))
                .foregroundStyle(Premium.textFaint)
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.15)) { dritteSpalte.toggle() }
            } label: {
                Text(dritteSpalte ? "Zwei Spalten" : "Drei Spalten")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Premium.textSoft)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.hairline, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            AppearanceToggle()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Premium.ink)
    }
    private func spalte(auswahl: Binding<SeitenleistenEintrag>, breite: CGFloat, hoehe: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: auswahl.wrappedValue.symbol)
                    .font(.system(size: 10))
                    .foregroundStyle(Premium.action)
                Picker("", selection: auswahl) {
                    ForEach(Self.vergleichbar, id: \.self) { e in
                        Text(e.bezeichnung).tag(e)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: min(220, breite - 40))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Premium.ink.opacity(0.6))
            Divider().overlay(Premium.hairline)
            ModulInhalt(eintrag: auswahl.wrappedValue, eigeneNavigation: false)
                .environment(\.fenlynineOSVergleichSpalte, true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(width: breite, height: hoehe, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
    }
    static let vergleichbar: [SeitenleistenEintrag] = [
        .lexara, .vorgaenge, .strategos, .opportunisma, .sunTzu, .analytik,
        .dashboard, .richterprofile, .zeitleiste, .dokumente,
        .organon, .schreibtisch, .aufgaben, .kiChat, .mandanten,
        .enterpriseRadar, .durchlauf, .jurisdiktionen, .honorare,
        .mandatsPipeline, .konfliktRadar, .lageZentrale
    ]
}
