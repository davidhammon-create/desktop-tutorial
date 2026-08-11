import Foundation

// MARK: - Lexara « Strategos Live-Kontext-Bridge

enum LexaraStrategosBridge {

struct SyncResult {
  var briefing: [String: Any]
  var contextPatch: [String: Any]
}

/// Lädt Lexara-Falldaten und erzeugt Strategos-Kontext + KI-Briefing.
static func sync(caseId: String) async throws -> SyncResult {
  let fall = try await Services.cases.get(id: caseId)
  async let args = Services.arguments.listForCase(caseId: caseId)
  async let evs = Services.evidence.listForCase(caseId: caseId)
  async let dead = Services.deadlines.listForCase(caseId: caseId)
  let (argumente, beweise, fristen) = try await (args, evs, dead)

  let gp = fall.gegner_profil?.dictValue ?? [:]
  let eigen = argumente.filter { $0.side == .eigen }
  let gegner = argumente.filter { $0.side == .gegner }

  let sachverhalt = [
    fall.zentrale_rechtsfrage,
    fall.prozessziel,
    fall.notes
  ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }
    .joined(separator: ". ")

  let briefing: [String: Any] = [
    "synced_at": ISO8601DateFormatter().string(from: Date()),
    "case_id": caseId,
    "fallname": fall.fallname,
    "aktenzeichen": fall.aktenzeichen ?? "",
    "rechtsgebiet": fall.rechtsgebiet ?? "",
    "prognose_pct": Int(fall.prognose ?? 50),
    "streitwert": fall.streitwert ?? 0,
    "eigene_argumente": eigen.map { ["titel": $0.title, "staerke": $0.strength] },
    "gegner_argumente": gegner.map { ["titel": $0.title, "staerke": $0.strength] },
    "beweise": beweise.map { ["titel": $0.title, "gewicht": $0.weight] },
    "offene_fristen": fristen.filter { $0.status == .offen }.map {
      ["titel": $0.title, "datum": ISO8601DateFormatter().string(from: $0.due_date)]
    },
    "gegner_profil": gp,
    "ki_berater_kurz": (fall.ki_berater_result?.dictValue?["empfehlung"] as? String) ?? "",
    "lexara_checkliste": eigen.prefix(5).map(\.title) + fristen.prefix(3).map(\.title)
  ]

  var contextPatch: [String: Any] = [
    "lexara_case_id": caseId,
    "sachverhalt_lang": sachverhalt.isEmpty
      ? "Lexara-Fall \(fall.fallname): \(fall.rechtsgebiet ?? "Recht") -- Prognose \(Int(fall.prognose ?? 50))%."
      : sachverhalt,
    "gegner_name": gp["gegner_name"] as? String ?? gegner.first?.title ?? "",
    "situationstyp": "bestehende_situation"
  ]
  if let rg = fall.rechtsgebiet, !rg.isEmpty {
    contextPatch["rechtsgebiete"] = [mapRechtsgebiet(rg)]
  }

  return SyncResult(briefing: briefing, contextPatch: contextPatch)
}

/// Wendet Sync auf ein Strategos-Szenario an und speichert es.
static func apply(to szenario: inout StrategosScenario, sync: SyncResult) async throws -> StrategosScenario {
  var ctx = szenario.unternehmenskontext?.dictValue ?? [:]
  for (k, v) in sync.contextPatch { ctx[k] = v }

  var kiKontext = szenario.ki_kontext?.dictValue ?? [:]
  kiKontext["lexara_briefing"] = sync.briefing
  kiKontext["lexara_sync"] = ["synced": true, "at": sync.briefing["synced_at"] ?? ""]

  szenario.unternehmenskontext = AnyCodable(ctx)
  szenario.ki_kontext = AnyCodable(kiKontext)
  szenario.lexara_sync = AnyCodable(["synced": true, "case_id": sync.briefing["case_id"] ?? ""])
  szenario.case_id = sync.briefing["case_id"] as? String

  guard let id = szenario.id else { return szenario }
  return try await Services.strategosScenarios.update(id: id, entity: szenario)
}

private static func mapRechtsgebiet(_ rg: String) -> String {
  let lower = rg.lowercased()
  if lower.contains("arbeits") { return "arbeitsrecht" }
  if lower.contains("vertrag") { return "vertragsrecht_buergerliches_recht" }
  if lower.contains("straf") { return "strafrecht" }
  if lower.contains("gesellschaft") { return "gesellschaftsrecht" }
  return "vertragsrecht_buergerliches_recht"
}
}

