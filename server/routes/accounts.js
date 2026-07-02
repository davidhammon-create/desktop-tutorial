import { Router } from "express";
import { store } from "../lib/store.js";

const router = Router();

// Real bank/PayPal OAuth needs a registered aggregator (e.g. PayPal Developer app,
// or a PSD2 aggregator like Tink/GoCardless/FinAPI for bank accounts) with credentials
// in env vars. Without those, "connect" is a demo toggle — the actual data path is
// document upload/paste, handled by /api/ai/analyze-statement.
router.get("/", (req, res) => {
  res.json(store.collection("accounts"));
});

router.post("/:id/connect", (req, res) => {
  const accounts = store.collection("accounts");
  const idx = accounts.findIndex((a) => a.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Konto nicht gefunden." });
  accounts[idx] = { ...accounts[idx], status: "demo-connected", connectedAt: new Date().toISOString() };
  store.setCollection("accounts", accounts);
  res.json(accounts[idx]);
});

router.post("/:id/disconnect", (req, res) => {
  const accounts = store.collection("accounts");
  const idx = accounts.findIndex((a) => a.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Konto nicht gefunden." });
  accounts[idx] = { ...accounts[idx], status: "disconnected", connectedAt: null };
  store.setCollection("accounts", accounts);
  res.json(accounts[idx]);
});

export default router;
