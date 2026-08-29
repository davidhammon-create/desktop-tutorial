# Modellsammlung – Interaktive 3D-Modelle für das Studium

Eine Lernplattform mit wissenschaftlich korrekten, interaktiven 3D-Modellen für
**Physik, Chemie, Biologie und Medizin** auf Universitätsniveau.

Jedes Modell verbindet eine räumliche Darstellung mit ausführlichem Fachtext,
Kennzahlen und typischen Prüfungsfragen. Die Geometrien sind nicht dekorativ,
sondern beruhen auf realen Strukturparametern – die Wasserstoff-Orbitale werden
zum Beispiel zur Laufzeit aus den analytischen Lösungen der Schrödinger-Gleichung
gesampelt, und die B-DNA verwendet die echten Helixparameter samt des
140°-Strangversatzes, aus dem große und kleine Furche entstehen.

## Modellübersicht

### ⚛ Physik
| Modell | Inhalt |
|---|---|
| **Quantencomputer (Transmon)** | Mischkryostat mit allen Kühlstufen, Josephson-Kontakte, dispersive Auslese, Bloch-Kugel mit Rabi-Oszillation |
| **Wasserstoff-Orbitale** | 1s/2s/2p/3s/3d als Monte-Carlo-Sampling von \|ψ\|², Vorzeichen farbcodiert, Knotenstruktur sichtbar |
| **Kristallgitter** | fcc, bcc, hcp und Diamantstruktur, Packungsdichten, Koordinationspolyeder, (111)-Netzebene |
| **Elektromagnetische Welle** | E- und B-Feld in Phase, Poynting-Vektor, lineare und zirkulare Polarisation |

### ⬡ Chemie
| Modell | Inhalt |
|---|---|
| **Benzol & π-System** | σ-Gerüst, sechs p_z-Orbitale, delokalisierte π-Wolke, animierter Ringstrom, Hückel-Regel |
| **Hybridisierung** | sp³/sp²/sp im direkten Vergleich – Geometrie, s-Anteil, σ/π-Trennung, C–H-Acidität |
| **Ionengitter NaCl** | Zwei fcc-Untergitter, Koordinationsoktaeder, Radienquotient, Gitterschwingung |
| **Cyclohexan** | Sesselkonformation mit animierter Ringinversion (axial ⇄ äquatorial), Wanne, A-Werte |

### 🧬 Biologie
| Modell | Inhalt |
|---|---|
| **B-DNA Doppelhelix** | 10,5 bp/Windung, 3,4 Å Anstieg, A–T/G–C mit korrekter Zahl an H-Brücken, Furchen |
| **Eukaryotische Zelle** | Kern mit Poren und Nukleolus, ER, Golgi, Mitochondrien, Lysosomen, Zytoskelett, Vesikeltransport |
| **Proteinstruktur** | α-Helix (i→i+4-Brücken), antiparalleles β-Faltblatt, Tertiärstruktur mit hydrophobem Kern |
| **Atmungskette & ATP-Synthase** | Komplex I–IV, Protonengradient, rotierender c-Ring mit Bindungswechsel-Mechanismus |

### 🫀 Medizin
| Modell | Inhalt |
|---|---|
| **Herz** | Vier Kammern im Herzzyklus, Klappenbewegung, Erregungsleitung vom Sinusknoten bis zu den Purkinje-Fasern, Koronarien |
| **Nephron** | Glomerulus, Tubulussystem, kortikomedullärer Osmolaritätsgradient, Gegenstromprinzip |
| **Chemische Synapse** | Sechs Schritte von der AP-Ankunft über Ca²⁺-Einstrom und Vesikelfusion bis zur Rezeptoröffnung |
| **Alveole** | Blut-Luft-Schranke im Schichtaufbau, Kapillarnetz, Erythrozytensättigung, Surfactant |

## Bedienung

| Eingabe | Wirkung |
|---|---|
| Ziehen mit linker Maustaste | Modell drehen |
| Scrollen | Zoomen |
| Ziehen mit rechter Maustaste | Ansicht verschieben |
| `Leertaste` | Animation anhalten / fortsetzen |
| `R` | Kameraansicht zurücksetzen |
| `L` | Beschriftungen ein-/ausblenden |
| `I` | Infopanel ein-/ausklappen |
| `↑` `↓` `←` `→` | Vorheriges / nächstes Modell |

