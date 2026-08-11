import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// PRO-KI API -- eigene Anbindung je Modul, optional global für alle
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum KIModulSlot: String, CaseIterable, Identifiable, Codable {
case global
case lexara
case strategos
case opportunisma
case fallAssistent
case advocatus
case richter
case vorgang
case organon
case plattform

var id: String { rawValue }

var titel: String {
  switch self {
  case .global: return "Alle KIs (Standard)"
  case .lexara: return "Lexara"
  case .strategos: return "Strategos"
  case .opportunisma: return "Opportunisma"
  case .fallAssistent: return "KI-Assistent / Chat"
  case .advocatus: return "Advocatus"
  case .richter: return "Richterprofile"
  case .vorgang: return "Vorgänge"
  case .organon: return "Organon"
  case .plattform: return "Plattform-Agent"
  }
}

var untertitel: String {
  switch self {
  case .global: return "Eine API für alle Module -- empfohlen"
  case .lexara: return "Fallanalyse, Prognose, Argumente"
  case .strategos: return "Enterprise · Szenarien"
  case .opportunisma: return "Optionsraum · Positionierung"
  case .fallAssistent: return "Chat & Agenten"
  case .advocatus: return "Live-Protokoll · Routing"
  case .richter: return "Richter- & Parteienanalyse"
  case .vorgang: return "Optionen · Formelkaskade"
  case .organon: return "Netzwerk · Personen"
  case .plattform: return "Workflow-Optimierer"
  }
}

/// Mapping von Log-Namen / Agent-Namen auf Slot
static func aus(kiName: String?) -> KIModulSlot {
  guard let n = kiName?.lowercased() else { return .global }
  if n.contains("lexara") || n.contains("fall") && n.contains("prognose") { return .lexara }
  if n.contains("strategos") { return .strategos }
  if n.contains("opportun") { return .opportunisma }
  if n.contains("fall_assistent") || n.contains("assistent") || n.contains("chat") { return .fallAssistent }
  if n.contains("advocatus") { return .advocatus }
  if n.contains("richter") || n.contains("judge") { return .richter }
  if n.contains("vorgang") { return .vorgang }
  if n.contains("organon") { return .organon }
  if n.contains("plattform") { return .plattform }
  return .global
}
}

struct KIModulAnbindung: Codable, Equatable {
/// true = erbt die globale Anbindung
var nutzeGlobal: Bool = true
var modus: KIModus = .base44
var offlineURL: String = "http://localhost:11434/api/chat"
var offlineModell: String = "llama3"
var modellOverride: String? = nil
/// Optional eigener Base44-Token (Keychain-Key-Suffix)
var eigenerToken: Bool = false
}

extension KIKonfiguration {
private static let moduleKey = "ki_modul_anbindungen_v1"
private static let overrideKey = "ki_modell_override"

/// Pro-Modul-Overrides. `.global` ist immer die Basis.
var modulAnbindungen: [String: KIModulAnbindung] {
  get {
    guard let data = UserDefaults.standard.data(forKey: Self.moduleKey),
       let map = try? JSONDecoder().decode([String: KIModulAnbindung].self, from: data)
    else { return [:] }
    return map
  }
  set {
    if let data = try? JSONEncoder().encode(newValue) {
      UserDefaults.standard.set(data, forKey: Self.moduleKey)
    }
  }
}

mutating func setzeAnbindung(_ slot: KIModulSlot, _ a: KIModulAnbindung) {
  var map = modulAnbindungen
  map[slot.rawValue] = a
 modulAnbindungen = map
}

func anbindung(fuer slot: KIModulSlot) -> KIModulAnbindung {
 if slot == .global {
   return KIModulAnbindung(
     nutzeGlobal: true,
     modus: modus,
     offlineURL: offlineURL,
     offlineModell: offlineModell,
     modellOverride: modellOverride,
     eigenerToken: false
   )
 }
 let a = modulAnbindungen[slot.rawValue] ?? KIModulAnbindung()
 if a.nutzeGlobal {
   return KIModulAnbindung(
     nutzeGlobal: true,
     modus: modus,
     offlineURL: offlineURL,
     offlineModell: offlineModell,
     modellOverride: modellOverride,
     eigenerToken: false
   )
 }
 return a
}

/// Effektive Runtime-Werte für einen Slot
func aufgeloest(fuer slot: KIModulSlot) -> (modus: KIModus, offlineURL: String, offlineModell: String, modell: String?) {
 let a = anbindung(fuer: slot)
 return (a.modus, a.offlineURL, a.offlineModell, a.modellOverride)
}

static func syncShared(from cfg: KIKonfiguration) {
 shared = cfg
}
}

