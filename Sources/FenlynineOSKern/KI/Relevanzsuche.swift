import Foundation

// MARK: - Relevanzsuche
//
// Findet zu einer Frage die passendsten Wissenseinträge -- ohne KI, ohne
// Netz, nachvollziehbar. Verfahren: BM25 über Wortstämme, mit starkem Bonus,
// wenn Frage und Eintrag dieselbe Norm nennen ("§ 626 BGB").
//
// Warum nicht einfach "enthält den Suchtext"? Weil eine Frage aus vielen
// Wörtern besteht und kein Eintrag sie wörtlich enthält. Gesucht ist der
// Eintrag, der die SELTENEN Wörter der Frage teilt.

public struct Suchdokument: Sendable {
    public let id: String
    public let titel: String
    public let text: String
    /// Normangabe des Eintrags, z. B. "§ 4 KSchG" (optional).
    public let norm: String?

    public init(id: String, titel: String, text: String, norm: String? = nil) {
        self.id = id
        self.titel = titel
        self.text = text
        self.norm = norm
    }
}

public struct Suchtreffer: Sendable, Hashable {
    public let id: String
    public let punkte: Double
    /// Wörter der Frage, die den Treffer tragen -- für die Anzeige "gefunden wegen".
    public let gruende: [String]
}

public enum Relevanzsuche {

    /// Die `limit` passendsten Dokumente, beste zuerst. Dokumente ohne jede
    /// Übereinstimmung werden nicht geliefert.
    public static func suche(_ frage: String,
                             in dokumente: [Suchdokument],
                             limit: Int = 8) -> [Suchtreffer] {
        let fragewoerter = Array(Set(woerter(frage)))
        let fragenormen = Set(NormzitatPruefer.zitate(in: frage).map(\.kurz))
        guard !dokumente.isEmpty, !(fragewoerter.isEmpty && fragenormen.isEmpty) else { return [] }

        // Titelwörter zählen doppelt: Sie sagen, worum es im Eintrag geht.
        let inhalte: [[String]] = dokumente.map {
            let t = woerter($0.titel)
            return t + t + woerter($0.text) + woerter($0.norm ?? "")
        }
        let n = Double(dokumente.count)
        let mittel = max(1, Double(inhalte.reduce(0) { $0 + $1.count }) / n)
        var dokfrequenz: [String: Int] = [:]
        for inhalt in inhalte {
            for w in Set(inhalt) { dokfrequenz[w, default: 0] += 1 }
        }

        let k1 = 1.4, b = 0.75
        var treffer: [Suchtreffer] = []
        for (i, dok) in dokumente.enumerated() {
            let inhalt = inhalte[i]
            var haeufigkeit: [String: Int] = [:]
            for w in inhalt { haeufigkeit[w, default: 0] += 1 }
            var punkte = 0.0
            var gruende: [(String, Double)] = []
            for w in fragewoerter {
                guard let tf = haeufigkeit[w], let df = dokfrequenz[w] else { continue }
                let idf = log(1 + (n - Double(df) + 0.5) / (Double(df) + 0.5))
                let f = Double(tf)
                let s = idf * (f * (k1 + 1)) / (f + k1 * (1 - b + b * Double(inhalt.count) / mittel))
                punkte += s
                gruende.append((w, s))
            }
            if !fragenormen.isEmpty {
                let doknormen = Set(NormzitatPruefer.zitate(in: (dok.norm ?? "") + " " + dok.titel
                                                            + " " + dok.text).map(\.kurz))
                let gemeinsam = fragenormen.intersection(doknormen)
                if !gemeinsam.isEmpty {
                    // Dieselbe Norm wiegt schwerer als jede Wortübereinstimmung.
                    punkte += 10 * Double(gemeinsam.count)
                    gruende.append(contentsOf: gemeinsam.sorted().map { ($0, 10) })
                }
            }
            if punkte > 0 {
                let top = gruende.sorted { $0.1 > $1.1 }.prefix(4).map(\.0)
                treffer.append(Suchtreffer(id: dok.id, punkte: punkte, gruende: Array(top)))
            }
        }
        return Array(treffer.sorted {
            $0.punkte != $1.punkte ? $0.punkte > $1.punkte : $0.id < $1.id
        }.prefix(max(0, limit)))
    }

    // MARK: Wortaufbereitung

    /// Kleinschreibung, Umlaute vereinheitlicht, Stoppwörter entfernt, grob
    /// auf den Stamm gekürzt ("Kündigungen" und "Kündigung" treffen sich).
    public static func woerter(_ text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
            .split(whereSeparator: { !($0.isLetter || $0.isNumber) })
            .map(String.init)
            .filter { $0.count >= 3 && !stoppwoerter.contains($0) }
            .map(stamm)
    }

    private static func stamm(_ w: String) -> String {
        guard w.count > 5 else { return w }
        for endung in ["ungen", "erung", "enden", "ende", "sche", "lich", "ung", "ern", "en", "er", "es", "em", "e", "n", "s"] {
            if w.hasSuffix(endung), w.count - endung.count >= 4 {
                return String(w.dropLast(endung.count))
            }
        }
        return w
    }

    private static let stoppwoerter: Set<String> = [
        "der", "die", "das", "den", "dem", "des", "ein", "eine", "einer", "eines",
        "einem", "einen", "und", "oder", "aber", "auch", "als", "auf", "aus", "bei",
        "bis", "durch", "fuer", "gegen", "mit", "nach", "ohne", "von", "vom", "vor",
        "zum", "zur", "ueber", "unter", "ist", "sind", "war", "wird", "werden",
        "wurde", "hat", "haben", "kann", "koennen", "muss", "soll", "sollen", "nicht",
        "nur", "noch", "sich", "wie", "was", "wer", "wenn", "dass", "diese", "dieser",
        "dieses", "sein", "seine", "ihre", "ihr", "wir", "sie", "ich", "bitte",
        "abs", "satz", "art", "vgl", "bzw", "etc", "gem", "gemaess", "the", "and"
    ]
}
