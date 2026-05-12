//
//  KIProvider.swift
//  Swift-Pendant zu lib/kiProvider.js. Stellt eine generische
//  `invokeLLM(prompt:schema:)`-Methode bereit, die intern den
//  ClaudeAPIService nutzt und KI-Nutzung in CloudKit loggt.
//

import Foundation
import Combine
import CloudKit

@MainActor
public final class KIProvider: ObservableObject {

    @Published public private(set) var lastOutput: String?
    @Published public var isBusy: Bool = false
    @Published public var lastError: String?

    private let claude  = ClaudeAPIService()
    private let cloudKit = CloudKitService()

    public init() {}

    /// Ruft Claude auf, optional mit erwartetem JSON-Schema.
    /// Loggt jede Anfrage in CloudKit (KIUsageLog).
    @discardableResult
    public func invokeLLM(prompt: String,
                          schema: [String: Any]? = nil,
                          context: String? = nil,
                          caseId: String? = nil) async -> Result<Any, Error> {
        isBusy = true
        defer { isBusy = false }
        do {
            let result: Any
            let outputString: String
            if let schema {
                let dict = try await claude.sendStructured(prompt: prompt, schema: schema)
                result = dict
                outputString = (try? JSONSerialization.data(withJSONObject: dict))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            } else {
                let text = try await claude.sendMessage(prompt: prompt)
                result = text
                outputString = text
            }
            lastOutput = outputString
            await log(prompt: prompt, output: outputString, context: context, caseId: caseId)
            return .success(result)
        } catch {
            lastError = error.localizedDescription
            return .failure(error)
        }
    }

    /// Schreibt einen Log-Eintrag in CloudKit. Fehler werden geschluckt.
    private func log(prompt: String, output: String, context: String?, caseId: String?) async {
        var entry = KIUsageLog(kiFunction: "InvokeLLM", output: output)
        entry.inputSummary = String(prompt.prefix(500))
        entry.model        = ClaudeAPIService.defaultModel
        entry.context      = context
        entry.caseId       = caseId
        entry.timestamp    = Date()
        _ = try? await cloudKit.save(entry)
    }
}
