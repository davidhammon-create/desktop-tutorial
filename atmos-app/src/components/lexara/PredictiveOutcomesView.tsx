import React, { useState } from 'react';
import { T, sans, scol } from './theme';
import { Panel, SectionTitle, Chip, Bar, BigRing } from './Primitives';
import { LexaraCase } from '@/types/lexara';
import { computeWinProbability, computeEvidenceBoost } from '@/lib/lexaraUtils';
import { RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis, ResponsiveContainer } from 'recharts';
interface Props {
  cases: LexaraCase[];
  onBack: () => void;
}
export function PredictiveOutcomesView({ cases, onBack }: Props) {
  const [selectedCase, setSelectedCase] = useState(cases[0]?.id || '');
  const c = cases.find(cs => cs.id === selectedCase);
  if (!c) return null;
  const { final, ownScore, oppScore, evBoostOwn, evBoostOpp, judgeCalib, excludeCount } = computeWinProbability(c);
  const scenarios = [
    { label: 'Best Case', probability: Math.min(95, final + 15), outcome: 'Vollsieg ? Klage stattgegeben', color: T.green },
    { label: 'Wahrscheinlich', probability: final, outcome: 'Teilsieg ? Vergleich', color: T.blue },
    { label: 'Worst Case', probability: Math.max(5, final - 20), outcome: 'Abweisung ? Gegenkosten', color: T.red },
  ];
  const radarData = [
    { factor: 'Argumentstärke', value: Math.round(ownScore / (ownScore + oppScore) * 100) },
    { factor: 'Beweisstärke', value: Math.round(evBoostOwn * 100) },
    { factor: 'Richter-Faktor', value: Math.round(50 + judgeCalib * 100) },
    { factor: 'Ausschluss', value: Math.min(100, excludeCount * 33) },
    { factor: 'Zeugenqualität', value: c.persons.filter(p => p.role === 'Zeuge').length > 0 ? 60 : 80 },
    { factor: 'Dokumentation', value: Math.min(100, Object.values(c.evidence).flat().length * 12) },
  ];
  const factors = [
    { name: 'Eigene Argumente', value: ownScore, max: ownScore + oppScore, desc: `${c.arguments.filter(a => a.side === 'own').length} Argumente` },
    { name: 'Gegnerische Argumente', value: oppScore, max: ownScore + oppScore, desc: `${c.arguments.filter(a => a.side === 'opp').length} Argumente` },
    { name: 'Evidenz-Boost Eigen', value: evBoostOwn * 100, max: 100, desc: 'Beweisstärke gewichtet' },
    { name: 'Evidenz-Boost Gegner', value: evBoostOpp * 100, max: 100, desc: 'Gegner-Beweislage' },
  ];
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      <div style={{ background: T.surface, borderBottom: `1px solid ${T.border}`, padding: '14px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <button onClick={onBack} style={{ fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.blue, background: 'none', border: 'none', cursor: 'pointer' }}>? Dashboard</button>
          <div>
            <div style={{ fontSize: 22, fontWeight: 700 }}>Predictive Case Outcomes</div>
            <div style={{ fontSize: 13, color: T.dim }}>ML-basierte Erfolgsprognosen</div>
          </div>
        </div>
        {/* Case selector */}
        <select value={selectedCase} onChange={e => setSelectedCase(e.target.value)} style={{
          fontFamily: sans, fontSize: 14, padding: '8px 14px', borderRadius: 10,
          border: `1px solid ${T.border}`, background: T.surface, color: T.text,
        }}>
          {cases.map(cs => <option key={cs.id} value={cs.id}>{cs.name}</option>)}
        </select>
      </div>
      <div style={{ padding: 24, maxWidth: 1400, margin: '0 auto' }}>
        {/* Top: Ring + Scenarios */}
        <div style={{ display: 'grid', gridTemplateColumns: '300px 1fr', gap: 24, marginBottom: 28 }}>
          <Panel style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <BigRing score={final} size={160} />
            <div style={{ fontSize: 18, fontWeight: 700, marginTop: 12, color: scol(final) }}>
              {final >= 65 ? 'Hohe Erfolgsaussicht' : final >= 40 ? 'Moderate Aussicht' : 'Niedrige Aussicht'}
            </div>
            <div style={{ fontSize: 13, color: T.dim, marginTop: 4 }}>Gesamtprognose</div>
          </Panel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {scenarios.map(s => (
              <Panel key={s.label} style={{ borderLeft: `4px solid ${s.color}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: 16, fontWeight: 600 }}>{s.label}</div>
                    <div style={{ fontSize: 13, color: T.dim }}>{s.outcome}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 28, fontWeight: 700, color: s.color }}>{s.probability}%</div>
                    <Bar v={s.probability} max={100} color={s.color} h={4} />
                  </div>
                </div>
              </Panel>
            ))}
          </div>
        </div>
        {/* Radar + Factors */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
          <Panel>
            <SectionTitle icon="?">Faktor-Radar</SectionTitle>
            <ResponsiveContainer width="100%" height={300}>
              <RadarChart data={radarData}>
                <PolarGrid stroke={T.muted} />
                <PolarAngleAxis dataKey="factor" tick={{ fontSize: 11, fill: T.dim }} />
                <PolarRadiusAxis angle={30} domain={[0, 100]} tick={{ fontSize: 10, fill: T.dim }} />
                <Radar dataKey="value" stroke={T.blue} fill={T.blue} fillOpacity={0.2} strokeWidth={2} />
              </RadarChart>
            </ResponsiveContainer>
          </Panel>
          <Panel>
            <SectionTitle icon="?">Einflussfaktoren</SectionTitle>
            {factors.map(f => (
              <div key={f.name} style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontSize: 14, fontWeight: 500 }}>{f.name}</span>
                  <span style={{ fontSize: 14, fontWeight: 600, color: scol(f.value / f.max * 100) }}>
                    {f.value.toFixed(1)}
                  </span>
                </div>
                <Bar v={f.value} max={f.max} color={scol(f.value / f.max * 100)} h={6} />
                <div style={{ fontSize: 12, color: T.dim, marginTop: 4 }}>{f.desc}</div>
              </div>
            ))}
          </Panel>
        </div>
      </div>
    </div>
  );
}
