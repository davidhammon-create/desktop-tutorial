# AtmOS + KOORDINAT

- [`atmos-app/`](atmos-app/README.md) – **AtmOS 0.2**: die komplette App aus `AtmOS-GANZER-CODE.pdf` (React/Vite/Electron + Python-Seitenwagen KOORDINAT 2.1), erweitert um alle KIs, Effort, 236 geprüfte Repos, 208 Befehle.
- [`koordinat_app/`](koordinat_app/README.md) / [`AtemOS/`](AtemOS/README.md) – KOORDINAT v0.5 (reines Python, CLI + lokale Web-Oberfläche + MCP).

Alle KIs, alle KI-Werkzeuge und ihre Befehle an einem Ort – mit geprüftem Repo-Katalog, geführten Abläufen,
Web-Oberfläche und MCP-Server.

Die App liegt in [`koordinat_app/`](koordinat_app/README.md) (gleich in [`AtemOS/`](AtemOS/README.md) zum Öffnen in Cursor/Claude Code).

```
cd koordinat_app
python3 tests.py                  # 140 Selbsttests
python3 -m koordinat uebersicht   # alles auf einen Blick
python3 -m koordinat ui           # Oberfläche im Browser
```
