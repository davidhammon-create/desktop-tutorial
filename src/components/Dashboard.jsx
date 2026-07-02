import React, { useMemo, useState } from "react";
import { T, S, statusCfg } from "../shared/tokens";
import { Reveal } from "../shared/Reveal";
import { GrowthChart } from "../shared/GrowthChart";
import { fmt, futureValue, monthsSince } from "../shared/format";
import { api } from "../shared/api";

// 0-100 health score: rewards low suspicious share and reviewed subscriptions, penalizes stale unreviewed ones.
function healthScore(subs) {
  if (subs.length === 0) return 100;
  const warn = subs.filter((s) => s.status === "warning").length;
  const pendingOld = subs.filter((s) => s.status === "pending" && monthsSince(s.since) >= 24).length;
  const reviewed = subs.filter((s) => s.status === "keep" || s.status === "switch").length;
  let score = 100;
  score -= warn * 18;
  score -= pendingOld * 8;
  score += Math.min(10, reviewed * 1.5);
  return Math.max(0, Math.min(100, Math.round(score)));
}

export default function Dashboard({ subs, onGoAbos, onFilterWarning, onRefresh }) {
  const switchedSum = subs.filter((s) => s.status === "switch").reduce((a, s) => a + s.amount, 0);
  const totalMonthly = subs.reduce((a, s) => a + s.amount, 0);
  const warnings = subs.filter((s) => s.status === "warning");
  const score = useMemo(() => healthScore(subs), [subs]);
  const scoreColor = score >= 75 ? T.green : score >= 45 ? T.orange : T.red;
  const [checking, setChecking] = useState(false);
  const [checkResult, setCheckResult] = useState(null);

  const runAutoCheck = async () => {
    setChecking(true);
    setCheckResult(null);
    try {
      const res = await api.ai.autoClassify();
      setCheckResult(res);
      onRefresh?.();
    } catch (e) {
      setCheckResult({ summary: e.message, engine: "fehler", results: [] });
    }
    setChecking(false);
  };

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 12 }}>
        <div>
          <Reveal><h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 6px" }}>Deine Finanz-Übersicht</h1></Reveal>
          <Reveal delay={0.05}><p style={{ color: T.textDim, margin: "0 0 32px" }}>{subs.length} erkannte wiederkehrende Zahlungen</p></Reveal>
        </div>
        <Reveal delay={0.1}>
          <button style={{ ...S.btn, opacity: checking ? 0.6 : 1 }} disabled={checking} onClick={runAutoCheck}>
            {checking ? "⏳ Prüft alle Abos…" : "✦ KI-Auto-Check starten"}
          </button>
        </Reveal>
      </div>

      {checkResult && (
        <Reveal>
          <div style={{ ...S.card, marginBottom: 32, borderColor: checkResult.engine === "ki" ? "rgba(191,90,242,0.35)" : "rgba(100,210,255,0.3)" }}>
            <div style={{ fontWeight: 650, marginBottom: 8, color: checkResult.engine === "ki" ? T.purple : T.teal }}>
              {checkResult.engine === "ki" ? "✦ KI-Analyse abgeschlossen" : checkResult.engine === "basis" ? "🛡 Basis-Check abgeschlossen" : "Fehler"}
            </div>
            <p style={{ fontSize: 14, color: T.textDim, margin: "0 0 12px", lineHeight: 1.5 }}>{checkResult.summary}</p>
            {checkResult.results?.length > 0 && (
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {checkResult.results.map((r) => {
                  const sub = subs.find((s) => s.id === r.id);
                  const cfg = statusCfg[r.status];
                  return cfg && (
                    <span key={r.id} style={S.tag(cfg.color)} title={r.reason}>
                      {cfg.icon} {sub?.name || `#${r.id}`}
                    </span>
                  );
                })}
              </div>
            )}
          </div>
        </Reveal>
      )}

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

      <Reveal>
        <div style={{ ...S.card, marginBottom: 32, display: "flex", alignItems: "center", gap: 24, flexWrap: "wrap" }}>
          <div style={{ position: "relative", width: 92, height: 92, flexShrink: 0 }}>
            <svg width="92" height="92" viewBox="0 0 92 92">
              <circle cx="46" cy="46" r="40" fill="none" stroke={T.border} strokeWidth="8" />
              <circle cx="46" cy="46" r="40" fill="none" stroke={scoreColor} strokeWidth="8" strokeLinecap="round"
                strokeDasharray={2 * Math.PI * 40} strokeDashoffset={2 * Math.PI * 40 * (1 - score / 100)}
                transform="rotate(-90 46 46)" style={{ transition: "stroke-dashoffset 1.2s cubic-bezier(0.16,1,0.3,1)" }} />
            </svg>
            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, fontWeight: 700, color: scoreColor }}>{score}</div>
          </div>
          <div>
            <div style={{ fontWeight: 650, fontSize: 16 }}>Abo-Gesundheits-Score</div>
            <div style={{ fontSize: 13.5, color: T.textDim, marginTop: 4, maxWidth: 480 }}>
              {score >= 75 ? "Sehr gut — deine Abos sind größtenteils überprüft und unbedenklich." : score >= 45 ? "Mittel — einige Abos sollten noch geprüft werden." : "Achtung — mehrere verdächtige oder lange unüberprüfte Abos."}
            </div>
          </div>
        </div>
      </Reveal>

      {warnings.length > 0 && (
        <Reveal>
          <div style={{ ...S.card, borderColor: "rgba(255,69,58,0.35)", background: "rgba(255,69,58,0.06)", marginBottom: 32 }}>
            <div style={{ fontWeight: 650, color: T.red, marginBottom: 12 }}>⚠ Verdächtige Abbuchungen erkannt</div>
            {warnings.map((w) => (
              <div key={w.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderTop: `1px solid ${T.border}`, gap: 12, flexWrap: "wrap" }}>
                <div>
                  <div style={{ fontWeight: 600 }}>{w.name} · {fmt(w.amount)}</div>
                  <div style={{ fontSize: 13, color: T.textDim }}>{w.note}</div>
                </div>
                <button style={{ ...S.btnGhost, padding: "8px 16px", fontSize: 13, borderColor: T.red, color: T.red }} onClick={onFilterWarning}>Prüfen →</button>
              </div>
            ))}
          </div>
        </Reveal>
      )}

      <Reveal>
        <div style={{ ...S.card, padding: 32 }}>
          <div style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 12, marginBottom: 16 }}>
            <div>
              <div style={{ fontSize: 14, color: T.textDim }}>Wenn du deine {subs.filter((s) => s.status === "switch").length} markierten Abos umwandelst ({fmt(switchedSum)}/Monat, MSCI World, 25 Jahre)</div>
              <div style={{ fontSize: 30, fontWeight: 700, letterSpacing: -0.5 }}>≈ {fmt(futureValue(switchedSum, 7.1, 25))} Vermögen</div>
            </div>
            <div style={{ ...S.tag(T.green), alignSelf: "center", fontSize: 14 }}>+{fmt(futureValue(switchedSum, 7.1, 25) * 0.04 / 12)}/Monat Renten-Boost*</div>
          </div>
          <GrowthChart monthly={switchedSum || 1} ret={7.1} years={25} />
        </div>
      </Reveal>
    </div>
  );
}
