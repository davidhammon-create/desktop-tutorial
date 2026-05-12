//
//  StrategieChecklisteView.swift
//  Konversion von src/components/lexara/StrategieCheckliste.jsx (704 Zeilen) nach SwiftUI.
//  Geführte strategische Checkliste basierend auf Sun Tzu, Machiavelli sowie
//  Rspr./Lit./Fall-Ergebnissen, mit interaktiven 2D-Funktionsvisualisierungen.
//

import SwiftUI
import Charts

// MARK: - Prinzipien-Bibliothek

fileprivate struct Prinzip: Identifiable, Hashable {
    let id: String
    let titel: String
    let zitat: String
    let kategorie: String
    let norm: String
}

fileprivate let SUN_TZU: [Prinzip] = [
    .init(id: "st1", titel: "Kenne deinen Feind, kenne dich selbst",
          zitat: "Wer den Feind und sich selbst kennt, wird in hundert Schlachten nicht scheitern.",
          kategorie: "Analyse",
          norm: "§ 138 ZPO (Wahrheitspflicht), § 282 ZPO (Prozessförderungspflicht)"),
    .init(id: "st2", titel: "Angriff auf Schwachstellen",
          zitat: "Greife Stärke nicht frontal an — umgehe sie und schlage bei der Schwäche.",
          kategorie: "Taktik", norm: "§ 138 ZPO, Widerklage § 33 ZPO"),
    .init(id: "st3", titel: "Überraschungsmoment",
          zitat: "Reagiere auf Veränderungen schneller als der Gegner erwartet.",
          kategorie: "Prozess", norm: "§ 296 ZPO, § 139 ZPO"),
    .init(id: "st4", titel: "Psychologische Kriegsführung",
          zitat: "Der überlegene Krieger gewinnt, bevor er kämpft.",
          kategorie: "Verhandlung", norm: "§ 278 ZPO (Güteverhandlung), § 42 ZPO (Befangenheit)"),
    .init(id: "st5", titel: "Ressourcenschonung",
          zitat: "Ein langer Krieg nützt niemandem.",
          kategorie: "Kosten", norm: "§§ 91 ff. ZPO, § 93 ZPO"),
    .init(id: "st6", titel: "Flexible Strategie (Wasser-Prinzip)",
          zitat: "Wasser hat keine feste Form — passe deine Strategie der Lage an.",
          kategorie: "Adaptiv", norm: "§ 263 ZPO (Klageänderung), § 264 ZPO"),
]

fileprivate let MACHIAVELLI: [Prinzip] = [
    .init(id: "mv1", titel: "Stärke vor Recht",
          zitat: "Der Fürst muss gleichzeitig Löwe und Fuchs sein.",
          kategorie: "Macht", norm: "§ 935 ZPO (e.V.), §§ 916 ff. ZPO (Arrest)"),
    .init(id: "mv2", titel: "Initiale Entscheidungsschnelligkeit",
          zitat: "Ein langsamer Angriff gibt dem Gegner Zeit – handle zuerst und entscheide.",
          kategorie: "Prozess", norm: "§ 688 ZPO, §§ 935 ff. ZPO"),
    .init(id: "mv3", titel: "Koalitionen schmieden",
          zitat: "Man soll niemals glauben, man könne immer sichere Entschlüsse fassen.",
          kategorie: "Netzwerk", norm: "§ 72 ZPO (Streitverkündung), § 64 ZPO"),
    .init(id: "mv4", titel: "Erschütterung des Vertrauens",
          zitat: "Der kluge Herrscher muss sein Wort nicht halten.",
          kategorie: "Psychologie", norm: "§ 138 ZPO, § 421 ZPO"),
    .init(id: "mv5", titel: "Erschöpfungstaktik",
          zitat: "Halte die Gegner in einem Kriegszustand.",
          kategorie: "Kosten", norm: "§§ 91a ZPO, § 281 ZPO"),
    .init(id: "mv6", titel: "Die Wahrheit dosiert einsetzen",
          zitat: "Täusche so viel, dass der Gegner das Echte nicht erkennt.",
          kategorie: "Taktik", norm: "§ 402 ZPO, § 373 ZPO"),
]

