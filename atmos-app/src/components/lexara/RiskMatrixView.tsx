import React from 'react';
import { LexaraCase } from '@/types/lexara';
import { computeWinProbability } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Panel } from './Primitives';
interface Props {
  c: LexaraCase;
  onBack: () => void;
}
const MATRIX: string[][] = [
  ['L', 'L', 'M', 'M', 'H'],
  ['L', 'M', 'M', 'H', 'H'],
  ['M', 'M', 'H', 'H', 'C'],
  ['M', 'H', 'H', 'C', 'C'],
  ['H', 'H', 'C', 'C', 'C'],
];
const cellColor = (v: string) => {
  if (v === 'L') return '#c8e6c9';
  if (v === 'M') return '#fff9c4';
  if (v === 'H') return '#ffccbc';
  return '#ef9a9a';
};
export function RiskMatrixView({ c, onBack }: Props) {
  const { final } = computeWinProbability(c);
  const processKosten = 25000;
  const processGewinn = 150000;
  const vergleichKosten = 5000;
  const vergleichGewinn = 70000;
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
          <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Risk & Cost-Benefit Analysis</h1>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
          {/* Risk matrix */}
          <Panel>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 16 }}>Risk & Opportunity Matrix</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <div style={{ fontSize: 12, color: T.dim, writingMode: 'vertical-rl', transform: 'rotate(180deg)', textAlign: 'center' }}>
                Auswirkung
              </div>
              <div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 4 }}>
                  {MATRIX.map((row, ri) => row.map((cell, ci) => (
                    <div key={`${ri}-${ci}`} style={{
                      width: 60, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center',
                      background: cellColor(cell), borderRadius: 8, fontSize: 14, fontWeight: 600, color: '#555',
                    }}>
                      {cell}
                    </div>
                  )))}
                </div>
                <div style={{ textAlign: 'center', fontSize: 12, color: T.dim, marginTop: 8 }}>Eintrittswahrscheinlichkeit</div>
              </div>
            </div>
          </Panel>
          {/* Cost-benefit */}
          <Panel>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 16 }}>
              Cost-Benefit Analysis (Szenario: Vergleich vs. Prozess)
            </div>
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 10 }}>Szenario A: Prozess Führen</div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 14px', background: T.bg, borderRadius: 10, marginBottom: 6 }}>
                <span style={{ fontSize: 14, color: T.textSecondary }}>Erwartete Kosten</span>
                <span style={{ fontSize: 14, fontWeight: 600 }}>€ {processKosten.toLocaleString('de-DE')}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 14px', background: T.bg, borderRadius: 10 }}>
                <span style={{ fontSize: 14, color: T.textSecondary }}>Möglicher Gewinn</span>
                <span style={{ fontSize: 14, fontWeight: 600, color: T.green }}>€ {processGewinn.toLocaleString('de-DE')}</span>
              </div>
            </div>
            <div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 10 }}>Szenario B: Vergleich Anstreben</div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 14px', background: T.bg, borderRadius: 10, marginBottom: 6 }}>
                <span style={{ fontSize: 14, color: T.textSecondary }}>Erwartete Kosten</span>
                <span style={{ fontSize: 14, fontWeight: 600 }}>€ {vergleichKosten.toLocaleString('de-DE')}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 14px', background: T.bg, borderRadius: 10 }}>
                <span style={{ fontSize: 14, color: T.textSecondary }}>Sicherer Gewinn</span>
                <span style={{ fontSize: 14, fontWeight: 600, color: T.green }}>€ {vergleichGewinn.toLocaleString('de-DE')}</span>
              </div>
            </div>
          </Panel>
        </div>
      </div>
    </div>
  );
}
