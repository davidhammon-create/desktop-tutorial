//
//  ClaudeAPIService.swift
//  Direkter HTTPS-Client zur Anthropic Claude API.
//  Endpoint:    https://api.anthropic.com/v1/messages
//  Default-Modell: claude-sonnet-4-6
//  Header:      x-api-key, anthropic-version: 2023-06-01
//

import Foundation
import Combine

public enum ClaudeError: LocalizedError {
    case missingApiKey
    case http(Int, String)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:        return "Kein Anthropic API-Key hinterlegt."
        case .http(let c, let m):   return "HTTP \(c): \(m)"
        case .decoding(let m):      return "Antwort konnte nicht gelesen werden: \(m)"
        }
    }
}

@MainActor
public final class ClaudeAPIService: ObservableObject {

    public static let endpoint   = URL(string: "https://api.anthropic.com/v1/messages")!
    public static let defaultModel = "claude-sonnet-4-6"
    public static let anthropicVersion = "2023-06-01"

    public static let defaultSystem =
        "Du bist ein juristischer KI-Assistent für deutsche und US-Rechtsanwälte. " +
        "Antworte präzise, neutral und auf Basis bekannter Rechtsprechung. " +
        "Bei strukturierter Ausgabe lieferst du ausschließlich gültiges JSON."

    @Published public var lastError: String?
    @Published public var isBusy: Bool = false

    private let apiKeyDefaultsKey = "anthropic.apiKey"
    private let keychainService   = "LegalOS"
    private let keychainAccount   = "anthropic.apiKey"

    public init() {}

    // MARK: - API Key Verwaltung

    /// Lädt den API-Key – bevorzugt aus Keychain, sonst aus UserDefaults.
    public var apiKey: String? {
        get {
            if let data = Keychain.read(service: keychainService, account: keychainAccount),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return UserDefaults.standard.string(forKey: apiKeyDefaultsKey)
        }
    }

    public func setApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let data = trimmed.data(using: .utf8) {
            Keychain.write(service: keychainService, account: keychainAccount, data: data)
        }
        UserDefaults.standard.set(trimmed, forKey: apiKeyDefaultsKey)
    }

    public func clearApiKey() {
        Keychain.delete(service: keychainService, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: apiKeyDefaultsKey)
    }

    // MARK: - Calls

    /// Schickt einen Prompt an Claude und gibt den reinen Text der Antwort zurück.
    public func sendMessage(prompt: String,
                            system: String = ClaudeAPIService.defaultSystem,
                            model: String = ClaudeAPIService.defaultModel,
                            maxTokens: Int = 4096,
                            temperature: Double = 0.4) async throws -> String {
        let body: [String: Any] = [
            "model":      model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "system":     system,
            "messages":   [["role": "user", "content": prompt]]
        ]
        let data = try await perform(body: body)
        return try extractText(data)
    }

    /// Wie `sendMessage`, fordert aber strukturiertes JSON gemäß `schema` zurück.
    /// Realisiert wird das via System-Prompt + Schema-Instruction (Claude unterstützt
    /// kein offizielles response_format, aber strict-JSON funktioniert zuverlässig).
    public func sendStructured(prompt: String,
                               schema: [String: Any],
                               system: String = ClaudeAPIService.defaultSystem,
                               model: String = ClaudeAPIService.defaultModel) async throws -> [String: Any] {
        let schemaJSON = (try? JSONSerialization.data(withJSONObject: schema, options: [.prettyPrinted])).flatMap {
            String(data: $0, encoding: .utf8)
        } ?? "{}"
        let augmentedSystem = system + """

        AUSGABE-FORMAT (PFLICHT):
        Antworte ausschließlich mit gültigem JSON, das exakt diesem Schema entspricht.
        Keine Fließtexte, keine Code-Fences, kein Kommentar.
        Schema:
        \(schemaJSON)
        """
        let body: [String: Any] = [
            "model":      model,
            "max_tokens": 4096,
            "temperature": 0.2,
            "system":     augmentedSystem,
            "messages":   [["role": "user", "content": prompt]]
        ]
        let data = try await perform(body: body)
        let raw = try extractText(data)
        // Code-Fences entfernen, falls vorhanden.
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = cleaned.data(using: .utf8),
              let object   = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ClaudeError.decoding("Antwort war kein JSON-Objekt")
        }
        return object
    }

    // MARK: - Internal

    private func perform(body: [String: Any]) async throws -> Data {
        guard let key = apiKey, !key.isEmpty else { throw ClaudeError.missingApiKey }
        var req = URLRequest(url: Self.endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        isBusy = true
        defer { isBusy = false }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "(keine Antwort)"
            throw ClaudeError.http(http.statusCode, msg)
        }
        return data
    }

    /// Extrahiert den ersten Text-Block aus der Claude-Antwort.
    private func extractText(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw ClaudeError.decoding("Ungültige Top-Level-Struktur")
        }
        let texts = content.compactMap { block -> String? in
            guard let type = block["type"] as? String, type == "text" else { return nil }
            return block["text"] as? String
        }
        guard let joined = texts.joined(separator: "\n").nilIfEmpty else {
            throw ClaudeError.decoding("Keine Text-Blöcke in Antwort.")
        }
        return joined
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
