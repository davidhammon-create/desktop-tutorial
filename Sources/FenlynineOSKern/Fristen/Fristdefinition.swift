import Foundation

/// Einheit einer Frist (§ 188 BGB).
public enum Fristeinheit: String, Codable, Hashable, Sendable {
    case tage, wochen, monate, jahre
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

    /// Zusätzliche Höchstfrist, die unabhängig von der Zustellung läuft
    /// (z. B. § 517 ZPO: fünf Monate ab Verkündung).
    public let hoechstfristMonateAbVerkuendung: Int?

    public init(laenge: Int,
                einheit: Fristeinheit,
                anfang: Anfangsregel,
                norm: String,
                istNotfrist: Bool,
                verlaengerbar: Bool,
                hinweis: String? = nil,
                hoechstfristMonateAbVerkuendung: Int? = nil) {
        self.laenge = laenge
        self.einheit = einheit
        self.anfang = anfang
        self.norm = norm
        self.istNotfrist = istNotfrist
        self.verlaengerbar = verlaengerbar
        self.hinweis = hinweis
        self.hoechstfristMonateAbVerkuendung = hoechstfristMonateAbVerkuendung
    }
}
