import Foundation
import SwiftUI
@MainActor
@Observable
final class EnterpriseRadarStore {
    static let shared = EnterpriseRadarStore()
    var eigen: ERUnternehmen
    var wettbewerber: [ERUnternehmen]
    var ergebnis: ERErgebnis?
    var verlauf: [ERErgebnis] = []
    var kiLaeuft = false
    var kiFehler: String?
    var letzteDauerMs: Double = 0
    private let profilKey = "enterprise_radar_profile_v1"
    private let verlaufKey = "enterprise_radar_verlauf_v1"
    private struct Profile: Codable {
        var eigen: ERUnternehmen
        var wettbewerber: [ERUnternehmen]
    }
    private init() {
        if let p: Profile = ImperiumDisk.load(profilKey, as: Profile.self) {
            eigen = p.eigen
            wettbewerber = p.wettbewerber
        } else {
            eigen = ERUnternehmen.leer(rolle: .eigen)
            var w = ERUnternehmen.leer(rolle: .konkurrent)
            w.name = "Wettbewerber A"
            wettbewerber = [w]
        }
        verlauf = ImperiumDisk.load(verlaufKey, as: [ERErgebnis].self) ?? []
        if let letztes = verlauf.first { ergebnis = letztes }
    }
    func speichereProfile() {
        ImperiumDisk.save(Profile(eigen: eigen, wettbewerber: wettbewerber), key: profilKey)
    }
    func wettbewerberHinzufuegen() {
        var w = ERUnternehmen.leer(rolle: .konkurrent)
        w.name = "Wettbewerber \(Character(UnicodeScalar(65 + min(25, wettbewerber.count))!))"
        w.branche = eigen.branche
        w.sitz = eigen.sitz
        wettbewerber.append(w)
        speichereProfile()
    }
    func wettbewerberEntfernen(_ id: String) {
        wettbewerber.removeAll { $0.id == id }
        speichereProfile()
    }
    func signalUmschalten(_ s: ERSignal, bei id: String) {
        if eigen.id == id {
            if eigen.signale.contains(s) { eigen.signale.remove(s) } else { eigen.signale.insert(s) }
        } else if let i = wettbewerber.firstIndex(where: { $0.id == id }) {
            if wettbewerber[i].signale.contains(s) { wettbewerber[i].signale.remove(s) } else { wettbewerber[i].signale.insert(s) }
        }
        speichereProfile()
    }
    func unternehmen(_ id: String) -> ERUnternehmen? {
        if eigen.id == id { return eigen }
        return wettbewerber.first { $0.id == id }
    }
    func aktualisiere(_ u: ERUnternehmen) {
        if eigen.id == u.id { eigen = u }
        else if let i = wettbewerber.firstIndex(where: { $0.id == u.id }) { wettbewerber[i] = u }
        speichereProfile()
    }
    @discardableResult
    func analysiere() -> ERErgebnis {
        let start = DispatchTime.now()
        speichereProfile()
        let e = EnterpriseRadarEngine.analysiere(eigen: eigen, wettbewerber: wettbewerber)
        letzteDauerMs = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
        ergebnis = e
        verlauf.insert(e, at: 0)
        if verlauf.count > 12 { verlauf = Array(verlauf.prefix(12)) }
        ImperiumDisk.save(verlauf, key: verlaufKey)
        return e
    }
    func kiVertiefen() async {
        guard let e = ergebnis, !kiLaeuft else { return }
        kiLaeuft = true
        kiFehler = nil
        defer { kiLaeuft = false }
        do {
            let synthese = try await EnterpriseRadarKI.synthese(fuer: e)
            ergebnis?.kiSynthese = synthese
            if let aktuell = ergebnis, let i = verlauf.firstIndex(where: { $0.id == aktuell.id }) {
                verlauf[i] = aktuell
                ImperiumDisk.save(verlauf, key: verlaufKey)
            }
        } catch {
            kiFehler = error.localizedDescription
        }
    }
    func insJournal() {
        guard let e = ergebnis else { return }
        let top = e.strategien.first
        let detail = """
        Gesamtrisiko eigen: \(e.gesamtscoreEigen)/100 · Resilienz \(e.resilienzIndex) · Vorteilsindex \(e.vorteilsIndex)
        Top-Risiken: \(e.topRisiken.map { "\($0.dimension.titel) (\($0.score))" }.joined(separator: ", "))
        Wettbewerber: \(e.wettbewerber.map(\.name).joined(separator: ", "))
        Schwachstellen Konkurrenz: \(e.wettbewerberSchwachstellen.prefix(3).map(\.titel).joined(separator: " | "))
        Beste Strategie: \(top.map { "\($0.titel) — P=\($0.erfolgswahrscheinlichkeit) %" } ?? "—")
        """
        ImperiumEntscheidungsJournal.shared.eintrag(
            typ: .strategie,
            titel: "Enterprise-Radar: \(e.eigen.name)",
            detail: detail,
            module: ["Enterprise-Radar", "Strategos", "Opportunisma"]
        )
    }
    func exportMarkdown() -> String {
        guard let e = ergebnis else { return "" }
        var md = "# Enterprise-Radar — \(e.eigen.name)\n\n_\(e.zeitpunkt.formatted()) · Regel-Engine \(EnterpriseRadarEngine.regeln.count) Regeln · \(e.simulationen.first?.laeufe ?? 0) Simulationsläufe je Strategie_\n\n"
        md += "## Lage\n- Gesamtrisiko: **\(e.gesamtscoreEigen)/100**\n- Resilienzindex: \(e.resilienzIndex)\n- Vorteilsindex: \(e.vorteilsIndex)\n\n"
        md += "## Risikomatrix (eigen)\n| Dimension | Score | Befunde |\n|---|---|---|\n"
        for s in e.eigeneScores.sorted(by: { $0.score > $1.score }) {
            md += "| \(s.dimension.titel) | \(s.score) | \(s.befunde.map(\.titel).joined(separator: "; ")) |\n"
        }
        md += "\n## Schwachstellen Wettbewerber\n"
        for s in e.wettbewerberSchwachstellen.prefix(10) {
            md += "- **\(s.unternehmenName)** · \(s.titel) — Hebel \(s.hebelIndex) (Ausnutzbarkeit \(s.ausnutzbarkeit), Nachweis \(s.nachweisbarkeit))\n"
        }
        md += "\n## Wettbewerbsvorteile\n"
        for v in e.vorteile.prefix(10) {
            md += "### \(v.typ.titel) · \(v.titel)\n\(v.mechanik)\n\n- Rechtsgrundlage: \(v.rechtsgrundlage.joined(separator: ", "))\n- Aktivlegitimation: \(v.aktivlegitimation)\n- Leitplanken: \(v.leitplanken)\n- Netto-Hebel: \(v.nettoHebel) · Zeitfenster: \(v.zeitfenster)\n\n"
        }
        md += "## Strategien\n"
        for s in e.strategien {
            md += "### \(s.archetyp.titel): \(s.titel)\n_\(s.archetyp.prinzip)_\n\n**Ziel:** \(s.ziel)\n\n"
            for (i, z) in s.zuege.enumerated() { md += "\(i + 1). \(z.schritt) — _\(z.verantwortlich), \(z.frist)\(z.norm.map { ", \($0)" } ?? "")_\n" }
            if let sim = e.simulationen.first(where: { $0.strategieId == s.id }) {
                md += "\n- Erfolgsquote: \(sim.erfolgsquote) % · P10/P50/P90: \(sim.p10)/\(sim.p50)/\(sim.p90)\n"
            }
            md += "- Gegenreaktion: \(s.gegenreaktion)\n- Leitplanken: \(s.leitplanken)\n\n"
        }
        if let k = e.kiSynthese {
            md += "## KI-Synthese (\(k.modell))\n\(k.executiveSummary)\n\n**Verborgene Risiken**\n" + k.verborgeneRisiken.map { "- \($0)" }.joined(separator: "\n")
            md += "\n\n**Erwartete Gegenzüge**\n" + k.gegenzuegeDesWettbewerbers.map { "- \($0)" }.joined(separator: "\n")
            md += "\n\n**Prioritäten**\n" + k.prioritaeten.map { "- \($0)" }.joined(separator: "\n") + "\n"
        }
        md += "\n---\n_Keine Rechtsberatung. Regelkatalog Stand 10/2026 — Stichtage vor Nutzung gegenprüfen._\n"
        return md
    }
}
enum EnterpriseRadarKI {
    static func synthese(fuer e: ERErgebnis) async throws -> ERKISynthese {
        let kompakt = EnterpriseRadarEngine.kompaktFuerKI(e)
        let prompt = """
        Du bist General Counsel und Chefstratege eines Konzerns. Du erhältst das Ergebnis einer deterministischen Rechtsrisiko-Engine (DE/EU).
        Liefere, was Regeln nicht sehen — immer aus RECHTLICHER Perspektive, nur zulässige Mittel:
        1. executive_summary (max. 120 Wörter, Vorstandssprache).
        2. verborgene_risiken: 3–5 Querverbindungen (1 Satz + Norm).
        3. gegenzuege: 3–4 realistische Rival-Reaktionen.
        4. prioritaeten: 4–5 Handlungen mit Zeithorizont und Verantwortlichem.
        5. unternehmens_dynamik: 4–6 Einträge zu den genannten Unternehmen — plausible Ursachen für Kurs-/Umsatz-/Gewinn-/Investitionsänderung und jeweils kurzfristige, mittelfristige und langfristige Folge (Format: „Ursache → kurz: … · mittel: … · lang: …“). Nutze die im Kontext genannten Fakten; erfinde keine Insider-Zahlen.
        6. massnahmen_folgen: 4–6 Einträge „Maßnahme → nutzen/nicht nutzen → positive Folge / negative Folge“ (Compliance, Verträge, IP, Governance, Wettbewerb — legal).
        7. wissenschaftliche_strategien: 3–5 Strategien inkl. Bezug zu wissenschaftlich/empirisch bekannten Ansätzen (z. B. Resource-Based View, Dynamic Capabilities, Stakeholder-Theorie, Compliance-as-Strategy) — jeweils 1–2 Sätze und rechtliche Leitplanke.
        8. macht_erhalt: 3–4 konkrete rechtliche Schritte zum Erhalt/Beibehalten erworbener Position.
        9. macht_wegnahme_legal: 3–4 zulässige Hebel gegen Rival-Schwächen (kein Kartell, keine Anschwärzung, kein unlauterer Boykott).
        Nur Deutsch. Keine Einleitung. Keine illegalen Handlungsanleitungen.
        \(kompakt)
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "executive_summary": ["type": "string"],
                "verborgene_risiken": ["type": "array", "items": ["type": "string"]],
                "gegenzuege": ["type": "array", "items": ["type": "string"]],
                "prioritaeten": ["type": "array", "items": ["type": "string"]],
                "unternehmens_dynamik": ["type": "array", "items": ["type": "string"]],
                "massnahmen_folgen": ["type": "array", "items": ["type": "string"]],
                "wissenschaftliche_strategien": ["type": "array", "items": ["type": "string"]],
                "macht_erhalt": ["type": "array", "items": ["type": "string"]],
                "macht_wegnahme_legal": ["type": "array", "items": ["type": "string"]]
            ] as [String: Any],
            "required": ["executive_summary", "verborgene_risiken", "gegenzuege", "prioritaeten",
                         "unternehmens_dynamik", "massnahmen_folgen", "wissenschaftliche_strategien",
                         "macht_erhalt", "macht_wegnahme_legal"]
        ]
        let modell = "claude_sonnet_4_6"
        let result: AnyCodable = try await LLMService.shared.invoke(
            prompt: prompt,
            schema: schema,
            model: modell,
            transparenzLabel: "Enterprise-Radar Synthese",
            logKiName: "strategos_enterprise_radar"
        )
        let d = try KIJson.requireObject(result, kontext: "Enterprise-Radar")
        return ERKISynthese(
            executiveSummary: KIJson.string(in: d, keys: "executive_summary", "summary") ?? "",
            verborgeneRisiken: KIJson.stringList(in: d, keys: "verborgene_risiken"),
            gegenzuegeDesWettbewerbers: KIJson.stringList(in: d, keys: "gegenzuege"),
            prioritaeten: KIJson.stringList(in: d, keys: "prioritaeten"),
            unternehmensDynamik: KIJson.stringList(in: d, keys: "unternehmens_dynamik"),
            massnahmenFolgen: KIJson.stringList(in: d, keys: "massnahmen_folgen", "masnahmen_folgen"),
            wissenschaftlicheStrategien: KIJson.stringList(in: d, keys: "wissenschaftliche_strategien"),
            machtErhalt: KIJson.stringList(in: d, keys: "macht_erhalt"),
            machtWegnahmeLegal: KIJson.stringList(in: d, keys: "macht_wegnahme_legal"),
            modell: modell,
            zeitpunkt: .now
        )
    }
}
