import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// KI-Funktionen über Apple Intelligence (FoundationModels-Framework):
/// Das Sprachmodell läuft ON-DEVICE — kostenlos, ohne API-Schlüssel, ohne
/// dass Kontodaten das Gerät verlassen. Verfügbar ab iOS 26 / macOS 26 auf
/// Apple-Intelligence-fähigen Geräten; ältere Systeme bekommen eine klare
/// Nicht-verfügbar-Meldung statt eines Absturzes.
///
/// Ehrlicher Hinweis: Das On-Device-Modell hat KEINEN Internetzugang.
/// Firmen-Einschätzungen basieren auf Modellwissen + den lokalen Daten
/// (IBAN-Land, Betrag, Muster) — keine Live-Web-Recherche wie in der
/// Web-App mit Anthropic-Key.
enum AppleAI {

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
            return false
        }
        #endif
        return false
    }

    static var availabilityText: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "Apple Intelligence verfügbar — Analysen laufen kostenlos auf diesem Gerät."
            case .unavailable(let reason):
                return "Apple Intelligence nicht verfügbar: \(String(describing: reason)). In den Systemeinstellungen aktivieren oder Gerät prüfen."
            @unknown default:
                return "Apple Intelligence: Status unbekannt."
            }
        }
        #endif
        return "Apple Intelligence benötigt iOS 26 / macOS 26 auf einem Apple-Intelligence-fähigen Gerät."
    }

    /// Freie Text-Antwort vom On-Device-Modell.
    static func respond(to prompt: String, instructions: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            return response.content
        }
        #endif
        throw NSError(domain: "AppleAI", code: 1, userInfo: [NSLocalizedDescriptionKey: availabilityText])
    }

    /// Seriositäts-Einschätzung zu einem Abo (on-device, ohne Web).
    static func companyAssessment(for sub: Subscription) async throws -> String {
        let country = String(RecurrenceScanner.ibanKey(sub.iban).prefix(2))
        let prompt = """
        Schätze die Seriosität dieser wiederkehrenden Abbuchung ein:
        Firma: \(sub.name)
        Betrag: \(sub.amount.euro) \(sub.cycle)
        IBAN-Land: \(country.isEmpty ? "unbekannt" : country)
        Kategorie: \(sub.category)
        Hinweise aus dem Algorithmus-Scan: \(sub.note.isEmpty ? "keine" : sub.note)

        Bewerte in 3-5 Sätzen auf Deutsch: Ist der Anbieter wahrscheinlich seriös? \
        Ist der Betrag plausibel? Worauf sollte man achten? \
        Formuliere als Wahrscheinlichkeits-Einschätzung, nicht als Tatsache. \
        Wichtig: Du hast keinen Internetzugang — sage ehrlich, wenn dir die Firma unbekannt ist.
        """
        return try await respond(to: prompt, instructions: "Du bist ein vorsichtiger Finanz-Sicherheits-Analyst. Antworte kurz, konkret, auf Deutsch.")
    }

    /// Kündigungsschreiben generieren (on-device).
    static func cancellationLetter(for sub: Subscription) async throws -> String {
        let prompt = """
        Verfasse eine kurze, höfliche, aber bestimmte Kündigung für das Abo \
        „\(sub.name)“ (Kunde seit \(sub.sinceMonth)). Deutsch, zum nächstmöglichen \
        ordentlichen Termin, mit Bitte um schriftliche Bestätigung. \
        Format: Betreffzeile, dann Brieftext.
        """
        return try await respond(to: prompt, instructions: "Du schreibst präzise deutsche Geschäftsbriefe.")
    }

    /// Markt-Einschätzung zu einer Anlage (on-device, ohne Live-Daten).
    static func investNote(for asset: InvestAsset, monthly: Double, years: Int) async throws -> String {
        let prompt = """
        Ein Nutzer überlegt, \(monthly.euro) monatlich über \(years) Jahre in \
        „\(asset.name)“ (\(asset.assetClass), historisch ~\(asset.ret)% p.a., Risiko: \(asset.risk)) zu investieren. \
        Erkläre in 4-6 Sätzen auf Deutsch: Wie hat sich diese Anlageklasse historisch entwickelt, \
        welche aktuellen strukturellen Trends und Kausalzusammenhänge sprechen dafür oder dagegen, \
        und was wäre eine realistische Erwartung? Betone, dass du keine Live-Marktdaten hast \
        und das keine Anlageberatung ist.
        """
        return try await respond(to: prompt, instructions: "Du bist ein nüchterner Finanz-Erklärer. Keine Übertreibungen, keine Garantien.")
    }
}
