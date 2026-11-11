import Foundation

// MARK: - Pseudonymisierer
//
// Ersetzt personenbezogene Angaben durch Platzhalter, BEVOR ein Text das Gerät
// verlässt, und setzt sie in der Antwort wieder ein. Die KI arbeitet dann mit
// "[[PERSON_1]] gegen [[PERSON_2]]" statt mit Klarnamen -- der Sachverhalt
// bleibt verständlich, die Zuordnung bleibt auf dem Gerät.
//
// Grenzen (ehrlich benannt): Erkannt wird, was als Name bekannt ist (aus der
// Akte gemeldet) oder ein festes Muster hat (E-Mail, Telefon, IBAN,
// Aktenzeichen der Instanzgerichte, Anschrift, Geburtsdatum). Ein Name, der
// nirgends hinterlegt ist und nur im Freitext steht, wird NICHT erkannt.
// Pseudonymisierung senkt das Risiko, sie ersetzt keine Entscheidung nach
// § 203 StGB / § 43e BRAO.

public struct Pseudonymisierer: Sendable {

    public enum Art: String, CaseIterable, Sendable {
        case person = "PERSON"
        case email = "EMAIL"
        case telefon = "TELEFON"
        case iban = "IBAN"
        case aktenzeichen = "AZ"
        case anschrift = "ANSCHRIFT"
        case geburtsdatum = "GEBURTSDATUM"
    }

    /// Platzhalter -> Original. Verlässt das Gerät nie.
    public private(set) var zuordnung: [String: String] = [:]
    /// Schlüssel (Art + normalisiertes Original) -> Platzhalter.
    private var vergeben: [String: String] = [:]
    private var zaehler: [String: Int] = [:]
    /// Suchbegriff (klein) -> kanonischer Name. Enthält auch Nachnamen-Aliase.
    private var namensformen: [(suchform: String, kanonisch: String)] = []
    private var eigeneAktenzeichen: [String] = []

    /// Hinweis, der dem Prompt angehängt werden sollte, damit das Modell die
    /// Platzhalter nicht umformuliert.
    public static let prompthinweis =
        "Platzhalter der Form [[PERSON_1]], [[AZ_1]] usw. stehen für geschützte Angaben. "
        + "Übernimm sie zeichengenau und unverändert; erfinde keine Klarnamen dafür."

    public init(bekannteNamen: [String] = [], eigeneAktenzeichen: [String] = []) {
        var formen: [(String, String)] = []
        var gesehen = Set<String>()
        for roh in bekannteNamen {
            let name = Self.gestrafft(roh)
            guard name.count >= 3 else { continue }
            let klein = name.lowercased()
            if gesehen.insert(klein).inserted { formen.append((klein, name)) }
            if let nach = Self.nachnamenAlias(name) {
                let nk = nach.lowercased()
                if gesehen.insert(nk).inserted { formen.append((nk, name)) }
            }
        }
        // Längste zuerst, damit "Müller Bau GmbH" vor "Müller" greift.
        self.namensformen = formen.sorted { $0.0.count > $1.0.count }
            .map { (suchform: $0.0, kanonisch: $0.1) }
        self.eigeneAktenzeichen = eigeneAktenzeichen
            .map(Self.gestrafft).filter { $0.count >= 4 }
            .sorted { $0.count > $1.count }
    }

    /// Zahl der unterschiedlichen geschützten Angaben.
    public var anzahl: Int { zuordnung.count }

    // MARK: Hinweg

