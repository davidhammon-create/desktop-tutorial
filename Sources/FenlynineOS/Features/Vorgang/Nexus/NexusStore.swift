import Foundation
@Observable
final class NexusStore {
    static let shared = NexusStore()
    private let key = "fenlynineos_nexus_v1"
    private(set) var graphen: [UUID: NexusGraph] = [:] // optionId
    private init() { laden() }
    func graph(optionId: UUID) -> NexusGraph? { graphen[optionId] }
    func graphFuerVorgang(_ vorgangId: UUID) -> NexusGraph? {
        graphen.values.filter { $0.vorgangId == vorgangId }.max { $0.geaendert < $1.geaendert }
    }
    func graph(vorgangId: UUID, optionId: UUID) -> NexusGraph? {
        graphen[optionId] ?? graphFuerVorgang(vorgangId)
    }
    @discardableResult
    func legeSkelettAn(vorgangId: UUID, optionId: UUID, vorlage: NexusAnspruchVorlage, store: VorgangStore? = nil) -> NexusGraph {
        let g = NexusRegelwerk.skelett(vorlage: vorlage, optionId: optionId, vorgangId: vorgangId)
        if let store {
            setzeUndLiefere(g, in: store)
        } else {
            setze(g)
        }
        return graphen[optionId] ?? g
    }
    func loescheGraph(optionId: UUID) {
        graphen.removeValue(forKey: optionId)
        speichern()
    }
    func setze(_ g: NexusGraph) {
        var copy = g
        NexusPropagation.auswerten(&copy)
        graphen[copy.optionId] = copy
        speichern()
    }
    func setzeUndLiefere(_ g: NexusGraph, in store: VorgangStore) {
        setze(g)
        uebernehmeP(in: store, vorgangId: g.vorgangId, optionId: g.optionId)
    }
    func fuegeKnotenHinzu(_ optionId: UUID, _ knoten: NexusKnoten) -> String? {
        guard var g = graphen[optionId] else { return "Kein Graph." }
        if let p = knoten.parentId, g.tiefe(von: p) >= 7 {
            return "Ebene 8 ist die harte Tiefengrenze (Kap. 19). Der Knoten wird nicht angelegt."
        }
        let geschwister = g.knoten.filter { $0.parentId == knoten.parentId }.count
        if geschwister >= 40 {
            return "Zu viele Geschwisterknoten. Die Darstellung bleibt bei sieben sichtbaren; legen Sie nur an, was Sie brauchen."
        }
        var k = knoten
        k.setzeKern(k.kern)
        g.knoten.append(k)
        if let p = k.parentId {
            let typ: NexusKantenTyp = (k.typ == .argGegner) ? .greiftAn : .stuetzt
            if NexusPropagation.wuerdeZyklusBilden(von: k.id, nach: p, graph: g) {
                return "Diese Kante wäre ein Zirkelschluss. Die Oberfläche verweigert sie — Zirkelargumente sind juristisch möglich, mathematisch nicht auswertbar."
            }
            g.kanten.append(.init(von: k.id, nach: p, typ: typ))
        }
        setze(g)
        return nil
    }
    func fuegeKanteHinzu(_ optionId: UUID, von: UUID, nach: UUID, typ: NexusKantenTyp) -> String? {
        guard var g = graphen[optionId] else { return "Kein Graph." }
        if NexusPropagation.wuerdeZyklusBilden(von: von, nach: nach, graph: g) {
            return "Diese Kante wäre ein Zirkelschluss. Die Oberfläche verweigert sie — Zirkelargumente sind juristisch möglich, mathematisch nicht auswertbar."
        }
        g.kanten.append(.init(von: von, nach: nach, typ: typ))
        setze(g)
        return nil
    }
    func aktualisiereKnoten(_ optionId: UUID, _ knoten: NexusKnoten) {
        guard var g = graphen[optionId] else { return }
        var k = knoten
        k.setzeKern(k.kern)
        if let i = g.knoten.firstIndex(where: { $0.id == k.id }) {
            g.knoten[i] = k
            setze(g)
        }
    }
    func uebernehmeP(in store: VorgangStore, vorgangId: UUID, optionId: UUID) {
        guard let g = graphen[optionId] else { return }
        store.mutate(vorgangId) { v in
            guard let i = v.optionen.firstIndex(where: { $0.id == optionId }) else { return }
            if v.optionen[i].pIstManuell { return }
            let herleitung = NexusDemo.herleitung(g)
            v.optionen[i].chancen.pErfolg = .formel(g.pErfolg, herleitung)
            v.optionen[i].chancen.likely = .formel(
                v.optionen[i].chancen.best.wert * g.pErfolg + v.optionen[i].chancen.worst.wert * (1 - g.pErfolg),
                "P × best + (1−P) × worst"
            )
            v.optionen[i].risiken.removeAll { $0.titel.hasPrefix("Offene Flanke:") }
            for flanke in g.offeneFlanken {
                v.optionen[i].risiken.append(.init(
                    titel: "Offene Flanke: \(flanke.kern)",
                    eintrittWahrscheinlichkeit: 8,
                    auswirkung: 8,
                    entdeckung: 5
                ))
            }
            for k in g.knoten where k.typ == .klausel && k.status != .kiVorschlag {
                if let f = k.fundstelle, !v.fristen.contains(where: { $0.quelle.contains(f.zitat) }) {
                    let kern = k.kern.lowercased()
                    if kern.contains("frist") || kern.contains("kündig") || kern.contains("verjähr") || kern.contains("nachfrist") {
                        v.fristen.append(VorgangFrist(
                            datum: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
                            art: k.kern,
                            kritisch: false,
                            quelle: "NEXUS Klausel \(f.zitat)",
                            typ: .frist
                        ))
                    }
                }
            }
            v.ereignisse.append(.init(was: "nexus_p_uebernommen", wer: "NEXUS", alt: nil, neu: NexusAnzeige.band(g.pErfolg)))
        }
        store.bewerteAlleOptionen(vorgangId)
    }
    private func speichern() {
        if let data = try? JSONEncoder().encode(graphen) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func laden() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let g = try? JSONDecoder().decode([UUID: NexusGraph].self, from: data) else { return }
        graphen = g
    }
}
