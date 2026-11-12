import Foundation

// MARK: - Normzitat-Prüfung
//
// Sprachmodelle erfinden gelegentlich Paragraphen. Diese Prüfung liest jedes
// Normzitat aus einer KI-Antwort und gleicht es mit einem Register ab: Gibt es
// das Gesetz, und liegt die Nummer im Bereich, den das Gesetz überhaupt hat?
//
// Was die Prüfung NICHT kann: feststellen, ob die Norm inhaltlich passt. Sie
// fängt den groben Fehler ("§ 3120 BGB"), nicht den feinen ("§ 280 statt § 281").
// Ein Befund heißt deshalb immer "bitte prüfen", nie "falsch".

public struct Normzitat: Hashable, Sendable, Codable {
    /// So stand es im Text, z. B. "§ 280 Abs. 1 BGB".
    public let roh: String
    public let gesetz: String
    public let nummer: Int
    /// Buchstabenzusatz, z. B. "a" bei § 312a.
    public let zusatz: String
    public let istArtikel: Bool

    public var kurz: String {
        "\(istArtikel ? "Art." : "§") \(nummer)\(zusatz) \(gesetz)"
    }
}

public enum Normstatus: Hashable, Sendable {
    /// Gesetz bekannt, Nummer im Bereich.
    case plausibel
    /// Gesetz bekannt, Nummer liegt über dem letzten bekannten Paragraphen.
    case ausserhalbBereich(hoechstwert: Int)
    /// "§" verwendet, das Gesetz zählt aber in Artikeln (oder umgekehrt).
    case falscheZaehlart
    /// Gesetz steht nicht im Register -- keine Aussage möglich.
    case gesetzUnbekannt
}

public struct Normbefund: Hashable, Sendable {
    public let zitat: Normzitat
    public let status: Normstatus

    public var istAuffaellig: Bool {
        switch status {
        case .ausserhalbBereich, .falscheZaehlart: return true
        case .plausibel, .gesetzUnbekannt: return false
        }
    }

    public var hinweis: String {
        switch status {
        case .plausibel:
            return "\(zitat.kurz): im Register plausibel"
        case let .ausserhalbBereich(max):
            return "\(zitat.kurz): liegt außerhalb des bekannten Bereichs "
                 + "(\(zitat.gesetz) endet nach Registerstand bei \(max)) – bitte prüfen"
        case .falscheZaehlart:
            return "\(zitat.kurz): \(zitat.gesetz) wird üblicherweise mit "
                 + "\(zitat.istArtikel ? "§" : "Art.") zitiert – bitte prüfen"
        case .gesetzUnbekannt:
            return "\(zitat.kurz): Gesetz nicht im Register – nicht geprüft"
        }
    }
}

// MARK: - Register

/// Höchste Paragraphen- bzw. Artikelnummer je Gesetz.
///
/// HERKUNFT: aus dem Gedächtnis zusammengestellt, NICHT gegen die amtlichen
/// Fassungen geprüft. Die Werte dienen nur als Plausibilitätsgrenze; im Zweifel
/// sind sie eher zu hoch als zu niedrig angesetzt, damit kein echtes Zitat
/// beanstandet wird. Vor Auslieferung gegen gesetze-im-internet.de prüfen und
/// `geprueft` auf `true` setzen.
public enum Gesetzesregister {
    public static let stand = "2026-11 (ungeprüft)"
    public static let geprueft = false

    public struct Eintrag: Sendable {
        public let hoechstwert: Int
        public let zaehltInArtikeln: Bool
    }

    public static let eintraege: [String: Eintrag] = {
        var r: [String: Eintrag] = [:]
        let paragraphen: [(String, Int)] = [
            ("BGB", 2385), ("ZPO", 1120), ("StGB", 358), ("StPO", 500),
            ("HGB", 905), ("KSchG", 26), ("BetrVG", 132), ("ArbGG", 122),
            ("InsO", 359), ("AktG", 410), ("GmbHG", 88), ("VwGO", 195),
            ("VwVfG", 103), ("RVG", 62), ("GKG", 73), ("BDSG", 86),
            ("UWG", 20), ("UrhG", 143), ("PatG", 147), ("MarkenG", 165),
            ("WEG", 49), ("StVG", 66), ("StVO", 53), ("AO", 417),
            ("UStG", 29), ("BRAO", 215), ("FamFG", 493), ("GVG", 202),
            ("VVG", 216), ("AGG", 33), ("TzBfG", 23), ("BUrlG", 16),
            ("ArbZG", 26), ("MiLoG", 24), ("EFZG", 13), ("GWB", 187),
            ("OWiG", 135), ("ZVG", 186), ("ProdHaftG", 19), ("BauGB", 250),
            ("PartGG", 11), ("EntgFG", 13)
        ]
        for (g, max) in paragraphen { r[g] = Eintrag(hoechstwert: max, zaehltInArtikeln: false) }
        let artikel: [(String, Int)] = [
            ("GG", 146), ("DSGVO", 99), ("DS-GVO", 99), ("EGBGB", 253),
            ("AEUV", 358), ("EUV", 55), ("EMRK", 59), ("GRCh", 54)
        ]
        for (g, max) in artikel { r[g] = Eintrag(hoechstwert: max, zaehltInArtikeln: true) }
        return r
    }()
}

// MARK: - Prüfer

public enum NormzitatPruefer {