// MARK: - Checklisten-Item
fileprivate struct ChecklistenItem: Identifiable, Hashable {
    let id: String
    var quelle: String          // "suntzu" | "machiavelli"
    var prioritaet: String      // "kritisch" | "hoch" | "mittel"
    var titel: String
    var zitat: String
    var kategorie: String
    var empfehlung: String?
    var norm: String?
    var lit: String?
    var rspr: String?
    var risiko: String?
    var kiGenerated: Bool = false
}

// MARK: - Diagramm-Modus
fileprivate enum ChartMode: String, CaseIterable, Identifiable {
    case wave = "sin(t) Prognose"
    case linear = "f(x)=mx+b"
    case scatter3d = "3D Argument-Feld"
    case radar = "Radar-Profil"
    var id: Self { self }
}

// MARK: - Hauptansicht

struct StrategieChecklisteView: View {
    let caseId: String
    let caseData: Case?
    var kiMode: Bool = true

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var deadlines: [Deadline] = []
    @State private var persons: [Person] = []
    @State private var gegnerVerhalten: [GegnerVerhalten] = []
    @State private var loading = true
    @State private var kiLoading = false
    @State private var checklist: [ChecklistenItem] = []
    @State private var checked: Set<String> = []
    @State private var expanded: Set<String> = []
    @State private var activeFilter: String = "alle"
    @State private var chartMode: ChartMode = .wave

    private var prognose: Double { caseData?.prognose ?? 50 }
    private var eigenArgs: [Argument] { args.filter { $0.side == .eigen } }
    private var gegnerArgs: [Argument] { args.filter { $0.side == .gegner } }
    private var progress: Int {
        guard !checklist.isEmpty else { return 0 }
        return Int(Double(checked.count) / Double(checklist.count) * 100)
    }
    private var richterRate: Double { caseData?.richterKlaegerRate ?? 50 }

