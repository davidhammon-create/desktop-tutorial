import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - LegalCase (Case)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct LegalCase: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var fallname: String
var aktenzeichen: String?
var gericht: String?
var rechtsgebiet: String?
var prozessziel: String?
var status: CaseStatus = .aktiv
var instanz: Instanz = .erstinstanz
var zentrale_rechtsfrage: String?
var prognose: Double?
var streitwert: Double?
var gebuehrenstufe: Double?
var sv_kosten: Double?
var reisekosten: Double?
var vergleichsangebot: Double?
var richter_name: String?
var richter_klaeger_rate: Double?
var ki_berater_result: AnyCodable?
var gegner_profil: AnyCodable?
var notes: String?
var folder_id: String?
var mandant_name: String?
var urteil: String?
var abschluss_datum: Date?

enum CodingKeys: String, CodingKey {
  case id, created_by, created_at, updated_at
  case fallname, aktenzeichen, gericht, rechtsgebiet, prozessziel
  case status, instanz, zentrale_rechtsfrage, prognose, streitwert
  case gebuehrenstufe, sv_kosten, reisekosten, vergleichsangebot
  case richter_name, richter_klaeger_rate, ki_berater_result
  case gegner_profil, notes, folder_id, mandant_name
  case urteil, abschluss_datum
}

enum CaseStatus: String, Codable, CaseIterable {
  case aktiv = "Aktiv"
  case vorbereitung = "Vorbereitung"
  case abgeschlossen = "Abgeschlossen"
  case ruhend = "Ruhend"

  var farbe: String {
    switch self {
    case .aktiv: return "green"
    case .vorbereitung: return "blue"
    case .abgeschlossen: return "gray"
    case .ruhend: return "orange"
    }
  }

  var symbol: String {
    switch self {
    case .aktiv: return "circle.fill"
    case .vorbereitung: return "clock.fill"
    case .abgeschlossen: return "checkmark.circle.fill"
    case .ruhend: return "pause.circle.fill"
    }
  }
}

enum Instanz: String, Codable, CaseIterable {
  case erstinstanz = "Erstinstanz"
  case berufung = "Berufung"
  case revision = "Revision"
}

