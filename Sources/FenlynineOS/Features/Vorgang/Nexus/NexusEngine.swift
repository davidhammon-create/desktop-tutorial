import Foundation
enum NexusHebelArt: String, CaseIterable, Identifiable, Hashable {
    case belegNachziehen
    case flankeSchliessen
    case konterLegen
    case fristKlaeren
    case durchsetzbarkeit
    case stellungHalten
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .belegNachziehen: return "Beleg nachziehen"
        case .flankeSchliessen: return "Flanke schließen"
        case .konterLegen: return "Konter legen"
        case .fristKlaeren: return "Frist klären"
        case .durchsetzbarkeit: return "Durchsetzbarkeit"
        case .stellungHalten: return "Stellung halten"
        }
    }
}
struct NexusZug: Identifiable, Hashable {
    var id: UUID = UUID()
    var hebel: NexusHebelArt
    var titel: String
    var begruendung: String
    var pVorher: Double
    var pNachher: Double
    var delta: Double
    var knotenId: UUID? = nil
    var satz: String { begruendung }
    var deltaPText: String {
        let pkt = Int((delta * 100).rounded())
        if pkt == 0 { return "±0" }
        return pkt > 0 ? "+\(pkt) Punkte" : "\(pkt) Punkte"
    }
}
struct NexusMerkmalStand: Identifiable, Hashable {
    var id: UUID
    var kern: String
    var p: Double
    var flanke: Bool
}
struct NexusRechenschritt: Identifiable, Hashable {
    var id: String { titel + wert }
    var titel: String
    var wert: String
    var detail: String
}
struct NexusHerleitungZeile: Identifiable, Hashable {
    var id: UUID
    var ebene: NexusKnotenTyp
    var kuerzel: String
    var sNetto: Double
    var zeile: String
    var kern: String
}
struct NexusSuchbericht: Hashable {
    var bewerteteStellungen: Int
    var tiefe: Int
    var kern: NexusRechenkern
    var dauerMs: Int
}
struct NexusMaterial: Hashable {
    var eigene: Int
    var gegner: Int
    var belege: Int
    var klauseln: Int
    var flanken: Int
    var blaetterGesamt: Int
    var belegteBlaetter: Int
}
struct NexusStellung: Hashable {
    var graph: NexusGraph
    var pErfolg: Double
    var band: String
    var intern: String
    var beta: Double
    var betaKalibriert: Bool
    var belegtheit: Double
    var pZulaessig: Double
    var pNichtVerjaehrt: Double
    var pDurchsetzbar: Double
    var merkmale: [NexusMerkmalStand]
    var aggregation: String
    var schritte: [NexusRechenschritt]
    var herleitung: [NexusHerleitungZeile]
    var zuege: [NexusZug]
    var material: NexusMaterial
    var suche: NexusSuchbericht
    var kern: NexusRechenkern
    var hinweis: String
    var pBand: String { band }
    var aggregationsZeile: String { aggregation }
    var betaHinweis: String {
        "β = \(String(format: "%.1f", beta).replacingOccurrences(of: ".", with: ",")) — \(betaKalibriert ? "kalibriert" : "nicht kalibriert")"
    }
    var belegteBlaetter: Int { material.belegteBlaetter }
    var blaetterGesamt: Int { material.blaetterGesamt }
}
enum NexusRechenkern: String, CaseIterable, Identifiable {
    case klassisch, cluster, quanten
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .klassisch: return "Klassisch"
        case .cluster: return "Cluster"
        case .quanten: return "Quanten"
        }
    }
    var satz: String {
        switch self {
        case .klassisch:
            return "Deterministisch im Client. Gleiche Eingabe → gleiche Ausgabe. Offline."
        case .cluster:
            return "Reserviert: parallele Varianten-Suche über viele Stellungen. Noch nicht angeschlossen."
        case .quanten:
            return "Schnittstelle vorbereitet. Sucht denselben Zugraum — nicht eine andere Wahrheit. Hardware nicht aktiv."
        }
    }
    var bereit: Bool { self == .klassisch }
}
enum NexusEngine {
    static func stellung(vorgangId: UUID, graph: NexusGraph, kern: NexusRechenkern = .klassisch) -> NexusStellung {
        _ = vorgangId
        return bewerte(mit: kern, graph: graph)
    }
    static func stellung(_ g: NexusGraph, ziel: Double = 0.65, kern: NexusRechenkern = .klassisch) -> NexusStellung {
        _ = ziel
        return bewerte(mit: kern, graph: g)
    }
    static func bewerte(mit kern: NexusRechenkern, graph: NexusGraph, ziel: Double = 0.65) -> NexusStellung {
        let t0 = Date()
        var g = graph
        NexusPropagation.auswerten(&g)
        let suche = sucheZuege(g, ziel: ziel, kern: kern)
        let dauer = Int(Date().timeIntervalSince(t0) * 1000)
        let mat = material(g)
        return NexusStellung(
            graph: g,
            pErfolg: g.pErfolg,
            band: NexusAnzeige.band(g.pErfolg),
            intern: NexusAnzeige.punkt(g.pErfolg),
            beta: g.beta,
            betaKalibriert: g.betaKalibriert,
            belegtheit: g.belegtheit,
            pZulaessig: g.pZulaessig,
            pNichtVerjaehrt: g.pNichtVerjaehrt,
            pDurchsetzbar: g.pDurchsetzbar,
            merkmale: merkmaleStand(g),
            aggregation: g.aggregationZeile(),
            schritte: herleitungSchritte(g),
            herleitung: herleitungZeilen(g),
            zuege: suche.zuege,
            material: mat,
            suche: NexusSuchbericht(
                bewerteteStellungen: suche.bewertet,
                tiefe: suche.tiefe,
                kern: kern.bereit ? kern : .klassisch,
                dauerMs: max(1, dauer)
            ),
            kern: kern.bereit ? kern : .klassisch,
            hinweis: "NEXUS gibt Wahrscheinlichkeiten aus, keine Handlungsempfehlung. β ist \(g.betaKalibriert ? "kalibriert" : "nicht kalibriert") — Konsistenz, keine Präzision."
        )
    }
    static func konterKarten(in graph: NexusGraph) -> [NexusKonterKarte] {
        NexusPropagation.konterBibliothek(graph: graph)
    }
    static func treffer(stichwort: String, in graph: NexusGraph) -> NexusKonterKarte? {
        treffer(stichwort: stichwort, bibliothek: konterKarten(in: graph))
    }
    static func treffer(stichwort: String, bibliothek: [NexusKonterKarte]) -> NexusKonterKarte? {
        let q = stichwort.lowercased().split { $0.isWhitespace || $0.isNewline }.map(String.init)
        guard !q.isEmpty else { return nil }
        func score(_ k: NexusKonterKarte) -> Int {
            let hay = (k.gegnerKern + " " + k.hauptKern + " " + (k.fundstelle ?? "")).lowercased()
            return q.filter { hay.contains($0) }.count
        }
        guard let best = bibliothek.max(by: { score($0) < score($1) }), score(best) > 0 else { return nil }
        return best
    }
    static func material(_ g: NexusGraph) -> NexusMaterial {
        let blaetter = g.knoten.filter { $0.typ != .norm && g.kinder(von: $0.id).isEmpty }
        let belegt = blaetter.filter { $0.status == .belegt && $0.qRang != .unbelegt }
        return NexusMaterial(
            eigene: g.knoten.filter { $0.typ == .argEigen && $0.status != .verworfen }.count,
            gegner: g.knoten.filter { $0.typ == .argGegner && $0.status != .verworfen }.count,
            belege: g.knoten.filter { $0.typ == .beleg }.count,
            klauseln: g.knoten.filter { $0.typ == .klausel }.count,
            flanken: g.offeneFlanken.count,
            blaetterGesamt: blaetter.count,
            belegteBlaetter: belegt.count
        )
    }
    static func merkmaleStand(_ g: NexusGraph) -> [NexusMerkmalStand] {
        g.merkmale().map { m in
            NexusMerkmalStand(
                id: m.id,
                kern: m.kern,
                p: m.pMerkmal ?? 0.5,
                flanke: g.offeneFlanken.contains(where: { $0.id == m.id })
            )
        }
    }
    static func herleitung(_ g: NexusGraph) -> [NexusRechenschritt] {
        herleitungSchritte(g)
    }
    static func herleitungSchritte(_ g: NexusGraph) -> [NexusRechenschritt] {
        var s: [NexusRechenschritt] = [
            .init(titel: "β", wert: String(format: "%.1f", g.beta).replacingOccurrences(of: ".", with: ","), detail: g.betaKalibriert ? "kalibriert" : "nicht kalibriert — Startwert Kap. 09"),
            .init(titel: "Belegtheit", wert: "\(Int((g.belegtheit * 100).rounded())) %", detail: "Anteil belegter Knoten"),
            .init(titel: "Filter zulässig", wert: NexusAnzeige.faktor(g.pZulaessig), detail: "prozessual, multiplikativ"),
            .init(titel: "Filter nicht verjährt", wert: NexusAnzeige.faktor(g.pNichtVerjaehrt), detail: "aus Fristen / Schritt 8"),
            .init(titel: "Filter durchsetzbar", wert: NexusAnzeige.faktor(g.pDurchsetzbar), detail: "Bonität Gegner")
        ]
        for w in g.wuerzel() {
            s.append(.init(titel: "Anspruch", wert: NexusAnzeige.punkt(g.pAnsprueche[w.id] ?? 0), detail: w.kern))
            for m in g.kinder(von: w.id).filter({ $0.typ == .merkmal }) {
                s.append(.init(
                    titel: "P(m) \(m.kern)",
                    wert: NexusAnzeige.punkt(m.pMerkmal ?? 0),
                    detail: "Sroh \(NexusAnzeige.netto(m.sRoh)) → Snetto \(NexusAnzeige.netto(m.sNetto))"
                ))
            }
        }
        s.append(.init(titel: "Aggregation", wert: NexusAnzeige.punkt(g.pErfolg), detail: g.aggregationZeile()))
        s.append(.init(titel: "Anzeige", wert: NexusAnzeige.band(g.pErfolg), detail: "Band. Nachkommastelle nur hier in der Herleitung."))
        return s
    }
    static func herleitungZeilen(_ g: NexusGraph) -> [NexusHerleitungZeile] {
        g.knoten
            .sorted { a, b in
                if a.typ.ebene != b.typ.ebene { return a.typ.ebene < b.typ.ebene }
                return a.sNetto > b.sNetto
            }
            .map { k in
                var zeile = "Sroh \(NexusAnzeige.netto(k.sRoh)) → Snetto \(NexusAnzeige.netto(k.sNetto))"
                if let p = k.pMerkmal {
                    zeile += " · P(m) \(NexusAnzeige.punkt(p))"
                }
                zeile += " · Q \(k.qRang.titel) · N \(k.nachweis.titel)"
                return NexusHerleitungZeile(
                    id: k.id,
                    ebene: k.typ,
                    kuerzel: k.typ.kuerzel,
                    sNetto: k.sNetto,
                    zeile: zeile,
                    kern: k.kern
                )
            }
    }
    static func zuege(_ g: NexusGraph, ziel: Double = 0.65) -> [NexusZug] {
        sucheZuege(g, ziel: ziel, kern: .klassisch).zuege
    }
    private static func sucheZuege(_ g: NexusGraph, ziel: Double, kern: NexusRechenkern) -> (zuege: [NexusZug], bewertet: Int, tiefe: Int) {
        _ = kern
        let aktuell = g.pErfolg
        var bewertet = 1
        var z: [NexusZug] = []
        if aktuell >= ziel && g.offeneFlanken.isEmpty {
            z.append(NexusZug(
                hebel: .stellungHalten,
                titel: "Stellung im Zielband",
                begruendung: "P(Erfolg) liegt bei \(NexusAnzeige.band(aktuell)). Kein Zwangszug. Halten und dokumentieren.",
                pVorher: aktuell,
                pNachher: aktuell,
                delta: 0
            ))
            return (z, bewertet, 1)
        }
        for m in g.merkmale() {
            let p0 = m.pMerkmal ?? 0.5
            guard p0 < 0.90 else { continue }
            let neu = simuliereBeleg(g, unter: m.id)
            bewertet += 1
            let d = neu - aktuell
            if d > 0.004 {
                let flanke = g.offeneFlanken.contains(where: { $0.id == m.id })
                z.append(NexusZug(
                    hebel: flanke ? .flankeSchliessen : .belegNachziehen,
                    titel: flanke ? "Flanke schließen: \(m.kern)" : "Zug: \(m.kern) stärken",
                    begruendung: flanke
                        ? "Merkmal ohne Beleg. Ein tragfähiger Nachweis hebt P(m) und damit die Konjunktion."
                        : "Stärkster Hebel an diesem Merkmal: Q×P×N nachziehen. ΔP kommt aus der Auswertung, nicht aus der KI.",
                    pVorher: aktuell,
                    pNachher: neu,
                    delta: d,
                    knotenId: m.id
                ))
            }
        }
        let angriffe = g.knoten.filter { $0.typ == .argGegner && $0.status != .verworfen }
        for ang in angriffe {
            let hatKonter = !g.kinder(von: ang.id).filter { $0.typ == .argEigen && $0.status != .verworfen }.isEmpty
            if hatKonter { continue }
            let neu = simuliereKonter(g, gegen: ang.id)
            bewertet += 1
            let d = neu - aktuell
            if d > 0.004 {
                z.append(NexusZug(
                    hebel: .konterLegen,
                    titel: "Konter gegen: \(ang.kern)",
                    begruendung: "Ungedeckter Angriff. Ein Konter mit schließt_aus (w=1,00) oder greift_an (w=0,60) ändert Snetto des Merkmals.",
                    pVorher: aktuell,
                    pNachher: neu,
                    delta: d,
                    knotenId: ang.id
                ))
            }
        }
        if g.pNichtVerjaehrt < 0.95 {
            var copy = g
            copy.pNichtVerjaehrt = 1
            NexusPropagation.auswerten(&copy)
            bewertet += 1
            let d = copy.pErfolg - aktuell
            if d > 0.004 {
                z.append(NexusZug(
                    hebel: .fristKlaeren,
                    titel: "Verjährung / Frist klären",
                    begruendung: "Filter «nicht verjährt» liegt bei \(NexusAnzeige.faktor(g.pNichtVerjaehrt)). Der Filter ist multiplikativ — jede Unsicherheit frisst die ganze Stellung.",
                    pVorher: aktuell,
                    pNachher: copy.pErfolg,
                    delta: d
                ))
            }
        }
        if g.pDurchsetzbar < 0.90 {
            var copy = g
            copy.pDurchsetzbar = min(1, g.pDurchsetzbar + 0.15)
            NexusPropagation.auswerten(&copy)
            bewertet += 1
            let d = copy.pErfolg - aktuell
            if d > 0.004 {
                z.append(NexusZug(
                    hebel: .durchsetzbarkeit,
                    titel: "Durchsetzbarkeit sichern",
                    begruendung: "Ein gewonnener Titel, der nicht beigetrieben wird, ist eine verlorene Stellung. Filter liegt bei \(NexusAnzeige.faktor(g.pDurchsetzbar)).",
                    pVorher: aktuell,
                    pNachher: copy.pErfolg,
                    delta: d
                ))
            }
        }
        let sortiert = Array(z.sorted { $0.delta > $1.delta }.prefix(7))
        return (sortiert, bewertet, 1)
    }
    static func simuliereBeleg(_ g: NexusGraph, unter parentId: UUID) -> Double {
        var copy = g
        let k = NexusKnoten(
            parentId: parentId,
            typ: .beleg,
            kern: "Hypothetischer Beleg — Simulation",
            qRang: .gesetz,
            passgenauigkeit: 1,
            nachweis: .urkundeUnstreitig,
            status: .belegt
        )
        copy.knoten.append(k)
        copy.kanten.append(.init(von: k.id, nach: parentId, typ: .stuetzt))
        NexusPropagation.auswerten(&copy)
        return copy.pErfolg
    }
    static func simuliereKonter(_ g: NexusGraph, gegen angId: UUID) -> Double {
        var copy = g
        let k = NexusKnoten(
            parentId: angId,
            typ: .argEigen,
            kern: "Hypothetischer Konter — Simulation",
            qRang: .gesetz,
            passgenauigkeit: 0.90,
            nachweis: .urkundeUnstreitig,
            status: .belegt
        )
        copy.knoten.append(k)
        copy.kanten.append(.init(von: k.id, nach: angId, typ: .schliesstAus))
        NexusPropagation.auswerten(&copy)
        return copy.pErfolg
    }
}