    /// Alle Normzitate eines Textes, in Lesereihenfolge, ohne Dubletten.
    public static func zitate(in text: String) -> [Normzitat] {
        guard text.contains("§") || text.contains("Art") else { return [] }
        let ns = text as NSString
        var ergebnis: [Normzitat] = []
        var gesehen = Set<String>()
        let ganze = NSRange(location: 0, length: ns.length)
        for m in zitatRegex.matches(in: text, options: [], range: ganze) {
            let zeichen = ns.substring(with: m.range(at: 1))
            let mitte = ns.substring(with: m.range(at: 2))
            let gesetz = ns.substring(with: m.range(at: 3))
            guard !keineGesetze.contains(gesetz) else { continue }
            let istArtikel = zeichen.hasPrefix("A")
            let mehrere = zeichen == "§§"
            guard let nummern = nummern(aus: mitte, mehrere: mehrere), !nummern.isEmpty else { continue }
            let roh = ns.substring(with: m.range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            for (n, zusatz) in nummern {
                let z = Normzitat(roh: roh, gesetz: gesetz, nummer: n, zusatz: zusatz,
                                  istArtikel: istArtikel)
                if gesehen.insert(z.kurz).inserted { ergebnis.append(z) }
            }
        }
        return ergebnis
    }

    public static func pruefe(_ text: String) -> [Normbefund] {
        zitate(in: text).map { z in
            guard let e = Gesetzesregister.eintraege[z.gesetz] else {
                return Normbefund(zitat: z, status: .gesetzUnbekannt)
            }
            if z.nummer < 1 || z.nummer > e.hoechstwert {
                return Normbefund(zitat: z, status: .ausserhalbBereich(hoechstwert: e.hoechstwert))
            }
            if e.zaehltInArtikeln != z.istArtikel {
                return Normbefund(zitat: z, status: .falscheZaehlart)
            }
            return Normbefund(zitat: z, status: .plausibel)
        }
    }

    // MARK: Intern

    /// Zeichen, Mittelteil (Nummern, Absätze, Sätze), Gesetzeskürzel.
    /// Das Kürzel braucht mindestens zwei Großbuchstaben ("BGB", "BetrVG",
    /// "DS-GVO"); so wird "§ 3 des Vertrags" nicht als Normzitat gelesen.
    private static let zitatRegex: NSRegularExpression = {
        let kuerzel = #"((?:[A-ZÄÖÜ][a-zäöü]*){2,}[A-ZÄÖÜa-zäöü]*(?:-[A-Z]{2,})?)"#
        let muster = #"(§§|§|Art\.|Artikel)\s*([0-9][0-9a-zA-Z .,/()–\-]{0,70}?)\s+"# + kuerzel + #"\b"#
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: muster, options: [])
    }()

    /// Großgeschriebene Wörter, die auf ein Zitat folgen können, aber kein Gesetz sind.
    private static let keineGesetze: Set<String> = ["AGB", "EU", "EG", "BRD", "USA", "II", "III", "IV", "VI", "VII", "VIII", "IX", "XI", "XII"]

    private static let untergliederung: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"(?:Abs\.|Absatz|S\.|Satz|Nr\.|Nummer|lit\.|Buchst\.|Alt\.|Hs\.|Halbs\.|Var\.|UAbs\.)\s*(?:\d+[a-z]?|[a-z]\b)(?:\s*(?:,|und|bis|-|–)\s*(?:\d+[a-z]?\b))*"#,
            options: [])
    }()

    private static let nummerRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: #"(\d+)\s?([a-z])?\b"#, options: [])
    }()

    private static let fuellwoerter: Set<String> = [
        "und", "bis", "ff", "f", "der", "des", "iVm", "i", "V", "m", "vom", "oder", "sowie"
    ]

    /// Paragraphennummern aus dem Mittelteil. `nil`, wenn der Mittelteil nach
    /// Abzug von Nummern und Untergliederungen noch Fremdtext enthält -- dann
    /// gehört das Kürzel am Ende vermutlich nicht zu diesem "§".
    private static func nummern(aus mitte: String, mehrere: Bool) -> [(Int, String)]? {
        let ohneAbs = untergliederung.stringByReplacingMatches(
            in: mitte, options: [], range: NSRange(location: 0, length: (mitte as NSString).length),
            withTemplate: " ")
        let ns = ohneAbs as NSString
        var gefunden: [(Int, String)] = []
        for m in nummerRegex.matches(in: ohneAbs, options: [],
                                     range: NSRange(location: 0, length: ns.length)) {
            guard let n = Int(ns.substring(with: m.range(at: 1))) else { continue }
            let zr = m.range(at: 2)
            let zusatz = zr.location == NSNotFound ? "" : ns.substring(with: zr)
            gefunden.append((n, zusatz))
        }
        // Fremdtext? Alles außer Nummern, Satzzeichen und Füllwörtern.
        let rest = nummerRegex.stringByReplacingMatches(
            in: ohneAbs, options: [], range: NSRange(location: 0, length: ns.length),
            withTemplate: " ")
        let woerter = rest.split(whereSeparator: { !$0.isLetter }).map(String.init)
        if woerter.contains(where: { !fuellwoerter.contains($0) && !istRoemisch($0) }) { return nil }
        guard !gefunden.isEmpty else { return nil }
        return mehrere ? gefunden : [gefunden[0]]
    }

    private static func istRoemisch(_ s: String) -> Bool {
        !s.isEmpty && s.allSatisfy { "IVX".contains($0) }
    }
}
