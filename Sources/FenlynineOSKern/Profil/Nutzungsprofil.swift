import Foundation

// MARK: - Nutzungsprofil
//
// Ein Profil legt fest, welche Module sichtbar sind und wie sie zusammenarbeiten.
// Es ist KEIN Berechtigungssystem -- es verbirgt Oberfläche, keine Daten.
// Pflichtmodule bleiben in jedem Profil erreichbar (der Modellverwalter erzwingt das).

public struct Nutzungsprofil: Codable, Hashable, Identifiable {
    public var id: String
    public var titel: String
    public var untertitel: String
    public var symbol: String
    /// Module, die in diesem Profil SICHTBAR sind. Pflichtmodule werden automatisch
    /// ergänzt, auch wenn sie hier nicht stehen.
    public var sichtbareModulIds: Set<String>
    /// Zonen, die in diesem Profil sichtbar sind.
    public var sichtbareZonenIds: Set<String>
    /// Verbünde: Gruppen von Modulen, die innerhalb dieses Profils zusammenarbeiten
    /// und deren Daten querverknüpft werden (z. B. im Dashboard des Profils).
    public var verbuende: [Modulverbund]
    /// Reihenfolge in der Profilauswahl.
    public var reihenfolge: Int
    /// Ob der Nutzer das Profil selbst erstellt hat oder ob es mitgeliefert wurde.
    public var istBenutzerdefiniert: Bool

    public init(id: String,
                titel: String,
                untertitel: String,
                symbol: String,
                sichtbareModulIds: Set<String>,
                sichtbareZonenIds: Set<String>,
                verbuende: [Modulverbund] = [],
                reihenfolge: Int,
                istBenutzerdefiniert: Bool = false) {
        self.id = id
        self.titel = titel
        self.untertitel = untertitel
        self.symbol = symbol
        self.sichtbareModulIds = sichtbareModulIds
        self.sichtbareZonenIds = sichtbareZonenIds
        self.verbuende = verbuende
        self.reihenfolge = reihenfolge
        self.istBenutzerdefiniert = istBenutzerdefiniert
    }
}

// MARK: - Modulverbund

/// Beschreibt eine Gruppe von Modulen, die innerhalb eines Profils zusammenarbeiten.
/// Ein Verbund hat eine Richtung: ein Leitmodul liefert den Kontext (z. B. den
/// aktuellen Fall), die Nebenmodule arbeiten in diesem Kontext.
public struct Modulverbund: Codable, Hashable, Identifiable {
    public var id: String
    public var titel: String
    /// Das Modul, das den Kontext vorgibt (z. B. Lexara liefert den aktuellen Fall).
    public var leitmodulId: String
    /// Module, die den Kontext des Leitmoduls empfangen und mit ihm arbeiten.
    public var nebenmodulIds: [String]
    /// Welche Daten vom Leitmodul an die Nebenmodule fließen.
    public var kontextTyp: KontextTyp

    public init(id: String, titel: String, leitmodulId: String,
                nebenmodulIds: [String], kontextTyp: KontextTyp) {
        self.id = id
        self.titel = titel
        self.leitmodulId = leitmodulId
        self.nebenmodulIds = nebenmodulIds
        self.kontextTyp = kontextTyp
    }
}

/// Was ein Verbund weitergibt. Nur Strukturinformationen, nie Fallinhalte.
public enum KontextTyp: String, Codable, Hashable, CaseIterable {
    /// Aktueller Fall (id + Rechtsgebiet + Streitwert)
    case fall
    /// Aktuelle Frist (id + Fristtyp + Fälligkeit)
    case frist
    /// Aktueller Mandant (id + Rechtsform)
    case mandant
    /// Kanzlei-Gesamtsicht (Kennzahlen + Zeiträume)
    case kanzlei
    /// Strategie-Kontext (Szenario-id + Akteur-ids)
    case strategie
}

// MARK: - Mitgelieferte Profile

extension Nutzungsprofil {

