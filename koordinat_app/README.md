# KOORDINAT v0.4 – wächst von selbst und führt dich

Läuft mit Python 3.10+ und git. Keine weiteren Pakete nötig.

## Start
```
cd koordinat_app
python3 tests.py                      # Selbsttest (101 Prüfungen, ohne Netz)
python3 -m koordinat versiegeln       # Kern-Siegel setzen (einmalig, nach jeder eigenen Änderung am Kern)
python3 -m koordinat suche "pdf table extraction"
python3 -m koordinat installiere jsvine/pdfplumber
python3 -m koordinat an jsvine/pdfplumber
python3 -m koordinat kontext jsvine/pdfplumber "extract table"
python3 -m koordinat vital
python3 -m koordinat hilfe
```
Daten liegen in `~/.koordinat` (änderbar über die Umgebungsvariable `KOORDINAT_HOME`).
Mit einem `GITHUB_TOKEN` in der Umgebung steigen die Abfragegrenzen von GitHub deutlich.

## Neu in v0.3: die drei Schleifen
Der versiegelte Kern (`verfassung.py`, `vital.py`) ist unverändert, das Siegel aus v0.2 gilt weiter.

### 1. Wachstum: Bedarf → Suche → Prüfung → Vorschlag (`wachstum.py`)
```
python3 -m koordinat brauche "Tabellen aus PDF Rechnungen"   # Bedarf in Alltagssprache
python3 -m koordinat wachse                                  # ein Takt
python3 -m koordinat vorschlaege                             # was gefunden und geprüft wurde
python3 -m koordinat annehmen 3                              # oder: ablehnen 3
python3 -m koordinat wachse 30                               # Dauerlauf alle 30 Minuten, endet bei "stop"
```
Auch ohne `brauche` entsteht Bedarf: Drei gescheiterte Fälle eines Problemtyps (`melde … ehrlich_gescheitert pdf.scan`)
lösen von selbst eine Suche aus; für Module in Not wird ein Nachfolger gesucht; der Katalog wächst je Takt um ein Thema.

Was die App allein tun darf, stellst du ein. Die Schalter ändert nur die Befehlszeile, nie die KI über MCP:
```
python3 -m koordinat schalter                       # anzeigen
python3 -m koordinat schalter auto.einschalten an   # ab Werk AUS
```
| Schalter | ab Werk | Wirkung |
|---|---|---|
| `auto.suche` | an | Hunger und Bedarf lösen eine GitHub-Suche aus |
| `auto.laden` | an | beste Treffer laden und prüfen (höchstens 2 je Takt, bleiben AUS) |
| `auto.einschalten` | aus | nur freie Lizenz + Scan bestanden + Score ≥ 75 + ≥ 500 Sterne gehen von selbst AN |
| `auto.entdecken` | an | Katalog wächst um neue KI-Werkzeuge |
| `auto.evolution` | an | eigene Algorithmen stellen sich nach |

Bei sinkendem Puls wird die Schleife vorsichtiger (A8): `vorsicht` schaltet nichts von selbst ein und macht keine
Experimente, `not` lädt auch nichts mehr, `sicher` und STOP tun nichts.

### 2. Algorithmen, die sich selbst verbessern (`evolution.py`, `algorithmen.py`)
Geändert werden nur Zahlen in festen Grenzen, nie Code (Band III, Kap. 4: keine code-schreibende Schleife ohne
Schutzschicht 3). Zwei Algorithmen lernen heute:

| Algorithmus | lernt aus | ohne dein Zutun |
|---|---|---|
| `repo_score` (Gewichte der Bewertung) | annehmen, ablehnen, `melde geloest` / `fehler_verborgen` | nein, braucht deine Entscheidungen |
| `kontext_rang` (welche Bausteine oben stehen) | welchen Baustein die KI nach `kontext "frage"` per `auszug` holt | ja |

Ablauf: lernen auf 60 % der Fälle → prüfen auf 25 %, die der Lerner nie sah (Zufallstest, p < 0,05) → Schattenbetrieb
bis 8 neue Fälle da sind → Champion, wenn auch der Tresor (15 %) nicht schlechter ist → Rückrollen, wenn der
Vorgänger später wieder besser ist. `python3 -m koordinat algorithmen` zeigt Parameter und Verlauf,
`algorithmen zuruecksetzen <name>` stellt die Standardwerte wieder her.

Gemessen (simulierte Rückmeldungen, je Welt 85 Bedarfe): In 60 Welten aus reinem Rauschen wurde 1 Kandidat
fälschlich Champion. In 20 Welten mit echtem Zusammenhang wurde 20-mal ein Champion gefunden; die Treffgenauigkeit
der Rangfolge auf frischen Fällen stieg von 0,74 auf 0,98. Mit echten Nutzerdaten ist das noch nicht gemessen.

### 3. Schutz vor Anweisungen an KI-Modelle in Repo-Texten (`module.py`)
Jedes Kontextpaket ist als Daten gekennzeichnet, verdächtige Zeilen werden entfernt, ein Repo mit solchen Texten
besteht den Scan nicht mehr als „bestanden“ und geht damit nie von selbst an. Das sind Muster, kein Beweis.

