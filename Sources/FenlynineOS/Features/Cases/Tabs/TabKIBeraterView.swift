import SwiftUI
struct TabKIBeraterView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var acknowledged = false
    @State private var showProfil = false
    @State private var profil: [String: String] = TabKIBeraterView.emptyProfil
    @State private var result: [String: Any]?
    @State private var laeuft = false
    @State private var fehler: String?
    private static let profilKeys: [(section: String, fields: [(label: String, key: String, placeholder: String)])] = [
        ("Gegner-Organisation", [
            ("Name", "gegner_name", "z.B. ABC GmbH"),
            ("Größe", "gegner_groesse", "Mittelstand, 200 MA"),
            ("Finanzlage", "gegner_finanzlage", "Liquiditätsprobleme"),
            ("Branche", "gegner_branche", "Pharma")
        ]),
        ("Entscheider (CEO/GF)", [
            ("Name/Titel", "entscheider_name", "Dr. Max Müller (CEO)"),
            ("Alter", "entscheider_alter", "58"),
            ("Persönlichkeit", "entscheider_persoenlichkeit", "Dominant, risikoscheu"),
            ("Karrierephase", "entscheider_karriere", "Kurz vor Ruhestand"),
            ("Schwächen", "entscheider_schwaechen", "Angst vor Medien")
        ]),
        ("Anwalt Gegenseite", [
            ("Kanzlei", "anwalt_kanzlei", "Schmidt & Partner"),
            ("Bekannt für", "anwalt_bekannt_fuer", "Aggressive Taktik"),
            ("Schwächen", "anwalt_schwaechen", "Richter genervt")
        ]),
        ("Bisheriges Verhalten", [
            ("Verhandlungsbereitschaft", "verhalten_verhandlung", "Privat: Signale"),
            ("Taktik", "verhalten_taktik", "Verzögerung"),
            ("Fehler", "verhalten_fehler", "Widersprüche")
        ]),
        ("Eigene Position", [
            ("Stärken", "eigene_staerken", "Klare Beweislage"),
            ("Schwächen", "eigene_schwaechen", "Mandant limitiert"),
            ("Ziel maximal", "ziel_maximal", "500.000€"),
            ("Ziel realistisch", "ziel_realistisch", "300.000€"),
            ("Ziel minimal", "ziel_minimal", "150.000€"),
            ("Nicht verhandelbar", "nicht_verhandelbar", "Entschuldigung")
        ]),
        ("Kontext & Externe Faktoren", [
            ("Öffentlichkeit", "kontext_oeffentlichkeit", "Medieninteresse"),
            ("Zeitdruck", "kontext_zeitdruck", "Fusion in 6 Monaten"),
            ("Weitere Faktoren", "kontext_weitere", "Hauptversammlung")
        ])
    ]
    static let emptyProfil: [String: String] = [
        "gegner_name": "", "gegner_groesse": "", "gegner_finanzlage": "", "gegner_branche": "",
        "entscheider_name": "", "entscheider_alter": "", "entscheider_persoenlichkeit": "",
        "entscheider_karriere": "", "entscheider_schwaechen": "",
        "anwalt_kanzlei": "", "anwalt_bekannt_fuer": "", "anwalt_schwaechen": "",
        "verhalten_verhandlung": "", "verhalten_taktik": "", "verhalten_fehler": "",
        "eigene_staerken": "", "eigene_schwaechen": "",
        "ziel_maximal": "", "ziel_realistisch": "", "ziel_minimal": "", "nicht_verhandelbar": "",
        "kontext_oeffentlichkeit": "", "kontext_zeitdruck": "", "kontext_weitere": ""
    ]
    var body: some View {
        Group {
            if !acknowledged {
                rechtshinweisView
            } else {
                mainContent
            }
        }
        .onAppear { hydrateFromFall() }
    }
    private var rechtshinweisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rechtshinweis & Vertraulichkeit").font(.title3.bold())
            Text("Diese Analyse dient ausschließlich der Vorbereitung auf mögliche gegnerische Taktiken und der Entwicklung legitimer Verhandlungsstrategien.")
                .font(.subheadline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                ForEach([
                    "Absolut vertraulich (§ 203 StGB Anwaltsgeheimnis)",
                    "Keine Anleitung zu unlauteren Methoden (§ 138 ZPO)",
                    "Defensive Taktik-Analyse, kein Rechtsbruch",
                    "Endverantwortung liegt IMMER beim Anwalt"
                ], id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle").font(.caption)
                }
            }
            Button("Verstanden – Strategischen Berater öffnen") {
                acknowledged = true
            }
            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
    private var mainContent: some View {
        VStack(spacing: 20) {
            profilSection
            if !kiMode {
                Label("Manuell-Modus — KI-Analyse deaktiviert", systemImage: "pencil")
                    .font(.caption).foregroundStyle(.orange)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            analyseModuleSection
            if let r = result { ergebnisView(r) }
            LexaraKIZusatzErgebnisBanner(viewModel: viewModel, kiMode: kiMode)
        }
    }
    private var profilSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showProfil.toggle() }
            } label: {
                Label("Gegner-Profil & Kontext (\(showProfil ? "ausblenden" : "anzeigen"))", systemImage: "target")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.plain)
            if showProfil {
                ForEach(Self.profilKeys, id: \.section) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.section).font(.caption.bold()).foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(section.fields, id: \.key) { field in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(field.label).font(.caption2).foregroundStyle(.secondary)
                                    TextField(field.placeholder, text: binding(for: field.key))
                                        .textFieldStyle(.roundedBorder)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                Button("Profil speichern") {
                    Task { await profilSpeichern() }
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
    private var analyseModuleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analyse-Module").font(.subheadline.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                modulKachel("Psychologisches Profil", done: result?["psychologisches_profil"] != nil)
                modulKachel("Druckmittel", done: (result?["druckmittel"] as? [Any])?.isEmpty == false)
                modulKachel("Strategieoptionen", done: (result?["strategien"] as? [Any])?.isEmpty == false)
                modulKachel("Timing", done: result?["timing"] != nil)
                modulKachel("Informationsstrategie", done: result?["informationsstrategie"] != nil)
                modulKachel("Verhandlungsskript", done: result?["verhandlungsskript"] != nil)
            }
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if kiMode {
                Button {
                    Task { await analyseStarten() }
                } label: {
                    if laeuft {
                        ProgressView().scaleEffect(0.7)
                        Text("Analysiere mit KI…")
                    } else {
                        Label("Vollständige Analyse starten", systemImage: "scope")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(laeuft)
                Text("Diese Analyse kann 30–60 Sekunden dauern").font(.caption2).foregroundStyle(.orange)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
    }
    @ViewBuilder
    private func modulKachel(_ titel: String, done: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.caption2.bold())
            if done {
                Text("✓ Ergebnis").font(.caption2).foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    @ViewBuilder
    private func ergebnisView(_ r: [String: Any]) -> some View {
        if let psycho = r["psychologisches_profil"] as? [String: Any] {
            kiBeraterErgebnisKarte(titel: "Psychologisches Profil", symbol: "person.fill") {
                if let bf = psycho["big_five"] as? [String: Any] {
                    Text("Big Five").font(.caption.bold())
                    ForEach(bf.keys.sorted(), id: \.self) { k in
                        if let v = KIJson.numberValue(bf[k]) {
                            HStack {
                                Text(k).font(.caption2).frame(width: 120, alignment: .leading)
                                ProgressView(value: v, total: 10).tint(.red)
                                Text("\(Int(v.rounded()))/10").font(.caption2)
                            }
                        }
                    }
                }
                if let emp = psycho["empfehlung"] as? String, !emp.isEmpty {
                    Text("Empfehlung: \(emp)").font(.caption).italic().padding(.top, 6)
                }
            }
        }
        if let druck = r["druckmittel"] as? [[String: Any]], !druck.isEmpty {
            kiBeraterErgebnisKarte(titel: "Druckmittel-Analyse", symbol: "bolt.fill") {
                ForEach(Array(druck.enumerated()), id: \.offset) { _, d in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(d["titel"] as? String ?? "").font(.caption.bold())
                        if let w = d["wie_nutzen"] as? String { Text("→ \(w)").font(.caption2) }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        if let strategien = r["strategien"] as? [[String: Any]], !strategien.isEmpty {
            kiBeraterErgebnisKarte(titel: "Strategieempfehlungen", symbol: "shield.lefthalf.filled") {
                ForEach(Array(strategien.enumerated()), id: \.offset) { _, s in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(s["name"] as? String ?? "").font(.caption.bold())
                            Spacer()
                            if let p = s["erfolg_pct"] as? Double { Text("\(Int(p))%").font(.caption2) }
                        }
                        if let st = s["stil"] as? String { Text(st).font(.caption2).italic() }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        if let timing = r["timing"] as? [String: Any] {
            kiBeraterErgebnisKarte(titel: "Timing & Momentum", symbol: "clock.fill") {
                if let m = timing["momentum"] as? String { Text(m).font(.caption) }
                if let n = timing["naechster_schritt"] as? String {
                    Text("Nächster Schritt: \(n)").font(.caption.bold()).padding(.top, 4)
                }
            }
        }
        if let info = r["informationsstrategie"] as? [String: Any] {
            kiBeraterErgebnisKarte(titel: "Informationsstrategie", symbol: "eye.slash.fill") {
                infoSpalte("Offenlegen", items: info["sofort_offenlegen"] as? [String], farbe: .green)
                infoSpalte("Verbergen", items: info["verbergen"] as? [String], farbe: .red)
                infoSpalte("Bluff", items: info["als_bluff"] as? [String], farbe: .orange)
            }
        }
        if let skript = r["verhandlungsskript"] as? [String: Any] {
            kiBeraterErgebnisKarte(titel: "Verhandlungsskript", symbol: "text.bubble.fill") {
                ForEach([("Opening", "opening"), ("Argumentation", "argumentation"), ("Closing", "closing")], id: \.1) { label, key in
                    if let t = skript[key] as? String, !t.isEmpty {
                        Text(label).font(.caption.bold())
                        Text(t).font(.caption2).padding(6).background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        if let recht = r["rechtliche_einordnung"] as? [String: Any] {
            kiBeraterErgebnisKarte(titel: "Rechtliche Einordnung", symbol: "scale.3d") {
                if let ag = recht["anspruchsgrundlagen"] as? [String] {
                    Text("Anspruchsgrundlagen: \(ag.joined(separator: ", "))").font(.caption)
                }
                if let p = recht["pruefungsschema"] as? String { Text(p).font(.caption2) }
            }
        }
        if let issues = r["issue_spotting"] as? [[String: Any]], !issues.isEmpty {
            kiBeraterErgebnisKarte(titel: "Issue Spotting", symbol: "exclamationmark.magnifyingglass") {
                ForEach(Array(issues.enumerated()), id: \.offset) { _, i in
                    Text("• \(i["risiko"] as? String ?? "") — \(i["empfehlung"] as? String ?? "")").font(.caption2)
                }
            }
        }
        if let comp = r["compliance_check"] as? [String: Any] {
            kiBeraterErgebnisKarte(titel: "Compliance-Check", symbol: "checkmark.shield.fill") {
                ForEach((comp["risiken"] as? [String] ?? []), id: \.self) { Text("⚠ \($0)").font(.caption2) }
            }
        }
        if let emp = r["empfehlung"] as? String, !emp.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Gesamtempfehlung").font(.subheadline.bold()).foregroundStyle(.white)
                    Spacer()
                    FenlynineOSTransparenzInfoButton(inhalt: .kiModul(
                        titel: "Gesamtempfehlung KI-Berater",
                        begruendung: "Synthese aller KI-Berater-Module.",
                        ausgabe: emp
                    ))
                }
                Text(emp).font(.caption).foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    @ViewBuilder
    private func infoSpalte(_ titel: String, items: [String]?, farbe: Color) -> some View {
        if let items, !items.isEmpty {
            Text(titel).font(.caption2.bold()).foregroundStyle(farbe)
            ForEach(items, id: \.self) { Text("• \($0)").font(.caption2) }
        }
    }
    @ViewBuilder
    private func kiBeraterErgebnisKarte<Content: View>(
        titel: String,
        symbol: String,
        transparenz: TransparenzInhalt? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(titel, systemImage: symbol).font(.subheadline.bold())
                Spacer()
                FenlynineOSTransparenzInfoButton(inhalt: transparenz ?? .kiModul(
                    titel: titel,
                    begruendung: "KI-Berater-Modul: \(titel) — basiert auf Gegner-Profil und Falldaten.",
                    erklaerung: "Modell: Claude Sonnet 4.6 via KI-Berater-Pipeline."
                ))
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
    }
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { profil[key] ?? "" },
            set: { profil[key] = $0 }
        )
    }
    private func hydrateFromFall() {
        guard let fall = viewModel.fall else { return }
        if fall.ki_berater_result?.dictValue != nil {
            acknowledged = true
            result = fall.ki_berater_result?.dictValue
        }
        if let gp = fall.gegner_profil?.dictValue {
            for key in Self.emptyProfil.keys {
                if let v = gp[key] as? String { profil[key] = v }
            }
        }
    }
    private func profilSpeichern() async {
        guard var fall = viewModel.fall else { return }
        var gp = fall.gegner_profil?.dictValue ?? [:]
        for (k, v) in profil where !v.isEmpty { gp[k] = v }
        fall.gegner_profil = AnyCodable(gp)
        do {
            let saved = try await Services.cases.update(id: viewModel.caseId, entity: fall)
            await MainActor.run { viewModel.fall = saved }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func analyseStarten() async {
        guard var fall = viewModel.fall else { return }
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let p = profil
        let prompt = KIPromptKit.wrap("""
        Analysiere diesen Fall vollständig.
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "") | Instanz: \(fall.instanz.rawValue) | Prognose: \(Int(fall.prognose ?? 50))%
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
        Prozessziel: \(fall.prozessziel ?? "")
        Eigene Argumente: \(eigene.map { "\($0.title) (\($0.strength)/10)" }.joined(separator: ", "))
        Gegner-Argumente: \(gegner.map { "\($0.title) (\($0.strength)/10)" }.joined(separator: ", "))
        Gegner: \(p["gegner_name"] ?? "") | Branche: \(p["gegner_branche"] ?? "")
        Entscheider: \(p["entscheider_name"] ?? "") | Persönlichkeit: \(p["entscheider_persoenlichkeit"] ?? "")
        Anwalt: \(p["anwalt_kanzlei"] ?? "") | Bekannt für: \(p["anwalt_bekannt_fuer"] ?? "")
        Verhalten: \(p["verhalten_taktik"] ?? "") | Ziele: Max \(p["ziel_maximal"] ?? ""), Real \(p["ziel_realistisch"] ?? "")
        Erstelle: rechtliche_einordnung, issue_spotting, psychologisches_profil (big_five, dark_triad, trigger),
        druckmittel, strategien, timing, informationsstrategie, verhandlungsskript, compliance_check, empfehlung.
        """, modul: .berater)
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "rechtliche_einordnung": ["type": "object", "properties": [
                    "anspruchsgrundlagen": ["type": "array", "items": ["type": "string"]],
                    "pruefungsschema": ["type": "string"],
                    "gegner_gegenargumente": ["type": "array", "items": ["type": "string"]],
                    "kritische_schwachstellen": ["type": "array", "items": ["type": "string"]]
                ]],
                "issue_spotting": ["type": "array", "items": ["type": "object", "properties": [
                    "risiko": ["type": "string"], "kategorie": ["type": "string"],
                    "empfehlung": ["type": "string"], "prioritaet": ["type": "string"]
                ]]],
                "psychologisches_profil": ["type": "object"],
                "druckmittel": ["type": "array", "items": ["type": "object"]],
                "strategien": ["type": "array", "items": ["type": "object"]],
                "timing": ["type": "object"],
                "informationsstrategie": ["type": "object"],
                "verhandlungsskript": ["type": "object"],
                "compliance_check": ["type": "object"],
                "empfehlung": ["type": "string"]
            ] as [String: Any]
        ] as [String: Any]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: schema,
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "KI-Berater Gegneranalyse"
            )
            let dict = try KIJson.requireObject(response, kontext: "KI-Berater")
            var gp = fall.gegner_profil?.dictValue ?? [:]
            for (k, v) in profil where !v.isEmpty { gp[k] = v }
            fall.ki_berater_result = AnyCodable(dict)
            fall.gegner_profil = AnyCodable(gp)
            let saved = try await Services.cases.update(id: viewModel.caseId, entity: fall)
            await MainActor.run {
                viewModel.fall = saved
                result = dict
            }
            Task { await LexaraKIZusatzAnalyseService.ergaenzeAnalyse(viewModel: viewModel, quelle: .berater, kiMode: kiMode) }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
