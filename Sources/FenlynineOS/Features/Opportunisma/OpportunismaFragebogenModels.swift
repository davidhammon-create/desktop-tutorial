import Foundation

// MARK: - Fragebogen (ausschließlich Multiple Choice · Unternehmensfokus)

struct PragFrageOption: Identifiable, Hashable {
let id: String
let label: String
let detail: String?
}

struct PragFrage: Identifiable {
let id: String
let schrittIndex: Int
let text: String
let hinweis: String?
let module: [OpportunismaTab]
let optionen: [PragFrageOption]
}

struct PragFrageAntwort: Equatable {
var optionId: String?

func zusammenfassung(optionen: [PragFrageOption]) -> String {
  guard let id = optionId, let opt = optionen.first(where: { $0.id == id }) else { return "--" }
  if let d = opt.detail, !d.isEmpty { return "\(opt.label) -- \(d)" }
  return opt.label
}

var istAusgefuellt: Bool { optionId != nil }
}

struct PragFragebogenSchritt: Identifiable {
let index: Int
let titel: String
let untertitel: String
let strategosBezug: String?
let fragen: [PragFrage]

var id: Int { index }
}

enum PragFragebogenPhase: String {
case fragen, auswertung, abgeschlossen
}

struct PragKausalitaet: Identifiable, Equatable {
let id = UUID()
var ursache: String
var wirkung: String
var beeinflussbar: Bool
var bewertung: String
var betroffene: [String]
var empfehlung: String?
var strategosBezug: String?
}

struct PragPrognoseZeile: Identifiable, Equatable {
let id = UUID()
var situation: String
var option: String
var fuehrt_zu: String
var vorteile: [String]
var risiken: [String]
var wahrscheinlichkeit: Int
var kontrolle: Int
var beeinflussbar: Bool
var mittel: [String]
var dimension: String // Politik | Wirtschaft | Wissenschaft
}

/// Verknüpfung Fragebogen/Strategos -> Modul
struct PragModulQuelle: Identifiable, Equatable {
let modul: OpportunismaTab
var quellen: [String]
var aktiv: Bool
var id: String { modul.rawValue }
}

// MARK: - Fragenkatalog (Unternehmen · Politik · Wirtschaft · Wissenschaft)

