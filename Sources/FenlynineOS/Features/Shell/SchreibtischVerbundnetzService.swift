import Foundation
enum SchreibtischVerbundnetzService {
    static func netzErzeugen(basis: String, ziel: String) async throws -> (knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], analyse: String) {
        let prompt = netzPrompt(basis: basis, ziel: ziel)
        do {
            let result = try await LLMService.shared.invokeObject(
                prompt: prompt,
                schema: netzSchema(),
                logKiName: "Schreibtisch_Verbundnetz"
            )
            return parseNetz(result, basis: basis, ziel: ziel)
        } catch {
            return algorithmischesNetz(basis: basis, ziel: ziel)
        }
    }
    static func taktikAnpassen(
        basis: String,
        ziel: String,
        situation: String,
        bestehendeKnoten: [VerbundNetzKnoten],
        bestehendeKanten: [VerbundNetzKante]
    ) async throws -> (knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], empfehlung: String) {
        let kontext = bestehendeKnoten.map { "• [\($0.typ.bezeichnung)] \($0.titel) (\($0.status.bezeichnung))" }.joined(separator: "\n")
        let prompt = """
        Du bist Prozess- und Verhandlungstaktiker. Reagiere SOFORT auf eine neue Situation in der Verhandlung/Gericht.
        BASISLAGE: \(basis)
        ZIEL: \(ziel)
        AKTUELLE SITUATION (JETZT): \(situation)
        BESTEHENDES NETZ:
        \(kontext)
        AUFGABE:
        1) Analysiere kausale Auswirkungen der Situation
        2) Empfehle 1–3 SOFORT-Reaktionen (neue Taktik-Knoten oder Anpassungen)
        3) Verknüpfe Reaktionen kausal mit bestehenden Knoten (reaktion_auf / knuepft_an)
        4) Markiere automatisierte Sofort-Schritte (automatisiert: true)
        5) Ordne jeden Schritt einem Modul zu: strategos, opportunisma, lexara, lagebild
        Antworte NUR als JSON. Neue Knoten-IDs mit Präfix "taktik_".
        """
        do {
            let result = try await LLMService.shared.invokeObject(
                prompt: prompt,
                schema: taktikSchema(),
                logKiName: "Schreibtisch_Verhandlung"
            )
            return parseTaktik(result)
        } catch {
            return algorithmischeTaktik(situation: situation, knoten: bestehendeKnoten, kanten: bestehendeKanten)
        }
    }
    private static func netzPrompt(basis: String, ziel: String) -> String {
        """
        Du bist Legal-Workflow-Architekt. Erstelle ein abstraktes ARBEITSNETZ (Spinnennetz/Mindmap) von der Basis-Situation bis zum Gerichtsverfahren.
        BASIS-SITUATION: \(basis)
        ZIEL: \(ziel)
        PRINZIPIEN:
        - Abstrakt auf JEDEN Fall anwendbar (nicht konkrete Namen aus Beispielen)
        - Jeder Knoten = ein Arbeitsschritt mit klarer Modul-Zuordnung
        - Kanten zeigen KAUSALE Zusammenhänge (Vorlage für Schriftsatz, Aussage knüpft an Beweis, etc.)
        - Verzweigungen wo mehrere Wege zum selben Ziel führen
        - 8–14 Knoten, Tiefe 0 (Ausgang) bis 4–5 (Gericht/Ziel)
        - Markiere Schritte die algorithmisch automatisierbar sind (automatisiert: true)
        MODUL-ZUORDNUNG (modul):
        - strategos: Verträge, Unternehmensstrategie, Szenarien
        - opportunisma: Taktik, Machtverhältnisse, Verhandlung
        - lexara: Fälle, Dokumente, Argumente, Schriftsätze
        - lagebild: Übersicht, KPIs, Koordination
        KNOTEN-TYPEN: ausgangslage, analyse, dokument, aussage, vorlage, arbeitsschritt, taktik, verhandlung, gericht, ziel
        KANTEN-TYPEN: fuehrt_zu, vorlage_fuer, knuepft_an, reaktion_auf, verzweigung
        Antworte NUR als JSON.
        """
    }
    private static func netzSchema() -> [String: Any] {
        knotenKantenSchema(includeEmpfehlung: false)
    }
    private static func taktikSchema() -> [String: Any] {
        var s = knotenKantenSchema(includeEmpfehlung: true)
        s["required"] = ["knoten", "kanten", "empfehlung"]
        return s
    }
    private static func knotenKantenSchema(includeEmpfehlung: Bool) -> [String: Any] {
        var props: [String: Any] = [
            "knoten": ["type": "array", "items": ["type": "object", "properties": [
                "id": ["type": "string"],
                "titel": ["type": "string"],
                "typ": ["type": "string"],
                "beschreibung": ["type": "string"],
                "modul": ["type": "string"],
                "modul_aktion": ["type": "string"],
                "tiefe": ["type": "number"],
                "automatisiert": ["type": "boolean"],
                "kausal_trigger": ["type": "string"]
            ]]],
            "kanten": ["type": "array", "items": ["type": "object", "properties": [
                "id": ["type": "string"],
                "von_id": ["type": "string"],
                "zu_id": ["type": "string"],
                "beziehung": ["type": "string"],
                "kausalitaet": ["type": "string"]
            ]]],
            "zusammenfassung": ["type": "string"]
        ]
        if includeEmpfehlung {
            props["empfehlung"] = ["type": "string"]
        }
        return ["type": "object", "properties": props]
    }
    private static func parseNetz(_ dict: [String: Any], basis: String, ziel: String) -> (knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], analyse: String) {
        let knoten = parseKnoten(dict["knoten"] as? [[String: Any]] ?? [], basis: basis)
        let kanten = parseKanten(dict["kanten"] as? [[String: Any]] ?? [])
        let analyse = dict["zusammenfassung"] as? String ?? "Netz erstellt."
        if knoten.isEmpty { return algorithmischesNetz(basis: basis, ziel: ziel) }
        return (knoten, kanten, analyse)
    }
    private static func parseTaktik(_ dict: [String: Any]) -> (knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], empfehlung: String) {
        let knoten = parseKnoten(dict["knoten"] as? [[String: Any]] ?? [], basis: nil)
        let kanten = parseKanten(dict["kanten"] as? [[String: Any]] ?? [])
        let empfehlung = dict["empfehlung"] as? String ?? dict["zusammenfassung"] as? String ?? "Taktik angepasst."
        return (knoten, kanten, empfehlung)
    }
    private static func parseKnoten(_ raw: [[String: Any]], basis: String?) -> [VerbundNetzKnoten] {
        var result: [VerbundNetzKnoten] = []
        for (i, k) in raw.enumerated() {
            let typRaw = k["typ"] as? String ?? "arbeitsschritt"
            let typ = VerbundNetzKnotenTyp(rawValue: typRaw) ?? .arbeitsschritt
            let modulRaw = k["modul"] as? String ?? "lexara"
            let modul = SchreibtischModul(rawValue: modulRaw) ?? .lexara
            let id = k["id"] as? String ?? "k\(i)"
            let titel = k["titel"] as? String ?? "Schritt \(i + 1)"
            result.append(VerbundNetzKnoten(
                id: id,
                titel: titel,
                typ: typ,
                beschreibung: k["beschreibung"] as? String ?? "",
                modul: modul,
                modulAktion: k["modul_aktion"] as? String ?? typ.bezeichnung,
                tiefe: Int(k["tiefe"] as? Double ?? Double(i)),
                status: i == 0 ? .erledigt : .wartend,
                automatisiert: k["automatisiert"] as? Bool ?? false,
                kausalTrigger: k["kausal_trigger"] as? String
            ))
        }
        if let basis, !basis.isEmpty, !result.contains(where: { $0.tiefe == 0 }) {
            result.insert(VerbundNetzKnoten.basis(id: "basis", titel: String(basis.prefix(80))), at: 0)
        }
        return result
    }
    private static func parseKanten(_ raw: [[String: Any]]) -> [VerbundNetzKante] {
        raw.enumerated().map { i, k in
            let typRaw = k["beziehung"] as? String ?? "fuehrt_zu"
            return VerbundNetzKante(
                id: k["id"] as? String ?? "e\(i)",
                vonId: k["von_id"] as? String ?? "",
                zuId: k["zu_id"] as? String ?? "",
                typ: VerbundNetzKantenTyp(rawValue: typRaw) ?? .fuehrt_zu,
                kausalitaet: k["kausalitaet"] as? String ?? ""
            )
        }.filter { !$0.vonId.isEmpty && !$0.zuId.isEmpty }
    }
    static func algorithmischesNetz(basis: String, ziel: String) -> (knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], analyse: String) {
        let basisTitel = basis.isEmpty ? "Basis-Situation" : String(basis.prefix(80))
        let zielTitel = ziel.isEmpty ? "Ziel" : String(ziel.prefix(80))
        let knoten: [VerbundNetzKnoten] = [
            .basis(id: "basis", titel: basisTitel),
            VerbundNetzKnoten(id: "k1", titel: "Sachverhalt strukturieren", typ: .analyse, beschreibung: "Fakten und Akteure erfassen", modul: .lexara, modulAktion: "Fallsubstanz anlegen", tiefe: 1, status: .wartend, automatisiert: true, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k2", titel: "Strategische Einordnung", typ: .analyse, beschreibung: "Risiken und Chancen bewerten", modul: .strategos, modulAktion: "Szenario analysieren", tiefe: 1, status: .wartend, automatisiert: false, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k3", titel: "Dokumente & Beweise", typ: .dokument, beschreibung: "Unterlagen sammeln und verknüpfen", modul: .lexara, modulAktion: "Dokumente hochladen", tiefe: 2, status: .wartend, automatisiert: true, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k4", titel: "Argumentationslinie", typ: .aussage, beschreibung: "Kernargumente formulieren", modul: .lexara, modulAktion: "Argumente erfassen", tiefe: 2, status: .wartend, automatisiert: false, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k5", titel: "Taktisches Lagebild", typ: .taktik, beschreibung: "Machtverhältnisse und Hebel identifizieren", modul: .opportunisma, modulAktion: "Taktik planen", tiefe: 2, status: .wartend, automatisiert: false, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k6", titel: "Schriftsatz-Vorlage", typ: .vorlage, beschreibung: "Kernargumente in Vorlage überführen", modul: .lexara, modulAktion: "Vorlage erstellen", tiefe: 3, status: .wartend, automatisiert: true, kausalTrigger: "wenn Argumente stehen"),
            VerbundNetzKnoten(id: "k7a", titel: "Außergerichtliche Verhandlung", typ: .verhandlung, beschreibung: "Verhandlungstaktik vorbereiten", modul: .opportunisma, modulAktion: "Verhandlung simulieren", tiefe: 3, status: .wartend, automatisiert: false, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k7b", titel: "Direkter Klageweg", typ: .arbeitsschritt, beschreibung: "Klage vorbereiten", modul: .lexara, modulAktion: "Klage einreichen", tiefe: 3, status: .wartend, automatisiert: false, kausalTrigger: nil),
            VerbundNetzKnoten(id: "k8", titel: "Verhandlungstaktik live", typ: .verhandlung, beschreibung: "Sofort-Reaktionen in Verhandlung", modul: .opportunisma, modulAktion: "Taktik anpassen", tiefe: 4, status: .wartend, automatisiert: false, kausalTrigger: "bei unerwarteter Gegenreaktion"),
            VerbundNetzKnoten(id: "k9", titel: "Gerichtsverfahren", typ: .gericht, beschreibung: "Prozessführung und Termine", modul: .lexara, modulAktion: "Verfahren führen", tiefe: 4, status: .wartend, automatisiert: false, kausalTrigger: nil),
            VerbundNetzKnoten(id: "ziel", titel: zielTitel, typ: .ziel, beschreibung: "Erreichbares Ziel", modul: .lagebild, modulAktion: "Erfolg messen", tiefe: 5, status: .wartend, automatisiert: false, kausalTrigger: nil)
        ]
        let kanten: [VerbundNetzKante] = [
            VerbundNetzKante(id: "e1", vonId: "basis", zuId: "k1", typ: .fuehrt_zu, kausalitaet: "Sachverhalt ist Grundlage"),
            VerbundNetzKante(id: "e2", vonId: "basis", zuId: "k2", typ: .fuehrt_zu, kausalitaet: "Strategische Einordnung parallel"),
            VerbundNetzKante(id: "e3", vonId: "k1", zuId: "k3", typ: .fuehrt_zu, kausalitaet: "Struktur ermöglicht Dokumentenzuordnung"),
            VerbundNetzKante(id: "e4", vonId: "k1", zuId: "k4", typ: .knuepft_an, kausalitaet: "Fakten stützen Argumente"),
            VerbundNetzKante(id: "e5", vonId: "k2", zuId: "k5", typ: .fuehrt_zu, kausalitaet: "Strategie definiert Taktik"),
            VerbundNetzKante(id: "e6", vonId: "k4", zuId: "k6", typ: .vorlage_fuer, kausalitaet: "Argumente werden Vorlage"),
            VerbundNetzKante(id: "e7", vonId: "k3", zuId: "k6", typ: .knuepft_an, kausalitaet: "Beweise fließen in Schriftsatz"),
            VerbundNetzKante(id: "e8", vonId: "k5", zuId: "k7a", typ: .verzweigung, kausalitaet: "Taktik: Verhandlung versuchen"),
            VerbundNetzKante(id: "e9", vonId: "k5", zuId: "k7b", typ: .verzweigung, kausalitaet: "Taktik: direkter Rechtsweg"),
            VerbundNetzKante(id: "e10", vonId: "k6", zuId: "k7a", typ: .fuehrt_zu, kausalitaet: "Vorlage für Verhandlung"),
            VerbundNetzKante(id: "e11", vonId: "k6", zuId: "k7b", typ: .fuehrt_zu, kausalitaet: "Vorlage für Klage"),
            VerbundNetzKante(id: "e12", vonId: "k7a", zuId: "k8", typ: .reaktion_auf, kausalitaet: "Verhandlung erfordert Live-Taktik"),
            VerbundNetzKante(id: "e13", vonId: "k7b", zuId: "k9", typ: .fuehrt_zu, kausalitaet: "Klage führt zu Gericht"),
            VerbundNetzKante(id: "e14", vonId: "k8", zuId: "k9", typ: .fuehrt_zu, kausalitaet: "Verhandlung scheitert → Gericht"),
            VerbundNetzKante(id: "e15", vonId: "k7a", zuId: "ziel", typ: .fuehrt_zu, kausalitaet: "Einigung erreicht Ziel"),
            VerbundNetzKante(id: "e16", vonId: "k9", zuId: "ziel", typ: .fuehrt_zu, kausalitaet: "Urteil/Vergleich erreicht Ziel")
        ]
        return (knoten, kanten, "Algorithmisches Standard-Netz — von Analyse über Taktik bis Gericht. KI nicht verfügbar oder fehlgeschlagen.")
    }
    private static func algorithmischeTaktik(
        situation: String,
        knoten: [VerbundNetzKnoten],
        kanten: [VerbundNetzKante]
    ) -> (knoten: [VerbundNetzKnoten], kanten: [VerbundNetzKante], empfehlung: String) {
        let verhandlungId = knoten.first(where: { $0.typ == .verhandlung })?.id ?? "k8"
        let neuId = "taktik_\(UUID().uuidString.prefix(6))"
        let neu = VerbundNetzKnoten(
            id: neuId,
            titel: "Sofort-Reaktion",
            typ: .taktik,
            beschreibung: "Reaktion auf: \(String(situation.prefix(120)))",
            modul: .opportunisma,
            modulAktion: "Taktik sofort anpassen",
            tiefe: 4,
            status: .aktiv,
            automatisiert: false,
            kausalTrigger: situation
        )
        let kante = VerbundNetzKante(
            id: "tk_\(neuId)",
            vonId: verhandlungId,
            zuId: neuId,
            typ: .reaktion_auf,
            kausalitaet: situation
        )
        return ([neu], [kante], "Sofort-Taktikknoten erstellt. Prüfen Sie Opportunisma für Details.")
    }
}
