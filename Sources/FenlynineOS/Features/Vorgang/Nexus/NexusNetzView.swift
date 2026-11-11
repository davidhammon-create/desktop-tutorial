import SwiftUI
struct NexusNetzView: View {
    let graph: NexusGraph
    var dichte: NexusDichte
    @Binding var fokus: UUID?
    @Binding var krumen: [UUID]
    var onHinzufuegen: (UUID) -> Void
    var onPTap: (() -> Void)? = nil
    private var wurzel: NexusKnoten? { graph.wuerzel().first }
    private var aktivId: UUID {
        fokus ?? astStart ?? wurzel?.id ?? UUID()
    }
    private var astStart: UUID? {
        if let luecke = graph.knoten.first(where: { $0.kern.localizedCaseInsensitiveContains("salvatorisch") }) {
            return luecke.id
        }
        return graph.merkmale().max { a, b in
            nachfahren(a.id) < nachfahren(b.id)
        }.flatMap { m in nachfahren(m.id) == 0 ? nil : m.id }
    }
    private func nachfahren(_ id: UUID) -> Int {
        let k = graph.kinder(von: id)
        return k.count + k.reduce(0) { $0 + nachfahren($1.id) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brotkrumen
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(InterfacePalette.Material.l1)
            Rectangle().fill(InterfacePalette.trennlinie).frame(height: 1)
            if graph.knoten(aktivId) != nil {
                NexusGraphCanvas(
                    graph: graph,
                    wurzelId: aktivId,
                    dichte: dichte,
                    onTap: { id in
                        if id == aktivId { return }
                        zoom(auf: id)
                    },
                    onHinzufuegen: { onHinzufuegen(aktivId) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            NexusFormelBanner(graph: graph)
                .padding(12)
        }
        .background(NexusPapier.grund)
        .onAppear {
            if fokus == nil, let start = astStart ?? wurzel?.id {
                fokus = start
            }
        }
    }
    private var brotkrumen: some View {
        let kette = ketteIds
        let sichtbar = Array(kette.suffix(3))
        return HStack(spacing: 6) {
            if kette.count > 3 {
                Text("…").font(.system(size: 11)).foregroundStyle(NexusPapier.leise)
            }
            ForEach(sichtbar, id: \.self) { id in
                Button { springe(zu: id) } label: {
                    Text(krumenText(id))
                        .font(.system(size: 11, weight: id == kette.last ? .semibold : .regular))
                        .foregroundStyle(id == kette.last ? NexusPapier.text : NexusPapier.leise)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                if id != sichtbar.last {
                    Text("›").foregroundStyle(NexusPapier.leise)
                }
            }
            Spacer(minLength: 8)
            Button {
                onPTap?()
            } label: {
                HStack(spacing: 6) {
                    Text("P(Erfolg)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NexusPapier.leise)
                    Text(NexusAnzeige.band(graph.pErfolg))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(InterfacePalette.berechnet)
                }
            }
            .buttonStyle(.plain)
            .help("Herleitung öffnen")
        }
    }
    private func krumenText(_ id: UUID) -> String {
        guard let k = graph.knoten(id) else { return "·" }
        if k.typ == .merkmal, let idx = graph.merkmale().firstIndex(where: { $0.id == id }) {
            return "Merkmal \(idx + 1): \(k.kern)"
        }
        return k.kern
    }
    private var ketteIds: [UUID] {
        var kette: [UUID] = []
        var id: UUID? = aktivId
        var schutz = 0
        while let x = id, schutz < 24 {
            kette.insert(x, at: 0)
            id = graph.knoten(x)?.parentId
            schutz += 1
        }
        return kette
    }
    private func zoom(auf id: UUID) {
        fokus = id
    }
    private func springe(zu id: UUID) {
        fokus = id
    }
}
struct NexusListePDF: View {
    let graph: NexusGraph
    var dichte: NexusDichte
    var onTap: (UUID) -> Void
    var body: some View {
        let eigen = graph.knoten.filter { $0.typ == .argEigen && $0.status != .verworfen }.sorted { $0.sNetto > $1.sNetto }
        let gegner = graph.knoten.filter { $0.typ == .argGegner && $0.status != .verworfen }.sorted { $0.sNetto > $1.sNetto }
        return VStack(alignment: .leading, spacing: 16) {
            Text("PRO / CONTRA — NACH NETTOSTÄRKE")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(InterfacePalette.sekundaer)
            HStack(alignment: .top, spacing: 16) {
                spalte("EIGEN · KONTER", eigen)
                spalte("GEGNER · ANGRIFF", gegner)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NexusPapier.grund)
    }
    private func spalte(_ titel: String, _ knoten: [NexusKnoten]) -> some View {
        let sichtbar = Array(knoten.prefix(7))
        return VStack(alignment: .leading, spacing: 8) {
            Text(titel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(NexusPapier.leise)
            ForEach(sichtbar) { k in
                NexusKnotenKartePDF(knoten: k, graph: graph, dichte: dichte) { onTap(k.id) }
            }
            if knoten.count > 7 {
                Text("+\(knoten.count - 7) weitere")
                    .font(.system(size: 11))
                    .foregroundStyle(NexusPapier.leise)
            }
            if sichtbar.isEmpty {
                Text("—").font(.system(size: 12)).foregroundStyle(NexusPapier.leise)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct NexusSchriftsatzPDF: View {
    let graph: NexusGraph
    var body: some View {
        ScrollView {
            Text(NexusDemo.schriftsatz(graph))
                .font(.system(size: 13))
                .foregroundStyle(NexusPapier.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(NexusPapier.grund)
    }
}
