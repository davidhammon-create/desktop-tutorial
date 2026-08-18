# -*- coding: utf-8 -*-
"""Bauplan Teil 3: Überlegenheit, Burggraben, Reihenfolge, Grenzen."""

B3 = [
 ("seitenumbruch", None),
 ("h1", "Teil 3 — Wo echte Überlegenheit entsteht"),
 ("p", "Bis hierhin ging es darum, Falsches richtig zu machen. Das bringt die App auf "
       "Augenhöhe, mehr nicht. Dieser Teil beschreibt neun Funktionen, die es in dieser Form "
       "nirgends gibt — und die alle aus derselben Grundlage folgen: dass jede Zahl ihre "
       "Herkunft kennt. Das ist der Punkt, an dem sich Ihre Vorarbeit auszahlt."),

 ("h3", "3.1 · Der Rechenweg als Anlage zum Schriftsatz"),
 ("p", "Jede Zahl der App kann ihre vollständige Herleitung als druckfertiges Dokument "
       "ausgeben: Ausgangswert, jeder Beitrag mit Begründung und Urheber, jede Formel mit "
       "Norm, das Ergebnis mit Zeitstempel und Prüfsumme. Kein Wettbewerber kann das, weil "
       "keiner die Herkunft mitführt."),
 ("p", "Der Nutzen ist unmittelbar: Der Anwalt kann die Anlage dem Mandanten zur "
       "Aufklärung geben, sie im Vergleichsgespräch auf den Tisch legen und im "
       "Regressprozess vorlegen. Aus einer Softwareausgabe wird ein Beweismittel."),
 ("code", """/// Vollständige Herleitung einer Zahl -- als Dokument, nicht als Tooltip.
public struct Rechenweg {
  public struct Schritt {
    public let beschreibung: String
    public let formel: String?
    public let norm: String?
    public let wertVorher: Double
    public let wertNachher: Double
    public let herkunft: Herkunft        // formel / ki / mensch / quelle
    public let urheber: String
    public let zeitpunkt: Date
    public let begruendung: String?
  }

  public let gegenstand: String          // "Erfolgsaussicht Hauptantrag"
  public let schritte: [Schritt]
  public let ergebnis: Double
  public let eingabenHash: String
  public let kernVersion: String
  public let erstelltAm: Date

  /// Ein Satz je Schritt, in der Sprache eines Schriftsatzes.
  public func alsFliesstext() -> String {
    var t = "Herleitung: \\(gegenstand)\\n\\n"
    for (i, s) in schritte.enumerated() {
      t += "\\(i + 1). \\(s.beschreibung)"
      if let n = s.norm { t += " (\\(n))" }
      t += ": \\(prozent(s.wertVorher)) auf \\(prozent(s.wertNachher))."
      if let b = s.begruendung { t += " Begründung: \\(b)" }
      t += " [\\(s.herkunft.kurz), \\(s.urheber)]\\n"
    }
    t += "\\nErgebnis: \\(prozent(ergebnis)). Berechnet mit Rechenkern "
      +  "\\(kernVersion), Datenstand \\(eingabenHash.prefix(12))."
    return t
  }
}"""),

 ("h3", "3.2 · Das Wiedereinsetzungs-Dossier — Software als Versicherung"),
 ("p", "Das ist die Funktion mit dem höchsten unmittelbaren Verkaufswert. Wenn eine Notfrist "
       "reißt, entscheidet § 233 ZPO über das Mandat: Wiedereinsetzung gibt es nur, wenn die "
       "Partei ohne Verschulden gehindert war — was in der Praxis heißt, dass die Kanzlei "
       "eine funktionierende Fristenorganisation nachweisen muss. Genau diesen Nachweis "
       "erzeugt Ihre Software im Alltag ohnehin. Sie muss ihn nur auf Knopfdruck "
       "zusammenstellen."),
 ("code", """/// Stellt bei versäumter Notfrist automatisch die Nachweise zusammen,
/// die § 233 ZPO verlangt. Aus laufender Protokollierung wird im Ernstfall
/// die Rettung des Mandats.
public struct WiedereinsetzungsDossier {
  public let frist: Deadline
  public let herleitung: Fristherleitung       // wie berechnet wurde
  public let eintragung: Protokolleintrag      // wann, von wem notiert
  public let vorfristen: [Protokolleintrag]    // Vorfrist gesetzt und angezeigt
  public let ausgangskontrollen: [Kontrolle]   // abendliche Kontrollen im Zeitraum
  public let bearbeiterHistorie: [Zuweisung]   // wer war zuständig
  public let systemereignisse: [Systemereignis] // Ausfälle, Abwesenheiten
  public let organisationsnachweis: URL        // Kanzlei-Fristenanweisung

  /// Was die Kanzlei belegen kann -- und was sie noch beibringen muss.
  public var luecken: [String] {
    var l: [String] = []
    if vorfristen.isEmpty { l.append("Keine Vorfrist protokolliert.") }
    if ausgangskontrollen.isEmpty {
      l.append("Keine Ausgangskontrolle im maßgeblichen Zeitraum protokolliert.")
    }
    return l
  }
}"""),
 ("kasten_wichtig", "Der Satz für das Verkaufsgespräch",
  "<b>„Wenn Ihnen eine Frist reißt, erzeugt diese Software den Wiedereinsetzungsantrag "
  "aus dem laufenden Protokoll — mit lückenlosem Nachweis Ihrer Organisation.\"</b> "
  "Fristversäumnis ist der häufigste Haftungsfall im Anwaltsberuf. Eine Software, die "
  "diesen Fall nicht nur verhindert, sondern für den Ernstfall vorsorgt, verkauft sich "
  "nicht über Funktionen, sondern über Angst — und das ist im Versicherungsgeschäft "
  "das stärkste Argument, das es gibt. Sprechen Sie darüber auch mit Ihrem "
  "Berufshaftpflichtversicherer: Ein Prämienrabatt für Kanzleien, die nachweislich "
  "so arbeiten, wäre ein Vertriebsweg, den kein Wettbewerber hat."),

 ("h3", "3.3 · Kalibrierungstraining — die App macht den Anwalt besser"),
 ("p", "Jede Prognose des Anwalts wird gespeichert, jeder Ausgang ebenso. Daraus entsteht "
       "nach einigen Dutzend Fällen eine persönliche Auswertung: <i>„Wenn Sie 70 Prozent "
       "sagen, treten die Fälle in 58 Prozent ein. Sie sind systematisch zu optimistisch, "
       "besonders im Arbeitsrecht.\"</i>"),
 ("p", "Das ist die einzige Funktion in diesem ganzen Dokument, die den Nutzer selbst "
       "verbessert statt nur seine Arbeit. Aus der Prognoseforschung ist bekannt, dass "
       "Rückmeldung dieser Art die Treffsicherheit messbar erhöht. Für eine Kanzlei heißt "
       "das: bessere Vergleichsempfehlungen, weniger verlorene Prozesse, zufriedenere "
       "Mandanten — und eine Bindung an das Produkt, die kein Wettbewerber lösen kann, "
       "weil die eigene Lernkurve darin steckt."),

 ("h3", "3.4 · Zeitreise: Was wusste die Kanzlei am 14. März?"),
 ("p", "Weil jeder Rechenbeleg seinen Eingabenstand mitführt und die Protokollkette "
       "unveränderlich ist, kann die App den Wissensstand jedes vergangenen Tages "
       "rekonstruieren. Im Regressprozess ist das die entscheidende Frage — und heute kann "
       "sie keine Kanzleisoftware beantworten."),

 ("h3", "3.5 · Bonitätsprüfung, bevor geklagt wird"),
 ("p", "Ein obsiegendes Urteil gegen einen insolventen Gegner ist wertlos, und der Mandant "
       "zahlt trotzdem. Die Insolvenzbekanntmachungen sind amtlich und frei zugänglich, das "
       "Handelsregister ebenso. Eine Prüfung vor Mandatsannahme und vor Klageerhebung ist "
       "technisch trivial und fachlich wertvoll — sie gehört als Pflichtschritt in die "
       "Mandats-Pipeline, mit protokolliertem Ergebnis. Kein anderes System macht das "
       "verbindlich."),

 ("h3", "3.6 · Vier-Augen-Prinzip bei Notfristen, technisch erzwungen"),
 ("p", "Bei Fristen mit <font face=\"Mono\">istNotfrist</font> verlangt die App eine zweite "
       "Bestätigung durch eine andere Person, bevor die Frist als erledigt gilt. Nicht als "
       "Empfehlung, sondern als Sperre. Das ist die technische Umsetzung dessen, was die "
       "Rechtsprechung zur Ausgangskontrolle ohnehin verlangt — und es ist zugleich der "
       "Baustein, der das Dossier aus 3.2 belastbar macht."),

 ("h3", "3.7 · Die Gegenprobe: Die App argumentiert gegen sich selbst"),
 ("p", "Der vorhandene Advocatus-Ansatz verdient Ausbau zur Pflichtstation: Bevor eine "
       "Empfehlung angezeigt wird, erzeugt die App die stärkste Gegenposition und benennt "
       "die Annahme, deren Umkehrung das Ergebnis kippen würde. Aus der "
       "Empfindlichkeitsanalyse ist diese Annahme bereits bekannt — sie muss nur "
       "ausgesprochen werden: <i>„Diese Empfehlung hängt an der Wirksamkeit der "
       "Kündigungsfrist. Fällt sie, dreht sich das Ergebnis.\"</i>"),

 ("h3", "3.8 · Portfolio-Sicht: Welches Mandat sollten wir ablehnen?"),
 ("p", "Aus der Korrelationsrechnung aus Kapitel 1.10 folgt eine Frage, die kein "
       "Kanzleisystem heute stellt. Vier Verfahren an derselben Rechtsfrage sind eine "
       "einzige, vierfach platzierte Wette. Das sichtbar zu machen, verwandelt die "
       "Mandats-Pipeline von einer Liste in ein Steuerungsinstrument."),

 ("h3", "3.9 · Der Datenflussnachweis"),
 ("p", "Die Souveränitätsschicht wird zum sichtbaren Versprechen: eine Anzeige, die "
       "jederzeit sagt, ob in dieser Sitzung Daten den Rechner verlassen haben, und ein "
       "Ausdruck, der es für einen Zeitraum belegt. Im deutschen und europäischen "
       "Rechtsmarkt, wo § 203 StGB und die Verschwiegenheitspflicht jede Cloud-Entscheidung "
       "belasten, ist ein überprüfbares „nichts hat diesen Rechner verlassen\" ein "
       "Verkaufsargument, gegen das internationale Anbieter strukturell nicht ankommen."),

 # ============================================================ TEIL 4
 ("seitenumbruch", None),
 ("h1", "Teil 4 — Was den Burggraben baut"),
 ("p", "Zum Abschluss die ehrliche Rechnung: Welche dieser Funktionen sind kopierbar, und "
       "welche bauen etwas auf, das mit der Zeit wächst? Nur die zweite Gruppe trägt eine "
       "hohe Bewertung."),
 ("burg_tabelle", [
   ("Fristenberechnung", "kopierbar", "Kann jeder bauen. Notwendig, aber kein Vorsprung — "
    "die etablierten Systeme haben sie längst."),
   ("Rechenweg und Protokollkette", "schwer kopierbar",
    "Erfordert, dass die Herkunft von Anfang an durch die gesamte Architektur läuft. "
    "Ein Wettbewerber müsste sein Fundament austauschen, nicht ein Feature ergänzen."),
   ("Wiedereinsetzungs-Dossier", "schwer kopierbar",
    "Setzt die Protokollkette voraus. Und es öffnet den Weg zum Versicherer als "
    "Vertriebspartner — eine Beziehung, die exklusiv sein kann."),
   ("Eigene Kalibrierungsdaten", "nicht kopierbar",
    "Wächst mit jedem abgeschlossenen Fall und lässt sich nicht kaufen. Das ist der "
    "einzige echte Burggraben in diesem Markt."),
   ("Kalibrierungstraining", "nicht kopierbar",
    "Die persönliche Lernkurve des Anwalts liegt im Produkt. Ein Wechsel bedeutet, "
    "sie zu verlieren."),
   ("Lokaler Betrieb mit Nachweis", "teilweise",
    "Technisch kopierbar, aber gegen das Geschäftsmodell cloudbasierter Anbieter — "
    "die werden es nicht tun."),
 ]),
 ("h3", "Der realistische Weg nach oben"),
 ("nummerierte_liste", [
   ("Jahr eins — eine Kanzlei, ein Ablauf",
    "Fristen und Berufspflicht vollständig, mit einer Pilotkanzlei im täglichen Einsatz. "
    "Ziel ist nicht Umsatz, sondern der Satz „wir würden ohne das nicht mehr arbeiten\"."),
   ("Jahr zwei — Nachweis als Produkt",
    "Rechenweg, Dossier und Datenflussnachweis ausgebaut. Gespräch mit einem "
    "Berufshaftpflichtversicherer über Prämienvorteile. Das ist der Punkt, an dem der "
    "Vertrieb aufhört, einzeln zu sein."),
   ("Jahr drei — Daten fangen an zu tragen",
    "Genug abgeschlossene Fälle für belastbare Kalibrierung. Ab hier wird das Produkt "
    "mit jedem Nutzer besser, und der Abstand wächst von allein."),
   ("Danach — horizontal statt tiefer",
    "Die Nachweis-Engine für andere regulierte Berufe öffnen. Das ist der Schritt, an dem "
    "aus einem sehr guten deutschen Anwaltsprodukt ein Unternehmen mit einem Markt "
    "jenseits von 165.000 Adressaten wird. Alles davor ist Vorbereitung darauf."),
 ]),
 ("kasten_wichtig", "Die nüchterne Wahrheit zum Unicorn",
  "Ich kann Ihnen nicht versprechen, dass daraus eine Milliardenbewertung wird — das hängt "
  "an Vertrieb, Kapital, Timing und Menschen, nicht an Code. Was ich sagen kann: "
  "<b>Von den zwölf Punkten in diesem Bauplan sind zwei so beschaffen, dass sie mit der "
  "Zeit uneinholbar werden</b> — die eigenen Kalibrierungsdaten und die durchgehende "
  "Nachweiskette. Alles andere ist Handwerk, das ein gut finanzierter Wettbewerber "
  "nachbaut. Wenn Sie Prioritäten setzen müssen, setzen Sie sie auf diese zwei."),

 # ============================================================ TEIL 5
 ("seitenumbruch", None),
 ("h1", "Teil 5 — Grenzen dieses Bauplans"),
 ("nummerierte_liste", [
   ("Der Code ist ungetestet",
    "Im Prüfcontainer stand kein Swift-Compiler zur Verfügung. Alle Vorlagen sind fachlich "
    "durchdacht, aber nicht kompiliert. Die numerischen Konstanten der Gauß-Hermite-"
    "Quadratur habe ich gegen die Summenbedingung geprüft (Summe der Gewichte = Wurzel Pi); "
    "die übrigen Formeln gehören vor dem Einsatz getestet."),
   ("Alle Rechts- und Quellenangaben stammen aus meinem Wissen",
    "Ich konnte weder Gesetzestexte noch Statistiken noch Websites abrufen. Normen, "
    "Fristlängen, RVG-Beträge, Bezeichnungen von Fachserien und Verfügbarkeit von Quellen "
    "sind aus dem Gedächtnis wiedergegeben. Die Systematik ist belastbar, einzelne Angaben "
    "können falsch sein — jede gehört gegen die Primärquelle geprüft."),
   ("Die drei Rechenfehler habe ich am Code verifiziert, nicht am Gesetz",
    "Dass zwei RVG-Tabellen im Programm unterschiedliche Werte liefern, ist unabhängig von "
    "jeder Quelle belegt — es ist ein Widerspruch im Code selbst. Welche der beiden näher "
    "am Gesetz liegt, müssen Sie an der Anlage 2 nachschlagen. Ebenso bei "
    "Auslagenpauschale und § 199 BGB: Die Abweichung von der Norm ist mein Kenntnisstand, "
    "die Fundstelle im Code ist gesichert."),
   ("Keine Rechtsberatung, keine Marktprognose",
    "Die Hinweise zu Berufsrecht, Datenschutz und KI-Verordnung sind Risikohinweise aus "
    "technischer Sicht. Die Aussagen zu Burggräben und Marktwegen sind unternehmerische "
    "Einschätzungen, keine Prognose."),
   ("Nicht geprüft",
    "Ob Anwälte diese Funktionen wollen. Ob der Pilotbetrieb die Annahmen bestätigt. "
    "Ob die Prompts im Praxiseinsatz taugen. Und ob das Programm nach diesen Änderungen "
    "noch kompiliert."),
 ]),
 ("p_final", "Der Bauplan beschreibt, was technisch und fachlich möglich ist. Ob daraus ein "
             "großes Unternehmen wird, entscheidet sich nicht an diesen Seiten, sondern an "
             "der ersten Kanzlei, die vier Wochen damit arbeitet und danach sagt, sie wolle "
             "nicht zurück. Diese eine Rückmeldung ist mehr wert als jede Zahl in diesem "
             "Dokument."),
]
