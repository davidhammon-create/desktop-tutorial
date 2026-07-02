import { Router } from "express";
import { hasApiKey, setApiKey } from "../lib/config.js";

const router = Router();

router.get("/", (req, res) => {
  res.json({ hasApiKey: hasApiKey() });
});

router.put("/", (req, res) => {
  setApiKey((req.body.apiKey || "").trim());
  res.json({ hasApiKey: hasApiKey() });
});

export default router;
