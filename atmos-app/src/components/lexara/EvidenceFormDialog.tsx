import React, { useState } from 'react';
import { LexaraEvidence } from '@/types/lexara';
import { T, sans } from './theme';
interface EvidenceFormDialogProps {
  isOpen: boolean;
  initial?: LexaraEvidence | null;
  onClose: () => void;
  onSave: (ev: LexaraEvidence) => void;
  onDelete?: (id: string) => void;
}
export function EvidenceFormDialog({ isOpen, initial, onClose, onSave, onDelete }: EvidenceFormDialogProps) {
  const [name, setName] = useState(initial?.name || '');
  const [desc, setDesc] = useState(initial?.desc || '');
  const [type, setType] = useState(initial?.type || '');
  const [validity, setValidity] = useState(initial?.validity ?? 70);
  const [strength, setStrength] = useState(initial?.strength ?? 5);
  React.useEffect(() => {
    if (isOpen) {
      setName(initial?.name || '');
      setDesc(initial?.desc || '');
      setType(initial?.type || '');
      setValidity(initial?.validity ?? 70);
      setStrength(initial?.strength ?? 5);
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
          {initial ? 'Beweis bearbeiten' : 'Neuer Beweis'}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div><label style={labelStyle}>Name</label><input style={inputStyle} value={name} onChange={e => setName(e.target.value)} placeholder="z.B. Originalkaufvertrag" /></div>
          <div><label style={labelStyle}>Beschreibung</label><textarea style={{ ...inputStyle, minHeight: 60, resize: 'vertical' }} value={desc} onChange={e => setDesc(e.target.value)} /></div>
          <div><label style={labelStyle}>Typ</label><input style={inputStyle} value={type} onChange={e => setType(e.target.value)} placeholder="Urkunde, Gutachten, Screenshot..." /></div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Gültigkeit (0-100%)</label>
              <input type="number" min={0} max={100} style={inputStyle} value={validity} onChange={e => setValidity(Number(e.target.value))} />
            </div>
            <div>
              <label style={labelStyle}>Stärke (1-10)</label>
              <input type="number" min={1} max={10} style={inputStyle} value={strength} onChange={e => setStrength(Number(e.target.value))} />
            </div>
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
              if (!name.trim()) return;
              onSave({ id: initial?.id || `ev-${Date.now()}`, name, desc, type: type || undefined, validity: Math.max(0, Math.min(100, validity)), strength: Math.max(1, Math.min(10, strength)) });
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
