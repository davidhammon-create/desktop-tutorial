import Foundation
struct CloudChatNachricht: Codable, Identifiable, Hashable {
    var id: String
    var rolle: String          // user | assistant | system
    var inhalt: String
    var zeitstempel: Date
    var transparenz: String?
    var caseContext: String?
    init(id: String = UUID().uuidString, rolle: String, inhalt: String, zeitstempel: Date = .init(), transparenz: String? = nil, caseContext: String? = nil) {
        self.id = id
        self.rolle = rolle
        self.inhalt = inhalt
        self.zeitstempel = zeitstempel
        self.transparenz = transparenz
        self.caseContext = caseContext
    }
}
struct CloudChatKonversation: Codable, Identifiable, Hashable {
    var id: String
    var agentName: String
    var titel: String
    var erstelltAm: Date
    var aktualisiertAm: Date
    var caseId: String?
    var remoteConversationId: String?
    var nachrichten: [CloudChatNachricht]
    var syncedToICloud: Bool
    var syncedToBase44: Bool
    init(
        id: String = UUID().uuidString,
        agentName: String,
        titel: String,
        erstelltAm: Date = .init(),
        aktualisiertAm: Date = .init(),
        caseId: String? = nil,
        remoteConversationId: String? = nil,
        nachrichten: [CloudChatNachricht] = [],
        syncedToICloud: Bool = false,
        syncedToBase44: Bool = false
    ) {
        self.id = id
        self.agentName = agentName
        self.titel = titel
        self.erstelltAm = erstelltAm
        self.aktualisiertAm = aktualisiertAm
        self.caseId = caseId
        self.remoteConversationId = remoteConversationId
        self.nachrichten = nachrichten
        self.syncedToICloud = syncedToICloud
        self.syncedToBase44 = syncedToBase44
    }
}
@Observable
@MainActor
final class ChatCloudStore {
    static let shared = ChatCloudStore()
    private(set) var konversationen: [CloudChatKonversation] = []
    private(set) var iCloudVerfuegbar = false
    private(set) var letzterSync: Date?
    private(set) var statusHinweis: String = "bereit"
    private let indexName = "index.json"
    private var speicherTask: Task<Void, Never>?
    private init() {
        laden()
        Task { await syncICloud() }
    }
    func konversationen(fuer agent: String) -> [CloudChatKonversation] {
        konversationen
            .filter { $0.agentName == agent }
            .sorted { $0.aktualisiertAm > $1.aktualisiertAm }
    }
    @discardableResult
    func neu(agentName: String, titel: String, caseId: String? = nil, remoteId: String? = nil) -> CloudChatKonversation {
        let k = CloudChatKonversation(
            agentName: agentName,
            titel: titel,
            caseId: caseId,
            remoteConversationId: remoteId,
            syncedToBase44: remoteId != nil
        )
        konversationen.insert(k, at: 0)
        scheduleSpeichern()
        return k
    }
    func speichereNachrichten(konversationId: String, nachrichten: [CloudChatNachricht], remoteId: String? = nil) {
        guard let idx = konversationen.firstIndex(where: { $0.id == konversationId }) else { return }
        konversationen[idx].nachrichten = nachrichten
        konversationen[idx].aktualisiertAm = .init()
        if let remoteId { konversationen[idx].remoteConversationId = remoteId; konversationen[idx].syncedToBase44 = true }
        scheduleSpeichern()
    }
    func aktualisiere(id: String, mutate: (inout CloudChatKonversation) -> Void) {
        guard let idx = konversationen.firstIndex(where: { $0.id == id }) else { return }
        mutate(&konversationen[idx])
        konversationen[idx].aktualisiertAm = .init()
        scheduleSpeichern()
    }
    func loesche(id: String) {
        konversationen.removeAll { $0.id == id }
        scheduleSpeichern()
        loescheDatei(id: id)
    }
    private var localRoot: URL {
        let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FenlynineOS/ChatCloud", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
    private var iCloudRoot: URL? {
        guard let ubi = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let docs = ubi.appendingPathComponent("Documents/FenlynineOS/ChatCloud", isDirectory: true)
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs
    }
    private func laden() {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let indexURL = localRoot.appendingPathComponent(indexName)
        if let data = try? Data(contentsOf: indexURL),
           let list = try? dec.decode([CloudChatKonversation].self, from: data) {
            konversationen = list
        }
        if let cloud = iCloudRoot?.appendingPathComponent(indexName),
           let data = try? Data(contentsOf: cloud),
           let remote = try? dec.decode([CloudChatKonversation].self, from: data) {
            merge(remote)
            iCloudVerfuegbar = true
        } else {
            iCloudVerfuegbar = FileManager.default.ubiquityIdentityToken != nil
        }
    }
    private func merge(_ remote: [CloudChatKonversation]) {
        var map = Dictionary(uniqueKeysWithValues: konversationen.map { ($0.id, $0) })
        for r in remote {
            if let lokal = map[r.id] {
                if r.aktualisiertAm > lokal.aktualisiertAm { map[r.id] = r }
            } else {
                map[r.id] = r
            }
        }
        konversationen = Array(map.values).sorted { $0.aktualisiertAm > $1.aktualisiertAm }
    }
    private func scheduleSpeichern() {
        speicherTask?.cancel()
        speicherTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.persistieren() }
        }
    }
    private func persistieren() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(konversationen) else { return }
        let local = localRoot.appendingPathComponent(indexName)
        try? data.write(to: local, options: .atomic)
        for k in konversationen {
            let file = localRoot.appendingPathComponent("\(k.id).json")
            if let kd = try? enc.encode(k) { try? kd.write(to: file, options: .atomic) }
        }
        if FenlynineOSSicherheitsHaertung.iCloudChatErlaubt, let cloud = iCloudRoot {
            try? data.write(to: cloud.appendingPathComponent(indexName), options: .atomic)
            for k in konversationen {
                var kk = k
                kk.syncedToICloud = true
                if let kd = try? enc.encode(kk) {
                    try? kd.write(to: cloud.appendingPathComponent("\(k.id).json"), options: .atomic)
                }
            }
            for i in konversationen.indices { konversationen[i].syncedToICloud = true }
            iCloudVerfuegbar = true
            letzterSync = .init()
            statusHinweis = "iCloud synchronisiert"
        } else {
            statusHinweis = FenlynineOSSicherheitsHaertung.iCloudChatErlaubt
                ? "Lokal gespeichert · iCloud nicht verfügbar"
                : "Lokal gespeichert · iCloud-Sync deaktiviert (Sicherheit)"
        }
    }
    private func loescheDatei(id: String) {
        try? FileManager.default.removeItem(at: localRoot.appendingPathComponent("\(id).json"))
        if let cloud = iCloudRoot {
            try? FileManager.default.removeItem(at: cloud.appendingPathComponent("\(id).json"))
        }
    }
    func syncICloud() async {
        statusHinweis = "Synchronisiere…"
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        if let cloud = iCloudRoot?.appendingPathComponent(indexName),
           let data = try? Data(contentsOf: cloud),
           let remote = try? dec.decode([CloudChatKonversation].self, from: data) {
            merge(remote)
            iCloudVerfuegbar = true
        }
        persistieren()
        letzterSync = .init()
    }
}
extension ChatNachricht {
    func alsCloud() -> CloudChatNachricht {
        let rolle: String
        switch self.rolle {
        case .benutzer: rolle = "user"
        case .ki: rolle = "assistant"
        case .system: rolle = "system"
        }
        return CloudChatNachricht(
            id: id.uuidString,
            rolle: rolle,
            inhalt: inhalt,
            zeitstempel: zeitstempel,
            transparenz: transparenz,
            caseContext: caseContext
        )
    }
    static func ausCloud(_ c: CloudChatNachricht) -> ChatNachricht {
        let rolle: ChatNachricht.ChatRolle
        switch c.rolle {
        case "user": rolle = .benutzer
        case "system": rolle = .system
        default: rolle = .ki
        }
        var n = ChatNachricht(rolle: rolle, inhalt: c.inhalt, zeitstempel: c.zeitstempel)
        if let uuid = UUID(uuidString: c.id) { n.id = uuid }
        n.transparenz = c.transparenz
        n.caseContext = c.caseContext
        return n
    }
}
