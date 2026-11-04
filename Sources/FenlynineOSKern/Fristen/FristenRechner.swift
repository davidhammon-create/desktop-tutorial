import Foundation

/// Nachvollziehbare Herleitung einer berechneten Frist -- Nachweis im Haftungsfall.
public struct Fristherleitung: Codable, Hashable, Sendable {
    public var ereignis: Date
    /// z. B. "Zustellung Urteil LG München I"
    public var ereignisBezeichnung: String
    /// z. B. "1 Monat, Ereignisfrist"
    public var definition: String
    public var norm: String
    /// Fristende vor Anwendung des § 193 BGB.
    public var rohesEnde: Date
    /// z. B. "Samstag", "Allerheiligen"; nil, wenn keine Verschiebung nötig war.
    public var verschiebungsgrund: String?
    /// Endgültiges Fristende nach § 193 BGB.
    public var faelligkeit: Date
    public var land: Bundesland
    public var istNotfrist: Bool
    public var rechnerVersion: String

    public init(ereignis: Date,
                ereignisBezeichnung: String,
                definition: String,
                norm: String,
                rohesEnde: Date,
                verschiebungsgrund: String?,
                faelligkeit: Date,
                land: Bundesland,
                istNotfrist: Bool,
                rechnerVersion: String) {
        self.ereignis = ereignis
        self.ereignisBezeichnung = ereignisBezeichnung
        self.definition = definition
        self.norm = norm
        self.rohesEnde = rohesEnde
        self.verschiebungsgrund = verschiebungsgrund
        self.faelligkeit = faelligkeit
        self.land = land
        self.istNotfrist = istNotfrist
        self.rechnerVersion = rechnerVersion
    }

    /// Ein Satz, der die Frist vollständig erklärt -- für Akte und Haftungsnachweis.
    public var klartext: String {
        var s = "\(ereignisBezeichnung) am \(Self.f(ereignis)), \(definition) "
        s += "nach \(norm), Ablauf \(Self.f(rohesEnde))"
        if let g = verschiebungsgrund {
            s += "; \(g) -- daher nach § 193 BGB nächster Werktag: \(Self.f(faelligkeit))"
        }
        if istNotfrist { s += ". Notfrist (§ 224 ZPO): nicht verlängerbar." }
        return s
    }

    private static func f(_ d: Date) -> String {
        let df = DateFormatter()
        df.calendar = Feiertagskalender.kalender
        df.timeZone = Feiertagskalender.kalender.timeZone
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: d)
    }
}

/// Fristberechnung nach §§ 187, 188 BGB mit Werktagsregel des § 193 BGB.
public enum FristenRechner {
    public static let version = "2026.1"

    /// Berechnet Fristende und Fälligkeit.
    /// - Parameters:
    ///   - ereignis: Ereignistag (Ereignisfrist) bzw. Anfangstag (Beginnfrist).
    ///   - ereignisBezeichnung: Klartext des Ereignisses für die Herleitung.
    ///   - definition: Rechtliche Beschreibung der Frist.
    ///   - land: Bundesland des Erklärungsorts (§ 193 BGB).
    ///   - verkuendung: Verkündungsdatum, nur für Höchstfristen (z. B. § 517 ZPO).
    public static func berechne(ereignis: Date,
                                ereignisBezeichnung: String,
                                definition d: Fristdefinition,
                                land: Bundesland,
                                verkuendung: Date? = nil) -> Fristherleitung {

        let kal = Feiertagskalender.kalender
        var start = kal.startOfDay(for: ereignis)
        var beginnGekappt = false

        // § 517 ZPO und Parallelnormen: Der Fristbeginn ist gekappt, nicht das Ende.
        // Ohne Zustellung beginnt die Frist spätestens n Monate nach Verkündung und
        // läuft von dort ihre volle Länge. Würde man stattdessen das Ende kappen,
        // verkürzte sich die Frist um ihre gesamte Länge -- bei einer Notfrist wäre
        // das Rechtsmittel dann unzulässig.
        if let monate = d.spaetesterBeginnMonateAbVerkuendung, let v = verkuendung {
            let spaetesterBeginn = kal.date(byAdding: .month, value: monate,
                                            to: kal.startOfDay(for: v))!
            if spaetesterBeginn < start {
                start = spaetesterBeginn
                beginnGekappt = true
            }
        }

        // §§ 187, 188 BGB
        let komponente: Calendar.Component
        switch d.einheit {
        case .tage:   komponente = .day
        case .wochen: komponente = .weekOfYear
        case .monate: komponente = .month
        case .jahre:  komponente = .year
        }

        // Ereignisfrist (§ 187 Abs. 1 i.V.m. § 188 Abs. 2 Fall 1):
        //   Ende = Ereignistag + n Einheiten.
        // Beginnfrist (§ 187 Abs. 2 i.V.m. § 188 Abs. 2 Fall 2):
        //   Ende = Anfangstag + n Einheiten - 1 Tag.
        var ende = kal.date(byAdding: komponente, value: d.laenge, to: start)!
        if d.anfang == .beginn {
            ende = kal.date(byAdding: .day, value: -1, to: ende)!
        }
        // § 188 Abs. 3 BGB (31.01. + 1 Monat = 28./29.02.) erledigt Foundation
        // durch Kappen des Monatstags.

        // § 193 BGB / § 222 Abs. 2 ZPO
        let (faellig, grund) = Feiertagskalender.naechsterWerktag(ende, land: land)

        let art = d.anfang == .ereignis ? "Ereignisfrist" : "Beginnfrist"
        let einheitText = d.einheit.bezeichnung(anzahl: d.laenge)
        var bezeichnung = ereignisBezeichnung
        if beginnGekappt {
            bezeichnung += " (Fristbeginn gekappt: Zustellung lag später als der "
                        + "gesetzlich spätestmögliche Beginn nach Verkündung)"
        }
        return Fristherleitung(
            ereignis: start,
            ereignisBezeichnung: bezeichnung,
            definition: "\(d.laenge) \(einheitText), \(art)",
            norm: d.norm,
            rohesEnde: ende,
            verschiebungsgrund: grund,
            faelligkeit: faellig,
            land: land,
            istNotfrist: d.istNotfrist,
            rechnerVersion: version
        )
    }

    /// § 199 Abs. 1 BGB -- Beginn der Regelverjährung erst mit Schluss des Jahres der
    /// Entstehung und Kenntnis. Anschließend § 193 BGB.
    /// Hinweis: Höchstfristen des § 199 Abs. 2 bis 4 BGB sind hier nicht berücksichtigt.
    public static func regelverjaehrung(entstehung: Date,
                                        kenntnis: Date? = nil,
                                        land: Bundesland) -> Fristherleitung {
        let kal = Feiertagskalender.kalender
        // Maßgeblich ist der spätere der beiden Zeitpunkte.
        let ausloeser = max(entstehung, kenntnis ?? entstehung)
        let jahr = kal.component(.year, from: ausloeser)
        let jahresschluss = Feiertagskalender.tag(jahr, 12, 31)

        return berechne(
            ereignis: jahresschluss,
            ereignisBezeichnung: "Schluss des Jahres der Entstehung und Kenntnis",
            definition: Fristdefinition(
                laenge: 3, einheit: .jahre, anfang: .ereignis,
                norm: "§§ 195, 199 Abs. 1 BGB",
                istNotfrist: false, verlaengerbar: false,
                hinweis: "Höchstfristen des § 199 Abs. 2-4 BGB gesondert prüfen."),
            land: land)
    }
}
