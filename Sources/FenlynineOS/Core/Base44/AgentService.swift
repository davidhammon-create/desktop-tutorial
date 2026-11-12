import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Agent Service (SDK-konform)
//
// Ruft Base44 AI-Agenten über HTTP auf.
// SDK-URLs:
// GET /apps/{appId}/agents/conversations -- alle listen
// GET /apps/{appId}/agents/conversations?agent_name=X -- gefiltert
// POST /apps/{appId}/agents/conversations -- neu erstellen
// GET /apps/{appId}/agents/conversations/{id} -- laden
// POST /apps/{appId}/agents/conversations/v2/{id}/messages -- Nachricht senden
//
// Echtzeit-Updates werden via Polling simuliert (socket.io-Alternative für macOS).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Datentypen

struct AgentConversation: Codable, Identifiable {
let id: String
var app_id: String?
var agent_name: String?
var created_by: String?
var created_date: Date?
var updated_date: Date?
var messages: [AgentMessage]?
var metadata: [String: AnyCodable]?
}

struct AgentMessage: Codable, Identifiable {
let id: String
var role: String // "user" | "assistant" | "system" | "tool"
var content: String?
var created_date: Date?
var updated_date: Date?
var file_urls: [String]?
var tool_calls: [AgentToolCall]?
var usage: AgentTokenUsage?
var hidden: Bool?
var model: String?
}

struct AgentToolCall: Codable, Identifiable {
var id: String
var name: String?
var arguments: String? // JSON-String
var status: String?
var result: AnyCodable?
}

struct AgentTokenUsage: Codable {
var prompt_tokens: Int?
var completion_tokens: Int?
}

// MARK: - Service

actor AgentService {
static let shared = AgentService()
private let client = Base44Client.shared

private var config: Base44Config { Base44Config.load() }

// MARK: - Konversationen

func listConversations(agentName: String? = nil) async throws -> [AgentConversation] {
  try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Agent-Konversationen")
  let url = URL(string: "\(config.appBaseUrl)/api/apps/\(config.appId)/agents/conversations")!
  var params: [URLQueryItem] = []
  if let name = agentName { params.append(.init(name: "agent_name", value: name)) }
  return try await client.get(url, queryItems: params)
}

func getConversation(_ id: String) async throws -> AgentConversation {
  try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Agent-Konversation laden")
  let url = URL(string: "\(config.appBaseUrl)/api/apps/\(config.appId)/agents/conversations/\(id)")!
  return try await client.get(url)
}

func createConversation(agentName: String, metadata: [String: String]? = nil) async throws -> AgentConversation {
  try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Agent-Konversation erstellen")
  let url = URL(string: "\(config.appBaseUrl)/api/apps/\(config.appId)/agents/conversations")!
  struct CreateRequest: Encodable {
    let agent_name: String
    let metadata: [String: String]?
  }
  return try await client.post(url, body: CreateRequest(agent_name: agentName, metadata: metadata))
}

// MARK: - Nachricht senden

func addMessage(conversationId: String, role: String = "user", content: String, fileUrls: [String]? = nil) async throws -> AgentMessage {
  guard await KontoAbrechnung.kiErlaubt() else {
    throw Base44Error.serverError(KontoAbrechnung.sperrHinweis)
  }
  try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Agent-Nachricht")
  let url = URL(string: "\(config.appBaseUrl)/api/apps/\(config.appId)/agents/conversations/v2/\(conversationId)/messages")!
  struct MessageRequest: Encodable {
    let role: String
   let content: String
   let file_urls: [String]?
 }
 return try await client.post(url, body: MessageRequest(role: role, content: content, file_urls: fileUrls))
}

// MARK: - Antwort abwarten (Polling, da kein socket.io)
//
// Das Original nutzt WebSocket-Subscriptions.
// Wir simulieren dies via kurzem Polling auf die Konversation.

func waitForAssistantReply(
 conversationId: String,
 afterMessageCount: Int,
 maxWaitSeconds: Double = 60,
 pollIntervalSeconds: Double = 1.5
) async throws -> AgentMessage? {
 let deadline = Date().addingTimeInterval(maxWaitSeconds)

 while Date() < deadline {
   let conv = try await getConversation(conversationId)
   let msgs = conv.messages ?? []

   // Neue Assistant-Nachricht nach der zuletzt bekannten Position?
   if msgs.count > afterMessageCount {
     let neueNachrichten = msgs[afterMessageCount...]
     // Letzte Assistenten-Nachricht (kann stream-weise aufgebaut sein)
     if let antwort = neueNachrichten.last(where: { $0.role == "assistant" }) {
       // Warten bis die Nachricht "fertig" ist (keine Streaming-Marker)
       if !(antwort.content?.isEmpty ?? true) {
         // Konto-Abrechnung: echte Token-Nutzung, falls gemeldet -- sonst Schätzung
         let tokensEin = antwort.usage?.prompt_tokens
           ?? KontoAbrechnung.geschaetzteTokens(zeichen: 800)
         let tokensAus = antwort.usage?.completion_tokens
           ?? KontoAbrechnung.geschaetzteTokens(zeichen: antwort.content?.count ?? 0)
         await KontoAbrechnung.verbuche(
           modul: "KI-Assistent",
           aktion: "Chat-Antwort",
           modell: antwort.model ?? "agent",
           tokensEin: tokensEin,
           tokensAus: tokensAus
         )
         return antwort
       }
     }
   }

   try await Task.sleep(for: .seconds(pollIntervalSeconds))
 }

 return nil
}

// MARK: - Vollständiger Sende-und-Warte-Flow

func sendAndWait(
 conversationId: String,
 userMessage: String,
 currentMessageCount: Int
) async throws -> AgentMessage? {
 _ = try await addMessage(conversationId: conversationId, role: "user", content: userMessage)
 return try await waitForAssistantReply(
   conversationId: conversationId,
   afterMessageCount: currentMessageCount + 1 // +1 für die User-Nachricht
 )
}
}

