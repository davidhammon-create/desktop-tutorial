import "dotenv/config";
import express from "express";
import cors from "cors";
import aiRouter from "./routes/ai.js";
import subscriptionsRouter from "./routes/subscriptions.js";
import accountsRouter from "./routes/accounts.js";
import etfsRouter from "./routes/etfs.js";
import userRouter from "./routes/user.js";

const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" }));

app.use("/api/ai", aiRouter);
app.use("/api/subscriptions", subscriptionsRouter);
app.use("/api/accounts", accountsRouter);
app.use("/api/etfs", etfsRouter);
app.use("/api/user", userRouter);

app.get("/api/health", (req, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 8787;
app.listen(PORT, () => console.log(`AboWandler API läuft auf Port ${PORT}`));
