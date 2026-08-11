import Foundation

// MARK: - Geräte-Identität (dieser Mac = „Account")

enum DeviceIdentity {
private static let idKey = "fenlynineos_device_id"

/// Stabile UUID pro Mac (UserDefaults im App-Sandbox-Kontext).
static var id: String {
  let d = UserDefaults.standard
  if let existing = d.string(forKey: idKey), !existing.isEmpty { return existing }
  let neu = UUID().uuidString.lowercased()
  d.set(neu, forKey: idKey)
  return neu
}

/// Geheimes Geräte-Passwort (Keychain -- nicht UserDefaults).
static var secret: String {
  FenlynineOSKeychain.migrateLegacySecretsIfNeeded()
  if let existing = FenlynineOSKeychain.get(account: .deviceSecret), existing.count >= 16 {
    return existing
  }
  let zeichen = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let neu = String((0..<32).compactMap { _ in zeichen.randomElement() })
  FenlynineOSKeychain.set(neu, account: .deviceSecret)
  return neu
}

static var base44Email: String {
  "fenlynineos-\(id.prefix(12))@device.local"
}

static var anzeigeName: String {
  Host.current().localizedName ?? "Dieser Mac"
}

static var datenVerzeichnis: URL {
  FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("FenlynineOS/devices/\(id)/data", isDirectory: true)
}
}

