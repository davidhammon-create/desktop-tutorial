/**
 * Electron-Hauptprozess der Desktop-App.
 *
 * CommonJS (.cjs), weil package.json "type": "module" setzt – Electrons
 * Hauptprozess wird als CommonJS geladen.
 *
 * Sicherheitsgrundsätze: Der Renderer bekommt keinen Node-Zugriff
 * (nodeIntegration aus, contextIsolation an, sandbox an). Die App braucht das
 * nicht – sie rendert nur lokale 3D-Modelle. Externe Links öffnen im
 * Systembrowser statt in einem App-Fenster.
 */
const { app, BrowserWindow, shell, Menu } = require('electron')
const path = require('node:path')

const istEntwicklung = !app.isPackaged
const DEV_SERVER = process.env.VITE_DEV_SERVER_URL ?? 'http://localhost:5173'

function fensterErzeugen() {
  const fenster = new BrowserWindow({
    width: 1500,
    height: 950,
    minWidth: 900,
    minHeight: 600,
    backgroundColor: '#070912',
    title: 'Modellsammlung',
    icon: path.join(__dirname, '..', 'build', 'icon.png'),
    // Fenster erst zeigen, wenn Inhalt da ist – vermeidet ein weißes Aufblitzen
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  })

  fenster.once('ready-to-show', () => fenster.show())

  if (istEntwicklung) {
    fenster.loadURL(DEV_SERVER)
  } else {
    fenster.loadFile(path.join(__dirname, '..', 'dist-electron-web', 'index.html'))
  }

  // Links mit target=_blank im Systembrowser öffnen, nicht in der App
  fenster.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url)
    return { action: 'deny' }
  })

  // Navigation aus der App heraus unterbinden
  fenster.webContents.on('will-navigate', (ereignis, url) => {
    const ziel = new URL(url)
    const erlaubt = istEntwicklung && ziel.origin === new URL(DEV_SERVER).origin
    if (!erlaubt && ziel.protocol !== 'file:') {
      ereignis.preventDefault()
      shell.openExternal(url)
    }
  })

  return fenster
}

function menueAufbauen() {
  const istMac = process.platform === 'darwin'
  Menu.setApplicationMenu(
    Menu.buildFromTemplate([
      ...(istMac ? [{ role: 'appMenu' }] : []),
      {
        label: 'Datei',
        submenu: [istMac ? { role: 'close' } : { role: 'quit', label: 'Beenden' }],
      },
      {
        label: 'Ansicht',
        submenu: [
          { role: 'reload', label: 'Neu laden' },
          { role: 'toggleDevTools', label: 'Entwicklerwerkzeuge' },
          { type: 'separator' },
          { role: 'resetZoom', label: 'Zoom zurücksetzen' },
          { role: 'zoomIn', label: 'Vergrößern' },
          { role: 'zoomOut', label: 'Verkleinern' },
          { type: 'separator' },
          { role: 'togglefullscreen', label: 'Vollbild' },
        ],
      },
      { role: 'windowMenu' },
    ]),
  )
}

app.whenReady().then(() => {
  menueAufbauen()
  fensterErzeugen()

  // macOS: Beim Klick aufs Dock-Icon ein Fenster öffnen, falls keines offen ist
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) fensterErzeugen()
  })
})

app.on('window-all-closed', () => {
  // macOS lässt Apps üblicherweise ohne Fenster weiterlaufen
  if (process.platform !== 'darwin') app.quit()
})
