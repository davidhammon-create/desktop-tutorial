import "dotenv/config";
import path from "node:path";
import express from "express";
import cors from "cors";
import aiRouter from "./routes/ai.js";
import subscriptionsRouter from "./routes/subscriptions.js";
import accountsRouter from "./routes/accounts.js";
import etfsRouter from "./routes/etfs.js";
import userRouter from "./routes/user.js";
import configRouter from "./routes/config.js";

const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" }));

app.use("/api/ai", aiRouter);
app.use("/api/subscriptions", subscriptionsRouter);
app.use("/api/accounts", accountsRouter);
app.use("/api/etfs", etfsRouter);
app.use("/api/user", userRouter);
app.use("/api/config", configRouter);

app.get("/api/health", (req, res) => res.json({ ok: true }));

// When ABOWANDLER_STATIC_DIR is set (packaged desktop app), the built
// frontend is served from the same process/port — no separate Vite dev
// server needed, and everything runs on one local origin.
if (process.env.ABOWANDLER_STATIC_DIR) {
  const staticDir = process.env.ABOWANDLER_STATIC_DIR;
  app.use(express.static(staticDir));
  app.get(/^\/(?!api).*/, (req, res) => {
    res.sendFile(path.join(staticDir, "index.html"));
  });
}

const PORT = process.env.PORT || 8787;
const HOST = process.env.HOST || "127.0.0.1";
app.listen(PORT, HOST, () => console.log(`AboWandler API läuft auf ${HOST}:${PORT}`));
