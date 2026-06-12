# LegalOS® – Legal-Tech Web App (Standalone)

Eigenständige Web-App ohne base44-Backend. Alle Daten werden in `localStorage` gespeichert.
KI-Buttons zeigen realistische Mock-Ergebnisse (Mockup-Modus).

## Starten (benötigt Node.js 18+)

```bash
npm install
npm run dev
```

Dann Browser öffnen: **http://localhost:3000**

## Für echte KI-Anbindung

In `src/lib/kiProvider.js`:
```js
const KI_MODE = "offline";          // "offline" = lokale KI
const OFFLINE_KI_URL = "http://localhost:11434/api/chat";  // z.B. Ollama
const OFFLINE_KI_MODEL = "llama3";
```

## Für echtes Backend (wenn wieder vorhanden)

In `src/api/base44Client.js` den Mock durch:
```js
import { createClient } from '@base44/sdk';
export const base44 = createClient({ appId: 'DEINE_APP_ID', ... });
```
ersetzen.
