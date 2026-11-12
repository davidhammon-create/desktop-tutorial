import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Function Service (SDK-konform)
//
// Ruft Base44 Serverless-Deno-Funktionen auf.
// SDK-URL: POST /apps/{appId}/functions/{functionName}
//
// Alle Parameter-Namen entsprechen den entry.ts Dateien im Repository.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

actor FunctionService {
static let shared = FunctionService()
private let client = Base44Client.shared

// MARK: - Generischer Aufruf

func invoke<P: Encodable, R: Decodable>(name: String, params: P) async throws -> R {
  try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "Cloud-Funktion \(name)")
  await client.ensureReady()
  let url = Base44Config.load().functionURL(name)
  return try await client.post(url, body: params)
}

// MARK: - analyzeDocument
//
// Deno entry.ts erwartet: { docId: string, caseId: string }
// Analysiert ein Dokument und erstellt Argumente, Beweise, Fristen, Personen
// sowie Fallaktualisierungen mit Claude Sonnet 4.6.
func analyzeDocument(docId: String, caseId: String) async throws -> AnalyzeDocumentResult {
  try await invoke(
    name: "analyzeDocument",
    params: AnalyzeDocumentRequest(docId: docId, caseId: caseId)
  )
}

// MARK: - checkCaseCompliance
//
// Deno entry.ts erwartet: { caseId: string }
// Erstellt CaseWarning-Entities und gibt Zusammenfassung zurück.
func checkCaseCompliance(caseId: String) async throws -> ComplianceResult {
  try await invoke(
    name: "checkCaseCompliance",
    params: ["caseId": caseId]
  )
}

// MARK: - exportCasePDF
//
// Deno entry.ts erwartet: { caseId: string }
// Gibt direkten PDF-Binärinhalt zurück (Content-Type: application/pdf).
// Wir laden es als Data und speichern im Downloads-Ordner.
func exportCasePDF(caseId: String) async throws -> URL {
  try await downloadPDF(functionName: "exportCasePDF", caseId: caseId, fileName: "Fallbericht_\(caseId).pdf")
}

// MARK: - exportGegnerVerhaltenPDF
func exportGegnerVerhaltenPDF(caseId: String) async throws -> URL {
  try await downloadPDF(functionName: "exportGegnerVerhaltenPDF", caseId: caseId, fileName: "GegnerProfil_\(caseId).pdf")
}

// MARK: - Hilfsmethode: PDF herunterladen

private func downloadPDF(functionName: String, caseId: String, fileName: String) async throws -> URL {
  try FenlynineOSSicherheitsHaertung.darfCloudEgress(aktion: "PDF-Export \(functionName)")
  await client.ensureReady()
  let config = Base44Config.load()
  let url = config.functionURL(functionName)

  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  if let token = config.accessToken, !token.isEmpty {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
  }
  if !config.appId.isEmpty {
    request.setValue(config.appId, forHTTPHeaderField: "X-App-Id")
  }
  request.httpBody = try JSONEncoder.base44.encode(["caseId": caseId])

  let (data, response) = try await URLSession.shared.data(for: request)
  guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
    throw Base44Error.httpError(
      (response as? HTTPURLResponse)?.statusCode ?? 0,
      "PDF-Export fehlgeschlagen"
    )
  }

  // Speichere im Downloads-Ordner
  let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
  let dest = downloads.appendingPathComponent(fileName)
  try data.write(to: dest)
  return dest
}

// MARK: - exportIcal
func exportIcal(caseId: String? = nil) async throws -> ICalExportResult {
  struct ICalParams: Encodable { let case_id: String? }
  return try await invoke(name: "exportIcal", params: ICalParams(case_id: caseId))
}

// MARK: - linkEvidenceToArguments
//
// Deno entry.ts erwartet: { caseId: string, docId?: string }
func linkEvidenceToArguments(caseId: String, docId: String? = nil) async throws -> LinkingResult {
 try await invoke(
   name: "linkEvidenceToArguments",
   params: LinkEvidenceRequest(caseId: caseId, docId: docId)
 )
}

// MARK: - logCaseChange
func logCaseChange(caseId: String, changeType: String, details: String) async throws {
 struct Params: Encodable { let case_id, change_type, details: String }
 let _: EmptyResponse = try await invoke(
   name: "logCaseChange",
   params: Params(case_id: caseId, change_type: changeType, details: details)
 )
}

// MARK: - sendMandantUpdate
func sendMandantUpdate(caseId: String, message: String) async throws {
 struct Params: Encodable { let case_id, message: String }
 let _: EmptyResponse = try await invoke(
   name: "sendMandantUpdate",
   params: Params(case_id: caseId, message: message)
 )
}

// MARK: - stripeCheckout
//
// Deno entry.ts erwartet: { type: "ki" | "module", successUrl?: string, cancelUrl?: string }
// Returns: { url: string }
func createStripeCheckout(
 type: StripeCheckoutType = .module,
 successUrl: String? = nil,
 cancelUrl: String? = nil
) async throws -> StripeCheckoutResult {
 try await invoke(
   name: "stripeCheckout",
   params: StripeCheckoutRequest(type: type.rawValue, successUrl: successUrl, cancelUrl: cancelUrl)
 )
}