static func neu(fallname: String) -> LegalCase {
  LegalCase(fallname: fallname, status: .vorbereitung)
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Argument
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Argument: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String
var description: String?
var side: ArgumentSeite = .eigen
var strength: Int = 5
var ki_strength: Double?
var ki_reasoning: String?
var type: String?
var zeitpunkt: String?
var counter_argument: String?
var ki_bewertung: String?
var rechtsgrundlage: String?
var linked_evidence_ids: [String]?
var connections: [ArgumentConnection]?

struct ArgumentConnection: Codable, Hashable {
 var targetId: String
 var type: String
 var explanation: String?
 var intensitaet: Int?
}

enum ArgumentSeite: String, Codable, CaseIterable {
 case eigen = "eigen"
 case gegner = "gegner"

 var bezeichnung: String {
   switch self {
   case .eigen: return "Eigenes Argument"
   case .gegner: return "Gegner-Argument"
   }
 }
}

var effectiveStrength: Double { ki_strength ?? Double(strength) }
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Evidence (Beweise)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Evidence: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String
var description: String?
var type: EvidenceType = .dokument
var weight: Int = 5
var ki_weight: Double?
var source: String?
var datum: Date?
var file_url: String?
var ki_bewertung: String?
var linked_argument_ids: [String]?
var zulaessigkeit: String?

enum EvidenceType: String, Codable, CaseIterable {
 case dokument = "Dokument"
 case zeuge = "Zeuge"
 case sachverstaendiger = "Sachverständiger"
 case augenschein = "Augenschein"
 case urkunde = "Urkunde"
 case gestaendnis = "Geständnis"
 case indiz = "Indiz"

 var symbol: String {
   switch self {
   case .dokument: return "doc.fill"
   case .zeuge: return "person.fill"
   case .sachverstaendiger: return "magnifyingglass"
   case .augenschein: return "eye.fill"
   case .urkunde: return "doc.badge.checkmark"
   case .gestaendnis: return "bubble.left.fill"
   case .indiz: return "link"
   }
 }
}

var effectiveWeight: Double { ki_weight ?? Double(weight) }
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Deadline (Frist)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Deadline: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String
var description: String?
var frist_type: FristTyp = .sonstige
var paragraph: String?
var due_date: Date
var side: String = "Wir"
var status: FristStatus = .offen
var erinnerung_tage: Int = 7
var erledigt_am: Date?
var notizen: String?
var wichtigkeit: FristWichtigkeit = .normal
var responsible: String?

enum FristTyp: String, Codable, CaseIterable {
 case berufungsfrist = "Berufungsfrist"
 case berufungsbegruendung = "Berufungsbegründung"
 case revisionsfrist = "Revisionsfrist"
 case klagBegruendung = "Klagebegründung"
 case schriftsatzfrist = "Schriftsatzfrist"
 case widerspruchMahnbescheid = "Widerspruch Mahnbescheid"
 case einspruchVersaeumnisurteil = "Einspruch Versäumnisurteil"
 case eVAntragsfrist = "eV-Antragsfrist"
 case verjährungsfrist = "Verjährungsfrist"
 case klagefristKSchG = "Klagefrist KSchG"
 case brAnzeige = "BR-Anzeige §102 BetrVG"
 case vollstreckungsfristen = "Vollstreckungsfristen"
 case gerichtlich = "Gerichtlich"
 case verfahrensbezogen = "Verfahrensbezogen"
 case intern = "Intern"
 case mandant = "Mandant"
 case verjaehrung = "Verjährung"
 case sonstige = "Sonstige"

 var symbol: String {
   switch self {
   case .gerichtlich, .berufungsfrist, .berufungsbegruendung, .revisionsfrist: return "building.columns"
   case .verfahrensbezogen, .schriftsatzfrist, .klagBegruendung: return "doc.text"
   case .intern: return "person"
   case .mandant: return "person.2"
   case .verjaehrung, .verjährungsfrist: return "clock.badge.exclamationmark"
   default: return "calendar.badge.clock"
   }
 }
}

enum FristStatus: String, Codable, CaseIterable {
 case offen = "offen"
 case erledigt = "erledigt"
 case versaeumt = "versaeumt"
 case verlängert = "verlängert"
}

enum FristWichtigkeit: String, Codable, CaseIterable {
 case niedrig = "niedrig"
 case normal = "normal"
 case hoch = "hoch"
 case kritisch = "kritisch"

 var farbe: String {
   switch self {
   case .niedrig: return "gray"
   case .normal: return "blue"
   case .hoch: return "orange"
   case .kritisch: return "red"
   }
 }
}

var tageVerbleibend: Int {
 Calendar.current.dateComponents([.day], from: Date(), to: due_date).day ?? 0
}

var istKritisch: Bool { tageVerbleibend >= 0 && tageVerbleibend <= 7 }
var istVersaeumt: Bool { status == .versaeumt || (status == .offen && due_date < Date()) }
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - LegalDocument (Dokument)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct LegalDocument: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String
var file_url: String?
var file_type: String?
var file_size: Int?
var ai_summary: String?
var ai_raw: AnyCodable?
var kategorie: DokumentKategorie = .sonstiges
var datum: Date?
var vertraulich: Bool = false
var analyse_status: String?
var tags: [String]?

enum DokumentKategorie: String, Codable, CaseIterable {
 case schriftsatz = "Schriftsatz"
 case beweismittel = "Beweismittel"
 case korrespondenz = "Korrespondenz"
 case urteil = "Urteil"
 case beschluss = "Beschluss"
 case vertrag = "Vertrag"
 case gutachten = "Gutachten"
 case sonstiges = "Sonstiges"
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Person
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Person: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var name: String
var role: Rolle = .zeuge
var organisation: String?
var organization: String? { get { organisation } set { organisation = newValue } }
var email: String?
var telefon: String?
var klaeger_rate: Int?
var vergleich_rate: Int?
var aussagen: Int?
var widersprueche: Int?
var glaubwuerdigkeit: Int?
var dauer_monate: Int?
var notizen: String?
var ki_profil: String?
var adresse: String?

enum Rolle: String, Codable, CaseIterable {
 case richter = "Richter"
 case zeuge = "Zeuge"
 case sachverstaendiger = "Sachverständiger"
 case partei = "Partei"
 case anwalt = "Anwalt"
 case gegner = "Gegner"
 case mandant = "Mandant"
 case gutachter = "Gutachter"

 var symbol: String {
   switch self {
   case .richter: return "hammer"
   case .zeuge: return "person"
   case .sachverstaendiger: return "microscope"
   case .partei: return "person.badge.key"
   case .anwalt: return "briefcase"
   case .gegner: return "person.crop.circle.badge.xmark"
   case .mandant: return "person.crop.circle.badge.checkmark"
   case .gutachter: return "doc.badge.magnifyingglass"
   }
 }
}
}

// Alias for backwards compatibility
typealias PersonRolle = Person.Rolle

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - CaseTask (Aufgabe)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct CaseTask: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String?
var title: String
var description: String?
var status: AufgabeStatus = .offen
var priority: Prioritaet = .mittel
var due_date: Date?
var assigned_to: String?
var tags: [String]?
var erledigt_am: Date?
var checkliste: [ChecklisteItem]?

enum AufgabeStatus: String, Codable, CaseIterable {
 case offen = "Offen"
 case inBearbeitung = "In Bearbeitung"
 case erledigt = "Erledigt"
 case archiviert = "Archiviert"
}

enum Prioritaet: String, Codable, CaseIterable {
 case niedrig = "Niedrig"
 case mittel = "Mittel"
 case hoch = "Hoch"
 case kritisch = "Kritisch"

 var farbe: String {
   switch self {
   case .niedrig: return "gray"
   case .mittel: return "blue"
   case .hoch: return "orange"
   case .kritisch: return "red"
   }
 }
}

struct ChecklisteItem: Codable, Hashable, Identifiable {
 var id = UUID().uuidString
 var text: String
 var erledigt: Bool = false
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - JudgeProfile (Richterprofil)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct JudgeProfile: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var name: String
var gericht: String?
var kammer: String?
var fachgebiet: String?
var klaeger_rate: Double?
var vergleich_rate: Double?
var urteil_dauer_tage: Double?
var stil: RichterStil?
var psycho_profil: String?
var entscheidungsmuster: [String]?
var beobachtungen: [String]?
var erfolgsquote_bei_uns: Double?
var faelle_analysiert: Int?
var staerken: [String]?
var schwaechen: [String]?
var bevorzugte_argumente: [String]?
var fallstricke: [String]?
var bekannt_fuer: String?
var durchschnitt_dauer_monate: Double?
var urteile_gesamt: Int?
var rechtsgebiet: String?
var kategorie: String?
var erfahrungen: [RichterErfahrung]?
var ki_analyse: AnyCodable?
var erfolgs_matrix: AnyCodable?
var beziehungsanalyse: AnyCodable?

struct RichterErfahrung: Codable, Hashable {
 var datum: String?
 var autor: String?
 var fall_kontext: String?
 var vergleichsbereitschaft: Int?
 var entscheidungsgeschwindigkeit: Int?
 var sachkompetenz: Int?
 var text: String?
}

enum RichterStil: String, Codable, CaseIterable {
 case formalistisch = "Formalistisch"
 case pragmatisch = "Pragmatisch"
 case vergleichsorientiert = "Vergleichsorientiert"
 case streng = "Streng"
 case liberal = "Liberal"
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Mandant (Portal-Stamm)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Mandant: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var anzeigename: String
var firma: String?
var typ: MandantTyp = .privat
var status: MandantStatus = .aktiv
var email: String?
var telefon: String?
var mobil: String?
var adresse: String?
var plz: String?
var ort: String?
var land: String? = "DE"
var steuernummer: String?
var iban: String?
var ansprechpartner: String?
var rolleBezeichnung: String? // z.B. Geschäftsführer
var preferredChannel: MandantKanal = .email
var portalZugangAktiv: Bool = false
var portalPinHinweis: String? // nie Klartext-PIN speichern -- nur Hinweis
var tags: [String]? = []
var notizen: String?
var risikostufe: MandantRisiko = .normal
var vertraulichkeit: MandantVertraulichkeit = .standard
var caseIds: [String]? = []
var letzteAktivitaet: Date?
var naechsterKontakt: Date?
var abrechnungshinweis: String?
var uspMerkmale: [String]? = [] // z.B. "Mandate-Radar", "Fristen-Push"

enum MandantTyp: String, Codable, CaseIterable {
 case privat = "Privat"
 case unternehmen = "Unternehmen"
 case oeffentlich = "Öffentlich"
 case verband = "Verband / NGO"
}

enum MandantStatus: String, Codable, CaseIterable {
 case lead = "Lead"
 case aktiv = "Aktiv"
 case ruhend = "Ruhend"
 case beendet = "Beendet"
}

enum MandantKanal: String, Codable, CaseIterable {
 case email = "E-Mail"
 case portal = "Portal"
 case telefon = "Telefon"
 case post = "Post"
}

enum MandantRisiko: String, Codable, CaseIterable {
 case niedrig = "Niedrig"
 case normal = "Normal"
 case erhoeht = "Erhöht"
 case kritisch = "Kritisch"
}

enum MandantVertraulichkeit: String, Codable, CaseIterable {
 case standard = "Standard"
 case sensibel = "Sensibel"
 case streng = "Streng vertraulich"
}
}

struct MandantAktivitaet: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var mandant_id: String
var typ: String // update | anruf | meeting | dokument | portal
var titel: String
var detail: String?
var case_id: String?
var autor: String?
var zeitpunkt: Date = .init()
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - CaseFolder (Ordner)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct CaseFolder: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var name: String
var farbe: String = "blue"
var symbol: String = "folder"
var beschreibung: String?
var parent_id: String?
var sortierung: Int = 0
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - CaseHistory (Audit-Trail)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct CaseHistory: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var change_type: String?
var details: String?
var benutzer: String?
var vorher: AnyCodable?
var nachher: AnyCodable?
var entity_type: String?
var entity_id: String?
var entity_title: String?
var action: String?
var field_changed: String?
var old_value: String?
var new_value: String?
var summary: String?
var user_email: String?
var timestamp: String?
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - TimelineEvent (Zeitstrahleinträge)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct TimelineEvent: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String
var description: String?
var datum: Date
var typ: TimelineTyp = .ereignis
var wichtigkeit: Int = 5
var quelle: String?
var linked_document_id: String?

enum TimelineTyp: String, Codable, CaseIterable {
 case ereignis = "Ereignis"
 case frist = "Frist"
 case hearing = "Verhandlung"
 case entscheidung = "Entscheidung"
 case schriftsatz = "Schriftsatz"
 case meilenstein = "Meilenstein"
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - StrategosScenario (Enterprise-Strategie)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct StrategosScenario: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var titel: String
var modus: StrategosModus = .fall
var case_id: String?

// 6-Schritt-Felder
var unternehmenskontext: AnyCodable?
var situationsanalyse: AnyCodable?
var szenario_matrix: AnyCodable?
var aktionsplan: AnyCodable?
var strategos_empfehlung: AnyCodable?
var lexara_sync: AnyCodable?

// Vertragsanalyse
var vertrag_text: String?
var vertrag_analyse: AnyCodable?
var klausel_analyse: [KlauselAnalyse]?

// Status
var aktueller_schritt: Int = 0
var enterprise_step: Int = 0
var abgeschlossen: Bool = false

// Enterprise-Felder (wie React EnterpriseShell)
var szenario_typ: String?
var rechtsgebiet: String?
var fragestellung: String?
var ausgangslage: String?
var status: String?
var ki_kontext: AnyCodable?
var ki_analyse: AnyCodable?
var finanzdaten: AnyCodable?

enum StrategosModus: String, Codable, CaseIterable {
 case fall = "fall"
 case vertrag = "vertrag"
 case unternehmen = "unternehmen"
}

struct KlauselAnalyse: Codable, Hashable, Identifiable {
 var id = UUID().uuidString
 var klausel_text: String
 var risiko_level: String
 var abteilung: String?
 var zeitlicher_impact: String?
 var finanzielle_auswirkung: Double?
 var empfehlung: String?
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - GegnerVerhalten
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

/// Einzelner Verhaltenseintrag der Gegenseite (1:1 Original GegnerVerhalten-Entity).
struct GegnerVerhalten: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
// Pflichtfelder
var titel: String = ""
var typ: EintragTyp = .sonstiges
var datum: String = "" // ISO-8601-String für einfaches Encoding
// Optionale Felder
var beschreibung: String?
var reaktion: RektionTyp?
var unser_angebot: Double?
var gegner_angebot: Double?
var verzoegerung_tage: Int?
var ergebnis: String?
var pattern_tag: MusterTag?
var auswirkung_prognose: Double = 0

enum EintragTyp: String, Codable, CaseIterable {
 case versaeumte_frist = "versaeumte_frist"
 case vergleichsreaktion = "vergleichsreaktion"
 case taktik  = "taktik"
 case prozessverhalten = "prozessverhalten"
 case sonstiges = "sonstiges"

 var bezeichnung: String {
   switch self {
   case .versaeumte_frist: return "Versäumte Frist"
   case .vergleichsreaktion: return "Vergleichsreaktion"
   case .taktik: return "Taktik"
   case .prozessverhalten: return "Prozessverhalten"
   case .sonstiges: return "Sonstiges"
   }
 }

 var symbol: String {
   switch self {
   case .versaeumte_frist: return "clock.badge.exclamationmark"
   case .vergleichsreaktion: return "handshake"
   case .taktik: return "chesspiece.king.fill"
   case .prozessverhalten: return "building.columns"
   case .sonstiges: return "doc.text"
   }
 }
}

enum RektionTyp: String, Codable, CaseIterable {
 case abgelehnt = "abgelehnt"
 case angenommen = "angenommen"
 case ignoriert = "ignoriert"
 case verzoegert = "verzoegert"
 case gegenvorschlag = "gegenvorschlag"
 case keine_reaktion = "keine_reaktion"

 var bezeichnung: String { rawValue.replacingOccurrences(of: "_", with: " ").capitalized }
}

enum MusterTag: String, Codable, CaseIterable {
 case verzoegerungstaktik = "verzoegerungstaktik"
 case druckmittel = "druckmittel"
 case konzessionsbereit = "konzessionsbereit"
 case konfrontativ = "konfrontativ"
 case kooperativ = "kooperativ"
 case unberechenbar = "unberechenbar"

 var bezeichnung: String {
   switch self {
   case .verzoegerungstaktik: return "Verzögerung"
   case .druckmittel: return "Druckmittel"
   case .konzessionsbereit: return "Konzessionsbereit"
   case .konfrontativ: return "Konfrontativ"
   case .kooperativ: return "Kooperativ"
   case .unberechenbar: return "Unberechenbar"
   }
 }
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - KIUsageLog
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct KIUsageLog: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String?
var ki_function: String?
var input_summary: String?
var output: String?
var model: String?
var context: String?
var timestamp: String?
var rating: Int?
var feedback: String?
var is_duplicate: Bool?
var parent_log_id: String?

// Legacy-Felder (ältere API-Varianten)
var funktion: String?
var prompt_tokens: Int?
var completion_tokens: Int?
var modell: String?
var dauer_ms: Int?
var erfolg: Bool = true
var fehler: String?

var anzeigeFunktion: String { ki_function ?? funktion ?? context ?? "KI" }
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - LegalLoophole (Rechtslücken)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct LegalLoophole: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String
var beschreibung: String
var rechtsgrundlage: String?
var nutzbarkeit: Int = 5
var risiko: Int = 5
var ki_bewertung: String?
var anwendungsempfehlung: String?
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - CaseQuestionnaire
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct CaseQuestionnaire: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var antworten: AnyCodable?
var abgeschlossen: Bool = false
var version: String = "1.0"
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - CaseWarning
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct CaseWarning: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String
var title: String = ""
var description: String?
var severity: Schwere = .mittel
var warning_type: String? // diskrepanz, fehlender_beleg, veraltete_rspr, widerspruch…
var element_title: String? // Titel des betroffenen Elements (Argument/Beweis)
var suggestion: String? // Empfohlene Maßnahme
var rspr_reference: String? // Rechtsprechungs-Referenz
var resolved: Bool = false
var resolved_date: String?

enum Schwere: String, Codable, CaseIterable {
 case niedrig = "niedrig"
 case mittel = "mittel"
 case hoch = "hoch"
 case kritisch = "kritisch"

 var bezeichnung: String {
   switch self {
   case .niedrig: return "Niedrig"
   case .mittel: return "Mittel"
   case .hoch: return "Hoch"
   case .kritisch: return "Kritisch"
   }
 }

 var farbe: Color {
   switch self {
   case .niedrig: return .gray
   case .mittel: return .orange
   case .hoch: return .red.opacity(0.8)
   case .kritisch: return .red
   }
 }

 var sortOrder: Int {
   switch self { case .kritisch: return 0; case .hoch: return 1; case .mittel: return 2; case .niedrig: return 3 }
 }
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - AIPerformanceFeedback
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct AIPerformanceFeedback: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var case_id: String?
var case_name: String?
var funktion: String?
var bewertung: Int?
var kommentar: String?
var prompt_hash: String?
var gesamtbewertung: Int?
var prognose_rating: Int?
var prognose_abweichung: Double?
var strategie_rating: Int?
var strategie_feedback: String?
var ki_berater_rating: Int?
var ki_berater_feedback: String?
var ki_feedback: String?
var fall_erfolgreich: Bool?
var verbesserungsvorschlaege: AnyCodable?

var effektiveGesamtbewertung: Int {
 gesamtbewertung ?? bewertung ?? 0
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - JurisdictionInsight
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct JurisdictionInsight: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var jurisdiction: String
var rechtsgebiet: String
var insight: String
var quelle: String?
var relevanz: Int = 5
var datum: Date?
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - User
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct User: Base44Entity, Hashable {
var id: String?
var created_by: String?
var created_at: Date?
var updated_at: Date?

var email: String
var name: String?
var role: UserRolle = .anwalt
var kanzlei: String?
var jurisdiction: String = "DE"
var sprache: String = "de"
var plan: UserPlan = .free
var avatar_url: String?
var einstellungen: AnyCodable?

enum UserRolle: String, Codable, CaseIterable {
 case anwalt = "Anwalt"
 case partner = "Partner"
 case referendar = "Referendar"
 case sekretariat = "Sekretariat"
 case unternehmensrechtler = "Unternehmensrechtler"
 case admin = "Admin"
}

enum UserPlan: String, Codable, CaseIterable {
 case free = "free"
 case basis = "basis"
 case professional = "professional"
 case enterprise = "enterprise"
}

enum CodingKeys: String, CodingKey {
 case id
 case created_by
 case created_at = "created_date"
 case updated_at = "updated_date"
 case email
 case name = "full_name"
 case role
 case kanzlei
 case jurisdiction
 case sprache
 case plan
 case avatar_url
 case einstellungen
}

init(from decoder: Decoder) throws {
 let c = try decoder.container(keyedBy: CodingKeys.self)
 id = try c.decodeIfPresent(String.self, forKey: .id)
 created_by = try c.decodeIfPresent(String.self, forKey: .created_by)
 created_at = try c.decodeIfPresent(Date.self, forKey: .created_at)
 updated_at = try c.decodeIfPresent(Date.self, forKey: .updated_at)
 email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
 name = try c.decodeIfPresent(String.self, forKey: .name)
 if let r = try? c.decode(UserRolle.self, forKey: .role) {
   role = r
 } else if let rs = try? c.decode(String.self, forKey: .role) {
   role = UserRolle(rawValue: rs) ?? UserRolle(rawValue: rs.capitalized) ?? .anwalt
 } else {
   role = .anwalt
 }
 kanzlei = try c.decodeIfPresent(String.self, forKey: .kanzlei)
 jurisdiction = try c.decodeIfPresent(String.self, forKey: .jurisdiction) ?? "DE"
 sprache = try c.decodeIfPresent(String.self, forKey: .sprache) ?? "de"
 plan = try c.decodeIfPresent(UserPlan.self, forKey: .plan) ?? .free
 avatar_url = try c.decodeIfPresent(String.self, forKey: .avatar_url)
 einstellungen = try c.decodeIfPresent(AnyCodable.self, forKey: .einstellungen)
}

init(email: String, name: String? = nil) {
 self.email = email
 self.name = name
}

func encode(to encoder: Encoder) throws {
 var c = encoder.container(keyedBy: CodingKeys.self)
 try c.encodeIfPresent(id, forKey: .id)
 try c.encodeIfPresent(created_by, forKey: .created_by)
 try c.encodeIfPresent(created_at, forKey: .created_at)
 try c.encodeIfPresent(updated_at, forKey: .updated_at)
 try c.encode(email, forKey: .email)
 try c.encodeIfPresent(name, forKey: .name)
 try c.encode(role, forKey: .role)
 try c.encodeIfPresent(kanzlei, forKey: .kanzlei)
 try c.encode(jurisdiction, forKey: .jurisdiction)
 try c.encode(sprache, forKey: .sprache)
 try c.encode(plan, forKey: .plan)
 try c.encodeIfPresent(avatar_url, forKey: .avatar_url)
 try c.encodeIfPresent(einstellungen, forKey: .einstellungen)
}
}

