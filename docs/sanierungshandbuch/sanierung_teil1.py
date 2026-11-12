# -*- coding: utf-8 -*-
"""Inhalt Teil 1: Deckblatt, Inhalt, Befund, Kapitel A (Fristen)."""

# Blocktypen: h1 h2 h3 p code tabelle liste kasten seitenumbruch klein

TEIL1 = [
 ("h1", "Sanierungshandbuch"),
 ("untertitel", "FenlynineOS Legal Suite — was zu tun ist, damit die App für Anwälte "
                "tragfähig wird. Für jeden Befund die konkrete Umsetzung."),
 ("meta", [
   ("Prüfgegenstand", "Snapshot Fenlynine-11.08.26-R1 · 225 Dateien · 85.146 Zeilen"),
   ("Erstellt", "17. August 2026"),
   ("Grundlage", "Vollständige Quellcode-Prüfung, kein Laufzeittest (kein Compiler im Prüfcontainer)"),
   ("Aufbau", "Teil I Befund · Teil II Sanierung (11 Kapitel) · Teil III Reihenfolge · Teil IV Grenzen"),
 ]),

 ("kasten_wichtig", "Wie dieses Dokument zu lesen ist",
  "Teil II ist das Kernstück. Jedes Kapitel folgt demselben Muster: <b>Was ist falsch</b> "
  "(mit Fundstelle im Code), <b>warum es zählt</b>, <b>wie es genau gemacht wird</b> "
  "(mit Code, den Sie übernehmen können) und <b>wie Sie prüfen, dass es stimmt</b> "
  "(mit Testfällen samt erwarteten Ergebnissen). "
  "Der Code ist als Vorlage gedacht, nicht als Copy-Paste-Endprodukt: Er passt zu den "
  "vorhandenen Datenmodellen, muss aber kompiliert und getestet werden — im Prüfcontainer "
  "stand kein Swift-Compiler zur Verfügung."),

 ("h2", "Inhalt"),
 ("inhalt", [
   ("Teil I", "Befund in zwölf Punkten", ""),
   ("Teil II", "Sanierung", ""),
   ("A", "Fristenberechnung nach §§ 187–193 BGB", "der kritische Kern"),
   ("B", "Willkürliche Zahlen ersetzen: Prognosen, die tragen", "kritisch"),
   ("C", "Reproduzierbarkeit und Audit-Fähigkeit", "kritisch"),
   ("D", "RVG-Tabelle und Kostenrisiko korrekt rechnen", "erheblich"),
   ("E", "Passwörter richtig schützen", "erheblich"),
   ("F", "Richterprofile rechtskonform umbauen", "kritisch"),
   ("G", "KI-Verordnung und Berufsrecht ehrlich erfüllen", "erheblich"),
   ("H", "Auftragsverarbeitung, § 203 StGB, § 43e BRAO", "erheblich"),
   ("I", "Anbindungen: beA, Kanzleisoftware, Kalender, E-Rechnung", "erheblich"),
   ("J", "Tests — es gibt bisher keinen einzigen", "kritisch"),
   ("K", "Von dreißig Modulen auf einen Arbeitsablauf", "strategisch"),
   ("Teil III", "Reihenfolge, Aufwand, Wirkung auf den Wert", ""),
   ("Teil IV", "Grenzen dieser Prüfung", ""),
 ]),

 ("seitenumbruch", None),

 # ============================================================ TEIL I
 ("h1", "Teil I — Befund"),

 ("p", "Zuerst das Positive, weil es echt ist und die Grundlage jeder Sanierung bildet."),

 ("h3", "Was tragfähig ist"),
 ("befund_gut", "1", "Die Herkunftsmarke löst das eigentliche Problem von KI im Recht",
  "Neben jeder Zahl sitzt ein Punkt, der ihre Herkunft anzeigt: gefüllt = Formel, "
  "Ring = unbestätigter KI-Vorschlag, blau = vom Menschen bestätigt und damit haftbar, "
  "grau = Gesetzesquelle. Damit ist auf einen Blick klar, wer für eine Zahl einsteht. "
  "Genau daran scheitern die meisten KI-Produkte im Rechtsmarkt. "
  "<i>Herkunftsmarke.swift:9–12</i>"),
 ("befund_gut", "2", "Der Berufspflicht-Desk kennt echte Rechtsprechung",
  "Die gestufte Ausgangskontrolle ist nachgebaut, inklusive der Feinheit, dass gestrichene "
  "Fristen bei der Endkontrolle erkennbar bleiben müssen. Das weiß nur, wer Anwaltshaftung "
  "verstanden hat. <i>ImperiumBerufspflichtDesk.swift:69, 143</i>"),
 ("befund_gut", "3", "Mandantendaten bleiben standardmäßig lokal",
  "Fall-Daten als JSON im Application-Support-Ordner, pro Gerät getrennt, mit einer "
  "Souveränitätsschicht vor jedem KI-Aufruf. Für § 203 StGB und § 43e BRAO der richtige "
  "Instinkt — und ein Verkaufsargument gegenüber reinen Cloud-Anbietern."),
 ("befund_gut", "4", "Datenschutzrechte sind eingebaut, nicht nachgerüstet",
  "Auskunft und Übertragbarkeit nach Art. 15/20 DSGVO als vollständiger Export, Löschung "
  "nach Art. 17 als echte Routine, dazu ein Protokoll aller KI-Aufrufe."),
 ("befund_gut", "5", "Keine einzige externe Abhängigkeit",
  "<font face=\"Mono\">dependencies: []</font> — nichts wird nachgeladen. Seltene Disziplin, "
  "senkt das Lieferkettenrisiko, erleichtert die Zulassungsprüfung."),

 ("h3", "Was saniert werden muss"),
 ("befund_tabelle", [
   ("6", "Keine Fristenberechnung", "kritisch",
    "Die gesamte Logik ist eine Kalendertage-Subtraktion. Kein §§ 187–193 BGB, keine "
    "Feiertage, keine Notfristen.", "Kapitel A"),
   ("7", "Prognosezahlen sind erfunden", "kritisch",
    "Streuungen (5,0 / 8,0 / 18,0) und Basisquoten (0,52 / 0,35) sind frei gesetzt. "
    "Ergebnis: Konfidenzintervall ohne Empirie.", "Kapitel B"),
   ("8", "Ergebnisse nicht reproduzierbar", "kritisch",
    "Unbesamter Zufall: dieselbe Eingabe liefert jeden Lauf ein anderes Ergebnis.", "Kapitel C"),
   ("9", "RVG-Tabelle ab 13.000 € falsch", "erheblich",
    "Erste sieben Werte exakt, danach abweichend. Speist einen Kostenrisiko-Score.", "Kapitel D"),
   ("10", "Passwort-Hashing unzureichend", "erheblich",
    "Ein SHA-256-Durchlauf, kein Arbeitsfaktor. Schützt Mandantengeheimnisse.", "Kapitel E"),
   ("11", "Richterprofile rechtlich riskant", "kritisch",
    "Namentliche Profile mit Erfolgsquoten. Datenschutz, Berufsrecht, EU-Ausblick.", "Kapitel F"),
   ("12", "Compliance-Siegel unverdient", "erheblich",
    "„EU AI Act\"-Schild ohne Klassifizierung und ohne Bewertung.", "Kapitel G"),
   ("13", "Keine beA-/Kanzleisoftware-Anbindung", "erheblich",
    "Bleibt damit Zweitsystem mit Doppelpflege — der klassische Abschaltgrund.", "Kapitel I"),
   ("14", "Kein einziger Test im Projekt", "kritisch",
    "85.000 Zeilen ohne Testabdeckung. Bei Fristen und Gebühren nicht vertretbar.", "Kapitel J"),
   ("15", "Dreißig Module, kein vollständiger Ablauf", "strategisch",
    "Der eine Ablauf, den jede Kanzlei täglich braucht, fehlt.", "Kapitel K"),
 ]),

 ("seitenumbruch", None),

 # ============================================================ KAPITEL A
 ("h1", "Teil II — Sanierung"),
 ("h2", "A · Fristenberechnung nach §§ 187–193 BGB"),
 ("etikett", "kritisch · der Kern · geschätzter Aufwand: 5–8 Tage inklusive Tests"),

 ("h3", "Was falsch ist"),
 ("p", "Die vollständige Fristenlogik der App besteht aus dieser Funktion in "
       "<font face=\"Mono\">VorgangKern.swift:261–263</font>:"),
 ("code", """var tageBisAblauf: Int {
  Calendar.current.dateComponents([.day], from: .init(), to: datum).day ?? 0
}"""),
 ("p", "Im Projekt findet sich nichts zu §§ 187–193 BGB, keine Feiertagstabelle, keine "
       "Bundesland-Unterscheidung, keine Notfristen. Die App speichert ein Datum, das jemand "
       "eintippt. Zugleich trägt das Modell schon das Feld "
       "<font face=\"Mono\">quelle</font> mit dem Kommentar „Formel (§ 4 KSchG, § 195 BGB, …) "
       "oder manuell\" — die Absicht war da, nur die Berechnung fehlt. Das ist gut: die "
       "Sanierung fügt sich in vorhandene Strukturen."),

 ("h3", "Warum das der wichtigste Punkt ist"),
 ("p", "Fristversäumnis ist in Deutschland der häufigste Grund für Anwaltshaftung. Jede "
       "etablierte Kanzleisoftware rechnet Fristen selbst. Eine App, die das nicht kann, aber "
       "ein Modul „Fristenwache\" mit BGH-Bezug anbietet, erzeugt Vertrauen, das sie nicht "
       "verdient — gefährlicher als gar kein Modul."),

 ("h3", "Die Rechtslage, die abgebildet werden muss"),
 ("regel_tabelle", [
   ("§ 187 Abs. 1 BGB", "Ereignisfrist",
    "Der Tag des Ereignisses (z. B. Zustellung) wird nicht mitgerechnet. Die Frist beginnt "
    "am Folgetag um 0:00."),
   ("§ 187 Abs. 2 BGB", "Beginnfrist",
    "Ist der Beginn eines Tages maßgebend, wird dieser Tag mitgerechnet."),
   ("§ 188 Abs. 1 BGB", "Tagesfristen",
    "Endet mit Ablauf des letzten Tages."),
   ("§ 188 Abs. 2 BGB", "Wochen-, Monats-, Jahresfristen",
    "Bei Ereignisfristen: Ablauf des Tages der letzten Woche bzw. des letzten Monats, der "
    "dem Ereignistag nach Benennung oder Zahl entspricht. Bei Beginnfristen: der Tag davor."),
   ("§ 188 Abs. 3 BGB", "Fehlender Monatstag",
    "Fehlt der Tag im letzten Monat, endet die Frist am letzten Tag dieses Monats. "
    "31. Januar + 1 Monat = 28. bzw. 29. Februar."),
   ("§ 193 BGB", "Sonn-, Feier-, Samstag",
    "Fällt das Fristende auf Sonntag, staatlich anerkannten allgemeinen Feiertag "
    "<b>am Erklärungsort</b> oder Samstag, tritt der nächste Werktag an seine Stelle."),
   ("§ 222 ZPO", "Prozessfristen",
    "Verweist auf das BGB und wiederholt die Werktagsregel für gerichtliche Fristen."),
   ("§ 224 ZPO", "Notfristen",
    "Nur die im Gesetz so bezeichneten Fristen sind Notfristen. Sie sind weder verlängerbar "
    "noch abkürzbar — die App muss das anzeigen und Verlängerungsanträge dort sperren."),
 ]),
 ("kasten_achtung", "Der Erklärungsort entscheidet, nicht der Kanzleisitz",
  "§ 193 BGB stellt auf den <b>am Erklärungsort</b> anerkannten Feiertag ab. Maßgeblich ist "
  "also das Bundesland des Gerichts oder der Stelle, bei der die Erklärung eingehen muss — "
  "nicht das Bundesland Ihrer Kanzlei. Eine Kanzlei in Köln, die beim Landgericht Dresden "
  "einreicht, rechnet mit dem sächsischen Feiertagskalender. Dieses Feld muss im Datenmodell "
  "am Vorgang hängen und darf nicht aus den Kanzleieinstellungen abgeleitet werden."),

 ("h3", "Schritt 1 — Feiertagskalender mit Bundesland"),
 ("p", "Beweglichen Feiertagen liegt Ostern zugrunde. Der Algorithmus von "
       "Meeus/Jones/Butcher liefert den Ostersonntag für jedes Jahr des gregorianischen "
       "Kalenders ohne Tabelle:"),
 ("code", """import Foundation

enum Bundesland: String, CaseIterable, Codable, Identifiable {
  case bw, by, be, bb, hb, hh, he, mv, ni, nw, rp, sl, sn, st, sh, th
  var id: String { rawValue }

  var bezeichnung: String {
    switch self {
    case .bw: return "Baden-Württemberg";   case .by: return "Bayern"
    case .be: return "Berlin";              case .bb: return "Brandenburg"
    case .hb: return "Bremen";              case .hh: return "Hamburg"
    case .he: return "Hessen";              case .mv: return "Mecklenburg-Vorpommern"
    case .ni: return "Niedersachsen";       case .nw: return "Nordrhein-Westfalen"
    case .rp: return "Rheinland-Pfalz";     case .sl: return "Saarland"
    case .sn: return "Sachsen";             case .st: return "Sachsen-Anhalt"
    case .sh: return "Schleswig-Holstein";  case .th: return "Thüringen"
    }
  }
}

/// Gesetzliche Feiertage. Grundlage sind die Feiertagsgesetze der Länder;
/// die Zuordnung ist einmal jährlich zu prüfen (siehe Wartungshinweis).
struct Feiertagskalender {

  /// Kalender ohne Zeitanteil, feste Zeitzone -- verhindert Sommerzeitfehler.
  static let kalender: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Berlin")!
    c.firstWeekday = 2          // Montag
    return c
  }()

  static func tag(_ jahr: Int, _ monat: Int, _ tag: Int) -> Date {
    kalender.date(from: DateComponents(year: jahr, month: monat, day: tag))!
  }

  /// Ostersonntag nach Meeus/Jones/Butcher (gregorianisch, ohne Tabelle).
  static func ostersonntag(jahr y: Int) -> Date {
    let a = y % 19
    let b = y / 100
    let c = y % 100
    let d = b / 4
    let e = b % 4
    let f = (b + 8) / 25
    let g = (b - f + 1) / 3
    let h = (19 * a + b - d - g + 15) % 30
    let i = c / 4
    let k = c % 4
    let l = (32 + 2 * e + 2 * i - h - k) % 7
    let m = (a + 11 * h + 22 * l) / 451
    let monat = (h + l - 7 * m + 114) / 31
    let tagImMonat = ((h + l - 7 * m + 114) % 31) + 1
    return tag(y, monat, tagImMonat)
  }

  private static func plus(_ tage: Int, _ datum: Date) -> Date {
    kalender.date(byAdding: .day, value: tage, to: datum)!
  }

  /// Buß- und Bettag: Mittwoch vor dem 23. November. Nur Sachsen.
  static func bussUndBettag(jahr: Int) -> Date {
    var d = tag(jahr, 11, 22)
    while kalender.component(.weekday, from: d) != 4 {   // 4 = Mittwoch
      d = plus(-1, d)
    }
    return d
  }

  /// Alle gesetzlichen Feiertage eines Jahres im angegebenen Land.
  static func feiertage(jahr: Int, land: Bundesland) -> [Date: String] {
    let ostern = ostersonntag(jahr: jahr)
    var f: [Date: String] = [
      tag(jahr, 1, 1):    "Neujahr",
      plus(-2, ostern):   "Karfreitag",
      plus(1, ostern):    "Ostermontag",
      tag(jahr, 5, 1):    "Tag der Arbeit",
      plus(39, ostern):   "Christi Himmelfahrt",
      plus(50, ostern):   "Pfingstmontag",
      tag(jahr, 10, 3):   "Tag der Deutschen Einheit",
      tag(jahr, 12, 25):  "1. Weihnachtstag",
      tag(jahr, 12, 26):  "2. Weihnachtstag",
    ]

    func setze(_ d: Date, _ name: String) { f[d] = name }

    // Heilige Drei Könige
    if [.bw, .by, .st].contains(land) { setze(tag(jahr, 1, 6), "Heilige Drei Könige") }
    // Internationaler Frauentag
    if [.be, .mv].contains(land) { setze(tag(jahr, 3, 8), "Internationaler Frauentag") }
    // Fronleichnam (in SN und TH nur in bestimmten Gemeinden -- siehe Hinweis)
    if [.bw, .by, .he, .nw, .rp, .sl].contains(land) {
      setze(plus(60, ostern), "Fronleichnam")
    }
    // Mariä Himmelfahrt (BY nur in überwiegend katholischen Gemeinden)
    if land == .sl { setze(tag(jahr, 8, 15), "Mariä Himmelfahrt") }
    // Weltkindertag
    if land == .th { setze(tag(jahr, 9, 20), "Weltkindertag") }
    // Reformationstag
    if [.bb, .mv, .sn, .st, .th, .hb, .hh, .ni, .sh].contains(land) {
      setze(tag(jahr, 10, 31), "Reformationstag")
    }
    // Allerheiligen
    if [.bw, .by, .nw, .rp, .sl].contains(land) { setze(tag(jahr, 11, 1), "Allerheiligen") }
    // Buß- und Bettag
    if land == .sn { setze(bussUndBettag(jahr: jahr), "Buß- und Bettag") }

    return f
  }

  static func istFeiertag(_ datum: Date, land: Bundesland) -> String? {
    let jahr = kalender.component(.year, from: datum)
    let tagOhneZeit = kalender.startOfDay(for: datum)
    return feiertage(jahr: jahr, land: land)[tagOhneZeit]
  }

  static func istWochenende(_ datum: Date) -> Bool {
    let wt = kalender.component(.weekday, from: datum)
    return wt == 1 || wt == 7            // 1 = Sonntag, 7 = Samstag
  }

  /// § 193 BGB / § 222 Abs. 2 ZPO: nächster Werktag, falls nötig.
  static func naechsterWerktag(_ datum: Date, land: Bundesland) -> (Date, String?) {
    var d = kalender.startOfDay(for: datum)
    var grund: String? = nil
    while true {
      if istWochenende(d) {
        grund = grund ?? (kalender.component(.weekday, from: d) == 7 ? "Samstag" : "Sonntag")
      } else if let name = istFeiertag(d, land: land) {
        grund = grund ?? name
      } else {
        return (d, grund)
      }
      d = plus(1, d)
    }
  }
}"""),
 ("kasten_achtung", "Drei Sonderfälle, die auf Gemeindeebene liegen",
  "Fronleichnam ist in Sachsen und Thüringen nur in bestimmten Gemeinden Feiertag, "
  "Mariä Himmelfahrt in Bayern nur in überwiegend katholischen Gemeinden, und Augsburg hat "
  "mit dem Friedensfest am 8. August einen eigenen Stadtfeiertag. Der Code oben behandelt "
  "diese Fälle bewusst konservativ (nicht als Feiertag, außer im Saarland). "
  "Das ist die sichere Richtung für Fristen, denn ein zu früh angesetztes Fristende ist "
  "unschädlich, ein zu spätes ruiniert das Mandat. Wollen Sie es exakt, brauchen Sie eine "
  "Gemeindetabelle und im Vorgang das Feld „Erklärungsort\" auf Gemeindeebene. "
  "Nehmen Sie in jedem Fall einen Wartungshinweis auf: Die Feiertagsgesetze der Länder "
  "ändern sich (Berlin und Mecklenburg-Vorpommern haben den Frauentag erst in den letzten "
  "Jahren eingeführt). Prüfen Sie die Tabelle jährlich im Dezember."),

 ("h3", "Schritt 2 — Fristdefinitionen mit gesetzlicher Grundlage"),
 ("p", "Jede Fristart braucht Länge, Einheit, Anfangsregel, Norm und die Angabe, ob sie "
       "Notfrist ist. Die 17 Werte des vorhandenen "
       "<font face=\"Mono\">FristTyp</font>-Enums bekommen damit eine juristische Hinterlegung:"),
 ("code", """enum Fristeinheit: String, Codable { case tage, wochen, monate, jahre }

enum Anfangsregel: String, Codable {
  case ereignis   // § 187 Abs. 1 BGB -- Ereignistag zählt nicht
  case beginn     // § 187 Abs. 2 BGB -- Tag wird mitgerechnet
}

struct Fristdefinition {
  let laenge: Int
  let einheit: Fristeinheit
  let anfang: Anfangsregel
  let norm: String
  let istNotfrist: Bool          // § 224 ZPO
  let verlaengerbar: Bool
  let hinweis: String?

  /// Zusätzliche Höchstfrist, die unabhängig von der Zustellung läuft
  /// (z. B. § 517 ZPO: fünf Monate ab Verkündung).
  var hoechstfristMonateAbVerkuendung: Int? = nil
}

extension Deadline.FristTyp {
  /// nil = keine gesetzliche Regelfrist, Datum muss manuell gesetzt werden.
  var definition: Fristdefinition? {
    switch self {
    case .berufungsfrist:
      return .init(laenge: 1, einheit: .monate, anfang: .ereignis,
                   norm: "§ 517 ZPO", istNotfrist: true, verlaengerbar: false,
                   hinweis: "Ab Zustellung des vollständigen Urteils, spätestens fünf "
                          + "Monate nach Verkündung.",
                   hoechstfristMonateAbVerkuendung: 5)
    case .berufungsbegruendung:
      return .init(laenge: 2, einheit: .monate, anfang: .ereignis,
                   norm: "§ 520 Abs. 2 ZPO", istNotfrist: false, verlaengerbar: true,
                   hinweis: "Verlängerung auf Antrag möglich; erste Verlängerung ohne "
                          + "Zustimmung des Gegners.")
    case .revisionsfrist:
      return .init(laenge: 1, einheit: .monate, anfang: .ereignis,
                   norm: "§ 548 ZPO", istNotfrist: true, verlaengerbar: false, hinweis: nil)
    case .einspruchVersaeumnisurteil:
      return .init(laenge: 2, einheit: .wochen, anfang: .ereignis,
                   norm: "§ 339 Abs. 1 ZPO", istNotfrist: true, verlaengerbar: false, hinweis: nil)
    case .widerspruchMahnbescheid:
      return .init(laenge: 2, einheit: .wochen, anfang: .ereignis,
                   norm: "§ 692 Abs. 1 Nr. 3 ZPO", istNotfrist: false, verlaengerbar: false,
                   hinweis: "Widerspruch ist auch später möglich, solange kein "
                          + "Vollstreckungsbescheid erlassen ist.")
    case .klagefristKSchG:
      return .init(laenge: 3, einheit: .wochen, anfang: .ereignis,
                   norm: "§ 4 Satz 1 KSchG", istNotfrist: false, verlaengerbar: false,
                   hinweis: "Materielle Klagefrist ab Zugang der schriftlichen Kündigung. "
                          + "Versäumung heilt nur über § 5 KSchG.")
    case .verjaehrung, .verjährungsfrist:
      return .init(laenge: 3, einheit: .jahre, anfang: .beginn,
                   norm: "§§ 195, 199 Abs. 1 BGB", istNotfrist: false, verlaengerbar: false,
                   hinweis: "Beginn erst mit Schluss des Jahres der Entstehung und "
                          + "Kenntnis -- als Anfangsdatum den 31.12. setzen.")
    default:
      return nil        // Schriftsatzfristen u. a.: Gericht setzt das Datum
    }
  }
}"""),
 ("p", "Die Liste ist bewusst nicht vollständig: Tragen Sie nur Fristen ein, deren Regel Sie "
       "belegen können, und lassen Sie den Rest <font face=\"Mono\">nil</font>. Eine fehlende "
       "Definition führt zur manuellen Eingabe — eine falsche führt zum Haftungsfall. "
       "Ergänzen Sie später etwa Anhörungsrüge (§ 321a ZPO, zwei Wochen), Beschwerde "
       "(§ 569 ZPO, zwei Wochen, Notfrist), Rechtsbeschwerde (§ 575 ZPO, ein Monat) und die "
       "arbeitsgerichtlichen Fristen des § 66 ArbGG."),

 ("h3", "Schritt 3 — Der Rechner"),
 ("code", """struct Fristherleitung: Codable, Hashable {
  var ereignis: Date
  var ereignisBezeichnung: String        // "Zustellung Urteil LG München I"
  var definition: String                 // "1 Monat, Ereignisfrist"
  var norm: String
  var rohesEnde: Date                    // vor § 193 BGB
  var verschiebungsgrund: String?        // "Samstag", "Allerheiligen", nil
  var faelligkeit: Date                  // endgültig
  var land: Bundesland
  var istNotfrist: Bool
  var rechnerVersion: String

  /// Ein Satz, der die Frist vollständig erklärt -- für Akte und Haftungsnachweis.
  var klartext: String {
    var s = "\\(ereignisBezeichnung) am \\(Self.f(ereignis)), \\(definition) "
    s += "nach \\(norm), Ablauf \\(Self.f(rohesEnde))"
    if let g = verschiebungsgrund {
      s += "; \\(g) -- daher nach § 193 BGB nächster Werktag: \\(Self.f(faelligkeit))"
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

enum FristenRechner {
  static let version = "2026.1"

  static func berechne(ereignis: Date,
                       ereignisBezeichnung: String,
                       definition d: Fristdefinition,
                       land: Bundesland,
                       verkuendung: Date? = nil) -> Fristherleitung {

    let kal = Feiertagskalender.kalender
    let start = kal.startOfDay(for: ereignis)

    // §§ 187, 188 BGB
    let komponente: Calendar.Component = {
      switch d.einheit {
      case .tage:   return .day
      case .wochen: return .weekOfYear
      case .monate: return .month
      case .jahre:  return .year
      }
    }()

    // Ereignisfrist (§ 187 Abs. 1 i.V.m. § 188 Abs. 2 Fall 1):
    //   Ende = Ereignistag + n Einheiten.
    // Beginnfrist (§ 187 Abs. 2 i.V.m. § 188 Abs. 2 Fall 2):
    //   Ende = Anfangstag + n Einheiten - 1 Tag.
    var ende = kal.date(byAdding: komponente, value: d.laenge, to: start)!
    if d.anfang == .beginn {
      ende = kal.date(byAdding: .day, value: -1, to: ende)!
    }
    // § 188 Abs. 3 BGB (31.01. + 1 Monat = 28./29.02.) erledigt Foundation
    // durch Kappen des Monatstags. Der Testfall in Kapitel J sichert das ab.

    // Höchstfrist, z. B. § 517 ZPO: fünf Monate ab Verkündung
    if let monate = d.hoechstfristMonateAbVerkuendung, let v = verkuendung {
      let grenze = kal.date(byAdding: .month, value: monate,
                            to: kal.startOfDay(for: v))!
      if grenze < ende { ende = grenze }
    }

    // § 193 BGB / § 222 Abs. 2 ZPO
    let (faellig, grund) = Feiertagskalender.naechsterWerktag(ende, land: land)

    return Fristherleitung(
      ereignis: start,
      ereignisBezeichnung: ereignisBezeichnung,
      definition: "\\(d.laenge) \\(d.einheit.rawValue), "
                + "\\(d.anfang == .ereignis ? "Ereignisfrist" : "Beginnfrist")",
      norm: d.norm,
      rohesEnde: ende,
      verschiebungsgrund: grund,
      faelligkeit: faellig,
      land: land,
      istNotfrist: d.istNotfrist,
      rechnerVersion: version
    )
  }
}"""),

 ("h3", "Schritt 4 — Anschluss an die bestehenden Modelle"),
 ("p", "<font face=\"Mono\">Deadline</font> hat bereits die Felder "
       "<font face=\"Mono\">paragraph</font> und <font face=\"Mono\">due_date</font>, "
       "<font face=\"Mono\">VorgangFrist</font> das Feld <font face=\"Mono\">quelle</font>. "
       "Die Herleitung wird dort abgelegt und ersetzt die naive Tagesdifferenz:"),
 ("code", """extension Deadline {
  /// Legt eine Frist aus einem Ereignis an -- mit vollständiger Herleitung.
  static func ausEreignis(caseId: String,
                          titel: String,
                          typ: FristTyp,
                          ereignis: Date,
                          ereignisBezeichnung: String,
                          land: Bundesland,
                          verkuendung: Date? = nil) -> (Deadline, Fristherleitung)? {
    guard let def = typ.definition else { return nil }
    let h = FristenRechner.berechne(ereignis: ereignis,
                                    ereignisBezeichnung: ereignisBezeichnung,
                                    definition: def, land: land,
                                    verkuendung: verkuendung)
    var d = Deadline(case_id: caseId, title: titel, due_date: h.faelligkeit)
    d.frist_type = typ
    d.paragraph  = h.norm
    d.notizen    = h.klartext
    d.wichtigkeit = def.istNotfrist ? .kritisch : .hoch
    return (d, h)
  }
}

extension VorgangFrist {
  /// Ersetzt die Kalendertage-Subtraktion: zählt nur verbleibende Werktage
  /// und weist auf abgelaufene Fristen hin.
  func restWerktage(land: Bundesland) -> Int {
    let kal = Feiertagskalender.kalender
    var d = kal.startOfDay(for: Date())
    let ziel = kal.startOfDay(for: datum)
    if ziel <= d { return 0 }
    var n = 0
    while d < ziel {
      d = kal.date(byAdding: .day, value: 1, to: d)!
      if !Feiertagskalender.istWochenende(d),
         Feiertagskalender.istFeiertag(d, land: land) == nil { n += 1 }
    }
    return n
  }
}"""),
 ("kasten_wichtig", "Vier Regeln für die Oberfläche, die aus der Haftung folgen",
  "<b>1 · Nie ein Datum ohne Herleitung anzeigen.</b> Jede Frist zeigt auf Antippen den "
  "<font face=\"Mono\">klartext</font>: Ereignis, Norm, Rohablauf, Verschiebungsgrund. "
  "Das ist Ihr Nachweis im Haftungsfall und der natürliche Ort für die blaue Herkunftsmarke.<br/>"
  "<b>2 · Notfristen optisch abgrenzen und Verlängerung sperren.</b> Bei "
  "<font face=\"Mono\">istNotfrist</font> darf die App keinen Verlängerungsantrag anbieten "
  "(§ 224 ZPO).<br/>"
  "<b>3 · Vorfrist automatisch mitsetzen.</b> Kanzleipraxis ist eine Vorfrist rund eine Woche "
  "vor Ablauf. Das Feld <font face=\"Mono\">erinnerung_tage</font> gibt es schon — setzen Sie "
  "es bei Notfristen auf mindestens 7 und erzeugen Sie einen eigenen Eintrag, keine bloße "
  "Benachrichtigung.<br/>"
  "<b>4 · Berechnetes Datum überschreibbar, aber protokolliert.</b> Wenn der Anwalt das Datum "
  "ändert, wechselt die Herkunftsmarke von Formel auf Mensch, und die Abweichung wird "
  "festgehalten. Nie stillschweigend überschreiben."),
]
