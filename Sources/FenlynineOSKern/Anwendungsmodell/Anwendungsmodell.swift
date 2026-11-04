import Foundation

// MARK: - Anwendungsmodell
//
// Deklarative Beschreibung der App-Struktur. Die Oberfläche rendert AUS diesem
// Modell: wer das Modell ändert, ändert die App -- ohne Code zu ändern. Das ist die
// Grundlage dafür, dass ein Agent Oberfläche und Abläufe anpassen darf.
//
// Das Modell enthält ausschließlich STRUKTUR (welche Module, in welcher Zone, in
// welcher Reihenfolge, welche Schritte mit welchen Feldnamen). Niemals Mandats-,
// Fall- oder Dokumentinhalte: So kann ein Modellexport oder -verlauf weitergegeben,
// geprüft und zurückgerollt werden, ohne dass dabei Berufsgeheimnisse berührt werden.

public struct Anwendungsmodell: Codable, Hashable {
    /// Laufende Nummer; jede angewendete Änderung und jeder Rückroll erhöht sie.
    public var version: Int
    public var geaendertAm: Date
    /// z. B. "Wächter" oder ein Nutzername -- wer hat diesen Stand erzeugt?
    public var geaendertVon: String
    public var module: [Moduleintrag]
    public var zonen: [Navigationszone]
    public var ablaeufe: [Ablauf]
    public var darstellung: Darstellung

    public init(version: Int,
                geaendertAm: Date,
                geaendertVon: String,
                module: [Moduleintrag],
                zonen: [Navigationszone],
                ablaeufe: [Ablauf],
                darstellung: Darstellung) {
        self.version = version
        self.geaendertAm = geaendertAm
        self.geaendertVon = geaendertVon
        self.module = module
        self.zonen = zonen
        self.ablaeufe = ablaeufe
        self.darstellung = darstellung
    }

    // MARK: Abfragen (damit Oberfläche und Verwalter nicht je eigene Sortierlogik bauen)

    public func modul(_ id: String) -> Moduleintrag? {
        module.first { $0.id == id }
    }

    public func zone(_ id: String) -> Navigationszone? {
        zonen.first { $0.id == id }
    }

    public func ablauf(_ id: String) -> Ablauf? {
        ablaeufe.first { $0.id == id }
    }

    /// Sichtbare Module einer Zone in Anzeigereihenfolge. Bei gleicher Reihenfolge
    /// entscheidet die id, damit die Anzeige nie von der Array-Lage abhängt.
    public func sichtbareModule(inZone zoneId: String) -> [Moduleintrag] {
        module
            .filter { $0.zoneId == zoneId && $0.sichtbar }
            .sorted { ($0.reihenfolge, $0.id) < ($1.reihenfolge, $1.id) }
    }

    /// Sichtbare Zonen in Anzeigereihenfolge.
    public var sichtbareZonen: [Navigationszone] {
        zonen
            .filter { $0.sichtbar }
            .sorted { ($0.reihenfolge, $0.id) < ($1.reihenfolge, $1.id) }
    }
}

public struct Moduleintrag: Codable, Hashable, Identifiable {
    /// Stabile Kennung, entspricht dem rawValue des jeweiligen Seitenleisten-Eintrags
    /// (z. B. "lexara", "zeitleiste").
    public var id: String
    public var titel: String
    public var untertitel: String
    public var sichtbar: Bool
    public var reihenfolge: Int
    public var zoneId: String
    /// Pflichtmodule dürfen nie ausgeblendet werden -- sonst könnte eine Anpassung
    /// den Zugang zu Fristen, Berufspflichten oder zur Rücknahme selbst verbergen.
    public var istPflichtmodul: Bool
    /// Symbolname (z. B. SF-Symbol); die Oberfläche entscheidet, wie er gezeichnet wird.
    public var symbol: String

    public init(id: String,
                titel: String,
                untertitel: String,
                sichtbar: Bool = true,
                reihenfolge: Int,
                zoneId: String,
                istPflichtmodul: Bool = false,
                symbol: String) {
        self.id = id
        self.titel = titel
        self.untertitel = untertitel
        self.sichtbar = sichtbar
        self.reihenfolge = reihenfolge
        self.zoneId = zoneId
        self.istPflichtmodul = istPflichtmodul
        self.symbol = symbol
    }
}

public struct Navigationszone: Codable, Hashable, Identifiable {
    public var id: String
    public var titel: String
    /// Kurzform für enge Platzverhältnisse (Tab-Leiste, schmale Seitenleiste).
    public var kurzLabel: String
    public var reihenfolge: Int
    public var sichtbar: Bool

