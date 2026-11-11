import SwiftUI
struct SchreibtischVerbundnetzView: View {
    @Bindable var store: SchreibtischVerbundnetzStore
    var modulOeffnen: (SchreibtischModul) -> Void
    @State private var canvasOffset: CGSize = .zero
    @State private var dragStart: CGSize = .zero
    @State private var canvasZoom: CGFloat = 1.0
    var body: some View {
        HSplitView {
            netzBereich
                .frame(minWidth: 420)
            seitlicheSteuerung
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
        }
    }
    private var netzBereich: some View {
        VStack(spacing: 0) {
            netzToolbar
            Divider().opacity(0.3)
            if store.hatNetz {
                GeometryReader { geo in
                    let pos = VerbundNetzLayout.positionen(knoten: store.knoten, in: geo.size)
                    ZStack {
                        rasterHintergrund
                        Canvas { ctx, size in
                            zeichneKanten(ctx: ctx, pos: pos, groesse: size)
                        }
                        .allowsHitTesting(false)
                        ForEach(store.knoten) { knoten in
                            if let p = pos[knoten.id] {
                                VerbundNetzKnotenView(
                                    knoten: knoten,
                                    istAusgewaehlt: store.ausgewaehlterId == knoten.id
                                )
                                .position(
                                    x: p.x * canvasZoom + canvasOffset.width,
                                    y: p.y * canvasZoom + canvasOffset.height
                                )
                                .onTapGesture {
                                    withAnimation(.spring(duration: 0.25)) {
                                        store.ausgewaehlterId = knoten.id
                                    }
                                }
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                canvasOffset = CGSize(
                                    width: dragStart.width + v.translation.width,
                                    height: dragStart.height + v.translation.height
                                )
                            }
                            .onEnded { _ in dragStart = canvasOffset }
                    )
                    .onAppear { dragStart = canvasOffset }
                }
            } else {
                leerZustand
            }
        }
    }
    private var rasterHintergrund: some View {
        ZStack {
            FenlynineOSTheme.background
            Canvas { ctx, size in
                let schritt: CGFloat = 28
                var path = Path()
                var x: CGFloat = 0
                while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += schritt }
                var y: CGFloat = 0
                while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += schritt }
                ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 0.5)
            }
        }
    }
    private func zeichneKanten(ctx: GraphicsContext, pos: [String: CGPoint], groesse: CGSize) {
        for kante in store.kanten {
            guard let a = pos[kante.vonId], let b = pos[kante.zuId] else { continue }
            let p1 = CGPoint(x: a.x * canvasZoom + canvasOffset.width, y: a.y * canvasZoom + canvasOffset.height)
            let p2 = CGPoint(x: b.x * canvasZoom + canvasOffset.width, y: b.y * canvasZoom + canvasOffset.height)
            var path = Path()
            path.move(to: p1)
            let mx = (p1.x + p2.x) / 2, my = (p1.y + p2.y) / 2
            path.addQuadCurve(to: p2, control: CGPoint(x: mx, y: my))
            let gestrichelt = kante.typ == .reaktion_auf || kante.typ == .verzweigung
            ctx.stroke(
                path,
                with: .color(kante.typ.farbe),
                style: StrokeStyle(lineWidth: kante.typ == .vorlage_fuer ? 2 : 1.2, lineCap: .round, dash: gestrichelt ? [5, 4] : [])
            )
        }
    }
    private var netzToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .foregroundStyle(FenlynineOSTheme.accent)
            Text("Verbundnetz")
                .font(.subheadline.bold())
            if store.hatNetz {
                ProgressView(value: store.fortschritt)
                    .frame(width: 80)
                Text("\(Int(store.fortschritt * 100))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(store.phase.bezeichnung)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(FenlynineOSTheme.accent.opacity(0.12), in: Capsule())
            }
            Spacer()
            HStack(spacing: 4) {
                Button { canvasZoom = max(0.5, canvasZoom - 0.15) } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                Text("\(Int(canvasZoom * 100))%").font(.caption2.monospacedDigit()).frame(width: 36)
                Button { canvasZoom = min(2, canvasZoom + 0.15) } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
    private var leerZustand: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 44))
                .foregroundStyle(FenlynineOSTheme.accent.opacity(0.5))
            Text("Arbeitsnetz erstellen")
                .font(.title3.bold())
            Text("Basis-Situation eingeben → KI erzeugt ein Spinnennetz aller Schritte bis zum Gerichtsverfahren. Jeder Knoten wird einem Modul zugeordnet.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var seitlicheSteuerung: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                eingabeKarte
                if store.hatNetz {
                    automatisierungKarte
                    if store.phase == .verhandlung || store.phase == .gericht {
                        verhandlungKarte
                    }
                    if let knoten = store.ausgewaehlterKnoten {
                        knotenDetailKarte(knoten)
                    }
                    if let analyse = store.letzteAnalyse, !analyse.isEmpty {
                        analyseKarte(analyse)
                    }
                }
            }
            .padding(14)
        }
        .background(FenlynineOSTheme.background)
    }
    private var eingabeKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Basis & Ziel", systemImage: "flag.fill")
                .font(.subheadline.bold())
            VStack(alignment: .leading, spacing: 4) {
                Text("Basis-Situation").font(.caption2.bold()).foregroundStyle(.secondary)
                TextEditor(text: $store.basisSituation)
                    .font(.caption)
                    .frame(minHeight: 56, maxHeight: 72)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ziel").font(.caption2.bold()).foregroundStyle(.secondary)
                TextField("z.B. Vergleich, Urteil, Compliance …", text: $store.ziel, axis: .vertical)
                    .font(.caption)
                    .lineLimit(1...3)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(FenlynineOSTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }
            HStack(spacing: 8) {
                Button {
                    Task { await netzGenerieren() }
                } label: {
                    Label(store.laedt ? "Erstellt …" : "Netz erstellen", systemImage: "sparkles")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .disabled(store.basisSituation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.laedt)
                if store.hatNetz {
                    Button { store.zuruecksetzen() } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Netz zurücksetzen")
                }
            }
            if store.laedt {
                ProgressView().controlSize(.small)
            }
            if let fehler = store.fehler {
                Text(fehler).font(.caption2).foregroundStyle(FenlynineOSTheme.danger)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private var automatisierungKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Automatisierung", systemImage: "gearshape.2.fill")
                .font(.subheadline.bold())
            Text("Arbeitsschritte laufen algorithmisch weiter, sobald Voraussetzungen erfüllt sind.")
                .font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button {
                    _ = store.naechsterSchrittAusfuehren()
                } label: {
                    Label("Nächster Schritt", systemImage: "forward.fill")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .disabled(store.aktiveKnoten.isEmpty)
                Button {
                    _ = store.automatisiereBereiteSchritte()
                } label: {
                    Label("Auto-Kette", systemImage: "bolt.fill")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .disabled(store.aktiveKnoten.filter(\.automatisiert).isEmpty)
            }
            if !store.aktiveKnoten.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktiv (\(store.aktiveKnoten.count))").font(.caption2.bold()).foregroundStyle(FenlynineOSTheme.success)
                    ForEach(store.aktiveKnoten.prefix(3)) { k in
                        HStack(spacing: 6) {
                            Circle().fill(k.typ.farbe).frame(width: 6, height: 6)
                            Text(k.titel).font(.caption2).lineLimit(1)
                            if k.automatisiert {
                                Image(systemName: "bolt.fill").font(.system(size: 7)).foregroundStyle(FenlynineOSTheme.warning)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private var verhandlungKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Verhandlung — Sofort reagieren", systemImage: "person.2.wave.2.fill")
                .font(.subheadline.bold())
                .foregroundStyle(FenlynineOSTheme.danger)
            Text("Neue Situation eingeben → KI passt Taktik und Netz sofort an.")
                .font(.caption2).foregroundStyle(.secondary)
            TextField("Was ist gerade passiert?", text: $store.verhandlungsSituation, axis: .vertical)
                .font(.caption)
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .padding(8)
                .background(FenlynineOSTheme.danger.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 6) {
                ForEach(["Gegner lenkt um", "Neuer Beweis", "Richter interveniert"], id: \.self) { chip in
                    Button(chip) { store.verhandlungsSituation = chip }
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1), in: Capsule())
                        .buttonStyle(.plain)
                }
            }
            Button {
                Task { await taktikAnpassen() }
            } label: {
                Label(store.laedt ? "Passt an …" : "Taktik anpassen", systemImage: "scope")
            }
            .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            .tint(FenlynineOSTheme.danger)
            .disabled(store.verhandlungsSituation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.laedt)
        }
        .padding(12)
        .background(FenlynineOSTheme.danger.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(FenlynineOSTheme.danger.opacity(0.2)))
    }
    private func knotenDetailKarte(_ knoten: VerbundNetzKnoten) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: knoten.typ.symbol)
                    .foregroundStyle(knoten.typ.farbe)
                Text(knoten.titel).font(.subheadline.bold())
            }
            HStack(spacing: 8) {
                statusBadge(knoten.status)
                Text(knoten.typ.bezeichnung).font(.caption2).foregroundStyle(.secondary)
            }
            if !knoten.beschreibung.isEmpty {
                Text(knoten.beschreibung).font(.caption).foregroundStyle(.secondary)
            }
            if let trigger = knoten.kausalTrigger, !trigger.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.triangle.branch").font(.caption2).foregroundStyle(FenlynineOSTheme.warning)
                    Text(trigger).font(.caption2).foregroundStyle(FenlynineOSTheme.warning)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: knoten.modul.eintrag.macSettingsSymbol)
                    .font(.caption)
                    .foregroundStyle(knoten.modul.eintrag.macSettingsIconColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(knoten.modul.titel).font(.caption.bold())
                    Text(knoten.modulAktion).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(knoten.modul.eintrag.macSettingsIconColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            let eingehend = store.kanten.filter { $0.zuId == knoten.id }
            if !eingehend.isEmpty {
                Text("Verknüpfungen").font(.caption2.bold()).foregroundStyle(.secondary)
                ForEach(eingehend.prefix(3)) { k in
                    if let von = store.knoten.first(where: { $0.id == k.vonId }) {
                        HStack(spacing: 4) {
                            Text(k.typ.bezeichnung).font(.system(size: 8)).foregroundStyle(k.typ.farbe)
                            Text("← \(von.titel)").font(.caption2).lineLimit(1)
                        }
                    }
                }
            }
            Button {
                modulOeffnen(knoten.modul)
            } label: {
                Label("In \(knoten.modul.titel) öffnen", systemImage: "arrow.up.forward.square")
            }
            .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            if knoten.status == .aktiv {
                Button {
                    store.markiereErledigt(knoten.id)
                    store.speichern()
                } label: {
                    Label("Als erledigt markieren", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(FenlynineOSTheme.success)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(knoten.typ.farbe.opacity(0.35), lineWidth: 1)
        )
    }
    private func analyseKarte(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("KI-Analyse", systemImage: "brain")
                .font(.caption.bold())
            Text(text).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
    private func statusBadge(_ status: VerbundNetzSchrittStatus) -> some View {
        Text(status.bezeichnung)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(statusFarbe(status).opacity(0.15), in: Capsule())
            .foregroundStyle(statusFarbe(status))
    }
    private func statusFarbe(_ status: VerbundNetzSchrittStatus) -> Color {
        switch status {
        case .wartend: return .secondary
        case .aktiv: return FenlynineOSTheme.success
        case .erledigt: return FenlynineOSTheme.accent
        case .blockiert: return FenlynineOSTheme.danger
        }
    }
    private func netzGenerieren() async {
        store.laedt = true
        store.fehler = nil
        defer { store.laedt = false }
        do {
            let result = try await SchreibtischVerbundnetzService.netzErzeugen(
                basis: store.basisSituation,
                ziel: store.ziel
            )
            store.uebernehmeNetz(knoten: result.knoten, kanten: result.kanten, analyse: result.analyse)
        } catch {
            let fallback = SchreibtischVerbundnetzService.algorithmischesNetz(
                basis: store.basisSituation,
                ziel: store.ziel
            )
            store.uebernehmeNetz(knoten: fallback.knoten, kanten: fallback.kanten, analyse: fallback.analyse)
            store.fehler = "KI nicht erreichbar — Standard-Netz verwendet."
        }
    }
    private func taktikAnpassen() async {
        store.laedt = true
        defer { store.laedt = false }
        do {
            let result = try await SchreibtischVerbundnetzService.taktikAnpassen(
                basis: store.basisSituation,
                ziel: store.ziel,
                situation: store.verhandlungsSituation,
                bestehendeKnoten: store.knoten,
                bestehendeKanten: store.kanten
            )
            store.fuegeTaktikAnpassungHinzu(knoten: result.knoten, kanten: result.kanten)
            store.letzteAnalyse = result.empfehlung
            store.ausgewaehlterId = result.knoten.first?.id
            store.verhandlungsSituation = ""
        } catch {
            store.fehler = "Taktik-Anpassung fehlgeschlagen."
        }
    }
}
struct VerbundNetzKnotenView: View {
    let knoten: VerbundNetzKnoten
    let istAusgewaehlt: Bool
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(knoten.typ.farbe.opacity(istAusgewaehlt ? 0.35 : 0.18))
                    .frame(width: istAusgewaehlt ? 52 : 44, height: istAusgewaehlt ? 52 : 44)
                Circle()
                    .stroke(knoten.typ.farbe.opacity(istAusgewaehlt ? 1 : 0.6), lineWidth: istAusgewaehlt ? 2 : 1)
                    .frame(width: istAusgewaehlt ? 52 : 44, height: istAusgewaehlt ? 52 : 44)
                Image(systemName: knoten.typ.symbol)
                    .font(.system(size: istAusgewaehlt ? 16 : 13, weight: .semibold))
                    .foregroundStyle(knoten.typ.farbe)
                if knoten.status == .aktiv {
                    Circle()
                        .fill(FenlynineOSTheme.success)
                        .frame(width: 8, height: 8)
                        .offset(x: 16, y: -16)
                }
                if knoten.automatisiert {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(FenlynineOSTheme.warning)
                        .offset(x: -16, y: -16)
                }
            }
            Text(knoten.titel)
                .font(.system(size: 8, weight: istAusgewaehlt ? .bold : .medium))
                .foregroundStyle(istAusgewaehlt ? FenlynineOSTheme.textPrimary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72)
        }
    }
}
