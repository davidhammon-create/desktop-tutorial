import React, { useState } from 'react';
import { LexaraCase } from '@/types/lexara';
import { computeWinProbability } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Chip, Bar, Panel } from './Primitives';
import { CaseFormDialog } from './CaseFormDialog';
interface DashboardProps {
  cases: LexaraCase[];
  onSelect: (id: string) => void;
  onAddCase: (data: Partial<LexaraCase>) => void;
  onUpdateCase: (updated: LexaraCase) => void;
  onDeleteCase: (id: string) => void;
  onBack?: () => void;
}
export function Dashboard({ cases, onSelect, onAddCase, onUpdateCase, onDeleteCase, onBack }: DashboardProps) {
  const [showCaseForm, setShowCaseForm] = useState(false);
  const [editingCase, setEditingCase] = useState<LexaraCase | null>(null);
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Header */}
      <div style={{ padding: '20px 24px', background: T.surface, borderBottom: `1px solid ${T.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          {onBack && (
            <button onClick={onBack} style={{
              fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.textSecondary, background: 'none', border: 'none',
              cursor: 'pointer', padding: 0, display: 'flex', alignItems: 'center', gap: 4,
            }}>
              ? Dashboard
            </button>
          )}
          <div>
            <div style={{ fontSize: 28, fontWeight: 700, color: T.text, letterSpacing: '-0.02em' }}>Case Management</div>
            <div style={{ fontSize: 13, color: T.dim }}>Fallübersicht & Verwaltung</div>
          </div>
        </div>
        <button onClick={() => { setEditingCase(null); setShowCaseForm(true); }} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.text,
          border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
        }}>
          + Neuer Fall
        </button>
      </div>
      {/* Cases */}
      <div style={{ padding: '24px', maxWidth: 1200, margin: '0 auto' }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.03em', marginBottom: 16 }}>
          {cases.length} Aktive Fälle
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: 16 }}>
          {cases.map(c => {
            const { final, ownScore, oppScore } = computeWinProbability(c);
            const col = scol(final);
            const judge = c.persons.find(p => p.role === 'Richter');
            return (
              <Panel key={c.id} style={{ cursor: 'pointer', transition: 'transform 0.15s, box-shadow 0.15s', position: 'relative' }}>
                <div onClick={() => onSelect(c.id)}
                  onMouseEnter={e => { e.currentTarget.parentElement!.style.transform = 'translateY(-2px)'; e.currentTarget.parentElement!.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)'; }}
                  onMouseLeave={e => { e.currentTarget.parentElement!.style.transform = ''; e.currentTarget.parentElement!.style.boxShadow = ''; }}>

                  {/* Top row */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, color: T.dim, marginBottom: 2 }}>{c.number}</div>
                      <div style={{ fontSize: 18, fontWeight: 600, color: T.text, marginBottom: 8 }}>{c.name}</div>
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        <Chip small>{c.type}</Chip>
                        <Chip small>{c.court}</Chip>
                        <Chip small color={c.status === 'Aktiv' ? T.green : T.dim}>{c.status}</Chip>
                      </div>
                    </div>
                    <div style={{ textAlign: 'center', flexShrink: 0, marginLeft: 16 }}>
                      <div style={{ fontSize: 36, fontWeight: 700, color: col, lineHeight: 1 }}>{final}%</div>
                      <div style={{ fontSize: 11, color: T.dim }}>Prognose</div>
                    </div>
                  </div>
                  {/* Score bar */}
                  <div style={{ marginBottom: 12 }}>
                    <Bar v={ownScore} max={ownScore + oppScore} color={T.text} h={3} />
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                      <span style={{ fontSize: 11, color: T.textSecondary }}>Eigen {ownScore.toFixed(1)}</span>
                      <span style={{ fontSize: 11, color: T.dim }}>Gegner {oppScore.toFixed(1)}</span>
                    </div>
                  </div>
                  {/* Stats */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
                    {([['Argumente', c.arguments.length], ['Beweise', Object.values(c.evidence).flat().length], ['Personen', c.persons.length]] as const).map(([l, v]) => (
                      <div key={l} style={{ background: T.bg, padding: '8px 10px', borderRadius: 10, textAlign: 'center' }}>
                        <div style={{ fontSize: 11, color: T.dim }}>{l}</div>
                        <div style={{ fontSize: 18, fontWeight: 600 }}>{v}</div>
                      </div>
                    ))}
                  </div>
                  {judge && (
                    <div style={{ marginTop: 10, padding: '8px 12px', background: T.bg, borderRadius: 10, fontSize: 13, color: T.textSecondary }}>
                      ?? {judge.name} ? {judge.plaintiffWinRate}% Klägerquote
                    </div>
                  )}
                </div>
                {/* Actions */}
                <div style={{ position: 'absolute', top: 12, right: 12, display: 'flex', gap: 4 }}>
                  <button onClick={(e) => { e.stopPropagation(); setEditingCase(c); setShowCaseForm(true); }}
                    style={{ width: 28, height: 28, borderRadius: 8, background: T.bg, border: 'none', cursor: 'pointer', fontSize: 12, color: T.dim }}>?</button>
                  <button onClick={(e) => { e.stopPropagation(); if (confirm('Fall wirklich löschen?')) onDeleteCase(c.id); }}
                    style={{ width: 28, height: 28, borderRadius: 8, background: T.bg, border: 'none', cursor: 'pointer', fontSize: 12, color: T.red }}>?</button>
                </div>
              </Panel>
            );
          })}
          {/* New case card */}
          <Panel style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 200, border: `2px dashed ${T.muted}`, boxShadow: 'none' }}>
            <div onClick={() => { setEditingCase(null); setShowCaseForm(true); }} style={{ textAlign: 'center', width: '100%', height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ fontSize: 36, color: T.muted, marginBottom: 8 }}>+</div>
              <div style={{ fontSize: 14, color: T.dim }}>Neuer Fall</div>
            </div>
          </Panel>
        </div>
      </div>
      <CaseFormDialog
        isOpen={showCaseForm}
        initial={editingCase}
        onClose={() => { setShowCaseForm(false); setEditingCase(null); }}
        onSave={(data) => {
          if (data.id && editingCase) {
            onUpdateCase({ ...editingCase, ...data } as LexaraCase);
          } else {
            onAddCase(data);
          }
          setShowCaseForm(false);
          setEditingCase(null);
        }}
      />
    </div>
  );
}
