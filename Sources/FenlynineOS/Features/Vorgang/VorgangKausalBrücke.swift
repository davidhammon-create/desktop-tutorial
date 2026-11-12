import Foundation
enum VorgangKausalBrucke {
    @MainActor
    static func spiegleAlsEreignis(_ v: Vorgang, in store: FenlynineOSKernStore) {
        let ereignisId = "vorgang.\(v.kurzId)"
        if store.knoten.contains(where: { $0.id == ereignisId }) { return }
        var neueKnoten: [FenlynineOSKernKnoten] = []
        var neueKanten: [FenlynineOSKernKante] = []
        var ereignis = FenlynineOSKernKnoten.basis(id: ereignisId, titel: v.titel)
        ereignis.typ = .ereignis
        ereignis.beschreibung = "[\(v.kurzId)] \(v.titel) — Typ: \(v.typ.bezeichnung), Zustand: \(v.zustand.bezeichnung)"
        ereignis.modul = brueckeModul(fuer: v.typ)
        ereignis.modulAktion = "Vorgang aus VorgangStore"
        ereignis.herkunft = "vorgang-store"
        ereignis.status = .aktiv
        neueKnoten.append(ereignis)
        for option in v.optionen.filter({ !$0.istVorgeschichte }) {
            let optionId = "vorgang.\(v.kurzId).option.\(option.id.uuidString.prefix(8))"
            var optK = FenlynineOSKernKnoten.basis(id: optionId, titel: option.label)
            optK.typ = .option
            optK.beschreibung = option.beschreibung
            optK.modul = brueckeModul(fuer: v.typ)
            optK.modulAktion = "Option des Vorgangs"
            optK.herkunft = "vorgang-option"
            optK.pErfolg = option.chancen.pErfolg.wert
            optK.gewinn = option.chancen.best.wert
            optK.verlust = option.chancen.worst.wert
            optK.kosten = option.kosten.summe
            optK.ev = option.bewertung.ev?.wert
            optK.rav = option.bewertung.rav?.wert
            optK.rpn = option.bewertung.rpnGesamt > 0 ? Double(option.bewertung.rpnGesamt) : nil
            optK.status = .aktiv
            neueKnoten.append(optK)
            neueKanten.append(FenlynineOSKernKante(
                id: "kante.\(ereignisId).\(optionId)",
                vonId: ereignisId,
                zuId: optionId,
                typ: .bedingt,
                kausalitaet: "Vorgang bietet Handlungsoption",
                payload: ["quelle": "vorgang-store"],
                origin: "vorgang-bruecke"
            ))
        }
        store.fuegeKnotenHinzuBatch(neueKnoten, kanten: neueKanten)
    }
    private static func brueckeModul(fuer typ: VorgangTyp) -> FenlynineOSKernModul {
        switch typ {
        case .streit:      return .lexara
        case .gestaltung:  return .strategos
        case .verhandlung: return .advocatus
        case .programm:    return .oportun
        }
    }
}
