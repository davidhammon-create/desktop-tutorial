import Foundation
import SwiftUI
@MainActor
final class DemoKILauf: ObservableObject {
    static let shared = DemoKILauf()
    private init() {}
    struct Eintrag: Identifiable {
        let id = UUID()
        let modul: String
        let aktion: String
        let ergebnis: String
        let erfolg: Bool
        let quelle: String
        let zeit = Date()
    }
    @Published private(set) var laeuft = false
    @Published private(set) var fertig = false
    @Published private(set) var fortschritt: Double = 0
    @Published private(set) var aktuellerSchritt = ""
    @Published private(set) var protokoll: [Eintrag] = []
    private var erledigt = 0
    private var gesamt = 1
    var kiModusLabel: String {
        switch KIKonfiguration.shared.modus {
        case .base44:  return "Base44 Cloud-KI"
        case .appleIntelligence: return "Apple Intelligence (on-device)"
        case .offline: return "Offline-KI (\(KIKonfiguration.shared.offlineModell))"
        }
    }
    var erfolgreiche: Int { protokoll.filter { $0.erfolg }.count }
    var fallbacks: Int { protokoll.filter { !$0.erfolg }.count }
    func starte() async {
        guard !laeuft else { return }
        laeuft = true
        fertig = false
        protokoll = []
        erledigt = 0
        fortschritt = 0
        aktuellerSchritt = "Demofälle sicherstellen …"
        await DemoDataSeeder.seedIfNeeded()
        let vorgaenge = VorgangStore.shared.vorgaenge
        gesamt = max(1, 1 + vorgaenge.count * 2 + 4)
        markiere("Setup", "Demofälle geladen",
                 "\(vorgaenge.count) Vorgänge · Lexara-, Strategos- & Opportunisma-Demos aktiv · KI-Modus: \(kiModusLabel)",
                 erfolg: true, quelle: "System")
        schrittFertig()
        for v in vorgaenge {
            await laufVorgangOptionen(v)
            await laufVorgangArgumente(v)
        }
        await laufFenylaw()
        await laufLexara()
        await laufStrategos()
        await laufOpportunisma()
        aktuellerSchritt = "Abgeschlossen — \(erfolgreiche) KI-Ergebnisse, \(fallbacks) Fallbacks"
        fortschritt = 1
        laeuft = false
        fertig = true
    }
    private func laufVorgangOptionen(_ v: Vorgang) async {
        aktuellerSchritt = "Vorgang · \(v.titel): Optionen"
        let vorschlaege = await VorgangKIService.schlageOptionenVor(fuer: v)
        let text = vorschlaege
            .map { "• \($0.titel) — p≈\(Int(($0.zahl ?? 0) * 100))%" }
            .joined(separator: "\n")
        await logKI(caseId: v.id.uuidString, ki: "Vorgang · Optionen-KI",
                    eingabe: "\(v.titel) · \(v.rechtsgebiet) · \(Int(v.volumen)) €",
                    ausgabe: text, erfolg: !vorschlaege.isEmpty)
        markiere("Vorgang", "\(v.titel) — Handlungsoptionen", text,
                 erfolg: !vorschlaege.isEmpty, quelle: kiModusLabel)
        schrittFertig()
    }
    private func laufVorgangArgumente(_ v: Vorgang) async {
        aktuellerSchritt = "Vorgang · \(v.titel): Argumente"
        guard let option = v.optionen.first else {
            markiere("Vorgang", "\(v.titel) — Argumente", "Keine Option vorhanden", erfolg: false, quelle: "System")
            schrittFertig()
            return
        }
        let args = await VorgangKIService.schlageArgumenteVor(fuer: option, vorgang: v)
        let text = args
            .map { "[\($0.titel)] \($0.text) (\(Int(($0.zahl ?? 0) * 100))%)" }
            .joined(separator: "\n")
        await logKI(caseId: v.id.uuidString, ki: "Vorgang · Argumente-KI",
                    eingabe: "Option: \(option.label)", ausgabe: text, erfolg: !args.isEmpty)
        markiere("Vorgang", "\(v.titel) — Pro/Contra zu „\(option.label)“", text,
                 erfolg: !args.isEmpty, quelle: kiModusLabel)
        schrittFertig()
    }
    private func laufFenylaw() async {
        aktuellerSchritt = "Fenylaw Strategies · Lageanalyse"
        let f = LageFaktoren(
            fristendruck: 0.7, beweisstaerke: 0.6, kostenDruck: 0.5,
            oeffentlichkeit: 0.4, machtAsymmetrie: 0.45,
            informationsVorsprung: 0.55, vergleichBereit: 0.6
        )
        let e = StrategieMotor.analysieren(
            fall: "Kündigungsschutz Müller ./. TechVision — Quellcode-Vorwurf, Vergleich denkbar.",
            gegner: "TechVision GmbH (Series-B, presseaffin)",
            ziel: "Unwirksamkeit feststellen oder Vergleich ≤ 55k €",
            f: f
        )
        let text = "LageScore \(Int(e.lageScore)) — \(e.lageLabel)\n"
            + e.empfehlungen.prefix(4).map { "\($0.prioritaet). \($0.titel)" }.joined(separator: "\n")
        await logKI(caseId: DemoIDs.lexaraCase, ki: "Fenylaw Strategies · Lagescore",
                    eingabe: "Müller ./. TechVision", ausgabe: text, erfolg: true)
        markiere("Fenylaw Strategies", "Lagebild & Empfehlungen", text,
                 erfolg: true, quelle: "Heuristik v1 (deterministisch)")
        schrittFertig()
    }
    private func laufLexara() async {
        aktuellerSchritt = "Lexara · KI-Berater Gegneranalyse"
        let prompt = """
        Fall: Kündigungsschutzklage Müller ./. TechVision GmbH (Arbeitsrecht, § 626 BGB, § 102 BetrVG).
        Vorwurf: Weitergabe von Quellcode. Streitwert 85.000 €, Vergleichsangebot 42.000 €.
        Analysiere kurz und strukturiert: (1) Erfolgsaussicht, (2) stärkster Formangriff,
        (3) Vergleichsband, (4) nächster Schritt. Maximal 8 Sätze.
        """
        await kiSchritt(
            modul: "Lexara", aktion: "KI-Berater — Gegneranalyse",
            caseId: DemoIDs.lexaraCase, kiName: "Lexara · KI-Berater",
            prompt: prompt,
            fallback: "Erfolgsaussicht ~68%. Stärkster Hebel: fehlerhafte BR-Anhörung (§ 102 BetrVG). "
                + "Vergleichsband 45.000–55.000 €. Nächster Schritt: BR-Protokoll anfordern, dann Vergleichsangebot 52k € platzieren."
        )
        schrittFertig()
    }
    private func laufStrategos() async {
        aktuellerSchritt = "Strategos · Unternehmens-Situationsanalyse"
        let prompt = """
        Unternehmen: TechVision GmbH (SaaS, 120 MA, Series-B). Parallele Konflikte: Kündigung Müller
        (Arbeitsrecht) und SLA-Streit mit CloudHost AG (Vertragsrecht). Gesamtexposure ~420k €.
        Erstelle eine knappe Situationsanalyse mit Gesamtrisiko (1–10), 3 kritischen Punkten und
        einer empfohlenen Handlungsoption. Maximal 8 Sätze.
        """
        await kiSchritt(
            modul: "Strategos", aktion: "Unternehmens-Analyse (Multi-Rechtsgebiet)",
            caseId: DemoIDs.strategosEnterprise, kiName: "Strategos · Situationsanalyse",
            prompt: prompt,
            fallback: "Gesamtrisiko 6,8/10. Kritisch: KSchG-Frist, Series-B-Timeline, CloudHost-Kündigungsrecht. "
                + "Empfehlung: parallele Vergleichsstrategie — Exposure von 420k € auf ~55k € reduzierbar."
        )
        schrittFertig()
    }
    private func laufOpportunisma() async {
        aktuellerSchritt = "Opportunisma · Strategische Positionsanalyse"
        let prompt = """
        Mittelständisches Industrieunternehmen (DACH). Ziel: Position in Politik, Wirtschaft und
        Wissenschaft stärken, regulatorische Gestaltungsmacht sichern. Nenne die 3 wirksamsten
        strategischen Züge (Wirksamkeit vs. Risiko) und den größten Positions-Engpass. Maximal 7 Sätze.
        """
        await kiSchritt(
            modul: "Opportunisma", aktion: "Positions- & Strategieanalyse",
            caseId: DemoIDs.strategosEnterprise, kiName: "Opportunisma · Strategieanalyse",
            prompt: prompt,
            fallback: "Züge: (1) Verbands-Lobby EU-Richtlinie (hohe Wirksamkeit, niedriges Risiko), "
                + "(2) Forschungsallianz intensivieren, (3) Compliance als Differenzierung. "
                + "Größter Engpass: politische Sichtbarkeit (Ist 5,5 / Soll 8,0)."
        )
        schrittFertig()
    }
    private func kiSchritt(
        modul: String, aktion: String, caseId: String, kiName: String,
        prompt: String, fallback: String
    ) async {
        do {
            let text = try await LLMService.shared.invokeText(
                prompt: prompt, logCaseId: caseId, logKiName: kiName
            )
            let ausgabe = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if ausgabe.isEmpty {
                await verbucheFallback(modul: modul, aktion: aktion, caseId: caseId, kiName: kiName,
                                       prompt: prompt, fallback: fallback, grund: "Leere KI-Antwort")
            } else {
                markiere(modul, aktion, ausgabe, erfolg: true, quelle: kiModusLabel)
            }
        } catch {
            await verbucheFallback(modul: modul, aktion: aktion, caseId: caseId, kiName: kiName,
                                   prompt: prompt, fallback: fallback, grund: fehlerText(error))
        }
    }
    private func verbucheFallback(
        modul: String, aktion: String, caseId: String, kiName: String,
        prompt: String, fallback: String, grund: String
    ) async {
        await logKI(caseId: caseId, ki: "\(kiName) (Fallback)", eingabe: prompt,
                    ausgabe: fallback, erfolg: false)
        markiere(modul, aktion, "\(fallback)\n\nHinweis: KI nicht erreichbar (\(grund)) — deterministische Heuristik verwendet.",
                 erfolg: false, quelle: "Offline-Heuristik")
    }
    private func logKI(caseId: String?, ki: String, eingabe: String, ausgabe: String, erfolg: Bool) async {
        let log = KIUsageLog(
            id: "demo-run-\(UUID().uuidString.prefix(8))",
            created_at: Date(),
            case_id: caseId,
            ki_function: ki,
            input_summary: String(eingabe.prefix(160)),
            output: String(ausgabe.prefix(800)),
            model: kiModusLabel,
            erfolg: erfolg
        )
        _ = try? await Services.kiUsageLogs.create(log)
    }
    private func markiere(_ modul: String, _ aktion: String, _ ergebnis: String,
                          erfolg: Bool, quelle: String) {
        protokoll.append(.init(modul: modul, aktion: aktion, ergebnis: ergebnis,
                               erfolg: erfolg, quelle: quelle))
    }
    private func schrittFertig() {
        erledigt += 1
        fortschritt = min(1, Double(erledigt) / Double(gesamt))
    }
    private func fehlerText(_ error: Error) -> String {
        if let b = error as? Base44Error {
            return String(describing: b).prefix(80).description
        }
        return error.localizedDescription
    }
}
