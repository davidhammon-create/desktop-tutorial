import Foundation

/// Schlanke Schnittstelle zu den Kosten. Das Modul bleibt dadurch eigenständig;
/// `Kostenrisiko` o. Ä. kann das Protokoll per Extension erfüllen.
public protocol KostenBasis {
    /// Alle Kosten, die bei vollständigem Unterliegen anfallen (eigene + gegnerische + Gericht).
    var gesamtkostenBeiNiederlage: Double { get }
    /// Eigene nicht erstattete Kosten bei vollständigem Obsiegen.
    var eigeneKostenBeiSieg: Double { get }
}

/// Alle Annahmen, die in eine Bewertung eingehen -- ausnahmslos vom Menschen gesetzt.
/// Die Willkür verschwindet nicht, wechselt aber zu dem, der sie verantworten kann.
public struct Annahmen: Codable, Hashable, Sendable {
    /// Erfolgswahrscheinlichkeit im Hauptpunkt, wie vom Anwalt eingeschätzt (0...1).
    public var erfolgswahrscheinlichkeit: Double
    /// Unsicherheit dieser Einschätzung (0...1), z. B. 0,15 = plus/minus 15 Punkte.
    public var unsicherheit: Double
    public var streitwert: Double
    /// 0...1
    public var vergleichsbereitschaftGegner: Double
    public var erwarteteVerfahrensdauerMonate: Int

    /// Wer hat die Annahme gesetzt und wann -- gehört in die Akte.
    public var gesetztVon: String
    public var gesetztAm: Date
    /// Pflichtfeld, nicht optional.
    public var begruendung: String

    public init(erfolgswahrscheinlichkeit: Double,
                unsicherheit: Double,
                streitwert: Double,
                vergleichsbereitschaftGegner: Double,
                erwarteteVerfahrensdauerMonate: Int,
                gesetztVon: String,
                gesetztAm: Date,
                begruendung: String) {
        self.erfolgswahrscheinlichkeit = erfolgswahrscheinlichkeit
        self.unsicherheit = unsicherheit
        self.streitwert = streitwert
        self.vergleichsbereitschaftGegner = vergleichsbereitschaftGegner
        self.erwarteteVerfahrensdauerMonate = erwarteteVerfahrensdauerMonate
        self.gesetztVon = gesetztVon
        self.gesetztAm = gesetztAm
        self.begruendung = begruendung
    }

    /// Vorschlagswerte für ein leeres Formular. Bewusst neutral: 50 % heißt
    /// "keine Ahnung", nicht "ausgewogen". Die App darf hier NIE eine
    /// rechtsgebietsspezifische Zahl vorbelegen -- sie wäre erfunden und würde
    /// als Anker auf die Einschätzung des Anwalts wirken.
    public static func neutralerStart(streitwert: Double, nutzer: String) -> Annahmen {
        Annahmen(erfolgswahrscheinlichkeit: 0.5,
                 unsicherheit: 0.2,
                 streitwert: streitwert,
                 vergleichsbereitschaftGegner: 0.5,
                 erwarteteVerfahrensdauerMonate: 12,
                 gesetztVon: nutzer,
                 gesetztAm: Date(),
                 begruendung: "")
    }
}

/// Eine Zeile der Tornado-Analyse.
public struct Empfindlichkeit: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let annahme: String
    public let basisWert: Double
    public let ergebnisBasis: Double
    /// Annahme um eine Stufe schlechter.
    public let ergebnisNiedrig: Double
    /// Annahme um eine Stufe besser.
    public let ergebnisHoch: Double

    public init(id: UUID = UUID(),
                annahme: String,
                basisWert: Double,
                ergebnisBasis: Double,
                ergebnisNiedrig: Double,
                ergebnisHoch: Double) {
        self.id = id
        self.annahme = annahme
        self.basisWert = basisWert
        self.ergebnisBasis = ergebnisBasis
        self.ergebnisNiedrig = ergebnisNiedrig
        self.ergebnisHoch = ergebnisHoch
    }

    public var spannweite: Double { abs(ergebnisHoch - ergebnisNiedrig) }
}

/// Statt einer Punktprognose zeigt die App, wie empfindlich das Ergebnis auf jede
/// Annahme reagiert: "Worauf kommt es an?" ist beantwortbar, "Wie geht es aus?" nicht.
public enum Szenariorechner {

    /// Erwartungswert: rein arithmetisch, keine verborgenen Konstanten.
    public static func erwartungswert<K: KostenBasis>(_ a: Annahmen, kosten: K) -> Double {
        a.erfolgswahrscheinlichkeit * (a.streitwert - kosten.eigeneKostenBeiSieg)
            - (1 - a.erfolgswahrscheinlichkeit) * kosten.gesamtkostenBeiNiederlage
    }

    /// Tornado-Analyse: welche Annahme bewegt das Ergebnis am stärksten?
    /// Absteigend nach Spannweite sortiert.
    public static func empfindlichkeiten<K: KostenBasis>(_ a: Annahmen, kosten: K) -> [Empfindlichkeit] {
        let basis = erwartungswert(a, kosten: kosten)
        var out: [Empfindlichkeit] = []

        var tief = a
        tief.erfolgswahrscheinlichkeit = max(0, a.erfolgswahrscheinlichkeit - a.unsicherheit)
        var hoch = a
        hoch.erfolgswahrscheinlichkeit = min(1, a.erfolgswahrscheinlichkeit + a.unsicherheit)
        out.append(Empfindlichkeit(annahme: "Erfolgswahrscheinlichkeit",
                                   basisWert: a.erfolgswahrscheinlichkeit,
                                   ergebnisBasis: basis,
                                   ergebnisNiedrig: erwartungswert(tief, kosten: kosten),
                                   ergebnisHoch: erwartungswert(hoch, kosten: kosten)))

        var sTief = a
        sTief.streitwert = a.streitwert * 0.8
        var sHoch = a
        sHoch.streitwert = a.streitwert * 1.2
        out.append(Empfindlichkeit(annahme: "Streitwert plus/minus 20 %",
                                   basisWert: a.streitwert,
                                   ergebnisBasis: basis,
                                   ergebnisNiedrig: erwartungswert(sTief, kosten: kosten),
                                   ergebnisHoch: erwartungswert(sHoch, kosten: kosten)))

        return out.sorted { $0.spannweite > $1.spannweite }
    }

    /// Der Kipppunkt: ab welcher Erfolgswahrscheinlichkeit lohnt das Verfahren?
    /// Die Zahl ist ehrlich, weil sie nichts prognostiziert, sondern eine Bedingung
    /// nennt, die der Anwalt selbst beurteilen kann. Nullstelle von
    /// p * gewinn - (1 - p) * verlust.
    public static func kipppunkt<K: KostenBasis>(streitwert: Double, kosten: K) -> Double {
        let gewinn = streitwert - kosten.eigeneKostenBeiSieg
        let verlust = kosten.gesamtkostenBeiNiederlage
        guard gewinn + verlust > 0 else { return 1 }
        return verlust / (gewinn + verlust)
    }
}
