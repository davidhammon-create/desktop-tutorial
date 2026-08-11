import Foundation

// MARK: - Advocatus Analyse (deterministisch + optionale KI-Rückfragen)

struct AdvocatusAussageAnalyse: Equatable {
let handlungsoptionen: [String]
let konter: [String]
let gegenargumente: [String]
let risikoHinweise: [String]
let vorgeschlageneFragen: [String]
}

struct AdvocatusFrageAntwort: Identifiable, Equatable {
let id: String
let frage: String
var antwort: String
var laedt: Bool
}

enum FenlynineOSAdvocatusAnalyseService {

static func analysiere(
  text: String,
  sprecher: AdvocatusSprecher,
  klassifikation: AdvocatusKlassifikation,
  store: FenlynineOSKernStore
) -> AdvocatusAussageAnalyse {
  var handlungen = handlungsoptionen(fuer: klassifikation, sprecher: sprecher, text: text)
  var konter = konterVorschlaege(store: store, klassifikation: klassifikation, text: text)
  var gegen = gegenargumente(fuer: sprecher, klassifikation: klassifikation, text: text)
  var risiken = risikoHinweise(text: text, klassifikation: klassifikation, store: store)
  let fragen = vorgeschlageneFragen(text: text, sprecher: sprecher, klassifikation: klassifikation)

  if let opt = store.hoechsteOption {
    konter.insert("Strategie-Option: \(opt.titel) (EV \(Int(opt.ev ?? 0)))", at: 0)
  }
  let argumente = store.knoten.filter { $0.typ == .argument || $0.typ == .klausel }.prefix(2)
  for arg in argumente {
    gegen.append("Graph-Bezug: \(arg.titel) -- prüfen ob Aussage stützt oder widerlegt")
  }

  if handlungen.isEmpty { handlungen = ["Aktenvermerk", "Pause beantragen", "Präzisierung verlangen"] }
  if konter.isEmpty { konter = ["Sachverhalt präzisieren", "Beweismittel benennen"] }
  if gegen.isEmpty { gegen = ["Gegenseite wird Einwand erheben -- vorbereiten"] }

  return AdvocatusAussageAnalyse(
    handlungsoptionen: handlungen,
    konter: konter,
    gegenargumente: gegen,
    risikoHinweise: risiken,
    vorgeschlageneFragen: fragen
  )
}

static func beantworteFrage(
  frage: String,
  aussage: String,
  sprecher: AdvocatusSprecher,
  klassifikation: AdvocatusKlassifikation,
  store: FenlynineOSKernStore
) async -> String {
  let kontext = store.hoechsteOption.map { "Beste Option: \($0.titel), EV \(Int($0.ev ?? 0))" } ?? "Kein Graph-Kontext"
  let prompt = """
  Advocatus Live-Protokoll (FenlynineOS). Sprecher: \(sprecher.bezeichnung). Klassifikation: \(klassifikation.bezeichnung).
  Aussage: "\(aussage)"
  Graph: \(kontext)
  Frage des Anwalts: \(frage)
  Antworte kurz, pragmatisch, auf Deutsch (max. 4 Sätze). Keine Einleitung.
  """
  do {
    return try await LLMService.shared.invokeText(
      prompt: prompt,
      logKiName: "Advocatus_Frage"
    )
  } catch {
    return antwortDeterministisch(frage: frage, aussage: aussage, sprecher: sprecher, klassifikation: klassifikation)
  }
}

// MARK: - Regelbasiert

private static func handlungsoptionen(
  fuer klassifikation: AdvocatusKlassifikation,
  sprecher: AdvocatusSprecher,
  text: String
) -> [String] {
  switch klassifikation {
  case .fakt:
    return ["Aktenvermerk anfertigen", "Beweis benennen", "Zeugenliste prüfen", "Sachverhalt präzisieren lassen"]
  case .zusage:
    return ["Zusage schriftlich fixieren", "Frist setzen", "Konsequenz bei Verzug klären"]
  case .frist:
    return ["Kalender-Eintrag", "Wiedervorlage setzen", "Fristsicherung prüfen", "Gegenfrist anregen"]
  case .widerspruch:
    return ["Konter vorbereiten", "Beweisantrag stellen", "Akteneinsicht nachfordern", "Hinweis an Gericht"]
  case .risiko:
    return ["Risiko im Graph markieren", "Alternative Option aktivieren", "Schadensbegrenzung", "Settlement prüfen"]
  case .notiz:
    return ["Interne Notiz", "Team informieren", "Später vertiefen"]
 }
}

private static func konterVorschlaege(
 store: FenlynineOSKernStore,
 klassifikation: AdvocatusKlassifikation,
 text: String
) -> [String] {
 var list: [String] = []
 switch klassifikation {
 case .widerspruch, .risiko:
   list += ["Einwand entkräften: Beweislage darlegen", "Subsumtion unter Norm wiederholen"]
 case .fakt:
   list += ["Bestätigung einfordern", "Widerspruch zu Aktenlage"]
 default:
   list += ["Nachfrage: Was genau ist gemeint?", "Protokollberichtigung"]
 }
 if text.localizedCaseInsensitiveContains("nicht") {
   list.append("Verneinung -- Gegenbeweis oder alternative Lesart")
 }
 if let r = store.knoten.first(where: { $0.typ == .risiko }) {
   list.append("Risiko-Knoten \(r.titel) einbeziehen (RPN \(Int(r.rpn ?? 0)))")
 }
 return list
}

private static func gegenargumente(
 fuer sprecher: AdvocatusSprecher,
 klassifikation: AdvocatusKlassifikation,
 text: String
) -> [String] {
 switch sprecher {
 case .richter:
   return ["Richterliche Einschätzung -- höchstrichterliche Rechtsprechung prüfen",
       "Ermessensspielraum des Gerichts",
       "Prozessökonomie als Gegenargument"]
 case .gegner:
   return ["Gegenposition dokumentieren", "Schwachstelle in Gegenargument suchen",
       "Vergleichsangebot als Konter"]
 case .zeuge:
   return ["Glaubwürdigkeit prüfen", "Widerspruch zu vorheriger Aussage",
       "Kreuzverhör vorbereiten"]
 case .eigen, .ich:
   return ["Eigene Aussage konsistent halten", "Widerspruch durch Aktenlage vermeiden"]
 }
}

private static func risikoHinweise(
 text: String,
 klassifikation: AdvocatusKlassifikation,
 store: FenlynineOSKernStore
) -> [String] {
 var h: [String] = []
 if klassifikation == .risiko || klassifikation == .widerspruch {
   h.append("Prozessrisiko steigt -- Graph aktualisiert")
 }
 if regelFilterFrist(text) {
   h.append("Frist-relevant -- Kalender & Lexara prüfen")
 }
 if store.knoten.contains(where: { ($0.rpn ?? 0) > 100 }) {
   h.append("Hoher RPN im Netz -- Eskalation erwägen")
 }
 return h
}

private static func vorgeschlageneFragen(
 text: String,
 sprecher: AdvocatusSprecher,
 klassifikation: AdvocatusKlassifikation
) -> [String] {
 var q = [
   "Was ist die rechtliche Tragweite dieser Aussage?",
   "Welche Beweismittel stützen oder widerlegen das?",
   "Wie wirkt das auf unsere beste Option?"
 ]
 switch sprecher {
 case .richter:
   q.insert("Welche Ermessensentscheidung liegt zugrunde?", at: 0)
 case .gegner:
   q.insert("Welche Schwachstelle hat das Gegenargument?", at: 0)
 case .zeuge:
   q.insert("Ist die Aussage mit Aktenlage vereinbar?", at: 0)
 default:
   break
 }
 if klassifikation == .frist {
   q.append("Bis wann muss reagiert werden?")
 }
 return q
}

private static func antwortDeterministisch(
 frage: String,
 aussage: String,
 sprecher: AdvocatusSprecher,
 klassifikation: AdvocatusKlassifikation
) -> String {
 let f = frage.lowercased()
 if f.contains("beweis") {
   return "Prüfen Sie Aktenlage und Zeugen zu: „\(String(aussage.prefix(80)))". \(sprecher.bezeichnung) -- \(klassifikation.bezeichnung)."
 }
 if f.contains("frist") || f.contains("wann") {
   return "Fristbezug prüfen. Bei \(klassifikation.bezeichnung) sofort Kalender und Lexara-Fristenmodul kontrollieren."
 }
 if f.contains("option") || f.contains("strateg") {
   return "Vergleichen Sie mit der höchsten EV-Option im Kern-Graph. Aussage ggf. als EREIGNIS-Kante routen."
 }
 return "Bezug: \(sprecher.bezeichnung), \(klassifikation.bezeichnung). „\(String(aussage.prefix(60)))" -- im Graph verknüpfen und Konter vorbereiten."
}

static func regelFilterFrist(_ text: String) -> Bool {
 text.contains("§") || text.contains("Frist")
   || text.range(of: #"\d{1,2}\.\d{1,2}"#, options: .regularExpression) != nil
}
}

