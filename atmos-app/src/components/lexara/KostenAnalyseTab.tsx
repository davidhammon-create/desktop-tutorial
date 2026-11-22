import React, { useState } from 'react';
import { LexaraCase, LexaraKosten } from '@/types/lexara';
import { computeKosten, computeDecisionAnalysis, computeWinProbability, getStrategieEmpfehlung } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Panel, SectionTitle, Bar, BigRing, Chip } from './Primitives';
export function KostenAnalyseTab({ c, onUpdateCase }: { c: LexaraCase; onUpdateCase: (c: LexaraCase) => void }) {
  const [streitwert, setStreitwert] = useState(c.kosten?.streitwert ?? 50000);
  const [stufe, setStufe] = useState(c.kosten?.gebuehrenstufe ?? 1.3);
  const [svKosten, setSvKosten] = useState(c.kosten?.sachverstaendigenKosten ?? 0);
  const [reise, setReise] = useState(c.kosten?.reisekosten ?? 0);
  const [vergleichsangebot, setVergleichsangebot] = useState(c.kosten?.vergleichsangebot ?? 0);
  const kosten: LexaraKosten = {
    streitwert, gebuehrenstufe: stufe, instanz: c.instanz || 'Erstinstanz',
    sachverstaendigenKosten: svKosten, reisekosten: reise, vergleichsangebot,
  };
  const saveKosten = () => {
    onUpdateCase({ ...c, kosten });
  };
  const kostenResult = computeKosten(kosten);
  const caseWithKosten = { ...c, kosten };
  const decision = computeDecisionAnalysis(caseWithKosten);
  const { final } = computeWinProbability(c);
  const empfehlung = getStrategieEmpfehlung(final);
  const fmt = (n: number) => n.toLocaleString('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 });
  const empfehlungColors = {
    klage: { bg: '#34c75912', border: '#34c759', icon: '??', label: 'KLAGE' },
    vergleich: { bg: '#ff950012', border: '#ff9500', icon: '?', label: 'VERGLEICH' },
    aufgabe: { bg: '#ff3b3012', border: '#ff3b30', icon: '?', label: 'AUFGABE' },
  };
  const dec = empfehlungColors[decision.empfehlung];
  const inputStyle: React.CSSProperties = {
    width: '100%', padding: '10px 14px', background: T.bg, border: `1px solid ${T.border}`,
    color: T.text, fontFamily: sans, fontSize: 14, borderRadius: 10, outline: 'none',
  };
  const labelStyle: React.CSSProperties = { fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.dim, marginBottom: 4, display: 'block' };
  return (
    <div style={{ padding: 24, maxWidth: 1000, margin: '0 auto', overflowY: 'auto', height: '100%' }}>
      {/* ?? Entscheidungsempfehlung ?? */}
      <Panel style={{ marginBottom: 24, background: dec.bg }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <span style={{ fontSize: 42 }}>{dec.icon}</span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 4 }}>
              Algorithmus-Empfehlung
            </div>
            <div style={{ fontSize: 24, fontWeight: 700, color: dec.border }}>{dec.label}</div>
            <div style={{ fontSize: 14, color: T.textSecondary, marginTop: 4 }}>{decision.details}</div>
          </div>
          <BigRing score={final} size={90} />
        </div>
      </Panel>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        {/* ?? Kosten-Eingabe ?? */}
        <div>
          <SectionTitle icon="?">Kostendaten</SectionTitle>
          <Panel>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div>
                <label style={labelStyle}>Streitwert (€)</label>
                <input type="number" style={inputStyle} value={streitwert} onChange={e => setStreitwert(Number(e.target.value))} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={labelStyle}>Gebührenstufe</label>
                  <select style={{ ...inputStyle, cursor: 'pointer' }} value={stufe} onChange={e => setStufe(Number(e.target.value))}>
                    {[1.0, 1.3, 1.5, 1.8, 2.0, 2.3].map(s => (
                      <option key={s} value={s}>{s}-fach</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label style={labelStyle}>Instanz</label>
                  <input style={inputStyle} value={c.instanz || 'Erstinstanz'} readOnly />
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={labelStyle}>SV-Kosten (€)</label>
                  <input type="number" style={inputStyle} value={svKosten} onChange={e => setSvKosten(Number(e.target.value))} />
                </div>
                <div>
                  <label style={labelStyle}>Reisekosten (€)</label>
                  <input type="number" style={inputStyle} value={reise} onChange={e => setReise(Number(e.target.value))} />
                </div>
              </div>
              <div>
                <label style={labelStyle}>Vergleichsangebot Gegenseite (€)</label>
                <input type="number" style={inputStyle} value={vergleichsangebot} onChange={e => setVergleichsangebot(Number(e.target.value))} />
              </div>
              <button onClick={saveKosten} style={{
                fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.blue,
                border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer', alignSelf: 'flex-end',
              }}>? Kosten speichern</button>
            </div>
          </Panel>
        </div>
        {/* ?? Kostenaufstellung ?? */}
        <div>
          <SectionTitle icon="?">RVG-Kostenberechnung</SectionTitle>
          <Panel>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                ['RVG-Grundgebühr', fmt(kostenResult.basis)],
                [`Anwaltshonorar (${stufe}?VG + 1.2?TG)`, fmt(kostenResult.eigenAnwalt)],
                ['Gerichtsgebühren (3? GKG)', fmt(kostenResult.gerichtskosten)],
                ['Gegneranwalt (Verlustfall)', fmt(kostenResult.gegnerAnwalt)],
                ['SV-Kosten', fmt(svKosten)],
                ['Reisekosten', fmt(reise)],
              ].map(([label, val]) => (
                <div key={label} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${T.border}08` }}>
                  <span style={{ fontSize: 13, color: T.dim }}>{label}</span>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{val}</span>
                </div>
              ))}
            </div>
          </Panel>
        </div>
      </div>
      {/* Divider */}
      <div style={{ borderTop: '1px solid rgba(0,0,0,0.06)', margin: '28px 0 20px' }} />
      {/* ?? Drei Szenarien ?? */}
      <div>
        <SectionTitle icon="?">Szenarien-Vergleich</SectionTitle>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 14 }}>
          {kostenResult.szenarien.map((sz, i) => {
            const isPositive = sz.netto > 0;
            return (
              <Panel key={i}>
                <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 12 }}>{sz.label}</div>
                {[
                  ['Eigene Kosten', fmt(sz.eigenKosten)],
                  ['Gegnerkosten', fmt(sz.gegnerKosten)],
                  ['Gerichtskosten', fmt(sz.gerichtsKosten)],
                ].map(([l, v]) => (
                  <div key={l} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', fontSize: 13, color: T.dim }}>
                    <span>{l}</span><span style={{ fontWeight: 500, color: T.text }}>{v}</span>
                  </div>
                ))}
                <div style={{ borderTop: `1px solid ${T.border}`, marginTop: 8, paddingTop: 8, display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>Nettowert</span>
                  <span style={{ fontSize: 18, fontWeight: 700, color: isPositive ? T.green : T.red }}>
                    {isPositive ? '+' : ''}{fmt(sz.netto)}
                  </span>
                </div>
              </Panel>
            );
          })}
        </div>
      </div>
      {/* Divider */}
      <div style={{ borderTop: '1px solid rgba(0,0,0,0.06)', margin: '28px 0 20px' }} />
      {/* ?? Erwartungswert-Analyse ?? */}
      <div>
        <SectionTitle icon="?">Entscheidungsalgorithmus ? Vergleich vs. Klage vs. Aufgabe</SectionTitle>
        <Panel>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginBottom: 16 }}>
            <div style={{ textAlign: 'center', padding: 16, background: T.bg, borderRadius: 12 }}>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Erwartungswert Klage</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: decision.ewKlage >= 0 ? T.green : T.red }}>
                {fmt(decision.ewKlage)}
              </div>
              <div style={{ fontSize: 11, color: T.dim, marginTop: 4 }}>P(Gewinn) ? Streitwert ? P(Verlust) ? Kosten</div>
            </div>
            <div style={{ textAlign: 'center', padding: 16, background: T.bg, borderRadius: 12 }}>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Erwartungswert Vergleich</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: decision.ewVergleich >= 0 ? T.green : T.red }}>
                {fmt(decision.ewVergleich)}
              </div>
              <div style={{ fontSize: 11, color: T.dim, marginTop: 4 }}>Angebot ? bisherige Kosten</div>
            </div>
            <div style={{ textAlign: 'center', padding: 16, background: T.bg, borderRadius: 12 }}>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Break-Even-Prognose</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: T.blue }}>
                {decision.breakEven}%
              </div>
              <div style={{ fontSize: 11, color: T.dim, marginTop: 4 }}>
                {final > decision.breakEven ? '? Prognose über Break-Even' : '? Prognose unter Break-Even'}
              </div>
            </div>
          </div>
          <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.6, padding: '12px 16px', background: T.bg, borderRadius: 10 }}>
            <strong>Formel:</strong> EW_Klage = P(Gewinn) ? Anspruchswert ? P(Verlust) ? Gesamtkosten_Verlust<br />
            <strong>Break-Even:</strong> Kosten_Niederlage / (Anspruchswert + Kosten_Niederlage)<br />
            <strong>Empfehlung:</strong> KLAGE wenn EW_Klage {'>'} EW_Vergleich + Risikoaufschlag (15%)
          </div>
        </Panel>
      </div>
    </div>
  );
}
