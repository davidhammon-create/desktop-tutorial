import SwiftUI
import AppKit
@Observable
final class PfadgrafStore {
    var graf: Pfadgraf
    var auswertung: PfadgrafAuswertung = .init()
    var layoutErgebnis: PfadgrafLayoutErgebnis = .init()
    var canvasSize: CGSize = CGSize(width: 900, height: 640)
    var kiLaeuft = false
    var kiFehler: String?
    private let persistKey: String
    private var fristen: [VorgangFrist] = []
    init(persistKey: String, startMitBeispiel: Bool = true) {
        self.persistKey = persistKey
        if let data = UserDefaults.standard.data(forKey: persistKey),
           let geladen = try? JSONDecoder().decode(Pfadgraf.self, from: data) {
            graf = geladen
        } else {
            graf = startMitBeispiel ? PfadgrafEngine.beispielGraf() : Pfadgraf()
        }
        neuBerechnen()
    }
    func setzeFristen(_ f: [VorgangFrist]) {
        fristen = f
        neuBerechnen()
    }
    func neuBerechnen() {
        auswertung = PfadgrafEngine.auswerten(graf, fristen: fristen, topN: 10)
        layoutErgebnis = PfadgrafEngine.layout(graf, fristen: fristen, canvas: canvasSize)
        if graf.hervorgehobenerPfadIds.isEmpty, let emp = auswertung.empfohlenerPfadId,
           let pfad = auswertung.pfade.first(where: { $0.id == emp }) {
            _ = pfad
        }
        speichern()
    }
    var aktiveHervorhebung: Set<UUID> {
        if !graf.hervorgehobenerPfadIds.isEmpty { return Set(graf.hervorgehobenerPfadIds) }
        if let emp = auswertung.empfohlenerPfadId,
           let pfad = auswertung.pfade.first(where: { $0.id == emp }) {
            return Set(pfad.kantenIds)
        }
        return []
    }
    func speichern() {
        if let data = try? JSONEncoder().encode(graf) {
            UserDefaults.standard.set(data, forKey: persistKey)
        }
    }
    func pfadWaehlen(_ pfad: PfadgrafPfad?) {
        graf.hervorgehobenerPfadIds = pfad?.kantenIds ?? []
        speichern()
    }
    func setzeKnotenPosition(_ id: UUID, x: CGFloat, y: CGFloat) {
        guard let i = graf.knoten.firstIndex(where: { $0.id == id }) else { return }
        graf.knoten[i].manuellX = Double(x)
        graf.knoten[i].manuellY = Double(y)
        if let j = layoutErgebnis.punkte.firstIndex(where: { $0.knotenId == id }) {
            layoutErgebnis.punkte[j].x = x
            layoutErgebnis.punkte[j].y = y
        }
        layoutErgebnis.breite = max(layoutErgebnis.breite, x + 140)
        layoutErgebnis.hoehe = max(layoutErgebnis.hoehe, y + 100)
        speichern()
    }
    func resetManuellesLayout() {
        PfadgrafEngine.autoLayoutZuruecksetzen(in: &graf)
        neuBerechnen()
    }
    var hatManuellesLayout: Bool {
        graf.knoten.contains(where: \.hatManuellePosition)
    }
}
struct PfadgrafLinse: View {
    let vorgangId: UUID?
    var caseId: String? = nil
    @Bindable var vorgangStore: VorgangStore = .shared
    @State private var store: PfadgrafStore
    @State private var knotenSheet: PfadgrafKnoten? = nil
    @State private var kanteSheet: PfadgrafKante? = nil
    @State private var zeigeLegende = true
    @State private var zeigeHilfe = true
    init(vorgangId: UUID? = nil, caseId: String? = nil) {
        self.vorgangId = vorgangId
        self.caseId = caseId
        let key: String
        if let vorgangId { key = "pfadgraf_vorgang_\(vorgangId.uuidString)" }
        else if let caseId { key = "pfadgraf_case_\(caseId)" }
        else { key = "pfadgraf_orphan" }
        _store = State(initialValue: PfadgrafStore(persistKey: key))
    }
    private var vorgang: Vorgang? {
        guard let vorgangId else { return nil }
        return vorgangStore.vorgang(vorgangId)
    }
    var body: some View {
        VStack(spacing: 0) {
            werkzeugleiste
            Divider()
            HStack(spacing: 0) {
                grafBereich
                Divider()
                seitenleiste
                    .frame(width: 300)
            }
        }
        .background(InterfacePalette.Material.l0)
        .onAppear {
            if let v = vorgang { store.setzeFristen(v.fristen) }
        }
        .sheet(item: $knotenSheet) { kn in
            PfadgrafKnotenBlatt(knoten: kn, optionswert: store.auswertung.optionswerte[kn.id], knotenwert: store.auswertung.knotenWerte[kn.id], istEngpass: store.auswertung.engpassKnotenIds.contains(kn.id)) { neu in
                if let i = store.graf.knoten.firstIndex(where: { $0.id == neu.id }) {
                    store.graf.knoten[i] = neu
                    if neu.typ == .ziel {
                        if !store.graf.zielKnotenIds.contains(neu.id) { store.graf.zielKnotenIds.append(neu.id) }
                    } else {
                        store.graf.zielKnotenIds.removeAll { $0 == neu.id }
                    }
                    if neu.typ == .ist { store.graf.startKnotenId = neu.id }
                    store.neuBerechnen()
                }
            } onDelete: { id in
                store.graf.knoten.removeAll { $0.id == id }
                store.graf.kanten.removeAll { $0.von == id || $0.nach == id }
                store.graf.zielKnotenIds.removeAll { $0 == id }
                if store.graf.startKnotenId == id { store.graf.startKnotenId = nil }
                store.neuBerechnen()
            }
        }
        .sheet(item: $kanteSheet) { ka in
            PfadgrafKantenBlatt(kante: ka, knoten: store.graf.knoten) { neu in
                if let i = store.graf.kanten.firstIndex(where: { $0.id == neu.id }) {
                    store.graf.kanten[i] = neu
                    store.neuBerechnen()
                }
            } onDelete: { id in
                store.graf.kanten.removeAll { $0.id == id }
                store.neuBerechnen()
            } onKnotenEinfuegen: {
                PfadgrafEngine.knotenEinfuegen(auf: ka.id, in: &store.graf, kennung: PfadgrafEngine.naechsteKennung(store.graf))
                store.neuBerechnen()
                kanteSheet = nil
            }
        }
    }
    private var werkzeugleiste: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Label("Pfadgraf", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 13, weight: .bold))
                Text("Wegenetz · Zustände = Knoten · Handlungen = Kanten")
                    .font(.system(size: 10))
                    .foregroundStyle(InterfacePalette.sekundaer)
                Spacer()
                Menu("Beispiele") {
                    Button("Abb. 2 — acht Zustände") {
                        store.graf = PfadgrafEngine.beispielGraf()
                        store.neuBerechnen()
                    }
                    Button("Zwickmühle") {
                        store.graf = PfadgrafEngine.zwickmuehleBeispiel()
                        store.neuBerechnen()
                    }
                }
                .controlSize(.small)
                Button {
                    Task { await kiVorbefuellen() }
                } label: {
                    if store.kiLaeuft {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("KI-Vorbefüllung", systemImage: "sparkles")
                    }
                }
                .controlSize(.small)
                .disabled(store.kiLaeuft)
                Button {
                    optionenUebernehmen()
                } label: {
                    Label("→ Optionen (Schritt 3)", systemImage: "list.bullet.rectangle")
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .disabled(vorgangId == nil || store.auswertung.pfade.filter(\.gangbar).isEmpty)
                .help("Jeder vollständige Weg A→Ziel wird eine Option — speist Schritt 3, ersetzt ihn nicht.")
            }
            HStack(alignment: .top, spacing: 14) {
                umschalter("Layout", Auswahl: PfadgrafLayout.allCases, bindung: Binding(
                    get: { store.graf.layout },
                    set: {
                        store.graf.layout = $0
                        PfadgrafEngine.autoLayoutZuruecksetzen(in: &store.graf)
                        store.neuBerechnen()
                    }
                ))
                umschalter("Betrieb", Auswahl: PfadgrafRichtung.allCases, bindung: Binding(
                    get: { store.graf.richtung },
                    set: {
                        store.graf.richtung = $0
                        PfadgrafEngine.autoLayoutZuruecksetzen(in: &store.graf)
                        store.neuBerechnen()
                    }
                ))
                umschalter("Optimieren", Auswahl: PfadgrafOptimierung.allCases, bindung: Binding(
                    get: { store.graf.optimierung },
                    set: { store.graf.optimierung = $0; store.graf.hervorgehobenerPfadIds = []; store.neuBerechnen() }
                ))
                umschalter("Kennzahl", Auswahl: PfadgrafKantenKennzahl.allCases, bindung: Binding(
                    get: { store.graf.kantenKennzahl },
                    set: { store.graf.kantenKennzahl = $0; store.neuBerechnen() }
                ))
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.graf.richtung.frage)
                        .font(.system(size: 11, weight: .medium))
                    Text(store.graf.layout.erklaerung)
                        .font(.system(size: 10))
                        .foregroundStyle(InterfacePalette.sekundaer)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 8) {
                    Button { neuerKnoten() } label: { Label("Knoten", systemImage: "plus.circle") }
                        .controlSize(.small)
                    Button { neueKante() } label: { Label("Kante", systemImage: "arrow.right.circle") }
                        .controlSize(.small)
                    if store.hatManuellesLayout {
                        Button {
                            store.resetManuellesLayout()
                        } label: {
                            Label("Auto-Layout", systemImage: "rectangle.3.group")
                        }
                        .controlSize(.small)
                        .help("Manuelle Knotenpositionen verwerfen und neu anordnen")
                    }
                    Toggle("Legende", isOn: $zeigeLegende)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(.system(size: 10))
                    Toggle("Hilfe", isOn: $zeigeHilfe)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(.system(size: 10))
                }
            }
            if zeigeHilfe {
                bedienungshilfe
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    private var bedienungshilfe: some View {
        HStack(alignment: .top, spacing: 16) {
            hilfeChip("arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", "Knoten ziehen", "Position speichern")
            hilfeChip("hand.tap", "Knoten tippen", "Zustandsblatt öffnen")
            hilfeChip("hand.draw", "Leere Fläche wischen", "Graf verschieben (Pan)")
            hilfeChip("arrow.triangle.branch", "Pfad in der Liste", "Weg hervorheben")
            hilfeChip("plus.diamond", "⌥ + Kantenmitte", "Zwischenknoten einfügen")
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InterfacePalette.Material.l1, in: RoundedRectangle(cornerRadius: 8))
    }
    private func hilfeChip(_ icon: String, _ titel: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(InterfacePalette.aktion)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(titel).font(.system(size: 10, weight: .semibold))
                Text(text).font(.system(size: 9)).foregroundStyle(InterfacePalette.sekundaer)
            }
        }
    }
    private func umschalter<T: Hashable & Identifiable>(_ titel: String, Auswahl: [T], bindung: Binding<T>) -> some View where T: RawRepresentable, T.RawValue == String {
        HStack(spacing: 4) {
            Text(titel)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(InterfacePalette.sekundaer)
            Picker("", selection: bindung) {
                ForEach(Auswahl) { v in
                    Text(v.rawValue).tag(v)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(maxWidth: titel == "Optimieren" ? 420 : 280)
        }
    }
    private var grafBereich: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                PfadgrafCanvas(
                    graf: store.graf,
                    layout: store.layoutErgebnis,
                    auswertung: store.auswertung,
                    hervorgehobeneKanten: store.aktiveHervorhebung,
                    onKnotenTap: { id in knotenSheet = store.graf.knoten.first(where: { $0.id == id }) },
                    onKnotenMoved: { id, x, y in store.setzeKnotenPosition(id, x: x, y: y) },
                    onKante: { id in kanteSheet = store.graf.kanten.first(where: { $0.id == id }) },
                    onKanteEinfuegen: { id in
                        PfadgrafEngine.knotenEinfuegen(auf: id, in: &store.graf, kennung: PfadgrafEngine.naechsteKennung(store.graf))
                        store.neuBerechnen()
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                if zeigeLegende {
                    legende
                        .padding(.top, 40)
                        .padding(.leading, 10)
                }
            }
            .onAppear {
                store.canvasSize = geo.size
                store.neuBerechnen()
            }
            .onChange(of: geo.size) { _, neu in
                store.canvasSize = neu
                store.layoutErgebnis = PfadgrafEngine.layout(store.graf, fristen: vorgang?.fristen ?? [], canvas: neu)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var legende: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ZEICHENSYSTEM").font(.system(size: 8, weight: .bold)).kerning(0.4)
            Text("Einfarbig: Füllung / Kontur / Strich — kein Farbschema.")
                .font(.system(size: 8))
                .foregroundStyle(InterfacePalette.sekundaer)
                .fixedSize(horizontal: false, vertical: true)
            Divider().frame(width: 160)
            Text("Knoten = Zustände").font(.system(size: 9, weight: .semibold))
            legendeZeile("● gefüllt", "Ist A — tatsächlich")
            legendeZeile("○ offen", "Geplant — noch nicht")
            legendeZeile("◌ gestrichelt", "Fremd — Gegner/Gericht")
            legendeZeile("◎ doppelt", "Ziel Z — Endpunkt")
            Divider().frame(width: 160)
            Text("Kanten = Handlungen").font(.system(size: 9, weight: .semibold))
            legendeZeile("— dick", "Empfohlener Pfad")
            legendeZeile("— normal", "Mögliche Handlung")
            legendeZeile("- - -", "Bedingt (Voraussetzung)")
            legendeZeile("· · ·", "Fremde Handlung")
            legendeZeile("◇ Raute", "Engpassknoten")
            if store.hatManuellesLayout {
                Divider().frame(width: 160)
                Text("⠿ = manuell verschoben")
                    .font(.system(size: 8))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
        }
        .font(.system(size: 9))
        .foregroundStyle(.primary.opacity(0.85))
        .padding(10)
        .frame(width: 210, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
    }
    private func legendeZeile(_ zeichen: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Text(zeichen).frame(width: 70, alignment: .leading).font(.system(size: 9, design: .monospaced))
            Text(text)
        }
    }
    private var seitenleiste: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AUSWERTUNG")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.5)
                Text("Jeder Weg A→Ziel ist eine Option. EV = P·(Wert+ΣEigen)−Kosten. «Optimieren» sortiert die Liste und hebt den besten Weg. Layout-Wechsel setzt Auto-Layout neu (manuelle Züge werden verworfen).")
                    .font(.system(size: 10))
                    .foregroundStyle(InterfacePalette.sekundaer)
                    .fixedSize(horizontal: false, vertical: true)
                kennzahlen
                verstosse
                pfadliste
            }
            .padding(12)
        }
        .background(InterfacePalette.Material.l1)
    }
    private var kennzahlen: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NUR DER GRAF LIEFERT").font(.system(size: 9, weight: .bold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
            kennzahlZeile("Pfade gesamt", "\(store.auswertung.allePfadAnzahl)")
            kennzahlZeile("Top-Anzeige", "\(store.auswertung.pfade.count)")
            kennzahlZeile("Redundanzgrad", "\(store.auswertung.redundanzgrad)")
            let eng = store.auswertung.engpassKnotenIds.compactMap { id in store.graf.knoten.first(where: { $0.id == id })?.kennung }
            kennzahlZeile("Engpassknoten", eng.isEmpty ? "—" : eng.joined(separator: ", "))
            if let emp = store.auswertung.empfohlenerPfadId,
               let p = store.auswertung.pfade.first(where: { $0.id == emp }) {
                kennzahlZeile("Empfohlen EV", euro(p.ev))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InterfacePalette.Material.l2, in: RoundedRectangle(cornerRadius: 8))
    }
    private func kennzahlZeile(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(.system(size: 11)).foregroundStyle(InterfacePalette.sekundaer)
            Spacer()
            Text(b).font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
    }
    @ViewBuilder
    private var verstosse: some View {
        if !store.auswertung.verstosse.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("KONSISTENZ").font(.system(size: 9, weight: .bold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                ForEach(store.auswertung.verstosse) { v in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: v.schwere == .sperre ? "xmark.octagon.fill" : "exclamationmark.triangle")
                            .font(.system(size: 10))
                        Text(v.text).font(.system(size: 10))
                    }
                    .foregroundStyle(v.schwere == .sperre ? InterfacePalette.kritisch : InterfacePalette.sekundaer)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(InterfacePalette.Material.l2, in: RoundedRectangle(cornerRadius: 8))
        }
        if let err = store.kiFehler {
            Text(err).font(.system(size: 10)).foregroundStyle(InterfacePalette.kritisch)
        }
    }
    private var pfadliste: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PFADE · SORTIERT NACH \(store.graf.optimierung.rawValue.uppercased())")
                .font(.system(size: 9, weight: .bold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
            Text("Klick markiert den Weg im Grafen. p = Produkt der Erfolgswahrscheinlichkeiten.")
                .font(.system(size: 9)).foregroundStyle(InterfacePalette.sekundaer.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(store.auswertung.pfade.enumerated()), id: \.element.id) { i, pfad in
                Button {
                    store.pfadWaehlen(store.graf.hervorgehobenerPfadIds == pfad.kantenIds ? nil : pfad)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("\(i + 1). \(pfadLabel(pfad))")
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                            Spacer()
                            if !pfad.gangbar {
                                Text("gesperrt")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .overlay(Capsule().stroke(InterfacePalette.kritisch, lineWidth: 1))
                                    .foregroundStyle(InterfacePalette.kritisch)
                            }
                        }
                        HStack(spacing: 8) {
                            Text(String(format: "p %.0f %%", pfad.p * 100))
                            Text(euro(pfad.kosten))
                            Text("\(Int(pfad.dauerTage)) d")
                            Spacer()
                            Text("EV \(euro(pfad.ev))")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(InterfacePalette.sekundaer)
                        if let g = pfad.sperrGrund {
                            Text(g).font(.system(size: 9)).foregroundStyle(InterfacePalette.kritisch)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(store.aktiveHervorhebung == Set(pfad.kantenIds) ? InterfacePalette.aktion.opacity(0.12) : InterfacePalette.Material.l2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(store.aktiveHervorhebung == Set(pfad.kantenIds) ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .opacity(pfad.gangbar ? 1 : 0.55)
            }
        }
    }
    private func pfadLabel(_ p: PfadgrafPfad) -> String {
        p.knotenIds.compactMap { id in store.graf.knoten.first(where: { $0.id == id })?.kennung }.joined(separator: "→")
    }
    private func euro(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " €"
    }
    private func neuerKnoten() {
        let k = PfadgrafKnoten(
            kennung: PfadgrafEngine.naechsteKennung(store.graf),
            typ: store.graf.knoten.isEmpty ? .ist : .geplant,
            bezeichnung: "Neuer Zustand",
            ressourcen: store.graf.knoten.first?.ressourcen ?? .init(budget: 100_000)
        )
        store.graf.knoten.append(k)
        if k.typ == .ist { store.graf.startKnotenId = k.id }
        store.neuBerechnen()
        knotenSheet = k
    }
    private func neueKante() {
        guard store.graf.knoten.count >= 2 else { return }
        let von = store.graf.startKnotenId ?? store.graf.knoten[0].id
        let nach = store.graf.knoten.first(where: { $0.id != von })!.id
        let k = PfadgrafKante(von: von, nach: nach, handlung: "Neue Handlung", kosten: 5_000, dauerMinTage: 10, dauerMaxTage: 20, pErfolg: 0.5)
        store.graf.kanten.append(k)
        store.neuBerechnen()
        kanteSheet = k
    }
    private func optionenUebernehmen() {
        guard let id = vorgangId else { return }
        let optionen = PfadgrafEngine.alsOptionen(store.auswertung, graf: store.graf, topN: 10)
        vorgangStore.mutate(id) { v in
            v.optionen.removeAll { $0.beschreibung.hasPrefix("Weg ") || $0.label.hasPrefix("Pfad ") }
            v.optionen.append(contentsOf: optionen)
            for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
            if v.zustand.reihenfolge < VorgangZustand.strukturiert.reihenfolge, v.optionen.count >= 2 {
                v.zustand = .strukturiert
            }
            v.ereignisse.append(.init(was: "Pfadgraf → Optionen", wer: "Pfadgraf", alt: nil, neu: "\(optionen.count) Pfade"))
        }
    }
    @MainActor
    private func kiVorbefuellen() async {
        store.kiLaeuft = true
        store.kiFehler = nil
        defer { store.kiLaeuft = false }
        let titel = vorgang?.titel ?? "Vorgang"
        let beschreibung = vorgang?.beschreibung ?? ""
        let ziel = vorgang?.optionen.first?.label ?? "Ziel erreichen"
        let prompt = """
        Du modellierst einen Pfadgraf (Wegenetz) für einen Rechts-/Strategievorgang.
        Knoten = Zustände (Ist A, geplant, fremdbestimmt, Ziel Z). Kanten = gerichtete Handlungen.
        Liefere 6–10 Knoten und passende Kanten als DAG. p(Erfolg) in Zehnerschritten (0.1…0.9).
        Konvergenz: mehrere Wege dürfen auf denselben Ziel-/Zwischenknoten laufen (keine Duplikate).
        Vorgang: \(titel)
        Beschreibung: \(beschreibung)
        Angestrebte Richtung/Ziel: \(ziel)
        JSON-Felder:
        knoten: [{kennung, typ: Ist-Zustand|Geplanter Zustand|Fremdbestimmt|Zielzustand, bezeichnung, eigenwert, budget}]
        kanten: [{von_kennung, nach_kennung, handlung, kosten, dauer_min, dauer_max, p_erfolg, art: Empfohlen|Möglich|Bedingt|Fremd, steuerung: eigen|fremd|Zufall, grundlage}]
        """
        let schema: [String: Any] = ["type": "object", "properties": [
            "knoten": ["type": "array", "items": ["type": "object", "properties": [
                "kennung": ["type": "string"], "typ": ["type": "string"], "bezeichnung": ["type": "string"],
                "eigenwert": ["type": "number"], "budget": ["type": "number"]
            ]]],
            "kanten": ["type": "array", "items": ["type": "object", "properties": [
                "von_kennung": ["type": "string"], "nach_kennung": ["type": "string"],
                "handlung": ["type": "string"], "kosten": ["type": "number"],
                "dauer_min": ["type": "number"], "dauer_max": ["type": "number"],
                "p_erfolg": ["type": "number"], "art": ["type": "string"],
                "steuerung": ["type": "string"], "grundlage": ["type": "string"]
            ]]]
        ]]
        do {
            let d = try await LLMService.shared.invokeObject(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6",
                logCaseId: caseId, logKiName: "Pfadgraf — KI-Vorbefüllung"
            )
            var neu = Pfadgraf()
            neu.layout = store.graf.layout
            neu.richtung = store.graf.richtung
            neu.optimierung = store.graf.optimierung
            var idMap: [String: UUID] = [:]
            for k in KIJson.array(in: d, keys: "knoten") {
                guard let kennung = KIJson.string(in: k, keys: "kennung") else { continue }
                let typRoh = (KIJson.string(in: k, keys: "typ") ?? "").lowercased()
                let typ: PfadgrafKnotenTyp
                if typRoh.contains("ist") { typ = .ist }
                else if typRoh.contains("fremd") { typ = .fremd }
                else if typRoh.contains("ziel") { typ = .ziel }
                else { typ = .geplant }
                let kn = PfadgrafKnoten(
                    kennung: kennung, typ: typ,
                    bezeichnung: KIJson.string(in: k, keys: "bezeichnung") ?? kennung,
                    ressourcen: .init(budget: KIJson.number(in: k, keys: "budget") ?? 100_000),
                    eigenwert: KIJson.number(in: k, keys: "eigenwert") ?? 0,
                    status: typ == .ist ? .erreicht : .offen
                )
                idMap[kennung] = kn.id
                neu.knoten.append(kn)
                if typ == .ist { neu.startKnotenId = kn.id }
                if typ == .ziel { neu.zielKnotenIds.append(kn.id) }
            }
            for k in KIJson.array(in: d, keys: "kanten") {
                guard let vk = KIJson.string(in: k, keys: "von_kennung", "von"),
                      let nk = KIJson.string(in: k, keys: "nach_kennung", "nach"),
                      let von = idMap[vk], let nach = idMap[nk] else { continue }
                var p = KIJson.number(in: k, keys: "p_erfolg", "p") ?? 0.5
                p = (p > 1 ? p / 100 : p)
                p = (p * 10).rounded() / 10
                let artRoh = (KIJson.string(in: k, keys: "art") ?? "").lowercased()
                let art: PfadgrafKantenArt
                if artRoh.contains("empfohl") { art = .empfohlen }
                else if artRoh.contains("bedingt") { art = .bedingt }
                else if artRoh.contains("fremd") { art = .fremd }
                else { art = .moeglich }
                let stRoh = (KIJson.string(in: k, keys: "steuerung") ?? "eigen").lowercased()
                let st: PfadgrafSteuerung = stRoh.contains("fremd") ? .fremd : (stRoh.contains("zufall") ? .zufall : .eigen)
                neu.kanten.append(PfadgrafKante(
                    von: von, nach: nach,
                    handlung: KIJson.string(in: k, keys: "handlung") ?? "",
                    kosten: KIJson.number(in: k, keys: "kosten") ?? 0,
                    dauerMinTage: KIJson.int(in: k, keys: "dauer_min") ?? 10,
                    dauerMaxTage: KIJson.int(in: k, keys: "dauer_max") ?? 20,
                    pErfolg: p,
                    grundlage: KIJson.string(in: k, keys: "grundlage") ?? "",
                    steuerung: st, art: art
                ))
            }
            guard !neu.knoten.isEmpty else {
                store.kiFehler = "KI lieferte keinen Grafen."
                return
            }
            if neu.startKnotenId == nil { neu.startKnotenId = neu.knoten.first?.id }
            store.graf = neu
            store.neuBerechnen()
        } catch {
            store.kiFehler = error.localizedDescription
        }
    }
}
struct PfadgrafKnotenBlatt: View {
    @State var knoten: PfadgrafKnoten
    var optionswert: Double?
    var knotenwert: Double?
    var istEngpass: Bool
    let onSave: (PfadgrafKnoten) -> Void
    let onDelete: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zustandsblatt — Knoten \(knoten.kennung)")
                .font(.system(size: 14, weight: .bold))
            HStack {
                TextField("Kennung", text: $knoten.kennung).frame(width: 60)
                TextField("Bezeichnung (max. 40)", text: Binding(
                    get: { knoten.bezeichnung },
                    set: { knoten.bezeichnung = String($0.prefix(40)) }
                ))
            }
            Picker("Typ", selection: $knoten.typ) {
                ForEach(PfadgrafKnotenTyp.allCases) { t in Text(t.rawValue).tag(t) }
            }
            .pickerStyle(.segmented)
            Picker("Status", selection: $knoten.status) {
                ForEach(PfadgrafKnotenStatus.allCases) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)
            Group {
                feld("Budget €", $knoten.ressourcen.budget)
                feld("Zeit (Tage)", $knoten.ressourcen.zeitTage)
                feld("Personal", $knoten.ressourcen.personal)
                feld("Eigenwert €", $knoten.eigenwert)
            }
            if istEngpass {
                Label("Engpassknoten — Einzelfehlerpunkt, gehört in die RPN-Tabelle", systemImage: "diamond")
                    .font(.system(size: 11, weight: .semibold))
            }
            if let ow = optionswert {
                Text(String(format: "Optionswert: %.0f (erreichbare Ziele × EV)", ow))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            if let kw = knotenwert {
                Text(String(format: "Knotenwert (Minimax/Max): %.0f", kw))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            HStack {
                Button("Löschen", role: .destructive) { onDelete(knoten.id); dismiss() }
                Spacer()
                Button("Abbrechen") { dismiss() }
                Button("Übernehmen") { onSave(knoten); dismiss() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 480)
    }
    private func feld(_ label: String, _ wert: Binding<Double>) -> some View {
        HStack {
            Text(label).frame(width: 120, alignment: .leading).font(.system(size: 11))
            TextField("", value: wert, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }
}
struct PfadgrafKantenBlatt: View {
    @State var kante: PfadgrafKante
    let knoten: [PfadgrafKnoten]
    let onSave: (PfadgrafKante) -> Void
    let onDelete: (UUID) -> Void
    let onKnotenEinfuegen: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Handlungsblatt — Kante")
                .font(.system(size: 14, weight: .bold))
            TextField("Handlung", text: $kante.handlung)
            HStack {
                Picker("Von", selection: $kante.von) {
                    ForEach(knoten) { k in Text(k.kennung).tag(k.id) }
                }
                Picker("Nach", selection: $kante.nach) {
                    ForEach(knoten) { k in Text(k.kennung).tag(k.id) }
                }
            }
            HStack {
                Text("Kosten €").frame(width: 100, alignment: .leading).font(.system(size: 11))
                TextField("", value: $kante.kosten, format: .number).textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Dauer min/max").frame(width: 100, alignment: .leading).font(.system(size: 11))
                TextField("", value: $kante.dauerMinTage, format: .number).frame(width: 60)
                Text("–")
                TextField("", value: $kante.dauerMaxTage, format: .number).frame(width: 60)
            }
            HStack {
                Text("p(Erfolg)").frame(width: 100, alignment: .leading).font(.system(size: 11))
                Slider(value: Binding(
                    get: { kante.pErfolg },
                    set: { kante.pErfolg = ($0 * 10).rounded() / 10 }
                ), in: 0...1, step: 0.1)
                Text(String(format: "%.0f %%", kante.pErfolg * 100))
                    .font(.system(size: 11, design: .monospaced)).frame(width: 40)
            }
            TextField("Rechtsgrundlage / Voraussetzung", text: $kante.grundlage)
            TextField("Voraussetzung (→ bedingt)", text: $kante.voraussetzung)
                .onChange(of: kante.voraussetzung) { _, neu in
                    if !neu.isEmpty && kante.art == .moeglich { kante.art = .bedingt }
                }
            Picker("Art", selection: $kante.art) {
                ForEach(PfadgrafKantenArt.allCases) { a in Text(a.rawValue).tag(a) }
            }.pickerStyle(.segmented)
            Picker("Steuerung", selection: $kante.steuerung) {
                ForEach(PfadgrafSteuerung.allCases) { s in Text(s.rawValue).tag(s) }
            }.pickerStyle(.segmented)
            Button {
                onKnotenEinfuegen()
            } label: {
                Label("Knoten auf dieser Kante einfügen (A→C wird A→D→C)", systemImage: "plus.diamond")
            }
            HStack {
                Button("Löschen", role: .destructive) { onDelete(kante.id); dismiss() }
                Spacer()
                Button("Abbrechen") { dismiss() }
                Button("Übernehmen") {
                    kante.verbrauch.budget = kante.kosten * 0.8
                    kante.verbrauch.zeitTage = Double(kante.dauerMinTage)
                    onSave(kante)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 520)
    }
}
struct TabPfadgraf: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    var body: some View {
        PfadgrafLinse(vorgangId: nil, caseId: viewModel.caseId)
            .frame(minHeight: 640)
    }
}
