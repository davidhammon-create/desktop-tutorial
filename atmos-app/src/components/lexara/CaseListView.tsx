import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LexaraCase } from '@/types/lexara';
import { computeWinProbability } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Chip, Bar, Panel, ScoreRing } from './Primitives';
import { CaseFormDialog } from './CaseFormDialog';
import { useAuth } from '@/hooks/useAuth';
interface Props {
  cases: LexaraCase[];
  onSelect: (id: string) => void;
  onAddCase: (data: Partial<LexaraCase>) => void;
  onUpdateCase: (updated: LexaraCase) => void;
  onDeleteCase: (id: string) => void;
}
export function CaseListView({ cases, onSelect, onAddCase, onUpdateCase, onDeleteCase }: Props) {
  const [showCaseForm, setShowCaseForm] = useState(false);
  const [editingCase, setEditingCase] = useState<LexaraCase | null>(null);
  const [search, setSearch] = useState('');
  const { signOut, user } = useAuth();
  const navigate = useNavigate();
  const filtered = cases.filter(c =>
    !search || c.name.toLowerCase().includes(search.toLowerCase()) || c.number.toLowerCase().includes(search.toLowerCase())
  );
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Header */}
      <div style={{
        background: '#1d1d1f', padding: '14px 24px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ display: 'flex', gap: 6 }}>
            <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f57' }} />
            <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e' }} />
            <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#28c840' }} />
          </div>
          <button onClick={() => navigate('/')} style={{
            fontFamily: sans, fontSize: 12, color: '#86868b', background: 'rgba(255,255,255,0.08)',
            border: 'none', borderRadius: 6, padding: '4px 10px', cursor: 'pointer', marginRight: 4,
          }}>? Home</button>
          <span style={{ color: '#fff', fontSize: 17, fontWeight: 700, letterSpacing: '-0.01em' }}>MachiavelLEX</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 12, color: '#86868b', maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {user?.email}
          </span>
          <button onClick={signOut} style={{
            fontSize: 12, fontFamily: sans, color: '#ff5f57', background: 'rgba(255,95,87,0.15)',
            border: 'none', borderRadius: 8, padding: '5px 12px', cursor: 'pointer',
          }}>Abmelden</button>
        </div>
      </div>
      <div style={{ padding: '28px 32px', maxWidth: 1200, margin: '0 auto' }}>
        {/* Title + actions */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <div>
            <h1 style={{ fontSize: 28, fontWeight: 700, margin: 0 }}>Fallübersicht</h1>
            <div style={{ fontSize: 13, color: T.dim, marginTop: 4 }}>{cases.length} Fälle ? Wähle einen Fall oder erstelle einen neuen</div>
          </div>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <div style={{ position: 'relative' }}>
              <input
                value={search}
                onChange={e => setSearch(e.target.value)}
                placeholder="Fall suchen..."
                style={{
                  fontFamily: sans, fontSize: 14, padding: '8px 14px 8px 34px',
                  border: `1px solid ${T.border}`, borderRadius: 10, background: T.surface,
                  outline: 'none', width: 220, color: T.text,
                }}
              />
              <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', fontSize: 14, color: T.dim }}>?</span>
            </div>
            <button onClick={() => { setEditingCase(null); setShowCaseForm(true); }} style={{
              fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff', background: T.blue,
              border: 'none', borderRadius: 12, padding: '10px 20px', cursor: 'pointer',
            }}>
              + Neuer Fall
            </button>
          </div>
        </div>
        {/* Cases grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: 16 }}>
          {filtered.map(c => {
            const { final, ownScore, oppScore } = computeWinProbability(c);
            const col = scol(final);
            const pendingFristen = (c.fristen || []).filter(f => f.status === 'offen').length;
            // Progress: 9 steps, check which have content
            const steps = [
              !!(c.name && c.court),          // 1 Basisdaten
              c.arguments.length > 0,          // 2 Argumente
              Object.values(c.evidence).flat().length > 0, // 3 Beweise
              c.edges.length > 0,              // 4 Verkettung
              c.persons.length > 0,            // 5 Personen
              (c.fristen || []).length > 0,     // 6 Fristen
              c.arguments.length >= 2 && c.edges.length >= 1, // 7 Strategie
              c.arguments.length >= 3,         // 8 KI-Berater
              !!(c.kosten?.streitwert),        // 9 Analyse
            ];
            const done = steps.filter(Boolean).length;
            const pct = Math.round((done / 9) * 100);
            return (
              <Panel key={c.id} onClick={() => onSelect(c.id)} style={{
                cursor: 'pointer', transition: 'transform 0.15s, box-shadow 0.15s', position: 'relative',
              }}
              >
                <div
                  onMouseEnter={e => { const p = e.currentTarget.parentElement!; p.style.transform = 'translateY(-2px)'; p.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)'; }}
                  onMouseLeave={e => { const p = e.currentTarget.parentElement!; p.style.transform = ''; p.style.boxShadow = ''; }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, color: T.dim, marginBottom: 2 }}>{c.number}</div>
                      <div style={{ fontSize: 18, fontWeight: 600, marginBottom: 8 }}>{c.name}</div>
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        <Chip small>{c.type}</Chip>
                        <Chip small color={c.status === 'Aktiv' ? T.green : T.dim}>{c.status}</Chip>
                        {c.instanz && <Chip small color={T.purple}>{c.instanz}</Chip>}
                        {pendingFristen > 0 && <Chip small color={T.orange}>? {pendingFristen}</Chip>}
                      </div>
                    </div>
                    <ScoreRing score={final} size={52} />
                  </div>
                  {/* Progress bar */}
                  <div style={{ marginBottom: 10 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                      <span style={{ fontSize: 11, fontWeight: 600, color: T.dim }}>Fortschritt</span>
                      <span style={{ fontSize: 11, fontWeight: 700, color: pct === 100 ? T.green : pct >= 50 ? T.blue : T.orange }}>{done}/9 ? {pct}%</span>
                    </div>
                    <div style={{ height: 6, borderRadius: 3, background: T.muted, overflow: 'hidden' }}>
                      <div style={{
                        height: '100%', borderRadius: 3, transition: 'width 0.3s',
                        width: `${pct}%`,
                        background: pct === 100 ? T.green : pct >= 50 ? T.blue : T.orange,
                      }} />
                    </div>
                    <div style={{ display: 'flex', gap: 3, marginTop: 4 }}>
                      {steps.map((s, i) => (
                        <div key={i} style={{
                          flex: 1, height: 3, borderRadius: 2,
                          background: s ? (pct === 100 ? T.green : T.blue) : T.muted,
                          transition: 'background 0.2s',
                        }} title={['Basisdaten','Argumente','Beweise','Verkettung','Personen','Fristen','Strategie','KI-Berater','Analyse'][i]} />
                      ))}
                    </div>
                  </div>
                  <div style={{ marginBottom: 10 }}>
                    <Bar v={ownScore} max={ownScore + oppScore} color={T.own} h={4} />
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                      <span style={{ fontSize: 11, color: T.own }}>Eigen {ownScore.toFixed(1)}</span>
                      <span style={{ fontSize: 11, color: T.opp }}>Gegner {oppScore.toFixed(1)}</span>
                    </div>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 6 }}>
                    {([
                      ['Args', c.arguments.length],
                      ['Beweise', Object.values(c.evidence).flat().length],
                      ['Personen', c.persons.length],
                      ['Fristen', (c.fristen || []).length],
                    ] as const).map(([l, v]) => (
                      <div key={l} style={{ background: T.bg, padding: '6px 8px', borderRadius: 8, textAlign: 'center' }}>
                        <div style={{ fontSize: 10, color: T.dim }}>{l}</div>
                        <div style={{ fontSize: 16, fontWeight: 600 }}>{v}</div>
                      </div>
                    ))}
                  </div>
                </div>
                {/* Edit/delete */}
                <div style={{ position: 'absolute', top: 10, right: 10, display: 'flex', gap: 4 }}>
                  <button onClick={(e) => { e.stopPropagation(); setEditingCase(c); setShowCaseForm(true); }}
                    style={{ width: 26, height: 26, borderRadius: 7, background: T.bg, border: 'none', cursor: 'pointer', fontSize: 11, color: T.dim }}>?</button>
                  <button onClick={(e) => { e.stopPropagation(); if (confirm('Fall wirklich löschen?')) onDeleteCase(c.id); }}
                    style={{ width: 26, height: 26, borderRadius: 7, background: T.bg, border: 'none', cursor: 'pointer', fontSize: 11, color: T.red }}>?</button>
                </div>
              </Panel>
            );
          })}
          {/* New case card */}
          <Panel onClick={() => { setEditingCase(null); setShowCaseForm(true); }}
            style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 200, border: `2px dashed ${T.muted}`, boxShadow: 'none' }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 36, color: T.muted, marginBottom: 8 }}>+</div>
              <div style={{ fontSize: 14, color: T.dim }}>Neuer Fall anlegen</div>
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
