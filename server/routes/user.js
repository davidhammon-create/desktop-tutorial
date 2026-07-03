import { Router } from "express";
import { store } from "../lib/store.js";
import { requireUser } from "../lib/currentUser.js";

const router = Router();
router.use(requireUser);

// Profile of the currently selected user (x-user-id header).
router.get("/", (req, res) => {
  const { id, name, role, emails, settings, createdAt } = req.user;
  res.json({ id, name, role, emails: emails?.length ? emails : [""], settings: settings || { aiEnabled: false }, createdAt });
});

router.put("/", (req, res) => {
  const users = store.collection("users");
  const idx = users.findIndex((u) => u.id === req.user.id);
  users[idx] = {
    ...users[idx],
    name: req.body.name ?? users[idx].name,
    emails: req.body.emails?.length ? req.body.emails : users[idx].emails,
  };
  store.setCollection("users", users);
  const { id, name, role, emails, settings } = users[idx];
  res.json({ id, name, role, emails, settings });
});

// Per-user feature switches, e.g. { aiEnabled: true } — KI stays off until
// the user explicitly enables it here.
router.patch("/settings", (req, res) => {
  const users = store.collection("users");
  const idx = users.findIndex((u) => u.id === req.user.id);
  users[idx].settings = { ...users[idx].settings, ...req.body };
  store.setCollection("users", users);
  res.json(users[idx].settings);
});

export default router;