    public init(id: String,
                titel: String,
                kurzLabel: String,
                reihenfolge: Int,
                sichtbar: Bool = true) {
        self.id = id
        self.titel = titel
        self.kurzLabel = kurzLabel
        self.reihenfolge = reihenfolge
        self.sichtbar = sichtbar
    }
}

public struct Ablauf: Codable, Hashable, Identifiable {
    /// z. B. "fristen.arbeitsablauf"
    public var id: String
    public var titel: String
    public var schritte: [Ablaufschritt]

    public init(id: String, titel: String, schritte: [Ablaufschritt]) {
        self.id = id
        self.titel = titel
        self.schritte = schritte
    }

    /// Schritte in Ausführungsreihenfolge.
    public var geordneteSchritte: [Ablaufschritt] {
        schritte.sorted { ($0.reihenfolge, $0.id) < ($1.reihenfolge, $1.id) }
    }
}

public struct Ablaufschritt: Codable, Hashable, Identifiable {
    public var id: String
    public var titel: String
    public var erklaerung: String
    public var reihenfolge: Int
    /// Nur Feldnamen, nie Feldwerte -- das Modell kennt keine Falldaten.
    public var pflichtfelder: [String]
    public var optionalfelder: [String]
    public var istUeberspringbar: Bool
    /// z. B. Vier-Augen-Prinzip bei Notfristen. Diese Sicherung darf nur ein
    /// Mensch abschwächen (siehe `ModellAenderung.schwaechtSicherungAb`).
    public var bestaetigungErforderlich: Bool

    public init(id: String,
                titel: String,
                erklaerung: String,
                reihenfolge: Int,
                pflichtfelder: [String] = [],
                optionalfelder: [String] = [],
                istUeberspringbar: Bool = false,
                bestaetigungErforderlich: Bool = false) {
        self.id = id
        self.titel = titel
        self.erklaerung = erklaerung
        self.reihenfolge = reihenfolge
        self.pflichtfelder = pflichtfelder
        self.optionalfelder = optionalfelder
        self.istUeberspringbar = istUeberspringbar
        self.bestaetigungErforderlich = bestaetigungErforderlich
    }
}

public struct Darstellung: Codable, Hashable {
    public enum Dichte: String, Codable, Hashable, CaseIterable {
        case kompakt
        case normal
        case luftig
    }

    public var dichte: Dichte
    /// -2 ... +2; Werte außerhalb werden begrenzt, damit die Oberfläche nie
    /// unlesbar klein oder unbenutzbar groß wird.
    public var schriftgroesseStufe: Int
    public var zeigeErklaersaetze: Bool
    public var zeigeHerkunftsmarken: Bool

    public init(dichte: Dichte = .normal,
                schriftgroesseStufe: Int = 0,
                zeigeErklaersaetze: Bool = true,
                zeigeHerkunftsmarken: Bool = true) {
        self.dichte = dichte
        self.schriftgroesseStufe = min(2, max(-2, schriftgroesseStufe))
        self.zeigeErklaersaetze = zeigeErklaersaetze
        self.zeigeHerkunftsmarken = zeigeHerkunftsmarken
    }
}

// MARK: - Vorbelegung

