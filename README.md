# AboWandler

KI-Finanz & Abo-Check App. Verbindet (Demo-Modus) oder importiert Konten/Kontoauszüge, erkennt per KI wiederkehrende und verdächtige Zahlungen, recherchiert Firmen im Web, schreibt Kündigungsbriefe und rechnet vor, was aus gekündigten Abos in einem ETF-Sparplan werden könnte.

Frontend: React + Vite. Backend: Express (Node).

## Entwicklung

Zwei Prozesse, zwei Terminals:

```bash
# Terminal 1 — Backend
cd server
npm install
cp .env.example .env   # ANTHROPIC_API_KEY eintragen für KI-Funktionen
npm run dev            # läuft auf Port 8787

# Terminal 2 — Frontend
npm install
npm run dev            # läuft auf Port 5173, proxyt /api an Port 8787
```

Ohne `ANTHROPIC_API_KEY` läuft die App vollständig (Abo-Verwaltung, ETF-Rechner, Konten-Demo), nur die KI-Endpunkte (Kontoauszug-Analyse, Firmenbericht, Kündigungsbrief) liefern dann einen klaren Fehlerhinweis statt eines Ergebnisses.

## Build

```bash
npm run build
```

## Architektur

- `src/` — Frontend (Landing, Dashboard, Abo-Liste, Konten & Import, ETF-Explorer, Einstellungen)
- `server/` — Backend: AI-Proxy (hält den Anthropic-Key serverseitig), Abo-CRUD mit AES-256-verschlüsselter Passwortablage, ETF-Referenzdaten, Konten-Demo-Endpunkte

### Was echt ist, was Demo ist

- **Abo-Verwaltung, ETF-Rechner, KI-Analyse/-Berichte/-Kündigungsbriefe**: voll funktionsfähig (KI-Teile benötigen `ANTHROPIC_API_KEY`).
- **Konten verbinden (PayPal, Bank, Kreditkarte, Klarna)**: Demo-Toggle. Echte Anbindung erfordert registrierte Zugänge bei einem Kontoaggregator (z. B. Tink, GoCardless, FinAPI für PSD2-Bankdaten) bzw. bei PayPal Developer — dafür sind eigene API-Keys und ein OAuth-Flow nötig, die hier nicht hinterlegt sind. Der funktionierende Datenweg ist der Import: Kontoauszug einfügen oder als PDF/CSV hochladen.
- **Logos**: über die öffentliche Clearbit-Logo-API anhand der Firmen-Domain, mit Fallback auf einen farbigen Buchstaben-Avatar, falls kein Logo geladen werden kann.

AboWandler ist keine Finanz-, Anlage- oder Rechtsberatung. Alle Prognosen sind unverbindliche Modellrechnungen.
