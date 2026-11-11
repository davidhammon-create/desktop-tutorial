import SwiftUI
enum NexusBrettRegister: String, CaseIterable, Identifiable {
    case lage = "Lage"
    case brett = "Brett"
    case zuege = "Züge"
    case saal = "Saal"
    case regelwerk = "Regelwerk"
    case kette = "Kette"
    var id: String { rawValue }
}
struct NexusBrett: View {
    let vorgangId: UUID
    @Bindable private var nexus = NexusStore.shared
    @Bindable private var vorgaenge = VorgangStore.shared
    @Bindable private var appearance = AppearanceStore.shared
    @State private var optionId: UUID?
    @State private var register: NexusBrettRegister = .brett
    @State private var modus: NexusAnsichtsModus = .netz
    @State private var dichte: NexusDichte = .karte
    @State private var fokus: UUID?
    @State private var krumen: [UUID] = []
    @State private var herleitungOffen = false
    @State private var saalEingabe = ""
    @State private var treffer: NexusKonterKarte?
    @State private var gewaehltId: String?
    @State private var rechenkern: NexusRechenkern = .klassisch
    @State private var fehler: String?
    @State private var zeigeAnlegen = false
    @State private var anlegenParent: UUID?
    @State private var neuerTyp: NexusKnotenTyp = .beleg
    @State private var neuerKern: String = ""
    private var vorgang: Vorgang? { vorgaenge.vorgang(vorgangId) }
    private var optionen: [VorgangOption] { vorgang?.aktiveOptionen ?? [] }
    private var aktivId: UUID? { optionId ?? optionen.first?.id }
    private var graph: NexusGraph? {
        if let id = aktivId, let g = nexus.graph(optionId: id) { return g }
        return nexus.graphFuerVorgang(vorgangId)
    }
    private var stellung: NexusStellung {
        NexusEngine.bewerte(mit: rechenkern, graph: graph ?? .leer)
    }
    var body: some View {
        VStack(spacing: 0) {
            kopf
            Rectangle().fill(InterfacePalette.trennlinie).frame(height: 1)
            registerLeiste
            Rectangle().fill(InterfacePalette.trennlinie).frame(height: 1)
            Group {
                if let g = graph, let oid = aktivId {
                    inhalt(g, optionId: oid)
                } else {
                    skelettWahl
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(NexusPapier.grund)
        .fontDesign(.default)
        .preferredColorScheme(appearance.modus.preferredScheme)
        .sheet(isPresented: $herleitungOffen) {
            NexusHerleitungSheet(stellung: stellung)
        }
        .alert("Kante verweigert", isPresented: Binding(
            get: { fehler != nil },
            set: { if !$0 { fehler = nil } }
        )) {
            Button("Verstanden") { fehler = nil }
        } message: {
            Text(fehler ?? "")
        }
        .onAppear {
            if optionId == nil { optionId = optionen.first?.id }
            sichereGraph()
        }
    }
    private var kopf: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXUS")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.4)
                    .foregroundStyle(InterfacePalette.sekundaer)
                Text("Stellung · Argumentationsgraph")
                    .font(.system(size: 11))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            if optionen.count > 1 {
                Picker("Option", selection: Binding(
                    get: { aktivId },
                    set: { optionId = $0; fokus = nil; krumen = [] }
                )) {
                    ForEach(optionen) { o in
                        Text(o.label).tag(Optional(o.id))
                    }
                }
                .frame(maxWidth: 200)
            }
            Spacer()
            Button { herleitungOffen = true } label: {
                HStack(spacing: 6) {
                    Herkunftsmarke(herkunft: .formel, groesse: 7)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("P(ERFOLG)")
                            .font(.system(size: 9, weight: .bold))
                            .kerning(0.5)
                            .foregroundStyle(InterfacePalette.sekundaer)
                        Text(stellung.pBand)
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundStyle(InterfacePalette.berechnet)
                        Text(stellung.betaHinweis)
                            .font(.system(size: 9))
                            .foregroundStyle(InterfacePalette.sekundaer)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Herleitung — jede Zwischenstufe, wie ein Schachprogramm")
            HStack(spacing: 6) {
                ForEach(NexusAnsichtsModus.allCases) { m in
                    NexusChip(titel: "[\(m.taste)] \(m.titel)", aktiv: modus == m) { modus = m }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(InterfacePalette.Material.l1)
    }
    private var registerLeiste: some View {
        HStack(spacing: 6) {
            ForEach(NexusBrettRegister.allCases) { r in
                NexusChip(titel: r.rawValue, aktiv: register == r) {
                    register = r
                    if r == .brett { modus = .netz }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(InterfacePalette.Material.l1)
    }
    @ViewBuilder
    private func inhalt(_ g: NexusGraph, optionId: UUID) -> some View {
        if modus == .schriftsatz {
            NexusSchriftsatzPDF(graph: g)
        } else {
            Group {
                switch register {
                case .lage:
                    NexusLageRegister(stellung: stellung, kern: $rechenkern, onHerleitung: { herleitungOffen = true })
                case .brett:
                    brettFlaeche(g, optionId: optionId)
                case .zuege:
                    NexusZuegeRegister(stellung: stellung)
                case .saal:
                    NexusSaalRegister(stellung: stellung, eingabe: $saalEingabe, treffer: $treffer)
                case .regelwerk:
                    NexusRegelwerkRegister(vorgangId: vorgangId, optionId: optionId, gewaehltId: $gewaehltId)
                case .kette:
                    NexusKetteRegister(stellung: stellung, vorgangId: vorgangId, optionId: optionId)
                }
            }
        }
    }
    private func brettFlaeche(_ g: NexusGraph, optionId: UUID) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(NexusDichte.allCases) { d in
                    NexusChip(titel: d.titel, aktiv: dichte == d) { dichte = d }
                }
                Text("Gesamtbaum · Klick zoomt in den Ast")
                    .font(.system(size: 10))
                    .foregroundStyle(InterfacePalette.sekundaer)
                Spacer()
                Text("\(stellung.suche.bewerteteStellungen) Stellungen · \(stellung.kern.titel)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(InterfacePalette.Material.l1)
            if zeigeAnlegen {
                knotenForm(g, optionId: optionId)
            }
            HStack(alignment: .top, spacing: 0) {
                Group {
                    if modus == .liste {
                        ScrollView {
                            NexusListePDF(graph: g, dichte: dichte) { id in
                                modus = .netz
                                register = .brett
                                zoom(auf: id, graph: g)
                            }
                        }
                    } else {
                        NexusNetzView(
                            graph: g,
                            dichte: dichte == .voll ? .karte : dichte,
                            fokus: $fokus,
                            krumen: $krumen,
                            onHinzufuegen: { parent in
                                anlegenParent = parent
                                neuerTyp = (g.knoten(parent)?.typ == .argGegner) ? .argEigen : .beleg
                                zeigeAnlegen = true
                            },
                            onPTap: { herleitungOffen = true }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if dichte == .voll, let k = (fokus.flatMap { g.knoten($0) } ?? g.wuerzel().first) {
                    NexusVollSpalte(knoten: k, graph: g)
                }
            }
        }
    }
    private func zoom(auf id: UUID, graph: NexusGraph) {
        if let alt = fokus ?? graph.wuerzel().first?.id, alt != id {
            krumen.append(alt)
        }
        fokus = id
    }
    private func sichereGraph() {
        guard graph == nil, let v = vorgang, let oid = aktivId ?? optionen.first?.id else { return }
        if v.kurzId == "V-2026-0004" || v.titel.localizedCaseInsensitiveContains("werklohn") {
            nexus.setze(NexusDemo.werklohnSalvatorisch(optionId: oid, vorgangId: v.id))
            optionId = oid
            register = .brett
            modus = .netz
        } else if v.titel.localizedCaseInsensitiveContains("kündigung") {
            nexus.setze(NexusDemo.kschgSkelett(optionId: oid, vorgangId: v.id))
            optionId = oid
            register = .brett
            modus = .netz
        }
    }
    private var skelettWahl: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("ERÖFFNUNG — DAS SKELETT KOMMT AUS DEM REGELWERK")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.4)
                    .foregroundStyle(NexusPapier.leise)
                Text("Kein Freitext. Keine KI-Struktur. Wählen Sie die Anspruchsgrundlage. Die KI darf später Blätter füllen — nicht das Brett aufstellen.")
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                ForEach(NexusRegelwerk.alle) { vorlage in
                    Button {
                        guard let oid = aktivId, let v = vorgang else { return }
                        nexus.legeSkelettAn(vorgangId: v.id, optionId: oid, vorlage: vorlage, store: vorgaenge)
                        modus = .netz
                        register = .brett
                        fokus = nil
                        krumen = []
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vorlage.rechtsgebiet)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(NexusPapier.leise)
                            Text(vorlage.norm).font(.system(size: 13, weight: .semibold)).foregroundStyle(NexusPapier.text)
                            Text(vorlage.ziel).font(.system(size: 11)).foregroundStyle(NexusPapier.leise)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(NexusPapier.karte))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(NexusPapier.grund)
    }
    private func knotenForm(_ g: NexusGraph, optionId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KNOTEN HINZUFÜGEN — LAZY, KEIN AUTOMATISCHES AUFFÜLLEN")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(NexusPapier.leise)
            HStack {
                Picker("Typ", selection: $neuerTyp) {
                    ForEach(NexusKnotenTyp.allCases) { t in
                        Text(t.kartenLabel).tag(t)
                    }
                }
                TextField("Kern (max. 12 Wörter)", text: $neuerKern)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
                Button("Anlegen") {
                    let parent = anlegenParent ?? fokus ?? g.wuerzel().first?.id
                    var k = NexusKnoten(parentId: parent, typ: neuerTyp, kern: neuerKern, status: .belegt)
                    k.setzeKern(neuerKern)
                    if let err = nexus.fuegeKnotenHinzu(optionId, k) {
                        fehler = err
                    } else {
                        neuerKern = ""
                        zeigeAnlegen = false
                        nexus.uebernehmeP(in: vorgaenge, vorgangId: vorgangId, optionId: optionId)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                Button("Abbrechen") { zeigeAnlegen = false }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(NexusPapier.leise)
            }
        }
        .padding(12)
    }
}
private struct NexusLageRegister: View {
    let stellung: NexusStellung
    @Binding var kern: NexusRechenkern
    let onHerleitung: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    lageKarte("P(Erfolg)", stellung.pBand, "Band, nicht Dezimal. Dezimal nur in der Herleitung.")
                    lageKarte("β", String(format: "%.1f", stellung.beta).replacingOccurrences(of: ".", with: ","), stellung.betaHinweis)
                    lageKarte("Belegtheit", "\(stellung.belegteBlaetter)/\(stellung.blaetterGesamt)", "Blätter mit Q>0. Ohne Beleg keine Zahl.")
                    lageKarte("Suche", "\(stellung.suche.bewerteteStellungen) Stellungen", "\(stellung.suche.dauerMs) ms · Tiefe \(stellung.suche.tiefe)")
                }
                HStack(alignment: .top, spacing: 12) {
                    lageKarte("Eigen", "\(stellung.material.eigene)", "Konter · argEigen")
                    lageKarte("Gegner", "\(stellung.material.gegner)", "Angriffe · argGegner")
                    lageKarte("Flanken", "\(stellung.material.flanken)", "Merkmale ohne Beleg")
                    lageKarte("Belege", "\(stellung.material.belege)", "Urkunden, Zeugen, Indizien")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Formel")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.8)
                        .foregroundStyle(NexusPapier.leise)
                    Text(stellung.aggregationsZeile)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Premium.text)
                        .textSelection(.enabled)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(NexusPapier.banner)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rechenkern")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.8)
                        .foregroundStyle(NexusPapier.leise)
                    HStack(spacing: 8) {
                        ForEach(NexusRechenkern.allCases) { k in
                            Button {
                                if k.bereit { kern = k }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(k.titel)
                                            .font(.system(size: 12, weight: .semibold))
                                        Spacer()
                                        Text(k.bereit ? "aktiv" : "Schnittstelle")
                                            .font(.system(size: 10))
                                            .foregroundStyle(k.bereit ? NexusPapier.text : NexusPapier.leise)
                                    }
                                    Text(k.satz)
                                        .font(.system(size: 11))
                                        .foregroundStyle(NexusPapier.leise)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 8).fill(kern == k ? InterfacePalette.Material.l2 : InterfacePalette.Material.l3))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(kern == k ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1))
                                .opacity(k.bereit ? 1 : 0.7)
                            }
                            .buttonStyle(.plain)
                            .disabled(!k.bereit)
                            .help(k.bereit ? k.satz : "Dieselbe Bewertungsfunktion. Hardware später — keine vorgetäuschte Präzision.")
                        }
                    }
                }
                Button(action: onHerleitung) {
                    HStack {
                        Text("Herleitung öffnen")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(NexusPapier.text)
                        Spacer()
                        Text("jede Zwischenstufe · wie ein Schachprogramm")
                            .font(.system(size: 11))
                            .foregroundStyle(NexusPapier.leise)
                    }
                    .padding(14)
                    .background(NexusPapier.karte)
                    .overlay(Rectangle().stroke(InterfacePalette.trennlinie, lineWidth: 1))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Was NEXUS ist — und was nicht")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(NexusPapier.text)
                    Text("NEXUS schätzt nicht. NEXUS rechnet. Claude, GPT und vergleichbare Modelle dürfen Blätter füllen — Q, P, N vorschlagen. 100 % der Zahl kommt aus der Formel Sroh = Q×P×N, saturierenden Stützen und den Kanten greift_an 0,60 / entkräftet 0,85 / schließt_aus 1,00. Quantencomputer und Cluster rechnen später dieselbe Funktion schneller, nicht eine andere. Bis dahin plant dieses Brett die Züge von Unternehmen und Anwälten: welche Flanke schließen, welcher Konter, welche Frist. Organon sieht diesen Graphen nicht. Advocatus konsumiert die Konter-Bibliothek, erzeugt keine Knoten.")
                        .font(.system(size: 12))
                        .foregroundStyle(NexusPapier.leise)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(NexusPapier.karte)
            }
            .padding(24)
        }
        .background(NexusPapier.grund)
    }
    private func lageKarte(_ titel: String, _ wert: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titel)
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.6)
                .foregroundStyle(NexusPapier.leise)
            Text(wert)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(NexusPapier.text)
            Text(note)
                .font(.system(size: 10))
                .foregroundStyle(NexusPapier.leise)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NexusPapier.karte)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
    }
}
private struct NexusZuegeRegister: View {
    let stellung: NexusStellung
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nächste Züge")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NexusPapier.text)
                Text("Kap. 09: NEXUS bewertet Stellungen, nicht Züge — und leitet daraus die stärksten Hebel ab. Jeder Zug ist eine simulierte Folgestellung. Die KI darf den Zug formulieren. Die Reihenfolge kommt aus ΔP. Cluster und Quanten suchen später denselben Zugraum.")
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                HStack(spacing: 16) {
                    Text("\(stellung.suche.bewerteteStellungen) Stellungen bewertet")
                    Text("Kern \(stellung.kern.titel)")
                    Text("Zielband 60–70 %")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(NexusPapier.leise)
                if stellung.zuege.isEmpty {
                    Text("Keine offenen Hebel. Die Stellung ist geschlossen — oder das Graph-Skelett ist leer.")
                        .font(.system(size: 12))
                        .foregroundStyle(NexusPapier.leise)
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(stellung.zuege.enumerated()), id: \.element.id) { i, zug in
                        zugZeile(rang: i + 1, zug: zug)
                    }
                }
            }
            .padding(24)
        }
        .background(NexusPapier.grund)
    }
    private func zugZeile(rang: Int, zug: NexusZug) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(rang).")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(NexusPapier.leise)
                .frame(width: 32, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(zug.hebel.titel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NexusPapier.leise)
                    Text(zug.titel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NexusPapier.text)
                    Spacer()
                    Text(zug.deltaPText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(NexusPapier.text)
                }
                Text(zug.satz)
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(NexusAnzeige.band(zug.pVorher))  →  \(NexusAnzeige.band(zug.pNachher))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(NexusPapier.leise)
            }
        }
        .padding(14)
        .background(NexusPapier.karte)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
    }
}
private struct NexusSaalRegister: View {
    let stellung: NexusStellung
    @Binding var eingabe: String
    @Binding var treffer: NexusKonterKarte?
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Live-Saal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NexusPapier.text)
                Text("Kein Mikrofon. § 201 StGB, § 169 GVG. Der Anwalt tippt das Stichwort, das der Gegner gerade gesagt hat. NEXUS legt die passende Konter-Karte auf. Advocatus konsumiert diese Bibliothek — erzeugt keine Knoten.")
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                HStack {
                    TextField("Stichwort — z. B. salvatorische Klausel, Schriftform, Verjährung", text: $eingabe)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
                        .onSubmit { suche() }
                    Button("Legen", action: suche)
                        .buttonStyle(.borderedProminent)
                        .tint(InterfacePalette.aktion)
                }
            }
            .padding(20)
            Divider()
            if let t = treffer {
                NexusKonterKarteView(karte: t)
                    .padding(20)
            } else if eingabe.trimmingCharacters(in: .whitespaces).isEmpty == false {
                Text("Kein Treffer in der Konter-Bibliothek dieses Graphen. Das Stichwort ist noch kein Knoten — oder der Konter fehlt. NEXUS erfindet keine Karte.")
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                    .padding(20)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bibliothek dieses Vorgangs")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NexusPapier.leise)
                    let karten = NexusEngine.konterKarten(in: stellung.graph)
                    if karten.isEmpty {
                        Text("Noch keine gedeckten Angriffe. Legen Sie am Brett einen Konter unter einen Gegner-Knoten.")
                            .font(.system(size: 12))
                            .foregroundStyle(NexusPapier.leise)
                    } else {
                        ForEach(karten) { k in
                            Text("· \(k.gegnerKern)  →  \(k.hauptKern)")
                                .font(.system(size: 12))
                                .foregroundStyle(NexusPapier.text)
                        }
                    }
                }
                .padding(20)
            }
            Spacer()
        }
        .background(NexusPapier.grund)
    }
    private func suche() {
        treffer = NexusEngine.treffer(stichwort: eingabe, in: stellung.graph)
    }
}
private struct NexusRegelwerkRegister: View {
    let vorgangId: UUID
    let optionId: UUID
    @Binding var gewaehltId: String?
    @Bindable private var nexus = NexusStore.shared
    @Bindable private var store = VorgangStore.shared
    var body: some View {
        HSplitView {
            List(NexusRegelwerk.alle, selection: $gewaehltId) { r in
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.rechtsgebiet)
                        .font(.system(size: 10))
                        .foregroundStyle(NexusPapier.leise)
                    Text(r.kurz)
                        .font(.system(size: 12, weight: .semibold))
                    Text(r.norm)
                        .font(.system(size: 11))
                        .foregroundStyle(NexusPapier.leise)
                }
                .tag(Optional(r.id))
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(NexusPapier.leiste)
            .frame(minWidth: 240)
            if let r = NexusRegelwerk.alle.first(where: { $0.id == gewaehltId }) ?? NexusRegelwerk.alle.first {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(r.kurz)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(NexusPapier.text)
                        Text("\(r.rechtsgebiet) · Verknüpfung \(r.verknuepfung)")
                            .font(.system(size: 12))
                            .foregroundStyle(NexusPapier.leise)
                        Text("Merkmale")
                            .font(.system(size: 11, weight: .semibold))
                        ForEach(r.merkmale) { m in
                            Text("· \(m.text)\(m.vermutung ? " (vermutet)" : "")")
                                .font(.system(size: 12))
                        }
                        if !r.einreden.isEmpty {
                            Text("Typische Einreden — vorbereiten, nicht automatisch anlegen")
                                .font(.system(size: 11, weight: .semibold))
                            ForEach(r.einreden, id: \.self) { e in
                                Text("· \(e)")
                                    .font(.system(size: 12))
                            }
                        }
                        Button("Skelett in diesen Vorgang übernehmen") {
                            nexus.legeSkelettAn(vorgangId: vorgangId, optionId: optionId, vorlage: r, store: store)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(InterfacePalette.aktion)
                        Text("Stufe 1: statisches Skelett. Die KI darf später Blätter füllen. Die Struktur kommt aus dem Regelwerk, nicht aus dem Modell.")
                            .font(.system(size: 11))
                            .foregroundStyle(NexusPapier.leise)
                    }
                    .padding(24)
                }
            }
        }
        .background(NexusPapier.grund)
        .onAppear {
            if gewaehltId == nil { gewaehltId = NexusRegelwerk.alle.first?.id }
        }
    }
}
private struct NexusKetteRegister: View {
    let stellung: NexusStellung
    let vorgangId: UUID
    let optionId: UUID
    @Bindable private var nexus = NexusStore.shared
    @Bindable private var store = VorgangStore.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Zulieferer an die bestehende Kette")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NexusPapier.text)
                Text("Kap. 07. NEXUS ist die sechste Linse. Was hier berechnet wird, fließt in die fünf anderen — nicht als Chat, als Zahl und als offene Flanke.")
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                ketteZeile(
                    schritt: "4  Streitwert",
                    was: "P(Erfolg) als Band. Der Schieberegler ist tot. Die Zahl kommt aus diesem Graphen.",
                    wert: stellung.pBand
                )
                ketteZeile(
                    schritt: "7  RPN",
                    was: "Offene Flanken = ungedeckte Angriffe. Jede Flanke ist ein Risiko, das der RPN-Rechner nicht erfinden muss.",
                    wert: stellung.material.flanken == 0 ? "keine offenen Flanken" : "\(stellung.material.flanken) Flanke(n)"
                )
                ketteZeile(
                    schritt: "8  Fristen",
                    was: "Klausel-Knoten tragen den Typ Frist | Termin | Ereignis. Die Frist ist an die Klausel gebunden.",
                    wert: "siehe Fristen-Linse"
                )
                ketteZeile(
                    schritt: "9  Advocatus",
                    was: "Konter-Bibliothek. Advocatus konsumiert, erzeugt keine Knoten. Organon sieht diesen Graphen nicht.",
                    wert: "\(NexusEngine.konterKarten(in: stellung.graph).count) Karten"
                )
                ketteZeile(
                    schritt: "Empfehlung",
                    was: "Hebel nach ΔP. Eine Rangliste mit Vergleich — Anhang A. Kein zweites Ranking.",
                    wert: "\(stellung.zuege.count) Züge"
                )
                Button("P(Erfolg) jetzt in Schritt 4 übernehmen") {
                    nexus.uebernehmeP(in: store, vorgangId: vorgangId, optionId: optionId)
                }
                .buttonStyle(.borderedProminent)
                .tint(InterfacePalette.aktion)
            }
            .padding(24)
        }
        .background(NexusPapier.grund)
    }
    private func ketteZeile(schritt: String, was: String, wert: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(schritt)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(width: 140, alignment: .leading)
                .foregroundStyle(NexusPapier.text)
            VStack(alignment: .leading, spacing: 4) {
                Text(was)
                    .font(.system(size: 12))
                    .foregroundStyle(NexusPapier.leise)
                    .fixedSize(horizontal: false, vertical: true)
                Text(wert)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NexusPapier.text)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NexusPapier.karte)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
    }
}
struct NexusHerleitungSheet: View {
    let stellung: NexusStellung
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Herleitung")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(stellung.pBand)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(InterfacePalette.berechnet)
                Button("Schließen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            Divider()
            List(stellung.herleitung) { z in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(z.ebene.kartenLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(z.kuerzel)
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Text(String(format: "S=%.4f", z.sNetto).replacingOccurrences(of: ".", with: ","))
                            .font(.system(.caption, design: .monospaced))
                    }
                    Text(z.zeile)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                    Text(z.kern)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            Text("β = \(String(format: "%.1f", stellung.beta).replacingOccurrences(of: ".", with: ",")) · \(stellung.betaHinweis). Dezimalstellen stehen nur hier. Im Kopf bleibt das Band. \(stellung.hinweis)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(16)
        }
        .frame(minWidth: 720, minHeight: 520)
        .background(Premium.void)
        .fontDesign(.default)
        .preferredColorScheme(AppearanceStore.shared.modus.preferredScheme)
    }
}
struct NexusStudioAbschnitt: View {
    var vorgangId: UUID?
    var body: some View {
        if let id = vorgangId {
            NexusBrett(vorgangId: id)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("NEXUS")
                    .font(.system(size: 22, weight: .semibold))
                Text("Öffnen Sie einen Vorgang. NEXUS bewertet Stellungen — wie ein Schachprogramm, mit juristischer Semantik auf den Kanten. Kein Chat. Eine Rechnung.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 520, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(32)
            .background(NexusPapier.grund)
        }
    }
}
