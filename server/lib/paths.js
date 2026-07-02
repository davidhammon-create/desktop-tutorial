import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Mutable app data (db.json, encryption key, API key config) lives here.
// Defaults to server/data for plain `node index.js` dev use; the Electron
// shell overrides this to point at the OS's per-user app-data folder, so
// nothing is ever written next to the app's own program files.
export const DATA_DIR = process.env.ABOWANDLER_DATA_DIR || path.join(__dirname, "..", "data");

// Read-only files shipped with the app (seed data, ETF reference data)
// always live next to the source, regardless of DATA_DIR.
export const BUNDLED_DATA_DIR = path.join(__dirname, "..", "data");
