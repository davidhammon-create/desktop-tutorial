import React from 'react';
import { LexaraCase, LexaraArgument } from '@/types/lexara';
import { T, sans } from './theme';
import { Panel, Chip } from './Primitives';
interface Props {
  c: LexaraCase;
  onBack: () => void;
}
export function ArgumentExtractionView({ c, onBack }: Props) {
  const ownArgs = c.arguments.filter(a => a.side === 'own');
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  const evidence = Object.values(c.evidence).flat();
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      <div style={{ background: '#1d1d1f', padding: '14px 24px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f57' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#28c840' }} />
        </div>
        <span style={{ color: '#fff', fontSize: 17, fontWeight: 700 }}>MachiavelLEX</span>
      </div>
      <div style={{ display: 'flex', minHeight: 'calc(100vh - 50px)' }}>
        {/* Main area ? left side for document (placeholder) */}
        <div style={{ flex: 1, padding: '28px 32px', borderRight: `1px solid ${T.border}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <button onClick={onBack} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: T.blue }}>?</button>
            <div>
              <div style={{ display: 'flex', gap: 12, marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: 600, color: T.text, borderBottom: `2px solid ${T.text}`, paddingBottom: 4 }}>Argument & Problem Board</span>
                <span style={{ fontSize: 14, color: T.dim, paddingBottom: 4 }}>Manuelle Dateien Analyse</span>
              </div>
            </div>
          </div>
          <h1 style={{ fontSize: 22, fontWeight: 700, margin: '16px 0 4px' }}>Argument & Problem Extraction Board</h1>
          <div style={{ fontSize: 15, fontWeight: 600, color: T.text, marginBottom: 4 }}>{c.name}</div>
          <div style={{ fontSize: 13, color: T.dim, marginBottom: 20 }}>
            Ausgewählte Argumente, Probleme und Beweise aus dem Fall, chronologisch sortiert.
          </div>
          {/* Placeholder for document view */}
          <div style={{
            height: 300, background: T.surface, borderRadius: 12, border: `1px dashed ${T.muted}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: T.dim, fontSize: 14,
          }}>
            Dokument hier ablegen oder auswählen
          </div>
        </div>
        {/* Right sidebar ? extracted items */}
        <div style={{ width: 380, padding: '20px', overflowY: 'auto' }}>
          {/* Free arguments */}
          <SectionHeader title="Freie Argumente" count={ownArgs.length + oppArgs.length} />
          {[...ownArgs, ...oppArgs].map(a => (
            <ExtractionCard
              key={a.id}
              title={a.label}
              desc={a.content || a.description || ''}
              type="Argument"
              side={a.side === 'own' ? 'Eigene Seite' : 'Gegenseite'}
              sideColor={a.side === 'own' ? T.green : T.orange}
            />
          ))}
          {/* Free evidence */}
          <SectionHeader title="Freie Beweise" count={evidence.length} />
          {evidence.slice(0, 4).map(ev => (
            <ExtractionCard
              key={ev.id}
              title={ev.name}
              desc={ev.desc}
              type="Beweis"
              side="Eigene Seite"
              sideColor={T.green}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
function SectionHeader({ title, count }: { title: string; count: number }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, marginTop: 20 }}>
      <h3 style={{ fontSize: 17, fontWeight: 700, margin: 0 }}>{title}</h3>
      <button style={{
        width: 28, height: 28, borderRadius: 8, background: T.bg, border: `1px solid ${T.border}`,
        cursor: 'pointer', fontSize: 16, display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>+</button>
    </div>
  );
}
function ExtractionCard({ title, desc, type, side, sideColor }: {
  title: string; desc: string; type: string; side: string; sideColor: string;
}) {
  const typeColor = type === 'Argument' ? '#e8f0fe' : type === 'Problem' ? '#fef7e0' : '#f0f0f0';
  const typeTextColor = type === 'Argument' ? T.blue : type === 'Problem' ? T.orange : T.textSecondary;
  return (
    <Panel style={{ marginBottom: 10, padding: 14 }}>
      <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{title}</div>
      <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.5, marginBottom: 8 }}>{desc}</div>
      <div style={{ display: 'flex', gap: 6 }}>
        <span style={{
          fontSize: 11, fontWeight: 500, padding: '2px 8px', borderRadius: 6,
          background: typeColor, color: typeTextColor,
        }}>{type}</span>
        <span style={{
          fontSize: 11, fontWeight: 500, padding: '2px 8px', borderRadius: 6,
          background: sideColor + '15', color: sideColor,
        }}>{side}</span>
      </div>
    </Panel>
  );
}
