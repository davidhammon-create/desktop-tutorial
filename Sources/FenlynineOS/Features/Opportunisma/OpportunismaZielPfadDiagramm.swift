import SwiftUI
enum OpportunismaHorizontalZielPfadLayout {
    static let colW: CGFloat = 220
    static let nodeW: CGFloat = 168
    static let nodeH: CGFloat = 52
    static let rowH: CGFloat = 78
    static let padTop: CGFloat = 28
    static let padLeft: CGFloat = 24
    static let ausgangId = "__ausgang__"
    static let zielId = "__ziel__"
    struct LaidNode: Identifiable {
        let id: String
        var label: String
        var typ: PragNodeTyp?
        var x: CGFloat
        var y: CGFloat
        var depth: Int
        var isSynthetisch: Bool
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
    }
    static func compute(root: PragTreeNode, ausgangText: String, zielText: String) -> Result {
        var stationNodes: [String: (label: String, typ: PragNodeTyp, depth: Int)] = [:]
        var edges: [Edge] = []
        var maxDepth = 0
        func walk(_ node: PragTreeNode, depth: Int, parentId: String) {
            if node.id != root.id {
                if node.typ == .goal {
                    edges.append(Edge(from: parentId, to: zielId))
                    return
                }
                stationNodes[node.id] = (node.label, node.typ, depth)
                maxDepth = max(maxDepth, depth)
            }
            let fromId = node.id == root.id ? ausgangId : node.id
            for child in node.children {
                if child.typ == .goal {
                    edges.append(Edge(from: fromId, to: zielId))
                } else {
                    edges.append(Edge(from: fromId, to: child.id))
                    walk(child, depth: depth + 1, parentId: child.id)
                }
            }
        }
        walk(root, depth: 0, parentId: ausgangId)
        var byDepth: [Int: [String]] = [:]
        for (id, meta) in stationNodes {
            byDepth[meta.depth, default: []].append(id)
        }
        for depth in byDepth.keys {
            byDepth[depth]?.sort()
        }
        var nodes: [String: LaidNode] = [:]
        let zielDepth = max(maxDepth + 1, 1)
        nodes[ausgangId] = LaidNode(
            id: ausgangId,
            label: trimmed(ausgangText, fallback: root.label),
            typ: .position,
            x: padLeft,
            y: padTop,
            depth: 0,
            isSynthetisch: true
        )
        var maxRows = 1
        for depth in 1...maxDepth {
            let ids = byDepth[depth] ?? []
            maxRows = max(maxRows, ids.count)
            let x = padLeft + CGFloat(depth) * colW
            for (row, id) in ids.enumerated() {
                guard let meta = stationNodes[id] else { continue }
                let y = padTop + CGFloat(row) * rowH
                nodes[id] = LaidNode(
                    id: id,
                    label: meta.label,
                    typ: meta.typ,
                    x: x,
                    y: y,
                    depth: depth,
                    isSynthetisch: false
                )
            }
        }
        let zielY = padTop + CGFloat(max(0, maxRows - 1)) * rowH / 2
        nodes[zielId] = LaidNode(
            id: zielId,
            label: trimmed(zielText, fallback: "Ziel"),
            typ: .goal,
            x: padLeft + CGFloat(zielDepth) * colW,
            y: zielY,
            depth: zielDepth,
            isSynthetisch: true
        )
        let width = padLeft + CGFloat(zielDepth + 1) * colW + nodeW
        let height = padTop + CGFloat(maxRows) * rowH + nodeH
        return Result(nodes: nodes, edges: edges, width: width, height: height)
    }
    private static func trimmed(_ text: String, fallback: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return fallback }
        return String(t.prefix(72))
    }
}
struct OpportunismaZielPfadDiagramm: View {
    let root: PragTreeNode
    let ausgangText: String
    let zielText: String
    private var layout: OpportunismaHorizontalZielPfadLayout.Result {
        OpportunismaHorizontalZielPfadLayout.compute(
            root: root,
            ausgangText: ausgangText,
            zielText: zielText
        )
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HANDLUNGSPFADE ZUM ZIEL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
                Spacer()
                Text("Alle Pfade führen zum definierten Ziel")
                    .font(.system(size: 8))
                    .foregroundStyle(OpportunismaTheme.gray)
            }
            ScrollView(.horizontal, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    Canvas { context, _ in
                        for edge in layout.edges {
                            guard let a = layout.nodes[edge.from], let b = layout.nodes[edge.to] else { continue }
                            var path = Path()
                            let x1 = a.x + OpportunismaHorizontalZielPfadLayout.nodeW
                            let y1 = a.y + OpportunismaHorizontalZielPfadLayout.nodeH / 2
                            let x2 = b.x
                            let y2 = b.y + OpportunismaHorizontalZielPfadLayout.nodeH / 2
                            let mx = (x1 + x2) / 2
                            path.move(to: CGPoint(x: x1, y: y1))
                            path.addCurve(
                                to: CGPoint(x: x2, y: y2),
                                control1: CGPoint(x: mx, y: y1),
                                control2: CGPoint(x: mx, y: y2)
                            )
                            context.stroke(
                                path,
                                with: .color(OpportunismaTheme.red.opacity(0.55)),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                            )
                        }
                    }
                    .frame(width: layout.width, height: layout.height)
                    ForEach(Array(layout.nodes.values).sorted(by: { $0.depth < $1.depth || ($0.depth == $1.depth && $0.y < $1.y) })) { node in
                        OpportunismaPfadKnoten(node: node)
                            .offset(x: node.x, y: node.y)
                    }
                }
            }
            .frame(minHeight: layout.height + 8)
        }
        .padding(12)
        .pragCardStyle()
    }
}
private struct OpportunismaPfadKnoten: View {
    let node: OpportunismaHorizontalZielPfadLayout.LaidNode
    private var accent: Color {
        switch node.typ {
        case .position: return OpportunismaTheme.gray
        case .move: return OpportunismaTheme.red.opacity(0.85)
        case .outcome: return Color.blue.opacity(0.75)
        case .goal: return OpportunismaTheme.red
        case .none: return OpportunismaTheme.line
        }
    }
    private var typLabel: String {
        if node.id == OpportunismaHorizontalZielPfadLayout.ausgangId { return "Ausgangslage" }
        if node.id == OpportunismaHorizontalZielPfadLayout.zielId { return "Ziel" }
        return node.typ?.label ?? "Station"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(typLabel.uppercased())
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(accent)
            Text(node.label)
                .font(.system(size: 10, weight: node.typ == .goal || node.isSynthetisch ? .bold : .medium))
                .foregroundStyle(OpportunismaTheme.ink)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: OpportunismaHorizontalZielPfadLayout.nodeW, alignment: .leading)
        .background(
            node.typ == .goal || node.id == OpportunismaHorizontalZielPfadLayout.zielId
                ? OpportunismaTheme.red.opacity(0.12)
                : OpportunismaTheme.card,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    node.id == OpportunismaHorizontalZielPfadLayout.zielId ? OpportunismaTheme.red : OpportunismaTheme.line,
                    lineWidth: node.id == OpportunismaHorizontalZielPfadLayout.zielId ? 1.5 : 1
                )
        )
    }
}
struct OpportunismaAusgangZielEingabe: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LAGE & ZIEL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
                Spacer()
                Text("Freitext — Pfade aktualisieren sich automatisch")
                    .font(.system(size: 8))
                    .foregroundStyle(OpportunismaTheme.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ausgangslage (optional)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.gray)
                TextEditor(text: $vm.situationText)
                    .font(.system(size: 11))
                    .frame(minHeight: 52, maxHeight: 72)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(OpportunismaTheme.card, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(OpportunismaTheme.line))
                    .onChange(of: vm.situationText) { _, _ in vm.aktualisiereAusgangUndZiel() }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Strategisches Ziel")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
                TextField("Unternehmensziel eingeben …", text: $vm.zielText, axis: .vertical)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(OpportunismaTheme.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(OpportunismaTheme.red.opacity(0.35)))
                    .onChange(of: vm.zielText) { _, _ in vm.aktualisiereAusgangUndZiel() }
            }
        }
        .padding(12)
        .pragCardStyle()
    }
}
