import React, { useState, useEffect, useMemo } from "react";
import { T, S } from "../shared/tokens";
import { fmt, futureValue } from "../shared/format";
import { GrowthChart, CompareChart } from "../shared/GrowthChart";
import { api } from "../shared/api";

const requiredMonthly = (targetFv, annualPct, years) => {
  const r = annualPct / 100 / 12;
  const n = years * 12;
  if (r === 0) return targetFv / n;
  return targetFv / ((Math.pow(1 + r, n) - 1) / r);
};

export default function EtfExplorer({ subs, switchedSum }) {
  const [allEtfs, setAllEtfs] = useState([]);
  const [etfs, setEtfs] = useState([]);
  const [query, setQuery] = useState("");
  const [calc, setCalc] = useState({ monthly: 59.99, etfId: null, years: 10 });
  const [compareIds, setCompareIds] = useState([]);
  const [pensionGoal, setPensionGoal] = useState(200);
  const [gapEtfId, setGapEtfId] = useState(null);
  const [gapYears, setGapYears] = useState(20);

  useEffect(() => {
    api.etfs.list().then((list) => {
      setAllEtfs(list);
      setCalc((c) => ({ ...c, etfId: c.etfId || list[0]?.id }));
      setGapEtfId((id) => id || list[0]?.id);
    });
  }, []);

  useEffect(() => {
    api.etfs.list(query).then(setEtfs);
  }, [query]);

  const selectedEtf = allEtfs.find((e) => e.id === calc.etfId) || allEtfs[0];
  const gapEtf = allEtfs.find((e) => e.id === gapEtfId) || allEtfs[0];

  const fv = selectedEtf ? futureValue(calc.monthly, selectedEtf.ret, calc.years) : 0;
  const invested = calc.monthly * 12 * calc.years;
  const monthlyPension = (fv * 0.04) / 12;

  const bestReturn = useMemo(() => allEtfs.reduce((a, b) => (b.ret > (a?.ret ?? -Infinity) ? b : a), null), [allEtfs]);
  const safest = useMemo(() => allEtfs.reduce((a, b) => (b.riskScore < (a?.riskScore ?? Infinity) ? b : a), null), [allEtfs]);
  const cheapest = useMemo(() => allEtfs.reduce((a, b) => (b.ter < (a?.ter ?? Infinity) ? b : a), null), [allEtfs]);

  const toggleCompare = (id) => {
    setCompareIds((ids) => (ids.includes(id) ? ids.filter((x) => x !== id) : ids.length < 3 ? [...ids, id] : ids));
  };

  const gapMonthly = gapEtf ? requiredMonthly(pensionGoal * 300, gapEtf.ret, gapYears) : 0;

  return (
    <div>
      <h1 style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1, margin: "0 0 6px" }}>↗ ETF-Explorer & Rechner</h1>
      <p style={{ color: T.textDim, margin: "0 0 24px" }}>Was könnte aus deinem gekündigten Abo werden?</p>

      {bestReturn && (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 12, marginBottom: 24 }}>
          <div style={{ ...S.card, padding: 16 }}>
            <div style={{ fontSize: 12, color: T.textDim }}>Höchste Rendite (hist.)</div>
            <div style={{ fontWeight: 650, marginTop: 4 }}>{bestReturn.name}</div>
            <div style={{ color: T.green, fontWeight: 700 }}>{bestReturn.ret}% p.a.*</div>
          </div>
          <div style={{ ...S.card, padding: 16 }}>
            <div style={{ fontSize: 12, color: T.textDim }}>Sicherster</div>
            <div style={{ fontWeight: 650, marginTop: 4 }}>{safest.name}</div>
            <div style={{ color: T.teal, fontWeight: 700 }}>Risiko: {safest.risk}</div>
          </div>
          <div style={{ ...S.card, padding: 16 }}>
            <div style={{ fontSize: 12, color: T.textDim }}>Günstigste TER</div>
            <div style={{ fontWeight: 650, marginTop: 4 }}>{cheapest.name}</div>
            <div style={{ color: T.purple, fontWeight: 700 }}>{cheapest.ter}%</div>
          </div>
        </div>
      )}

      <input style={{ ...S.input, maxWidth: 320, marginBottom: 16 }} placeholder="🔍 ETF suchen (z.B. World, Tech, Dividende)…" value={query} onChange={(e) => setQuery(e.target.value)} />

      <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: 20, maxWidth: 780 }}>
        <div style={S.card}>
          <label style={{ fontSize: 13.5, color: T.textDim }}>Monatlicher Betrag (z. B. dein gekündigtes Abo)</label>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 8 }}>
            <input type="range" min="5" max="300" step="0.01" value={calc.monthly} onChange={(e) => setCalc({ ...calc, monthly: +e.target.value })} style={{ flex: 1, accentColor: T.green }} />
            <div style={{ fontSize: 24, fontWeight: 700, minWidth: 110, textAlign: "right" }}>{fmt(calc.monthly)}</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" }}>
            {subs.filter((s) => s.status === "switch").map((s) => (
              <button key={s.id} style={{ ...S.btnGhost, padding: "6px 12px", fontSize: 12.5 }} onClick={() => setCalc({ ...calc, monthly: s.amount })}>{s.name} ({fmt(s.amount)})</button>
            ))}
            {switchedSum > 0 && (
              <button style={{ ...S.btnGhost, padding: "6px 12px", fontSize: 12.5, color: T.green, borderColor: T.green + "55" }} onClick={() => setCalc({ ...calc, monthly: +switchedSum.toFixed(2) })}>Alle markierten ({fmt(switchedSum)})</button>
            )}
          </div>

          <label style={{ fontSize: 13.5, color: T.textDim, display: "block", marginTop: 22 }}>Anlagedauer: <b style={{ color: T.text }}>{calc.years} Jahre</b></label>
          <input type="range" min="1" max="50" value={calc.years} onChange={(e) => setCalc({ ...calc, years: +e.target.value })} style={{ width: "100%", accentColor: T.teal, marginTop: 8 }} />

          <label style={{ fontSize: 13.5, color: T.textDim, display: "block", marginTop: 22, marginBottom: 10 }}>ETF wählen (Klick zum Vergleichen anhaken)</label>
          <div style={{ display: "grid", gap: 8 }}>
            {etfs.map((e) => (
              <div key={e.id} style={{
                ...S.btnGhost, textAlign: "left", padding: "12px 16px", borderRadius: 14,
                borderColor: calc.etfId === e.id ? T.green : T.border, background: calc.etfId === e.id ? "rgba(48,209,88,0.08)" : "transparent",
                display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, flexWrap: "wrap", cursor: "pointer",
              }} onClick={() => setCalc({ ...calc, etfId: e.id })}>
                <span>
                  <span style={{ fontWeight: 600, fontSize: 14.5 }}>{e.name}</span>
                  {e.tags.map((t) => <span key={t} style={{ ...S.tag(T.teal), marginLeft: 8, fontSize: 11 }}>{t}</span>)}
                  <div style={{ fontSize: 12.5, color: T.textDim, marginTop: 3 }}>{e.desc} · Risiko: {e.risk} · TER {e.ter}%</div>
                </span>
                <span style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span style={{ fontWeight: 700, color: T.green }}>{e.ret}% p.a.*</span>
                  <button
                    onClick={(ev) => { ev.stopPropagation(); toggleCompare(e.id); }}
                    style={{ ...S.btnGhost, padding: "4px 10px", fontSize: 11, color: compareIds.includes(e.id) ? T.purple : T.textFaint, borderColor: compareIds.includes(e.id) ? T.purple : T.border }}
                  >{compareIds.includes(e.id) ? "✓ Vergleich" : "+ Vergleich"}</button>
                </span>
              </div>
            ))}
            {etfs.length === 0 && <div style={{ color: T.textDim, fontSize: 13.5 }}>Keine ETFs gefunden.</div>}
          </div>
        </div>

        <div style={{ ...S.card, background: "linear-gradient(135deg, rgba(48,209,88,0.10), rgba(100,210,255,0.06))" }}>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 16, marginBottom: 20 }}>
            <div><div style={{ fontSize: 13, color: T.textDim }}>Eingezahlt</div><div style={{ fontSize: 24, fontWeight: 700 }}>{fmt(invested)}</div></div>
            <div><div style={{ fontSize: 13, color: T.textDim }}>Mögliches Vermögen*</div><div style={{ fontSize: 24, fontWeight: 700, color: T.green }}>{fmt(fv)}</div></div>
            <div><div style={{ fontSize: 13, color: T.textDim }}>Davon Zinseszins</div><div style={{ fontSize: 24, fontWeight: 700, color: T.teal }}>{fmt(fv - invested)}</div></div>
            <div><div style={{ fontSize: 13, color: T.textDim }}>Renten-Boost (4%-Regel)*</div><div style={{ fontSize: 24, fontWeight: 700, color: T.purple }}>+{fmt(monthlyPension)}/Mon.</div></div>
          </div>
          {selectedEtf && <GrowthChart monthly={calc.monthly} ret={selectedEtf.ret} years={calc.years} />}
          <p style={{ fontSize: 11.5, color: T.textFaint, marginTop: 14, lineHeight: 1.5 }}>
            *Modellrechnung mit historischen Durchschnittsrenditen. Keine Anlageberatung, keine Garantie. Renditen schwanken, Verluste sind möglich. Die 4%-Entnahmeregel ist eine Faustformel, keine Zusicherung.
          </p>
        </div>

        {compareIds.length > 0 && (
          <div style={S.card}>
            <div style={{ fontWeight: 650, marginBottom: 14 }}>ETF-Vergleich ({fmt(calc.monthly)}/Monat, {calc.years} Jahre)</div>
            <CompareChart years={calc.years} series={compareIds.map((id) => { const e = etfs.find((x) => x.id === id); return { name: e.name, monthly: calc.monthly, ret: e.ret }; })} />
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 12, marginTop: 16 }}>
              {compareIds.map((id) => {
                const e = etfs.find((x) => x.id === id);
                return (
                  <div key={id} style={{ padding: 12, background: "rgba(255,255,255,0.03)", borderRadius: 12 }}>
                    <div style={{ fontWeight: 600, fontSize: 13.5 }}>{e.name}</div>
                    <div style={{ fontSize: 18, fontWeight: 700, color: T.green, marginTop: 4 }}>{fmt(futureValue(calc.monthly, e.ret, calc.years))}</div>
                    <div style={{ fontSize: 11.5, color: T.textFaint }}>{e.ret}% p.a. · TER {e.ter}%</div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        <div style={S.card}>
          <div style={{ fontWeight: 650, marginBottom: 6 }}>🎯 Renten-Lücken-Rechner</div>
          <p style={{ fontSize: 13, color: T.textDim, margin: "0 0 16px" }}>Wie viel musst du monatlich sparen, um eine bestimmte Rentenaufstockung zu erreichen?</p>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 16 }}>
            <div>
              <label style={{ fontSize: 13, color: T.textDim }}>Gewünschter Renten-Boost: <b style={{ color: T.text }}>{fmt(pensionGoal)}/Monat</b></label>
              <input type="range" min="10" max="2000" step="10" value={pensionGoal} onChange={(e) => setPensionGoal(+e.target.value)} style={{ width: "100%", accentColor: T.purple, marginTop: 8 }} />
            </div>
            <div>
              <label style={{ fontSize: 13, color: T.textDim }}>Anlagedauer: <b style={{ color: T.text }}>{gapYears} Jahre</b></label>
              <input type="range" min="1" max="50" value={gapYears} onChange={(e) => setGapYears(+e.target.value)} style={{ width: "100%", accentColor: T.teal, marginTop: 8 }} />
            </div>
          </div>
          <select style={{ ...S.input, marginTop: 16, maxWidth: 320 }} value={gapEtfId || ""} onChange={(e) => setGapEtfId(e.target.value)}>
            {allEtfs.map((e) => <option key={e.id} value={e.id}>{e.name} ({e.ret}% p.a.)</option>)}
          </select>
          <div style={{ marginTop: 16, padding: 16, background: "rgba(191,90,242,0.08)", borderRadius: 14 }}>
            Du müsstest ≈ <b style={{ color: T.purple, fontSize: 20 }}>{fmt(gapMonthly)}</b> monatlich investieren, um in {gapYears} Jahren einen Renten-Boost von {fmt(pensionGoal)}/Monat zu erreichen.*
          </div>
        </div>
      </div>
    </div>
  );
}
