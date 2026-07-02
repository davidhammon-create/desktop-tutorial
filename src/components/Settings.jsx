import React, { useState, useEffect } from "react";
import { T, S } from "../shared/tokens";
import { api } from "../shared/api";

export default function Settings({ user, setUser, aiUsageCount }) {
  const [saving, setSaving] = useState(false);
  const [hasApiKey, setHasApiKey] = useState(false);
  const [apiKeyInput, setApiKeyInput] = useState("");
  const [savingKey, setSavingKey] = useState(false);
  const [keyMessage, setKeyMessage] = useState("");

  useEffect(() => {
    api.config.get().then((c) => setHasApiKey(c.hasApiKey)).catch(() => {});
  }, []);

  const save = async () => {
    setSaving(true);
    try {
      const saved = await api.user.save(user);
      setUser(saved);
    } finally {
      setSaving(false);
    }
  };

  const saveApiKey = async () => {
    setSavingKey(true);
    setKeyMessage("");
    try {
      const res = await api.config.saveApiKey(apiKeyInput);
      setHasApiKey(res.hasApiKey);
      setApiKeyInput("");
      setKeyMessage(res.hasApiKey ? "✓ Gespeichert — KI-Funktionen sind jetzt aktiv." : "Key entfernt.");
    } catch (e) {
      setKeyMessage(e.message);
    }
    setSavingKey(false);
  };

  const removeApiKey = async () => {
    setSavingKey(true);
    try {
      const res = await api.config.saveApiKey("");
      setHasApiKey(res.hasApiKey);
      setKeyMessage("Key entfernt.");
    } finally {
      setSavingKey(false);
    }
  };

  return (
    <div style={{ maxWidth: 640 }}>
      <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 24px" }}>⚙ Konto & Einstellungen</h1>

      <div style={{ ...S.card, marginBottom: 20 }}>
        <div style={{ fontWeight: 650, marginBottom: 14 }}>Profil</div>
        <label style={{ fontSize: 13, color: T.textDim }}>Name</label>
        <input style={{ ...S.input, marginTop: 6, marginBottom: 16 }} placeholder="Dein Name" value={user.name} onChange={(e) => setUser({ ...user, name: e.target.value })} />
        <label style={{ fontSize: 13, color: T.textDim }}>Deine E-Mail-Adressen (werden Abos zugeordnet)</label>
        {user.emails.map((em, i) => (
          <div key={i} style={{ display: "flex", gap: 8, marginTop: 8 }}>
            <input style={S.input} placeholder={`E-Mail ${i + 1}`} value={em} onChange={(e) => {
              const emails = [...user.emails]; emails[i] = e.target.value; setUser({ ...user, emails });
            }} />
            {user.emails.length > 1 && (
              <button style={{ ...S.btnGhost, padding: "0 14px" }} onClick={() => setUser({ ...user, emails: user.emails.filter((_, j) => j !== i) })}>✕</button>
            )}
          </div>
        ))}
        <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
          <button style={{ ...S.btnGhost, padding: "8px 16px", fontSize: 13 }} onClick={() => setUser({ ...user, emails: [...user.emails, ""] })}>+ Weitere E-Mail hinzufügen</button>
          <button style={{ ...S.btn, padding: "8px 16px", fontSize: 13 }} onClick={save} disabled={saving}>{saving ? "Speichert…" : "Speichern"}</button>
        </div>
      </div>

      <div style={{ ...S.card, marginBottom: 20 }}>
        <div style={{ fontWeight: 650, marginBottom: 6 }}>✦ KI-Zugang</div>
        <p style={{ fontSize: 13, color: T.textDim, margin: "0 0 14px", lineHeight: 1.5 }}>
          Für KI-Auto-Check, Kontoauszug-Analyse, Firmenberichte und Kündigungsbriefe brauchst du einen eigenen{" "}
          <a href="https://console.anthropic.com/settings/keys" target="_blank" rel="noreferrer" style={{ color: T.teal }}>Anthropic API-Key</a>.
          Er wird nur lokal auf diesem Gerät gespeichert (in deinem App-Datenordner) — nie auf einem fremden Server.
        </p>
        <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 8, flexWrap: "wrap" }}>
          <span style={S.tag(hasApiKey ? T.green : T.orange)}>{hasApiKey ? "✓ KI-Zugang aktiv" : "⚠ Kein Key hinterlegt"}</span>
        </div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <input
            type="password"
            style={{ ...S.input, maxWidth: 340 }}
            placeholder="sk-ant-…"
            value={apiKeyInput}
            onChange={(e) => setApiKeyInput(e.target.value)}
          />
          <button style={{ ...S.btn, padding: "10px 18px", fontSize: 13.5 }} onClick={saveApiKey} disabled={savingKey || !apiKeyInput}>
            {savingKey ? "…" : "Speichern"}
          </button>
          {hasApiKey && (
            <button style={{ ...S.btnGhost, padding: "10px 18px", fontSize: 13.5, color: T.red, borderColor: T.red + "55" }} onClick={removeApiKey} disabled={savingKey}>
              Entfernen
            </button>
          )}
        </div>
        {keyMessage && <div style={{ fontSize: 12.5, color: T.textDim, marginTop: 8 }}>{keyMessage}</div>}
        {aiUsageCount > 0 && (
          <p style={{ fontSize: 12, color: T.textFaint, marginTop: 12 }}>{aiUsageCount} KI-Analysen in dieser Sitzung. Abgerechnet direkt über dein Anthropic-Konto — AboWandler selbst verlangt keine eigene Gebühr.</p>
        )}
      </div>

      <div style={{ ...S.card, marginBottom: 20 }}>
        <div style={{ fontWeight: 650, marginBottom: 10 }}>🔒 Daten & Sicherheit</div>
        <p style={{ fontSize: 13.5, color: T.textDim, lineHeight: 1.6, margin: "0 0 10px" }}>
          Alle Abo-Daten und Zugangsdaten bleiben auf diesem Gerät — es gibt keinen zentralen Cloud-Server. Passwörter werden lokal AES-256-verschlüsselt gespeichert und nie im Klartext geloggt. Kontoauszüge werden nur bei aktiver KI-Analyse an Anthropic übermittelt, sonst nirgendwo hin.
        </p>
        <p style={{ fontSize: 12.5, color: T.textFaint, lineHeight: 1.6, margin: 0 }}>
          Damit du AboWandler auch von deinem Handy im selben WLAN öffnen kannst, ist es im lokalen Netzwerk erreichbar (nicht nur auf diesem Gerät). Andere Geräte in deinem WLAN könnten die Adresse theoretisch mit-erraten — für ein privates Heimnetz unkritisch. Willst du es auf dieses Gerät beschränken oder später an einen echten Server/eine echte Domain anbinden, ist das über die Umgebungsvariablen <code>HOST</code>/<code>PORT</code> beim Start einstellbar (siehe README).
        </p>
      </div>

      <div style={{ ...S.card, borderColor: "rgba(255,159,10,0.3)" }}>
        <div style={{ fontWeight: 650, marginBottom: 10, color: T.orange }}>Wichtiger Hinweis</div>
        <p style={{ fontSize: 13.5, color: T.textDim, lineHeight: 1.6, margin: 0 }}>
          AboWandler ist keine Finanz-, Anlage- oder Rechtsberatung. Alle Prognosen sind unverbindliche Modellrechnungen. Risiko-Hinweise zu Zahlungen sind Wahrscheinlichkeits-Einschätzungen, keine Tatsachenbehauptungen. Entscheidungen triffst du eigenverantwortlich.
        </p>
      </div>
    </div>
  );
}
