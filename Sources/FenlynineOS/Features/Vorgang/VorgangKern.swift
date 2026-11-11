import Foundation
enum VorgangTyp: String, Codable, CaseIterable, Identifiable {
    case streit       // = Lexara
    case gestaltung   // = Strategos
    case verhandlung  // = Advocatus (Modus, basiert auf streit)
    case programm     // = Oportun (Portfolio-Vorgang höherer Ordnung)
    var id: String { rawValue }
    var bezeichnung: String {
        switch self {
        case .streit:      return "Streit"
        case .gestaltung:  return "Gestaltung"
        case .verhandlung: return "Verhandlung"
        case .programm:    return "Portfolio"
        }
    }
    var linsenSymbol: String {
        switch self {
        case .streit:      return "scalemass"
        case .gestaltung:  return "rhombus"
        case .verhandlung: return "circle.fill"
        case .programm:    return "square.grid.2x2"
        }
    }
    var moduleName: String {
        switch self {
        case .streit:      return "Lexara"
        case .gestaltung:  return "Strategos"
        case .verhandlung: return "Advocatus"
        case .programm:    return "Oportun"
        }
    }
}
enum VorgangZustand: String, Codable, CaseIterable, Identifiable {
    case erfasst
    case strukturiert
    case bewertet
    case entschieden
    case laufend
    case abgeschlossen
    var id: String { rawValue }
    var bezeichnung: String { rawValue.capitalized }
    var reihenfolge: Int {
        switch self {
        case .erfasst:       return 0
        case .strukturiert:  return 1
        case .bewertet:      return 2
        case .entschieden:   return 3
        case .laufend:       return 4
        case .abgeschlossen: return 5
        }
    }
    var bedingung: String {
        switch self {
        case .erfasst:       return "Titel + Beschreibung vorhanden"
        case .strukturiert:  return "Mindestens 2 Optionen definiert"
        case .bewertet:      return "Alle Optionen haben EV + RAV"
        case .entschieden:   return "Eine Option gewählt + begründet"
        case .laufend:       return "Umsetzung begonnen"
        case .abgeschlossen: return "Ergebnis eingetragen"
        }
    }
    var wasErlaubt: String {
        switch self {
        case .erfasst:       return "KI-Analyse, Dokumente hochladen"
        case .strukturiert:  return "Details eingeben, Argumente sammeln"
        case .bewertet:      return "Vergleich, Risiko, Empfehlung, Aufnahme ins Portfolio"
        case .entschieden:   return "Verhandlungsmodus, Handlungsplan, Monitoring"
        case .laufend:       return "Meilensteine, Neubewertung bei neuer Info"
        case .abgeschlossen: return "Kalibrierung: Prognose vs. Realität"
        }
    }
}
enum Herkunft: String, Codable, CaseIterable, Identifiable {
    case formel       // ● grün — Deterministisch aus Formelkaskade
    case ki           // ◯ orange — KI-Vorschlag, unbestätigt
    case mensch       // ● blau — Vom Anwalt bestätigt / überschrieben
    case quelle       // ● grau — Aus Gesetzestext (§, BGH, EuGH, …)
    var id: String { rawValue }
    var kurz: String {
        switch self {
        case .formel: return "Formel"
        case .ki:     return "KI-Vorschlag"
        case .mensch: return "Bestätigt"
        case .quelle: return "Quelle"
        }
    }
    var beschreibung: String {
        switch self {
        case .formel: return "Deterministisch. Ändert sich nur bei Eingabe-Änderung."
        case .ki:     return "Sprachmodell hat geraten. Unbestätigt. Sie haften."
        case .mensch: return "Von einem Menschen bestätigt oder überschrieben."
        case .quelle: return "Aus Gesetzestext / Rechtsprechung. Unveränderlich."
        }
    }
}
struct Partei: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var rolle: String       // Kläger, Beklagter, Vertragspartner, Mandant, …
    var name: String
    var organonKnotenId: String?
}
struct WertMitHerkunft: Codable, Hashable {
    var wert: Double
    var herkunft: Herkunft
    var quelle: String
    var wann: Date = .init()
    var wer: String?
    static func formel(_ w: Double, _ formel: String) -> WertMitHerkunft {
        .init(wert: w, herkunft: .formel, quelle: formel)
    }
    static func ki(_ w: Double, modell: String = "KI") -> WertMitHerkunft {
        .init(wert: w, herkunft: .ki, quelle: modell)
    }
    static func mensch(_ w: Double, name: String) -> WertMitHerkunft {
        .init(wert: w, herkunft: .mensch, quelle: "Mensch", wer: name)
    }
    static func quelle(_ w: Double, norm: String) -> WertMitHerkunft {
        .init(wert: w, herkunft: .quelle, quelle: norm)
    }
}
struct OptionKosten: Codable, Hashable {
    var anwalt: Double
    var gericht: Double
    var intern: Double
    var opportunitaet: Double
    var summe: Double { anwalt + gericht + intern + opportunitaet }
}
struct OptionChancen: Codable, Hashable {
    var pErfolg: WertMitHerkunft
    var best: WertMitHerkunft
    var worst: WertMitHerkunft
    var likely: WertMitHerkunft
}
struct OptionZeit: Codable, Hashable {
    var minMonate: Int
    var maxMonate: Int
}
struct OptionQualitativ: Codable, Hashable {
    var reputation: Int  // −5 bis +5
    var beziehung: Int
    var medien: Int
    var praezedenz: Int
}
struct OptionArgument: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var seite: String  // "pro" | "contra"
    var text: String
    var gewicht: Double  // 0.0 … 1.0
}
struct OptionRisiko: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titel: String
    var eintrittWahrscheinlichkeit: Int  // 1..10
    var auswirkung: Int                  // 1..10
    var entdeckung: Int                  // 1..10
    var rpn: Int { eintrittWahrscheinlichkeit * auswirkung * entdeckung }
    var kritisch: Bool { rpn > 100 }
}
struct OptionBewertung: Codable, Hashable {
    var ev: WertMitHerkunft?           // Erwartungswert
    var rav: WertMitHerkunft?          // Risikoadjustierter Wert
    var downside: WertMitHerkunft?
    var var95: WertMitHerkunft?        // Value at Risk 95%
    var var99: WertMitHerkunft?
    var sharpe: WertMitHerkunft?
    var kelly: WertMitHerkunft?
    var breakEven: WertMitHerkunft?
    var rpnGesamt: Int = 0
    var kipppunkte: [String: Double] = [:]
}
struct VorgangOption: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String
    var beschreibung: String
    var kosten: OptionKosten
    var chancen: OptionChancen
    var zeit: OptionZeit
    var qualitativ: OptionQualitativ
    var argumente: [OptionArgument] = []
    var risiken: [OptionRisiko] = []
    var bewertung: OptionBewertung = .init()
    var istVorgeschichte: Bool = false  // nach Typwechsel → alte Optionen als Vorgeschichte
    var legalitaet: OptionLegalitaet? = nil
    var pManuellUebersteuert: Bool? = nil
    var legalitaetsStatus: OptionLegalitaet { legalitaet ?? .legal }
    var pIstManuell: Bool { pManuellUebersteuert ?? false }
}
struct VorgangFrist: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var datum: Date
    var art: String
    var kritisch: Bool
    var quelle: String
    var typ: FristTyp? = nil
    var tageBisAblauf: Int {
        Calendar.current.dateComponents([.day], from: .init(), to: datum).day ?? 0
    }
    var fristTyp: FristTyp { typ ?? .frist }
    var erzeugtAlarm: Bool { fristTyp == .frist }
    init(id: UUID = UUID(), datum: Date = Date(), art: String, kritisch: Bool, quelle: String, typ: FristTyp = .frist) {
        self.id = id
        self.datum = datum
        self.art = art
        self.kritisch = kritisch
        self.quelle = quelle
        self.typ = typ
    }
}
struct VorgangEreignis: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var zeitpunkt: Date = .init()
    var was: String
    var wer: String
    var alt: String?
    var neu: String?
}
struct Empfehlung: Codable, Hashable {
    var optionId: UUID
    var score: Double
    var prognose: String
    var begruendung: String
    var gegenprobe: String? = nil
}
struct Entscheidung: Codable, Hashable {
    var optionId: UUID
    var wer: String
    var wann: Date
    var abweichungGrund: String?
}
struct Ergebnis: Codable, Hashable {
    var realKosten: Double
    var realDauerMonate: Int
    var realAusgang: String
}
struct Vorgang: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kurzId: String  // "V-2026-0417" — menschenlesbar
    var typ: VorgangTyp
    var zustand: VorgangZustand = .erfasst
    var titel: String
    var parteien: [Partei] = []
    var abteilung: String?
    var verantwortlich: String?
    var budget: Double?
    var organonKnotenId: String?
    var organonKanteId: String?
    var beschreibung: String = ""
    var rechtsgebiet: String = ""
    var volumen: Double = 0
    var dokumente: [VorgangDokument] = []
    var optionen: [VorgangOption] = []
    var fristen: [VorgangFrist] = []
    var ereignisse: [VorgangEreignis] = []
    var empfehlung: Empfehlung?
    var entscheidung: Entscheidung?
    var ergebnis: Ergebnis?
    var programmId: UUID?  // null wenn allein
    var abhaengigVon: [UUID] = []
    var betriebsvereinbarungTitel: String? = nil
    var mandantenProfil: MandantenProfil? = nil
    var profil: MandantenProfil { mandantenProfil ?? .ausgewogen }
    var angelegt: Date = .init()
    var geaendert: Date = .init()
    var aktiveOptionen: [VorgangOption] { optionen.filter { !$0.istVorgeschichte } }
}
struct VorgangDokument: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var typ: String         // "Vertrag", "Klage", "Beschluss", …
    var titel: String
    var text: String
    var kiExtrakt: String?
    var hochgeladen: Date = .init()
}
