import Foundation

// MARK: - Arbeitsfluss
//
// Verbindet die Module zu einem Ablauf: Aus dem Stand einer Akte wird
// abgeleitet, welcher Schritt als Nächstes ansteht und in welchem Modul er
// erledigt wird. Das ist reine Regelarbeit -- keine KI, kein Netz, bei
// gleichem Stand immer dieselbe Empfehlung.
//
// Die Reihenfolge folgt der anwaltlichen Sorgfalt: Fristen vor allem anderen
// (Haftung), dann die Grundlagen der Akte, dann Darlegung und Beweis, dann
// Bewertung und Verhandlung, zuletzt die Nacharbeit.
//
// Der Aktenstand enthält nur Zählwerte und Ja/Nein-Merkmale, keine Inhalte.

public struct Aktenstand: Hashable, Sendable {
    public var akteId: String
    public var istAbgeschlossen: Bool
    public var hatRechtsfrage: Bool
    public var hatProzessziel: Bool
    public var hatStreitwert: Bool
    public var hatPrognose: Bool
    public var hatVergleichsangebot: Bool
    /// Bei abgeschlossenen Akten: Ist der Ausgang festgehalten?
    public var hatErgebnis: Bool
    public var eigeneArgumente: Int
    public var gegnerArgumente: Int
    public var eigeneArgumenteOhneBeweis: Int
    public var beweismittel: Int
    public var dokumente: Int
    public var offeneFristen: Int
    /// Offene Fristen, deren Fälligkeit bereits vorbei ist.
    public var ueberfaelligeFristen: Int
    /// Tage bis zur nächsten offenen, noch nicht abgelaufenen Frist.
    public var tageBisNaechsteFrist: Int?

    public init(akteId: String,
                istAbgeschlossen: Bool = false,
                hatRechtsfrage: Bool = false,
                hatProzessziel: Bool = false,
                hatStreitwert: Bool = false,
                hatPrognose: Bool = false,
                hatVergleichsangebot: Bool = false,
                hatErgebnis: Bool = false,
                eigeneArgumente: Int = 0,
                gegnerArgumente: Int = 0,
                eigeneArgumenteOhneBeweis: Int = 0,
                beweismittel: Int = 0,
                dokumente: Int = 0,
                offeneFristen: Int = 0,
                ueberfaelligeFristen: Int = 0,
                tageBisNaechsteFrist: Int? = nil) {
        self.akteId = akteId
        self.istAbgeschlossen = istAbgeschlossen
        self.hatRechtsfrage = hatRechtsfrage
        self.hatProzessziel = hatProzessziel
        self.hatStreitwert = hatStreitwert
        self.hatPrognose = hatPrognose
        self.hatVergleichsangebot = hatVergleichsangebot
        self.hatErgebnis = hatErgebnis
        self.eigeneArgumente = eigeneArgumente
        self.gegnerArgumente = gegnerArgumente
        self.eigeneArgumenteOhneBeweis = eigeneArgumenteOhneBeweis
        self.beweismittel = beweismittel
        self.dokumente = dokumente
        self.offeneFristen = offeneFristen
        self.ueberfaelligeFristen = ueberfaelligeFristen
        self.tageBisNaechsteFrist = tageBisNaechsteFrist
    }
}

public struct Arbeitsschritt: Hashable, Sendable, Identifiable {
    public enum Dringlichkeit: Int, Comparable, Sendable, CaseIterable {
        case empfohlen = 0, wichtig = 1, kritisch = 2
        public static func < (a: Dringlichkeit, b: Dringlichkeit) -> Bool { a.rawValue < b.rawValue }
        public var bezeichnung: String {
            switch self {
            case .kritisch: return "Sofort"
            case .wichtig: return "Diese Woche"
            case .empfohlen: return "Empfohlen"
            }
        }
    }

    public var id: String { akteId + "|" + regel }
    public let akteId: String
    /// Stabile Kennung der Regel, z. B. "frist.ueberfaellig".
    public let regel: String
    /// Kennung des Moduls, in dem der Schritt erledigt wird
    /// (entspricht `SeitenleistenEintrag.rawValue`).
    public let modulId: String
    public let titel: String
    public let grund: String
    public let dringlichkeit: Dringlichkeit
    /// Position im Ablauf; kleinere Zahl = früher.
    public let rang: Int
}

public enum Arbeitsfluss {

    public static let version = "1"

