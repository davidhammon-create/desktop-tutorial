import Foundation

// MARK: - Lokaler JSON-Speicher (Fall-Daten auf diesem Mac)

actor LocalDataStore {
static let shared = LocalDataStore()

private var basisURL: URL?
private var istInitialisiert = false

func initialize(deviceId: String) {
  basisURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("FenlynineOS/devices/\(deviceId)/data", isDirectory: true)
  try? FileManager.default.createDirectory(at: basisURL!, withIntermediateDirectories: true)
  istInitialisiert = true
}

var speicherPfad: String {
  basisURL?.path ?? DeviceIdentity.datenVerzeichnis.path
}

func load<T: Decodable>(_ type: T.Type, entityName: String) throws -> [T] {
  let url = dateiURL(entityName)
  guard FileManager.default.fileExists(atPath: url.path) else { return [] }
  let data = try Data(contentsOf: url)
  return try JSONDecoder.base44.decode([T].self, from: data)
}

func save<T: Encodable>(_ items: [T], entityName: String) throws {
  guard istInitialisiert, let basisURL else {
    throw Base44Error.serverError("Lokaler Speicher nicht initialisiert.")
  }
  try FileManager.default.createDirectory(at: basisURL, withIntermediateDirectories: true)
  let data = try JSONEncoder.base44.encode(items)
  try data.write(to: dateiURL(entityName), options: .atomic)
}

private func dateiURL(_ entityName: String) -> URL {
  (basisURL ?? DeviceIdentity.datenVerzeichnis).appendingPathComponent("\(entityName).json")
}
}