Zusätzlich lässt sich über die **Ebenen-Leiste** oben rechts jede Baugruppe
einzeln ein- und ausblenden – etwa nur das σ-Gerüst des Benzols ohne π-System
oder das Nephron ohne Osmolaritätsgradient. Der **Tempo-Regler** verlangsamt
Animationen bis zum Stillstand, was bei mehrstufigen Abläufen wie der
synaptischen Übertragung hilfreich ist.

Die **Suche** oben durchsucht nicht nur Modellnamen, sondern auch die
vollständigen Fachtexte und Kennzahlen – eine Suche nach „Gegenstrom“,
„Hückel“ oder „Josephson“ findet das passende Modell.

## Infopanel

Jedes Modell besitzt vier Textbereiche:

- **Überblick** – Kernaussage und der zentrale Abschnitt
- **Vertiefung** – vollständiger Fachtext, meist vier Abschnitte mit Herleitungen
- **Kennzahlen** – Tabelle mit den prüfungsrelevanten Zahlenwerten
- **Prüfung** – typische Klausur- und Physikumsfragen zum Modell

## Als App nutzen

Das Projekt läuft auf drei Wegen aus demselben Quellcode:

| Weg | Wie | Wofür |
|---|---|---|
| **Im Browser** | `npm run dev` | Entwicklung |
| **Als installierte PWA** | Im Browser öffnen → „App installieren" | Handy, Tablet, Desktop – offline nutzbar |
| **Als Desktop-App** | `npm run electron:build` | Windows, macOS, Linux mit Installer |

### PWA (installierbare Web-App)

Nach `npm run build` enthält der Build ein Web-App-Manifest und einen Service
Worker, der alle Dateien vorab zwischenspeichert. Ergebnis:

- Ein Knopf **„App installieren"** erscheint oben rechts, sobald der Browser
  die Installation anbietet.
- Nach der Installation startet sie mit eigenem Icon ohne Browserleiste.
- Sie funktioniert **vollständig offline** – alle 16 Modelle sind lokal.
- Bei einer neuen Version erscheint unten rechts ein Hinweis mit
  „Jetzt aktualisieren".

Auf dem iPhone gibt es kein Installationsangebot durch den Browser; dort läuft
es über Teilen → „Zum Home-Bildschirm". Die dafür nötigen Angaben stehen in
`index.html`.

Wichtig: Ein Service Worker braucht HTTPS (Ausnahme: `localhost`). Auf einem
Webserver muss die Seite also über HTTPS ausgeliefert werden, sonst bleibt es
bei einer normalen Website ohne Installation und ohne Offline-Betrieb.

### Desktop-App

```bash
npm run electron:dev            # Entwicklung: startet Vite und Electron zusammen
npm run electron:pack           # Ungepackter Testlauf in release/
npm run electron:build          # Installer für das aktuelle System
npm run electron:build:win      # .exe  (NSIS)
npm run electron:build:mac      # .dmg  (x64 und Apple Silicon)
npm run electron:build:linux    # AppImage und .deb
```

Die Installer landen in `release/`.

Zu beachten: Ein Installer lässt sich nur auf dem jeweiligen Betriebssystem
zuverlässig erzeugen – ein `.dmg` also auf einem Mac, eine signierte `.exe` unter
Windows. Für alle drei Plattformen aus einem Lauf heraus braucht es eine CI mit
entsprechenden Runnern.

## Installation

```bash
npm install
npm run dev      # Entwicklungsserver auf http://localhost:5173
npm run build    # Produktions-Build (Web/PWA) nach dist/
npm run preview  # Build lokal testen auf http://localhost:4173
npm run icons    # App-Icons neu erzeugen (benötigt Python mit Pillow)
npm run pdf      # Quellcode-PDF erzeugen (benötigt Python mit reportlab)
```

### Smoke-Test

`scripts/smoke.mjs` öffnet jedes der 16 Modelle in einem echten Browser,
schaltet dabei alle Ebenen und Textbereiche durch und meldet jeden Konsolen-
oder Laufzeitfehler:

```bash
npm run build && npm run preview   # in einem Terminal
npm run smoke                      # in einem zweiten
```

Der Test endet mit Exit-Code 1, sobald irgendein Modell einen Fehler wirft –
so fällt ein kaputtes Modell sofort auf, statt erst beim Anklicken.

## Projektstruktur

