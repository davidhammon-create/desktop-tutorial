import Foundation
import SwiftUI

// MARK: - Navigation

enum OpportunismaTab: String, CaseIterable, Identifiable {
case briefing
case fragebogen
case strategosLink
case uebersicht
case hegemonogramm
case machtStrategie
case entscheidungsnetz
case szenarien
case risiken
case gegneranalyse
case netzwerk
case ressourcen
case narrativ
case influence
case zeitplan
case zielpersonen
case dossier
case actionBoard
case chancen
case feed
case warRoom
case weeklyBrief
case exportStudio
case journey
case playbooks

var id: String { rawValue }

/// Tabs für Strategos-Einbettung (ohne Pro-only Module).
static var legacyCases: [OpportunismaTab] {
  allCases.filter {
    switch $0 {
    case .briefing, .actionBoard, .chancen, .feed, .warRoom, .weeklyBrief, .exportStudio, .journey, .playbooks:
      return false
    default: return true
    }
  }
}

static var proOnlyCases: [OpportunismaTab] {
  [.briefing, .journey, .playbooks, .actionBoard, .chancen, .feed, .warRoom, .weeklyBrief, .exportStudio]
}

var titel: String {
  switch self {
  case .briefing: return "EXECUTIVE BRIEFING"
  case .fragebogen: return "LAGEFRAGEBOGEN"
  case .strategosLink: return "STRATEGOS-LINK"
  case .uebersicht: return "UNTERNEHMENSLAGE"
  case .hegemonogramm: return "POSITIONSRADAR"
  case .machtStrategie: return "STRATEGIE-BAUM"
  case .entscheidungsnetz: return "ENTSCHEIDUNGSNETZ"
  case .szenarien: return "SZENARIEN"
  case .risiken: return "RISIKEN & RESILIENZ"
  case .gegneranalyse: return "WETTBEWERB"
  case .netzwerk: return "STAKEHOLDER-NETZ"
  case .ressourcen: return "RESSOURCEN"
  case .narrativ: return "POLITIK & NARRATIV"
  case .influence: return "EINFLUSSKANÄLE"
  case .zeitplan: return "UMSETZUNGSPLAN"
  case .zielpersonen: return "AKTEURE"
  case .dossier: return "UNTERNEHMENS-DOSSIER"
  case .actionBoard: return "ACTION BOARD"
  case .chancen: return "CHANCENRADAR"
  case .feed: return "CI FEED"
  case .warRoom: return "WAR ROOM"
  case .weeklyBrief: return "WEEKLY BRIEF"
  case .exportStudio: return "EXPORT STUDIO"
  case .journey: return "JOURNEY"
  case .playbooks: return "PLAYBOOKS"
  }
}

var proTitel: String {
  switch self {
  case .briefing: return "Executive Briefing"
  case .fragebogen: return "Lagefragebogen"
  case .strategosLink: return "Strategos-Anbindung"
  case .uebersicht: return "Unternehmenslage"
  case .hegemonogramm: return "Positionsradar"
  case .machtStrategie: return "Strategie-Baum"
  case .entscheidungsnetz: return "Entscheidungsnetz"
  case .szenarien: return "Szenarien"
  case .risiken: return "Risiken"
  case .gegneranalyse: return "Wettbewerb"
  case .netzwerk: return "Stakeholder"
  case .ressourcen: return "Ressourcen"
  case .narrativ: return "Narrativ"
  case .influence: return "Einflusskanäle"
  case .zeitplan: return "Umsetzungsplan"
  case .zielpersonen: return "Akteure"
  case .dossier: return "Dossier"
  case .actionBoard: return "Action Board"
 case .chancen: return "Chancenradar"
 case .feed: return "CI-Feed"
 case .warRoom: return "War Room"
 case .weeklyBrief: return "Weekly Brief"
 case .exportStudio: return "Export Studio"
 case .journey: return "Setup-Journey"
 case .playbooks: return "Sektor-Playbooks"
 }
}

var proBeschreibung: String {
 switch self {
 case .briefing: return "Board-fähige Lage -- CI als Liefergegenstand."
 case .fragebogen: return "Strukturierte Lageaufnahme für Module und Prognosen."
 case .strategosLink: return "Vertrags-/Unternehmenskontext aus Strategos."
 case .uebersicht: return "Command Center mit Kennzahlen und Kernmodulen."
 case .hegemonogramm: return "Ist/Soll-Gap über Politik, Markt, Wissenschaft."
 case .machtStrategie: return "Handlungspfade mit Wirksamkeit und Risiko."
 case .entscheidungsnetz: return "Optionen und Abhängigkeiten."
 case .szenarien: return "Pfade vergleichen und priorisieren."
 case .risiken: return "Impact x Wahrscheinlichkeit."
 case .gegneranalyse: return "Wettbewerber und Gegenbewegung."
 case .netzwerk: return "Stakeholder-Karte."
 case .ressourcen: return "Kapazitäten und Engpässe."
 case .narrativ: return "Wahrnehmung in Politik und Öffentlichkeit."
 case .influence: return "Kanäle, die die Lage bewegen."
 case .zeitplan: return "Meilensteine und Druck."
 case .zielpersonen: return "Schlüsselakteure."
 case .dossier: return "Gesamtsicht für Mandant und Board."
 case .actionBoard: return "Kanban -- aus CI wird Ausführung."
 case .chancen: return "Sector White-Space priorisieren."
 case .feed: return "Was sich seit gestern bewegt."
 case .warRoom: return "Lage · Gegner · Zug in einer Decision Surface."
 case .weeklyBrief: return "Wöchentlicher CI-Brief für Partnerschaft / Leitung."
 case .exportStudio: return "Board Pack, One-Pager, Mandatsmemo -- ein Klick."
 case .journey: return "Geführter Einstieg: Setup in 5 Schritten bis Entscheidungsreife."
 case .playbooks: return "Sektor-Vorlagen laden Desk, Actions und Narrative in einem Schritt."
 }
}

var symbol: String {
 switch self {
 case .briefing: return "doc.richtext"
 case .fragebogen: return "list.bullet.clipboard"
 case .strategosLink: return "link.circle"
 case .uebersicht: return "square.grid.2x2"
 case .hegemonogramm: return "hexagon"
 case .machtStrategie: return "arrow.triangle.branch"
 case .entscheidungsnetz: return "point.3.connected.trianglepath.dotted"
 case .szenarien: return "chart.line.uptrend.xyaxis"
 case .risiken: return "square.grid.3x3"
 case .gegneranalyse: return "person.crop.circle.badge.exclamationmark"
 case .netzwerk: return "circle.grid.cross"
 case .ressourcen: return "cube.box"
 case .narrativ: return "megaphone"
 case .influence: return "brain.head.profile"
 case .zeitplan: return "calendar"
 case .zielpersonen: return "person.2"
 case .dossier: return "doc.text"
 case .actionBoard: return "rectangle.3.group"
 case .chancen: return "scope"
 case .feed: return "dot.radiowaves.up.forward"
 case .warRoom: return "shield.lefthalf.filled"
 case .weeklyBrief: return "newspaper.fill"
 case .exportStudio: return "square.and.arrow.up.on.square"
 case .journey: return "map.fill"
 case .playbooks: return "book.closed.fill"
 }
}
}

