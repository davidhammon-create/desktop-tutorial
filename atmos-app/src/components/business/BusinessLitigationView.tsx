import React, { useMemo } from 'react';
import { BusinessScenario, OptionCosts } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, SectionTitle, Chip, Bar, BigRing } from '@/components/lexara/Primitives';
import { scol } from '@/components/lexara/theme';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
export function BusinessLitigationView({ scenario, onUpdate }: Props) {
  const options = scenario.options || [];

  // Derive litigation analysis from scenario data
  const analysis = useMemo(() => {
    const proArgs = options.flatMap(o => (o.arguments || []).filter(a => a.side === 'pro').map(a => ({ ...a, option: o.label })));
    const conArgs = options.flatMap(o => (o.arguments || []).filter(a => a.side === 'contra').map(a => ({ ...a, option: o.label })));

    const totalPro = proArgs.reduce((s, a) => s + (a.weight || 5), 0);
    const totalCon = conArgs.reduce((s, a) => s + (a.weight || 5), 0);
    const total = totalPro + totalCon;
    const successPct = total > 0 ? Math.round((totalPro / total) * 100) : 50;
    const costOf = (c: OptionCosts) => c.anwaltskosten + c.gerichtskosten + c.interneKosten + c.opportunitaetskosten;
    const avgCost = options.length > 0
      ? options.reduce((s, o) => s + costOf(o.costs), 0) / options.length
      : 0;
    const avgRevenue = options.length > 0
      ? options.reduce((s, o) => s + (o.risk?.bestCase || 0), 0) / options.length
      : 0;
    // Monte Carlo (simplified)
    const results: number[] = [];
    for (let i = 0; i < 1000; i++) {
      const p = Math.min(1, Math.max(0, successPct / 100 + (Math.random() - 0.5) * 0.3));
      results.push(Math.random() < p ? avgRevenue - avgCost : -avgCost);
    }
    results.sort((a, b) => a - b);
    const ew = Math.round(results.reduce((s, v) => s + v, 0) / results.length);
    const var95 = Math.round(results[Math.floor(results.length * 0.05)]);
    // Risk priorities
    const risks = conArgs.sort((a: any, b: any) => (b.weight || 5) - (a.weight || 5)).slice(0, 5);
    const strengths = proArgs.sort((a: any, b: any) => (b.weight || 5) - (a.weight || 5)).slice(0, 5);
    return { successPct, ew, var95, avgCost, avgRevenue, risks, strengths, proArgs, conArgs };
  }, [options]);
  const fmt = (n: number) => n.toLocaleString('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 });
  return (
    <div style={{ padding: '24px 40px', maxWidth: 1100, margin: '0 auto' }}>
      <Panel style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 20 }}>
        <BigRing score={analysis.successPct} size={90} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Litigation-Risiko-Analyse
          </div>
          <div style={{ fontSize: 20, fontWeight: 700, marginTop: 2 }}>Prozessrisiko & Strategie</div>
          <div style={{ fontSize: 13, color: T.dim, marginTop: 4 }}>
            Algorithmische Analyse: Erwartungswert, VaR, Prioritäten
          </div>
        </div>
      </Panel>
      {/* Key Metrics */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
        {[
          ['Erfolgswahrscheinl.', `${analysis.successPct}%`, scol(analysis.successPct)],
          ['Erwartungswert', fmt(analysis.ew), analysis.ew >= 0 ? T.green : '#ff3b30'],
          ['VaR 95%', fmt(analysis.var95), '#ff9500'],
          ['? Kosten', fmt(analysis.avgCost), T.dim],
        ].map(([label, val, col]) => (
          <Panel key={label as string} style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: T.dim }}>{label}</div>
            <div style={{ fontSize: 20, fontWeight: 700, color: col as string }}>{val}</div>
          </Panel>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 20 }}>
        {/* Risks */}
        <div>
          <SectionTitle icon="??">Top-Risiken</SectionTitle>
          {analysis.risks.length > 0 ? analysis.risks.map((r: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8, borderLeft: '3px solid #ff3b30' }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{r.text || r.label || `Risiko ${i + 1}`}</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
                <Chip small color="#ff3b30">Gewicht: {r.weight || 5}/10</Chip>
                {r.option && <Chip small>{r.option}</Chip>}
              </div>
            </Panel>
          )) : <Panel><div style={{ fontSize: 13, color: T.dim }}>Keine Contra-Argumente erfasst. Argumente-Schritt ausfüllen.</div></Panel>}
        </div>
        {/* Strengths */}
        <div>
          <SectionTitle icon="?">Top-Stärken</SectionTitle>
          {analysis.strengths.length > 0 ? analysis.strengths.map((s: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8, borderLeft: `3px solid ${T.green}` }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{s.text || s.label || `Stärke ${i + 1}`}</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
                <Chip small color={T.green}>Gewicht: {s.weight || 5}/10</Chip>
                {s.option && <Chip small>{s.option}</Chip>}
              </div>
            </Panel>
          )) : <Panel><div style={{ fontSize: 13, color: T.dim }}>Keine Pro-Argumente erfasst.</div></Panel>}
        </div>
      </div>
      {/* Empfehlung */}
      <Panel style={{ background: analysis.successPct >= 60 ? T.green + '08' : analysis.successPct >= 35 ? '#ff950008' : '#ff3b3008' }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 6 }}>
          {analysis.successPct >= 60 ? '?? Durchsetzung empfohlen' : analysis.successPct >= 35 ? '? Vergleich/Verhandlung anstreben' : '? Rückzug evaluieren'}
        </div>
        <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.6 }}>
          Erwartungswert {fmt(analysis.ew)}. {analysis.proArgs.length} Pro-Argumente vs. {analysis.conArgs.length} Contra-Argumente.
          {analysis.ew > 0 ? ' Positive Renditeerwartung bei Durchsetzung.' : ' Negative Renditeerwartung ? Kosten übersteigen erwarteten Nutzen.'}
        </div>
      </Panel>
    </div>
  );
}
