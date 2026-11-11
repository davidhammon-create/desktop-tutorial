import Foundation
enum NexusPropagation {
    static let betaStart = 1.7
    static func auswerten(_ graph: inout NexusGraph) {
        var cache: [UUID: Double] = [:]
        var visited: Set<UUID> = []
        for i in graph.knoten.indices {
            graph.knoten[i].sNetto = netto(graph.knoten[i].id, graph: graph, cache: &cache, visited: &visited)
            graph.knoten[i].sRoh = roh(graph.knoten[i].id, graph: graph)
        }
        var pAnspruch: [UUID: Double] = [:]
        for wurzel in graph.wuerzel() {
            let merkmale = graph.kinder(von: wurzel.id).filter { $0.typ == .merkmal }
            var produkt = 1.0
            for m in merkmale {
                let p = pMerkmal(m, graph: graph)
                if let idx = graph.knoten.firstIndex(where: { $0.id == m.id }) {
                    graph.knoten[idx].pMerkmal = p
                }
                produkt *= p
            }
            if merkmale.isEmpty { produkt = 0.5 }
            pAnspruch[wurzel.id] = produkt
        }
        graph.pAnsprueche = pAnspruch
        let disj: Double
        if pAnspruch.isEmpty {
            disj = 0.5
        } else {
            disj = 1 - pAnspruch.values.reduce(1.0) { $0 * (1 - $1) }
        }
        let raw = disj * graph.pZulaessig * graph.pNichtVerjaehrt * graph.pDurchsetzbar
        graph.pErfolg = min(0.98, max(0.02, raw))
        graph.geaendert = Date()
    }
    static func pMerkmal(_ m: NexusKnoten, graph: NexusGraph) -> Double {
        let angriffe = graph.kanten.filter { $0.nach == m.id && ($0.typ == .greiftAn || $0.typ == .schliesstAus) }
        if angriffe.isEmpty {
            let evid = max(m.sRoh, nachweisEffektiv(m))
            return min(0.98, max(0.02, evid > 0 ? evid : 0.50))
        }
        let rest = angriffe.compactMap { graph.knoten($0.von)?.sNetto }.max() ?? 0
        return min(0.98, max(0.02, 1 - graph.beta * rest))
    }
    static func nachweisEffektiv(_ k: NexusKnoten) -> Double {
        var n = k.nachweis.n
        if k.vermutung || k.beweislast == .schuldner {
            n = 1 - (1 - n) * 0.4
        }
        if k.status == .kiVorschlag || k.qRang == .unbelegt {
            n = min(n, 0.10)
        }
        return n
    }
    static func roh(_ id: UUID, graph: NexusGraph) -> Double {
        guard let k = graph.knoten(id) else { return 0 }
        let stuetzen = graph.kanten.filter { $0.nach == id && $0.typ == .stuetzt }
        if stuetzen.isEmpty {
            var s = k.qRang.q * k.passgenauigkeit * nachweisEffektiv(k)
            if k.status == .kiVorschlag { s = min(s, 0.10) }
            return min(1, max(0, s))
        }
        var produkt = 1.0
        for s in stuetzen {
            guard let v = graph.knoten(s.von) else { continue }
            let beitrag = v.qRang.q * v.passgenauigkeit * nachweisEffektiv(v)
            produkt *= (1 - min(1, max(0, beitrag)))
        }
        return min(1, max(0, 1 - produkt))
    }
    static func netto(_ id: UUID, graph: NexusGraph, cache: inout [UUID: Double], visited: inout Set<UUID>) -> Double {
        if let c = cache[id] { return c }
        guard !visited.contains(id) else { return cache[id] ?? 0 }
        visited.insert(id)
        var s = roh(id, graph: graph)
        let voraus = graph.kanten.filter { $0.nach == id && $0.typ == .setztVoraus }
        for v in voraus {
            if netto(v.von, graph: graph, cache: &cache, visited: &visited) < 0.15 {
                s = 0
            }
        }
        let angriffe = graph.kanten.filter { $0.nach == id && ($0.typ == .greiftAn || $0.typ == .schliesstAus || $0.typ == .entkraeftet) }
        for a in angriffe {
            let sa = netto(a.von, graph: graph, cache: &cache, visited: &visited)
            s *= (1 - a.w * sa)
        }
        s = min(1, max(0, s))
        cache[id] = s
        return s
    }
    static func wuerdeZyklusBilden(von: UUID, nach: UUID, graph: NexusGraph) -> Bool {
        if von == nach { return true }
        var gesehen: Set<UUID> = [nach]
        var stack = [nach]
        while let k = stack.popLast() {
            for e in graph.kanten where e.von == k {
                if e.nach == von { return true }
                if gesehen.insert(e.nach).inserted { stack.append(e.nach) }
            }
        }
        return false
    }
    static func hebel(graph: NexusGraph, ziel: Double = 0.65) -> [String] {
        let merkmale = graph.knoten.filter { $0.typ == .merkmal }
        let aktuell = graph.pErfolg
        guard aktuell < ziel else {
            return ["P(Erfolg) liegt bereits im Zielband \(NexusAnzeige.band(ziel))."]
        }
        var vorschlaege: [(delta: Double, text: String)] = []
        for m in merkmale {
            let p0 = m.pMerkmal ?? 0.5
            guard p0 < 0.92 else { continue }
            let p1 = min(0.92, p0 + 0.15)
            var produkt = 1.0
            for n in merkmale {
                produkt *= (n.id == m.id ? p1 : (n.pMerkmal ?? 0.5))
            }
            let neu = min(0.98, produkt * graph.pZulaessig * graph.pNichtVerjaehrt * graph.pDurchsetzbar)
            let d = neu - aktuell
            if d > 0.005 {
                vorschlaege.append((d, "„\(m.kern)“ von \(NexusAnzeige.punkt(p0)) auf \(NexusAnzeige.punkt(p1)): +\(Int((d * 100).rounded())) Punkte"))
            }
        }
        return Array(vorschlaege.sorted { $0.delta > $1.delta }.prefix(3).map(\.text))
    }
    static func konterBibliothek(graph: NexusGraph) -> [NexusKonterKarte] {
        let angriffe = graph.knoten.filter { $0.typ == .argGegner && $0.status != .verworfen }
            .sorted { $0.sNetto > $1.sNetto }
        return angriffe.prefix(40).compactMap { ang in
            let konter = graph.kanten.filter { $0.nach == ang.id && ($0.typ == .schliesstAus || $0.typ == .greiftAn || $0.typ == .stuetzt) }
                .compactMap { graph.knoten($0.von) }
                .sorted { $0.sNetto > $1.sNetto }
            guard let haupt = konter.first else { return nil }
            let kante = graph.kanten.first { $0.von == haupt.id && $0.nach == ang.id }
            return NexusKonterKarte(
                gegnerKern: ang.kern,
                gegnerNetto: ang.sNetto,
                hauptKern: haupt.kern,
                hauptNetto: haupt.sNetto,
                hauptTyp: kante?.typ ?? .greiftAn,
                fundstelle: haupt.fundstelle?.zitat,
                alternative: konter.dropFirst().prefix(2).map { NexusKonterAlternative(kern: $0.kern, netto: $0.sNetto) },
                selbstAngegriffen: graph.kanten.contains { $0.nach == haupt.id && ($0.typ == .greiftAn || $0.typ == .schliesstAus) }
            )
        }
    }
}
struct NexusKonterKarte: Identifiable, Hashable {
    var id: String { gegnerKern + "·" + hauptKern }
    let gegnerKern: String
    let gegnerNetto: Double
    let hauptKern: String
    let hauptNetto: Double
    let hauptTyp: NexusKantenTyp
    let fundstelle: String?
    let alternative: [NexusKonterAlternative]
    let selbstAngegriffen: Bool
}
struct NexusKonterAlternative: Hashable {
    let kern: String
    let netto: Double
}
