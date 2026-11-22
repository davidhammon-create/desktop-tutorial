import React from 'react';
import { LexaraCase } from '@/types/lexara';
import { T, sans } from './theme';
interface Props {
  c: LexaraCase;
  onBack: () => void;
}
export function EvidenceMatrixView({ c, onBack }: Props) {
  // Build flat list of argument ? evidence pairs
  const rows: { argument: string; evidence: string; type: string; status: 'confirmed' | 'pending' | 'rejected'; timestamp: string }[] = [];
  c.arguments.forEach(arg => {
    const evs = c.evidence[arg.id] || [];
    evs.forEach(ev => {
      const typeIcon = ev.type === 'Zeuge' ? '?' : ev.type === 'Gutachten' ? '?' : ev.type === 'Screenshot' ? '?' : '?';
      const status = (ev.validity ?? 50) >= 70 ? 'confirmed' as const : (ev.validity ?? 50) >= 40 ? 'pending' as const : 'rejected' as const;
      rows.push({
        argument: arg.label,
        evidence: ev.name,
        type: typeIcon,
        status,
        timestamp: ev.desc?.match(/\d{2}\.\d{2}\.\d{4}/)?.[0] || '?',
      });
    });
  });
  const statusIcon = (s: string) => s === 'confirmed' ? '?' : s === 'pending' ? '?' : '?';
  const statusColor = (s: string) => s === 'confirmed' ? T.green : s === 'pending' ? T.orange : T.red;
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
      <div style={{ padding: '28px 32px', maxWidth: 1200, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button onClick={onBack} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 18, color: T.dim }}>?</button>
          <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Evidence Matrix</h1>
        </div>
        <div style={{ background: T.surface, borderRadius: 12, overflow: 'hidden', border: `1px solid ${T.border}` }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: sans }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${T.border}` }}>
                {['Argument', 'Evidence', 'Type', 'Status', 'Zeitstempel'].map(h => (
                  <th key={h} style={{ padding: '14px 18px', fontSize: 13, fontWeight: 600, color: T.text, textAlign: 'left' }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((r, i) => (
                <tr key={i} style={{ borderBottom: `1px solid ${T.border}` }}>
                  <td style={{ padding: '16px 18px', fontSize: 14, color: T.text }}>{r.argument}</td>
                  <td style={{ padding: '16px 18px', fontSize: 14, color: T.textSecondary }}>{r.evidence}</td>
                  <td style={{ padding: '16px 18px', fontSize: 18, textAlign: 'center' }}>{r.type}</td>
                  <td style={{ padding: '16px 18px', textAlign: 'center' }}>
                    <span style={{ fontSize: 16 }}>{statusIcon(r.status)}</span>
                  </td>
                  <td style={{ padding: '16px 18px', fontSize: 13, color: T.dim }}>{r.timestamp}</td>
                </tr>
              ))}
              {rows.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ padding: 32, textAlign: 'center', color: T.dim, fontSize: 14 }}>
                    Keine Beweismittel zugeordnet. Bitte öffnen Sie einen Fall und fügen Sie Beweise hinzu.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
