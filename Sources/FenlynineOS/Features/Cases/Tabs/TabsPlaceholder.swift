import SwiftUI
struct TabGegneranalyse: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    private let subTabs = ["Profil & Simulation", "KI-Berater", "Verhaltenstracking", "Risikomatrix", "Psycho-Analyse"]
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(subTabs.indices, id: \.self) { i in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { subTab = i }
                        } label: {
                            Text(subTabs[i])
                                .font(.system(size: 12, weight: subTab == i ? .semibold : .regular))
                                .foregroundStyle(subTab == i ? .primary : .secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .overlay(alignment: .bottom) {
                                    if subTab == i {
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Divider()
                .padding(.bottom, 16)
            Group {
                switch subTab {
                case 0: GegnerProfilSimulationView(viewModel: viewModel, kiMode: kiMode)
                case 1: TabKIBeraterView(viewModel: viewModel, kiMode: kiMode)
                case 2: GegnerVerhaltenTrackingView(caseId: viewModel.caseId, fallName: viewModel.fall?.fallname ?? "", rechtsgebiet: viewModel.fall?.rechtsgebiet, kiMode: kiMode)
                case 3: GegnerRisikoMatrixView(viewModel: viewModel, kiMode: kiMode)
                case 4: LexaraGegnerPsychologieErgaenzungView(viewModel: viewModel, kiMode: kiMode)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
struct GegnerVerhaltenTrackingView: View {
    let caseId: String
    let fallName: String
    let rechtsgebiet: String?
    var kiMode: Bool = true
    @State private var eintraege: [GegnerVerhalten] = []
    @State private var laden = true
    @State private var zeigeFormular = false
    @State private var kiAnalyse: AnyCodable?
    @State private var analysiertMuster = false
    @State private var exportiert = false
    @State private var fehler: String?
    var body: some View {
        VStack(spacing: 16) {
            if !eintraege.isEmpty {
                statistikHeader
            }
            HStack(spacing: 8) {
                Button {
                    withAnimation { zeigeFormular.toggle() }
                } label: {
                    Label("Verhalten erfassen", systemImage: "plus.circle.fill")
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .controlSize(.small)
                if eintraege.count >= 2 {
                    Button {
                        Task { await musterAnalysieren() }
                    } label: {
                        if analysiertMuster {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Label("KI-Musteranalyse", systemImage: "brain.fill")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .controlSize(.small)
                    .disabled(analysiertMuster || !kiMode)
                }
                if !eintraege.isEmpty {
                    Button {
                        Task { await pdfExportieren() }
                    } label: {
                        if exportiert {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Label("PDF-Bericht", systemImage: "arrow.down.doc")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .controlSize(.small)
                }
            }
            if zeigeFormular {
                NeuerVerhaltenEintragForm(caseId: caseId) { neuer in
                    eintraege.insert(neuer, at: 0)
                    zeigeFormular = false
                } onAbbrechen: { zeigeFormular = false }
            }
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if let analyse = kiAnalyse {
                KIMusteranalyseView(analyse: analyse)
            }
            if laden {
                ProgressView("Lade Einträge…")
            } else if eintraege.isEmpty && !zeigeFormular {
                InfoHinweis(
                    titel: "Noch keine Verhaltenseinträge",
                    nachricht: "Erfassen Sie das erste Verhalten der Gegenseite — Fristen, Vergleichsreaktionen, Taktiken.",
                    symbol: "doc.text.magnifyingglass"
                )
            } else {
                ForEach(eintraege) { eintrag in
                    GegnerEintragKarte(eintrag: eintrag, onLoeschen: {
                        Task { await eintragLoeschen(eintrag) }
                    })
                }
            }
        }
        .task { await eintraegeHolen() }
    }
    private var statistikHeader: some View {
        let versaeumt = eintraege.filter { $0.typ == .versaeumte_frist }.count
        let abgelehnt = eintraege.filter { $0.typ == .vergleichsreaktion && $0.reaktion == .abgelehnt }.count
        let angenommen = eintraege.filter { $0.typ == .vergleichsreaktion && $0.reaktion == .angenommen }.count
        let dominantesMuster = eintraege.compactMap(\.pattern_tag).reduce(into: [:]) { $0[$1, default: 0] += 1 }.max(by: { $0.value < $1.value })?.key
        return HStack(spacing: 10) {
            StatistikPill(wert: "\(versaeumt)", label: "Versäumte Fristen", farbe: .red)
            StatistikPill(wert: "\(abgelehnt)", label: "Abgelehnte Vergleiche", farbe: .orange)
            StatistikPill(wert: "\(angenommen)", label: "Angenommene Vergleiche", farbe: .green)
            if let muster = dominantesMuster {
                StatistikPill(wert: muster.bezeichnung, label: "Dominantes Muster", farbe: .purple)
            }
        }
    }
    private func eintraegeHolen() async {
        laden = true
        eintraege = (try? await Services.gegnerVerhalten.listForCase(caseId: caseId)) ?? []
        laden = false
    }
    private func eintragLoeschen(_ eintrag: GegnerVerhalten) async {
        guard let id = eintrag.id else { return }
        do {
            try await Services.gegnerVerhalten.delete(id: id)
            eintraege.removeAll { $0.id == id }
        } catch {
            fehler = "Eintrag nicht gelöscht: \(error.localizedDescription)"
        }
    }
    private func musterAnalysieren() async {
        guard kiMode else { return }
        analysiertMuster = true
        fehler = nil
        defer { analysiertMuster = false }
        let uebersicht = eintraege.prefix(20).map { e in
            "[\(e.datum.isEmpty ? "?" : e.datum)] \(e.typ.bezeichnung): \"\(e.titel)\" | Reaktion: \(e.reaktion?.bezeichnung ?? "–") | Muster: \(e.pattern_tag?.bezeichnung ?? "–") | \(e.beschreibung ?? "")"
        }.joined(separator: "\n")
        let prompt = """
        Analysiere das historische Verhalten der Gegenseite in diesem Rechtsstreit und erkenne Muster.
        Fall: \(fallName)
        Rechtsgebiet: \(rechtsgebiet ?? "")
        PROTOKOLLIERTE VERHALTENSEINTRÄGE (\(eintraege.count)):
        \(uebersicht)
        Analysiere:
        1. Welche klaren Verhaltensmuster zeigt die Gegenseite?
        2. Wie reagiert sie typischerweise auf Vergleichsangebote?
        3. Welche Verzögerungstaktiken werden eingesetzt?
        4. Was ist die prognostizierte Strategie für die nächste Phase?
        5. Wie sollten wir diese Muster für unsere Verhandlungsstrategie nutzen?
        6. Wie beeinflusst dieses Verhalten die Erfolgswahrscheinlichkeit?
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "hauptmuster": ["type": "array", "items": ["type": "string"]],
                        "vergleichsstrategie": ["type": "string"],
                        "verzoegerungsmuster": ["type": "string"],
                        "prognose_einfluss": ["type": "string"],
                        "empfehlung": ["type": "string"],
                        "naechste_phase": ["type": "string"],
                        "verhandlungstipp": ["type": "string"]
                    ] as [String: Any]
                ] as [String: Any]
            )
            await MainActor.run { kiAnalyse = result }
            if let dict = result.dictValue {
                let ausgabe = (dict["empfehlung"] as? String ?? "") + "\n" + (dict["naechste_phase"] as? String ?? "")
                await KIProtokollService.log(
                    caseId: caseId,
                    kiName: "Gegner-Verhalten Musteranalyse",
                    eingabe: prompt,
                    ausgabe: ausgabe,
                    modell: "claude_sonnet_4_6"
                )
            }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func pdfExportieren() async {
        exportiert = true
        defer { exportiert = false }
        do {
            let url = try await FunctionService.shared.exportGegnerVerhaltenPDF(caseId: caseId)
            NSWorkspace.shared.open(url)
        } catch {
            fehler = "PDF-Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
struct StatistikPill: View {
    let wert: String
    let label: String
    let farbe: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(wert)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(farbe)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(farbe.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.12), lineWidth: 1))
    }
}
struct GegnerEintragKarte: View {
    let eintrag: GegnerVerhalten
    let onLoeschen: () -> Void
    @State private var aufgeklappt = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: eintrag.typ.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(eintrag.typ.bezeichnung)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        if let muster = eintrag.pattern_tag {
                            Text(muster.bezeichnung)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        }
                        if !eintrag.datum.isEmpty {
                            Text(eintrag.datum)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(eintrag.titel)
                        .font(.system(size: 12, weight: .medium))
                }
                Spacer()
                if let reaktion = eintrag.reaktion {
                    Text(reaktion.bezeichnung)
                        .font(.caption2.bold())
                        .foregroundStyle(reaktion == .angenommen ? .green : reaktion == .abgelehnt ? .red : .orange)
                }
                Button {
                    withAnimation { aufgeklappt.toggle() }
                } label: {
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button { onLoeschen() } label: {
                    Image(systemName: "trash").font(.caption).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            if aufgeklappt {
                Divider().padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 6) {
                    if let beschr = eintrag.beschreibung, !beschr.isEmpty {
                        Text(beschr).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 16) {
                        if let unser = eintrag.unser_angebot {
                            LabelWert(label: "Unser Angebot", wert: formatEuro(unser))
                        }
                        if let gegner = eintrag.gegner_angebot {
                            LabelWert(label: "Gegner-Angebot", wert: formatEuro(gegner))
                        }
                        if let tage = eintrag.verzoegerung_tage {
                            LabelWert(label: "Verzögerung", wert: "+\(tage) Tage")
                        }
                        if eintrag.auswirkung_prognose != 0 {
                            LabelWert(label: "Prognose-Impact",
                                      wert: "\(eintrag.auswirkung_prognose > 0 ? "+" : "")\(Int(eintrag.auswirkung_prognose))%",
                                      farbe: eintrag.auswirkung_prognose > 0 ? .green : .red)
                        }
                    }
                    if let ergebnis = eintrag.ergebnis, !ergebnis.isEmpty {
                        Text("Ergebnis: \(ergebnis)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(12)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
    }
}
struct LabelWert: View {
    let label: String
    let wert: String
    var farbe: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(wert).font(.caption.bold()).foregroundStyle(farbe)
        }
    }
}
struct KIMusteranalyseView: View {
    let analyse: AnyCodable
    var body: some View {
        Group {
            if let dict = analyse.dictValue {
                analyseContent(dict: dict)
            }
        }
    }
    @ViewBuilder
    private func analyseContent(dict: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("KI-Muster-Analyse", systemImage: "brain.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.purple)
            if let muster = dict["hauptmuster"] as? [String], !muster.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Erkannte Hauptmuster").font(.caption.bold()).foregroundStyle(.secondary)
                    WrapLayout(muster) { m in
                        Text(m)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.1), in: Capsule())
                    }
                }
            }
            let felder: [(String, String)] = [
                ("Vergleichsstrategie",   dict["vergleichsstrategie"] as? String ?? ""),
                ("Verzögerungsmuster",    dict["verzoegerungsmuster"] as? String ?? ""),
                ("Einfluss auf Prognose", dict["prognose_einfluss"] as? String ?? ""),
                ("Nächste Phase",         dict["naechste_phase"] as? String ?? ""),
            ].filter { !$0.1.isEmpty }
            ForEach(felder, id: \.0) { label, wert in
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption.bold()).foregroundStyle(.secondary)
                    Text(wert).font(.system(size: 12))
                }
            }
            if let tipp = dict["verhandlungstipp"] as? String, !tipp.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verhandlungstipp").font(.caption.bold())
                        Text(tipp).font(.system(size: 12))
                    }
                }
                .padding(10)
                .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.12), lineWidth: 1))
    }
}
struct WrapLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    init(_ items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 4) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}
struct NeuerVerhaltenEintragForm: View {
    let caseId: String
    let onCreated: (GegnerVerhalten) -> Void
    let onAbbrechen: () -> Void
    @State private var typ: GegnerVerhalten.EintragTyp = .sonstiges
    @State private var datum = ""
    @State private var titel = ""
    @State private var beschreibung = ""
    @State private var reaktion: GegnerVerhalten.RektionTyp? = nil
    @State private var unserAngebot = ""
    @State private var gegnerAngebot = ""
    @State private var verzoegerungTage = ""
    @State private var ergebnis = ""
    @State private var musterTag: GegnerVerhalten.MusterTag? = nil
    @State private var auswirkungPrognose = ""
    @State private var speichert = false
    @State private var speichernFehler: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Neues Verhalten erfassen")
                .font(.system(size: 13, weight: .semibold))
            if let err = speichernFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Typ").font(.caption).foregroundStyle(.secondary)
                    Picker("Typ", selection: $typ) {
                        ForEach(GegnerVerhalten.EintragTyp.allCases, id: \.self) {
                            Text($0.bezeichnung).tag($0)
                        }
                    }
                    .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Datum (YYYY-MM-DD)").font(.caption).foregroundStyle(.secondary)
                    TextField("2024-01-15", text: $datum)
                        .textFieldStyle(.roundedBorder)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Titel *").font(.caption).foregroundStyle(.secondary)
                TextField("Kurzbeschreibung", text: $titel)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Beschreibung").font(.caption).foregroundStyle(.secondary)
                TextField("Details...", text: $beschreibung, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
            if typ == .vergleichsreaktion {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reaktion").font(.caption).foregroundStyle(.secondary)
                        Picker("Reaktion", selection: $reaktion) {
                            Text("—").tag(Optional<GegnerVerhalten.RektionTyp>.none)
                            ForEach(GegnerVerhalten.RektionTyp.allCases, id: \.self) {
                                Text($0.bezeichnung).tag(Optional($0))
                            }
                        }
                        .labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unser Angebot (€)").font(.caption).foregroundStyle(.secondary)
                        TextField("0", text: $unserAngebot)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gegner-Angebot (€)").font(.caption).foregroundStyle(.secondary)
                        TextField("0", text: $gegnerAngebot)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            if typ == .versaeumte_frist {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verzögerung (Tage)").font(.caption).foregroundStyle(.secondary)
                    TextField("0", text: $verzoegerungTage)
                        .textFieldStyle(.roundedBorder)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Muster-Tag").font(.caption).foregroundStyle(.secondary)
                    Picker("Muster", selection: $musterTag) {
                        Text("—").tag(Optional<GegnerVerhalten.MusterTag>.none)
                        ForEach(GegnerVerhalten.MusterTag.allCases, id: \.self) {
                            Text($0.bezeichnung).tag(Optional($0))
                        }
                    }
                    .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prognose-Auswirkung %").font(.caption).foregroundStyle(.secondary)
                    TextField("0", text: $auswirkungPrognose)
                        .textFieldStyle(.roundedBorder)
                }
            }
            HStack {
                Spacer()
                Button("Abbrechen", action: onAbbrechen)
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                Button("Speichern") {
                    Task { await speichern() }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(titel.isEmpty || speichert)
            }
        }
        .padding(14)
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.12), lineWidth: 1))
    }
    private func speichern() async {
        speichert = true
        speichernFehler = nil
        var eintrag = GegnerVerhalten(case_id: caseId)
        eintrag.titel = titel
        eintrag.typ = typ
        eintrag.datum = datum
        eintrag.beschreibung = beschreibung.isEmpty ? nil : beschreibung
        eintrag.reaktion = reaktion
        eintrag.unser_angebot = Double(unserAngebot)
        eintrag.gegner_angebot = Double(gegnerAngebot)
        eintrag.verzoegerung_tage = Int(verzoegerungTage)
        eintrag.ergebnis = ergebnis.isEmpty ? nil : ergebnis
        eintrag.pattern_tag = musterTag
        eintrag.auswirkung_prognose = Double(auswirkungPrognose) ?? 0
        do {
            let created = try await Services.gegnerVerhalten.create(eintrag)
            await MainActor.run { onCreated(created) }
        } catch {
            await MainActor.run { speichernFehler = error.localizedDescription }
        }
        speichert = false
    }
}
struct GegnerRisikoMatrixView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var risikoAnalyse: String?
    @State private var laeuft = false
    @State private var fehler: String?
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gegner-Risikomatrix")
                        .font(.title2.bold())
                    Text("Wahrscheinlichkeit × Auswirkung für jede erkannte Gegner-Taktik")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await analyseErstellen() }
                } label: {
                    if laeuft { ProgressView().scaleEffect(0.7) }
                    else { Label(risikoAnalyse != nil ? "Neu analysieren" : "Matrix erstellen", systemImage: "chart.bar.xaxis.ascending") }
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .disabled(laeuft || !kiMode)
            }
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if let analyse = risikoAnalyse {
                KIProfilKarte(titel: "Risikomatrix-Analyse", inhalt: analyse)
            } else {
                InfoHinweis(
                    titel: "Gegner-Risikomatrix",
                    nachricht: "Die KI erstellt eine 2D-Risikomatrix aller identifizierten Gegner-Taktiken nach Eintrittswahrscheinlichkeit und Schadensausmaß — mit konkreten Gegenmaßnahmen für jede Risikostufe.",
                    symbol: "chart.bar.xaxis.ascending"
                )
            }
        }
    }
    private func analyseErstellen() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }
        let prompt = """
        Erstelle eine vollständige Risikomatrix für die Gegner-Taktiken in diesem Fall:
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "")
        Gegner-Argumente: \(gegnerArgs.map { "\($0.title) (Stärke \(Int($0.effectiveStrength))/10)" }.joined(separator: "; "))
        Identifiziere alle möglichen Gegner-Taktiken und bewerte jede nach:
        - Eintrittswahrscheinlichkeit (1-10)
        - Schadenspotenzial für unsere Position (1-10)
        - Erkennungsmerkmale (wann sehen wir, dass diese Taktik eingesetzt wird?)
        - Sofortmaßnahme (was tun, wenn diese Taktik eingesetzt wird?)
        Stufe die Risiken in KRITISCH / HOCH / MITTEL / NIEDRIG ein.
        Erkläre bei jedem Risiko, wie du die Wahrscheinlichkeit und den Schaden bewertest.
        """
        do {
            let result: String = try await LLMService.shared.invokeText(
                prompt: prompt,
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Gegner-Risikomatrix"
            )
            await MainActor.run { risikoAnalyse = result }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct TabRechtlicheAnalyse: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    private let subTabs = ["Compliance-Prüfung", "Kostenanalyse & Rspr.", "Präzedenzfälle"]
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(subTabs.indices, id: \.self) { i in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { subTab = i }
                        } label: {
                            Text(subTabs[i])
                                .font(.system(size: 12, weight: subTab == i ? .semibold : .regular))
                                .foregroundStyle(subTab == i ? .primary : .secondary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .overlay(alignment: .bottom) {
                                    if subTab == i {
                                        Rectangle().fill(Color.primary).frame(height: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Divider().padding(.bottom, 16)
            Group {
                switch subTab {
                case 0: ComplianceCheckerView(viewModel: viewModel, kiMode: kiMode)
                case 1: KostenanalyseView(viewModel: viewModel, kiMode: kiMode)
                case 2: PraezedenzfallView(viewModel: viewModel, kiMode: kiMode)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
struct ComplianceCheckerView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var warnungen: [CaseWarning] = []
    @State private var laden = true
    @State private var pruefen = false
    @State private var letzterCheck: Date? = nil
    @State private var filter: CaseWarning.Schwere? = nil
    @State private var fehler: String?
    var gefilterteWarnungen: [CaseWarning] {
        let base = warnungen.filter { !$0.resolved }.sorted { $0.severity.sortOrder < $1.severity.sortOrder }
        guard let f = filter else { return base }
        return base.filter { $0.severity == f }
    }
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("KI-Compliance-Prüfung", systemImage: "checkmark.shield.fill")
                        .font(.title2.bold())
                    Text("Analysiert Argumente & Beweise gegen aktuelle Rechtsprechung")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let letzter = letzterCheck {
                        Text("Letzte Prüfung: \(letzter.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Button {
                    Task { await compliancePruefen() }
                } label: {
                    if pruefen {
                        ProgressView().scaleEffect(0.7)
                        Text("Prüfe…").font(.caption)
                    } else {
                        Label("Scan starten", systemImage: "bolt.fill")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(pruefen || !kiMode)
            }
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if !warnungen.isEmpty {
                HStack(spacing: 10) {
                    let total = warnungen.filter { !$0.resolved }.count
                    let kritisch = warnungen.filter { !$0.resolved && $0.severity == .kritisch }.count
                    let hoch = warnungen.filter { !$0.resolved && $0.severity == .hoch }.count
                    ForEach([
                        ("Insgesamt", "\(total)", Color.primary),
                        ("Kritisch", "\(kritisch)", Color.red),
                        ("Hoch", "\(hoch)", Color.orange),
                    ], id: \.0) { label, wert, farbe in
                        VStack(spacing: 2) {
                            Text(wert).font(.system(size: 18, weight: .bold)).foregroundStyle(farbe)
                            Text(label).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterPill(bezeichnung: "Alle", aktiv: filter == nil) { filter = nil }
                        ForEach(CaseWarning.Schwere.allCases, id: \.self) { schwere in
                            FilterPill(bezeichnung: schwere.bezeichnung, aktiv: filter == schwere, farbe: schwere.farbe) {
                                filter = (filter == schwere) ? nil : schwere
                            }
                        }
                    }
                }
            }
            if laden {
                ProgressView("Lade Warnungen…")
            } else if gefilterteWarnungen.isEmpty {
                if warnungen.isEmpty {
                    InfoHinweis(
                        titel: "Keine Warnungen",
                        nachricht: "Starten Sie eine Compliance-Prüfung, um Lücken zu erkennen.",
                        symbol: "checkmark.shield"
                    )
                } else {
                    InfoHinweis(titel: "Alle behoben", nachricht: "Alle gefilterten Warnungen wurden behoben.", symbol: "checkmark.circle.fill")
                }
            } else {
                ForEach(gefilterteWarnungen) { warnung in
                    WarningKarte(warnung: warnung) {
                        Task { await warnungBeheben(warnung) }
                    }
                }
            }
            WieEsFunktioniertView()
        }
        .task { await warnungenLaden() }
    }
    private func warnungenLaden() async {
        laden = true
        warnungen = (try? await Services.caseWarnings.filter(
            ["case_id": viewModel.caseId, "resolved": "false"]
        )) ?? []
        laden = false
    }
    private func compliancePruefen() async {
        pruefen = true
        fehler = nil
        defer { pruefen = false }
        do {
            _ = try await FunctionService.shared.checkCaseCompliance(caseId: viewModel.caseId)
            letzterCheck = Date()
            await warnungenLaden()
            let offen = warnungen.filter { !$0.resolved }.count
            await KIProtokollService.log(
                caseId: viewModel.caseId,
                kiName: "Compliance-Prüfung",
                eingabe: "checkCaseCompliance für Fall \(viewModel.fall?.fallname ?? viewModel.caseId)",
                ausgabe: "\(offen) offene Warnungen nach Scan",
                modell: "claude_sonnet_4_6"
            )
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func warnungBeheben(_ warnung: CaseWarning) async {
        guard let id = warnung.id else { return }
        var updated = warnung
        updated.resolved = true
        updated.resolved_date = ISO8601DateFormatter().string(from: Date())
        do {
            _ = try await Services.caseWarnings.update(id: id, entity: updated)
            await warnungenLaden()
        } catch {
            fehler = "Warnung nicht gespeichert: \(error.localizedDescription)"
        }
    }
}
struct WarningKarte: View {
    let warnung: CaseWarning
    let onBeheben: () -> Void
    @State private var aufgeklappt = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { aufgeklappt.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(warnung.severity.farbe)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(warnung.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        if let el = warnung.element_title {
                            Text(el).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let wt = warnung.warning_type {
                        Text(wt.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }
                    Text(warnung.severity.bezeichnung)
                        .font(.caption2.bold())
                        .foregroundStyle(warnung.severity.farbe)
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            if aufgeklappt {
                Divider().padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 8) {
                    if let desc = warnung.description {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Beschreibung").font(.caption.bold()).foregroundStyle(.secondary)
                            Text(desc).font(.system(size: 12))
                        }
                    }
                    if let sug = warnung.suggestion {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill").font(.caption2).foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Empfohlene Maßnahme").font(.caption.bold())
                                Text(sug).font(.system(size: 12))
                            }
                        }
                    }
                    if let rspr = warnung.rspr_reference {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "book.fill").font(.caption2).foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rechtsprechungs-Referenz").font(.caption.bold())
                                Text(rspr).font(.system(size: 12)).foregroundStyle(.blue)
                            }
                        }
                    }
                    HStack {
                        Button {
                            onBeheben()
                        } label: {
                            Label("Als behoben markieren", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                        .controlSize(.small)
                        Spacer()
                    }
                }
                .padding(12)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(warnung.severity.farbe.opacity(0.2), lineWidth: 1))
    }
}
struct FilterPill: View {
    let bezeichnung: String
    let aktiv: Bool
    var farbe: Color = .primary
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(bezeichnung)
                .font(.system(size: 11, weight: aktiv ? .semibold : .regular))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(aktiv ? farbe : Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(aktiv ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}
struct WieEsFunktioniertView: View {
    @State private var aufgeklappt = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { aufgeklappt.toggle() }
            } label: {
                HStack {
                    Image(systemName: "info.circle").foregroundStyle(.blue)
                    Text("Wie die Prüfung funktioniert").font(.caption.bold())
                    Spacer()
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down").font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(10)
            }
            .buttonStyle(.plain)
            if aufgeklappt {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach([
                        "Argumente ohne Beweise prüfen",
                        "Gegensätzliche Argumente mit ähnlicher Stärke erkennen",
                        "KI-Analyse gegen aktuelle Rechtsprechung",
                        "Fehlende Fristen und schwache Beweise identifizieren",
                    ], id: \.self) { text in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark").font(.caption2).foregroundStyle(.green)
                            Text(text).font(.caption)
                        }
                    }
                }
                .padding([.horizontal, .bottom], 10)
            }
        }
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct KostenanalyseView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var entscheidungen: [RsprEntscheidung] = []
    @State private var zusammenfassung: String?
    @State private var laeuft = false
    @State private var fehler: String?
    struct RsprEntscheidung: Identifiable {
        let id = UUID()
        var gericht: String
        var aktenzeichen: String
        var datum: String
        var leitsatz: String
        var relevanz: String
        var staerke: String
    }
    var body: some View {
        VStack(spacing: 20) {
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kostenanalyse & Rechtsprechung")
                        .font(.title2.bold())
                    Text("KI sucht relevante Urteile im Internet (wie TabAnalyse)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await rechtsprechungSuchen() }
                } label: {
                    if laeuft { ProgressView().scaleEffect(0.7) }
                    else { Label("Rechtsprechung suchen", systemImage: "globe") }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(laeuft || !kiMode)
            }
            if let fall = viewModel.fall, let streitwert = fall.streitwert {
                HStack(spacing: 16) {
                    KosteninfoKarte(titel: "Streitwert", wert: formatEuro(streitwert))
                    KosteninfoKarte(titel: "Gerichtsgebühren (ca.)", wert: formatEuro(streitwert * 0.048))
                    KosteninfoKarte(titel: "Anwaltsgebühren (ca.)", wert: formatEuro(streitwert * 0.025))
                }
            }
            if let z = zusammenfassung, !z.isEmpty {
                Text(z).font(.system(size: 12)).lineSpacing(4)
                    .padding(10)
                    .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            }
            if !entscheidungen.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relevante Entscheidungen (\(entscheidungen.count))")
                        .font(.system(size: 13, weight: .semibold))
                    ForEach(entscheidungen) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(e.gericht) — \(e.aktenzeichen)").font(.caption.bold())
                                Spacer()
                                Text(e.staerke).font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1), in: Capsule())
                            }
                            Text(e.leitsatz).font(.caption)
                            Text(e.relevanz).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else if !laeuft {
                InfoHinweis(
                    titel: "Rechtsprechungssuche",
                    nachricht: "Die KI durchsucht das Internet nach relevanten BGH/OLG-Entscheidungen zu Ihren Argumenten und der zentralen Rechtsfrage.",
                    symbol: "globe"
                )
            }
            if !viewModel.luecken.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rechtslücken (\(viewModel.luecken.count))")
                        .font(.system(size: 13, weight: .semibold))
                    ForEach(viewModel.luecken) { RechtsluckeKarte(lucke: $0) }
                }
            }
        }
    }
    private func rechtsprechungSuchen() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let argList = viewModel.argumente.filter { $0.side == .eigen }.map { $0.title }.joined(separator: ", ")
        let prompt = """
        Du bist ein erfahrener Fachanwalt und suchst gezielt nach Rechtsprechung, die unsere Mandantenposition stärkt oder gefährdet. Suche im Internet nach aktueller relevanter Rechtsprechung für folgenden Fall:
        Fall: "\(fall.fallname)"
        Rechtsgebiet: \(fall.rechtsgebiet ?? "Zivilrecht")
        Gericht: \(fall.gericht ?? "")
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
        Argumente: \(argList.isEmpty ? "keine" : argList)
        Instanz: \(fall.instanz.rawValue)
        Finde 5-8 relevante Gerichtsentscheidungen aus Deutschland. Gib NUR Entscheidungen an, die wirklich existieren und über eine Internetsuche verifizierbar sind.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "entscheidungen": ["type": "array", "items": ["type": "object", "properties": [
                        "gericht": ["type": "string"], "aktenzeichen": ["type": "string"],
                        "datum": ["type": "string"], "leitsatz": ["type": "string"],
                        "relevanz": ["type": "string"], "anwendung": ["type": "string"],
                        "staerke": ["type": "string"]
                    ]]],
                    "zusammenfassung": ["type": "string"]
                ]] as [String: Any],
                webContext: true,
                logCaseId: viewModel.caseId,
                logKiName: "Kostenanalyse Rechtsprechung"
            )
            let dict = try KIJson.requireObject(result, kontext: "Rechtsprechungssuche")
            let liste = (dict["entscheidungen"] as? [[String: Any]] ?? []).map {
                RsprEntscheidung(
                    gericht: $0["gericht"] as? String ?? "",
                    aktenzeichen: $0["aktenzeichen"] as? String ?? "",
                    datum: $0["datum"] as? String ?? "",
                    leitsatz: $0["leitsatz"] as? String ?? "",
                    relevanz: $0["relevanz"] as? String ?? "",
                    staerke: $0["staerke"] as? String ?? "mittel"
                )
            }
            await MainActor.run {
                entscheidungen = liste
                zusammenfassung = dict["zusammenfassung"] as? String
            }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct KosteninfoKarte: View {
    let titel: String
    let wert: String
    var body: some View {
        VStack(spacing: 4) {
            Text(wert).font(.system(size: 16, weight: .bold))
            Text(titel).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct PraezedenzfallView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var urteile: [PraezedenzUrteil] = []
    @State private var suchstrategie: String?
    @State private var laeuft = false
    @State private var fehler: String?
    struct PraezedenzUrteil: Identifiable {
        let id = UUID()
        var aktenzeichen: String
        var gericht: String
        var datum: String
        var leitsatz: String
        var relevanz: String
        var seite: String
        var staerke: Int
    }
    var body: some View {
        VStack(spacing: 20) {
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Präzedenzfall-Recherche")
                        .font(.title2.bold())
                    Text("KI sucht vergleichbare Urteile im Internet (Gemini Flash)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await rechercheStarten() }
                } label: {
                    if laeuft { ProgressView().scaleEffect(0.7) }
                    else { Label("Recherche starten", systemImage: "magnifyingglass.circle") }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(laeuft || !kiMode)
            }
            if let info = suchstrategie, !info.isEmpty {
                Text(info).font(.caption).foregroundStyle(.secondary)
            }
            if !urteile.isEmpty {
                ForEach(urteile) { u in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(u.gericht) — \(u.aktenzeichen)").font(.caption.bold())
                            Spacer()
                            Text("\(u.staerke)/10 · \(u.seite)").font(.caption2)
                        }
                        Text(u.leitsatz).font(.caption)
                        Text(u.relevanz).font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            } else if !laeuft {
                InfoHinweis(
                    titel: "Präzedenzfall-Recherche",
                    nachricht: "Die KI analysiert BGH-, OLG- und EuGH-Entscheidungen mit Internetsuche und zeigt Relevanz für unseren Fall.",
                    symbol: "magnifyingglass.circle"
                )
            }
        }
    }
    private func rechercheStarten() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let prompt = """
        Führe eine umfassende Präzedenzfall-Recherche durch (mit Internetsuche):
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "unbekannt")
        Instanz: \(fall.instanz.rawValue)
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "nicht angegeben")
        Eigene Argumente: \(viewModel.argumente.filter { $0.side == .eigen }.prefix(5).map { $0.title }.joined(separator: "; "))
        Finde 5-8 konkrete, gut belegbare Urteile (BGH, OLG, BVerfG, EuGH wenn relevant).
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "urteile": ["type": "array", "items": ["type": "object", "properties": [
                        "aktenzeichen": ["type": "string"], "gericht": ["type": "string"],
                        "datum": ["type": "string"], "leitsatz": ["type": "string"],
                        "relevanz_erklaerung": ["type": "string"],
                        "seite": ["type": "string"], "staerke": ["type": "number"]
                    ]]],
                    "suchstrategie": ["type": "string"],
                    "lucken_hinweis": ["type": "string"]
                ]] as [String: Any],
                webContext: true,
                model: "gemini_3_flash",
                logCaseId: viewModel.caseId,
                logKiName: "Präzedenzfall-Recherche"
            )
            let dict = try KIJson.requireObject(result, kontext: "Präzedenzfall-Recherche")
            let liste = (dict["urteile"] as? [[String: Any]] ?? []).map {
                PraezedenzUrteil(
                    aktenzeichen: $0["aktenzeichen"] as? String ?? "",
                    gericht: $0["gericht"] as? String ?? "",
                    datum: $0["datum"] as? String ?? "",
                    leitsatz: $0["leitsatz"] as? String ?? "",
                    relevanz: $0["relevanz_erklaerung"] as? String ?? "",
                    seite: $0["seite"] as? String ?? "neutral",
                    staerke: KIJson.intValue($0["staerke"]) ?? 6
                )
            }
            let strategie = [dict["suchstrategie"] as? String, dict["lucken_hinweis"] as? String]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
            await MainActor.run {
                urteile = liste
                suchstrategie = strategie.isEmpty ? nil : strategie
            }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct TabStrategie: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var kiAnalyseLaeuft = false
    @State private var strategieErgebnis: StrategieKIResult? = nil
    @State private var fehler: String?
    struct StrategieKIResult {
        var erfolgswahrscheinlichkeit: Int
        var begruendung: String
        var staerksteGegenargumente: [(titel: String, gefahr: String, schwere: String)]
        var kritischeSchwachstellen: [(titel: String, beschreibung: String)]
        var strategischeEmpfehlung: String
        var gegenmassnahmen: [(massnahme: String, ziel: String, rechtsgrundlage: String)]
    }
    var body: some View {
        VStack(spacing: 20) {
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strategie & Prognose")
                        .font(.title2.bold())
                    Text("KI-Prognose mit Gegenargumenten und strategischer Empfehlung")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await strategieEntwickeln() }
                } label: {
                    if kiAnalyseLaeuft {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Label("KI-Analyse starten", systemImage: "shield.lefthalf.filled")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(kiAnalyseLaeuft || !kiMode)
            }
            if let result = strategieErgebnis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(result.erfolgswahrscheinlichkeit)%").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(.blue)
                        Text("KI-Erfolgswahrscheinlichkeit").font(.caption).foregroundStyle(.secondary)
                    }
                    if !result.begruendung.isEmpty {
                        Text(result.begruendung).font(.system(size: 12)).lineSpacing(3)
                    }
                    if !result.staerksteGegenargumente.isEmpty {
                        Text("Stärkste Gegenargumente").font(.caption.bold())
                        ForEach(Array(result.staerksteGegenargumente.enumerated()), id: \.offset) { _, g in
                            Text("[\(g.schwere)] \(g.titel): \(g.gefahr)").font(.caption2)
                        }
                    }
                    if !result.strategischeEmpfehlung.isEmpty {
                        KIProfilKarte(titel: "Strategische Empfehlung", inhalt: result.strategischeEmpfehlung)
                    }
                }
            } else if !kiAnalyseLaeuft {
                InfoHinweis(
                    titel: "Strategische KI-Empfehlung",
                    nachricht: "Die KI berechnet Erfolgswahrscheinlichkeit, identifiziert Gegenargumente und entwickelt eine maßgeschneiderte Prozessstrategie.",
                    symbol: "shield.lefthalf.filled"
                )
            }
        }
    }
    private func strategieEntwickeln() async {
        guard let fall = viewModel.fall else { return }
        kiAnalyseLaeuft = true
        fehler = nil
        defer { kiAnalyseLaeuft = false }
        let eigenA = viewModel.argumente.filter { $0.side == .eigen }
        let gegnerA = viewModel.argumente.filter { $0.side == .gegner }
        let versaeumt = viewModel.fristen.filter { $0.status == .versaeumt }.count
        let prompt = """
        Du bist ein erfahrener Prozessanwalt auf Senior-Partner-Niveau.
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "") | Instanz: \(fall.instanz.rawValue)
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
        EIGENE ARGUMENTE:
        \(eigenA.map { "- \($0.title) (Stärke: \($0.strength)/10): \($0.description ?? "")" }.joined(separator: "\n"))
        GEGNERARGUMENTE:
        \(gegnerA.map { "- \($0.title) (Stärke: \($0.strength)/10): \($0.description ?? "")" }.joined(separator: "\n"))
        BEWEISE: \(viewModel.beweise.prefix(10).map { "\($0.title) (\($0.type.rawValue), \($0.weight)/10)" }.joined(separator: ", "))
        FRISTEN: \(viewModel.fristen.count) gesamt, \(versaeumt) versäumt
        Richter-Klägerquote: \(fall.richter_klaeger_rate.map { "\(Int($0))%" } ?? "50%")
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "erfolgswahrscheinlichkeit": ["type": "number"],
                    "begruendung": ["type": "string"],
                    "staerkste_gegenargumente": ["type": "array", "items": ["type": "object", "properties": [
                        "titel": ["type": "string"], "gefahr": ["type": "string"], "schwere": ["type": "string"]
                    ]]],
                    "kritische_schwachstellen": ["type": "array", "items": ["type": "object", "properties": [
                        "titel": ["type": "string"], "beschreibung": ["type": "string"]
                    ]]],
                    "strategische_empfehlung": ["type": "string"],
                    "gegenmassnahmen": ["type": "array", "items": ["type": "object", "properties": [
                        "massnahme": ["type": "string"], "ziel": ["type": "string"], "rechtsgrundlage": ["type": "string"]
                    ]]]
                ]] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "KI-Urteilsprognose & Strategie"
            )
            let d = try KIJson.requireObject(result, kontext: "KI-Urteilsprognose")
            let gegen = (d["staerkste_gegenargumente"] as? [[String: Any]] ?? []).map {
                (titel: $0["titel"] as? String ?? "", gefahr: $0["gefahr"] as? String ?? "", schwere: $0["schwere"] as? String ?? "mittel")
            }
            let schwach = (d["kritische_schwachstellen"] as? [[String: Any]] ?? []).map {
                (titel: $0["titel"] as? String ?? "", beschreibung: $0["beschreibung"] as? String ?? "")
            }
            let massnahmen = KIJson.array(in: d, keys: "gegenmassnahmen", "gegenmasnahmen").map {
                (massnahme: KIJson.string(in: $0, keys: "massnahme", "maßnahme") ?? "", ziel: KIJson.string(in: $0, keys: "ziel") ?? "",
                 rechtsgrundlage: KIJson.string(in: $0, keys: "rechtsgrundlage") ?? "")
            }
            await MainActor.run {
                strategieErgebnis = StrategieKIResult(
                    erfolgswahrscheinlichkeit: KIJson.intValue(d["erfolgswahrscheinlichkeit"]) ?? Int(fall.prognose ?? 50),
                    begruendung: KIJson.string(in: d, keys: "begruendung", "beguendung") ?? "",
                    staerksteGegenargumente: gegen,
                    kritischeSchwachstellen: schwach,
                    strategischeEmpfehlung: d["strategische_empfehlung"] as? String ?? "",
                    gegenmassnahmen: massnahmen
                )
            }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct TabAktion: View {
    let viewModel: CaseDetailViewModel
    @State private var zeigeNeueAufgabe = false
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Aktionsplan & Aufgaben")
                    .font(.title2.bold())
                Spacer()
                Button { zeigeNeueAufgabe = true } label: {
                    Label("Aufgabe", systemImage: "plus")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Anstehende Fristen (\(viewModel.fristen.filter { $0.status == .offen }.count))")
                    .font(.system(size: 13, weight: .semibold))
                ForEach(viewModel.fristen.filter { $0.status == .offen }.sorted { $0.due_date < $1.due_date }) { frist in
                    FristAktionsZeile(frist: frist)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("Aufgaben (\(viewModel.aufgaben.count))")
                    .font(.system(size: 13, weight: .semibold))
                ForEach(viewModel.aufgaben) { aufgabe in
                    AufgabeZeile(aufgabe: aufgabe)
                }
                if viewModel.aufgaben.isEmpty {
                    PlatzhalterView(nachricht: "Keine Aufgaben für diesen Fall")
                }
            }
        }
        .sheet(isPresented: $zeigeNeueAufgabe) {
            NeueAufgabeSheet(caseId: viewModel.caseId) { neue in
                viewModel.aufgaben.append(neue)
            }
        }
    }
}
struct FristAktionsZeile: View {
    let frist: Deadline
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: frist.istKritisch ? "exclamationmark.circle.fill" : "clock")
                .foregroundStyle(frist.istKritisch ? .red : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(frist.title)
                    .font(.system(size: 13, weight: .medium))
                Text(frist.due_date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(frist.tageVerbleibend) Tage")
                .font(.caption.bold())
                .foregroundStyle(frist.istKritisch ? .red : .orange)
        }
        .padding(10)
        .background(frist.istKritisch ? Color.red.opacity(0.05) : Color.orange.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct AufgabeZeile: View {
    let aufgabe: CaseTask
    var body: some View {
        HStack {
            Image(systemName: aufgabe.status == .erledigt ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(aufgabe.status == .erledigt ? .green : .secondary)
            Text(aufgabe.title)
                .font(.system(size: 13))
                .strikethrough(aufgabe.status == .erledigt)
            Spacer()
            Text(aufgabe.priority.rawValue)
                .font(.caption2)
                .foregroundStyle(prioritaetFarbe(aufgabe.priority))
        }
        .padding(.vertical, 4)
    }
    private func prioritaetFarbe(_ p: CaseTask.Prioritaet) -> Color {
        switch p {
        case .niedrig: return .gray
        case .mittel: return .blue
        case .hoch: return .orange
        case .kritisch: return .red
        }
    }
}
struct TabCockpit: View {
    let viewModel: CaseDetailViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text("Fall-Cockpit")
                .font(.title2.bold())
            if let vollanalyse = viewModel.vollanalyse {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    DashboardCard(titel: "Prognose", symbol: "chart.line.uptrend.xyaxis") {
                        Text("\(vollanalyse.prognose.score)%")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(vollanalyse.prognose.score >= 65 ? .green : vollanalyse.prognose.score >= 45 ? .orange : .red)
                        Text("90%-CI: [\(vollanalyse.prognose.ciLow)%, \(vollanalyse.prognose.ciHigh)%]")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    DashboardCard(titel: "Gesamtrisiko", symbol: "exclamationmark.triangle") {
                        Text(vollanalyse.risikofaktoren.gesamtrisiko.capitalized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(vollanalyse.risikofaktoren.gesamtrisiko == "niedrig" ? .green : vollanalyse.risikofaktoren.gesamtrisiko == "mittel" ? .orange : .red)
                        Text("Score: \(String(format: "%.1f", vollanalyse.risikofaktoren.gesamtScore))/10")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    DashboardCard(titel: "Monte-Carlo Median", symbol: "function") {
                        Text("\(vollanalyse.monteCarlo.median)%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("P10: \(vollanalyse.monteCarlo.p10)% / P90: \(vollanalyse.monteCarlo.p90)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    DashboardCard(titel: "Break-Even", symbol: "eurosign.circle") {
                        if let be = vollanalyse.breakEven.breakEvenPct {
                            Text("\(be)%")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(be > 60 ? .red : be > 40 ? .orange : .green)
                            Text("Mindest-Erfolgschance")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                InfoHinweis(
                    titel: "Cockpit leer",
                    nachricht: "Starten Sie zuerst die KI-Analyse über den Button oben rechts.",
                    symbol: "gauge"
                )
            }
            Divider().padding(.vertical, 8)
            if let fall = viewModel.fall {
                CaseAIPerformanceSection(caseId: viewModel.caseId, fallname: fall.fallname)
            }
            TabHistoryView(caseId: viewModel.caseId)
        }
    }
}
struct TabKIProtokoll: View {
    let viewModel: CaseDetailViewModel
    @State private var logs: [KIUsageLog] = []
    @State private var laden = true
    @State private var filter = "alle"
    @State private var aufgeklappt: Set<String> = []
    private var kiNamen: [String] {
        ["alle"] + Array(Set(logs.map { $0.anzeigeFunktion })).sorted()
    }
    private var gefiltert: [KIUsageLog] {
        filter == "alle" ? logs : logs.filter { $0.anzeigeFunktion == filter }
    }
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("KI-Transparenz-Protokoll")
                    .font(.title2.bold())
                Spacer()
                Button { Task { await neuLaden() } } label: {
                    Label("Aktualisieren", systemImage: "arrow.clockwise")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .controlSize(.small)
            }
            if !logs.isEmpty {
                Picker("Filter", selection: $filter) {
                    ForEach(kiNamen, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
            }
            if laden {
                ProgressView("Protokoll wird geladen…")
            } else if gefiltert.isEmpty {
                InfoHinweis(
                    titel: "Noch keine KI-Nutzungen protokolliert",
                    nachricht: "Jede KI-Analyse wird hier mit Eingabe, Antwort und Modell gespeichert — wie im Original TabKIProtokoll.",
                    symbol: "brain"
                )
            } else {
                ForEach(gefiltert.filter { $0.id != nil }, id: \.id!) { log in
                    kiLogKarte(log)
                }
            }
            if let vollanalyse = viewModel.vollanalyse {
                Divider()
                BerechnungsTransparenzView(schritte: vollanalyse.prognose.schritte)
            }
        }
        .task { await neuLaden() }
    }
    @ViewBuilder
    private func kiLogKarte(_ log: KIUsageLog) -> some View {
        let logId = log.id ?? UUID().uuidString
        let isOpen = aufgeklappt.contains(logId)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if isOpen { aufgeklappt.remove(logId) } else { aufgeklappt.insert(logId) }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.anzeigeFunktion).font(.caption.bold()).foregroundStyle(.purple)
                        if let summary = log.input_summary {
                            Text(summary).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                        }
                        if let model = log.model ?? log.modell, model != "standard" {
                            Text(model).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    FenlynineOSTransparenzInfoButton(inhalt: .kiLog(log))
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down").font(.caption2)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            if isOpen {
                VStack(alignment: .leading, spacing: 8) {
                    if let summary = log.input_summary {
                        Text("Eingabe").font(.caption2.bold()).foregroundStyle(.secondary)
                        Text(summary).font(.caption).textSelection(.enabled)
                    }
                    if let output = log.output {
                        Text("KI-Antwort").font(.caption2.bold()).foregroundStyle(.secondary)
                        Text(output).font(.caption).textSelection(.enabled).lineLimit(40)
                    }
                }
                .padding([.horizontal, .bottom], 12)
                .background(Color.gray.opacity(0.04))
            }
        }
        .background(Color.purple.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.1)))
    }
    private func neuLaden() async {
        laden = true
        defer { laden = false }
        logs = (try? await Services.kiUsageLogs.filter(["case_id": viewModel.caseId], sort: "-created_at", limit: 200)) ?? []
    }
}
struct PersonKarte: View {
    let person: Person
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: person.role.symbol)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.system(size: 13, weight: .semibold))
                Text(person.role.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let klaegerRate = person.klaeger_rate {
                VStack(spacing: 1) {
                    Text("\(Int(klaegerRate))%")
                        .font(.system(size: 13, weight: .bold))
                    Text("Klägerquote")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12), lineWidth: 1))
    }
}
struct KIProfilKarte: View {
    let titel: String
    let inhalt: String
    var transparenz: TransparenzInhalt? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(titel, systemImage: "brain.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.purple)
                Spacer()
                FenlynineOSTransparenzInfoButton(inhalt: transparenz ?? .kiModul(
                    titel: titel,
                    begruendung: "KI-generierte Analyse.",
                    ausgabe: inhalt
                ))
            }
            Text(inhalt)
                .font(.system(size: 12))
                .textSelection(.enabled)
        }
        .padding(14)
        .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.12), lineWidth: 1))
    }
}
struct InfoHinweis: View {
    let titel: String
    let nachricht: String
    let symbol: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(titel)
                    .font(.system(size: 13, weight: .semibold))
                Text(nachricht)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.1), lineWidth: 1))
    }
}
struct RechtsluckeKarte: View {
    let lucke: LegalLoophole
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(lucke.title)
                    .font(.system(size: 12, weight: .semibold))
                Text(lucke.beschreibung)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text("Nutzbarkeit: \(lucke.nutzbarkeit)/10")
                .font(.caption2.bold())
                .foregroundStyle(.green)
        }
        .padding(10)
        .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct NeueAufgabeSheet: View {
    let caseId: String
    let onCreated: (CaseTask) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var priority = CaseTask.Prioritaet.mittel
    @State private var isSaving = false
    @State private var speichernFehler: String?
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Neue Aufgabe", systemImage: "plus.circle")
                    .font(.title3.bold())
                Spacer()
                Button("Abbrechen") { dismiss() }
            }
            .padding(20)
            Divider()
            Form {
                TextField("Titel *", text: $title)
                Picker("Priorität", selection: $priority) {
                    ForEach(CaseTask.Prioritaet.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                if let err = speichernFehler {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Erstellen") {
                    Task { await speichern() }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(title.isEmpty || isSaving)
            }
            .padding(16)
        }
        .frame(width: 360, height: 280)
    }
    private func speichern() async {
        isSaving = true
        speichernFehler = nil
        var aufgabe = CaseTask(case_id: caseId, title: title)
        aufgabe.priority = priority
        do {
            let created = try await Services.tasks.create(aufgabe)
            await MainActor.run { onCreated(created); dismiss() }
        } catch {
            await MainActor.run { speichernFehler = error.localizedDescription }
        }
        isSaving = false
    }
}
private func formatEuro(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "EUR"
    formatter.locale = Locale(identifier: "de_DE")
    return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
}
