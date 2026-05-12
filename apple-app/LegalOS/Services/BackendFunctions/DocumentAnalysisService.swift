//
//  DocumentAnalysisService.swift
//  Volltext-Analyse eines Dokuments via Claude API – 1:1 Port von
//  base44/functions/analyzeDocument/entry.ts. Extrahiert: Basisdaten,
//  Argumente, Beweise, Fristen, Personen, Gegneranalyse, rechtliche
//  Analyse, Strategie, Risiko, Simulation, Aktion, Cockpit, Abschluss.
//

import Foundation
import PDFKit

@MainActor
public final class DocumentAnalysisService: ObservableObject {
    private let kiProvider: KIProvider
    private let cloudKit:   CloudKitService

    public init(kiProvider: KIProvider, cloudKit: CloudKitService) {
        self.kiProvider = kiProvider
        self.cloudKit = cloudKit
    }

    /// Vollständige Analyse-Ergebnis-Struktur (mappt auf das JSON-Schema).
    public struct AnalysisResult: Codable, Hashable {
        public var zusammenfassung: String?
        public var basisdaten: Basisdaten?
        public var streitwert: Double?
        public var argumente: [ExtArgument]?
        public var beweise:   [ExtEvidence]?
        public var fristen:   [ExtFrist]?
        public var personen:  [ExtPerson]?
        public var schritt3_gegneranalyse: Gegneranalyse?
        public var schritt4_rechtliche_analyse: RechtlicheAnalyse?
        public var schritt5_strategie: Strategie?
        public var schritt6_risiko: Risiko?
        public var schritt7_simulation: Simulation?
        public var schritt8_aktion: Aktion?
        public var schritt9_cockpit: Cockpit?
        public var schritt10_abschluss: Abschluss?
        public var informationsluecken: [InfoLuecke]?

        public struct Basisdaten: Codable, Hashable {
            public var gericht: String?
            public var aktenzeichen: String?
            public var rechtsgebiet: String?
            public var prozessziel: String?
            public var zentrale_rechtsfrage: String?
            public var instanz: String?
        }
        public struct ExtArgument: Codable, Hashable {
            public var titel: String?, beschreibung: String?
            public var seite: String?, staerke: Double?, datum: String?
        }
        public struct ExtEvidence: Codable, Hashable {
            public var titel: String?, beschreibung: String?
            public var typ: String?, gewicht: Double?, datum: String?
        }
        public struct ExtFrist: Codable, Hashable {
            public var titel: String?, datum: String?, fristtyp: String?
        }
        public struct ExtPerson: Codable, Hashable {
            public var name: String?, rolle: String?, organisation: String?
        }
        public struct Gegneranalyse: Codable, Hashable {
            public var zusammenfassung: String?
            public var taktiken: [String]?
            public var schwachstellen: [String]?
            public var gegner_profil: String?
        }
        public struct RechtlicheAnalyse: Codable, Hashable {
            public var zusammenfassung: String?
            public var relevante_paragrafen: [String]?
            public var praezedenzfaelle: [String]?
            public var compliance_risiken: [String]?
        }
        public struct Strategie: Codable, Hashable {
            public var zusammenfassung: String?, empfohlene_strategie: String?
            public var staerken: [String]?, schwaechen: [String]?
        }
        public struct Risiko: Codable, Hashable {
            public var zusammenfassung: String?, risiken: [String]?, risiko_level: String?
        }
        public struct Simulation: Codable, Hashable {
            public var zusammenfassung: String?
            public var vergleichswert_eur: Double?, prognose_einfluss: String?
        }
        public struct Aktion: Codable, Hashable {
            public var zusammenfassung: String?
            public var naechste_schritte: [String]?
            public var erforderliche_dokumente: [String]?
        }
        public struct Cockpit: Codable, Hashable {
            public var zusammenfassung: String?, prognose_delta_pct: Double?
        }
        public struct Abschluss: Codable, Hashable {
            public var zusammenfassung: String?
            public var prozessziel_erreichbar: Bool?
            public var vergleichsempfehlung: String?
        }
        public struct InfoLuecke: Codable, Hashable {
            public var schritt: String?, hinweis: String?
        }
    }

