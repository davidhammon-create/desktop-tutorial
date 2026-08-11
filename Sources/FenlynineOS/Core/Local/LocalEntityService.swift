import Foundation

// MARK: - Lokaler Entity-Service (ersetzt Base44-CRUD für Fall-Daten)

final class LocalEntityService<T: Base44EntityProtocol & Codable> {

let entityName: String
private let store = LocalDataStore.shared

init(entityName: String) {
  self.entityName = entityName
}

func list(sort: String? = nil, limit: Int? = nil, skip: Int? = nil) async throws -> [T] {
  var items = try await store.load(T.self, entityName: entityName)
  if let sort {
    items = sortiere(items, nach: sort)
  }
  if let skip, skip > 0 { items = Array(items.dropFirst(skip)) }
  if let limit { items = Array(items.prefix(limit)) }
  return items
}

func filter(_ query: [String: String], sort: String? = nil, limit: Int? = nil) async throws -> [T] {
  var items = try await list()
  items = items.filter { passt($0, zu: query) }
  if let sort { items = sortiere(items, nach: sort) }
  if let limit { items = Array(items.prefix(limit)) }
  return items
}

func get(id: String) async throws -> T {
  let items = try await list()
  guard let item = items.first(where: { $0.id == id }) else {
    throw Base44Error.notFound
  }
  return item
}

@discardableResult
func create(_ entity: T) async throws -> T {
  var neu = entity
  if neu.id == nil || neu.id!.isEmpty {
    neu.id = UUID().uuidString.lowercased()
  }
  let now = Date()
  neu.created_at = neu.created_at ?? now
  neu.updated_at = now
  var all = try await list()
  all.append(neu)
  try await store.save(all, entityName: entityName)
  return neu
}

@discardableResult
func update(id: String, entity: T) async throws -> T {
  var all = try await list()
  guard let idx = all.firstIndex(where: { $0.id == id }) else {
    throw Base44Error.notFound
  }
  var aktualisiert = entity
  aktualisiert.id = id
  aktualisiert.updated_at = Date()
  all[idx] = aktualisiert
  try await store.save(all, entityName: entityName)
  return aktualisiert
}

func delete(id: String) async throws {
  var all = try await list()
  guard all.contains(where: { $0.id == id }) else {
    throw Base44Error.notFound
  }
  all.removeAll { $0.id == id }
  try await store.save(all, entityName: entityName)
}

func listForCase(caseId: String) async throws -> [T] {
  try await filter(["case_id": caseId])
}

// MARK: - Hilfsmethoden

private func passt(_ entity: T, zu query: [String: String]) -> Bool {
  guard let data = try? JSONEncoder.base44.encode(entity),
     let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else { return false }

  for (key, expected) in query {
    guard let raw = obj[key] else { return false }
    let actual: String
    if let s = raw as? String { actual = s }
    else if let n = raw as? NSNumber { actual = n.stringValue }
    else { actual = String(describing: raw) }
    if actual != expected { return false }
  }
  return true
}

private func sortiere(_ items: [T], nach sort: String) -> [T] {
 let absteigend = sort.hasPrefix("-")
 let feld = absteigend ? String(sort.dropFirst()) : sort
 return items.sorted { a, b in
   let va = feldWert(a, feld: feld) ?? ""
   let vb = feldWert(b, feld: feld) ?? ""
   if va == vb { return false }
   return absteigend ? va > vb : va < vb
 }
}

private func feldWert(_ entity: T, feld: String) -> String? {
 guard let data = try? JSONEncoder.base44.encode(entity),
    let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
    let raw = obj[feld]
 else { return nil }
 if let s = raw as? String { return s }
 if let d = raw as? Double { return String(d) }
 if let n = raw as? NSNumber { return n.stringValue }
 return String(describing: raw)
}
}

