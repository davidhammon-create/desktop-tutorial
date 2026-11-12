import SwiftUI
import Charts
import AppKit
struct TabStrategiePrognose: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach([
                        (0, "Strategie & Prognose"),
                        (1, "Was-wäre-wenn"),
                        (2, "Monte Carlo"),
                        (3, "KI-Risikomatrix"),
                        (4, "KI-Strategiezentrum")
                    ], id: \.0) { tag, label in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { subTab = tag }
                        } label: {
                            Text(label)
                                .font(.system(size: 12, weight: subTab == tag ? .semibold : .regular))
                                .foregroundStyle(subTab == tag ? .primary : .secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .overlay(alignment: .bottom) {
                                    if subTab == tag {
                                        Rectangle().fill(Color.primary).frame(height: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Divider()
                .padding(.bottom, 16)
            switch subTab {
            case 0: TabStrategie(viewModel: viewModel, kiMode: kiMode)
            case 1: WasWaereWennView(viewModel: viewModel, kiMode: kiMode)
            case 2: TabSimulation(viewModel: viewModel, kiMode: kiMode)
            case 3: KIRisikoMatrixView(viewModel: viewModel, kiMode: kiMode)
            default: LexaraStrategieIntelligenceHubView(viewModel: viewModel, kiMode: kiMode)
            }
        }
    }
}
struct WasWaereWennView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    struct Szenario: Identifiable {
        let id = UUID()
        var name: String
        var prognoseOffset: Double   // z.B. +10 oder -20
        var kosten: Double
        var risiko: String           // "niedrig" | "mittel" | "hoch"
        var beschreibung: String
    }
    @State private var szenarien: [Szenario] = [
        Szenario(name: "Optimistisch", prognoseOffset: +15, kosten: 5_000, risiko: "niedrig",
                 beschreibung: "Alle Argumente greifen, Richter kooperativ, Gegner schwach vertreten."),
        Szenario(name: "Realistisch", prognoseOffset: 0, kosten: 12_000, risiko: "mittel",
                 beschreibung: "Normaler Verlauf entsprechend aktueller Datenlage."),
        Szenario(name: "Pessimistisch", prognoseOffset: -25, kosten: 20_000, risiko: "hoch",
                 beschreibung: "Gegner bringt neue Beweise, Fristen-Komplikationen, ungünstiger Richter."),
    ]
    @State private var kiAnalyse: String? = nil
    @State private var laeuft = false
    @State private var motiveAnalyse: String? = nil
    @State private var dossier: String? = nil
    @State private var motiveLaeuft = false
    @State private var dossierLaeuft = false
    @State private var exportLaeuft = false
    @State private var neuesSzenario = false
    @State private var neuerName = ""
    @State private var neuerOffset = 0.0
    @State private var neueKosten = 10_000.0
    @State private var wwFehler: String?
    private var basisPrognose: Double { viewModel.fall?.prognose ?? 50 }
    var body: some View {
        VStack(spacing: 20) {
            if let err = wwFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Label("Was-wäre-wenn Analyse", systemImage: "arrow.triangle.branch")
                    .font(.title2.bold())
                Spacer()
                Button {
                    Task { await kiSzenarienGenerieren() }
                } label: {
                    if laeuft { ProgressView().scaleEffect(0.7) }
                    else { Label("KI-Szenarien", systemImage: "wand.and.stars") }
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .disabled(laeuft || !kiMode)
                if kiMode {
                    Button { Task { await motiveAufdecken() } } label: {
                        if motiveLaeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("Motive aufdecken", systemImage: "eye.fill") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small).disabled(motiveLaeuft || !kiMode)
                    Button { Task { await verhandlungsDossier() } } label: {
                        if dossierLaeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("Verhandlungs-Dossier", systemImage: "doc.text.fill") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small).disabled(dossierLaeuft || !kiMode)
                    Button { Task { await prozessnotizPDF() } } label: {
                        if exportLaeuft { ProgressView().scaleEffect(0.7) }
                        else { Label(exportLaeuft ? "Erstelle PDF…" : "Prozessnotiz PDF", systemImage: "arrow.down.doc") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small).disabled(exportLaeuft || !kiMode)
                }
                Button {
                    withAnimation { neuesSzenario.toggle() }
                } label: {
                    Label("Szenario", systemImage: "plus")
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
            }
            HStack(spacing: 4) {
                Text("Basisprognose:").font(.caption).foregroundStyle(.secondary)
                Text("\(Int(basisPrognose))%").font(.caption.bold()).foregroundStyle(.blue)
            }
            if neuesSzenario {
                VStack(spacing: 10) {
                    TextField("Szenario-Name", text: $neuerName)
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prognose-Änderung: \(Int(neuerOffset))%").font(.caption2)
                            Slider(value: $neuerOffset, in: -50...50, step: 5)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kosten: \(formatEuroW(neueKosten))").font(.caption2)
                            Slider(value: $neueKosten, in: 0...100_000, step: 1_000)
                        }
                    }
                    HStack {
                        Spacer()
                        Button("Abbrechen") { neuesSzenario = false }.buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        Button("Hinzufügen") {
                            szenarien.append(Szenario(
                                name: neuerName.isEmpty ? "Szenario \(szenarien.count+1)" : neuerName,
                                prognoseOffset: neuerOffset, kosten: neueKosten,
                                risiko: neuerOffset >= 0 ? "niedrig" : "hoch",
                                beschreibung: "Benutzerdefiniertes Szenario"
                            ))
                            neuesSzenario = false
                        }.buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(szenarien) { s in
                    SzenarienKarte(szenario: s, basis: basisPrognose)
                }
            }
            if let analyse = kiAnalyse {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("KI-Szenarioanalyse", systemImage: "brain.head.profile")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.purple)
                        FenlynineOSTransparenzInfoButton(inhalt: .kiModul(
                            titel: "Was-wäre-wenn — KI-Szenarien",
                            begruendung: "KI-Bewertung der Szenario-Realität und Handlungsempfehlungen.",
                            ausgabe: analyse
                        ))
                    }
                    Text(analyse).font(.system(size: 12)).lineSpacing(4)
                }
                .padding(14)
                .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }
            if let m = motiveAnalyse {
                KIProfilKarte(
                    titel: "Motive & Timing-Analyse",
                    inhalt: m,
                    transparenz: .kiModul(titel: "Motive & Timing", begruendung: "KI-Analyse der Gegner-Timing-Strategie.", ausgabe: m)
                )
            }
            if let d = dossier {
                KIProfilKarte(
                    titel: "Verhandlungs-Dossier",
                    inhalt: d,
                    transparenz: .kiModul(titel: "Verhandlungs-Dossier", begruendung: "KI-generiertes Verhandlungs-Dossier.", ausgabe: d)
                )
            }
            if szenarien.count >= 2 {
                SzenarienChart(szenarien: szenarien, basis: basisPrognose)
            }
        }
        .onAppear { hydrateWasWaereWenn() }
    }
    private func hydrateWasWaereWenn() {
        guard let ww = viewModel.fall?.ki_berater_result?.dictValue?["was_waere_wenn"] as? [String: Any] else { return }
        if kiAnalyse == nil { kiAnalyse = ww["ki_analyse_text"] as? String }
        if motiveAnalyse == nil { motiveAnalyse = ww["motive_text"] as? String }
        if dossier == nil { dossier = ww["prozessnotiz_zusammenfassung"] as? String }
    }
    private func kiSzenarienGenerieren() async {
        guard kiMode, let fall = viewModel.fall else { return }
        laeuft = true
        wwFehler = nil
        defer { laeuft = false }
        let prompt = """
        Analysiere folgende Was-wäre-wenn-Szenarien für den Fall "\(fall.fallname)" (\(fall.rechtsgebiet ?? ""), \(fall.instanz.rawValue)):
        Basisprognose: \(Int(basisPrognose))%
        Bewerte für jedes Szenario: Wie realistisch ist es? Was sind die konkreten Trigger? Was sollte der Anwalt tun?
        Szenarien: Optimistisch (+15%), Realistisch (0%), Pessimistisch (-25%)
        Gib auch: Welches Szenario ist am wahrscheinlichsten? Was ist der kritischste Risikofaktor?
        """
        do {
            let result = try await LLMService.shared.invokeText(
                prompt: prompt,
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Was-wäre-wenn — Szenarien"
            )
            await MainActor.run { kiAnalyse = result }
            if var fallUpd = viewModel.fall {
                var ww = fallUpd.ki_berater_result?.dictValue?["was_waere_wenn"] as? [String: Any] ?? [:]
                ww["ki_analyse_text"] = result
                let saved = try await KIResultStore.mergeBeraterSubKey(
                    caseId: viewModel.caseId,
                    fall: &fallUpd,
                    key: "was_waere_wenn",
                    value: ww
                )
                await MainActor.run { viewModel.fall = saved }
            }
        } catch {
            await MainActor.run { wwFehler = error.localizedDescription }
        }
    }
    private func motiveAufdecken() async {
        guard kiMode, let fall = viewModel.fall else { return }
        motiveLaeuft = true
        wwFehler = nil
        defer { motiveLaeuft = false }
        let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }
        let eigenArgs = viewModel.argumente.filter { $0.side == .eigen }
        let gegnerFristen = viewModel.fristen.filter { $0.side.lowercased().contains("gegner") }
        let prompt = """
        Du bist ein erfahrener Prozessanwalt und Verhaltensstratege.
        Analysiere die TIMING-STRATEGIE der Gegenseite in diesem Rechtstreit.
        Fall: \(fall.fallname) | Rechtsgebiet: \(fall.rechtsgebiet ?? "")
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
        GEGNER-ARGUMENTE (\(gegnerArgs.count)):
        \(gegnerArgs.map { "- \"\($0.title)\" (Stärke: \($0.strength)/10): \($0.description ?? "")" }.joined(separator: "\n"))
        FRISTEN (\(gegnerFristen.count)):
        \(gegnerFristen.map { "- \"\($0.title)\" bis \($0.due_date.formatted(date: .abbreviated, time: .omitted))" }.joined(separator: "\n"))
        EIGENE ARGUMENTE (\(eigenArgs.count)):
        \(eigenArgs.map { "- \"\($0.title)\" (Stärke: \($0.strength)/10)" }.joined(separator: "\n"))
        Analysiere Timing, verdeckte Ziele, psychologische Taktiken, nächsten Schritt und empfohlene Reaktion.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "timing_analyse": ["type": "string"],
                    "fristen_hintergedanken": ["type": "string"],
                    "verdeckte_ziele": ["type": "array", "items": ["type": "string"]],
                    "psychologische_taktiken": ["type": "array", "items": ["type": "object", "properties": [
                        "taktik": ["type": "string"], "beweis": ["type": "string"], "intensitaet": ["type": "string"]
                    ]]],
                    "naechster_schritt_gegner": ["type": "string"],
                    "empfohlene_reaktion": ["type": "string"],
                    "rote_flaggen": ["type": "array", "items": ["type": "string"]]
                ]] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Was-wäre-wenn — Motive aufdecken"
            )
            let d = try KIJson.requireObject(result, kontext: "Motive")
            var text = ""
            if let t = d["timing_analyse"] as? String { text += "TIMING: \(t)\n\n" }
            if let f = d["fristen_hintergedanken"] as? String { text += "FRISTEN: \(f)\n\n" }
            if let z = d["verdeckte_ziele"] as? [String], !z.isEmpty { text += "Verdeckte Ziele: \(z.joined(separator: "; "))\n\n" }
            if let n = d["naechster_schritt_gegner"] as? String { text += "Nächster Schritt Gegner: \(n)\n\n" }
            if let r = d["empfohlene_reaktion"] as? String { text += "Empfohlene Reaktion: \(r)" }
            await MainActor.run { motiveAnalyse = text.trimmingCharacters(in: .whitespacesAndNewlines) }
            if var fallUpd = viewModel.fall {
                var ww = fallUpd.ki_berater_result?.dictValue?["was_waere_wenn"] as? [String: Any] ?? [:]
                ww["motive_text"] = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let saved = try await KIResultStore.mergeBeraterSubKey(
                    caseId: viewModel.caseId,
                    fall: &fallUpd,
                    key: "was_waere_wenn",
                    value: ww
                )
                await MainActor.run { viewModel.fall = saved }
            }
        } catch {
            await MainActor.run { wwFehler = error.localizedDescription }
        }
    }
    private func verhandlungsDossier() async {
        guard kiMode, let fall = viewModel.fall else { return }
        dossierLaeuft = true
        wwFehler = nil
        defer { dossierLaeuft = false }
        let eigen = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let prompt = """
        Du bist ein erfahrener Prozessanwalt. Erstelle ein kompaktes Verhandlungs-Dossier für die nächste Sitzung.
        Fall: \(fall.fallname) | Aktenzeichen: \(fall.aktenzeichen ?? "")
        Aktuelle Prognose: \(Int(basisPrognose))%
        STARKE EIGENE ARGUMENTE:
        \(eigen.filter { $0.strength >= 6 }.map { "- \"\($0.title)\" (\($0.strength)/10)" }.joined(separator: "\n"))
        GEGNER-ARGUMENTE:
        \(gegner.map { "- \"\($0.title)\" (\($0.strength)/10)" }.joined(separator: "\n"))
        Erstelle ein prägnantes Dossier für die nächste Verhandlung.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "staerkste_argumente": ["type": "array", "items": ["type": "object", "properties": [
                        "argument": ["type": "string"], "einsatz": ["type": "string"], "formulierung": ["type": "string"]
                    ]]],
                    "gegner_schwachstellen": ["type": "array", "items": ["type": "object", "properties": [
                        "schwachstelle": ["type": "string"], "angriffspunkt": ["type": "string"]
                    ]]],
                    "verhandlungsziele": ["type": "array", "items": ["type": "object", "properties": [
                        "ziel": ["type": "string"], "prioritaet": ["type": "string"], "taktik": ["type": "string"]
                    ]]],
                    "opening_statement": ["type": "string"],
                    "rote_linien": ["type": "array", "items": ["type": "string"]]
                ]] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Was-wäre-wenn — Verhandlungs-Dossier"
            )
            guard let d = try? KIJson.requireObject(result, kontext: "Was-wäre-wenn Verhandlungs-Dossier") else {
                await MainActor.run { wwFehler = KIResultStore.parseFehler }
                return
            }
            var text = ""
            if let o = d["opening_statement"] as? String { text += "ERÖFFNUNG:\n\(o)\n\n" }
            if let ziele = d["verhandlungsziele"] as? [[String: Any]] {
                text += "ZIELE:\n" + ziele.map { "- \($0["ziel"] as? String ?? "") (\(KIJson.string(in: $0, keys: "prioritaet", "priorität") ?? "")): \($0["taktik"] as? String ?? "")" }.joined(separator: "\n") + "\n\n"
            }
            if let rot = d["rote_linien"] as? [String], !rot.isEmpty {
                text += "ROTE LINIEN: \(rot.joined(separator: "; "))"
            }
            await MainActor.run { dossier = text.trimmingCharacters(in: .whitespacesAndNewlines) }
        } catch {
            await MainActor.run { wwFehler = error.localizedDescription }
        }
    }
    private func prozessnotizPDF() async {
        guard let fall = viewModel.fall else { return }
        exportLaeuft = true
        wwFehler = nil
        defer { exportLaeuft = false }
        let eigen = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let prompt = """
        Du bist ein erfahrener Prozessanwalt. Erstelle eine vollständige taktische Prozessnotiz.
        Fall: \(fall.fallname)
        Aktenzeichen: \(fall.aktenzeichen ?? "")
        Gericht: \(fall.gericht ?? "")
        Rechtsgebiet: \(fall.rechtsgebiet ?? "")
        Prognose: \(Int(basisPrognose))%
        EIGENE ARGUMENTE (\(eigen.count)):
        \(eigen.map { "- \($0.title) (Stärke: \($0.strength)/10)" }.joined(separator: "\n"))
        GEGNER-ARGUMENTE (\(gegner.count)):
        \(gegner.map { "- \($0.title) (Stärke: \($0.strength)/10)" }.joined(separator: "\n"))
        Erstelle: 1) Executive Summary 2) Mind. 5 Gegner-Strategien mit Gegenmaßnahmen 3) Timing-Analyse 4) Psychologische Taktiken 5) Verhandlungsführung 6) Warnsignale 7) Gesamtstrategie
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "gegner_strategien": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "strategie": ["type": "string"],
                            "beschreibung": ["type": "string"],
                            "wahrscheinlichkeit": ["type": "string"],
                            "gegenmassnahme": ["type": "string"]
                        ]
                    ]
                ],
                "timing_analyse": ["type": "string"],
                "verhandlungsfuehrung": ["type": "string"],
                "warnsignale": ["type": "array", "items": ["type": "string"]],
                "gesamtstrategie": ["type": "string"]
            ]
        ]
        do {
            let d = try await LLMService.shared.invokeObject(
                prompt: prompt,
                schema: schema,
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Was-wäre-wenn — Prozessnotiz"
            )
            var text = "PROZESSNOTIZ — TAKTISCHE ANALYSE\n"
            text += "Fall: \(fall.fallname) | Az: \(fall.aktenzeichen ?? "–") | Prognose: \(Int(basisPrognose))%\n"
            text += "Erstellt: \(Date().formatted(date: .abbreviated, time: .omitted)) | VERTRAULICH\n\n"
            if let z = KIJson.string(in: d, keys: "zusammenfassung", "summary") { text += "EXECUTIVE SUMMARY\n\(z)\n\n" }
            let strategien = KIJson.array(in: d, keys: "gegner_strategien", "strategien")
            if !strategien.isEmpty {
                text += "MÖGLICHE STRATEGIEN DER GEGENSEITE\n"
                for (i, s) in strategien.enumerated() {
                    text += "\n\(i + 1). \(KIJson.string(in: s, keys: "strategie") ?? "") (\(KIJson.string(in: s, keys: "wahrscheinlichkeit") ?? ""))\n"
                    text += "\(KIJson.string(in: s, keys: "beschreibung") ?? "")\n→ GEGENMASSNAHME: \(KIJson.string(in: s, keys: "gegenmassnahme", "gegenmasnahme") ?? "")\n"
                }
                text += "\n"
            }
            if let t = KIJson.string(in: d, keys: "timing_analyse") { text += "TIMING-ANALYSE\n\(t)\n\n" }
            if let v = KIJson.string(in: d, keys: "verhandlungsfuehrung") { text += "VERHANDLUNGSFÜHRUNG\n\(v)\n\n" }
            if let w = d["warnsignale"] as? [String], !w.isEmpty { text += "WARNUNGEN\n\(w.map { "• \($0)" }.joined(separator: "\n"))\n\n" }
            if let g = KIJson.string(in: d, keys: "gesamtstrategie") { text += "GESAMTSTRATEGIE\n\(g)\n" }
            let filename = "Prozessnotiz_\(fall.fallname.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).txt"
            guard let basis = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
                throw CocoaError(.fileReadNoSuchFile)
            }
            let url = basis.appendingPathComponent(filename)
            try text.write(to: url, atomically: true, encoding: .utf8)
            await MainActor.run { _ = NSWorkspace.shared.open(url) }
        } catch {
            await MainActor.run { wwFehler = error.localizedDescription }
        }
    }
}
struct SzenarienKarte: View {
    let szenario: WasWaereWennView.Szenario
    let basis: Double
    var effektivePrognose: Double { min(100, max(0, basis + szenario.prognoseOffset)) }
    var farbe: Color {
        switch szenario.risiko {
        case "niedrig": return .green
        case "hoch":    return .red
        default:        return .orange
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(szenario.name).font(.system(size: 13, weight: .bold))
                FenlynineOSTransparenzInfoButton(inhalt: TransparenzInhalt(
                    titel: "Szenario: \(szenario.name)",
                    quelle: .algorithmus,
                    modell: "Was-wäre-wenn — Szenario-Rechner",
                    ergebnis: "\(Int(effektivePrognose))% (Basis \(Int(basis))% \(szenario.prognoseOffset >= 0 ? "+" : "")\(Int(szenario.prognoseOffset))%)",
                    begruendung: szenario.beschreibung,
                    formel: "Prognose = clamp(Basis + Offset, 0, 100)",
                    erklaerung: "Kosten: \(formatEuroW(szenario.kosten)) · Risiko: \(szenario.risiko)"
                ))
                Spacer()
                Text(szenario.risiko.capitalized)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(farbe.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(farbe)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(effektivePrognose))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(farbe)
                Text(szenario.prognoseOffset >= 0 ? "+\(Int(szenario.prognoseOffset))%" : "\(Int(szenario.prognoseOffset))%")
                    .font(.caption.bold())
                    .foregroundStyle(szenario.prognoseOffset >= 0 ? .green : .red)
            }
            ProgressView(value: effektivePrognose, total: 100)
                .tint(farbe)
                .frame(height: 6)
            Text(szenario.beschreibung)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            HStack {
                Image(systemName: "eurosign.circle")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(formatEuroW(szenario.kosten))
                    .font(.caption2.bold())
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.2), lineWidth: 1))
    }
}
struct SzenarienChart: View {
    let szenarien: [WasWaereWennView.Szenario]
    let basis: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prognose-Vergleich").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            Chart {
                ForEach(szenarien) { s in
                    let p = min(100, max(0, basis + s.prognoseOffset))
                    BarMark(
                        x: .value("Szenario", s.name),
                        y: .value("Prognose %", p)
                    )
                    .foregroundStyle(s.prognoseOffset >= 5 ? Color.green : s.prognoseOffset <= -10 ? Color.red : Color.orange)
                    .annotation(position: .top) {
                        Text("\(Int(p))%").font(.caption2.bold())
                    }
                }
                RuleMark(y: .value("Basis", basis))
                    .foregroundStyle(.blue.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                    .annotation(position: .trailing) {
                        Text("Basis").font(.caption2).foregroundStyle(.blue)
                    }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 180)
        }
        .padding(12)
        .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
    }
}
private func formatEuroW(_ val: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "EUR"
    f.locale = Locale(identifier: "de_DE")
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: val)) ?? "\(Int(val)) €"
}
struct GesamtbewertungView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var kiAnalyse: GesamtAnalyse? = nil
    @State private var laeuft = false
    @State private var aufgeklappt: Set<Int> = []
    @State private var fehler: String?
    struct GesamtAnalyse {
        var erfolgswahrscheinlichkeit: Int
        var begruendung: String
        var unsere_taktiken: [Taktik]
        var gegner_strategien: [GegnerStrategie]
        var gegner_asse: [Taktik]
        var unsere_schwachstellen: [Schwachstelle]
        var gesamtstrategie: String
        var gegner_argumente: [GegnerArgument]
        var gegner_vorgehen: [VorgehenSchritt]
        struct Taktik: Identifiable {
            let id = UUID()
            var titel: String
            var beschreibung: String
        }
        struct GegnerStrategie: Identifiable {
            let id = UUID()
            var titel: String
            var beschreibung: String
            var gefahr: String
        }
        struct Schwachstelle: Identifiable {
            let id = UUID()
            var titel: String
            var risiko: String
        }
        struct GegnerArgument: Identifiable {
            let id = UUID()
            var argument: String
            var paragraphen: String
            var staerke: String
            var unsere_antwort: String
        }
        struct VorgehenSchritt: Identifiable {
            let id = UUID()
            var phase: String
            var beschreibung: String
            var risiko: String
        }
    }
    var body: some View {
        VStack(spacing: 20) {
                if let err = fehler {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
                HStack {
                    Label("Gesamtbewertung", systemImage: "trophy.fill")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        Task { await kiAnalyseStarten() }
                    } label: {
                        if laeuft {
                            ProgressView().scaleEffect(0.7)
                            Text("Analysiere…").font(.caption)
                        } else {
                            Label(kiAnalyse != nil ? "Neu analysieren" : "Analyse starten", systemImage: "brain")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    .disabled(laeuft || !kiMode)
                }
                if let fall = viewModel.fall {
                    AlgorithmPrognoseKarte(
                        fall: fall,
                        argumente: viewModel.argumente,
                        beweise: viewModel.beweise,
                        fristen: viewModel.fristen,
                        prognose: viewModel.vollanalyse?.prognose
                    )
                }
                if let analyse = kiAnalyse {
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            PrognoseGaugeView(
                                wert: Double(analyse.erfolgswahrscheinlichkeit),
                                transparenz: .kiModul(
                                    titel: "KI-Gesamtbewertung",
                                    begruendung: analyse.begruendung,
                                    ausgabe: "\(analyse.erfolgswahrscheinlichkeit)%"
                                )
                            )
                            Text("KI-Prognose").font(.caption).foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            if !analyse.begruendung.isEmpty {
                                Text(analyse.begruendung).font(.system(size: 12)).lineSpacing(3)
                            }
                            if !analyse.gesamtstrategie.isEmpty {
                                Label("Gesamtstrategie: \(analyse.gesamtstrategie)", systemImage: "scope")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    if !analyse.unsere_taktiken.isEmpty {
                        GesamtAbschnitt(titel: "Unsere Taktiken", symbol: "shield.lefthalf.filled", farbe: .blue) {
                            ForEach(Array(analyse.unsere_taktiken.enumerated()), id: \.element.id) { idx, t in
                                GesamtKarte(nummer: idx + 1, titel: t.titel, text: t.beschreibung, farbe: .blue)
                            }
                        }
                    }
                    if !analyse.gegner_strategien.isEmpty {
                        GesamtAbschnitt(titel: "Erwartete Gegnerstrategien", symbol: "exclamationmark.triangle.fill", farbe: .red) {
                            ForEach(analyse.gegner_strategien) { s in
                                GesamtKarte(
                                    nummer: nil,
                                    titel: s.titel,
                                    text: s.beschreibung,
                                    farbe: s.gefahr == "hoch" ? .red : s.gefahr == "mittel" ? .orange : .green,
                                    badge: s.gefahr.capitalized
                                )
                            }
                        }
                    }
                    if !analyse.gegner_argumente.isEmpty {
                        GesamtAbschnitt(titel: "Konkrete Gegenargumente", symbol: "scale.3d", farbe: .orange) {
                            ForEach(analyse.gegner_argumente) { g in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(g.argument).font(.system(size: 12, weight: .medium)).lineLimit(3)
                                        Spacer()
                                        Text(g.staerke.capitalized)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 5).padding(.vertical, 2)
                                            .background(g.staerke == "hoch" ? Color.red.opacity(0.1) : g.staerke == "mittel" ? Color.orange.opacity(0.1) : Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                                            .foregroundStyle(g.staerke == "hoch" ? .red : g.staerke == "mittel" ? .orange : .green)
                                    }
                                    if !g.paragraphen.isEmpty {
                                        Text(g.paragraphen).font(.caption2).foregroundStyle(.blue)
                                    }
                                    if !g.unsere_antwort.isEmpty {
                                        Text("↳ \(g.unsere_antwort)").font(.system(size: 11)).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    if !analyse.gegner_vorgehen.isEmpty {
                        GesamtAbschnitt(titel: "Vorgehen der Gegenseite", symbol: "arrow.forward.circle.fill", farbe: .purple) {
                            ForEach(Array(analyse.gegner_vorgehen.enumerated()), id: \.element.id) { idx, v in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(width: 20, height: 20)
                                        .background(Color.purple.opacity(0.15), in: Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(v.phase).font(.system(size: 12, weight: .semibold))
                                        Text(v.beschreibung).font(.system(size: 11)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(8)
                        }
                    }
                    if !analyse.unsere_schwachstellen.isEmpty {
                        GesamtAbschnitt(titel: "Unsere Schwachstellen", symbol: "exclamationmark.triangle", farbe: .red) {
                            ForEach(analyse.unsere_schwachstellen) { s in
                                GesamtKarte(nummer: nil, titel: s.titel, text: s.risiko, farbe: .red)
                            }
                        }
                    }
                } else if !laeuft {
                    InfoHinweis(titel: "KI-Strategieanalyse starten", nachricht: "Die KI liefert Taktiken, Gegnerstrategien, konkrete Gegenargumente und einen Schritt-für-Schritt Plan der Gegenseite.", symbol: "brain")
                }
                LexaraKIZusatzErgebnisBanner(viewModel: viewModel, kiMode: kiMode)
            }
        .onAppear { hydrateGesamtbewertung() }
    }
    private func hydrateGesamtbewertung() {
        guard kiAnalyse == nil,
              let d = viewModel.fall?.ki_berater_result?.dictValue?["gesamtbewertung"] as? [String: Any]
        else { return }
        kiAnalyse = parseGesamtAnalyse(d)
    }
    private func kiAnalyseStarten() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let eigeneArgs = viewModel.argumente.filter { $0.side == .eigen }.prefix(5)
        let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }.prefix(5)
        let beweise = viewModel.beweise.prefix(5)
        let prompt = """
        Du bist erfahrener Strafverteidiger. Analysiere diesen Fall tiefgehend:
        Fall: "\(fall.fallname)" | \(fall.rechtsgebiet ?? "") | Gericht: \(fall.gericht ?? "")
        Zentrale Frage: \(fall.zentrale_rechtsfrage ?? "")
        Eigene Argumente: \(eigeneArgs.map { "\"\($0.title)\" Stärke:\($0.strength)/10" }.joined(separator: ", "))
        Gegnerargumente: \(gegnerArgs.map { "\"\($0.title)\" Stärke:\($0.strength)/10" }.joined(separator: ", "))
        Beweise: \(beweise.map { "\"\($0.title)\"" }.joined(separator: ", "))
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "erfolgswahrscheinlichkeit": ["type": "integer"],
                        "erfolgswahrscheinlichkeit_begruendung": ["type": "string"],
                        "unsere_taktiken": ["type": "array", "items": ["type": "object", "properties": ["titel": ["type": "string"], "beschreibung": ["type": "string"]]]],
                        "gegner_strategien": ["type": "array", "items": ["type": "object", "properties": ["titel": ["type": "string"], "beschreibung": ["type": "string"], "gefahr": ["type": "string"]]]],
                        "gegner_asse": ["type": "array", "items": ["type": "object", "properties": ["titel": ["type": "string"], "beschreibung": ["type": "string"]]]],
                        "unsere_schwachstellen": ["type": "array", "items": ["type": "object", "properties": ["titel": ["type": "string"], "risiko": ["type": "string"]]]],
                        "gesamtstrategie": ["type": "string"],
                        "gegner_argumente": ["type": "array", "items": ["type": "object", "properties": ["argument": ["type": "string"], "paragraphen": ["type": "string"], "staerke": ["type": "string"], "unsere_antwort": ["type": "string"]]]],
                        "gegner_vorgehen": ["type": "array", "items": ["type": "object", "properties": ["phase": ["type": "string"], "beschreibung": ["type": "string"], "risiko": ["type": "string"]]]]
                    ] as [String: Any]
                ] as [String: Any],
                model: "gemini_3_flash",
                logCaseId: viewModel.caseId,
                logKiName: "Gesamtbewertung — KI-Strategieanalyse"
            )
            let dict = try KIJson.requireObject(result, kontext: "Gesamtbewertung")
            let analyse = parseGesamtAnalyse(dict)
            await MainActor.run { kiAnalyse = analyse }
            if var fallUpd = viewModel.fall {
                let saved = try await KIResultStore.mergeBeraterSubKey(
                    caseId: viewModel.caseId,
                    fall: &fallUpd,
                    key: "gesamtbewertung",
                    value: dict
                )
                await MainActor.run { viewModel.fall = saved }
            }
            Task { await LexaraKIZusatzAnalyseService.ergaenzeAnalyse(viewModel: viewModel, quelle: .gesamtbewertung, kiMode: kiMode) }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func parseGesamtAnalyse(_ d: [String: Any]) -> GesamtAnalyse {
        func taktiken(_ key: String) -> [GesamtAnalyse.Taktik] {
            (d[key] as? [[String: Any]] ?? []).map { GesamtAnalyse.Taktik(titel: $0["titel"] as? String ?? "", beschreibung: $0["beschreibung"] as? String ?? "") }
        }
        let gegnerStr = (d["gegner_strategien"] as? [[String: Any]] ?? []).map {
            GesamtAnalyse.GegnerStrategie(titel: $0["titel"] as? String ?? "", beschreibung: $0["beschreibung"] as? String ?? "", gefahr: $0["gefahr"] as? String ?? "mittel")
        }
        let schwachstellen = (d["unsere_schwachstellen"] as? [[String: Any]] ?? []).map {
            GesamtAnalyse.Schwachstelle(titel: $0["titel"] as? String ?? "", risiko: $0["risiko"] as? String ?? "")
        }
        let gegnerArgs = (d["gegner_argumente"] as? [[String: Any]] ?? []).map {
            GesamtAnalyse.GegnerArgument(argument: $0["argument"] as? String ?? "", paragraphen: $0["paragraphen"] as? String ?? "", staerke: $0["staerke"] as? String ?? "mittel", unsere_antwort: $0["unsere_antwort"] as? String ?? "")
        }
        let vorgehen = (d["gegner_vorgehen"] as? [[String: Any]] ?? []).map {
            GesamtAnalyse.VorgehenSchritt(phase: $0["phase"] as? String ?? "", beschreibung: $0["beschreibung"] as? String ?? "", risiko: $0["risiko"] as? String ?? "mittel")
        }
        return GesamtAnalyse(
            erfolgswahrscheinlichkeit: KIJson.intValue(d["erfolgswahrscheinlichkeit"]) ?? 50,
            begruendung: KIJson.string(in: d, keys: "erfolgswahrscheinlichkeit_begruendung", "erfolgswahrscheinlichkeit_beguendung") ?? "",
            unsere_taktiken: taktiken("unsere_taktiken"),
            gegner_strategien: gegnerStr,
            gegner_asse: taktiken("gegner_asse"),
            unsere_schwachstellen: schwachstellen,
            gesamtstrategie: d["gesamtstrategie"] as? String ?? "",
            gegner_argumente: gegnerArgs,
            gegner_vorgehen: vorgehen
        )
    }
}
struct AlgorithmPrognoseKarte: View {
    let fall: LegalCase
    let argumente: [Argument]
    let beweise: [Evidence]
    let fristen: [Deadline]
    var prognose: PrognoseErgebnis? = nil
    private var score: Double {
        Double(prognose?.score ?? Int(fall.prognose ?? 50))
    }
    var body: some View {
        HStack(spacing: 20) {
            PrognoseGaugeView(wert: score, transparenz: prognose.map { .prognose($0) })
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Algorithmus-Prognose").font(.system(size: 13, weight: .bold))
                    if let p = prognose {
                        FenlynineOSTransparenzInfoButton(inhalt: .prognose(p))
                    } else {
                        FenlynineOSTransparenzInfoButton(inhalt: .fallPrognoseChip(prognose: score, vollanalyse: nil))
                    }
                }
                Text("\(argumente.count) Argumente · \(beweise.count) Beweise · \(fristen.filter { $0.status == .offen }.count) offene Fristen")
                    .font(.caption).foregroundStyle(.secondary)
                if let p = prognose {
                    HStack {
                        Text("90%-CI: [\(p.ciLow)% – \(p.ciHigh)%]")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("σ \(String(format: "%.1f", p.sigma * 100)) Pp")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Konfidenzintervall nach vollständiger Berechnung verfügbar.")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}
struct PrognoseGaugeView: View {
    let wert: Double
    var transparenz: TransparenzInhalt? = nil
    private var farbe: Color {
        wert >= 65 ? .green : wert >= 40 ? .orange : .red
    }
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .stroke(farbe.opacity(0.15), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: wert / 100)
                    .stroke(farbe, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(wert))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(farbe)
                }
            }
            if let t = transparenz {
                FenlynineOSTransparenzInfoButton(inhalt: t)
                    .offset(x: 6, y: -6)
            }
        }
    }
}
struct GesamtAbschnitt<Content: View>: View {
    let titel: String
    let symbol: String
    let farbe: Color
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titel, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(farbe)
            content()
        }
        .padding(12)
        .background(farbe.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.12), lineWidth: 1))
    }
}
struct GesamtKarte: View {
    let nummer: Int?
    let titel: String
    let text: String
    let farbe: Color
    var badge: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let n = nummer {
                Text("\(n)")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(farbe.opacity(0.15), in: Circle())
                    .foregroundStyle(farbe)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(titel).font(.system(size: 12, weight: .semibold))
                    if let b = badge {
                        Text(b).font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(farbe.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(farbe)
                    }
                }
                if !text.isEmpty {
                    Text(text).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(4)
                }
            }
        }
    }
}
struct VerhandlungsCockpit: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var lastMinuteCheck: LastMinuteResult? = nil
    @State private var laeuft = false
    @State private var fehler: String?
    struct LastMinuteResult {
        var gefahren: [(angriff: String, konter: String)]
        var verbote: [String]
        var motivation: String
    }
    var body: some View {
        VStack(spacing: 20) {
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if let kiDict = viewModel.fall?.ki_berater_result?.dictValue {
                DokumentKiBeraterPanel(ki: kiDict)
            }
            HStack {
                Label("Verhandlungs-Cockpit", systemImage: "gauge.with.needle")
                    .font(.title2.bold())
                Spacer()
                Button {
                    Task { await lastMinuteCheckStarten() }
                } label: {
                    if laeuft {
                        ProgressView().scaleEffect(0.7)
                        Text("Analysiere…").font(.caption)
                    } else {
                        Label(lastMinuteCheck != nil ? "Neu analysieren" : "Last-Minute-Check", systemImage: "bolt.fill")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .tint(.orange)
                .disabled(laeuft || !kiMode)
            }
            let alerts = erstelleAlerts()
            if !alerts.isEmpty {
                VStack(spacing: 6) {
                    ForEach(alerts, id: \.0) { alert in
                        HStack(spacing: 10) {
                            Text(alert.2).font(.body)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(alert.0).font(.system(size: 12, weight: .semibold)).foregroundStyle(alert.1)
                                Text(alert.3).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(alert.1.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if let fall = viewModel.fall {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    CockpitKachel(symbol: "⚔️", titel: "Eigene Argumente", wert: "\(viewModel.argumente.filter { $0.side == .eigen }.count)", sub: "erfasst", farbe: .blue)
                    CockpitKachel(symbol: "🛡️", titel: "Gegner-Argumente", wert: "\(viewModel.argumente.filter { $0.side == .gegner }.count)", sub: "bekannt", farbe: .red)
                    CockpitKachel(symbol: "📋", titel: "Offene Aufgaben", wert: "\(viewModel.aufgaben.filter { $0.status != .erledigt }.count)", sub: "ausstehend", farbe: .orange)
                    CockpitKachel(symbol: "⏰", titel: "Aktive Fristen", wert: "\(viewModel.fristen.filter { $0.status == .offen }.count)", sub: "offen", farbe: .purple)
                }
                HStack(spacing: 16) {
                    PrognoseGaugeView(
                        wert: fall.prognose ?? 50,
                        transparenz: viewModel.vollanalyse.map { .prognose($0.prognose, kontext: "Cockpit-Prognose") }
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        let prognose = fall.prognose ?? 50
                        Text(prognose >= 65 ? "Gute Ausgangslage" : prognose >= 40 ? "Ausgangslage unklar" : "Schwierige Ausgangslage")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(prognose >= 65 ? .green : prognose >= 40 ? .orange : .red)
                        Text(fall.fallname).font(.caption).foregroundStyle(.secondary)
                        Text("\(fall.rechtsgebiet ?? "") · \(fall.instanz.rawValue)").font(.caption2).foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            }
            let offeneFristen = viewModel.fristen.filter { $0.status == .offen }.sorted { $0.due_date < $1.due_date }.prefix(5)
            if !offeneFristen.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Anstehende Fristen", systemImage: "clock.fill")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    ForEach(Array(offeneFristen)) { f in
                        let tage = f.tageVerbleibend
                        HStack {
                            Circle().fill(tage < 3 ? Color.red : tage < 14 ? .orange : .green).frame(width: 8, height: 8)
                            Text(f.title).font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(f.due_date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.secondary)
                            Text(tage < 0 ? "Überfällig!" : "in \(tage)d")
                                .font(.caption2.bold())
                                .foregroundStyle(tage < 3 ? .red : tage < 14 ? .orange : .green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
            if let lm = lastMinuteCheck {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Last-Minute-Check", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.orange)
                    ForEach(Array(lm.gefahren.enumerated()), id: \.offset) { idx, g in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red).font(.system(size: 13))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Angriff:").font(.system(size: 11, weight: .semibold)).foregroundStyle(.red)
                                    Text(g.angriff).font(.system(size: 11))
                                }
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.shield.fill").foregroundStyle(.green).font(.system(size: 13))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Konter:").font(.system(size: 11, weight: .semibold)).foregroundStyle(.green)
                                    Text(g.konter).font(.system(size: 11))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                    if !lm.verbote.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🚫 Das darf im Termin NICHT passieren:")
                                .font(.system(size: 12, weight: .bold)).foregroundStyle(.red)
                            ForEach(lm.verbote, id: \.self) { v in
                                HStack(spacing: 6) {
                                    Text("✗").foregroundStyle(.red).font(.system(size: 11))
                                    Text(v).font(.system(size: 11))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                    if !lm.motivation.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.bubble.fill").foregroundStyle(.blue)
                            Text("\u{201E}\(lm.motivation)\u{201C}").font(.system(size: 12, weight: .medium)).italic()
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else if !laeuft {
                InfoHinweis(titel: "Last-Minute-Check", nachricht: "Analysiert die gefährlichsten Gegenargumente und liefert Konterstrategien für den Gerichtstermin.", symbol: "bolt.fill")
            }
        }
        .onAppear { hydrateLastMinute() }
    }
    private func hydrateLastMinute() {
        guard lastMinuteCheck == nil,
              let d = viewModel.fall?.ki_berater_result?.dictValue?["last_minute_check"] as? [String: Any]
        else { return }
        let gefahrenRaw = d["gefahren"] as? [[String: Any]] ?? []
        let gefahren = gefahrenRaw.map { g in
            (angriff: g["angriff"] as? String ?? "", konter: g["konter"] as? String ?? "")
        }
        lastMinuteCheck = LastMinuteResult(
            gefahren: gefahren,
            verbote: d["verbote"] as? [String] ?? [],
            motivation: d["motiviation"] as? String ?? d["motivation"] as? String ?? ""
        )
    }
    private func erstelleAlerts() -> [(String, Color, String, String)] {
        var alerts: [(String, Color, String, String)] = []
        let kritische = viewModel.warnungen.filter { $0.severity == .kritisch && !$0.resolved }
        if !kritische.isEmpty {
            alerts.append(("\(kritische.count) KRITISCHE Compliance-Warnung(en)", .red, "🔴", kritische.prefix(2).map(\.title).joined(separator: " | ")))
        }
        let versaeumte = viewModel.fristen.filter { $0.status == .versaeumt }
        if !versaeumte.isEmpty {
            alerts.append(("\(versaeumte.count) Frist(en) versäumt", .red, "⚠️", "Auswirkung auf Prognose"))
        }
        let starkeGegner = viewModel.argumente.filter { $0.side == .gegner && $0.strength >= 7 }
        if starkeGegner.count >= 3 {
            alerts.append(("Starke Gegnerargumente", .orange, "🛡️", "\(starkeGegner.count) starke Argumente vorhanden"))
        }
        return alerts
    }
    private func lastMinuteCheckStarten() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }.sorted { $0.strength > $1.strength }.prefix(4)
        let eigeneArgs = viewModel.argumente.filter { $0.side == .eigen }.prefix(5)
        let prompt = """
        Führe einen Last-Minute-Check für den bevorstehenden Gerichtstermin durch.
        Fall: \(fall.fallname) | \(fall.rechtsgebiet ?? "") | Prognose: \(Int(fall.prognose ?? 50))%
        Eigene Argumente: \(eigeneArgs.map { "\($0.title) (Stärke \($0.strength)/10)" }.joined(separator: "; "))
        Stärkste Gegenargumente: \(gegnerArgs.map { "\($0.title) (Stärke \($0.strength)/10)" }.joined(separator: "; "))
        Liefere: 3 gefährlichste Angriffspunkte mit Konterstrategien, 3 Verbote, motivierender Schlusssatz.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "gefahren": ["type": "array", "items": ["type": "object", "properties": ["angriff": ["type": "string"], "konter": ["type": "string"]]]],
                        "verbote": ["type": "array", "items": ["type": "string"]],
                        "motiviation": ["type": "string"]
                    ] as [String: Any]
                ] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Last-Minute-Check"
            )
            let dict = try KIJson.requireObject(result, kontext: "Last-Minute")
            let gefahrenArr = (dict["gefahren"] as? [[String: Any]] ?? []).map {
                (angriff: $0["angriff"] as? String ?? "", konter: $0["konter"] as? String ?? "")
            }
            let verbote = dict["verbote"] as? [String] ?? []
            let motivation = dict["motiviation"] as? String ?? ""
            await MainActor.run {
                lastMinuteCheck = LastMinuteResult(gefahren: gefahrenArr, verbote: verbote, motivation: motivation)
            }
            if var fallUpd = viewModel.fall {
                let saved = try await KIResultStore.mergeBeraterSubKey(
                    caseId: viewModel.caseId,
                    fall: &fallUpd,
                    key: "last_minute_check",
                    value: dict
                )
                await MainActor.run { viewModel.fall = saved }
            }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
struct CockpitKachel: View {
    let symbol: String
    let titel: String
    let wert: String
    let sub: String
    let farbe: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(symbol).font(.title3)
            Text(wert).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(farbe)
            Text(titel).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text(sub).font(.system(size: 8)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}
