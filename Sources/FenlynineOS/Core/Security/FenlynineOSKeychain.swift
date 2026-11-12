import Foundation
import Security

// MARK: - Keychain-Speicher (Tokens & Geheimnisse)

enum FenlynineOSKeychain {
private static let service = "com.fenlynineos.machiavellex"

enum Account: String {
  case base44AccessToken = "base44_access_token"
  case deviceSecret = "fenlynineos_device_secret"
}

static func set(_ value: String, account: Account) {
  guard let data = value.data(using: .utf8) else { return }
  let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account.rawValue,
    kSecValueData as String: data,
    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
  ]
  SecItemDelete(query as CFDictionary)
  SecItemAdd(query as CFDictionary, nil)
}

static func get(account: Account) -> String? {
  let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account.rawValue,
    kSecReturnData as String: true,
    kSecMatchLimit as String: kSecMatchLimitOne
  ]
  var item: CFTypeRef?
  let status = SecItemCopyMatching(query as CFDictionary, &item)
  guard status == errSecSuccess,
     let data = item as? Data,
     let value = String(data: data, encoding: .utf8) else { return nil }
  return value
}

static func delete(account: Account) {
  let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account.rawValue
  ]
  SecItemDelete(query as CFDictionary)
}

/// Einmalige Migration aus UserDefaults (ältere Builds).
static func migrateLegacySecretsIfNeeded() {
  migrateLegacy(key: Account.base44AccessToken.rawValue, account: .base44AccessToken)
  migrateLegacy(key: Account.deviceSecret.rawValue, account: .deviceSecret)
}

private static func migrateLegacy(key: String, account: Account) {
  if get(account: account) != nil { return }
  if let legacy = UserDefaults.standard.string(forKey: key), !legacy.isEmpty {
    set(legacy, account: account)
    UserDefaults.standard.removeObject(forKey: key)
  }
}
}

