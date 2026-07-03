import { Router } from "express";
import multer from "multer";
import fs from "node:fs";
import path from "node:path";
import pdfParse from "pdf-parse/lib/pdf-parse.js";
import { analyzeStatement, companyReport, cancellationLetter, autoClassify, investAnalysis, financeRadar, AnthropicNotConfigured } from "../lib/anthropic.js";
import { classifyAll } from "../lib/classify.js";
import { store } from "../lib/store.js";
import { hasApiKey } from "../lib/config.js";
import { BUNDLED_DATA_DIR } from "../lib/paths.js";

const investUniverse = [
  ...JSON.parse(fs.readFileSync(path.join(BUNDLED_DATA_DIR, "etfs.json"), "utf8")).map((e) => ({ ...e, class: "etf" })),
  ...JSON.parse(fs.readFileSync(path.join(BUNDLED_DATA_DIR, "invest.json"), "utf8")),
];

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

// Classifies every subscription at once. Uses Claude when a key is configured;
// otherwise falls back to the built-in rule engine so the feature works out of the box.
router.post("/auto-classify", async (req, res) => {
  const subs = store.collection("subscriptions");
  if (subs.length === 0) return res.json({ results: [], summary: "Keine Abos vorhanden.", engine: "none" });

  let results;
  let summary;
  let engine;

  if (hasApiKey()) {
    try {
      const raw = await autoClassify(subs);
      const parsed = JSON.parse(raw.replace(/```json|```/g, "").trim());
      results = parsed.results;
      summary = parsed.summary;
      engine = "ki";
    } catch (err) {
      console.error("KI-Klassifizierung fehlgeschlagen, nutze Basis-Check:", err.message);
    }
  }

  if (!results) {
    results = classifyAll(subs);
    const warn = results.filter((r) => r.status === "warning").length;
    summary = `Basis-Check (ohne KI) abgeschlossen: ${results.length} Zahlungen geprüft, ${warn} Warnung${warn !== 1 ? "en" : ""}. Mit hinterlegtem KI-Zugang (Konto → KI-Zugang) wird die Analyse deutlich genauer.`;
    engine = "basis";
  }

  const byId = new Map(results.map((r) => [r.id, r]));
  const updated = subs.map((s) => {
    const r = byId.get(s.id);
    return r ? { ...s, status: r.status, note: r.reason || s.note } : s;
  });
  store.setCollection("subscriptions", updated);

  res.json({ results, summary, engine });
});

// Rule-based fallback when no AI key is configured: filters the universe by the
// requested risk band and diversifies across asset classes, best return first.
function fallbackInvestPicks({ years, risk }) {
  const band = risk === "sicher" ? [1, 2] : risk === "wachstum" ? [4, 6] : [2, 4];
  const candidates = investUniverse
    .filter((a) => a.riskScore >= band[0] && a.riskScore <= band[1])
    .sort((a, b) => b.ret - a.ret);
  const picks = [];
  const usedClasses = new Set();
  for (const a of candidates) {
    if (picks.length >= 4) break;
    if (usedClasses.has(a.class) && picks.length < 3) continue;
    usedClasses.add(a.class);
    picks.push({
      id: a.id,
      warum: `${a.desc} Historische Rendite ${a.ret}% p.a. bei Risiko "${a.risk}" — passt zum Profil "${risk}" über ${years} Jahre.`,
      signal: a.riskScore <= 2 ? "defensiv" : a.riskScore >= 5 ? "beobachten" : "kauf-signal",
    });
  }
  return {
    picks,
    marktlage: `Basis-Auswahl (ohne KI) nach historischer Rendite und Risikoprofil "${risk}". Mit hinterlegtem KI-Zugang (Konto → KI-Zugang) analysiert die KI zusätzlich aktuelle Nachrichten, Zinsentscheidungen und Kausalketten weltweit.`,
    risikohinweis: "Historische Renditen sind keine Garantie für die Zukunft; Verluste sind möglich.",
    engine: "basis",
  };
}

// AI investment picks across all asset classes — the "alternative to your cancelled subscription".
router.post("/invest-picks", async (req, res) => {
  const monthly = Number(req.body?.monthly) || 50;
  const years = Number(req.body?.years) || 15;
  const risk = ["sicher", "ausgewogen", "wachstum"].includes(req.body?.risk) ? req.body.risk : "ausgewogen";

  if (hasApiKey()) {
    try {
      const raw = await investAnalysis({ monthly, years, risk, universe: investUniverse });
      const parsed = JSON.parse(raw.replace(/```json|```/g, "").trim());
      const known = new Set(investUniverse.map((a) => a.id));
      parsed.picks = (parsed.picks || []).filter((p) => known.has(p.id));
      if (parsed.picks.length > 0) return res.json({ ...parsed, engine: "ki" });
    } catch (err) {
      console.error("KI-Invest-Analyse fehlgeschlagen, nutze Basis-Auswahl:", err.message);
    }
  }
  res.json(fallbackInvestPicks({ years, risk }));
});

// Live AI research per Finanz-Radar topic. No fallback content here — the
// curated tips from /api/tips are already the offline baseline.
router.post("/finance-radar", async (req, res) => {
  try {
    const { topicId, topicTitle } = req.body || {};
    const raw = await financeRadar({ topicId, topicTitle });
    const parsed = JSON.parse(raw.replace(/```json|```/g, "").trim());
    res.json(parsed);
  } catch (err) {
    if (err instanceof SyntaxError) {
      return res.status(502).json({ error: "KI-Antwort konnte nicht gelesen werden." });
    }
    handleAiError(res, err);
  }
});

export default router;
