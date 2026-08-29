/**
 * Preload-Skript.
 *
 * Läuft isoliert zwischen Hauptprozess und Seite. Die App braucht derzeit keine
 * Systemfunktionen – deshalb wird bewusst nur eine minimale, schreibgeschützte
 * Information durchgereicht, damit die Oberfläche erkennen kann, dass sie in der
 * Desktop-App läuft (dort ist etwa der "App installieren"-Knopf sinnlos).
 *
 * Bewusst KEIN Zugriff auf ipcRenderer, fs oder require: Was nicht freigegeben
 * ist, kann auch nicht missbraucht werden.
 */
const { contextBridge } = require('electron')

contextBridge.exposeInMainWorld('desktopApp', {
  istDesktop: true,
  plattform: process.platform,
  versionen: {
    electron: process.versions.electron,
    chrome: process.versions.chrome,
  },
})
