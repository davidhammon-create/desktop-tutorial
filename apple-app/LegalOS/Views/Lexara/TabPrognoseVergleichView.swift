//
//  TabPrognoseVergleichView.swift
//  Konversion von src/components/lexara/TabPrognoseVergleich.jsx
//  Vergleich aller Prognose-Modelle eines Falls plus KI-Erklärung der Unterschiede.
//

import SwiftUI
import Charts

struct TabPrognoseVergleichView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var deadlines: [Deadline] = []
    @State private var persons: [Person] = []
    @State private var gegnerVerhalten: [GegnerVerhalten] = []
    @State private var algoResult: VollanalyseResult? = nil
    @State private var loaded = false
    @State private var kiErklarung: KIErklarung? = nil
    @State private var kiLoading = false
    @State private var openDetail: Set<String> = []

    struct Prognose: Identifiable {
        let id: String
        let label: String
        let reiter: String
        let wert: Double
        let farbe: Color
        let methode: String
        let faktoren: [String]
        let beschreibung: String
    }

    struct KIErklarung: Codable {
        var abweichungs_erklaerung: String?
        var verlasslichste_prognose: String?
        var begruendung_verlasslich: String?
        var top_faktoren: [TopFaktor]?
        var verbesserungsmassnahmen: [Massnahme]?
        var gesamtbewertung: String?
    }
    struct TopFaktor: Codable, Identifiable {
        var id: String { faktor }
        var faktor: String
        var einfluss: String
        var richtung: String
    }
    struct Massnahme: Codable, Identifiable {
        var id: String { massnahme }
        var massnahme: String
        var erwartete_wirkung: String
        var prioritaet: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !loaded || algoResult == nil {
                    HStack { Spacer(); ProgressView("Lade und berechne alle Prognosen…"); Spacer() }.padding(40)
                } else {
                    headerCard
                    overviewCard
                    detailsList
                    if let r = kiErklarung { kiResultsView(r) }
                    else if !kiLoading { hintCard }
                }
            }.padding(20)
        }
        .task { await load() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROGNOSE-VERGLEICH — ALLE MODELLE").font(.caption2).foregroundColor(.secondary)
            HStack {
                VStack(alignment: .leading) {
                    Text("\(prognosen.count) Prognosen").font(.title.weight(.bold))
                    Text("Spannweite: \(Int(minP))% – \(Int(maxP))% (Δ \(Int(spannweite))pp)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button { Task { await runKiErklarung() } } label: {
                    Label(kiLoading ? "Analysiere…" : "KI erklärt die Unterschiede", systemImage: "sparkles")
                }.buttonStyle(.borderedProminent).disabled(kiLoading || prognosen.isEmpty)
            }
            if spannweite >= 15 {
                Text("⚠️ Hohe Abweichung (\(Int(spannweite))pp) — KI-Erklärung empfohlen").font(.caption).foregroundColor(.orange).padding(8).background(Color.orange.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.2)))
    }

    private var overviewCard: some View {
        GroupBox("Alle Prognosen auf einen Blick") {
            VStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(prognosen) { p in
                        PrognoseCircle(value: p.wert, label: p.label, color: p.farbe, size: 80)
                    }
                }
                Chart(prognosen) { p in
                    BarMark(x: .value("Modell", p.label), y: .value("Wert", p.wert))
                        .foregroundStyle(p.farbe)
                }.frame(height: 120)
            }.padding(8)
        }
    }

    private var detailsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Warum diese Prognose? — Einzelerklärungen").font(.subheadline.weight(.semibold))
            ForEach(prognosen) { p in
                DisclosureGroup(isExpanded: Binding(get: { openDetail.contains(p.id) }, set: { val in if val { openDetail.insert(p.id) } else { openDetail.remove(p.id) } })) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(p.beschreibung).font(.caption).foregroundColor(.secondary)
                        Text("Eingeflossene Faktoren").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                        ForEach(p.faktoren, id: \.self) { f in Text("• \(f)").font(.caption).foregroundColor(.secondary) }
                    }.padding(8)
                } label: {
                    HStack {
                        Text("\(Int(p.wert))").font(.headline.weight(.bold)).frame(width: 40, height: 40).background(p.farbe).foregroundColor(.white).clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(p.label).font(.subheadline.weight(.semibold))
                            Text("\(p.reiter) · \(p.methode)").font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        ProgressView(value: p.wert / 100).tint(p.farbe).frame(width: 100)
                    }
                }
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func kiResultsView(_ r: KIErklarung) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("KI-Analyse der Prognose-Unterschiede", systemImage: "sparkles").font(.subheadline.weight(.semibold))
            if let g = r.gesamtbewertung { GroupBox("Gesamtbewertung") { Text(g).font(.caption).padding(8) } }
            if let a = r.abweichungs_erklaerung { GroupBox("Warum weichen die Prognosen ab?") { Text(a).font(.caption).padding(8) } }
            if let v = r.verlasslichste_prognose {
                GroupBox("Verlässlichste Prognose") {
                    VStack(alignment: .leading) {
                        Text(v).font(.subheadline.weight(.semibold)).foregroundColor(.green)
                        if let b = r.begruendung_verlasslich { Text(b).font(.caption).foregroundColor(.secondary) }
                    }.padding(8)
                }
            }
            if let f = r.top_faktoren, !f.isEmpty {
                GroupBox("Die 3 stärksten Einfluss-Faktoren") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(f.prefix(3)) { factor in
                            let dirColor: Color = factor.richtung == "positiv" ? .green : factor.richtung == "negativ" ? .red : .gray
                            let icon = factor.richtung == "positiv" ? "arrow.up" : factor.richtung == "negativ" ? "arrow.down" : "arrow.right"
                            HStack {
                                Image(systemName: icon).foregroundColor(dirColor)
                                VStack(alignment: .leading) {
                                    Text(factor.faktor).font(.caption.weight(.bold))
                                    Text(factor.einfluss).font(.caption2).foregroundColor(.secondary)
                                }
                            }.padding(6).background(dirColor.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }.padding(8)
                }
            }
            if let m = r.verbesserungsmassnahmen, !m.isEmpty {
                GroupBox("Verbesserungsmaßnahmen") {
                    VStack(alignment: .leading) {
                        ForEach(m) { mas in
                            HStack(alignment: .top) {
                                Text(mas.prioritaet.uppercased()).font(.caption2.weight(.bold)).padding(.horizontal, 4).background((mas.prioritaet == "hoch" ? Color.red : mas.prioritaet == "mittel" ? Color.orange : Color.gray).opacity(0.2)).clipShape(Capsule())
                                VStack(alignment: .leading) {
                                    Text(mas.massnahme).font(.caption.weight(.semibold))
                                    Text(mas.erwartete_wirkung).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }.padding(8)
                }
            }
        }
    }

    private var hintCard: some View {
        VStack {
            Image(systemName: "sparkles").font(.title)
            Text("Klicken Sie auf „KI erklärt die Unterschiede"").font(.caption).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed

    private var prognosen: [Prognose] {
        guard let algo = algoResult else { return [] }
        var list: [Prognose] = []
        list.append(Prognose(id: "manuell", label: "Manuelle Prognose", reiter: "Reiter 6 · Strategie",
                             wert: caseData?.prognose ?? Double(computeStrategiePrognose()),
                             farbe: .blue, methode: "Manuell oder 6-Stufen-Algorithmus",
                             faktoren: ["Argumente: \(args.filter{$0.side == .eigen}.count) eigen / \(args.filter{$0.side == .gegner}.count) Gegner",
                                        "Beweise: \(evidence.count) Stück",
                                        "Versäumte Fristen: \(deadlines.filter{$0.status == .versaeumt}.count)"],
                             beschreibung: "Der einfache 6-Stufen-Algorithmus berechnet eine Basisprognose."))
        list.append(Prognose(id: "prozessstaerke", label: "Prozessstärke-Score", reiter: "Reiter 6 · Strategie",
                             wert: Double(computeProzessStaerke()), farbe: .purple,
                             methode: "Gewichtete Faktoren-Matrix",
                             faktoren: ["Argumente-Balance (30%)", "Beweislage (20%)", "Fristen-Risiko (20%)", "Gegnerverhalten (15%)", "Richter-Profil (15%)"],
                             beschreibung: "Gewichtetes Mittel von 5 Dimensionen."))
        list.append(Prognose(id: "bayes", label: "Bayesianische Prognose", reiter: "Reiter 6 · Risikoformeln",
                             wert: Double(algo.prognose.score), farbe: .green,
                             methode: "Bayes-Modell mit Log-Odds + σ-Funktion",
                             faktoren: ["Konfidenz: [\(algo.prognose.ciLow)%, \(algo.prognose.ciHigh)%]",
                                        "Sigma: \(String(format: "%.1f", algo.prognose.sigma * 100))pp",
                                        "\(algo.prognose.steps.count) Berechnungsschritte"],
                             beschreibung: "Mathematisch robust durch Log-Odds-Akkumulation."))
        list.append(Prognose(id: "montecarlo", label: "Monte Carlo Median", reiter: "Reiter 6 · Risikoformeln",
                             wert: Double(algo.monteCarlo.median), farbe: .orange,
                             methode: "\(algo.monteCarlo.iterations) stochastische Simulationen",
                             faktoren: ["P10: \(algo.monteCarlo.p10)%", "P25: \(algo.monteCarlo.p25)%", "Median: \(algo.monteCarlo.median)%", "P75: \(algo.monteCarlo.p75)%", "P90: \(algo.monteCarlo.p90)%"],
                             beschreibung: "Robuste Schätzung durch tausende Szenarien."))
        return list
    }

    private var minP: Double { prognosen.map(\.wert).min() ?? 0 }
    private var maxP: Double { prognosen.map(\.wert).max() ?? 0 }
    private var spannweite: Double { maxP - minP }

    private func computeStrategiePrognose() -> Int {
        let eigene = args.filter { $0.side == .eigen }
        let gegner = args.filter { $0.side == .gegner }
        let eigenStaerke = eigene.compactMap(\.strength).reduce(0, +)
        let gegnerStaerke = gegner.compactMap(\.strength).reduce(0, +)
        let argBasis: Double = (eigene.isEmpty && gegner.isEmpty) ? 50 : max(0, ((eigenStaerke / Double(max(eigene.count, 1))) - (gegnerStaerke / Double(max(gegner.count, 1)))) * 5 + 50)
        let avgEvid = evidence.isEmpty ? 5 : evidence.compactMap(\.weight).reduce(0, +) / Double(evidence.count)
        let beweisBoost = 1 + (avgEvid / 10) * 0.5
        return min(99, max(1, Int(argBasis * beweisBoost)))
    }

    private func computeProzessStaerke() -> Int {
        let eArgs = args.filter { $0.side == .eigen }
        let gArgs = args.filter { $0.side == .gegner }
        let eS = eArgs.isEmpty ? 5 : eArgs.compactMap(\.strength).reduce(0, +) / Double(eArgs.count)
        let gS = gArgs.isEmpty ? 5 : gArgs.compactMap(\.strength).reduce(0, +) / Double(gArgs.count)
        let argScore = min(100, max(0, (eS - gS) * 5 + 50))
        let beweisScore = evidence.isEmpty ? 50 : min(100, evidence.compactMap(\.weight).reduce(0, +) / Double(evidence.count) * 10)
        let versaeumt = deadlines.filter { $0.status == .versaeumt }.count
        let fristenScore = max(0, 100 - versaeumt * 25)
        let gvSum = gegnerVerhalten.compactMap(\.auswirkungPrognose).reduce(0, +)
        let gegnerScore = min(100, max(0, 50 + Int(gvSum)))
        let richterScore = Int(caseData?.richterKlaegerRate ?? 50)
        return Int(argScore * 0.30 + beweisScore * 0.20 + Double(fristenScore) * 0.20 + Double(gegnerScore) * 0.15 + Double(richterScore) * 0.15)
    }

    // MARK: - Actions
    private func load() async {
        do {
            async let a = cloudKit.fetchForCase(Argument.self, caseId: caseId)
            async let e = cloudKit.fetchForCase(Evidence.self, caseId: caseId)
            async let d = cloudKit.fetchForCase(Deadline.self, caseId: caseId)
            async let p = cloudKit.fetchForCase(Person.self, caseId: caseId)
            async let g = cloudKit.fetchForCase(GegnerVerhalten.self, caseId: caseId)
            args = try await a; evidence = try await e; deadlines = try await d; persons = try await p; gegnerVerhalten = try await g
            loaded = true
            algoResult = LegalAlgorithms.computeVollanalyse(PrognoseInput(args: args, evidence: evidence, deadlines: deadlines, persons: persons, caseData: caseData))
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func runKiErklarung() async {
        guard !prognosen.isEmpty else { return }
        kiLoading = true; defer { kiLoading = false }
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Erkläre warum die Prognosen abweichen.
        FALL: \(caseData?.fallname ?? "?")
        \(prognosen.map { "• \($0.label): \(Int($0.wert))% — \($0.methode)" }.joined(separator: "\n"))
        Antworte als JSON: {abweichungs_erklaerung, verlasslichste_prognose, begruendung_verlasslich, top_faktoren: [{faktor, einfluss, richtung}], verbesserungsmassnahmen: [{massnahme, erwartete_wirkung, prioritaet}], gesamtbewertung}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "PrognoseVergleich", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String,
           let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(KIErklarung.self, from: data) {
            kiErklarung = result
        }
    }
}

private struct PrognoseCircle: View {
    let value: Double
    let label: String
    let color: Color
    let size: CGFloat
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.2), lineWidth: size * 0.06)
                Circle().trim(from: 0, to: value / 100).stroke(color, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(Int(value))%").font(.system(size: size * 0.22, weight: .black))
            }.frame(width: size, height: size)
            Text(label).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center).frame(maxWidth: 90)
        }
    }
}