### Guide (`guide.json`, `guide.py`)
`python3 -m koordinat guide` zeigt das Inhaltsverzeichnis, `guide lizenz` einen Eintrag. 24 Einträge als Grundstock.
Begriffe, die gesucht werden und fehlen, zählt `guide-luecken`: die Arbeitsliste für neue Einträge.
Ein neuer Eintrag ist ein Block in `guide.json`, ohne Programmierung.

## Offen (für den nächsten Bauabschnitt)
| Aufgabe | Wo | Schwierigkeit |
|---|---|---|
| Guide von 24 auf einige hundert Einträge ausbauen, Lernpfade | `guide.json` | leicht, viel Schreibarbeit |
| Katalog ordnen: Themenliste erweitern, Unpassendes aussortieren | `wachstum.THEMEN`, Tabelle `katalog` | leicht |
| Deutsch→Englisch der Suchanfrage über ein Modell statt Wörterliste | `wachstum.anfrage` | leicht |
| Oberfläche (Modul-Store mit Schaltern, Vorschläge, Vital-Anzeige) | neu, liest dieselbe Datenbank | mittel |
| Werkzeuge wirklich starten: Container bauen, Rauchtest, Reparatur | `Dockerfile.koordinat` liegt je Modul bereit | mittel bis schwer |
| Modell-Anbindung: Kaskade, Router, Kristalle aus `referenz/koordinat_kern.py` | neu; `Kern.modell()` ist die Einhängestelle | mittel |
| Weitere lernende Algorithmen (Suchanfrage, Sicherheitsmuster) | `algorithmen.py`: Raum, Einheiten, Güte | mittel |
| Fremde Algorithmen ausführen und gegeneinander antreten lassen | erst nach Container-Ausführung und Schutzschicht 3 | schwer |

## Neu in v0.4: Ziel im Kern, Besitzer-Schlüssel, geführte Abläufe

**Der Kern trägt jetzt ein Ziel.** `verfassung.py` beginnt mit `ZIEL`: nützlicher werden, mehr wissen,
mehr können, schwerere Probleme lösen, wachsen – gebunden an Nutzen und die acht Artikel. Ambition im
Kern, Leitplanken im Kern.

**Ein einziger Hebel, den Kern zu ändern: dein Besitzer-Schlüssel.**
```
python3 -m koordinat besitzer-setzen     # einmalig deinen geheimen Code setzen (min. 8 Zeichen)
python3 -m koordinat versiegeln          # ab jetzt nur noch mit diesem Code
```
Der Schlüssel liegt als gesalzener Hash in `~/.koordinat/owner.lock`, nie im Code. Ohne ihn nimmt die
App keinen neuen Kern an (sicherer Modus). `stop` wirkt weiter ohne Schlüssel (A1). Google-OAuth lässt
sich später vor `setze_besitzer`/`versiegeln` hängen – dein Google-Konto entsperrt dann den Schlüssel.

**Geführte Abläufe – sofort Schritt für Schritt.** `leitfaden.py` + `leitfaden.json`:
```
python3 -m koordinat los "ich will KI Videos erstellen"
python3 -m koordinat weiter
python3 -m koordinat leitfaden            # alle Abläufe
```
8 Abläufe, 45 Schritte: KI-Video, Firma automatisieren, bessere Agenten, wie GitHub funktioniert,
KI-Konten/Schlüssel verbinden, Dokumente auswerten, lokale KI, erste Schritte. Jeder Schritt nennt das
Werkzeug, das er braucht. Über MCP bekommt die KI mit `koordinat_los` den ganzen Plan zum Abarbeiten.

## In Claude, Cursor oder ein anderes MCP-fähiges Programm einhängen
Eintrag in der MCP-Konfiguration des jeweiligen Programms (Pfad anpassen):
```json
{ "mcpServers": { "koordinat": {
    "command": "python3", "args": ["-m", "koordinat", "mcp"],
    "env": { "PYTHONPATH": "/PFAD/ZU/koordinat_app" } } } }
```
Die genaue Stelle der Konfiguration steht in der Dokumentation des Programms.

## Geschützter Kern
`koordinat/verfassung.py` und `koordinat/vital.py` sind versiegelt (`verfassung.lock`).
Für echten Schutz zusätzlich auf Betriebssystem-Ebene sperren, z. B. macOS:
```
sudo chown root koordinat/verfassung.py koordinat/vital.py koordinat/verfassung.lock
sudo chmod 444  koordinat/verfassung.py koordinat/vital.py koordinat/verfassung.lock
sudo chflags schg koordinat/verfassung.py koordinat/vital.py koordinat/verfassung.lock
```

## Wichtig
- Fremder Code wird nur geladen und gelesen, nie ausgeführt. Zum Ausführen das erzeugte
  `Dockerfile.koordinat` in einem Container ohne Netz nutzen.
- Der Sicherheitsscan arbeitet mit Mustern und ersetzt keine vollwertigen Scanner.
- Lizenzklassen sind eine technische Einordnung, keine Rechtsberatung.
