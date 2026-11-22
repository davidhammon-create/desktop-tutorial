# AtmOS 0.2 – alle KIs, alle Befehle, alle Werkzeuge in einer App

AtmOS ist die Oberfläche (React/Vite, auch als Electron-Desktop-App) über der Koordinationsschicht KOORDINAT 2.1
(`python/`). Dieser Stand wurde aus `AtmOS-GANZER-CODE.pdf` vollständig zurückgewonnen und erweitert.

## Starten
```bash
npm install --legacy-peer-deps
npm run dev            # http://localhost:8080
npm test               # Vitest
npm run electron:dev   # Desktop-App
```
Ohne `.env` läuft alles im Demo-Modus (vorher stoppte eine fehlende Supabase-Adresse die ganze App).

## Neu in 0.2
| Bereich | Was | Befehl |
|---|---|---|
| **KIs** | 15 Anbieter: Claude, OpenAI, Gemini, Mistral, DeepSeek, xAI, Groq, OpenRouter, Together, Perplexity, Fireworks, Cerebras, Ollama, LM Studio, eigener OpenAI-kompatibler Server. Schlüssel, Modell, Test, Modellliste je Anbieter. | Navigation → KIs, `/anbieter` |
| **Chat** | Gespräch mit der Standard-KI, `@gemini` oder `--effort max` je Frage | `/frage …`, `/neu` |
| **Alle KIs** | dieselbe Frage parallel an jede verbundene KI | `/alle …` |
| **Effort** | Denktiefe `aus · low · medium · high · xhigh · max`, je Anbieter übersetzt (Claude `output_config.effort`, OpenAI `reasoning_effort`, Gemini `thinkingBudget`, OpenRouter `reasoning.effort`). Router-Stufe 0–6 bleibt: ab 4 plant bei `/mach` eine echte KI, bei 6 alle. | `/effort high`, `/effort 6` |
| **Katalog** | 236 gegen GitHub geprüfte Repos in 22 Kategorien mit echten Sternzahlen und Lizenzen (vorher 35 mit erfundenen Werten) | Navigation → Katalog, `/katalog MCP` |
| **Referenz** | 208 Befehle und Regler: Claude Code, Codex CLI, Gemini CLI, Aider, Cursor, Ollama, llama.cpp, APIs, MCP, Git/GitHub, Prompting | Navigation → Referenz, `/befehle effort` |
| **Antwortkarte** | Ergebnisse jedes Befehls werden angezeigt (vorher landeten sie nur in der Spur) | – |
| **Handy** | Navigation als Leiste, keine Lücke mehr | – |

Schlüssel liegen nur lokal (localStorage bzw. Electron-Profil) und gehen nur an den jeweiligen Anbieter. Fragen kosten
dort Geld. Claude-Modelle der 5er-Reihe schicken den serverseitigen Fallback mit (`fallbacks: "default"`).
Lokale Dienste brauchen eine CORS-Freigabe, z. B. `OLLAMA_ORIGINS=* ollama serve`.

Python-Seitenwagen: `cd python && python3 -m koordinat anbieter | frage "…" --alle | befehle effort` (gleiche Logik, plus MCP-Werkzeuge
`koordinat_frage`, `koordinat_befehle`, `koordinat_ki_anbieter`).

---

# Welcome to your Lovable project
## Project info
**URL**: https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID
## How can I edit this code?
There are several ways of editing your application.
**Use Lovable**
Simply visit the [Lovable Project](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and start prompting.
Changes made via Lovable will be committed automatically to this repo.
**Use your preferred IDE**
If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.
The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)
Follow these steps:
```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>
# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>
# Step 3: Install the necessary dependencies.
npm i
# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```
**Edit a file directly in GitHub**
- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.
**Use GitHub Codespaces**
- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.
## What technologies are used for this project?
This project is built with:
- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS
## How can I deploy this project?
Simply open [Lovable](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and click on Share -> Publish.
## Can I connect a custom domain to my Lovable project?
Yes, you can!
To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.
Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
