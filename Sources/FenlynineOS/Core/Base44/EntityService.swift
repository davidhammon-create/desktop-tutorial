import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Entity Service (SDK-konform)
//
// Alle URLs und Query-Parameter entsprechen dem @base44/sdk v0.8.32:
// GET /apps/{appId}/entities/{Entity} -- list / filter
// GET /apps/{appId}/entities/{Entity}/{id} -- get
// POST /apps/{appId}/entities/{Entity} -- create
// PUT /apps/{appId}/entities/{Entity}/{id} -- update
// DELETE /apps/{appId}/entities/{Entity}/{id} -- delete
//
// Filter-Format: ?q={"field":"value"} (JSON-encoded)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Protokoll

protocol Base44EntityProtocol: Codable, Identifiable where ID == String? {
var id: String? { get set }
var created_by: String? { get set }
var created_at: Date? { get set }
var updated_at: Date? { get set }
}

// Für Hashable-Konformanz in Views
typealias Base44Entity = Base44EntityProtocol

// MARK: - Generischer Entity-Service

final class EntityService<T: Base44EntityProtocol> {

let entityName: String
private let client = Base44Client.shared

init(entityName: String) {
  self.entityName = entityName
}

// MARK: - Alle auflisten

func list(sort: String? = nil, limit: Int? = nil, skip: Int? = nil) async throws -> [T] {
  let config = Base44Config.load()
  let url = config.entityURL(entityName)

  var params: [URLQueryItem] = []
  if let s = sort { params.append(.init(name: "sort", value: s)) }
  if let l = limit { params.append(.init(name: "limit", value: "\(l)")) }
  if let sk = skip { params.append(.init(name: "skip", value: "\(sk)")) }

  let response: [T] = try await client.get(url, queryItems: params)
  return response
}

// MARK: - Filtern (SDK: q=JSON)

func filter(_ query: [String: String], sort: String? = nil, limit: Int? = nil) async throws -> [T] {
  let config = Base44Config.load()
  let url = config.entityURL(entityName)

  guard let qData = try? JSONEncoder().encode(query),
     let qString = String(data: qData, encoding: .utf8)
  else { return [] }

  var params = [URLQueryItem(name: "q", value: qString)]
  if let s = sort { params.append(.init(name: "sort", value: s)) }
  if let l = limit { params.append(.init(name: "limit", value: "\(l)")) }

  let response: [T] = try await client.get(url, queryItems: params)
  return response
}

// MARK: - Einzelnes Objekt

func get(id: String) async throws -> T {
  let config = Base44Config.load()
  let url = config.entityItemURL(entityName, id: id)
  return try await client.get(url)
}

// MARK: - Erstellen

@discardableResult
func create(_ entity: T) async throws -> T {
  let config = Base44Config.load()
  let url = config.entityURL(entityName)
  return try await client.post(url, body: entity)
}

// MARK: - Aktualisieren

@discardableResult
func update(id: String, entity: T) async throws -> T {
  let config = Base44Config.load()
  let url = config.entityItemURL(entityName, id: id)
  return try await client.put(url, body: entity)
}

// MARK: - Löschen

func delete(id: String) async throws {
 let config = Base44Config.load()
 let url = config.entityItemURL(entityName, id: id)
 try await client.delete(url)
}

// MARK: - Upsert

@discardableResult
func save(_ entity: T) async throws -> T {
 if let id = entity.id, !id.isEmpty {
   return try await update(id: id, entity: entity)
 }
 return try await create(entity)
}

// MARK: - Alle Einträge für einen Fall laden

func listForCase(caseId: String) async throws -> [T] {
 return try await filter(["case_id": caseId])
}
}

// MARK: - Singleton-Services
//
// Geräte-Modus: Fall-Daten lokal auf diesem Mac (JSON).
// Base44 nur für KI / Functions (Konfiguration in AppDefaults).

enum Services {
static let cases = LocalEntityService<LegalCase>(entityName: "Case")
static let arguments = LocalEntityService<Argument>(entityName: "Argument")
static let evidence = LocalEntityService<Evidence>(entityName: "Evidence")
static let deadlines = LocalEntityService<Deadline>(entityName: "Deadline")
static let documents = LocalEntityService<LegalDocument>(entityName: "Document")
static let persons = LocalEntityService<Person>(entityName: "Person")
static let tasks = LocalEntityService<CaseTask>(entityName: "Task")
static let judgeProfiles = LocalEntityService<JudgeProfile>(entityName: "JudgeProfile")
static let mandanten = LocalEntityService<Mandant>(entityName: "Mandant")
static let mandantAktivitaeten = LocalEntityService<MandantAktivitaet>(entityName: "MandantAktivitaet")
static let caseFolders = LocalEntityService<CaseFolder>(entityName: "CaseFolder")
static let caseHistory = LocalEntityService<CaseHistory>(entityName: "CaseHistory")
static let timelineEvents = LocalEntityService<TimelineEvent>(entityName: "TimelineEvent")
static let strategosScenarios = LocalEntityService<StrategosScenario>(entityName: "StrategosScenario")
static let gegnerVerhalten = LocalEntityService<GegnerVerhalten>(entityName: "GegnerVerhalten")
static let kiUsageLogs = LocalEntityService<KIUsageLog>(entityName: "KIUsageLog")
static let legalLoopholes = LocalEntityService<LegalLoophole>(entityName: "LegalLoophole")
static let caseQuestionnaires = LocalEntityService<CaseQuestionnaire>(entityName: "CaseQuestionnaire")
static let caseWarnings = LocalEntityService<CaseWarning>(entityName: "CaseWarning")
static let aiPerformanceFeedback = LocalEntityService<AIPerformanceFeedback>(entityName: "AIPerformanceFeedback")
static let jurisdictionInsights = LocalEntityService<JurisdictionInsight>(entityName: "JurisdictionInsight")
static let users = EntityService<User>(entityName: "User")
}

