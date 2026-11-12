import Foundation

// MARK: - Korrektur
//
// Das ist die EINZIGE Sprache, in der der Prüf- und Korrektur-Agent etwas
// verändern darf. Alles, was hier nicht als Fall steht, kann der Agent nicht
// ausdrücken -- weder versehentlich noch durch einen Fehler in einer Regel noch
// durch eine manipulierte Eingabe.
//
// BEWUSST NICHT vorhanden sind:
//   - fristAendern
//   - fristErledigen
//   - loeschen
//   - senden
//   - wertUeberschreiben
//
// Diese Fälle sind nicht verboten, sondern UNMÖGLICH: Der Typ kennt sie nicht.
// Ein Verbot ist eine Zusage ("wir passen auf, dass der Agent das nicht tut");
// ein fehlender Fall ist eine Garantie ("der Agent hat keine Möglichkeit, das
// zu tun"). Eine Zusage kann gebrochen werden -- durch einen Programmierfehler,
// eine vergessene Prüfung, einen Konfigurationsfehler. Eine Garantie lässt sich
// nur brechen, indem jemand den Typ ändert, und das fällt im Code-Review und im
// Diff sofort auf. Für Prüfer und Versicherer ist das der entscheidende
// Unterschied.
//
// Wer hier künftig einen Fall ergänzt, ändert die Sicherheitsarchitektur und
// muss das als solche Änderung begründen.
public enum Korrektur: Codable, Hashable, Sendable {
    /// Legt einen Hinweis an (z. B. "Für diese Frist fehlt die Herleitung").
    case hinweisAnlegen(text: String)
    /// Setzt eine Markierung an ein Objekt (nur Kennung, kein Inhalt).
    case markierungSetzen(objektId: String, markierung: String)
    /// Stößt eine Neuberechnung an. Erzeugt einen NEUEN Beleg; der alte bleibt.
    case neuBerechnen(objektId: String, grund: String)
    /// Schlägt einen Feldwert vor. Wird nie automatisch übernommen.
    case feldErgaenzen(objektId: String, feld: String, vorschlag: String)
    /// Bittet einen Menschen um Prüfung.
    case pruefungAnfordern(objektId: String, frage: String)
    /// Ändert Oberfläche, Ablauf oder Funktionskonfiguration (nie Falldaten).
    case modellAendern(aenderungId: String, beschreibung: String, umkehrbar: Bool)

    /// Darf der Wächter diese Korrektur ohne Rückfrage ausführen (Stufe `.selbstheilend`)?
    ///
    /// Maßstab: Nach der Ausführung ist nichts verloren, was vorher da war.
    public var darfAutomatischLaufen: Bool {
        switch self {
        case .hinweisAnlegen:
            // Ein Hinweis fügt etwas hinzu und ersetzt nichts.
            return true
        case .markierungSetzen:
            // Eine Markierung ist eine Zusatzinformation und lässt sich entfernen.
            return true
        case .pruefungAnfordern:
            // Fragt nur einen Menschen; ändert selbst nichts.
            return true
        case .neuBerechnen:
            // Erzeugt einen neuen Beleg und überschreibt nichts; der alte bleibt
            // nachvollziehbar erhalten.
            return true
        case .modellAendern(_, _, let umkehrbar):
            // Eine Oberflächenänderung, die sich auf Knopfdruck zurücknehmen
            // lässt, ist folgenlos -- eine andere nicht. Die Umkehrbarkeit ist
            // eine Angabe der Regel; der Ausführer muss sie einlösen können.
            return umkehrbar
        case .feldErgaenzen:
            // Inhalt ist Verantwortung des Anwalts. Immer nur ein Vorschlag.
            return false
        }
    }

    /// Beschreibung in Alltagssprache, so wie sie dem Anwalt angezeigt wird.
    public var beschreibung: String {
        switch self {
        case .hinweisAnlegen(let text):
            return "Einen Hinweis anlegen: \(text)"
        case .markierungSetzen(_, let markierung):
            return "Eine Markierung setzen: \(markierung)"
        case .neuBerechnen(_, let grund):
            return "Neu berechnen (alter Beleg bleibt erhalten): \(grund)"
        case .feldErgaenzen(_, let feld, _):
            return "Für das Feld \"\(feld)\" einen Wert vorschlagen -- Sie entscheiden, ob er übernommen wird."
        case .pruefungAnfordern(_, let frage):
            return "Um Ihre Prüfung bitten: \(frage)"
        case .modellAendern(_, let beschreibung, let umkehrbar):
            return umkehrbar
                ? "Einstellung ändern (mit einem Klick rückgängig zu machen): \(beschreibung)"
                : "Einstellung ändern (nicht rückgängig zu machen): \(beschreibung)"
        }
    }
}
