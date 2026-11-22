import React, { useState } from 'react';
import { BusinessScenario, BusinessOption, Deadline, DeadlineType } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
const DEADLINE_TYPES: DeadlineType[] = ['Verjährung', 'Widerspruch', 'Kündigung', 'Vertragsfrist', 'Behördenfrist', 'Sonstige'];
function daysUntil(dateStr: string): number {
  const target = new Date(dateStr);
  const now = new Date();
  return Math.ceil((target.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
}
function deadlineColor(days: number): string {
  if (days < 0) return '#888';
  if (days <= 30) return T.red;
  if (days <= 90) return T.orange;
  return T.green;
}
function deadlineStatus(days: number): string {
  if (days < 0) return 'Abgelaufen';
  if (days === 0) return 'Heute!';
  if (days <= 7) return `${days} Tage!`;
  return `${days} Tage`;
}
export function DeadlineStep({ scenario, onUpdate }: Props) {
  const [activeIdx, setActiveIdx] = useState(0);
  const opts = scenario.options;
  if (!opts.length) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: T.dim }}>
        <div style={{ fontSize: 15 }}>Bitte fügen Sie zuerst Optionen hinzu</div>
      </div>
    );
  }
  const opt = opts[activeIdx] || opts[0];
  const deadlines = opt.deadlines || [];
  const updateOption = (id: string, patch: Partial<BusinessOption>) => {
    onUpdate({
      ...scenario,
      options: scenario.options.map(o => o.id === id ? { ...o, ...patch } : o),
    });
  };
  const addDeadline = () => {
    const dl: Deadline = {
      id: `dl-${Date.now()}`,
      label: '',
      date: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      type: 'Sonstige',
      critical: false,
      notes: '',
    };
    updateOption(opt.id, { deadlines: [...deadlines, dl] });
  };
  const updateDeadline = (idx: number, patch: Partial<Deadline>) => {
    const arr = [...deadlines];
    arr[idx] = { ...arr[idx], ...patch };
    updateOption(opt.id, { deadlines: arr });
  };
  const removeDeadline = (idx: number) => {
    updateOption(opt.id, { deadlines: deadlines.filter((_, i) => i !== idx) });
  };
  const allDeadlines = opts.flatMap((o, oi) =>
    (o.deadlines || []).map(dl => ({ ...dl, optionLabel: o.label, optionIdx: oi }))
  ).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  return (
    <div style={{ padding: 24, maxWidth: 1000 }}>
      {/* Option tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, overflowX: 'auto' }}>
        {opts.map((o, i) => (
          <button key={o.id} onClick={() => setActiveIdx(i)} style={{
            fontFamily: sans, fontSize: 13, fontWeight: i === activeIdx ? 600 : 400,
            color: i === activeIdx ? '#fff' : T.text,
            background: i === activeIdx ? T.blue : T.surface,
            border: `1px solid ${i === activeIdx ? T.blue : T.border}`,
            borderRadius: 10, padding: '8px 16px', cursor: 'pointer', whiteSpace: 'nowrap',
          }}>
            {String.fromCharCode(65 + i)}: {o.label}
            {(o.deadlines || []).length > 0 && (
              <span style={{ marginLeft: 6, fontSize: 11, opacity: 0.7 }}>({(o.deadlines || []).length})</span>
            )}
          </button>
        ))}
      </div>
      {/* Add deadline */}
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <Label>Fristen für ?{opt.label}"</Label>
          <button onClick={addDeadline} style={{
            fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.blue,
            background: T.blue + '10', border: 'none', borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
          }}>+ Frist hinzufügen</button>
        </div>
        {deadlines.length === 0 && (
          <div style={{ fontSize: 13, color: T.dim, textAlign: 'center', padding: 20 }}>
            Keine Fristen eingetragen. Klicken Sie ?+ Frist hinzufügen".
          </div>
        )}
        {deadlines.map((dl, i) => {
          const days = daysUntil(dl.date);
          const col = deadlineColor(days);
          return (
            <div key={dl.id} style={{
              padding: 16, marginBottom: 10, borderRadius: 12,
              background: T.bg,
            }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 140px 140px auto auto', gap: 10, alignItems: 'center', marginBottom: 8 }}>
                <input value={dl.label} onChange={e => updateDeadline(i, { label: e.target.value })}
                  placeholder="Bezeichnung (z.B. Verjährung)"
                  style={{ fontFamily: sans, fontSize: 13, padding: '6px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.surface, color: T.text, outline: 'none' }} />
                <input type="date" value={dl.date} onChange={e => updateDeadline(i, { date: e.target.value })}
                  style={{ fontFamily: sans, fontSize: 13, padding: '6px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.surface, color: T.text, outline: 'none' }} />
                <select value={dl.type} onChange={e => updateDeadline(i, { type: e.target.value as DeadlineType })}
                  style={{ fontFamily: sans, fontSize: 13, padding: '6px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.surface, color: T.text, outline: 'none' }}>
                  {DEADLINE_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
                </select>
                <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, color: T.dim, cursor: 'pointer', whiteSpace: 'nowrap' }}>
                  <input type="checkbox" checked={dl.critical} onChange={e => updateDeadline(i, { critical: e.target.checked })} />
                  Kritisch
                </label>
                <button onClick={() => removeDeadline(i)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: T.dim, fontSize: 14 }}>?</button>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <input value={dl.notes} onChange={e => updateDeadline(i, { notes: e.target.value })}
                  placeholder="Notizen..."
                  style={{ fontFamily: sans, fontSize: 12, flex: 1, padding: '4px 10px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.surface, color: T.text, outline: 'none' }} />
                <div style={{
                  fontSize: 13, fontWeight: 700, color: col, whiteSpace: 'nowrap',
                  padding: '4px 12px', borderRadius: 8, background: col + '12',
                }}>
                  {deadlineStatus(days)}
                </div>
              </div>
            </div>
          );
        })}
      </Panel>
      {/* Timeline */}
      {allDeadlines.length > 0 && (
        <Panel>
          <Label>Gesamtübersicht ? Alle Fristen chronologisch</Label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {allDeadlines.map((dl, i) => {
              const days = daysUntil(dl.date);
              const col = deadlineColor(days);
              return (
                <div key={`${dl.id}-${i}`} style={{
                  display: 'grid', gridTemplateColumns: '80px 1fr 120px 100px 80px',
                  gap: 10, alignItems: 'center', fontSize: 13, padding: '8px 12px',
                  borderRadius: 8, background: i % 2 === 0 ? T.bg : 'transparent',
                }}>
                  <div style={{ fontSize: 12, color: T.dim }}>
                    {new Date(dl.date).toLocaleDateString('de-DE')}
                  </div>
                  <div style={{ fontWeight: 500 }}>
                    {dl.critical && <span style={{ color: T.red, marginRight: 4 }}>!</span>}
                    {dl.label || 'Ohne Bezeichnung'}
                  </div>
                  <div style={{ fontSize: 11, color: T.blue }}>
                    Option {String.fromCharCode(65 + dl.optionIdx)}: {dl.optionLabel}
                  </div>
                  <div style={{ fontSize: 11, color: T.dim }}>{dl.type}</div>
                  <div style={{ fontWeight: 700, color: col, textAlign: 'right' }}>
                    {deadlineStatus(days)}
                  </div>
                </div>
              );
            })}
          </div>
        </Panel>
      )}
    </div>
  );
}
