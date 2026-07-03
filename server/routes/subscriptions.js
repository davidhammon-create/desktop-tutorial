import { Router } from "express";
import fs from "node:fs";
import path from "node:path";
import { store } from "../lib/store.js";
import { encrypt, decrypt } from "../lib/crypto.js";
import { requireUser } from "../lib/currentUser.js";
import { BUNDLED_DATA_DIR } from "../lib/paths.js";

// Kündigungsbutton-Gesetz: direct links to each provider's cancellation page,
// matched against the subscription name/subject by keyword.
const cancelLinks = JSON.parse(fs.readFileSync(path.join(BUNDLED_DATA_DIR, "cancel-links.json"), "utf8"));

function findCancelLink(sub) {
  const hay = `${sub.name || ""} ${sub.note || ""}`.toLowerCase();
  const hit = cancelLinks.find((c) => c.match.some((m) => hay.includes(m)));
  return hit ? { label: hit.label, url: hit.url } : null;
}

const router = Router();
router.use(requireUser);

function toPublic(sub) {
  const { passwordEnc, ...rest } = sub;
  return { ...rest, hasPassword: Boolean(passwordEnc), cancelLink: findCancelLink(sub) };
}

router.get("/", (req, res) => {
  res.json(store.collection("subscriptions").filter((s) => s.userId === req.user.id).map(toPublic));
});

router.post("/", (req, res) => {
  const subs = store.collection("subscriptions");
  const maxId = Math.max(0, ...subs.map((s) => s.id));
  const body = req.body || {};
  const sub = {
    id: maxId + 1,
    userId: req.user.id,
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
    paused: Boolean(body.paused),
    paymentDay: body.paymentDay ? Number(body.paymentDay) : null,
    priceHistory: body.priceHistory || [{ date: body.since || new Date().toISOString().slice(0, 7), amount: Number(body.amount) || 0 }],
  };
  subs.push(sub);
  store.setCollection("subscriptions", subs);
  res.status(201).json(toPublic(sub));
});

router.patch("/:id", (req, res) => {
  const id = Number(req.params.id);
  const subs = store.collection("subscriptions");
  const idx = subs.findIndex((s) => s.id === id && s.userId === req.user.id);
  if (idx === -1) return res.status(404).json({ error: "Abo nicht gefunden." });

  const body = req.body || {};
  const current = subs[idx];
  const updated = { ...current };

  for (const field of ["name", "domain", "cycle", "since", "category", "status", "color", "iban", "email", "username", "phone", "note", "lastCharge"]) {
    if (body[field] !== undefined) updated[field] = body[field];
  }
  if (body.paused !== undefined) updated.paused = Boolean(body.paused);
  if (body.paymentDay !== undefined) updated.paymentDay = body.paymentDay === null ? null : Math.min(28, Math.max(1, Number(body.paymentDay) || 1));
  // 3-point conversion checklist (Abo gekündigt / Sparplan angelegt / Betrag
  // bestätigt) plus the chosen ETF/broker — the app remembers the progress.
  if (body.conversion !== undefined) {
    const c = body.conversion || {};
    updated.conversion = {
      cancelled: Boolean(c.cancelled),
      planCreated: Boolean(c.planCreated),
      confirmed: Boolean(c.confirmed),
      etfIsin: c.etfIsin ?? current.conversion?.etfIsin ?? null,
      etfName: c.etfName ?? current.conversion?.etfName ?? null,
      brokerId: c.brokerId ?? current.conversion?.brokerId ?? null,
    };
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
  const next = subs.filter((s) => !(s.id === id && s.userId === req.user.id));
  store.setCollection("subscriptions", next);
  res.status(204).end();
});

// Reveals the decrypted password for one subscription — a separate opt-in call so list responses never carry secrets.
router.get("/:id/password", (req, res) => {
  const id = Number(req.params.id);
  const sub = store.collection("subscriptions").find((s) => s.id === id && s.userId === req.user.id);
  if (!sub) return res.status(404).json({ error: "Abo nicht gefunden." });
  res.json({ password: sub.passwordEnc ? decrypt(sub.passwordEnc) : "" });
});

export default router;
