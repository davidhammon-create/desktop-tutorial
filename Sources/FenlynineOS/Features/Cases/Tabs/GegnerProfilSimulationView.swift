import SwiftUI
struct GegnerProfilSimulationView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var profil = GegnerProfilDaten.empty
    @State private var showForm = true
    @State private var speichert = false
    @State private var gespeichert = false
    @State private var simuliert = false
    @State private var simulation: GegnerSimulationErgebnis?
    @State private var fehler: String?
    struct GegnerProfilDaten {
        var partei_name: String = ""
        var partei_typ: String = "Privatperson"
        var partei_beschreibung: String = ""
        var anwalt_name: String = ""
        var anwalt_kanzlei: String = ""
        var anwalt_bekannt_fuer: String = ""
        var anwalt_stil: String = ""
        var bekannte_taktiken: String = ""
        var bisherige_reaktionen: String = ""
        var interessen: String = ""
        var schwaechen: String = ""
        static let empty = GegnerProfilDaten()
        static let typen = ["Privatperson", "Unternehmen", "GmbH", "AG", "Versicherung", "Behörde", "Sonstiges"]
        func asDict() -> [String: Any] {
            [
                "partei_name": partei_name, "partei_typ": partei_typ,
                "partei_beschreibung": partei_beschreibung,
                "anwalt_name": anwalt_name, "anwalt_kanzlei": anwalt_kanzlei,
                "anwalt_bekannt_fuer": anwalt_bekannt_fuer, "anwalt_stil": anwalt_stil,
                "bekannte_taktiken": bekannte_taktiken, "bisherige_reaktionen": bisherige_reaktionen,
                "interessen": interessen, "schwaechen": schwaechen
            ]
        }
        static func fromDict(_ d: [String: Any]) -> GegnerProfilDaten {
            var p = GegnerProfilDaten.empty
            p.partei_name = d["partei_name"] as? String ?? d["gegner_name"] as? String ?? ""
            p.partei_typ = d["partei_typ"] as? String ?? "Unternehmen"
            p.partei_beschreibung = d["partei_beschreibung"] as? String ?? d["gegner_groesse"] as? String ?? d["gegner_branche"] as? String ?? ""
            p.anwalt_name = d["anwalt_name"] as? String ?? d["entscheider_name"] as? String ?? ""
            p.anwalt_kanzlei = d["anwalt_kanzlei"] as? String ?? ""
            p.anwalt_bekannt_fuer = d["anwalt_bekannt_fuer"] as? String ?? ""
            p.anwalt_stil = d["anwalt_stil"] as? String ?? d["entscheider_persoenlichkeit"] as? String ?? ""
            p.bekannte_taktiken = d["bekannte_taktiken"] as? String ?? d["verhalten_taktik"] as? String ?? ""
            p.bisherige_reaktionen = d["bisherige_reaktionen"] as? String ?? d["verhalten_verhandlung"] as? String ?? ""
            p.interessen = d["interessen"] as? String ?? d["ziel_realistisch"] as? String ?? ""
            p.schwaechen = d["schwaechen"] as? String ?? d["entscheider_schwaechen"] as? String ?? d["anwalt_schwaechen"] as? String ?? ""
            return p
        }
    }
    struct GegnerSimulationErgebnis {
        var naechsteZuege: [(zug: String, wahrscheinlichkeit: Int, verteidigung: String, dringlichkeit: String)]
        var motivation: String
        var risikobereitschaft: String
        var verhandlungstyp: String
        var schwaechen: [String]
        var hebelpunkte: [String]
        var topStrategie: String
        var warnung: String?
    }
    var body: some View {
        VStack(spacing: 20) {
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if let gp = viewModel.fall?.gegner_profil?.dictValue,
               gp["ki_zusammenfassung"] != nil || (gp["taktiken"] as? [Any])?.isEmpty == false {
                DokumentGegnerProfilPanel(profil: gp)
            }
            profilFormular
            if let sim = simulation { simulationView(sim) }
            Divider().padding(.vertical, 4)
            GegnerStrategieDashboardView(viewModel: viewModel, kiMode: kiMode)
        }
        .onAppear { hydrate() }
    }
    private var profilFormular: some View {
        VStack(spacing: 0) {
            Button { withAnimation { showForm.toggle() } } label: {
                HStack {
                    Label("Gegenpartei-Profil", systemImage: "person.fill")
                        .font(.subheadline.bold())
                    if !profil.partei_name.isEmpty {
                        Text("· \(profil.partei_name)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: showForm ? "chevron.up" : "chevron.down").font(.caption)
                }
            }
            .buttonStyle(.plain)
            .padding(14)
            if showForm {
                Divider()
                VStack(alignment: .leading, spacing: 16) {
                    formSection("Gegenpartei", symbol: "person.fill", farbe: .red) {
                        HStack {
                            profilFeld("Name / Firma", text: $profil.partei_name)
                            Picker("Typ", selection: $profil.partei_typ) {
                                ForEach(GegnerProfilDaten.typen, id: \.self) { Text($0).tag($0) }
                            }
                            .labelsHidden()
                        }
                        profilFeldMultiline("Beschreibung", text: $profil.partei_beschreibung)
                        profilFeldMultiline("Interessen & Ziele", text: $profil.interessen)
                        profilFeldMultiline("Schwächen / Verwundbarkeiten", text: $profil.schwaechen)
                    }
                    formSection("Anwalt der Gegenseite", symbol: "briefcase.fill", farbe: .blue) {
                        HStack {
                            profilFeld("Name", text: $profil.anwalt_name)
                            profilFeld("Kanzlei", text: $profil.anwalt_kanzlei)
                        }
                        HStack {
                            profilFeld("Bekannt für", text: $profil.anwalt_bekannt_fuer)
                            profilFeld("Verhandlungsstil", text: $profil.anwalt_stil)
                        }
                    }
                    formSection("Bisheriges Verhalten", symbol: "brain.head.profile", farbe: .purple) {
                        profilFeldMultiline("Bekannte Taktiken", text: $profil.bekannte_taktiken)
                        profilFeldMultiline("Bisherige Reaktionen", text: $profil.bisherige_reaktionen)
                    }
                    HStack {
                        Button {
                            Task { await profilSpeichern() }
                        } label: {
                            if speichert { ProgressView().scaleEffect(0.7) }
                            else { Label(gespeichert ? "✓ Gespeichert" : "Profil speichern", systemImage: "square.and.arrow.down") }
                        }
                        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        .disabled(speichert)
                        Spacer()
                        if kiMode {
                            Button {
                                Task { await simulationStarten() }
                            } label: {
                                if simuliert { ProgressView().scaleEffect(0.7); Text("Simuliere…") }
                                else { Label("KI-Simulation starten", systemImage: "wand.and.stars") }
                            }
                            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                            .disabled(simuliert)
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
    }
    @ViewBuilder
    private func formSection<Content: View>(_ titel: String, symbol: String, farbe: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titel, systemImage: symbol).font(.caption.bold()).foregroundStyle(farbe)
            content()
        }
    }
    private func profilFeld(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField(label, text: text).textFieldStyle(.roundedBorder).font(.caption)
        }
    }
    private func profilFeldMultiline(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField(label, text: text, axis: .vertical).lineLimit(2...4)
                .textFieldStyle(.roundedBorder).font(.caption)
        }
    }
    @ViewBuilder
    private func simulationView(_ sim: GegnerSimulationErgebnis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let w = sim.warnung, !w.isEmpty {
                Label(w, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
                    .padding(10).background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            if !sim.naechsteZuege.isEmpty {
                Text("Nächste Schachzüge").font(.subheadline.bold())
                ForEach(Array(sim.naechsteZuege.enumerated()), id: \.offset) { _, z in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(z.zug).font(.caption.bold())
                            Spacer()
                            Text("\(z.wahrscheinlichkeit)% · \(z.dringlichkeit)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Text("Verteidigung: \(z.verteidigung)").font(.caption2)
                    }
                    .padding(10)
                    .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            Text("Psychologisches Profil").font(.subheadline.bold())
            Text("Motivation: \(sim.motivation)").font(.caption)
            Text("Risiko: \(sim.risikobereitschaft) · Typ: \(sim.verhandlungstyp)").font(.caption2)
            if !sim.hebelpunkte.isEmpty {
                Text("Hebelpunkte: \(sim.hebelpunkte.joined(separator: "; "))").font(.caption2)
            }
            if !sim.topStrategie.isEmpty {
                Label("Top-Strategie: \(sim.topStrategie)", systemImage: "scope").font(.caption)
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
    private func hydrate() {
        guard let gp = viewModel.fall?.gegner_profil?.dictValue else { return }
        profil = GegnerProfilDaten.fromDict(gp)
        if let simDict = gp["simulation"] as? [String: Any] {
            simulation = parseSimulation(simDict)
            showForm = false
        }
    }
    private func profilSpeichern() async {
        guard var fall = viewModel.fall else { return }
        speichert = true
        defer { speichert = false }
        var gp = fall.gegner_profil?.dictValue ?? [:]
        for (k, v) in profil.asDict() { gp[k] = v }
        if let sim = simulation { gp["simulation"] = simDict(sim) }
        fall.gegner_profil = AnyCodable(gp)
        do {
            let saved = try await Services.cases.update(id: viewModel.caseId, entity: fall)
            await MainActor.run {
                viewModel.fall = saved
                gespeichert = true
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { gespeichert = false }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func simulationStarten() async {
        guard let fall = viewModel.fall, kiMode else { return }
        simuliert = true
        fehler = nil
        defer { simuliert = false }
        let prompt = """
        Du bist ein erfahrener Prozessstratege und Psychologe. Analysiere die Gegenpartei und erstelle eine taktische Simulation.
        FALLKONTEXT:
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "")
        Prozessziel: \(fall.prozessziel ?? "")
        Instanz: \(fall.instanz.rawValue)
        GEGENPARTEI-PROFIL:
        Name: \(profil.partei_name)
        Typ: \(profil.partei_typ)
        Beschreibung: \(profil.partei_beschreibung)
        Anwalt: \(profil.anwalt_name) / \(profil.anwalt_kanzlei)
        Taktiken: \(profil.bekannte_taktiken)
        Interessen: \(profil.interessen)
        Schwächen: \(profil.schwaechen)
        Simuliere 3 nächste Schachzüge, Verteidigung, psychologisches Profil, Hebelpunkte, Top-Strategie.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "naechste_zuege": ["type": "array", "items": ["type": "object", "properties": [
                    "zug": ["type": "string"], "wahrscheinlichkeit": ["type": "number"],
                    "begruendung": ["type": "string"], "verteidigung": ["type": "string"],
                    "dringlichkeit": ["type": "string"]
                ]]],
                "psycho_profil": ["type": "object", "properties": [
                    "motivation": ["type": "string"], "risikobereitschaft": ["type": "string"],
                    "verhandlungstyp": ["type": "string"],
                    "schwaechen": ["type": "array", "items": ["type": "string"]],
                    "hebelpunkte": ["type": "array", "items": ["type": "string"]]
                ]],
                "top_strategie": ["type": "object", "properties": [
                    "name": ["type": "string"], "beschreibung": ["type": "string"],
                    "massnahmen": ["type": "array", "items": ["type": "string"]],
                    "erfolgsquote": ["type": "number"]
                ]],
                "warnung": ["type": "string"]
            ] as [String: Any]
        ] as [String: Any]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId, logKiName: "Gegner-Profil Simulation"
            )
            let dict = try KIJson.requireObject(response, kontext: "Gegner-Simulation")
            let sim = parseSimulation(dict)
            await MainActor.run {
                simulation = sim
                showForm = false
            }
            guard var fallUpd = viewModel.fall else { return }
            var gp = fallUpd.gegner_profil?.dictValue ?? profil.asDict()
            for (k, v) in profil.asDict() { gp[k] = v }
            gp["simulation"] = simDict(sim)
            fallUpd.gegner_profil = AnyCodable(gp)
            let saved = try await Services.cases.update(id: viewModel.caseId, entity: fallUpd)
            await MainActor.run { viewModel.fall = saved }
            Task { await LexaraKIZusatzAnalyseService.ergaenzeAnalyse(viewModel: viewModel, quelle: .berater, kiMode: kiMode) }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func parseSimulation(_ dict: [String: Any]) -> GegnerSimulationErgebnis {
        let zuege = (dict["naechste_zuege"] as? [[String: Any]] ?? []).map {
            (zug: $0["zug"] as? String ?? "",
             wahrscheinlichkeit: KIJson.intValue($0["wahrscheinlichkeit"]) ?? 0,
             verteidigung: $0["verteidigung"] as? String ?? "",
             dringlichkeit: $0["dringlichkeit"] as? String ?? "mittel")
        }
        let psycho = dict["psycho_profil"] as? [String: Any] ?? [:]
        let top = dict["top_strategie"] as? [String: Any] ?? [:]
        return GegnerSimulationErgebnis(
            naechsteZuege: zuege,
            motivation: psycho["motivation"] as? String ?? "",
            risikobereitschaft: psycho["risikobereitschaft"] as? String ?? "",
            verhandlungstyp: psycho["verhandlungstyp"] as? String ?? "",
            schwaechen: psycho["schwaechen"] as? [String] ?? [],
            hebelpunkte: psycho["hebelpunkte"] as? [String] ?? [],
            topStrategie: [top["name"] as? String, top["beschreibung"] as? String].compactMap { $0 }.joined(separator: ": "),
            warnung: dict["warnung"] as? String
        )
    }
    private func simDict(_ sim: GegnerSimulationErgebnis) -> [String: Any] {
        [
            "naechste_zuege": sim.naechsteZuege.map { [
                "zug": $0.zug, "wahrscheinlichkeit": $0.wahrscheinlichkeit,
                "verteidigung": $0.verteidigung, "dringlichkeit": $0.dringlichkeit
            ]},
            "psycho_profil": [
                "motivation": sim.motivation, "risikobereitschaft": sim.risikobereitschaft,
                "verhandlungstyp": sim.verhandlungstyp,
                "schwaechen": sim.schwaechen, "hebelpunkte": sim.hebelpunkte
            ],
            "top_strategie": ["name": sim.topStrategie, "beschreibung": sim.topStrategie],
            "warnung": sim.warnung ?? ""
        ]
    }
}
