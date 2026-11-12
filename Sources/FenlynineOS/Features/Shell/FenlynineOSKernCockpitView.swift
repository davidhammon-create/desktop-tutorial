import SwiftUI
struct FenlynineOSKernCockpitView: View {
    @Bindable var store: FenlynineOSKernStore
    var modulOeffnen: (SchreibtischModul) -> Void
    var verknuepfungsModus: Bool
    @State private var auditorFunde: [FenlynineOSAuditorFund] = []
    @State private var zeigeAuditor = false
    @State private var gewaehlterKantenTyp: FenlynineOSKernKantenTyp = .bedingt
    @State private var exportHinweis: String?
    @State private var basisDraft = ""
    @State private var zielDraft = ""
    @State private var auditorTask: Task<Void, Never>?
    var body: some View {
        HSplitView {
            graphBereich.frame(minWidth: 420)
            seitlicheSteuerung.frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
        }
        .onAppear {
            basisDraft = store.basisSituation
            zielDraft = store.ziel
            auditorAktualisieren()
        }
        .onChange(of: store.graphRevision) { _, _ in
            auditorDebounced()
        }
        .onChange(of: zeigeAuditor) { _, offen in
            if offen { auditorAktualisieren() }
        }
        .onDisappear { auditorTask?.cancel() }
    }
    private func auditorDebounced() {
        auditorTask?.cancel()
        auditorTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            await MainActor.run { auditorAktualisieren() }
        }
    }
    private func auditorAktualisieren() {
        auditorFunde = FenlynineOSAuditorService.pruefen(store: store)
    }
    private var graphBereich: some View {
        VStack(spacing: 0) {
            graphToolbar
            Divider().opacity(0.3)
            if store.hatNetz {
                FenlynineOSKernGraphCanvas(
                    store: store,
                    verknuepfungsModus: verknuepfungsModus,
                    gewaehlterKantenTyp: gewaehlterKantenTyp,
                    onKnotenTapped: knotenTapped
                )
            } else { leerZustand }
        }
    }
    private var graphToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: verknuepfungsModus ? "link.circle.fill" : "point.3.connected.trianglepath.dotted")
                .foregroundStyle(verknuepfungsModus ? FenlynineOSTheme.warning : FenlynineOSTheme.accent)
            Text(verknuepfungsModus ? "Verknüpfungs-Modus" : "Kausalgraph")
                .font(.subheadline.bold())
            if store.hatNetz {
                ProgressView(value: store.fortschritt).frame(width: 70)
                Text(store.phase.bezeichnung).font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(FenlynineOSTheme.accent.opacity(0.12), in: Capsule())
            }
            Spacer()
            if verknuepfungsModus && store.verknuepfungsModus {
                Text("Quelle: \(store.verknuepfungQuelleId ?? "—")")
                    .font(.caption2).foregroundStyle(FenlynineOSTheme.warning)
            }
            Button { zeigeAuditor.toggle() } label: {
                Image(systemName: "checkmark.shield")
            }.help("Auditor")
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
    private func knotenTapped(_ id: String) {
        withAnimation(.spring(duration: 0.25)) {
            if verknuepfungsModus {
                if store.verknuepfungsModus, let quelle = store.verknuepfungQuelleId, quelle != id {
                    store.kanteErstellen(zuId: id, typ: gewaehlterKantenTyp, kausalitaet: "Manuell verknüpft", origin: "cockpit.verknuepfung")
                } else { store.verknuepfungStarten(mit: id) }
            } else { store.ausgewaehlterId = id }
        }
    }
    private var leerZustand: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "circle.hexagongrid.fill").font(.system(size: 44)).foregroundStyle(FenlynineOSTheme.accent.opacity(0.5))
            Text("Kausalgraph erstellen").font(.title3.bold())
            Text("PDF-Architektur: Oportun → Strategos → Lexara → Advocatus\nEin Rechenkern, ein Graph, Live-Sync")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
    }
    private var seitlicheSteuerung: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                modulLeitfaden
                eingabeKarte
                if store.hatNetz {
                    if verknuepfungsModus { verknuepfungKarte }
                    modulFlussKarte
                    automatisierungKarte
                    if let k = store.ausgewaehlterKnoten { knotenDetail(k) }
                    if zeigeAuditor { auditorKarte }
                    if let analyse = store.letzteAnalyse { analyseKarte(analyse) }
                    exportKarte
                }
            }.padding(14)
        }.background(FenlynineOSTheme.background)
    }
    private var modulLeitfaden: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Drei Denkrichtungen · eine Wahrheit").font(.caption.bold())
            ForEach([FenlynineOSKernModul.oportun, .strategos, .lexara, .advocatus], id: \.self) { m in
                HStack(spacing: 6) {
                    Circle().fill(FenlynineOSTheme.accent).frame(width: 5, height: 5)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(m.bezeichnung).font(.caption2.bold())
                        Text(m.zeitrichtung).font(.system(size: 8)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(FenlynineOSTheme.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
    private var eingabeKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Basis & Ziel", systemImage: "flag.fill").font(.subheadline.bold())
            TextEditor(text: $basisDraft).font(.caption).frame(minHeight: 52, maxHeight: 72)
                .scrollContentBackground(.hidden).padding(8).background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            TextField("Ziel …", text: $zielDraft, axis: .vertical).font(.caption).lineLimit(1...3)
                .textFieldStyle(.plain).padding(8).background(FenlynineOSTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            Button { Task { await netzGenerieren() } } label: {
                Label(store.laedt ? "Erstellt …" : "Netz erstellen", systemImage: "sparkles")
            }
            .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            .disabled(basisDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.laedt)
            if store.hatNetz {
                Button { store.zuruecksetzen() } label: { Label("Zurücksetzen", systemImage: "arrow.counterclockwise") }.buttonStyle(.borderless)
            }
        }
        .padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private var verknuepfungKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Kante ziehen", systemImage: "link").font(.caption.bold())
            Text("Quelle anklicken → Ziel anklicken → Typ wählt Rechenregel").font(.caption2).foregroundStyle(.secondary)
            Picker("Kantentyp", selection: $gewaehlterKantenTyp) {
                ForEach(FenlynineOSKernKantenTyp.allCases, id: \.self) { t in Text(t.bezeichnung).tag(t) }
            }
            if store.verknuepfungsModus {
                Button { store.verknuepfungBeenden() } label: { Text("Abbrechen") }.buttonStyle(.borderless)
            }
        }
        .padding(10).background(FenlynineOSTheme.warning.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
    private var modulFlussKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Modulflüsse", systemImage: "arrow.triangle.swap").font(.caption.bold())
            HStack(spacing: 6) {
                Button { _ = FenlynineOSModulFlussService.optionenUebergeben(von: store, ziel: .strategos) } label: {
                    Text("Oportun→Strategos").font(.caption2)
                }.buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small)
                Button {
                    if let s = store.knoten.first(where: { $0.modul == .strategos }) {
                        _ = FenlynineOSModulFlussService.szenarioNachLexara(store: store, szenarioId: s.id)
                    }
                } label: {
                    Text("→Lexara").font(.caption2)
                }.buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small)
            }
        }
        .padding(10).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    private var automatisierungKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Automatisierung", systemImage: "bolt.fill").font(.caption.bold())
            Button { _ = store.naechsterSchrittAusfuehren() } label: { Label("Nächster Schritt", systemImage: "forward.fill") }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).disabled(store.aktiveKnoten.isEmpty)
        }
        .padding(10).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    private func knotenDetail(_ k: FenlynineOSKernKnoten) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: k.typ.symbol).foregroundStyle(k.typ.farbe); Text(k.titel).font(.subheadline.bold()) }
            Text(k.modul.zeitrichtung).font(.caption2).foregroundStyle(.secondary)
            if let ev = k.ev { metrik("EV", ev) }
            if let rav = k.rav { metrik("RAV", rav) }
            if let rpn = k.rpn { metrik("RPN", rpn) }
            if let p = k.pErfolg { Text("P(Erfolg): \(Int(p*100))%").font(.caption2) }
            Text("Herkunft: \(k.herkunft)").font(.caption2).foregroundStyle(.tertiary)
            if let sm = k.modul.schreibtischModul {
                Button { modulOeffnen(sm) } label: { Label("In \(k.modul.bezeichnung) öffnen", systemImage: "arrow.up.forward.square") }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            }
            if verknuepfungsModus {
                Button { store.verknuepfungStarten(mit: k.id) } label: { Label("Als Quelle", systemImage: "link") }.buttonStyle(.borderless)
            }
        }
        .padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private func metrik(_ name: String, _ wert: Double) -> some View {
        HStack { Text(name).font(.caption2.bold()); Spacer(); Text(String(format: "%.0f", wert)).font(.caption.monospacedDigit()) }
    }
    private var auditorKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Auditor", systemImage: "checkmark.shield").font(.caption.bold())
            ForEach(auditorFunde.prefix(5)) { f in
                HStack(alignment: .top, spacing: 6) {
                    Circle().fill(auditorFarbe(f.schwere)).frame(width: 6, height: 6).padding(.top, 4)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(f.pruefung).font(.caption2.bold())
                        Text(f.begruendung).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Button { auditorFunde = FenlynineOSAuditorService.pruefen(store: store) } label: { Text("Erneut prüfen") }.buttonStyle(.borderless).font(.caption2)
        }
        .padding(10).background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
    private func auditorFarbe(_ s: FenlynineOSAuditorSchwere) -> Color {
        switch s { case .kritisch: return FenlynineOSTheme.danger; case .pruefen: return FenlynineOSTheme.warning; case .ok: return FenlynineOSTheme.success }
    }
    private func analyseKarte(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Analyse", systemImage: "brain").font(.caption.bold())
            Text(t).font(.caption2).foregroundStyle(.secondary)
        }.padding(10).background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
    private var exportKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Akte exportieren", systemImage: "doc.richtext").font(.caption.bold())
            Button {
                Task {
                    let text = FenlynineOSKernExportService.akteAlsText(store: store, funde: auditorFunde)
                    let url = await Task.detached {
                        FenlynineOSKernExportService.speichereAkte(text: text)
                    }.value
                    if let url {
                        exportHinweis = "Gespeichert: \(url.lastPathComponent)"
                        NSWorkspace.shared.open(url)
                    }
                }
            } label: { Label("PDF-Akte → Downloads", systemImage: "arrow.down.doc") }
            .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            if let h = exportHinweis { Text(h).font(.caption2).foregroundStyle(FenlynineOSTheme.success) }
        }
        .padding(10).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    private func netzGenerieren() async {
        store.basisSituation = basisDraft
        store.ziel = zielDraft
        store.laedt = true; defer { store.laedt = false }
        do {
            let r = try await FenlynineOSModulFlussService.netzErzeugen(basis: basisDraft, ziel: zielDraft)
            store.uebernehmeNetz(knoten: r.knoten, kanten: r.kanten, analyse: r.analyse)
        } catch {
            let f = FenlynineOSModulFlussService.algorithmischesNetz(basis: basisDraft, ziel: zielDraft)
            store.uebernehmeNetz(knoten: f.knoten, kanten: f.kanten, analyse: f.analyse)
        }
        auditorAktualisieren()
    }
}
struct FenlynineOSKernGraphCanvas: View {
    @Bindable var store: FenlynineOSKernStore
    var verknuepfungsModus: Bool
    var gewaehlterKantenTyp: FenlynineOSKernKantenTyp
    var onKnotenTapped: (String) -> Void
    @State private var canvasOffset: CGSize = .zero
    @State private var dragStart: CGSize = .zero
    @State private var canvasZoom: CGFloat = 1.0
    var body: some View {
        GeometryReader { geo in
            let pos = FenlynineOSKernLayout.positionen(knoten: store.knoten, in: geo.size)
            ZStack(alignment: .topTrailing) {
                ZStack {
                    rasterHintergrund
                    Canvas { ctx, _ in zeichneKanten(ctx: ctx, pos: pos) }.allowsHitTesting(false)
                    ForEach(store.knoten) { k in
                        if let p = pos[k.id] {
                            FenlynineOSKernKnotenBadge(
                                knoten: k,
                                ausgewaehlt: store.ausgewaehlterId == k.id,
                                verknuepfungAktiv: store.verknuepfungQuelleId == k.id
                            )
                            .position(
                                x: p.x * canvasZoom + canvasOffset.width,
                                y: p.y * canvasZoom + canvasOffset.height
                            )
                            .onTapGesture { onKnotenTapped(k.id) }
                        }
                    }
                }
                .gesture(DragGesture().onChanged { v in
                    canvasOffset = CGSize(
                        width: dragStart.width + v.translation.width,
                        height: dragStart.height + v.translation.height
                    )
                }.onEnded { _ in dragStart = canvasOffset })
                .onAppear { dragStart = canvasOffset }
                HStack(spacing: 4) {
                    Button { canvasZoom = max(0.5, canvasZoom - 0.15) } label: { Image(systemName: "minus.magnifyingglass") }
                    Text("\(Int(canvasZoom * 100))%").font(.caption2.monospacedDigit()).frame(width: 36)
                    Button { canvasZoom = min(2, canvasZoom + 0.15) } label: { Image(systemName: "plus.magnifyingglass") }
                }
                .buttonStyle(.borderless)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(8)
            }
        }
    }
    private var rasterHintergrund: some View {
        ZStack {
            FenlynineOSTheme.background
            Canvas { ctx, size in
                var path = Path(); let s: CGFloat = 28
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += s
                }
                var y: CGFloat = 0
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += s
                }
                ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 0.5)
            }
        }
    }
    private func zeichneKanten(ctx: GraphicsContext, pos: [String: CGPoint]) {
        for k in store.kanten {
            guard let a = pos[k.vonId], let b = pos[k.zuId] else { continue }
            let p1 = CGPoint(x: a.x * canvasZoom + canvasOffset.width, y: a.y * canvasZoom + canvasOffset.height)
            let p2 = CGPoint(x: b.x * canvasZoom + canvasOffset.width, y: b.y * canvasZoom + canvasOffset.height)
            var path = Path(); path.move(to: p1)
            path.addQuadCurve(to: p2, control: CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2))
            let gestrichelt = k.typ == .reaktion_auf || k.typ == .uebergibt
            ctx.stroke(path, with: .color(k.typ.farbe), style: StrokeStyle(lineWidth: k.typ == .uebergibt ? 2 : 1.2, dash: gestrichelt ? [5, 4] : []))
        }
    }
}
struct FenlynineOSKernKnotenBadge: View {
    let knoten: FenlynineOSKernKnoten
    let ausgewaehlt: Bool
    let verknuepfungAktiv: Bool
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().fill(knoten.typ.farbe.opacity(ausgewaehlt || verknuepfungAktiv ? 0.35 : 0.18))
                    .frame(width: ausgewaehlt ? 52 : 44, height: ausgewaehlt ? 52 : 44)
                Circle().stroke(knoten.typ.farbe.opacity(ausgewaehlt ? 1 : 0.6), lineWidth: verknuepfungAktiv ? 2.5 : 1)
                    .frame(width: ausgewaehlt ? 52 : 44, height: ausgewaehlt ? 52 : 44)
                Image(systemName: knoten.typ.symbol).font(.system(size: ausgewaehlt ? 16 : 13, weight: .semibold)).foregroundStyle(knoten.typ.farbe)
                if knoten.status == .aktiv {
                    Circle().fill(FenlynineOSTheme.success).frame(width: 8, height: 8).offset(x: 16, y: -16)
                }
            }
            Text(knoten.titel).font(.system(size: 8, weight: ausgewaehlt ? .bold : .medium))
                .foregroundStyle(ausgewaehlt ? FenlynineOSTheme.textPrimary : .secondary)
                .lineLimit(2).multilineTextAlignment(.center).frame(width: 72)
            Text(knoten.typ.bezeichnung).font(.system(size: 6, weight: .bold)).foregroundStyle(knoten.typ.farbe)
        }
    }
}
private extension FenlynineOSKernKantenTyp {
    static var reaktion_auf: FenlynineOSKernKantenTyp { .erhoeht_risiko }
}
