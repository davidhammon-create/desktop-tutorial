import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
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
    chunkSizeWarningLimit: 900,
    rollupOptions: {
      output: {
        // Three.js in einen eigenen Chunk, damit der App-Code getrennt cachebar bleibt.
        manualChunks: {
          three: ['three'],
        },
      },
    },
  },
})
