import React, { useState, useMemo } from 'react';
import { LexaraCase, LexaraArgument, LexaraEvidence } from '@/types/lexara';
import { T, sans, scol } from './theme';
import { Bar, Chip, Panel, Label, SectionTitle } from './Primitives';
import { EvidenceFormDialog } from './EvidenceFormDialog';
interface EvidenceTabEditableProps {
  c: LexaraCase;
  onUpdateCase: (updated: LexaraCase) => void;
  onEditArg: (arg: LexaraArgument) => void;
}
const typeIcons: Record<string, string> = {
  'Urkunde': '?', 'Gutachten': '?', 'Screenshot': '?', 'Schriftstück': '?',
  'Protokoll': '?', 'Zeuge': '?', 'Intern': '?', 'Dokument': '?',
  'Nachweis': '?', 'Berechnung': '?',
};
export function EvidenceTabEditable({ c, onUpdateCase, onEditArg }: EvidenceTabEditableProps) {
  const [active, setActive] = useState<string | null>(c.arguments[0]?.id || null);
  const [showEvDialog, setShowEvDialog] = useState(false);
  const [editingEv, setEditingEv] = useState<LexaraEvidence | null>(null);
  const arg = c.arguments.find(a => a.id === active);
  const evs = active ? (c.evidence[active] || []) : [];
  const col = arg ? (arg.side === 'own' ? T.blue : T.red) : T.blue;
  const ket = useMemo(() => {
    if (evs.length === 0) return 0;
    return evs.reduce((s, e) => s + (e.strength ?? 5) * ((e.validity ?? 50) / 100), 0) / evs.length * 10;
  }, [evs]);
  const handleSaveEvidence = (ev: LexaraEvidence) => {
    if (!active) return;
    const currentEvs = c.evidence[active] || [];
    const exists = currentEvs.find(e => e.id === ev.id);
    const updatedEvs = exists ? currentEvs.map(e => e.id === ev.id ? ev : e) : [...currentEvs, ev];
    onUpdateCase({ ...c, evidence: { ...c.evidence, [active]: updatedEvs } });
    setShowEvDialog(false);
    setEditingEv(null);
  };
  const handleDeleteEvidence = (evId: string) => {
    if (!active) return;
    const updatedEvs = (c.evidence[active] || []).filter(e => e.id !== evId);
    onUpdateCase({ ...c, evidence: { ...c.evidence, [active]: updatedEvs } });
  };
  return (
    <div style={{ display: 'flex', gap: 20, height: '100%', overflow: 'hidden', padding: 20 }}>
      {/* Arguments list */}
      <div style={{ width: 220, overflowY: 'auto', flexShrink: 0 }}>
        <Label>Argumente</Label>
        {c.arguments.map(a => {
          const ac = a.side === 'own' ? T.blue : T.red;
          const isA = active === a.id;
          const evCount = (c.evidence[a.id] || []).length;
          return (
            <div key={a.id} onClick={() => setActive(a.id)} style={{
              background: isA ? T.surface : 'transparent', borderRadius: 12,
              padding: '12px 14px', marginBottom: 4, cursor: 'pointer',
              transition: 'all 0.15s',
              boxShadow: isA ? '0 1px 3px rgba(0,0,0,0.06)' : 'none',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, alignItems: 'center' }}>
                <Chip small color={ac}>{a.side === 'own' ? 'Eigen' : 'Gegner'}</Chip>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                  <span style={{ fontSize: 13, fontWeight: 600, color: ac }}>{a.strength}</span>
                  <button onClick={(e) => { e.stopPropagation(); onEditArg(a); }}
                    style={{ background: 'none', border: 'none', color: T.dim, cursor: 'pointer', fontSize: 12 }}>?</button>
                </div>
              </div>
              <div style={{ fontSize: 13, color: isA ? T.text : T.dim, lineHeight: 1.4, fontWeight: isA ? 500 : 400 }}>
                {a.label}
              </div>
              <div style={{ fontSize: 11, color: T.dim, marginTop: 4 }}>{evCount} Beweise</div>
            </div>
          );
        })}
      </div>
      {/* Evidence detail */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 12, color: T.dim, marginBottom: 2 }}>{arg?.side === 'own' ? 'Eigenes Argument' : 'Gegenargument'}</div>
            <div style={{ fontSize: 20, fontWeight: 700 }}>{arg?.label}</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <button onClick={() => { setEditingEv(null); setShowEvDialog(true); }} style={{
              fontFamily: sans, fontSize: 13, fontWeight: 500, color: T.blue, background: T.blue + '10',
              border: 'none', borderRadius: 16, padding: '6px 16px', cursor: 'pointer',
            }}>+ Beweis</button>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: T.dim }}>KET</div>
              <div style={{ fontSize: 28, fontWeight: 700, color: col }}>{Math.min(99, Math.round(ket))}</div>
            </div>
          </div>
        </div>
        <Panel style={{ marginBottom: 20, padding: 16 }}>
          <SectionTitle icon="?">Beweisstrang mit Konkretisierungen</SectionTitle>
          <div style={{ fontSize: 13, color: T.dim, marginBottom: 16 }}>
            Klicken Sie auf die Punkte (?) neben Beweisen, um Konkretisierungen anzuzeigen.
          </div>
          {/* Vertical timeline */}
          {evs.map((e, i) => {
            const strengthPercent = ((e.strength ?? 5) / 10) * 100;
            const barColor = scol(strengthPercent);
            const icon = typeIcons[e.type || ''] || '?';
            return (
              <div key={e.id} style={{ display: 'flex', gap: 0, alignItems: 'stretch' }}>
                {/* Timeline line + dot */}
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 28, flexShrink: 0 }}>
                  <div style={{
                    width: 12, height: 12, borderRadius: '50%', background: T.blue,
                    border: `2px solid ${T.surface}`, boxShadow: `0 0 0 2px ${T.blue}`, flexShrink: 0, zIndex: 1,
                  }} />
                  {i < evs.length - 1 && <div style={{ flex: 1, width: 2, background: T.blue + '30' }} />}
                </div>
                {/* Evidence card */}
                <div onClick={() => { setEditingEv(e); setShowEvDialog(true); }} style={{
                  flex: 1, background: T.surface, borderRadius: 16, padding: '14px 16px',
                  marginBottom: 12, marginLeft: 10, cursor: 'pointer',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
                  transition: 'box-shadow 0.15s',
                  border: `1px solid ${T.border}`,
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                    <span style={{ fontSize: 20 }}>{icon}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 15, fontWeight: 600 }}>{e.name}</div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginLeft: 30 }}>
                    <div style={{ width: 60 }}><Bar v={e.strength ?? 5} max={10} color={barColor} h={4} /></div>
                    <span style={{ fontSize: 13, fontWeight: 600, color: barColor }}>{e.strength ?? 5}/10</span>
                  </div>
                  {e.desc && (
                    <div style={{ fontSize: 12, color: T.dim, marginTop: 6, marginLeft: 30, lineHeight: 1.4 }}>{e.desc}</div>
                  )}
                </div>
              </div>
            );
          })}
          {evs.length === 0 && (
            <div style={{ textAlign: 'center', padding: 40, color: T.dim, fontSize: 14 }}>
              Keine Beweise hinterlegt. Klicke ?+ Beweis" um einen hinzuzufügen.
            </div>
          )}
        </Panel>
      </div>
      <EvidenceFormDialog
        isOpen={showEvDialog}
        initial={editingEv}
        onClose={() => { setShowEvDialog(false); setEditingEv(null); }}
        onSave={handleSaveEvidence}
        onDelete={handleDeleteEvidence}
      />
    </div>
  );
}
