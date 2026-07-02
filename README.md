# AboWandler

KI-Finanz & Abo-Check App. Findet wiederkehrende und verdächtige Zahlungen, klassifiziert alle Abos auf Knopfdruck, recherchiert Firmen im Web, schreibt Kündigungsbriefe und rechnet vor, was aus einem gekündigten Abo in einem ETF-Sparplan werden könnte.

**Alle Daten bleiben auf deinem Gerät** — es gibt keinen zentralen Cloud-Server. Frontend: React + Vite. Backend: eine lokale Express-App, die nur auf `127.0.0.1` läuft. Als Desktop-App: Electron.

---

## Genaue Anleitung: App starten

Voraussetzung für alle Wege: **Node.js** muss installiert sein (kostenlos, [nodejs.org](https://nodejs.org), LTS-Version reicht). Ohne Node.js läuft nichts von alldem — das ist die einzige Voraussetzung, es braucht keinen Account, keine Cloud, keine Installation von irgendwas anderem.

### Weg A — Doppelklick-Start (am einfachsten)

Im Hauptordner liegt ein Startprogramm für dein Betriebssystem:

- **Mac**: `start-mac.command` doppelklicken
- **Windows**: `start-windows.bat` doppelklicken
- **Linux**: `start-linux.sh` doppelklicken (oder `bash start-linux.sh`)

Beim ersten Start installiert es automatisch alles Nötige (kann ein paar Minuten dauern), danach öffnet sich AboWandler in deinem Standard-Browser unter `http://127.0.0.1:8787`. Bei jedem weiteren Start geht es sofort los.

> Mac: Falls eine Sicherheitswarnung erscheint ("nicht verifizierter Entwickler"), einmal rechtsklicken → Öffnen, statt doppelzuklicken.

### Weg B — Als natives Fenster (Electron)

```bash
npm install
cd server && npm install && cd ..
npm run electron
```

Öffnet AboWandler als eigenes Fenster statt im Browser. Für eine installierbare Datei (`.dmg` / `.exe` / `.AppImage`):

```bash
npm run dist
```

Das Ergebnis liegt danach im Ordner `release/`. **Wichtig:** Baue für dein eigenes Betriebssystem — ein `.dmg` entsteht nur auf einem Mac, ein `.exe` nur unter Windows (bzw. mit passendem Cross-Build-Setup).

### Weg C — Für die Entwicklung (im Browser, mit Hot-Reload)

Zwei Terminals:

```bash
# Terminal 1 — Backend
cd server
npm install
npm run dev            # läuft auf http://127.0.0.1:8787

# Terminal 2 — Frontend
npm install
npm run dev            # läuft auf http://localhost:5173, proxyt /api an Port 8787
```

Dann `http://localhost:5173` im Browser öffnen.

### KI-Funktionen aktivieren

Egal welcher Weg: In der App unter **Konto → KI-Zugang** einmal deinen eigenen [Anthropic API-Key](https://console.anthropic.com/settings/keys) eintragen. Er wird lokal auf deinem Gerät gespeichert (App-Datenordner bzw. `server/data/config.json` im Dev-Modus) — nicht in der Cloud, nicht im Code. Ohne Key läuft die App trotzdem vollständig; KI-Funktionen (Kontoauszug-Analyse, Firmenbericht, Kündigungsbrief, KI-Auto-Check) nutzen dann einen eingebauten Basis-Check statt echter KI.

---

## Wo landen meine Daten?

| Modus | Speicherort |
|---|---|
| `npm run electron` / `npm run dist` | Betriebssystem-Datenordner der App (z. B. `~/Library/Application Support/AboWandler` auf Mac, `%APPDATA%\AboWandler` auf Windows, `~/.config/AboWandler` auf Linux) |
| `npm run dev` (Browser) | `server/data/` im Projektordner |

In beiden Fällen: nur auf deinem eigenen Rechner, nie auf einem fremden Server. Passwörter sind zusätzlich AES-256-verschlüsselt.

## Build (nur Frontend, ohne Electron)

```bash
npm run build
```

## Architektur

- `src/` — Frontend (Landing, Dashboard, Abo-Liste, Konten & Import, ETF-Explorer, Einstellungen)
- `server/` — lokale Express-App: AI-Proxy (der Anthropic-Key verlässt nie den Browser/das Gerät des Nutzers), Abo-CRUD mit AES-256-verschlüsselter Passwortablage, ETF-Referenzdaten, Konten-Demo-Endpunkte. Läuft nur auf `127.0.0.1`, nicht im Netzwerk erreichbar.
- `electron/` — Desktop-Shell: startet die lokale Express-App als Kindprozess (mit Electrons eigenem Node — kein separates Node.js auf dem Zielrechner nötig) und öffnet ein natives Fenster darauf.

### KI-Auto-Check

Der Button „✦ KI-Auto-Check starten" (Übersicht) klassifiziert alle Abos auf einen Klick in Behalten / In ETF umwandeln / Warnung / Ausstehender Check — inkl. Begründung pro Abo:

- **Mit hinterlegtem API-Key**: echte Claude-Analyse (Betrugsmuster, Plausibilität, Preisentwicklung).
- **Ohne Key**: eingebauter Basis-Check (Regel-Engine: ausländische IBAN + unbekannte Firma, Preissprünge ≥ 25 %, nie überprüfte Alt-Verträge, Abgleich mit bekannter Anbieter-Liste) — klar als Basis-Check gekennzeichnet.

### ETF-Tausch pro Abo

Jede Abo-Karte hat einen „↗ ETF-Tausch"-Button: „Statt 19,99 € für Streaming → 19,99 €/Monat in MSCI World bzw. den rendite-stärksten ETF", mit 10/20/30-Jahres-Projektion und Renten-Boost nach 4%-Regel.

### Mobile / Cross-Platform

Das Frontend ist React — die portabelste Basis für den späteren Handy-Schritt (iOS + Android): als PWA installierbar (Manifest + Apple-Meta-Tags sind eingerichtet) oder per Capacitor/React Native in echte Store-Apps überführbar. Das Layout ist responsiv und auf Mobilgeräten getestet.

### Was echt ist, was Demo ist

- **Abo-Verwaltung, ETF-Rechner, KI-Auto-Check, KI-Analyse/-Berichte/-Kündigungsbriefe, Desktop-App**: voll funktionsfähig.
- **Konten verbinden (PayPal, Bank, Kreditkarte, Klarna)**: Demo-Toggle. Echte Anbindung erfordert registrierte Zugänge bei einem Kontoaggregator (z. B. Tink, GoCardless, FinAPI für PSD2-Bankdaten) bzw. bei PayPal Developer — dafür sind eigene API-Keys und ein OAuth-Flow nötig, die hier nicht hinterlegt sind. Der funktionierende Datenweg ist der Import: Kontoauszug einfügen oder als PDF/CSV hochladen.
- **Logos**: über die öffentliche Clearbit-Logo-API anhand der Firmen-Domain, mit Fallback auf einen farbigen Buchstaben-Avatar, falls kein Logo geladen werden kann (z. B. ohne Internetverbindung).

AboWandler ist keine Finanz-, Anlage- oder Rechtsberatung. Alle Prognosen sind unverbindliche Modellrechnungen.
