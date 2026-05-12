//
//  TabGesamtbewertungView.swift
//  Konversion von src/components/lexara/TabGesamtbewertung.jsx (683 Zeilen) nach SwiftUI.
//  Algorithmische Prognose + KI-Strategieanalyse + Break-Even-Berechnung
//  und Score-Vergleich (manuell vs. KI).
//

import SwiftUI

// MARK: - Laienerklärungen für jeden Berechnungsschritt
fileprivate let SIMPLE_EXPLANATIONS: [String: String] = [
    "Prior-Wahrscheinlichkeit (Basisrate)":
        "💡 Bevor wir irgendetwas wissen, fragen wir: Wie oft gewinnt der Kläger statistisch in diesem Rechtsgebiet?",
    "Argumentationsbilanz":
        "💡 Wie stark sind unsere Argumente vs. die gegnerischen? Eine Waage.",
    "Beweisqualität & -quantität":
        "💡 Mehr gute Beweise = bessere Chancen, aber abnehmender Grenznutzen.",
    "Richter-Statistik (Bayesianisch)":
        "💡 Wir passen die Prognose an die Richter-Klägerquote an.",
    "Richter-Statistik":
        "💡 Kein Richter bekannt – Prognose unverändert.",
    "Fristenrisiko (Malus)":
        "💡 Versäumte Fristen schaden erheblich.",
    "Vergleichsangebot-Signal":
        "💡 Ein hohes Angebot zeigt gegnerische Unsicherheit.",
    "Finale Wahrscheinlichkeit (Logistische Transformation)":
        "💡 Logistische Funktion → Prozentzahl 0–100%.",
    "90%-Konfidenzintervall (Fehlerfortpflanzung)":
        "💡 Realistischer Korridor mit 90% Wahrscheinlichkeit.",
]

// MARK: - KI-Strategieanalyse-Modell
fileprivate struct GesamtKIAnalyse: Hashable {
    var erfolgswahrscheinlichkeit: Int = 50
    var begruendung: String?
    var unsereTaktiken: [TaktikItem] = []
    var gegnerStrategien: [GegnerItem] = []
    var gegnerAsse: [TaktikItem] = []
    var unsereSchwachstellen: [SchwachItem] = []
    var gesamtstrategie: String?
    var gegnerArgumente: [GegnerArg] = []
    var gegnerVorgehen: [VorgehenStep] = []
}
fileprivate struct TaktikItem: Identifiable, Hashable {
    let id = UUID(); var titel: String; var beschreibung: String
}
fileprivate struct GegnerItem: Identifiable, Hashable {
    let id = UUID(); var titel: String; var beschreibung: String; var gefahr: String
}
fileprivate struct SchwachItem: Identifiable, Hashable {
    let id = UUID(); var titel: String; var risiko: String?
}
fileprivate struct GegnerArg: Identifiable, Hashable {
    let id = UUID(); var argument: String; var paragraphen: String?; var staerke: String; var unsereAntwort: String?
}
fileprivate struct VorgehenStep: Identifiable, Hashable {
    let id = UUID(); var phase: String; var beschreibung: String; var risiko: String?
}

// MARK: - Hauptansicht

