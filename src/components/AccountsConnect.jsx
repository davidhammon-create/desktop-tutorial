import React, { useState, useRef } from "react";
import { T, S } from "../shared/tokens";
import { fmt } from "../shared/format";
import { api } from "../shared/api";

const providerIcon = { bank: "🏦", paypal: "🅿", card: "💳", klarna: "🛍" };

export default function AccountsConnect({ accounts, setAccounts, onImported }) {
  const [connecting, setConnecting] = useState(null);
  const [aiInput, setAiInput] = useState("");
  const [file, setFile] = useState(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiResult, setAiResult] = useState(null);
  const fileRef = useRef(null);

  const toggleConnect = async (acc) => {
    setConnecting(acc.id);
    try {
      const updated = acc.status === "disconnected" ? await api.accounts.connect(acc.id) : await api.accounts.disconnect(acc.id);
      setAccounts(accounts.map((a) => (a.id === acc.id ? updated : a)));
    } finally {
      setConnecting(null);
    }
  };

  const analyze = async () => {
    if (!aiInput.trim() && !file) return;
    setAiLoading(true);
    setAiResult(null);
    try {
      const result = await api.ai.analyzeStatement(aiInput, file);
      setAiResult(result);
    } catch (e) {
      setAiResult({ error: e.message });
    }
    setAiLoading(false);
  };

  const importAll = async () => {
    if (!aiResult?.subs) return;
    for (const s of aiResult.subs) {
      await api.subscriptions.create({
        name: s.name,
        amount: s.amount,
        status: s.suspicious ? "warning" : "pending",
        category: "Importiert",
        note: s.reason || "",
      });
    }
    onImported();
    setAiResult(null);
    setAiInput("");
    setFile(null);
  };

  return (
    <div>
      <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 6px" }}>Konten & Import</h1>
      <p style={{ color: T.textDim, margin: "0 0 24px", maxWidth: 680 }}>
        Verbinde deine Konten oder importiere Kontoauszüge direkt — die KI erkennt wiederkehrende Zahlungen und markiert verdächtige Abbuchungen automatisch.
      </p>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 16, marginBottom: 32 }}>
        {accounts.map((acc) => (
          <div key={acc.id} style={S.card}>
            <div style={{ fontSize: 28, marginBottom: 10 }}>{providerIcon[acc.provider] || "🔗"}</div>
            <div style={{ fontWeight: 650, marginBottom: 4 }}>{acc.label}</div>
            <div style={{ fontSize: 13, color: acc.status === "demo-connected" ? T.green : T.textFaint, marginBottom: 12 }}>
              {acc.status === "demo-connected" ? "✓ Verbunden (Demo)" : "Nicht verbunden"}
            </div>
            <button
              style={{ ...S.btnGhost, padding: "8px 16px", fontSize: 13, width: "100%", boxSizing: "border-box", borderColor: acc.status === "demo-connected" ? T.red + "55" : T.border, color: acc.status === "demo-connected" ? T.red : T.text }}
              onClick={() => toggleConnect(acc)}
              disabled={connecting === acc.id}
            >
              {connecting === acc.id ? "…" : acc.status === "demo-connected" ? "Trennen" : "Verbinden"}
            </button>
          </div>
        ))}
      </div>

      <div style={{ ...S.card, marginBottom: 24, background: "rgba(255,159,10,0.06)", borderColor: "rgba(255,159,10,0.25)" }}>
        <p style={{ fontSize: 12.5, color: T.textDim, margin: 0, lineHeight: 1.6 }}>
          ℹ Echte Bank-/PayPal-Anbindung (PSD2/OAuth) erfordert registrierte API-Zugänge bei einem Kontoaggregator (z. B. Tink, GoCardless, FinAPI) bzw. bei PayPal Developer. „Verbinden" simuliert diesen Schritt im Demo-Modus — für echte Daten nutze den Import unten: Kontoauszug einfügen oder als PDF/CSV hochladen.
        </p>
      </div>

      <div style={S.card}>
        <div style={{ fontWeight: 650, marginBottom: 14 }}>✦ Kontoauszug importieren</div>
        <textarea
          style={{ ...S.input, minHeight: 160, fontFamily: "SF Mono, Menlo, monospace", fontSize: 13, resize: "vertical" }}
          placeholder={"Text einfügen, z.B.:\n28.06.2026  NETFLIX INTERNATIONAL B.V.   -17,99 EUR\n25.06.2026  SPOTIFY AB                    -10,99 EUR\n…"}
          value={aiInput}
          onChange={(e) => setAiInput(e.target.value)}
        />
        <div style={{ display: "flex", gap: 12, marginTop: 14, alignItems: "center", flexWrap: "wrap" }}>
          <button style={{ ...S.btnGhost, padding: "10px 18px", fontSize: 13.5 }} onClick={() => fileRef.current?.click()}>
            📎 {file ? file.name : "PDF / CSV hochladen"}
          </button>
          <input ref={fileRef} type="file" accept=".pdf,.csv,.txt" style={{ display: "none" }} onChange={(e) => setFile(e.target.files?.[0] || null)} />
          {file && <button style={{ ...S.btnGhost, padding: "6px 12px", fontSize: 12 }} onClick={() => setFile(null)}>✕ Entfernen</button>}
        </div>
        <div style={{ display: "flex", gap: 12, marginTop: 16, alignItems: "center", flexWrap: "wrap" }}>
          <button style={{ ...S.btn, opacity: aiLoading ? 0.6 : 1 }} disabled={aiLoading} onClick={analyze}>
            {aiLoading ? "⏳ KI analysiert…" : "✦ Jetzt analysieren"}
          </button>
          <span style={{ fontSize: 12.5, color: T.textFaint }}>KI-Kosten: ~0,02 € pro Analyse (transparent abgerechnet)</span>
        </div>
      </div>

      {aiResult && !aiResult.error && (
        <div style={{ ...S.card, marginTop: 20 }}>
          <div style={{ fontWeight: 650, marginBottom: 12 }}>Ergebnis der Analyse</div>
          <p style={{ color: T.textDim, fontSize: 14 }}>{aiResult.summary}</p>
          {aiResult.subs?.map((s, i) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderTop: `1px solid ${T.border}`, gap: 12, flexWrap: "wrap" }}>
              <div>
                <span style={{ fontWeight: 600 }}>{s.name}</span>
                {s.suspicious && <span style={{ ...S.tag(T.red), marginLeft: 10 }}>⚠ verdächtig</span>}
                {s.reason && <div style={{ fontSize: 13, color: T.textDim }}>{s.reason}</div>}
              </div>
              <div style={{ fontWeight: 650 }}>{fmt(s.amount)}</div>
            </div>
          ))}
          <button style={{ ...S.btn, marginTop: 16 }} onClick={importAll}>Alle in Abo-Liste übernehmen →</button>
        </div>
      )}
      {aiResult?.error && <div style={{ ...S.card, marginTop: 20, color: T.red }}>{aiResult.error}</div>}
    </div>
  );
}
