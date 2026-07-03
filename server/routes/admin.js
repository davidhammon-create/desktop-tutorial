import { Router } from "express";
import fs from "node:fs";
import path from "node:path";
import { store } from "../lib/store.js";
import { requireAdmin } from "../lib/currentUser.js";
import { listApis, setNamedApi, API_SLOTS } from "../lib/config.js";
import { DATA_DIR, BUNDLED_DATA_DIR } from "../lib/paths.js";
import { getLanIp } from "./../lib/network.js";

const router = Router();
router.use(requireAdmin);

// One call for the whole admin dashboard: users incl. usage counts,
// configured APIs (masked), and system info.
router.get("/overview", (req, res) => {
  const users = store.collection("users");
  const accounts = store.collection("accounts");
  const txs = store.collection("transactions");
  const subs = store.collection("subscriptions");

  res.json({
    users: users.map((u) => ({
      id: u.id,
      name: u.name,
      role: u.role,
      createdAt: u.createdAt,
      aiEnabled: Boolean(u.settings?.aiEnabled),
      accounts: accounts.filter((a) => a.userId === u.id).length,
      transactions: txs.filter((t) => t.userId === u.id).length,
      subscriptions: subs.filter((s) => s.userId === u.id).length,
    })),
    apis: listApis(),
    stats: { users: users.length, accounts: accounts.length, transactions: txs.length, subscriptions: subs.length },
    system: {
      dataDir: DATA_DIR,
      port: Number(process.env.PORT || 8787),
      host: process.env.HOST || "0.0.0.0",
      lanIp: getLanIp(),
      node: process.version,
    },
  });
});

router.patch("/users/:id", (req, res) => {
  const users = store.collection("users");
  const idx = users.findIndex((u) => u.id === Number(req.params.id));
  if (idx === -1) return res.status(404).json({ error: "Nutzer nicht gefunden." });
  if (req.body.name !== undefined) users[idx].name = String(req.body.name);
  if (req.body.role !== undefined) {
    // Never demote the last remaining admin — the admin area would lock out.
    const admins = users.filter((u) => u.role === "admin");
    if (users[idx].role === "admin" && req.body.role !== "admin" && admins.length === 1) {
      return res.status(400).json({ error: "Der letzte Admin kann nicht herabgestuft werden." });
    }
    users[idx].role = req.body.role === "admin" ? "admin" : "user";
  }
  if (req.body.aiEnabled !== undefined) {
    users[idx].settings = { ...users[idx].settings, aiEnabled: Boolean(req.body.aiEnabled) };
  }
  store.setCollection("users", users);
  res.json(users[idx]);
});

// Removes the user and everything that belongs to them.
router.delete("/users/:id", (req, res) => {
  const id = Number(req.params.id);
  if (id === req.user.id) return res.status(400).json({ error: "Du kannst dein eigenes Konto nicht löschen, während du es benutzt." });
  const users = store.collection("users");
  if (!users.some((u) => u.id === id)) return res.status(404).json({ error: "Nutzer nicht gefunden." });
  store.setCollection("users", users.filter((u) => u.id !== id));
  store.setCollection("accounts", store.collection("accounts").filter((a) => a.userId !== id));
  store.setCollection("transactions", store.collection("transactions").filter((t) => t.userId !== id));
  store.setCollection("subscriptions", store.collection("subscriptions").filter((s) => s.userId !== id));
  res.status(204).end();
});

router.put("/apis/:name", (req, res) => {
  if (!API_SLOTS.some((s) => s.name === req.params.name)) return res.status(404).json({ error: "Unbekannter API-Slot." });
  const key = String(req.body?.key || "").trim();
  if (!key) return res.status(400).json({ error: "Kein Schlüssel übergeben." });
  setNamedApi(req.params.name, key);
  res.json({ ok: true, apis: listApis() });
});

router.delete("/apis/:name", (req, res) => {
  if (!API_SLOTS.some((s) => s.name === req.params.name)) return res.status(404).json({ error: "Unbekannter API-Slot." });
  setNamedApi(req.params.name, "");
  res.json({ ok: true, apis: listApis() });
});

// Resets the database back to the shipped demo dataset.
router.post("/reset", (req, res) => {
  const seedFile = path.join(BUNDLED_DATA_DIR, "db.seed.json");
  const dbFile = path.join(DATA_DIR, "db.json");
  fs.copyFileSync(seedFile, dbFile);
  res.json({ ok: true });
});

export default router;
