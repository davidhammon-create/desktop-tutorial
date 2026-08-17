# -*- coding: utf-8 -*-
"""Inhalt Teil 3: Kapitel F–K, Teil III (Reihenfolge/Wert), Teil IV (Grenzen)."""

TEIL3 = [
 # ============================================================ KAPITEL F
 ("seitenumbruch", None),
 ("h2", "F · Richterprofile rechtskonform umbauen"),
 ("etikett", "kritisch · Aufwand: 1 Tag Rückbau, dann Rechtsprüfung"),

 ("h3", "Was falsch ist"),
 ("p", "Das Modul führt namentliche Profile mit Erfolgsquoten. In den Demo-Daten steht "
       "„Dr. Sabine König, Arbeitsgericht München, Klägerquote 58 %\" — ein Name, der wie eine "
       "reale Person an einem realen Gericht aussieht "
       "(<font face=\"Mono\">DemoDataSeeder.swift:100–101, 453</font>). Dazu kommen "
       "Netzwerkgraphen, die Richter mit Anwälten und Verfahren verknüpfen "
       "(<font face=\"Mono\">RichterProfileView.swift:913–1050</font>)."),

 ("h3", "Warum das kein Programmierfehler ist, sondern eine Produktfrage"),
 ("p", "Drei Fronten laufen hier zusammen. Erstens Datenschutz: Erfolgsquoten einzelner "
       "Richter sind personenbezogene Daten, und für ihre Verarbeitung braucht es eine "
       "Rechtsgrundlage nach Art. 6 DSGVO, dazu die Information der Betroffenen nach Art. 14 "
       "— also der Richter. Zweitens Berufsrecht und richterliche Unabhängigkeit: Eine "
       "Kanzleisoftware, die Richter statistisch bewertet, wird von Gerichten und Kammern "
       "nicht neutral aufgenommen. Drittens der europäische Ausblick: Frankreich hat das "
       "Profiling von Richtern mit Art. 33 der Loi 2019-222 unter Strafe gestellt. Wenn Sie "
       "über Deutschland hinaus verkaufen wollen, ist dieses Modul ein Ausschlusskriterium."),

 ("h3", "Was Sie sofort tun"),
 ("nummerierte_liste", [
   ("Demo-Daten mit Personennamen löschen",
    "Der erfundene Name an einem echten Gericht ist das Erste, was ein Prüfer sieht. "
    "Ersetzen Sie ihn durch eine erkennbare Platzhalterbezeichnung wie „3. Kammer, "
    "Beispielgericht\" — ohne Personennamen."),
   ("Erfolgsquoten je Person aus der Auslieferung nehmen",
    "Feature-Flag statt Löschen (siehe Kapitel K), damit die Arbeit nicht verloren ist. "
    "Standardmäßig aus, nicht einschaltbar ohne dokumentierte Rechtsprüfung."),
   ("Netzwerkgraph auf Institutionen umstellen",
    "Gericht, Kammer, Gegneranwaltskanzlei — das sind Organisationen, keine natürlichen "
    "Personen. Der analytische Nutzen bleibt fast vollständig erhalten."),
 ]),

 ("h3", "Was rechtlich tragfähig ist — und fachlich fast genauso nützlich"),
 ("p", "Es gibt zwei Formen, die ein Anwalt ohnehin führen darf und die den eigentlichen "
       "Nutzen liefern:"),
 ("tabelle", ["Form", "Warum tragfähig", "Was sie leistet"], [
   ["Eigene Verfahrensnotiz zum konkreten Fall",
    "Handaktenführung ist anwaltliche Pflicht (§ 50 BRAO). Notizen über den Verlauf eines "
    "eigenen Verfahrens sind normale Aktenarbeit, keine Profilbildung.",
    "„In diesem Verfahren wurde ein Sachverständigengutachten angeordnet, "
    "der Vergleichsvorschlag kam im ersten Termin.\" — genau das, was beim nächsten Mal hilft."],
   ["Aggregierte Statistik je Gericht oder Kammer",
    "Bezieht sich auf eine Institution, nicht auf eine Person — kein Personenbezug, "
    "solange keine Zuordnung zu Einzelpersonen möglich ist.",
    "„Bei diesem Gericht endeten 8 von 11 eigenen Verfahren im Vergleich, "
    "durchschnittliche Dauer 9 Monate.\" — belastbar, weil aus eigenen Fällen."],
 ]),
 ("kasten_achtung", "Die Schwelle, die Sie technisch erzwingen müssen",
  "Eine Kammer mit einem Einzelrichter <b>ist</b> eine bestimmbare Person — die Aggregation "
  "nach Institution hilft dann nicht. Bauen Sie die Schwelle in den Code ein, nicht in die "
  "Anleitung: Statistiken erst ab einer Mindestzahl eigener Verfahren anzeigen, und "
  "Einzelrichter-Spruchkörper von der Auswertung ausnehmen. Sonst haben Sie den Personenbezug "
  "durch die Hintertür wieder drin."),
 ("code", """/// Aggregierte Erfahrungswerte -- ohne Personenbezug, mit erzwungener Schwelle.
struct GerichtsErfahrung: Identifiable, Codable {
  var id = UUID()
  var gericht: String              // "Landgericht München I"
  var spruchkoerper: String?       // "3. Zivilkammer" -- nie ein Personenname
  var istEinzelrichter: Bool

  var anzahlEigeneVerfahren: Int
  var davonVergleich: Int
  var davonUrteil: Int
  var durchschnittsdauerMonate: Double

  /// Mindestzahl, unter der nichts angezeigt wird.
  static let mindestFallzahl = 5

  /// Anzeigbar nur ohne Personenbezug und mit ausreichender Fallzahl.
  var darfAngezeigtWerden: Bool {
    !istEinzelrichter && anzahlEigeneVerfahren >= Self.mindestFallzahl
  }

  /// Ehrliche Aussage statt Quote: nennt immer die Grundgesamtheit.
  var klartext: String? {
    guard darfAngezeigtWerden else { return nil }
    return "\\(davonVergleich) von \\(anzahlEigeneVerfahren) eigenen Verfahren endeten "
         + "im Vergleich, Durchschnittsdauer "
         + String(format: "%.1f", durchschnittsdauerMonate) + " Monate. "
         + "Eigene Erfahrungswerte, keine Statistik über Personen."
  }
}"""),
 ("p", "Wenn Sie am Personenbezug festhalten wollen, brauchen Sie vor jeder Auslieferung: "
       "eine dokumentierte Interessenabwägung nach Art. 6 Abs. 1 lit. f DSGVO, ein Konzept "
       "für die Information der Betroffenen nach Art. 14, eine berufsrechtliche Einschätzung "
       "durch Ihre Rechtsanwaltskammer, und die Klärung, was bei Auskunfts- oder "
       "Löschungsverlangen eines Richters passiert. Das ist kein Entwicklungsthema mehr, "
       "sondern eine Vorstandsentscheidung."),

 # ============================================================ KAPITEL G
 ("seitenumbruch", None),
 ("h2", "G · KI-Verordnung und Berufsrecht ehrlich erfüllen"),
 ("etikett", "erheblich · Aufwand: 2 Tage Dokumentation, 1 Tag Code"),

 ("h3", "Was falsch ist"),
 ("p", "Die App zeigt ein Schild-Symbol „EU AI Act\" mit Verweis auf Art. 13 und Art. 14 "
       "(<font face=\"Mono\">KITransparenzView.swift:371–377</font>). Ein Etikett ist keine "
       "Konformität. Art. 13 und 14 richten sich an Anbieter von Hochrisiko-Systemen und "
       "setzen eine Klassifizierung und Bewertung voraus, die nie stattgefunden hat. "
       "Wer eine Konformität behauptet, die er nicht nachweisen kann, hat neben dem "
       "Aufsichtsrisiko ein wettbewerbsrechtliches."),

 ("h3", "Schritt 1 — Klassifizierung dokumentieren"),
 ("p", "Die erste Frage ist, ob die App überhaupt ein Hochrisiko-System ist. Anhang III der "
       "KI-Verordnung nennt unter Nummer 8 Systeme, die <b>von einer Justizbehörde oder in "
       "deren Auftrag</b> verwendet werden. Ein Werkzeug für Rechtsanwälte fällt "
       "voraussichtlich nicht darunter — die Kanzlei ist keine Justizbehörde. Das ist die "
       "wahrscheinliche und für Sie günstige Einordnung, aber sie muss <b>schriftlich "
       "begründet</b> vorliegen, nicht bloß angenommen werden. Legen Sie ein zweiseitiges "
       "Dokument ins Projekt, das festhält: Zweckbestimmung, Nutzergruppe, warum Anhang III "
       "Nr. 8 nicht greift, welche Rolle Sie einnehmen (bei Nutzung eines fremden "
       "Sprachmodells sind Sie Betreiber, nicht Anbieter), und welche Transparenzpflichten "
       "aus Art. 50 dennoch gelten. Dieses Dokument ist das, was ein Käufer oder eine "
       "Aufsichtsbehörde sehen will."),
 ("kasten_achtung", "Zeitlich ist das jetzt relevant",
  "Die KI-Verordnung ist seit August 2024 in Kraft, die Pflichten treten gestuft in "
  "Anwendung. Die Stufen für Anhang-III-Systeme greifen ab August 2026 — also ab jetzt. "
  "Prüfen Sie den aktuellen Anwendungsstand, bevor Sie Aussagen treffen; ich konnte den "
  "Verordnungstext hier nicht abrufen und gebe den Rahmen aus dem Gedächtnis wieder."),

 ("h3", "Schritt 2 — Das Siegel durch ehrliche Aussagen ersetzen"),
 ("p", "Ersetzen Sie das Schild-Symbol durch Aussagen, die stimmen und die Sie belegen "
       "können. Inhaltlich ist das stärker, weil es beschreibt, was die App wirklich "
       "besonders macht:"),
 ("tabelle", ["Statt", "Besser"], [
   ["Schild „EU AI Act\" mit Häkchen",
    "„KI-Ausgaben sind Vorschläge und als solche gekennzeichnet. Die Entscheidung "
    "trifft ausschließlich der Bearbeiter.\""],
   ["„Art. 13 – Transparenzpflicht ✓\"",
    "„Jeder KI-Aufruf wird mit Zeitpunkt, Modell, Eingabe und Ausgabe protokolliert. "
    "Das Protokoll ist im Reiter KI-Protokoll einsehbar und exportierbar.\""],
   ["„Art. 14 – Menschliche Aufsicht ✓\"",
    "„Keine KI-Ausgabe wird ohne Bestätigung übernommen. Die Herkunftsmarke zeigt bei jeder "
    "Zahl, ob sie berechnet, vorgeschlagen oder bestätigt ist.\""],
 ]),
 ("p", "Der zweite und dritte Satz sind keine Behauptungen, sondern Beschreibungen dessen, "
       "was der Code tatsächlich tut. Damit erfüllen Sie den Geist der Transparenzpflicht "
       "besser als mit jedem Siegel — und Sie können es beweisen."),

 ("h3", "Schritt 3 — Protokollierung so ausbauen, dass sie beweiskräftig ist"),
 ("p", "Der vorhandene <font face=\"Mono\">KIProtokollService</font> ist die richtige Stelle. "
       "Er braucht Vollständigkeit und Unveränderlichkeit:"),
 ("code", """struct KIProtokollEintrag: Codable, Identifiable {
  var id = UUID()
  var zeitpunkt: Date
  var nutzer: String
  var fallId: String?
  var modell: String              // "claude-...", "llama3 lokal" -- konkret, nicht "KI"
  var anbieter: String            // wer die Verarbeitung durchführt
  var verarbeitungsort: String    // "lokal" oder Region -- für Art. 44 ff. DSGVO
  var zweck: String               // "Argumentvorschläge", "Dokumentanalyse"

  /// Ein- und Ausgabe als Hash, nicht als Klartext: das Protokoll selbst
  /// soll kein zweiter Speicherort für Mandantengeheimnisse werden.
  var eingabeHash: String
  var eingabeZeichen: Int
  var ausgabeHash: String
  var ausgabeZeichen: Int

  var uebernommen: Bool           // hat der Mensch den Vorschlag übernommen?
  var uebernommenAm: Date?
  var uebernommenVon: String?

  /// Verkettung: jeder Eintrag hängt am Hash des Vorgängers. Nachträgliches
  /// Ändern oder Entfernen einzelner Einträge fällt damit auf.
  var vorgaengerHash: String
  var eigenerHash: String
}"""),
 ("kasten_wichtig", "Warum die Verkettung den Unterschied macht",
  "Ein Protokoll, das man unbemerkt bearbeiten kann, ist im Streitfall wertlos. Durch die "
  "Verkettung jedes Eintrags mit dem Hash seines Vorgängers entsteht eine Kette, deren "
  "Bruch auffällt. Zusammen mit dem Rechenbeleg aus Kapitel C und der Herkunftsmarke haben "
  "Sie dann drei ineinandergreifende Nachweise: <b>welche Zahl</b> mit <b>welcher Formel</b> "
  "aus <b>welcher Eingabe</b> entstand, ob eine <b>KI beteiligt</b> war, und <b>wer sie "
  "bestätigt</b> hat. Das ist die Beweiskette, die eine Kanzlei im Haftungsfall braucht — "
  "und kein Wettbewerber bietet sie in dieser Klarheit."),

 # ============================================================ KAPITEL H
 ("seitenumbruch", None),
 ("h2", "H · Auftragsverarbeitung, § 203 StGB, § 43e BRAO"),
 ("etikett", "erheblich · Aufwand: Vertragsarbeit, kein Code"),

 ("h3", "Die Lage"),
 ("p", "Die KI-Aufrufe laufen über Base44 (<font face=\"Mono\">app.base44.com</font>, "
       "<font face=\"Mono\">Base44Client.swift</font>). Sobald Mandantendaten den Rechner "
       "verlassen, greift eine Kette von Pflichten, die vollständig erfüllt sein muss — "
       "sonst ist die Nutzung für einen Anwalt berufsrechtswidrig, unabhängig davon, wie gut "
       "die Software ist. Positiv: Die Souveränitätsschicht prüft den Abfluss bereits. Sie "
       "muss nur konsequent durchgesetzt und vertraglich unterlegt werden."),
 ("tabelle", ["Pflicht", "Was konkret zu tun ist"], [
   ["§ 43e BRAO — Inanspruchnahme von Dienstleistungen",
    "Vertrag in Textform mit jedem Dienstleister, der Zugang zu Mandatsdaten haben kann. "
    "Er muss zur Verschwiegenheit verpflichtet und darüber belehrt werden, dass ihn "
    "§ 203 StGB trifft. Gilt für Base44 und für den Modellanbieter dahinter."],
   ["§ 203 Abs. 3 StGB — mitwirkende Personen",
    "Offenbarung an Dienstleister ist nur zulässig, soweit sie für ihre Tätigkeit "
    "erforderlich ist. Praktisch: Datenminimierung im Prompt, keine Klarnamen, "
    "wo Pseudonyme genügen."],
   ["Art. 28 DSGVO — Auftragsverarbeitung",
    "Auftragsverarbeitungsvertrag mit Weisungsbindung, Subunternehmerregelung, "
    "Löschkonzept, Kontrollrechten."],
   ["Art. 44 ff. DSGVO — Drittlandtransfer",
    "Klären, wo verarbeitet wird. Bei Verarbeitung außerhalb der EU: Transfergrundlage "
    "und Transfer-Folgenabschätzung. Das Feld „Verarbeitungsort\" aus Kapitel G "
    "macht das im Protokoll nachweisbar."],
   ["Art. 32 DSGVO — Sicherheit",
    "Verschlüsselung im Transport und at rest, Zugriffskonzept, Löschfristen."],
 ]),
 ("h3", "Die technische Konsequenz, die Sie ziehen sollten"),
 ("p", "Machen Sie den Offline-Betrieb zur gleichwertigen Betriebsart, nicht zur Fußnote. "
       "Die App unterstützt lokale Modelle bereits "
       "(<font face=\"Mono\">KIKonfiguration</font> mit Offline-Modus). Wenn eine Kanzlei die "
       "Suite vollständig ohne Datenabfluss betreiben kann, entfällt die ganze Vertragskette — "
       "und Sie haben das stärkste Verkaufsargument im deutschen Markt. Konkret: "
       "Standardeinstellung auf „lokal\", Cloud nur nach ausdrücklicher, protokollierter "
       "Freigabe je Fall, und ein sichtbarer Zustandsanzeiger, der jederzeit sagt, wohin "
       "Daten gehen."),

 # ============================================================ KAPITEL I
 ("seitenumbruch", None),
 ("h2", "I · Anbindungen: beA, Kanzleisoftware, Kalender, E-Rechnung"),
 ("etikett", "erheblich · Aufwand: pro Anbindung Wochen bis Monate, teils fremdbestimmt"),

 ("p", "Ohne Anbindungen bleibt die Suite ein Zweitsystem mit Doppelpflege — der klassische "
       "Grund, aus dem Kanzleien Zusatzsoftware nach wenigen Wochen abschalten. "
       "Die vier relevanten Richtungen, mit ehrlicher Einschätzung des Aufwands:"),
 ("tabelle", ["Anbindung", "Weg", "Realistische Einschätzung"], [
   ["beA (§ 130d ZPO)",
    "Die BRAK stellt eine Schnittstelle für Kanzleisoftware bereit; der Weg führt über eine "
    "formale Abstimmung mit der BRAK. Datenformat der Justiz ist XJustiz, der "
    "Übermittlungsweg EGVP/OSCI.",
    "Nicht in Eigenregie an einem Wochenend­projekt machbar. Rechnen Sie mit einem "
    "Zulassungs- und Testverfahren. Erster Schritt: schriftliche Anfrage an die BRAK zu "
    "Schnittstelle und Voraussetzungen. Konditionen und technische Details bitte dort "
    "verifizieren — ich konnte sie hier nicht prüfen."],
   ["DATEV",
    "DATEV bietet Schnittstellen für Partnerlösungen und einen Marktplatz mit "
    "Partnerprogramm.",
    "Erfordert Partnerstatus. Für die Anwaltsabrechnung ist die Buchhaltungs­schnittstelle "
    "der wichtigste Teil."],
   ["RA-MICRO, Advoware, Actaport",
    "Proprietäre Schnittstellen, jeweils Partnerprogramm.",
    "Strategisch die Frage: Konkurrieren oder ergänzen? Als Ergänzung zu einem "
    "bestehenden Kanzleisystem haben Sie eine viel bessere Verkaufsgeschichte."],
   ["Kalender und E-Rechnung",
    "EventKit ist bereits eingebunden; für Exchange und Google zusätzlich CalDAV. "
    "Für Rechnungen an unternehmerische Mandanten die strukturierten Formate "
    "XRechnung/ZUGFeRD.",
    "Das ist der Teil, den Sie selbst in Tagen erledigen können — und der sofort "
    "spürbaren Nutzen bringt."],
 ]),
 ("kasten_wichtig", "Die Reihenfolge, die ich empfehle",
  "Fangen Sie <b>nicht</b> mit beA an, obwohl es das prominenteste Thema ist. Beginnen Sie "
  "mit Kalender-Synchronisation und einem sauberen Export: Wenn die berechneten Fristen "
  "aus Kapitel A zuverlässig im Outlook- oder Google-Kalender der Kanzlei landen, hat die "
  "App ihren ersten echten, spürbaren Nutzen — ohne fremde Zulassung, ohne Partnerprogramm, "
  "in wenigen Tagen. beA und DATEV sind Projekte für die Zeit, in der Sie zahlende Nutzer "
  "und damit ein Argument für die Partnerprogramme haben."),

 # ============================================================ KAPITEL J
 ("seitenumbruch", None),
 ("h2", "J · Tests — es gibt bisher keinen einzigen"),
 ("etikett", "kritisch · Aufwand: 2 Tage Grundgerüst, dann laufend"),

 ("h3", "Der Befund"),
 ("p", "Im gesamten Projekt existiert kein Testziel und keine Testdatei. Das einzige, was "
       "„Test\" heißt, ist <font face=\"Mono\">scripts/test-ki.sh</font> — ein Shell-Skript "
       "für einen Verbindungstest. 85.000 Zeilen ohne Testabdeckung sind bei einer "
       "Nutzeroberfläche verzeihlich. Bei Fristen und Gebühren sind sie es nicht: Genau die "
       "Stellen, an denen ein Fehler ein Mandat kostet, sind ungeprüft."),

 ("h3", "Schritt 1 — Logik aus dem ausführbaren Ziel herausziehen"),
 ("p", "Aktuell ist alles ein <font face=\"Mono\">executableTarget</font> mit "
       "<font face=\"Mono\">-parse-as-library</font>. Ein Testziel kann darauf nur mühsam "
       "zugreifen. Lösen Sie das architektonisch — die Rechenlogik gehört ohnehin nicht in "
       "dieselbe Einheit wie die Oberfläche:"),
 ("code", """// Package.swift
let package = Package(
  name: "FenlynineOS",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "FenlynineOS", targets: ["FenlynineOS"])
  ],
  targets: [
    // NEU: reine Logik, ohne SwiftUI -- testbar und wiederverwendbar
    .target(name: "FenlynineOSKern", path: "Sources/FenlynineOSKern"),

    .executableTarget(
      name: "FenlynineOS",
      dependencies: ["FenlynineOSKern"],
      path: "Sources/FenlynineOS",
      resources: [.process("Resources")],
      swiftSettings: [.unsafeFlags(["-parse-as-library"])]
    ),

    // NEU: Testziel
    .testTarget(name: "FenlynineOSKernTests",
                dependencies: ["FenlynineOSKern"],
                path: "Tests/FenlynineOSKernTests")
  ]
)"""),
 ("p", "Nach <font face=\"Mono\">Sources/FenlynineOSKern</font> wandern: Feiertagskalender, "
       "FristenRechner, RVG, Kostenrisiko, Szenariorechner, Kalibrierung, "
       "DeterministischerZufall. Alles ohne <font face=\"Mono\">import SwiftUI</font>. "
       "Das ist zugleich der Umbau, der die App wartbar macht."),

 ("h3", "Schritt 2 — Die Testfälle, die wirklich zählen"),
 ("p", "Diese Fälle sind mit ihren erwarteten Ergebnissen ausgerechnet. Wenn Ihr Code sie "
       "alle besteht, funktioniert die Fristenberechnung:"),
 ("testtabelle", ["Ereignis", "Frist", "Land", "Erwartet", "Warum"], [
   ["Zustellung Mo 15.04.2024", "1 Monat Berufung", "BY", "15.05.2024 (Mi)",
    "§ 188 Abs. 2: gleicher Zahltag im Folgemonat, Werktag"],
   ["Zustellung Mi 31.01.2024", "1 Monat", "BY", "29.02.2024 (Do)",
    "§ 188 Abs. 3: Tag fehlt im Februar, Schaltjahr"],
   ["Zustellung Sa 30.03.2024", "2 Wochen Einspruch", "NW", "15.04.2024 (Mo)",
    "Rohablauf 13.04. ist Samstag → § 193 BGB nächster Werktag"],
   ["Kündigung Mi 20.12.2023", "3 Wochen § 4 KSchG", "HH", "10.01.2024 (Mi)",
    "Ereignisfrist über den Jahreswechsel, keine Verschiebung"],
   ["Zustellung Do 28.03.2024", "2 Wochen", "BW", "11.04.2024 (Do)",
    "Gründonnerstag als Ereignistag ist unschädlich"],
   ["Rohablauf 01.05.2025", "—", "alle", "02.05.2025 (Fr)",
    "Tag der Arbeit ist bundesweit Feiertag"],
   ["Rohablauf Do 31.10.2024", "—", "NI", "01.11.2024 (Fr)",
    "Reformationstag ist in NI Feiertag, Allerheiligen nicht"],
   ["Rohablauf Do 31.10.2024", "—", "NW", "31.10.2024 (Do)",
    "In NW kein Feiertag — dieselbe Frist, anderes Ergebnis"],
   ["Anspruch entstanden 2024", "3 Jahre Verjährung", "BY", "31.12.2027 (Fr)",
    "§ 199: Beginn mit Jahresschluss; Beginnfrist ab 31.12.2024"],
 ]),
 ("kasten_wichtig", "Der siebte und achte Fall sind der wichtigste Test",
  "Dieselbe Frist, dasselbe Datum, zwei Bundesländer, zwei Ergebnisse. Wenn Ihr Test diese "
  "beiden Fälle unterscheidet, haben Sie bewiesen, dass der Erklärungsort tatsächlich "
  "durchgereicht wird und nicht irgendwo eine Kanzlei-Standardeinstellung greift. Das ist "
  "der Fehler, der in der Praxis passiert und den niemand bemerkt, bis eine Frist reißt."),
 ("code", """import XCTest
@testable import FenlynineOSKern

final class FristenRechnerTests: XCTestCase {

  private func datum(_ t: Int, _ m: Int, _ j: Int) -> Date {
    Feiertagskalender.tag(j, m, t)
  }

  func testMonatsfristGleicherZahltag() {
    let h = FristenRechner.berechne(
      ereignis: datum(15, 4, 2024), ereignisBezeichnung: "Zustellung",
      definition: Deadline.FristTyp.berufungsfrist.definition!, land: .by)
    XCTAssertEqual(h.faelligkeit, datum(15, 5, 2024))
    XCTAssertNil(h.verschiebungsgrund)
    XCTAssertTrue(h.istNotfrist)
  }

  /// § 188 Abs. 3 BGB -- verlässt sich darauf, dass Foundation den
  /// Monatstag kappt. Genau deshalb muss dieser Test existieren.
  func testFehlenderMonatstagSchaltjahr() {
    let h = FristenRechner.berechne(
      ereignis: datum(31, 1, 2024), ereignisBezeichnung: "Zustellung",
      definition: Deadline.FristTyp.berufungsfrist.definition!, land: .by)
    XCTAssertEqual(h.faelligkeit, datum(29, 2, 2024))
  }

  func testSamstagVerschiebung() {
    let h = FristenRechner.berechne(
      ereignis: datum(30, 3, 2024), ereignisBezeichnung: "Zustellung",
      definition: Deadline.FristTyp.einspruchVersaeumnisurteil.definition!, land: .nw)
    XCTAssertEqual(h.rohesEnde, datum(13, 4, 2024))
    XCTAssertEqual(h.faelligkeit, datum(15, 4, 2024))
    XCTAssertEqual(h.verschiebungsgrund, "Samstag")
  }

  /// Der entscheidende Test: gleiches Datum, verschiedene Länder.
  func testErklaerungsortEntscheidet() {
    let (niedersachsen, grundNI) =
      Feiertagskalender.naechsterWerktag(datum(31, 10, 2024), land: .ni)
    XCTAssertEqual(niedersachsen, datum(1, 11, 2024))
    XCTAssertEqual(grundNI, "Reformationstag")

    let (nordrhein, grundNW) =
      Feiertagskalender.naechsterWerktag(datum(31, 10, 2024), land: .nw)
    XCTAssertEqual(nordrhein, datum(31, 10, 2024))
    XCTAssertNil(grundNW)
  }

  func testOsterberechnung() {
    // Bekannte Ostersonntage als Stützstellen
    XCTAssertEqual(Feiertagskalender.ostersonntag(jahr: 2024), datum(31, 3, 2024))
    XCTAssertEqual(Feiertagskalender.ostersonntag(jahr: 2025), datum(20, 4, 2025))
    XCTAssertEqual(Feiertagskalender.ostersonntag(jahr: 2026), datum(5, 4, 2026))
  }
}

final class RVGTests: XCTestCase {
  /// Golden-Test: schützt die Tabelle gegen Tippfehler und stellt sicher,
  /// dass eine RVG-Änderung nicht unbemerkt bleibt.
  func testGebuehrenStuetzstellen() {
    XCTAssertEqual(RVG.gebuehr(streitwert: 500), 49)
    XCTAssertEqual(RVG.gebuehr(streitwert: 5_000), 334)
    XCTAssertEqual(RVG.gebuehr(streitwert: 13_000), 666)
    XCTAssertEqual(RVG.gebuehr(streitwert: 25_000), 874)
    XCTAssertEqual(RVG.gebuehr(streitwert: 50_000), 1_279)
    XCTAssertEqual(RVG.gebuehr(streitwert: 200_000), 2_219)
    // Stufengrenzen: 5.000,01 fällt in die nächste Stufe
    XCTAssertEqual(RVG.gebuehr(streitwert: 5_000.01), 390)
    // Jenseits der Tabelle bewusst kein Wert
    XCTAssertNil(RVG.gebuehr(streitwert: 600_000))
  }
}

final class ReproduzierbarkeitTests: XCTestCase {
  /// Zweimal dieselbe Eingabe muss dieselbe Zahl ergeben -- sonst ist
  /// keine Aussage der App im Haftungsfall belegbar.
  func testGleicherStartwertGleichesErgebnis() {
    var a = DeterministischerZufall(startwert: 42)
    var b = DeterministischerZufall(startwert: 42)
    for _ in 0..<1000 { XCTAssertEqual(a.next(), b.next()) }
  }
}"""),
 ("kasten_achtung", "Ein Hinweis zu den Osterdaten und Wochentagen",
  "Die Stützstellen im Ostertest und die Wochentage in der Fallsammlung habe ich gerechnet, "
  "nicht nachgeschlagen. Prüfen Sie sie beim ersten Testlauf gegen einen Kalender — wenn "
  "einer abweicht, ist wahrscheinlich meine Angabe falsch und nicht Ihr Code. "
  "Der Wert der Tabelle liegt in der Systematik der Fälle, nicht in meiner Rechenkunst."),

 # ============================================================ KAPITEL K
 ("seitenumbruch", None),
 ("h2", "K · Von dreißig Modulen auf einen Arbeitsablauf"),
 ("etikett", "strategisch · Aufwand: 2 Tage Technik, dann Entscheidungen"),

 ("h3", "Was falsch ist"),
 ("p", "Über dreißig Bereiche, die größte Einzeldatei heißt "
       "<font face=\"Mono\">TabsPlaceholder.swift</font> und hat 1.979 Zeilen. Zugleich fehlt "
       "der eine Ablauf, den jede Kanzlei täglich braucht: Post kommt herein, Frist wird "
       "berechnet und notiert, Wiedervorlage, Ausgangskontrolle, erledigt. "
       "Ihr Wunsch, die Bedienung radikal zu vereinfachen, war richtig — er behandelt aber "
       "das Symptom. Die Ursache ist, dass zu viel gebaut und zu wenig entschieden wurde."),

 ("h3", "Wie Sie kürzen, ohne Arbeit zu vernichten"),
 ("p", "Nichts löschen, alles abschaltbar machen. Dann bleibt die Substanz erhalten, und die "
       "Oberfläche wird trotzdem ruhig. Die Registry der Module ist bereits vorhanden — "
       "<font face=\"Mono\">SeitenleistenEintrag</font> —, sie braucht nur eine Reifestufe:"),
 ("code", """/// Reifegrad eines Moduls. Bestimmt, ob und wie es ausgeliefert wird.
enum Modulreife: String, Codable {
  case produktiv     // getestet, verantwortbar, sichtbar
  case beta          // nutzbar, sichtbar mit Hinweis
  case werkstatt     // nur mit gesetztem Schalter, nicht in der Navigation
  case gesperrt      // vorhanden, aber rechtlich ungeklärt -- nie sichtbar
}

extension SeitenleistenEintrag {
  var reife: Modulreife {
    switch self {
    // Der eine Ablauf, der zuerst fertig wird:
    case .zeitleiste, .berufspflicht, .dokumente, .lexara:
      return .produktiv
    case .dashboard, .aufgaben, .honorare, .mandanten, .einstellungen:
      return .beta
    // Rechtlich ungeklärt -- siehe Kapitel F:
    case .richterprofile:
      return .gesperrt
    // Gute Ideen, aber ohne validierten Bedarf:
    default:
      return .werkstatt
    }
  }

  var istSichtbar: Bool {
    switch reife {
    case .produktiv, .beta: return true
    case .werkstatt: return UserDefaults.standard.bool(forKey: "fenlynineos_werkstatt")
    case .gesperrt: return false
    }
  }
}"""),
 ("p", "In der Modulliste wird dann nur noch nach "
       "<font face=\"Mono\">istSichtbar</font> gefiltert. Der Schalter „Werkstatt\" in den "
       "Einstellungen macht die übrigen Module für Sie selbst und für Vorführungen wieder "
       "sichtbar. Aus dreißig Einträgen werden neun — ohne dass eine Zeile Code verloren geht."),

 ("h3", "Der Ablauf, den ich zuerst fertigstellen würde"),
 ("ablauf", [
   ("Post erfassen", "Gerichtspost oder Schreiben eingeben, Zustelldatum festhalten. "
                     "Ein Feld, ein Datum, ein Dokument."),
   ("Frist berechnen", "Fristart wählen, Erklärungsort wählen, Kapitel A rechnet. "
                       "Herleitung im Klartext, Notfrist gekennzeichnet."),
   ("Notieren und Vorfrist", "Frist und Vorfrist in Kalender und Liste, mit Verantwortlichem."),
   ("Wiedervorlage", "Am Vorfristtag erscheint der Fall oben — nicht als Nachricht, "
                     "sondern als Arbeitsvorrat."),
   ("Ausgangskontrolle", "Abends die gestufte Kontrolle nach BGH, mit Protokoll. "
                         "Der Berufspflicht-Desk kann das schon."),
   ("Erledigt", "Frist streichen — sichtbar bleibend, wie es die Rechtsprechung verlangt."),
 ]),
 ("p", "Sechs Schritte. Wenn diese Kette lückenlos funktioniert, hat die App einen Nutzen, "
       "für den Kanzleien zahlen — und alles Übrige darf in der Werkstatt warten, bis ein "
       "zahlender Nutzer danach fragt."),

 # ============================================================ TEIL III
 ("seitenumbruch", None),
 ("h1", "Teil III — Reihenfolge, Aufwand, Wirkung"),

 ("p", "Die Reihenfolge ist nicht beliebig: Sie ist so gewählt, dass nach jedem Schritt "
       "etwas gewonnen ist, und dass die haftungskritischen Punkte vor den kosmetischen "
       "kommen. Die Aufwände sind grobe Schätzungen für eine erfahrene Entwicklerin, "
       "Rechtsprüfungen nicht eingerechnet."),
 ("plan_tabelle", [
   ("1", "A", "Fristenberechnung mit Tests", "5–8 Tage",
    "Aus „nicht einsetzbar\" wird „einsetzbar\". Der größte einzelne Wertsprung."),
   ("2", "F", "Richterprofile stilllegen", "1 Tag",
    "Beseitigt das Risiko, das das ganze Produkt untragbar machen kann."),
   ("3", "J", "Kern herauslösen, Testziel anlegen", "2 Tage",
    "Voraussetzung dafür, dass Schritt 1 dauerhaft hält."),
   ("4", "B", "Prognosen zu Szenario-Rechner umbauen", "3–4 Tage",
    "Aus einer angreifbaren Behauptung wird ein verteidigungsfähiges Werkzeug."),
   ("5", "C", "Reproduzierbarkeit und Rechenbeleg", "2 Tage",
    "Macht jede Zahl nachweisbar — Grundlage für Haftpflicht und Verkauf."),
   ("6", "D+E", "RVG vervollständigen, Passwörter härten", "2 Tage",
    "Beseitigt einen Rechenfehler und eine Sicherheitslücke."),
   ("7", "G", "Klassifizierung dokumentieren, Siegel ersetzen", "3 Tage",
    "Aus einem Compliance-Problem wird ein Compliance-Nachweis."),
   ("8", "K", "Module auf Reifestufen, ein Ablauf fertig", "2 Tage + Entscheidungen",
    "Die App wird lernbar. Erst hier lohnt eine Vorführung."),
   ("9", "I", "Kalender-Synchronisation und Export", "3–5 Tage",
    "Erster spürbarer Alltagsnutzen ohne fremde Zulassung."),
   ("10", "H+I", "Verträge, dann beA und DATEV", "Monate, teils fremdbestimmt",
    "Der Schritt vom Werkzeug zum Kanzleisystem — erst mit zahlenden Nutzern angehen."),
 ]),
 ("p", "Die Schritte 1 bis 8 summieren sich auf etwa <b>vier bis fünf Wochen "
       "Entwicklungsarbeit</b>. Das ist der Abstand zwischen dem heutigen Stand und einer "
       "App, die eine Kanzlei verantwortlich einsetzen kann."),

 ("h3", "Was das für den Wert bedeutet"),
 ("wert_tabelle", [
   ("Heute", "Nutzwert nahe null; Marktwert als Asset 10–40 T€",
    "Fristen nicht berechenbar, Prognosen nicht belegbar, ein Modul rechtlich riskant."),
   ("Nach Schritt 1–3 (rund zwei Wochen)", "Erstmals einsetzbar",
    "Eine Kanzlei kann die Fristenverwaltung verantwortlich nutzen. Ab hier ist eine "
    "Pilotkanzlei sinnvoll — und ohne Pilotkanzlei ist jede weitere Zahl geraten."),
   ("Nach Schritt 1–8 (vier bis fünf Wochen)", "Verkaufbares Nischenprodukt",
    "Fristen- und Haftungsschutz mit durchgehender Beweiskette. In diesem Zustand halte "
    "ich 25–60 € pro Nutzer und Monat für erzielbar."),
   ("Mit 800 Nutzern", "rund 380 T€ Jahresumsatz",
    "Ein halbes Prozent der etwa 165.000 zugelassenen Rechtsanwälte. Zwei bis drei Jahre "
    "entfernt und abhängig von Vertrieb, nicht von Code. Größenordnung, keine Prognose."),
 ]),
 ("kasten_wichtig", "Der eine Satz, wenn Sie nur einen mitnehmen",
  "Die App ist heute nicht zu wenig, sondern zu viel: Sie kann dreißig Dinge andeuten und "
  "kein einziges verantworten. Der Weg zum Wert führt über Wegnehmen und über die eine "
  "Funktion, die niemand anders in dieser Klarheit anbietet — nachvollziehbare Fristen mit "
  "durchgehender Herkunft jeder Zahl. Alles in diesem Handbuch dient diesem einen Ziel."),

 # ============================================================ TEIL IV
 ("seitenumbruch", None),
 ("h1", "Teil IV — Grenzen dieser Prüfung"),
 ("p", "Diese Angaben gehören zum Bericht: Ohne sie könnten Sie meine Aussagen falsch "
       "gewichten."),
 ("nummerierte_liste", [
   ("Kein Laufzeittest",
    "Ich habe den Quellcode gelesen, die App nicht bedient — im Prüfcontainer stand kein "
    "Swift-Compiler zur Verfügung. Alle Aussagen über Laufzeitverhalten sind aus dem Code "
    "erschlossen. Der Code in diesem Handbuch ist ungetestet: Er ist als fachlich "
    "durchdachte Vorlage gedacht, nicht als kompilierfertiges Ergebnis."),
   ("Rechtsangaben aus dem Gedächtnis",
    "Paragraphen, Fristlängen, RVG-Beträge, Feiertagszuordnungen und der Stand der "
    "KI-Verordnung sind aus meinem Wissen wiedergegeben, nicht aus abgerufenen Quellen — "
    "der Prüfcontainer hatte keinen Zugriff auf Gesetzestexte. Jede einzelne Angabe gehört "
    "vor der Umsetzung gegen die Primärquelle geprüft. Die Systematik ist belastbar, "
    "einzelne Zahlen können falsch sein."),
   ("Keine Rechtsberatung",
    "Die Hinweise zu Richterprofilen, KI-Verordnung, Berufsrecht und Datenschutz sind "
    "Risikohinweise aus technischer Sicht. Für die Fragen aus Kapitel F, G und H brauchen "
    "Sie eine anwaltliche Einschätzung und gegebenenfalls Ihre Rechtsanwaltskammer."),
   ("Marktzahlen sind Größenordnungen",
    "Preisspannen, Anwaltszahl und Umsatzrechnung dienen der Einordnung. Sie beruhen auf "
    "allgemeiner Marktkenntnis, nicht auf einer Erhebung für dieses Produkt."),
   ("Nicht geprüft",
    "Die Qualität der KI-Prompts im Praxiseinsatz, die Bedienbarkeit mit echten Anwälten, "
    "die inhaltliche Richtigkeit der Rechtsdaten in den Jurisdiktions-Modulen, und die "
    "Frage, ob der Code nach den Änderungen dieses Handbuchs noch kompiliert."),
 ]),
 ("p_final", "Der wichtigste ungeprüfte Punkt ist der letzte, der nicht in der Liste steht: "
             "ob Anwälte dieses Werkzeug haben wollen. Das kann kein Codeaudit beantworten, "
             "nur eine Kanzlei, die es vier Wochen benutzt. Diese Antwort ist mehr wert als "
             "alles in diesem Handbuch."),
]
