import { Router } from "express";
import fs from "node:fs";
import path from "node:path";
import { BUNDLED_DATA_DIR } from "../lib/paths.js";

const brokers = JSON.parse(fs.readFileSync(path.join(BUNDLED_DATA_DIR, "brokers.json"), "utf8"));

const router = Router();

// Broker catalog for the guided savings-plan flow. etfUrl per ISIN when the
// broker has a stable deeplink pattern; justETF works as neutral fallback.
router.get("/", (req, res) => {
  res.json(brokers);
});

export default router;