    /// Alle Module sichtbar. Standard beim ersten Start.
    public static let vollzugriff = Nutzungsprofil(
        id: "vollzugriff",
        titel: "Vollzugriff",
        untertitel: "Alle Module und Funktionen",
        symbol: "square.grid.3x3.fill",
        sichtbareModulIds: Set(alleModulIds),
        sichtbareZonenIds: Set(alleZonenIds),
        reihenfolge: 0)

    /// Für die Arbeit an einem konkreten Rechtsfall: Fristen, Dokumente, Schriftsätze.
    public static let rechtsfall = Nutzungsprofil(
        id: "rechtsfall",
        titel: "Rechtsfall",
        untertitel: "Fälle bearbeiten: Fristen, Schriftsätze, Beweismittel",
        symbol: "folder.fill.badge.gearshape",
        sichtbareModulIds: [
            "vorgaenge", "lexara", "zeitleiste", "dokumente", "aufgaben",
            "mandanten", "berufspflicht", "beaCheck", "kiChat",
            "einstellungen"
        ],
        sichtbareZonenIds: ["arbeit", "akten", "kanzlei", "system"],
        verbuende: [
            Modulverbund(
                id: "fall.kern",
                titel: "Fallbearbeitung",
                leitmodulId: "lexara",
                nebenmodulIds: ["zeitleiste", "dokumente", "aufgaben", "beaCheck"],
                kontextTyp: .fall),
            Modulverbund(
                id: "fall.frist",
                titel: "Fristenkontrolle",
                leitmodulId: "zeitleiste",
                nebenmodulIds: ["lexara", "aufgaben", "berufspflicht"],
                kontextTyp: .frist)
        ],
        reihenfolge: 1)

    /// Risikoanalyse: Kosten, Szenarien, Prognosen, Erfolgsaussichten.
    public static let risikoanalyse = Nutzungsprofil(
        id: "risikoanalyse",
        titel: "Risikoanalyse",
        untertitel: "Kosten, Szenarien und Erfolgsaussichten bewerten",
        symbol: "chart.bar.xaxis.ascending",
        sichtbareModulIds: [
            "vorgaenge", "lexara", "strategos", "analytik", "cockpit",
            "entscheidungsjournal", "kiChat", "einstellungen"
        ],
        sichtbareZonenIds: ["arbeit", "akten", "kanzlei", "system"],
        verbuende: [
            Modulverbund(
                id: "risiko.analyse",
                titel: "Risikobewertung",
                leitmodulId: "lexara",
                nebenmodulIds: ["strategos", "analytik", "entscheidungsjournal"],
                kontextTyp: .fall),
            Modulverbund(
                id: "risiko.kanzlei",
                titel: "Kanzleirisiko",
                leitmodulId: "cockpit",
                nebenmodulIds: ["analytik", "strategos"],
                kontextTyp: .kanzlei)
        ],
        reihenfolge: 2)

    /// Unternehmenskonkurrenz: Wettbewerber, Positionen, strategische Analyse.
    public static let unternehmenskonkurrenz = Nutzungsprofil(
        id: "unternehmenskonkurrenz",
        titel: "Unternehmenskonkurrenz",
        untertitel: "Wettbewerber analysieren und Positionen vergleichen",
        symbol: "arrow.triangle.branch",
        sichtbareModulIds: [
            "vorgaenge", "lexara", "richterprofile", "strategos",
            "opportunisma", "sunTzu", "analytik", "konfliktRadar",
            "kiChat", "einstellungen"
        ],
        sichtbareZonenIds: ["arbeit", "akten", "kanzlei", "system"],
        verbuende: [
            Modulverbund(
                id: "konkurrenz.lage",
                titel: "Wettbewerbslage",
                leitmodulId: "lexara",
                nebenmodulIds: ["richterprofile", "strategos", "opportunisma", "sunTzu"],
                kontextTyp: .strategie),
            Modulverbund(
                id: "konkurrenz.konflikt",
                titel: "Konfliktprüfung",
                leitmodulId: "konfliktRadar",
                nebenmodulIds: ["lexara", "richterprofile"],
                kontextTyp: .fall)
        ],
        reihenfolge: 3)

