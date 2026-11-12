import SwiftUI
struct NexusGraphCanvas: View {
    let graph: NexusGraph
    let wurzelId: UUID
    let dichte: NexusDichte
    var onTap: (UUID) -> Void
    var onHinzufuegen: () -> Void
    private var spalte: CGFloat { dichte == .punkt ? 168 : 236 }
    var body: some View {
        Group {
            if let wurzel = graph.knoten(wurzelId) {
                ScrollView([.horizontal, .vertical]) {
                    NexusAstZweig(
                        knoten: wurzel,
                        graph: graph,
                        dichte: dichte,
                        spalte: spalte,
                        tiefe: 0,
                        maxTiefe: wurzel.typ == .norm ? 1 : 2,
                        onTap: onTap,
                        onHinzufuegen: onHinzufuegen
                    )
                    .padding(24)
                }
            } else {
                Text("Kein Anspruchsknoten.")
                    .font(.system(size: 12))
                    .foregroundStyle(InterfacePalette.sekundaer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Premium.void)
    }
}
private struct NexusAstZweig: View {
    let knoten: NexusKnoten
    let graph: NexusGraph
    let dichte: NexusDichte
    let spalte: CGFloat
    let tiefe: Int
    let maxTiefe: Int
    var onTap: (UUID) -> Void
    var onHinzufuegen: () -> Void
    private var pack: (sichtbar: [NexusKnoten], weitere: Int) {
        guard tiefe < maxTiefe else { return ([], 0) }
        return graph.sichtbareKinder(von: knoten.id)
    }
    private var karteBreite: CGFloat { dichte == .punkt ? 152 : 220 }
    var body: some View {
        let kinder = pack.sichtbar
        let cols = kinder.map { spaltenzahl($0, tiefe: tiefe + 1) }
        let gesamt = max(1, cols.reduce(0, +))
        let breite = CGFloat(gesamt) * spalte
        VStack(spacing: 0) {
            NexusKnotenKartePDF(
                knoten: knoten,
                graph: graph,
                dichte: dichte,
                istWurzel: tiefe == 0
            ) { onTap(knoten.id) }
            .frame(width: karteBreite)
            if kinder.isEmpty {
                if tiefe == 0, knoten.typ != .norm {
                    NexusAstGabel.stamm
                    NexusGeistKnoten(action: onHinzufuegen)
                }
            } else {
                NexusAstGabel(
                    spalten: cols,
                    kanten: kinder.map { graph.kanteVon($0.id) },
                    spalte: spalte
                )
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(kinder.enumerated()), id: \.element.id) { i, kind in
                        NexusAstZweig(
                            knoten: kind,
                            graph: graph,
                            dichte: dichte,
                            spalte: spalte,
                            tiefe: tiefe + 1,
                            maxTiefe: maxTiefe,
                            onTap: onTap,
                            onHinzufuegen: onHinzufuegen
                        )
                        .frame(width: CGFloat(cols[i]) * spalte, alignment: .top)
                    }
                }
                if pack.weitere > 0 {
                    Text("+\(pack.weitere) weitere — Kap. 11, max. 7 je Ebene")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(InterfacePalette.sekundaer)
                        .padding(.top, 8)
                }
            }
        }
        .frame(width: breite, alignment: .top)
    }
    private func spaltenzahl(_ k: NexusKnoten, tiefe: Int) -> Int {
        guard tiefe < maxTiefe else { return 1 }
        let kids = graph.sichtbareKinder(von: k.id).sichtbar
        if kids.isEmpty { return 1 }
        return max(1, kids.reduce(0) { $0 + spaltenzahl($1, tiefe: tiefe + 1) })
    }
}
private struct NexusAstGabel: View {
    let spalten: [Int]
    let kanten: [NexusKante?]
    let spalte: CGFloat
    static var stamm: some View {
        Rectangle()
            .fill(InterfacePalette.trennlinie)
            .frame(width: 1, height: 22)
    }
    var body: some View {
        let gesamt = max(1, spalten.reduce(0, +))
        let breite = CGFloat(gesamt) * spalte
        VStack(spacing: 0) {
            Canvas { ctx, size in
                let yArm = size.height * 0.45
                var startX: CGFloat = 0
                var mitten: [CGFloat] = []
                for c in spalten {
                    let w = CGFloat(c) * spalte
                    mitten.append(startX + w / 2)
                    startX += w
                }
                var stamm = Path()
                stamm.move(to: CGPoint(x: size.width / 2, y: 0))
                stamm.addLine(to: CGPoint(x: size.width / 2, y: yArm))
                ctx.stroke(stamm, with: .color(InterfacePalette.trennlinie), lineWidth: 1)
                if mitten.count > 1, let erst = mitten.first, let letzt = mitten.last {
                    var arm = Path()
                    arm.move(to: CGPoint(x: erst, y: yArm))
                    arm.addLine(to: CGPoint(x: letzt, y: yArm))
                    ctx.stroke(arm, with: .color(InterfacePalette.trennlinie), lineWidth: 1)
                }
                for (i, x) in mitten.enumerated() {
                    let k = i < kanten.count ? kanten[i] : nil
                    var drop = Path()
                    drop.move(to: CGPoint(x: x, y: yArm))
                    drop.addLine(to: CGPoint(x: x, y: size.height))
                    let farbe = kantenFarbe(k)
                    let dicke = CGFloat(k?.typ.strichDicke ?? 1)
                    let muster = k?.typ.strichMuster ?? []
                    if muster.isEmpty {
                        ctx.stroke(drop, with: .color(farbe), lineWidth: dicke)
                    } else {
                        ctx.stroke(
                            drop,
                            with: .color(farbe),
                            style: StrokeStyle(lineWidth: dicke, dash: muster.map { CGFloat($0) })
                        )
                    }
                }
            }
            .frame(width: breite, height: 18)
            HStack(spacing: 0) {
                ForEach(Array(kanten.enumerated()), id: \.offset) { _, kante in
                    Text(kante?.typ.label ?? "")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(kantenFarbe(kante))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: breite, height: 14)
        }
    }
    private func kantenFarbe(_ k: NexusKante?) -> Color {
        switch k?.typ {
        case .greiftAn, .schliesstAus: return InterfacePalette.kritisch
        case .entkraeftet, .stuetzt: return InterfacePalette.berechnet
        case .setztVoraus: return InterfacePalette.sekundaer
        case .alternativ: return InterfacePalette.aktion
        case .none: return InterfacePalette.trennlinie
        }
    }
}
private struct NexusGeistKnoten: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("+ Knoten")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(InterfacePalette.sekundaer)
                .frame(width: 168, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(InterfacePalette.trennlinie, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
        }
        .buttonStyle(.plain)
        .help("Kap. 10: Ghost-Knoten. Stufe 1 manuell.")
    }
}
