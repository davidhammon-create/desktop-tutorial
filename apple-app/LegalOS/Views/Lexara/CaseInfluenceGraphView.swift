//
//  CaseInfluenceGraphView.swift
//  Konversion von src/components/lexara/CaseInfluenceGraph.jsx
//  Visualisiert Zusammenhänge zwischen Argumenten, Beweisen, Fristen und Personen.
//

import SwiftUI

struct CaseInfluenceGraphView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var deadlines: [Deadline] = []
    @State private var persons: [Person] = []
    @State private var loading = true
    @State private var view: ViewMode = .network
    @State private var filter: NodeType = .all
    @State private var selected: GraphNode?

    enum ViewMode: String, CaseIterable, Identifiable {
        case network, timeline, sankey
        var id: Self { self }
        var label: String { switch self { case .network: return "Netzwerk"; case .timeline: return "Zeitachse"; case .sankey: return "Sankey" } }
        var icon: String { switch self { case .network: return "circle.grid.cross"; case .timeline: return "clock"; case .sankey: return "bolt" } }
    }

    enum NodeType: String, CaseIterable, Identifiable {
        case all, argument, evidence, deadline, person
        var id: Self { self }
        var label: String {
            switch self {
            case .all: return "Alle"; case .argument: return "Argumente"
            case .evidence: return "Beweise"; case .deadline: return "Fristen"; case .person: return "Personen"
            }
        }
    }

    struct GraphNode: Identifiable, Hashable {
        let id: String
        let label: String
        let type: NodeType
        let strength: Double
        let color: Color
        let date: Date?
    }
    struct GraphEdge: Identifiable, Hashable {
        let id = UUID()
        let source: String
        let target: String
        let weight: Double
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading { ProgressView().padding() }
                else {
                    controls
                    Group {
                        switch view {
                        case .network: networkView
                        case .timeline: timelineView
                        case .sankey: sankeyView
                        }
                    }
                    if let s = selected { detailCard(s) }
                    statsCard
                }
            }.padding(20)
        }
        .task { await load() }
    }

    private var controls: some View {
        HStack {
            Picker("View", selection: $view) {
                ForEach(ViewMode.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
            }.pickerStyle(.segmented)
            Picker("Filter", selection: $filter) {
                ForEach(NodeType.allCases) { Text($0.label).tag($0) }
            }.fixedSize()
        }.padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var networkView: some View {
        GroupBox {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                ForEach(filteredNodes) { node in
                    Button {
                        selected = node
                    } label: {
                        VStack(spacing: 4) {
                            Circle().fill(node.color).frame(width: 30 + node.strength * 2, height: 30 + node.strength * 2)
                            Text(node.label).font(.caption2).lineLimit(2).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                }
            }.padding(8)
        }
    }

    private var timelineView: some View {
        GroupBox("Zeitachse") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(timelineNodes) { node in
                    HStack {
                        Circle().fill(node.color).frame(width: 12, height: 12)
                        Text(node.label).font(.caption)
                        Spacer()
                        if let d = node.date { Text(d.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundColor(.secondary) }
                    }
                }
            }.padding(8)
        }
    }

    private var sankeyView: some View {
        GroupBox("Beziehungen (Sankey)") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(filteredEdges) { e in
                    HStack {
                        Text(label(for: e.source)).font(.caption).lineLimit(1)
                        Image(systemName: "arrow.right").font(.caption)
                        Text(label(for: e.target)).font(.caption).lineLimit(1)
                        Spacer()
                        Text("Gewicht: \(Int(e.weight))").font(.caption2).foregroundColor(.secondary)
                    }.padding(.vertical, 4).overlay(Divider(), alignment: .bottom)
                }
            }.padding(8)
        }
    }

    private func detailCard(_ node: GraphNode) -> some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading) {
                    Text(node.label).font(.subheadline.weight(.semibold))
                    Text(node.type.label).font(.caption).foregroundColor(.secondary)
                    Text("Stärke: \(Int(node.strength))/10").font(.caption)
                }
                Spacer()
                Button { selected = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }.padding(8)
        }
    }

    private var statsCard: some View {
        GroupBox("Übersicht") {
            HStack(spacing: 16) {
                StatPill(label: "Argumente", count: args.count, color: .blue)
                StatPill(label: "Beweise", count: evidence.count, color: .green)
                StatPill(label: "Fristen", count: deadlines.count, color: .orange)
                StatPill(label: "Personen", count: persons.count, color: .purple)
            }.padding(8)
        }
    }

    // MARK: - Computed
    private var nodes: [GraphNode] {
        var arr: [GraphNode] = []
        for a in args {
            arr.append(GraphNode(id: a.id, label: a.title, type: .argument, strength: a.kiStrength ?? a.strength ?? 5, color: a.side == .eigen ? .blue : .red, date: nil))
        }
        for e in evidence { arr.append(GraphNode(id: e.id, label: e.title, type: .evidence, strength: e.kiWeight ?? e.weight ?? 5, color: .green, date: nil)) }
        for d in deadlines { arr.append(GraphNode(id: d.id, label: d.title, type: .deadline, strength: 7, color: .orange, date: d.dueDate)) }
        for p in persons { arr.append(GraphNode(id: p.id, label: p.name, type: .person, strength: p.glaubwuerdigkeit ?? 5, color: .purple, date: nil)) }
        return arr
    }

    private var filteredNodes: [GraphNode] { filter == .all ? nodes : nodes.filter { $0.type == filter } }
    private var timelineNodes: [GraphNode] { nodes.filter { $0.date != nil }.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) } }
    private var edges: [GraphEdge] {
        args.flatMap { a in a.evidenceIds.map { GraphEdge(source: $0, target: a.id, weight: a.kiStrength ?? a.strength ?? 5) } }
    }
    private var filteredEdges: [GraphEdge] { edges.filter { e in filteredNodes.contains(where: { $0.id == e.source }) && filteredNodes.contains(where: { $0.id == e.target }) } }

    private func label(for id: String) -> String { nodes.first { $0.id == id }?.label ?? id }

    private func load() async {
        loading = true; defer { loading = false }
        do {
            args = try await cloudKit.fetchForCase(Argument.self, caseId: caseId)
            evidence = try await cloudKit.fetchForCase(Evidence.self, caseId: caseId)
            deadlines = try await cloudKit.fetchForCase(Deadline.self, caseId: caseId)
            persons = try await cloudKit.fetchForCase(Person.self, caseId: caseId)
        } catch { cloudKit.lastError = error.localizedDescription }
    }
}

struct StatPill: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        VStack {
            Text("\(count)").font(.headline.weight(.bold)).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(8).background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