// MARK: - Strategie-Baum (Machtportal)

enum PragNodeTyp: String {
case position, move, outcome, goal

var label: String {
 switch self {
 case .position: return "Ausgangslage"
 case .move: return "Handlung"
 case .outcome: return "Mögliche Folge"
 case .goal: return "Ziel"
 }
}
}

struct PragScores: Equatable {
var efficacy: Int
var risk: Int
var reversibility: Int
var harm: Int
}

struct PragTreeNode: Identifiable {
let id: String
var typ: PragNodeTyp
var label: String
var detail: String
var scores: PragScores?
var children: [PragTreeNode]
}

struct PragSzenario: Identifiable {
let id: String
var label: String
var situation: String
var ziel: String
var akteure: [String]
var root: PragTreeNode
}

// MARK: - Dashboard-Daten

struct PragBarItem: Identifiable {
let id = UUID()
var name: String
var wert: Int
}

struct PragZielZeile: Identifiable {
let id = UUID()
var ziel: String
var status: String
var fortschritt: Int
}

struct PragGegnerZeile: Identifiable {
let id = UUID()
var name: String
var einfluss: String
var bedrohung: String
var kontrolle: String
}

struct PragSzenarioZeile: Identifiable {
let id = UUID()
var name: String
var wahrscheinlichkeit: Int
var kontrolle: Int
var ergebnis: String
}

struct PragNetzKnoten: Identifiable {
let id = UUID()
var label: String
var typ: String // kontrolliert, verbündet, neutral, feindlich
var x: CGFloat
var y: CGFloat
}

struct PragNetzKante: Identifiable {
let id = UUID()
var von: String
var zu: String
}

struct PragMeilenstein: Identifiable {
let id = UUID()
var titel: String
var start: Int
var dauer: Int
}

// MARK: - Pro Intelligence Models

enum OpportunismaActionStatus: String, Codable, CaseIterable {
case offen, laeuft, erledigt
var label: String {
 switch self {
 case .offen: return "Offen"
 case .laeuft: return "In Arbeit"
 case .erledigt: return "Erledigt"
 }
}
}

struct OpportunismaActionItem: Identifiable, Codable {
let id: UUID
var titel: String
var detail: String
var status: OpportunismaActionStatus
var prio: OpportunismaActionPrio
var tabRaw: String
var owner: String
var dueLabel: String

var tab: OpportunismaTab {
 get { OpportunismaTab(rawValue: tabRaw) ?? .actionBoard }
 set { tabRaw = newValue.rawValue }
}

init(id: UUID = UUID(), titel: String, detail: String, status: OpportunismaActionStatus, prio: OpportunismaActionPrio, tab: OpportunismaTab, owner: String = "Counsel", dueLabel: String = "Diese Woche") {
 self.id = id
 self.titel = titel
 self.detail = detail
 self.status = status
 self.prio = prio
 self.tabRaw = tab.rawValue
 self.owner = owner
 self.dueLabel = dueLabel
}
}

enum OpportunismaActionPrio: String, CaseIterable, Codable {
case hoch, mittel, niedrig
var label: String {
 switch self {
 case .hoch: return "Hoch"
 case .mittel: return "Mittel"
 case .niedrig: return "Niedrig"
 }
}
var color: Color {
 switch self {
 case .hoch: return OpportunismaPro.danger
 case .mittel: return OpportunismaPro.warn
 case .niedrig: return OpportunismaPro.textFaint
 }
}
}

struct OpportunismaChance: Identifiable {
let id: UUID
var sektor: String
var titel: String
var begruendung: String
var score: Int
var effort: String

init(id: UUID = UUID(), sektor: String, titel: String, begruendung: String, score: Int, effort: String) {
 self.id = id
 self.sektor = sektor
 self.titel = titel
 self.begruendung = begruendung
 self.score = score
 self.effort = effort
}
}

struct OpportunismaFeedEvent: Identifiable {
let id: UUID
var zeit: String
var quelle: String
var titel: String
var wirkung: String
var tab: OpportunismaTab?

init(id: UUID = UUID(), zeit: String, quelle: String, titel: String, wirkung: String, tab: OpportunismaTab? = nil) {
 self.id = id
 self.zeit = zeit
 self.quelle = quelle
 self.titel = titel
 self.wirkung = wirkung
 self.tab = tab
}
}

struct OpportunismaKontakt: Identifiable, Codable, Equatable {
let id: UUID
var name: String
var rolle: String
var organisation: String
var stance: String
var prioritaet: Int
var naechsterZug: String
var notiz: String

init(id: UUID = UUID(), name: String, rolle: String, organisation: String, stance: String, prioritaet: Int, naechsterZug: String, notiz: String = "") {
 self.id = id
 self.name = name
 self.rolle = rolle
 self.organisation = organisation
 self.stance = stance
 self.prioritaet = prioritaet
 self.naechsterZug = naechsterZug
 self.notiz = notiz
}
}

enum OpportunismaExportPack: String, CaseIterable, Identifiable {
case board, weekly, counsel, krisen, beirat, mandatsmemo
var id: String { rawValue }
var titel: String {
 switch self {
 case .board: return "Board Pack"
 case .weekly: return "Weekly Brief"
 case .counsel: return "Counsel Memo"
 case .krisen: return "Krisenbrief"
 case .beirat: return "Beirat 1-Pager"
 case .mandatsmemo: return "Mandatsmemo"
 }
}
var detail: String {
 switch self {
 case .board: return "Kennzahlen · Lage · Ziele · Chancen · Actions"
 case .weekly: return "Wöchentlicher Partner-Brief"
 case .counsel: return "Rechtlich-strategische Kurzlage"
 case .krisen: return "Druck · Gegner · Sofortzüge"
 case .beirat: return "Eine Seite für Beirat / Aufsicht"
 case .mandatsmemo: return "Kurzmemo Lage + nächster Zug"
 }
}
var symbol: String {
 switch self {
 case .board: return "doc.richtext"
 case .weekly: return "newspaper.fill"
 case .counsel: return "briefcase.fill"
 case .krisen: return "exclamationmark.shield.fill"
 case .beirat: return "person.3.sequence.fill"
 case .mandatsmemo: return "envelope.fill"
 }
}
}

