//
//  StrategosView.swift
//  Strategos: Szenario-Analyse + Vertragsklauseln-Auswirkungen (Kurz/Mittel/Lang).
//  Entspricht src/pages/Strategos.jsx + EnterpriseShell.jsx.
//

import SwiftUI

struct StrategosView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var scenarios: [StrategosScenario] = []
    @State private var loopholes: [LegalLoophole] = []
    @State private var selectedScenario: StrategosScenario?
    @State private var showNew = false
    @State private var contractText: String = ""
    @State private var impacts: [StrategosImpact] = []
    @State private var analyzing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                scenarioGrid
                Divider().padding(.vertical, 8)
                contractAnalyzer
                if !impacts.isEmpty {
                    impactSection
                }
                Divider().padding(.vertical, 8)
                loopholeSection
            }
            .padding()
        }
        .navigationTitle("Strategos")
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Strategos").font(.title.weight(.semibold))
            Text("Vertragsanalyse, Szenarien und identifizierte Hebel.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: - Szenarien Grid
    private var scenarioGrid: some View {
        VStack(alignment: .leading) {
            Text("Szenarien").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                ForEach(scenarios) { s in scenarioCard(s) }
            }
        }
    }

    private func scenarioCard(_ s: StrategosScenario) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(s.szenarioTyp.label.uppercased())
                .font(.caption2).foregroundStyle(.secondary)
            Text(s.title).font(.subheadline.weight(.medium)).lineLimit(2)
            ProgressView(value: Double(s.enterpriseStep) / 6.0)
            Text("Schritt \(s.enterpriseStep)/6").font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Vertragsanalyse
    private var contractAnalyzer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vertragsklauseln analysieren").font(.headline)
            Text("Füge eine Klausel ein. Strategos analysiert kurz-, mittel- und langfristige Auswirkungen auf alle Abteilungen.")
                .font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $contractText)
                .frame(minHeight: 140)
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
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
        }
    }

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auswirkungen").font(.headline)
            ForEach(StrategosHorizont.allCases, id: \.self) { h in
                let group = impacts.filter { $0.horizont == h }
                if !group.isEmpty {
                    Text(h.rawValue).font(.subheadline.weight(.semibold)).padding(.top, 4)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                        ForEach(group) { i in impactCard(i) }
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
                Text(String(format: "%.0f / 10", i.schwere))
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(severityColor(i.schwere).opacity(0.2), in: Capsule())
                    .foregroundStyle(severityColor(i.schwere))
            }
            Text(i.beschreibung).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func severityColor(_ s: Double) -> Color {
        if s >= 7 { return .red }
        if s >= 4 { return .orange }
        return .green
    }

    // MARK: - Schlupflöcher
    private var loopholeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identifizierte Hebel & Lücken").font(.headline)
            if loopholes.isEmpty {
                Text("Noch keine Hebel hinterlegt.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(loopholes) { l in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(l.gesetz) \(l.paragraph ?? "")")
                                .font(.caption.monospaced())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
                            Text(l.aktiv ? "Aktiv" : "Geschlossen")
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background((l.aktiv ? Color.green : Color.gray).opacity(0.15), in: Capsule())
                        }
                        Text(l.titel).font(.subheadline.weight(.medium))
                        Text(l.beschreibung).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Logik
    @MainActor
    private func reload() async {
        scenarios = (try? await cloudKit.fetch(StrategosScenario.self)) ?? []
        loopholes = (try? await cloudKit.fetch(LegalLoophole.self)) ?? []
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
                            "abteilung":   ["type": "string"],
                            "horizont":    ["type": "string", "enum": ["Kurzfristig","Mittelfristig","Langfristig"]],
                            "beschreibung": ["type": "string"],
                            "schwere":     ["type": "number"]
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
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Vertragsanalyse")
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

struct NewScenarioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var typ: SzenarioTyp = .sonstiges
    var onCreate: (StrategosScenario) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titel", text: $title)
                Picker("Typ", selection: $typ) {
                    ForEach(SzenarioTyp.allCases, id: \.self) { t in Text(t.label).tag(t) }
                }
            }
            .navigationTitle("Neues Szenario")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var s = StrategosScenario(title: title)
                        s.szenarioTyp = typ
                        onCreate(s); dismiss()
                    }.disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}
