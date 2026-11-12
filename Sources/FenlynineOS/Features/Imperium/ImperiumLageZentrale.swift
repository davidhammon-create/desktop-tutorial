import SwiftUI
struct ImperiumLageZentraleView: View {
    @State private var praxis = ImperiumPraxisStore.shared
    @State private var pipeline = ImperiumPipelineStore.shared
    @State private var journal = ImperiumEntscheidungsJournal.shared
    @State private var konflikt = ImperiumKonfliktEngine.shared
    @State private var honorar = ImperiumHonorarStore.shared
    @State private var bea = ImperiumBeAStore.shared
    @State private var faelle: [LegalCase] = []
    @State private var fristen: [Deadline] = []
    @State private var tab: LageTab = .lagebild
    @State private var ladeFehler: String?
    enum LageTab: String, CaseIterable, Identifiable {
        case lagebild, portfolio, praxis
        var id: String { rawValue }
        var titel: String {
            switch self {
            case .lagebild: return "Lagebild"
            case .portfolio: return "Portfolio"
            case .praxis: return "Praxis"
            }
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("", selection: $tab) {
                ForEach(LageTab.allCases) { t in
                    Text(t.titel).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Premium.ink)
            Group {
                switch tab {
                case .lagebild: lagebild
                case .portfolio: PortfolioLinse().padding(8)
                case .praxis: ImperiumPraxisProfilView(embedded: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Premium.void)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let ladeFehler {
                Text(ladeFehler)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.10))
            }
        }
        .task {
            await laden()
            let namen = OrganonStore.shared.knoten.map(\.name)
            konflikt.scannen(faelle: faelle, mandanten: [], organonNamen: namen)
        }
    }
    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lagezentrale")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Premium.text)
                Text("\(praxis.kanzleiName) · \(praxis.aktiv.titel)")
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
            }
            Spacer()
            metric("Mandate", "\(faelle.filter { $0.status == .aktiv || $0.status == .vorbereitung }.count)")
            metric("Pipeline", "\(pipeline.akten.filter { $0.stufe != .archiv }.count)")
            metric("Konflikte", "\(konflikt.treffer.count)")
            metric("Fristen", "\(fristen.filter { $0.istKritisch }.count)")
        }
        .padding(16)
        .background(Premium.ink)
    }
    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Premium.text)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Premium.textFaint)
        }
        .frame(minWidth: 64)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
    }
    private var lagebild: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    lageKarte(
                        titel: "Berufspflicht",
                        symbol: "scalemass.fill",
                        text: "Fristenwache · Ausgangskontrolle · Mandatsgate · KI-Endprüfung",
                        ziel: .berufspflicht
                    )
                    lageKarte(
                        titel: "KonfliktRadar",
                        symbol: "exclamationmark.shield.fill",
                        text: konflikt.treffer.isEmpty
                            ? "Kein Treffer — Scan bei Neumandaten wiederholen."
                            : "\(konflikt.treffer.count) Hinweise · höchste: \(konflikt.treffer.first?.schwere.label ?? "—")",
                        ziel: .konfliktRadar
                    )
                    lageKarte(
                        titel: "Pipeline",
                        symbol: "arrow.triangle.branch",
                        text: pipelineKurz,
                        ziel: .mandatsPipeline
                    )
                    lageKarte(
                        titel: "Honorare",
                        symbol: "eurosign.circle",
                        text: String(format: "%.0f € gebucht · RVG-Orientierung bereit", honorar.summeEUR),
                        ziel: .honorare
                    )
                    lageKarte(
                        titel: "beA-Check",
                        symbol: "envelope.badge.shield.half.filled",
                        text: "\(bea.items.filter(\.erledigt).count)/\(bea.items.count) erledigt",
                        ziel: .beaCheck
                    )
                    lageKarte(
                        titel: "Journal",
                        symbol: "book.closed.fill",
                        text: journal.eintraege.first.map { "Zuletzt: \($0.titel)" } ?? "Noch leer — Entscheidungen werden automatisch protokolliert.",
                        ziel: .entscheidungsjournal
                    )
                    lageKarte(
                        titel: "Lexara",
                        symbol: "folder.fill",
                        text: "\(faelle.count) Mandate · Praxisfilter: \(praxis.aktiv.kurz)",
                        ziel: .lexara
                    )
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nächste Schritte (\(praxis.aktiv.titel))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Premium.text)
                    let offen = (praxis.checklistenStand[praxis.aktiv.rawValue] ?? []).filter { !$0.erledigt }.prefix(5)
                    if offen.isEmpty {
                        Text("Praxis-Checkliste vollständig.")
                            .font(.system(size: 11))
                            .foregroundStyle(Premium.computed)
                    } else {
                        ForEach(Array(offen)) { p in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .foregroundStyle(Premium.action)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.titel).font(.system(size: 12, weight: .medium)).foregroundStyle(Premium.text)
                                    Text(p.detail).font(.system(size: 10)).foregroundStyle(Premium.textSoft)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Premium.ink))
                if !fristen.filter(\.istKritisch).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kritische Fristen")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Premium.text)
                        ForEach(fristen.filter(\.istKritisch).prefix(6), id: \.self) { f in
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundStyle(Color.orange)
                                Text(f.title)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Premium.text)
                                Spacer()
                                Text(f.due_date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Premium.textFaint)
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Premium.ink))
                }
            }
            .padding(16)
        }
    }
    private var pipelineKurz: String {
        let counts = Dictionary(grouping: pipeline.akten, by: \.stufe).mapValues(\.count)
        let lead = counts[.lead, default: 0]
        let aktiv = counts[.aktiv, default: 0]
        return "\(lead) Leads · \(aktiv) aktiv"
    }
    private func lageKarte(titel: String, symbol: String, text: String, ziel: SeitenleistenEintrag) -> some View {
        Button {
            NotificationCenter.default.post(name: .navigateToSidebar, object: ziel.rawValue)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: symbol)
                        .foregroundStyle(Premium.action)
                    Text(titel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Premium.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Premium.textFaint)
                }
                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Premium.ink))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Premium.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    private func laden() async {
        var meldungen: [String] = []
        do { faelle = try await Services.cases.list() }
        catch { meldungen.append("Mandate: \(error.localizedDescription)") }
        do { fristen = try await Services.deadlines.list() }
        catch { meldungen.append("Fristen: \(error.localizedDescription)") }
        ladeFehler = meldungen.isEmpty ? nil : meldungen.joined(separator: " · ")
    }
}
struct ImperiumPraxisProfilView: View {
    var embedded: Bool = false
    @State private var store = ImperiumPraxisStore.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !embedded {
                    Text("Praxisprofil")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Premium.text)
                    Text("Die App adaptiert Prioritäten für Patent, Straf, Wirtschaft, Syndikus und weitere — ohne Modul-Silos.")
                        .font(.system(size: 12))
                        .foregroundStyle(Premium.textSoft)
                }
                TextField("Kanzleiname", text: $store.kanzleiName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: store.kanzleiName) { _, _ in store.speichern() }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ImperiumPraxisTyp.allCases) { t in
                        Button {
                            store.setzeAktiv(t)
                            ImperiumEntscheidungsJournal.shared.eintrag(
                                typ: .system,
                                titel: "Praxisprofil: \(t.titel)",
                                detail: t.kurz,
                                module: ["Praxisprofil", "Lagezentrale"]
                            )
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: t.symbol)
                                    .foregroundStyle(store.aktiv == t ? Premium.action : Premium.textSoft)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(t.titel)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Premium.text)
                                    Text(t.kurz)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Premium.textSoft)
                                    ProgressView(value: store.fortschritt(fuer: t))
                                        .tint(Premium.action)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(store.aktiv == t ? Premium.action.opacity(0.12) : Premium.ink)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(store.aktiv == t ? Premium.action.opacity(0.5) : Premium.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Checkliste — \(store.aktiv.titel)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Premium.text)
                    ForEach(store.checklistenStand[store.aktiv.rawValue] ?? []) { p in
                        Button {
                            store.toggleCheck(typ: store.aktiv, id: p.id)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: p.erledigt ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(p.erledigt ? Premium.computed : Premium.textFaint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.titel)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Premium.text)
                                        .strikethrough(p.erledigt)
                                    Text(p.detail)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Premium.textSoft)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Premium.ink))
            }
            .padding(embedded ? 12 : 20)
        }
        .background(Premium.void)
        .fenlynineOSAdaptiveNavigationTitle(embedded ? "" : "Praxisprofil")
    }
}
