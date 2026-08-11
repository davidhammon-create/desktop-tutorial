import Foundation

// MARK: - KI-Prompt-Qualität (deutsche Rechtsanalyse, präzise JSON)

enum KIPromptKit {
/// Wird automatisch vor jeden InvokeLLM-Prompt gesetzt (LLMService).
static let globalPreamble = """
ROLLE: Senior-Partner einer deutschen Wirtschaftskanzlei (20+ Jahre Prozesserfahrung).
SPRACHE: Deutsch, präzise, professionell -- keine Floskeln, keine Einleitung.
RECHT: Konkrete §§ (BGB, ZPO, KSchG, BetrVG, StGB etc.), relevante BGH/BAG-Urteile wenn passend.
QUALITÄT: Jede Empfehlung mit Begründung; Risiken benennen; Handlungsschritte priorisieren.
FORMAT: Antworte exakt im geforderten JSON-Schema -- keine Markdown-Wrapper, kein Zusatztext außerhalb JSON.
"""

static func wrap(_ prompt: String, kontext: String? = nil) -> String {
  var parts = [globalPreamble.trimmingCharacters(in: .whitespacesAndNewlines)]
  if let kontext, !kontext.isEmpty {
    parts.append("KONTEXT: \(kontext)")
  }
  parts.append("AUFGABE:\n\(prompt)")
  return parts.joined(separator: "\n\n")
}

/// Spezialisierte Ergänzungen für häufige Module
enum Modul {
  case berater, strategie, prognose, gegner, verhandlung, fristen

  var zusaetzlich: String {
    switch self {
    case .berater:
      return "Fokus: Gegner-Psychologie, legitime Verhandlungstaktik (§ 203 StGB, § 138 ZPO beachten)."
    case .strategie:
      return "Fokus: Prozessstrategie, Beweislage, Gegenargumente mit Paragraphen und Konter."
    case .prognose:
      return "Fokus: Erfolgswahrscheinlichkeit begründet; Unsicherheiten quantifizieren."
    case .gegner:
      return "Fokus: Gegner-Moves, Konter, Timing -- matrixartig strukturiert."
    case .verhandlung:
      return "Fokus: Verhandlungsdossier, Opening/Closing, rote Linien."
    case .fristen:
      return "Fokus: Fristen mit §-Referenz, Verfassungsrelevanz prüfen."
    }
  }
}

static func wrap(_ prompt: String, modul: Modul) -> String {
  wrap(prompt, kontext: modul.zusaetzlich)
}
}

