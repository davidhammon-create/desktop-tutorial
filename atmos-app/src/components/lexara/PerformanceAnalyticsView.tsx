import React, { useState } from 'react';
import { T, sans, scol } from './theme';
import { Panel, SectionTitle, Chip, Bar } from './Primitives';
import { LexaraCase } from '@/types/lexara';
import { computeWinProbability } from '@/lib/lexaraUtils';
import { BarChart, Bar as RBar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
interface Props {
  cases: LexaraCase[];
  onBack: () => void;
}
export function PerformanceAnalyticsView({ cases, onBack }: Props) {
  const caseData = cases.map(c => {
    const { final, ownScore, oppScore } = computeWinProbability(c);
    return { ...c, prognosis: final, ownScore, oppScore };
  });
  const avgPrognosis = Math.round(caseData.reduce((s, c) => s + c.prognosis, 0) / Math.max(1, caseData.length));
  const totalArgs = caseData.reduce((s, c) => s + c.arguments.length, 0);
  const totalEvidence = caseData.reduce((s, c) => s + Object.values(c.evidence).flat().length, 0);
  const activeCases = caseData.filter(c => c.status === 'Aktiv').length;
  const chartData = caseData.map(c => ({
    name: c.name.length > 20 ? c.name.substring(0, 20) + '?' : c.name,
    prognosis: c.prognosis,
    arguments: c.arguments.length,
  }));
  const typeDistribution = caseData.reduce((acc, c) => {
    acc[c.type] = (acc[c.type] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);
  const pieData = Object.entries(typeDistribution).map(([name, value]) => ({ name, value }));
  const PIE_COLORS = [T.blue, T.orange, T.green, T.purple, T.teal];
  const kpis = [
    { label: '? Prognose', value: `${avgPrognosis}%`, color: scol(avgPrognosis) },
    { label: 'Aktive Fälle', value: activeCases.toString(), color: T.blue },
    { label: 'Argumente gesamt', value: totalArgs.toString(), color: T.purple },
    { label: 'Beweismittel', value: totalEvidence.toString(), color: T.green },
  ];
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      <div style={{ background: T.surface, borderBottom: `1px solid ${T.border}`, padding: '14px 24px', display: 'flex', alignItems: 'center', gap: 16 }}>
        <button onClick={onBack} style={{ fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.blue, background: 'none', border: 'none', cursor: 'pointer' }}>? Dashboard</button>
        <div>
          <div style={{ fontSize: 22, fontWeight: 700 }}>Performance Analytics</div>
          <div style={{ fontSize: 13, color: T.dim }}>KPIs und Fallübersicht</div>
        </div>
      </div>
      <div style={{ padding: 24, maxWidth: 1400, margin: '0 auto' }}>
        {/* KPI cards */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 28 }}>
          {kpis.map(kpi => (
            <Panel key={kpi.label}>
              <div style={{ fontSize: 13, color: T.dim, marginBottom: 4 }}>{kpi.label}</div>
              <div style={{ fontSize: 32, fontWeight: 700, color: kpi.color }}>{kpi.value}</div>
            </Panel>
          ))}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 20, marginBottom: 24 }}>
          {/* Bar chart */}
          <Panel>
            <SectionTitle icon="?">Fallprognosen im Vergleich</SectionTitle>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke={T.muted} />
                <XAxis dataKey="name" tick={{ fontSize: 11, fill: T.dim }} />
                <YAxis tick={{ fontSize: 11, fill: T.dim }} domain={[0, 100]} />
                <Tooltip contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)', fontFamily: sans }} />
                <RBar dataKey="prognosis" fill={T.blue} radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Panel>
          {/* Pie chart */}
          <Panel>
            <SectionTitle icon="?">Rechtsgebiete</SectionTitle>
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie data={pieData} cx="50%" cy="50%" innerRadius={50} outerRadius={80} dataKey="value" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                  {pieData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Panel>
        </div>
        {/* Case table */}
        <SectionTitle icon="?">Fallübersicht</SectionTitle>
        <Panel>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: sans, fontSize: 14 }}>
              <thead>
                <tr style={{ borderBottom: `2px solid ${T.muted}` }}>
                  {['Fall', 'Rechtsgebiet', 'Status', 'Argumente', 'Beweise', 'Prognose'].map(h => (
                    <th key={h} style={{ textAlign: 'left', padding: '10px 12px', fontSize: 12, fontWeight: 600, color: T.dim, textTransform: 'uppercase' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {caseData.map(c => (
                  <tr key={c.id} style={{ borderBottom: `1px solid ${T.border}` }}>
                    <td style={{ padding: '12px', fontWeight: 600 }}>{c.name}</td>
                    <td style={{ padding: '12px' }}><Chip small>{c.type}</Chip></td>
                    <td style={{ padding: '12px' }}><Chip small color={c.status === 'Aktiv' ? T.green : T.dim}>{c.status}</Chip></td>
                    <td style={{ padding: '12px' }}>{c.arguments.length}</td>
                    <td style={{ padding: '12px' }}>{Object.values(c.evidence).flat().length}</td>
                    <td style={{ padding: '12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <Bar v={c.prognosis} max={100} color={scol(c.prognosis)} h={6} />
                        <span style={{ fontWeight: 700, color: scol(c.prognosis), minWidth: 36 }}>{c.prognosis}%</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      </div>
    </div>
  );
}
