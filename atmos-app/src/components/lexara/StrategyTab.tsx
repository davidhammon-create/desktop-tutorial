import React, { useState } from 'react';
import { LexaraCase, LexaraArgument, ARGUMENT_WEIGHT_TABLE } from '@/types/lexara';
import { computeWinProbability, computeCredibility, getStrategieEmpfehlung, computeFristenAbzug } from '@/lib/lexaraUtils';
import { T, sans, scol, mono } from './theme';
import { Bar, BigRing, Panel, Label, Chip, SectionTitle } from './Primitives';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
type ViewMode = 'own' | 'combined' | 'opp';
type SortMode = 'time' | 'strength' | 'manual';
function sortArgs(args: LexaraArgument[], mode: SortMode): LexaraArgument[] {
  const sorted = [...args];
  if (mode === 'manual') {
    return sorted.sort((a, b) => (a.sortOrder ?? 9999) - (b.sortOrder ?? 9999));
  }
  if (mode === 'time') {
    // Sort by timestamp, fallback to strength (as proxy for causal weight)
    return sorted.sort((a, b) => {
      const tA = a.timestamp ? new Date(a.timestamp).getTime() : null;
      const tB = b.timestamp ? new Date(b.timestamp).getTime() : null;
      if (tA && tB) return tA - tB;
      if (tA && !tB) return -1;
      if (!tA && tB) return 1;
      // Fallback: stronger arguments (more causal weight) first
      return (b.strength ?? 0) - (a.strength ?? 0);
    });
  }
  // strength
  return sorted.sort((a, b) => (b.strength ?? 0) - (a.strength ?? 0));
}
function formatTimestamp(ts?: string): string | null {
  if (!ts) return null;
  try {
    const d = new Date(ts);
    return d.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: '2-digit' }) + ' ? ' +
      d.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  } catch { return null; }
}
export function StrategyTab({ c, onUpdateCase }: { c: LexaraCase; onUpdateCase?: (updated: LexaraCase) => void }) {
  const [viewMode, setViewMode] = useState<ViewMode>('combined');
  const [showRefTable, setShowRefTable] = useState(false);
  const [sortMode, setSortMode] = useState<SortMode>('time');
  const [dragId, setDragId] = useState<string | null>(null);
  const [dragOverId, setDragOverId] = useState<string | null>(null);
  const result = computeWinProbability(c);
  const { final, ownScore, oppScore, evBoostOwn, judgeCalib, excludeCount, fristenAbzug, rawRatio } = result;
  const judge = c.persons.find(p => p.role === 'Richter');
  const witnesses = c.persons.filter(p => p.role === 'Zeuge');
  const ownArgs = sortArgs(c.arguments.filter(a => a.side === 'own'), sortMode);
  const oppArgs = sortArgs(c.arguments.filter(a => a.side === 'opp'), sortMode);
  const empfehlung = getStrategieEmpfehlung(final);
  const handleDrop = (targetId: string, side: 'own' | 'opp') => {
    if (!dragId || dragId === targetId || !onUpdateCase) return;
    const sideArgs = sortArgs(c.arguments.filter(a => a.side === side), sortMode);
    const fromIdx = sideArgs.findIndex(a => a.id === dragId);
    const toIdx = sideArgs.findIndex(a => a.id === targetId);
    if (fromIdx === -1 || toIdx === -1) return;
    const reordered = [...sideArgs];
    const [moved] = reordered.splice(fromIdx, 1);
    reordered.splice(toIdx, 0, moved);
    // Assign sortOrder
    const updatedArgs = c.arguments.map(a => {
      const idx = reordered.findIndex(r => r.id === a.id);
      if (idx !== -1) return { ...a, sortOrder: idx };
      return a;
    });
    onUpdateCase({ ...c, arguments: updatedArgs });
    setDragId(null);
  };
  // Visual reordering during drag
  const getVisualDragOrder = (list: LexaraArgument[]): LexaraArgument[] => {
    if (!dragId || !dragOverId || dragId === dragOverId) return list;
    const fromIdx = list.findIndex(a => a.id === dragId);
    const toIdx = list.findIndex(a => a.id === dragOverId);
    if (fromIdx === -1 || toIdx === -1) return list;
    const reordered = [...list];
    const [moved] = reordered.splice(fromIdx, 1);
    reordered.splice(toIdx, 0, moved);
    return reordered;
  };
  // Build timeline data
  const sortedDates = ['1. März', '22. Apr.', '13. Juni', '5. Aug.'];

  const getChartData = () => {
    if (viewMode === 'own') {
      return sortedDates.map((d, i) => ({
        date: d,
        strength: Math.round(ownArgs.slice(0, Math.max(1, Math.ceil(ownArgs.length * (i + 1) / sortedDates.length)))
          .reduce((s, a) => s + a.strength * 5, 0)),
      }));
    }
    if (viewMode === 'opp') {
      return sortedDates.map((d, i) => ({
        date: d,
        strength: Math.round(oppArgs.slice(0, Math.max(1, Math.ceil(oppArgs.length * (i + 1) / sortedDates.length)))
          .reduce((s, a) => s + a.strength * 4, 0)),
      }));
    }
    return sortedDates.map((d, i) => ({
      date: d,
      strength: Math.round(
        ownArgs.slice(0, Math.max(1, Math.ceil(ownArgs.length * (i + 1) / sortedDates.length)))
          .reduce((s, a) => s + a.strength * 5, 0) -
        oppArgs.slice(0, Math.max(1, Math.ceil(oppArgs.length * (i + 1) / sortedDates.length)))
          .reduce((s, a) => s + a.strength * 3, 0)
      ),
    }));
  };
  const chartData = getChartData();
  const viewLabels: { id: ViewMode; label: string; icon: string }[] = [
    { id: 'own', label: 'Eigene Seite', icon: '?' },
    { id: 'combined', label: 'Kombiniert', icon: '?' },
    { id: 'opp', label: 'Gegenseite', icon: '?' },
  ];
  // 6 Stufen des Algorithmus
  const stufen = [
    { nr: 1, label: 'Argument-Basisgewichtung', value: Math.round(ownScore), note: `${ownArgs.length} eigene vs. ${oppArgs.length} gegnerische Argumente`, formula: 'ArgBasis = Stärke (0?10)' },
    { nr: 2, label: 'Beweisboost', value: Math.round(evBoostOwn * 100), note: 'Kettenergebnis ? 0.5 Boost-Faktor', formula: 'BoostFaktor = 1 + (Kettenergebnis/10) ? 0.5' },
    { nr: 3, label: 'Kanteneffekte', value: excludeCount, note: `${excludeCount} Ausschluss-Kanten (+${(excludeCount * 2)}% Bonus)`, formula: 'Entkräftung: ?20%, Ausschluss: ?80%' },
    { nr: 4, label: 'Zeugenmultiplikator', value: Math.round(result.oppWitnessMult * 100), note: 'Gegner-Zeugenmultiplikator', formula: 'Mult = 0.70 + (Glaubwürdigkeit/100) ? 0.30' },
    { nr: 5, label: 'Richter-Kalibrierung', value: Math.round(50 + judgeCalib * 100), note: judge ? `${judge.name}: ${judge.plaintiffWinRate}% Klägerquote` : 'Kein Richter hinterlegt', formula: 'Adj = (Rate?50)/100 ? 0.15' },
    { nr: 6, label: 'Fristenkorrektur', value: Math.round((1 - fristenAbzug) * 100), note: `${(c.fristen || []).filter(f => f.status === 'offen').length} offene Fristen`, formula: 'Final = Basis ? ?(1?Abzug)' },
  ];
  return (
    <div style={{ padding: 24, maxWidth: 1100, margin: '0 auto', overflowY: 'auto', height: '100%' }}>
      {/* Main prognosis */}
      <Panel style={{ display: 'flex', gap: 24, alignItems: 'center', marginBottom: 20 }}>
        <BigRing score={final} size={120} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.03em', marginBottom: 4 }}>
            Gesamtprognose ? {c.name}
          </div>
          <div style={{ fontSize: 22, fontWeight: 700, color: empfehlung.color, marginBottom: 8 }}>{empfehlung.label}</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <Chip small variant="filled" color={empfehlung.color}>{empfehlung.pfad === 'klage' ? '?? Klage' : empfehlung.pfad === 'vergleich' ? '? Vergleich' : '? Aufgabe'}</Chip>
          </div>
          <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.5, marginTop: 4 }}>
            {empfehlung.desc} Berechnung auf Basis von {ownArgs.length + oppArgs.length} Argumenten, {Object.values(c.evidence).flat().length} Beweisstücken, {c.persons.length} Personen{(c.fristen || []).length > 0 ? `, ${(c.fristen || []).length} Fristen` : ''}.
          </div>
        </div>
      </Panel>
      <div style={{ height: 1, background: 'rgba(0,0,0,0.06)', margin: '24px 0' }} />
      {/* 6-Stufen-Algorithmus */}
      <SectionTitle icon="?">6-Stufen-Algorithmus (vollständig einsehbar)</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 20 }}>
        {stufen.map(s => (
          <Panel key={s.nr}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
              <Chip small color={T.blue}>Stufe {s.nr}</Chip>
              <span style={{ fontSize: 18, fontWeight: 700, color: T.text }}>{s.value}{s.nr === 1 ? '' : s.nr <= 2 ? '%' : s.nr === 3 ? '?' : '%'}</span>
            </div>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{s.label}</div>
            <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>{s.note}</div>
            <div style={{ fontSize: 11, color: T.blue, fontFamily: "'SF Mono', monospace" }}>{s.formula}</div>
          </Panel>
        ))}
      </div>
      <div style={{ height: 1, background: 'rgba(0,0,0,0.06)', margin: '24px 0' }} />
      {/* Timeline Chart */}
      <SectionTitle icon="?">Zeitabhängige Analyse</SectionTitle>

      {/* View mode tabs */}
      <div style={{ display: 'inline-flex', background: T.bg, borderRadius: 10, padding: 3, marginBottom: 16 }}>
        {viewLabels.map(v => (
          <button key={v.id} onClick={() => setViewMode(v.id)} style={{
            fontFamily: sans, fontSize: 13, fontWeight: viewMode === v.id ? 600 : 400,
            color: viewMode === v.id ? T.text : T.dim,
            background: viewMode === v.id ? T.surface : 'transparent',
            border: 'none', borderRadius: 8, padding: '6px 16px', cursor: 'pointer',
            boxShadow: viewMode === v.id ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
            transition: 'all 0.15s',
          }}>
            {v.icon} {v.label}
          </button>
        ))}
      </div>
      <Panel style={{ marginBottom: 20 }}>
        <ResponsiveContainer width="100%" height={200}>
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke={T.muted} />
            <XAxis dataKey="date" tick={{ fontSize: 12, fill: T.dim }} axisLine={{ stroke: T.muted }} />
            <YAxis tick={{ fontSize: 12, fill: T.dim }} axisLine={{ stroke: T.muted }} />
            <Tooltip contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)', fontFamily: sans }} />
            <Line type="monotone" dataKey="strength" stroke={viewMode === 'opp' ? T.red : T.blue} strokeWidth={2} dot={{ fill: viewMode === 'opp' ? T.red : T.blue, r: 5 }} />
          </LineChart>
        </ResponsiveContainer>
      </Panel>
      <div style={{ height: 1, background: 'rgba(0,0,0,0.06)', margin: '24px 0' }} />
      {/* Sort controls */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
        <span style={{ fontSize: 12, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.04em' }}>Sortierung</span>
        {([
          { id: 'time' as SortMode, label: 'Chronologisch', icon: '?' },
          { id: 'strength' as SortMode, label: 'Stärke', icon: '?' },
          { id: 'manual' as SortMode, label: 'Manuell', icon: '??' },
        ]).map(s => (
          <button key={s.id} onClick={() => setSortMode(s.id)} style={{
            fontFamily: sans, fontSize: 12, fontWeight: sortMode === s.id ? 600 : 400,
            color: sortMode === s.id ? T.text : T.dim,
            background: sortMode === s.id ? T.surface : 'transparent',
            border: `1px solid ${sortMode === s.id ? T.border : 'transparent'}`,
            borderRadius: 8, padding: '5px 12px', cursor: 'pointer',
            boxShadow: sortMode === s.id ? '0 1px 3px rgba(0,0,0,0.06)' : 'none',
            transition: 'all 0.15s',
          }}>
            {s.icon} {s.label}
          </button>
        ))}
      </div>
      {/* Arguments split */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <div>
          <SectionTitle>Eigene Argumente ({ownArgs.length})</SectionTitle>
          {(() => {
            const visual = getVisualDragOrder(ownArgs);
            return visual.map(a => (
              <DraggableArgumentCard
                key={a.id} arg={a} evidence={c.evidence[a.id] || []}
                isDragging={dragId === a.id}
                isOver={dragOverId === a.id && dragId !== a.id}
                sortMode={sortMode}
                onDragStart={() => setDragId(a.id)}
                onDragOver={(e) => { e.preventDefault(); setDragOverId(a.id); }}
                onDrop={() => { handleDrop(a.id, 'own'); setDragOverId(null); }}
                onDragEnd={() => { setDragId(null); setDragOverId(null); }}
              />
            ));
          })()}
        </div>
        <div>
          <SectionTitle>Gegnerische Argumente ({oppArgs.length})</SectionTitle>
          {(() => {
            const visual = getVisualDragOrder(oppArgs);
            return visual.map(a => (
              <DraggableArgumentCard
                key={a.id} arg={a} evidence={c.evidence[a.id] || []}
                isDragging={dragId === a.id}
                isOver={dragOverId === a.id && dragId !== a.id}
                sortMode={sortMode}
                onDragStart={() => setDragId(a.id)}
                onDragOver={(e) => { e.preventDefault(); setDragOverId(a.id); }}
                onDrop={() => { handleDrop(a.id, 'opp'); setDragOverId(null); }}
                onDragEnd={() => { setDragId(null); setDragOverId(null); }}
              />
            ));
          })()}
        </div>
      </div>
      {/* Psychologische Faktoren Section */}
      {(() => {
        const psychoArgs = c.arguments.filter(a => a.notes?.includes('Psychologisches Profil') || a.notes?.includes('Eigene Schwäche'));
        if (psychoArgs.length === 0) return null;
        const psychoOwn = psychoArgs.filter(a => a.notes?.includes('Verwundbarkeit') || a.notes?.includes('Eigene Schwäche'));
        const psychoOpp = psychoArgs.filter(a => a.notes?.includes('ausnutzbar'));
        return (
          <div style={{ marginTop: 20 }}>
            <SectionTitle icon="?">Psychologische Faktoren ({psychoArgs.length})</SectionTitle>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: 8 }}>
                  ?? Eigene Verwundbarkeiten ({psychoOwn.length})
                </div>
                {psychoOwn.length === 0 && <div style={{ fontSize: 12, color: T.dim, fontStyle: 'italic' }}>Keine erkannt</div>}
                {psychoOwn.map(a => (
                  <Panel key={a.id} style={{ marginBottom: 8, padding: '12px 14px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
                      <div style={{ fontSize: 14, fontWeight: 600, color: T.text, flex: 1 }}>{a.label}</div>
                      <div style={{ fontSize: 12, fontWeight: 600, color: T.orange, background: T.orange + '0a', padding: '2px 10px', borderRadius: 6, fontFamily: mono }}>{a.strength}/10</div>
                    </div>
                    {a.content && <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6, whiteSpace: 'pre-line' }}>{a.content}</div>}
                    {a.notes && <div style={{ fontSize: 10, color: T.dim, marginTop: 4, fontStyle: 'italic' }}>{a.notes}</div>}                  </Panel>
                ))}
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: 8 }}>
                  ? Gegenseite ausnutzbar ({psychoOpp.length})
                </div>
                {psychoOpp.length === 0 && <div style={{ fontSize: 12, color: T.dim, fontStyle: 'italic' }}>Keine erkannt</div>}
                {psychoOpp.map(a => (
                  <Panel key={a.id} style={{ marginBottom: 8, padding: '12px 14px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
                      <div style={{ fontSize: 14, fontWeight: 600, color: T.text, flex: 1 }}>{a.label}</div>
                      <div style={{ fontSize: 12, fontWeight: 600, color: T.text, background: 'rgba(0,0,0,0.04)', padding: '2px 10px', borderRadius: 6, fontFamily: mono }}>{a.strength}/10</div>
                    </div>
                    {a.content && <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6, whiteSpace: 'pre-line' }}>{a.content}</div>}
                    {a.notes && <div style={{ fontSize: 10, color: T.dim, marginTop: 4, fontStyle: 'italic' }}>{a.notes}</div>}                  </Panel>
                ))}
              </div>
            </div>
          </div>
        );
      })()}
      {/* Witness credibility */}
      {witnesses.length > 0 && (
        <div style={{ marginTop: 20 }}>
          <SectionTitle icon="?">Zeugenglaubwürdigkeit</SectionTitle>
          <Panel>
            {witnesses.map(w => {
              const cred = computeCredibility(w);
              return (
                <div key={w.id} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
                  <span style={{ fontSize: 14, width: 160 }}>{w.name}</span>
                  <div style={{ flex: 1 }}><Bar v={cred ?? 50} max={100} color={scol(cred ?? 50)} h={5} /></div>
                  <span style={{ fontSize: 14, fontWeight: 600, color: scol(cred ?? 50), width: 40, textAlign: 'right' }}>{cred}%</span>
                </div>
              );
            })}
          </Panel>
        </div>
      )}
      {/* Referenz-Tabelle toggle */}
      <div style={{ marginTop: 20 }}>
        <button onClick={() => setShowRefTable(!showRefTable)} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.blue, background: T.blue + '10',
          border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
        }}>
          ? {showRefTable ? 'Referenztabelle ausblenden' : 'Argumentgewichtungs-Referenz anzeigen'}
        </button>
        {showRefTable && (
          <Panel style={{ marginTop: 12 }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: sans, fontSize: 13 }}>
              <thead>
                <tr style={{ borderBottom: `1px solid ${T.border}` }}>
                  {['Typ', 'Gewicht', 'Kategorie'].map(h => (
                    <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontWeight: 600, color: T.dim, fontSize: 12 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {ARGUMENT_WEIGHT_TABLE.map((r, i) => (
                  <tr key={i} style={{ borderBottom: `1px solid ${T.border}08` }}>
                    <td style={{ padding: '6px 10px' }}>{r.type}</td>
                    <td style={{ padding: '6px 10px', fontWeight: 600, color: scol(r.weight * 10) }}>{r.weight}</td>
                    <td style={{ padding: '6px 10px' }}><Chip small>{r.category}</Chip></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Panel>
        )}
      </div>
    </div>
  );
}
function DraggableArgumentCard({ arg, evidence, isDragging, isOver, sortMode, onDragStart, onDragOver, onDrop, onDragEnd }: {
  arg: LexaraArgument; evidence: any[]; isDragging: boolean; isOver?: boolean; sortMode: SortMode;
  onDragStart: () => void; onDragOver: (e: React.DragEvent) => void; onDrop: () => void; onDragEnd: () => void;
}) {
  const isDruckmittel = arg.notes?.includes('Druckmittel');
  const isWiderspruch = arg.argType === 'Gegenargument' && arg.notes?.includes('Widerspruch');
  const isPsycho = arg.notes?.includes('Psychologisches Profil');
  const isEigenSchwaeche = arg.notes?.includes('Eigene Schwäche');
  const ts = formatTimestamp(arg.timestamp);
  return (
    <div
      draggable
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDrop={onDrop}
      onDragEnd={onDragEnd}
      style={{
        opacity: isDragging ? 0.3 : 1,
        cursor: 'grab',
        transition: 'all 0.15s ease',
        transform: isOver ? 'translateY(4px)' : 'none',
        marginBottom: 8,
        padding: '14px 16px',
        background: T.surface,
        borderRadius: 12,
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 12, color: T.dim, cursor: 'grab', userSelect: 'none' }}>?</span>
            <div style={{ fontSize: 14, fontWeight: 600, color: T.text, letterSpacing: '-0.01em', lineHeight: 1.4 }}>{arg.label}</div>
          </div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginTop: 3 }}>
            {arg.argType && <span style={{ fontSize: 11, color: T.dim, fontWeight: 400 }}>{arg.argType}</span>}
            {ts && <span style={{ fontSize: 10, color: T.dim, fontWeight: 400, fontFamily: mono }}>{ts}</span>}
          </div>
        </div>
        <div style={{ fontSize: 12, fontWeight: 600, color: T.text, background: 'rgba(0,0,0,0.04)', padding: '2px 10px', borderRadius: 6, fontFamily: mono, letterSpacing: '0.02em' }}>
          {arg.strength}/10
        </div>
      </div>
      {arg.content && <div style={{ fontSize: 13, color: T.textSecondary, lineHeight: 1.6, marginBottom: 8 }}>{arg.content}</div>}
      <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
        {arg.legalBasis && <span style={{ fontSize: 11, color: T.textSecondary, fontWeight: 500, fontFamily: mono }}>{arg.legalBasis}</span>}
        {evidence.length > 0 && <span style={{ fontSize: 11, color: T.dim }}>? {evidence.length} Beweise</span>}
        {arg.source === 'ki' && <span style={{ fontSize: 10, color: T.dim }}>? KI</span>}
        {isDruckmittel && <span style={{ fontSize: 10, color: T.dim, fontStyle: 'italic' }}>? Druckmittel</span>}
        {isWiderspruch && <span style={{ fontSize: 10, color: T.dim, fontStyle: 'italic' }}>? Widerspruch</span>}
        {isPsycho && <span style={{ fontSize: 10, color: T.dim, fontStyle: 'italic' }}>? ? Psycho-Profil</span>}
        {isEigenSchwaeche && <span style={{ fontSize: 10, color: T.dim, fontStyle: 'italic' }}>? ?? Schwäche</span>}
      </div>
    </div>
  );
}
