import Foundation

/// Einheit einer Frist (§ 188 BGB).
public enum Fristeinheit: String, Codable, Hashable, Sendable {
    case tage, wochen, monate, jahre

    /// Grammatisch richtige Bezeichnung. Der Klartext der Herleitung geht in die
    /// Handakte und gegebenenfalls in einen Schriftsatz -- dort steht "1 Monat",
    /// nicht "1 monate".
    public func bezeichnung(anzahl: Int) -> String {
        switch self {
        case .tage:   return anzahl == 1 ? "Tag"   : "Tage"
        case .wochen: return anzahl == 1 ? "Woche" : "Wochen"
        case .monate: return anzahl == 1 ? "Monat" : "Monate"
        case .jahre:  return anzahl == 1 ? "Jahr"  : "Jahre"
        }
    }
}

/// Anfangsregel einer Frist (§ 187 BGB).
public enum Anfangsregel: String, Codable, Hashable, Sendable {
    /// § 187 Abs. 1 BGB: Der Ereignistag zählt nicht mit (Ereignisfrist).
    case ereignis
    /// § 187 Abs. 2 BGB: Der Anfangstag wird mitgerechnet (Beginnfrist).
    case beginn
}

/// Rechtliche Beschreibung einer Fristart: Länge, Einheit, Anfangsregel, Norm
/// und die Angabe, ob es sich um eine Notfrist handelt.
public struct Fristdefinition: Codable, Hashable, Sendable {
    public let laenge: Int
    public let einheit: Fristeinheit
    public let anfang: Anfangsregel
    /// Rechtsgrundlage, z. B. "§ 517 ZPO".
    public let norm: String
    /// Notfrist im Sinne des § 224 ZPO: weder verlängerbar noch abkürzbar.
    public let istNotfrist: Bool
    public let verlaengerbar: Bool
    public let hinweis: String?

    /// Spätester Fristbeginn, unabhängig von der Zustellung.
    ///
    /// § 517 ZPO: Die Berufungsfrist "beginnt mit der Zustellung des in vollständiger
    /// Form abgefassten Urteils, spätestens aber mit dem Ablauf von fünf Monaten nach
    /// der Verkündung". Die fünf Monate kappen also den BEGINN, nicht das Ende --
    /// ohne Zustellung endet die Frist sechs Monate nach Verkündung, nicht fünf.
    /// Eine Kappung des Endes würde die Frist um einen Monat verkürzen und bei dieser
    /// Notfrist zur Unzulässigkeit des Rechtsmittels führen.
    public let spaetesterBeginnMonateAbVerkuendung: Int?

    public init(laenge: Int,
                einheit: Fristeinheit,
                anfang: Anfangsregel,
                norm: String,
                istNotfrist: Bool,
                verlaengerbar: Bool,
                hinweis: String? = nil,
                spaetesterBeginnMonateAbVerkuendung: Int? = nil) {
        self.laenge = laenge
        self.einheit = einheit
        self.anfang = anfang
        self.norm = norm
        self.istNotfrist = istNotfrist
        self.verlaengerbar = verlaengerbar
        self.hinweis = hinweis
        self.spaetesterBeginnMonateAbVerkuendung = spaetesterBeginnMonateAbVerkuendung
    }
}
