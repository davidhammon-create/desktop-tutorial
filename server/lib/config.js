import fs from "node:fs";
import path from "node:path";
import { DATA_DIR } from "./paths.js";

const CONFIG_FILE = path.join(DATA_DIR, "config.json");

function readConfig() {
  if (!fs.existsSync(CONFIG_FILE)) return {};
  try {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8"));
  } catch {
    return {};
  }
}

function writeConfig(cfg) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2), "utf8");
}

// The API key is entered once in the app's Settings and saved on-device —
// no .env file needed for the desktop app. ANTHROPIC_API_KEY in the
// environment still works as a fallback (useful for local `npm run dev`).
export function getApiKey() {
  return readConfig().anthropicApiKey || process.env.ANTHROPIC_API_KEY || "";
}

export function setApiKey(key) {
  const cfg = readConfig();
  if (key) cfg.anthropicApiKey = key;
  else delete cfg.anthropicApiKey;
  writeConfig(cfg);
}

export function hasApiKey() {
  return Boolean(getApiKey());
}
