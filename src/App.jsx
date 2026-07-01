import React, { useState, useEffect, useRef, useMemo } from "react";

/* ============================================================
   ABOWANDLER — KI-Finanz & Abo-Check App
   Dark Mode · Apple-Style · Scroll-Animationen
   ============================================================ */

// ---------- Design Tokens ----------
const T = {
  bg: "#050508",
  bgCard: "rgba(255,255,255,0.04)",
  bgCardHover: "rgba(255,255,255,0.07)",
  border: "rgba(255,255,255,0.08)",
  text: "#F5F5F7",
  textDim: "#A1A1A6",
  textFaint: "#6E6E73",
  green: "#30D158",
  teal: "#64D2FF",
  purple: "#BF5AF2",
  orange: "#FF9F0A",
  red: "#FF453A",
  blue: "#0A84FF",
};

// ---------- Beispiel-Abos (Demo-Daten) ----------
const initialSubs = [
  { id: 1, name: "Netflix", amount: 17.99, cycle: "monatlich", since: "2019-03", category: "Streaming", status: "keep", color: "#E50914", letter: "N", iban: "DE44 5001 0517 5407 3249 31", email: "", lastCharge: "2026-06-28", note: "" },
  { id: 2, name: "Spotify", amount: 10.99, cycle: "monatlich", since: "2020-01", category: "Musik", status: "keep", color: "#1DB954", letter: "S", iban: "DE89 3704 0044 0532 0130 00", email: "", lastCharge: "2026-06-25", note: "" },
  { id: 3, name: "Adobe Creative Cloud", amount: 59.99, cycle: "monatlich", since: "2021-06", category: "Software", status: "switch", color: "#FF0000", letter: "A", iban: "DE02 1203 0000 0000 2020 51", email: "", lastCharge: "2026-06-20", note: "Wird kaum noch genutzt" },
  { id: 4, name: "Fitness First", amount: 39.90, cycle: "monatlich", since: "2018-09", category: "Sport", status: "pending", color: "#0A84FF", letter: "F", iban: "DE12 5005 0201 0200 4455 66", email: "", lastCharge: "2026-06-15", note: "Läuft seit fast 8 Jahren — nie überprüft" },
  { id: 5, name: "Amazon Prime", amount: 8.99, cycle: "monatlich", since: "2017-11", category: "Shopping", status: "keep", color: "#FF9900", letter: "P", iban: "DE87 3007 0010 0111 2223 33", email: "", lastCharge: "2026-06-22", note: "" },
  { id: 6, name: "CloudSecure Pro LTD", amount: 24.99, cycle: "monatlich", since: "2026-04", category: "Unbekannt", status: "warning", color: "#FF453A", letter: "?", iban: "FI21 1234 5600 0007 85", email: "", lastCharge: "2026-06-29", note: "⚠ Finnische IBAN · Firma nicht im Handelsregister auffindbar · neue Abbuchung" },
  { id: 7, name: "Vodafone", amount: 39.99, cycle: "monatlich", since: "2022-02", category: "Mobilfunk", status: "pending", color: "#E60000", letter: "V", iban: "DE33 5002 0000 0011 2233 44", email: "", lastCharge: "2026-06-27", note: "Preiserhöhung: früher 29,99 €" },
];

// ---------- ETF Demo-Daten ----------
const etfs = [
  { name: "MSCI World (thesaurierend)", ret: 7.1, risk: "Mittel", ter: 0.20, tag: "Beliebtester", desc: "Weltweit gestreut, ~1.500 Unternehmen" },
  { name: "S&P 500", ret: 9.2, risk: "Mittel-Hoch", ter: 0.07, tag: "Höchste Rendite (hist.)", desc: "500 größte US-Unternehmen" },
  { name: "MSCI World (ausschüttend)", ret: 6.8, risk: "Mittel", ter: 0.20, tag: "Für Dividenden-Fans", desc: "Regelmäßige Ausschüttungen" },
  { name: "FTSE All-World", ret: 6.9, risk: "Mittel", ter: 0.22, tag: "Breiteste Streuung", desc: "Industrieländer + Schwellenländer" },
  { name: "Tagesgeld-Vergleich", ret: 2.8, risk: "Sehr niedrig", ter: 0, tag: "Sicherster", desc: "Kein Kursrisiko, Zinsen variabel" },
];

// ---------- Helpers ----------
const fmt = (n) => n.toLocaleString("de-DE", { style: "currency", currency: "EUR" });
const monthsSince = (ym) => {
  const [y, m] = ym.split("-").map(Number);
  const now = new Date(2026, 6);
  return (now.getFullYear() - y) * 12 + (now.getMonth() + 1 - m);
};
const yearsLabel = (ym) => {
  const m = monthsSince(ym);
  const y = Math.floor(m / 12);
  return y >= 1 ? `${y} Jahr${y > 1 ? "e" : ""}` : `${m} Monate`;
};
// Zinseszins: monatliche Sparrate
const futureValue = (monthly, annualPct, years) => {
  const r = annualPct / 100 / 12;
  const n = years * 12;
  if (r === 0) return monthly * n;
  return monthly * ((Math.pow(1 + r, n) - 1) / r);
};

// ---------- Scroll Reveal Hook ----------
function useReveal() {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([e]) => e.isIntersecting && setVisible(true),
      { threshold: 0.15 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);
  return [ref, visible];
}