// MARK: - deadlineEmailAlert
func sendDeadlineEmailAlert(caseId: String, deadlineId: String) async throws {
 struct Params: Encodable { let case_id, deadline_id: String }
 let _: EmptyResponse = try await invoke(
   name: "deadlineEmailAlert",
   params: Params(case_id: caseId, deadline_id: deadlineId)
 )
}

// MARK: - exportToSupabase (Datenexport)
func exportToSupabase(caseId: String) async throws -> ExportResult {
 try await invoke(name: "exportToSupabase", params: ["case_id": caseId])
}
}

// MARK: - Request/Response-Typen

struct AnalyzeDocumentRequest: Encodable {
let docId: String
let caseId: String
}

struct AnalyzeDocumentResult: Decodable {
let success: Bool
let result: AnyCodable?
let stats: AnalyzeStats?
}

struct AnalyzeStats: Decodable {
let argumente: Int?
let beweise: Int?
let fristen: Int?
let personen: Int?
let case_felder_aktualisiert: Int?
let verknuepfungen: Int?
}

struct ComplianceResult: Decodable {
// Antwort von checkCaseCompliance/entry.ts:
// { caseId, warnings_count, warnings: [{ type, severity, title }] }
let caseId: String?
let warnings_count: Int?
let warnings: [ComplianceWarningBrief]?

var compliant: Bool { (warnings_count ?? 0) == 0 }
var score: Int { max(0, 100 - ((warnings_count ?? 0) * 10)) }
}

struct ComplianceWarningBrief: Decodable {
let type: String?
let severity: String?
let title: String?
}

// PDFExportResult wird nicht mehr direkt verwendet -- exportCasePDF gibt URL zurück

struct ICalExportResult: Decodable {
let url: String
let filename: String
let event_count: Int
}

struct LinkEvidenceRequest: Encodable {
let caseId: String
let docId: String?
}

struct LinkingResult: Decodable {
let success: Bool
let linked: Int
let zuordnungen: [LinkZuordnung]?
let message: String?
}

struct LinkZuordnung: Decodable {
let evidence_id: String
let argument_id: String
let konfidenz: String?
let begruendung: String?
}

enum StripeCheckoutType: String {
case module = "module" // €29/Monat Abo
case ki = "ki" // €1.99 Einzel-KI-Nutzung
}

struct StripeCheckoutRequest: Encodable {
let type: String
let successUrl: String?
let cancelUrl: String?
}

struct StripeCheckoutResult: Decodable {
let url: String
}

struct ExportResult: Decodable {
let success: Bool
let exported: Int?
let message: String?
}

// MARK: - KI-Transparenz-Typen (für Funktions-Antworten)

struct KISchritt: Codable, Identifiable {
var id: UUID = UUID()
let kategorie: String
let label: String
let formel: String?
let wert: AnyCodable?
let einheit: String?
let erklaerung: String
let details: AnyCodable?

enum CodingKeys: String, CodingKey {
 case kategorie, label, formel, wert, einheit, erklaerung, details
}
}

// MARK: - AnyCodable (für dynamische JSON-Werte aus dem Backend)

struct AnyCodable: Codable, Hashable, Equatable {
let value: Any

static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
 "\(lhs.value)" == "\(rhs.value)"
}

func hash(into hasher: inout Hasher) {
 hasher.combine("\(value)")
}

init(_ value: Any) { self.value = value }

init(from decoder: Decoder) throws {
 let c = try decoder.singleValueContainer()
 if let v = try? c.decode(Bool.self) { value = v }
 else if let v = try? c.decode(Int.self) { value = v }
 else if let v = try? c.decode(Double.self) { value = v }
 else if let v = try? c.decode(String.self) { value = v }
 else if let v = try? c.decode([AnyCodable].self){ value = v.map(\.value) }
 else if let v = try? c.decode([String: AnyCodable].self) {
   value = v.mapValues(\.value)
 } else { value = NSNull() }
}

func encode(to encoder: Encoder) throws {
 var c = encoder.singleValueContainer()
 switch value {
 case let v as Bool: try c.encode(v)
 case let v as Int: try c.encode(v)
 case let v as Double: try c.encode(v)
 case let v as String: try c.encode(v)
 case let v as [Any]: try c.encode(v.map { AnyCodable($0) })
 case let v as [String: Any]:try c.encode(v.mapValues { AnyCodable($0) })
 default:      try c.encodeNil()
 }
}

var stringValue: String? { value as? String }
var doubleValue: Double? { value as? Double }
var intValue: Int? { value as? Int }
var boolValue: Bool? { value as? Bool }
var arrayValue: [Any]? { value as? [Any] }
var dictValue: [String: Any]? { value as? [String: Any] }
}

