import { Router } from "express";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const etfs = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "data", "etfs.json"), "utf8"));

const router = Router();

router.get("/", (req, res) => {
  const { q } = req.query;
  if (!q) return res.json(etfs);
  const needle = String(q).toLowerCase();
  res.json(etfs.filter((e) => e.name.toLowerCase().includes(needle) || e.category.toLowerCase().includes(needle) || e.tags.some((t) => t.toLowerCase().includes(needle))));
});

export default router;
