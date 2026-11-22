import React, { useState } from 'react';
import { LexaraCase } from '@/types/lexara';
import { T, sans } from './theme';
import { Panel, SectionTitle, Chip } from './Primitives';
interface Props {
  c: LexaraCase;
  onUpdateCase: (updated: LexaraCase) => void;
}
export function CaseBasicsStep({ c, onUpdateCase }: Props) {
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({ ...c });
  const save = () => {
    onUpdateCase({ ...c, ...form });
    setEditing(false);
  };
  const inputStyle: React.CSSProperties = {
    width: '100%', padding: '10px 14px', background: T.bg, border: `1px solid ${T.border}`,
    color: T.text, fontFamily: sans, fontSize: 14, borderRadius: 10, outline: 'none',
  };
  const labelStyle: React.CSSProperties = {
    fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.dim, marginBottom: 4, display: 'block',
  };
  return (
    <div style={{ padding: 24, maxWidth: 900, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <SectionTitle icon="?">Falldaten</SectionTitle>
        <button onClick={() => editing ? save() : setEditing(true)} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff',
          background: editing ? T.green : T.blue,
          border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
        }}>
          {editing ? '? Speichern' : '? Bearbeiten'}
        </button>
      </div>
      {editing ? (
        <Panel>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            <div>
              <label style={labelStyle}>Fallname</label>
              <input style={inputStyle} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Aktenzeichen</label>
              <input style={inputStyle} value={form.number} onChange={e => setForm({ ...form, number: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Gericht</label>
              <input style={inputStyle} value={form.court} onChange={e => setForm({ ...form, court: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Rechtsgebiet</label>
              <input style={inputStyle} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Prozessziel</label>
              <input style={inputStyle} value={form.goal} onChange={e => setForm({ ...form, goal: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Status</label>
              <select style={{ ...inputStyle, cursor: 'pointer' }} value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}>
                {['Vorbereitung', 'Aktiv', 'Ruhend', 'Abgeschlossen'].map(s => (
                  <option key={s} value={s}>{s}</option>
                ))}
              </select>
            </div>
            <div>
              <label style={labelStyle}>Instanz</label>
              <select style={{ ...inputStyle, cursor: 'pointer' }} value={form.instanz || 'Erstinstanz'} onChange={e => setForm({ ...form, instanz: e.target.value })}>
                {['Erstinstanz', 'Berufung', 'Revision'].map(s => (
                  <option key={s} value={s}>{s}</option>
                ))}
              </select>
            </div>
            <div>
              <label style={labelStyle}>Erstellt</label>
              <input style={inputStyle} value={form.created} readOnly />
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
              <label style={labelStyle}>Zentrale Rechtsfrage (Kernfrage)</label>
              <textarea
                style={{ ...inputStyle, minHeight: 80, resize: 'vertical' }}
                value={form.kernfrage || ''}
                onChange={e => setForm({ ...form, kernfrage: e.target.value })}
                placeholder="z.B. Liegt ein Sachmangel i.S.d. §434 BGB vor?"
              />
            </div>
          </div>
        </Panel>
      ) : (
        <>
          <Panel style={{ marginBottom: 16 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
              <InfoRow label="Fallname" value={c.name} />
              <InfoRow label="Aktenzeichen" value={c.number || '?'} />
              <InfoRow label="Gericht" value={c.court || '?'} />
              <InfoRow label="Rechtsgebiet" value={c.type || '?'} />
              <InfoRow label="Prozessziel" value={c.goal || '?'} />
              <InfoRow label="Status" value={c.status} chip chipColor={c.status === 'Aktiv' ? T.green : T.dim} />
              <InfoRow label="Instanz" value={c.instanz || 'Erstinstanz'} />
              <InfoRow label="Erstellt" value={c.created} />
            </div>
          </Panel>
          {c.kernfrage && (
            <Panel>
              <div style={{ fontSize: 12, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.03em', marginBottom: 8 }}>
                Zentrale Rechtsfrage
              </div>
              <div style={{ fontSize: 16, fontStyle: 'italic', color: T.text, lineHeight: 1.5 }}>
                ?{c.kernfrage}"
              </div>
            </Panel>
          )}
          {/* Quick stats */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginTop: 16 }}>
            {[
              { label: 'Argumente', value: c.arguments.length, icon: '??' },
              { label: 'Beweise', value: Object.values(c.evidence).flat().length, icon: '?' },
              { label: 'Personen', value: c.persons.length, icon: '?' },
              { label: 'Fristen', value: (c.fristen || []).length, icon: '?' },
            ].map(s => (
              <Panel key={s.label} style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 24, marginBottom: 4 }}>{s.icon}</div>
                <div style={{ fontSize: 28, fontWeight: 700 }}>{s.value}</div>
                <div style={{ fontSize: 12, color: T.dim }}>{s.label}</div>
              </Panel>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
function InfoRow({ label, value, chip, chipColor }: { label: string; value: string; chip?: boolean; chipColor?: string }) {
  return (
    <div>
      <div style={{ fontSize: 12, fontWeight: 600, color: T.dim, marginBottom: 4 }}>{label}</div>
      {chip ? (
        <Chip color={chipColor}>{value}</Chip>
      ) : (
        <div style={{ fontSize: 15, fontWeight: 500, color: T.text }}>{value}</div>
      )}
    </div>
  );
}
