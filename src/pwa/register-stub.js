/**
 * Ersatz für 'virtual:pwa-register/react' im Electron-Build.
 *
 * Dort ist das PWA-Plugin abgeschaltet, das virtuelle Modul existiert also
 * nicht und der Build würde an dem Import scheitern. vite.config.js bildet die
 * Kennung im Electron-Modus auf diese Datei ab. Die Signatur entspricht der
 * echten, liefert aber durchgehend "nichts zu tun" – die Desktop-App hat ihre
 * Dateien ohnehin lokal und aktualisiert sich über den Installer.
 */
export function useRegisterSW() {
  return {
    needRefresh: [false, () => {}],
    offlineReady: [false, () => {}],
    updateServiceWorker: () => Promise.resolve(),
  }
}
