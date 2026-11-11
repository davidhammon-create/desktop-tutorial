import Foundation

// MARK: - Belegprüfung
//
// Zwei typische Fehler von Sprachmodellen lassen sich ohne KI erkennen:
//  1. Geldbeträge, die in keiner Eingabe vorkamen (das Modell hat "gerechnet").
//  2. Gerichtsentscheidungen mit Aktenzeichen, die niemand geliefert hat
//     (das Modell kann sie erfunden haben).
// Beides wird nicht verboten, sondern sichtbar gemacht: Der Anwalt sieht, was
// aus seinen Daten stammt und was das Modell hinzugefügt hat.

public enum Belegpruefung {

    public struct Ergebnis: Hashable, Sendable {
        /// Beträge der Antwort, die in den Quellen nicht vorkommen.
        public let unbelegteBetraege: [String]
        /// Beträge der Antwort, die sich in den Quellen wiederfinden.
        public let belegteBetraege: Int
        /// Aktenzeichen der Antwort, die in den Quellen nicht vorkommen.
        public let ungepruefteEntscheidungen: [String]
    }

    public static func pruefe(antwort: String, quellen: String) -> Ergebnis {
        let quellzahlen = alleZahlen(in: quellen)
        var unbelegt: [String] = []
        var belegt = 0
        var gesehen = Set<String>()
        for (roh, wert) in betraege(in: antwort) {
            guard gesehen.insert(wert).inserted else { continue }
            if quellzahlen.contains(wert) { belegt += 1 } else { unbelegt.append(roh) }
        }
        let quelleKlein = normalisiert(quellen)
        var entscheidungen: [String] = []
        var azGesehen = Set<String>()
        for az in aktenzeichen(in: antwort) {
            let n = normalisiert(az)
            guard azGesehen.insert(n).inserted else { continue }
            if !quelleKlein.contains(n) { entscheidungen.append(az) }
        }
        return Ergebnis(unbelegteBetraege: unbelegt, belegteBetraege: belegt,
                        ungepruefteEntscheidungen: entscheidungen)
    }

    // MARK: Bausteine (öffentlich, weil auch die Oberfläche sie zum Markieren nutzt)

    /// Euro-Beträge als (Schreibweise im Text, normalisierter Wert in Cent).
    public static func betraege(in text: String) -> [(roh: String, cent: String)] {
        let ns = text as NSString
        return betragRegex.matches(in: text, options: [],
                                   range: NSRange(location: 0, length: ns.length)).compactMap { m in
            let zahl = ns.substring(with: m.range(at: 1))
            guard let cent = cent(aus: zahl) else { return nil }
            return (ns.substring(with: m.range).trimmingCharacters(in: .whitespaces), cent)
        }
    }

    /// Aktenzeichen von Gerichtsentscheidungen ("VIII ZR 123/21", "2 AZR 45/20",
    /// "1 BvR 12/19", "12 O 345/23").
    public static func aktenzeichen(in text: String) -> [String] {
        let ns = text as NSString
        return azRegex.matches(in: text, options: [],
                               range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range)
        }
    }

    // MARK: Intern

    private static let betragRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"(\d{1,3}(?:[.  ]\d{3})+(?:,\d{1,2})?|\d+(?:,\d{1,2})?)\s?(?:€|EUR\b|Euro\b)"#,
            options: [])
    }()

    private static let zahlRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"\d{1,3}(?:[.  ]\d{3})+(?:,\d{1,2})?|\d+(?:[.,]\d{1,2})?"#, options: [])
    }()

    private static let azRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"\b(?:[IVX]{1,5}[a-z]?|\d{1,4})\s[A-Z][A-Za-z]{0,3}(?:\s\([A-Za-z]+\))?\s\d{1,5}/\d{2,4}\b"#,
            options: [])
    }()

    /// "12.500,50" -> "1250050"; "12500" -> "1250000"; "12500.5" -> "1250050".
    private static func cent(aus roh: String) -> String? {
        var s = roh.replacingOccurrences(of: "\u{00A0}", with: "")
                   .replacingOccurrences(of: " ", with: "")
        var nachkomma = ""
        if let k = s.lastIndex(of: ",") {
            nachkomma = String(s[s.index(after: k)...])
            s = String(s[..<k])
        } else if let p = s.lastIndex(of: "."),
                  s.distance(from: p, to: s.endIndex) <= 3, !istTausenderpunkt(s, p) {
            // Dezimalpunkt (JSON-Zahl wie 12500.5), kein Tausenderpunkt.
            nachkomma = String(s[s.index(after: p)...])
            s = String(s[..<p])
        }
        s = s.replacingOccurrences(of: ".", with: "")
        guard !s.isEmpty, s.allSatisfy(\.isNumber), nachkomma.allSatisfy(\.isNumber) else { return nil }
        let cent = (nachkomma + "00").prefix(2)
        let ganz = String(s.drop(while: { $0 == "0" }))
        return (ganz.isEmpty ? "0" : ganz) + cent
    }

    /// Ein Punkt mit genau drei Ziffern dahinter ist im Deutschen ein Tausenderpunkt.
    private static func istTausenderpunkt(_ s: String, _ p: String.Index) -> Bool {
        s.distance(from: p, to: s.endIndex) == 4
    }

    private static func alleZahlen(in text: String) -> Set<String> {
        let ns = text as NSString
        var menge = Set<String>()
        for m in zahlRegex.matches(in: text, options: [],
                                   range: NSRange(location: 0, length: ns.length)) {
            if let c = cent(aus: ns.substring(with: m.range)) { menge.insert(c) }
        }
        return menge
    }

    private static func normalisiert(_ s: String) -> String {
        s.lowercased().filter { !$0.isWhitespace }
    }
}

