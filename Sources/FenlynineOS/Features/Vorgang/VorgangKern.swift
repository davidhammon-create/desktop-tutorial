import Foundation

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// DAS EINZIGE KERNOBJEKT VON FenlynineOS
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Umsetzung aus:
// (cid:127) FenlynineOS Prozessarchitektur.pdf -- Teil V (S. 19 f.)
// (cid:127) FenlynineOS Interface Design.pdf -- Teil V (Systemkarte)
//
// Wichtig (aus PDF):
// 1. organon_ref darf null sein -> Organon ist NIE Voraussetzung
// 2. ereignisse[] ist Anhang-Log (Audit / Art. 22 DSGVO / künftiger Ereignisbus)
// 3. bewertung wird NIE von KI geschrieben -- nur vom Formelmotor
// 4. ergebnis: nur Mensch (wertvollster Datensatz -- Kalibrierung)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Vorgangstyp (streit · gestaltung · verhandlung · programm)

enum VorgangTyp: String, Codable, CaseIterable, Identifiable {
case streit // = Lexara
case gestaltung // = Strategos
case verhandlung // = Advocatus (Modus, basiert auf streit)
case programm // = Oportun (Portfolio-Vorgang höherer Ordnung)

var id: String { rawValue }

var bezeichnung: String {
  switch self {
  case .streit: return "Streit"
  case .gestaltung: return "Gestaltung"
  case .verhandlung: return "Verhandlung"
  case .programm: return "Portfolio"
  }
}

var linsenSymbol: String {
  switch self {
  case .streit: return "scalemass"
  case .gestaltung: return "rhombus"
  case .verhandlung: return "circle.fill"
  case .programm: return "square.grid.2x2"
  }
}

var moduleName: String {
  switch self {
  case .streit: return "Lexara"
  case .gestaltung: return "Strategos"
  case .verhandlung: return "Advocatus"
  case .programm: return "Oportun"
  }
}
}

// MARK: - Zustand (Zustandsmaschine, Teil V.2)

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
  case .erfasst: return 0
  case .strukturiert: return 1
  case .bewertet: return 2
  case .entschieden: return 3
  case .laufend: return 4
  case .abgeschlossen: return 5
  }
}

/// Bedingung -- was muss erfüllt sein, um DIESEN Zustand zu erreichen (PDF S. 21).
var bedingung: String {
  switch self {
  case .erfasst: return "Titel + Beschreibung vorhanden"
  case .strukturiert: return "Mindestens 2 Optionen definiert"
  case .bewertet: return "Alle Optionen haben EV + RAV"
  case .entschieden: return "Eine Option gewählt + begründet"
  case .laufend: return "Umsetzung begonnen"
  case .abgeschlossen: return "Ergebnis eingetragen"
  }
}

/// Was dann möglich wird.
var wasErlaubt: String {
  switch self {
  case .erfasst: return "KI-Analyse, Dokumente hochladen"
  case .strukturiert: return "Details eingeben, Argumente sammeln"
  case .bewertet: return "Vergleich, Risiko, Empfehlung, Aufnahme ins Portfolio"
  case .entschieden: return "Verhandlungsmodus, Handlungsplan, Monitoring"
  case .laufend: return "Meilensteine, Neubewertung bei neuer Info"
  case .abgeschlossen: return "Kalibrierung: Prognose vs. Realität"
 }
}
}

// MARK: - Herkunftsmarke (PDF Interface Design, Teil II)
// Vier Herkünfte, vier Marken, keine fünfte. Sitzt links neben JEDER Zahl.

enum Herkunft: String, Codable, CaseIterable, Identifiable {
case formel // l grün -- Deterministisch aus Formelkaskade
case ki // n orange -- KI-Vorschlag, unbestätigt
case mensch // l blau -- Vom Anwalt bestätigt / überschrieben
case quelle // l grau -- Aus Gesetzestext (§, BGH, EuGH, …)

var id: String { rawValue }

var kurz: String {
 switch self {
 case .formel: return "Formel"
 case .ki: return "KI-Vorschlag"
 case .mensch: return "Bestätigt"
 case .quelle: return "Quelle"
 }
}

var beschreibung: String {
 switch self {
 case .formel: return "Deterministisch. Ändert sich nur bei Eingabe-Änderung."
 case .ki: return "Sprachmodell hat geraten. Unbestätigt. Sie haften."
 case .mensch: return "Von einem Menschen bestätigt oder überschrieben."
 case .quelle: return "Aus Gesetzestext / Rechtsprechung. Unveränderlich."
 }
}
}

// MARK: - Partei (Kontext)