struct OpportunismaPlaybook: Identifiable {
let id: String
var titel: String
var sektor: String
var detail: String
var symbol: String
var seedsituation: String
var seedZiel: String
}

enum OpportunismaProDemo {
static let actions: [OpportunismaActionItem] = [
 .init(titel: "Lagefragebogen abschließen", detail: "Graphen und Prognosen härten.", status: .offen, prio: .hoch, tab: .fragebogen),
 .init(titel: "Positionsradar priorisieren", detail: "Ist/Soll-Lücke schließen.", status: .offen, prio: .hoch, tab: .hegemonogramm),
 .init(titel: "Strategie-Zug wählen", detail: "Wirksamkeit vs. Risiko.", status: .laeuft, prio: .hoch, tab: .machtStrategie),
 .init(titel: "Board Pack an Leitung", detail: "CI als Liefergegenstand.", status: .offen, prio: .mittel, tab: .briefing)
]

static let kontakte: [OpportunismaKontakt] = [
 .init(name: "Dr. Elena Vogt", rolle: "Verbandsvorsitz", organisation: "Branchenverband DACH", stance: "Verbündet", prioritaet: 92, naechsterZug: "Briefing zu RegTech-Position", notiz: "Key influencer EU"),
 .init(name: "Markus Rehn", rolle: "CFO", organisation: "Unternehmen", stance: "Intern", prioritaet: 88, naechsterZug: "Budget für Lobby-Linie"),
 .init(name: "Prof. Iris Lange", rolle: "Forschungspartnerin", organisation: "TU München", stance: "Neutral->Verbündet", prioritaet: 81, naechsterZug: "IP-Kooperationsmemo", notiz: "F&E-Allianz"),
 .init(name: "Clara Stein", rolle: "Regulatory Affairs", organisation: "EU-Peer", stance: "Wettbewerb", prioritaet: 74, naechsterZug: "Peer-Messaging beobachten"),
 .init(name: "Tom Keller", rolle: "Politikberater", organisation: "Public Affairs Desk", stance: "Verbündet", prioritaet: 79, naechsterZug: "Hearing-Vorbereitung", notiz: "Q3")
]

static let playbooks: [OpportunismaPlaybook] = [
 .init(id: "regtech", titel: "RegTech / Compliance", sektor: "Regulierung", detail: "Gestaltungsmacht bei EU-Regeln, Compliance als Differenzierung.", symbol: "building.columns.fill", seedsituation: "RegTech-Druck steigt: neue EU-Pflichten, Peer-Messaging aggressiv, Compliance-Budget unter Beobachtung.", seedZiel: "Regulatorische Gestaltungsmacht sichern und Compliance als Marktvorteil positionieren."),
 .init(id: "health", titel: "HealthTech / Life Science", sektor: "Gesundheit", detail: "Zulassung, Wissenschaftsallianzen, Public Trust.", symbol: "cross.case.fill", seedsituation: "HealthTech-Unternehmen mit Zulassungsdruck, Wissenschaftspartner und öffentlicher Wahrnehmung als Engpass.", seedZiel: "Zulassungspfad absichern und wissenschaftliche Glaubwürdigkeit ausbauen."),
 .init(id: "litigation", titel: "Litigation / Dispute", sektor: "Streit", detail: "Verfahrenslage, Gegnerdruck, Settlement-Hebel.", symbol: "hammer.fill", seedsituation: "Streitiges Verfahren mit hohem Gegnerdruck; Settlement-Fenster und Beweislast im Fokus.", seedZiel: "Verhandlungsposition härten und verfahrenssichere Züge priorisieren."),
 .init(id: "public", titel: "Public Affairs", sektor: "Politik", detail: "Narrativ, Verbände, Hearing-Ready Briefs.", symbol: "megaphone.fill", seedsituation: "Public-Affairs-Lage: Verbandsarbeit, Hearing-Kalender und Narrativ-Lücken gegenüber Peers.", seedZiel: "Politische Sichtbarkeit und Verbandshebel in den nächsten 90 Tagen maximieren."),
 .init(id: "patent", titel: "Patent / IP Enforcement", sektor: "IP", detail: "Anspruchssatz, Forum, Lizenz vs. Klage.", symbol: "lightbulb.fill", seedsituation: "Patentverletzung oder Lizenzdruck: Merkmalsanalyse, Stand der Technik und Forumwahl offen.", seedZiel: "Durchsetzungs- oder Lizenzpfad mit maximalem Hebel wählen."),
 .init(id: "straf", titel: "Strafverteidigung", sektor: "Straf", detail: "Aktenlage, Haft, Einlassungsstrategie.", symbol: "hand.raised.fill", seedsituation: "Strafverfahren mit Akteneinsicht, möglichen Haftfragen und öffentlichem Druck.", seedZiel: "Verteidigungsstrategie absichern und kritische Fristen beherrschen."),
 .init(id: "syndikus", titel: "Syndikus / Inhouse Board", sektor: "Inhouse", detail: "Governance, Risiko, External Counsel Brief.", symbol: "briefcase.fill", seedsituation: "Inhouse-Legal muss Board-Risiken steuern und External Counsel effizient briefen.", seedZiel: "Freigabepfad und Risikoregister in 14 Tagen belastbar machen."),
 .init(id: "ma", titel: "M&A / Transaktion", sektor: "Deal", detail: "DD, SPA-Issues, Closing Conditions.", symbol: "arrow.left.arrow.right", seedsituation: "Transaktion mit DD-Lücken, SPA-Verhandlung und Closing-Druck.", seedZiel: "Issues-List priorisieren und Closing-Risiken reduzieren.")
]

static let chancen: [OpportunismaChance] = [
 .init(sektor: "RegTech / Compliance", titel: "White-Space bei Mittelstand-Cloud", begruendung: "Wettbewerber adressieren Enterprise -- Mittelstand unterversorgt.", score: 82, effort: "Mittel"),
 .init(sektor: "HealthTech", titel: "Kooperationsfenster mit Verband", begruendung: "Konsultationsphase offen -- Sichtbarkeit jetzt skalierbar.", score: 74, effort: "Niedrig"),
 .init(sektor: "Public Affairs", titel: "Narrativ-Shift ESG -> Operative Resilienz", begruendung: "Peer-Messaging dreht; eigene Seite veraltet.", score: 68, effort: "Niedrig"),
 .init(sektor: "Litigation / ADR", titel: "Vergleichspfad vor Eskalation", begruendung: "Gegner-Kostenkurve steigt schneller als eigene.", score: 71, effort: "Hoch")
]

static let feed: [OpportunismaFeedEvent] = [
 .init(zeit: "Heute", quelle: "Lage", titel: "Positionsindex bei 72%", wirkung: "Stabil, aber Fragebogen offen", tab: .uebersicht),
 .init(zeit: "Heute", quelle: "Wettbewerb", titel: "Marktführer Branche A -- Druck steigt", wirkung: "Gegenbewegung prüfen", tab: .gegneranalyse),
 .init(zeit: "Gestern", quelle: "Risiko", titel: "Heatmap-Peak 6/6 aktiv", wirkung: "Mitigation priorisieren", tab: .risiken),
 .init(zeit: "Gestern", quelle: "Strategos", titel: "Vertragsanalyse TechVision verknüpft", wirkung: "Kontext übernommen", tab: .strategosLink),
 .init(zeit: "Diese Woche", quelle: "Sektor", titel: "4/6 Peers mit Resilienz-Messaging", wirkung: "Narrativ nachziehen", tab: .narrativ)
]
}

