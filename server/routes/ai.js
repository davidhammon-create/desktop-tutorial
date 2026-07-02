import { Router } from "express";
import multer from "multer";
import pdfParse from "pdf-parse/lib/pdf-parse.js";
import { analyzeStatement, companyReport, cancellationLetter, AnthropicNotConfigured } from "../lib/anthropic.js";
import { store } from "../lib/store.js";

const router = Router();
const upload = multer({ limits: { fileSize: 15 * 1024 * 1024 } });

function handleAiError(res, err) {
  if (err instanceof AnthropicNotConfigured) {
    return res.status(503).json({ error: err.message });
  }
  console.error(err);
  return res.status(502).json({ error: "KI-Anfrage fehlgeschlagen. Bitte erneut versuchen." });
}

async function extractText(file) {
  if (!file) return "";
  if (file.mimetype === "application/pdf") {
    const parsed = await pdfParse(file.buffer);
    return parsed.text;
  }
  return file.buffer.toString("utf8");
}

router.post("/analyze-statement", upload.single("file"), async (req, res) => {
  try {
    const fileText = await extractText(req.file);
    const text = [req.body.text, fileText].filter(Boolean).join("\n");
    if (!text.trim()) return res.status(400).json({ error: "Kein Text oder Datei übergeben." });
    const raw = await analyzeStatement(text);
    const clean = raw.replace(/```json|```/g, "").trim();
    let parsed;
    try {
      parsed = JSON.parse(clean);
    } catch {
      return res.status(502).json({ error: "KI-Antwort konnte nicht gelesen werden." });
    }
    res.json(parsed);
  } catch (err) {
    handleAiError(res, err);
  }
});

router.post("/company-report", async (req, res) => {
  try {
    const { subscriptionId } = req.body;
    const subs = store.collection("subscriptions");
    const sub = subs.find((s) => s.id === subscriptionId);
    if (!sub) return res.status(404).json({ error: "Abo nicht gefunden." });
    const report = await companyReport({
      name: sub.name,
      ibanCountry: sub.iban ? sub.iban.slice(0, 2) : null,
      amount: sub.amount,
    });
    res.json({ report });
  } catch (err) {
    handleAiError(res, err);
  }
});

router.post("/cancellation-letter", async (req, res) => {
  try {
    const { subscriptionId } = req.body;
    const subs = store.collection("subscriptions");
    const sub = subs.find((s) => s.id === subscriptionId);
    if (!sub) return res.status(404).json({ error: "Abo nicht gefunden." });
    const raw = await cancellationLetter({ name: sub.name, since: sub.since, note: sub.note });
    const clean = raw.replace(/```json|```/g, "").trim();
    let parsed;
    try {
      parsed = JSON.parse(clean);
    } catch {
      return res.status(502).json({ error: "KI-Antwort konnte nicht gelesen werden." });
    }
    res.json(parsed);
  } catch (err) {
    handleAiError(res, err);
  }
});

export default router;
