import React, { useEffect, useState } from 'react'
import { useRegisterSW } from 'virtual:pwa-register/react'

/**
 * Zwei kleine Einblendungen rund um die Installation:
 *
 *  - "Offline verfügbar", sobald der Service Worker alles zwischengespeichert hat
 *  - "Neue Version verfügbar" mit Knopf zum Aktualisieren
 *
 * Beides erscheint unauffällig unten rechts und blockiert die Ansicht nicht.
 */
export function PwaLeiste() {
  const {
    needRefresh: [aktualisierungBereit, setzeAktualisierung],
    offlineReady: [offlineBereit, setzeOffline],
    updateServiceWorker,
  } = useRegisterSW()

  // Der Offline-Hinweis verschwindet von selbst – er ist eine Bestätigung,
  // keine Aufgabe für den Nutzer.
  useEffect(() => {
    if (!offlineBereit) return
    const t = setTimeout(() => setzeOffline(false), 5000)
    return () => clearTimeout(t)
  }, [offlineBereit, setzeOffline])

  if (!aktualisierungBereit && !offlineBereit) return null

  return (
    <div className="pwa-hinweis" role="status">
      {aktualisierungBereit ? (
        <>
          <span>Eine neue Version ist verfügbar.</span>
          <button className="pwa-primaer" onClick={() => updateServiceWorker(true)}>
            Jetzt aktualisieren
          </button>
          <button className="pwa-sekundaer" onClick={() => setzeAktualisierung(false)}>
            Später
          </button>
        </>
      ) : (
        <span>✓ Die App ist jetzt offline verfügbar.</span>
      )}
    </div>
  )
}

/**
 * Installationsknopf für die PWA.
 *
 * Browser lösen 'beforeinstallprompt' nur aus, wenn die App installierbar und
 * noch nicht installiert ist. Fehlt das Ereignis, wird kein Knopf gezeigt –
 * das betrifft die bereits installierte App, die Desktop-App und iOS-Safari,
 * wo die Installation ausschließlich über "Zum Home-Bildschirm" läuft.
 */
export function InstallKnopf() {
  const [ereignis, setEreignis] = useState(null)
  const [installiert, setInstalliert] = useState(false)

  useEffect(() => {
    // In der Electron-App ist eine Installation sinnlos
    if (window.desktopApp?.istDesktop) return
    // Bereits im Standalone-Modus gestartet? Dann ist sie schon installiert.
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setInstalliert(true)
      return
    }

    const beiAufforderung = (e) => {
      e.preventDefault() // eigenen Knopf statt der Browserleiste zeigen
      setEreignis(e)
    }
    const beiInstallation = () => {
      setInstalliert(true)
      setEreignis(null)
    }

    window.addEventListener('beforeinstallprompt', beiAufforderung)
    window.addEventListener('appinstalled', beiInstallation)
    return () => {
      window.removeEventListener('beforeinstallprompt', beiAufforderung)
      window.removeEventListener('appinstalled', beiInstallation)
    }
  }, [])

  if (installiert || !ereignis) return null

  return (
    <button
      className="install-knopf"
      onClick={async () => {
        ereignis.prompt()
        const { outcome } = await ereignis.userChoice
        // Das Ereignis ist einmalig verwendbar – danach in jedem Fall verwerfen.
        setEreignis(null)
        if (outcome === 'accepted') setInstalliert(true)
      }}
      title="Als App installieren"
    >
      ↓ App installieren
    </button>
  )
}
