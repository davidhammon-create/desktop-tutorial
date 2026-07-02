import { Router } from "express";
import { store } from "../lib/store.js";
import { encrypt, decrypt } from "../lib/crypto.js";

const router = Router();

function toPublic(sub) {
  const { passwordEnc, ...rest } = sub;
  return { ...rest, hasPassword: Boolean(passwordEnc) };
}

router.get("/", (req, res) => {
  res.json(store.collection("subscriptions").map(toPublic));
});

router.post("/", (req, res) => {
  const subs = store.collection("subscriptions");
  const maxId = Math.max(0, ...subs.map((s) => s.id));
  const body = req.body || {};
  const sub = {
    id: maxId + 1,
    name: body.name || "Unbenannt",
    domain: body.domain || null,
    amount: Number(body.amount) || 0,
    cycle: body.cycle || "monatlich",
    since: body.since || new Date().toISOString().slice(0, 7),
    category: body.category || "Importiert",
    status: body.status || "pending",
    color: body.color || "#64D2FF",
    letter: (body.name || "?")[0].toUpperCase(),
    iban: body.iban || "",
    email: body.email || "",
    username: body.username || "",
    passwordEnc: body.password ? encrypt(body.password) : null,
    phone: body.phone || "",
    lastCharge: body.lastCharge || null,
    note: body.note || "",
    priceHistory: body.priceHistory || [{ date: body.since || new Date().toISOString().slice(0, 7), amount: Number(body.amount) || 0 }],
  };
  subs.push(sub);
  store.setCollection("subscriptions", subs);
  res.status(201).json(toPublic(sub));
});

router.patch("/:id", (req, res) => {
  const id = Number(req.params.id);
  const subs = store.collection("subscriptions");
  const idx = subs.findIndex((s) => s.id === id);
  if (idx === -1) return res.status(404).json({ error: "Abo nicht gefunden." });

  const body = req.body || {};
  const current = subs[idx];
  const updated = { ...current };

  for (const field of ["name", "domain", "cycle", "since", "category", "status", "color", "iban", "email", "username", "phone", "note", "lastCharge"]) {
    if (body[field] !== undefined) updated[field] = body[field];
  }
  if (body.amount !== undefined) {
    const newAmount = Number(body.amount);
    if (newAmount !== current.amount) {
      updated.priceHistory = [...(current.priceHistory || []), { date: new Date().toISOString().slice(0, 7), amount: newAmount }];
    }
    updated.amount = newAmount;
  }
  if (body.password !== undefined) {
    updated.passwordEnc = body.password ? encrypt(body.password) : null;
  }

  subs[idx] = updated;
  store.setCollection("subscriptions", subs);
  res.json(toPublic(updated));
});

router.delete("/:id", (req, res) => {
  const id = Number(req.params.id);
  const subs = store.collection("subscriptions");
  const next = subs.filter((s) => s.id !== id);
  store.setCollection("subscriptions", next);
  res.status(204).end();
});

// Reveals the decrypted password for one subscription — a separate opt-in call so list responses never carry secrets.
router.get("/:id/password", (req, res) => {
  const id = Number(req.params.id);
  const sub = store.collection("subscriptions").find((s) => s.id === id);
  if (!sub) return res.status(404).json({ error: "Abo nicht gefunden." });
  res.json({ password: sub.passwordEnc ? decrypt(sub.passwordEnc) : "" });
});

export default router;
