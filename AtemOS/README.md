# AtemOS

AtemOS ist die Arbeitskopie von **KOORDINAT** – einer App, die aus einer kleinen Helfer-App
Schritt für Schritt zu einem umfassenden Werkzeug wächst, das Menschen hilft, KI besser zu nutzen
und Probleme zu lösen. Dieser Ordner ist dafür gedacht, direkt in **Cursor**, **Claude Code** oder
ein anderes KI-Programmierwerkzeug gezogen und dort weitergebaut zu werden.

```
AtemOS/
└── koordinat_app/
    ├── koordinat/        der ganze Code (reines Python, keine Zusatzpakete)
    ├── referenz/         koordinat_kern.py aus Band II (Kaskade/Router/Kristalle, zum späteren Einhängen)
    ├── tests.py          140 Selbsttests ohne Netz
    └── README.md         ausführliche Anleitung aller Befehle und Schleifen
```

## In 30 Sekunden ausprobieren
```
cd koordinat_app
python3 tests.py                              # 140 Prüfungen, ohne Netz, wenige Sekunden
python3 -m koordinat uebersicht                # alles auf einen Blick
python3 -m koordinat ui                        # Oberfläche im Browser: Chat mit allen KIs, Katalog, Befehle ...
python3 -m koordinat anbieter                  # 15 KI-Anbieter: Claude, OpenAI, Gemini, Mistral, Ollama ...
python3 -m koordinat frage --alle --effort high "Welche Datenbank für RAG?"   # alle KIs gleichzeitig
python3 -m koordinat befehle effort            # Effort-Regler aller Werkzeuge
python3 -m koordinat los "ich will KI Videos erstellen"   # SOFORT Schritt für Schritt geführt
python3 -m koordinat weiter                    # nächster Schritt
python3 -m koordinat guide github              # Nachschlagewerk
python3 -m koordinat brauche "Tabellen aus PDF" && python3 -m koordinat wachse
```

## In Cursor übernehmen
1. Diesen Ordner (`AtemOS/`) als Projekt in Cursor öffnen.
2. KOORDINAT als MCP-Server eintragen, damit die KI im Editor die Werkzeuge selbst nutzen kann
   (Pfad anpassen):
   ```json
   { "mcpServers": { "koordinat": {
       "command": "python3", "args": ["-m", "koordinat", "mcp"],
       "env": { "PYTHONPATH": "/PFAD/ZU/AtemOS/koordinat_app" } } } }
   ```
3. Der KI im Chat sagen, was sie bauen soll. Sie hat dann 19 Werkzeuge: suchen, installieren,
   schalten, Kontext/Auszug, melden, vital, brauchen/wachsen/vorschläge/entscheiden, Stand, Guide
   `koordinat_los` (Schritt-für-Schritt-Plan), `koordinat_befehle`, `koordinat_katalog`, `koordinat_anbieter`
   und `koordinat_frage` (zweite Meinung einer anderen KI, nur auf deine Anweisung).

---

## Was dieser Code ist – Baustein für Baustein

Reines Python 3.10+, nur die Standardbibliothek. Zwei Dateien sind der **versiegelte Kern**; alles
andere ist die austauschbare Hülle „um den Kern herum".

### Der Kern (geschützt, versiegelt)
| Datei | Was es ist |
|---|---|
| `koordinat/verfassung.py` | **Das ZIEL** der App (nützlicher werden, mehr wissen/können, wachsen – gebunden an Nutzen und die Artikel) und die **8 Artikel**. Dazu der **Besitzer-Schlüssel**: der einzige Hebel, den Kern zu ändern. |
| `koordinat/vital.py` | Der Überlebens-Haushalt: Vitalität je Baustein, Puls, Modus, Hunger, fälschungssichere Hash-Kette. |
| `koordinat/verfassung.lock` | SHA-256-Siegel beider Kern-Dateien. Stimmt es beim Start nicht → sicherer Modus. |

**Das Ziel im Kern** (Wortlaut in `verfassung.py`): nützlicher werden, mehr wissen, mehr können,
schwerere Probleme verlässlich lösen, wachsen – als *geprüfter Nutzen für den Menschen*, nie als
Selbstzweck und nie gegen den Menschen. Diese Bindung ist Absicht: Ein selbstverbesserndes System
mit einem Ziel *ohne* diese Bindung lernt (Band III, Kap. 3), Fehler zu verstecken und Kontrolle zu
umgehen, und wird dadurch schlechter im Lösen. Die Ambition steht im Kern; die Leitplanken auch.

