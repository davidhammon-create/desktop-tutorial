import Foundation

// MARK: - Prüfbare Sichten (Eingabe des Wächters)
//
// ZENTRAL FÜR DIE SICHERHEIT: Keines dieser Protokolle gibt Namen, Texte,
// Beträge oder Dokumentinhalte heraus. Sie liefern ausschließlich
// Strukturmerkmale (Kennung, Datum, Zähler) und Ja/Nein-Angaben. Ein Agent, der
// nur diese Sicht hat, KANN keine Mandatsdaten preisgeben, in ein Protokoll
// schreiben oder in einen Hinweistext einbauen -- er hat sie nie gesehen.
// Datenschutz ist hier keine Disziplin, sondern fehlende Gelegenheit.
//
// Die Kennungen (`id`) sind undurchsichtige Schlüssel; sie dürfen keine
// Klarnamen oder Aktenzeichen mit Personenbezug enthalten. Wer das Protokoll
// implementiert, bildet sie entsprechend ab.

/// Strukturmerkmale einer Frist -- ohne Bezeichnung, Gegenstand oder Beteiligte.
public protocol PruefbareFrist {
    var id: String { get }
    var faelligkeit: Date { get }
    var istNotfrist: Bool { get }
    var hatHerleitung: Bool { get }
    /// Mit welcher Kernversion wurde die Frist berechnet? `nil`, wenn unbekannt.
    var berechnetMitVersion: String? { get }
    var vierAugenBestaetigt: Bool { get }
    var erledigt: Bool { get }
    var gestrichen: Bool { get }
    var hatVorfrist: Bool { get }
    var verantwortlicherGesetzt: Bool { get }
}

/// Strukturmerkmale eines Vorgangs -- ohne Parteien, Gegenstand oder Streitwert.
public protocol PruefbarerVorgang {
    var id: String { get }
    var hatAnnahmenBegruendung: Bool { get }
    var prognoseVorhanden: Bool { get }
    var kostenrisikoBerechnet: Bool { get }
    var streitwertGesetzt: Bool { get }
    var konfliktpruefungErfolgt: Bool { get }
    var rechtsgebietGesetzt: Bool { get }
}

/// Ein belegter Wert -- ohne den Wert selbst. Geprüft wird nur, ob die Herkunft stimmt.
public protocol PruefbarerWert {
    var id: String { get }
    var quelleGenannt: Bool { get }
    var abgerufenAm: Date? { get }
    var istVeraltet: Bool { get }
}

/// Ein Modul der Oberfläche -- hier geht es um Bedienung, nicht um Fälle.
public protocol PruefbaresModul {
    var id: String { get }
    var sichtbar: Bool { get }
    var zuletztBenutzt: Date? { get }
    var benutzungenLetzte90Tage: Int { get }
    var istPflichtmodul: Bool { get }
}

/// Alles, was eine Regel über den Zustand der Kanzlei erfährt.
public protocol Pruefzustand {
    var fristen: [any PruefbareFrist] { get }
    var vorgaenge: [any PruefbarerVorgang] { get }
    var belegteWerte: [any PruefbarerWert] { get }
    var modul: [any PruefbaresModul] { get }
    /// Wann wurde zuletzt geprüft, was die Kanzlei verlässt? `nil`: noch nie.
    var letzteAusgangskontrolle: Date? { get }
    /// "Jetzt" wird übergeben statt abgefragt, damit Regeln reproduzierbar sind.
    var heute: Date { get }
    var aktuelleKernversion: String { get }
}

// MARK: - Regel

/// Eine einzelne Prüfung. Rein deterministisch: kein Zufall, keine KI, kein Netz,
/// kein Zugriff auf Uhr oder Dateien -- nur der übergebene Zustand. Dieselbe
/// Eingabe führt so immer zum selben Befund, und ein Prüfer kann jede
/// Regel einzeln nachvollziehen.
public protocol Regel {
    var id: String { get }
    /// Ändert sich die Logik, ändert sich die Version; Befunde nennen sie mit.
    var version: String { get }
    var titel: String { get }
    var schwere: Schwere { get }
    /// Rechtsnorm, auf der die Regel beruht, falls es eine gibt.
    var norm: String? { get }

    func pruefe(_ zustand: any Pruefzustand) -> [Befund]
}