    var body: some View {
        ScrollView {
            if loading {
                ProgressView("Lade Falldaten…").padding(40)
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    statsChips
                    visualisierung
                    filterChips
                    checklistView
                    prinzipienReferenz
                }
                .padding()
            }
        }
        .navigationTitle("Strategie-Checkliste")
        .task { await load() }
    }

    // MARK: Sub-Views

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title2).foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text("Strategische Checkliste — Sun Tzu & Machiavelli").bold().font(.callout)
                Text("Geführte nächste Schritte basierend auf allen Fallergebnissen, Prognosen und strategischen Prinzipien.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    ProgressView(value: Double(progress), total: 100).tint(.green)
                    Text("\(progress)%").font(.caption2).bold()
                    Text("\(checked.count)/\(checklist.count) erledigt").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            Spacer()
            Button {
                Task { await runKIChecklist() }
            } label: {
                Label(kiLoading ? "KI lädt…" : "KI-Schritte ergänzen", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(kiLoading)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsChips: some View {
        let items: [(String, String, Color)] = [
            ("Prognose", "\(Int(prognose))%",
             prognose >= 55 ? .green : (prognose >= 40 ? .orange : .red)),
            ("Eigene Args", "\(eigenArgs.count)", .blue),
            ("Gegner Args", "\(gegnerArgs.count)", .red),
            ("Beweise", "\(evidence.count)", .purple),
            ("Versäumt", "\(deadlines.filter { $0.status == .versaeumt }.count)",
             deadlines.contains(where: { $0.status == .versaeumt }) ? .red : .gray),
            ("Richterquote", "\(Int(richterRate))%", .gray),
        ]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 6) {
            ForEach(items, id: \.0) { item in
                VStack {
                    Text(item.1).font(.title3).bold().foregroundStyle(item.2)
                    Text(item.0).font(.caption2).foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(item.2.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var visualisierung: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Strategische Visualisierung", systemImage: "chart.xyaxis.line").bold().font(.callout)
                Spacer()
                Picker("Modus", selection: $chartMode) {
                    ForEach(ChartMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)
            }
            Group {
                switch chartMode {
                case .wave:      prognoseWaveChart
                case .linear:    linearChart
                case .scatter3d: scatterChart
                case .radar:     radarChart
                }
            }
            .frame(height: 240)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    /// Sinuskurve y(t) = prognose + (prognose/2) * sin(t)
    private var prognoseWaveChart: some View {
        let amp = prognose / 2
        let data: [(t: Double, y: Double, lower: Double)] = (0..<40).map { i in
            let t = Double(i) * 0.4
            return (t,
                    prognose + amp * sin(t),
                    prognose - amp * 0.4 * sin(t + .pi / 3))
        }
        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("t", p.t), y: .value("y", p.y), series: .value("Serie", "Prognose"))
                    .foregroundStyle(.indigo)
            }
            ForEach(Array(data.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("t", p.t), y: .value("y", p.lower), series: .value("Serie", "Risiko"))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
            RuleMark(y: .value("50%", 50)).foregroundStyle(.orange).lineStyle(StrokeStyle(dash: [4]))
        }
        .chartYScale(domain: 0...100)
    }

    /// Lineare Strategie-Funktion f(x) = m·x + b
    private var linearChart: some View {
        let m: Double = prognose > 50 ? 2.1 : 1.2
        let b: Double = max(5, prognose - Double(eigenArgs.count) * m)
        let data = (0..<15).map { x in (Double(x), m * Double(x) + b) }
        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("x", p.0), y: .value("f(x)", p.1)).foregroundStyle(.green)
                PointMark(x: .value("x", p.0), y: .value("f(x)", p.1)).foregroundStyle(.green)
            }
            RuleMark(y: .value("50%", 50)).foregroundStyle(.orange).lineStyle(StrokeStyle(dash: [4]))
        }
        .chartYScale(domain: 0...100)
    }

    /// 3D-ähnlicher Scatter (X=Stärke, Y=Beweis-Ø, Symbolgröße = Beweisanzahl)
    private var scatterChart: some View {
        struct ScatterPt: Identifiable {
            let id = UUID(); let x: Double; let y: Double; let size: Double
            let name: String; let side: ArgumentSide
        }
        let data: [ScatterPt] = args.prefix(12).enumerated().map { (i, a) in
            let related = evidence.filter { $0.argumentId == a.id }
            let evCount = related.count
            let yVal = evCount > 0 ? related.reduce(0.0) { $0 + ($1.weight ?? 5) } / Double(evCount) : 0
            return ScatterPt(x: a.strength ?? 5, y: yVal,
                             size: Double(evCount) * 15 + 10,
                             name: a.title.prefix(14).description, side: a.side)
        }
        return Chart {
            ForEach(data) { p in
                PointMark(x: .value("Stärke", p.x), y: .value("Ø Gewicht", p.y))
                    .symbolSize(p.size * 4)
                    .foregroundStyle(p.side == .eigen ? .green : .red)
            }
        }
        .chartXScale(domain: 0...10)
        .chartYScale(domain: 0...10)
    }

    /// Radar – wir nutzen Bar-Chart als Ersatz auf macOS, da Charts kein Radar bietet.
    private var radarChart: some View {
        struct RadarPt: Identifiable { let id = UUID(); let label: String; let value: Double }
        let pts: [RadarPt] = [
            .init(label: "Argumente",
                  value: eigenArgs.isEmpty ? 0 :
                    eigenArgs.reduce(0) { $0 + ($1.strength ?? 5) } / Double(eigenArgs.count) * 10),
            .init(label: "Beweise", value: min(100, Double(evidence.count) * 12)),
            .init(label: "Prognose", value: prognose),
            .init(label: "Fristen",
                  value: max(0, 100 - Double(deadlines.filter { $0.status == .versaeumt }.count) * 25)),
            .init(label: "Richter", value: richterRate),
            .init(label: "Gegner-Info", value: min(100, Double(gegnerVerhalten.count) * 15)),
        ]
        return Chart {
            ForEach(pts) { p in
                BarMark(x: .value("Faktor", p.label), y: .value("Wert", p.value))
                    .foregroundStyle(.indigo)
            }
        }
        .chartYScale(domain: 0...100)
    }

    private var filterChips: some View {
        HStack {
            ForEach([("alle","Alle"), ("kritisch","Kritisch"), ("hoch","Hoch"),
                     ("suntzu","Sun Tzu"), ("machiavelli","Machiavelli"), ("ki","KI-Schritte")], id: \.0) { v, l in
                Button(l) { activeFilter = v }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(activeFilter == v ? Color.black : Color.gray.opacity(0.15),
                                in: Capsule())
                    .foregroundStyle(activeFilter == v ? .white : .primary)
            }
        }
    }

    private var checklistView: some View {
        VStack(spacing: 8) {
            if filteredList.isEmpty {
                Text("Keine Einträge für diesen Filter.")
                    .font(.caption).foregroundStyle(.secondary).padding()
            } else {
                ForEach(filteredList) { item in
                    CheckItemRow(
                        item: item,
                        checked: checked.contains(item.id),
                        expanded: expanded.contains(item.id),
                        onToggle: { toggleSet(&checked, item.id) },
                        onExpand: { toggleSet(&expanded, item.id) }
                    )
                }
            }
        }
    }

    private var prinzipienReferenz: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 16) {
                column(title: "Sun Tzu — Die Kunst des Krieges", icon: "shield.lefthalf.filled", items: SUN_TZU)
                column(title: "Machiavelli — Il Principe", icon: "book.closed", items: MACHIAVELLI)
            }
        }
    }
    private func column(title: String, icon: String, items: [Prinzip]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption).bold().foregroundStyle(.secondary)
            ForEach(items) { p in
                HStack(alignment: .top) {
                    Text(p.kategorie).font(.caption2).bold()
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
                    VStack(alignment: .leading) {
                        Text(p.titel).font(.caption).bold()
                        Text(p.zitat).font(.caption2).italic().foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Datenoperationen

    private func toggleSet(_ set: inout Set<String>, _ id: String) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private var filteredList: [ChecklistenItem] {
        switch activeFilter {
        case "alle": return checklist
        case "ki":   return checklist.filter { $0.kiGenerated }
        case "suntzu": return checklist.filter { $0.quelle == "suntzu" }
        case "machiavelli": return checklist.filter { $0.quelle == "machiavelli" }
        default: return checklist.filter { $0.prioritaet == activeFilter }
        }
    }

    private func load() async {
        loading = true
        let pred = NSPredicate(format: "case_id == %@", caseId)
        async let a = cloudKit.fetch(Argument.self, predicate: pred)
        async let e = cloudKit.fetch(Evidence.self, predicate: pred)
        async let d = cloudKit.fetch(Deadline.self, predicate: pred)
        async let p = cloudKit.fetch(Person.self, predicate: pred)
        async let gv = cloudKit.fetch(GegnerVerhalten.self, predicate: pred)
        args = (try? await a) ?? []
        evidence = (try? await e) ?? []
        deadlines = (try? await d) ?? []
        persons = (try? await p) ?? []
        gegnerVerhalten = (try? await gv) ?? []
        generateAlgorithmicChecklist()
        loading = false
    }

    /// Erzeugt die Checkliste rein algorithmisch (ohne KI), basierend auf Falldaten.
    private func generateAlgorithmicChecklist() {
        let eigen = args.filter { $0.side == .eigen }
        let gegner = args.filter { $0.side == .gegner }
        let versaeumt = deadlines.filter { $0.status == .versaeumt }.count
        var items: [ChecklistenItem] = []

        // Stärkstes eigenes Argument
        if let top = eigen.max(by: { ($0.strength ?? 0) < ($1.strength ?? 0) }) {
            items.append(.init(
                id: "st_kenne_dich", quelle: "suntzu", prioritaet: "kritisch",
                titel: "Stärkstes eigenes Argument identifizieren & schärfen",
                zitat: SUN_TZU[0].zitat, kategorie: "Analyse",
                empfehlung: "„\(top.title)" + " (Stärke \(Int(top.strength ?? 5))/10) als Kernargument ausbauen.",
                norm: "§ 138 ZPO – vollständige, wahrheitsgemäße Darlegung",
                lit: "Zöller/Greger, ZPO § 138 Rn. 8 ff.",
                rspr: "BGH NJW 2008, 2047 – Substanziierungspflicht",
                risiko: "Unsubstanziiertes Vorbringen kann nach § 296 ZPO zurückgewiesen werden."
            ))
        }
        // Schwächstes Gegnerargument
        if let weak = gegner.min(by: { ($0.strength ?? 10) < ($1.strength ?? 10) }) {
            items.append(.init(
                id: "st_schwachstelle", quelle: "suntzu", prioritaet: "hoch",
                titel: "Schwächstes Gegenargument angreifen",
                zitat: SUN_TZU[1].zitat, kategorie: "Taktik",
                empfehlung: "„\(weak.title)" + " (\(Int(weak.strength ?? 5))/10) gezielt entkräften.",
                norm: "§ 138 Abs. 2 ZPO – Erklärungspflicht auf Gegenvorbringen",
                lit: "Rosenberg/Schwab/Gottwald § 65 Rn. 12",
                rspr: "BGH NJW 2011, 1965 – Bestreiten mit Nichtwissen",
                risiko: "Unsubstanziiertes Bestreiten = Zugeständnis (§ 138 Abs. 3 ZPO)."
            ))
        }
        if versaeumt > 0 {
            items.append(.init(
                id: "mv_fristen", quelle: "machiavelli", prioritaet: "kritisch",
                titel: "\(versaeumt) versäumte Fristen – Wiedereinsetzung prüfen",
                zitat: MACHIAVELLI[1].zitat, kategorie: "Prozess",
                empfehlung: "Sofort Wiedereinsetzungsantrag nach § 233 ZPO prüfen.",
                norm: "§§ 233–238 ZPO", lit: "Zöller/Greger § 233 Rn. 1 ff.",
                rspr: "BGH NJW 2012, 2048", risiko: "Präklusion (§ 296 ZPO) oder Rechtsverlust."))
        }
        if evidence.count < 3 {
            items.append(.init(
                id: "st_beweis", quelle: "suntzu", prioritaet: "hoch",
                titel: "Beweislage kritisch schwach – Beweise beschaffen",
                zitat: "Der Sieg gehört dem, der am meisten weiß.", kategorie: "Analyse",
                empfehlung: "§ 422 ZPO Urkunden, § 402 ZPO SV, § 373 ZPO Zeugen.",
                norm: "§§ 373, 402, 422 ZPO", lit: "MüKoZPO/Prütting § 286 Rn. 45 ff.",
                rspr: "BGH NJW 2020, 1234", risiko: "Beweisnotstand."))
        }
        if richterRate > 60 {
            items.append(.init(
                id: "st_richter_positiv", quelle: "suntzu", prioritaet: "mittel",
                titel: "Günstige Richterquote ausnutzen", zitat: SUN_TZU[3].zitat,
                kategorie: "Verhandlung",
                empfehlung: "Richter-Klägerquote \(Int(richterRate))% – strukturiert argumentieren.",
                norm: "§ 136 GVG, § 139 ZPO",
                lit: "Prütting/Gehrlein § 139 Rn. 2 ff.",
                rspr: "BVerfG NJW 2003, 281",
                risiko: "Richter kann wechseln – Geschäftsverteilungsplan prüfen."))
        } else if richterRate < 40 {
            items.append(.init(
                id: "mv_richter_kritisch", quelle: "machiavelli", prioritaet: "hoch",
                titel: "Kritische Richterquote – Befangenheit oder Vergleich",
                zitat: MACHIAVELLI[0].zitat, kategorie: "Macht",
                empfehlung: "Richter-Klägerquote nur \(Int(richterRate))% – § 42 ZPO prüfen.",
                norm: "§ 42 ZPO, § 278 ZPO", lit: "Zöller/Vollkommer § 42 Rn. 8 ff.",
                rspr: "BGH NJW 2018, 1412", risiko: "Kostenfolge bei Ablehnung."))
        }
        if prognose < 40 {
            items.append(.init(
                id: "mv_erschoepfung", quelle: "machiavelli", prioritaet: "kritisch",
                titel: "Niedrige Prognose – Vergleich oder Kostenanalyse",
                zitat: MACHIAVELLI[4].zitat, kategorie: "Kosten",
                empfehlung: "Prognose \(Int(prognose))% – Kostenrisiko kalkulieren.",
                norm: "§ 278 ZPO, §§ 91 ff. ZPO", lit: "Musielak/Voit § 91 Rn. 3 ff.",
                rspr: "BGH NJW 2016, 897", risiko: "Volle Kostentragung nach § 91 ZPO."))
        } else if prognose >= 65 {
            items.append(.init(
                id: "mv_angriff", quelle: "machiavelli", prioritaet: "hoch",
                titel: "Starke Prognose – Initiative ergreifen",
                zitat: MACHIAVELLI[1].zitat, kategorie: "Prozess",
                empfehlung: "Prognose \(Int(prognose))% – Verfahren beschleunigen.",
                norm: "§ 704 ZPO, §§ 803 ff. ZPO",
                lit: "Schuschke/Walker, Vollstreckung Rn. 4",
                rspr: "BGH NJW 2019, 2392",
                risiko: "Schadensersatzpflicht aus § 717 ZPO."))
        }
        if gegnerVerhalten.contains(where: { $0.patternTag == .verzoegerungstaktik }) {
            items.append(.init(
                id: "mv_verzoegerung", quelle: "machiavelli", prioritaet: "hoch",
                titel: "Gegner verzögert – prozessuale Gegenmaßnahmen",
                zitat: MACHIAVELLI[4].zitat, kategorie: "Taktik",
                empfehlung: "§ 296 ZPO-Rüge, § 231 ZPO (Säumnisurteil), § 272 ZPO.",
                norm: "§§ 272, 296, 231 ZPO",
                lit: "Prütting/Gehrlein § 272 Rn. 1 ff.",
                rspr: "BGH NJW 2014, 1881",
                risiko: "Eigenes Zuwarten = Einwilligung in Verzögerung."))
        }
        if persons.contains(where: { $0.role == .zeuge }) {
            items.append(.init(
                id: "st_zeuge", quelle: "suntzu", prioritaet: "mittel",
                titel: "Zeugen strategisch einsetzen & vorbereiten",
                zitat: SUN_TZU[2].zitat, kategorie: "Prozess",
                empfehlung: "Kernaussagen schärfen, Widersprüche herausarbeiten (§ 396 ZPO).",
                norm: "§§ 373–401 ZPO, § 396 ZPO",
                lit: "Stein/Jonas/Berger § 373 Rn. 6 ff.",
                rspr: "BGH NJW 2017, 2050",
                risiko: "Unvorbereitete Zeugen schaden."))
        }
        if eigen.contains(where: { ($0.kiStrength ?? 0) > ($0.strength ?? 0) + 3 }) {
            items.append(.init(
                id: "st_ki_diskrepanz", quelle: "suntzu", prioritaet: "mittel",
                titel: "KI bewertet eigene Argumente stärker", zitat: SUN_TZU[5].zitat,
                kategorie: "Adaptiv",
                empfehlung: "Möglicherweise unterschätzte Argumente weiter ausbauen.",
                norm: "§ 138 ZPO", lit: "Prütting/Gehrlein § 138 Rn. 3 ff.", rspr: nil, risiko: nil))
        }
        if items.count < 3 {
            items.append(.init(
                id: "mv_koalition", quelle: "machiavelli", prioritaet: "mittel",
                titel: "Streitverkündung oder Nebenintervention prüfen",
                zitat: MACHIAVELLI[2].zitat, kategorie: "Netzwerk",
                empfehlung: "§ 72 ZPO an mögliche Regress-Schuldner.",
                norm: "§ 72 ZPO, § 64 ZPO",
                lit: "Zöller/Vollkommer § 72 Rn. 4 ff.",
                rspr: "BGH NJW 2007, 1534", risiko: nil))
        }
        checklist = items
    }

    /// Ergänzt die Checkliste durch KI-generierte Schritte (Sun-Tzu/Machiavelli-Stil).
    private func runKIChecklist() async {
        kiLoading = true; defer { kiLoading = false }
        let prompt = """
        Du bist Senior-Prozessanwalt. Analysiere diesen Fall und erstelle 4 strategische
        Handlungsschritte basierend auf Sun Tzu UND Machiavelli mit ZPO/BGB-Normen, BGH-Rspr., Lit.

        Fall: \(caseData?.fallname ?? "") | Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Prognose: \(Int(prognose))% | Eigene: \(eigenArgs.count) | Gegner: \(gegnerArgs.count)
        Beweise: \(evidence.count) | Versäumte Fristen: \(deadlines.filter { $0.status == .versaeumt }.count)
        Richterquote: \(Int(richterRate))%
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "schritte": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "titel":      ["type": "string"],
                            "prinzip":    ["type": "string"],
                            "quelle":     ["type": "string", "enum": ["suntzu", "machiavelli"]],
                            "kategorie":  ["type": "string"],
                            "empfehlung": ["type": "string"],
                            "norm":       ["type": "string"],
                            "lit":        ["type": "string"],
                            "rspr":       ["type": "string"],
                            "prioritaet": ["type": "string", "enum": ["kritisch", "hoch", "mittel"]],
                            "risiko":     ["type": "string"]
                        ]
                    ]
                ]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res,
              let dict = any as? [String: Any],
              let arr  = dict["schritte"] as? [[String: Any]] else { return }
        for (i, s) in arr.enumerated() {
            let item = ChecklistenItem(
                id: "ki_\(i)",
                quelle: s["quelle"] as? String ?? "suntzu",
                prioritaet: s["prioritaet"] as? String ?? "mittel",
                titel: s["titel"] as? String ?? "Unbenannt",
                zitat: s["prinzip"] as? String ?? "",
                kategorie: s["kategorie"] as? String ?? "Strategie",
                empfehlung: s["empfehlung"] as? String,
                norm: s["norm"] as? String,
                lit: s["lit"] as? String,
                rspr: s["rspr"] as? String,
                risiko: s["risiko"] as? String,
                kiGenerated: true
            )
            checklist.append(item)
        }
    }
}

// MARK: - Check-Item-Zeile
fileprivate struct CheckItemRow: View {
    let item: ChecklistenItem
    let checked: Bool
    let expanded: Bool
    var onToggle: () -> Void
    var onExpand: () -> Void

    private var prioColor: Color {
        switch item.prioritaet {
        case "kritisch": return .red
        case "hoch":     return .orange
        default:         return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Button { onToggle() } label: {
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(checked ? .green : .gray)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.quelle == "suntzu" ? "shield" : "book")
                            .foregroundStyle(.secondary)
                        Text(item.titel)
                            .font(.subheadline).bold()
                            .strikethrough(checked)
                            .foregroundStyle(checked ? .secondary : .primary)
                        Text(item.kategorie).font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.gray.opacity(0.15), in: Capsule())
                        Text(item.prioritaet).font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(prioColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(prioColor)
                        if item.kiGenerated {
                            Text("KI").font(.caption2).bold()
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color.purple.opacity(0.15), in: Capsule())
                                .foregroundStyle(.purple)
                        }
                    }
                    Text(item.zitat).font(.caption2).italic().foregroundStyle(.secondary)
                    if let e = item.empfehlung { Text("→ \(e)").font(.caption) }
                }
                Spacer()
                Button { onExpand() } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let n = item.norm   { row("Rechtsgrundlage", n, .indigo) }
                    if let l = item.lit    { row("Literatur", l, .gray) }
                    if let r = item.rspr   { row("Rspr.", r, .gray) }
                    if let r = item.risiko {
                        Label(r, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }
                .padding([.horizontal, .bottom])
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(checked ? Color.gray.opacity(0.05) : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption2).bold().foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value).font(.caption).foregroundStyle(color)
        }
    }
}
