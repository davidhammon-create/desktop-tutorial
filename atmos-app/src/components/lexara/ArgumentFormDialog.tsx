import React, { useState } from 'react';
import { LexaraArgument } from '@/types/lexara';
import { T, sans } from './theme';
interface ArgumentFormDialogProps {
  isOpen: boolean;
  initial?: LexaraArgument | null;
  onClose: () => void;
  onSave: (arg: LexaraArgument) => void;
  onDelete?: (id: string) => void;
}
export function ArgumentFormDialog({ isOpen, initial, onClose, onSave, onDelete }: ArgumentFormDialogProps) {
  const [label, setLabel] = useState(initial?.label || '');
  const [side, setSide] = useState<'own' | 'opp'>(initial?.side || 'own');
  const [strength, setStrength] = useState(initial?.strength || 5);
  const [content, setContent] = useState(initial?.content || '');
  const [timestamp, setTimestamp] = useState(initial?.timestamp || '');
  React.useEffect(() => {
    if (isOpen) {
      setLabel(initial?.label || '');
      setSide(initial?.side || 'own');
      setStrength(initial?.strength || 5);
      setContent(initial?.content || '');
      setTimestamp(initial?.timestamp || '');
    }
  }, [isOpen, initial]);
  if (!isOpen) return null;
  const inputStyle: React.CSSProperties = {
    width: '100%', padding: '10px 14px', background: T.bg, border: `1px solid ${T.border}`,
    color: T.text, fontFamily: sans, fontSize: 14, borderRadius: 10, outline: 'none',
  };
  const labelStyle: React.CSSProperties = { fontFamily: sans, fontSize: 13, fontWeight: 600, color: T.dim, marginBottom: 4, display: 'block' };
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(8px)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
      onClick={onClose}>
      <div style={{ background: T.surface, borderRadius: 20, padding: 28, width: 440, boxShadow: '0 20px 60px rgba(0,0,0,0.15)' }}
        onClick={e => e.stopPropagation()}>
        <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 20 }}>
          {initial ? 'Argument bearbeiten' : 'Neues Argument'}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div><label style={labelStyle}>Bezeichnung</label><input style={inputStyle} value={label} onChange={e => setLabel(e.target.value)} placeholder="z.B. Vertragsverletzung §633 BGB" /></div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Seite</label>
              <select style={{ ...inputStyle, cursor: 'pointer' }} value={side} onChange={e => setSide(e.target.value as 'own' | 'opp')}>
                <option value="own">Eigene Seite</option>
                <option value="opp">Gegenseite</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>Stärke (1-10)</label>
              <input type="number" min={1} max={10} step={0.5} style={inputStyle} value={strength} onChange={e => setStrength(Number(e.target.value))} />
            </div>
          </div>
          <div>
            <label style={labelStyle}>Zeitpunkt (Datum & Uhrzeit)</label>
            <input type="datetime-local" style={inputStyle} value={timestamp} onChange={e => setTimestamp(e.target.value)} />
            <div style={{ fontSize: 11, color: T.dim, marginTop: 4 }}>Bestimmt die chronologische Reihenfolge der Argumente</div>
          </div>
          <div>
            <label style={labelStyle}>Beschreibung</label>
            <textarea style={{ ...inputStyle, minHeight: 80, resize: 'vertical' }} value={content} onChange={e => setContent(e.target.value)} />
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 24 }}>
          <div>
            {initial && onDelete && (
              <button onClick={() => { onDelete(initial.id); onClose(); }} style={{
                fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.red, background: T.red + '10',
                border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
              }}>Löschen</button>
            )}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={onClose} style={{
              fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.dim, background: T.bg,
              border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
            }}>Abbrechen</button>
            <button onClick={() => {
              if (!label.trim()) return;
              onSave({
                id: initial?.id || `arg-${Date.now()}`,
                label, side, strength: Math.max(1, Math.min(10, strength)), content, description: content,
                timestamp: timestamp || undefined,
                sortOrder: initial?.sortOrder,
              });
              onClose();
            }} style={{
              fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.blue,
              border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
            }}>Speichern</button>
          </div>
        </div>
      </div>
    </div>
  );
}