enum OpportunismaFragebogenBank {
/// Adaptiert Fragen wenn Strategos-Vertragsanalyse vorliegt; sonst Standardbogen
static func schritte(fuer szenario: StrategosScenario?) -> [PragFragebogenSchritt] {
  guard let va = StrategosOpportunismaVertragsService.vertragsAnalyseDict(fuer: szenario) else {
    return standardSchritte
  }
  var result = standardSchritte
  if let idx = result.firstIndex(where: { $0.index == 1 }) {
    result.insert(vertragAdaptionsSchritt(aus: va), at: idx + 1)
  } else {
    result.insert(vertragAdaptionsSchritt(aus: va), at: 1)
  }
  return result
}

/// Multiple-Choice-Fragen aus Vertrags-KI (klauseln, termine, ziele)
private static func vertragAdaptionsSchritt(aus va: [String: Any]) -> PragFragebogenSchritt {
  var fragen: [PragFrage] = []

 if let termine = va["liefertermine"] as? [[String: Any]], let t = termine.first {
   let terminLabel = t["termin"] as? String ?? "Liefertermin"
   fragen.append(PragFrage(
     id: "vertrag_verzug_prioritaet",
     schrittIndex: 10,
     text: "Bei \(terminLabel): Was ist Ihr Unternehmensziel?",
     hinweis: "Aus Strategos-Vertragsanalyse abgeleitet",
     module: [.machtStrategie, .szenarien, .risiken],
     optionen: [
       .init(id: "einhalten", label: "Eigenen Termin einhalten", detail: "Compliance-Fokus"),
       .init(id: "schadenersatz", label: "Schadenersatz bei Verzug des Partners", detail: nil),
       .init(id: "tolerieren", label: "Verzug tolerieren -- geringer Firmenschaden", detail: nil),
       .init(id: "strategisch", label: "Verzug des Partners strategisch nutzen", detail: "Opportunisma-Pfad")
     ]
   ))
 }

 if let ziele = va["zielhypothesen"] as? [[String: Any]], !ziele.isEmpty {
   let opts = ziele.prefix(4).enumerated().map { i, z in
     PragFrageOption(
       id: "ziel_\(i)",
       label: z["ziel"] as? String ?? "Ziel \(i + 1)",
       detail: z["typ"] as? String
     )
   }
   fragen.append(PragFrage(
     id: "vertrag_hauptziel",
     schrittIndex: 10,
     text: "Welches Vertragsziel priorisiert Ihr Unternehmen?",
     hinweis: "Strategos Zielhypothesen",
     module: [.uebersicht, .machtStrategie, .narrativ],
     optionen: opts + [.init(id: "offen", label: "Noch unklar -- Fragebogen klärt", detail: nil)]
   ))
 }

 if let klauseln = va["klauseln"] as? [[String: Any]], !klauseln.isEmpty {
   let opts = klauseln.prefix(4).enumerated().map { i, k in
     PragFrageOption(
       id: "klausel_\(i)",
       label: k["klausel_typ"] as? String ?? "Klausel",
       detail: k["risiko_level"] as? String
     )
   }
   fragen.append(PragFrage(
     id: "vertrag_klausel_fokus",
     schrittIndex: 10,
     text: "Welche Klausel ist für Ihr Unternehmen kritisch?",
     hinweis: "Aus Vertragsanalyse",
     module: [.risiken, .ressourcen, .dossier],
     optionen: opts
   ))
 }

 if fragen.isEmpty {
   fragen.append(PragFrage(
     id: "vertrag_allgemein",
     schrittIndex: 10,
     text: "Vertragslage: Was soll Opportunisma priorisieren?",
     hinweis: "Vertrag in Strategos analysiert",
     module: [.machtStrategie, .risiken],
     optionen: [
       .init(id: "compliance", label: "Vertragserfüllung", detail: nil),
       .init(id: "verhandlung", label: "Nachverhandlung", detail: nil),
       .init(id: "durchsetzung", label: "Rechtliche Durchsetzung", detail: nil),
       .init(id: "ausstieg", label: "Vertragsausstieg prüfen", detail: nil)
     ]
   ))
 }

 return PragFragebogenSchritt(
   index: 10,
   titel: "VERTRAGS-ANPASSUNG",
   untertitel: "Fragen aus Strategos-Vertragsanalyse (Multiple Choice)",
   strategosBezug: "Schritt 3 Vertragsanalyse · Opportunisma-Kausalität",
   fragen: fragen
 )
}

static let standardSchritte: [PragFragebogenSchritt] = [
 PragFragebogenSchritt(
   index: 0,
   titel: "STRATEGOS-ANBINDUNG",
   untertitel: "Opportunisma erweitert Strategos -- Enterprise-Analysen fließen hier ein.",
   strategosBezug: "Schritt 0-4 in Strategos (Dokumente, Vertrag, Patent, Situation)",
   fragen: [
     PragFrage(
       id: "strategos_status",
       schrittIndex: 0,
       text: "Welchen Reifegrad hat Ihre Strategos-Dokumentation?",
       hinweis: "Opportunisma nutzt vorhandene Strategos-Szenarien als Datenbasis.",
       module: [.strategosLink, .uebersicht],
       optionen: [
         .init(id: "voll", label: "Vollständig (Dokumente + Analysen)", detail: "Vertrag, Patent, Situation vorhanden"),
         .init(id: "teil", label: "Teilweise (1-2 Analysen)", detail: "Lücken in Enterprise-Schritten"),
         .init(id: "start", label: "Gerade gestartet", detail: "Nur Kontext oder Briefing"),
         .init(id: "keins", label: "Noch kein Strategos-Szenario", detail: "Fragebogen legt Grundlage")
       ]
     ),
     PragFrage(
       id: "strategos_schwerpunkt",
       schrittIndex: 0,
       text: "Welcher Strategos-Schwerpunkt ist für Ihr Unternehmen zentral?",
       hinweis: nil,
       module: [.strategosLink, .ressourcen, .risiken],
       optionen: [
         .init(id: "vertrag", label: "Vertrags- & Klauselrisiken", detail: "Strategos Schritt 3"),
         .init(id: "patent", label: "Patent / IP / FTO", detail: "Strategos Schritt 4"),
         .init(id: "situation", label: "Rechtsgebiet-Situationsanalyse", detail: "Strategos Schritt 2"),
         .init(id: "handlung", label: "Handlungsoptionen & Quantifizierung", detail: "Strategos Schritt 5-6"),
         .init(id: "mix", label: "Ganzheitliches Enterprise-Bild", detail: "Alle Schritte verknüpft")
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 1,
   titel: "UNTERNEHMENSPROFIL",
   untertitel: "Branche, Größe und strategische Ausrichtung der Organisation.",
   strategosBezug: "Strategos Schritt 1 -- Unternehmenskontext",
   fragen: [
     PragFrage(
       id: "branche",
       schrittIndex: 1,
       text: "Primäre Branche des Unternehmens?",
       hinweis: nil,
       module: [.uebersicht, .hegemonogramm],
       optionen: [
         .init(id: "tech", label: "Technologie / Digital", detail: nil),
         .init(id: "industrie", label: "Industrie / Produktion", detail: nil),
         .init(id: "finanz", label: "Finanz / Versicherung", detail: nil),
         .init(id: "energie", label: "Energie / Infrastruktur", detail: nil),
         .init(id: "gesund", label: "Gesundheit / Life Sciences", detail: nil),
         .init(id: "dienst", label: "Dienstleistung / Beratung", detail: nil)
       ]
     ),
     PragFrage(
       id: "groesse",
       schrittIndex: 1,
       text: "Unternehmensgröße (Marktpräsenz)?",
       hinweis: nil,
       module: [.uebersicht, .ressourcen],
       optionen: [
         .init(id: "konzern", label: "Konzern / >5.000 MA", detail: "Internationale Präsenz"),
         .init(id: "mittel", label: "Mittelstand / 250-5.000 MA", detail: "Regional bis national"),
         .init(id: "kmu", label: "KMU / <250 MA", detail: "Fokussierter Markt"),
         .init(id: "startup", label: "Scale-up / Startup", detail: "Wachstumsphase")
       ]
     ),
     PragFrage(
       id: "maerkte",
       schrittIndex: 1,
       text: "Geografischer Schwerpunkt?",
       hinweis: nil,
       module: [.netzwerk, .risiken],
       optionen: [
         .init(id: "dach", label: "DACH", detail: nil),
         .init(id: "eu", label: "EU-weit", detail: nil),
         .init(id: "global", label: "Global", detail: nil),
         .init(id: "lokal", label: "Regional / lokal", detail: nil)
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 2,
   titel: "MARKT & WETTBEWERB",
   untertitel: "Marktposition und Wettbewerbsdruck auf Unternehmensebene.",
   strategosBezug: "Strategos Handlungsoptionen · Wettbewerbsrisiken",
   fragen: [
     PragFrage(
       id: "marktposition",
       schrittIndex: 2,
       text: "Marktposition Ihres Unternehmens?",
       hinweis: nil,
       module: [.uebersicht, .gegneranalyse],
       optionen: [
         .init(id: "fuehrer", label: "Marktführer", detail: "Dominante Position"),
         .init(id: "heraus", label: "Herausforderer", detail: "Wachsend, unter Druck"),
         .init(id: "nische", label: "Nischenführer", detail: "Spezialisierung"),
         .init(id: "nachz", label: "Nachzügler / unter Druck", detail: "Marktanteilsverlust")
       ]
     ),
     PragFrage(
       id: "wettbewerb_intensitaet",
       schrittIndex: 2,
       text: "Intensität des Wettbewerbs?",
       hinweis: nil,
       module: [.gegneranalyse, .szenarien],
       optionen: [
         .init(id: "hoch", label: "Sehr hoch", detail: "Preis- & Innovationsdruck"),
         .init(id: "mittel", label: "Mittel", detail: "Stabile Konkurrenz"),
         .init(id: "niedrig", label: "Niedrig", detail: "Hohe Eintrittsbarrieren"),
         .init(id: "disrupt", label: "Disruptiv / neu", detail: "Neue Akteure am Markt")
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 3,
   titel: "POLITIK & REGULATORIK",
   untertitel: "Politische Einflussnahme, Gesetze und Lobby-Position des Unternehmens.",
   strategosBezug: "Strategos Rechtsgebiet-Analyse · kritische Fristen",
   fragen: [
     PragFrage(
       id: "regulatorik",
       schrittIndex: 3,
       text: "Regulatorische Belastung für Ihr Unternehmen?",
       hinweis: nil,
       module: [.risiken, .narrativ],
       optionen: [
         .init(id: "stark", label: "Stark reguliert", detail: "Finanz, Energie, Gesundheit …"),
         .init(id: "moderat", label: "Moderat", detail: "Branchenstandards"),
         .init(id: "gering", label: "Gering", detail: "Wenig staatliche Eingriffe"),
         .init(id: "wandel", label: "Im Wandel", detail: "Neue Gesetze drohen / kommen")
       ]
     ),
     PragFrage(
       id: "politik_einfluss",
       schrittIndex: 3,
       text: "Politische Einflussnahme des Unternehmens?",
       hinweis: "Lobby, Verbände, Policy-Arbeit -- legal & transparent.",
       module: [.netzwerk, .narrativ, .entscheidungsnetz],
       optionen: [
         .init(id: "etabliert", label: "Etabliert", detail: "Aktive Verbände & Anbindung"),
         .init(id: "aufbau", label: "Im Aufbau", detail: "Erste Kontakte"),
         .init(id: "reaktiv", label: "Reaktiv", detail: "Nur bei Gesetzesänderungen"),
         .init(id: "defizit", label: "Defizit", detail: "Kaum strukturierte Anbindung")
       ]
     ),
     PragFrage(
       id: "gesetzeslage",
       schrittIndex: 3,
       text: "Aktuelle Gesetzeslage für Ihre Branche?",
       hinweis: nil,
       module: [.risiken, .szenarien],
       optionen: [
         .init(id: "guenstig", label: "Überwiegend günstig", detail: "Regulierung stützt Geschäftsmodell"),
         .init(id: "neutral", label: "Neutral", detail: "Keine großen Änderungen"),
         .init(id: "unguenstig", label: "Ungünstig / Verschärfung", detail: "Kosten & Risiken steigen"),
         .init(id: "offen", label: "Offen / unklar", detail: "Gesetzgebung in Flux")
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 4,
   titel: "WISSENSCHAFT & INNOVATION",
   untertitel: "Forschung, Patente, akademische Partnerschaften -- Position in der Wissenschaft.",
   strategosBezug: "Strategos Patentanalyse · IP-Strategie",
   fragen: [
     PragFrage(
       id: "forschung",
       schrittIndex: 4,
       text: "Forschungs- & Innovationskraft?",
       hinweis: nil,
       module: [.hegemonogramm, .ressourcen],
       optionen: [
         .init(id: "fuehrer", label: "Branchenführend", detail: "Hohe F&E-Quote"),
         .init(id: "solide", label: "Solide", detail: "Kontinuierliche Entwicklung"),
         .init(id: "begrenzt", label: "Begrenzt", detail: "Wenig eigene F&E"),
         .init(id: "abhaengig", label: "Abhängig von Partnern", detail: "Externe Innovation")
       ]
     ),
     PragFrage(
       id: "wissenschaft_netz",
       schrittIndex: 4,
       text: "Anbindung an Wissenschaft & Forschung?",
       hinweis: "Universitäten, Institute, Standards-Gremien.",
       module: [.netzwerk, .hegemonogramm],
       optionen: [
         .init(id: "stark", label: "Starke Kooperationen", detail: "Joint Research, Patente"),
         .init(id: "projekt", label: "Projektbezogen", detail: "Einzelne Partnerschaften"),
         .init(id: "schwach", label: "Schwach", detail: "Kaum strukturiert"),
         .init(id: "strategisch", label: "Strategischer Ausbau geplant", detail: "Investition nötig")
       ]
     ),
     PragFrage(
       id: "ip_lage",
       schrittIndex: 4,
       text: "IP- & Patentsituation (Strategos-relevant)?",
       hinweis: nil,
       module: [.strategosLink, .risiken],
       optionen: [
         .init(id: "schutz", label: "Starker Schutz", detail: "Breites Portfolio"),
         .init(id: "fto_risiko", label: "FTO-Risiken", detail: "Fremdpatente blockieren"),
         .init(id: "aufbau", label: "Portfolio im Aufbau", detail: "Neue Anmeldungen"),
         .init(id: "unklar", label: "Unklar / nicht analysiert", detail: "Strategos Patent-Schritt empfohlen")
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 5,
   titel: "WIRTSCHAFT & RESSOURCEN",
   untertitel: "Finanzielle Stabilität und operative Hebel des Unternehmens.",
   strategosBezug: "Strategos Quantifizierung · Exposure",
   fragen: [
     PragFrage(
       id: "wirtschaftslage",
       schrittIndex: 5,
       text: "Wirtschaftliche Lage des Unternehmens?",
       hinweis: nil,
       module: [.ressourcen, .uebersicht],
       optionen: [
         .init(id: "stark", label: "Stark / wachsend", detail: "Investitionsspielraum"),
         .init(id: "stabil", label: "Stabil", detail: "Planbare Entwicklung"),
         .init(id: "druck", label: "Unter Druck", detail: "Margendruck, Kostensenkung"),
         .init(id: "krise", label: "Krisenmodus", detail: "Restrukturierung / Sanierung")
       ]
     ),
     PragFrage(
       id: "ressourcen_hebel",
       schrittIndex: 5,
       text: "Stärkster unternehmerischer Hebel?",
       hinweis: nil,
       module: [.ressourcen, .influence],
       optionen: [
         .init(id: "kapital", label: "Kapital & Investitionen", detail: nil),
         .init(id: "marke", label: "Marke & Reputation", detail: nil),
         .init(id: "daten", label: "Daten & Digitalisierung", detail: nil),
         .init(id: "personal", label: "Fachkräfte & Know-how", detail: nil),
         .init(id: "vertrag", label: "Vertrags- & Rechtsstruktur", detail: nil)
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 6,
   titel: "STAKEHOLDER-NETZWERK",
   untertitel: "Verbände, Politik, Wissenschaft, Medien -- institutionelle Beziehungen.",
   strategosBezug: "Strategos Umsetzungsplan · Stakeholder-Roadmap",
   fragen: [
     PragFrage(
       id: "verbaende",
       schrittIndex: 6,
       text: "Branchenverbände & institutionelle Netzwerke?",
       hinweis: nil,
       module: [.netzwerk, .entscheidungsnetz],
       optionen: [
         .init(id: "fuehrend", label: "Führend engagiert", detail: "Gremien, Vorstände"),
         .init(id: "mitglied", label: "Mitgliedschaft", detail: "Standard-Engagement"),
         .init(id: "passiv", label: "Passiv", detail: "Kaum sichtbar"),
         .init(id: "fehlend", label: "Fehlend", detail: "Aufbau dringend empfohlen")
       ]
     ),
     PragFrage(
       id: "medien_narrativ",
       schrittIndex: 6,
       text: "Öffentliches Narrativ & Medienpräsenz?",
       hinweis: "Wahrnehmung in Politik, Wirtschaft, Wissenschaft.",
       module: [.narrativ, .influence],
       optionen: [
         .init(id: "positiv", label: "Positiv / Thought Leader", detail: nil),
         .init(id: "neutral", label: "Neutral", detail: nil),
         .init(id: "kritisch", label: "Kritisch / unter Beobachtung", detail: nil),
         .init(id: "unsichtbar", label: "Kaum sichtbar", detail: "Chancen ungenutzt")
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 7,
   titel: "RISIKEN & RESILIENZ",
   untertitel: "Bedrohungen für Marktposition, Regulatorik und Reputation.",
   strategosBezug: "Strategos Risiko-Matrix · Bußgeld-Worst-Case",
   fragen: [
     PragFrage(
       id: "hauptrisiko",
       schrittIndex: 7,
       text: "Größtes unternehmerisches Risiko?",
       hinweis: nil,
       module: [.risiken, .szenarien],
       optionen: [
         .init(id: "regulatorik", label: "Regulatorik / Gesetzesänderung", detail: nil),
         .init(id: "wettbewerb", label: "Wettbewerb / Marktanteil", detail: nil),
         .init(id: "reputation", label: "Reputation / ESG / Skandal", detail: nil),
         .init(id: "tech", label: "Technologie / Disruption", detail: nil),
         .init(id: "lieferkette", label: "Lieferkette / Geopolitik", detail: nil)
       ]
     ),
     PragFrage(
       id: "resilienz",
       schrittIndex: 7,
       text: "Resilienz des Unternehmens?",
       hinweis: nil,
       module: [.risiken, .zeitplan],
       optionen: [
         .init(id: "hoch", label: "Hoch", detail: "Diversifiziert, robust"),
         .init(id: "mittel", label: "Mittel", detail: "Einzelne Schwachstellen"),
         .init(id: "niedrig", label: "Niedrig", detail: "Klumpenrisiken"),
         .init(id: "aufbau", label: "Resilienz im Aufbau", detail: "Maßnahmen laufen")
       ]
     )
   ]
 ),
 PragFragebogenSchritt(
   index: 8,
   titel: "STRATEGISCHE ZIELE",
   untertitel: "Wo soll das Unternehmen in Politik, Wirtschaft und Wissenschaft stehen?",
   strategosBezug: "Strategos Handlungsoptionen -> Opportunisma Umsetzung",
   fragen: [
     PragFrage(
       id: "ziel_politik",
       schrittIndex: 8,
       text: "Politisches Ziel des Unternehmens?",
       hinweis: nil,
       module: [.narrativ, .netzwerk, .zeitplan],
       optionen: [
         .init(id: "gestaltung", label: "Regulierung mitgestalten", detail: nil),
         .init(id: "schutz", label: "Bestehende Rahmenbedingungen sichern", detail: nil),
         .init(id: "expansion", label: "Politische Öffnung neuer Märkte", detail: nil),
         .init(id: "abwehr", label: "Abwehr ungünstiger Gesetze", detail: nil)
       ]
     ),
     PragFrage(
       id: "ziel_wirtschaft",
       schrittIndex: 8,
       text: "Wirtschaftliches Ziel (12 Monate)?",
       hinweis: nil,
       module: [.uebersicht, .szenarien, .machtStrategie],
       optionen: [
         .init(id: "wachstum", label: "Marktwachstum / Umsatz", detail: nil),
         .init(id: "marge", label: "Margen & Effizienz", detail: nil),
         .init(id: "marktanteil", label: "Marktanteil gewinnen", detail: nil),
         .init(id: "divers", label: "Diversifikation / neue Segmente", detail: nil)
       ]
     ),
     PragFrage(
       id: "ziel_wissenschaft",
       schrittIndex: 8,
       text: "Wissenschaftliches / Innovationsziel?",
       hinweis: nil,
       module: [.hegemonogramm, .strategosLink],
       optionen: [
         .init(id: "standard", label: "Standardsetzer werden", detail: "Normen, Patente"),
         .init(id: "koop", label: "Forschungskooperationen ausbauen", detail: nil),
         .init(id: "transfer", label: "Technology Transfer stärken", detail: nil),
         .init(id: "halten", label: "Position halten", detail: "Defensiv IP")
       ]
     ),
     PragFrage(
       id: "horizont",
       schrittIndex: 8,
       text: "Planungshorizont für die Gesamtstrategie?",
       hinweis: nil,
       module: [.zeitplan, .machtStrategie],
       optionen: [
         .init(id: "3m", label: "3 Monate (taktisch)", detail: nil),
         .init(id: "12m", label: "12 Monate", detail: nil),
         .init(id: "3j", label: "3 Jahre", detail: nil),
         .init(id: "5j", label: "5+ Jahre (strukturell)", detail: nil)
       ]
     )
   ]
 )
]

static func alleFragen(fuer szenario: StrategosScenario? = nil) -> [PragFrage] {
 schritte(fuer: szenario).flatMap(\.fragen)
}

static func moduleFuerAntworten(_ antworten: [String: PragFrageAntwort], szenario: StrategosScenario? = nil) -> [PragModulQuelle] {
 var map: [OpportunismaTab: Set<String>] = [:]
 for frage in alleFragen(fuer: szenario) {
   guard let a = antworten[frage.id], a.istAusgefuellt else { continue }
   let label = a.zusammenfassung(optionen: frage.optionen)
   for mod in frage.module {
     map[mod, default: []].insert("\(frage.text.prefix(40))… -> \(label)")
   }
 }
 return OpportunismaTab.legacyCases.map { tab in
   let q = map[tab].map(Array.init) ?? []
   return PragModulQuelle(modul: tab, quellen: q, aktiv: !q.isEmpty || tab == .fragebogen)
 }
}
}

