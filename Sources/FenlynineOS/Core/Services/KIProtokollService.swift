import Foundation
enum KIProtokollService {
    static func log(
        caseId: String,
        kiName: String,
        eingabe: String,
        ausgabe: String,
        modell: String = "standard",
        dokumente: [String] = []
    ) async {
        let docsInfo = dokumente.isEmpty ? "" : "\nDokumente: \(dokumente.joined(separator: ", "))"
        let summary = String(eingabe.prefix(500)) + docsInfo
        let entry = KIUsageLog(
            case_id: caseId,
            ki_function: kiName,
            input_summary: summary,
            output: ausgabe,
            model: modell,
            context: kiName,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            funktion: kiName,
            modell: modell,
            erfolg: true
        )
        _ = try? await Services.kiUsageLogs.create(entry)
    }
    static func logResult(
        caseId: String,
        kiName: String,
        eingabe: String,
        result: AnyCodable?,
        modell: String = "claude_sonnet_4_6"
    ) async {
        let ausgabe: String
        if let dict = result?.dictValue {
            let keys = ["gesamtfazit", "zusammenfassung", "empfehlung", "verhandlungs_empfehlung",
                          "gegner_strategie", "strategische_empfehlung", "schriftsatz", "text", "response"]
            ausgabe = keys.compactMap { dict[$0] as? String }.first
                ?? (dict.values.first as? String)
                ?? String(describing: dict).prefix(800).description
        } else if let text = result?.stringValue {
            ausgabe = text
        } else {
            ausgabe = "Analyse abgeschlossen"
        }
        await log(caseId: caseId, kiName: kiName, eingabe: eingabe, ausgabe: ausgabe, modell: modell)
    }
}
