import Foundation
enum StrategosOpportunismaVertragsService {
    static func dokumentURLs(fuer szenario: StrategosScenario) -> [String] {
        var urls: [String] = []
        var seen = Set<String>()
        func add(_ url: String?) {
            guard let u = url?.trimmingCharacters(in: .whitespacesAndNewlines),
                  KIFileURLs.isValidAttachmentURL(u), !seen.contains(u) else { return }
            seen.insert(u)
            urls.append(u)
        }
        if let docs = szenario.ki_kontext?.dictValue?["docs"] as? [[String: Any]] {
            for d in docs { add(d["url"] as? String) }
        }
        if let docs = szenario.unternehmenskontext?.dictValue?["dokumente"] as? [[String: Any]] {
            for d in docs { add(d["url"] as? String) }
        }
        return urls
    }
    static func dokumentKontextText(fuer szenario: StrategosScenario) -> String {
        var teile: [String] = []
        if let docs = szenario.ki_kontext?.dictValue?["docs"] as? [[String: Any]] {
            for d in docs {
                let name = d["name"] as? String ?? "Dokument"
                if let s = d["summary"] as? String, !s.isEmpty {
                    teile.append("• \(name): \(s)")
                }
            }
        }
        if let docs = szenario.unternehmenskontext?.dictValue?["dokumente"] as? [[String: Any]] {
            for d in docs {
                let name = d["name"] as? String ?? "Dokument"
                if let a = d["analyse"] as? [String: Any], !a.isEmpty {
                    teile.append("• \(name) (Scan): \(String(describing: a).prefix(500))")
                }
            }
        }
        if let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String, !briefing.isEmpty {
            teile.append("KI-Briefing:\n\(String(briefing.prefix(4000)))")
        }
        if let facts = szenario.ki_kontext?.dictValue?["schluessel_fakten"] as? [String], !facts.isEmpty {
            teile.append("Schlüsselfakten: \(facts.joined(separator: "; "))")
        }
        return teile.joined(separator: "\n\n")
    }
    static func vertragsAnalysePrompt(szenario: StrategosScenario, notiz: String) -> String {
        let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
        let briefing = szenario.ki_kontext?.dictValue?["ki_briefing"] as? String ?? ""
        let sit = szenario.situationsanalyse?.dictValue ?? [:]
        let frage = szenario.fragestellung ?? "—"
        return """
        Du bist Senior-Vertragsanwalt UND Unternehmensstratege (Opportunisma-Ebene von Strategos).
        Analysiere Vertrag/Dokument auf Klauseln, Kausalverhalten und Unternehmenswirkung — NICHT individuelle Karrierevorteile.
        UNTERNEHMEN (eigen): \(ctx["unternehmen_name"] as? String ?? "—")
        VERTRAGSPARTNER: \(ctx["gegner_name"] as? String ?? "—") (\(ctx["gegner_rolle"] as? String ?? "—"))
        SACHVERHALT: \(ctx["sachverhalt_lang"] as? String ?? String(briefing.prefix(2500)))
        FRAGESTELLUNG: \(frage)
        SITUATIONSRISIKO: \(sit["gesamt_risiko"] ?? "—")
        NOTIZEN: \(notiz)
        DOKUMENT-KONTEXT (Text):
        \(dokumentKontextText(fuer: szenario).isEmpty ? "—" : dokumentKontextText(fuer: szenario))
        AUFGABEN:
        1) Klauseln: Risiko, betroffene Bereiche/Personen/Abteilungen, Wirkung auf Gesamtunternehmen
        2) Liefertermine/Verzug: Wahrscheinlichkeit Nichteinhaltung, Schadenersatzansprüche, Sinn der Durchsetzung
        3) Schaden für eigenes Unternehmen bei Verzug vs. Nutzen einer Klage vs. strategischer Vorteil wenn Gegner in Verzug
        4) Entscheidungsbäume: Optionen → Folgeoptionen → Ziele (Compliance? Wettbewerb? Schadenersatz? Steuer/Ressourcen?)
        5) Eigene Pflichtverletzung UND Vertragspartner-Pflichtverletzung: Sinn, Risiken, rechtliche Optionen (Schadenersatz, Vertragsstrafe, Kündigung)
        6) Steuer-/Ressourcen-Trade-offs (z.B. Bußgeld vs. Zahlung) — nur legal/compliant
        7) opportunisma_kausalitaeten mit strategos_bezug je Klausel/Entscheidung
        8) opportunisma_prognosen: mindestens 8 Zeilen — je Klausel Was-wenn-Szenarien (eigene Verletzung, Partner-Verletzung, positive/negative Unternehmenswirkung, rechtliche Optionen)
        9) politik_lobby: relevante Akteure und Folgen für Unternehmen
        10) verhandlungspunkte: konkrete Verhandlungshebel
        KLAUSEL-TIEFENANALYSE (Mechanik-Prinzip — je Klausel, abstrakt auf JEDEN Vertragstyp anwendbar):
        Für JEDE Klausel zusätzlich ausfüllen:
        a) paragraf_referenz (z.B. "§ 4") + norm_referenzen (einschlägige Gesetze/Normen/Beschlüsse)
        b) risiko_score 0–10 (kritisch ≥ 8.5, hoch ≥ 7, mittel ≥ 4, niedrig darunter)
        c) rechtliche_mechanik: WIE die Klausel juristisch wirkt (der Mechanismus, nicht nur das Ergebnis)
        d) juristische_vorteile und juristische_nachteile (je 2–4 Punkte)
        e) szenario_projektionen: je Zeithorizont (kurzfristig/mittelfristig/langfristig) ein Wenn-Dann-Trigger
           ("wenn X eintritt …"), erwartete Entwicklung und empfohlene_reaktion
        f) verhandlungsempfehlung: konkreter Verhandlungszug vor Unterzeichnung/Änderung
        g) ist_formulierung (wörtliche/sinngemäße aktuelle Klausel) und soll_formulierung (empfohlene Neuformulierung)
        h) durchsetzbarkeit: Einschätzung, ob/wie die Klausel real durchsetzbar ist
        i) handlungsoptionen: 2–4 Optionen (typ: akzeptieren/nachverhandeln/alternativ_formulieren/ablehnen)
           mit wahrscheinlichkeit_pct (Akzeptanz Gegenseite), kosten (Gering/Mittel/Hoch oder €), strategischer_wert
           (negativ/mittel/hoch) und genau EINER Option empfohlen=true
        j) wirkungsbaum: Folgen-Knoten (typ: rechtliche_folge/rechtlicher_vorteil/betrieb, zeithorizont, text)
        GESAMT-PROJEKTION (zusätzlich, Vertrags-übergreifend):
        - szenario_projektion: best_case / base_case / worst_case (je 1–3 Sätze, konkret)
        - verhandlungsprioritaeten: 3 nummerierte Prioritäten VOR Unterzeichnung (rang, titel, beschreibung)
        - kritische_fristen: datierte Fristen/Ereignisse mit Konsequenz (datum, titel, konsequenz)
        TRANSPARENZ in methodik. Deutsch. Keine illegalen Empfehlungen.
        """
    }
    static func vertragsAnalyseSchema() -> [String: Any] {
        [
            "type": "object",
            "properties": [
                "dokument_typ": ["type": "string"],
                "gesamtrisiko": ["type": "string"],
                "methodik": ["type": "string"],
                "verhandlungspunkte": ["type": "array", "items": ["type": "string"]],
                "klauseln": ["type": "array", "items": ["type": "object", "properties": [
                    "klausel_typ": ["type": "string"],
                    "kurzbeschreibung": ["type": "string"],
                    "risiko_level": ["type": "string"],
                    "betroffene_bereiche": ["type": "array", "items": ["type": "string"]],
                    "betroffene_personen_rollen": ["type": "array", "items": ["type": "string"]],
                    "wirkung_unternehmen": ["type": "string"],
                    "wirkung_gesamt": ["type": "string"],
                    "empfehlung": ["type": "string"],
                    "paragraf_referenz": ["type": "string"],
                    "norm_referenzen": ["type": "array", "items": ["type": "string"]],
                    "risiko_score": ["type": "number"],
                    "rechtliche_mechanik": ["type": "string"],
                    "juristische_vorteile": ["type": "array", "items": ["type": "string"]],
                    "juristische_nachteile": ["type": "array", "items": ["type": "string"]],
                    "szenario_projektionen": ["type": "array", "items": ["type": "object", "properties": [
                        "zeithorizont": ["type": "string"],
                        "trigger": ["type": "string"],
                        "entwicklung": ["type": "string"],
                        "empfohlene_reaktion": ["type": "string"]
                    ]]],
                    "verhandlungsempfehlung": ["type": "string"],
                    "ist_formulierung": ["type": "string"],
                    "soll_formulierung": ["type": "string"],
                    "durchsetzbarkeit": ["type": "string"],
                    "handlungsoptionen": ["type": "array", "items": ["type": "object", "properties": [
                        "label": ["type": "string"],
                        "typ": ["type": "string"],
                        "beschreibung": ["type": "string"],
                        "wahrscheinlichkeit_pct": ["type": "number"],
                        "kosten": ["type": "string"],
                        "strategischer_wert": ["type": "string"],
                        "empfohlen": ["type": "boolean"]
                    ]]],
                    "wirkungsbaum": ["type": "array", "items": ["type": "object", "properties": [
                        "typ": ["type": "string"],
                        "zeithorizont": ["type": "string"],
                        "text": ["type": "string"]
                    ]]]
                ]]],
                "szenario_projektion": ["type": "object", "properties": [
                    "best_case": ["type": "string"],
                    "base_case": ["type": "string"],
                    "worst_case": ["type": "string"]
                ]],
                "verhandlungsprioritaeten": ["type": "array", "items": ["type": "object", "properties": [
                    "rang": ["type": "number"],
                    "titel": ["type": "string"],
                    "beschreibung": ["type": "string"]
                ]]],
                "kritische_fristen": ["type": "array", "items": ["type": "object", "properties": [
                    "datum": ["type": "string"],
                    "titel": ["type": "string"],
                    "konsequenz": ["type": "string"]
                ]]],
                "liefertermine": ["type": "array", "items": ["type": "object", "properties": [
                    "termin": ["type": "string"],
                    "wahrscheinlichkeit_verzug_pct": ["type": "number"],
                    "schadenersatz_anspruch": ["type": "string"],
                    "durchsetzung_sinnvoll": ["type": "boolean"],
                    "schaden_eigenes_unternehmen": ["type": "string"],
                    "schaden_durch_klage": ["type": "string"],
                    "vorteil_gegner_verzug": ["type": "string"],
                    "empfehlung": ["type": "string"]
                ]]],
                "zielhypothesen": ["type": "array", "items": ["type": "object", "properties": [
                    "ziel": ["type": "string"],
                    "typ": ["type": "string"],
                    "wahrscheinlichkeit_pct": ["type": "number"],
                    "beschreibung": ["type": "string"]
                ]]],
                "entscheidungsbaeume": ["type": "array", "items": ["type": "object", "properties": [
                    "wurzel": ["type": "string"],
                    "optionen": ["type": "array", "items": ["type": "object", "properties": [
                        "label": ["type": "string"],
                        "wahrscheinlichkeit_pct": ["type": "number"],
                        "folge_optionen": ["type": "array", "items": ["type": "string"]],
                        "ziel": ["type": "string"],
                        "wirkung_unternehmen": ["type": "string"]
                    ]]]
                ]]],
                "eigene_pflichtverletzung": ["type": "object", "properties": [
                    "szenario": ["type": "string"],
                    "kostenersparnis": ["type": "string"],
                    "risiken": ["type": "array", "items": ["type": "string"]],
                    "empfehlung": ["type": "string"]
                ]],
                "steuer_ressourcen": ["type": "array", "items": ["type": "object", "properties": [
                    "option": ["type": "string"],
                    "kosten_eur": ["type": "number"],
                    "strafe_risiko_eur": ["type": "number"],
                    "empfehlung": ["type": "string"],
                    "legal": ["type": "boolean"]
                ]]],
                "politik_lobby": ["type": "array", "items": ["type": "object", "properties": [
                    "akteur": ["type": "string"],
                    "massnahme": ["type": "string"],
                    "folge": ["type": "string"]
                ]]],
                "szenarien": ["type": "object"],
                "opportunisma_kausalitaeten": ["type": "array", "items": ["type": "object", "properties": [
                    "ursache": ["type": "string"],
                    "wirkung": ["type": "string"],
                    "beeinflussbar": ["type": "boolean"],
                    "bewertung": ["type": "string"],
                    "betroffene": ["type": "array", "items": ["type": "string"]],
                    "empfehlung": ["type": "string"],
                    "strategos_bezug": ["type": "string"]
                ]]],
                "opportunisma_prognosen": ["type": "array", "items": ["type": "object", "properties": [
                    "situation": ["type": "string"],
                    "option": ["type": "string"],
                    "fuehrt_zu": ["type": "string"],
                    "wahrscheinlichkeit": ["type": "number"],
                    "kontrolle": ["type": "number"],
                    "dimension": ["type": "string"]
                ]]]
            ] as [String: Any]
        ] as [String: Any]
    }
    @MainActor
    static func analysiereVertrag(
        szenario: StrategosScenario,
        notiz: String
    ) async throws -> [String: Any] {
        let fileUrls = KIFileURLs.sanitize(dokumentURLs(fuer: szenario))
        let prompt = vertragsAnalysePrompt(szenario: szenario, notiz: notiz)
        let schema = vertragsAnalyseSchema()
        let response: AnyCodable = try await LLMService.shared.invoke(
            prompt: prompt,
            schema: schema,
            fileUrls: fileUrls,
            model: "claude_sonnet_4_6"
        )
        return try KIJson.requireObject(response, kontext: "Vertragsanalyse")
    }
    static func opportunismaDaten(aus vertrag: [String: Any]) -> (
        kausalitaeten: [PragKausalitaet],
        prognosen: [PragPrognoseZeile]
    ) {
        let kausal = KIJson.array(in: vertrag, keys: "opportunisma_kausalitaeten").map { row in
            PragKausalitaet(
                ursache: row["ursache"] as? String ?? "—",
                wirkung: row["wirkung"] as? String ?? "—",
                beeinflussbar: row["beeinflussbar"] as? Bool ?? false,
                bewertung: row["bewertung"] as? String ?? "neutral",
                betroffene: row["betroffene"] as? [String] ?? [],
                empfehlung: row["empfehlung"] as? String,
                strategosBezug: row["strategos_bezug"] as? String
            )
        }
        let prog = KIJson.array(in: vertrag, keys: "opportunisma_prognosen").map { row in
            PragPrognoseZeile(
                situation: row["situation"] as? String ?? "—",
                option: row["option"] as? String ?? "—",
                fuehrt_zu: row["fuehrt_zu"] as? String ?? "—",
                vorteile: [],
                risiken: [],
                wahrscheinlichkeit: KIJson.intValue(row["wahrscheinlichkeit"]) ?? 50,
                kontrolle: KIJson.intValue(row["kontrolle"]) ?? 50,
                beeinflussbar: true,
                mittel: [],
                dimension: row["dimension"] as? String ?? "Wirtschaft"
            )
        }
        return (kausal, prog)
    }
    static func vertragsAnalyseDict(fuer szenario: StrategosScenario?) -> [String: Any]? {
        guard let s = szenario else { return nil }
        return s.ki_analyse?.dictValue?["vertrags_analyse"] as? [String: Any]
    }
}
