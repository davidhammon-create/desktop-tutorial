import React, { useState } from 'react';
import {
  BusinessScenario, totalCosts, expectedValue, argumentScore,
  breakEvenProbability, nettoRisiko, valueAtRisk,
} from '@/types/business';
import {
  riskAdjustedValue, downsideRisk, sharpeRatio, kellyKriterium,
  qualitativeScore, weightedScore, ComparisonWeights, DEFAULT_COMPARISON_WEIGHTS,
} from '@/types/businessFormulas';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label, Bar } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
}
function fmt(n: number): string {
  return n.toLocaleString('de-DE', { maximumFractionDigits: 0 });
}
export function ScenarioComparisonStep({ scenario }: Props) {
  const opts = scenario.options;
  const [weights, setWeights] = useState<ComparisonWeights>(DEFAULT_COMPARISON_WEIGHTS);
  const [diskontRate] = useState(5);
  if (opts.length < 2) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: T.dim }}>
        <div style={{ fontSize: 15 }}>Mindestens 2 Optionen nötig für den Vergleich</div>
      </div>
    );
  }
  const metrics = opts.map(o => ({
    option: o,
    ev: expectedValue(o),
    rav: riskAdjustedValue(o, diskontRate / 100),
    downside: downsideRisk(o),
    var95: valueAtRisk(o).var95,
    sharpe: sharpeRatio(o),
    kelly: kellyKriterium(o),
    breakEven: breakEvenProbability(o),
    nettoRisk: nettoRisiko(o),
    qualiScore: qualitativeScore(o),
    argScore: argumentScore(o.arguments),
    costs: totalCosts(o.costs),
    duration: o.timeframe.maxMonths,
    wScore: weightedScore(o, opts, weights, diskontRate / 100),
  }));
  const ranked = [...metrics].sort((a, b) => b.wScore - a.wScore);
  const bestId = ranked[0]?.option.id;
  const maxCost = Math.max(...metrics.map(m => m.costs), 1);
  const maxEv = Math.max(...metrics.map(m => Math.abs(m.ev)), 1);
  const updateWeight = (key: keyof ComparisonWeights, val: number) => {
    const newWeights = { ...weights, [key]: val / 100 };
    const sum = Object.values(newWeights).reduce((s, v) => s + v, 0);
    if (sum > 0) {
      Object.keys(newWeights).forEach(k => {
        (newWeights as any)[k] = (newWeights as any)[k] / sum;
      });
    }
    setWeights(newWeights);
  };
  return (
    <div style={{ padding: 24 }}>
      {/* Master Comparison Table */}
      <Panel style={{ overflowX: 'auto', marginBottom: 24 }}>
        <Label>Master-Vergleichstabelle</Label>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: sans, fontSize: 13 }}>
          <thead>
            <tr style={{ borderBottom: `2px solid ${T.border}` }}>
              <th style={{ textAlign: 'left', padding: '10px 12px', color: T.dim, fontWeight: 600 }}>Kriterium</th>
              {metrics.map((m, i) => (
                <th key={m.option.id} style={{ textAlign: 'right', padding: '10px 12px', fontWeight: 600 }}>
                  <span style={{
                    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                    width: 22, height: 22, borderRadius: '50%',
                    background: m.option.id === bestId ? T.green : T.blue,
                    color: '#fff', fontSize: 11, fontWeight: 700, marginRight: 6,
                  }}>{String.fromCharCode(65 + i)}</span>
                  {m.option.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {[
              { label: 'Gesamtkosten', values: metrics.map(m => fmt(m.costs) + ' €') },
              { label: 'Erwartungswert', values: metrics.map(m => (m.ev >= 0 ? '+' : '') + fmt(m.ev) + ' €'), colors: metrics.map(m => m.ev >= 0 ? T.green : T.red) },
              { label: 'Risikoadj. Wert', values: metrics.map(m => (m.rav >= 0 ? '+' : '') + fmt(m.rav) + ' €'), colors: metrics.map(m => m.rav >= 0 ? T.green : T.red) },
              { label: 'Downside Risk', values: metrics.map(m => fmt(m.downside) + ' €'), colors: metrics.map(() => T.red) },
              { label: 'VaR 95%', values: metrics.map(m => fmt(m.var95) + ' €') },
              { label: 'Sharpe Ratio', values: metrics.map(m => m.sharpe.toFixed(2)), colors: metrics.map(m => m.sharpe >= 1 ? T.green : m.sharpe >= 0.5 ? T.orange : T.red) },
              { label: 'Kelly-Anteil', values: metrics.map(m => (m.kelly * 100).toFixed(0) + '%'), colors: metrics.map(() => T.purple) },
              { label: 'Break-Even', values: metrics.map(m => m.breakEven.toFixed(0) + '%') },
              { label: 'Erfolgswahrsch.', values: metrics.map(m => m.option.risk.erfolgswahrscheinlichkeit + '%') },
              { label: 'Dauer', values: metrics.map(m => `${m.option.timeframe.minMonths}?${m.duration} Mon.`) },
              { label: 'Quali-Score', values: metrics.map(m => m.qualiScore.toFixed(1) + '/10') },
              { label: 'Arg.-Score', values: metrics.map(m => (m.argScore.net >= 0 ? '+' : '') + m.argScore.net.toFixed(1)), colors: metrics.map(m => m.argScore.net >= 0 ? T.green : T.red) },
            ].map((row, ri) => (
              <tr key={row.label} style={{ borderBottom: `1px solid ${T.border}` }}>
                <td style={{ padding: '10px 12px', color: T.dim, fontSize: 12 }}>{row.label}</td>
                {row.values.map((v, i) => (
                  <td key={i} style={{
                    padding: '10px 12px', textAlign: 'right', fontWeight: 500,
                    color: (row as any).colors ? (row as any).colors[i] : T.text,
                  }}>{v}</td>
                ))}
              </tr>
            ))}
            <tr style={{ borderTop: `2px solid ${T.blue}`, background: T.blue + '06' }}>
              <td style={{ padding: '12px', fontWeight: 700, color: T.blue }}>Gesamt-Score</td>
              {metrics.map(m => (
                <td key={m.option.id} style={{
                  padding: '12px', textAlign: 'right', fontWeight: 700, fontSize: 16,
                  color: m.option.id === bestId ? T.green : T.text,
                }}>
                  {m.wScore.toFixed(2)}
                  {m.option.id === bestId && ' ?'}
                </td>
              ))}
            </tr>
          </tbody>
        </table>
      </Panel>
      {/* Gewichtung */}
      <Panel style={{ marginBottom: 24 }}>
        <Label>Gewichtung anpassen</Label>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>
          Passen Sie die Prioritäten an Ihre Unternehmensstrategie an. Die Werte normalisieren sich automatisch.
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
          {([
            { key: 'erwartungswert' as const, label: 'Erwartungswert' },
            { key: 'risiko' as const, label: 'Risiko (niedrig)' },
            { key: 'geschwindigkeit' as const, label: 'Geschwindigkeit' },
            { key: 'qualitativ' as const, label: 'Qualitativ' },
          ]).map(({ key, label }) => (
            <div key={key}>
              <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>{label}</div>
              <input type="range" min={0} max={100} value={Math.round(weights[key] * 100)}
                onChange={e => updateWeight(key, Number(e.target.value))}
                style={{ width: '100%', accentColor: T.blue }} />
              <div style={{ fontSize: 13, fontWeight: 600, textAlign: 'center', color: T.text }}>
                {Math.round(weights[key] * 100)}%
              </div>
            </div>
          ))}
        </div>
      </Panel>
      {/* Visual Bars */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <Panel>
          <Label>Kostenvergleich</Label>
          {opts.map((o, i) => (
            <div key={o.id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                <span style={{ fontWeight: 500 }}>{String.fromCharCode(65 + i)}: {o.label}</span>
                <span style={{ color: T.dim }}>{totalCosts(o.costs).toLocaleString('de-DE')} €</span>
              </div>
              <Bar v={totalCosts(o.costs)} max={maxCost} color={T.red} h={8} />
            </div>
          ))}
        </Panel>
        <Panel>
          <Label>Netto-Erwartungswert</Label>
          {metrics.map((m, i) => (
            <div key={m.option.id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                <span style={{ fontWeight: 500 }}>{String.fromCharCode(65 + i)}: {m.option.label}</span>
                <span style={{ color: m.ev >= 0 ? T.green : T.red, fontWeight: 600 }}>
                  {m.ev >= 0 ? '+' : ''}{fmt(m.ev)} €
                </span>
              </div>
              <Bar v={Math.max(0, m.ev)} max={maxEv} color={m.ev >= 0 ? T.green : T.red} h={8} />
            </div>
          ))}
        </Panel>
        <Panel>
          <Label>Sharpe Ratio (Rendite/Risiko)</Label>
          {metrics.map((m, i) => (
            <div key={m.option.id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                <span style={{ fontWeight: 500 }}>{String.fromCharCode(65 + i)}: {m.option.label}</span>
                <span style={{ color: m.sharpe >= 1 ? T.green : T.red, fontWeight: 600 }}>{m.sharpe.toFixed(2)}</span>
              </div>
              <Bar v={Math.max(0, m.sharpe)} max={Math.max(...metrics.map(x => Math.abs(x.sharpe)), 1)} color={m.sharpe >= 1 ? T.green : T.orange} h={8} />
            </div>
          ))}
        </Panel>
        <Panel>
          <Label>Gewichteter Gesamt-Score</Label>
          {ranked.map((m, i) => (
            <div key={m.option.id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                <span style={{ fontWeight: m.option.id === bestId ? 700 : 500 }}>
                  #{i + 1} {m.option.label}
                  {m.option.id === bestId && <span style={{ color: T.green, marginLeft: 4 }}>GEWINNER</span>}
                </span>
                <span style={{ fontWeight: 700, color: m.option.id === bestId ? T.green : T.text }}>{m.wScore.toFixed(2)}</span>
              </div>
              <Bar v={Math.max(0, m.wScore)} max={Math.max(...ranked.map(x => x.wScore), 0.01)} color={m.option.id === bestId ? T.green : T.blue} h={10} />
            </div>
          ))}
        </Panel>
      </div>
    </div>
  );
}
