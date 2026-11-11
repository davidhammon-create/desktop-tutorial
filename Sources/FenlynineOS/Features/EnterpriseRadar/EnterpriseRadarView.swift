import SwiftUI
enum ERTab: String, CaseIterable, Identifiable {
    case matrix, schwaechen, vorteile, strategien, fristen, ki
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .matrix: return "Risikomatrix"
        case .schwaechen: return "Schwachstellen"
        case .vorteile: return "Vorteile"
        case .strategien: return "Strategien"
        case .fristen: return "Stichtage"
        case .ki: return "KI-Synthese"
        }
    }
    var symbol: String {
        switch self {
        case .matrix: return "square.grid.3x3.fill"
        case .schwaechen: return "exclamationmark.triangle.fill"
        case .vorteile: return "arrow.up.right.circle.fill"
        case .strategien: return "flag.checkered"
        case .fristen: return "calendar.badge.exclamationmark"
        case .ki: return "sparkles"
        }
    }
}
extension ERSchwere {
    var farbe: Color {
        switch self {
        case .gering: return Premium.computed
        case .mittel: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .hoch: return Premium.proposed
        case .kritisch: return Premium.critical
        }
    }
}
extension ERVorteilTyp {
    var farbe: Color {
        switch self {
        case .offensiv: return Premium.critical
        case .defensiv: return Premium.action
        case .positionierung: return Premium.computed
        case .verhandlung: return Premium.proposed
        }
    }
}
struct EnterpriseRadarView: View {
    @State private var store = EnterpriseRadarStore.shared
    @State private var tab: ERTab = .matrix
    @State private var ausgewaehltesUnternehmen: String = ""
    @State private var exportHinweis = ""
    @State private var offeneDimension: ERDimension?
    var body: some View {
        VStack(spacing: 0) {
            kopf
            Divider().overlay(Premium.hairline)
            HStack(spacing: 0) {
                profilSpalte.frame(width: 340)
                Divider().overlay(Premium.hairline)
                inhalt
            }
        }
        .background(Premium.void)
        .fenlynineOSAdaptiveNavigationTitle("Enterprise-Radar")
        .onAppear {
            if ausgewaehltesUnternehmen.isEmpty { ausgewaehltesUnternehmen = store.eigen.id }
            if store.ergebnis == nil { store.analysiere() }
        }
    }
    private var kopf: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enterprise-Radar")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Premium.text)
                Text("Jedes rechtliche Risiko · Schwächen eigen und beim Wettbewerber · Vorteil · Strategie. \(EnterpriseRadarEngine.regeln.count) Regeln, 14 Dimensionen, deterministisch — KI nur zur Vertiefung.")
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
            }
            Spacer()
            if let e = store.ergebnis {
                kpi("Gesamtrisiko", "\(e.gesamtscoreEigen)", ERSchwere.aus(score: e.gesamtscoreEigen).farbe)
                kpi("Resilienz", "\(e.resilienzIndex)", Premium.computed)
                kpi("Vorteilsindex", "\(e.vorteilsIndex)", Premium.proposed)
                kpi("Engine", String(format: "%.1f ms", store.letzteDauerMs), Premium.textFaint)
            }
            Button {
                store.analysiere()
            } label: {
                Label("Analysieren", systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(.borderedProminent)
            .tint(Premium.action)
            .keyboardShortcut(.return, modifiers: .command)
            Menu {
                Button("Ins Entscheidungsjournal") { store.insJournal(); exportHinweis = "Journal ✓" }
                Button("Markdown in Zwischenablage") { kopiereMarkdown() }
            } label: {
                Label(exportHinweis.isEmpty ? "Export" : exportHinweis, systemImage: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(16)
        .background(Premium.ink)
    }
    private func kpi(_ titel: String, _ wert: String, _ farbe: Color) -> some View {
        VStack(spacing: 2) {
            Text(wert).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(farbe)
            Text(titel.uppercased()).font(.system(size: 9, weight: .semibold)).foregroundStyle(Premium.textFaint).tracking(0.6)
        }
        .frame(minWidth: 70)
    }
    private func kopiereMarkdown() {
        let md = store.exportMarkdown()
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(md, forType: .string)
        #else
        UIPasteboard.general.string = md
        #endif
        exportHinweis = "Kopiert ✓"
    }
    private var profilSpalte: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    unternehmenChip(store.eigen)
                    ForEach(store.wettbewerber) { w in unternehmenChip(w) }
                    Button { store.wettbewerberHinzufuegen() } label: {
                        Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(Circle().fill(Premium.well))
                }
                .padding(12)
            }
            Divider().overlay(Premium.hairline)
            if let u = store.unternehmen(ausgewaehltesUnternehmen) ?? Optional(store.eigen) {
                ScrollView {
                    ERProfilEditor(unternehmen: u, store: store, offeneDimension: $offeneDimension)
                        .padding(14)
                }
            }
        }
        .background(Premium.ink)
    }
    private func unternehmenChip(_ u: ERUnternehmen) -> some View {
        Button {
            ausgewaehltesUnternehmen = u.id
        } label: {
            HStack(spacing: 6) {
                Image(systemName: u.rolle == .eigen ? "building.2.fill" : "flag.fill")
                Text(u.name.isEmpty ? u.rolle.titel : u.name).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .premiumChip(active: ausgewaehltesUnternehmen == u.id, tint: u.rolle == .eigen ? Premium.action : Premium.proposed)
    }
    private var inhalt: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(ERTab.allCases) { t in
                    Button { tab = t } label: {
                        Label(t.titel, systemImage: t.symbol).labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .premiumChip(active: tab == t)
                }
                Spacer()
                if let e = store.ergebnis {
                    Text("Stand \(e.zeitpunkt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 10)).foregroundStyle(Premium.textFaint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider().overlay(Premium.hairline)
            if let e = store.ergebnis {
                ScrollView {
                    Group {
                        switch tab {
                        case .matrix: ERMatrixAnsicht(ergebnis: e, offeneDimension: $offeneDimension)
                        case .schwaechen: ERSchwaechenAnsicht(ergebnis: e)
                        case .vorteile: ERVorteileAnsicht(ergebnis: e)
                        case .strategien: ERStrategienAnsicht(ergebnis: e)
                        case .fristen: ERFristenAnsicht(ergebnis: e)
                        case .ki: ERKIAnsicht(store: store)
                        }
                    }
                    .padding(16)
                }
            } else {
                Spacer()
                Text("Profil ausfüllen und analysieren.").foregroundStyle(Premium.textSoft)
                Spacer()
            }
        }
    }
}
private struct ERProfilEditor: View {
    let unternehmen: ERUnternehmen
    let store: EnterpriseRadarStore
    @Binding var offeneDimension: ERDimension?
    private func binde<T>(_ kp: WritableKeyPath<ERUnternehmen, T>) -> Binding<T> {
        Binding(
            get: { store.unternehmen(unternehmen.id)?[keyPath: kp] ?? unternehmen[keyPath: kp] },
            set: { neu in
                var u = store.unternehmen(unternehmen.id) ?? unternehmen
                u[keyPath: kp] = neu
                store.aktualisiere(u)
            }
        )
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sektion(unternehmen.rolle.titel)
                Spacer()
                if unternehmen.rolle == .konkurrent {
                    Button(role: .destructive) { store.wettbewerberEntfernen(unternehmen.id) } label: {
                        Image(systemName: "trash").font(.system(size: 11))
                    }.buttonStyle(.plain).foregroundStyle(Premium.textFaint)
                }
            }
            TextField("Name", text: binde(\.name))
                .textFieldStyle(.roundedBorder)
            Picker("Branche", selection: binde(\.branche)) {
                ForEach(ERBranche.allCases) { b in Text(b.titel).tag(b) }
            }
            Picker("Sitz", selection: binde(\.sitz)) {
                ForEach(ERLand.allCases) { l in Text(l.titel).tag(l) }
            }
            zahl("Mitarbeiter", binde(\.mitarbeiter), schritt: 50)
            zahlD("Umsatz (Mio. €)", binde(\.umsatzMio), schritt: 10)
            zahlD("Marktanteil (%)", binde(\.marktanteil), schritt: 5, max: 100)
            zahl("Patente", binde(\.patente), schritt: 1)
            zahl("Marken", binde(\.marken), schritt: 1)
            Toggle("Börsennotiert / kapitalmarktorientiert", isOn: binde(\.boersennotiert))
                .font(.system(size: 11))
            sektion("Signale (\(unternehmen.signale.count) aktiv)")
            ForEach(ERDimension.allCases) { d in
                let signale = ERSignal.allCases.filter { $0.dimension == d && (unternehmen.rolle == .eigen || $0.vonAussenBeobachtbar) }
                let aktiv = signale.filter { unternehmen.signale.contains($0) }.count
                DisclosureGroup(isExpanded: Binding(
                    get: { offeneDimension == d },
                    set: { offeneDimension = $0 ? d : nil }
                )) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(signale) { s in
                            Toggle(isOn: Binding(
                                get: { store.unternehmen(unternehmen.id)?.signale.contains(s) ?? false },
                                set: { _ in store.signalUmschalten(s, bei: unternehmen.id) }
                            )) {
                                Text(s.titel).font(.system(size: 11)).foregroundStyle(Premium.text)
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                    .padding(.vertical, 6)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: d.symbol).font(.system(size: 11)).foregroundStyle(Premium.action).frame(width: 16)
                        Text(d.titel).font(.system(size: 12, weight: .medium)).foregroundStyle(Premium.text)
                        Spacer()
                        if aktiv > 0 {
                            Text("\(aktiv)").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.onAction)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Premium.action))
                        }
                    }
                }
            }
            sektion("Belegte Fakten")
            TextEditor(text: binde(\.belegteFakten))
                .font(.system(size: 11))
                .frame(minHeight: 70)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
            Text(unternehmen.rolle == .eigen
                 ? "Bußgelder, Verfahren, Audit-Feststellungen — fließen in die KI-Synthese ein."
                 : "Nur belegte, öffentlich zugängliche Fakten (Register, Urteile, Presse) — erhöhen die Nachweisbarkeit.")
                .font(.system(size: 10)).foregroundStyle(Premium.textFaint)
        }
    }
    private func sektion(_ t: String) -> some View {
        Text(t.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint).tracking(0.8)
    }
    private func zahl(_ titel: String, _ b: Binding<Int>, schritt: Int) -> some View {
        HStack {
            Text(titel).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
            Spacer()
            TextField("", value: b, format: .number).textFieldStyle(.roundedBorder).frame(width: 90).multilineTextAlignment(.trailing)
            Stepper("", value: b, in: 0...1_000_000, step: schritt).labelsHidden()
        }
    }
    private func zahlD(_ titel: String, _ b: Binding<Double>, schritt: Double, max: Double = 1_000_000) -> some View {
        HStack {
            Text(titel).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
            Spacer()
            TextField("", value: b, format: .number.precision(.fractionLength(0...1))).textFieldStyle(.roundedBorder).frame(width: 90).multilineTextAlignment(.trailing)
            Stepper("", value: b, in: 0...max, step: schritt).labelsHidden()
        }
    }
}
private struct ERMatrixAnsicht: View {
    let ergebnis: ERErgebnis
    @Binding var offeneDimension: ERDimension?
    @State private var detail: ERDimension?
    private var spalten: [(String, String, [ERDimensionsScore])] {
        [(ergebnis.eigen.id, ergebnis.eigen.name, ergebnis.eigeneScores)]
        + ergebnis.wettbewerber.map { ($0.id, $0.name, ergebnis.wettbewerberScores[$0.id] ?? []) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("Dimension").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
                    ForEach(spalten, id: \.0) { s in
                        Text(s.1).font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint).lineLimit(1).frame(width: 110)
                    }
                    Text("Δ").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint).frame(width: 44)
                }
                ForEach(ERDimension.allCases) { d in
                    let eigen = ergebnis.eigeneScores.first { $0.dimension == d }?.score ?? 0
                    let bester = spalten.dropFirst().compactMap { $0.2.first { $0.dimension == d }?.score }.max() ?? eigen
                    GridRow {
                        Button { detail = detail == d ? nil : d } label: {
                            HStack(spacing: 6) {
                                Image(systemName: d.symbol).font(.system(size: 11)).foregroundStyle(Premium.action).frame(width: 16)
                                Text(d.titel).font(.system(size: 12, weight: .medium)).foregroundStyle(Premium.text)
                            }
                        }.buttonStyle(.plain).frame(minWidth: 190, alignment: .leading)
                        ForEach(spalten, id: \.0) { s in
                            let sc = s.2.first { $0.dimension == d }?.score ?? 0
                            zelle(sc)
                        }
                        let delta = bester - eigen
                        Text(delta == 0 ? "–" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(delta > 0 ? Premium.computed : (delta < 0 ? Premium.critical : Premium.textFaint))
                            .frame(width: 44)
                    }
                    if detail == d {
                        GridRow {
                            befunde(d).gridCellColumns(spalten.count + 2)
                        }
                    }
                }
            }
            .padding(14)
            .premiumPanel()
            HStack(spacing: 14) {
                ForEach(ERSchwere.allCases, id: \.self) { s in
                    HStack(spacing: 4) {
                        Circle().fill(s.farbe).frame(width: 8, height: 8)
                        Text(s.titel).font(.system(size: 10)).foregroundStyle(Premium.textSoft)
                    }
                }
                Spacer()
                Text("Δ = bester Wettbewerber minus eigen · positiv = unser Vorteil").font(.system(size: 10)).foregroundStyle(Premium.textFaint)
            }
            Text("Top-Befunde eigen").font(.system(size: 13, weight: .bold)).foregroundStyle(Premium.text)
            ForEach(ergebnis.eigeneScores.flatMap(\.befunde).sorted { $0.punkte > $1.punkte }.prefix(8)) { b in
                ERBefundKarte(befund: b)
            }
        }
    }
    private func zelle(_ score: Int) -> some View {
        let s = ERSchwere.aus(score: score)
        return Text("\(score)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(score < 30 ? Premium.text : Color.white)
            .frame(width: 110, height: 26)
            .background(RoundedRectangle(cornerRadius: 6).fill(s.farbe.opacity(0.18 + Double(score) / 100.0 * 0.72)))
    }
    private func befunde(_ d: ERDimension) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(d.rechtsrahmen.joined(separator: " · ")).font(.system(size: 10, design: .monospaced)).foregroundStyle(Premium.textFaint)
            Text("Sanktionsrahmen: \(d.sanktionsrahmen)").font(.system(size: 10)).foregroundStyle(Premium.textSoft)
            ForEach(spalten, id: \.0) { s in
                if let sc = s.2.first(where: { $0.dimension == d }), !sc.befunde.isEmpty {
                    Text(s.1).font(.system(size: 11, weight: .bold)).foregroundStyle(Premium.text).padding(.top, 4)
                    ForEach(sc.befunde) { b in ERBefundKarte(befund: b, kompakt: true) }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
    }
}
struct ERBefundKarte: View {
    let befund: ERBefund
    var kompakt = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(befund.schwere.farbe).frame(width: 8, height: 8)
                Text(befund.titel).font(.system(size: kompakt ? 11 : 12, weight: .semibold)).foregroundStyle(Premium.text)
                Spacer()
                Text("P \(befund.eintrittswahrscheinlichkeit) · S \(befund.schadenshoehe)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Premium.textFaint)
                if let f = befund.frist {
                    Text(f).font(.system(size: 10, weight: .semibold)).foregroundStyle(Premium.proposed)
                }
            }
            Text(befund.begruendung).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
            if !kompakt {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.turn.down.right").font(.system(size: 10)).foregroundStyle(Premium.action)
                    Text(befund.sofortmassnahme).font(.system(size: 11)).foregroundStyle(Premium.text)
                }
                Text(befund.normen.joined(separator: " · ")).font(.system(size: 10, design: .monospaced)).foregroundStyle(Premium.textFaint)
            }
        }
        .padding(kompakt ? 8 : 12)
        .premiumPanel(elevated: !kompakt)
    }
}
private struct ERSchwaechenAnsicht: View {
    let ergebnis: ERErgebnis
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                titel("Wettbewerber — nutzbar", ergebnis.wettbewerberSchwachstellen.count, Premium.proposed)
                if ergebnis.wettbewerberSchwachstellen.isEmpty {
                    leer("Keine signifikante Exposure beim Wettbewerber erkannt — Signale im Profil setzen.")
                }
                ForEach(ergebnis.wettbewerberSchwachstellen) { s in karte(s) }
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                titel("Eigen — zu schließen", ergebnis.eigeneSchwachstellen.count, Premium.action)
                if ergebnis.eigeneSchwachstellen.isEmpty {
                    leer("Keine eigene Schwachstelle über Schwelle. Festung steht.")
                }
                ForEach(ergebnis.eigeneSchwachstellen) { s in karte(s) }
            }
            .frame(maxWidth: .infinity)
        }
    }
    private func titel(_ t: String, _ n: Int, _ farbe: Color) -> some View {
        HStack {
            Text(t).font(.system(size: 13, weight: .bold)).foregroundStyle(Premium.text)
            Text("\(n)").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.onAction).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(farbe))
        }
    }
    private func leer(_ t: String) -> some View {
        Text(t).font(.system(size: 11)).foregroundStyle(Premium.textSoft).padding(12).frame(maxWidth: .infinity, alignment: .leading).premiumPanel()
    }
    private func karte(_ s: ERSchwachstelle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: s.dimension.symbol).foregroundStyle(s.rolle == .eigen ? Premium.action : Premium.proposed)
                Text(s.titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text).lineLimit(2)
                Spacer()
                Text("\(s.hebelIndex)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(ERSchwere.aus(score: s.hebelIndex).farbe)
            }
            if s.rolle == .konkurrent {
                Text(s.unternehmenName).font(.system(size: 10, weight: .semibold)).foregroundStyle(Premium.textFaint)
            }
            Text(s.beschreibung).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
            HStack(spacing: 10) {
                balken("Ausnutzbar", s.ausnutzbarkeit)
                balken("Nachweis", s.nachweisbarkeit)
                balken("Dringlich", s.dringlichkeit)
            }
            if s.differenzZumEigenen != 0 {
                Text(s.rolle == .konkurrent
                     ? "Δ zu uns: +\(s.differenzZumEigenen) — wir stehen in dieser Dimension besser"
                     : "Δ bester Wettbewerber: \(s.differenzZumEigenen) — \(s.differenzZumEigenen < 0 ? "Gegner steht besser" : "wir stehen besser")")
                    .font(.system(size: 10)).foregroundStyle(Premium.textFaint)
            }
        }
        .padding(12)
        .premiumPanel(elevated: true)
    }
    private func balken(_ t: String, _ v: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(t) \(v)").font(.system(size: 9, weight: .semibold)).foregroundStyle(Premium.textFaint)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Premium.well)
                    Capsule().fill(ERSchwere.aus(score: v).farbe).frame(width: g.size.width * CGFloat(v) / 100)
                }
            }.frame(height: 5)
        }
    }
}
private struct ERVorteileAnsicht: View {
    let ergebnis: ERErgebnis
    @State private var filter: ERVorteilTyp?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Button { filter = nil } label: { Text("Alle") }.buttonStyle(.plain).premiumChip(active: filter == nil)
                ForEach(ERVorteilTyp.allCases, id: \.self) { t in
                    Button { filter = t } label: { Text(t.titel) }.buttonStyle(.plain).premiumChip(active: filter == t, tint: t.farbe)
                }
                Spacer()
                Text("Sortiert nach Netto-Hebel (Effekt − ½ Aufwand)").font(.system(size: 10)).foregroundStyle(Premium.textFaint)
            }
            let liste = ergebnis.vorteile.filter { filter == nil || $0.typ == filter }
            if liste.isEmpty {
                Text("Keine Vorteile in dieser Kategorie. Mehr Signale bei Wettbewerbern setzen.").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
            }
            ForEach(liste) { v in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(v.typ.titel.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(Premium.onAction)
                            .padding(.horizontal, 6).padding(.vertical, 3).background(RoundedRectangle(cornerRadius: 4).fill(v.typ.farbe))
                        Image(systemName: v.dimension.symbol).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                        Text(v.titel).font(.system(size: 13, weight: .bold)).foregroundStyle(Premium.text)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(v.nettoHebel)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(v.typ.farbe)
                            Text("Netto-Hebel").font(.system(size: 8)).foregroundStyle(Premium.textFaint)
                        }
                    }
                    Text(v.mechanik).font(.system(size: 12)).foregroundStyle(Premium.text)
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                        zeile("Rechtsgrundlage", v.rechtsgrundlage.joined(separator: " · "))
                        zeile("Aktivlegitimation", v.aktivlegitimation)
                        zeile("Leitplanken", v.leitplanken)
                        zeile("Zeitfenster", "\(v.zeitfenster) · Effekt \(v.erwarteterEffekt) · Aufwand \(v.umsetzungsaufwand)")
                    }
                }
                .padding(14)
                .premiumPanel(elevated: true)
            }
        }
    }
    private func zeile(_ k: String, _ v: String) -> some View {
        GridRow {
            Text(k).font(.system(size: 10, weight: .semibold)).foregroundStyle(Premium.textFaint).frame(width: 110, alignment: .leading)
            Text(v).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
        }
    }
}
private struct ERStrategienAnsicht: View {
    let ergebnis: ERErgebnis
    @State private var offen: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if ergebnis.strategien.isEmpty {
                Text("Noch keine Strategie ableitbar — Profil vervollständigen.").foregroundStyle(Premium.textSoft)
            }
            ForEach(Array(ergebnis.strategien.enumerated()), id: \.element.id) { idx, s in
                let sim = ergebnis.simulationen.first { $0.strategieId == s.id }
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(idx + 1)").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(Premium.textFaint).frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.archetyp.titel.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(Premium.proposed).tracking(0.8)
                            Text(s.titel).font(.system(size: 14, weight: .bold)).foregroundStyle(Premium.text)
                            Text(s.archetyp.prinzip).font(.system(size: 10)).italic().foregroundStyle(Premium.textFaint)
                        }
                        Spacer()
                        HStack(spacing: 14) {
                            metrik("Erfolg", "\(s.erfolgswahrscheinlichkeit) %", ERSchwere.aus(score: 100 - s.erfolgswahrscheinlichkeit).farbe)
                            metrik("Nutzen", "\(s.erwarteterNutzen)", Premium.computed)
                            metrik("Risiko", "\(s.risiko)", ERSchwere.aus(score: s.risiko).farbe)
                        }
                    }
                    Text(s.ziel).font(.system(size: 12)).foregroundStyle(Premium.text)
                    if let sim {
                        ERSzenarioBalken(sim: sim)
                    }
                    DisclosureGroup(isExpanded: Binding(get: { offen == s.id }, set: { offen = $0 ? s.id : nil })) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(s.zuege.enumerated()), id: \.element.id) { i, z in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(i + 1)").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.onAction).frame(width: 18, height: 18).background(Circle().fill(Premium.action))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(z.schritt).font(.system(size: 11)).foregroundStyle(Premium.text)
                                        Text("\(z.verantwortlich) · \(z.frist)\(z.norm.map { " · \($0)" } ?? "")").font(.system(size: 10, design: .monospaced)).foregroundStyle(Premium.textFaint)
                                    }
                                }
                            }
                            Divider().overlay(Premium.hairline)
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "arrow.uturn.left").font(.system(size: 10)).foregroundStyle(Premium.critical)
                                Text("Gegenreaktion: \(s.gegenreaktion)").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                            }
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "hand.raised").font(.system(size: 10)).foregroundStyle(Premium.proposed)
                                Text("Leitplanken: \(s.leitplanken)").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("\(s.zuege.count) Züge · Gegenreaktion · Leitplanken").font(.system(size: 11, weight: .semibold)).foregroundStyle(Premium.action)
                    }
                }
                .padding(14)
                .premiumPanel(elevated: true)
            }
        }
    }
    private func metrik(_ t: String, _ v: String, _ farbe: Color) -> some View {
        VStack(spacing: 1) {
            Text(v).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(farbe)
            Text(t).font(.system(size: 8, weight: .semibold)).foregroundStyle(Premium.textFaint)
        }
    }
}
struct ERSzenarioBalken: View {
    let sim: ERSimulation
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { g in
                let w = g.size.width
                let maxWert = max(100.0, Double(sim.p90) * 1.1)
                let x10 = w * CGFloat(Double(sim.p10) / maxWert)
                let x50 = w * CGFloat(Double(sim.p50) / maxWert)
                let x90 = w * CGFloat(Double(sim.p90) / maxWert)
                ZStack(alignment: .leading) {
                    Capsule().fill(Premium.well).frame(height: 8)
                    Capsule().fill(Premium.action.opacity(0.35)).frame(width: max(2, x90 - x10), height: 8).offset(x: x10)
                    Circle().fill(Premium.action).frame(width: 12, height: 12).offset(x: x50 - 6)
                }
            }
            .frame(height: 12)
            Text("Szenario-Simulation \(sim.laeufe) Läufe · P10 \(sim.p10) · P50 \(sim.p50) · P90 \(sim.p90) · Erfolgsquote \(sim.erfolgsquote) %")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Premium.textFaint)
        }
    }
}
private struct ERFristenAnsicht: View {
    let ergebnis: ERErgebnis
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Regulatorische Stichtage mit Relevanz für dieses Profil — Stand Regelkatalog 10/2026, vor Nutzung gegenprüfen.")
                .font(.system(size: 11)).foregroundStyle(Premium.textSoft)
            ForEach(ergebnis.fristen) { f in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: f.dimension.symbol).foregroundStyle(Premium.proposed).frame(width: 18)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(f.titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
                        Text(f.relevanz).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                    }
                    Spacer()
                    Text(f.datum).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(Premium.proposed)
                }
                .padding(12)
                .premiumPanel()
            }
            if ergebnis.fristen.isEmpty {
                Text("Keine Stichtage über Relevanzschwelle.").font(.system(size: 11)).foregroundStyle(Premium.textFaint)
            }
        }
    }
}
private struct ERKIAnsicht: View {
    let store: EnterpriseRadarStore
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("KI-Synthese").font(.system(size: 13, weight: .bold)).foregroundStyle(Premium.text)
                    Text("Ein Aufruf, striktes Schema. Liefert, was Regeln nicht sehen: Querverbindungen, verborgene Risiken, Gegenzüge, Priorisierung.")
                        .font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                }
                Spacer()
                Button {
                    Task { await store.kiVertiefen() }
                } label: {
                    Label(store.kiLaeuft ? "Analysiert…" : "KI-Vertiefung", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent).tint(Premium.proposed)
                .disabled(store.kiLaeuft || store.ergebnis == nil)
            }
            if let f = store.kiFehler {
                Text(f).font(.system(size: 11)).foregroundStyle(Premium.critical).padding(10).premiumPanel()
            }
            if let k = store.ergebnis?.kiSynthese {
                block("Executive Summary", [k.executiveSummary], "text.alignleft", Premium.action)
                block("Verborgene Risiken", k.verborgeneRisiken, "eye.trianglebadge.exclamationmark", Premium.critical)
                block("Erwartete Gegenzüge", k.gegenzuegeDesWettbewerbers, "arrow.uturn.left", Premium.proposed)
                block("Prioritäten", k.prioritaeten, "list.number", Premium.computed)
                if !k.unternehmensDynamik.isEmpty {
                    block("Unternehmensdynamik (Ursache → Folgen)", k.unternehmensDynamik, "chart.line.uptrend.xyaxis", Premium.action)
                }
                if !k.massnahmenFolgen.isEmpty {
                    block("Maßnahmen & Folgen", k.massnahmenFolgen, "arrow.triangle.branch", Premium.proposed)
                }
                if !k.wissenschaftlicheStrategien.isEmpty {
                    block("Strategien (inkl. Wissenschaft)", k.wissenschaftlicheStrategien, "book.fill", Premium.computed)
                }
                if !k.machtErhalt.isEmpty {
                    block("Macht-Erhalt / Beibehalten", k.machtErhalt, "shield.checkered", Premium.computed)
                }
                if !k.machtWegnahmeLegal.isEmpty {
                    block("Macht-Wegnahme (legal)", k.machtWegnahmeLegal, "scope", Premium.critical)
                }
                Text("\(k.modell) · \(k.zeitpunkt.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 10)).foregroundStyle(Premium.textFaint)
            } else if !store.kiLaeuft {
                Text("Noch keine Synthese. Die Regel-Engine ist vollständig — die KI ergänzt nur.").font(.system(size: 11)).foregroundStyle(Premium.textFaint)
            }
            if store.kiLaeuft { ProgressView().controlSize(.small) }
        }
    }
    private func block(_ t: String, _ zeilen: [String], _ sym: String, _ farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(t, systemImage: sym).font(.system(size: 12, weight: .bold)).foregroundStyle(farbe)
            ForEach(Array(zeilen.enumerated()), id: \.offset) { _, z in
                Text(z).font(.system(size: 12)).foregroundStyle(Premium.text)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumPanel(elevated: true)
    }
}