// MARK: - Prüfbericht

/// Ergebnis der Nachprüfung einer KI-Antwort. Enthält nur Prüfmerkmale
/// (Normkürzel, Beträge, Aktenzeichen zitierter Entscheidungen), keinen
/// Sachverhalt.
public struct KIPruefbericht: Identifiable, Hashable, Sendable {
    public enum Stufe: Int, Comparable, Sendable {
        case sauber = 0, pruefen = 1, auffaellig = 2
        public static func < (a: Stufe, b: Stufe) -> Bool { a.rawValue < b.rawValue }
    }

    public let id: UUID
    public let erstelltAm: Date
    public let modul: String
    public let modell: String
    /// Zahl der Angaben, die vor dem Versand durch Platzhalter ersetzt wurden.
    public let pseudonymisierteAngaben: Int
    public let normzitateGesamt: Int
    public let auffaelligeNormen: [String]
    public let unbekannteGesetze: [String]
    public let unbelegteBetraege: [String]
    public let belegteBetraege: Int
    public let ungepruefteEntscheidungen: [String]

    public var stufe: Stufe {
        if !auffaelligeNormen.isEmpty { return .auffaellig }
        if !ungepruefteEntscheidungen.isEmpty || !unbelegteBetraege.isEmpty { return .pruefen }
        return .sauber
    }

    /// Ein Satz für die Statuszeile.
    public var kurztext: String {
        switch stufe {
        case .sauber:
            return normzitateGesamt == 0
                ? "Keine Auffälligkeiten"
                : "\(normzitateGesamt) Normzitat\(normzitateGesamt == 1 ? "" : "e") plausibel"
        case .pruefen:
            var teile: [String] = []
            if !ungepruefteEntscheidungen.isEmpty {
                teile.append("\(ungepruefteEntscheidungen.count) zitierte Entscheidung"
                           + "\(ungepruefteEntscheidungen.count == 1 ? "" : "en") nachschlagen")
            }
            if !unbelegteBetraege.isEmpty {
                teile.append("\(unbelegteBetraege.count) Betrag"
                           + "\(unbelegteBetraege.count == 1 ? "" : "e") nicht aus Ihren Daten")
            }
            return teile.joined(separator: " · ")
        case .auffaellig:
            return "\(auffaelligeNormen.count) Normzitat"
                 + "\(auffaelligeNormen.count == 1 ? "" : "e") außerhalb des Gesetzes – prüfen"
        }
    }

    /// Alle Hinweise als Liste, wichtigste zuerst.
    public var hinweise: [String] {
        var h = auffaelligeNormen
        h += ungepruefteEntscheidungen.map {
            "Entscheidung \($0): von der KI genannt, nicht in Ihren Daten – vor Verwendung nachschlagen"
        }
        h += unbelegteBetraege.map {
            "Betrag \($0): stammt nicht aus Ihren Eingaben oder dem Rechenkern"
        }
        h += unbekannteGesetze.map { "\($0): Gesetz nicht im Register – nicht geprüft" }
        return h
    }
}

public enum KIAntwortPruefer {
    /// Prüft eine KI-Antwort gegen die Eingaben.
    /// - Parameters:
    ///   - antwort: Text der Antwort (bei strukturierten Antworten alle Textfelder).
    ///   - quellen: Alles, was dem Modell mitgegeben wurde (Prompt, Kontext, Rechenkern-Fakten).
    public static func pruefe(antwort: String,
                              quellen: String,
                              modul: String,
                              modell: String,
                              pseudonymisierteAngaben: Int = 0,
                              jetzt: Date = Date()) -> KIPruefbericht {
        let normen = NormzitatPruefer.pruefe(antwort)
        let beleg = Belegpruefung.pruefe(antwort: antwort, quellen: quellen)
        var unbekannt: [String] = []
        var gesehen = Set<String>()
        for n in normen where n.status == .gesetzUnbekannt {
            if gesehen.insert(n.zitat.gesetz).inserted { unbekannt.append(n.zitat.gesetz) }
        }
        return KIPruefbericht(
            id: UUID(), erstelltAm: jetzt, modul: modul, modell: modell,
            pseudonymisierteAngaben: pseudonymisierteAngaben,
            normzitateGesamt: normen.count,
            auffaelligeNormen: normen.filter(\.istAuffaellig).map(\.hinweis),
            unbekannteGesetze: unbekannt,
            unbelegteBetraege: beleg.unbelegteBetraege,
            belegteBetraege: beleg.belegteBetraege,
            ungepruefteEntscheidungen: beleg.ungepruefteEntscheidungen)
    }
}
