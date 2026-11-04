import Foundation

/// Wie ernst ist ein Befund? Aufsteigend sortiert, damit man Schwellen
/// ("alles ab ernst") einfach vergleichen kann.
public enum Schwere: Int, Codable, Comparable, CaseIterable, Sendable {
    case hinweis = 0
    case auffaellig = 1
    case ernst = 2
    case kritisch = 3

    public static func < (links: Schwere, rechts: Schwere) -> Bool {
        links.rawValue < rechts.rawValue
    }

    /// Wort für die Oberfläche und für den Negativnachweis.
    public var bezeichnung: String {
        switch self {
        case .hinweis: return "Hinweis"
        case .auffaellig: return "auffällig"
        case .ernst: return "ernst"
        case .kritisch: return "kritisch"
        }
    }
}

/// Ein Ergebnis einer Regel: "Hier stimmt etwas nicht -- und das ist der Grund."
///
/// Ein Befund trägt bewusst nur Kennungen (`objektId`, `belegstelle`), niemals
/// Namen, Beträge oder Texte aus dem Fall. Er ist damit gefahrlos zu speichern,
/// zu protokollieren und an Prüfer weiterzugeben.
public struct Befund: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    /// Welche Regel hat das gefunden?
    public let regelId: String
    /// In welcher Fassung? Regeln ändern sich; der Befund muss einer Fassung zuordenbar bleiben.
    public let regelVersion: String
    public let schwere: Schwere
    public let titel: String
    /// Warum ist das ein Problem? In Alltagssprache, ohne Paragrafenkürzel-Deutsch.
    public let erklaerung: String
    /// Kennung des betroffenen Objekts (Frist, Vorgang, Wert, Modul) -- kein Inhalt.
    public let objektId: String?
    /// Verweis auf die Stelle, an der man es nachprüft (z. B. "Herleitung, Schritt 2").
    public let belegstelle: String?
    /// Vorschlag zur Behebung, falls es einen gibt. Nur der Typ `Korrektur` ist möglich.
    public let korrektur: Korrektur?
    /// Rechtsnorm, auf der die Regel beruht (z. B. "§ 233 ZPO").
    public let norm: String?
    public let gefundenAm: Date

    /// Stammt dieser Befund aus der KI-Schicht statt aus dem deterministischen
    /// Regelwerk?
    ///
    /// Das ist sicherheitsrelevant und nicht bloß eine Beschriftung: Ein
    /// KI-Befund wird NIEMALS automatisch ausgeführt, auch nicht auf der Stufe
    /// `selbstheilend` und auch dann nicht, wenn seine Korrektur für sich
    /// genommen harmlos wäre. Sonst könnte ein Sprachmodell über den Umweg
    /// einer scheinbar folgenlosen Korrektur Wirkung entfalten, ohne dass ein
    /// Mensch zugestimmt hat -- genau das, was der ganze Entwurf ausschließen
    /// soll. Die KI darf vorschlagen; drücken muss ein Mensch.
    public let ausKI: Bool

    public init(id: UUID = UUID(),
                regelId: String,
                regelVersion: String,
                schwere: Schwere,
                titel: String,
                erklaerung: String,
                objektId: String? = nil,
                belegstelle: String? = nil,
                korrektur: Korrektur? = nil,
                norm: String? = nil,
                gefundenAm: Date = Date(),
                ausKI: Bool = false) {
        self.id = id
        self.regelId = regelId
        self.regelVersion = regelVersion
        self.schwere = schwere
        self.titel = titel
        self.erklaerung = erklaerung
        self.objektId = objektId
        self.belegstelle = belegstelle
        self.korrektur = korrektur
        self.norm = norm
        self.gefundenAm = gefundenAm
        self.ausKI = ausKI
    }

    /// Kann der Wächter das ohne Rückfrage beheben? Nur wenn es eine Korrektur
    /// gibt, diese automatisch laufen darf UND der Befund nicht aus der KI stammt.
    public var istAutomatischBehebbar: Bool {
        guard !ausKI else { return false }
        return korrektur?.darfAutomatischLaufen ?? false
    }
}
