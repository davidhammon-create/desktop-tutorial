import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

/**
 * Ein Quellcode, zwei Ziele:
 *
 *   npm run build           → Web / PWA   (absolute Pfade, Service Worker)
 *   npm run build:electron  → Desktop-App (relative Pfade, kein Service Worker)
 *
 * Electron lädt die Dateien über file:// – dort funktionieren absolute Pfade
 * nicht, deshalb base './'. Umgekehrt braucht ein Service Worker einen
 * absoluten Scope, weshalb er im Electron-Build entfällt (und dort auch keinen
 * Zweck hätte: die Dateien liegen ohnehin lokal).
 */
export default defineConfig(({ mode }) => {
  const fuerElectron = mode === 'electron'

  return {
    base: fuerElectron ? './' : '/',

    resolve: {
      alias: fuerElectron
        ? {
            // Ohne PWA-Plugin gibt es das virtuelle Modul nicht – der Import in
            // PwaLeiste.jsx würde den Build brechen. Der Stub hat dieselbe
            // Signatur und tut nichts.
            'virtual:pwa-register/react': '/src/pwa/register-stub.js',
          }
        : {},
    },

    plugins: [
      react(),
      !fuerElectron &&
        VitePWA({
          registerType: 'prompt',
          includeAssets: ['apple-touch-icon.png'],
          manifest: {
            name: 'Modellsammlung – Interaktive 3D-Modelle',
            short_name: 'Modellsammlung',
            description:
              'Interaktive 3D-Modelle auf Universitätsniveau für Physik, Chemie, Biologie und Medizin.',
            lang: 'de',
            theme_color: '#0d1120',
            background_color: '#070912',
            display: 'standalone',
            orientation: 'any',
            start_url: '/',
            scope: '/',
            categories: ['education', 'science'],
            icons: [
              { src: 'icon-192.png', sizes: '192x192', type: 'image/png' },
              { src: 'icon-512.png', sizes: '512x512', type: 'image/png' },
              {
                src: 'icon-maskable-512.png',
                sizes: '512x512',
                type: 'image/png',
                purpose: 'maskable',
              },
            ],
          },
          workbox: {
            // Alles vorab in den Cache legen – die App läuft dann vollständig
            // offline. Der Three.js-Chunk ist rund 490 kB, deshalb das erhöhte
            // Limit (Standard wären 2 MB, hier großzügig für künftige Modelle).
            globPatterns: ['**/*.{js,css,html,png,svg,woff2}'],
            maximumFileSizeToCacheInBytes: 6 * 1024 * 1024,
            cleanupOutdatedCaches: true,
            navigateFallback: 'index.html',
          },
          devOptions: {
            // Im Entwicklungsmodus aus – sonst cached der Service Worker
            // Änderungen weg und man debuggt alte Stände.
            enabled: false,
          },
        }),
    ].filter(Boolean),

    server: {
      port: 5173,
      open: true,
    },

    preview: {
      port: 4173,
      // Nicht automatisch öffnen – sonst schlägt `vite preview` in Umgebungen
      // ohne Desktop (CI, Container) mit "spawn xdg-open ENOENT" fehl.
      open: false,
    },

    build: {
      outDir: fuerElectron ? 'dist-electron-web' : 'dist',
      chunkSizeWarningLimit: 900,
      rollupOptions: {
        output: {
          // Three.js in einen eigenen Chunk, damit der App-Code getrennt
          // cachebar bleibt und ein Update nicht die ganze Bibliothek erneuert.
          manualChunks: {
            three: ['three'],
          },
        },
      },
    },
  }
})
