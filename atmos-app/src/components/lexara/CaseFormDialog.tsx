import React, { useState } from 'react';
import { LexaraCase } from '@/types/lexara';
import { T, sans } from './theme';
interface CaseFormDialogProps {
  isOpen: boolean;
  initial?: LexaraCase | null;
  onClose: () => void;
  onSave: (data: Partial<LexaraCase> & { name: string }) => void;
}
export function CaseFormDialog({ isOpen, initial, onClose, onSave }: CaseFormDialogProps) {
  const [name, setName] = useState(initial?.name || '');
  const [number, setNumber] = useState(initial?.number || '');
  const [court, setCourt] = useState(initial?.court || '');
  const [type, setType] = useState(initial?.type || 'Zivilrecht');
  const [goal, setGoal] = useState(initial?.goal || '');
  const [status, setStatus] = useState(initial?.status || 'Aktiv');
  React.useEffect(() => {
    if (isOpen) {
      setName(initial?.name || '');
      setNumber(initial?.number || '');
      setCourt(initial?.court || '');
      setType(initial?.type || 'Zivilrecht');
      setGoal(initial?.goal || '');
      setStatus(initial?.status || 'Aktiv');
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
          {initial ? 'Fall bearbeiten' : 'Neuer Fall'}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div><label style={labelStyle}>Fallname</label><input style={inputStyle} value={name} onChange={e => setName(e.target.value)} placeholder="z.B. Schadensersatz Werkvertrag" /></div>
          <div><label style={labelStyle}>Aktenzeichen</label><input style={inputStyle} value={number} onChange={e => setNumber(e.target.value)} placeholder="LG-2024-0847" /></div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div><label style={labelStyle}>Gericht</label><input style={inputStyle} value={court} onChange={e => setCourt(e.target.value)} /></div>
            <div><label style={labelStyle}>Rechtsgebiet</label><input style={inputStyle} value={type} onChange={e => setType(e.target.value)} /></div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div><label style={labelStyle}>Ziel</label><input style={inputStyle} value={goal} onChange={e => setGoal(e.target.value)} /></div>
            <div>
              <label style={labelStyle}>Status</label>
              <select style={{ ...inputStyle, cursor: 'pointer' }} value={status} onChange={e => setStatus(e.target.value)}>
                <option value="Aktiv">Aktiv</option>
                <option value="Vorbereitung">Vorbereitung</option>
                <option value="Abgeschlossen">Abgeschlossen</option>
              </select>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 24 }}>
          <button onClick={onClose} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.dim, background: T.bg,
            border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
          }}>Abbrechen</button>
          <button onClick={() => {
            if (!name.trim()) return;
            onSave({ id: initial?.id, name, number, court, type, goal, status, created: initial?.created || new Date().toLocaleDateString('de-DE') });
            onClose();
          }} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.blue,
            border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
          }}>Speichern</button>
        </div>
      </div>
    </div>
  );
}
