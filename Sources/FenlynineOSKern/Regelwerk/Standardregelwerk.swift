import Foundation

/// Das Regelwerk, das ohne weitere Konfiguration gilt.
///
/// Eine Liste an einer Stelle: Wer wissen will, was der Wächter prüft, liest
/// diese Datei. Eine Regel, die hier nicht steht, wird nicht geprüft.
public enum Standardregelwerk {
    public static let alle: [Regel] = [
        // Fristen
        FristOhneHerleitungRegel(),
        NotfristOhneVieraugenRegel(),
        FristOhneVorfristRegel(),
        FristOhneVerantwortlichenRegel(),
        FristVeralteteBerechnungRegel(),
        FristKritischNahRegel(),
        AusgangskontrolleFehltRegel(),
        // Vorgänge
        PrognoseOhneBegruendungRegel(),
        VorgangOhneKonfliktpruefungRegel(),
        VorgangOhneKostenrisikoRegel(),
        VorgangOhneStreitwertRegel(),
        // System
        WertVeraltetRegel(),
        WertOhneQuelleRegel(),
        // Module
        ModulUngenutztRegel(),
        ModulPflichtAusgeblendetRegel(),
        ModulVielBenutztWeitHintenRegel()
    ]

    /// Nur Regeln ab einer Mindestschwere, z. B. für eine schnelle Prüfung
    /// ("nur Kritisches") statt des vollen Durchlaufs.
    public static func fuer(schwereMindestens: Schwere) -> [Regel] {
        alle.filter { $0.schwere >= schwereMindestens }
    }
}
