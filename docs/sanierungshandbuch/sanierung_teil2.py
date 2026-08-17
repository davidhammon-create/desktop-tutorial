# -*- coding: utf-8 -*-
"""Inhalt Teil 2: Kapitel B (Prognosen), C (Reproduzierbarkeit), D (RVG), E (Passwörter)."""

TEIL2 = [
 ("seitenumbruch", None),
 ("h2", "B · Willkürliche Zahlen ersetzen: Prognosen, die tragen"),
 ("etikett", "kritisch · Aufwand: 3–4 Tage für den Umbau, dann laufend"),

 ("h3", "Was falsch ist"),
 ("p", "Die Monte-Carlo-Simulation ist handwerklich echt: Box-Muller-Transformation, "
       "3.000 Ziehungen, Perzentile. Erfunden sind die Zahlen, mit denen sie rechnet "
       "(<font face=\"Mono\">AbschlussMonteCarloEngine.swift:50–54</font>):"),
 ("code", """let algoStd       = 5.0
let kiStdCorrect  = 8.0
let kiStdWrong    = 18.0
let complianceStd = 6.0
let riskStd       = 5.0"""),
 ("p", "Ebenso die Ausgangswahrscheinlichkeiten und Instanzfaktoren "
       "(<font face=\"Mono\">LegalAlgorithmsService.swift:16–33</font>):"),
 ("code", """static let rechtsgebietBaserates: [String: Double] = [
  "Arbeitsrecht": 0.52,  "Mietrecht": 0.54,  "Vertragsrecht": 0.51,
  "Strafrecht": 0.35,    // Staatsanwaltschaft hat strukturellen Vorteil
  ...
]
static let instanzFaktor: [LegalCase.Instanz: Double] = [
  .erstinstanz: 1.0,
  .berufung: 0.88,   // Berufungsgerichte bestätigen i.d.R. ~70-75% Urteile
  .revision: 0.70
]"""),
 ("p", "Keine dieser Zahlen ist mit einer Quelle belegt, und im Projekt liegt kein Datensatz, "
       "aus dem sie stammen könnten. Die Kommentare behaupten eine Empirie, die nicht "
       "existiert. Heraus kommt eine Prognose mit 90-%-Konfidenzintervall — eine Zahl, die "
       "Präzision vortäuscht, die sie nicht hat."),

 ("kasten_achtung", "Die unangenehme Wahrheit über die Datenlage",
  "Bevor Sie losziehen, um „die richtigen Zahlen\" zu suchen: <b>Eine öffentlich verfügbare "
  "Statistik der Klägererfolgsquoten nach Rechtsgebiet gibt es in Deutschland nicht.</b> "
  "Die amtliche Zivilgerichtsstatistik (Destatis, Fachserie 10 Reihe 2.1) erhebt "
  "Erledigungsarten — Urteil, Vergleich, Klagerücknahme, Anerkenntnis —, "
  "Verfahrensdauern und Rechtsmittelerledigungen. Sie erhebt nicht, wer „gewonnen\" hat, "
  "und erst recht nicht aufgeschlüsselt nach Rechtsgebiet in der Feinheit, die der Code "
  "unterstellt. Was sich daraus belegen lässt: Anteil der Vergleichserledigungen, "
  "durchschnittliche Verfahrensdauer je Instanz und Gerichtsart, und der Anteil der "
  "Berufungen, die zur Abänderung führen — Letzteres ist die einzige Größe, aus der sich "
  "ein Instanzfaktor seriös ableiten ließe. Alle Destatis-Werte prüfen Sie bitte selbst "
  "an der Quelle; ich konnte sie hier nicht abrufen."),

 ("p", "Daraus folgt: Sie haben drei Wege, und nur zwei davon sind sofort begehbar."),

 ("h3", "Weg 1 — Szenario-Rechner statt Prognose (sofort, ohne Daten)"),
 ("p", "Das ist der Weg, den ich empfehle. Die Idee: <b>Der Anwalt setzt die Annahmen, die "
       "App rechnet.</b> Damit verschwindet die Willkür nicht, aber sie wechselt den "
       "Besitzer — und zwar zu demjenigen, der sie fachlich verantworten kann und muss. "
       "Das passt exakt zur Herkunftsmarke: die Annahme ist blau (Mensch), das Ergebnis grün "
       "(Formel). Nichts ist mehr orange und tut so, als wüsste es etwas."),
 ("code", """/// Alle Annahmen, die in eine Bewertung eingehen -- ausnahmslos vom Menschen gesetzt.
struct Annahmen: Codable, Hashable {
  /// Erfolgswahrscheinlichkeit im Hauptpunkt, wie vom Anwalt eingeschätzt.
  var erfolgswahrscheinlichkeit: Double        // 0...1
  /// Unsicherheit dieser Einschätzung: wie weit kann sie daneben liegen?
  var unsicherheit: Double                     // 0...1, z. B. 0,15 = plus/minus 15 Punkte
  var streitwert: Double
  var vergleichsbereitschaftGegner: Double     // 0...1
  var erwarteteVerfahrensdauerMonate: Int

  /// Wer hat die Annahme gesetzt und wann -- gehört in die Akte.
  var gesetztVon: String
  var gesetztAm: Date
  var begruendung: String                      // Pflichtfeld, nicht optional

  /// Vorschlagswerte für ein leeres Formular. Bewusst neutral:
  /// 50 % heißt "keine Ahnung", nicht "ausgewogen". Die App darf hier
  /// niemals eine rechtsgebietsspezifische Zahl vorbelegen.
  static func neutralerStart(streitwert: Double, nutzer: String) -> Annahmen {
    .init(erfolgswahrscheinlichkeit: 0.5, unsicherheit: 0.2,
          streitwert: streitwert, vergleichsbereitschaftGegner: 0.5,
          erwarteteVerfahrensdauerMonate: 12,
          gesetztVon: nutzer, gesetztAm: Date(), begruendung: "")
  }
}"""),
 ("p", "Statt einer Punktprognose zeigt die App dann, <b>wie empfindlich das Ergebnis auf "
       "jede Annahme reagiert</b>. Das ist die Information, die einem Anwalt tatsächlich "
       "hilft — sie beantwortet die Frage „worauf kommt es an?\", nicht die unbeantwortbare "
       "Frage „wie geht es aus?\":"),
 ("code", """struct Empfindlichkeit: Identifiable {
  let id = UUID()
  let annahme: String
  let basisWert: Double
  let ergebnisBasis: Double
  let ergebnisNiedrig: Double     // Annahme um eine Stufe schlechter
  let ergebnisHoch: Double        // Annahme um eine Stufe besser
  var spannweite: Double { abs(ergebnisHoch - ergebnisNiedrig) }
}

enum Szenariorechner {
  /// Erwartungswert: rein arithmetisch, keine verborgenen Konstanten.
  static func erwartungswert(_ a: Annahmen, kosten: Kostenrisiko) -> Double {
    a.erfolgswahrscheinlichkeit * (a.streitwert - kosten.eigeneKostenBeiSieg)
      - (1 - a.erfolgswahrscheinlichkeit) * kosten.gesamtkostenBeiNiederlage
  }

  /// Tornado-Analyse: welche Annahme bewegt das Ergebnis am stärksten?
  static func empfindlichkeiten(_ a: Annahmen, kosten: Kostenrisiko) -> [Empfindlichkeit] {
    let basis = erwartungswert(a, kosten: kosten)
    var out: [Empfindlichkeit] = []

    var tief = a; tief.erfolgswahrscheinlichkeit = max(0, a.erfolgswahrscheinlichkeit - a.unsicherheit)
    var hoch = a; hoch.erfolgswahrscheinlichkeit = min(1, a.erfolgswahrscheinlichkeit + a.unsicherheit)
    out.append(.init(annahme: "Erfolgswahrscheinlichkeit",
                     basisWert: a.erfolgswahrscheinlichkeit, ergebnisBasis: basis,
                     ergebnisNiedrig: erwartungswert(tief, kosten: kosten),
                     ergebnisHoch: erwartungswert(hoch, kosten: kosten)))

    var sTief = a; sTief.streitwert = a.streitwert * 0.8
    var sHoch = a; sHoch.streitwert = a.streitwert * 1.2
    out.append(.init(annahme: "Streitwert plus/minus 20 %",
                     basisWert: a.streitwert, ergebnisBasis: basis,
                     ergebnisNiedrig: erwartungswert(sTief, kosten: kosten),
                     ergebnisHoch: erwartungswert(sHoch, kosten: kosten)))

    return out.sorted { $0.spannweite > $1.spannweite }
  }

  /// Der Kipppunkt: ab welcher Erfolgswahrscheinlichkeit lohnt das Verfahren?
  /// Diese Zahl ist ehrlich, weil sie nichts prognostiziert, sondern eine
  /// Bedingung nennt, die der Anwalt selbst beurteilen kann.
  static func kipppunkt(streitwert: Double, kosten: Kostenrisiko) -> Double {
    let gewinn = streitwert - kosten.eigeneKostenBeiSieg
    let verlust = kosten.gesamtkostenBeiNiederlage
    guard gewinn + verlust > 0 else { return 1 }
    return verlust / (gewinn + verlust)
  }
}"""),
 ("kasten_wichtig", "Der Satz, der den Unterschied macht",
  "Statt „Erfolgsaussicht 63 %, Intervall 55–71 %\" sagt die App künftig: "
  "<b>„Ab einer Erfolgswahrscheinlichkeit von 38 % ist die Klage wirtschaftlich sinnvoll. "
  "Ihre Einschätzung liegt bei 60 %. Der Abstand ist komfortabel; entscheidend ist der "
  "Streitwert, nicht die Erfolgsquote.\"</b> "
  "Der erste Satz ist unbelegbar und im Haftungsfall angreifbar. Der zweite ist eine "
  "reine Rechnung aus Zahlen, die der Anwalt selbst gesetzt hat — nachvollziehbar, "
  "verteidigungsfähig und praktisch nützlicher. Das ist der ganze Trick, und er kostet "
  "Sie keine Funktionalität, sondern nur eine falsche Behauptung."),

 ("h3", "Weg 2 — Eigene Daten sammeln und ehrlich kalibrieren (mittelfristig)"),
 ("p", "Wenn Sie später doch echte Wahrscheinlichkeiten wollen, ist der einzige seriöse Weg "
       "der über eigene Fälle. Das dauert, ist aber der Punkt, an dem aus der App ein "
       "verteidigungsfähiges Produkt und ein echter Wettbewerbsvorsprung würde. "
       "Der Ablauf in vier Stufen:"),
 ("nummerierte_liste", [
   ("Merkmale und Ausgang jedes abgeschlossenen Falls festhalten",
    "Bei jedem Abschluss einen Datensatz schreiben: Rechtsgebiet, Instanz, Streitwert, "
    "Anzahl eigener und gegnerischer Argumente, Beweismittel nach Art, Vergleich oder Urteil, "
    "und den tatsächlichen Ausgang als Zahl zwischen 0 und 1 (0 = vollständig verloren, "
    "0,5 = Vergleich zur Hälfte, 1 = vollständig obsiegt). Wichtig: Der Ausgang muss "
    "<b>nach</b> der Prognose eingetragen werden, sonst kalibrieren Sie auf Ihre eigene "
    "Erwartung statt auf die Wirklichkeit."),
   ("Erst ab etwa 200 abgeschlossenen Fällen rechnen",
    "Darunter ist jede Schätzung Rauschen. Bei 200 Fällen und fünf Merkmalen liegt der "
    "Standardfehler einer Quote grob bei 3–4 Prozentpunkten — das ist die Grenze dessen, "
    "was Sie überhaupt behaupten können. Zeigen Sie deshalb niemals eine Prognose auf "
    "Prozentpunkt genau, sondern in Stufen von fünf."),
   ("Logistische Regression, nicht Handgewichtung",
    "Exportieren Sie die Datensätze als CSV und schätzen Sie ein logistisches Modell "
    "(Python/statsmodels, R/glm). Die Koeffizienten legen Sie als versionierte JSON-Datei "
    "in die App. Damit ist jede Zahl auf einen Datenstand zurückführbar — und die "
    "Herkunftsmarke kann ehrlich „Formel\" zeigen."),
   ("Kalibrierung messen und veröffentlichen, nicht behaupten",
    "Zwei Kennzahlen entscheiden, ob das Modell ausgeliefert werden darf: der Brier-Score "
    "(mittlerer quadratischer Fehler der Wahrscheinlichkeit; kleiner ist besser, und er muss "
    "unter dem Wert der bloßen Grundquote liegen, sonst ist das Modell schlechter als "
    "Raten) und das Kalibrierungsdiagramm: Sortieren Sie die Prognosen in Zehnergruppen "
    "und tragen Sie die tatsächliche Erfolgsquote gegen die prognostizierte auf. Nur wenn "
    "diese Kurve nahe an der Diagonale liegt, darf die Zahl „63 %\" heißen. "
    "Zeigen Sie beides in der App an, damit der Nutzer weiß, wie gut die Prognose ist."),
 ]),
 ("code", """/// Ein Datensatz je abgeschlossenem Fall -- die Grundlage jeder späteren Kalibrierung.
struct Prognosedatensatz: Codable, Identifiable {
  var id = UUID()
  var fallId: String
  var rechtsgebiet: String
  var instanz: String
  var streitwert: Double
  var anzahlEigeneArgumente: Int
  var anzahlGegnerArgumente: Int
  var beweismittelUrkunden: Int
  var beweismittelZeugen: Int
  var beweismittelSachverstaendige: Int

  /// Was die App vor Verfahrensende vorhergesagt hat -- unveränderlich.
  var prognoseVorher: Double
  var prognoseModellVersion: String
  var prognoseErstelltAm: Date

  /// Was tatsächlich herauskam. Wird erst beim Abschluss gesetzt.
  var tatsaechlicherAusgang: Double?          // 0...1
  var erledigungsart: String?                 // Urteil, Vergleich, Rücknahme...
  var abgeschlossenAm: Date?
}

enum Kalibrierung {
  /// Brier-Score: mittlerer quadratischer Fehler. Muss unter dem Wert der
  /// Grundquote liegen, sonst ist das Modell schlechter als schlichtes Raten.
  static func brier(_ daten: [Prognosedatensatz]) -> (modell: Double, grundquote: Double)? {
    let fertig = daten.compactMap { d -> (Double, Double)? in
      guard let a = d.tatsaechlicherAusgang else { return nil }
      return (d.prognoseVorher, a)
    }
    guard fertig.count >= 30 else { return nil }
    let basis = fertig.map(\\.1).reduce(0, +) / Double(fertig.count)
    let modell = fertig.map { pow($0.0 - $0.1, 2) }.reduce(0, +) / Double(fertig.count)
    let referenz = fertig.map { pow(basis - $0.1, 2) }.reduce(0, +) / Double(fertig.count)
    return (modell, referenz)
  }

  /// Kalibrierungskurve in Zehnergruppen: prognostiziert gegen tatsächlich.
  static func kurve(_ daten: [Prognosedatensatz]) -> [(bereich: String, prognose: Double,
                                                       tatsaechlich: Double, n: Int)] {
    var gruppen: [Int: [(Double, Double)]] = [:]
    for d in daten {
      guard let a = d.tatsaechlicherAusgang else { continue }
      let bin = min(9, Int(d.prognoseVorher * 10))
      gruppen[bin, default: []].append((d.prognoseVorher, a))
    }
    return gruppen.keys.sorted().map { bin in
      let w = gruppen[bin]!
      return ("\\(bin * 10)-\\(bin * 10 + 9) %",
              w.map(\\.0).reduce(0, +) / Double(w.count),
              w.map(\\.1).reduce(0, +) / Double(w.count),
              w.count)
    }
  }
}"""),

 ("h3", "Weg 3 — Amtliche Statistik für das, was sie hergibt"),
 ("p", "Für zwei Größen gibt es belastbare öffentliche Zahlen, und die sollten Sie nutzen, "
       "weil sie die App sofort glaubwürdiger machen als jede erfundene Erfolgsquote:"),
 ("tabelle", ["Größe", "Quelle", "Wofür in der App"], [
   ["Anteil der Vergleichserledigungen",
    "Destatis Fachserie 10 Reihe 2.1, Erledigungsarten",
    "Ehrliche Aussage „X von 100 vergleichbaren Verfahren enden im Vergleich\" — "
    "als Kontext, nicht als Prognose"],
   ["Durchschnittliche Verfahrensdauer je Instanz und Gerichtsart",
    "Destatis Fachserie 10 Reihe 2.1",
    "Vorbelegung des Feldes „erwartete Verfahrensdauer\" und Zinsberechnung"],
   ["Erledigung von Berufungen (Abänderung / Zurückweisung)",
    "Destatis Fachserie 10 Reihe 2.1",
    "Die einzige Größe, aus der ein Instanzfaktor seriös abgeleitet werden kann — "
    "ersetzt den erfundenen Wert 0,88"],
   ["RVG- und GKG-Gebühren", "Anlage 2 RVG, Anlage 2 GKG",
    "Kostenrisiko exakt statt geschätzt (Kapitel D)"],
 ]),
 ("p", "Legen Sie diese Werte als versionierte JSON-Datei mit Fundstelle und Abrufdatum ins "
       "Projekt, nicht als Konstante in den Code. Dann ist jede Zahl belegt, "
       "und die jährliche Aktualisierung ist ein Datei-Austausch statt einer Codeänderung:"),
 ("code", """{
  "quelle": "Statistisches Bundesamt, Fachserie 10 Reihe 2.1",
  "berichtsjahr": 2024,
  "abgerufen_am": "2026-08-17",
  "fundstelle": "Tabelle 4.1, Erledigung der Verfahren vor den Landgerichten",
  "werte": {
    "vergleichsquote_landgericht_erstinstanz": 0.21,
    "durchschnittsdauer_monate_landgericht_erstinstanz": 10.8
  },
  "hinweis": "Alle Werte vor Auslieferung gegen die Originaltabelle prüfen."
}"""),
 ("kasten_wichtig", "Was Sie sofort löschen sollten",
  "Solange Weg 1 nicht umgesetzt ist: Entfernen Sie die Kommentare, die eine Empirie "
  "behaupten („Berufungsgerichte bestätigen i.d.R. ~70-75 % Urteile\", „Staatsanwaltschaft "
  "hat strukturellen Vorteil\"). Sie sind der gefährlichste Teil des Codes, weil ein "
  "Entwickler oder Gutachter sie für belegt hält. Ersetzen Sie sie durch: "
  "<font face=\"Mono\">// UNBELEGT -- Platzhalter, siehe Sanierungshandbuch Kapitel B</font>. "
  "Das ist eine Zeile Arbeit und beseitigt eine Irreführung."),

 # ============================================================ KAPITEL C
 ("seitenumbruch", None),
 ("h2", "C · Reproduzierbarkeit und Audit-Fähigkeit"),
 ("etikett", "kritisch · Aufwand: 2 Tage"),

 ("h3", "Was falsch ist"),
 ("p", "Die Simulation zieht unbesamte Zufallszahlen. Dieselbe Eingabe liefert bei jedem "
       "Lauf ein anderes Ergebnis. Für eine Zahl, die ein Anwalt Jahre später gegenüber "
       "Mandant, Haftpflichtversicherer oder Gericht erklären muss, ist das disqualifizierend: "
       "Was sich nicht wiederherstellen lässt, ist kein Beleg."),

 ("h3", "Wie es genau gemacht wird"),
 ("p", "Zwei Bausteine: ein deterministischer Zufallsgenerator, und ein Ergebnis, das seine "
       "eigene Herkunft mitführt."),
 ("code", """/// SplitMix64 -- kompakt, schnell, vollständig deterministisch.
/// Gleicher Startwert bedeutet immer gleiche Zahlenfolge, auf jedem Gerät,
/// in jeder Swift-Version.
struct DeterministischerZufall: RandomNumberGenerator {
  private var zustand: UInt64
  init(startwert: UInt64) { self.zustand = startwert }

  mutating func next() -> UInt64 {
    zustand = zustand &+ 0x9E37_79B9_7F4A_7C15
    var z = zustand
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

/// Jedes Rechenergebnis führt mit, wie es entstanden ist.
struct Rechenbeleg<Ergebnis: Codable>: Codable {
  var ergebnis: Ergebnis
  var eingabenHash: String        // SHA256 über die kanonisch serialisierten Eingaben
  var startwert: UInt64          // damit ist der Zufall wiederholbar
  var kernVersion: String        // "2026.1" -- Formeln können sich ändern
  var berechnetAm: Date
  var berechnetVon: String

  /// Prüft, ob ein Beleg zu den heutigen Eingaben passt. Weicht der Hash ab,
  /// wurde am Fall etwas geändert und die Zahl ist veraltet -- die Oberfläche
  /// muss das anzeigen, statt eine alte Zahl weiter als gültig auszugeben.
  func giltNochFuer(eingabenHash aktuell: String) -> Bool {
    eingabenHash == aktuell
  }
}

enum Rechenkern {
  static let version = "2026.1"

  /// Startwert aus den Eingaben ableiten: gleiche Eingabe, gleiches Ergebnis --
  /// aber verschiedene Fälle bekommen verschiedene Zufallsfolgen.
  static func startwert(fuer hash: String) -> UInt64 {
    var wert: UInt64 = 0xCBF2_9CE4_8422_2325        // FNV-1a Offset
    for byte in hash.utf8 {
      wert = (wert ^ UInt64(byte)) &* 0x100_0000_01B3
    }
    return wert
  }

  static func hash<T: Encodable>(_ eingaben: T) throws -> String {
    let kodierer = JSONEncoder()
    kodierer.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    kodierer.dateEncodingStrategy = .iso8601
    let daten = try kodierer.encode(eingaben)
    return SHA256.hash(data: daten).map { String(format: "%02x", $0) }.joined()
  }
}"""),
 ("p", "Der Aufruf der Simulation ändert sich damit minimal, das Ergebnis aber grundlegend:"),
 ("code", """// vorher: nicht reproduzierbar
let ergebnis = AbschlussMonteCarloEngine.runMonteCarlo(inputs: eingaben)

// nachher: jede Zahl ist jederzeit exakt wiederherstellbar
let h = try Rechenkern.hash(eingaben)
var zufall = DeterministischerZufall(startwert: Rechenkern.startwert(fuer: h))
let ergebnis = AbschlussMonteCarloEngine.runMonteCarlo(inputs: eingaben, zufall: &zufall)
let beleg = Rechenbeleg(ergebnis: ergebnis, eingabenHash: h,
                        startwert: Rechenkern.startwert(fuer: h),
                        kernVersion: Rechenkern.version,
                        berechnetAm: Date(), berechnetVon: nutzer)"""),
 ("p", "In der Engine wird dazu jedes <font face=\"Mono\">Double.random(in:)</font> auf den "
       "übergebenen Generator umgestellt — eine mechanische Änderung:"),
 ("code", """// vorher
func randn() -> Double {
  let u = max(1e-10, 1 - Double.random(in: 0..<1))
  let v = Double.random(in: 0..<1)
  return sqrt(-2 * log(u)) * cos(2 * .pi * v)
}

// nachher: Generator wird durchgereicht
static func runMonteCarlo(inputs: AbschlussMonteCarloInputs,
                          zufall: inout DeterministischerZufall,
                          n: Int = 3000) -> AbschlussMonteCarloErgebnis {
  func randn(_ g: inout DeterministischerZufall) -> Double {
    let u = max(1e-10, 1 - Double.random(in: 0..<1, using: &g))
    let v = Double.random(in: 0..<1, using: &g)
    return sqrt(-2 * log(u)) * cos(2 * .pi * v)
  }
  ...
}"""),
 ("kasten_wichtig", "Warum das den Wert der App unmittelbar erhöht",
  "Ein Rechenbeleg ist genau das, was eine Haftpflichtversicherung und ein Käufer sehen "
  "wollen: Die Kanzlei kann jede jemals angezeigte Zahl auf Knopfdruck rekonstruieren, "
  "mit Eingabestand, Formelversion, Zeitpunkt und Bearbeiter. Zusammen mit der "
  "Herkunftsmarke und dem KI-Protokoll haben Sie damit eine <b>durchgehende Beweiskette "
  "von der Eingabe bis zur angezeigten Zahl</b>. Das ist ein Verkaufsargument, das kein "
  "Wettbewerber in dieser Klarheit hat — und es ist zwei Tage Arbeit."),

 # ============================================================ KAPITEL D
 ("seitenumbruch", None),
 ("h2", "D · RVG-Tabelle und Kostenrisiko korrekt rechnen"),
 ("etikett", "erheblich · Aufwand: 1 Tag"),

 ("h3", "Was falsch ist"),
 ("p", "Die Tabelle in <font face=\"Mono\">LegalAlgorithmsService.swift:35–41</font> ist im "
       "Code selbst als „vereinfacht\" bezeichnet. Die ersten sieben Werte entsprechen exakt "
       "der Anlage 2 zum RVG, danach läuft sie auseinander. Zusätzlich rechnet "
       "<font face=\"Mono\">computeKostenRisiko</font> mit "
       "<font face=\"Mono\">basisGebuehr * gebuehr * 2</font> — das vermischt Verfahrens- und "
       "Terminsgebühr mit der Kostenerstattung der Gegenseite und lässt Gerichtskosten, "
       "Auslagenpauschale und Umsatzsteuer weg."),

 ("h3", "Wie das Kostenrisiko wirklich zusammengesetzt ist"),
 ("p", "Verliert die Partei vollständig, trägt sie nach § 91 ZPO die eigenen und die "
       "gegnerischen Anwaltskosten sowie die Gerichtskosten. Vollständig sieht die Rechnung "
       "für die erste Instanz so aus:"),
 ("tabelle", ["Posten", "Ansatz", "Grundlage"], [
   ["Verfahrensgebühr", "1,3 × Gebühr nach Streitwert", "Nr. 3100 VV RVG"],
   ["Terminsgebühr", "1,2 × Gebühr", "Nr. 3104 VV RVG"],
   ["Einigungsgebühr (nur bei Vergleich)", "1,0 × Gebühr", "Nr. 1003 VV RVG"],
   ["Auslagenpauschale", "20 % der Gebühren, höchstens 20 €", "Nr. 7002 VV RVG"],
   ["Umsatzsteuer", "19 % auf Gebühren und Auslagen", "Nr. 7008 VV RVG"],
   ["Gerichtskosten erste Instanz", "3,0 × Gebühr nach Anlage 2 GKG", "KV 1210 GKG"],
   ["Kosten der Gegenseite", "bei Unterliegen in gleicher Höhe", "§ 91 ZPO"],
 ]),
 ("p", "Daraus wird eine Rechnung, die man einem Mandanten zeigen kann:"),
 ("code", """/// Vollständige Gebührentabelle Anlage 2 RVG.
/// PFLICHT: Diese Werte vor Auslieferung gegen den Gesetzestext prüfen und
/// den Golden-Test aus Kapitel J laufen lassen. Bei jeder RVG-Änderung
/// (letzte größere Anpassung durch das KostRÄG) Tabelle und Test aktualisieren.
enum RVG {
  static let stand = "Anlage 2 RVG, Fassung KostRÄG 2021"

  /// (Streitwert bis einschließlich, einfache Gebühr in Euro)
  static let tabelle: [(bis: Double, gebuehr: Double)] = [
    (500, 49), (1_000, 88), (1_500, 127), (2_000, 166), (3_000, 222),
    (4_000, 278), (5_000, 334), (6_000, 390), (7_000, 446), (8_000, 502),
    (9_000, 558), (10_000, 614), (13_000, 666), (16_000, 718), (19_000, 770),
    (22_000, 822), (25_000, 874), (30_000, 955), (35_000, 1_036), (40_000, 1_117),
    (45_000, 1_198), (50_000, 1_279), (65_000, 1_373), (80_000, 1_467),
    (95_000, 1_561), (110_000, 1_655), (125_000, 1_749), (140_000, 1_843),
    (155_000, 1_937), (170_000, 2_031), (185_000, 2_125), (200_000, 2_219),
    (230_000, 2_351), (260_000, 2_483), (290_000, 2_615), (320_000, 2_747),
    (350_000, 2_879), (380_000, 3_011), (410_000, 3_143), (440_000, 3_275),
    (470_000, 3_407), (500_000, 3_539)
  ]

  /// Einfache Gebühr. Oberhalb von 500.000 € gilt § 13 Abs. 1 Satz 3 RVG:
  /// je weitere 50.000 € erhöht sich die Gebühr -- Betrag im Gesetz prüfen.
  static func gebuehr(streitwert: Double) -> Double? {
    if let stufe = tabelle.first(where: { streitwert <= $0.bis }) { return stufe.gebuehr }
    return nil      // bewusst nil: lieber keine Zahl als eine falsche
  }
}

struct Kostenrisiko {
  var eigeneAnwaltskosten: Double
  var gegnerAnwaltskosten: Double
  var gerichtskosten: Double
  var umsatzsteuerSatz: Double

  var gesamtkostenBeiNiederlage: Double {
    eigeneAnwaltskosten + gegnerAnwaltskosten + gerichtskosten
  }
  /// Bei vollem Sieg trägt der Gegner die Kosten -- Risiko bleibt das
  /// Beitreibungsrisiko, nicht die Gebühr.
  var eigeneKostenBeiSieg: Double { 0 }

  /// Erste Instanz, Zivilprozess, ohne Vergleich.
  static func erstinstanz(streitwert: Double, ustSatz: Double = 0.19,
                          gerichtsgebuehr: Double) -> Kostenrisiko? {
    guard let g = RVG.gebuehr(streitwert: streitwert) else { return nil }
    let verfahren = g * 1.3                       // Nr. 3100 VV RVG
    let termin    = g * 1.2                       // Nr. 3104 VV RVG
    let auslagen  = min((verfahren + termin) * 0.20, 20)   // Nr. 7002 VV RVG
    let netto     = verfahren + termin + auslagen
    let brutto    = netto * (1 + ustSatz)         // Nr. 7008 VV RVG
    return .init(eigeneAnwaltskosten: brutto,
                 gegnerAnwaltskosten: brutto,    // § 91 ZPO
                 gerichtskosten: gerichtsgebuehr * 3.0,   // KV 1210 GKG
                 umsatzsteuerSatz: ustSatz)
  }
}"""),
 ("kasten_achtung", "Zwei Dinge, die Sie selbst prüfen müssen",
  "<b>Erstens:</b> Ich habe die Tabellenwerte aus dem Gedächtnis rekonstruiert und konnte sie "
  "im Prüfcontainer nicht gegen den Gesetzestext abgleichen. Dass die ersten sieben Werte "
  "des vorhandenen Codes exakt passen und die späteren abweichen, ist ein belastbares "
  "Muster — die konkreten Beträge oben gehören aber vor der Auslieferung Zeile für Zeile "
  "gegen die Anlage 2 RVG geprüft. Der Golden-Test aus Kapitel J macht das zu einer "
  "Einmalarbeit.<br/>"
  "<b>Zweitens:</b> Über 500.000 € Streitwert greift die Fortschreibungsregel des § 13 RVG; "
  "die Gerichtsgebühr nach Anlage 2 GKG ist eine eigene Tabelle, die Sie ebenso vollständig "
  "hinterlegen müssen. Die Funktion gibt bewusst <font face=\"Mono\">nil</font> zurück, statt "
  "zu schätzen — eine fehlende Zahl ist ehrlich, eine falsche ist ein Beratungsfehler."),

 # ============================================================ KAPITEL E
 ("seitenumbruch", None),
 ("h2", "E · Passwörter richtig schützen"),
 ("etikett", "erheblich · Aufwand: 1 Tag inklusive Migration"),

 ("h3", "Was falsch ist"),
 ("p", "In <font face=\"Mono\">KontoSystem.swift:641–644</font>:"),
 ("code", """private static func hash(passwort: String, salt: String) -> String {
  let digest = SHA256.hash(data: Data((salt + passwort).utf8))
  return digest.map { String(format: "%02x", $0) }.joined()
}"""),
 ("p", "Der Salt ist richtig, das Verfahren ist falsch. SHA-256 ist auf Geschwindigkeit "
       "ausgelegt — genau das falsche Eigenschaftsprofil für Passwörter. Auf handelsüblicher "
       "Grafikhardware sind damit Milliarden Versuche pro Sekunde möglich. Ein Passwort-Hash "
       "braucht einen einstellbaren Arbeitsfaktor, der das Durchprobieren teuer macht."),

 ("h3", "Der beste Weg: gar keine Passwortdatenbank"),
 ("p", "Die Daten liegen ohnehin lokal auf dem Mac. Damit ist die naheliegendste Lösung, die "
       "Anmeldung dem Betriebssystem zu überlassen: Touch ID oder Systempasswort über "
       "<font face=\"Mono\">LocalAuthentication</font>, und die Kontodaten im Schlüsselbund. "
       "Das entfernt die Angriffsfläche vollständig, statt sie zu härten, und ist für "
       "Einzelanwälte und kleine Einheiten die bessere Bedienung:"),
 ("code", """import LocalAuthentication

enum GeraeteAnmeldung {
  /// Anmeldung über Touch ID oder Systempasswort. Kein Passwort-Hash nötig.
  static func anmelden(grund: String = "Zugriff auf Mandantendaten") async throws {
    let kontext = LAContext()
    kontext.localizedFallbackTitle = "Systempasswort verwenden"
    var fehler: NSError?
    guard kontext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &fehler) else {
      throw fehler ?? NSError(domain: "Anmeldung", code: -1)
    }
    try await kontext.evaluatePolicy(.deviceOwnerAuthentication,
                                     localizedReason: grund)
  }
}"""),
 ("h3", "Wenn eigene Konten nötig bleiben: PBKDF2 mit Migration"),
 ("p", "Für den Mehrbenutzerbetrieb mit eigener Kontoverwaltung brauchen Sie ein echtes "
       "Passwortverfahren. Da das Projekt keine externen Abhängigkeiten hat und CryptoKit "
       "keine Passwort-Ableitung mitbringt, ist PBKDF2-HMAC-SHA256 über CommonCrypto der "
       "Weg ohne neue Abhängigkeit. Entscheidend ist die Iterationszahl: Die "
       "OWASP-Empfehlung für PBKDF2-HMAC-SHA256 liegt bei mindestens 600.000 — bitte "
       "aktuellen Stand nachsehen, die Zahl steigt mit der Hardware."),
 ("code", """import CommonCrypto

enum PasswortSchutz {
  static let aktuellesVerfahren = "pbkdf2-sha256"
  static let aktuelleIterationen = 600_000        // OWASP-Stand prüfen

  static func ableiten(passwort: String, salt: Data,
                       iterationen: Int = aktuelleIterationen) -> Data {
    var ergebnis = Data(count: 32)
    let passwortBytes = Array(passwort.utf8)
    _ = ergebnis.withUnsafeMutableBytes { ziel in
      salt.withUnsafeBytes { saltZeiger in
        CCKeyDerivationPBKDF(
          CCPBKDFAlgorithm(kCCPBKDF2),
          passwortBytes.map { Int8(bitPattern: $0) }, passwortBytes.count,
          saltZeiger.bindMemory(to: UInt8.self).baseAddress, salt.count,
          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
          UInt32(iterationen),
          ziel.bindMemory(to: UInt8.self).baseAddress, 32)
      }
    }
    return ergebnis
  }

  /// Zeitkonstanter Vergleich -- verhindert, dass die Vergleichsdauer
  /// Rückschlüsse auf das Passwort erlaubt.
  static func gleich(_ a: Data, _ b: Data) -> Bool {
    guard a.count == b.count else { return false }
    var unterschied: UInt8 = 0
    for (x, y) in zip(a, b) { unterschied |= x ^ y }
    return unterschied == 0
  }
}"""),
 ("p", "Bestehende Konten dürfen dabei nicht ausgesperrt werden. Das Konto merkt sich, mit "
       "welchem Verfahren sein Hash entstanden ist, und wird bei der nächsten erfolgreichen "
       "Anmeldung stillschweigend hochgezogen:"),
 ("code", """struct Konto {
  // ... bestehende Felder ...
  var passwortHash: String
  var salt: String
  var verfahren: String = "sha256-legacy"     // neu, mit Standard für Altbestand
  var iterationen: Int = 0                     // neu
}

extension KontoStore {
  /// Prüft das Passwort und hebt Altbestände auf das aktuelle Verfahren.
  func pruefeUndMigriere(konto: inout Konto, passwort: String) -> Bool {
    switch konto.verfahren {
    case "sha256-legacy":
      let alt = SHA256.hash(data: Data((konto.salt + passwort).utf8))
        .map { String(format: "%02x", $0) }.joined()
      guard alt == konto.passwortHash else { return false }
      // Passwort stimmt -> sofort auf PBKDF2 umstellen
      let neuerSalt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
      konto.salt = neuerSalt.base64EncodedString()
      konto.passwortHash = PasswortSchutz
        .ableiten(passwort: passwort, salt: neuerSalt).base64EncodedString()
      konto.verfahren = PasswortSchutz.aktuellesVerfahren
      konto.iterationen = PasswortSchutz.aktuelleIterationen
      speichern()
      return true

    case "pbkdf2-sha256":
      guard let salt = Data(base64Encoded: konto.salt),
            let erwartet = Data(base64Encoded: konto.passwortHash) else { return false }
      let berechnet = PasswortSchutz.ableiten(passwort: passwort, salt: salt,
                                              iterationen: konto.iterationen)
      return PasswortSchutz.gleich(berechnet, erwartet)

    default:
      return false
    }
  }
}"""),
 ("kasten_wichtig", "Drei Kleinigkeiten, die dazugehören",
  "<b>Salt als Zufallsbytes, nicht als Zeichenkette.</b> Der vorhandene "
  "<font face=\"Mono\">neuerSalt()</font> erzeugt einen String; nehmen Sie 16 echte "
  "Zufallsbytes.<br/>"
  "<b>Anmeldeversuche begrenzen.</b> Nach fünf Fehlversuchen eine wachsende Wartezeit — sonst "
  "hilft der beste Hash nichts gegen Ausprobieren an der laufenden App.<br/>"
  "<b>Die Datenbank selbst verschlüsseln.</b> Der Passwortschutz nützt wenig, wenn die "
  "JSON-Dateien daneben unverschlüsselt liegen. FileVault ist Pflicht in der Anleitung; "
  "besser ist ein eigener Schlüssel im Schlüsselbund, mit dem die Falldateien verschlüsselt "
  "werden. Für Mandantengeheimnisse ist das der eigentliche Schutz."),
]
