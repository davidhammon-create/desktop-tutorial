import Foundation
enum FenlynineOSModulFlussService {
    static func optionenUebergeben(von store: FenlynineOSKernStore, ziel: FenlynineOSKernModul) -> [FenlynineOSKernKnoten] {
        let optionen = store.knoten.filter { $0.modul == .oportun && $0.typ == .option }
        var kopien: [FenlynineOSKernKnoten] = []
        var neueKanten: [FenlynineOSKernKante] = []
        for o in optionen {
            let id = "sync_\(ziel.rawValue)_\(o.id)"
            var k = o
            k.id = id; k.modul = ziel; k.herkunft = "oportun.uebergibt"
            k.modulAktion = ziel == .lexara ? "Fall-Startpunkt" : "Szenario bewerten"
            k.status = .wartend
            kopien.append(k)
            neueKanten.append(FenlynineOSKernKante(
                id: "fluss1_\(id)", vonId: o.id, zuId: id,
                typ: .uebergibt, kausalitaet: "Oportun → \(ziel.bezeichnung)",
                origin: "modulfluss.oportun"
            ))
        }
        store.fuegeKnotenHinzuBatch(kopien, kanten: neueKanten)
        return kopien
    }
    static func szenarioNachLexara(store: FenlynineOSKernStore, szenarioId: String) -> FenlynineOSKernKnoten? {
        guard let szenario = store.knoten.first(where: { $0.id == szenarioId }) else { return nil }
        var fall = szenario
        fall.id = "lexara_\(szenarioId)"
        fall.modul = .lexara; fall.herkunft = "strategos.sync"
        fall.modulAktion = "9-Schritt-Analyse starten"; fall.status = .aktiv; fall.tiefe = 1
        store.fuegeKnotenHinzu(fall, kanten: [FenlynineOSKernKante(
            id: "fluss2_\(fall.id)", vonId: szenarioId, zuId: fall.id,
            typ: .uebergibt, kausalitaet: "Szenario eskaliert zu Fall",
            origin: "modulfluss.strategos_lexara"
        )])
        return fall
    }
    static func praezedenzZurueck(store: FenlynineOSKernStore, fallId: String, ausgang: Double) {
        let prior = FenlynineOSKernKnoten(
            id: "prior_\(fallId)", typ: .option,
            titel: "Präzedenz aus Fall", beschreibung: "Ausgang: \(Int(ausgang * 100))%",
            modul: .strategos, modulAktion: "Prior für künftige Szenarien",
            herkunft: "lexara.praezedenz", tiefe: 1, status: .erledigt, automatisiert: true,
            pErfolg: ausgang, gewinn: nil, verlust: nil, kosten: nil,
            rav: nil, ev: nil, rpn: nil, a: nil, b: nil, e: nil,
            fristDatum: nil, fristKritisch: nil, tageRestlauf: nil, kausalTrigger: nil
        )
        store.fuegeKnotenHinzu(prior, kanten: [FenlynineOSKernKante(
            id: "fluss3_\(prior.id)", vonId: fallId, zuId: prior.id,
            typ: .uebergibt, kausalitaet: "Fall-Ergebnis als Prior",
            origin: "modulfluss.lexara_strategos"
        )])
    }
    static func klauselVerknuepfen(
        store: FenlynineOSKernStore, klauselId: String, zielId: String,
        typ: FenlynineOSKernKantenTyp, delta: Double = 0.15
    ) {
        store.kanten.append(FenlynineOSKernKante(
            id: "fluss4_\(klauselId)_\(zielId)",
            vonId: klauselId, zuId: zielId, typ: typ,
            kausalitaet: "Klausel wirkt auf Ziel",
            payload: ["delta": String(delta)],
            origin: "strategos.vertragsanalyse"
        ))
        store.graphNeuBerechnen()
        store.scheduleSpeichern()
    }
    static func algorithmischesNetz(basis: String, ziel: String) -> (knoten: [FenlynineOSKernKnoten], kanten: [FenlynineOSKernKante], analyse: String) {
        let basisTitel = basis.isEmpty ? "Basis-Situation" : String(basis.prefix(80))
        let zielTitel = ziel.isEmpty ? "Ziel" : String(ziel.prefix(80))
        let knoten: [FenlynineOSKernKnoten] = [
            .basis(id: "basis", titel: basisTitel),
            kn("o_a", "Option A — konservativ", .option, .oportun, 1, 0.55, 80_000, -30_000, 8_000),
            kn("o_b", "Option B — mittel", .option, .oportun, 1, 0.50, 120_000, -60_000, 15_000),
            kn("o_c", "Option C — aggressiv", .option, .oportun, 1, 0.35, 200_000, -120_000, 25_000),
            kn("s1", "Strategische Einordnung", .option, .strategos, 2, nil, nil, nil, nil),
            kn("k1", "Klausel-Analyse", .klausel, .strategos, 2, nil, nil, nil, nil),
            kn("r1", "Haftungsrisiko", .risiko, .strategos, 3, nil, nil, nil, nil, a: 7, b: 6, e: 5),
            kn("l1", "Lexara 9-Schritte", .option, .lexara, 3, 0.57, 100_000, -50_000, 12_000),
            kn("a1", "Kernargument", .argument, .lexara, 3, nil, nil, nil, nil),
            kn("v1", "Verhandlung live", .ereignis, .advocatus, 4, nil, nil, nil, nil),
            kn("ziel", zielTitel, .option, .koordination, 5, 0.65, 150_000, -40_000, 10_000)
        ]
        let kanten: [FenlynineOSKernKante] = [
            ka("e1", "basis", "o_a", .bedingt, "Ausgangslage"),
            ka("e2", "basis", "o_b", .bedingt, "Ausgangslage"),
            ka("e3", "basis", "o_c", .bedingt, "Ausgangslage"),
            ka("e4", "o_a", "s1", .uebergibt, "Oportun → Strategos"),
            ka("e5", "o_b", "s1", .uebergibt, "Oportun → Strategos"),
            ka("e6", "s1", "k1", .bedingt, "Vertrag vorhanden"),
            ka("e7", "k1", "r1", .erhoeht_risiko, "Klausel #K7", ["delta": "0.15"]),
            ka("e8", "k1", "o_b", .aendert_p_erfolg, "Nachverhandeln", ["delta": "0.10"]),
            ka("e9", "s1", "l1", .uebergibt, "Eskalation → Lexara"),
            ka("e10", "a1", "l1", .begruendet, "Argument stützt"),
            ka("e11", "l1", "v1", .bedingt, "Verhandlungstag"),
            ka("e12", "v1", "o_a", .aendert_p_erfolg, "Live-Ereignis", ["delta": "-0.15"]),
            ka("e13", "o_a", "ziel", .bedingt, "Ziel erreicht"),
            ka("e14", "l1", "ziel", .bedingt, "Empfehlung umgesetzt")
        ]
        return (knoten, kanten, "Kern-Netz: Oportun → Strategos → Lexara → Advocatus → Ziel. Deterministischer Rechenkern aktiv.")
    }
    static func netzErzeugen(basis: String, ziel: String) async throws -> (knoten: [FenlynineOSKernKnoten], kanten: [FenlynineOSKernKante], analyse: String) {
        let prompt = """
        Erstelle ein FenlynineOS-Kausalgraph-Netz (PDF-Spezifikation).
        BASIS: \(basis) | ZIEL: \(ziel)
        Knotentypen: OPTION, RISIKO, FRIST, KOSTEN, ARGUMENT, KLAUSEL, EREIGNIS
        Module: oportun, strategos, lexara, advocatus, koordination
        Kantentypen: begruendet, widerlegt, bedingt, erhoeht_risiko, senkt_risiko, aendert_p_erfolg, verschiebt_frist, uebergibt
        Fluss: Oportun findet Optionen → Strategos rechnet Zukunft → Lexara entscheidet → Advocatus live.
        10-16 Knoten, Zahlenfelder für OPTION (p_erfolg, gewinn, verlust, kosten).
        Antworte NUR als JSON.
        """
        do {
            let r = try await LLMService.shared.invokeObject(prompt: prompt, schema: kiSchema(), logKiName: "FenlynineOS_Kern_Netz")
            return parseKI(r, basis: basis)
        } catch {
            return algorithmischesNetz(basis: basis, ziel: ziel)
        }
    }
    private static func kn(
        _ id: String, _ titel: String, _ typ: FenlynineOSKernKnotenTyp, _ modul: FenlynineOSKernModul,
        _ tiefe: Int, _ p: Double? = nil, _ g: Double? = nil, _ v: Double? = nil, _ k: Double? = nil,
        a: Int = 5, b: Int = 5, e: Int = 5
    ) -> FenlynineOSKernKnoten {
        FenlynineOSKernKnoten(
            id: id, typ: typ, titel: titel, beschreibung: typ.bezeichnung,
            modul: modul, modulAktion: modul.bezeichnung, herkunft: "\(modul.rawValue).kern",
            tiefe: tiefe, status: .wartend, automatisiert: typ == .option,
            pErfolg: p, gewinn: g, verlust: v, kosten: k,
            rav: nil, ev: nil, rpn: typ == .risiko ? Double(FenlynineOSRechenkern.rpn(a: a, b: b, e: e)) : nil,
            a: a, b: b, e: e, fristDatum: nil, fristKritisch: nil, tageRestlauf: nil, kausalTrigger: nil
        )
    }
    private static func ka(_ id: String, _ von: String, _ zu: String, _ typ: FenlynineOSKernKantenTyp, _ kaus: String, _ payload: [String: String] = [:]) -> FenlynineOSKernKante {
        FenlynineOSKernKante(id: id, vonId: von, zuId: zu, typ: typ, kausalitaet: kaus, payload: payload, origin: "kern")
    }
    private static func kiSchema() -> [String: Any] {
        ["type": "object", "properties": [
            "knoten": ["type": "array"], "kanten": ["type": "array"],
            "zusammenfassung": ["type": "string"]
        ]]
    }
    private static func parseKI(_ d: [String: Any], basis: String) -> (knoten: [FenlynineOSKernKnoten], kanten: [FenlynineOSKernKante], analyse: String) {
        let fallback = algorithmischesNetz(basis: basis, ziel: "")
        guard let rawK = d["knoten"] as? [[String: Any]], !rawK.isEmpty else { return fallback }
        var knoten: [FenlynineOSKernKnoten] = []
        for (i, k) in rawK.enumerated() {
            let typ = FenlynineOSKernKnotenTyp(rawValue: (k["typ"] as? String ?? "option").lowercased()) ?? .option
            let modul = FenlynineOSKernModul(rawValue: k["modul"] as? String ?? "koordination") ?? .koordination
            knoten.append(FenlynineOSKernKnoten(
                id: k["id"] as? String ?? "k\(i)",
                typ: typ, titel: k["titel"] as? String ?? "Knoten \(i)",
                beschreibung: k["beschreibung"] as? String ?? "",
                modul: modul, modulAktion: k["modul_aktion"] as? String ?? "",
                herkunft: k["herkunft"] as? String ?? "ki",
                tiefe: Int(k["tiefe"] as? Double ?? Double(i)),
                status: i == 0 ? .erledigt : .wartend, automatisiert: k["automatisiert"] as? Bool ?? false,
                pErfolg: k["p_erfolg"] as? Double, gewinn: k["gewinn"] as? Double,
                verlust: k["verlust"] as? Double, kosten: k["kosten"] as? Double,
                rav: nil, ev: nil, rpn: nil, a: nil, b: nil, e: nil,
                fristDatum: nil, fristKritisch: nil, tageRestlauf: nil,
                kausalTrigger: k["kausal_trigger"] as? String
            ))
        }
        if !knoten.contains(where: { $0.tiefe == 0 }) {
            knoten.insert(.basis(id: "basis", titel: String(basis.prefix(80))), at: 0)
        }
        var kanten: [FenlynineOSKernKante] = []
        if let rawE = d["kanten"] as? [[String: Any]] {
            for (i, e) in rawE.enumerated() {
                let typ = FenlynineOSKernKantenTyp(rawValue: e["typ"] as? String ?? e["beziehung"] as? String ?? "bedingt") ?? .bedingt
                kanten.append(FenlynineOSKernKante(
                    id: e["id"] as? String ?? "e\(i)",
                    vonId: e["von_id"] as? String ?? "", zuId: e["zu_id"] as? String ?? "",
                    typ: typ, kausalitaet: e["kausalitaet"] as? String ?? "",
                    payload: (e["payload"] as? [String: String]) ?? [:],
                    origin: e["origin"] as? String ?? "ki"
                ))
            }
        }
        return (knoten, kanten.filter { !$0.vonId.isEmpty && !$0.zuId.isEmpty }, d["zusammenfassung"] as? String ?? "KI-Netz")
    }
}