// MARK: - ViewModel

@Observable
final class OpportunismaViewModel {
var selectedTab: OpportunismaTab = .fragebogen
var situationText: String = OpportunismaDemo.defaultSituation
var zielText: String = OpportunismaDemo.defaultZiel
var szenarioKey: String = "unternehmen"
var schadensSchwelle: Double = 70
var risikoOverlay: Bool = false
var selectedNodeId: String = "uroot"
var kiLaeuft = false
var kiFehler: String?
var kiTipp: String?
var kiAnalyse: String?

// MARK: Fragebogen
var fragebogenSchrittIndex: Int = 0
var fragebogenAntworten: [String: PragFrageAntwort] = [:]
var fragebogenPhase: PragFragebogenPhase = .fragen
var fragebogenLaeuft = false
var fragebogenZusammenfassung: String?
var kausalitaeten: [PragKausalitaet] = []
var prognosen: [PragPrognoseZeile] = []
var fragebogenAbgeschlossen = false

// MARK: Pro Intelligence Layer (Standalone)
var actionItems: [OpportunismaActionItem] = OpportunismaProDemo.actions
var chancen: [OpportunismaChance] = OpportunismaProDemo.chancen
var feedEvents: [OpportunismaFeedEvent] = OpportunismaProDemo.feed
var kontakte: [OpportunismaKontakt] = OpportunismaProDemo.kontakte
var aktivesPlaybookId: String?
var pinnedTabIds: [String] = UserDefaults.standard.stringArray(forKey: "opportunisma_pro_pins") ?? ["briefing", "actionBoard", "machtStrategie"]

init() {
 ladeProSession()
}

func togglePin(_ tab: OpportunismaTab) {
 if let i = pinnedTabIds.firstIndex(of: tab.rawValue) {
   pinnedTabIds.remove(at: i)
 } else {
   pinnedTabIds.insert(tab.rawValue, at: 0)
   if pinnedTabIds.count > 5 { pinnedTabIds = Array(pinnedTabIds.prefix(5)) }
 }
 UserDefaults.standard.set(pinnedTabIds, forKey: "opportunisma_pro_pins")
}

func isPinned(_ tab: OpportunismaTab) -> Bool {
 pinnedTabIds.contains(tab.rawValue)
}

var offenActions: Int { actionItems.filter { $0.status != .erledigt }.count }

var chanceScore: Int {
 let sum = chancen.reduce(0) { $0 + $1.score }
 return chancen.isEmpty ? 0 : min(100, sum / max(1, chancen.count))
}

/// 0…5 Setup-Schritte zur Entscheidungsreife (Pro Journey).
var journeySchritte: [(titel: String, ok: Bool, tab: OpportunismaTab)] {
 [
   ("Lagefragebogen", fragebogenAbgeschlossen, .fragebogen),
   ("Strategos anbinden", verknuepftesStrategos != nil, .strategosLink),
   ("Position verstehen", machtIndex > 0, .hegemonogramm),
   ("Strategie-Zug wählen", !flacheKnoten.isEmpty, .machtStrategie),
   ("Action Board aktiv", offenActions >= 0 && !actionItems.isEmpty, .actionBoard)
 ]
}

var journeyFortschritt: Double {
 let ok = journeySchritte.filter(\.ok).count
 return Double(ok) / Double(max(1, journeySchritte.count))
}

var entscheidungsreif: Bool { journeyFortschritt >= 0.8 }

var groessteHegemonieLuecke: (label: String, gap: Double)? {
 hegemonogramm
   .map { (label: $0.label, gap: $0.soll - $0.ist) }
   .max(by: { $0.gap < $1.gap })
}

var engpassRessource: PragBarItem? {
 ressourcen.min(by: { $0.wert < $1.wert })
}

func speichereProSession() {
 let ud = UserDefaults.standard
 ud.set(situationText, forKey: "opportunisma_pro_situation")
 ud.set(zielText, forKey: "opportunisma_pro_ziel")
 ud.set(aktivesPlaybookId, forKey: "opportunisma_pro_playbook")
 if let data = try? JSONEncoder().encode(actionItems) {
   ud.set(data, forKey: "opportunisma_pro_actions")
 }
 if let data = try? JSONEncoder().encode(kontakte) {
   ud.set(data, forKey: "opportunisma_pro_kontakte")
 }
}

func ladeProSession() {
 let ud = UserDefaults.standard
 if let s = ud.string(forKey: "opportunisma_pro_situation"), !s.isEmpty { situationText = s }
 if let z = ud.string(forKey: "opportunisma_pro_ziel"), !z.isEmpty { zielText = z }
 aktivesPlaybookId = ud.string(forKey: "opportunisma_pro_playbook")
 if let data = ud.data(forKey: "opportunisma_pro_actions"),
  let decoded = try? JSONDecoder().decode([OpportunismaActionItem].self, from: data),
  !decoded.isEmpty {
   actionItems = decoded
 }
 if let data = ud.data(forKey: "opportunisma_pro_kontakte"),
  let decoded = try? JSONDecoder().decode([OpportunismaKontakt].self, from: data),
  !decoded.isEmpty {
   kontakte = decoded
 }
}

func setzeActionStatus(_ id: UUID, _ status: OpportunismaActionStatus) {
 guard let i = actionItems.firstIndex(where: { $0.id == id }) else { return }
 actionItems[i].status = status
 speichereProSession()
}

@MainActor
func wendePlaybookAn(_ book: OpportunismaPlaybook) {
 aktivesPlaybookId = book.id
 situationText = book.seedsituation
 zielText = book.seedZiel
 aktualisiereAusgangUndZiel()
 feedEvents.insert(
   .init(zeit: "Jetzt", quelle: "Playbook", titel: "\(book.titel) geladen", wirkung: "Lage & Ziel gesetzt", tab: .playbooks),
   at: 0
 )
 actionItems.insert(
   .init(titel: "Playbook „\(book.titel)" ausführen", detail: book.detail, status: .offen, prio: .hoch, tab: .warRoom, owner: "Partner", dueLabel: "Sofort"),
   at: 0
 )
 actionItems.insert(
   .init(titel: "Sektor-Narrativ schärfen", detail: book.sektor, status: .offen, prio: .mittel, tab: .narrativ),
   at: 1
 )
 chancen.insert(
   .init(sektor: book.sektor, titel: "Playbook-Chance · \(book.titel)", begruendung: book.detail, score: 80, effort: "Mittel"),
   at: 0
 )
 speichereProSession()
 selectedTab = .warRoom
}

func exportMarkdown(fuer pack: OpportunismaExportPack) -> String {
 let actions = actionItems.filter { $0.status != .erledigt }.prefix(6).map { "- [\($0.prio.label)] \($0.titel) · \($0.owner) · \($0.dueLabel)" }.joined(separator: "\n")
 let topChance = chancen.sorted { $0.score > $1.score }.prefix(3).map { "- \($0.score) · \($0.titel) (\($0.sektor))" }.joined(separator: "\n")
 let gegner = self.gegner.prefix(4).map { "- \($0.name): \($0.bedrohung)" }.joined(separator: "\n")
 let ziele = strategischeZiele.prefix(5).map { "- \($0.ziel) (\($0.status), \($0.fortschritt)%)" }.joined(separator: "\n")
 let gaps = hegemonogramm.sorted { ($0.soll - $0.ist) > ($1.soll - $1.ist) }.prefix(3)
   .map { "- \($0.label): Ist \(Int($0.ist)) -> Soll \(Int($0.soll)) (Gap \(Int($0.soll - $0.ist)))" }
   .joined(separator: "\n")
 let kontakteMD = kontakte.sorted { $0.prioritaet > $1.prioritaet }.prefix(4)
   .map { "- \($0.name) · \($0.rolle) · Prio \($0.prioritaet) · \($0.naechsterZug)" }
   .joined(separator: "\n")
 let prognoseMD = prognosen.prefix(3).map { "- \($0.option) -> \($0.fuehrt_zu) (P=\($0.wahrscheinlichkeit)%)" }.joined(separator: "\n")

 switch pack {
 case .weekly:
   return weeklyBriefMarkdown()
 case .board:
   return """
   # Opportunisma Board Pack
   Generiert: \(ISO8601DateFormatter().string(from: Date()))

   ## Kennzahlen
   - Positionsindex: **\(machtIndex)%** · \(dominanzLabel)
   - Chance Ø: **\(chanceScore)** · Offene Züge: **\(offenActions)**
   - Setup: **\(Int(journeyFortschritt * 100))%**

   ## Ausgangslage
   \(situationText.isEmpty ? "--" : situationText)

   ## Ziel
   \(zielText.isEmpty ? "--" : zielText)

   ## Strategische Ziele
   \(ziele.isEmpty ? "- --" : ziele)

   ## Positions-Lücken
   \(gaps.isEmpty ? "- --" : gaps)

   ## Wettbewerb
   \(gegner.isEmpty ? "- --" : gegner)

   ## Chancen
   \(topChance.isEmpty ? "- --" : topChance)

   ## Action Board
   \(actions.isEmpty ? "- --" : actions)

   ## Key Contacts
   \(kontakteMD.isEmpty ? "- --" : kontakteMD)

   ---
   FenlynineOS Legal Suite · Opportunisma CI Strategy Desk
   """
 case .counsel:
   return """
   # Counsel Memo -- Opportunisma
   Position \(machtIndex)% · \(offenActions) offene Züge

   ## Lage
   \(situationText)

   ## Ziel
   \(zielText)

   ## Rechtlich-strategische Empfehlung
   \(entscheidungsreif ? "Entscheidungsreif -- War Room / Board Pack freigeben." : "Setup schließen, dann Strategie-Zug wählen.")

   ## Prognosen
   \(prognoseMD.isEmpty ? "- (Fragebogen für Prognosen abschließen)" : prognoseMD)

   ## Nächste Züge
   \(actions.isEmpty ? "- --" : actions)

   ## KI
   \(kiTipp ?? kiAnalyse ?? "--")
   """
 case .krisen:
   return """
   # Krisenbrief -- Opportunisma
   Sofortlage · \(ISO8601DateFormatter().string(from: Date()).prefix(10))

   ## Druck
   Position **\(machtIndex)%** · Risiko-Peak **\(risikoMatrix.flatMap { $0 }.max() ?? 0)**

   ## Gegner
   \(gegner.isEmpty ? "- --" : gegner)

   ## Sofortzüge
   \(actions.isEmpty ? "- --" : actions)

   ## Stakeholder (Priorität)
   \(kontakteMD.isEmpty ? "- --" : kontakteMD)
   """
 case .beirat:
   return """
   # Beirat 1-Pager -- Opportunisma
   **\(machtIndex)%** Position · **\(chanceScore)** Chance · **\(offenActions)** Züge

   Lage: \(situationText)
   Ziel: \(zielText)

   Lücken:
   \(gaps.isEmpty ? "- --" : gaps)

   Empfehlung: \(entscheidungsreif ? "Freigabe der nächsten Züge." : "Setup auf Entscheidungsreife bringen.")
   """
 case .mandatsmemo:
   let top = actionItems.first { $0.status != .erledigt }
   return """
   # Mandatsmemo -- Opportunisma
   Position: \(machtIndex)%
   Lage: \(situationText)
   Ziel: \(zielText)
   Nächster Zug: \(top?.titel ?? "--")
   Owner: \(top?.owner ?? "--") · \(top?.dueLabel ?? "--")
   """
 }
}

func weeklyBriefMarkdown() -> String {
 let actions = actionItems.filter { $0.status != .erledigt }.prefix(6).map { "- [\($0.prio.label)] \($0.titel)" }.joined(separator: "\n")
 let topChance = chancen.sorted { $0.score > $1.score }.prefix(3).map { "- \($0.score) · \($0.titel) (\($0.sektor))" }.joined(separator: "\n")
 let feed = feedEvents.prefix(5).map { "- \($0.zeit): \($0.titel)" }.joined(separator: "\n")
 return """
 # Opportunisma Weekly Brief
 Woche: \(ISO8601DateFormatter().string(from: Date()).prefix(10))

 ## Headline
 Position **\(machtIndex)%** · Chance Ø **\(chanceScore)** · \(offenActions) offene Züge · Setup \(Int(journeyFortschritt * 100))%

 ## Lage
 \(situationText.isEmpty ? "--" : situationText)

 ## Ziel
 \(zielText.isEmpty ? "--" : zielText)

 ## Top-Chancen
 \(topChance.isEmpty ? "- --" : topChance)

 ## Diese Woche ausführen
 \(actions.isEmpty ? "- --" : actions)

 ## CI-Signale
 \(feed.isEmpty ? "- --" : feed)

 ## Empfehlung an die Leitung
 \(entscheidungsreif ? "Entscheidungsreif -- War Room oder Board Pack freigeben." : "Setup schließen (Fragebogen / Strategos), dann Action Board priorisieren.")

 ---
 FenlynineOS Legal Suite · Opportunisma CI Strategy Desk
 """
}

func regeneriereActionBoardAusLage() {
 var neu: [OpportunismaActionItem] = []
 if !fragebogenAbgeschlossen {
   neu.append(.init(titel: "Lagefragebogen abschließen", detail: "Ohne strukturierte Antworten bleiben Graphen weich.", status: .offen, prio: .hoch, tab: .fragebogen))
 }
 if verknuepftesStrategos == nil {
   neu.append(.init(titel: "Strategos anbinden", detail: "Vertrags-/Unternehmenskontext importieren.", status: .offen, prio: .mittel, tab: .strategosLink))
 }
 neu.append(.init(titel: "Positionsradar priorisieren", detail: "Größte Ist/Soll-Lücke schließen.", status: .offen, prio: .hoch, tab: .hegemonogramm))
 neu.append(.init(titel: "Nächsten Strategie-Zug wählen", detail: "Wirksamkeit vs. Risiko im Baum.", status: .offen, prio: .hoch, tab: .machtStrategie))
 neu.append(.init(titel: "Board Pack für Leitung", detail: "CI als Liefergegenstand exportieren.", status: .offen, prio: .mittel, tab: .briefing))
 neu.append(.init(titel: "Risiko-Heatmap reviewen", detail: "Kritische Felder mitigieren.", status: .offen, prio: .mittel, tab: .risiken))
 // Preserve done items by title match
 for item in actionItems where item.status == .erledigt {
   if let j = neu.firstIndex(where: { $0.titel == item.titel }) {
     neu[j].status = .erledigt
   }
 }
 actionItems = neu
 speichereProSession()
}

// MARK: Strategos-Erweiterung
var strategosSzenarien: [StrategosScenario] = []
var verknuepftesStrategosId: String?
var modulQuellen: [PragModulQuelle] = []

var verknuepftesStrategos: StrategosScenario? {
 guard let id = verknuepftesStrategosId else { return strategosSzenarien.first }
 return strategosSzenarien.first { $0.id == id }
}

var verknuepftesStrategosName: String? { verknuepftesStrategos?.titel }

var machtIndex: Int = 58
var dominanzLabel: String = "POSITIONSINDEX"
var hebel: [PragBarItem] = OpportunismaDemo.hebel
var dimensionen: [PragBarItem] = OpportunismaDemo.dimensionen
var strategischeZiele: [PragZielZeile] = OpportunismaDemo.ziele
var gegner: [PragGegnerZeile] = OpportunismaDemo.gegner
var szenarien: [PragSzenarioZeile] = OpportunismaDemo.szenarioZeilen
var ressourcen: [PragBarItem] = OpportunismaDemo.ressourcen
var narrativ: [(label: String, value: Double)] = OpportunismaDemo.narrativ
var influence: [PragBarItem] = OpportunismaDemo.influence
var risikoMatrix: [[Int]] = OpportunismaDemo.risikoMatrix
var netzKnoten: [PragNetzKnoten] = OpportunismaDemo.netzKnoten
var netzKanten: [PragNetzKante] = OpportunismaDemo.netzKanten
var meilensteine: [PragMeilenstein] = OpportunismaDemo.meilensteine
var hegemonogramm: [(label: String, ist: Double, soll: Double)] = OpportunismaDemo.hegemonogramm

/// Mutable Kopie der Demo-Bäume -- KI-Pfade werden hier angehängt.
var szenarienBaum: [String: PragSzenario] = OpportunismaDemo.szenarien

var aktivesSzenario: PragSzenario {
 szenarienBaum[szenarioKey] ?? OpportunismaDemo.szenarien["unternehmen"] ?? OpportunismaDemo.unternehmen
}

var kiBereit: Bool {
 KIKonfiguration.shared.modus == .base44 || KIKonfiguration.shared.modus == .offline
}

func flatten(_ node: PragTreeNode) -> [PragTreeNode] {
 [node] + node.children.flatMap { flatten($0) }
}

var flacheKnoten: [PragTreeNode] { flatten(aktivesSzenario.root) }

var fragebogenSchritte: [PragFragebogenSchritt] {
 OpportunismaFragebogenBank.schritte(fuer: verknuepftesStrategos)
}

var aktuellerFragebogenSchritt: PragFragebogenSchritt {
 let schritte = fragebogenSchritte
 guard !schritte.isEmpty else { return PragFragebogenFallback.leererSchritt }
 let idx = FenlynineOSRuntimeGuard.clampIndex(fragebogenSchrittIndex, count: schritte.count)
 return schritte[idx]
}

var fragebogenFortschritt: Double {
 guard !fragebogenSchritte.isEmpty else { return 0 }
 return Double(fragebogenSchrittIndex + 1) / Double(fragebogenSchritte.count + 1)
}

func antwort(fuer frageId: String) -> PragFrageAntwort {
 fragebogenAntworten[frageId] ?? PragFrageAntwort()
}

func setAntwort(_ antwort: PragFrageAntwort, fuer frageId: String) {
 fragebogenAntworten[frageId] = antwort
 modulQuellen = OpportunismaFragebogenBank.moduleFuerAntworten(fragebogenAntworten, szenario: verknuepftesStrategos)
}

func schrittIstVollstaendig(_ schritt: PragFragebogenSchritt) -> Bool {
 schritt.fragen.allSatisfy { antwort(fuer: $0.id).istAusgefuellt }
}

var fragebogenKannWeiter: Bool { schrittIstVollstaendig(aktuellerFragebogenSchritt) }

var fragebogenAntwortenText: String {
 OpportunismaFragebogenBank.alleFragen(fuer: verknuepftesStrategos).compactMap { frage in
   let a = antwort(fuer: frage.id)
   guard a.istAusgefuellt else { return nil }
   return "[\(frage.id)] \(frage.text)\n-> \(a.zusammenfassung(optionen: frage.optionen))"
 }.joined(separator: "\n\n")
}

func fragebogenZuruecksetzen() {
 fragebogenSchrittIndex = 0
 fragebogenAntworten = [:]
 fragebogenPhase = .fragen
 fragebogenZusammenfassung = nil
 kausalitaeten = []
 prognosen = []
 fragebogenAbgeschlossen = false
 modulQuellen = []
}

@MainActor
func aktualisiereAusgangUndZiel() {
 guard var sz = szenarienBaum[szenarioKey] else { return }
 sz.situation = situationText
 sz.ziel = zielText
 if !situationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
   sz.root.label = String(situationText.prefix(60))
   sz.root.detail = situationText
 }
 szenarienBaum[szenarioKey] = sz
}

@MainActor
func ladeStrategosSzenarien() async {
 strategosSzenarien = (try? await Services.strategosScenarios.list()) ?? []
 if verknuepftesStrategosId == nil, let first = strategosSzenarien.first?.id {
   verknuepftesStrategosId = first
 }
}

@MainActor
func synchronisiereMitStrategos() async {
 guard let sz = verknuepftesStrategos else { return }
 if let ctx = sz.unternehmenskontext?.dictValue {
   if let name = ctx["unternehmen_name"] as? String, !name.isEmpty {
     situationText = "Unternehmen: \(name). \(ctx["sachverhalt_lang"] as? String ?? situationText)"
   }
 }
 if let ziel = sz.fragestellung, !ziel.isEmpty { zielText = ziel }
 else if let z = sz.ausgangslage, !z.isEmpty { zielText = z }

 if let va = StrategosOpportunismaVertragsService.vertragsAnalyseDict(fuer: sz) {
   StrategosOpportunismaVertragsMapper.anwenden(auf: self, vertrag: va, szenario: sz)
 } else if var szTree = szenarienBaum["unternehmen"] {
   szTree.situation = situationText
   szTree.ziel = zielText
   szenarienBaum["unternehmen"] = szTree
 }

 modulQuellen = OpportunismaFragebogenBank.moduleFuerAntworten(fragebogenAntworten, szenario: sz)
 clampFragebogenSchritt()
}

func quellen(fuer tab: OpportunismaTab) -> [String] {
 modulQuellen.first { $0.modul == tab }?.quellen ?? []
}

/// Hängt einen KI-generierten Pfad unter `parentId` an (typisch: gewählter Knoten oder Wurzel).
func fuegeBaumKnoten(parentId: String, knoten: PragTreeNode) {
 guard var sz = szenarienBaum[szenarioKey] else { return }
 sz.root = Self.einfuegen(in: sz.root, parentId: parentId, knoten: knoten)
 szenarienBaum[szenarioKey] = sz
}

private static func einfuegen(in node: PragTreeNode, parentId: String, knoten: PragTreeNode) -> PragTreeNode {
 if node.id == parentId {
   var n = node
   n.children.append(knoten)
   return n
 }
 var n = node
 n.children = node.children.map { einfuegen(in: $0, parentId: parentId, knoten: knoten) }
 return n
}
}

