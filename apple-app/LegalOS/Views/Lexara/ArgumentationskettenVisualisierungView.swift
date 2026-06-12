//
//  ArgumentationskettenVisualisierungView.swift
//  Konversion von src/components/lexara/ArgumentationskettenVisualisierung.jsx
//  Argumentationsketten-Visualisierung mit Lückenerkennung und KI-Analyse.
//

import SwiftUI

struct ArgumentationskettenVisualisierungView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var loading = true
    @State private var selectedArg: Argument? = nil
    @State private var view: ViewMode = .kette
    @State private var kiAnalyzing = false
    @State private var kiLuecken: KILueckenAnalyse? = nil

    enum ViewMode: String, CaseIterable, Identifiable {
        case kette, luecken, ki
        var id: Self { self }
        var label: String {
            switch self { case .kette: return "Argumentkette"; case .luecken: return "Lückenanalyse"; case .ki: return "KI-Analyse" }
        }
    }

    struct Connection: Identifiable {
        let id = UUID()
        let fromId: String
        let fromTitle: String
        let toId: String
        let type: String
        let intensitaet: Int
        let explanation: String
    }

    enum GapType: String {
        case noEvidence = "no_evidence"
        case weakChain = "weak_chain"
        case contradiction = "contradiction"
        case isolated = "isolated"
        case missingCounter = "missing_counter"
        var label: String {
            switch self {
            case .noEvidence: return "Kein Beweis verknüpft"
            case .weakChain: return "Schwache Kette"
            case .contradiction: return "Widerspruch"
            case .isolated: return "Isoliertes Argument"
            case .missingCounter: return "Kein Gegenargument"
            }
        }
        var color: Color {
            switch self {
            case .noEvidence, .contradiction: return .red
            case .weakChain: return .orange
            case .isolated: return .gray
            case .missingCounter: return .blue
            }
        }
    }

    struct Gap: Identifiable {
        let id = UUID()
        let argId: String
        let type: GapType
        let desc: String
    }

    struct KILueckenAnalyse: Codable {
        var gesamtbewertung: String?
        var staerke_eigene_kette: Double?
        var luecken: [KILuecke]?
        var empfehlungen: [String]?
    }
    struct KILuecke: Codable, Identifiable {
        var id: String { typ + beschreibung }
        var typ: String
        var beschreibung: String
        var empfehlung: String?
        var schwere: String?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else if args.isEmpty {
                    emptyState
                } else {
                    header
                    if !gaps.isEmpty { gapBanner }
                    switch view {
                    case .kette: chainView
                    case .luecken: GapsPanel(gaps: gaps, args: args, onSelect: { selectedArg = $0; view = .kette })
                    case .ki: kiAnalysisView
                    }
                }
            }
            .padding(20)
        }
        .task { await load() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Argumentationsketten-Visualisierung").font(.headline)
                Text("\(args.count) Argumente · \(connections.count) Verbindungen · \(evidence.count) Beweise · \(gaps.count) Lücken").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Picker("", selection: $view) {
                ForEach(ViewMode.allCases) { Text($0.label).tag($0) }
            }.pickerStyle(.segmented).fixedSize()
        }
    }

    private var gapBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text("\(gaps.count) logische Lücken in der Beweisführung erkannt").font(.caption).foregroundColor(.orange)
            Spacer()
            Button("Zeigen") { view = .luecken }.buttonStyle(.plain).font(.caption2).foregroundColor(.orange)
        }.padding(10).background(Color.orange.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chainView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                argColumn(label: "Eigene Argumente", group: args.filter { $0.side == .eigen }, color: .blue)
                argColumn(label: "Gegenargumente", group: args.filter { $0.side == .gegner }, color: .red)
            }
            if !connections.isEmpty {
                GroupBox("Argumentketten (\(connections.count))") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(connections) { c in connectionRow(c) }
                    }
                }
            }
            if let sel = selectedArg { argDetail(sel) }
        }
    }

    private func argColumn(label: String, group: [Argument], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(label) (\(group.count))").font(.caption.weight(.bold)).foregroundColor(color).textCase(.uppercase)
            ForEach(group) { arg in
                argNode(arg).onTapGesture { selectedArg = arg }
            }
            if group.isEmpty { Text("Keine vorhanden").font(.caption).foregroundColor(.secondary).italic() }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func argNode(_ arg: Argument) -> some View {
        let argGaps = gaps.filter { $0.argId == arg.id }
        let argEvidence = evidence.filter { $0.argumentId == arg.id }
        let isEigen = arg.side == .eigen
        let strength = arg.kiStrength ?? arg.strength ?? 5
        let strengthColor: Color = strength >= 7 ? .green : strength >= 4 ? .orange : .red
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isEigen ? "EIGEN" : "GEGNER").font(.system(size: 9, weight: .bold)).padding(.horizontal, 4).padding(.vertical, 2).background((isEigen ? Color.blue : Color.red).opacity(0.15)).foregroundColor(isEigen ? .blue : .red)
                Spacer()
                Text("\(Int(strength))/10").font(.system(size: 9, weight: .semibold)).foregroundColor(strengthColor)
            }
            Text(arg.title).font(.caption.weight(.semibold)).lineLimit(3)
            if !argEvidence.isEmpty {
                Label("\(argEvidence.count) Beweise", systemImage: "checkmark.circle").font(.system(size: 9)).foregroundColor(.green)
            } else {
                Label("Kein Beweis", systemImage: "xmark.circle").font(.system(size: 9)).foregroundColor(.red)
            }
            ForEach(argGaps) { g in
                Text(g.type.label).font(.system(size: 8)).padding(.horizontal, 4).padding(.vertical, 1).background(g.type.color.opacity(0.15)).foregroundColor(g.type.color).clipShape(Capsule())
            }
        }
        .padding(10)
        .background(isEigen ? Color.blue.opacity(0.05) : Color.red.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedArg?.id == arg.id ? Color.primary : (isEigen ? Color.blue : Color.red).opacity(0.25), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func connectionRow(_ c: Connection) -> some View {
        HStack {
            Text(args.first { $0.id == c.fromId }?.title ?? "").font(.caption).lineLimit(1)
            Text(c.type).font(.caption2.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2).background(connectionColor(c.type).opacity(0.15)).foregroundColor(connectionColor(c.type)).clipShape(Capsule())
            Image(systemName: "arrow.right").foregroundColor(connectionColor(c.type)).font(.caption2)
            Text(args.first { $0.id == c.toId }?.title ?? "").font(.caption).lineLimit(1)
            Spacer()
            Text("Intensität \(c.intensitaet)/10").font(.caption2).foregroundColor(.secondary)
        }
        .padding(.vertical, 4).overlay(Divider(), alignment: .bottom)
    }

    private func connectionColor(_ type: String) -> Color {
        switch type {
        case "stützt", "verstärkt": return .green
        case "entkräftet": return .red
        case "widerspricht", "schwächt": return .orange
        case "schließt aus": return .gray
        default: return .blue
        }
    }

    private func argDetail(_ arg: Argument) -> some View {
        let argEvidence = evidence.filter { $0.argumentId == arg.id }
        let outgoing = connections.filter { $0.fromId == arg.id }
        let incoming = connections.filter { $0.toId == arg.id }
        return GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(arg.side == .eigen ? "Eigenes Argument" : "Gegenargument").font(.caption2.weight(.bold))
                        Text(arg.title).font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("Stärke \(Int(arg.kiStrength ?? arg.strength ?? 5))/10").font(.caption.weight(.bold))
                }
                if let desc = arg.argDescription { Text(desc).font(.caption).foregroundColor(.secondary) }
                Text("Verknüpfte Beweise (\(argEvidence.count))").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                if argEvidence.isEmpty { Label("Kein Beweis verknüpft – Lücke!", systemImage: "xmark.circle").font(.caption).foregroundColor(.red) }
                else {
                    ForEach(argEvidence) { ev in
                        Label(ev.title, systemImage: "checkmark.circle").font(.caption).foregroundColor(.green)
                    }
                }
                if !outgoing.isEmpty {
                    Text("Wirkt auf").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                    ForEach(outgoing) { c in
                        let target = args.first { $0.id == c.toId }
                        HStack {
                            Text(c.type).font(.caption2.weight(.semibold)).padding(.horizontal, 4).padding(.vertical, 1).background(connectionColor(c.type).opacity(0.15)).foregroundColor(connectionColor(c.type)).clipShape(Capsule())
                            Image(systemName: "arrow.right")
                            Text(target?.title ?? "").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                if !incoming.isEmpty {
                    Text("Wird beeinflusst von").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                    ForEach(incoming) { c in
                        let source = args.first { $0.id == c.fromId }
                        HStack {
                            Text(source?.title ?? "").font(.caption).foregroundColor(.secondary)
                            Image(systemName: "arrow.right")
                            Text(c.type).font(.caption2.weight(.semibold)).padding(.horizontal, 4).padding(.vertical, 1).background(connectionColor(c.type).opacity(0.15)).foregroundColor(connectionColor(c.type)).clipShape(Capsule())
                        }
                    }
                }
            }.padding(8)
        }
    }

    private var kiAnalysisView: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text("KI-Lückenanalyse der Beweisführung").font(.subheadline.weight(.semibold))
                        Text("Die KI analysiert die vollständige Argumentationskette auf logische Lücken.").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { Task { await runKILueckenAnalyse() } } label: {
                        Label(kiAnalyzing ? "Analysiere…" : (kiLuecken != nil ? "Neu analysieren" : "Analyse starten"), systemImage: "sparkles")
                    }.buttonStyle(.borderedProminent).tint(.purple).disabled(kiAnalyzing || args.count < 2)
                }
            }
            if let r = kiLuecken {
                GroupBox {
                    HStack {
                        VStack {
                            Text(String(format: "%.0f", r.staerke_eigene_kette ?? 0)).font(.title.weight(.bold))
                            Text("Kettenstärke").font(.caption2)
                        }
                        Text(r.gesamtbewertung ?? "").font(.caption).foregroundColor(.secondary)
                    }
                }
                if let luecken = r.luecken, !luecken.isEmpty {
                    Text("Identifizierte Lücken (\(luecken.count))").font(.caption.weight(.semibold))
                    ForEach(luecken) { l in
                        GroupBox {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(l.typ).font(.caption.weight(.semibold))
                                    Spacer()
                                    if let s = l.schwere { Text(s).font(.caption2.weight(.bold)).padding(.horizontal, 4).background((s == "kritisch" ? Color.red : s == "hoch" ? Color.orange : Color.gray).opacity(0.15)).clipShape(Capsule()) }
                                }
                                Text(l.beschreibung).font(.caption)
                                if let e = l.empfehlung { Label(e, systemImage: "checkmark.circle").font(.caption2).foregroundColor(.green) }
                            }
                        }
                    }
                }
                if let emp = r.empfehlungen, !emp.isEmpty {
                    GroupBox("Empfehlungen") {
                        VStack(alignment: .leading) {
                            ForEach(emp, id: \.self) { e in Text("→ \(e)").font(.caption).foregroundColor(.green) }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle").font(.title)
            Text("Noch keine Argumente vorhanden").font(.subheadline).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(40).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed
    private var connections: [Connection] {
        // CloudKit-Modell Argument hat keine "connections" Property; abgeleitet wäre via separates Modell.
        []
    }

    private var gaps: [Gap] {
        var gaps: [Gap] = []
        for arg in args {
            let hasEvidence = evidence.contains { $0.argumentId == arg.id }
            if !hasEvidence {
                gaps.append(Gap(argId: arg.id, type: .noEvidence, desc: "Argument \"\(String(arg.title.prefix(40)))\" hat keinen Beweis verknüpft."))
            }
            let strength = arg.kiStrength ?? arg.strength ?? 5
            if strength < 4 && arg.side == .eigen {
                gaps.append(Gap(argId: arg.id, type: .weakChain, desc: "Eigenes Argument \"\(String(arg.title.prefix(40)))\" ist schwach (Stärke < 4)."))
            }
        }
        return gaps
    }

    // MARK: - Actions
    private func load() async {
        loading = true; defer { loading = false }
        do {
            args = try await cloudKit.fetchForCase(Argument.self, caseId: caseId)
            evidence = try await cloudKit.fetchForCase(Evidence.self, caseId: caseId)
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func runKILueckenAnalyse() async {
        guard args.count >= 2 else { return }
        kiAnalyzing = true; defer { kiAnalyzing = false }
        let prompt = """
        Du bist ein Experte für juristische Beweisführung. Analysiere die Argumentationskette auf logische Lücken.
        Argumente: \(args.map { "- [\($0.side.rawValue)] \"\($0.title)\" Stärke: \(Int($0.kiStrength ?? $0.strength ?? 5))/10" }.joined(separator: "\n"))
        Antworte als JSON: {gesamtbewertung, staerke_eigene_kette, luecken: [{typ, beschreibung, empfehlung, schwere}], empfehlungen}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Lückenanalyse", caseId: caseId)
        if case .success(let value) = res, let raw = value as? String,
           let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(KILueckenAnalyse.self, from: data) {
            kiLuecken = result
        }
    }
}

// MARK: - Gaps Panel

private struct GapsPanel: View {
    let gaps: [ArgumentationskettenVisualisierungView.Gap]
    let args: [Argument]
    let onSelect: (Argument) -> Void

    var body: some View {
        if gaps.isEmpty {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("Keine logischen Lücken erkannt").font(.subheadline.weight(.semibold)).foregroundColor(.green)
                    Text("Alle Argumente sind gestützt und verknüpft.").font(.caption).foregroundColor(.secondary)
                }
            }.padding(12).background(Color.green.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label("\(gaps.count) logische Lücken erkannt", systemImage: "exclamationmark.triangle").font(.subheadline.weight(.semibold)).foregroundColor(.orange)
                ForEach(Dictionary(grouping: gaps, by: \.type).sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { type, items in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(type.label) (\(items.count))").font(.caption.weight(.bold)).foregroundColor(type.color).textCase(.uppercase)
                            ForEach(items) { g in
                                HStack {
                                    Circle().fill(type.color).frame(width: 4, height: 4)
                                    Text(g.desc).font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    if let arg = args.first(where: { $0.id == g.argId }) {
                                        Button("anzeigen") { onSelect(arg) }.buttonStyle(.plain).font(.caption2).foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
