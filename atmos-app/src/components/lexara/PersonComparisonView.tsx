import React from 'react';
import { LexaraPerson } from '@/types/lexara';
import { computeCredibility, computeMachiavelliRisk, computeDarkEmpathScore, classifyPersonality } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Bar, Panel, SectionTitle } from './Primitives';
interface PersonComparisonViewProps {
  persons: LexaraPerson[];
  onClose: () => void;
}
const DIMENSIONS = [
  { key: 'narcissism', label: 'Narzissmus', invert: true },
  { key: 'manipulationSkill', label: 'Manipulation', invert: true },
  { key: 'coldness', label: 'Kaltblütigkeit', invert: true },
  { key: 'cognitiveEmpathy', label: 'Kogn. Empathie', invert: true },
  { key: 'affectiveEmpathy', label: 'Affekt. Empathie', invert: false },
  { key: 'conflictOfInterest', label: 'Interessenkonflikt', invert: true },
  { key: 'hiddenMotive', label: 'Verb. Motiv', invert: true },
  { key: 'selfPreservation', label: 'Selbstschutz', invert: true },
  { key: 'fearFactor', label: 'Angstfaktor', invert: true },
  { key: 'loyaltySignals', label: 'Loyalität', invert: false },
  { key: 'competenceLevel', label: 'Kompetenz', invert: false },
  { key: 'historicalConsistency', label: 'Konsistenz', invert: false },
] as const;
export function PersonComparisonView({ persons, onClose }: PersonComparisonViewProps) {
  if (persons.length === 0) {
    return (
      <Panel style={{ textAlign: 'center', padding: 40 }}>
        <div style={{ fontSize: 15, color: T.dim }}>Keine Personen zum Vergleichen vorhanden.</div>
      </Panel>
    );
  }
  return (
    <div style={{ padding: 20, height: '100%', overflowY: 'auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <SectionTitle>Personen-Vergleich ? Dark Empath Profile</SectionTitle>
        <button
          onClick={onClose}
          style={{
            fontFamily: sans,
            fontSize: 13,
            fontWeight: 500,
            color: T.textSecondary,
            background: 'none',
            border: `1px solid ${T.border}`,
            borderRadius: 8,
            padding: '6px 14px',
            cursor: 'pointer',
          }}
        >
          ? Zurück
        </button>
      </div>
      {/* Summary cards */}
      <div style={{ display: 'flex', gap: 16, overflowX: 'auto', paddingBottom: 16, marginBottom: 20 }}>
        {persons.map((p) => {
          const personality = classifyPersonality(p);
          const darkScore = computeDarkEmpathScore(p);
          const cred = computeCredibility(p);
          const mach = computeMachiavelliRisk(p);
          return (
            <div
              key={p.id}
              style={{
                minWidth: 200,
                flex: '0 0 auto',
                background: T.surface,
                border: `1px solid ${T.border}`,
                borderRadius: 12,
                padding: 16,
                textAlign: 'center',
              }}
            >
              <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>{p.name}</div>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 10 }}>{p.role}{p.party ? ` ? ${p.party}` : ''}</div>
              <div style={{
                display: 'inline-block',
                fontSize: 12,
                fontWeight: 700,
                color: personality.color,
                background: `${personality.color}12`,
                padding: '3px 10px',
                borderRadius: 6,
                marginBottom: 10,
              }}>
                {personality.label}
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, fontSize: 12 }}>
                <div>
                  <div style={{ color: T.dim }}>Dark Empath</div>
                  <div style={{ fontWeight: 700, color: darkScore !== null ? scol(100 - darkScore) : T.dim }}>{darkScore ?? '?'}%</div>
                </div>
                <div>
                  <div style={{ color: T.dim }}>Glaubw.</div>
                  <div style={{ fontWeight: 700, color: cred !== null ? scol(cred) : T.dim }}>{cred ?? '?'}%</div>
                </div>
                <div>
                  <div style={{ color: T.dim }}>Mach.-Risiko</div>
                  <div style={{ fontWeight: 700, color: mach !== null ? scol(100 - mach) : T.dim }}>{mach ?? '?'}%</div>
                </div>
                <div>
                  <div style={{ color: T.dim }}>Fälle</div>
                  <div style={{ fontWeight: 700 }}>{p.historicalCases}</div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      {/* Dimension comparison table */}
      <Panel>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 16 }}>Dimensionsvergleich</div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: sans, fontSize: 13 }}>
            <thead>
              <tr>
                <th style={{ textAlign: 'left', padding: '8px 12px', borderBottom: `1px solid ${T.muted}`, color: T.dim, fontWeight: 600, fontSize: 12 }}>
                  Dimension
                </th>
                {persons.map((p) => (
                  <th key={p.id} style={{ textAlign: 'center', padding: '8px 12px', borderBottom: `1px solid ${T.muted}`, fontWeight: 600, fontSize: 12, minWidth: 120 }}>
                    {p.name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {/* Computed scores row */}
              {[
                { label: 'Dark-Empath-Score', fn: (p: LexaraPerson) => computeDarkEmpathScore(p), invert: true },
                { label: 'Glaubwürdigkeit', fn: (p: LexaraPerson) => computeCredibility(p), invert: false },
                { label: 'Mach.-Risiko', fn: (p: LexaraPerson) => computeMachiavelliRisk(p), invert: true },
              ].map((row) => (
                <tr key={row.label} style={{ background: T.bg }}>
                  <td style={{ padding: '8px 12px', fontWeight: 700, borderBottom: `1px solid ${T.border}` }}>{row.label}</td>
                  {persons.map((p) => {
                    const v = row.fn(p);
                    const color = v !== null ? scol(row.invert ? 100 - v : v) : T.dim;
                    return (
                      <td key={p.id} style={{ padding: '8px 12px', textAlign: 'center', borderBottom: `1px solid ${T.border}` }}>
                        <span style={{ fontWeight: 700, color }}>{v !== null ? `${v}%` : '?'}</span>
                      </td>
                    );
                  })}
                </tr>
              ))}
              {/* Raw dimensions */}
              {DIMENSIONS.map((dim) => (
                <tr key={dim.key}>
                  <td style={{ padding: '8px 12px', color: T.textSecondary, borderBottom: `1px solid ${T.border}` }}>{dim.label}</td>
                  {persons.map((p) => {
                    const v = (p as any)[dim.key] as number ?? 0;
                    const color = scol(dim.invert ? 100 - v : v);
                    return (
                      <td key={p.id} style={{ padding: '8px 12px', borderBottom: `1px solid ${T.border}` }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center' }}>
                          <div style={{ flex: 1, maxWidth: 80 }}><Bar v={v} max={100} color={color} h={4} /></div>
                          <span style={{ fontSize: 12, fontWeight: 600, color, minWidth: 24, textAlign: 'right' }}>{v}</span>
                        </div>
                      </td>
                    );
                  })}
                </tr>
              ))}
              {/* Personality type row */}
              <tr style={{ background: T.bg }}>
                <td style={{ padding: '8px 12px', fontWeight: 700 }}>Persönlichkeitstyp</td>
                {persons.map((p) => {
                  const personality = classifyPersonality(p);
                  return (
                    <td key={p.id} style={{ padding: '8px 12px', textAlign: 'center' }}>
                      <span style={{
                        fontSize: 12,
                        fontWeight: 700,
                        color: personality.color,
                        background: `${personality.color}12`,
                        padding: '3px 10px',
                        borderRadius: 6,
                      }}>
                        {personality.label}
                      </span>
                    </td>
                  );
                })}
              </tr>
            </tbody>
          </table>
        </div>
      </Panel>
    </div>
  );
}