struct TabGesamtbewertungView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var persons: [Person] = []
    @State private var deadlines: [Deadline] = []
    @State private var loaded = false
    @State private var analyzing = false
    @State private var kiAnalyse: GesamtKIAnalyse?
    @State private var algoResult: PrognoseResult?
    @State private var breakEven: BreakEvenResult?
    @State private var showAlgoSteps = false

    var body: some View {
        ScrollView {
            if !loaded {
                ProgressView().padding(40)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    if let r = algoResult { algoStepsCard(r) }
                    scoreVergleichCard
                    kiAnalyseCard
                }
                .padding()
            }
        }
        .navigationTitle("Gesamtbewertung")
        .task { await load() }
    }

    // MARK: Sub-Views

    private var headerCard: some View {
        let score = algoResult?.score ?? 0
        let ci = algoResult.map { "[\($0.ciLow)%–\($0.ciHigh)%]" } ?? ""
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GESAMTBEWERTUNG · \(caseData?.fallname ?? "Fall")")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline) {
                    Text("\(score)%").font(.system(size: 48, weight: .bold))
                    Text("90%-CI: \(ci)").font(.caption).foregroundStyle(.secondary)
                }
                Text("\(args.count) Argumente · \(evidence.count) Beweise · \(args.filter{$0.side == .eigen}.count) eigen · \(args.filter{$0.side == .gegner}.count) Gegner")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Label("Algorithmus", systemImage: "function")
                .font(.caption)
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color.black, in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
    }

    private func algoStepsCard(_ result: PrognoseResult) -> some View {
        let grouped = Dictionary(grouping: result.steps, by: { $0.kategorie })
        return GroupBox {
            DisclosureGroup(isExpanded: $showAlgoSteps) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(grouped.keys), id: \.self) { kat in
                        VStack(alignment: .leading) {
                            Text(kat).font(.caption).bold().foregroundStyle(.secondary)
                            ForEach(grouped[kat] ?? []) { step in
                                AlgoStepRow(step: step)
                            }
                        }
                    }
                    if let be = breakEven { breakEvenSection(be) }
                }
            } label: {
                HStack {
                    Label("Berechnungsschritte (aufklappbar)", systemImage: "function").bold().font(.callout)
                    Spacer()
                    Text("σ=\(String(format: "%.1f", result.sigma * 100))% Unsicherheit").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func breakEvenSection(_ be: BreakEvenResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Break-Even-Schwelle").font(.caption).foregroundStyle(.secondary)
                    Text(be.formel).font(.caption2).monospaced().foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(be.breakEvenPct ?? 0)%").font(.title).bold().foregroundStyle(.orange)
                    Text("Mindest-Erfolgsquote").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text("💡 \(be.empfehlung)")
                .font(.caption)
                .padding(8)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            if !be.zusatzoptionen.isEmpty {
                Text("⚡ Zusätzliche Klageoptions-Szenarien")
                    .font(.caption).bold().foregroundStyle(.secondary)
                ForEach(be.zusatzoptionen) { opt in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("\(opt.symbol) \(opt.titel)").font(.caption).bold()
                            Text(opt.beschreibung).font(.caption2).foregroundStyle(.secondary)
                            Text(opt.rechtsgrundlage).font(.caption2).monospaced().foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(opt.breakEvenPct)%").font(.headline).foregroundStyle(.green)
                            Text("Break-Even").font(.caption2).foregroundStyle(.secondary)
                            Text(opt.basis).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var scoreVergleichCard: some View {
        let eigene = args.filter { $0.side == .eigen }
        let gegner = args.filter { $0.side == .gegner }
        let manEigen = avg(eigene.compactMap { $0.strength })
        let manGegner = avg(gegner.compactMap { $0.strength })
        let manEv = avg(evidence.compactMap { $0.weight })
        let kiEigen = avg(eigene.compactMap { $0.kiStrength })
        let kiGegner = avg(gegner.compactMap { $0.kiStrength })
        let kiEv = avg(evidence.compactMap { $0.kiWeight })
        let hasKi = eigene.contains(where: { $0.kiStrength != nil }) || evidence.contains(where: { $0.kiWeight != nil })

        let manScore = (eigene.count + evidence.count) == 0 ? 0 :
            manEigen * 0.4 + max(0, 10 - manGegner) * 0.3 + manEv * 0.3
        let kiScore: Double? = hasKi ? (kiEigen * 0.4 + max(0, 10 - kiGegner) * 0.3 + kiEv * 0.3) : nil

        return GroupBox("Gewichtungsvergleich") {
            VStack(spacing: 12) {
                HStack {
                    scoreCard(label: "Eigene Argumente", manual: manEigen, ki: hasKi ? kiEigen : nil, icon: "scalemass")
                    scoreCard(label: "Gegner-Argumente", manual: manGegner, ki: hasKi ? kiGegner : nil, icon: "exclamationmark.shield")
                    scoreCard(label: "Beweise", manual: manEv, ki: hasKi ? kiEv : nil, icon: "doc.text")
                }
                Divider()
                HStack {
                    VStack {
                        Text("Gesamtscore manuell").font(.caption).foregroundStyle(.secondary)
                        Text("\(manScore, specifier: "%.1f")").font(.largeTitle).bold().foregroundStyle(.blue)
                        Text("von 10").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    if let ks = kiScore {
                        VStack {
                            Text("Gesamtscore KI").font(.caption).foregroundStyle(.purple)
                            Text("\(ks, specifier: "%.1f")").font(.largeTitle).bold().foregroundStyle(.purple)
                            Text("von 10").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack {
                            Text("KI-Gewichtung fehlt").font(.caption).foregroundStyle(.secondary)
                            Text("Nutze KI-Gewichtung in Tab 2 & 3").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func scoreCard(label: String, manual: Double, ki: Double?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.caption).bold()
            HStack {
                Text("Manuell").font(.caption2).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                ProgressView(value: manual / 10).tint(.blue)
                Text("\(manual, specifier: "%.1f")/10").font(.caption2).bold().frame(width: 50, alignment: .trailing)
            }
            if let k = ki {
                HStack {
                    Text("KI").font(.caption2).foregroundStyle(.purple).frame(width: 60, alignment: .leading)
                    ProgressView(value: k / 10).tint(.purple)
                    Text("\(k, specifier: "%.1f")/10").font(.caption2).bold().foregroundStyle(.purple).frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var kiAnalyseCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Label("KI-Strategieanalyse", systemImage: "brain.head.profile").bold()
                        Text("Liefert Rspr., Taktiken & Gegnerstrategien – keine eigene Risikoberechnung")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await runKiAnalyse() }
                    } label: {
                        Label(analyzing ? "Analysiere…" : (kiAnalyse != nil ? "Neu analysieren" : "Analyse starten"),
                              systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(analyzing)
                }

                if let a = kiAnalyse {
                    kiAnalyseInhalt(a)
                } else if !analyzing {
                    Text("Starte die KI-Analyse für eine vollständige strategische Bewertung")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func kiAnalyseInhalt(_ a: GesamtKIAnalyse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("KI-Erfolgswahrscheinlichkeit").font(.caption).foregroundStyle(.secondary)
                    Text("\(a.erfolgswahrscheinlichkeit)%").font(.system(size: 40, weight: .bold))
                }
                Spacer()
                ProgressView(value: Double(a.erfolgswahrscheinlichkeit), total: 100).tint(.green).frame(width: 200)
            }
            .padding()
            .background(LinearGradient(colors: [.black, .gray], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            if let beg = a.begruendung { Text(beg).font(.caption) }
            if let s = a.gesamtstrategie {
                VStack(alignment: .leading) {
                    Text("🎯 Empfohlene Gesamtstrategie").font(.caption).bold().foregroundStyle(.blue)
                    Text(s).font(.subheadline)
                }
                .padding()
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            if !a.unsereTaktiken.isEmpty {
                section("⚔️ Unsere Taktiken", color: .green) {
                    ForEach(a.unsereTaktiken) { t in
                        VStack(alignment: .leading) {
                            Label(t.titel, systemImage: "target").bold().font(.caption)
                            Text(t.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerStrategien.isEmpty {
                section("🛡️ Erwartete Gegnerstrategien", color: .red) {
                    ForEach(a.gegnerStrategien) { g in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(g.titel).bold().font(.caption)
                                Text(g.gefahr).font(.caption2).bold()
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(gefahrColor(g.gefahr).opacity(0.2), in: Capsule())
                                    .foregroundStyle(gefahrColor(g.gefahr))
                            }
                            Text(g.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(gefahrColor(g.gefahr).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerAsse.isEmpty {
                section("🃏 Asse im Ärmel des Gegners", color: .red) {
                    ForEach(a.gegnerAsse) { ace in
                        VStack(alignment: .leading) {
                            Label(ace.titel, systemImage: "bolt").bold().font(.caption).foregroundStyle(.red)
                            Text(ace.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.unsereSchwachstellen.isEmpty {
                section("⚠️ Unsere kritischen Schwachstellen", color: .orange) {
                    ForEach(a.unsereSchwachstellen) { sw in
                        VStack(alignment: .leading) {
                            Label(sw.titel, systemImage: "exclamationmark.triangle").bold().font(.caption).foregroundStyle(.orange)
                            if let r = sw.risiko { Text(r).font(.caption2).foregroundStyle(.secondary) }
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerArgumente.isEmpty {
                section("⚖️ Konkrete Argumente der Gegenseite", color: .gray) {
                    ForEach(a.gegnerArgumente) { g in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(g.argument).bold().font(.caption)
                                if let p = g.paragraphen {
                                    Text(p).font(.caption2).monospaced()
                                        .padding(.horizontal, 4)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 3))
                                }
                                Spacer()
                                Text(g.staerke.uppercased()).font(.caption2).bold()
                                    .foregroundStyle(gefahrColor(g.staerke))
                            }
                            if let ant = g.unsereAntwort {
                                Text("Unsere Antwort: \(ant)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .background(gefahrColor(g.staerke).opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerVorgehen.isEmpty {
                section("🗂️ Vorgehensweise der Gegenseite", color: .gray) {
                    ForEach(Array(a.gegnerVorgehen.enumerated()), id: \.element.id) { (i, v) in
                        HStack(alignment: .top) {
                            Text("\(i+1)").bold().font(.caption2)
                                .padding(6)
                                .background(Circle().stroke(gefahrColor(v.risiko ?? "")))
                                .foregroundStyle(gefahrColor(v.risiko ?? ""))
                            VStack(alignment: .leading) {
                                Text(v.phase).bold().font(.caption)
                                Text(v.beschreibung).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let r = v.risiko { Text(r.uppercased()).font(.caption2).bold().foregroundStyle(gefahrColor(r)) }
                        }
                        .padding(8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, color: Color,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).bold().foregroundStyle(color)
            content()
        }
    }

    private func gefahrColor(_ g: String) -> Color {
        switch g.lowercased() {
        case "hoch": return .red
        case "mittel": return .orange
        case "niedrig": return .green
        default: return .gray
        }
    }

    // MARK: Datenoperationen

    private func avg(_ arr: [Double]) -> Double {
        guard !arr.isEmpty else { return 0 }
        return arr.reduce(0, +) / Double(arr.count)
    }

    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        async let a = cloudKit.fetch(Argument.self, predicate: pred)
        async let e = cloudKit.fetch(Evidence.self, predicate: pred)
        async let p = cloudKit.fetch(Person.self, predicate: pred)
        async let d = cloudKit.fetch(Deadline.self, predicate: pred)
        args = (try? await a) ?? []
        evidence = (try? await e) ?? []
        persons = (try? await p) ?? []
        deadlines = (try? await d) ?? []
        // Algorithmus berechnen
        let input = PrognoseInput(args: args, evidence: evidence,
                                  deadlines: deadlines, persons: persons,
                                  caseData: caseData)
        algoResult = LegalAlgorithms.computePrognose(input)
        breakEven = LegalAlgorithms.computeBreakEven(caseData: caseData)
        loaded = true
    }

    private func runKiAnalyse() async {
        analyzing = true; defer { analyzing = false }
        let eigArg = args.filter { $0.side == .eigen }.prefix(5).map {
            "\"\($0.title)\" Stärke:\(Int($0.kiStrength ?? $0.strength ?? 5))/10"
        }.joined(separator: ", ")
        let gegArg = args.filter { $0.side == .gegner }.prefix(5).map {
            "\"\($0.title)\" Stärke:\(Int($0.kiStrength ?? $0.strength ?? 5))/10"
        }.joined(separator: ", ")
        let evList = evidence.prefix(5).map {
            "\"\($0.title)\" Gewicht:\(Int($0.kiWeight ?? $0.weight ?? 5))/10"
        }.joined(separator: ", ")

        let prompt = """
        Du bist erfahrener Strafverteidiger. Analysiere diesen Fall tiefgehend.

        Fall: \(caseData?.fallname ?? "") | \(caseData?.rechtsgebiet ?? "") | Gericht: \(caseData?.gericht ?? "")
        Zentrale Frage: \(caseData?.zentraleRechtsfrage ?? "")
        Eigene Argumente: \(eigArg.isEmpty ? "keine" : eigArg)
        Gegnerargumente: \(gegArg.isEmpty ? "keine" : gegArg)
        Beweise: \(evList.isEmpty ? "keine" : evList)
        Notizen: \(caseData?.notes ?? "")

        Gib JSON mit: erfolgswahrscheinlichkeit, unsere_taktiken (3), gegner_strategien (3),
        gegner_asse (3), unsere_schwachstellen (3), gesamtstrategie,
        gegner_argumente (5 mit § und unserer Antwort), gegner_vorgehen (Schritte).
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "erfolgswahrscheinlichkeit": ["type": "integer", "minimum": 0, "maximum": 100],
                "erfolgswahrscheinlichkeit_begruendung": ["type": "string"],
                "unsere_taktiken": ["type": "array"],
                "gegner_strategien": ["type": "array"],
                "gegner_asse": ["type": "array"],
                "unsere_schwachstellen": ["type": "array"],
                "gesamtstrategie": ["type": "string"],
                "gegner_argumente": ["type": "array"],
                "gegner_vorgehen": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            kiAnalyse = GesamtKIAnalyse(
                erfolgswahrscheinlichkeit: Int(caseData?.prognose ?? 50),
                begruendung: "KI-Analyse konnte nicht vollständig durchgeführt werden."
            )
            return
        }
        var k = GesamtKIAnalyse()
        k.erfolgswahrscheinlichkeit = (dict["erfolgswahrscheinlichkeit"] as? Int) ?? 50
        k.begruendung = dict["erfolgswahrscheinlichkeit_begruendung"] as? String
        k.gesamtstrategie = dict["gesamtstrategie"] as? String

        if let ut = dict["unsere_taktiken"] as? [[String: Any]] {
            k.unsereTaktiken = ut.map {
                TaktikItem(titel: $0["titel"] as? String ?? "",
                           beschreibung: $0["beschreibung"] as? String ?? "")
            }
        }
        if let gs = dict["gegner_strategien"] as? [[String: Any]] {
            k.gegnerStrategien = gs.map {
                GegnerItem(titel: $0["titel"] as? String ?? "",
                           beschreibung: $0["beschreibung"] as? String ?? "",
                           gefahr: $0["gefahr"] as? String ?? "mittel")
            }
        }
        if let asse = dict["gegner_asse"] as? [[String: Any]] {
            k.gegnerAsse = asse.map {
                TaktikItem(titel: $0["titel"] as? String ?? "",
                           beschreibung: $0["beschreibung"] as? String ?? "")
            }
        }
        if let sw = dict["unsere_schwachstellen"] as? [[String: Any]] {
            k.unsereSchwachstellen = sw.map {
                SchwachItem(titel: $0["titel"] as? String ?? "",
                            risiko: $0["risiko"] as? String)
            }
        }
        if let ga = dict["gegner_argumente"] as? [[String: Any]] {
            k.gegnerArgumente = ga.map {
                GegnerArg(argument: $0["argument"] as? String ?? "",
                          paragraphen: $0["paragraphen"] as? String,
                          staerke: $0["staerke"] as? String ?? "mittel",
                          unsereAntwort: $0["unsere_antwort"] as? String)
            }
        }
        if let gv = dict["gegner_vorgehen"] as? [[String: Any]] {
            k.gegnerVorgehen = gv.map {
                VorgehenStep(phase: $0["phase"] as? String ?? "",
                             beschreibung: $0["beschreibung"] as? String ?? "",
                             risiko: $0["risiko"] as? String)
            }
        }
        kiAnalyse = k
    }
}

// MARK: - Eine einzelne Berechnungsschritt-Zeile
fileprivate struct AlgoStepRow: View {
    let step: CalculationStep
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { open.toggle() } label: {
                HStack {
                    Text(step.label).font(.caption).bold()
                    Spacer()
                    Text(formattedWert).font(.caption2).monospaced().foregroundStyle(.purple)
                    Image(systemName: open ? "chevron.up" : "chevron.down").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            if open {
                VStack(alignment: .leading, spacing: 6) {
                    GroupBox {
                        VStack(alignment: .leading) {
                            Text("FORMEL").font(.caption2).bold().foregroundStyle(.secondary)
                            Text(step.formel).font(.caption2).monospaced().foregroundStyle(.blue)
                        }
                    }
                    Text(step.erklaerung).font(.caption)
                    if let s = SIMPLE_EXPLANATIONS[step.label] {
                        Text(s).font(.caption2)
                            .padding(6).foregroundStyle(.blue)
                            .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(6)
        .background(.background, in: RoundedRectangle(cornerRadius: 6))
    }
    private var formattedWert: String {
        let prefix = step.wert > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.4f", step.wert)) \(step.einheit ?? "")"
    }
}
