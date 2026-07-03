import { Router } from "express";
import { store } from "../lib/store.js";

const router = Router();

// Public profile list for the profile picker (no settings/emails leaked).
router.get("/", (req, res) => {
  res.json(store.collection("users").map((u) => ({ id: u.id, name: u.name, role: u.role })));
});

router.post("/", (req, res) => {
  const users = store.collection("users");
  const name = (req.body?.name || "").trim();
  if (!name) return res.status(400).json({ error: "Name fehlt." });
  const user = {
    id: Math.max(0, ...users.map((u) => u.id)) + 1,
    name,
    role: "user",
    createdAt: new Date().toISOString().slice(0, 10),
    emails: [""],
    settings: { aiEnabled: false },
  };
  users.push(user);
  store.setCollection("users", users);
  res.status(201).json({ id: user.id, name: user.name, role: user.role });
});

export default router;
