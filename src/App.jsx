import React, { useState, useEffect } from "react";
import { T, S } from "./shared/tokens";
import { Orbs } from "./shared/Reveal";
import { api } from "./shared/api";
import Landing from "./components/Landing";
import Dashboard from "./components/Dashboard";
import Subscriptions from "./components/Subscriptions";
import AccountsConnect from "./components/AccountsConnect";
import EtfExplorer from "./components/EtfExplorer";
import Settings from "./components/Settings";

export default function AboWandler() {
  const [page, setPage] = useState("landing"); // landing | app
  const [tab, setTab] = useState("dashboard");
  const [subs, setSubs] = useState([]);
  const [accounts, setAccounts] = useState([]);
  const [user, setUser] = useState({ name: "", emails: [""] });
  const [aiUsageCount, setAiUsageCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filterOverride, setFilterOverride] = useState(null);

  const loadAll = () => {
    setLoading(true);
    Promise.all([api.subscriptions.list(), api.accounts.list(), api.user.get()])
      .then(([s, a, u]) => {
        setSubs(s);
        setAccounts(a);
        setUser(u);
        setError(null);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (page === "app") loadAll();
  }, [page]);

  const switchedSum = subs.filter((s) => s.status === "switch").reduce((a, s) => a + s.amount, 0);
  const emails = user.emails.filter(Boolean);

  const NavBtn = ({ id, label, icon }) => (
    <button onClick={() => setTab(id)} style={{
      background: tab === id ? T.bgCardHover : "transparent", border: "none", color: tab === id ? T.text : T.textDim,
      borderRadius: 12, padding: "10px 16px", fontSize: 14.5, fontWeight: tab === id ? 600 : 450, cursor: "pointer",
      display: "flex", alignItems: "center", gap: 8, transition: "all 0.2s",
    }}>{icon} {label}</button>
  );

  if (page === "landing") {
    return <Landing onStart={() => setPage("app")} />;
  }

  return (
    <div style={S.page}>
      <Orbs />
      <nav style={{ position: "sticky", top: 0, zIndex: 10, backdropFilter: "blur(24px)", background: "rgba(5,5,8,0.75)", borderBottom: `1px solid ${T.border}` }}>
        <div style={{ ...S.container, display: "flex", justifyContent: "space-between", alignItems: "center", height: 60, gap: 12 }}>
          <div style={{ fontWeight: 700, fontSize: 17, cursor: "pointer", whiteSpace: "nowrap" }} onClick={() => setPage("landing")}>
            Abo<span style={{ background: `linear-gradient(90deg, ${T.green}, ${T.teal})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Wandler</span>
          </div>
          <div style={{ display: "flex", gap: 4, overflowX: "auto" }}>
            <NavBtn id="dashboard" label="Übersicht" icon="◉" />
            <NavBtn id="abos" label="Abos" icon="☰" />
            <NavBtn id="konten" label="Konten" icon="🔗" />
            <NavBtn id="etf" label="ETF-Rechner" icon="↗" />
            <NavBtn id="settings" label="Konto" icon="⚙" />
          </div>
        </div>
      </nav>

      <main style={{ ...S.container, padding: "40px 24px 80px" }}>
        {error && (
          <div style={{ ...S.card, marginBottom: 24, borderColor: "rgba(255,69,58,0.35)", color: T.red }}>
            Verbindung zum Server fehlgeschlagen: {error}. Läuft das Backend (server/) auf Port 8787?
          </div>
        )}
        {loading ? (
          <div style={{ color: T.textDim }}>Lädt…</div>
        ) : (
          <>
            {tab === "dashboard" && (
              <Dashboard
                subs={subs}
                onGoAbos={() => setTab("abos")}
                onFilterWarning={() => { setFilterOverride("warning"); setTab("abos"); }}
              />
            )}
            {tab === "abos" && (
              <Subscriptions
                subs={subs}
                setSubs={setSubs}
                emails={emails}
                forceFilter={filterOverride}
                onForceFilterApplied={() => setFilterOverride(null)}
              />
            )}
            {tab === "konten" && (
              <AccountsConnect accounts={accounts} setAccounts={setAccounts} onImported={() => { loadAll(); setAiUsageCount((c) => c + 1); }} />
            )}
            {tab === "etf" && <EtfExplorer subs={subs} switchedSum={switchedSum} />}
            {tab === "settings" && <Settings user={user} setUser={setUser} aiUsageCount={aiUsageCount} />}
          </>
        )}
      </main>
    </div>
  );
}
