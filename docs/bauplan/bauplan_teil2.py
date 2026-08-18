# -*- coding: utf-8 -*-
"""Bauplan Teil 2: Kapitel 1.6-1.11, Quellenverzeichnis, Überlegenheit, Burggraben, Grenzen."""

B2 = [
 # ---------------------------------------------------------- 1.6
 ("seitenumbruch", None),
 ("h2", "1.6 · Die Gewichte des Prognosemodells"),
 ("etikett", "erfunden · das Herzstück · Aufwand: 4 Tage"),
 ("h3", "Die gute Nachricht zuerst"),
 ("p", "Das Modell addiert Beiträge auf einer Log-Odds-Skala. Das ist mathematisch exakt "
       "eine logistische Regression — die <b>Struktur ist richtig</b>. Nur die Koeffizienten "
       "sind gesetzt statt gelernt:"),
 ("code", """// LegalAlgorithmsService.swift:214, 229, 252, 285
let argLogOddsDelta   = argDelta * 1.6
let beweisQualitaet   = (avgBeweis - 0.5) * 1.2 + log(n+1)/log(20) * 0.3
let richterLogOddsDelta = richterDelta * 0.4
let fristenPenalty    = -(versaeumt * 0.4 + kritisch * 0.15)"""),
 ("p", "Sie müssen also nichts neu erfinden. Sie müssen den Zahlen beibringen, woher sie "
       "kommen. Dafür gibt es zwei Wege, und ich empfehle beide gleichzeitig."),

 ("h3", "Weg 1 — Bayes-Faktoren: die Frage so stellen, dass ein Anwalt sie beantworten kann"),
 ("p", "Ein Anwalt kann nicht sagen, ob ein Argument „1,6 Log-Odds\" wert ist. Diese Frage "
       "ist unbeantwortbar, und genau deshalb steht dort eine erfundene Zahl. Er kann aber "
       "sehr wohl sagen: <i>„Dieses Urteil des BGH verdoppelt unsere Chancen ungefähr.\"</i> "
       "Und das ist keine Umgangssprache, sondern exakt ein Bayes-Faktor — eine Zahl, die "
       "sich auf der Odds-Skala multiplikativ verhält."),
 ("p", "Damit verschwindet die Willkür nicht nur, sie wird durch etwas <b>Besseres</b> "
       "ersetzt: durch eine Größe, die der Fachmann direkt einschätzen kann, die "
       "mathematisch sauber in das bestehende Modell passt und die sich später gegen echte "
       "Ausgänge prüfen lässt."),
 ("code", """/// Ein Beitrag zur Prognose -- vom Anwalt in einer Sprache angegeben,
/// die er tatsächlich beherrscht.
public struct Beitrag: Codable, Identifiable {
  public enum Staerke: String, Codable, CaseIterable {
    case schwach       // "spricht leicht dafür"
    case merklich      // "verdoppelt die Chancen etwa"
    case stark         // "vervierfacht sie etwa"
    case entscheidend  // "zehnfach -- das trägt den Fall"

    /// Bayes-Faktor: wirkt multiplikativ auf die Odds.
    /// Die Stufen sind bewusst grob -- Scheingenauigkeit wäre derselbe
    /// Fehler noch einmal, nur feiner aufgelöst.
    var faktor: Double {
      switch self {
      case .schwach:      return 1.5
      case .merklich:     return 2.0
      case .stark:        return 4.0
      case .entscheidend: return 10.0
      }
    }
    var beschreibung: String {
      switch self {
      case .schwach:      return "spricht leicht dafür (Faktor 1,5)"
      case .merklich:     return "verdoppelt die Chancen (Faktor 2)"
      case .stark:        return "vervierfacht die Chancen (Faktor 4)"
      case .entscheidend: return "trägt den Fall (Faktor 10)"
      }
    }
  }

  public var id = UUID()
  public var bezeichnung: String          // "BGH VIII ZR 1/23 -- direkt einschlägig"
  public var staerke: Staerke
  public var fuerUns: Bool
  public var begruendung: String          // Pflichtfeld
  public var gesetztVon: String
  public var gesetztAm: Date

  /// Abhängigkeiten: zwei Beweise aus derselben Quelle zählen nicht doppelt.
  public var quellenGruppe: String?       // "Zeuge Schmidt", "Vertragsakte 2023"

  var logOdds: Double { (fuerUns ? 1 : -1) * log(staerke.faktor) }
}

public enum Prognose {
  /// Bayessche Aktualisierung -- die gesamte Rechnung in sechs Zeilen.
  /// Abhängige Beiträge werden gedämpft, statt sie voll zu multiplizieren.
  public static func rechne(prior: Double, beitraege: [Beitrag]) -> Double {
    var l = log(prior / (1 - prior))
    let gruppen = Dictionary(grouping: beitraege) { $0.quellenGruppe ?? UUID().uuidString }
    for (_, gruppe) in gruppen {
      // Innerhalb einer Quellengruppe zählt der stärkste Beitrag voll,
      // jeder weitere nur zur Wurzel -- Standardvorgehen gegen Doppelzählung
      // korrelierter Evidenz.
      let sortiert = gruppe.sorted { abs($0.logOdds) > abs($1.logOdds) }
      for (i, b) in sortiert.enumerated() {
        l += i == 0 ? b.logOdds : b.logOdds * 0.5
      }
    }
    return 1 / (1 + exp(-l))
  }
}"""),
 ("kasten_wichtig", "Warum das den Wettbewerb schlägt",
  "Jedes andere Produkt zeigt eine Prozentzahl, die aus einer Blackbox fällt. Ihres zeigt "
  "eine Prozentzahl <b>und die Kette, aus der sie entstand</b>: „Ausgangspunkt 50 %. "
  "BGH-Urteil einschlägig — verdoppelt. Zeuge unsicher — halbiert. Verjährungseinrede "
  "offen — viertelt. Ergebnis 33 %.\" Das kann ein Anwalt einem Mandanten vorlesen, im "
  "Schriftsatz verwenden und vor Gericht verteidigen. Genau das kann heute niemand."),

 ("h3", "Weg 2 — Die Gewichte aus eigenen Fällen lernen"),
 ("p", "Sobald genügend abgeschlossene Fälle vorliegen, ersetzen Sie die Stufenwerte 1,5 / 2 "
       "/ 4 / 10 durch geschätzte. Da das Modell bereits eine logistische Regression ist, "
       "ist das keine Umstellung, sondern nur ein Zahlentausch. Die Schätzung selbst braucht "
       "keine Bibliothek — ein Newton-Verfahren über die Log-Likelihood genügt und läuft "
       "auf jedem Mac in Millisekunden:"),
 ("code", """/// Logistische Regression per IRLS (Newton-Raphson).
/// Genügt vollständig für die hier zu erwartenden Datenmengen.
public enum LogistischeRegression {
  public static func schaetze(merkmale X: [[Double]], ausgang y: [Double],
                              schritte: Int = 25,
                              regularisierung lambda: Double = 1.0) -> [Double] {
    let n = X.count, p = X[0].count
    var beta = [Double](repeating: 0, count: p)

    for _ in 0..<schritte {
      var gradient = [Double](repeating: 0, count: p)
      var hessisch = [[Double]](repeating: [Double](repeating: 0, count: p), count: p)

      for i in 0..<n {
        let eta = zip(X[i], beta).map(*).reduce(0, +)
        let mu = 1 / (1 + exp(-eta))
        let w = max(mu * (1 - mu), 1e-9)
        for j in 0..<p {
          gradient[j] += X[i][j] * (y[i] - mu)
          for k in 0..<p { hessisch[j][k] += X[i][j] * X[i][k] * w }
        }
      }
      // Ridge: verhindert, dass seltene Merkmale das Modell sprengen.
      for j in 0..<p {
        gradient[j] -= lambda * beta[j]
        hessisch[j][j] += lambda
      }
      guard let delta = loese(hessisch, gradient) else { break }
      for j in 0..<p { beta[j] += delta[j] }
      if delta.map({ abs($0) }).max() ?? 0 < 1e-8 { break }
    }
    return beta
  }
}"""),

 # ---------------------------------------------------------- 1.7
 ("seitenumbruch", None),
 ("h2", "1.7 · Der Fristen-Malus ist falsch modelliert, nicht nur falsch beziffert"),
 ("etikett", "Modellfehler · Aufwand: 1 Tag"),
 ("code", """// LegalAlgorithmsService.swift:285
let fristenPenalty = -(Double(versaeumt) * 0.4 + Double(kritisch) * 0.15)"""),
 ("p", "Hier stimmt nicht die Zahl nicht — hier stimmt die Denkweise nicht. Eine versäumte "
       "Notfrist senkt die Erfolgsaussicht nicht um einen Betrag. Sie beendet das Verfahren: "
       "Das Rechtsmittel ist unzulässig, die Erfolgsaussicht springt auf nahezu null, und "
       "die einzige verbleibende Frage ist die Wiedereinsetzung nach § 233 ZPO. Eine "
       "Schriftsatzfrist dagegen kostet praktisch nichts, weil verspäteter Vortrag oft noch "
       "zugelassen wird."),
 ("p", "Ein Abschlag von 0,4 Log-Odds bildet beides gleich ab und ist damit in beiden "
       "Richtungen falsch. Richtig ist ein Zustandsmodell:"),
 ("code", """/// Fristversäumnis ist ein Zustand, keine Punktwertung.
public enum Fristzustand {
  case unauffaellig
  case kritisch(tageRest: Int)
  case versaeumtHeilbar(norm: String)        // z. B. Schriftsatzfrist
  case versaeumtFatal(norm: String,
                      wiedereinsetzungMoeglich: Bool)   // Notfrist

  /// Wirkung auf die Prognose -- kein Abschlag, sondern eine Aussage.
  var wirkung: String {
    switch self {
    case .unauffaellig:
      return "keine"
    case .kritisch(let t):
      return "Frist läuft in \\(t) Tagen ab -- Prognose unverändert, Handlungsdruck hoch"
    case .versaeumtHeilbar(let n):
      return "\\(n) versäumt -- Vortrag ggf. noch zulässig, Prognose leicht belastet"
    case .versaeumtFatal(let n, let wieder):
      return wieder
        ? "\\(n) als Notfrist versäumt -- Verfahren nur über Wiedereinsetzung "
        + "(§ 233 ZPO) zu retten. Prognose bis zur Entscheidung darüber ausgesetzt."
        : "\\(n) als Notfrist versäumt, Wiedereinsetzung ausgeschlossen -- "
        + "Rechtsmittel unzulässig."
    }
  }

  /// Die Prognose wird nicht gedrückt, sondern angehalten. Eine Zahl,
  /// die den Zustand ignoriert, wäre irreführend.
  var prognoseGueltig: Bool {
    if case .versaeumtFatal = self { return false }
    return true
  }
}"""),
 ("kasten_wichtig", "Hieraus entsteht eine Funktion, die es nirgends gibt",
  "Wenn die App den Zustand <font face=\"Mono\">versaeumtFatal</font> erkennt, kann sie "
  "sofort das tun, was in dieser Lage zählt: <b>das Wiedereinsetzungs-Dossier erzeugen.</b> "
  "§ 233 ZPO verlangt die Darlegung, dass die Partei ohne Verschulden gehindert war — und "
  "das heißt in der Praxis: Nachweis einer funktionierenden Kanzleiorganisation. Genau "
  "diesen Nachweis führt Ihre Software ohnehin mit (Fristenprotokoll, Ausgangskontrolle, "
  "Vier-Augen-Bestätigungen). Sie muss ihn nur zusammenstellen. Mehr dazu in Teil 3."),

 # ---------------------------------------------------------- 1.8
 ("h2", "1.8 · Monte Carlo: erfundene Streuung und 400-mal zu langsam"),
 ("etikett", "erfunden + ineffizient · Aufwand: 1 Tag"),
 ("code", """// AbschlussMonteCarloEngine.swift:50
let algoStd = 5.0;  let kiStdCorrect = 8.0;  let kiStdWrong = 18.0
// ... 3000 Zufallsziehungen"""),
 ("p", "Zwei Probleme. Erstens sind die Streuungen erfunden — sie kommen künftig aus der "
       "vom Anwalt gesetzten Unsicherheit. Zweitens, und das ist der interessantere Punkt: "
       "<b>Monte Carlo ist hier das falsche Werkzeug.</b>"),
 ("p", "Gesucht ist der Erwartungswert einer glatten Funktion über eine Normalverteilung. "
       "Genau dafür gibt es die Gauß-Hermite-Quadratur. Sieben Stützstellen liefern eine "
       "Genauigkeit, für die man mit Zufallsziehungen Millionen Läufe bräuchte — "
       "deterministisch, in Mikrosekunden, ohne Startwert-Problem aus Kapitel C des "
       "Sanierungshandbuchs."),
 ("tabelle", ["Verfahren", "Auswertungen", "Fehler", "Reproduzierbar"], [
   ["Monte Carlo, 3.000 Ziehungen", "3.000", "rund 0,005 (Zufallsfehler)", "nein"],
   ["Gauß-Hermite, 7 Stützstellen", "7", "unter 0,000001", "ja, immer"],
 ]),
 ("code", """/// Erwartungswert einer Wahrscheinlichkeit bei unsicheren Log-Odds.
/// Gauß-Hermite-Quadratur: exakt, deterministisch, 400-mal weniger Rechenarbeit.
public enum Unsicherheit {
  // 7-Punkt-Gauß-Hermite (Gewichtsfunktion e^{-x^2}); Summe der Gewichte = sqrt(pi)
  private static let knoten: [Double] = [
    -2.651961356835233, -1.673551628767471, -0.816287882858965, 0,
     0.816287882858965,  1.673551628767471,  2.651961356835233
  ]
  private static let gewichte: [Double] = [
    0.000971781245099519, 0.054515582819127, 0.425607252610128,
    0.810264617556807,
    0.425607252610128, 0.054515582819127, 0.000971781245099519
  ]
  private static let wurzelPi = 1.772453850905516

  /// mittel = erwartete Log-Odds, streuung = Unsicherheit darauf.
  /// Ergebnis: erwartete Wahrscheinlichkeit samt Bandbreite.
  public static func wahrscheinlichkeit(mittel: Double, streuung: Double)
      -> (erwartet: Double, unten: Double, oben: Double) {
    guard streuung > 0 else {
      let p = 1 / (1 + exp(-mittel));  return (p, p, p)
    }
    var summe = 0.0
    for (k, g) in zip(knoten, gewichte) {
      let l = mittel + 1.4142135623730951 * streuung * k
      summe += g * (1 / (1 + exp(-l)))
    }
    let erwartet = summe / wurzelPi
    // 90-%-Band: 1,645 Standardabweichungen auf der Log-Odds-Skala
    let unten = 1 / (1 + exp(-(mittel - 1.645 * streuung)))
    let oben  = 1 / (1 + exp(-(mittel + 1.645 * streuung)))
    return (erwartet, unten, oben)
  }
}"""),
 ("kasten_achtung", "Wo Monte Carlo trotzdem richtig bleibt",
  "Für den Pfadgraf und die Zug-um-Zug-Simulation der Macht-Einfluss-Engine ist Monte Carlo "
  "das richtige Verfahren — dort gibt es Verzweigungen und Pfadabhängigkeiten, die keine "
  "Quadratur abbildet. Ersetzen Sie es also nur dort, wo eine glatte Funktion über eine "
  "Verteilung gemittelt wird. Für die Simulationen bleibt es bei Monte Carlo, dann aber "
  "zwingend mit festem Startwert."),

 # ---------------------------------------------------------- 1.9
 ("seitenumbruch", None),
 ("h2", "1.9 · Die Macht-Einfluss-Engine: vierzehn Setzungen"),
 ("etikett", "erfunden · Aufwand: 3 Tage"),
 ("code", """// MachtEinflussEngine.swift -- Auszug
var erwarteterNutzen: Double { eintrittsWk * nutzbarkeit * (0.5 + 0.5 * beeinflussbarkeit) }
let folgen = (1 - folgenHandhabbarkeit) * 0.6 + (1 - reversibilitaet) * 0.4
return min(1, folgen * (0.4 + 0.6 * aufwand))
var nettoScore: Double { erwarteterNutzen - 0.5 * restrisiko }
let machtFaktor = 0.8 + 0.4 * (machtIndex / 100)
let staerke = zug.nutzbarkeit * zug.beeinflussbarkeit * 0.28 * (0.8 + 0.4 * rng.double01())"""),
 ("p", "Hier steckt viel Denkarbeit — und jede einzelne Gewichtung ist gesetzt. Besonders "
       "problematisch ist <font face=\"Mono\">nettoScore</font>: Der Faktor 0,5 entscheidet "
       "darüber, wie risikofreudig die App ist, und diese Entscheidung gehört niemals der "
       "Software, sondern immer dem Mandanten."),
 ("h3", "Das Verfahren: Swing-Gewichtung"),
 ("p", "Die Entscheidungstheorie kennt für genau dieses Problem ein etabliertes Verfahren, "
       "das ohne erfundene Zahlen auskommt und in fünf Minuten durchführbar ist. Man fragt "
       "nicht „wie wichtig ist Reversibilität?\" — darauf gibt es keine sinnvolle Antwort. "
       "Man fragt: <i>„Wenn alle Kriterien im schlechtesten Zustand wären und Sie dürften "
       "genau eines auf den besten Wert heben — welches?\"</i> Das ist beantwortbar, und aus "
       "der Reihenfolge samt Punktvergabe folgen die Gewichte zwingend."),
 ("code", """/// Swing-Gewichtung: Gewichte werden erhoben, nicht gesetzt.
public struct Kriteriengewichtung: Codable {
  public struct Kriterium: Codable, Identifiable {
    public var id = UUID()
    public var name: String              // "Reversibilität"
    public var frage: String             // die Swing-Frage im Klartext
    public var rang: Int                 // 1 = wichtigster Sprung
    public var punkte: Double            // wichtigster = 100, Rest relativ dazu
  }

  public var kriterien: [Kriterium]
  public var erhobenVon: String
  public var erhobenAm: Date
  public var fuerMandat: String

  /// Normierte Gewichte -- Summe 1. Keine Konstante im Code.
  public var gewichte: [UUID: Double] {
    let summe = kriterien.map(\\.punkte).reduce(0, +)
    guard summe > 0 else { return [:] }
    return Dictionary(uniqueKeysWithValues:
      kriterien.map { ($0.id, $0.punkte / summe) })
  }

  /// Prüft, ob die Angaben zueinander passen: Rangfolge und Punkte
  /// müssen dieselbe Reihenfolge ergeben. Sonst hat sich der Nutzer
  /// widersprochen -- und das muss er erfahren, nicht die Software glätten.
  public var widersprueche: [String] {
    let nachRang = kriterien.sorted { $0.rang < $1.rang }
    var fehler: [String] = []
    for (a, b) in zip(nachRang, nachRang.dropFirst()) where a.punkte < b.punkte {
      fehler.append("\\(a.name) ist als wichtiger eingestuft, hat aber weniger Punkte "
                  + "als \\(b.name).")
    }
    return fehler
  }
}"""),
 ("p", "Der Risikofaktor 0,5 aus <font face=\"Mono\">nettoScore</font> wird ebenso erhoben — "
       "als Frage an den Mandanten, nicht als Konstante: <i>„Würden Sie eine sichere "
       "Zahlung von 40.000 € einer 50-Prozent-Chance auf 100.000 € vorziehen?\"</i> "
       "Aus wenigen solchen Fragen ergibt sich die Risikoneigung, und sie gehört ins "
       "Mandat, dokumentiert und unterschrieben."),

 # ---------------------------------------------------------- 1.10 / 1.11
 ("h2", "1.10 · Klumpenrisiko als Pauschale statt als Rechnung"),
 ("etikett", "erfunden · Aufwand: halber Tag"),
 ("code", """// VorgangMotor.swift:247
let klumpen = gruppen.values.filter { $0.count > 2 }.count
let bereinigt = roh * (1 - Double(klumpen) * 0.08)"""),
 ("p", "Acht Prozent Abschlag je Gruppe mit mehr als zwei Fällen — die Schwelle, der "
       "Abschlag und die Linearität sind gesetzt. Dabei ist Portfoliorisiko ein gelöstes "
       "Problem der Finanzmathematik. Die Varianz einer Summe korrelierter Größen hat eine "
       "geschlossene Formel, und die Korrelationen lassen sich aus den Fallmerkmalen "
       "ableiten, statt sie zu raten:"),
 ("code", """/// Portfoliorisiko nach der Standardformel -- keine Pauschale.
public enum Portfolio {
  /// Korrelation zweier Verfahren aus geteilten Risikoquellen.
  /// Jede Übereinstimmung addiert einen begründbaren Beitrag.
  static func korrelation(_ a: Vorgang, _ b: Vorgang) -> Double {
    var r = 0.0
    if a.rechtsgebiet == b.rechtsgebiet     { r += 0.25 }  // gleiche Rechtsfrage
    if a.gegner?.id == b.gegner?.id         { r += 0.35 }  // derselbe Gegner
    if a.gericht == b.gericht               { r += 0.20 }  // dieselbe Kammer
    if a.tragendeNorm == b.tragendeNorm     { r += 0.40 }  // dieselbe Norm entscheidet
    return min(0.95, r)
  }

  /// Erwartungswert bleibt additiv; das Risiko nicht.
  public static func kennzahlen(_ v: [Vorgang]) -> (ev: Double, streuung: Double) {
    let ev = v.compactMap { $0.erwartungswert }.reduce(0, +)
    var varianz = 0.0
    for i in v.indices {
      for j in v.indices {
        let si = v[i].streuung, sj = v[j].streuung
        varianz += si * sj * (i == j ? 1 : korrelation(v[i], v[j]))
      }
    }
    return (ev, varianz.squareRoot())
  }
}"""),
 ("kasten_wichtig", "Warum das mehr ist als Genauigkeit",
  "Die Korrelationsrechnung beantwortet eine Frage, die kein Kanzleisystem heute stellt: "
  "<b>„Welches Mandat sollten wir nicht annehmen?\"</b> Wenn vier laufende Verfahren an "
  "derselben BGH-Frage hängen, ist die Kanzlei nicht viermal beschäftigt — sie hat eine "
  "einzige Wette vierfach platziert. Das sichtbar zu machen, ist echter "
  "unternehmerischer Nutzen und passt exakt zum Modul Mandats-Pipeline."),

 ("h2", "1.11 · Der Vergleichsanker bei 70 Prozent"),
 ("etikett", "erfunden · Aufwand: halber Tag"),
 ("code", """// VorgangRechenwerk.swift:145
let anker = existiert ? unten + 0.7 * (oben - unten) : unten"""),
 ("p", "Der Anker für die Vergleichsverhandlung liegt bei 70 Prozent der Spanne — eine Zahl "
       "ohne Grundlage. Dabei ist der richtige Wert bekannt und im Programm bereits "
       "vorhanden: <b>die beste Alternative zum Vergleich</b>, also der Erwartungswert des "
       "streitigen Verfahrens abzüglich Kosten und Zeit. Unterhalb davon darf man nicht "
       "abschließen; oberhalb beginnt der Verhandlungsspielraum."),
 ("code", """/// Verhandlungsrahmen aus der besten Alternative -- nicht aus einem Anteil.
public struct Verhandlungsrahmen {
  /// Was das Verfahren wert ist, wenn man es durchzieht (Kapitel 1.6 + 1.1).
  public let eigeneAlternative: Double
  /// Geschätzte Alternative der Gegenseite -- ausdrücklich eine Annahme.
  public let gegnerAlternative: Double
  public let zeitwertVerlust: Double      // Zinsen, Bindung, Aufwand

  /// Unterhalb dieses Betrags ist Prozessieren besser als Vergleichen.
  public var untergrenze: Double { eigeneAlternative - zeitwertVerlust }
  /// Oberhalb dieses Betrags würde die Gegenseite prozessieren.
  public var obergrenze: Double { gegnerAlternative + zeitwertVerlust }

  /// Gibt es überhaupt einen Bereich, in dem beide zustimmen?
  public var einigungsbereich: ClosedRange<Double>? {
    untergrenze <= obergrenze ? untergrenze...obergrenze : nil
  }

  public var klartext: String {
    guard let b = einigungsbereich else {
      return "Kein Einigungsbereich: Beide Seiten fahren mit dem Verfahren besser. "
           + "Ein Vergleich setzt voraus, dass eine Annahme falsch ist -- welche?"
    }
    return "Einigung sinnvoll zwischen \\(waehrung(b.lowerBound)) und "
         + "\\(waehrung(b.upperBound)). Unter \\(waehrung(untergrenze)) nicht "
         + "abschließen -- dann ist Prozessieren besser."
  }
}"""),
 ("p", "Der letzte Satz ist der wertvollste: Wenn kein Einigungsbereich existiert, sagt die "
       "App das — statt einen Anker zu erfinden. Und sie sagt zugleich, was daraus folgt: "
       "Eine der beiden Einschätzungen muss falsch sein, und darüber lohnt das Gespräch."),

 # ============================================================ TEIL 2
 ("seitenumbruch", None),
 ("h1", "Teil 2 — Woher jede Zahl kommt"),
 ("p", "Die Frage, welche Statistik oder Website hinter einer Zahl steht, gehört ins "
       "Programm selbst — als Feld neben dem Wert, nicht als Wissen im Kopf des Entwicklers. "
       "Diese Übersicht listet für jede Zahlenart die Quelle, die Aktualisierungspflicht und "
       "das Modul, in dem sie gebraucht wird."),
 ("quellen_tabelle", [
   ("Anwaltsgebühren", "Anlage 2 zum RVG · Gesetzestext beim Bundesjustizministerium "
    "(gesetze-im-internet.de)", "bei jeder Gesetzesänderung", "Kostenrisiko, Honorare"),
   ("Gerichtskosten", "Anlage 2 zum GKG, Kostenverzeichnis KV 1210",
    "bei jeder Gesetzesänderung", "Kostenrisiko, Mandantenaufklärung"),
   ("Fristen und Normen", "BGB, ZPO, ArbGG, KSchG · gesetze-im-internet.de",
    "laufend beobachten", "Fristenwache, Berufspflicht-Desk"),
   ("Gesetzliche Feiertage", "Feiertagsgesetze der 16 Länder · Landesrecht",
    "jährlich im Dezember", "Fristenberechnung (§ 193 BGB)"),
   ("Verzugszinsen", "Basiszinssatz nach § 247 BGB · Deutsche Bundesbank, "
    "halbjährlich zum 1.1. und 1.7.", "halbjährlich, automatisierbar", "Forderungsrechner"),
   ("Verfahrensdauern, Erledigungsarten, Berufungserfolge",
    "Statistisches Bundesamt, Fachserie 10 Reihe 2.1 (Zivilgerichte) · destatis.de",
    "jährlich", "Instanzfaktor, Zeitplanung"),
   ("Rechtsprechung", "rechtsprechung-im-internet.de (Bundesgerichte) · "
    "Landesrechtsprechungsdatenbanken · openJur", "laufend", "Argumentbelege, Rechtsradar"),
   ("EU-Recht", "EUR-Lex", "laufend", "KI-Verordnung, DSGVO, Jurisdiktionen"),
   ("Insolvenzen der Gegenseite", "insolvenzbekanntmachungen.de · amtlich und frei",
    "vor jeder Klage prüfen", "Bonitätsprüfung, Mandats-Pipeline"),
   ("Unternehmensdaten der Gegenseite", "Handelsregister · Unternehmensregister · "
    "Bundesanzeiger (Jahresabschlüsse)", "bei Mandatsannahme", "Konfliktprüfung, Bonität"),
   ("Lebenserwartung für Renten und Schadensersatz",
    "Sterbetafel des Statistischen Bundesamts", "jährlich", "Kapitalisierung"),
   ("Preisentwicklung für Wertsicherung", "Verbraucherpreisindex · destatis.de",
    "monatlich", "Miet- und Vertragsanpassung"),
 ]),
 ("kasten_achtung", "Bitte prüfen Sie jede Quelle selbst",
  "Ich konnte im Prüfcontainer keine dieser Seiten aufrufen. Die Zuordnung von Zahlenart zu "
  "Quelle beruht auf meinem Wissen, nicht auf einem Abruf: Bezeichnungen von Fachserien, "
  "Verfügbarkeit und Nutzungsbedingungen können abweichen. Klären Sie vor einer "
  "automatisierten Abfrage in jedem Fall die Nutzungsrechte — insbesondere beim "
  "Handelsregister und den Insolvenzbekanntmachungen gelten Beschränkungen für den "
  "automatisierten Massenabruf."),
 ("h3", "Wie die Quelle in den Code kommt"),
 ("p", "Jede externe Zahl bekommt denselben Rahmen. Damit ist im Programm jederzeit "
       "sichtbar, wie alt ein Wert ist — und die Oberfläche kann warnen, bevor jemand mit "
       "veralteten Gebühren rechnet:"),
 ("code", """/// Ein Wert mit Herkunft. Ersetzt jede nackte Konstante im Programm.
public struct BelegterWert<T: Codable>: Codable {
  public var wert: T
  public var quelle: String            // "Anlage 2 RVG"
  public var fundstelle: String        // "Stufe bis 25.000 EUR"
  public var abgerufenAm: Date
  public var abgerufenVon: String      // URL oder "Gesetzestext, gedruckt"
  public var gueltigBis: Date?         // wenn bekannt
  public var geprueftVon: String       // wer hat nachgeschlagen

  /// Warnschwelle für die Oberfläche.
  public var istVeraltet: Bool {
    if let g = gueltigBis, g < Date() { return true }
    return Date().timeIntervalSince(abgerufenAm) > 400 * 24 * 3600   // > 13 Monate
  }

  public var herkunftstext: String {
    "\\(quelle), \\(fundstelle). Geprüft von \\(geprueftVon) am "
    + "\\(abgerufenAm.formatted(date: .abbreviated, time: .omitted))."
  }
}"""),
]