    /// Analysiert ein Dokument im Kontext eines Falls.
    /// Liefert das geparste AnalysisResult zurück und persistiert
    /// die abgeleiteten Updates in CloudKit (Case + Argumente + Beweise + Fristen).
    public func analyze(document: LegalDocument, caseEntity: Case) async throws -> AnalysisResult {

        // ── SCHRITT 1: Volltext-Extraktion (lokal via PDFKit für PDFs) ──
        var ocrText = ""
        if let urlStr = document.fileUrl, let url = URL(string: urlStr),
           document.fileType?.contains("pdf") == true,
           let pdf = PDFDocument(url: url) {
            ocrText = (0..<pdf.pageCount)
                .compactMap { pdf.page(at: $0)?.string }
                .joined(separator: "\n")
            ocrText = String(ocrText.prefix(15000))
        }

        // ── SCHRITT 2: Prompt zusammenstellen (1:1 wie in TypeScript) ───
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt auf Senior-Partner-Niveau und analysierst ein juristisches Dokument für einen Fall.

        FALLKONTEXT:
        - Fallname: \(caseEntity.fallname)
        - Rechtsgebiet: \(caseEntity.rechtsgebiet ?? "Nicht angegeben")
        - Gericht: \(caseEntity.gericht ?? "Nicht angegeben")
        - Prozessziel: \(caseEntity.prozessziel ?? "Nicht angegeben")
        - Zentrale Rechtsfrage: \(caseEntity.zentraleRechtsfrage ?? "Nicht angegeben")

        DOKUMENT: "\(document.title)" (Typ: \(document.fileType ?? "unbekannt"))
        \(ocrText.isEmpty ? "(Kein Volltext extrahierbar)" : "DOKUMENTINHALT:\n" + ocrText)

        AUFGABE: Analysiere das Dokument und extrahiere NUR was tatsächlich im Dokument steht. Erfinde NICHTS. Lasse Felder leer wenn die Information nicht vorhanden ist.

        REGELN:
        - Basisdaten (Gericht, AZ etc.) nur eintragen wenn explizit im Dokument genannt
        - Argumente nur wenn konkrete rechtliche Positionen erkennbar sind – extrahiere IMMER das Datum (YYYY-MM-DD) wenn ein Datum oder Zeitraum erkennbar ist
        - Beweise nur wenn konkrete Beweismittel erkennbar sind – extrahiere IMMER das Datum
        - Fristen nur wenn konkrete Daten genannt werden (Format: YYYY-MM-DD)
        - Personen nur wenn namentlich erwähnt
        - Gegneranalyse nur wenn Gegnerposition erkennbar ist
        - Strategie/Risiko/Simulation nur wenn daraus Ableitungen möglich sind
        - Gib kurze, präzise Texte – keine langen Aufsätze
        """

        let schema: [String: Any] = Self.fullJsonSchema()
        let raw = try await kiProvider.invokeLLM(prompt: prompt, schema: schema)

        // ── SCHRITT 3: Parsen ────────────────────────────────────────────
        let data = raw.data(using: .utf8) ?? Data()
        let result = (try? JSONDecoder().decode(AnalysisResult.self, from: data)) ?? AnalysisResult()

        // ── SCHRITT 4: Persistieren (Case + neue Argumente / Beweise / Fristen) ──
        try await applyToCase(result: result, caseEntity: caseEntity, document: document)

        return result
    }

    private func applyToCase(result: AnalysisResult,
                             caseEntity: Case,
                             document: LegalDocument) async throws {
        // Case-Update – nur leere Felder befüllen
        var updated = caseEntity
        var changed = false
        if let bd = result.basisdaten {
            if let v = bd.gericht,             isMeaningful(v), updated.gericht == nil           { updated.gericht = v;            changed = true }
            if let v = bd.aktenzeichen,        isMeaningful(v), updated.aktenzeichen == nil      { updated.aktenzeichen = v;       changed = true }
            if let v = bd.rechtsgebiet,        isMeaningful(v), updated.rechtsgebiet == nil      { updated.rechtsgebiet = v;       changed = true }
            if let v = bd.prozessziel,         isMeaningful(v), updated.prozessziel == nil       { updated.prozessziel = v;        changed = true }
            if let v = bd.zentrale_rechtsfrage,isMeaningful(v), updated.zentraleRechtsfrage == nil { updated.zentraleRechtsfrage = v; changed = true }
            if let v = bd.instanz, let inst = CaseInstanz(rawValue: v) { updated.instanz = inst; changed = true }
        }
        if let sw = result.streitwert, sw > 0, updated.streitwert == nil {
            updated.streitwert = sw; changed = true
        }
        // Notizen anhängen aus Strategie/Risiko/Aktion
        var notizen: [String] = []
        if let s = result.schritt5_strategie?.empfohlene_strategie, !s.isEmpty {
            notizen.append("📋 Strategie aus \"\(document.title)\":\n\(s)")
        }
        if let r = result.schritt6_risiko, let z = r.zusammenfassung, !z.isEmpty {
            notizen.append("⚠ Risiko [\(r.risiko_level ?? "?")] aus \"\(document.title)\":\n\(z)")
        }
        if let steps = result.schritt8_aktion?.naechste_schritte, !steps.isEmpty {
            notizen.append("→ Nächste Schritte:\n" + steps.map { "• \($0)" }.joined(separator: "\n"))
        }
        if !notizen.isEmpty {
            let combined = ([updated.notes].compactMap { $0 } + notizen).joined(separator: "\n\n")
            updated.notes = combined; changed = true
        }
        if changed {
            updated.updatedAt = Date()
            _ = try await cloudKit.save(updated)
        }

        // Argumente anlegen
        for a in result.argumente ?? [] {
            guard let titel = a.titel, !titel.isEmpty else { continue }
            var arg = Argument(caseId: caseEntity.id, title: titel)
            arg.argDescription = a.beschreibung
            arg.kiStrength = a.staerke
            arg.zeitpunkt = a.datum
            _ = try? await cloudKit.save(arg)
        }
        // Beweise anlegen
        for e in result.beweise ?? [] {
            guard let titel = e.titel, !titel.isEmpty else { continue }
            var ev = Evidence(caseId: caseEntity.id, title: titel)
            ev.evidenceDescription = e.beschreibung
            ev.kiWeight = e.gewicht
            ev.type = e.typ
            ev.datum = e.datum
            _ = try? await cloudKit.save(ev)
        }
        // Fristen anlegen
        let dF = DateFormatter(); dF.dateFormat = "yyyy-MM-dd"
        for f in result.fristen ?? [] {
            guard let titel = f.titel, let datum = f.datum,
                  let date = dF.date(from: datum) else { continue }
            var d = Deadline(caseId: caseEntity.id, title: titel, dueDate: date)
            d.fristType = f.fristtyp
            _ = try? await cloudKit.save(d)
        }
        // Personen anlegen
        for p in result.personen ?? [] {
            guard let name = p.name, !name.isEmpty else { continue }
            var per = Person(caseId: caseEntity.id, name: name)
            per.organization = p.organisation
            if let r = p.rolle, let role = PersonRole(rawValue: r) { per.role = role }
            _ = try? await cloudKit.save(per)
        }
        // Document Update (KI-Summary)
        var doc = document
        doc.aiSummary = result.zusammenfassung ?? doc.aiSummary
        if let raw = try? JSONEncoder().encode(result),
           let str = String(data: raw, encoding: .utf8) {
            doc.aiRawJSON = str
        }
        _ = try? await cloudKit.save(doc)
    }

    private func isMeaningful(_ v: String) -> Bool {
        let t = v.trimmingCharacters(in: .whitespaces)
        return t.count > 2 && !t.contains("Nicht angegeben")
    }

    // Schema (vereinfachte JSON-Schema-Map – Claude nutzt dies als Strukturhinweis)
    private static func fullJsonSchema() -> [String: Any] {
        [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "basisdaten": [
                    "type": "object",
                    "properties": [
                        "gericht":             ["type": "string"],
                        "aktenzeichen":        ["type": "string"],
                        "rechtsgebiet":        ["type": "string"],
                        "prozessziel":         ["type": "string"],
                        "zentrale_rechtsfrage":["type": "string"],
                        "instanz":             ["type": "string"]
                    ]
                ],
                "streitwert": ["type": "number"],
                "argumente": ["type": "array", "items": ["type": "object"]],
                "beweise":   ["type": "array", "items": ["type": "object"]],
                "fristen":   ["type": "array", "items": ["type": "object"]],
                "personen":  ["type": "array", "items": ["type": "object"]],
                "schritt3_gegneranalyse":      ["type": "object"],
                "schritt4_rechtliche_analyse": ["type": "object"],
                "schritt5_strategie":          ["type": "object"],
                "schritt6_risiko":             ["type": "object"],
                "schritt7_simulation":         ["type": "object"],
                "schritt8_aktion":             ["type": "object"],
                "schritt9_cockpit":            ["type": "object"],
                "schritt10_abschluss":         ["type": "object"],
                "informationsluecken":         ["type": "array", "items": ["type": "object"]]
            ]
        ]
    }
}