struct Partei: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var rolle: String // Kläger, Beklagter, Vertragspartner, Mandant, …
var name: String
/// Verknüpfung zu Organon-Knoten (optional!) -- String-ID aus OrganonStore
var organonKnotenId: String?
}

// MARK: - Zahl mit Herkunft (der Bohrer, PDF Abb. 10)

struct WertMitHerkunft: Codable, Hashable {
var wert: Double
var herkunft: Herkunft
/// Formel, KI-Prompt, Gesetzeszitat, Bestätiger -- je nach Herkunft.
var quelle: String
/// Zeitpunkt der letzten Änderung
var wann: Date = .init()
/// Wer? (Bei Herkunft `.mensch` gefüllt.)
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

// MARK: - Kosten / Chancen / Zeit / Qualitativ

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
var reputation: Int // -5 bis +5
var beziehung: Int
var medien: Int
var praezedenz: Int
}

// MARK: - Argument

struct OptionArgument: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var seite: String // "pro" | "contra"
var text: String
var gewicht: Double // 0.0 … 1.0
}

// MARK: - Risiko-Element (RPN)

struct OptionRisiko: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var titel: String
var eintrittWahrscheinlichkeit: Int // 1..10
var auswirkung: Int // 1..10
var entdeckung: Int // 1..10
var rpn: Int { eintrittWahrscheinlichkeit * auswirkung * entdeckung }
var kritisch: Bool { rpn > 100 }
}

// MARK: - Bewertung (NUR Formelmotor darf schreiben -- PDF Teil VI!)

struct OptionBewertung: Codable, Hashable {
var ev: WertMitHerkunft? // Erwartungswert
var rav: WertMitHerkunft? // Risikoadjustierter Wert
var downside: WertMitHerkunft?
var var95: WertMitHerkunft? // Value at Risk 95%
var var99: WertMitHerkunft?
var sharpe: WertMitHerkunft?
var kelly: WertMitHerkunft?
var breakEven: WertMitHerkunft?
var rpnGesamt: Int = 0
/// Sensitivitätsanalyse -- Kipppunkte für Regler.
var kipppunkte: [String: Double] = [:]
}

// MARK: - Option

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
var istVorgeschichte: Bool = false // nach Typwechsel -> alte Optionen als Vorgeschichte
}

// MARK: - Frist

struct VorgangFrist: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var datum: Date
var art: String
var kritisch: Bool
/// Quelle: Formel (§ 4 KSchG, § 195 BGB, …) oder "manuell"
var quelle: String
var tageBisAblauf: Int {
 Calendar.current.dateComponents([.day], from: .init(), to: datum).day ?? 0
}
}

// MARK: - Ereignis (Anhang-Log, PDF S. 27)

struct VorgangEreignis: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var zeitpunkt: Date = .init()
var was: String
var wer: String
var alt: String?
var neu: String?
}

// MARK: - Empfehlung / Entscheidung / Ergebnis

struct Empfehlung: Codable, Hashable {
var optionId: UUID
var score: Double
var prognose: String
var begruendung: String
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

// MARK: - Der Vorgang selbst

struct Vorgang: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var kurzId: String // "V-2026-0417" -- menschenlesbar
var typ: VorgangTyp
var zustand: VorgangZustand = .erfasst
var titel: String

// nnn KONTEXT nnn
var parteien: [Partei] = []
var abteilung: String?
var verantwortlich: String?
var budget: Double?
/// Organon ist optional -- String-ID aus OrganonStore
var organonKnotenId: String?
var organonKanteId: String?

// nnn SACHVERHALT nnn
var beschreibung: String = ""
var rechtsgebiet: String = ""
var volumen: Double = 0
var dokumente: [VorgangDokument] = []

// nnn OPTIONEN nnn
var optionen: [VorgangOption] = []

// nnn ZEIT nnn
var fristen: [VorgangFrist] = []
var ereignisse: [VorgangEreignis] = []

// nnn ERGEBNIS nnn
var empfehlung: Empfehlung?
var entscheidung: Entscheidung?
var ergebnis: Ergebnis?

// nnn PORTFOLIO nnn
var programmId: UUID? // null wenn allein
var abhaengigVon: [UUID] = []

// nnn META nnn
var angelegt: Date = .init()
var geaendert: Date = .init()
}

// MARK: - Dokument

struct VorgangDokument: Identifiable, Codable, Hashable {
var id: UUID = UUID()
var typ: String // "Vertrag", "Klage", "Beschluss", …
var titel: String
var text: String
var kiExtrakt: String?
var hochgeladen: Date = .init()
}

