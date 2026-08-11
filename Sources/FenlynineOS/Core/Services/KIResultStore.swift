import Foundation

// MARK: - Zentraler Speicher für KI-Ergebnisse (Lexara-Fall)

enum KIResultStore {
static let parseFehler = "KI-Antwort konnte nicht verarbeitet werden. Bitte erneut versuchen."

/// Speichert einen Unter-Schlüssel in `ki_berater_result` und aktualisiert den Fall.
@discardableResult
static func mergeBeraterSubKey(
  caseId: String,
  fall: inout LegalCase,
  key: String,
  value: Any
) async throws -> LegalCase {
  var root = fall.ki_berater_result?.dictValue ?? [:]
  root[key] = value
  fall.ki_berater_result = AnyCodable(root)
  let saved = try await Services.cases.update(id: caseId, entity: fall)
  fall = saved
  return saved
}

/// Speichert einen Unter-Schlüssel in `gegner_profil`.
@discardableResult
static func mergeGegnerProfilSubKey(
  caseId: String,
  fall: inout LegalCase,
  key: String,
  value: Any
) async throws -> LegalCase {
  var root = fall.gegner_profil?.dictValue ?? [:]
  root[key] = value
  fall.gegner_profil = AnyCodable(root)
  let saved = try await Services.cases.update(id: caseId, entity: fall)
  fall = saved
  return saved
}

/// Fortschritt der KI-Module für Intelligence-Score.
static func moduleFortschritt(fall: LegalCase?) -> (erledigt: Int, gesamt: Int, module: [(name: String, done: Bool)]) {
  let keys: [(String, String)] = [
    ("KI-Berater", "psychologisches_profil"),
    ("Gesamtbewertung", "gesamtbewertung"),
    ("Strategie-Checkliste", "strategie_checkliste_schritte"),
    ("Prognose-Vergleich", "prognose_vergleich"),
    ("Was-wäre-wenn", "was_waere_wenn"),
    ("Last-Minute", "last_minute_check"),
    ("KI-Zusatzanalyse", "ki_zusatz_analyse"),
    ("Gegner-Strategie", "strategie_dashboard")
  ]
  let berater = fall?.ki_berater_result?.dictValue ?? [:]
  let gegner = fall?.gegner_profil?.dictValue ?? [:]
  var module: [(name: String, done: Bool)] = []
  for (name, key) in keys {
    let done: Bool
    if key == "strategie_dashboard" {
      done = gegner[key] != nil
    } else {
      done = berater[key] != nil
    }
    module.append((name, done))
  }
  let erledigt = module.filter(\.done).count
  return (erledigt, module.count, module)
}
}

// MARK: - Titel-Matching (Matrix Gegner-Argument « Beweis)

enum KITitleMatcher {
static func matchId(title: String, candidates: [(id: String?, title: String)]) -> String? {
  let norm = normalize(title)
  guard !norm.isEmpty else { return nil }

  if let exact = candidates.first(where: { normalize($0.title) == norm }) {
    return exact.id
  }
  if let contains = candidates.first(where: {
    let c = normalize($0.title)
    return c.contains(norm) || norm.contains(c)
  }) {
    return contains.id
  }
  let words = Set(norm.split(separator: " ").map(String.init).filter { $0.count > 3 })
  if !words.isEmpty {
    let scored = candidates.map { c -> (String?, Int) in
      let cw = Set(normalize(c.title).split(separator: " ").map(String.init))
      return (c.id, words.intersection(cw).count)
    }
    if let best = scored.max(by: { $0.1 < $1.1 }), best.1 >= 2 {
      return best.0
    }
  }
  return candidates.first(where: {
    normalize($0.title).hasPrefix(String(norm.prefix(12)))
  })?.id
}

private static func normalize(_ s: String) -> String {
 s.lowercased()
   .folding(options: .diacriticInsensitive, locale: .current)
   .replacingOccurrences(of: "[^a-z0-9äöüß ]", with: " ", options: .regularExpression)
   .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
   .trimmingCharacters(in: .whitespaces)
}
}