    public mutating func pseudonymisiere(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        let ns = text as NSString
        var treffer: [(bereich: NSRange, art: Art, original: String, kanonisch: String?)] = []

        // 1. Bekannte Namen und eigene Aktenzeichen (am zuverlässigsten).
        for form in namensformen {
            for r in Self.vorkommen(von: form.suchform, in: ns, ganzesWort: true) {
                treffer.append((r, .person, ns.substring(with: r), form.kanonisch))
            }
        }
        for az in eigeneAktenzeichen {
            for r in Self.vorkommen(von: az.lowercased(), in: ns, ganzesWort: false) {
                treffer.append((r, .aktenzeichen, ns.substring(with: r), nil))
            }
        }
        // 2. Muster.
        for (art, regex, gruppe) in Self.muster {
            let ganze = NSRange(location: 0, length: ns.length)
            for m in regex.matches(in: text, options: [], range: ganze) {
                let r = m.range(at: gruppe)
                guard r.location != NSNotFound, r.length > 0 else { continue }
                let s = ns.substring(with: r)
                if art == .telefon, s.filter(\.isNumber).count < 7 { continue }
                treffer.append((r, art, s, nil))
            }
        }
        guard !treffer.isEmpty else { return text }

        // Überlappungen auflösen: früher zuerst, bei gleichem Start der längere.
        treffer.sort {
            $0.bereich.location != $1.bereich.location
                ? $0.bereich.location < $1.bereich.location
                : $0.bereich.length > $1.bereich.length
        }
        var gewaehlt: [(NSRange, String)] = []
        var ende = 0
        for t in treffer where t.bereich.location >= ende {
            let platzhalter = platzhalter(fuer: t.art, original: t.kanonisch ?? t.original)
            gewaehlt.append((t.bereich, platzhalter))
            ende = t.bereich.location + t.bereich.length
        }
        let ergebnis = NSMutableString(string: text)
        for (bereich, platzhalter) in gewaehlt.reversed() {
            ergebnis.replaceCharacters(in: bereich, with: platzhalter)
        }
        return ergebnis as String
    }

    // MARK: Rückweg

    /// Setzt die Originale wieder ein. Tolerant gegen kleine Umformungen des
    /// Modells: "[PERSON_1]", "[[ PERSON_1 ]]" und "[[person_1]]" werden erkannt.
    public func wiederherstellen(_ text: String) -> String {
        wiederherstellen(text) { $0 }
    }

    /// Wie `wiederherstellen`, aber für rohen JSON-Text: Anführungszeichen und
    /// Rückstriche im Original werden entschärft, damit das JSON gültig bleibt.
    public func wiederherstellenInJSON(_ text: String) -> String {
        wiederherstellen(text) {
            $0.replacingOccurrences(of: "\\", with: "/")
              .replacingOccurrences(of: "\"", with: "'")
              .replacingOccurrences(of: "\n", with: " ")
        }
    }

    private func wiederherstellen(_ text: String, _ aufbereiten: (String) -> String) -> String {
        guard !zuordnung.isEmpty, text.contains("[") else { return text }
        let ns = text as NSString
        let ergebnis = NSMutableString(string: text)
        let ganze = NSRange(location: 0, length: ns.length)
        for m in Self.platzhalterRegex.matches(in: text, options: [], range: ganze).reversed() {
            let art = ns.substring(with: m.range(at: 1)).uppercased()
            let nr = ns.substring(with: m.range(at: 2))
            if let original = zuordnung["[[\(art)_\(nr)]]"] {
                ergebnis.replaceCharacters(in: m.range, with: aufbereiten(original))
            }
        }
        return ergebnis as String
    }

    // MARK: Intern

    private mutating func platzhalter(fuer art: Art, original: String) -> String {
        let schluessel = art.rawValue + "|" + Self.gestrafft(original).lowercased()
        if let da = vergeben[schluessel] { return da }
        let n = (zaehler[art.rawValue] ?? 0) + 1
        zaehler[art.rawValue] = n
        let p = "[[\(art.rawValue)_\(n)]]"
        vergeben[schluessel] = p
        zuordnung[p] = Self.gestrafft(original)
        return p
    }

    private static func gestrafft(_ s: String) -> String {
        s.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .joined(separator: " ")
    }

    private static let rechtsformen: Set<String> = [
        "gmbh", "ag", "kg", "ohg", "gbr", "ug", "se", "mbh", "e.v.", "ev", "kgaa",
        "co", "co.", "&", "stiftung", "partg", "mbb", "ltd", "ltd.", "inc", "inc.",
        "holding", "gruppe", "group"
    ]

    /// Nachnamen, die zugleich gängige Wörter juristischer Texte sind. Allein
    /// stehend werden sie NICHT ersetzt -- sonst würde aus jedem "Richter" im
    /// Schriftsatz ein Platzhalter.
    private static let mehrdeutigeNachnamen: Set<String> = [
        "richter", "zeuge", "kläger", "klaeger", "anwalt", "notar", "schöffe",
        "vertreter", "meister", "koch", "bauer", "kaufmann", "schuldner",
        "gläubiger", "erbe", "mieter", "vermieter", "verwalter", "vogt",
        "käufer", "verkäufer", "bürge", "herr", "frau", "recht", "gericht"
    ]