    /// Die offenen Schritte einer Akte, wichtigste zuerst.
    public static func naechsteSchritte(_ s: Aktenstand) -> [Arbeitsschritt] {
        var r: [Arbeitsschritt] = []
        func schritt(_ regel: String, _ modul: String, _ titel: String, _ grund: String,
                     _ d: Arbeitsschritt.Dringlichkeit, _ rang: Int) {
            r.append(Arbeitsschritt(akteId: s.akteId, regel: regel, modulId: modul, titel: titel,
                                    grund: grund, dringlichkeit: d, rang: rang))
        }

        if s.istAbgeschlossen {
            if !s.hatErgebnis {
                schritt("abschluss.ergebnis", "lexara", "Ausgang festhalten",
                        "Ohne festgehaltenen Ausgang lernt die Prognose nichts aus dieser Akte.",
                        .empfohlen, 90)
            }
            if s.offeneFristen > 0 {
                schritt("abschluss.fristen", "zeitleiste", "Offene Fristen der abgeschlossenen Akte klären",
                        "Die Akte ist abgeschlossen, es stehen aber noch \(s.offeneFristen) Fristen offen.",
                        .wichtig, 20)
            }
            return sortiert(r)
        }

        // 1 · Fristen -- vor allem anderen.
        if s.ueberfaelligeFristen > 0 {
            schritt("frist.ueberfaellig", "zeitleiste", "Abgelaufene Frist prüfen",
                    "\(s.ueberfaelligeFristen) offene Frist\(s.ueberfaelligeFristen == 1 ? " ist" : "en sind") abgelaufen. "
                    + "Erledigung nachtragen oder Wiedereinsetzung prüfen (§ 233 ZPO).",
                    .kritisch, 1)
        }
        if let tage = s.tageBisNaechsteFrist {
            if tage <= 3 {
                schritt("frist.akut", "zeitleiste",
                        tage == 0 ? "Frist läuft heute ab" : "Frist läuft in \(tage) Tag\(tage == 1 ? "" : "en") ab",
                        "Schriftsatz fertigstellen und Ausgangskontrolle durchführen.",
                        .kritisch, 2)
            } else if tage <= 10 {
                schritt("frist.nah", "zeitleiste", "Frist in \(tage) Tagen",
                        "Bearbeitung jetzt einplanen; bei verlängerbaren Fristen Antrag rechtzeitig stellen.",
                        .wichtig, 10)
            }
        }
        if s.offeneFristen == 0 {
            schritt("frist.keine", "zeitleiste", "Fristen erfassen",
                    "In der laufenden Akte ist keine Frist notiert. Prüfen, ob wirklich keine läuft.",
                    .wichtig, 11)
        }

        // 2 · Grundlagen der Akte.
        if !s.hatProzessziel || !s.hatRechtsfrage {
            schritt("basis.ziel", "lexara", "Ziel und Rechtsfrage festlegen",
                    "Ohne Prozessziel und zentrale Rechtsfrage lassen sich Argumente nicht gewichten.",
                    .wichtig, 20)
        }
        if s.dokumente == 0 {
            schritt("basis.dokumente", "dokumente", "Unterlagen zur Akte nehmen",
                    "Zu dieser Akte ist noch kein Dokument hinterlegt.", .empfohlen, 25)
        }

        // 3 · Darlegung und Beweis.
        if s.eigeneArgumente == 0 {
            schritt("vortrag.argumente", "lexara", "Eigene Argumente erfassen",
                    "Die Akte enthält noch kein eigenes Argument.", .wichtig, 30)
        } else {
            if s.eigeneArgumenteOhneBeweis > 0 {
                schritt("vortrag.beweis", "lexara", "Beweis zu jedem Argument zuordnen",
                        "\(s.eigeneArgumenteOhneBeweis) eigene\(s.eigeneArgumenteOhneBeweis == 1 ? "s Argument hat" : " Argumente haben") "
                        + "kein Beweismittel. Wer die Beweislast trägt, verliert ohne Beweis.",
                        .wichtig, 31)
            }
            if s.gegnerArgumente == 0 {
                schritt("vortrag.gegenseite", "lexara", "Vortrag der Gegenseite durchdenken",
                        "Es ist kein Argument der Gegenseite erfasst. Einwendungen vorab zu kennen, "
                        + "verhindert Überraschungen im Termin.",
                        .empfohlen, 35)
            }
        }

        // 4 · Bewertung.
        if !s.hatStreitwert {
            schritt("bewertung.streitwert", "lexara", "Streitwert eintragen",
                    "Ohne Streitwert kann das Kostenrisiko nicht berechnet werden.", .empfohlen, 40)
        }
        if !s.hatPrognose && s.eigeneArgumente >= 2 {
            schritt("bewertung.prognose", "lexara", "Erfolgsaussicht bewerten",
                    "Argumente liegen vor, eine Prognose fehlt. Sie ist Grundlage für die Beratung "
                    + "über das Prozessrisiko.",
                    .empfohlen, 45)
        }

        // 5 · Verhandlung.
        if s.hatVergleichsangebot {
            if s.hatPrognose && s.hatStreitwert {
                schritt("verhandlung.pruefen", "strategos", "Vergleichsangebot gegen Erwartungswert prüfen",
                        "Ein Angebot liegt vor; Prognose und Streitwert sind bekannt. Jetzt lässt sich "
                        + "rechnen, ob der Vergleich besser ist als das Urteil.",
                        .wichtig, 50)
            } else {
                schritt("verhandlung.grundlage", "lexara", "Grundlage für die Vergleichsprüfung schaffen",
                        "Ein Angebot liegt vor, aber Prognose oder Streitwert fehlen. Ohne beides ist "
                        + "keine belastbare Empfehlung möglich.",
                        .wichtig, 49)
            }
        }
        return sortiert(r)
    }

    /// Die wichtigsten Schritte über alle Akten. Je Akte höchstens
    /// `jeAkte` Schritte, damit eine einzelne Akte die Liste nicht füllt.
    public static func uebersicht(_ staende: [Aktenstand], limit: Int = 12,
                                  jeAkte: Int = 2) -> [Arbeitsschritt] {
        let alle = staende.flatMap { Array(naechsteSchritte($0).prefix(max(1, jeAkte))) }
        return Array(sortiert(alle).prefix(max(0, limit)))
    }

    private static func sortiert(_ s: [Arbeitsschritt]) -> [Arbeitsschritt] {
        s.sorted {
            if $0.dringlichkeit != $1.dringlichkeit { return $0.dringlichkeit > $1.dringlichkeit }
            if $0.rang != $1.rang { return $0.rang < $1.rang }
            return $0.id < $1.id
        }
    }
}
