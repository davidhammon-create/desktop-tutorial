import SwiftUI

// MARK: - Navigationskatalog
//
// Die eine Ordnung aller Module, nach der Seitenleiste, Startseite und
// Modulliste aufgebaut werden. Aufbau wie in den Systemeinstellungen:
//
//   Bereich (Überschrift)  ->  Kategorie (Zeile mit Symbol)  ->  Modul
//
// Geordnet ist nach der Frage, die man gerade hat ("Was läuft ab?", "Wie
// stehen die Chancen?"), nicht nach Markennamen. Jede Kategorie bringt einen
// kurzen Ablauf mit, der die Module in der Reihenfolge nennt, in der man sie
// sinnvoll benutzt.
//
// Die Zuordnung ist ein vollständiger `switch`: Kommt ein Modul hinzu,
// kompiliert die App erst, wenn es einer Kategorie zugeordnet ist. So kann
// kein Modul unauffindbar werden.

enum NavBereich: String, CaseIterable, Identifiable {
    case arbeit, analyse, kanzlei, system
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .arbeit: return "Arbeit"
        case .analyse: return "Analyse & Strategie"
        case .kanzlei: return "Kanzlei"
        case .system: return "KI & System"
        }
    }
    var kategorien: [NavKategorie] { NavKategorie.allCases.filter { $0.bereich == self } }
}

struct NavAblaufSchritt: Identifiable {
    let titel: String
    let text: String
    let modul: SeitenleistenEintrag
    var id: String { modul.rawValue + titel }
}

enum NavKategorie: String, CaseIterable, Identifiable {
    case akten, fristen, mandanten
    case prognose, strategie, gegenseite
    case ueberblick, team, berufsrecht
    case ki, system

    var id: String { rawValue }

    var bereich: NavBereich {
        switch self {
        case .akten, .fristen, .mandanten: return .arbeit
        case .prognose, .strategie, .gegenseite: return .analyse
        case .ueberblick, .team, .berufsrecht: return .kanzlei
        case .ki, .system: return .system
        }
    }

    var titel: String {
        switch self {
        case .akten: return "Vorgänge & Akten"
        case .fristen: return "Fristen & Aufgaben"
        case .mandanten: return "Mandanten & Mandate"
        case .prognose: return "Risiko & Prognose"
        case .strategie: return "Strategie & Verhandlung"
        case .gegenseite: return "Gericht & Gegenseite"
        case .ueberblick: return "Überblick"
        case .team: return "Team & Honorare"
        case .berufsrecht: return "Berufsrecht & Compliance"
        case .ki: return "KI-Assistent"
        case .system: return "System"
        }
    }

    /// Die Frage, die diese Kategorie beantwortet.
    var frage: String {
        switch self {
        case .akten: return "Woran arbeite ich, und was steht in der Akte?"
        case .fristen: return "Was läuft wann ab, und wer kümmert sich?"
        case .mandanten: return "Darf ich das Mandat annehmen, und wie betreue ich es?"
        case .prognose: return "Wie stehen die Chancen, und was kostet es?"
        case .strategie: return "Welcher Weg führt am sichersten zum Ziel?"
        case .gegenseite: return "Wie entscheidet das Gericht, wie argumentiert die Gegenseite?"
        case .ueberblick: return "Wie steht die Kanzlei heute da?"
        case .team: return "Wer macht was, und was wird abgerechnet?"
        case .berufsrecht: return "Halte ich alle Berufspflichten ein?"
        case .ki: return "Was kann mir die KI zu dieser Akte sagen?"
        case .system: return "Konto, Darstellung, Daten und Wartung"
        }
    }

    var symbol: String {
        switch self {
        case .akten: return "tray.full.fill"
        case .fristen: return "calendar.badge.clock"
        case .mandanten: return "person.2.fill"
        case .prognose: return "chart.line.uptrend.xyaxis"
        case .strategie: return "scope"
        case .gegenseite: return "building.columns.fill"
        case .ueberblick: return "square.grid.2x2.fill"
        case .team: return "person.3.fill"
        case .berufsrecht: return "checkmark.shield.fill"
        case .ki: return "sparkles"
        case .system: return "gearshape.fill"
        }
    }

