import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// SICHERHEITSHÄRTUNG -- Offline-first · maschinengestützt · kein stiller Cloud-Egress
//
// Prinzip:
// 1. Mandatsdaten bleiben auf diesem Mac (FileVault / Benutzerkonto = Trust-Boundary).
// 2. Cloud nur nach bewusster Residenz-Freigabe (DatenResidenz).
// 3. Lokale Offline-KI nur auf Loopback (127.0.0.1 / localhost) -- kein Prompt-Exfil.
// 4. Remote-Updates standardmäßig AUS (kein stilles Binary-Replace).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum FenlynineOSSicherheitsFehler: LocalizedError {
case cloudGesperrt(String)
case offlineURLUngueltig
case updateRemoteGesperrt
case uploadGesperrt

var errorDescription: String? {
  switch self {
  case .cloudGesperrt(let grund):
    return "Cloud-Zugriff gesperrt (Residenz): \(grund)"
  case .offlineURLUngueltig:
    return "Offline-KI nur auf diesem Mac erlaubt (localhost / 127.0.0.1)."
  case .updateRemoteGesperrt:
    return "Remote-Updates sind aus Sicherheitsgründen deaktiviert. Nur lokale Manifeste."
  case .uploadGesperrt:
    return "Dokument-Upload in die Cloud ist bei der aktuellen Residenz-Stufe nicht erlaubt."
  }
}
}

enum FenlynineOSSicherheitsHaertung {

/// Remote-Auto-Update (Binary-Replace) -- Standard: AUS.
static var remoteUpdatesErlaubt: Bool {
  get { UserDefaults.standard.bool(forKey: "fenlynineos_updates_remote_erlaubt") }
  set { UserDefaults.standard.set(newValue, forKey: "fenlynineos_updates_remote_erlaubt") }
}

/// iCloud-Chat-Sync -- Standard: AUS.
static var iCloudChatErlaubt: Bool {
  get { UserDefaults.standard.bool(forKey: "fenlynineos_icloud_chat_erlaubt") }
  set { UserDefaults.standard.set(newValue, forKey: "fenlynineos_icloud_chat_erlaubt") }
}

/// Prüft, ob Daten die Maschine verlassen dürfen (Base44, Uploads, Functions, Agents).
static func darfCloudEgress(aktion: String) throws {
  guard DatenResidenz.darfCloud else {
    throw FenlynineOSSicherheitsFehler.cloudGesperrt(
      "Aktion „\(aktion)" · Region: \(DatenResidenz.region.titel). " +
      "Stellen Sie Residenz auf „Weltweit" oder aktivieren Sie die Base44-AV-Ausnahme " +
      "(nicht bei „Nur dieses Gerät")."
    )
  }
}

/// Offline-KI-URL: nur Loopback. Verhindert Prompt-Exfiltration an fremde Hosts.
static func validiereOfflineURL(_ raw: String) throws -> URL {
  let getrimmt = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  guard let url = URL(string: getrimmt), let host = url.host?.lowercased() else {
    throw FenlynineOSSicherheitsFehler.offlineURLUngueltig
  }
  let erlaubt = host == "localhost" || host == "127.0.0.1" || host == "::1"
    || host.hasSuffix(".localhost")
  guard erlaubt else { throw FenlynineOSSicherheitsFehler.offlineURLUngueltig }
  guard url.scheme == "http" || url.scheme == "https" else {
    throw FenlynineOSSicherheitsFehler.offlineURLUngueltig
  }
  return url
}

/// Kurzstatus für UI.
static var statusZeilen: [(String, String, Bool)] {
  let cloud = DatenResidenz.darfCloud
  let ki = KIKonfiguration.shared.modus
  return [
    ("Residenz", DatenResidenz.statusLabel, DatenResidenz.region == .nurLokal || !cloud),
    ("KI-Modus", ki.rawValue, ki != .base44 || cloud),
    ("Cloud-Egress", cloud ? "freigegeben" : "gesperrt", !cloud),
    ("Remote-Updates", remoteUpdatesErlaubt ? "AN (Risiko)" : "AUS", !remoteUpdatesErlaubt),
    ("iCloud-Chat", iCloudChatErlaubt ? "AN" : "AUS", !iCloudChatErlaubt)
  ]
}
}