    /// Schwachstellenanalyse: Eigene und gegnerische Position prüfen.
    public static let schwachstellenanalyse = Nutzungsprofil(
        id: "schwachstellenanalyse",
        titel: "Schwachstellenanalyse",
        untertitel: "Eigene und gegnerische Schwächen identifizieren",
        symbol: "magnifyingglass.circle.fill",
        sichtbareModulIds: [
            "dashboard", "lexara", "richterprofile", "analytik", "cockpit",
            "strategos", "sunTzu", "konfliktRadar", "praxisProfil",
            "entscheidungsjournal", "kiChat", "einstellungen"
        ],
        sichtbareZonenIds: ["arbeit", "akten", "kanzlei", "system"],
        verbuende: [
            Modulverbund(
                id: "schwaeche.intern",
                titel: "Eigene Schwächen",
                leitmodulId: "cockpit",
                nebenmodulIds: ["analytik", "praxisProfil", "entscheidungsjournal"],
                kontextTyp: .kanzlei),
            Modulverbund(
                id: "schwaeche.extern",
                titel: "Gegnerische Schwächen",
                leitmodulId: "lexara",
                nebenmodulIds: ["richterprofile", "strategos", "sunTzu", "konfliktRadar"],
                kontextTyp: .strategie)
        ],
        reihenfolge: 4)

    /// Kanzleimanagement: Team, Honorare, Compliance, Pipeline.
    public static let kanzleimanagement = Nutzungsprofil(
        id: "kanzleimanagement",
        titel: "Kanzleimanagement",
        untertitel: "Team, Honorare, Mandate und Compliance steuern",
        symbol: "building.2.fill",
        sichtbareModulIds: [
            "dashboard", "cockpit", "analytik", "organon", "honorare",
            "mandatsPipeline", "berufspflicht", "compliance", "praxisProfil",
            "konfliktRadar", "aufgaben", "adminZentrale", "einstellungen"
        ],
        sichtbareZonenIds: ["arbeit", "akten", "kanzlei", "system"],
        verbuende: [
            Modulverbund(
                id: "kanzlei.steuerung",
                titel: "Kanzleisteuerung",
                leitmodulId: "cockpit",
                nebenmodulIds: ["analytik", "honorare", "mandatsPipeline", "organon"],
                kontextTyp: .kanzlei),
            Modulverbund(
                id: "kanzlei.pflicht",
                titel: "Pflichtenkontrolle",
                leitmodulId: "berufspflicht",
                nebenmodulIds: ["compliance", "konfliktRadar", "praxisProfil"],
                kontextTyp: .kanzlei)
        ],
        reihenfolge: 5)

    /// Alle mitgelieferten Profile.
    public static let alleStandard: [Nutzungsprofil] = [
        .vollzugriff, .rechtsfall, .risikoanalyse,
        .unternehmenskonkurrenz, .schwachstellenanalyse, .kanzleimanagement
    ]

    // Hilfslisten (entsprechen den ids aus Anwendungsmodell.standard)
    private static let alleModulIds: [String] = [
        "dashboard", "schreibtisch", "vorgaenge", "lexara", "richterprofile",
        "aufgaben", "zeitleiste", "cockpit", "analytik", "strategos",
        "opportunisma", "kiChat", "plattformAgent", "sunTzu", "mandanten",
        "organon", "compliance", "dokumente", "einstellungen", "lageZentrale",
        "konfliktRadar", "mandatsPipeline", "honorare", "entscheidungsjournal",
        "praxisProfil", "beaCheck", "berufspflicht", "adminZentrale",
        "jurisdiktionen", "selbstreparatur"
    ]

    private static let alleZonenIds: [String] = [
        "arbeit", "akten", "kanzlei", "system"
    ]
}
