import Foundation
struct VorgangKIVorschlag: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var art: String          // "option" | "p_erfolg" | "argument" | "frist"
    var titel: String
    var text: String
    var zahl: Double?
    var bestaetigt: Bool = false
}
enum VorgangKIService {
    @MainActor
    static func schlageOptionenVor(fuer vorgang: Vorgang) async -> [VorgangKIVorschlag] {
        let prompt = """
        Du bist Rechtsanalyst. Vorgang: \(vorgang.titel)
        Typ: \(vorgang.typ.bezeichnung). Beschreibung: \(vorgang.beschreibung)
        Volumen: \(Int(vorgang.volumen)) €. Rechtsgebiet: \(vorgang.rechtsgebiet)
        Gib 3–4 Handlungsoptionen als JSON-Array:
        [{"titel":"…","text":"…","p_erfolg":0.0-1.0}]
        Nur JSON, keine Prosa.
        """
        do {
            let roh = try await LLMService.shared.invokeText(
                prompt: "Antworte ausschließlich mit gültigem JSON-Array.\n\n" + prompt
            )
            return parseOptionen(roh)
        } catch {
            return offlineOptionen(fuer: vorgang)
        }
    }
    @MainActor
    static func schlageArgumenteVor(fuer option: VorgangOption, vorgang: Vorgang) async -> [VorgangKIVorschlag] {
        let prompt = """
        Option „\(option.label)“ im Vorgang „\(vorgang.titel)“.
        Gib 2 Pro- und 2 Contra-Argumente als JSON:
        [{"seite":"pro"|"contra","text":"…","gewicht":0.0-1.0}]
        """
        do {
            let roh = try await LLMService.shared.invokeText(
                prompt: "Nur JSON-Array.\n\n" + prompt
            )
            return parseArgumente(roh)
        } catch {
            return [
                .init(art: "argument", titel: "pro", text: "Starke rechtliche Ausgangslage bei \(vorgang.rechtsgebiet).", zahl: 0.7),
                .init(art: "argument", titel: "contra", text: "Prozessrisiko und Kosten können den EV drücken.", zahl: 0.55)
            ]
        }
    }
    @MainActor
    static func uebernehmeAlsOptionen(_ vorschlaege: [VorgangKIVorschlag], in store: VorgangStore, vorgangId: UUID) {
        for v in vorschlaege where v.art == "option" {
            let p = min(0.95, max(0.05, v.zahl ?? 0.5))
            let option = VorgangOption(
                label: v.titel,
                beschreibung: v.text,
                kosten: .init(anwalt: 15_000, gericht: 5_000, intern: 2_000, opportunitaet: 3_000),
                chancen: .init(
                    pErfolg: .ki(p, modell: "FenlynineOS-KI"),
                    best: .mensch(store.vorgang(vorgangId)?.volumen ?? 100_000, name: "System"),
                    worst: .mensch(-(store.vorgang(vorgangId)?.volumen ?? 50_000) * 0.3, name: "System"),
                    likely: .formel(0, "wird berechnet")
                ),
                zeit: .init(minMonate: 3, maxMonate: 18),
                qualitativ: .init(reputation: 0, beziehung: 0, medien: 0, praezedenz: 0)
            )
            store.fuegeOptionHinzu(vorgangId, option, wer: "KI (unbestätigt)")
        }
        store.bewerteAlleOptionen(vorgangId)
        store.setzeEmpfehlung(vorgangId)
    }
    private static func parseOptionen(_ roh: String) -> [VorgangKIVorschlag] {
        guard let data = roh.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return offlineOptionen(fuer: nil) }
        return arr.prefix(4).compactMap { d in
            guard let titel = d["titel"] as? String else { return nil }
            let text = d["text"] as? String ?? ""
            let p = (d["p_erfolg"] as? Double) ?? (d["p_erfolg"] as? NSNumber)?.doubleValue
            return .init(art: "option", titel: titel, text: text, zahl: p)
        }
    }
    private static func parseArgumente(_ roh: String) -> [VorgangKIVorschlag] {
        guard let data = roh.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return arr.prefix(6).compactMap { d in
            let seite = d["seite"] as? String ?? "pro"
            let text = d["text"] as? String ?? ""
            let g = (d["gewicht"] as? Double) ?? 0.5
            return .init(art: "argument", titel: seite, text: text, zahl: g)
        }
    }
    private static func offlineOptionen(fuer vorgang: Vorgang?) -> [VorgangKIVorschlag] {
        let typ = vorgang?.typ ?? .streit
        switch typ {
        case .streit:
            return [
                .init(art: "option", titel: "A · Vergleich anbieten", text: "Früh vergleichen, Kosten und Zeit sparen.", zahl: 0.72),
                .init(art: "option", titel: "B · Klage volle Instanz", text: "Durchfechten — höheres Upside, längere Dauer.", zahl: 0.55),
                .init(art: "option", titel: "C · Abfindung fordern", text: "Mittlerer Weg mit klarer Schmerzgrenze.", zahl: 0.65),
                .init(art: "option", titel: "D · Nichts tun", text: "Frist verstreichen lassen — immer durchgerechnet.", zahl: 0.05)
            ]
        case .gestaltung:
            return [
                .init(art: "option", titel: "A · Legale Optimierung", text: "Compliance-sicher, niedriger RPN.", zahl: 0.90),
                .init(art: "option", titel: "B · Aggressive Struktur", text: "Höheres Upside, erhöhtes Prüfrisiko.", zahl: 0.55),
                .init(art: "option", titel: "C · Status quo", text: "Nichts ändern — Opportunitätskosten.", zahl: 0.40)
            ]
        default:
            return [
                .init(art: "option", titel: "A · Empfohlener Pfad", text: "Basierend auf Sachverhalt.", zahl: 0.70),
                .init(art: "option", titel: "B · Alternativpfad", text: "Zweitrangige Option.", zahl: 0.50)
            ]
        }
    }
}