    /// Liefert den Nachnamen einer natürlichen Person als zusätzliche Suchform
    /// ("Dr. Hans Müller" -> "Müller"). Für Firmen und Einwortnamen `nil`.
    private static func nachnamenAlias(_ name: String) -> String? {
        let teile = name.split(separator: " ").map(String.init)
        guard teile.count >= 2 else { return nil }
        if teile.contains(where: { rechtsformen.contains($0.lowercased()) }) { return nil }
        guard let letzter = teile.last, letzter.count >= 4,
              let erster = letzter.first, erster.isUppercase,
              !mehrdeutigeNachnamen.contains(letzter.lowercased()) else { return nil }
        return letzter
    }

    private static func vorkommen(von suchformKlein: String, in ns: NSString,
                                  ganzesWort: Bool) -> [NSRange] {
        var ergebnis: [NSRange] = []
        var start = 0
        let laenge = ns.length
        while start < laenge {
            let r = ns.range(of: suchformKlein, options: [.caseInsensitive],
                             range: NSRange(location: start, length: laenge - start))
            if r.location == NSNotFound { break }
            var passt = true
            if ganzesWort {
                if r.location > 0, istWortzeichen(ns.character(at: r.location - 1)) { passt = false }
                let danach = r.location + r.length
                if danach < laenge, istWortzeichen(ns.character(at: danach)) { passt = false }
            }
            if passt { ergebnis.append(r) }
            start = r.location + max(1, r.length)
        }
        return ergebnis
    }

    private static func istWortzeichen(_ c: unichar) -> Bool {
        guard let skalar = Unicode.Scalar(c) else { return true }
        return CharacterSet.alphanumerics.contains(skalar)
    }

    private static func regex(_ muster: String,
                              _ optionen: NSRegularExpression.Options = []) -> NSRegularExpression {
        // Die Muster sind fest im Quelltext; ein Fehler wäre ein Programmierfehler.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: muster, options: optionen)
    }

    private static let platzhalterRegex = regex(
        #"\[{1,2}\s*(PERSON|EMAIL|TELEFON|IBAN|AZ|ANSCHRIFT|GEBURTSDATUM)_(\d+)\s*\]{1,2}"#,
        [.caseInsensitive])

    /// (Art, Muster, Nummer der Gruppe, die ersetzt wird).
    private static let muster: [(Art, NSRegularExpression, Int)] = [
        (.email, regex(#"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, [.caseInsensitive]), 0),
        (.iban, regex(#"\b[A-Z]{2}\d{2}(?:[ ]?[A-Z0-9]{4}){3,7}(?:[ ]?[A-Z0-9]{1,3})?\b"#), 0),
        (.geburtsdatum,
         regex(#"(?:geb\.|geboren am|Geburtsdatum:?)\s*(\d{1,2}\.\s?\d{1,2}\.\s?\d{4})"#,
               [.caseInsensitive]), 1),
        // Aktenzeichen der Instanzgerichte: "12 O 345/23", "5 Sa 12/23", "3 C 44/24".
        // Bundesgerichte (römischer Senat, AZR, BvR, StR ...) bleiben stehen: Das
        // sind veröffentlichte Entscheidungen, die die KI kennen soll.
        (.aktenzeichen,
         regex(#"\b\d{1,4}\s(?!AZR|AZB|AZN|BvR|BvL|BvF|StR|ZR|ZB)[A-Z][A-Za-z]{0,3}(?:\s\([A-Za-z]+\))?\s\d{1,5}/\d{2,4}\b"#), 0),
        (.anschrift,
         regex(#"\b[A-ZÄÖÜ][A-Za-zÄÖÜäöüß.\-]*(?:straße|strasse|str\.|weg|allee|platz|gasse|ring|damm|ufer|chaussee)\s\d{1,4}\s?[a-z]?\b(?:,?\s\d{5}\s[A-ZÄÖÜ][A-Za-zÄÖÜäöüß\-]+)?"#), 0),
        (.telefon,
         regex(#"(?<![\d.,])(?:\+49[ ]?|0049[ ]?|0)\(?\d{2,5}\)?[ /\-]\d{3,}(?:[ \-]?\d{2,})*"#), 0)
    ]
}