```
electron/
├── main.cjs             Hauptprozess: Fenster, Menü, Sicherheitsregeln
└── preload.cjs          Isolierte Brücke zum Renderer
scripts/
├── smoke.mjs            Browser-Test über alle Modelle
├── electron-dev.mjs     Startet Vite und Electron gemeinsam
├── icons.py             Erzeugt die App-Icons
└── code2pdf.py          Erzeugt die Quellcode-PDF
src/
├── App.jsx              Oberfläche: Navigation, Werkzeuge, Infopanel
├── styles.css           Gestaltung
├── pwa/
│   ├── PwaLeiste.jsx    Installations-Knopf und Update-Hinweis
│   └── register-stub.js Ersatzmodul für den Electron-Build
├── three/
│   ├── Viewer.jsx       Renderer, OrbitControls, HTML-Beschriftungen,
│   │                    Aufbau und Freigabe beim Modellwechsel
│   └── lib.js           Bausteine: Atome, Bindungen, Schläuche, Pfeile,
│                        Orbitallappen, Lipiddoppelschicht, Punktwolken
└── models/
    ├── index.js         Registry und Volltextsuche
    ├── physik/          4 Modelle
    ├── chemie/          4 Modelle
    ├── biologie/        4 Modelle
    └── medizin/         4 Modelle
```

## Ein eigenes Modell ergänzen

Eine Datei in den passenden Fachordner legen und in `src/models/index.js`
eintragen. Das Format:

```js
export default {
  id: 'ribosom',
  name: 'Ribosom',
  discipline: 'biologie',      // physik | chemie | biologie | medizin
  level: 'Master',
  tagline: 'Translation Schritt für Schritt',
  scale: '1 Einheit = 1 nm',

  build() {
    const group = new THREE.Group()
    const untereinheiten = new THREE.Group()
    // ... Geometrie aufbauen, Bausteine aus three/lib.js nutzen
    group.add(untereinheiten)

    return {
      group,
      camera: { position: [0, 8, 40], target: [0, 0, 0] },
      layers: [
        { id: 'gross', name: '50S-Untereinheit', objects: [untereinheiten] },
      ],
      update(t, dt) {
        // wird pro Frame aufgerufen, solange die Animation läuft
      },
    }
  },

  info: {
    summary: '…',
    sections: [{ title: '…', body: ['…', '…'] }],
    facts: [{ k: 'Sedimentationskoeffizient', v: '70S' }],
    exam: ['…'],
  },
}
```

Der Viewer übernimmt Kamera, Beleuchtung, Ebenen-Umschaltung und gibt beim
Modellwechsel alle Geometrien, Materialien und Beschriftungen wieder frei.

## Technik

- **React 18** für die Oberfläche
- **Three.js 0.160** mit `OrbitControls` und `CSS2DRenderer` für Beschriftungen,
  die als HTML über der Szene liegen und mit dem Modell mitdrehen
- **Vite** als Build-Tool; Three.js wird in einen eigenen Chunk ausgelagert
- **vite-plugin-pwa** (Workbox) für Manifest, Service Worker und Offline-Betrieb
- **Electron** samt electron-builder für die Desktop-Installer
- **Playwright** für den Smoke-Test

Ein Quellcode, zwei Build-Ziele – gesteuert über den Vite-Modus:

| | `npm run build` | `npm run build:electron` |
|---|---|---|
| Ausgabe | `dist/` | `dist-electron-web/` |
| Pfade | absolut (`/`) | relativ (`./`) für `file://` |
| Service Worker | ja | nein (Dateien liegen ohnehin lokal) |

Damit der Electron-Build nicht am fehlenden PWA-Modul scheitert, bildet
`vite.config.js` in diesem Modus `virtual:pwa-register/react` auf
`src/pwa/register-stub.js` ab – gleiche Signatur, ohne Funktion.

Einige Details, die für flüssige Darstellung sorgen:

- Beim Modellwechsel wird der komplette Szenenbaum abgeräumt – Geometrien,
  Materialien, Texturen und die DOM-Knoten der Beschriftungen. Ohne das würde
  jeder Wechsel Grafikspeicher liegen lassen.
- Es läuft genau **eine** Animationsschleife im Viewer. Modelle liefern nur eine
  `update(t, dt)`-Funktion, statt eigene Schleifen zu starten.
- Die Lipiddoppelschichten bestehen aus mehreren tausend Lipiden und werden als
  `InstancedMesh` gezeichnet: zwei Draw Calls statt Tausender.
- Es werden keine externen Schriften oder CDN-Ressourcen geladen; die Seite
  funktioniert vollständig offline.

## Lizenz

MIT
