import Foundation

// MARK: - KI-Verbindungs- & Modell-Health-Check

struct KIHealthResult: Identifiable {
let id = UUID()
var modell: String
var ok: Bool
var latencyMs: Int
var message: String
}

enum KIHealthCheck {
static func runAll() async -> [KIHealthResult] {
  await withTaskGroup(of: KIHealthResult.self) { group in
    for model in ["claude_sonnet_4_6", "gemini_3_flash", "gpt_5"] {
      group.addTask { await probe(model: model) }
    }
    var results: [KIHealthResult] = []
    for await r in group { results.append(r) }
    return results.sorted { $0.modell < $1.modell }
  }
}

private static func probe(model: String) async -> KIHealthResult {
  let start = Date()
  do {
    let _: String = try await LLMService.shared.invokeText(
      prompt: "Antworte nur mit dem Wort OK.",
      model: model
    )
    let ms = Int(Date().timeIntervalSince(start) * 1000)
    return KIHealthResult(modell: model, ok: true, latencyMs: ms, message: "Verbindung OK")
  } catch {
    let ms = Int(Date().timeIntervalSince(start) * 1000)
    return KIHealthResult(modell: model, ok: false, latencyMs: ms, message: error.localizedDescription)
  }
}
}

