import { Router } from "express";
import { store } from "../lib/store.js";

const router = Router();

router.get("/", (req, res) => {
  res.json(store.read().user || { name: "", emails: [""] });
});

router.put("/", (req, res) => {
  const db = store.read();
  db.user = { name: req.body.name || "", emails: req.body.emails?.length ? req.body.emails : [""] };
  store.write(db);
  res.json(db.user);
});

export default router;
