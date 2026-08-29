/**
 * Startet Vite und danach Electron – ohne Zusatzpakete wie concurrently oder
 * wait-on, damit die Abhängigkeitsliste schlank bleibt.
 *
 *   npm run electron:dev
 *
 * Ablauf: Vite starten, warten bis der Port antwortet, Electron starten.
 * Beendet sich eines von beiden, wird auch das andere gestoppt.
 */
import { spawn } from 'node:child_process'
import process from 'node:process'

const URL = 'http://localhost:5173'
const istWindows = process.platform === 'win32'
const npx = istWindows ? 'npx.cmd' : 'npx'

const vite = spawn(npx, ['vite', '--port', '5173', '--strictPort'], {
  stdio: 'inherit',
  shell: istWindows,
})

async function warteAufServer(versuche = 60) {
  for (let i = 0; i < versuche; i++) {
    try {
      const antwort = await fetch(URL)
      if (antwort.ok) return true
    } catch {
      // Server noch nicht bereit – weiter warten
    }
    await new Promise((r) => setTimeout(r, 500))
  }
  return false
}

const bereit = await warteAufServer()
if (!bereit) {
  console.error(`Vite antwortet nicht unter ${URL} – Abbruch.`)
  vite.kill()
  process.exit(1)
}

const electron = spawn(npx, ['electron', '.'], {
  stdio: 'inherit',
  shell: istWindows,
  env: { ...process.env, VITE_DEV_SERVER_URL: URL },
})

const aufraeumen = () => {
  vite.kill()
  electron.kill()
}

electron.on('close', (code) => {
  vite.kill()
  process.exit(code ?? 0)
})
vite.on('close', () => electron.kill())
process.on('SIGINT', aufraeumen)
process.on('SIGTERM', aufraeumen)
