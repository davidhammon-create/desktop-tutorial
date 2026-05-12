//
//  EvidenceLinkingService.swift
//  KI-basiertes Verknüpfen von Beweisen mit Argumenten.
//  1:1 Port von base44/functions/linkEvidenceToArguments/entry.ts.
//

import Foundation

@MainActor
public final class EvidenceLinkingService: ObservableObject {
    private let kiProvider: KIProvider
    private let cloudKit:   CloudKitService
    public init(kiProvider: KIProvider, cloudKit: CloudKitService) {
        self.kiProvider = kiProvider; self.cloudKit = cloudKit
    }

    public struct Mapping: Codable, Hashable {
        public var evidenceId: String
        public var argumentId: String
        public var begruendung: String
    }

    public func linkAll(arguments: [Argument], evidence: [Evidence]) async throws -> [Mapping] {
        guard !arguments.isEmpty, !evidence.isEmpty else { return [] }

        let argList = arguments.map { "- ID:\($0.id) | [\($0.side.rawValue)] \($0.title): \($0.argDescription ?? "")" }
            .joined(separator: "\n")
        let evList = evidence.map { "- ID:\($0.id) | \($0.title) (\($0.type ?? "?")): \($0.evidenceDescription ?? "")" }
            .joined(separator: "\n")

        let prompt = """
        Ordne jedes Beweismittel den passenden Argumenten zu (KEIN Argument darf erfunden sein,
        nutze nur die unten gelisteten IDs). Gib eine Liste von Zuordnungen zurück.

        ARGUMENTE:
        \(argList)

        BEWEISE:
        \(evList)

        Pro Beweis maximal 3 Argument-Verknüpfungen. Begründung in 1 Satz.
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "mappings": ["type": "array", "items": ["type": "object",
                    "properties": [
                        "evidenceId": ["type": "string"],
                        "argumentId": ["type": "string"],
                        "begruendung": ["type": "string"]
                    ]
                ]]
            ]
        ]

        struct Wrapper: Codable { var mappings: [Mapping] }
        let raw = try await kiProvider.invokeLLM(prompt: prompt, schema: schema)
        let parsed = (try? JSONDecoder().decode(Wrapper.self,
                                                from: raw.data(using: .utf8) ?? Data()))?.mappings ?? []

        // Persistiere: setze Evidence.argumentId und ergänze Argument.evidenceIds
        for m in parsed {
            if var ev = evidence.first(where: { $0.id == m.evidenceId }) {
                ev.argumentId = m.argumentId
                _ = try? await cloudKit.save(ev)
            }
            if var arg = arguments.first(where: { $0.id == m.argumentId }) {
                if !arg.evidenceIds.contains(m.evidenceId) {
                    arg.evidenceIds.append(m.evidenceId)
                    _ = try? await cloudKit.save(arg)
                }
            }
        }
        return parsed
    }
}