const Reveal = ({ children, delay = 0, style = {} }) => {
  const [ref, vis] = useReveal();
  return (
    <div
      ref={ref}
      style={{
        opacity: vis ? 1 : 0,
        transform: vis ? "translateY(0)" : "translateY(40px)",
        transition: `opacity 0.8s ease ${delay}s, transform 0.8s cubic-bezier(0.16,1,0.3,1) ${delay}s`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

// ---------- Animierter Wachstums-Graph ----------
function GrowthChart({ monthly, ret, years }) {
  const [ref, vis] = useReveal();
  const points = useMemo(() => {
    const pts = [];
    for (let y = 0; y <= years; y++) {
      pts.push({ y, invested: monthly * 12 * y, value: futureValue(monthly, ret, y) });
    }
    return pts;
  }, [monthly, ret, years]);
  const max = points[points.length - 1].value || 1;
  const W = 640, H = 260, P = 10;
  const toXY = (i, v) => [P + (i / years) * (W - 2 * P), H - P - (v / max) * (H - 2 * P)];
  const path = (key) => points.map((p, i) => { const [x, y] = toXY(i, p[key]); return `${i === 0 ? "M" : "L"}${x},${y}`; }).join(" ");
  return (
    <div ref={ref} style={{ width: "100%" }}>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: "100%", height: "auto", display: "block" }}>
        <defs>
          <linearGradient id="gGreen" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={T.green} stopOpacity="0.35" />
            <stop offset="100%" stopColor={T.green} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={`${path("value")} L${W - P},${H - P} L${P},${H - P} Z`} fill="url(#gGreen)"
          style={{ opacity: vis ? 1 : 0, transition: "opacity 1.5s ease 0.8s" }} />
        <path d={path("invested")} fill="none" stroke={T.textFaint} strokeWidth="2" strokeDasharray="6 6"
          style={{ strokeDashoffset: vis ? 0 : 1200, strokeDasharray: vis ? "6 6" : "1200", transition: "all 2s ease" }} />
        <path d={path("value")} fill="none" stroke={T.green} strokeWidth="3" strokeLinecap="round"
          pathLength="100"
          style={{ strokeDasharray: 100, strokeDashoffset: vis ? 0 : 100, transition: "stroke-dashoffset 2.2s cubic-bezier(0.6,0,0.2,1) 0.2s" }} />
      </svg>
      <div style={{ display: "flex", gap: 24, marginTop: 8, fontSize: 13, color: T.textDim }}>
        <span><span style={{ color: T.green }}>—</span> Vermögen mit Zinseszins</span>
        <span><span style={{ color: T.textFaint }}>- -</span> Nur eingezahlt</span>
      </div>
    </div>
  );
}

// ---------- Gradient Orbs (Hintergrund) ----------
const Orbs = () => (
  <>
    <style>{`
      @keyframes float1 { 0%,100%{transform:translate(0,0) scale(1)} 50%{transform:translate(60px,-40px) scale(1.15)} }
      @keyframes float2 { 0%,100%{transform:translate(0,0) scale(1)} 50%{transform:translate(-50px,50px) scale(0.9)} }
      @media (prefers-reduced-motion: reduce) { .orb { animation: none !important; } }
    `}</style>
    <div className="orb" style={{ position: "fixed", top: "-10%", right: "-5%", width: 600, height: 600, borderRadius: "50%", background: "radial-gradient(circle, rgba(48,209,88,0.14), transparent 65%)", filter: "blur(60px)", animation: "float1 14s ease-in-out infinite", pointerEvents: "none", zIndex: 0 }} />
    <div className="orb" style={{ position: "fixed", bottom: "-15%", left: "-10%", width: 700, height: 700, borderRadius: "50%", background: "radial-gradient(circle, rgba(100,210,255,0.10), transparent 65%)", filter: "blur(70px)", animation: "float2 18s ease-in-out infinite", pointerEvents: "none", zIndex: 0 }} />
  </>
);

// ---------- Status-Konfiguration ----------
const statusCfg = {
  pending: { label: "Ausstehender Check", color: T.orange, icon: "◷" },
  warning: { label: "Warnung / Risiko", color: T.red, icon: "⚠" },
  keep: { label: "Behalten", color: T.blue, icon: "✓" },
  switch: { label: "In ETF umwandeln", color: T.green, icon: "↗" },
};

// ---------- Haupt-App ----------
export default function AboWandler() {
  const [page, setPage] = useState("landing"); // landing | app
  const [tab, setTab] = useState("dashboard");
  const [subs, setSubs] = useState(initialSubs);
  const [user, setUser] = useState({ name: "", emails: [""], loggedIn: false });
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState("amount");
  const [filterStatus, setFilterStatus] = useState("all");
  const [aiInput, setAiInput] = useState("");
  const [aiLoading, setAiLoading] = useState(false);
  const [aiResult, setAiResult] = useState(null);
  const [calc, setCalc] = useState({ monthly: 59.99, etf: 0, years: 10 });
  const [reportLoading, setReportLoading] = useState(null);
  const [reports, setReports] = useState({});

  const switchedSum = subs.filter(s => s.status === "switch").reduce((a, s) => a + s.amount, 0);
  const totalMonthly = subs.reduce((a, s) => a + s.amount, 0);
  const warnings = subs.filter(s => s.status === "warning");

  // --- KI: Kontoauszug analysieren ---
  const analyzeStatement = async () => {
    if (!aiInput.trim()) return;
    setAiLoading(true); setAiResult(null);
    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 1000,
          messages: [{
            role: "user",
            content: `Analysiere diesen Kontoauszug. Finde wiederkehrende Zahlungen (Abos) und verdächtige Abbuchungen (ungewöhnliche Beträge, ausländische IBANs, unbekannte Firmen). Antworte NUR mit validem JSON, ohne Markdown:
{"subs":[{"name":"...","amount":0.00,"suspicious":false,"reason":"..."}],"summary":"kurze Zusammenfassung"}

Kontoauszug:
${aiInput}`
          }],
        }),
      });
      const data = await res.json();
      const text = data.content.filter(c => c.type === "text").map(c => c.text).join("");
      const clean = text.replace(/```json|```/g, "").trim();
      setAiResult(JSON.parse(clean));
    } catch (e) {
      setAiResult({ error: "Analyse fehlgeschlagen. Bitte erneut versuchen." });
    }
    setAiLoading(false);
  };

  const importAiSubs = () => {
    if (!aiResult?.subs) return;
    const maxId = Math.max(...subs.map(s => s.id), 0);
    const news = aiResult.subs.map((s, i) => ({
      id: maxId + i + 1, name: s.name, amount: s.amount, cycle: "monatlich",
      since: "2026-06", category: "Importiert",
      status: s.suspicious ? "warning" : "pending",
      color: s.suspicious ? T.red : T.teal, letter: s.name[0]?.toUpperCase() || "?",
      iban: "", email: "", lastCharge: "2026-06-30", note: s.reason || "",
    }));
    setSubs([...subs, ...news]);
    setAiResult(null); setAiInput(""); setTab("abos");
  };

  // --- KI: Firmen-Bericht ---
  const generateReport = async (sub) => {
    setReportLoading(sub.id);
    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 800,
          messages: [{ role: "user", content: `Erstelle einen kurzen Seriositäts-Bericht über die Firma "${sub.name}" (IBAN-Land: ${sub.iban.slice(0,2) || "unbekannt"}, monatliche Abbuchung: ${sub.amount}€). Recherchiere: Existiert die Firma? Gibt es Betrugswarnungen? Ist der Betrag plausibel? Bewerte das Risiko (niedrig/mittel/hoch) und begründe kurz. Max. 150 Wörter, auf Deutsch. Hinweis: Gib Wahrscheinlichkeiten an, keine Tatsachenbehauptungen.` }],
          tools: [{ type: "web_search_20250305", name: "web_search" }],
        }),
      });
      const data = await res.json();
      const text = data.content.filter(c => c.type === "text").map(c => c.text).join("\n");
      setReports(r => ({ ...r, [sub.id]: text }));
    } catch {
      setReports(r => ({ ...r, [sub.id]: "Bericht konnte nicht erstellt werden." }));
    }
    setReportLoading(null);
  };

  const setStatus = (id, status) => setSubs(subs.map(s => s.id === id ? { ...s, status } : s));
  const setEmail = (id, email) => setSubs(subs.map(s => s.id === id ? { ...s, email } : s));
  const removeSub = (id) => setSubs(subs.filter(s => s.id !== id));

  const filtered = useMemo(() => {
    let list = subs.filter(s => s.name.toLowerCase().includes(search.toLowerCase()));
    if (filterStatus !== "all") list = list.filter(s => s.status === filterStatus);
    list.sort((a, b) => {
      if (sortBy === "amount") return b.amount - a.amount;
      if (sortBy === "name") return a.name.localeCompare(b.name);
      if (sortBy === "age") return monthsSince(b.since) - monthsSince(a.since);
      return 0;
    });
    return list;
  }, [subs, search, sortBy, filterStatus]);

  const fv = futureValue(calc.monthly, etfs[calc.etf].ret, calc.years);
  const invested = calc.monthly * 12 * calc.years;
  const monthlyPension = (fv * 0.04) / 12; // 4%-Regel

  // ---------- Styles ----------
  const S = {
    page: { minHeight: "100vh", background: T.bg, color: T.text, fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, sans-serif", position: "relative", overflowX: "hidden" },
    container: { maxWidth: 1100, margin: "0 auto", padding: "0 24px", position: "relative", zIndex: 1 },
    card: { background: T.bgCard, border: `1px solid ${T.border}`, borderRadius: 20, padding: 24, backdropFilter: "blur(20px)" },
    btn: { background: T.text, color: T.bg, border: "none", borderRadius: 999, padding: "14px 28px", fontSize: 16, fontWeight: 600, cursor: "pointer", transition: "transform 0.2s, opacity 0.2s" },
    btnGhost: { background: "transparent", color: T.text, border: `1px solid ${T.border}`, borderRadius: 999, padding: "13px 26px", fontSize: 16, fontWeight: 500, cursor: "pointer" },
    input: { background: "rgba(255,255,255,0.06)", border: `1px solid ${T.border}`, borderRadius: 12, padding: "12px 16px", color: T.text, fontSize: 15, outline: "none", width: "100%", boxSizing: "border-box" },
    tag: (c) => ({ display: "inline-flex", alignItems: "center", gap: 6, background: `${c}22`, color: c, borderRadius: 999, padding: "5px 12px", fontSize: 12.5, fontWeight: 600 }),
  };

  // ============ LANDING PAGE ============
  if (page === "landing") {
    return (
      <div style={S.page}>
        <Orbs />
        {/* Nav */}
        <nav style={{ position: "sticky", top: 0, zIndex: 10, backdropFilter: "blur(24px)", background: "rgba(5,5,8,0.7)", borderBottom: `1px solid ${T.border}` }}>
          <div style={{ ...S.container, display: "flex", justifyContent: "space-between", alignItems: "center", height: 60 }}>
            <div style={{ fontWeight: 700, fontSize: 19, letterSpacing: -0.5 }}>
              Abo<span style={{ background: `linear-gradient(90deg, ${T.green}, ${T.teal})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Wandler</span>
            </div>
            <button style={{ ...S.btn, padding: "9px 20px", fontSize: 14 }} onClick={() => setPage("app")}>App starten</button>
          </div>
        </nav>

        {/* Hero */}
        <section style={{ ...S.container, textAlign: "center", padding: "110px 24px 90px" }}>
          <Reveal>
            <div style={{ ...S.tag(T.green), marginBottom: 24 }}>✦ KI-gestützter Finanz-Check</div>
          </Reveal>
          <Reveal delay={0.1}>
            <h1 style={{ fontSize: "clamp(40px, 7vw, 76px)", fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.05, margin: "0 0 24px" }}>
              Dein Netflix-Abo<br />
              <span style={{ background: `linear-gradient(90deg, ${T.green}, ${T.teal}, ${T.purple})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>wird zu Vermögen.</span>
            </h1>
          </Reveal>
          <Reveal delay={0.2}>
            <p style={{ fontSize: 20, color: T.textDim, maxWidth: 560, margin: "0 auto 40px", lineHeight: 1.5 }}>
              Die KI findet vergessene Abos und dubiose Abbuchungen — und zeigt dir, was aus dem Geld werden könnte, wenn du es stattdessen investierst.
            </p>
          </Reveal>
          <Reveal delay={0.3}>
            <div style={{ display: "flex", gap: 14, justifyContent: "center", flexWrap: "wrap" }}>
              <button style={S.btn} onClick={() => setPage("app")}>Kostenlos analysieren →</button>
              <button style={S.btnGhost} onClick={() => document.getElementById("how")?.scrollIntoView({ behavior: "smooth" })}>So funktioniert's</button>
            </div>
          </Reveal>
        </section>

        {/* Live-Demo Chart */}
        <section style={{ ...S.container, paddingBottom: 100 }}>
          <Reveal>
            <div style={{ ...S.card, padding: 36 }}>
              <div style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 16, marginBottom: 20 }}>
                <div>
                  <div style={{ fontSize: 14, color: T.textDim }}>Beispiel: Adobe-Abo (59,99 €/Monat) → MSCI World, 25 Jahre</div>
                  <div style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1 }}>
                    ≈ {fmt(futureValue(59.99, 7.1, 25))}
                  </div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ fontSize: 14, color: T.textDim }}>Möglicher Renten-Boost*</div>
                  <div style={{ fontSize: 26, fontWeight: 700, color: T.green }}>+{fmt(futureValue(59.99, 7.1, 25) * 0.04 / 12)}/Monat</div>
                </div>
              </div>
              <GrowthChart monthly={59.99} ret={7.1} years={25} />
              <p style={{ fontSize: 12, color: T.textFaint, marginTop: 14 }}>
                *Modellrechnung auf Basis historischer Durchschnittsrenditen. Keine Garantie, keine Anlageberatung. Vergangene Wertentwicklung ist kein Indikator für zukünftige Ergebnisse.
              </p>
            </div>
          </Reveal>
        </section>

        {/* How it works */}
        <section id="how" style={{ ...S.container, paddingBottom: 100 }}>
          <Reveal><h2 style={{ fontSize: 40, fontWeight: 700, letterSpacing: -1, textAlign: "center", marginBottom: 56 }}>Drei Schritte zur Klarheit</h2></Reveal>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 20 }}>
            {[
              { icon: "🔗", t: "Verbinden oder hochladen", d: "Kontoauszüge einfügen oder hochladen — von Girokonto, PayPal, Kreditkarte, Klarna. Die KI liest alles.", c: T.teal },
              { icon: "🧠", t: "KI prüft alles", d: "Wiederkehrende Zahlungen, unbekannte Empfänger, ausländische IBANs, Preissteigerungen — alles wird erkannt und bewertet.", c: T.purple },
              { icon: "📈", t: "Umwandeln statt verlieren", d: "Unnötige Abos kündigen und denselben Betrag in einen ETF-Sparplan umleiten. Dein Konto merkt nichts — dein Vermögen schon.", c: T.green },
            ].map((f, i) => (
              <Reveal key={i} delay={i * 0.12}>
                <div style={{ ...S.card, height: "100%", boxSizing: "border-box" }}>
                  <div style={{ fontSize: 36, marginBottom: 16 }}>{f.icon}</div>
                  <h3 style={{ fontSize: 20, fontWeight: 650, margin: "0 0 10px", color: f.c }}>{f.t}</h3>
                  <p style={{ color: T.textDim, lineHeight: 1.55, margin: 0, fontSize: 15 }}>{f.d}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </section>

        {/* Features / Abgrenzung */}
        <section style={{ ...S.container, paddingBottom: 100 }}>
          <Reveal><h2 style={{ fontSize: 40, fontWeight: 700, letterSpacing: -1, textAlign: "center", marginBottom: 12 }}>Mehr als nur Tracking</h2></Reveal>
          <Reveal delay={0.1}><p style={{ textAlign: "center", color: T.textDim, marginBottom: 56, fontSize: 17 }}>Was AboWandler anders macht als klassische Finanz-Apps</p></Reveal>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))", gap: 16 }}>
            {[
              ["⚠ Betrugs-Radar", "KI recherchiert unbekannte Zahlungsempfänger im Web: Existiert die Firma? Gibt es Beschwerden? Passt der Betrag?"],
              ["📄 Firmen-Berichte", "Zu jedem Abo ein ladbarer KI-Bericht über den Anbieter — Seriosität, Historie, Risiko-Einschätzung."],
              ["🔄 Abo-zu-ETF-Wandler", "Der einzige Rechner, der aus deiner Kündigung eine konkrete Renten-Prognose macht."],
              ["🕰 Alters-Check", "„Dieses Abo läuft seit 8 Jahren und wurde nie überprüft“ — die App erinnert dich."],
              ["✉ Zugangs-Verwaltung", "E-Mail, Nutzername und Vertragsdaten pro Abo hinterlegen — nie wieder suchen beim Kündigen."],
              ["💶 Faire KI-Kosten", "Du zahlst KI-Analysen transparent nach Nutzung. Keine versteckten Gebühren."],
            ].map(([t, d], i) => (
              <Reveal key={i} delay={(i % 3) * 0.1}>
                <div style={{ ...S.card, padding: 20, height: "100%", boxSizing: "border-box" }}>
                  <div style={{ fontWeight: 650, marginBottom: 8, fontSize: 16 }}>{t}</div>
                  <div style={{ color: T.textDim, fontSize: 14, lineHeight: 1.5 }}>{d}</div>
                </div>
              </Reveal>
            ))}
          </div>
        </section>

        {/* CTA */}
        <section style={{ ...S.container, paddingBottom: 120, textAlign: "center" }}>
          <Reveal>
            <div style={{ ...S.card, padding: "64px 32px", background: "linear-gradient(135deg, rgba(48,209,88,0.10), rgba(100,210,255,0.08))" }}>
              <h2 style={{ fontSize: 36, fontWeight: 700, letterSpacing: -1, margin: "0 0 16px" }}>Bereit für den Abo-Check?</h2>
              <p style={{ color: T.textDim, marginBottom: 32, fontSize: 17 }}>Finde in 2 Minuten heraus, wo dein Geld wirklich hingeht.</p>
              <button style={S.btn} onClick={() => setPage("app")}>Jetzt starten — kostenlos →</button>
            </div>
          </Reveal>
          <p style={{ fontSize: 12, color: T.textFaint, marginTop: 40, maxWidth: 640, margin: "40px auto 0", lineHeight: 1.6 }}>
            AboWandler bietet keine Finanz- oder Anlageberatung. Alle Prognosen sind Modellrechnungen ohne Garantie. Investments bergen Verlustrisiken. Die Nutzung erfolgt auf eigenes Risiko.
          </p>
        </section>
      </div>
    );
  }

  // ============ APP ============
  const NavBtn = ({ id, label, icon }) => (
    <button onClick={() => setTab(id)} style={{
      background: tab === id ? T.bgCardHover : "transparent", border: "none", color: tab === id ? T.text : T.textDim,
      borderRadius: 12, padding: "10px 16px", fontSize: 14.5, fontWeight: tab === id ? 600 : 450, cursor: "pointer",
      display: "flex", alignItems: "center", gap: 8, transition: "all 0.2s",
    }}>{icon} {label}</button>
  );

  return (
    <div style={S.page}>
      <Orbs />
      {/* App Nav */}
      <nav style={{ position: "sticky", top: 0, zIndex: 10, backdropFilter: "blur(24px)", background: "rgba(5,5,8,0.75)", borderBottom: `1px solid ${T.border}` }}>
        <div style={{ ...S.container, display: "flex", justifyContent: "space-between", alignItems: "center", height: 60, gap: 12 }}>
          <div style={{ fontWeight: 700, fontSize: 17, cursor: "pointer", whiteSpace: "nowrap" }} onClick={() => setPage("landing")}>
            Abo<span style={{ background: `linear-gradient(90deg, ${T.green}, ${T.teal})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Wandler</span>
          </div>
          <div style={{ display: "flex", gap: 4, overflowX: "auto" }}>
            <NavBtn id="dashboard" label="Übersicht" icon="◉" />
            <NavBtn id="abos" label="Abos" icon="☰" />
            <NavBtn id="ai" label="KI-Analyse" icon="✦" />
            <NavBtn id="calc" label="ETF-Rechner" icon="↗" />
            <NavBtn id="settings" label="Konto" icon="⚙" />
          </div>
        </div>
      </nav>

      <main style={{ ...S.container, padding: "40px 24px 80px" }}>

        {/* ===== DASHBOARD ===== */}
        {tab === "dashboard" && (
          <div>
            <Reveal><h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 6px" }}>Deine Finanz-Übersicht</h1></Reveal>
            <Reveal delay={0.05}><p style={{ color: T.textDim, margin: "0 0 32px" }}>Stand: Juli 2026 · {subs.length} erkannte wiederkehrende Zahlungen</p></Reveal>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))", gap: 16, marginBottom: 32 }}>
              {[
                ["Monatliche Abo-Kosten", fmt(totalMonthly), T.text],
                ["Umwandlungs-Potenzial", fmt(switchedSum) + "/Monat", T.green],
                ["Warnungen", warnings.length + " verdächtige Zahlung" + (warnings.length !== 1 ? "en" : ""), T.red],
                ["In 25 J. (bei 7,1% p.a.)", "≈ " + fmt(futureValue(switchedSum, 7.1, 25)), T.teal],
              ].map(([l, v, c], i) => (
                <Reveal key={i} delay={i * 0.08}>
                  <div style={S.card}>
                    <div style={{ fontSize: 13, color: T.textDim, marginBottom: 8 }}>{l}</div>
                    <div style={{ fontSize: 24, fontWeight: 700, color: c, letterSpacing: -0.5 }}>{v}</div>
                  </div>
                </Reveal>
              ))}
            </div>

            {warnings.length > 0 && (
              <Reveal>
                <div style={{ ...S.card, borderColor: "rgba(255,69,58,0.35)", background: "rgba(255,69,58,0.06)", marginBottom: 32 }}>
                  <div style={{ fontWeight: 650, color: T.red, marginBottom: 12 }}>⚠ Verdächtige Abbuchungen erkannt</div>
                  {warnings.map(w => (
                    <div key={w.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderTop: `1px solid ${T.border}`, gap: 12, flexWrap: "wrap" }}>
                      <div>
                        <div style={{ fontWeight: 600 }}>{w.name} · {fmt(w.amount)}</div>
                        <div style={{ fontSize: 13, color: T.textDim }}>{w.note}</div>
                      </div>
                      <button style={{ ...S.btnGhost, padding: "8px 16px", fontSize: 13, borderColor: T.red, color: T.red }} onClick={() => { setTab("abos"); setFilterStatus("warning"); }}>Prüfen →</button>
                    </div>
                  ))}
                </div>
              </Reveal>
            )}

            <Reveal>
              <div style={{ ...S.card, padding: 32 }}>
                <div style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 12, marginBottom: 16 }}>
                  <div>
                    <div style={{ fontSize: 14, color: T.textDim }}>Wenn du deine {subs.filter(s => s.status === "switch").length} markierten Abos umwandelst ({fmt(switchedSum)}/Monat, MSCI World, 25 Jahre)</div>
                    <div style={{ fontSize: 30, fontWeight: 700, letterSpacing: -0.5 }}>≈ {fmt(futureValue(switchedSum, 7.1, 25))} Vermögen</div>
                  </div>
                  <div style={{ ...S.tag(T.green), alignSelf: "center", fontSize: 14 }}>+{fmt(futureValue(switchedSum, 7.1, 25) * 0.04 / 12)}/Monat Renten-Boost*</div>
                </div>
                <GrowthChart monthly={switchedSum || 1} ret={7.1} years={25} />
              </div>
            </Reveal>
          </div>
        )}

        {/* ===== ABOS ===== */}
        {tab === "abos" && (
          <div>
            <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 24px" }}>Deine Abos & Zahlungen</h1>
            <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
              <input style={{ ...S.input, maxWidth: 280 }} placeholder="🔍 Abo suchen…" value={search} onChange={e => setSearch(e.target.value)} />
              <select style={{ ...S.input, maxWidth: 180 }} value={sortBy} onChange={e => setSortBy(e.target.value)}>
                <option value="amount">Nach Preis</option>
                <option value="name">Nach Name</option>
                <option value="age">Nach Alter</option>
              </select>
              <select style={{ ...S.input, maxWidth: 200 }} value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
                <option value="all">Alle Status</option>
                {Object.entries(statusCfg).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
              </select>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {filtered.map(sub => {
                const cfg = statusCfg[sub.status];
                return (
                  <div key={sub.id} style={{ ...S.card, padding: 20 }}>
                    <div style={{ display: "flex", gap: 16, alignItems: "flex-start", flexWrap: "wrap" }}>
                      <div style={{ width: 48, height: 48, borderRadius: 14, background: `${sub.color}22`, color: sub.color, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, fontWeight: 700, flexShrink: 0 }}>{sub.letter}</div>
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
                        {monthsSince(sub.since) >= 48 && sub.status === "pending" && (
                          <div style={{ fontSize: 13, color: T.orange, marginTop: 6 }}>🕰 Läuft seit über {Math.floor(monthsSince(sub.since) / 12)} Jahren — Zeit für einen Check?</div>
                        )}
                      </div>
                      <div style={{ textAlign: "right", flexShrink: 0 }}>
                        <div style={{ fontSize: 20, fontWeight: 700 }}>{fmt(sub.amount)}</div>
                        <div style={{ fontSize: 12, color: T.textFaint }}>= {fmt(sub.amount * 12)}/Jahr</div>
                      </div>
                    </div>

                    {/* Aktionen */}
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
                      <button onClick={() => removeSub(sub.id)} style={{ ...S.btnGhost, padding: "7px 14px", fontSize: 12.5, color: T.textFaint }}>Entfernen</button>
                    </div>

                    {/* E-Mail-Zuordnung */}
                    {user.emails.filter(Boolean).length > 0 && (
                      <div style={{ marginTop: 12, display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
                        <span style={{ fontSize: 13, color: T.textDim }}>✉ Zugehörige E-Mail:</span>
                        <select style={{ ...S.input, maxWidth: 260, padding: "7px 12px", fontSize: 13 }} value={sub.email} onChange={e => setEmail(sub.id, e.target.value)}>
                          <option value="">— auswählen —</option>
                          {user.emails.filter(Boolean).map((em, i) => <option key={i} value={em}>{em}</option>)}
                        </select>
                      </div>
                    )}

                    {/* KI-Bericht */}
                    {reports[sub.id] && (
                      <div style={{ marginTop: 14, padding: 16, background: "rgba(191,90,242,0.07)", border: `1px solid rgba(191,90,242,0.25)`, borderRadius: 14, fontSize: 14, lineHeight: 1.6, color: T.textDim, whiteSpace: "pre-wrap" }}>
                        <div style={{ color: T.purple, fontWeight: 650, marginBottom: 8 }}>📄 KI-Bericht: {sub.name}</div>
                        {reports[sub.id]}
                      </div>
                    )}
                  </div>
                );
              })}
              {filtered.length === 0 && <div style={{ ...S.card, textAlign: "center", color: T.textDim }}>Keine Abos gefunden. Nutze die KI-Analyse, um Kontoauszüge zu importieren.</div>}
            </div>
          </div>
        )}

        {/* ===== KI-ANALYSE ===== */}
        {tab === "ai" && (
          <div>
            <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 6px" }}>✦ KI-Kontoauszug-Analyse</h1>
            <p style={{ color: T.textDim, margin: "0 0 24px", maxWidth: 640 }}>
              Füge deinen Kontoauszug ein (Text kopieren aus Online-Banking, PayPal, Klarna…). Die KI erkennt wiederkehrende Zahlungen und markiert verdächtige Abbuchungen automatisch.
            </p>
            <div style={S.card}>
              <textarea
                style={{ ...S.input, minHeight: 200, fontFamily: "SF Mono, Menlo, monospace", fontSize: 13, resize: "vertical" }}
                placeholder={"Beispiel:\n28.06.2026  NETFLIX INTERNATIONAL B.V.   -17,99 EUR\n25.06.2026  SPOTIFY AB                    -10,99 EUR\n29.06.2026  CLOUDSECURE PRO LTD FI21...   -24,99 EUR\n…"}
                value={aiInput} onChange={e => setAiInput(e.target.value)}
              />
              <div style={{ display: "flex", gap: 12, marginTop: 16, alignItems: "center", flexWrap: "wrap" }}>
                <button style={{ ...S.btn, opacity: aiLoading ? 0.6 : 1 }} disabled={aiLoading} onClick={analyzeStatement}>
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
                <button style={{ ...S.btn, marginTop: 16 }} onClick={importAiSubs}>Alle in Abo-Liste übernehmen →</button>
              </div>
            )}
            {aiResult?.error && <div style={{ ...S.card, marginTop: 20, color: T.red }}>{aiResult.error}</div>}
          </div>
        )}

        {/* ===== ETF-RECHNER ===== */}
        {tab === "calc" && (
          <div>
            <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 6px" }}>↗ Abo-zu-ETF-Rechner</h1>
            <p style={{ color: T.textDim, margin: "0 0 24px" }}>Was könnte aus deinem gekündigten Abo werden?</p>

            <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: 20, maxWidth: 760 }}>
              <div style={S.card}>
                <label style={{ fontSize: 13.5, color: T.textDim }}>Monatlicher Betrag (z. B. dein gekündigtes Abo)</label>
                <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 8 }}>
                  <input type="range" min="5" max="300" step="0.01" value={calc.monthly} onChange={e => setCalc({ ...calc, monthly: +e.target.value })} style={{ flex: 1, accentColor: T.green }} />
                  <div style={{ fontSize: 24, fontWeight: 700, minWidth: 110, textAlign: "right" }}>{fmt(calc.monthly)}</div>
                </div>
                <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" }}>
                  {subs.filter(s => s.status === "switch").map(s => (
                    <button key={s.id} style={{ ...S.btnGhost, padding: "6px 12px", fontSize: 12.5 }} onClick={() => setCalc({ ...calc, monthly: s.amount })}>{s.name} ({fmt(s.amount)})</button>
                  ))}
                  <button style={{ ...S.btnGhost, padding: "6px 12px", fontSize: 12.5, color: T.green, borderColor: T.green + "55" }} onClick={() => setCalc({ ...calc, monthly: +switchedSum.toFixed(2) })}>Alle markierten ({fmt(switchedSum)})</button>
                </div>

                <label style={{ fontSize: 13.5, color: T.textDim, display: "block", marginTop: 22 }}>Anlagedauer: <b style={{ color: T.text }}>{calc.years} Jahre</b></label>
                <input type="range" min="1" max="50" value={calc.years} onChange={e => setCalc({ ...calc, years: +e.target.value })} style={{ width: "100%", accentColor: T.teal, marginTop: 8 }} />

                <label style={{ fontSize: 13.5, color: T.textDim, display: "block", marginTop: 22, marginBottom: 10 }}>ETF / Anlage wählen</label>
                <div style={{ display: "grid", gap: 8 }}>
                  {etfs.map((e, i) => (
                    <button key={i} onClick={() => setCalc({ ...calc, etf: i })} style={{
                      ...S.btnGhost, textAlign: "left", padding: "12px 16px", borderRadius: 14,
                      borderColor: calc.etf === i ? T.green : T.border, background: calc.etf === i ? "rgba(48,209,88,0.08)" : "transparent",
                      display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, flexWrap: "wrap",
                    }}>
                      <span>
                        <span style={{ fontWeight: 600, fontSize: 14.5 }}>{e.name}</span>
                        <span style={{ ...S.tag(T.teal), marginLeft: 8, fontSize: 11 }}>{e.tag}</span>
                        <div style={{ fontSize: 12.5, color: T.textDim, marginTop: 3 }}>{e.desc} · Risiko: {e.risk} · TER {e.ter}%</div>
                      </span>
                      <span style={{ fontWeight: 700, color: T.green }}>{e.ret}% p.a.*</span>
                    </button>
                  ))}
                </div>
              </div>

              <div style={{ ...S.card, background: "linear-gradient(135deg, rgba(48,209,88,0.10), rgba(100,210,255,0.06))" }}>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 16, marginBottom: 20 }}>
                  <div><div style={{ fontSize: 13, color: T.textDim }}>Eingezahlt</div><div style={{ fontSize: 24, fontWeight: 700 }}>{fmt(invested)}</div></div>
                  <div><div style={{ fontSize: 13, color: T.textDim }}>Mögliches Vermögen*</div><div style={{ fontSize: 24, fontWeight: 700, color: T.green }}>{fmt(fv)}</div></div>
                  <div><div style={{ fontSize: 13, color: T.textDim }}>Davon Zinseszins</div><div style={{ fontSize: 24, fontWeight: 700, color: T.teal }}>{fmt(fv - invested)}</div></div>
                  <div><div style={{ fontSize: 13, color: T.textDim }}>Renten-Boost (4%-Regel)*</div><div style={{ fontSize: 24, fontWeight: 700, color: T.purple }}>+{fmt(monthlyPension)}/Mon.</div></div>
                </div>
                <GrowthChart monthly={calc.monthly} ret={etfs[calc.etf].ret} years={calc.years} />
                <p style={{ fontSize: 11.5, color: T.textFaint, marginTop: 14, lineHeight: 1.5 }}>
                  *Modellrechnung mit historischen Durchschnittsrenditen. Keine Anlageberatung, keine Garantie. Renditen schwanken, Verluste sind möglich. Die 4%-Entnahmeregel ist eine Faustformel, keine Zusicherung.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* ===== KONTO / EINSTELLUNGEN ===== */}
        {tab === "settings" && (
          <div style={{ maxWidth: 640 }}>
            <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 24px" }}>⚙ Konto & Einstellungen</h1>

            <div style={{ ...S.card, marginBottom: 20 }}>
              <div style={{ fontWeight: 650, marginBottom: 14 }}>Profil</div>
              <label style={{ fontSize: 13, color: T.textDim }}>Name</label>
              <input style={{ ...S.input, marginTop: 6, marginBottom: 16 }} placeholder="Dein Name" value={user.name} onChange={e => setUser({ ...user, name: e.target.value })} />
              <label style={{ fontSize: 13, color: T.textDim }}>Deine E-Mail-Adressen (werden Abos zugeordnet)</label>
              {user.emails.map((em, i) => (
                <div key={i} style={{ display: "flex", gap: 8, marginTop: 8 }}>
                  <input style={S.input} placeholder={`E-Mail ${i + 1}`} value={em} onChange={e => {
                    const emails = [...user.emails]; emails[i] = e.target.value; setUser({ ...user, emails });
                  }} />
                  {user.emails.length > 1 && (
                    <button style={{ ...S.btnGhost, padding: "0 14px" }} onClick={() => setUser({ ...user, emails: user.emails.filter((_, j) => j !== i) })}>✕</button>
                  )}
                </div>
              ))}
              <button style={{ ...S.btnGhost, padding: "8px 16px", fontSize: 13, marginTop: 12 }} onClick={() => setUser({ ...user, emails: [...user.emails, ""] })}>+ Weitere E-Mail hinzufügen</button>
            </div>

            <div style={{ ...S.card, marginBottom: 20 }}>
              <div style={{ fontWeight: 650, marginBottom: 14 }}>Verbundene Quellen</div>
              {["Girokonto (Kontoauszug-Import)", "PayPal (Kontoauszug-Import)", "Kreditkarte (Kontoauszug-Import)"].map((q, i) => (
                <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 0", borderTop: i > 0 ? `1px solid ${T.border}` : "none" }}>
                  <span style={{ fontSize: 14.5 }}>{q}</span>
                  <span style={S.tag(T.green)}>✓ per KI-Import aktiv</span>
                </div>
              ))}
              <p style={{ fontSize: 12.5, color: T.textFaint, marginTop: 12, lineHeight: 1.5 }}>
                Direkte Bank-Anbindung (PSD2-API) ist für eine spätere Version geplant. Aktuell: Kontoauszüge sicher per Copy&nbsp;&&nbsp;Paste importieren — deine Zugangsdaten verlassen nie dein Gerät.
              </p>
            </div>

            <div style={{ ...S.card, marginBottom: 20 }}>
              <div style={{ fontWeight: 650, marginBottom: 14 }}>Abrechnung & KI-Nutzung</div>
              <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: 14.5 }}><span style={{ color: T.textDim }}>Plattform-Abo</span><span>4,99 €/Monat</span></div>
              <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: 14.5, borderTop: `1px solid ${T.border}` }}><span style={{ color: T.textDim }}>KI-Nutzung diesen Monat</span><span>{Object.keys(reports).length + (aiResult ? 1 : 0)} Analysen ≈ {fmt((Object.keys(reports).length + (aiResult ? 1 : 0)) * 0.02)}</span></div>
              <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: 15, fontWeight: 650, borderTop: `1px solid ${T.border}` }}><span>Gesamt</span><span>{fmt(4.99 + (Object.keys(reports).length + (aiResult ? 1 : 0)) * 0.02)}</span></div>
              <p style={{ fontSize: 12.5, color: T.textFaint, marginTop: 10 }}>Du zahlst KI-Kosten transparent nach tatsächlicher Nutzung — keine versteckten Gebühren, keine Kostenexplosion möglich.</p>
            </div>

            <div style={{ ...S.card, borderColor: "rgba(255,159,10,0.3)" }}>
              <div style={{ fontWeight: 650, marginBottom: 10, color: T.orange }}>Wichtiger Hinweis</div>
              <p style={{ fontSize: 13.5, color: T.textDim, lineHeight: 1.6, margin: 0 }}>
                AboWandler ist keine Finanz-, Anlage- oder Rechtsberatung. Alle Prognosen sind unverbindliche Modellrechnungen. Risiko-Hinweise zu Zahlungen sind Wahrscheinlichkeits-Einschätzungen, keine Tatsachenbehauptungen. Entscheidungen triffst du eigenverantwortlich.
              </p>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