    /// Farbe des Symbolquadrats -- dieselben Systemfarben wie in den
    /// Systemeinstellungen, damit sich die Kategorien auf einen Blick trennen.
    var farbe: Color {
        switch self {
        case .akten: return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .fristen: return Color(red: 1.00, green: 0.23, blue: 0.19)
        case .mandanten: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .prognose: return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .strategie: return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .gegenseite: return Color(red: 0.35, green: 0.34, blue: 0.84)
        case .ueberblick: return Color(red: 0.56, green: 0.56, blue: 0.58)
        case .team: return Color(red: 0.19, green: 0.69, blue: 0.78)
        case .berufsrecht: return Color(red: 0.16, green: 0.60, blue: 0.40)
        case .ki: return Color(red: 1.00, green: 0.18, blue: 0.47)
        case .system: return Color(red: 0.45, green: 0.45, blue: 0.48)
        }
    }

    /// Module dieser Kategorie in sinnvoller Reihenfolge. Nur für Administratoren
    /// sichtbare Module werden ohne Adminrecht weggelassen.
    func module(istAdmin: Bool) -> [SeitenleistenEintrag] {
        SeitenleistenEintrag.allCases
            .compactMap { e -> (SeitenleistenEintrag, Int)? in
                let z = e.navZuordnung
                guard z.kategorie == self, istAdmin || !e.nurFuerAdmins else { return nil }
                return (e, z.rang)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    /// So geht man in dieser Kategorie typischerweise vor.
    var ablauf: [NavAblaufSchritt] {
        switch self {
        case .akten: return [
            .init(titel: "Vorgang anlegen",
                  text: "Jeder neue Auftrag beginnt als Vorgang: Art wählen, Ziel festhalten.", modul: .vorgaenge),
            .init(titel: "Fall aufbauen",
                  text: "Sachverhalt, Argumente beider Seiten und Beweismittel erfassen.", modul: .lexara),
            .init(titel: "Unterlagen ablegen",
                  text: "Schriftstücke hochladen und der Akte zuordnen.", modul: .dokumente),
            .init(titel: "Gesamtauswertung",
                  text: "Eine Frage stellen; die Module werten die Akte gemeinsam aus.", modul: .durchlauf)
        ]
        case .fristen: return [
            .init(titel: "Frist berechnen und notieren",
                  text: "Zustellungsdatum eintragen; das Fristende wird nach §§ 187 ff. BGB, § 222 ZPO berechnet und mit Herleitung gespeichert.",
                  modul: .zeitleiste),
            .init(titel: "Bearbeitung zuweisen",
                  text: "Vorfrist und Verantwortliche festlegen, damit nichts am letzten Tag liegen bleibt.", modul: .aufgaben),
            .init(titel: "Ausgangskontrolle",
                  text: "Vor Fristablauf prüfen, dass der Schriftsatz über das beA versandt ist (§ 130d ZPO).", modul: .beaCheck)
        ]
        case .mandanten: return [
            .init(titel: "Interessenkonflikt prüfen",
                  text: "Vor der Annahme: widerstreitende Interessen ausschließen (§ 43a Abs. 4 BRAO).", modul: .konfliktRadar),
            .init(titel: "Mandat annehmen",
                  text: "Vom Erstkontakt über die Annahme bis zur Abrechnung verfolgen.", modul: .mandatsPipeline),
            .init(titel: "Mandanten betreuen",
                  text: "Kommunikation und Freigaben an einem Ort.", modul: .mandanten)
        ]
        case .prognose: return [
            .init(titel: "Szenarien rechnen",
                  text: "Best-, Basis- und Schlechtfall mit Kostenrisiko aus dem Rechenkern.", modul: .strategos),
            .init(titel: "Risiken bündeln",
                  text: "Alle Risikodimensionen und Gegenzüge in einer Übersicht.", modul: .enterpriseRadar),
            .init(titel: "Auswerten",
                  text: "Kennzahlen über alle Akten: Wo liegt das Risiko der Kanzlei?", modul: .analytik)
        ]
        case .strategie: return [
            .init(titel: "Lage bewerten",
                  text: "Gesamtlage und Kräfteverhältnis des Falls einschätzen.", modul: .sunTzu),
            .init(titel: "Optionen entwickeln",
                  text: "Handlungsoptionen und Verhandlungsspielraum ausloten.", modul: .opportunisma),
            .init(titel: "Entscheidung festhalten",
                  text: "Warum so entschieden wurde -- nachvollziehbar für Mandant und Haftpflicht.", modul: .entscheidungsjournal)
        ]
        case .gegenseite: return [
            .init(titel: "Spruchpraxis auswerten",
                  text: "Veröffentlichte Entscheidungen und Rechtsauffassungen, keine Persönlichkeitsprofile.", modul: .richterprofile),
            .init(titel: "Rechtsordnungen vergleichen",
                  text: "Bei Auslandsbezug: Lösungen anderer Rechtsordnungen gegenüberstellen.", modul: .jurisdiktionen)
        ]
        case .ueberblick: return [
            .init(titel: "Tageslage", text: "Kennzahlen, Risiken und nächste Schritte.", modul: .dashboard),
            .init(titel: "Lagezentrale", text: "Mandate, Konflikte, Pipeline und Fristen in einem Blick.", modul: .lageZentrale),
            .init(titel: "Steuerung", text: "Auslastung und Kapazität der Kanzlei.", modul: .cockpit)
        ]
        case .team: return [
            .init(titel: "Zuständigkeiten klären", text: "Wer entscheidet, wer bearbeitet, wer vertritt.", modul: .organon),
            .init(titel: "Zeit erfassen", text: "Zeiten buchen und nach RVG oder Vereinbarung abrechnen.", modul: .honorare),
            .init(titel: "Fachprofil pflegen", text: "Schwerpunkte der Kanzlei festlegen.", modul: .praxisProfil)
        ]
        case .berufsrecht: return [
            .init(titel: "Pflichten prüfen",
                  text: "Ausgangskontrolle, Mandatsannahme und Endkontrolle von KI-Texten.", modul: .berufspflicht),
            .init(titel: "KI-Einsatz dokumentieren",
                  text: "Welche KI wann was beigetragen hat -- für Transparenz und Nachweis.", modul: .compliance)
        ]
        case .ki: return [
            .init(titel: "Frage zur Akte stellen",
                  text: "Jede Antwort wird auf Normzitate, Beträge und zitierte Entscheidungen nachgeprüft.", modul: .kiChat),
            .init(titel: "Abläufe verbessern",
                  text: "Vorschläge zur Organisation der Arbeit.", modul: .plattformAgent)
        ]
        case .system: return [
            .init(titel: "Einstellungen", text: "Konto, Darstellung, KI-Anbindung und Daten.", modul: .einstellungen),
            .init(titel: "Wartung", text: "Automatische Prüfungen und Reparaturen.", modul: .selbstreparatur)
        ]
        }
    }
}

extension SeitenleistenEintrag {
    /// Kategorie und Position innerhalb der Kategorie.
    var navZuordnung: (kategorie: NavKategorie, rang: Int) {
        switch self {
        case .vorgaenge: return (.akten, 1)
        case .lexara: return (.akten, 2)
        case .dokumente: return (.akten, 3)
        case .durchlauf: return (.akten, 4)

        case .zeitleiste: return (.fristen, 1)
        case .aufgaben: return (.fristen, 2)
        case .beaCheck: return (.fristen, 3)

        case .konfliktRadar: return (.mandanten, 1)
        case .mandatsPipeline: return (.mandanten, 2)
        case .mandanten: return (.mandanten, 3)

        case .strategos: return (.prognose, 1)
        case .enterpriseRadar: return (.prognose, 2)
        case .analytik: return (.prognose, 3)

        case .sunTzu: return (.strategie, 1)
        case .opportunisma: return (.strategie, 2)
        case .entscheidungsjournal: return (.strategie, 3)

        case .richterprofile: return (.gegenseite, 1)
        case .jurisdiktionen: return (.gegenseite, 2)

        case .dashboard: return (.ueberblick, 1)
        case .lageZentrale: return (.ueberblick, 2)
        case .cockpit: return (.ueberblick, 3)
        case .schreibtisch: return (.ueberblick, 4)

        case .organon: return (.team, 1)
        case .honorare: return (.team, 2)
        case .praxisProfil: return (.team, 3)

        case .berufspflicht: return (.berufsrecht, 1)
        case .compliance: return (.berufsrecht, 2)

        case .kiChat: return (.ki, 1)
        case .plattformAgent: return (.ki, 2)

        case .einstellungen: return (.system, 1)
        case .selbstreparatur: return (.system, 2)
        case .adminZentrale: return (.system, 3)
        }
    }

    var navKategorie: NavKategorie { navZuordnung.kategorie }

    var nurFuerAdmins: Bool { self == .adminZentrale }
}
