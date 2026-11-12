import Foundation
struct Base44Config {
    var appId: String
    var appBaseUrl: String          // z.B. "https://app.base44.com"
    var accessToken: String?
    var functionsVersion: String?
    static func load() -> Base44Config {
        FenlynineOSKeychain.migrateLegacySecretsIfNeeded()
        let d = UserDefaults.standard
        return Base44Config(
            appId:             d.string(forKey: "base44_app_id") ?? "",
            appBaseUrl:        d.string(forKey: "base44_app_base_url") ?? "https://app.base44.com",
            accessToken:       FenlynineOSKeychain.get(account: .base44AccessToken),
            functionsVersion:  d.string(forKey: "base44_functions_version")
        )
    }
    private var apiBase: String { "\(appBaseUrl)/api" }
    func entityURL(_ entityName: String) -> URL {
        URL(string: "\(apiBase)/apps/\(appId)/entities/\(entityName)")!
    }
    func entityItemURL(_ entityName: String, id: String) -> URL {
        URL(string: "\(apiBase)/apps/\(appId)/entities/\(entityName)/\(id)")!
    }
    var meURL: URL {
        URL(string: "\(apiBase)/apps/\(appId)/entities/User/me")!
    }
    func functionURL(_ name: String) -> URL {
        URL(string: "\(apiBase)/apps/\(appId)/functions/\(name)")!
    }
    func integrationURL(_ endpoint: String) -> URL {
        URL(string: "\(apiBase)/apps/\(appId)/integration-endpoints/Core/\(endpoint)")!
    }
    func authURL(_ method: String) -> URL {
        URL(string: "\(apiBase)/apps/\(appId)/auth/\(method)")!
    }
}
enum Base44Error: LocalizedError {
    case networkError(Error)
    case httpError(Int, String)
    case decodingError(Error)
    case unauthorized
    case notFound
    case serverError(String)
    case invalidResponse
    var errorDescription: String? {
        switch self {
        case .networkError(let e):   return "Netzwerkfehler: \(e.localizedDescription)"
        case .httpError(let c, let m): return "HTTP \(c): \(m)"
        case .decodingError(let e):  return "Dekodierung: \(e.localizedDescription)"
        case .unauthorized:          return "Nicht autorisiert. Bitte neu anmelden."
        case .notFound:              return "Nicht gefunden."
        case .serverError(let m):    return "Serverfehler: \(m)"
        case .invalidResponse:       return "Ungültige Antwort."
        }
    }
}
actor Base44Client {
    static let shared = Base44Client()
    private var session: URLSession
    private var config: Base44Config
    init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 300
        cfg.timeoutIntervalForResource = 600
        cfg.waitsForConnectivity = true
        self.session = URLSession(configuration: cfg)
        self.config  = Base44Config.load()
    }
    func updateConfig(_ newConfig: Base44Config) {
        self.config = newConfig
        let d = UserDefaults.standard
        d.set(newConfig.appId,      forKey: "base44_app_id")
        d.set(newConfig.appBaseUrl, forKey: "base44_app_base_url")
        if let t = newConfig.accessToken, !t.isEmpty {
            FenlynineOSKeychain.set(t, account: .base44AccessToken)
        } else {
            FenlynineOSKeychain.delete(account: .base44AccessToken)
        }
    }
    func syncConfigFromStorage() {
        config = Base44Config.load()
    }
    func ensureReady() async {
        syncConfigFromStorage()
        var cfg = Base44Config.load()
        if cfg.appId.isEmpty {
            cfg.appId = AppDefaults.base44AppId
            cfg.appBaseUrl = AppDefaults.base44BaseUrl
        }
        if (cfg.accessToken ?? "").isEmpty,
           let token = FenlynineOSKeychain.get(account: .base44AccessToken),
           !token.isEmpty {
            cfg.accessToken = token
        }
        updateConfig(cfg)
    }
    var currentConfig: Base44Config { config }
    private func assertCloudErlaubt() throws {
        guard DatenResidenz.darfCloud else {
            throw Base44Error.serverError(
                "Cloud-Zugriff gesperrt (Residenz: \(DatenResidenz.region.titel)). " +
                "Mandatsdaten bleiben auf diesem Mac — Base44/API deaktiviert."
            )
        }
    }
    func get<T: Decodable>(_ url: URL, queryItems: [URLQueryItem] = []) async throws -> T {
        try assertCloudErlaubt()
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            comps.queryItems = (comps.queryItems ?? []) + queryItems
        }
        return try await perform(buildRequest(url: comps.url!, method: "GET"))
    }
    func post<T: Decodable>(_ url: URL, body: Encodable) async throws -> T {
        let data = try await postRaw(url, body: body)
        do {
            return try JSONDecoder.base44.decode(T.self, from: data)
        } catch {
            throw Base44Error.decodingError(error)
        }
    }
    func postRaw(_ url: URL, body: Encodable) async throws -> Data {
        try assertCloudErlaubt()
        var req = buildRequest(url: url, method: "POST")
        req.httpBody = try JSONEncoder.base44.encode(body)
        var letzterFehler: Error?
        for versuch in 0..<2 {
            do {
                let (data, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse else {
                    throw Base44Error.invalidResponse
                }
                switch http.statusCode {
                case 200...299:
                    return data
                case 401: throw Base44Error.unauthorized
                case 404: throw Base44Error.notFound
                case 400...499:
                    let msg = (try? JSONDecoder.base44.decode(Base44ErrorResponse.self, from: data))?.message ?? "Ungültige Anfrage"
                    throw Base44Error.httpError(http.statusCode, msg)
                default:
                    let msg = (try? JSONDecoder.base44.decode(Base44ErrorResponse.self, from: data))?.message ?? "Serverfehler"
                    throw Base44Error.serverError(msg)
                }
            } catch let e as Base44Error {
                throw e
            } catch {
                letzterFehler = error
                if versuch == 0, Self.istTransient(error) {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    continue
                }
                throw Base44Error.networkError(error)
            }
        }
        throw Base44Error.networkError(letzterFehler ?? URLError(.unknown))
    }
    private static func istTransient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .networkConnectionLost, .cannotConnectToHost, .cannotFindHost,
             .dnsLookupFailed, .notConnectedToInternet, .resourceUnavailable:
            return true
        default:
            return false
        }
    }
    func put<T: Decodable>(_ url: URL, body: Encodable) async throws -> T {
        try assertCloudErlaubt()
        var req = buildRequest(url: url, method: "PUT")
        req.httpBody = try JSONEncoder.base44.encode(body)
        return try await perform(req)
    }
    func delete(_ url: URL) async throws {
        try assertCloudErlaubt()
        let req = buildRequest(url: url, method: "DELETE")
        let _: EmptyResponse = try await perform(req)
    }
    private func buildRequest(url: URL, method: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = config.accessToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if !config.appId.isEmpty {
            req.setValue(config.appId, forHTTPHeaderField: "X-App-Id")
        }
        return req
    }
    private func perform<T: Decodable>(_ req: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw Base44Error.invalidResponse
            }
            switch http.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder.base44.decode(T.self, from: data)
                } catch {
                    throw Base44Error.decodingError(error)
                }
            case 401: throw Base44Error.unauthorized
            case 404: throw Base44Error.notFound
            case 400...499:
                let msg = (try? JSONDecoder.base44.decode(Base44ErrorResponse.self, from: data))?.message ?? "Ungültige Anfrage"
                throw Base44Error.httpError(http.statusCode, msg)
            default:
                let msg = (try? JSONDecoder.base44.decode(Base44ErrorResponse.self, from: data))?.message ?? "Serverfehler"
                throw Base44Error.serverError(msg)
            }
        } catch let e as Base44Error { throw e
        } catch { throw Base44Error.networkError(error) }
    }
}
struct EmptyResponse: Codable {}
struct Base44ErrorResponse: Codable {
    let message: String
    let code: String?
}
extension JSONEncoder {
    static let base44: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}
extension JSONDecoder {
    static let base44: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            let fmts: [ISO8601DateFormatter] = [
                { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
                { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()
            ]
            for fmt in fmts { if let date = fmt.date(from: s) { return date } }
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; df.locale = Locale(identifier: "en_US_POSIX")
            if let date = df.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Kein gültiges Datum: \(s)")
        }
        return d
    }()
}
