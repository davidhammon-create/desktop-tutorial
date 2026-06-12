//
//  StrategosView.swift
//  Strategos: Szenario-Analyse (6-Schritt-Wizard) + Vertragsklauseln-Analyse
//  + Gegnerverhalten-Tracking + Identifizierte Hebel.
//  Entspricht src/pages/Strategos.jsx + EnterpriseShell.jsx (base44).
//

import SwiftUI

struct StrategosView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var scenarios: [StrategosScenario] = []
    @State private var loopholes: [LegalLoophole] = []
    @State private var cases: [Case] = []
    @State private var selectedScenario: StrategosScenario?
    @State private var showNew = false
    @State private var contractText: String = ""
    @State private var impacts: [StrategosImpact] = []
    @State private var analyzing = false
    @State private var selectedCaseForGegner: String?
    @State private var gegnerItems: [GegnerVerhalten] = []
    @State private var activeTab: StrategosTab = .szenarien

    enum StrategosTab: String, CaseIterable {
        case szenarien    = "Szenarien"
        case vertragsanalyse = "Vertragsanalyse"
        case gegnerverhalten = "Gegnerverhalten"
        case hebel        = "Hebel & Lücken"

        var icon: String {
            switch self {
            case .szenarien:      return "square.grid.2x2"
            case .vertragsanalyse: return "doc.text.magnifyingglass"
            case .gegnerverhalten: return "shield.lefthalf.filled"
            case .hebel:          return "key.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Interner Tab-Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(StrategosTab.allCases, id: \.self) { t in
                        Button { activeTab = t } label: {
                            Label(t.rawValue, systemImage: t.icon)
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(activeTab == t
                                    ? Color.accentColor.opacity(0.15) : .clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(activeTab == t ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
            }
            Divider()

            // Inhalt
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeTab {
                    case .szenarien:       szenarienTab
                    case .vertragsanalyse: vertragsanalyseTab
                    case .gegnerverhalten: gegnerVerhaltenTab
                    case .hebel:           hebelTab
                    }
                }
                .padding()
                .animation(.default, value: activeTab)
            }
        }
        .navigationTitle("Strategos")
        .navigationDestination(for: StrategosScenario.self) { s in
            scenarioDetailDestination(for: s)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neues Szenario", systemImage: "plus") }
            }
        }
        .task { await reload() }
        .sheet(isPresented: $showNew) {
            NewScenarioSheet { s in
                Task { _ = try? await cloudKit.save(s); await reload() }
            }
        }
    }

    // MARK: - Szenarien Tab

    private var szenarienTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Strategos").font(.title.weight(.semibold))
                Text("Szenario-Planung, Vertragsanalyse und identifizierte Hebel.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if scenarios.isEmpty {
                ContentUnavailableView(
                    "Noch keine Szenarien",
                    systemImage: "square.grid.2x2",
                    description: Text("Erstelle ein Szenario für die 6-stufige Enterprise-Analyse."))
                    .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                    ForEach(scenarios) { s in
                        NavigationLink(value: s) {
                            scenarioCard(s)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func scenarioCard(_ s: StrategosScenario) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.szenarioTyp.label.uppercased())
                        .font(.caption2).foregroundStyle(.secondary)
                    Text(s.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                }
                Spacer()
                // Status-Badge
                Text(s.status.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(statusColor(s.status).opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor(s.status))
            }

            // Schritt-Fortschritt
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(1...6, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(step <= s.enterpriseStep
                                ? Color.accentColor
                                : Color.gray.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                Text("Schritt \(s.enterpriseStep) / 6 · \(Int(Double(s.enterpriseStep-1)/5.0 * 100))% abgeschlossen")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            // Rechtsgebiet
            if let rg = s.rechtsgebiet {
                Label(rg, systemImage: "folder").font(.caption2).foregroundStyle(.secondary)
            }

            // Weiter-Pfeil
            HStack {
                Spacer()
                Label("Öffnen", systemImage: "chevron.right")
                    .font(.caption).foregroundStyle(.accentColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statusColor(_ s: SzenarioStatus) -> Color {
        switch s {
        case .entwurf:    return .gray
        case .analyse:    return .blue
        case .ergebnis:   return .green
        case .archiviert: return .orange
        }
    }

    @ViewBuilder
    private func scenarioDetailDestination(for s: StrategosScenario) -> some View {
        // Wrap in Binding to allow wizard saves to propagate
        let idx = scenarios.firstIndex(where: { $0.id == s.id })
        if let idx {
            StrategosScenarioDetailView(
                scenario: Binding(
                    get: { scenarios[idx] },
                    set: { scenarios[idx] = $0 }
                ),
                onSave: { updated in
                    Task {
                        _ = try? await cloudKit.save(updated)
                        await reload()
                    }
                }
            )
        } else {
            // Fallback für direkte Navigation (z.B. über NavigationStack)
            let bound = Binding.constant(s)
            StrategosScenarioDetailView(scenario: bound, onSave: { updated in
                Task { _ = try? await cloudKit.save(updated); await reload() }
            })
        }
    }

    // MARK: - Vertragsanalyse Tab

    private var vertragsanalyseTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vertragsklauseln analysieren").font(.title2.weight(.semibold))
                Text("Füge eine Klausel ein. Strategos analysiert kurz-, mittel- und langfristige Auswirkungen auf alle Abteilungen.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            TextEditor(text: $contractText)
                .frame(minHeight: 160)
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2))
                )
            if contractText.isEmpty {
                Text("Beispiel: „Der Auftragnehmer verpflichtet sich, Schadensersatz bis zum dreifachen Auftragswert zu leisten."")
                    .font(.caption2).foregroundStyle(.secondary.opacity(0.7))
            }
            HStack {
                Spacer()
                Button {
                    Task { await analyzeContract() }
                } label: {
                    Label(analyzing ? "Analysiere…" : "Analyse starten", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(contractText.trimmingCharacters(in: .whitespaces).isEmpty || analyzing)
            }

            if !impacts.isEmpty {
                impactSection
            }
        }
    }

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Auswirkungen nach Zeithorizont & Abteilung")
                .font(.headline)
            ForEach(StrategosHorizont.allCases, id: \.self) { h in
                let group = impacts.filter { $0.horizont == h }
                if !group.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(h.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(group.count) Abteilungen betroffen")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                            ForEach(group) { i in impactCard(i) }
                        }
                    }
                }
            }
        }
    }

    private func impactCard(_ i: StrategosImpact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(i.abteilung).font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f/10", i.schwere))
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(severityColor(i.schwere).opacity(0.15), in: Capsule())
                    .foregroundStyle(severityColor(i.schwere))
            }
            ProgressView(value: i.schwere / 10).tint(severityColor(i.schwere))
            Text(i.beschreibung).font(.caption).foregroundStyle(.secondary).lineLimit(3)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func severityColor(_ s: Double) -> Color {
        if s >= 7 { return .red }
        if s >= 4 { return .orange }
        return .green
    }

    // MARK: - Gegnerverhalten Tab

    private var gegnerVerhaltenTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gegnerverhalten").font(.title2.weight(.semibold))
                Text("Taktiken, Reaktionsmuster und Verhaltensanalyse der Gegenseite – fallübergreifend.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            // Case-Picker
            if cases.isEmpty {
                Label("Keine Fälle vorhanden. Lege zuerst Fälle in LEXARA an.",
                      systemImage: "folder.badge.plus")
                    .font(.caption).foregroundStyle(.orange)
            } else {
                HStack {
                    Text("Fall auswählen:").font(.caption).foregroundStyle(.secondary)
                    Picker("Fall", selection: $selectedCaseForGegner) {
                        Text("– Bitte wählen –").tag(String?.none)
                        ForEach(cases) { c in
                            Text(c.fallname).tag(Optional(c.id))
                        }
                    }
                    .onChange(of: selectedCaseForGegner) { _, id in
                        Task { await loadGegner(caseId: id) }
                    }
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            if let caseId = selectedCaseForGegner,
               let c = cases.first(where: { $0.id == caseId }) {
                GegnerVerhaltenTabView(caseId: caseId, caseEntity: c)
            } else {
                Text("Wähle einen Fall um das Gegnerverhalten anzuzeigen.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Hebel Tab

    private var hebelTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Identifizierte Hebel & Schlupflöcher").font(.title2.weight(.semibold))
                Text("Gesetzliche Lücken und strategische Hebel die genutzt werden können.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if loopholes.isEmpty {
                ContentUnavailableView("Keine Hebel hinterlegt",
                    systemImage: "key.slash",
                    description: Text("Hinterlege strategische Hebel und Gesetzeslücken."))
                    .padding(.vertical, 40)
            } else {
                ForEach(loopholes) { l in
                    loopholeCard(l)
                }
            }
        }
    }

    private func loopholeCard(_ l: LegalLoophole) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(l.gesetz) \(l.paragraph ?? "")")
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
                Text(l.aktiv ? "Aktiv" : "Geschlossen")
                    .font(.caption2)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background((l.aktiv ? Color.green : Color.gray).opacity(0.15), in: Capsule())
                    .foregroundStyle(l.aktiv ? .green : .secondary)
                Spacer()
                if let rg = l.rechtsgebiet {
                    Text(rg).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(l.titel).font(.subheadline.weight(.semibold))
            Text(l.beschreibung).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            if let strat = l.gegenstrategien {
                Label(strat, systemImage: "lightbulb.fill")
                    .font(.caption).foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logik

    @MainActor
    private func reload() async {
        scenarios = (try? await cloudKit.fetch(StrategosScenario.self)) ?? []
        loopholes = (try? await cloudKit.fetch(LegalLoophole.self)) ?? []
        cases     = (try? await cloudKit.fetch(Case.self)) ?? []
    }

    @MainActor
    private func loadGegner(caseId: String?) async {
        guard let caseId else { gegnerItems = []; return }
        let pred = NSPredicate(format: "case_id == %@", caseId)
        gegnerItems = (try? await cloudKit.fetch(GegnerVerhalten.self, predicate: pred)) ?? []
    }

    @MainActor
    private func analyzeContract() async {
        analyzing = true
        defer { analyzing = false }
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "impacts": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "abteilung":    ["type": "string"],
                            "horizont":     ["type": "string",
                                             "enum": ["Kurzfristig","Mittelfristig","Langfristig"]],
                            "beschreibung": ["type": "string"],
                            "schwere":      ["type": "number"]
                        ],
                        "required": ["abteilung","horizont","beschreibung","schwere"]
                    ]
                ]
            ],
            "required": ["impacts"]
        ]
        let prompt = """
        Analysiere die folgende Vertragsklausel auf Auswirkungen für jede betroffene Abteilung \
        (Finanzen, Recht, HR, IT, Vertrieb, Compliance, Geschäftsführung). Lege je Abteilung \
        bis zu drei Auswirkungen in den Horizonten Kurzfristig (0-6 Monate), Mittelfristig \
        (6-24 Monate), Langfristig (>24 Monate) an. Schwere skaliert 0..10.

        KLAUSEL:
        \(contractText)
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema,
                                              context: "Strategos.Vertragsanalyse")
        switch res {
        case .success(let value):
            guard let dict = value as? [String: Any],
                  let arr = dict["impacts"] as? [[String: Any]] else { return }
            impacts = arr.compactMap { raw in
                guard let ab = raw["abteilung"] as? String,
                      let hRaw = raw["horizont"] as? String,
                      let h = StrategosHorizont(rawValue: hRaw),
                      let b = raw["beschreibung"] as? String,
                      let s = raw["schwere"] as? Double else { return nil }
                return StrategosImpact(abteilung: ab, horizont: h, beschreibung: b, schwere: s)
            }
        case .failure:
            impacts = []
        }
    }
}

// MARK: - Neues Szenario Sheet

struct NewScenarioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var typ: SzenarioTyp = .sonstiges
    @State private var rechtsgebiet = ""
    var onCreate: (StrategosScenario) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Grunddaten") {
                    TextField("Titel *", text: $title)
                    Picker("Typ", selection: $typ) {
                        ForEach(SzenarioTyp.allCases, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }
                    TextField("Rechtsgebiet (optional)", text: $rechtsgebiet)
                }
                Section {
                    Text("Nach dem Anlegen öffnet sich der 6-stufige Enterprise-Wizard.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Neues Szenario")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var s = StrategosScenario(title: title)
                        s.szenarioTyp = typ
                        s.rechtsgebiet = rechtsgebiet.isEmpty ? nil : rechtsgebiet
                        onCreate(s)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
