import React, { useState } from 'react';
import { LexaraCase, LexaraFrist, FRIST_TYPES } from '@/types/lexara';
import { computeFristUrgency, daysUntil } from '@/lib/lexaraUtils';
import { T, sans } from './theme';
import { Panel, SectionTitle, Chip } from './Primitives';
const urgencyStyles: Record<string, { bg: string; color: string; label: string }> = {
  green: { bg: '#34c75915', color: '#34c759', label: '> 14 Tage' },
  yellow: { bg: '#ff950015', color: '#ff9500', label: '3?14 Tage' },
  red: { bg: '#ff3b3015', color: '#ff3b30', label: '< 3 Tage!' },
  grey: { bg: '#86868b15', color: '#86868b', label: 'Versäumt' },
};
export function FristenTab({ c, onUpdateCase }: { c: LexaraCase; onUpdateCase: (c: LexaraCase) => void }) {
  const [showAdd, setShowAdd] = useState(false);
  const [newType, setNewType] = useState<string>(FRIST_TYPES[0].type);
  const [newDate, setNewDate] = useState('');
  const [newResp, setNewResp] = useState('');
  const [newSide, setNewSide] = useState<'own' | 'opp'>('own');
  const fristen = c.fristen || [];
  const sorted = [...fristen].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  const addFrist = () => {
    if (!newDate) return;
    const fristDef = FRIST_TYPES.find(f => f.type === newType);
    const frist: LexaraFrist = {
      id: `fr-${Date.now()}`,
      type: newType,
      paragraph: fristDef?.paragraph || '',
      date: newDate,
      status: 'offen',
      responsible: newResp,
      side: newSide,
      abzugMin: fristDef?.abzugMin ?? 10,
      abzugMax: fristDef?.abzugMax ?? 30,
    };
    onUpdateCase({ ...c, fristen: [...fristen, frist] });
    setShowAdd(false);
    setNewDate('');
    setNewResp('');
  };
  const updateStatus = (id: string, status: LexaraFrist['status']) => {
    onUpdateCase({ ...c, fristen: fristen.map(f => f.id === id ? { ...f, status } : f) });
  };
  const deleteFrist = (id: string) => {
    onUpdateCase({ ...c, fristen: fristen.filter(f => f.id !== id) });
  };
  const inputStyle: React.CSSProperties = {
    width: '100%', padding: '10px 14px', background: T.bg, border: `1px solid ${T.border}`,
    color: T.text, fontFamily: sans, fontSize: 14, borderRadius: 10, outline: 'none',
  };
  const labelStyle: React.CSSProperties = { fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.dim, marginBottom: 4, display: 'block' };
  return (
    <div style={{ padding: 24, maxWidth: 900, margin: '0 auto', overflowY: 'auto', height: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <SectionTitle icon="?">Fristenmanagement</SectionTitle>
        <button onClick={() => setShowAdd(!showAdd)} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.blue,
          border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
        }}>+ Frist</button>
      </div>
      {/* Legende */}
      <div style={{ display: 'flex', gap: 16, marginBottom: 16, flexWrap: 'wrap', paddingBottom: 16, borderBottom: '1px solid rgba(0,0,0,0.06)' }}>
        {Object.entries(urgencyStyles).map(([key, v]) => (
          <div key={key} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: v.color }}>
            <div style={{ width: 10, height: 10, borderRadius: '50%', background: v.color }} />
            {v.label}
          </div>
        ))}
      </div>
      {/* Add dialog */}
      {showAdd && (
        <Panel style={{ marginBottom: 20 }}>
          <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 14 }}>Neue Frist</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Fristtyp</label>
              <select style={{ ...inputStyle, cursor: 'pointer' }} value={newType} onChange={e => setNewType(e.target.value)}>
                {FRIST_TYPES.map(f => (
                  <option key={f.type} value={f.type}>{f.type} ({f.paragraph})</option>
                ))}
              </select>
            </div>
            <div>
              <label style={labelStyle}>Datum</label>
              <input type="date" style={inputStyle} value={newDate} onChange={e => setNewDate(e.target.value)} />
            </div>
            <div>
              <label style={labelStyle}>Verantwortlich</label>
              <input style={inputStyle} value={newResp} onChange={e => setNewResp(e.target.value)} placeholder="z.B. RA Müller" />
            </div>
            <div>
              <label style={labelStyle}>Seite</label>
              <select style={{ ...inputStyle, cursor: 'pointer' }} value={newSide} onChange={e => setNewSide(e.target.value as 'own' | 'opp')}>
                <option value="own">Eigene Frist</option>
                <option value="opp">Gegnerische Frist</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 14, justifyContent: 'flex-end' }}>
            <button onClick={() => setShowAdd(false)} style={{ fontFamily: sans, fontSize: 13, color: T.dim, background: T.bg, border: 'none', borderRadius: 8, padding: '8px 16px', cursor: 'pointer' }}>Abbrechen</button>
            <button onClick={addFrist} style={{ fontFamily: sans, fontSize: 13, color: '#fff', background: T.blue, border: 'none', borderRadius: 8, padding: '8px 16px', cursor: 'pointer', fontWeight: 600 }}>Hinzufügen</button>
          </div>
        </Panel>
      )}
      {/* Fristen-Liste */}
      {sorted.length === 0 ? (
        <Panel style={{ textAlign: 'center', padding: 40, color: T.dim }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>?</div>
          <div style={{ fontSize: 15 }}>Noch keine Fristen hinterlegt</div>
          <div style={{ fontSize: 13, marginTop: 4 }}>Fristen wirken sich direkt auf die Prognose aus (Stufe 6).</div>
        </Panel>
      ) : (
        sorted.map(f => {
          const urgency = computeFristUrgency(f);
          const style = urgencyStyles[urgency];
          const days = daysUntil(f.date);
          const fristDef = FRIST_TYPES.find(ft => ft.type === f.type);
          return (
            <Panel key={f.id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                    <span style={{ fontSize: 15, fontWeight: 600 }}>{f.type}</span>
                    <Chip small color={style.color}>{f.paragraph}</Chip>
                    <Chip small color={f.side === 'own' ? T.blue : T.red}>{f.side === 'own' ? 'Eigene' : 'Gegner'}</Chip>
                  </div>
                  <div style={{ fontSize: 13, color: T.dim, marginBottom: 6 }}>
                    {new Date(f.date).toLocaleDateString('de-DE', { day: '2-digit', month: 'long', year: 'numeric' })}
                    {f.status !== 'versäumt' && f.status !== 'erledigt' && (
                      <span style={{ color: style.color, fontWeight: 600, marginLeft: 8 }}>
                        {days > 0 ? `${days} Tage verbleibend` : 'Überfällig!'}
                      </span>
                    )}
                  </div>
                  {f.responsible && <div style={{ fontSize: 12, color: T.dim }}>Verantwortlich: {f.responsible}</div>}
                  {fristDef && (
                    <div style={{ fontSize: 12, color: T.dim, marginTop: 4 }}>
                      Prognoseabzug bei Versäumnis: {fristDef.abzugMin === fristDef.abzugMax ? `?${fristDef.abzugMax}%` : `?${Math.abs(fristDef.abzugMin!)}% bis ?${Math.abs(fristDef.abzugMax!)}%`}
                    </div>
                  )}
                </div>
                <div style={{ display: 'flex', gap: 6, flexShrink: 0, alignItems: 'center' }}>
                  {f.status === 'offen' && (
                    <>
                      <button onClick={() => updateStatus(f.id, 'erledigt')} style={{
                        fontFamily: sans, fontSize: 12, color: T.green, background: T.green + '10',
                        border: 'none', borderRadius: 8, padding: '6px 12px', cursor: 'pointer', fontWeight: 500,
                      }}>? Erledigt</button>
                      <button onClick={() => updateStatus(f.id, 'versäumt')} style={{
                        fontFamily: sans, fontSize: 12, color: T.red, background: T.red + '10',
                        border: 'none', borderRadius: 8, padding: '6px 12px', cursor: 'pointer', fontWeight: 500,
                      }}>? Versäumt</button>
                    </>
                  )}
                  {f.status !== 'offen' && (
                    <Chip small variant="filled" color={f.status === 'erledigt' ? T.green : T.red}>
                      {f.status === 'erledigt' ? '? Erledigt' : '? Versäumt'}
                    </Chip>
                  )}
                  <button onClick={() => deleteFrist(f.id)} style={{
                    fontFamily: sans, fontSize: 12, color: T.dim, background: 'none',
                    border: 'none', cursor: 'pointer', padding: '6px',
                  }}>?</button>
                </div>
              </div>
            </Panel>
          );
        })
      )}
      {/* Divider */}
      <div style={{ borderTop: '1px solid rgba(0,0,0,0.06)', margin: '28px 0 20px' }} />
      {/* Referenz-Tabelle */}
      <div>
        <SectionTitle icon="?">Fristentypen-Referenz</SectionTitle>
        <Panel>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: sans, fontSize: 13 }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${T.border}` }}>
                {['Fristtyp', 'Paragraph', 'Dauer', 'Prognoseabzug'].map(h => (
                  <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontWeight: 600, color: T.dim, fontSize: 12 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {FRIST_TYPES.map((f, i) => (
                <tr key={i} style={{ borderBottom: `1px solid ${T.border}08` }}>
                  <td style={{ padding: '8px 10px', fontWeight: 500 }}>{f.type}</td>
                  <td style={{ padding: '8px 10px', color: T.blue }}>{f.paragraph}</td>
                  <td style={{ padding: '8px 10px', color: T.dim }}>{f.dauer}</td>
                  <td style={{ padding: '8px 10px', color: f.abzugMin < 0 ? T.green : T.red }}>
                    {f.abzugMin < 0 ? `+${Math.abs(f.abzugMin)}?${Math.abs(f.abzugMax)}%` : `?${f.abzugMin}?${f.abzugMax}%`}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>
      </div>
    </div>
  );
}
