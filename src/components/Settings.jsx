import React, { useState } from "react";
import { T, S } from "../shared/tokens";
import { fmt } from "../shared/format";
import { api } from "../shared/api";

export default function Settings({ user, setUser, aiUsageCount }) {
  const [saving, setSaving] = useState(false);

  const save = async () => {
    setSaving(true);
    try {
      const saved = await api.user.save(user);
      setUser(saved);
    } finally {
      setSaving(false);
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
        <div style={{ fontWeight: 650, marginBottom: 14 }}>Abrechnung & KI-Nutzung</div>
        <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: 14.5 }}><span style={{ color: T.textDim }}>Plattform-Abo</span><span>4,99 €/Monat</span></div>
        <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: 14.5, borderTop: `1px solid ${T.border}` }}><span style={{ color: T.textDim }}>KI-Nutzung diesen Monat</span><span>{aiUsageCount} Analysen ≈ {fmt(aiUsageCount * 0.02)}</span></div>
        <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: 15, fontWeight: 650, borderTop: `1px solid ${T.border}` }}><span>Gesamt</span><span>{fmt(4.99 + aiUsageCount * 0.02)}</span></div>
        <p style={{ fontSize: 12.5, color: T.textFaint, marginTop: 10 }}>Du zahlst KI-Kosten transparent nach tatsächlicher Nutzung — keine versteckten Gebühren, keine Kostenexplosion möglich.</p>
      </div>

      <div style={{ ...S.card, marginBottom: 20 }}>
        <div style={{ fontWeight: 650, marginBottom: 10 }}>🔒 Sicherheit</div>
        <p style={{ fontSize: 13.5, color: T.textDim, lineHeight: 1.6, margin: 0 }}>
          Zugangsdaten (Passwörter) werden serverseitig AES-256-verschlüsselt gespeichert und nie im Klartext geloggt. Kontoauszüge werden nur zur Analyse an die KI übermittelt, nicht dauerhaft bei Drittanbietern gespeichert.
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
