
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Sparkles, Calculator, TrendingUp, AlertTriangle } from "lucide-react";
import { AppleCard, AppleButton, AppleField, AppleInput, SF } from "../AppleCard";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell, ReferenceLine } from "recharts";

const SF_FONT = { fontFamily: "-apple-system,'Helvetica Neue',Arial,sans-serif" };
const TOOLTIP_STYLE = { borderRadius: 12, border: "1px solid rgba(0,0,0,0.07)", boxShadow: "0 8px 28px rgba(0,0,0,0.12)", fontSize: 12, fontFamily: SF_FONT.fontFamily, background: "#fff", padding: "8px 14px" };

function GaugeMini({ value, max = 100, color, label }) {
  const r = 20, circ = 2 * Math.PI * r;
  const pct = Math.min(100, (value / max) * 100);
  return (
    <div style={{ textAlign: "center" }}>
      <svg width={48} height={48}>
        <circle cx={24} cy={24} r={r} fill="none" stroke="rgba(0,0,0,0.07)" strokeWidth={5} />
        <circle cx={24} cy={24} r={r} fill="none" stroke={color} strokeWidth={5}
          strokeDasharray={circ} strokeDashoffset={circ * (1 - pct / 100)}
          strokeLinecap="round" style={{ transform: "rotate(-90deg)", transformOrigin: "24px 24px" }} />
      </svg>
      <p style={{ fontSize: 11, fontWeight: 800, color, marginTop: -38, lineHeight: "48px", position: "relative" }}>{Math.round(value)}</p>
      <p style={{ fontSize: 9, color: "#888", fontWeight: 600, textTransform: "uppercase", marginTop: 2 }}>{label}</p>
    </div>
  );
}

