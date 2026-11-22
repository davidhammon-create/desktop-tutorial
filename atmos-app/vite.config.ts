import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";
// https://vitejs.dev/config/
const electronBuild = process.env.ELECTRON === "true";
export default defineConfig(({ mode }) => ({
  // Relative asset paths required for Electron file:// / asar loads.
  base: electronBuild ? "./" : "/",
  // ATMOS_* for Google keys (also saved via Einstellungen ? localStorage)
  envPrefix: ["VITE_", "ATMOS_"],
  server: {
    host: "::",
    port: 8080,
    strictPort: true,
    hmr: {
      overlay: false,
    },
  },
  plugins: [react(), mode === "development" && componentTagger()].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
}));
