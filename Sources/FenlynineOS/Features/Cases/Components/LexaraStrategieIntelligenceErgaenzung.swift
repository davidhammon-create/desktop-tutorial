import SwiftUI
import Charts
struct LexaraStrategieIntelligenceHubView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var segment = 0
    private let segmente = ["Psychologie", "Prognosen", "Handlung", "Verfahrenstaktik", "Erfolgsaussichten"]
    var body: some View {
        VStack(spacing: 16) {
            kopfzeile
            Picker("", selection: $segment) {
                ForEach(segmente.indices, id: \.self) { i in
                    Text(segmente[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            switch segment {
            case 0: LexaraPsychologieErgaenzungPanel(viewModel: viewModel, kiMode: kiMode)
            case 1: LexaraPrognoseWahrscheinlichkeitenPanel(viewModel: viewModel, kiMode: kiMode)
            case 2: LexaraHandlungsvorschlaegePanel(viewModel: viewModel, kiMode: kiMode)
            case 3: LexaraVerfahrenstaktikPanel(viewModel: viewModel, kiMode: kiMode)
            default:
                VStack(spacing: 14) {
                    LexaraErfolgsaussichtenZusatzPanel(viewModel: viewModel)
                    LexaraStrategieTaktikZusatzPanel(viewModel: viewModel)
                    LexaraPersonenKIZusatzPanel(viewModel: viewModel, kiMode: kiMode)
                }
            }
        }
    }
    private var kopfzeile: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Label("KI-Strategiezentrum", systemImage: "brain.head.profile")
                    .font(.title2.bold())
                Text("Psychologische Analyse, Prognosen, Handlungsvorschläge und Verfahrenstaktik — aggregiert aus allen Lexara-KI-Modulen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            let fortschritt = KIResultStore.moduleFortschritt(fall: viewModel.fall)
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(fortschritt.erledigt)/\(fortschritt.gesamt) Module")
                    .font(.caption.weight(.semibold))
                ProgressView(value: Double(fortschritt.erledigt), total: Double(max(fortschritt.gesamt, 1)))
                    .frame(width: 100)
            }
        }
    }
}
struct LexaraGegnerPsychologieErgaenzungView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Psychologische Gegneranalyse")
                        .font(.title2.bold())
                    Text("Big Five, Dark Triad, Verhandlungsprofil und taktische Hebelpunkte")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            LexaraPsychologieErgaenzungPanel(viewModel: viewModel, kiMode: kiMode, fokusGegner: true)
        }
    }
}
struct LexaraPsychologieErgaenzungPanel: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    var fokusGegner: Bool = false
    @State private var laeuft = false
    @State private var fehler: String?
    private var berater: [String: Any] { viewModel.fall?.ki_berater_result?.dictValue ?? [:] }
    private var gegner: [String: Any] { viewModel.fall?.gegner_profil?.dictValue ?? [:] }
    private var psychoBerater: [String: Any]? { berater["psychologisches_profil"] as? [String: Any] }
    private var psychoSim: [String: Any]? {
        (gegner["simulation"] as? [String: Any])?["psycho_profil"] as? [String: Any]
            ?? gegner["psycho_profil"] as? [String: Any]
    }
    var body: some View {
        VStack(spacing: 14) {
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            }
            if kiMode {
                HStack {
                    Spacer()
                    Button {
                        Task { await psychoAnalyseStarten() }
                    } label: {
                        if laeuft {
                            ProgressView().scaleEffect(0.7)
                            Text("Analysiere…")
                        } else {
                            Label("KI-Psychoanalyse", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    .disabled(laeuft)
                }
            }
            if psychoBerater != nil || psychoSim != nil {
                if let bf = psychoBerater?["big_five"] as? [String: Any], !bf.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Big Five — Gegnerprofil", symbol: "person.crop.circle") {
                        LexaraTraitBalkenDiagramm(traits: bf, maxWert: 10, accent: .blue)
                    }
                }
                if let dt = psychoBerater?["dark_triad"] as? [String: Any], !dt.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Dark Triad", symbol: "eye.trianglebadge.exclamationmark") {
                        LexaraTraitBalkenDiagramm(traits: dt, maxWert: 10, accent: .red)
                    }
                }
                if let sim = psychoSim {
                    LexaraIntelligenceErgaenzungKarte(titel: "Verhandlungs- & Risikoprofil", symbol: "figure.mind.and.body") {
                        LexaraSchluesselWertGrid(zeilen: [
                            ("Motivation", sim["motivation"] as? String),
                            ("Risikobereitschaft", sim["risikobereitschaft"] as? String),
                            ("Verhandlungstyp", sim["verhandlungstyp"] as? String ?? sim["verhandlungsstil"] as? String),
                            ("Dominanz", sim["dominanz"] as? String),
                            ("Risikoaversion", sim["risikoaversion"] as? String)
                        ])
                        if let schw = sim["schwaechen"] as? [String], !schw.isEmpty {
                            Text("Schwächen").font(.caption.bold()).padding(.top, 6)
                            LexaraChipZeile(items: schw, accent: .orange)
                        }
                        if let hebel = sim["hebelpunkte"] as? [String], !hebel.isEmpty {
                            Text("Hebelpunkte").font(.caption.bold()).padding(.top, 6)
                            LexaraChipZeile(items: hebel, accent: .green)
                        }
                    }
                }
                if let trigger = psychoBerater?["trigger"] as? String, !trigger.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Psychologischer Trigger", symbol: "bolt.heart") {
                        Text(trigger).font(.caption)
                    }
                }
                if let emp = psychoBerater?["empfehlung"] as? String, !emp.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Taktische Psycho-Empfehlung", symbol: "lightbulb.fill") {
                        Text(emp).font(.caption).italic()
                    }
                }
            } else {
                LexaraIntelligenceLeerHinweis(
                    titel: "Noch keine Psychoanalyse",
                    text: "Starten Sie die KI-Psychoanalyse oder den KI-Berater im Tab „KI-Berater“, um Big Five, Dark Triad und Verhandlungsprofile zu befüllen."
                )
            }
        }
    }
    private func psychoAnalyseStarten() async {
        guard var fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let prompt = """
        Du bist Prozesspsychologe und Verhandlungsstratege. Analysiere die Gegenseite für einen deutschen Rechtsstreit.
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "—")
        Streitwert: \(fall.streitwert.map { "\(Int($0)) €" } ?? "—")
        Gegner-Kontext: \(String(describing: gegner.prefix(8)))
        Liefere Big Five (0-10), Dark Triad (0-10), Trigger, taktische Empfehlung.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "psychologisches_profil": [
                    "type": "object",
                    "properties": [
                        "big_five": ["type": "object"],
                        "dark_triad": ["type": "object"],
                        "trigger": ["type": "string"],
                        "empfehlung": ["type": "string"]
                    ]
                ]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6"
            )
            guard let dict = response.dictValue,
                  let psycho = dict["psychologisches_profil"] as? [String: Any] else {
                fehler = KIResultStore.parseFehler
                return
            }
            let saved = try await KIResultStore.mergeBeraterSubKey(
                caseId: viewModel.caseId, fall: &fall, key: "psychologisches_profil", value: psycho
            )
            await MainActor.run { viewModel.fall = saved }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct LexaraPrognoseWahrscheinlichkeitenPanel: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var laeuft = false
    @State private var fehler: String?
    private var berater: [String: Any] { viewModel.fall?.ki_berater_result?.dictValue ?? [:] }
    var body: some View {
        VStack(spacing: 14) {
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            }
            prognoseHauptRing
            if let vergleich = berater["prognose_vergleich"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Prognose-Modellvergleich", symbol: "chart.bar.xaxis") {
                    if let modelle = vergleich["modelle"] as? [[String: Any]], !modelle.isEmpty {
                        Chart(modelle.indices, id: \.self) { i in
                            let m = modelle[i]
                            let name = m["name"] as? String ?? "?"
                            BarMark(
                                x: .value("Modell", name),
                                y: .value("%", KIJson.intValue(m["wert"]) ?? 0)
                            )
                            .foregroundStyle(by: .value("Modell", name))
                            .annotation(position: .top) {
                                Text("\(KIJson.intValue(m["wert"]) ?? 0)%").font(.caption2)
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .frame(height: 160)
                        ForEach(Array(modelle.enumerated()), id: \.offset) { _, m in
                            if let b = KIJson.string(in: m, keys: "begruendung", "beguendung") {
                                Text("• \(m["name"] as? String ?? ""): \(b)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let emp = vergleich["empfehlung"] as? String {
                        Text(emp).font(.caption).padding(.top, 6)
                    }
                    if let verlaesslich = vergleich["verlasslichste_prognose"] as? String {
                        Label("Verlässlichste: \(verlaesslich)", systemImage: "checkmark.seal")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }
            if let gesamt = berater["gesamtbewertung"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Gesamtbewertung — Erfolgswahrscheinlichkeit", symbol: "percent") {
                    let pct = KIJson.intValue(gesamt["erfolgswahrscheinlichkeit"]) ?? Int(viewModel.fall?.prognose ?? 50)
                    HStack(alignment: .center, spacing: 16) {
                        FenlynineOSPrognoseRing(wert: pct, groesse: 72)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(pct)% Erfolgsaussicht").font(.headline)
                            if let b = KIJson.string(in: gesamt, keys: "erfolgswahrscheinlichkeit_begruendung", "erfolgswahrscheinlichkeit_beguendung") {
                                Text(b).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let strat = gesamt["gesamtstrategie"] as? String {
                        Divider().padding(.vertical, 4)
                        Text(strat).font(.caption)
                    }
                }
            }
            if let strategien = berater["strategien"] as? [[String: Any]], !strategien.isEmpty {
                LexaraIntelligenceErgaenzungKarte(titel: "Strategie-Szenarien & Wahrscheinlichkeiten", symbol: "arrow.triangle.branch") {
                    Chart(strategien.indices, id: \.self) { i in
                        let s = strategien[i]
                        BarMark(
                            x: .value("Erfolg", KIJson.intValue(s["erfolg_pct"]) ?? 0),
                            y: .value("Strategie", s["name"] as? String ?? "—")
                        )
                        .foregroundStyle(farbeFuerRisiko(s["risiko"] as? String))
                    }
                    .chartXScale(domain: 0...100)
                    .frame(height: CGFloat(strategien.count * 36 + 20))
                    ForEach(Array(strategien.enumerated()), id: \.offset) { _, s in
                        HStack(alignment: .top) {
                            Text(s["name"] as? String ?? "").font(.caption.bold()).frame(width: 140, alignment: .leading)
                            Text(s["beschreibung"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(KIJson.intValue(s["erfolg_pct"]) ?? 0)%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            if berater["prognose_vergleich"] == nil && berater["gesamtbewertung"] == nil {
                LexaraIntelligenceLeerHinweis(
                    titel: "Prognosedaten laden",
                    text: "Nutzen Sie „Gesamtbewertung“, „Prognose-Vergleich“ oder „Monte Carlo“ in den bestehenden Strategie-Tabs — die Ergebnisse erscheinen hier automatisch."
                )
                if kiMode {
                    Button { Task { await prognoseVergleichGenerieren() } } label: {
                        if laeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("KI-Prognosevergleich erzeugen", systemImage: "wand.and.stars") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .disabled(laeuft)
                }
            }
        }
    }
    @ViewBuilder
    private var prognoseHauptRing: some View {
        let algoScore = viewModel.vollanalyse.map { Double($0.prognose.score) }
        let pct = Int(viewModel.fall?.prognose ?? algoScore ?? 50)
        FenlynineOSCard(elevated: false) {
            HStack(spacing: 20) {
                FenlynineOSPrognoseRing(wert: pct, groesse: 88)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aktuelle Fallprognose").font(.subheadline.bold())
                    Text("Algorithmus + gespeicherte KI-Module").font(.caption).foregroundStyle(.secondary)
                    if let algo = viewModel.vollanalyse {
                        Text("Vollanalyse-Score: \(algo.prognose.score)%").font(.caption2)
                    }
                }
                Spacer()
            }
        }
    }
    private func prognoseVergleichGenerieren() async {
        guard var fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let prompt = """
        Vergleiche Prognosemodelle für den Fall „\(fall.fallname)“ (Rechtsgebiet: \(fall.rechtsgebiet ?? "—")).
        Liefere modelle (name, wert 0-100, begruendung), verlasslichste_prognose, empfehlung, abweichungs_erklaerung.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "prognose_vergleich": [
                    "type": "object",
                    "properties": [
                        "modelle": ["type": "array", "items": ["type": "object"]],
                        "verlasslichste_prognose": ["type": "string"],
                        "empfehlung": ["type": "string"],
                        "abweichungs_erklaerung": ["type": "string"]
                    ]
                ]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
            guard let pv = response.dictValue?["prognose_vergleich"] else {
                fehler = KIResultStore.parseFehler
                return
            }
            let saved = try await KIResultStore.mergeBeraterSubKey(
                caseId: viewModel.caseId, fall: &fall, key: "prognose_vergleich", value: pv
            )
            await MainActor.run { viewModel.fall = saved }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func farbeFuerRisiko(_ risiko: String?) -> Color {
        switch risiko?.lowercased() {
        case "niedrig": return .green
        case "hoch": return .red
        default: return .orange
        }
    }
}
struct LexaraHandlungsvorschlaegePanel: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var laeuft = false
    @State private var fehler: String?
    private var berater: [String: Any] { viewModel.fall?.ki_berater_result?.dictValue ?? [:] }
    private var gegner: [String: Any] { viewModel.fall?.gegner_profil?.dictValue ?? [:] }
    private var dashboard: [String: Any]? { gegner["strategie_dashboard"] as? [String: Any] }
    var body: some View {
        VStack(spacing: 14) {
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            }
            if let moves = dashboard?["counter_moves"] as? [[String: Any]], !moves.isEmpty {
                LexaraIntelligenceErgaenzungKarte(titel: "Konter & Handlungsoptionen", symbol: "shield.lefthalf.filled") {
                    ForEach(Array(moves.enumerated()), id: \.offset) { _, m in
                        LexaraHandlungsKarte(
                            titel: m["titel"] as? String ?? "—",
                            typ: m["typ"] as? String,
                            beschreibung: m["beschreibung"] as? String,
                            timing: m["timing"] as? String,
                            erfolg: KIJson.intValue(m["erfolgsaussicht"]),
                            meta: m["gegner_arg"] as? String ?? m["unsere_strategie"] as? String
                        )
                    }
                }
            }
            if let druck = berater["druckmittel"] as? [[String: Any]], !druck.isEmpty {
                LexaraIntelligenceErgaenzungKarte(titel: "Druckmittel & Hebel", symbol: "bolt.fill") {
                    ForEach(Array(druck.enumerated()), id: \.offset) { _, d in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d["titel"] as? String ?? "").font(.caption.bold())
                                Text(d["wie_nutzen"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let s = KIJson.intValue(d["staerke"]) {
                                Text("Stärke \(s)/10").font(.caption2.bold()).foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            if let timing = berater["timing"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Timing & nächste Schritte", symbol: "clock.arrow.circlepath") {
                    LexaraSchluesselWertGrid(zeilen: [
                        ("Nächster Schritt", timing["naechster_schritt"] as? String),
                        ("Fenster", timing["fenster"] as? String),
                        ("Empfehlung", timing["empfehlung"] as? String),
                        ("Momentum", timing["momentum"] as? String)
                    ])
                }
            }
            if let sim = gegner["simulation"] as? [String: Any],
               let top = sim["top_strategie"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Top-Strategie (Simulation)", symbol: "star.fill") {
                    Text(top["name"] as? String ?? top["beschreibung"] as? String ?? "—").font(.caption.bold())
                    if let desc = top["beschreibung"] as? String { Text(desc).font(.caption2) }
                    if let q = KIJson.intValue(top["erfolgsquote"]) {
                        Text("Erfolgsquote: \(q)%").font(.caption).foregroundStyle(.green)
                    }
                    if let massnahmen = top["massnahmen"] as? [String] {
                        LexaraChipZeile(items: massnahmen, accent: .blue)
                    }
                }
            }
            if let zuege = (gegner["simulation"] as? [String: Any])?["naechste_zuege"] as? [[String: Any]], !zuege.isEmpty {
                LexaraIntelligenceErgaenzungKarte(titel: "Erwartete Gegnerzüge", symbol: "figure.fencing") {
                    ForEach(Array(zuege.enumerated()), id: \.offset) { _, z in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(z["zug"] as? String ?? "").font(.caption.bold())
                                Text("Verteidigung: \(z["verteidigung"] as? String ?? "—")").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(KIJson.intValue(z["wahrscheinlichkeit"]) ?? 0)%").font(.caption.bold())
                                Text(z["dringlichkeit"] as? String ?? "").font(.caption2).foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            if dashboard == nil && berater["druckmittel"] == nil {
                LexaraIntelligenceLeerHinweis(
                    titel: "Handlungsvorschläge",
                    text: "Starten Sie KI-Berater, Gegner-Simulation oder das Strategie-Dashboard — Konter, Druckmittel und Timing erscheinen hier."
                )
                if kiMode {
                    Button { Task { await handlungsvorschlaegeGenerieren() } } label: {
                        if laeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("KI-Handlungsplan erzeugen", systemImage: "wand.and.stars") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .disabled(laeuft)
                }
            }
        }
    }
    private func handlungsvorschlaegeGenerieren() async {
        guard var fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let prompt = """
        Erstelle Handlungsvorschläge für den Rechtsstreit „\(fall.fallname)“:
        druckmittel (titel, staerke 1-10, wie_nutzen), timing (naechster_schritt, fenster, empfehlung).
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "druckmittel": ["type": "array", "items": ["type": "object"]],
                "timing": ["type": "object"]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
            guard let dict = response.dictValue else { fehler = KIResultStore.parseFehler; return }
            if let d = dict["druckmittel"] {
                _ = try await KIResultStore.mergeBeraterSubKey(caseId: viewModel.caseId, fall: &fall, key: "druckmittel", value: d)
            }
            if let t = dict["timing"] {
                _ = try await KIResultStore.mergeBeraterSubKey(caseId: viewModel.caseId, fall: &fall, key: "timing", value: t)
            }
            let refreshed = try await Services.cases.get(id: viewModel.caseId)
            await MainActor.run { viewModel.fall = refreshed }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct LexaraVerfahrenstaktikPanel: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var laeuft = false
    @State private var fehler: String?
    private var berater: [String: Any] { viewModel.fall?.ki_berater_result?.dictValue ?? [:] }
    var body: some View {
        VStack(spacing: 14) {
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            }
            if let lmc = berater["last_minute_check"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Last-Minute-Check (Verhandlung/Termin)", symbol: "exclamationmark.triangle.fill") {
                    if let gefahren = lmc["gefahren"] as? [[String: Any]] {
                        ForEach(Array(gefahren.enumerated()), id: \.offset) { _, g in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Angriff: \(g["angriff"] as? String ?? "")").font(.caption.bold()).foregroundStyle(.red)
                                Text("Konter: \(g["konter"] as? String ?? "")").font(.caption2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    if let verbote = lmc["verbote"] as? [String] {
                        Text("Verbote").font(.caption.bold()).padding(.top, 4)
                        ForEach(verbote, id: \.self) { Text("⛔ \($0)").font(.caption2).foregroundStyle(.red) }
                    }
                    if let mot = lmc["motiviation"] as? String ?? lmc["motivation"] as? String {
                        Text(mot).font(.caption).italic().padding(.top, 4)
                    }
                }
            }
            if let info = berater["informationsstrategie"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Informationsstrategie", symbol: "eye.slash") {
                    infoSpalte("Sofort offenlegen", info["sofort_offenlegen"] as? [String], .green)
                    infoSpalte("Verbergen", info["verbergen"] as? [String], .red)
                    infoSpalte("Als Bluff", info["als_bluff"] as? [String], .orange)
                }
            }
            if let skript = berater["verhandlungsskript"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Verhandlungsskript", symbol: "text.bubble") {
                    ForEach([("Eröffnung", "eroeffnung"), ("Opening", "opening"), ("Argumentation", "argumentation"), ("Schlussphase", "schlussphase"), ("Closing", "closing")], id: \.1) { label, key in
                        if let t = skript[key] as? String, !t.isEmpty {
                            Text(label).font(.caption.bold())
                            Text(t).font(.caption2)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            if let www = berater["was_waere_wenn"] as? [String: Any] {
                LexaraIntelligenceErgaenzungKarte(titel: "Was-wäre-wenn — Motive & Prozess", symbol: "arrow.triangle.branch") {
                    if let ki = www["ki_analyse_text"] as? String { Text(ki).font(.caption) }
                    if let mot = www["motive_text"] as? String {
                        Divider().padding(.vertical, 4)
                        Text(mot).font(.caption2).foregroundStyle(.secondary)
                    }
                    if let pn = www["prozessnotiz_zusammenfassung"] as? String {
                        Text(pn).font(.caption2).padding(.top, 4)
                    }
                }
            }
            if berater["last_minute_check"] == nil && berater["informationsstrategie"] == nil {
                LexaraIntelligenceLeerHinweis(
                    titel: "Verfahrenstaktik",
                    text: "Nutzen Sie „Was-wäre-wenn“, KI-Berater oder Last-Minute-Check in den Strategie-Tabs."
                )
                if kiMode {
                    Button { Task { await lastMinuteGenerieren() } } label: {
                        if laeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("Last-Minute-Check erzeugen", systemImage: "wand.and.stars") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .disabled(laeuft)
                }
            }
        }
    }
    @ViewBuilder
    private func infoSpalte(_ titel: String, _ items: [String]?, _ farbe: Color) -> some View {
        if let items, !items.isEmpty {
            Text(titel).font(.caption2.bold()).foregroundStyle(farbe)
            ForEach(items, id: \.self) { Text("• \($0)").font(.caption2) }
        }
    }
    private func lastMinuteGenerieren() async {
        guard var fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let prompt = """
        Last-Minute-Check vor Verhandlung/Termin im Fall „\(fall.fallname)“:
        gefahren (angriff, konter), verbote, motivation.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "last_minute_check": [
                    "type": "object",
                    "properties": [
                        "gefahren": ["type": "array", "items": ["type": "object"]],
                        "verbote": ["type": "array", "items": ["type": "string"]],
                        "motivation": ["type": "string"]
                    ]
                ]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
            guard let lmc = response.dictValue?["last_minute_check"] else {
                fehler = KIResultStore.parseFehler
                return
            }
            let saved = try await KIResultStore.mergeBeraterSubKey(
                caseId: viewModel.caseId, fall: &fall, key: "last_minute_check", value: lmc
            )
            await MainActor.run { viewModel.fall = saved }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct LexaraIntelligenceErgaenzungKarte<Content: View>: View {
    let titel: String
    let symbol: String
    @ViewBuilder let content: Content
    var body: some View {
        FenlynineOSCard(elevated: false) {
            VStack(alignment: .leading, spacing: 10) {
                Label(titel, systemImage: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                content
            }
        }
    }
}
struct LexaraIntelligenceLeerHinweis: View {
    let titel: String
    let text: String
    var body: some View {
        FenlynineOSCard(elevated: false) {
            VStack(alignment: .leading, spacing: 8) {
                Text(titel).font(.subheadline.bold())
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
struct LexaraTraitBalkenDiagramm: View {
    let traits: [String: Any]
    var maxWert: Double = 10
    var accent: Color = .blue
    var body: some View {
        VStack(spacing: 6) {
            ForEach(traits.keys.sorted(), id: \.self) { key in
                if let v = KIJson.numberValue(traits[key]) {
                    HStack(spacing: 8) {
                        Text(key)
                            .font(.caption2)
                            .frame(width: 110, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.08))
                                Capsule()
                                    .fill(accent.opacity(0.75))
                                    .frame(width: geo.size.width * CGFloat(min(v / maxWert, 1)))
                            }
                        }
                        .frame(height: 8)
                        Text("\(Int(v.rounded()))")
                            .font(.caption2.monospacedDigit())
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
    }
}
struct LexaraSchluesselWertGrid: View {
    let zeilen: [(String, String?)]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(zeilen.filter { $0.1 != nil && !($0.1?.isEmpty ?? true) }, id: \.0) { label, wert in
                HStack(alignment: .top) {
                    Text("\(label):").font(.caption2).foregroundStyle(.secondary).frame(width: 120, alignment: .leading)
                    Text(wert ?? "").font(.caption)
                }
            }
        }
    }
}
struct LexaraChipZeile: View {
    let items: [String]
    var accent: Color = .blue
    var body: some View {
        FlowLayoutErgaenzung(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(accent.opacity(0.3), lineWidth: 1))
            }
        }
    }
}
struct LexaraHandlungsKarte: View {
    let titel: String
    let typ: String?
    let beschreibung: String?
    let timing: String?
    let erfolg: Int?
    let meta: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titel).font(.caption.bold())
                if let typ {
                    Text(typ.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                }
                Spacer()
                if let erfolg {
                    Text("\(erfolg)%").font(.caption.bold()).foregroundStyle(.green)
                }
            }
            if let beschreibung { Text(beschreibung).font(.caption2).foregroundStyle(.secondary) }
            if let meta { Text(meta).font(.caption2).italic() }
            if let timing {
                Label(timing, systemImage: "clock").font(.caption2).foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }
}
private struct FlowLayoutErgaenzung: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let r = arrange(proposal: proposal, subviews: subviews)
        return r.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = arrange(proposal: proposal, subviews: subviews)
        for (i, pos) in r.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        var positions: [CGPoint] = []
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
        return (CGSize(width: maxW, height: y + rowH), positions)
    }
}
