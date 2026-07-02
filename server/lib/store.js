import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_FILE = path.join(__dirname, "..", "data", "db.json");
const SEED_FILE = path.join(__dirname, "..", "data", "db.seed.json");

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
