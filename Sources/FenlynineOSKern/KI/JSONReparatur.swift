import Foundation

// MARK: - JSON-Reparatur
//
// Lokale Sprachmodelle halten sich nicht immer an "antworte nur mit JSON":
// Sie setzen Markdown-Zäune, einen Einleitungssatz oder ein Komma zu viel.
// Statt die ganze Analyse scheitern zu lassen, wird der JSON-Teil
// herausgelöst und von den häufigsten Formfehlern befreit.
//
// Es wird nichts erfunden: Fehlt eine schließende Klammer oder ist der Inhalt
// kein JSON, liefert die Funktion `nil`.

public enum JSONReparatur {

    /// Der erste vollständige JSON-Wert (Objekt oder Liste) im Text, bereinigt
    /// und geprüft. `nil`, wenn sich kein gültiges JSON gewinnen lässt.
    public static func extrahiere(_ text: String) -> Data? {
        let roh = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = gueltig(roh) { return d }
        guard let kandidat = ersterWert(in: roh) else { return nil }
        if let d = gueltig(kandidat) { return d }
        return gueltig(ohneHaengendeKommas(kandidat))
    }

    private static func gueltig(_ s: String) -> Data? {
        guard let first = s.first, first == "{" || first == "[" else { return nil }
        let d = Data(s.utf8)
        return (try? JSONSerialization.jsonObject(with: d)) != nil ? d : nil
    }

    /// Schneidet vom ersten "{" oder "[" bis zur passenden schließenden
    /// Klammer aus; Klammern innerhalb von Zeichenketten zählen nicht.
    private static func ersterWert(in text: String) -> String? {
        guard let start = text.firstIndex(where: { $0 == "{" || $0 == "[" }) else { return nil }
        var tiefe = 0
        var inString = false
        var escaped = false
        var i = start
        while i < text.endIndex {
            let c = text[i]
            if inString {
                if escaped { escaped = false }
                else if c == "\\" { escaped = true }
                else if c == "\"" { inString = false }
            } else {
                if c == "\"" { inString = true }
                else if c == "{" || c == "[" { tiefe += 1 }
                else if c == "}" || c == "]" {
                    tiefe -= 1
                    if tiefe == 0 { return String(text[start...i]) }
                }
            }
            i = text.index(after: i)
        }
        return nil
    }

    /// Entfernt Kommas direkt vor "}" oder "]" (außerhalb von Zeichenketten).
    private static func ohneHaengendeKommas(_ text: String) -> String {
        var aus: [Character] = []
        aus.reserveCapacity(text.count)
        var inString = false
        var escaped = false
        for c in text {
            if inString {
                if escaped { escaped = false }
                else if c == "\\" { escaped = true }
                else if c == "\"" { inString = false }
                aus.append(c)
                continue
            }
            if c == "\"" { inString = true }
            if c == "}" || c == "]" {
                var j = aus.count - 1
                while j >= 0, aus[j].isWhitespace { j -= 1 }
                if j >= 0, aus[j] == "," { aus.remove(at: j) }
            }
            aus.append(c)
        }
        return String(aus)
    }
}
