//
//  CaseComplianceService.swift
//  Compliance-Check eines Falls via Claude API. 1:1 Port von
//  base44/functions/checkCaseCompliance/entry.ts.
//

import Foundation

@MainActor
public final class CaseComplianceService: ObservableObject {
    private let kiProvider: KIProvider
    private let cloudKit:   CloudKitService
    public init(kiProvider: KIProvider, cloudKit: CloudKitService) {
        self.kiProvider = kiProvider; self.cloudKit = cloudKit
    }

    public struct ComplianceWarning: Codable, Hashable {
        public var typ: String                // "rechtsfehler" | "frist" | "form" | "anhörung" | "beweis"
        public var schweregrad: String        // "hoch" | "mittel" | "niedrig"
        public var titel: String
        public var beschreibung: String
        public var paragraph: String?
        public var empfehlung: String
        public var betroffenes_objekt_typ: String?    // "case" | "argument" | "deadline" | "evidence"
        public var betroffenes_objekt_id: String?
    }

    public struct ComplianceResult: Codable, Hashable {
        public var warnings: [ComplianceWarning]
        public var gesamtbewertung: String?
        public var compliance_score: Int?     // 0–100
    }

    public func check(caseEntity: Case,
                      arguments: [Argument],
                      evidence: [Evidence],
                      deadlines: [Deadline],
                      persons: [Person]) async throws -> ComplianceResult {

        let prompt = """
        Du bist ein erfahrener juristischer Compliance-Prüfer (Senior Partner Niveau).
        Prüfe den folgenden Fall auf JURISTISCHE COMPLIANCE-RISIKEN, FORMFEHLER, FRISTPROBLEME und PROZEDURALE SCHWACHSTELLEN.

        Berücksichtige insbesondere:
        - Form- und Fristenrecht der ZPO/StPO/VwGO
        - Anhörungsrechte (Art. 103 GG)
        - Beweislastregeln
        - Verfahrensgrundsätze
        - Mögliche Berufungs-/Revisionsgründe

        FALL:
        - Fallname: \(caseEntity.fallname)
        - Rechtsgebiet: \(caseEntity.rechtsgebiet ?? "?")
        - Gericht: \(caseEntity.gericht ?? "?")
        - Status: \(caseEntity.status.rawValue)
        - Instanz: \(caseEntity.instanz.rawValue)
        - Zentrale Rechtsfrage: \(caseEntity.zentraleRechtsfrage ?? "?")
        - Streitwert: \(caseEntity.streitwert.map { "\(Int($0)) €" } ?? "?")

        ARGUMENTE (\(arguments.count)):
        \(arguments.prefix(10).map { "- [\($0.side.rawValue)] \($0.title) (Stärke: \($0.kiStrength ?? $0.strength ?? 5))" }.joined(separator: "\n"))

        BEWEISE (\(evidence.count)):
        \(evidence.prefix(10).map { "- \($0.title) (Gewicht: \($0.kiWeight ?? $0.weight ?? 5))" }.joined(separator: "\n"))

        FRISTEN (\(deadlines.count)):
        \(deadlines.prefix(10).map { "- \($0.title) [\($0.status.rawValue)]" }.joined(separator: "\n"))

        PERSONEN (\(persons.count)):
        \(persons.prefix(10).map { "- \($0.name) (\($0.role.rawValue))" }.joined(separator: "\n"))

        Gib max. 15 KONKRETE Warnungen zurück, sortiert nach Schweregrad. Erfinde keine Vorschriften – wenn unsicher, weglassen.
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "warnings": ["type": "array", "items": ["type": "object",
                    "properties": [
                        "typ": ["type": "string"],
                        "schweregrad": ["type": "string"],
                        "titel": ["type": "string"],
                        "beschreibung": ["type": "string"],
                        "paragraph": ["type": "string"],
                        "empfehlung": ["type": "string"],
                        "betroffenes_objekt_typ": ["type": "string"],
                        "betroffenes_objekt_id":  ["type": "string"]
                    ]
                ]],
                "gesamtbewertung": ["type": "string"],
                "compliance_score": ["type": "number"]
            ]
        ]
        let raw = try await kiProvider.invokeLLM(prompt: prompt, schema: schema)
        let result = try JSONDecoder().decode(ComplianceResult.self,
                                              from: raw.data(using: .utf8) ?? Data())

        // Persistiere als CaseWarning-Records
        for w in result.warnings {
            let typ: WarningType = {
                switch w.typ.lowercased() {
                case "frist":          return .fehlenderBeleg
                case "form":           return .diskrepanz
                case "anhörung", "anhoerung": return .unterstuetzungFehlt
                case "beweis":         return .fehlenderBeleg
                default:               return .widerspruch
                }
            }()
            let sev: WarningSeverity = {
                switch w.schweregrad.lowercased() {
                case "kritisch":  return .kritisch
                case "hoch":      return .hoch
                case "niedrig":   return .niedrig
                default:          return .mittel
                }
            }()
            var cw = CaseWarning(caseId: caseEntity.id, warningType: typ, title: w.titel)
            cw.severity = sev
            cw.warningDescription = w.beschreibung
            cw.suggestion = w.empfehlung
            cw.rsprReference = w.paragraph
            cw.elementType = w.betroffenes_objekt_typ.flatMap { WarningElementType(rawValue: $0) }
            cw.elementId = w.betroffenes_objekt_id
            _ = try? await cloudKit.save(cw)
        }
        return result
    }
}
