# -*- coding: utf-8 -*-
"""Bauplan Teil 1: Einordnung + vollständiger Zahlen-Katalog."""

B1 = [
 ("h1", "Bauplan"),
 ("untertitel", "Jede willkürliche Zahl im Programm — ersetzt durch ein eigenes, "
                "belegbares Verfahren. Und die Stellen, an denen echte Überlegenheit "
                "entsteht statt nur Gleichstand."),
 ("meta", [
   ("Prüfgegenstand", "Snapshot Fenlynine-11.08.26-R1 · 225 Dateien · 85.146 Zeilen"),
   ("Gefundene Zahlen", "24 willkürliche Konstanten in 6 Dateien · 3 davon sind echte Rechenfehler"),
   ("Aufbau", "Teil 0 Einordnung · Teil 1 Zahlenkatalog · Teil 2 Quellen · "
              "Teil 3 Überlegenheit · Teil 4 Burggraben · Teil 5 Grenzen"),
   ("Erstellt", "17. August 2026"),
 ]),

 # ============================================================ TEIL 0
 ("h2", "Teil 0 — Was ein Unicorn wirklich macht"),
 ("p", "Sie haben nach einem Programm gefragt, das eine Firma theoretisch zum Unicorn "
       "machen kann. Diese Frage verdient eine ehrliche Antwort, bevor ich dreißig Seiten "
       "Technik liefere."),
 ("p", "Milliardenbewertungen entstehen nicht aus Funktionsumfang. Sie entstehen aus drei "
       "Dingen: einem hinreichend großen Markt, einem Vertriebsweg, der skaliert, und einem "
       "Burggraben, der mit jedem Kunden breiter wird. Funktionen sind kopierbar — ein "
       "Wettbewerber mit dreißig Entwicklern baut jedes einzelne Feature dieser App in einem "
       "Jahr nach. Burggräben sind es nicht."),
 ("p", "Für Ihr Produkt heißt das konkret: Der deutsche Anwaltsmarkt mit rund 165.000 "
       "Zugelassenen trägt bei realistischen Preisen ein Unternehmen im niedrigen "
       "zweistelligen Millionenbereich — ein sehr gutes Geschäft, aber kein Unicorn. "
       "Der Weg darüber hinaus führt über drei Mechanismen, und jeder davon ist eine "
       "Produktentscheidung, die Sie heute im Code treffen:"),
 ("nummerierte_liste", [
   ("Datenrückkopplung als Burggraben",
    "Jeder abgeschlossene Fall, dessen Ausgang zurückfließt, verbessert die Kalibrierung "
    "für alle. Nach 10.000 Fällen hat niemand sonst diesen Datensatz, und er lässt sich "
    "nicht kaufen. Das ist der einzige Mechanismus in diesem Markt, der mit der Zeit "
    "stärker wird statt schwächer. Kapitel 1.1 und 1.6 bauen genau diese Rückkopplung — "
    "sie sind deshalb die wichtigsten des ganzen Dokuments."),
   ("Nachweisbarkeit als horizontales Produkt",
    "Die Herkunftsmarke plus Rechenbeleg plus Protokollkette ist keine Anwaltsfunktion. "
    "Sie ist die Antwort auf die Frage „welche Zahl kam wie zustande\", und diese Frage "
    "stellt sich jedem regulierten Beruf: Wirtschaftsprüfern, Steuerberatern, Aktuaren, "
    "Ärzten, Ingenieuren in der Zulassung. Ein Anwaltsprodukt hat einen Markt von 165.000. "
    "Eine Nachweis-Engine für regulierte Entscheidungen hat einen Markt in Millionenhöhe."),
   ("Regulierung als Vertriebsweg",
    "Die KI-Verordnung zwingt jede Kanzlei, die KI einsetzt, zu Transparenz und "
    "Protokollierung. Wer als Erster ein Produkt hat, das diesen Nachweis nicht nachrüstet, "
    "sondern strukturell erbringt, verkauft nicht ein Werkzeug, sondern die Erfüllung "
    "einer Pflicht. Das ist der stärkste Vertriebshebel in regulierten Märkten."),
 ]),
 ("kasten_wichtig", "Der Satz, an dem sich alles entscheidet",
  "Alle drei Mechanismen hängen an derselben technischen Grundlage: <b>Jede Zahl im "
  "Programm muss wissen, woher sie kommt.</b> Solange Konstanten wie 1,6 oder 0,88 im Code "
  "stehen, ist keiner der drei Wege gangbar — es gibt nichts zu kalibrieren, nichts "
  "nachzuweisen und nichts zu belegen. Deshalb ist der Zahlenkatalog in Teil 1 kein "
  "Aufräumen, sondern die Voraussetzung für alles Weitere."),

 # ============================================================ TEIL 1
 ("seitenumbruch", None),
 ("h1", "Teil 1 — Der vollständige Zahlenkatalog"),
 ("p", "Ich habe den Code systematisch nach Konstanten durchsucht, die eine fachliche "
       "Aussage treffen. Ergebnis: 24 Stellen. Drei davon sind keine Willkür, sondern "
       "handfeste Rechenfehler — sie stehen zuerst."),
 ("befund_tabelle", [
   ("1.1", "Zwei verschiedene RVG-Tabellen im selben Programm", "kritisch",
    "Bei 10.000 € Streitwert: 590 € oder 964 €, je nachdem welcher Bildschirm rechnet. "
    "Anlage 2 RVG sagt 614 €.", "Kapitel 1.1"),
   ("1.2", "Auslagenpauschale mit umgekehrter Formel", "kritisch",
    "Code rechnet 20 € plus 3 %. Nr. 7002 VV RVG sagt 20 % gedeckelt auf 20 €. "
    "Faktor 4,6 zu hoch.", "Kapitel 1.2"),
   ("1.3", "Verjährung ohne Jahresschluss-Regel", "kritisch",
    "Code rechnet Entstehung plus 3 Jahre. § 199 BGB beginnt erst mit Schluss des Jahres. "
    "Bis zu 12 Monate zu früh.", "Kapitel 1.3"),
   ("1.4", "Basisquoten je Rechtsgebiet", "erfunden",
    "0,52 / 0,54 / 0,35 — ohne Quelle, ohne Datensatz.", "Kapitel 1.4"),
   ("1.5", "Instanzfaktor 0,88 / 0,70", "erfunden",
    "Mit einem Kommentar, der eine Empirie behauptet.", "Kapitel 1.5"),
   ("1.6", "Log-Odds-Gewichte 1,6 / 1,2 / 0,3 / 0,4", "erfunden",
    "Die Koeffizienten des Prognosemodells — frei gesetzt.", "Kapitel 1.6"),
   ("1.7", "Fristen-Malus 0,4 und 0,15", "falsch modelliert",
    "Eine versäumte Notfrist ist kein Abschlag, sondern ein Zustandswechsel.", "Kapitel 1.7"),
   ("1.8", "Monte-Carlo-Streuungen 5,0 / 8,0 / 18,0", "erfunden",
    "Und zugleich 400-mal langsamer als nötig.", "Kapitel 1.8"),
   ("1.9", "Macht-Einfluss-Engine: 14 Konstanten", "erfunden",
    "0,6 / 0,4 / 0,28 / 0,35 / 0,7 — ein komplettes Modell aus Setzungen.", "Kapitel 1.9"),
   ("1.10", "Klumpenrisiko 8 % je Gruppe", "erfunden",
    "Portfoliokorrelation als Pauschale statt als Rechnung.", "Kapitel 1.10"),
   ("1.11", "Vergleichsanker bei 70 % der Spanne", "erfunden",
    "Ignoriert die einzige Zahl, die den Anker bestimmt: die BATNA.", "Kapitel 1.11"),
 ]),

 # ---------------------------------------------------------- 1.1
 ("seitenumbruch", None),
 ("h2", "1.1 · Zwei RVG-Tabellen, drei verschiedene Wahrheiten"),
 ("etikett", "kritisch · Rechenfehler · Aufwand: 4 Stunden"),
 ("h3", "Was im Code steht"),
 ("p", "Das Programm enthält zwei voneinander unabhängige Gebührentabellen, die einander "
       "widersprechen:"),
 ("code", """// Sources/FenlynineOS/Core/Services/LegalAlgorithmsService.swift:36
static let rvgTabelle: [(maxStreitwert: Double, basisGebuehr: Double)] = [
  (500, 49), (1000, 88), ... (13000, 590), (19000, 758), (25000, 986), ...
]

// Sources/FenlynineOS/Features/Vorgang/VorgangMotor.swift:263
switch sw {
case ..<2_000:   einfach = 149
case ..<5_000:   einfach = 334
case ..<10_000:  einfach = 614
case ..<25_000:  einfach = 964
case ..<50_000:  einfach = 1_534
...
}"""),
 ("tabelle", ["Streitwert", "LegalAlgorithms", "VorgangMotor", "Anlage 2 RVG"], [
   ["10.000 €", "590 €", "964 €", "614 €"],
   ["20.000 €", "986 €", "964 €", "822 €"],
   ["50.000 €", "1.474 €", "2.197 €", "1.279 €"],
 ]),
 ("p", "Bei 10.000 € Streitwert weichen die beiden Bildschirme um 63 Prozent voneinander ab. "
       "Beide liegen falsch. Zusätzlich greift in "
       "<font face=\"Mono\">LegalAlgorithmsService:603</font> bei Überschreitung der Tabelle "
       "ein Notwert von <font face=\"Mono\">?? 5000</font> — eine frei erfundene Gebühr."),
 ("h3", "Wie es gemacht wird"),
 ("p", "Eine einzige Quelle der Wahrheit, in einem eigenen Modul, mit Prüfsumme über die "
       "Tabelle. Kein Aufrufer rechnet mehr selbst:"),
 ("code", """/// Gebührentabelle Anlage 2 RVG -- die EINZIGE Stelle im Programm,
/// an der Gebührenbeträge stehen. Jeder andere Ort ruft hier auf.
public enum RVGTabelle {
  public static let fassung = "Anlage 2 RVG, Stand KostRÄG"
  public static let geprueftAm = "2026-08-17"

  /// Prüfsumme über die Tabelle. Ändert jemand einen Wert, ohne den
  /// Golden-Test anzupassen, schlägt der Test fehl -- nicht der Kunde.
  public static let pruefsumme = "sha256:…"

  static let stufen: [(bis: Decimal, gebuehr: Decimal)] = [
    (500, 49), (1_000, 88), (1_500, 127), (2_000, 166), (3_000, 222),
    (4_000, 278), (5_000, 334), (6_000, 390), (7_000, 446), (8_000, 502),
    (9_000, 558), (10_000, 614), (13_000, 666), (16_000, 718), (19_000, 770),
    (22_000, 822), (25_000, 874), (30_000, 955), (35_000, 1_036),
    (40_000, 1_117), (45_000, 1_198), (50_000, 1_279), (65_000, 1_373),
    (80_000, 1_467), (95_000, 1_561), (110_000, 1_655), (125_000, 1_749),
    (140_000, 1_843), (155_000, 1_937), (170_000, 2_031), (185_000, 2_125),
    (200_000, 2_219), (230_000, 2_351), (260_000, 2_483), (290_000, 2_615),
    (320_000, 2_747), (350_000, 2_879), (380_000, 3_011), (410_000, 3_143),
    (440_000, 3_275), (470_000, 3_407), (500_000, 3_539)
  ]

  /// Decimal statt Double: Geldbeträge dürfen nicht runden-driften.
  /// Gibt nil zurück statt zu schätzen -- eine fehlende Zahl ist ehrlich,
  /// eine erfundene ist ein Beratungsfehler.
  public static func gebuehr(streitwert: Decimal) -> Decimal? {
    guard streitwert > 0 else { return nil }
    if let stufe = stufen.first(where: { streitwert <= $0.bis }) { return stufe.gebuehr }
    return fortschreibung(streitwert: streitwert)   // § 13 Abs. 1 S. 3 RVG
  }
}"""),
 ("kasten_achtung", "Decimal statt Double — bei Geld kein Stilfrage",
  "Der bestehende Code rechnet mit <font face=\"Mono\">Double</font>. "
  "0,1 + 0,2 ergibt dort 0,30000000000000004. Bei einer Kostennote summieren sich solche "
  "Abweichungen, und spätestens wenn ein Mandant nachrechnet, steht die Kanzlei dumm da. "
  "<font face=\"Mono\">Decimal</font> rechnet dezimal exakt. Das ist eine der wenigen "
  "Stellen, an denen Sie ohne Nachdenken den Typ wechseln sollten."),

 # ---------------------------------------------------------- 1.2
 ("h2", "1.2 · Die Auslagenpauschale steht auf dem Kopf"),
 ("etikett", "kritisch · Rechenfehler · Aufwand: 10 Minuten"),
 ("code", """// Sources/FenlynineOS/Features/Vorgang/VorgangMotor.swift:278
let auslagen = 20.0 + (verfahren + termin) * 0.03"""),
 ("p", "Nr. 7002 VV RVG bestimmt: 20 Prozent der Gebühren, <b>höchstens 20 Euro</b>. Der Code "
       "macht daraus 20 Euro als Untergrenze plus drei Prozent — also aus einem Deckel einen "
       "Boden. Bei 10.000 € Streitwert ergibt das 92,30 € statt 20 €, das 4,6-fache."),
 ("code", """/// Nr. 7002 VV RVG: 20 % der Gebühren, gedeckelt auf 20 €.
/// In der Praxis ist das Ergebnis fast immer genau 20 € -- der Deckel greift
/// bereits ab 100 € Gebühren.
static func auslagenpauschale(gebuehren: Decimal) -> Decimal {
  min(gebuehren * Decimal(string: "0.20")!, 20)
}"""),

 # ---------------------------------------------------------- 1.3
 ("h2", "1.3 · Verjährung beginnt nicht am Tag des Anspruchs"),
 ("etikett", "kritisch · Rechenfehler · Aufwand: 30 Minuten"),
 ("code", """// Sources/FenlynineOS/Features/Vorgang/VorgangMotor.swift:299
let datum = Calendar.current.date(byAdding: .year, value: 3, to: entstehung)"""),
 ("p", "§ 199 Abs. 1 BGB: Die Regelverjährung beginnt <b>mit dem Schluss des Jahres</b>, in "
       "dem der Anspruch entstanden ist und der Gläubiger Kenntnis erlangt hat. Für einen "
       "Anspruch vom 15. März 2024 endet die Verjährung also am 31. Dezember 2027 — der Code "
       "sagt 15. März 2027, neuneinhalb Monate zu früh."),
 ("p", "Die Fehlerrichtung ist zwar die vorsichtige, aber falsch bleibt falsch: Der Anwalt "
       "verhandelt mit einem Druckmittel, das er noch neun Monate länger gehabt hätte, oder "
       "klagt unnötig früh."),
 ("code", """/// § 199 Abs. 1 BGB -- Beginn erst mit Schluss des Jahres der Entstehung
/// und Kenntnis. Anschließend § 193 BGB (Kapitel A des Sanierungshandbuchs).
static func regelverjaehrung(entstehung: Date, kenntnis: Date? = nil,
                             land: Bundesland) -> Fristherleitung {
  let kal = Feiertagskalender.kalender
  // Maßgeblich ist der spätere der beiden Zeitpunkte.
  let ausloeser = max(entstehung, kenntnis ?? entstehung)
  let jahr = kal.component(.year, from: ausloeser)
  let jahresschluss = Feiertagskalender.tag(jahr, 12, 31)

  return FristenRechner.berechne(
    ereignis: jahresschluss,
    ereignisBezeichnung: "Schluss des Jahres der Entstehung und Kenntnis",
    definition: .init(laenge: 3, einheit: .jahre, anfang: .ereignis,
                      norm: "§§ 195, 199 Abs. 1 BGB",
                      istNotfrist: false, verlaengerbar: false,
                      hinweis: "Höchstfristen des § 199 Abs. 2-4 BGB gesondert prüfen."),
    land: land)
}"""),
 ("kasten_achtung", "Was hier zusätzlich fehlt",
  "§ 199 Abs. 2 bis 4 BGB kennt Höchstfristen, die unabhängig von der Kenntnis laufen — "
  "zehn Jahre ab Entstehung, dreißig Jahre bei Verletzung von Leben, Körper, Gesundheit "
  "oder Freiheit. Eine Verjährungsberechnung, die diese Grenzen nicht mitführt, ist "
  "unvollständig. Bauen Sie beide Fristen und zeigen Sie die früher endende an, mit einem "
  "Hinweis darauf, welche greift."),

 # ---------------------------------------------------------- 1.4
 ("seitenumbruch", None),
 ("h2", "1.4 · Basisquoten je Rechtsgebiet"),
 ("etikett", "erfunden · Aufwand: 2 Tage Umbau, dann laufend"),
 ("code", """// LegalAlgorithmsService.swift:22
"Arbeitsrecht": 0.52,  "Mietrecht": 0.54,  "Vertragsrecht": 0.51,
"Strafrecht": 0.35,    // Staatsanwaltschaft hat strukturellen Vorteil"""),
 ("h3", "Warum es keine bessere Quelle gibt"),
 ("p", "Eine öffentliche Statistik der Klägererfolgsquoten nach Rechtsgebiet existiert in "
       "Deutschland nicht. Die amtliche Zivilgerichtsstatistik erhebt Erledigungsarten, "
       "nicht Sieger. Wer diese Zahlen ersetzen will, muss sie selbst erzeugen."),
 ("h3", "Das Verfahren: Beta-Bayes mit Schrumpfung"),
 ("p", "Sie brauchen kein neuronales Netz. Für eine Erfolgsquote ist die Beta-Verteilung die "
       "mathematisch richtige Antwort — sie ist das konjugierte Prior zur Binomialverteilung, "
       "aktualisiert sich mit einer Zeile Code und liefert von sich aus ein Unsicherheits"
       "intervall. Entscheidend ist die Schrumpfung: Bei drei Fällen im Baurecht darf die "
       "Anzeige nicht „67 %\" lauten, sondern muss zum neutralen Wert hin gezogen werden."),
 ("code", """/// Erfolgsquote als Beta-Verteilung. Zwei Zahlen genügen -- und sie
/// tragen ihre eigene Unsicherheit mit sich.
public struct Erfolgsquote {
  var alpha: Double      // Erfolge + Prior
  var beta: Double       // Misserfolge + Prior

  /// Jeffreys-Prior (0,5 / 0,5): der übliche uninformative Startpunkt für
  /// Anteilswerte. Bei null Fällen ergibt sich exakt 50 % mit maximaler Streuung.
  public static func neu() -> Erfolgsquote { .init(alpha: 0.5, beta: 0.5) }

  public mutating func beobachte(erfolg: Double) {      // 0…1, Vergleich = 0,5
    alpha += erfolg
    beta  += (1 - erfolg)
  }

  public var erwartungswert: Double { alpha / (alpha + beta) }
  public var fallzahl: Double { alpha + beta - 1 }

  /// Standardabweichung der Beta-Verteilung -- die ehrliche Fehlerangabe.
  public var streuung: Double {
    let n = alpha + beta
    return (alpha * beta / (n * n * (n + 1))).squareRoot()
  }

  /// Anzeige nur, wenn die Streuung klein genug ist. Faustregel: erst wenn
  /// das Intervall schmaler als 20 Punkte ist, ist die Zahl eine Aussage.
  public var darfAngezeigtWerden: Bool { streuung < 0.05 }

  /// Klartext statt Scheingenauigkeit -- immer mit Grundgesamtheit.
  public var text: String {
    guard darfAngezeigtWerden else {
      return "Noch zu wenige eigene Fälle (\\(Int(fallzahl))) für eine belastbare Quote."
    }
    let p = Int((erwartungswert * 100).rounded() / 5) * 5      // Stufen zu 5
    let s = Int((streuung * 200).rounded())
    return "\\(p) % ± \\(s) Punkte, aus \\(Int(fallzahl)) eigenen Verfahren."
  }
}"""),
 ("kasten_wichtig", "Warum diese fünfzehn Zeilen mehr wert sind als das ganze bisherige Modell",
  "Sie liefern eine Zahl, die (1) aus echten Daten stammt, (2) ihre eigene Unsicherheit "
  "kennt, (3) sich weigert zu sprechen, solange sie nichts weiß, und (4) mit jedem "
  "abgeschlossenen Fall besser wird. Das ist der Kern der Datenrückkopplung aus Teil 0 — "
  "und es ist weniger Code als die erfundene Tabelle, die sie ersetzt."),

 # ---------------------------------------------------------- 1.5
 ("h2", "1.5 · Instanzfaktor"),
 ("etikett", "erfunden · aber hier gibt es eine echte Quelle"),
 ("code", """// LegalAlgorithmsService.swift:16
.berufung: 0.88,   // Berufungsgerichte bestätigen i.d.R. ~70-75% Urteile
.revision: 0.70"""),
 ("p", "Das ist die einzige der erfundenen Zahlen, für die eine amtliche Quelle wirklich "
       "existiert. Das Statistische Bundesamt erhebt in der Zivilgerichtsstatistik die "
       "Erledigung von Berufungen, aufgeschlüsselt nach Zurückweisung, Abänderung, "
       "Zurücknahme und Vergleich. Aus dem Verhältnis von Abänderung zu Zurückweisung "
       "ergibt sich ein belegbarer Faktor."),
 ("h3", "Das Verfahren"),
 ("p", "Nicht als Konstante in den Code, sondern als versionierte Datei mit Fundstelle. "
       "So wird die jährliche Aktualisierung zum Dateitausch statt zur Codeänderung — "
       "und jede Zahl trägt ihre Herkunft mit:"),
 ("code", """{
  "quelle": "Statistisches Bundesamt, Fachserie 10 Reihe 2.1 (Zivilgerichte)",
  "berichtsjahr": 2024,
  "abgerufen_am": "2026-08-17",
  "abgerufen_von": "https://www.destatis.de",
  "fundstelle": "Tabelle: Erledigung der Berufungen vor den Oberlandesgerichten",
  "werte": {
    "berufungen_erledigt_gesamt": null,
    "davon_zurueckgewiesen": null,
    "davon_abgeaendert": null,
    "davon_zurueckgenommen": null
  },
  "abgeleitet": {
    "aenderungsquote": null,
    "hinweis": "Aenderungsquote = abgeaendert / (abgeaendert + zurueckgewiesen). Erst
                nach Eintragen der Originalwerte berechnen -- nicht schaetzen."
  }
}"""),
 ("p", "Die Felder stehen bewusst auf <font face=\"Mono\">null</font>. Tragen Sie die Werte "
       "aus der Originaltabelle ein; eine Zahl, die niemand nachgeschlagen hat, gehört nicht "
       "in dieses Programm."),
]
