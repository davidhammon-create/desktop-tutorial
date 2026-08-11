import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// APPLE INTELLIGENCE -- On-Device-KI als Alternative zur Base44-API
//
// Nutzt das FoundationModels-Framework von macOS (ab macOS 26 „Tahoe").
// Das Modell ist Bestandteil des Betriebssystems und wird von Apple über
// macOS-Updates automatisch aktuell gehalten -- es läuft also immer die
// neueste auf diesem Gerät verfügbare Version, ohne dass die App etwas
// nachladen muss. Alle Anfragen bleiben vollständig auf dem Gerät
// (keine Cloud, keine Datenübertragung, DSGVO-freundlich).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Verfügbarkeitsstatus

enum AppleIntelligenceStatus: Equatable {
case verfuegbar(osVersion: String)
case nichtAktiviert
case geraetNichtGeeignet
case modellLaedt
case osZuAlt
case frameworkFehlt

var ok: Bool {
  if case .verfuegbar = self { return true }
  return false
}

var titel: String {
  switch self {
  case .verfuegbar: return "Apple Intelligence verfügbar"
  case .nichtAktiviert: return "Apple Intelligence nicht aktiviert"
  case .geraetNichtGeeignet: return "Gerät nicht geeignet"
  case .modellLaedt: return "Modell wird geladen"
  case .osZuAlt: return "macOS-Version zu alt"
  case .frameworkFehlt: return "Framework nicht vorhanden"
  }
}

var hinweis: String {
  switch self {
  case .verfuegbar(let os):
    return "On-Device-Modell aktiv (\(os)). Wird über macOS-Updates automatisch auf der neuesten Version gehalten -- keine Cloud, keine Datenübertragung."
  case .nichtAktiviert:
    return "In Systemeinstellungen -> Apple Intelligence & Siri aktivieren. Danach steht das Modell sofort zur Verfügung."
  case .geraetNichtGeeignet:
    return "Dieses Gerät unterstützt Apple Intelligence nicht (Apple-Silicon erforderlich)."
  case .modellLaedt:
    return "macOS lädt das Modell gerade herunter -- in wenigen Minuten erneut versuchen."
  case .osZuAlt:
    return "Apple Intelligence erfordert macOS 26 oder neuer. Nach dem macOS-Update automatisch verfügbar."
  case .frameworkFehlt:
    return "Diese App-Version wurde ohne FoundationModels-SDK gebaut."
  }
}
}

// MARK: - Service

enum AppleIntelligenceService {

/// Aktueller Status -- wird bei jedem Zugriff live vom System abgefragt,
/// sodass macOS-Updates und Einstellungs-Änderungen sofort sichtbar sind.
static var status: AppleIntelligenceStatus {
  #if canImport(FoundationModels)
  if #available(macOS 26.0, *) {
    switch SystemLanguageModel.default.availability {
    case .available:
      return .verfuegbar(osVersion: "macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case .unavailable(.deviceNotEligible):
      return .geraetNichtGeeignet
    case .unavailable(.appleIntelligenceNotEnabled):
      return .nichtAktiviert
    case .unavailable(.modelNotReady):
      return .modellLaedt
    case .unavailable:
      return .nichtAktiviert
    }
  } else {
    return .osZuAlt
  }
  #else
  return .frameworkFehlt
  #endif
}

static var verfuegbar: Bool { status.ok }

/// Anzeigename inkl. OS-Stand (die Modellversion folgt dem OS).
static var modellLabel: String {
  let v = ProcessInfo.processInfo.operatingSystemVersion
  return "apple-intelligence (on-device, macOS \(v.majorVersion).\(v.minorVersion))"
}

private static let systemInstruktion = """
Du bist ein juristischer KI-Assistent für Rechtsanwälte in der Software FenlynineOS Legal Suite by Håmmon & Partner. \
Antworte präzise, strukturiert und auf Deutsch, sofern die Frage nicht in einer anderen Sprache gestellt wird. \
Kennzeichne Unsicherheiten. Erfinde keine Normen oder Fundstellen.
"""

/// Freitext-Antwort vom On-Device-Modell.
static func antwort(prompt: String) async throws -> String {
 #if canImport(FoundationModels)
 guard #available(macOS 26.0, *) else {
   throw Base44Error.serverError(AppleIntelligenceStatus.osZuAlt.hinweis)
 }
 let s = status
 guard s.ok else { throw Base44Error.serverError(s.hinweis) }
 let session = LanguageModelSession(instructions: systemInstruktion)
 let antwort = try await session.respond(to: gekuerzt(prompt))
 return antwort.content
 #else
 throw Base44Error.serverError(AppleIntelligenceStatus.frameworkFehlt.hinweis)
 #endif
}

/// Strukturierte Antwort: Modell wird auf JSON verpflichtet, Ergebnis dekodiert.
static func antwortJSON<T: Decodable>(prompt: String, schema: Any?) async throws -> T {
 let schemaText = schema.map { String(describing: $0) } ?? "frei, aber valides JSON"
 let jsonPrompt = """
 Antworte AUSSCHLIESSLICH mit validem JSON, ohne Markdown-Zäune, ohne Erläuterung.
 Erwartetes Schema: \(schemaText)

 Aufgabe:
 \(prompt)
 """
 let roh = try await antwort(prompt: jsonPrompt)
 let bereinigt = roh
   .replacingOccurrences(of: "```json", with: "")
   .replacingOccurrences(of: "```", with: "")
   .trimmingCharacters(in: .whitespacesAndNewlines)
 guard let data = bereinigt.data(using: .utf8) else {
   throw Base44Error.serverError("Leere Antwort von Apple Intelligence")
 }
 return try JSONDecoder.base44.decode(T.self, from: data)
}

/// On-Device-Modelle haben ein begrenztes Kontextfenster -- lange Prompts
/// werden am Anfang und Ende erhalten, die Mitte gekürzt.
private static func gekuerzt(_ prompt: String, limit: Int = 12_000) -> String {
 guard prompt.count > limit else { return prompt }
 let kopf = prompt.prefix(limit * 2 / 3)
 let fuss = prompt.suffix(limit / 3)
 return kopf + "\n\n[… Kontext gekürzt für On-Device-Modell …]\n\n" + fuss
}
}

