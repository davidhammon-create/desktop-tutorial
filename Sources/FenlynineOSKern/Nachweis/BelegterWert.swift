import Foundation

/// Ein Wert mit Herkunft. Ersetzt jede nackte Konstante im Programm, damit jederzeit
/// sichtbar ist, woher eine Zahl stammt und wie alt sie ist.
public struct BelegterWert<T: Codable>: Codable {
    public var wert: T
    /// z. B. "Anlage 2 RVG"
    public var quelle: String
    /// z. B. "Stufe bis 25.000 EUR"
    public var fundstelle: String
    public var abgerufenAm: Date
    /// URL oder "Gesetzestext, gedruckt"
    public var abgerufenVon: String
    /// Wenn bekannt.
    public var gueltigBis: Date?
    /// Wer hat nachgeschlagen.
    public var geprueftVon: String

    public init(wert: T,
                quelle: String,
                fundstelle: String,
                abgerufenAm: Date,
                abgerufenVon: String,
                gueltigBis: Date? = nil,
                geprueftVon: String) {
        self.wert = wert
        self.quelle = quelle
        self.fundstelle = fundstelle
        self.abgerufenAm = abgerufenAm
        self.abgerufenVon = abgerufenVon
        self.gueltigBis = gueltigBis
        self.geprueftVon = geprueftVon
    }

    /// Warnschwelle für die Oberfläche: Gebühren und Sätze ändern sich meist
    /// jährlich, nach 13 Monaten ist ein Abruf deshalb mindestens einmal überholt.
    public var istVeraltet: Bool {
        istVeraltet(stand: Date())
    }

    /// Mit festem Stichtag, damit Tests und Belege nicht von der Uhr abhängen.
    public func istVeraltet(stand: Date) -> Bool {
        if let g = gueltigBis, g < stand { return true }
        return stand.timeIntervalSince(abgerufenAm) > 400 * 24 * 3600   // > 13 Monate
    }

    public var herkunftstext: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .none
        return "\(quelle), \(fundstelle). Geprüft von \(geprueftVon) am \(f.string(from: abgerufenAm))."
    }
}
