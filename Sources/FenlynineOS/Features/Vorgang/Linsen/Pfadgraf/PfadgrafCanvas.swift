import SwiftUI
import AppKit
struct PfadgrafCanvas: View {
    let graf: Pfadgraf
    let layout: PfadgrafLayoutErgebnis
    let auswertung: PfadgrafAuswertung
    let hervorgehobeneKanten: Set<UUID>
    var onKnotenTap: (UUID) -> Void
    var onKnotenMoved: (UUID, CGFloat, CGFloat) -> Void
    var onKante: (UUID) -> Void
    var onKanteEinfuegen: (UUID) -> Void
    private let knotenR: CGFloat = 16
    private let dragSchwelle: CGFloat = 5
    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var panStart: CGSize = .zero
    @State private var dragKnotenId: UUID?
    @State private var dragDelta: CGSize = .zero
    @State private var hatGezogen = false
    @State private var hintergrundPanAktiv = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(nsColor: .textBackgroundColor).opacity(0.35)
                    .contentShape(Rectangle())
                    .gesture(hintergrundPan)
                ZStack(alignment: .topLeading) {
                    zeichnung
                        .frame(width: layout.breite, height: layout.hoehe)
                    ForEach(layout.punkte, id: \.knotenId) { p in
                        let pt = anzeigePunkt(p)
                        Circle()
                            .fill(Color.primary.opacity(dragKnotenId == p.knotenId ? 0.08 : 0.001))
                            .frame(width: knotenR * 2 + 14, height: knotenR * 2 + 14)
                            .overlay {
                                if dragKnotenId == p.knotenId {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                        .frame(width: knotenR * 2 + 20, height: knotenR * 2 + 20)
                                }
                            }
                            .position(x: pt.x, y: pt.y)
                            .gesture(knotenDrag(p))
                            .help("Ziehen: Position · Klick: Zustandsblatt")
                    }
                    ForEach(graf.kanten) { kante in
                        if let mitte = kantenMitte(kante) {
                            Circle()
                                .fill(Color.primary.opacity(0.001))
                                .frame(width: 22, height: 22)
                                .position(mitte)
                                .onTapGesture {
                                    if NSEvent.modifierFlags.contains(.option) {
                                        onKanteEinfuegen(kante.id)
                                    } else {
                                        onKante(kante.id)
                                    }
                                }
                                .help("Klick: Handlungsblatt · ⌥-Klick: Knoten einfügen")
                        }
                    }
                }
                .frame(width: layout.breite, height: layout.hoehe)
                .scaleEffect(zoom, anchor: .topLeading)
                .offset(pan)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Label(graf.layout.fortschrittsHinweis, systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                        Spacer(minLength: 8)
                        Text(String(format: "%.0f %%", zoom * 100))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                            .allowsHitTesting(false)
                        Button { zoom = max(0.4, zoom - 0.1) } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .buttonStyle(.borderless)
                        .help("Verkleinern")
                        Button { zoom = min(2.5, zoom + 0.1) } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .buttonStyle(.borderless)
                        .help("Vergrößern")
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                zoom = 1
                                pan = .zero
                                panStart = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Ansicht zurücksetzen (Zoom & Pan)")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    Spacer(minLength: 0)
                        .allowsHitTesting(false)
                    if dragKnotenId != nil {
                        Text("Knoten verschieben — Loslassen speichert die Position")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 8)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .clipped()
            .onAppear { zentriereWennNoetig(in: geo.size) }
        }
        .help("Knoten ziehen · Leere Fläche wischen (pan) · Zoom-Buttons · Klick öffnet Detail")
    }
    private var hintergrundPan: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { wert in
                guard dragKnotenId == nil else { return }
                if !hintergrundPanAktiv {
                    hintergrundPanAktiv = true
                    panStart = pan
                }
                pan = CGSize(
                    width: panStart.width + wert.translation.width,
                    height: panStart.height + wert.translation.height
                )
            }
            .onEnded { _ in
                hintergrundPanAktiv = false
                panStart = pan
            }
    }
    private func knotenDrag(_ p: PfadgrafLayoutPunkt) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { wert in
                if dragKnotenId == nil {
                    dragKnotenId = p.knotenId
                    hatGezogen = false
                }
                guard dragKnotenId == p.knotenId else { return }
                dragDelta = wert.translation
                if hypot(wert.translation.width, wert.translation.height) > dragSchwelle {
                    hatGezogen = true
                }
            }
            .onEnded { wert in
                defer {
                    dragKnotenId = nil
                    dragDelta = .zero
                    hatGezogen = false
                }
                guard dragKnotenId == p.knotenId else { return }
                if hatGezogen || hypot(wert.translation.width, wert.translation.height) > dragSchwelle {
                    let nx = p.x + wert.translation.width / zoom
                    let ny = p.y + wert.translation.height / zoom
                    onKnotenMoved(p.knotenId, max(24, nx), max(24, ny))
                } else {
                    onKnotenTap(p.knotenId)
                }
            }
    }
    private func anzeigePunkt(_ p: PfadgrafLayoutPunkt) -> CGPoint {
        if dragKnotenId == p.knotenId {
            return CGPoint(x: p.x + dragDelta.width / zoom, y: p.y + dragDelta.height / zoom)
        }
        return CGPoint(x: p.x, y: p.y)
    }
    private func kantenMitte(_ kante: PfadgrafKante) -> CGPoint? {
        guard let von = layout.punkte.first(where: { $0.knotenId == kante.von }),
              let nach = layout.punkte.first(where: { $0.knotenId == kante.nach }) else { return nil }
        let a = anzeigePunkt(von)
        let b = anzeigePunkt(nach)
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
    private func zentriereWennNoetig(in size: CGSize) {
        if layout.breite < size.width {
            pan.width = (size.width - layout.breite * zoom) / 2
        }
        if layout.hoehe < size.height {
            pan.height = max(28, (size.height - layout.hoehe * zoom) / 4)
        }
        panStart = pan
    }
    private var zeichnung: some View {
        Canvas { context, size in
            let punkteMap = Dictionary(uniqueKeysWithValues: layout.punkte.map { ($0.knotenId, anzeigePunkt($0)) })
            let hatHervorhebung = !hervorgehobeneKanten.isEmpty
            if graf.layout == .zeitachse {
                for frist in layout.fristLinien {
                    let x = 70 + CGFloat(frist.tage) * (size.width - 140)
                    var linie = Path()
                    linie.move(to: CGPoint(x: x, y: 20))
                    linie.addLine(to: CGPoint(x: x, y: size.height - 20))
                    context.stroke(linie, with: .color(.primary.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                    context.draw(
                        Text(frist.label).font(.system(size: 8)).foregroundStyle(.primary.opacity(0.7)),
                        at: CGPoint(x: x + 4, y: 28),
                        anchor: .topLeading
                    )
                }
                for tag in [0, 30, 60, 90, 120] {
                    let x = 70 + CGFloat(tag) / 120.0 * (size.width - 140)
                    context.draw(
                        Text("Tag \(tag)").font(.system(size: 8)).foregroundStyle(.secondary),
                        at: CGPoint(x: x, y: size.height - 10),
                        anchor: .center
                    )
                }
            }
            for kante in graf.kanten {
                guard let p1 = punkteMap[kante.von], let p2 = punkteMap[kante.nach] else { continue }
                let hervorgehoben = hervorgehobeneKanten.contains(kante.id)
                let opacity: Double = hatHervorhebung ? (hervorgehoben ? 1.0 : 0.3) : 1.0
                let dicke: CGFloat = kante.art == .empfohlen || hervorgehoben ? 2.2 : 1.2
                var pfad = Path()
                pfad.move(to: p1)
                if abs(p1.x - p2.x) < 2 || abs(p1.y - p2.y) < 2 {
                    pfad.addLine(to: p2)
                } else {
                    let ctrl = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                    pfad.addQuadCurve(to: p2, control: ctrl)
                }
                let dash: [CGFloat]
                switch kante.art {
                case .bedingt: dash = [6, 4]
                case .fremd:   dash = [2, 3]
                default:       dash = []
                }
                context.stroke(
                    pfad,
                    with: .color(.primary.opacity(opacity)),
                    style: StrokeStyle(lineWidth: dicke, lineCap: .round, dash: dash)
                )
                let t: CGFloat = 0.6
                let ax = p1.x + (p2.x - p1.x) * t
                let ay = p1.y + (p2.y - p1.y) * t
                let winkel = atan2(p2.y - p1.y, p2.x - p1.x)
                var pfeil = Path()
                let laenge: CGFloat = 7
                pfeil.move(to: CGPoint(x: ax, y: ay))
                pfeil.addLine(to: CGPoint(
                    x: ax - laenge * cos(winkel - 0.4),
                    y: ay - laenge * sin(winkel - 0.4)
                ))
                pfeil.move(to: CGPoint(x: ax, y: ay))
                pfeil.addLine(to: CGPoint(
                    x: ax - laenge * cos(winkel + 0.4),
                    y: ay - laenge * sin(winkel + 0.4)
                ))
                context.stroke(pfeil, with: .color(.primary.opacity(opacity)), style: StrokeStyle(lineWidth: dicke, lineCap: .round))
                if graf.kantenKennzahl != .keine {
                    let label: String
                    switch graf.kantenKennzahl {
                    case .kosten: label = "\(Int(kante.kosten))"
                    case .dauer:  label = "\(kante.dauerMinTage)–\(kante.dauerMaxTage)d"
                    case .p:      label = String(format: "%.0f %%", kante.pErfolg * 100)
                    case .keine:  label = ""
                    }
                    context.draw(
                        Text(label).font(.system(size: 8, weight: .medium)).foregroundStyle(.primary.opacity(opacity * 0.85)),
                        at: CGPoint(x: ax, y: ay - 10),
                        anchor: .center
                    )
                }
            }
            let engpass = Set(auswertung.engpassKnotenIds)
            for kn in graf.knoten {
                guard let pt = punkteMap[kn.id] else { continue }
                let aufPfad = !hatHervorhebung
                    || graf.kanten.contains { hervorgehobeneKanten.contains($0.id) && ($0.von == kn.id || $0.nach == kn.id) }
                    || graf.startKnotenId == kn.id
                    || graf.zielKnotenIds.contains(kn.id)
                let opacity: Double = hatHervorhebung ? (aufPfad ? 1.0 : 0.3) : 1.0
                let rect = CGRect(x: pt.x - knotenR, y: pt.y - knotenR, width: knotenR * 2, height: knotenR * 2)
                switch kn.typ {
                case .ist:
                    context.fill(Path(ellipseIn: rect), with: .color(.primary.opacity(opacity)))
                    context.draw(
                        Text(kn.kennung).font(.system(size: 11, weight: .bold)).foregroundStyle(.background),
                        at: CGPoint(x: pt.x, y: pt.y),
                        anchor: .center
                    )
                case .geplant:
                    context.stroke(Path(ellipseIn: rect), with: .color(.primary.opacity(opacity)), lineWidth: 1.5)
                    context.draw(
                        Text(kn.kennung).font(.system(size: 11, weight: .bold)).foregroundStyle(.primary.opacity(opacity)),
                        at: CGPoint(x: pt.x, y: pt.y),
                        anchor: .center
                    )
                case .fremd:
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.primary.opacity(opacity)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])
                    )
                    context.draw(
                        Text(kn.kennung).font(.system(size: 10, weight: .bold)).foregroundStyle(.primary.opacity(opacity)),
                        at: CGPoint(x: pt.x, y: pt.y),
                        anchor: .center
                    )
                case .ziel:
                    let aussen = rect.insetBy(dx: -3, dy: -3)
                    context.stroke(Path(ellipseIn: aussen), with: .color(.primary.opacity(opacity)), lineWidth: 1)
                    context.stroke(Path(ellipseIn: rect), with: .color(.primary.opacity(opacity)), lineWidth: 2)
                    context.draw(
                        Text(kn.kennung).font(.system(size: 11, weight: .bold)).foregroundStyle(.primary.opacity(opacity)),
                        at: CGPoint(x: pt.x, y: pt.y),
                        anchor: .center
                    )
                }
                if engpass.contains(kn.id) {
                    var raute = Path()
                    let r: CGFloat = knotenR + 8
                    raute.move(to: CGPoint(x: pt.x, y: pt.y - r))
                    raute.addLine(to: CGPoint(x: pt.x + r, y: pt.y))
                    raute.addLine(to: CGPoint(x: pt.x, y: pt.y + r))
                    raute.addLine(to: CGPoint(x: pt.x - r, y: pt.y))
                    raute.closeSubpath()
                    context.stroke(raute, with: .color(.primary.opacity(opacity * 0.7)), style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
                }
                if kn.hatManuellePosition {
                    context.draw(
                        Text("⠿").font(.system(size: 7)).foregroundStyle(.secondary.opacity(opacity * 0.6)),
                        at: CGPoint(x: pt.x + knotenR + 2, y: pt.y + knotenR - 2),
                        anchor: .bottomLeading
                    )
                }
                if let kw = auswertung.knotenWerte[kn.id] {
                    let evText = graf.optimierung == .erwartungswert
                        ? String(format: "EV %.0f", kw)
                        : String(format: "%.0f", kw)
                    context.draw(
                        Text(evText).font(.system(size: 8, weight: .semibold, design: .monospaced)).foregroundStyle(.primary.opacity(opacity * 0.7)),
                        at: CGPoint(x: pt.x, y: pt.y + knotenR + 11),
                        anchor: .top
                    )
                }
                let label = kn.bezeichnung
                let kurz = label.count > 40 ? String(label.prefix(37)) + "…" : label
                switch graf.layout {
                case .vertikal:
                    context.draw(
                        Text(kurz).font(.system(size: 9)).foregroundStyle(.primary.opacity(opacity * 0.75)),
                        at: CGPoint(x: pt.x + knotenR + 8, y: pt.y),
                        anchor: .leading
                    )
                case .horizontal, .zeitachse:
                    context.draw(
                        Text(kurz).font(.system(size: 9)).foregroundStyle(.primary.opacity(opacity * 0.75)),
                        at: CGPoint(x: pt.x, y: pt.y - knotenR - 8),
                        anchor: .bottom
                    )
                }
            }
        }
    }
}