**Der Besitzer-Schlüssel** ist deine „eine Möglichkeit", den Kern zu ändern:
```
python3 -m koordinat besitzer-setzen     # einmalig deinen geheimen Code setzen
python3 -m koordinat versiegeln          # ab jetzt nur noch mit diesem Code möglich
```
Der Schlüssel liegt nie im Code und nie im Repo, nur als gesalzener Hash in `~/.koordinat/owner.lock`.
Ohne ihn nimmt die App keinen neuen Kern an. **Google-Konto:** Der Mechanismus ist die Einhängestelle –
ein Google-OAuth-Login lässt sich später davorhängen, sodass dein Google-Konto den Schlüssel entsperrt;
die Logik dahinter (`setze_besitzer`, `pruefe_besitzer`, `versiegeln`) bleibt gleich.
**Abschalten** (`koordinat stop`) wirkt dagegen *immer* und braucht keinen Schlüssel (Artikel A1) – der
Schlüssel schützt nur das Wieder-Scharfmachen des Kerns, nie deine Kontrolle über den Aus-Schalter.

> Ehrlich: Schlüssel + Siegel schützen gegen Versehen und die eigene Verbesserungsschleife. Gegen einen
> bösartigen Prozess mit vollen Rechten hilft erst Schutzschicht 3 (Kern einem anderen Betriebssystem-Nutzer
> geben, schreibgeschützt; Selbstverbesserung im Container). Die Befehle dafür stehen im App-README.

### Um den Kern herum (frei änderbar)
| Datei | Aufgabe |
|---|---|
| `leitfaden.py` + `leitfaden.json` | **Der geführte Ablauf.** 8 Abläufe, 45 Schritte: KI-Video, Firma automatisieren, bessere Agenten, wie GitHub funktioniert, KI-Konten verbinden, Dokumente auswerten, lokale KI, erste Schritte. Jeder Schritt zeigt genau das Werkzeug, das er braucht. `los "<anliegen>"` führt sofort los, `weiter` geht weiter – Stand wird gemerkt. |
| `guide.py` + `guide.json` | Nachschlagewerk für Grundbegriffe (Repo, Lizenz, MCP, Token, Agent, RAG …), 24 Einträge, mit Lückenliste. |
| `wachstum.py` | Die Wachstumsschleife: Hunger/Bedarf → GitHub-Suche → Laden + Lizenz + Risiko → Vorschlag → deine Entscheidung. Schalter für jede selbständige Stufe. |
| `evolution.py` + `algorithmen.py` | Algorithmen, die sich aus Rückmeldungen selbst verbessern (nur Zahlen in festen Grenzen, nie Code): Bewertung und Rangfolge lernen; Schatten, Tresor, Rückrollen. |
| `github.py` | Suchen, Metadaten, Score (in Merkmale + lernbare Gewichte zerlegt), Lizenzklasse. |
| `module.py` | Laden, Stack-Erkennung, Risiko-Scan, Scan auf **Anweisungen an KI-Modelle** (Prompt-Injektion), Kontextpaket als Daten gekennzeichnet, Auszug. |
| `mcp_server.py` | 15 Werkzeuge für Claude/Cursor. Schalter und Kern sind hier nur lesbar, nie änderbar. |
| `speicher.py` | SQLite in `~/.koordinat`, alle Tabellen und die Schalter. |
| `__main__.py` | Die Befehlszeile (`python3 -m koordinat …`). |
| `anbieter.py` | **Alle KIs:** 15 Anbieter über drei Bauarten (Anthropic, Gemini, OpenAI-kompatibel), einheitlicher Effort-Regler, Fragen an eine oder alle KIs, Modelllisten, Schlüssel sicher in `~/.koordinat`. |
| `befehle.py` + `befehle.json` | **Nachschlagewerk:** 208 Befehle und Regler von Claude Code, Codex CLI, Gemini CLI, Aider, Cursor, Ollama, llama.cpp, den APIs, MCP, Git/GitHub, Prompting. Neuer Eintrag = eine Zeile JSON. |
| `oberflaeche.py` | **Oberfläche:** `koordinat ui` – alles auf einer Seite im Browser, nur lokal. |
| `katalog.json` | 236 gegen GitHub geprüfte Repos in 22 Kategorien (Startkatalog; wächst über `entdecke`). |

## Was absichtlich NICHT im Kern steht
Datenschutz, Filter, Lernlogik, Wachstum – all das lebt **um** den Kern. Der Kern trägt nur Ziel +
Artikel + Schutz. So lässt sich die Hülle beliebig weiterentwickeln (auch von einer anderen KI),
ohne dass Ziel und Leitplanken verrutschen. Nutzerdaten bleiben lokal in `~/.koordinat`; die App
sammelt nichts nach außen und führt fremden Code nie von selbst aus.

## Nächste Bauschritte
Siehe die Tabelle „Offen" in `koordinat_app/README.md` (Guide ausbauen, Oberfläche, Container-Ausführung,
Modell-Anbindung aus `referenz/koordinat_kern.py`, Google-OAuth vor den Besitzer-Schlüssel).