export default function Step5QuantitativeAnalyse({ scenario, onSave }) {
  const ctx = scenario.unternehmenskontext || {};
  const sit = scenario.situationsanalyse || {};
  const opts = scenario.ki_analyse?.handlungsoptionen || {};
  const [fin, setFin] = useState(scenario.finanzdaten || {});
  const [result, setResult] = useState(scenario.ki_analyse?.quant_analyse || null);
  const [analysing, setAnalysing] = useState(false);

  const saveFin = (k, v) => {
    const n = { ...fin, [k]: v };
    setFin(n);
    onSave({ finanzdaten: n });
  };

  const runAnalysis = async () => {
    setAnalysing(true);
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist Quantitativer Risikoanalyst und Senior-Anwalt für Wirtschaftsrecht. Führe eine vollständige quantitative Kosten-Nutzen-Analyse durch.

UNTERNEHMENSKONTEXT:
Unternehmen: ${ctx.unternehmen_name} (${ctx.rechtsform}), Umsatz: ${ctx.umsatz ? (ctx.umsatz/1e6).toFixed(1)+"Mio.€" : "—"}
Märkte: ${(ctx.operative_maerkte || []).join(", ")}
Sachverhalt: ${ctx.sachverhalt_lang || "—"}
Rechtsgebiete: ${(ctx.rechtsgebiete || []).join(", ")}

FINANZEINGABEN:
${Object.entries(fin).filter(([,v]) => v).map(([k, v]) => `${k}: ${typeof v === "number" ? v.toLocaleString()+"€" : v}`).join("\n") || "Keine manuellen Eingaben"}

HANDLUNGSOPTIONEN:
Option A: ${JSON.stringify(scenario.option_a || opts.option_a || {}).slice(0, 400)}
Option B: ${JSON.stringify(scenario.option_b || opts.option_b || {}).slice(0, 400)}
Option C: ${JSON.stringify(scenario.option_c || opts.option_c || {}).slice(0, 400)}

RISIKOANALYSE: Gesamt-Risiko ${sit.gesamt_risiko || "—"}/10, Exposure ${sit.gesamt_exposure_eur ? (sit.gesamt_exposure_eur/1e6).toFixed(1)+"Mio.€" : "—"}

BERECHNE:

1. EXPECTED VALUE (EV) pro Option: wahrscheinlichkeitsgewichteter Nettoertrag
   Formel: EV = P(Erfolg) × Ertrag_Erfolg + P(Misserfolg) × Verlust_Misserfolg

2. RISIKOADJUSTIERTER WERT (RAV): EV - Risikopuffer
   
3. DOWNSIDE RISK: Worst-Case-Verlust bei 95% Konfidenz

4. RISIKOPRIORITÄTSZAHL (RPN): Eintrittswahrscheinlichkeit × Schadenshöhe × Entdeckbarkeit (je 1-10)

5. MONTE-CARLO-SIMULATION: 3 Szenarien (optimistisch/base/pessimistisch) mit Wahrscheinlichkeiten

6. BREAK-EVEN-ANALYSE: Wann wird welche Option rentabel?

7. SENSITIVITÄTSANALYSE: Welcher Parameter hat den größten Einfluss? (Tornado-Diagramm Daten)

8. INDIREKTE KOSTEN: Reputationsschaden, Managementaufwand, Produktionsverzögerung, regulatorische Auflagen (häufig höher als direkte Kosten!)

RECHTLICHE BUSSGELDER / RISIKEN (als Worst-Case einpreisen):
- Kartellrecht: bis 10% weltweiter Konzernumsatz (§ 81 Abs. 4 GWB)
- DSGVO: bis 20 Mio.€ oder 4% Umsatz (Art. 83 DSGVO)
- Steuern: Zinsen 1,8% p.a. nach § 233a AO, Festsetzungsfristen 4/5/10 Jahre (§§ 169 ff. AO)
- Patentrecht: entgangener Gewinn / Lizenzanalogie / Verletzergewinn (§ 139 PatG)
- Schiedsverfahren: ICC/DIS-Gebühren nach Streitwert
- Bonusregelung/Kronzeuge: vollständige Bußgeldfreistellung möglich

${ctx.umsatz ? `Umsatz für Bußgeldberechnung: ${(ctx.umsatz/1e6).toFixed(1)}Mio.€ → Kartellrechts-Bußgeld max: ${(ctx.umsatz * 0.1 / 1e6).toFixed(1)}Mio.€` : ""}`,
      response_json_schema: {
        type: "object",
        properties: {
          optionen_bewertung: { type: "array", items: { type: "object", properties: {
            option: { type: "string" },
            name: { type: "string" },
            ev_eur: { type: "number" },
            rav_eur: { type: "number" },
            downside_risk_eur: { type: "number" },
            rpn: { type: "number" },
            break_even_monate: { type: "number" },
            roi_pct: { type: "number" },
            erfolg_pct: { type: "number" }
          }}},
          monte_carlo: { type: "object", properties: {
            optimistisch: { type: "object", properties: { wert_eur: { type: "number" }, wahrscheinlichkeit_pct: { type: "number" }, beschreibung: { type: "string" } } },
            base: { type: "object", properties: { wert_eur: { type: "number" }, wahrscheinlichkeit_pct: { type: "number" }, beschreibung: { type: "string" } } },
            pessimistisch: { type: "object", properties: { wert_eur: { type: "number" }, wahrscheinlichkeit_pct: { type: "number" }, beschreibung: { type: "string" } } }
          }},
          sensitivitaet: { type: "array", items: { type: "object", properties: {
            parameter: { type: "string" }, einfluss_pct: { type: "number" }, richtung: { type: "string" }
          }}},
          indirekte_kosten: { type: "object", properties: {
            reputationsschaden_eur: { type: "number" },
            management_aufwand_eur: { type: "number" },
            produktionsverzögerung_eur: { type: "number" },
            regulatorische_auflagen_eur: { type: "number" },
            gesamt_indirekt_eur: { type: "number" }
          }},
          bussgeld_worst_cases: { type: "array", items: { type: "object", properties: {
            rechtsgebiet: { type: "string" }, norm: { type: "string" }, max_eur: { type: "number" }, einschätzung: { type: "string" }
          }}},
          empfohlene_option: { type: "string" },
          gesamtfazit: { type: "string" },
          steuer_fristen: { type: "array", items: { type: "object", properties: {
            typ: { type: "string" }, frist: { type: "string" }, rechtsfolge: { type: "string" }
          }}}
        }
      },
      model: "claude_sonnet_4_6"
    });
    setResult(r);
    await onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), quant_analyse: r } });
    setAnalysing(false);
  };

  const FINANZFELDER = [
    ["transaktionswert", "Transaktionswert / Streitwert (€)"],
    ["kosten_legal", "Kosten Option A — Legal (€)"],
    ["kosten_aggressiv", "Kosten Option B — Aggressiv (€)"],
    ["erwarteter_gewinn", "Erwarteter Gewinn Best Case (€)"],
    ["potentielle_strafe", "Potentielle Strafe / Buße (€)"],
    ["reputationsschaden", "Geschätzter Reputationsschaden (€)"],
    ["zeitkosten", "Zeitkosten / Opportunitätskosten (€)"],
    ["schiedsverfahren_kosten", "Schiedsverfahrenskosten (€)"],
  ];

  const evData = result?.optionen_bewertung?.map(o => ({
    name: `Option ${o.option}`,
    EV: Math.round((o.ev_eur || 0) / 1000),
    RAV: Math.round((o.rav_eur || 0) / 1000),
    Downside: Math.round(Math.abs(o.downside_risk_eur || 0) / 1000) * -1,
  })) || [];

  const sensData = result?.sensitivitaet?.slice(0, 6).sort((a, b) => b.einfluss_pct - a.einfluss_pct) || [];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, ...SF }}>
      <div style={{ textAlign: "center", padding: "8px 0 2px" }}>
        <p style={{ fontSize: 11, fontWeight: 700, color: "#5856D6", letterSpacing: "0.15em", textTransform: "uppercase" }}>Schritt 5 · Strategos</p>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: "#1a1a1a", letterSpacing: "-0.5px", marginTop: 4 }}>Quantitative Risiko- & Kosten-Nutzen-Analyse</h2>
        <p style={{ fontSize: 12, color: "#888", marginTop: 3 }}>Expected Value · Monte Carlo · Sensitivität · Indirekte Kosten · Bußgeld-Worst-Case</p>
      </div>

      {/* Finanzeingaben */}
      <AppleCard title="Finanzeingaben (optional — KI schätzt bei fehlenden Daten)" accentColor="#5856D6">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          {FINANZFELDER.map(([key, label]) => (
            <AppleField key={key} label={label}>
              <AppleInput type="number" value={fin[key] || ""}
                onChange={e => setFin(f => ({ ...f, [key]: Number(e.target.value) }))}
                onBlur={() => saveFin(key, fin[key])}
                placeholder="0" />
            </AppleField>
          ))}
        </div>
      </AppleCard>

      {/* Analyse starten */}
      <AppleCard accentColor="#5856D6">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
          <div>
            <p style={{ fontSize: 13, fontWeight: 700, color: "#1a1a1a" }}>Quantitative Analyse starten</p>
            <p style={{ fontSize: 11, color: "#888", marginTop: 2 }}>EV · Monte Carlo · Sensitivität · Bußgeld-Max · Steuerfristen</p>
          </div>
          <AppleButton onClick={runAnalysis} disabled={analysing} variant="violet" icon={Calculator}>
            {analysing ? "Berechnet…" : result ? "Neu berechnen" : "Analyse starten"}
          </AppleButton>
        </div>
      </AppleCard>

      {result && (
        <>
          {/* Optionen-Vergleich */}
          {result.optionen_bewertung?.length > 0 && (
            <AppleCard title="Optionen-Vergleich (EV / RAV / Downside)" accentColor="#5856D6">
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12, marginBottom: 16 }}>
                {result.optionen_bewertung.map((o, i) => {
                  const isRecommended = i === 0;
                  return (
                    <div key={o.option || i} style={{ padding: "13px 14px", background: isRecommended ? "rgba(29,185,84,0.07)" : "rgba(0,0,0,0.025)", borderRadius: 12, border: isRecommended ? "1px solid rgba(29,185,84,0.25)" : "1px solid rgba(0,0,0,0.06)" }}>
                      <p style={{ fontSize: 11, fontWeight: 700, color: isRecommended ? "#1DB954" : "#888", textTransform: "uppercase", marginBottom: 4 }}>Option {o.option}{isRecommended ? " ★ Empfohlen" : ""}</p>
                      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
                        {[["EV", (o.ev_eur || 0).toLocaleString("de-DE") + " €", "#5856D6"], ["RAV", (o.rav_eur || 0).toLocaleString("de-DE") + " €", "#0A84FF"], ["Downside", (o.downside_risk_eur || 0).toLocaleString("de-DE") + " €", "#FF3B30"], ["Eintritt", `${o.eintritt_pct ?? "—"}%`, "#FF9500"]].map(([l, v, c]) => (
                          <div key={l}>
                            <p style={{ fontSize: 9, color: "#aaa", textTransform: "uppercase", fontWeight: 600 }}>{l}</p>
                            <p style={{ fontSize: 13, fontWeight: 700, color: c }}>{v}</p>
                          </div>
                        ))}
                      </div>
                      {o.begründung && <p style={{ fontSize: 11, color: "#666", marginTop: 6 }}>{o.begründung}</p>}
                    </div>
                  );
                })}
              </div>
              {evData.length > 0 && (
                <ResponsiveContainer width="100%" height={180}>
                  <BarChart data={evData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.04)" />
                    <XAxis dataKey="name" tick={{ fontSize: 10, fill: "#888" }} />
                    <YAxis tick={{ fontSize: 10, fill: "#888" }} tickFormatter={v => `${v}K`} />
                    <Tooltip contentStyle={TOOLTIP_STYLE} formatter={v => [`${v}K €`]} />
                    <ReferenceLine y={0} stroke="rgba(0,0,0,0.15)" />
                    <Bar dataKey="EV" fill="#5856D6" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="RAV" fill="#0A84FF" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="Downside" fill="#FF3B30" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </AppleCard>
          )}

          {/* Monte Carlo */}
          {result.monte_carlo && (
            <AppleCard title="Monte Carlo Simulation" accentColor="#0A84FF">
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
                {[
                  ["P10 (Best Case)", result.monte_carlo.p10_eur, "#1DB954"],
                  ["P50 (Median)", result.monte_carlo.p50_eur, "#0A84FF"],
                  ["P90 (Worst Case)", result.monte_carlo.p90_eur, "#FF3B30"],
                  ["Simulationen", result.monte_carlo.simulationen?.toLocaleString(), "#888"],
                ].map(([l, v, c]) => (
                  <div key={l} style={{ textAlign: "center", padding: "10px", background: "rgba(0,0,0,0.025)", borderRadius: 10 }}>
                    <p style={{ fontSize: 9, color: "#aaa", textTransform: "uppercase", fontWeight: 600, marginBottom: 4 }}>{l}</p>
                    <p style={{ fontSize: 14, fontWeight: 800, color: c }}>{typeof v === "number" ? v.toLocaleString("de-DE") + " €" : v || "—"}</p>
                  </div>
                ))}
              </div>
              {result.monte_carlo.haupttreiber?.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 6 }}>Haupttreiber</p>
                  {result.monte_carlo.haupttreiber.map((t, i) => (
                    <p key={i} style={{ fontSize: 11, color: "#555", marginBottom: 3 }}>• {t}</p>
                  ))}
                </div>
              )}
            </AppleCard>
          )}

          {/* Sensitivität */}
          {sensData.length > 0 && (
            <AppleCard title="Sensitivitätsanalyse (Tornado)" accentColor="#5856D6">
              {sensData.map((s, i) => (
                <div key={i} style={{ marginBottom: 8 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 3 }}>
                    <span style={{ fontSize: 11, color: "#333" }}>{s.faktor}</span>
                    <span style={{ fontSize: 11, fontWeight: 700, color: "#5856D6" }}>{s.einfluss_pct}%</span>
                  </div>
                  <div style={{ height: 8, background: "rgba(0,0,0,0.05)", borderRadius: 4, overflow: "hidden" }}>
                    <div style={{ height: "100%", width: `${s.einfluss_pct}%`, background: `linear-gradient(90deg, #5856D6, #0A84FF)`, borderRadius: 4 }} />
                  </div>
                </div>
              ))}
            </AppleCard>
          )}

          {/* Bußgeld Worst Case */}
          {result.bussgeldszenario && (
            <AppleCard title="Bußgeld-Worst-Case" accentColor="#FF3B30">
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <div style={{ padding: "12px", background: "rgba(255,59,48,0.06)", borderRadius: 10 }}>
                  <p style={{ fontSize: 9, color: "#aaa", textTransform: "uppercase", fontWeight: 600 }}>Max. Bußgeld</p>
                  <p style={{ fontSize: 20, fontWeight: 800, color: "#FF3B30" }}>{(result.bussgeldszenario.max_bussgeldbetrag_eur || 0).toLocaleString("de-DE")} €</p>
                </div>
                <div style={{ padding: "12px", background: "rgba(255,149,0,0.06)", borderRadius: 10 }}>
                  <p style={{ fontSize: 9, color: "#aaa", textTransform: "uppercase", fontWeight: 600 }}>Rechtsgrundlage</p>
                  <p style={{ fontSize: 11, fontWeight: 700, color: "#FF9500" }}>{result.bussgeldszenario.rechtsgrundlage || "—"}</p>
                </div>
              </div>
              {result.bussgeldszenario.gegebenheiten_fuer_max?.length > 0 && (
                <div style={{ marginTop: 10 }}>
                  <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 5 }}>Voraussetzungen für Maximum</p>
                  {result.bussgeldszenario.gegebenheiten_fuer_max.map((g, i) => (
                    <p key={i} style={{ fontSize: 11, color: "#B81C3A", marginBottom: 3 }}>• {g}</p>
                  ))}
                </div>
              )}
            </AppleCard>
          )}

          {/* Empfohlene Option */}
          {result.empfohlene_option && (
            <AppleCard accentColor="#1DB954">
              <p style={{ fontSize: 13, fontWeight: 700, color: "#1a1a1a", marginBottom: 4 }}>✅ Empfohlene Option: {result.empfohlene_option}</p>
              {result.empfehlungs_begruendung && (
                <p style={{ fontSize: 12, color: "#555", lineHeight: 1.5 }}>{result.empfehlungs_begruendung}</p>
              )}
            </AppleCard>
          )}
        </>
      )}
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );
}
}
