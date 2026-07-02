import fs from "node:fs";
import path from "node:path";
import { DATA_DIR, BUNDLED_DATA_DIR } from "./paths.js";

// db.json is user data — lives in DATA_DIR (the OS app-data folder when
// running as the desktop app). db.seed.json is the shipped starter
// dataset and always stays with the app's own files.
const DB_FILE = path.join(DATA_DIR, "db.json");
const SEED_FILE = path.join(BUNDLED_DATA_DIR, "db.seed.json");

function load() {
  if (!fs.existsSync(DB_FILE)) {
    const seed = fs.existsSync(SEED_FILE) ? fs.readFileSync(SEED_FILE, "utf8") : "{}";
    fs.mkdirSync(path.dirname(DB_FILE), { recursive: true });
    fs.writeFileSync(DB_FILE, seed, "utf8");
  }
  return JSON.parse(fs.readFileSync(DB_FILE, "utf8"));
}

function save(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), "utf8");
}

// Minimal file-backed JSON store. Fine for a single-user demo app;
// swap for a real database before handling concurrent users.
export const store = {
  read() {
    return load();
  },
  write(db) {
    save(db);
  },
  collection(name) {
    const db = load();
    if (!db[name]) db[name] = [];
    return db[name];
  },
  setCollection(name, items) {
    const db = load();
    db[name] = items;
    save(db);
  },
};
