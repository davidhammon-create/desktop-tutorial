import SwiftUI
struct OpportunismaMachtportalView: View {
    @Bindable var vm: OpportunismaViewModel
    @State private var selectedId: String = "uroot"
    @State private var overlay = false
    @State private var schwelle: Double = 70
    private var szenario: PragSzenario { vm.aktivesSzenario }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PragModulKopf(vm: vm, tab: .machtStrategie)
            steuerleiste
            OpportunismaAusgangZielEingabe(vm: vm)
            OpportunismaZielPfadDiagramm(
                root: szenario.root,
                ausgangText: vm.situationText,
                zielText: vm.zielText
            )
            lageZeile
            HStack(alignment: .top, spacing: 16) {
                baumPanel
                    .frame(maxWidth: .infinity)
                inspektor
                    .frame(width: 280)
            }
        }
        .onAppear { selectedId = szenario.root.id }
        .onChange(of: vm.szenarioKey) { _, _ in selectedId = vm.aktivesSzenario.root.id }
        .onChange(of: vm.selectedNodeId) { _, new in
            if !new.isEmpty { selectedId = new }
        }
    }
    private var steuerleiste: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Array(vm.szenarienBaum.keys.sorted()), id: \.self) { key in
                    let active = vm.szenarioKey == key
                    Button(vm.szenarienBaum[key]?.label ?? key) {
                        vm.szenarioKey = key
                    }
                    .font(.system(size: 11, weight: active ? .bold : .regular))
                    .foregroundStyle(active ? OpportunismaTheme.ink : OpportunismaTheme.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(active ? OpportunismaTheme.red.opacity(0.18) : Color.clear, in: Capsule())
                }
            }
            .background(OpportunismaTheme.card, in: OpportunismaTheme.buttonShape)
            .overlay(OpportunismaTheme.buttonShape.stroke(OpportunismaTheme.line))
            Toggle("Risiko-Overlay", isOn: $overlay)
                .toggleStyle(.switch)
                .font(.system(size: 10))
                .tint(OpportunismaTheme.red)
            HStack(spacing: 6) {
                Text("Schadensgrenze").font(.system(size: 10)).foregroundStyle(OpportunismaTheme.gray)
                Slider(value: $schwelle, in: 0...100)
                    .frame(width: 100)
                    .tint(OpportunismaTheme.red)
                Text("\(Int(schwelle))").font(.system(size: 10, weight: .bold))
            }
            Spacer()
            PragKIButton(titel: "KI-PFAD", laeuft: vm.kiLaeuft) {
                vm.selectedNodeId = selectedId
                Task { await OpportunismaService.erweitereStrategiebaum(vm: vm) }
            }
            .disabled(vm.kiLaeuft || !vm.kiBereit)
        }
    }
    private var lageZeile: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lage · \(szenario.situation)")
                    .font(.system(size: 11))
                    .foregroundStyle(OpportunismaTheme.gray)
                Text("Ziel: \(szenario.ziel)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
            }
            Spacer()
            FenlynineOSTransparenzInfoButton(inhalt: .opportunismaWidget(
                titel: "Strategie-Baum",
                formel: "Knoten: Position → Handlung → Folge → Ziel · Scores: Wirkung, Risiko, Umkehrbarkeit, Schaden",
                begruendung: "Entscheidungsbaum aus Machtportal-Konzept. Schadens-Schwelle filtert Pfade.",
                ergebnis: "Aktiv: \(szenario.label)"
            ))
        }
        .padding(10)
        .pragCardStyle()
    }
    private var baumPanel: some View {
        let layout = PragTreeLayout.compute(root: szenario.root)
        let blocked = layout.blockedIds(root: szenario.root, threshold: Int(schwelle))
        let pathIds = layout.pathIds(to: selectedId, root: szenario.root)
        return ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for edge in layout.edges {
                        guard let a = layout.nodes[edge.from], let b = layout.nodes[edge.to] else { continue }
                        let onPath = pathIds.contains(edge.from) && pathIds.contains(edge.to)
                        var path = Path()
                        let x1 = a.x + PragTreeLayout.nodeW
                        let y1 = a.y + 34
                        let x2 = b.x
                        let y2 = b.y + 34
                        let mx = (x1 + x2) / 2
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addCurve(to: CGPoint(x: x2, y: y2),
                                      control1: CGPoint(x: mx, y: y1),
                                      control2: CGPoint(x: mx, y: y2))
                        context.stroke(path, with: .color(onPath ? OpportunismaTheme.red : OpportunismaTheme.line),
                                       lineWidth: onPath ? 2 : 1)
                    }
                }
                .frame(width: layout.width, height: layout.height)
                ForEach(Array(layout.nodes.values), id: \.id) { node in
                    if !blocked.contains(node.id) || node.id == selectedId {
                        PragTreeNodeCard(
                            node: node,
                            selected: node.id == selectedId,
                            onPath: pathIds.contains(node.id),
                            showRisk: overlay,
                            blocked: blocked.contains(node.id)
                        ) {
                            selectedId = node.id
                        }
                        .offset(x: node.x, y: node.y)
                    }
                }
            }
        }
        .frame(minHeight: 320)
        .pragCardStyle()
    }
    @ViewBuilder
    private var inspektor: some View {
        let node = findNode(szenario.root, id: selectedId)
        VStack(alignment: .leading, spacing: 12) {
            if let node {
                Text(node.typ.label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
                Text(node.label)
                    .font(.system(size: 16, weight: .bold))
                Text(node.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(OpportunismaTheme.gray)
                    .fixedSize(horizontal: false, vertical: true)
                if let s = node.scores {
                    Divider()
                    PragScoreBar(label: "Wirksamkeit", value: s.efficacy, color: OpportunismaTheme.red)
                    PragScoreBar(label: "Eigenrisiko", value: s.risk, color: riskColor(s.risk))
                    PragScoreBar(label: "Umkehrbarkeit", value: s.reversibility, color: .green)
                    PragScoreBar(label: "Schadensgrad", value: s.harm, color: s.harm > Int(schwelle) ? OpportunismaTheme.red : OpportunismaTheme.gray)
                    if s.harm > Int(schwelle) {
                        Text("Schadensgrad über Grenze (\(Int(schwelle))). Pfad wird gedimmt.")
                            .font(.caption2)
                            .foregroundStyle(OpportunismaTheme.red)
                    }
                    FenlynineOSTransparenzInfoButton(inhalt: .opportunismaWidget(
                        titel: node.label,
                        formel: "W=\(s.efficacy) R=\(s.risk) U=\(s.reversibility) S=\(s.harm)",
                        begruendung: "Bewertung nach Machtportal-Scoring (0–100).",
                        ergebnis: "Risiko: \(riskLabel(s.risk))"
                    ))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pragCardStyle()
    }
    private func findNode(_ node: PragTreeNode, id: String) -> PragTreeNode? {
        if node.id == id { return node }
        for c in node.children {
            if let f = findNode(c, id: id) { return f }
        }
        return nil
    }
    private func riskColor(_ r: Int) -> Color {
        r < 40 ? .green : r < 65 ? .orange : OpportunismaTheme.red
    }
    private func riskLabel(_ r: Int) -> String {
        r < 40 ? "gering" : r < 65 ? "mittel" : "hoch"
    }
}
struct PragTreeNodeCard: View {
    let node: PragTreeLayout.LaidNode
    let selected: Bool
    let onPath: Bool
    let showRisk: Bool
    let blocked: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.typ.label.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
                Text(node.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(OpportunismaTheme.ink)
                    .multilineTextAlignment(.leading)
                if let s = node.scores {
                    Text("Wirkung \(s.efficacy)")
                        .font(.system(size: 8))
                        .foregroundStyle(OpportunismaTheme.gray)
                }
            }
            .padding(10)
            .frame(width: PragTreeLayout.nodeW, alignment: .leading)
            .background(selected ? OpportunismaTheme.red.opacity(0.12) : OpportunismaTheme.card, in: OpportunismaTheme.cardShape)
            .overlay(OpportunismaTheme.cardShape.stroke(selected ? OpportunismaTheme.red : OpportunismaTheme.line, lineWidth: selected ? 2 : 1))
            .opacity(blocked ? 0.35 : 1)
        }
        .buttonStyle(.plain)
    }
}
struct PragScoreBar: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption2).foregroundStyle(OpportunismaTheme.gray)
                Spacer()
                Text("\(value)").font(.caption2.bold())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(OpportunismaTheme.grayLight)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 4)
        }
    }
}
enum PragTreeLayout {
    static let colW: CGFloat = 248
    static let nodeW: CGFloat = 200
    static let rowH: CGFloat = 116
    static let padTop: CGFloat = 28
    static let padLeft: CGFloat = 24
    struct LaidNode {
        let id: String
        var typ: PragNodeTyp
        var label: String
        var detail: String
        var scores: PragScores?
        var x: CGFloat
        var y: CGFloat
        var depth: Int
    }
    struct Edge: Hashable {
        let from: String
        let to: String
    }
    struct Result {
        var nodes: [String: LaidNode]
        var edges: [Edge]
        var width: CGFloat
        var height: CGFloat
        func pathIds(to target: String, root: PragTreeNode) -> Set<String> {
            var parent: [String: String] = [:]
            func walk(_ n: PragTreeNode, _ p: String?) {
                if let p { parent[n.id] = p }
                for c in n.children { walk(c, n.id) }
            }
            walk(root, nil)
            var ids = Set<String>()
            var cur: String? = target
            while let c = cur {
                ids.insert(c)
                cur = parent[c]
            }
            return ids
        }
        func blockedIds(root: PragTreeNode, threshold: Int) -> Set<String> {
            var blocked = Set<String>()
            func block(_ n: PragTreeNode) {
                blocked.insert(n.id)
                for c in n.children { block(c) }
            }
            func walk(_ n: PragTreeNode) {
                if let s = n.scores, s.harm > threshold { block(n) }
                for c in n.children { walk(c) }
            }
            walk(root)
            return blocked
        }
    }
    static func compute(root: PragTreeNode) -> Result {
        var nodes: [String: LaidNode] = [:]
        var edges: [Edge] = []
        var leafY = 0
        func walk(_ node: PragTreeNode, depth: Int, parent: PragTreeNode?) -> CGFloat {
            let x = padLeft + CGFloat(depth) * colW
            let y: CGFloat
            if node.children.isEmpty {
                y = padTop + CGFloat(leafY) * rowH
                leafY += 1
            } else {
                let ys = node.children.map { walk($0, depth: depth + 1, parent: node) }
                if let first = ys.first, let last = ys.last {
                    y = (first + last) / 2
                } else {
                    y = padTop + CGFloat(leafY) * rowH
                    leafY += 1
                }
            }
            nodes[node.id] = LaidNode(
                id: node.id, typ: node.typ, label: node.label, detail: node.detail,
                scores: node.scores, x: x, y: y, depth: depth
            )
            if let p = parent { edges.append(Edge(from: p.id, to: node.id)) }
            return y
        }
        _ = walk(root, depth: 0, parent: nil)
        let maxY = nodes.values.map(\.y).max() ?? 0
        let maxX = nodes.values.map(\.x).max() ?? 0
        return Result(
            nodes: nodes,
            edges: edges,
            width: maxX + nodeW + padLeft,
            height: maxY + rowH
        )
    }
}
