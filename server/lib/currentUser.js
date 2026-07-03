import { store } from "./store.js";

// Local-first "session": the client sends its selected profile via x-user-id.
// This is a convenience for a device-local multi-profile app, not real auth —
// anyone with access to the machine/LAN can switch profiles.
export function currentUser(req) {
  const id = Number(req.headers["x-user-id"] || 1);
  return store.collection("users").find((u) => u.id === id) || null;
}

export function requireUser(req, res, next) {
  const user = currentUser(req);
  if (!user) return res.status(401).json({ error: "Kein gültiges Nutzerprofil gewählt." });
  req.user = user;
  next();
}

export function requireAdmin(req, res, next) {
  const user = currentUser(req);
  if (!user) return res.status(401).json({ error: "Kein gültiges Nutzerprofil gewählt." });
  if (user.role !== "admin") return res.status(403).json({ error: "Nur für Admin-Konten." });
  req.user = user;
  next();
}
