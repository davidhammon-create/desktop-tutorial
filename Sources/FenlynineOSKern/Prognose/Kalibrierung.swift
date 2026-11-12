import Foundation

/// Ein Datensatz je abgeschlossenem Fall -- die Grundlage jeder späteren Kalibrierung.
public struct Prognosedatensatz: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var fallId: String
    public var rechtsgebiet: String
    public var instanz: String
    public var streitwert: Double
    public var anzahlEigeneArgumente: Int
    public var anzahlGegnerArgumente: Int
    public var beweismittelUrkunden: Int
    public var beweismittelZeugen: Int
    public var beweismittelSachverstaendige: Int

    /// Was die App vor Verfahrensende vorhergesagt hat -- unveränderlich. Nur so
    /// wird auf die Wirklichkeit kalibriert und nicht auf die eigene Erwartung.
    public var prognoseVorher: Double
    public var prognoseModellVersion: String
    public var prognoseErstelltAm: Date

    /// Was tatsächlich herauskam (0...1). Wird erst beim Abschluss gesetzt.
    public var tatsaechlicherAusgang: Double?
    /// Urteil, Vergleich, Rücknahme ...
    public var erledigungsart: String?
    public var abgeschlossenAm: Date?

    public init(id: UUID = UUID(),
                fallId: String,
                rechtsgebiet: String,
                instanz: String,
                streitwert: Double,
                anzahlEigeneArgumente: Int = 0,
                anzahlGegnerArgumente: Int = 0,
                beweismittelUrkunden: Int = 0,
                beweismittelZeugen: Int = 0,
                beweismittelSachverstaendige: Int = 0,
                prognoseVorher: Double,
                prognoseModellVersion: String,
                prognoseErstelltAm: Date,
                tatsaechlicherAusgang: Double? = nil,
                erledigungsart: String? = nil,
                abgeschlossenAm: Date? = nil) {
        self.id = id
        self.fallId = fallId
        self.rechtsgebiet = rechtsgebiet
        self.instanz = instanz
        self.streitwert = streitwert
        self.anzahlEigeneArgumente = anzahlEigeneArgumente
        self.anzahlGegnerArgumente = anzahlGegnerArgumente
        self.beweismittelUrkunden = beweismittelUrkunden
        self.beweismittelZeugen = beweismittelZeugen
        self.beweismittelSachverstaendige = beweismittelSachverstaendige
        self.prognoseVorher = prognoseVorher
        self.prognoseModellVersion = prognoseModellVersion
        self.prognoseErstelltAm = prognoseErstelltAm
        self.tatsaechlicherAusgang = tatsaechlicherAusgang
        self.erledigungsart = erledigungsart
        self.abgeschlossenAm = abgeschlossenAm
    }
}

public enum Kalibrierung {

    /// Mindestzahl abgeschlossener Fälle, darunter ist jeder Score Rauschen.
    public static let mindestFaelle = 30

    /// Brier-Score: mittlerer quadratischer Fehler. Muss unter dem Wert der
    /// Grundquote liegen, sonst ist das Modell schlechter als schlichtes Raten.
    public static func brier(_ daten: [Prognosedatensatz]) -> (modell: Double, grundquote: Double)? {
        let fertig = daten.compactMap { d -> (Double, Double)? in
            guard let a = d.tatsaechlicherAusgang else { return nil }
            return (d.prognoseVorher, a)
        }
        guard fertig.count >= mindestFaelle else { return nil }
        let n = Double(fertig.count)
        let basis = fertig.map { $0.1 }.reduce(0, +) / n
        let modell = fertig.map { pow($0.0 - $0.1, 2) }.reduce(0, +) / n
        let referenz = fertig.map { pow(basis - $0.1, 2) }.reduce(0, +) / n
        return (modell, referenz)
    }

    /// Kalibrierungskurve in Zehnergruppen: prognostiziert gegen tatsächlich.
    /// Nur wenn sie nahe der Diagonale liegt, darf die Zahl "63 %" heißen.
    public static func kurve(_ daten: [Prognosedatensatz])
        -> [(bereich: String, prognose: Double, tatsaechlich: Double, n: Int)] {
        var gruppen: [Int: [(Double, Double)]] = [:]
        for d in daten {
            guard let a = d.tatsaechlicherAusgang else { continue }
            // Klammern: 1,0 gehört in die oberste Gruppe, Ausreißer nicht in fremde.
            let bin = min(9, max(0, Int(d.prognoseVorher * 10)))
            gruppen[bin, default: []].append((d.prognoseVorher, a))
        }
        return gruppen.keys.sorted().map { bin in
            let w = gruppen[bin] ?? []
            let n = Double(max(1, w.count))
            return (bereich: "\(bin * 10)-\(bin * 10 + 9) %",
                    prognose: w.map { $0.0 }.reduce(0, +) / n,
                    tatsaechlich: w.map { $0.1 }.reduce(0, +) / n,
                    n: w.count)
        }
    }
}
