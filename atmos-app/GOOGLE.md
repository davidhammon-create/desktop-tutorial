# AtmOS ? Google APIs
Live Google calls are optional. Without keys, `/suche`, `/google`, and router hints use **demo fallbacks** (KOORDINAT-Katalog + sample hits).
## Einstellungen (preferred)
?K ? **Einstellungen**:
1. **Apple Intelligence** ? first provider toggle (stub until system API).
2. **Google / Gemini** ? paste API key + optional CSE ID ? **Speichern**.
3. OpenAI / Anthropic keys optional for later.
Keys persist in `localStorage` (`atmos.provider.secrets.v1`) ? never committed.
## Env vars (optional override)
| Variable | Purpose |
|----------|---------|
| `ATMOS_GOOGLE_API_KEY` | Google API key with **Generative Language API** (Gemini) enabled. Also used for Custom Search when CSE ID is set. |
| `ATMOS_GOOGLE_CSE_ID` | [Programmable Search Engine](https://programmablesearchengine.google.com/) ID for live web/GitHub-flavored `/suche`. |
| `ATMOS_GEMINI_MODEL` | Optional, default `gemini-2.0-flash`. |
Aliases: `VITE_GOOGLE_API_KEY`, `VITE_GEMINI_API_KEY`, `VITE_GOOGLE_CSE_ID`.
Copy `.env.example` ? `.env` for local Vite/Electron. Einstellungen values win over env when Google is enabled.
### Cursor app secrets
To reach Google (Gemini / Custom Search), the app needs 3 values. Add them in the secure form. If you don't have them, ask your team admin. I can publish now with sample data and switch to real data once they're added.
Bind `ATMOS_GOOGLE_API_KEY`, `ATMOS_GOOGLE_CSE_ID`, `ATMOS_GEMINI_MODEL` in Cursor Dashboard ? Secrets (do not paste keys into chat). Vite `envPrefix` includes `ATMOS_`.
## Commands
| Command | Live behavior | Demo |
|---------|---------------|------|
| `/suche <q>` | KOORDINAT-Katalog + Google Custom Search (if key+CSE) + optional Gemini summary | Katalog + demo Google rows || `/google <q>` | Alias focused on Google layer | Demo hits |
| `/mach ?` / router | After local plan, Gemini may add a short router hint when key present | Local KOORDINAT plan only |
| `/vital` | Reports Google mode (`live` / `demo`) | ? |
## Verify
```bash
# no keys ? demo
npm run electron:dev
# ?K ? /suche gemini
# with keys in .env
ATMOS_GOOGLE_API_KEY=? ATMOS_GOOGLE_CSE_ID=? npm run electron:dev
```
