import React, { useState, useMemo, useEffect } from "react";
import { T, S, statusCfg } from "../shared/tokens";
import { fmt, yearsLabel, monthsSince, futureValue } from "../shared/format";
import { Logo } from "../shared/Logo";
import { api } from "../shared/api";

// "Statt 19,99 € fürs Abo → 19,99 € in einen ETF" — Projektion für denselben Monatsbetrag.
function SwapSuggestion({ sub, etfs }) {
  const popular = etfs.find((e) => e.tags?.includes("Beliebtester")) || etfs[0];
  const best = etfs.reduce((a, b) => (b.ret > (a?.ret ?? -Infinity) ? b : a), null);
  if (!popular || !best) return null;
  const rows = [popular, ...(best.id !== popular.id ? [best] : [])];
  return (
    <div style={{ marginTop: 14, padding: 16, background: "rgba(48,209,88,0.06)", border: "1px solid rgba(48,209,88,0.25)", borderRadius: 14 }}>
      <div style={{ color: T.green, fontWeight: 650, marginBottom: 4, fontSize: 14 }}>
        ↗ Tausch-Vorschlag: Statt {fmt(sub.amount)} für „{sub.name}“ …
      </div>
      <div style={{ fontSize: 13, color: T.textDim, marginBottom: 12 }}>… denselben Betrag monatlich in einen ETF-Sparplan:</div>
      <div style={{ display: "grid", gap: 10 }}>
        {rows.map((e) => (
          <div key={e.id} style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 8, padding: "10px 12px", background: "rgba(255,255,255,0.03)", borderRadius: 10 }}>
            <div>
              <div style={{ fontWeight: 600, fontSize: 13.5 }}>{e.name} <span style={{ color: T.green }}>({e.ret}% p.a.*)</span></div>
              <div style={{ fontSize: 12, color: T.textFaint }}>Risiko: {e.risk} · TER {e.ter}%</div>
            </div>
            <div style={{ display: "flex", gap: 16, fontSize: 12.5, alignItems: "center", flexWrap: "wrap" }}>
              {[10, 20, 30].map((y) => (
                <div key={y} style={{ textAlign: "right" }}>
                  <div style={{ color: T.textFaint }}>{y} J.</div>
                  <div style={{ fontWeight: 700, color: T.green }}>{fmt(futureValue(sub.amount, e.ret, y))}</div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
      <div style={{ fontSize: 11.5, color: T.textFaint, marginTop: 10 }}>
        Eingezahlt wären es {fmt(sub.amount * 12 * 20)} in 20 Jahren — Renten-Boost nach 4%-Regel: +{fmt((futureValue(sub.amount, popular.ret, 20) * 0.04) / 12)}/Monat.* Modellrechnung, keine Anlageberatung.
      </div>
    </div>
  );
}

function CredentialForm({ sub, emails, onSave }) {
  const [email, setEmail] = useState(sub.email || "");
  const [username, setUsername] = useState(sub.username || "");
  const [phone, setPhone] = useState(sub.phone || "");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [loadedPw, setLoadedPw] = useState(false);
  const [saving, setSaving] = useState(false);

  const revealPassword = async () => {
    if (!loadedPw && sub.hasPassword) {
      const res = await api.subscriptions.password(sub.id);
      setPassword(res.password);
      setLoadedPw(true);
    }
    setShowPw((v) => !v);
  };

  const save = async () => {
    setSaving(true);
    try {
      await onSave({ email, username, phone, password });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ marginTop: 14, padding: 16, background: "rgba(255,255,255,0.03)", border: `1px solid ${T.border}`, borderRadius: 14 }}>
      <div style={{ fontSize: 13, color: T.textDim, marginBottom: 10 }}>✉ Zugangsdaten (verschlüsselt gespeichert)</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: 10 }}>
        <div>
          <label style={{ fontSize: 12, color: T.textFaint }}>E-Mail</label>
          {emails.length > 1 ? (
            <select style={{ ...S.input, padding: "9px 12px", fontSize: 13.5, marginTop: 4 }} value={email} onChange={(e) => setEmail(e.target.value)}>
              <option value="">— auswählen —</option>
              {emails.map((em, i) => <option key={i} value={em}>{em}</option>)}
            </select>
          ) : (
            <input style={{ ...S.input, padding: "9px 12px", fontSize: 13.5, marginTop: 4 }} value={email} onChange={(e) => setEmail(e.target.value)} placeholder="name@example.com" />
          )}
        </div>
        <div>
          <label style={{ fontSize: 12, color: T.textFaint }}>Nutzername</label>
          <input style={{ ...S.input, padding: "9px 12px", fontSize: 13.5, marginTop: 4 }} value={username} onChange={(e) => setUsername(e.target.value)} />
        </div>
        <div>
          <label style={{ fontSize: 12, color: T.textFaint }}>Passwort</label>
          <div style={{ display: "flex", gap: 6, marginTop: 4 }}>
            <input type={showPw ? "text" : "password"} style={{ ...S.input, padding: "9px 12px", fontSize: 13.5 }} value={password} onChange={(e) => { setPassword(e.target.value); setLoadedPw(true); }} placeholder={sub.hasPassword ? "••••••••" : ""} />
            <button style={{ ...S.btnGhost, padding: "0 12px", fontSize: 12 }} onClick={revealPassword} type="button">{showPw ? "🙈" : "👁"}</button>
          </div>
        </div>
        <div>
          <label style={{ fontSize: 12, color: T.textFaint }}>Handynummer</label>
          <input style={{ ...S.input, padding: "9px 12px", fontSize: 13.5, marginTop: 4 }} value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+49 …" />
        </div>
      </div>
      <button style={{ ...S.btnGhost, padding: "7px 16px", fontSize: 12.5, marginTop: 12 }} onClick={save} disabled={saving}>{saving ? "Speichert…" : "Speichern"}</button>
    </div>
  );
}

export default function Subscriptions({ subs, setSubs, emails, forceFilter, onForceFilterApplied }) {
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState("amount");
  const [filterStatus, setFilterStatus] = useState("all");

  useEffect(() => {
    if (forceFilter) {
      setFilterStatus(forceFilter);
      onForceFilterApplied?.();
    }
  }, [forceFilter]);
  const [reportLoading, setReportLoading] = useState(null);
  const [reports, setReports] = useState({});
  const [letterLoading, setLetterLoading] = useState(null);
  const [letters, setLetters] = useState({});
  const [openCreds, setOpenCreds] = useState(null);
  const [openSwap, setOpenSwap] = useState(null);
  const [etfs, setEtfs] = useState([]);

  useEffect(() => {
    api.etfs.list().then(setEtfs).catch(() => {});
  }, []);

  const filtered = useMemo(() => {
    let list = subs.filter((s) => s.name.toLowerCase().includes(search.toLowerCase()));
    if (filterStatus !== "all") list = list.filter((s) => s.status === filterStatus);
    list.sort((a, b) => {
      if (sortBy === "amount") return b.amount - a.amount;
      if (sortBy === "name") return a.name.localeCompare(b.name);
      if (sortBy === "age") return monthsSince(b.since) - monthsSince(a.since);
      return 0;
    });
    return list;
  }, [subs, search, sortBy, filterStatus]);

  const setStatus = async (id, status) => {
    setSubs(subs.map((s) => (s.id === id ? { ...s, status } : s)));
    await api.subscriptions.update(id, { status });
  };

  const removeSub = async (id) => {
    setSubs(subs.filter((s) => s.id !== id));
    await api.subscriptions.remove(id);
  };

  const saveCreds = async (id, body) => {
    const updated = await api.subscriptions.update(id, body);
    setSubs(subs.map((s) => (s.id === id ? { ...s, ...updated } : s)));
  };

  const generateReport = async (sub) => {
    setReportLoading(sub.id);
    try {
      const { report } = await api.ai.companyReport(sub.id);
      setReports((r) => ({ ...r, [sub.id]: report }));
    } catch (e) {
      setReports((r) => ({ ...r, [sub.id]: e.message }));
    }
    setReportLoading(null);
  };

  const generateLetter = async (sub) => {
    setLetterLoading(sub.id);
    try {
      const letter = await api.ai.cancellationLetter(sub.id);
      setLetters((l) => ({ ...l, [sub.id]: letter }));
    } catch (e) {
      setLetters((l) => ({ ...l, [sub.id]: { subject: "Fehler", body: e.message } }));
    }
    setLetterLoading(null);
  };

  const exportCsv = () => {
    const header = ["Name", "Betrag", "Zyklus", "Seit", "Kategorie", "Status", "Notiz"];
    const rows = subs.map((s) => [s.name, s.amount, s.cycle, s.since, s.category, s.status, s.note || ""]);
    const csv = [header, ...rows].map((r) => r.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(";")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "abowandler_abos.csv";
    a.click();
    URL.revokeObjectURL(url);
  };

  const downloadLetter = (sub, letter) => {
    const blob = new Blob([`Betreff: ${letter.subject}\n\n${letter.body}`], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `Kuendigung_${sub.name.replace(/\s+/g, "_")}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12, marginBottom: 24 }}>
        <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: 0 }}>Deine Abos & Zahlungen</h1>
        <button style={{ ...S.btnGhost, padding: "9px 18px", fontSize: 13.5 }} onClick={exportCsv}>⬇ Als CSV exportieren</button>
      </div>
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
        <input style={{ ...S.input, maxWidth: 280 }} placeholder="🔍 Abo suchen…" value={search} onChange={(e) => setSearch(e.target.value)} />
        <select style={{ ...S.input, maxWidth: 180 }} value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
          <option value="amount">Nach Preis</option>
          <option value="name">Nach Name</option>
          <option value="age">Nach Alter</option>
        </select>
        <select style={{ ...S.input, maxWidth: 200 }} value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
          <option value="all">Alle Status</option>
          {Object.entries(statusCfg).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
        </select>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {filtered.map((sub) => {
          const cfg = statusCfg[sub.status];
          const priceHike = sub.priceHistory && sub.priceHistory.length > 1 && sub.priceHistory[sub.priceHistory.length - 1].amount > sub.priceHistory[0].amount;
          return (
            <div key={sub.id} style={{ ...S.card, padding: 20 }}>
              <div style={{ display: "flex", gap: 16, alignItems: "flex-start", flexWrap: "wrap" }}>
                <Logo domain={sub.domain} letter={sub.letter} color={sub.color} />
                <div style={{ flex: 1, minWidth: 200 }}>
                  <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                    <span style={{ fontWeight: 650, fontSize: 17 }}>{sub.name}</span>
                    <span style={S.tag(cfg.color)}>{cfg.icon} {cfg.label}</span>
                  </div>
                  <div style={{ fontSize: 13.5, color: T.textDim, marginTop: 4 }}>
                    {fmt(sub.amount)} {sub.cycle} · läuft seit {yearsLabel(sub.since)} · {sub.category}
                    {sub.iban && <> · IBAN: {sub.iban.slice(0, 8)}…</>}
                  </div>
                  {sub.note && <div style={{ fontSize: 13, color: sub.status === "warning" ? T.red : T.orange, marginTop: 6 }}>{sub.note}</div>}
                  {priceHike && (
                    <div style={{ fontSize: 13, color: T.orange, marginTop: 6 }}>
                      📈 Preis gestiegen: {fmt(sub.priceHistory[0].amount)} → {fmt(sub.amount)} seit {sub.priceHistory[0].date}
                    </div>
                  )}
                  {monthsSince(sub.since) >= 48 && sub.status === "pending" && (
                    <div style={{ fontSize: 13, color: T.orange, marginTop: 6 }}>🕰 Läuft seit über {Math.floor(monthsSince(sub.since) / 12)} Jahren — Zeit für einen Check?</div>
                  )}
                </div>
                <div style={{ textAlign: "right", flexShrink: 0 }}>
                  <div style={{ fontSize: 20, fontWeight: 700 }}>{fmt(sub.amount)}</div>
                  <div style={{ fontSize: 12, color: T.textFaint }}>= {fmt(sub.amount * 12)}/Jahr</div>
                </div>
              </div>

              <div style={{ display: "flex", gap: 8, marginTop: 16, flexWrap: "wrap" }}>
                {Object.entries(statusCfg).map(([k, v]) => (
                  <button key={k} onClick={() => setStatus(sub.id, k)} style={{
                    ...S.btnGhost, padding: "7px 14px", fontSize: 12.5,
                    borderColor: sub.status === k ? v.color : T.border,
                    color: sub.status === k ? v.color : T.textDim,
                    background: sub.status === k ? `${v.color}15` : "transparent",
                  }}>{v.icon} {v.label}</button>
                ))}
                <button onClick={() => generateReport(sub)} disabled={reportLoading === sub.id} style={{ ...S.btnGhost, padding: "7px 14px", fontSize: 12.5, color: T.purple, borderColor: T.purple + "55" }}>
                  {reportLoading === sub.id ? "⏳ KI recherchiert…" : "📄 KI-Firmenbericht"}
                </button>
                <button onClick={() => generateLetter(sub)} disabled={letterLoading === sub.id} style={{ ...S.btnGhost, padding: "7px 14px", fontSize: 12.5, color: T.teal, borderColor: T.teal + "55" }}>
                  {letterLoading === sub.id ? "⏳ KI schreibt…" : "✉ Kündigungsbrief"}
                </button>
                <button onClick={() => setOpenSwap(openSwap === sub.id ? null : sub.id)} style={{ ...S.btnGhost, padding: "7px 14px", fontSize: 12.5, color: T.green, borderColor: T.green + "55" }}>
                  ↗ ETF-Tausch
                </button>
                <button onClick={() => setOpenCreds(openCreds === sub.id ? null : sub.id)} style={{ ...S.btnGhost, padding: "7px 14px", fontSize: 12.5 }}>
                  🔑 Zugangsdaten
                </button>
                <button onClick={() => removeSub(sub.id)} style={{ ...S.btnGhost, padding: "7px 14px", fontSize: 12.5, color: T.textFaint }}>Entfernen</button>
              </div>

              {openSwap === sub.id && etfs.length > 0 && (
                <SwapSuggestion sub={sub} etfs={etfs} />
              )}

              {openCreds === sub.id && (
                <CredentialForm sub={sub} emails={emails} onSave={(body) => saveCreds(sub.id, body)} />
              )}

              {reports[sub.id] && (
                <div style={{ marginTop: 14, padding: 16, background: "rgba(191,90,242,0.07)", border: `1px solid rgba(191,90,242,0.25)`, borderRadius: 14, fontSize: 14, lineHeight: 1.6, color: T.textDim, whiteSpace: "pre-wrap" }}>
                  <div style={{ color: T.purple, fontWeight: 650, marginBottom: 8 }}>📄 KI-Bericht: {sub.name}</div>
                  {reports[sub.id]}
                </div>
              )}

              {letters[sub.id] && (
                <div style={{ marginTop: 14, padding: 16, background: "rgba(100,210,255,0.07)", border: `1px solid rgba(100,210,255,0.25)`, borderRadius: 14, fontSize: 14, lineHeight: 1.6, color: T.textDim, whiteSpace: "pre-wrap" }}>
                  <div style={{ color: T.teal, fontWeight: 650, marginBottom: 8 }}>✉ {letters[sub.id].subject}</div>
                  {letters[sub.id].body}
                  <div style={{ marginTop: 10 }}>
                    <button style={{ ...S.btnGhost, padding: "6px 14px", fontSize: 12.5 }} onClick={() => downloadLetter(sub, letters[sub.id])}>Als TXT herunterladen</button>
                  </div>
                </div>
              )}
            </div>
          );
        })}
        {filtered.length === 0 && <div style={{ ...S.card, textAlign: "center", color: T.textDim }}>Keine Abos gefunden. Nutze „Konten" um Kontoauszüge zu importieren.</div>}
      </div>
    </div>
  );
}
