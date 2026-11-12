import Foundation
import FenlynineOSKern
enum KIModus: String, CaseIterable, Codable {
    case base44 = "base44"
    case appleIntelligence = "apple_intelligence"
    case offline = "offline"
    var bezeichnung: String {
        switch self {
        case .base44:  return "Base44 Cloud-KI (Claude Sonnet 4.6)"
        case .appleIntelligence: return "Apple Intelligence (on-device, automatisch aktuell)"
        case .offline: return "Offline-KI (Ollama / LM Studio)"
        }
    }
}
struct KIKonfiguration {
    var modus:         KIModus = .offline
    var offlineURL:    String  = "http://127.0.0.1:11434/api/chat"
    var offlineModell: String  = "llama3"
    var modellOverride: String? = nil
    static var shared: KIKonfiguration = {
        let d = UserDefaults.standard
        var c = KIKonfiguration()
        if d.object(forKey: "ki_modus_migration_offline_v1") == nil {
            if d.string(forKey: "ki_modus") == nil || !DatenResidenz.darfCloud {
                c.modus = AppleIntelligenceService.status.ok ? .appleIntelligence : .offline
                d.set(c.modus.rawValue, forKey: "ki_modus")
            }
            d.set(true, forKey: "ki_modus_migration_offline_v1")
        }
        if let m = d.string(forKey: "ki_modus"),         let km = KIModus(rawValue: m) { c.modus = km }
        if let u = d.string(forKey: "ki_offline_url")   { c.offlineURL = u }
        if let mo = d.string(forKey: "ki_offline_modell"){ c.offlineModell = mo }
        if let o = d.string(forKey: "ki_modell_override"), !o.isEmpty { c.modellOverride = o }
        if (try? FenlynineOSSicherheitsHaertung.validiereOfflineURL(c.offlineURL)) == nil {
            c.offlineURL = "http://127.0.0.1:11434/api/chat"
        }
        return c
    }()
    func save() {
        let d = UserDefaults.standard
        d.set(modus.rawValue, forKey: "ki_modus")
        d.set(offlineURL,     forKey: "ki_offline_url")
        d.set(offlineModell,  forKey: "ki_offline_modell")
        if let o = modellOverride, !o.isEmpty {
            d.set(o, forKey: "ki_modell_override")
        } else {
            d.removeObject(forKey: "ki_modell_override")
        }
        _ = modulAnbindungen
        KIKonfiguration.shared = self
    }
}
struct LLMRequest: Encodable {
    let prompt: String
    let response_json_schema: AnyCodable?
    let file_urls: [String]?
    let add_context_from_internet: Bool?
    let model: String?
    init(
        prompt: String,
        schema: Any? = nil,
        fileUrls: [String]? = nil,
        webContext: Bool? = nil,
        model: String? = nil
    ) {
        self.prompt                    = prompt
        self.response_json_schema      = schema.map { AnyCodable($0) }
        self.file_urls                 = fileUrls
        self.add_context_from_internet = webContext
        self.model                     = model
    }
}
actor LLMService {
    static let shared = LLMService()
    private let client = Base44Client.shared
    func invoke<T: Decodable>(
        prompt: String,
        schema: Any? = nil,
        fileUrls: [String]? = nil,
        webContext: Bool = false,
        model: String? = nil,
        transparenzLabel: String? = nil,
        logCaseId: String? = nil,
        logKiName: String? = nil
    ) async throws -> T {
        guard await KontoAbrechnung.kiErlaubt() else {
            throw Base44Error.serverError(KontoAbrechnung.sperrHinweis)
        }
        let slot = KIModulSlot.aus(kiName: logKiName)
        let eff = KIKonfiguration.shared.aufgeloest(fuer: slot)
        let resolvedModel: String? = model ?? eff.modell
        var logModel = resolvedModel ?? "automatic"
        let residenz = DatenResidenz.effektiverModus(fuer: eff.modus)
        DatenResidenz.protokolliere(angefragt: eff.modus, entschieden: residenz.modus, umleitung: residenz.umleitung)
        // Veredelung: Rechtsordnung, Rechenkern-Fakten, passendes Rechtswissen und
        // die Arbeitsmethode des Moduls -- für jedes Modul gleich, an einer Stelle.
        let angereichert = await anreichern(prompt, slot: slot, caseId: logCaseId, wissenLimit: 4)
        var pseudo = await KIVeredelung.pseudonymisierer(fuer: residenz.modus)
        let zuSenden = pseudonymisiert(angereichert, mit: &pseudo)
        let result: T
        do {
            switch residenz.modus {
            case .offline:
                logModel = eff.offlineModell
                result = try await invokeOffline(prompt: zuSenden, schema: schema, fileUrls: fileUrls, model: eff.offlineModell, url: eff.offlineURL)
            case .appleIntelligence:
                logModel = AppleIntelligenceService.modellLabel
                result = try await AppleIntelligenceService.antwortJSON(prompt: zuSenden, schema: schema)
            case .base44:
                result = try await invokeBase44(prompt: zuSenden, schema: schema, fileUrls: fileUrls, webContext: webContext, model: resolvedModel, pseudo: pseudo)
            }
            SelbstreparaturAgent.meldeKIErfolg(modus: residenz.modus)
        } catch {
            SelbstreparaturAgent.meldeKIFehler(modus: residenz.modus, modul: logKiName ?? "KI", fehler: error)
            throw error
        }
        await KIVeredelung.pruefe(result, quellen: angereichert, modul: logKiName ?? "KI",
                                  modell: logModel, pseudonymisierteAngaben: pseudo?.anzahl ?? 0)
        let ausgabeZeichen = (result as? String)?.count ?? 1600
        await KontoAbrechnung.verbuche(
            modul: logKiName ?? "KI",
            aktion: "Strukturierte Analyse",
            modell: logModel,
            tokensEin: KontoAbrechnung.geschaetzteTokens(zeichen: zuSenden.count),
            tokensAus: KontoAbrechnung.geschaetzteTokens(zeichen: ausgabeZeichen)
        )
        if let logCaseId, let logKiName {
            if let codable = result as? AnyCodable {
                await KIProtokollService.logResult(caseId: logCaseId, kiName: logKiName, eingabe: prompt, result: codable, modell: logModel)
            } else if let text = result as? String {
                await KIProtokollService.log(caseId: logCaseId, kiName: logKiName, eingabe: prompt, ausgabe: text, modell: logModel)
            } else {
                await KIProtokollService.log(caseId: logCaseId, kiName: logKiName, eingabe: prompt, ausgabe: "Strukturierte KI-Antwort", modell: logModel)
            }
        }
        return result
    }
    func invokeObject(
        prompt: String,
        schema: Any? = nil,
        fileUrls: [String]? = nil,
        webContext: Bool = false,
        model: String? = nil,
        logCaseId: String? = nil,
        logKiName: String? = nil
    ) async throws -> [String: Any] {
        let result: AnyCodable = try await invoke(
            prompt: prompt,
            schema: schema,
            fileUrls: fileUrls,
            webContext: webContext,
            model: model,
            logCaseId: logCaseId,
            logKiName: logKiName
        )
        return try KIJson.requireObject(result)
    }
    func invokeText(
        prompt: String,
        fileUrls: [String]? = nil,
        webContext: Bool = false,
        model: String? = nil,
        logCaseId: String? = nil,
        logKiName: String? = nil
    ) async throws -> String {
        guard await KontoAbrechnung.kiErlaubt() else {
            throw Base44Error.serverError(KontoAbrechnung.sperrHinweis)
        }
        let slot = KIModulSlot.aus(kiName: logKiName)
        let eff = KIKonfiguration.shared.aufgeloest(fuer: slot)
        let resolvedModel: String? = model ?? eff.modell
        var logModel = resolvedModel ?? "automatic"
        let residenz = DatenResidenz.effektiverModus(fuer: eff.modus)
        DatenResidenz.protokolliere(angefragt: eff.modus, entschieden: residenz.modus, umleitung: residenz.umleitung)
        let angereichert = await anreichern(prompt, slot: slot, caseId: logCaseId, wissenLimit: 8)
        var pseudo = await KIVeredelung.pseudonymisierer(fuer: residenz.modus)
        let zuSenden = pseudonymisiert(angereichert, mit: &pseudo)
        let text: String
        do {
            switch residenz.modus {
            case .offline:
                logModel = eff.offlineModell
                text = try await invokeOfflineText(prompt: zuSenden, url: eff.offlineURL, model: eff.offlineModell)
            case .appleIntelligence:
                logModel = AppleIntelligenceService.modellLabel
                text = try await AppleIntelligenceService.antwort(prompt: zuSenden)
            case .base44:
                text = try await invokeBase44Text(prompt: zuSenden, fileUrls: fileUrls, webContext: webContext, model: resolvedModel, pseudo: pseudo)
            }
            SelbstreparaturAgent.meldeKIErfolg(modus: residenz.modus)
        } catch {
            SelbstreparaturAgent.meldeKIFehler(modus: residenz.modus, modul: logKiName ?? "KI", fehler: error)
            throw error
        }
        await KIVeredelung.pruefe(text, quellen: angereichert, modul: logKiName ?? "KI",
                                  modell: logModel, pseudonymisierteAngaben: pseudo?.anzahl ?? 0)
        await KontoAbrechnung.verbuche(
            modul: logKiName ?? "KI",
            aktion: "Text-Anfrage",
            modell: logModel,
            tokensEin: KontoAbrechnung.geschaetzteTokens(zeichen: zuSenden.count),
            tokensAus: KontoAbrechnung.geschaetzteTokens(zeichen: text.count)
        )
        if let logCaseId, let logKiName {
            await KIProtokollService.log(caseId: logCaseId, kiName: logKiName, eingabe: prompt, ausgabe: text, modell: logModel)
        }
        return text
    }
    /// Baut den Prompt für alle Module gleich auf: Rechtsordnung, verbindliche
    /// Rechenkern-Fakten, passendes lokales Rechtswissen, Arbeitsmethode, Aufgabe.
    private func anreichern(_ prompt: String, slot: KIModulSlot, caseId: String?,
                            wissenLimit: Int) async -> String {
        let fakten = await KIVeredelung.rechenkernFakten(caseId: caseId)
        let wissen = await KIVeredelung.rechtswissen(fuer: prompt, limit: wissenLimit)
        let teile = [Rechtsordnung.promptKopf, fakten, wissen, KIPromptKit.methodik(fuer: slot), prompt]
        return teile
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n---\n\n")
    }
    /// Ersetzt geschützte Angaben durch Platzhalter, wenn ein Pseudonymisierer
    /// übergeben wurde (also nur, wenn die Anfrage das Gerät verlässt).
    private func pseudonymisiert(_ text: String, mit pseudo: inout Pseudonymisierer?) -> String {
        guard var p = pseudo else { return text }
        let ersetzt = p.pseudonymisiere(text)
        pseudo = p
        return p.anzahl > 0 ? ersetzt + "\n\n" + Pseudonymisierer.prompthinweis : ersetzt
    }
    private func ensureCloudConfig() async {
        await client.ensureReady()
    }
    private func invokeBase44<T: Decodable>(
        prompt: String,
        schema: Any?,
        fileUrls: [String]?,
        webContext: Bool,
        model: String?,
        pseudo: Pseudonymisierer? = nil
    ) async throws -> T {
        await ensureCloudConfig()
        let sanitized = KIFileURLs.sanitize(fileUrls)
        do {
            return try await performBase44Invoke(
                prompt: prompt, schema: schema, fileUrls: sanitized,
                webContext: webContext, model: model, pseudo: pseudo
            )
        } catch Base44Error.httpError(400, let msg) where KIFileURLs.isInvalidAttachmentError(msg) && sanitized != nil {
            return try await performBase44Invoke(
                prompt: prompt + "\n\n[Hinweis: Datei-Anhänge konnten nicht geladen werden — nutze den Textkontext oben.]",
                schema: schema, fileUrls: nil,
                webContext: webContext, model: model, pseudo: pseudo
            )
        }
    }
    private func performBase44Invoke<T: Decodable>(
        prompt: String,
        schema: Any?,
        fileUrls: [String]?,
        webContext: Bool,
        model: String?,
        pseudo: Pseudonymisierer? = nil
    ) async throws -> T {
        let url = Base44Config.load().integrationURL("InvokeLLM")
        let req = LLMRequest(
            prompt: KIPromptKit.wrap(prompt),
            schema: schema,
            fileUrls: fileUrls,
            webContext: webContext ? true : nil,
            model: model
        )
        let data = KIVeredelung.wiederhergestellt(try await client.postRaw(url, body: req), mit: pseudo)
        return try InvokeLLMResponseParser.decode(data, as: T.self)
    }
    private func invokeBase44Text(
        prompt: String,
        fileUrls: [String]?,
        webContext: Bool,
        model: String?,
        pseudo: Pseudonymisierer? = nil
    ) async throws -> String {
        await ensureCloudConfig()
        let sanitized = KIFileURLs.sanitize(fileUrls)
        do {
            return try await performBase44InvokeText(
                prompt: prompt, fileUrls: sanitized, webContext: webContext, model: model, pseudo: pseudo
            )
        } catch Base44Error.httpError(400, let msg) where KIFileURLs.isInvalidAttachmentError(msg) && sanitized != nil {
            return try await performBase44InvokeText(
                prompt: prompt + "\n\n[Hinweis: Datei-Anhänge nicht verfügbar — Textkontext nutzen.]",
                fileUrls: nil, webContext: webContext, model: model, pseudo: pseudo
            )
        }
    }
    private func performBase44InvokeText(
        prompt: String,
        fileUrls: [String]?,
        webContext: Bool,
        model: String?,
        pseudo: Pseudonymisierer? = nil
    ) async throws -> String {
        let url = Base44Config.load().integrationURL("InvokeLLM")
        let req = LLMRequest(prompt: KIPromptKit.wrap(prompt), fileUrls: fileUrls, webContext: webContext ? true : nil, model: model)
        let data = KIVeredelung.wiederhergestellt(try await client.postRaw(url, body: req), mit: pseudo)
        return try InvokeLLMResponseParser.decodeText(data)
    }
    func extractDataFromFile(fileUrl: String, jsonSchema: Any? = nil) async throws -> AnyCodable? {
        guard await KontoAbrechnung.kiErlaubt() else {
            throw Base44Error.serverError(KontoAbrechnung.sperrHinweis)
        }
        try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Dokument-OCR (Cloud)")
        guard KIFileURLs.isValidAttachmentURL(fileUrl) else {
            throw Base44Error.serverError("Ungültige Datei-URL. Bitte Dokument in Schritt 0 erneut hochladen.")
        }
        struct ExtractRequest: Encodable {
            let file_url: String
            let json_schema: AnyCodable?
        }
        await ensureCloudConfig()
        let url = Base44Config.load().integrationURL("ExtractDataFromUploadedFile")
        let req = ExtractRequest(
            file_url: fileUrl,
            json_schema: jsonSchema.map { AnyCodable($0) }
        )
        let data = try await client.postRaw(url, body: req)
        let response = try InvokeLLMResponseParser.decode(data, as: AnyCodable.self)
        let pauschale = await MainActor.run { KontoStore.shared.preise.dokumentAnalyse }
        await KontoAbrechnung.verbuche(
            modul: "Dokumente",
            aktion: "Dokument-Analyse (OCR)",
            modell: "extract",
            tokensEin: 0, tokensAus: 0,
            pauschale: pauschale
        )
        if let dict = response.dictValue {
            if let out = dict["output"] { return AnyCodable(out) }
            if let res = dict["result"] { return AnyCodable(res) }
        }
        return response
    }
    private func invokeOffline<T: Decodable>(
        prompt: String,
        schema: Any?,
        fileUrls: [String]?,
        model: String,
        url: String
    ) async throws -> T {
        let content = try await invokeOfflineText(
            prompt: KIPromptKit.wrap(prompt) + (fileUrls?.isEmpty == false ? "\n\n[Hinweis: \(fileUrls!.count) Datei(en) wurden hochgeladen]" : ""),
            url: url,
            model: model,
            jsonSchema: schema
        )
        // Lokale Modelle liefern oft Markdown-Zäune, einen Einleitungssatz oder ein
        // Komma zu viel. Erst reparieren, dann EINMAL gezielt nachfordern.
        if let data = JSONReparatur.extrahiere(content),
           let wert = try? JSONDecoder.base44.decode(T.self, from: data) {
            return wert
        }
        let zweiter = try await invokeOfflineText(
            prompt: "Deine letzte Antwort war kein gültiges JSON. Gib dieselbe Antwort erneut aus, "
                + "ausschließlich als ein gültiges JSON-Objekt nach dem Schema, ohne Text davor oder danach.\n\n"
                + "LETZTE ANTWORT:\n" + String(content.prefix(6000)),
            url: url,
            model: model,
            jsonSchema: schema
        )
        guard let data = JSONReparatur.extrahiere(zweiter) else {
            throw Base44Error.decodingError(NSError(domain: "LLMService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Die lokale KI hat auch im zweiten Versuch kein gültiges JSON geliefert. Bitte erneut versuchen oder ein größeres Modell wählen."]))
        }
        return try JSONDecoder.base44.decode(T.self, from: data)
    }
    private func invokeOfflineText(
        prompt: String,
        url urlString: String,
        model: String,
        jsonSchema: Any? = nil
    ) async throws -> String {
        let url: URL
        do {
            url = try FenlynineOSSicherheitsHaertung.validiereOfflineURL(urlString)
        } catch {
            throw Base44Error.serverError(error.localizedDescription)
        }
        let systemPrompt: String
        if let schema = jsonSchema {
            systemPrompt = "Du bist ein juristischer KI-Assistent. Antworte AUSSCHLIESSLICH mit validem JSON. Schema: \(String(describing: schema))"
        } else {
            systemPrompt = "Du bist ein juristischer KI-Assistent für Rechtsanwälte."
        }
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": prompt]
            ],
            "stream": false,
            "format": jsonSchema != nil ? "json" : ""
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 120
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw Base44Error.httpError(
                (response as? HTTPURLResponse)?.statusCode ?? 0,
                "Offline-KI-Fehler"
            )
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Base44Error.invalidResponse
        }
        return (json["message"] as? [String: Any])?["content"] as? String
            ?? (json["choices"] as? [[String: Any]])?.first.flatMap { ($0["message"] as? [String: Any])?["content"] as? String }
            ?? json["response"] as? String
            ?? ""
    }
    func uploadFile(data: Data, fileName: String, mimeType: String) async throws -> String {
        try FenlynineOSSecurity.validateDataSize(data.count)
        try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Dokument-Upload")
        await ensureCloudConfig()
        let config = Base44Config.load()
        let url = config.integrationURL("UploadFile")
        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = config.accessToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if !config.appId.isEmpty {
            req.setValue(config.appId, forHTTPHeaderField: "X-App-Id")
        }
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(FenlynineOSSecurity.sanitizedMultipartFileName(fileName))\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        let (responseData, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder.base44.decode(Base44ErrorResponse.self, from: responseData))?.message ?? "Upload fehlgeschlagen"
            throw Base44Error.httpError(http.statusCode, msg)
        }
        let result = try JSONDecoder.base44.decode([String: AnyCodable].self, from: responseData)
        guard let fileUrl = result["url"]?.stringValue ?? result["file_url"]?.stringValue,
              KIFileURLs.isValidAttachmentURL(fileUrl) else {
            throw Base44Error.serverError("Upload ohne gültige Datei-URL — Base44-Konfiguration prüfen.")
        }
        return fileUrl
    }
}