// MARK: - Demo-Daten (Machtportal + Mockups)

enum OpportunismaDemo {
static let defaultSituation =
 "Mittelständisches Industrieunternehmen in der DACH-Region. Moderate Marktposition, steigende Regulatorik, Forschungspartnerschaft mit einer Universität."
static let defaultZiel =
 "Position in Politik, Wirtschaft und Wissenschaft stärken -- nachhaltiges Wachstum und regulatorische Gestaltungsmacht."

static let hebel: [PragBarItem] = [
 .init(name: "Regulatorische Gestaltung", wert: 62),
 .init(name: "Forschung & IP", wert: 71),
 .init(name: "Markt & Vertrieb", wert: 68),
 .init(name: "Stakeholder-Netzwerk", wert: 74),
 .init(name: "Finanzielle Stabilität", wert: 79)
]

static let dimensionen: [PragBarItem] = [
 .init(name: "Wirtschaft", wert: 72),
 .init(name: "Politik", wert: 55),
 .init(name: "Wissenschaft", wert: 64),
 .init(name: "Recht & Compliance", wert: 78),
 .init(name: "Innovation", wert: 61),
 .init(name: "Reputation", wert: 70)
]

static let ziele: [PragZielZeile] = [
 .init(ziel: "EU-Regulierung mitgestalten", status: "In Vorbereitung", fortschritt: 42),
 .init(ziel: "Forschungsallianz ausbauen", status: "Aktiv", fortschritt: 58),
 .init(ziel: "Marktanteil DACH +2%", status: "In Umsetzung", fortschritt: 51),
 .init(ziel: "Strategos-Risiken absichern", status: "Offen", fortschritt: 35)
]

static let gegner: [PragGegnerZeile] = [
 .init(name: "Marktführer Branche A", einfluss: "Sehr hoch", bedrohung: "Hoch", kontrolle: "Beobachtung"),
 .init(name: "Asiatischer Low-Cost-Anbieter", einfluss: "Mittel", bedrohung: "Mittel", kontrolle: "Produktinnovation"),
 .init(name: "Neuer Regulator (EU)", einfluss: "Entscheidend", bedrohung: "Hoch", kontrolle: "Lobby & Compliance")
]

static let szenarioZeilen: [PragSzenarioZeile] = [
 .init(name: "Verbands-Lobby EU-Gesetz", wahrscheinlichkeit: 65, kontrolle: 58, ergebnis: "CHANCE"),
 .init(name: "F&E-Kooperation Universität", wahrscheinlichkeit: 72, kontrolle: 70, ergebnis: "ERFOLG"),
 .init(name: "Regulatorische Verschärfung", wahrscheinlichkeit: 55, kontrolle: 40, ergebnis: "RISIKO"),
 .init(name: "Marktexpansion DACH", wahrscheinlichkeit: 60, kontrolle: 65, ergebnis: "OPTION")
]

static let ressourcen: [PragBarItem] = [
 .init(name: "Kapital / Investition", wert: 74),
 .init(name: "Forschung & Patente", wert: 68),
 .init(name: "Compliance & Recht", wert: 82),
 .init(name: "Stakeholder-Netzwerk", wert: 71),
 .init(name: "Digitale Infrastruktur", wert: 63),
 .init(name: "Employer Brand", wert: 76)
]

static let narrativ: [(label: String, value: Double)] = [
 ("Politik", 5.8), ("Wirtschaft", 7.2), ("Wissenschaft", 6.4),
 ("Medien", 5.5), ("Recht", 7.8), ("Innovation", 6.9), ("Gesellschaft", 5.2)
]

static let influence: [PragBarItem] = [
 .init(name: "Verbandsarbeit", wert: 68),
 .init(name: "Policy-Kommunikation", wert: 72),
 .init(name: "Thought Leadership", wert: 61),
 .init(name: "Koalitionsbildung", wert: 55),
 .init(name: "Transparenz & ESG", wert: 74)
]

static let risikoMatrix: [[Int]] = [
 [0, 0, 1, 2, 3],
 [0, 1, 2, 3, 4],
 [1, 2, 3, 4, 5],
 [2, 3, 4, 5, 6],
 [3, 4, 5, 6, 6]
]

static let netzKnoten: [PragNetzKnoten] = [
 .init(label: "UNTERNEHMEN", typ: "kontrolliert", x: 0.5, y: 0.45),
 .init(label: "Branchenverband", typ: "verbündet", x: 0.28, y: 0.25),
 .init(label: "Forschungspartner", typ: "verbündet", x: 0.72, y: 0.22),
 .init(label: "Wettbewerber", typ: "feindlich", x: 0.78, y: 0.62),
 .init(label: "Regulator", typ: "neutral", x: 0.22, y: 0.68)
]

static let netzKanten: [PragNetzKante] = [
 .init(von: "UNTERNEHMEN", zu: "Branchenverband"),
 .init(von: "UNTERNEHMEN", zu: "Forschungspartner"),
 .init(von: "Wettbewerber", zu: "Regulator"),
 .init(von: "Forschungspartner", zu: "Regulator")
]

static let meilensteine: [PragMeilenstein] = [
 .init(titel: "Fragebogen & Strategos-Link", start: 0, dauer: 2),
 .init(titel: "Stakeholder-Roadmap", start: 2, dauer: 3),
 .init(titel: "Policy-Engagement", start: 4, dauer: 4),
 .init(titel: "Umsetzung Strategie-Baum", start: 7, dauer: 3)
]

static let hegemonogramm: [(label: String, ist: Double, soll: Double)] = [
 ("Politik", 5.5, 8.0), ("Wirtschaft", 7.0, 8.5), ("Wissenschaft", 6.4, 8.8),
 ("Innovation", 6.2, 8.5), ("Compliance", 7.8, 9.0), ("Stakeholder", 6.8, 8.5),
 ("Marktanteil", 6.5, 8.0), ("Resilienz", 6.0, 8.2)
]

static let footerMottos: [(symbol: String, text: String)] = [
 ("building.2", "UNTERNEHMEN VOR INDIVIDUUM"),
 ("globe.europe.africa", "POLITIK · WIRTSCHAFT · WISSENSCHAFT"),
 ("link", "STRATEGOS IN OPPORTUNISMA UMSETZEN"),
 ("chart.line.uptrend.xyaxis", "POSITION SICHERN · WACHSEN"),
 ("shield.checkered", "COMPLIANCE IST STRATEGIE"),
 ("person.3", "STAKEHOLDER ORCHESTRIEREN"),
 ("target", "UNTERNEHMENSZIELE SIND MASS")
]

static let szenarien: [String: PragSzenario] = [
 "unternehmen": unternehmen,
 "politik": politikPfad
]

static let unternehmen = PragSzenario(
 id: "unternehmen",
 label: "Unternehmensstrategie",
 situation: "Mittelstand unter Regulatorik- und Wettbewerbsdruck. Strategos-Analysen liegen teilweise vor.",
 ziel: "Position in Politik, Wirtschaft und Wissenschaft stärken",
 akteure: ["Unternehmen", "Branchenverband", "Forschungspartner", "Regulator", "Wettbewerber"],
 root: PragTreeNode(
   id: "uroot", typ: .position, label: "Unternehmenslage",
   detail: "Marktposition stabil, Regulatorik im Wandel, F&E-Kooperation vorhanden.",
   scores: nil,
   children: [
     PragTreeNode(id: "um1", typ: .move, label: "Verbands-Lobby EU-Richtlinie",
       detail: "Branchenverband aktiv einbinden, Positionspapier.",
       scores: .init(efficacy: 74, risk: 28, reversibility: 80, harm: 12),
       children: [
         PragTreeNode(id: "uo1", typ: .outcome, label: "Mitgestaltung Gesetzentwurf",
           detail: "Günstigere Übergangsfristen.",
           scores: .init(efficacy: 78, risk: 22, reversibility: 75, harm: 10),
           children: [
             PragTreeNode(id: "ug1", typ: .goal, label: "Regulatorische Sicherheit",
               detail: "Planbare Compliance-Kosten.", scores: .init(efficacy: 82, risk: 18, reversibility: 70, harm: 8), children: [])
           ])
       ]),
     PragTreeNode(id: "um2", typ: .move, label: "Forschungsallianz intensivieren",
       detail: "Joint Lab mit Universität, Patente sichern.",
       scores: .init(efficacy: 70, risk: 24, reversibility: 85, harm: 8),
       children: [
         PragTreeNode(id: "uo2", typ: .outcome, label: "Technologieführerschaft",
           detail: "Stärkere Wissenschafts-Position.", scores: nil,
           children: [
             PragTreeNode(id: "ug2", typ: .goal, label: "Innovationsführerschaft",
               detail: "Marktanteil durch IP.", scores: nil, children: [])
           ])
       ])
   ]
 )
)

static let politikPfad = PragSzenario(
 id: "politik",
 label: "Politik & Regulatorik",
 situation: "Neue EU-Regulierung droht. Wettbewerber lobbyieren bereits.",
 ziel: "Regulatorischen Rahmen mitgestalten",
 akteure: ["Unternehmen", "EU-Kommission", "Branchenverband", "NGO", "Wettbewerber"],
 root: PragTreeNode(
   id: "proot", typ: .position, label: "Regulatorische Ausgangslage",
   detail: "Gesetzentwurf in Konsultation. Wettbewerber haben Vorsprung.",
   scores: nil,
   children: [
     PragTreeNode(id: "pm1", typ: .move, label: "Konsultationsantwort einreichen",
       detail: "Fachlich, mit Wissenschaftsbelegen.", scores: .init(efficacy: 76, risk: 20, reversibility: 90, harm: 5),
       children: [
         PragTreeNode(id: "po1", typ: .outcome, label: "Anhörung eingeladen",
           detail: "Sichtbarkeit im Prozess.", scores: nil,
           children: [
             PragTreeNode(id: "pg1", typ: .goal, label: "Ausgewogene Regulierung",
               detail: "Wettbewerbsfähigkeit erhalten.", scores: nil, children: [])
           ])
       ])
   ]
 )
)
}

extension TransparenzInhalt {
static func opportunismaKI(titel: String, begruendung: String, ausgabe: String) -> TransparenzInhalt {
 kiModul(titel: titel, modell: "Claude Sonnet 4.6", begruendung: begruendung, ausgabe: ausgabe,
     erklaerung: "Opportunisma: Unternehmensstrategie als Erweiterung von Strategos -- Politik, Wirtschaft, Wissenschaft.")
}

static func opportunismaWidget(titel: String, formel: String, begruendung: String, ergebnis: String) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: titel,
   quelle: .algorithmus,
   modell: "Opportunisma Unternehmens-Engine v2",
   ergebnis: ergebnis,
   begruendung: begruendung,
   formel: formel,
   erklaerung: "Verknüpfte Berechnung aus Fragebogen, Strategos-Daten und Modul-Kette."
 )
}
}