extension Anwendungsmodell {
    /// Ausgangsstand. Fester Zeitstempel (1.1.2026, UTC), damit der Hash des
    /// ersten Verlaufseintrags auf jedem Gerät gleich ist.
    public static let standard: Anwendungsmodell = Anwendungsmodell(
        version: 1,
        geaendertAm: Date(timeIntervalSince1970: 1_767_225_600),
        geaendertVon: "System",
        module: [
            // Zone "arbeit": das Tagesgeschäft
            Moduleintrag(id: "vorgaenge", titel: "Vorgänge",
                         untertitel: "Ein Vorgang, ein Motor",
                         reihenfolge: 1, zoneId: "arbeit",
                         istPflichtmodul: true, symbol: "tray.full"),
            Moduleintrag(id: "aufgaben", titel: "Aufgaben",
                         untertitel: "Was heute zu tun ist",
                         reihenfolge: 2, zoneId: "arbeit", symbol: "checklist"),
            Moduleintrag(id: "zeitleiste", titel: "Fristen & Termine",
                         untertitel: "Fristen im Blick",
                         reihenfolge: 3, zoneId: "arbeit",
                         istPflichtmodul: true, symbol: "calendar"),
            // Zone "akten": Fälle, Unterlagen, Beteiligte
            Moduleintrag(id: "lexara", titel: "Fälle & Mandate (Lexara)",
                         untertitel: "Fallarbeit",
                         reihenfolge: 1, zoneId: "akten", symbol: "scalemass"),
            Moduleintrag(id: "dokumente", titel: "Dokumente & Akten",
                         untertitel: "Schriftstücke und Akten",
                         reihenfolge: 2, zoneId: "akten", symbol: "doc.text"),
            Moduleintrag(id: "mandanten", titel: "Mandantenportal",
                         untertitel: "Austausch mit Mandanten",
                         reihenfolge: 3, zoneId: "akten", symbol: "person.2"),
            // Zone "kanzlei": Betrieb und Berufsrecht
            Moduleintrag(id: "honorare", titel: "Honorare & Zeit",
                         untertitel: "Zeiterfassung und Abrechnung",
                         reihenfolge: 1, zoneId: "kanzlei", symbol: "eurosign.circle"),
            Moduleintrag(id: "organon", titel: "Team & Netzwerk (Organon)",
                         untertitel: "Zusammenarbeit",
                         reihenfolge: 2, zoneId: "kanzlei", symbol: "point.3.connected.trianglepath.dotted"),
            Moduleintrag(id: "berufspflicht", titel: "Berufspflichten",
                         untertitel: "Pflichten sicher einhalten",
                         reihenfolge: 3, zoneId: "kanzlei",
                         istPflichtmodul: true, symbol: "checkmark.shield"),
            // Zone "system": Pflichtmodul, damit Anpassungen immer erreichbar
            // und rücknehmbar bleiben.
            Moduleintrag(id: "einstellungen", titel: "Einstellungen",
                         untertitel: "Darstellung und Konto",
                         reihenfolge: 1, zoneId: "system",
                         istPflichtmodul: true, symbol: "gearshape")
        ],
        zonen: [
            Navigationszone(id: "arbeit", titel: "Arbeit", kurzLabel: "Arbeit", reihenfolge: 1),
            Navigationszone(id: "akten", titel: "Akten & Fälle", kurzLabel: "Akten", reihenfolge: 2),
            Navigationszone(id: "kanzlei", titel: "Kanzlei", kurzLabel: "Kanzlei", reihenfolge: 3),
            Navigationszone(id: "system", titel: "System", kurzLabel: "System", reihenfolge: 4)
        ],
        ablaeufe: [
            Ablauf(
                id: "fristen.arbeitsablauf",
                titel: "Fristen-Arbeitsablauf",
                schritte: [
                    Ablaufschritt(
                        id: "post-erfassen", titel: "Post erfassen",
                        erklaerung: "Eingang festhalten: Was ist wann auf welchem Weg eingegangen?",
                        reihenfolge: 1,
                        pflichtfelder: ["eingangsdatum", "zustellart", "schriftstueckart"],
                        optionalfelder: ["absender"]),
                    Ablaufschritt(
                        id: "frist-berechnen", titel: "Frist berechnen",
                        erklaerung: "Die Frist wird aus dem auslösenden Ereignis berechnet.",
                        reihenfolge: 2,
                        pflichtfelder: ["fristart", "ausloesendesEreignis", "gericht"],
                        optionalfelder: ["feiertagsregion"]),
                    Ablaufschritt(
                        id: "ergebnis-pruefen", titel: "Ergebnis prüfen",
                        erklaerung: "Das berechnete Fristende gegenprüfen, bevor es gilt (Vier-Augen bei Notfristen).",
                        reihenfolge: 3,
                        pflichtfelder: ["ergebnisGeprueft"],
                        bestaetigungErforderlich: true),
                    Ablaufschritt(
                        id: "notieren", titel: "Notieren",
                        erklaerung: "Frist und Vorfrist im Kalender eintragen.",
                        reihenfolge: 4,
                        pflichtfelder: ["kalendereintrag"],
                        optionalfelder: ["vorfrist"]),
                    Ablaufschritt(
                        id: "wiedervorlage", titel: "Wiedervorlage",
                        erklaerung: "Festlegen, wann die Akte wieder vorgelegt wird.",
                        reihenfolge: 5,
                        pflichtfelder: ["wiedervorlagedatum"],
                        optionalfelder: ["verantwortlich"]),
                    Ablaufschritt(
                        id: "ausgangskontrolle", titel: "Ausgangskontrolle",
                        erklaerung: "Vor Fristablauf prüfen, dass das Schriftstück wirklich raus ist.",
                        reihenfolge: 6,
                        pflichtfelder: ["fristwahrung"],
                        bestaetigungErforderlich: true)
                ])
        ],
        darstellung: Darstellung()
    )
}
