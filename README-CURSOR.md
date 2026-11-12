# FenlynineOS Legal Suite — Bauen in Cursor

Snapshot `Fenlynine-11.08.26-R1` · 225 Quelldateien · Swift 5.9 / SwiftUI · macOS 14+

## In drei Schritten zum laufenden Build

```bash
# 1 · Ordner in Cursor öffnen (dieser hier)
# 2 · Bauen
swift build -c release

# 3 · Starten
swift run FenlynineOS
```

Fertig. Der erste Build dauert je nach Mac zwei bis fünf Minuten.

Alternativ die signierte `.app` erzeugen (nur auf macOS mit Xcode-Tools):

```bash
bash scripts/build-app.sh release
```

## Voraussetzungen

| | |
|---|---|
| Betriebssystem | macOS 14 (Sonoma) oder neuer — die App nutzt SwiftUI-APIs von macOS 14 |
| Toolchain | Xcode 15+ oder Swift 5.9 Command Line Tools (`xcode-select --install`) |
| Abhängigkeiten | keine — `Package.swift` hat `dependencies: []`, es wird nichts nachgeladen |

Auf Linux oder Windows lässt sich das Projekt **nicht** bauen: es verwendet
AppKit und macOS-eigene SwiftUI-Szenen (`MenuBarExtra`, `NSApplicationDelegateAdaptor`).

## Ein Hinweis zu den Bild-Assets

`Sources/FenlynineOS/Resources/Assets.xcassets/` enthält zwei **Platzhalter-Bilder**
(neutrale Farbverläufe). Die Originale konnten nicht mitkommen, weil sie als
Binärdateien nicht in einen PDF-Katalog passen.

Betroffen sind ausschließlich zwei Vorschaubilder in den Design-Einstellungen.
Die App baut und läuft damit vollständig — ersetzen Sie die Dateien bei
Gelegenheit durch Ihre Originale, Details in `Resources/README-RESOURCES.txt`.

## Aufbau des Projekts

```
Package.swift                    Build-Definition (keine externen Pakete)
Configuration/                   Info.plist · Entitlements
scripts/                         Build-, Start- und Export-Skripte
Sources/FenlynineOS/
├─ FenlynineOSApp.swift          App-Einstieg, Fenster, Menübefehle
├─ Core/                         Backend: Modelle, Services, KI-Anbindung,
│                                Sicherheit, Konten, Rechtsdaten
├─ Components/                   Design-System: Farben, Typografie, Glas-Effekte
└─ Features/                     Oberfläche, nach Modulen gegliedert:
   ├─ Studio/                    Produkt-Spine — hier startet die App
   ├─ Vorgang/                   Vorgänge mit vier Linsen
   ├─ Cases/                     Fälle & Mandate (Lexara)
   ├─ Strategos/ Opportunisma/   Szenarien und Chancen-Radar
   ├─ Imperium/                  Kanzlei-Verwaltung
   ├─ Organon/                   Team & Netzwerk
   └─ Shell/ Konto/ Wartung/ …   Einstellungen, Konten, Selbstreparatur
```

Der Einstiegspunkt ist `FenlynineOSApp.swift`; die tragende Oberfläche ist
`Features/Studio/FenlynineOSStudioShell.swift`.

## Was an dieser Fassung überarbeitet wurde

Die Bedienung wurde vereinfacht, **ohne eine einzige Funktion zu verändern**:

1. **Klartext-Namen** — Module heißen nach ihrer Funktion, die Marke steht in
   Klammern: „Fälle & Mandate (Lexara)“, „Zukunfts-Szenarien (Strategos)“.
2. **Beschriftete Hauptleiste** — jedes Icon trägt ein Label statt nur ein Symbol.
3. **Modul-Bibliothek nach Tätigkeit sortiert** — jede Zeile mit Erklärsatz.
4. **Einstellungen gruppiert** — 13 flache Reiter wurden vier Gruppen.
5. **Tutorial aktualisiert** — erklärt die neue Navigation.

Alle `rawValue`s, Routing-Ziele, Deep-Links und gespeicherten Einstellungen sind
unverändert. Betroffen waren vier Dateien: `AppShell.swift`,
`FenlynineOSStudioShell.swift`, `EinstellungenView.swift`, `TutorialView.swift`.
