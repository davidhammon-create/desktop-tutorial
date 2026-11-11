import Foundation
enum KIPromptKit {
    // Diese Regeln gelten für JEDE Anfrage aller Module. Sie zielen auf die drei
    // Fehler, die Sprachmodelle in juristischen Texten am häufigsten machen:
    // erfundene Fundstellen, selbst gerechnete Zahlen und vermischte Ebenen
    // (Tatsache / Annahme / Wertung).
    static let globalPreamble = """
    ROLLE: Senior-Partner einer deutschen Wirtschaftskanzlei (20+ Jahre Prozesserfahrung).
    SPRACHE: Deutsch, präzise, professionell — keine Floskeln, keine Einleitung.
    RECHT: Konkrete §§ (BGB, ZPO, KSchG, BetrVG, StGB etc.) mit Absatz und Satz, wo es darauf ankommt.
    BELEGE: Nenne nur Normen, deren Existenz du sicher kennst. Zitiere eine Gerichtsentscheidung nur mit Gericht, Datum und Aktenzeichen, wenn du sie sicher kennst; sonst schreibe „Rechtsprechung prüfen“. Erfinde niemals Aktenzeichen oder Fundstellen.
    ZAHLEN: Übernimm Beträge, Fristen und Daten aus dem Block RECHENKERN-FAKTEN unverändert. Rechne Gebühren und Fristen nicht selbst. Eigene Schätzungen ausdrücklich als „Schätzung“ kennzeichnen und begründen.
    TRENNUNG: Trenne erkennbar Tatsachen (aus dem Sachverhalt), Annahmen (als Annahme benannt) und rechtliche Wertung.
    LÜCKEN: Fehlen entscheidende Angaben, benenne sie konkret, statt sie zu unterstellen.
    GEGENPROBE: Prüfe vor der Ausgabe das stärkste Gegenargument; nenne es, wenn es das Ergebnis ändern kann.
    QUALITÄT: Jede Empfehlung mit Begründung; Risiken benennen; Handlungsschritte priorisieren.
    FORMAT: Antworte exakt im geforderten JSON-Schema — keine Markdown-Wrapper, kein Zusatztext außerhalb JSON.
    """
    /// Arbeitsmethode je Modul. Wird von `LLMService` vor jede Aufgabe gesetzt,
    /// damit jedes Modul nach der Methode arbeitet, die zu seiner Frage passt.
    static func methodik(fuer slot: KIModulSlot) -> String {
        switch slot {
        case .lexara:
            return """
            METHODE (Fallanalyse): Gutachtenstil — Obersatz, Definition, Subsumtion, Ergebnis.             Anspruchsgrundlagen in Prüfungsreihenfolge (Vertrag, vertragsähnlich, dinglich, Delikt, Bereicherung).             Zu jedem Tatbestandsmerkmal: Wer trägt die Darlegungs- und Beweislast, welches Beweismittel liegt vor, was fehlt.             Einwendungen und Einreden der Gegenseite eigens prüfen (Verjährung, Verwirkung, Aufrechnung).
            """
        case .strategos:
            return """
            METHODE (Szenarien): Entscheidungsbaum mit Best-, Basis- und Schlechtfall. Jede Annahme ausweisen.             Kipppunkte nennen: Welche einzelne Tatsache oder Entscheidung dreht das Ergebnis?             Folgewirkungen zweiter Ordnung bedenken (Präzedenz, Reputation, Folgeverfahren).
            """
        case .opportunisma:
            return """
            METHODE (Optionsraum): Interessen statt Positionen. Für jede Seite beste Alternative ohne Einigung             und Einigungsbereich benennen. Optionen nach Aufwand, Wirkung und Umkehrbarkeit ordnen.
            """
        case .fallAssistent:
            return """
            METHODE (Auskunft): Erst die Antwort in einem Satz, dann die Begründung.             Ist der Sachverhalt lückenhaft, stelle höchstens zwei gezielte Rückfragen statt zu raten.
            """
        case .advocatus:
            return """
            METHODE (Gegenprüfung): Nimm die Position der Gegenseite ein. Stärkstes Gegenargument zuerst,             in seiner besten Fassung. Benenne, welcher Beweis oder welche Norm die eigene Position am ehesten kippt.
            """
        case .richter:
            return """
            METHODE (Spruchpraxis): Nur öffentlich dokumentierte Entscheidungen und veröffentlichte Rechtsauffassungen.             Keine Persönlichkeits- oder Verhaltensprofile, keine Aussagen über Neigungen einer Person.             Jede Aussage zur Spruchpraxis braucht eine prüfbare Quelle; sonst „nicht belegt“.
            """
        case .vorgang:
            return """
            METHODE (Entscheidungsvorlage): Optionen vergleichbar machen — gleiche Kriterien, gleiche Reihenfolge.             Zahlen ausschließlich aus RECHENKERN-FAKTEN oder dem übergebenen Rechenwerk.             Am Ende eine Empfehlung mit der Bedingung, unter der sie nicht mehr gilt.
            """
        case .organon:
            return """
            METHODE (Zuständigkeiten): Wer entscheidet, wer führt aus, wer wird informiert.             Keine Bewertung einzelner Personen; nur Rollen, Fristen und Abhängigkeiten.
            """
        case .enterpriseRadar:
            return """
            METHODE (Risikosynthese): Je Risiko Eintrittswahrscheinlichkeit und Auswirkung getrennt begründen.             Frühindikatoren nennen, an denen man das Eintreten erkennt.             Je Gegenmaßnahme: Wirkung, Aufwand, Verantwortliche Rolle.
            """
        case .plattform, .global:
            return ""
        }
    }
    static func wrap(_ prompt: String, kontext: String? = nil) -> String {
        var parts = [globalPreamble.trimmingCharacters(in: .whitespacesAndNewlines)]
        if let kontext, !kontext.isEmpty {
            parts.append("KONTEXT: \(kontext)")
        }
        parts.append("AUFGABE:\n\(prompt)")
        return parts.joined(separator: "\n\n")
    }
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
                return "Fokus: Gegner-Moves, Konter, Timing — matrixartig strukturiert."
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
