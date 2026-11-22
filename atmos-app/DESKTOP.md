# AtmOS Desktop
Electron shell around the existing Vite React AtmOS UI (KOORDINAT shell + Apple App Store?style ?K overlay). Visual style is unchanged ? desktop only adds a native window.
## Downloads (GitHub Release `v0.1.0-desktop`)
Release page: https://github.com/dniemann2016/apple-legal-ease/releases/tag/v0.1.0-desktop
| Platform | Direct download |
|----------|-----------------|
| **macOS Apple Silicon** | https://github.com/dniemann2016/apple-legal-ease/releases/download/v0.1.0-desktop/AtmOS-0.1.0-macOS-arm64.zip |
| **macOS Intel** | https://github.com/dniemann2016/apple-legal-ease/releases/download/v0.1.0-desktop/AtmOS-0.1.0-macOS-x64.zip |
| **Windows x64** | https://github.com/dniemann2016/apple-legal-ease/releases/download/v0.1.0-desktop/AtmOS-0.1.0-windows-x64.zip |
| **Linux AppImage** | https://github.com/dniemann2016/apple-legal-ease/releases/download/v0.1.0-desktop/AtmOS-0.1.0-x86_64.AppImage |
| **Linux deb** | https://github.com/dniemann2016/apple-legal-ease/releases/download/v0.1.0-desktop/AtmOS-0.1.0-amd64.deb |
| **Full source zip** | https://github.com/dniemann2016/apple-legal-ease/releases/download/v0.1.0-desktop/AtmOS-0.1.0-full-source.zip |
Repo is private ? you must be signed in to GitHub with access. macOS builds are unsigned (right-click ? Open the first time).
## Run (dev)
```bash
npm i
npm run electron:dev
```
Opens a minimal AtmOS window loading the Vite app at `/` (HashRouter inside Electron). Web `npm run dev` still works as before.## Package
| Script | What it builds |
|--------|----------------|
| `npm run electron:dist:linux` | **AppImage + deb** (what this Linux CI can produce) |
| `npm run electron:dist:mac` | **dmg + zip** (requires macOS host / signed tooling) |
| `npm run electron:dist:win` | **NSIS installer + portable** (requires Windows host or Wine) |
| `npm run electron:dist:all` | mac + win + linux via electron-builder `-mwl` |
| `npm run electron:pack` | Unpacked dir only (`release/<platform>-unpacked`) |
Artifacts land in `release/`.
### This environment (Linux)
```bash
npm run electron:dist:linux
```
Produced on this Linux host:
- `release/AtmOS-0.1.0-x86_64.AppImage`
- `release/AtmOS-0.1.0-amd64.deb`
- Unpacked: `release/linux-unpacked/`
Cross-building macOS/Windows binaries from Linux is not reliable without extra toolchains; configs for dmg/zip/nsis/portable are in `package.json` ? `build` so Mac/Windows CI or local machines can run the matching scripts.
## Window chrome
- Title: **AtmOS**
- Dark background `#0a0a0c` matching the shell
- Auto-hidden menu bar (Linux/Windows); macOS uses `hiddenInset` title bar
- Main shell route: `/` (same AtmOS page as the web app)
## Layout
- `electron/main.cjs` ? BrowserWindow + load Vite (dev) / `dist/index.html` (prod)
- `electron/preload.cjs` ? exposes `window.atmosDesktop`
- `build/icons/icon.png` ? app icon for electron-builder
