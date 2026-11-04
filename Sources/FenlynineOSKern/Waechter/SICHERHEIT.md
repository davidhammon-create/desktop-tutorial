# Sicherheitszusage des Wächters — und ihre Grenzen

Dieses Dokument gehört zum Modul `Waechter/`. Es beschreibt, worauf die Zusage
„der Agent kann keine Falldaten verändern" beruht, und wo sie dünn wird.
Es ist für Entwickler, Prüfer und Versicherer geschrieben.

## Worauf die Zusage beruht

Nicht auf einer Richtlinie und nicht auf einem Prompt, sondern auf zwei
Eigenschaften des Codes:

**1. Der Agent kann nur sechs Dinge vorschlagen.** Das Enum `Korrektur` kennt
`hinweisAnlegen`, `markierungSetzen`, `neuBerechnen`, `feldErgaenzen`,
`pruefungAnfordern` und `modellAendern`. Es gibt keine Variante, die eine Frist
ändert, erledigt, löscht oder etwas nach außen sendet. Diese Fälle sind nicht
verboten — sie existieren nicht.

**2. Der Agent sieht keine Inhalte.** Seine Eingabe besteht aus den
`Pruefbare*`-Sichten: Ja/Nein-Merkmale und Zählwerte. Keine Namen, keine
Aktenzeichen, keine Beträge, keine Dokumenttexte. Was man nicht sieht, kann man
nicht preisgeben.

Abgesichert ist das durch `Tests/FenlynineOSKernTests/KorrekturGarantieTests.swift`.
Der dortige Schalter über alle Enum-Fälle kompiliert nicht mehr, sobald jemand
eine Variante ergänzt — die Änderung wird also im Diff sichtbar und muss
begründet werden.

## Sechs Wege, auf denen die Zusage doch unterlaufen werden kann

Diese Liste ist das Ergebnis einer gezielten Suche. Sie ist vollständig, soweit
wir sie kennen, und sie gehört in jede Codeprüfung.

**1 · Freitext in den Korrekturen.** Die Zeichenketten in `Korrektur`
(`text`, `vorschlag`, `grund`, `frage`) könnten Inhalte transportieren, wenn
eine Regel sie dort hineinschreibt. Dem Agenten fehlt dafür die Gelegenheit,
weil er nur die schlanken Sichten kennt. Der Schutz hält also genau so lange,
wie die Sichten schlank bleiben.

**2 · Rückcast auf den konkreten Typ.** Eine Regel könnte `any PruefbareFrist`
per `as?` auf den App-Typ zurückcasten und so an Inhalte kommen, die dieser
zusätzlich trägt. **Gegenmaßnahme, die noch aussteht:** Die App darf ihre
Domänenmodelle nicht direkt konform machen, sondern muss eigene, schlanke
Structs als Sichten übergeben. Solange das nicht umgesetzt ist, ist dies die
größte offene Lücke.

**3 · Offenes Regelprotokoll.** `Regel` kann jeder implementieren, und eine
Regel könnte an globalen Zuständen oder anderen Datenquellen vorbei am
`Pruefzustand` lesen. Der Typ verhindert das nicht. Nur ein verbindliches
Regelregister und Codeprüfung helfen.

**4 · Der Ausführer liegt außerhalb.** `Korrekturausfuehrer` wird von der App
gestellt. Er muss `neuBerechnen` als zusätzlichen Beleg umsetzen und
`modellAendern` auf Oberfläche und Konfiguration beschränken. `aenderungId` ist
ein freier String; der Kern kann nicht prüfen, was dahintersteckt. Diese
Implementierung gehört besonders sorgfältig geprüft.

**5 · `umkehrbar` ist eine Selbstauskunft.** Das Flag entscheidet, ob eine
Modelländerung automatisch laufen darf, wird aber von der Regel selbst gesetzt.
Eine falsch gesetzte Angabe schaltet die Automatik frei. Der Ausführer sollte
die Umkehrbarkeit tatsächlich einlösen können, statt sie zu glauben.

**6 · Ein neuer Enum-Fall.** Wer künftig `Korrektur` erweitert, hebelt die
Garantie aus. Der Garantie-Test macht das sichtbar, verhindert es aber nicht.

## Was daraus folgt

Die Zusage ist belastbar gegen Versehen, Fehlkonfiguration und schlechte
KI-Ausgaben — also gegen die Fälle, die im Betrieb tatsächlich vorkommen.
Sie ist nicht belastbar gegen einen Entwickler, der sie absichtlich aushebelt.
Das ist keine Schwäche dieses Entwurfs, sondern die Grenze dessen, was ein
Typsystem leisten kann; alles Weitere ist Organisation.

Für die Außendarstellung heißt das: Sagen Sie „der Agent kann es strukturell
nicht", nicht „der Agent darf es nicht". Beides ist wahr, aber nur das Erste
lässt sich zeigen — und Punkt 2 dieser Liste sollte vorher geschlossen sein.
