import React, { useState, useMemo } from 'react';
import { LexaraCase } from '@/types/lexara';
import { T, sans, scol } from './theme';
import { Panel, SectionTitle, Chip, Bar, BigRing, Btn } from './Primitives';
import { computeWinProbability } from '@/lib/lexaraUtils';
import {
  computeAnspruchspyramide,
  computeBeweisluecken,
  computeVergleichskorridor,
  computeProzessrisiko,
  computeDynamischeStrategie,
  computeGegnerAnalyse,
  computeVerhandlungssimulation,
  computeGesamtanalyse,
} from '@/lib/litigationAlgorithms';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
interface Props {
  c: LexaraCase;
  onUpdateCase: (c: LexaraCase) => void;
}
const MODULES = [
  { id: 'full_analysis', icon: '?', label: 'Gesamtanalyse', desc: 'Alle Module kompakt: Ansprüche, Beweise, ZOPA, Risiko, Empfehlung' },
  { id: 'claims', icon: '??', label: 'Anspruchspyramide', desc: 'Hierarchische Anspruchsanalyse mit §§, Schlüssigkeit, Beweisbarkeit' },
  { id: 'evidence_gaps', icon: '?', label: 'Beweislücken', desc: 'Beweislastmatrix, Beweismittel-Inventar, kritische Lücken' },  { id: 'settlement', icon: '?', label: 'Vergleichskorridor', desc: 'ZOPA, BATNA, Diskontierung, Stufenklage-Prüfung' },
  { id: 'risk_simulation', icon: '?', label: 'Prozessrisiko', desc: 'Wahrscheinlichkeitsbaum, Monte-Carlo, VaR, Sharpe Ratio' },
  { id: 'dynamic_strategy', icon: '??', label: 'Dynamische Strategie', desc: 'Trigger-Ereignisse, Eskalation, Strategieoptionen-Matrix' },
  { id: 'opponent_litigation', icon: '?', label: 'Gegner-Analyse', desc: 'Wirtschaftliche Situation, Gegenansprüche, Netting' },
  { id: 'negotiation', icon: '?', label: 'Verhandlung', desc: 'Prioritätenliste, Tausch-Analyse, BATNA-Berechnung' },
] as const;
type ModuleId = typeof MODULES[number]['id'];
export function LitigationStrategyView({ c, onUpdateCase }: Props) {
  const [activeModule, setActiveModule] = useState<ModuleId | null>(null);
  const [kiResults, setKiResults] = useState<Record<string, any>>({});
  const [kiLoading, setKiLoading] = useState<ModuleId | null>(null);
  const [useKi, setUseKi] = useState(false);
  const { final } = computeWinProbability(c);
  // ALGORITHMUS: Sofortige Berechnung ? kein Warten auf KI
  const algoResults = useMemo(() => ({
    full_analysis: computeGesamtanalyse(c),
    claims: computeAnspruchspyramide(c),
    evidence_gaps: computeBeweisluecken(c),
    settlement: computeVergleichskorridor(c),
    risk_simulation: computeProzessrisiko(c),
    dynamic_strategy: computeDynamischeStrategie(c),
    opponent_litigation: computeGegnerAnalyse(c),
    negotiation: computeVerhandlungssimulation(c),
  }), [c]);
  // Optional KI-Anreicherung
  const runKiAnalysis = async (moduleId: ModuleId) => {
    setKiLoading(moduleId);
    try {
      const { data, error } = await supabase.functions.invoke('litigation-strategy', {
        body: {
          module: moduleId === 'negotiation' ? 'settlement' : moduleId,
          caseData: {
            name: c.name, number: c.number, court: c.court, type: c.type, goal: c.goal,
            status: c.status, instanz: c.instanz, kernfrage: c.kernfrage,
            arguments: c.arguments, edges: c.edges, evidence: c.evidence,
            persons: c.persons, fristen: c.fristen, kosten: c.kosten,
          },
        },
      });
      if (error) throw error;
      if (data?.error) throw new Error(data.error);
      setKiResults(prev => ({ ...prev, [moduleId]: data.result }));
      toast.success(`KI-Anreicherung für "${MODULES.find(m => m.id === moduleId)?.label}" abgeschlossen`);
    } catch (e: any) {
      toast.error(e.message || 'KI-Analyse fehlgeschlagen');
    } finally {
      setKiLoading(null);
    }
  };
  const getResult = (moduleId: ModuleId) => {
    // If KI result exists and user wants KI, merge; otherwise pure algorithm
    if (useKi && kiResults[moduleId]) return kiResults[moduleId];
    return algoResults[moduleId as keyof typeof algoResults];
  };
  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto', overflowY: 'auto', height: '100%' }}>
      {/* Header */}
      <Panel style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 20 }}>
        <BigRing score={final} size={90} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Prozessstrategie-Algorithmus
          </div>
          <div style={{ fontSize: 20, fontWeight: 700, marginTop: 2 }}>Litigation Intelligence</div>
          <div style={{ fontSize: 13, color: T.dim, marginTop: 4 }}>
            Deterministische Module: Ansprüche, Beweislücken, ZOPA, Monte-Carlo, Verhandlungssimulation
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-end' }}>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span style={{ fontSize: 11, color: T.dim }}>KI-Anreicherung</span>
            <button onClick={() => setUseKi(!useKi)} style={{
              width: 40, height: 22, borderRadius: 11, border: 'none', cursor: 'pointer',
              background: useKi ? T.blue : T.muted, transition: 'background 0.2s', position: 'relative',
            }}>
              <div style={{
                width: 18, height: 18, borderRadius: 9, background: '#fff',
                position: 'absolute', top: 2, left: useKi ? 20 : 2, transition: 'left 0.2s',
                boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
              }} />
            </button>
          </div>
          <span style={{ fontSize: 10, color: T.dim }}>
            {useKi ? '? KI aktiv ? ergänzt Algorithmus' : '? Rein algorithmisch'}
          </span>
        </div>
      </Panel>
      {/* Module Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 12, marginBottom: 24 }}>
        {MODULES.map(m => {
          const isActive = activeModule === m.id;
          const hasKi = !!kiResults[m.id];
          const isKiLoading = kiLoading === m.id;
          return (
            <Panel key={m.id} onClick={() => setActiveModule(m.id)} style={{
              cursor: 'pointer', border: isActive ? `2px solid ${T.blue}` : undefined,
            }}>
              <div style={{ fontSize: 24, marginBottom: 6 }}>{m.icon}</div>
              <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 3 }}>{m.label}</div>
              <div style={{ fontSize: 11, color: T.dim, lineHeight: 1.5, marginBottom: 8 }}>{m.desc}</div>
              <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                <Chip small color={T.green}>? Berechnet</Chip>
                {useKi && !hasKi && !isKiLoading && (
                  <button onClick={(e) => { e.stopPropagation(); runKiAnalysis(m.id); }} style={{
                    fontFamily: sans, fontSize: 10, color: T.blue, background: T.blue + '10',
                    border: 'none', borderRadius: 4, padding: '2px 6px', cursor: 'pointer',
                  }}>? KI</button>
                )}
                {hasKi && <Chip small color={T.blue}>? KI</Chip>}
                {isKiLoading && <Chip small color={T.orange}>?</Chip>}
              </div>
            </Panel>
          );
        })}
      </div>
      {/* Results */}
      {activeModule && (
        <ResultRenderer moduleId={activeModule} result={getResult(activeModule)} />
      )}
    </div>
  );
}
function ResultRenderer({ moduleId, result }: { moduleId: string; result: any }) {
  if (!result) return null;
  switch (moduleId) {
    case 'full_analysis': return <FullAnalysisResult r={result} />;
    case 'claims': return <ClaimsResult r={result} />;
    case 'evidence_gaps': return <EvidenceGapsResult r={result} />;
    case 'settlement': return <SettlementResult r={result} />;
    case 'risk_simulation': return <RiskSimResult r={result} />;
    case 'dynamic_strategy': return <DynamicStrategyResult r={result} />;
    case 'opponent_litigation': return <OpponentResult r={result} />;
    case 'negotiation': return <NegotiationResult r={result} />;
    default: return <Panel><pre style={{ fontSize: 12, whiteSpace: 'pre-wrap' }}>{JSON.stringify(result, null, 2)}</pre></Panel>;
  }
}
const fmt = (n: number) => typeof n === 'number' ? n.toLocaleString('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 }) : '?';
const EBENE_COLORS: Record<string, string> = { primaer: T.blue, sekundaer: T.green, hilfs: T.orange, prozessual: T.dim };
const SEV_COLORS: Record<string, string> = { kritisch: '#ff3b30', mittel: '#ff9500', gering: '#34c759' };
// ??? FULL ANALYSIS ???
function FullAnalysisResult({ r }: { r: any }) {
  const empCol = r.empfehlung === 'klage' ? '#34c759' : r.empfehlung === 'vergleich' ? '#ff9500' : '#ff3b30';
  const empIcon = r.empfehlung === 'klage' ? '??' : r.empfehlung === 'vergleich' ? '?' : '?';
  return (
    <div>
      <Panel style={{ background: empCol + '0a', marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 36 }}>{empIcon}</span>
          <div>
            <div style={{ fontSize: 18, fontWeight: 700, color: empCol, textTransform: 'uppercase' }}>{r.empfehlung}</div>
            <div style={{ fontSize: 13, color: T.dim, marginTop: 4, lineHeight: 1.6 }}>{r.begruendung}</div>
          </div>
        </div>
      </Panel>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        <div>
          <SectionTitle icon="??">Top-Ansprüche</SectionTitle>
          {(r.ansprueche_top3 || []).map((a: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{a.anspruchsgrundlage}</div>
              {a.paragraphen && <div style={{ fontSize: 12, color: T.blue, marginBottom: 4 }}>{a.paragraphen}</div>}
              <div style={{ display: 'flex', gap: 8 }}>
                <Chip small color={scol(a.erfolgswahrscheinlichkeit)}>{a.erfolgswahrscheinlichkeit}%</Chip>
                {a.betrag && <Chip small>{fmt(a.betrag)}</Chip>}
              </div>
            </Panel>
          ))}
        </div>
        <div>
          <SectionTitle icon="?">Risikokennzahlen</SectionTitle>
          <Panel>
            {[
              ['Erwartungswert', fmt(r.risiko?.erwartungswert)],
              ['VaR 95%', fmt(r.risiko?.var_95)],
              ['Break-Even', `${r.risiko?.break_even}%`],
              ['Sharpe Ratio', r.risiko?.sharpe_ratio?.toFixed(2)],
            ].map(([l, v]) => (
              <div key={l as string} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${T.border}08` }}>
                <span style={{ fontSize: 13, color: T.dim }}>{l}</span>
                <span style={{ fontSize: 14, fontWeight: 600 }}>{v}</span>
              </div>
            ))}
          </Panel>
          {r.zopa && (
            <>
              <SectionTitle icon="?">ZOPA</SectionTitle>
              <Panel>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <span style={{ fontSize: 12, color: T.dim }}>Untergrenze</span>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{fmt(r.zopa.untergrenze)}</span>
                </div>
                <Bar v={r.zopa.optimal || (r.zopa.untergrenze + r.zopa.obergrenze) / 2} max={r.zopa.obergrenze} color={T.green} h={8} />
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
                  <span style={{ fontSize: 12, color: T.dim }}>Obergrenze</span>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{fmt(r.zopa.obergrenze)}</span>
                </div>
              </Panel>
            </>
          )}
        </div>
      </div>
      {r.kritische_beweisluecken?.length > 0 && (
        <>
          <SectionTitle icon="?">Kritische Beweislücken</SectionTitle>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
            {r.kritische_beweisluecken.map((l: any, i: number) => (
              <Panel key={i} style={{ background: '#ff3b3008' }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#ff3b30', marginBottom: 4 }}>?? {l.merkmal}</div>
                <div style={{ fontSize: 12, color: T.dim }}>{l.massnahme}</div>
              </Panel>
            ))}
          </div>
        </>
      )}
      {r.naechste_schritte?.length > 0 && (
        <>
          <SectionTitle icon="?">Nächste Schritte</SectionTitle>
          <Panel>
            {r.naechste_schritte.map((s: any) => (
              <div key={s.nr} style={{ display: 'flex', gap: 12, padding: '8px 0', borderBottom: `1px solid ${T.border}08` }}>
                <div style={{ width: 28, height: 28, borderRadius: '50%', background: T.blue, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 700, flexShrink: 0 }}>{s.nr}</div>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{s.aktion}</div>
                  <div style={{ fontSize: 12, color: T.dim }}>{s.timing}</div>
                </div>
              </div>
            ))}
          </Panel>
        </>
      )}
    </div>
  );
}
// ??? CLAIMS ???
function ClaimsResult({ r }: { r: any }) {
  return (
    <div>
      {r.gesamtbetrag != null && (
        <Panel style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 12, color: T.dim }}>Gesamtanspruchswert</div>
          <div style={{ fontSize: 24, fontWeight: 700, color: T.blue }}>{fmt(r.gesamtbetrag)}</div>
        </Panel>
      )}
      {['primaer', 'sekundaer', 'hilfs', 'prozessual'].map(ebene => {
        const items = (r.ansprueche || []).filter((a: any) => a.ebene === ebene);
        if (!items.length) return null;
        const labels: Record<string, string> = { primaer: 'Primäre Ansprüche', sekundaer: 'Sekundäre Ansprüche', hilfs: 'Hilfsansprüche', prozessual: 'Prozessuale Nebenansprüche' };
        return (
          <div key={ebene} style={{ marginBottom: 16 }}>
            <SectionTitle icon="??">{labels[ebene]}</SectionTitle>
            {items.map((a: any, i: number) => (
              <Panel key={i} style={{ marginBottom: 8, borderLeft: `3px solid ${EBENE_COLORS[ebene] || T.dim}` }}>
                <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4 }}>{a.label}</div>
                <div style={{ fontSize: 12, color: T.blue, marginBottom: 6 }}>{a.paragraphen}</div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 6 }}>
                  <Chip small color={scol(a.schluessigkeit_pct)}>Schlüssigkeit: {a.schluessigkeit_pct}%</Chip>
                  <Chip small color={scol(a.beweisbarkeit_pct)}>Beweisbarkeit: {a.beweisbarkeit_pct}%</Chip>
                  {a.betrag && <Chip small>{fmt(a.betrag)}</Chip>}
                  {a.verjaehrung_status && <Chip small color={a.verjaehrung_status.includes('verjährt') ? '#ff3b30' : T.green}>{a.verjaehrung_status}</Chip>}
                </div>
                {a.begruendung && <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.5 }}>{a.begruendung}</div>}
              </Panel>
            ))}
          </div>
        );
      })}
    </div>
  );
}
// ??? EVIDENCE GAPS ???
function EvidenceGapsResult({ r }: { r: any }) {
  return (
    <div>
      {r.beweislast_matrix?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Beweislast-Matrix</SectionTitle>
          <Panel>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
                <thead>
                  <tr style={{ borderBottom: `2px solid ${T.border}` }}>
                    {['Tatbestandsmerkmal', 'Beweislast', 'Vorhanden?', 'Typ', 'Kraft', 'Angreifbar?'].map(h => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 6px', fontSize: 11, fontWeight: 700, color: T.dim, textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {r.beweislast_matrix.map((b: any, i: number) => (
                    <tr key={i} style={{ borderBottom: `1px solid ${T.border}08` }}>
                      <td style={{ padding: '8px 6px', fontWeight: 500 }}>{b.tatbestandsmerkmal}</td>
                      <td style={{ padding: '8px 6px' }}>
                        <Chip small color={b.beweislast_traeger === 'eigen' ? T.orange : T.green}>
                          {b.beweislast_traeger === 'eigen' ? '?? Eigen' : '? Gegner'}
                        </Chip>
                      </td>
                      <td style={{ padding: '8px 6px' }}>{b.beweismittel_vorhanden ? '?' : '?'}</td>
                      <td style={{ padding: '8px 6px', color: T.dim }}>{b.beweismittel_typ || '?'}</td>
                      <td style={{ padding: '8px 6px' }}>
                        <Chip small color={b.beweiskraft === 'stark' ? T.green : b.beweiskraft === 'mittel' ? T.orange : '#ff3b30'}>
                          {b.beweiskraft}
                        </Chip>
                      </td>
                      <td style={{ padding: '8px 6px', fontSize: 12, color: T.dim }}>{b.angreifbarkeit || '?'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Panel>
        </div>
      )}
      {r.luecken?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="??">Beweislücken ({r.luecken.length})</SectionTitle>
          {r.luecken.map((l: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8, borderLeft: `3px solid ${SEV_COLORS[l.schweregrad] || T.dim}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: 600 }}>{l.merkmal}</span>
                <Chip small variant="filled" color={SEV_COLORS[l.schweregrad]}>{l.schweregrad}</Chip>
              </div>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Fehlend: {l.fehlender_beweis}</div>
              <div style={{ fontSize: 12, color: T.blue }}>? {l.massnahme}</div>
            </Panel>
          ))}
        </div>
      )}
      {r.gesamtbewertung && (
        <Panel style={{ background: T.blue + '08' }}>
          <div style={{ fontSize: 13, lineHeight: 1.6 }}>{r.gesamtbewertung}</div>
        </Panel>
      )}
    </div>
  );
}
// ??? SETTLEMENT (ZOPA) ???
function SettlementResult({ r }: { r: any }) {
  return (
    <div>
      <Panel style={{ marginBottom: 16 }}>
        <SectionTitle icon="?">Vergleichskorridor (ZOPA)</SectionTitle>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginBottom: 16 }}>
          <div style={{ textAlign: 'center', padding: 16, background: T.bg, borderRadius: 12 }}>
            <div style={{ fontSize: 11, color: T.dim }}>Min. Kläger</div>
            <div style={{ fontSize: 22, fontWeight: 700, color: T.blue }}>{fmt(r.mindestbetrag_klaeger)}</div>
          </div>
          <div style={{ textAlign: 'center', padding: 16, background: '#34c75908', borderRadius: 12, border: `2px solid ${T.green}` }}>
            <div style={{ fontSize: 11, color: T.dim }}>Optimal</div>
            <div style={{ fontSize: 22, fontWeight: 700, color: T.green }}>{fmt(r.optimaler_vergleichsbetrag || (r.zopa_untergrenze + r.zopa_obergrenze) / 2)}</div>
          </div>
          <div style={{ textAlign: 'center', padding: 16, background: T.bg, borderRadius: 12 }}>
            <div style={{ fontSize: 11, color: T.dim }}>Max. Beklagter</div>
            <div style={{ fontSize: 22, fontWeight: 700, color: T.orange }}>{fmt(r.maximalbetrag_beklagter)}</div>
          </div>
        </div>
        {r.zopa_obergrenze > 0 && (
          <div style={{ position: 'relative', height: 30, background: T.bg, borderRadius: 8, overflow: 'hidden', marginBottom: 12 }}>
            <div style={{
              position: 'absolute', left: `${(r.zopa_untergrenze / r.maximalbetrag_beklagter) * 100}%`,
              width: `${((r.zopa_obergrenze - r.zopa_untergrenze) / r.maximalbetrag_beklagter) * 100}%`,
              height: '100%', background: T.green + '30', borderRadius: 6,
            }}>
              <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 700, color: T.green }}>
                ZOPA: {fmt(r.zopa_untergrenze)} ? {fmt(r.zopa_obergrenze)}
              </div>
            </div>
          </div>
        )}
        {r.berechnung_klaeger && <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Kläger: {r.berechnung_klaeger}</div>}
        {r.berechnung_beklagter && <div style={{ fontSize: 12, color: T.dim }}>Beklagter: {r.berechnung_beklagter}</div>}
      </Panel>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        {r.rapb != null && (
          <Panel>
            <div style={{ fontSize: 12, color: T.dim }}>Risiko-Adjustierter Prozessbarwert</div>
            <div style={{ fontSize: 22, fontWeight: 700, color: r.rapb >= 0 ? T.green : '#ff3b30' }}>{fmt(r.rapb)}</div>
            {r.diskontierungssatz && <div style={{ fontSize: 11, color: T.dim }}>Diskontierung: {r.diskontierungssatz}% p.a., {r.verfahrensdauer_monate} Monate</div>}
          </Panel>
        )}
        {r.batna_wert != null && (
          <Panel>
            <div style={{ fontSize: 12, color: T.dim }}>BATNA</div>
            <div style={{ fontSize: 22, fontWeight: 700 }}>{fmt(r.batna_wert)}</div>
            {r.batna_beschreibung && <div style={{ fontSize: 12, color: T.dim, marginTop: 4 }}>{r.batna_beschreibung}</div>}
          </Panel>
        )}
      </div>
      {r.stufenklage_sinnvoll != null && (
        <Panel style={{ marginBottom: 16, background: r.stufenklage_sinnvoll ? T.blue + '08' : T.bg }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>
            {r.stufenklage_sinnvoll ? '? Stufenklage empfohlen (§ 254 ZPO)' : '? Stufenklage nicht empfohlen'}
          </div>
          {r.stufenklage_begruendung && <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.5 }}>{r.stufenklage_begruendung}</div>}
        </Panel>
      )}
      {r.empfehlung && (
        <Panel style={{ background: T.blue + '08' }}>
          <div style={{ fontSize: 13, lineHeight: 1.6 }}>{r.empfehlung}</div>
        </Panel>
      )}
    </div>
  );
}
// ??? RISK SIMULATION ???
function RiskSimResult({ r }: { r: any }) {
  return (
    <div>
      {r.wahrscheinlichkeitsbaum?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Wahrscheinlichkeitsbaum (5 Stufen)</SectionTitle>
          <Panel>
            {r.wahrscheinlichkeitsbaum.map((s: any) => (
              <div key={s.stufe} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: `1px solid ${T.border}08` }}>
                <div style={{ width: 32, height: 32, borderRadius: '50%', background: scol(s.wahrscheinlichkeit_pct), color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700, flexShrink: 0 }}>S{s.stufe}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{s.name}</div>
                  {s.begruendung && <div style={{ fontSize: 12, color: T.dim }}>{s.begruendung}</div>}
                </div>
                <div style={{ width: 120 }}><Bar v={s.wahrscheinlichkeit_pct} max={100} color={scol(s.wahrscheinlichkeit_pct)} h={6} /></div>
                <span style={{ fontSize: 16, fontWeight: 700, color: scol(s.wahrscheinlichkeit_pct), width: 50, textAlign: 'right' }}>{s.wahrscheinlichkeit_pct}%</span>
              </div>
            ))}
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', marginTop: 8, borderTop: `2px solid ${T.border}` }}>
              <span style={{ fontSize: 14, fontWeight: 700 }}>Gesamterfolgswahrscheinlichkeit</span>
              <span style={{ fontSize: 20, fontWeight: 700, color: scol(r.gesamt_erfolgswahrscheinlichkeit) }}>{r.gesamt_erfolgswahrscheinlichkeit}%</span>
            </div>
          </Panel>
        </div>
      )}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 16 }}>
        {[
          ['Erwartungswert', fmt(r.erwartungswert), r.erwartungswert >= 0 ? T.green : '#ff3b30'],
          ['VaR 95%', fmt(r.var_95), '#ff9500'],
          ['Break-Even', `${r.break_even_pct}%`, T.blue],
          ['RAPB', fmt(r.rapb), r.rapb >= 0 ? T.green : '#ff3b30'],
          ['Sharpe Ratio', r.sharpe_ratio?.toFixed(2) || '?', T.blue],
          ['VaR 99%', fmt(r.var_99), '#ff3b30'],
        ].map(([label, val, col]) => (
          <Panel key={label as string} style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: T.dim }}>{label}</div>
            <div style={{ fontSize: 20, fontWeight: 700, color: col as string }}>{val}</div>
          </Panel>
        ))}
      </div>
      {r.instanz_kosten?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Instanz-Kosten-Matrix</SectionTitle>
          <Panel>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
                <thead>
                  <tr style={{ borderBottom: `2px solid ${T.border}` }}>
                    {['Instanz', 'Szenario', 'Gericht', 'Eigen-RA', 'Gegner-RA', 'Netto'].map(h => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 6px', fontSize: 11, fontWeight: 700, color: T.dim }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {r.instanz_kosten.map((k: any, i: number) => (
                    <tr key={i} style={{ borderBottom: `1px solid ${T.border}08` }}>
                      <td style={{ padding: '6px', fontWeight: 500 }}>{k.instanz}</td>
                      <td style={{ padding: '6px' }}>{k.szenario}</td>
                      <td style={{ padding: '6px' }}>{fmt(k.gerichtsgebuehren || 0)}</td>
                      <td style={{ padding: '6px' }}>{fmt(k.eigen_anwalt || 0)}</td>
                      <td style={{ padding: '6px' }}>{fmt(k.gegner_anwalt || 0)}</td>
                      <td style={{ padding: '6px', fontWeight: 700, color: k.netto >= 0 ? T.green : '#ff3b30' }}>{fmt(k.netto)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Panel>
        </div>
      )}
      {r.empfehlung && (
        <Panel style={{ background: T.blue + '08' }}>
          <div style={{ fontSize: 13, lineHeight: 1.6 }}>{r.empfehlung}</div>
        </Panel>
      )}
    </div>
  );
}
// ??? DYNAMIC STRATEGY ???
function DynamicStrategyResult({ r }: { r: any }) {
  return (
    <div>
      {r.strategieoptionen?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="??">Strategieoptionen-Matrix</SectionTitle>
          {(r.strategieoptionen || []).filter((s: any) => !s.dominiert).map((s: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8, border: s.empfohlen ? `2px solid ${T.green}` : undefined }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <span style={{ fontSize: 15, fontWeight: 700 }}>{s.name}</span>
                <div style={{ display: 'flex', gap: 6 }}>
                  {s.empfohlen && <Chip small variant="filled" color={T.green}>? Empfohlen</Chip>}
                  <Chip small>EW: {fmt(s.erwartungswert)}</Chip>
                  <Chip small color={scol(100 - s.risiko_score * 10)}>Risiko: {s.risiko_score}/10</Chip>
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, fontSize: 12, color: T.dim }}>
                {s.verfahrensart && <div>? {s.verfahrensart}</div>}
                {s.zeitpunkt && <div>? {s.zeitpunkt}</div>}
                {s.instanzenziel && <div>?? {s.instanzenziel}</div>}
              </div>
            </Panel>
          ))}
          {(r.strategieoptionen || []).filter((s: any) => s.dominiert).length > 0 && (
            <div style={{ fontSize: 12, color: T.dim, fontStyle: 'italic', marginTop: 4 }}>
              {r.strategieoptionen.filter((s: any) => s.dominiert).length} dominierte Strategien ausgeschlossen
            </div>
          )}
        </div>
      )}
      {r.trigger_ereignisse?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Trigger-Ereignisse</SectionTitle>
          {r.trigger_ereignisse.map((t: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{t.ereignis}</div>
              <div style={{ fontSize: 12, color: T.dim }}>{t.auswirkung}</div>
              <div style={{ fontSize: 12, color: T.blue, marginTop: 4 }}>? {t.reaktion}</div>
            </Panel>
          ))}
        </div>
      )}
      {r.eskalationsmassnahmen?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Eskalations-Framework</SectionTitle>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, color: '#ff3b30', textTransform: 'uppercase', marginBottom: 8 }}>?? Eskalation</div>
              {(r.eskalationsmassnahmen || []).filter((e: any) => e.typ === 'eskalation').map((e: any, i: number) => (
                <Panel key={i} style={{ marginBottom: 6, background: '#ff3b3005' }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{e.massnahme}</div>
                  <div style={{ fontSize: 12, color: T.dim }}>{e.erwartete_wirkung}</div>
                </Panel>
              ))}
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, color: T.green, textTransform: 'uppercase', marginBottom: 8 }}>?? De-Eskalation</div>
              {(r.eskalationsmassnahmen || []).filter((e: any) => e.typ === 'de_eskalation').map((e: any, i: number) => (
                <Panel key={i} style={{ marginBottom: 6, background: '#34c75905' }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{e.massnahme}</div>
                  <div style={{ fontSize: 12, color: T.dim }}>{e.erwartete_wirkung}</div>
                </Panel>
              ))}
            </div>
          </div>
        </div>
      )}
      {r.naechste_schritte?.length > 0 && (
        <>
          <SectionTitle icon="?">Nächste Schritte</SectionTitle>
          <Panel>
            {r.naechste_schritte.map((s: any) => (
              <div key={s.nr} style={{ display: 'flex', gap: 12, padding: '8px 0', borderBottom: `1px solid ${T.border}08` }}>
                <div style={{ width: 24, height: 24, borderRadius: '50%', background: T.blue, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700, flexShrink: 0 }}>{s.nr}</div>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{s.aktion}</div>
                  <div style={{ fontSize: 12, color: T.dim }}>{s.wann} ? {s.ziel}</div>
                </div>
              </div>
            ))}
          </Panel>
        </>
      )}
      {r.empfehlung && (
        <Panel style={{ marginTop: 16, background: T.blue + '08' }}>
          <div style={{ fontSize: 13, lineHeight: 1.6 }}>{r.empfehlung}</div>
        </Panel>
      )}
    </div>
  );
}
// ??? OPPONENT ???
function OpponentResult({ r }: { r: any }) {
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        <Panel>
          <div style={{ fontSize: 12, color: T.dim }}>Vollstreckungswahrscheinlichkeit</div>
          <div style={{ fontSize: 24, fontWeight: 700, color: scol(r.vollstreckungswahrscheinlichkeit) }}>{r.vollstreckungswahrscheinlichkeit}%</div>
          <Bar v={r.vollstreckungswahrscheinlichkeit} max={100} color={scol(r.vollstreckungswahrscheinlichkeit)} h={6} />
        </Panel>
        <Panel>
          <div style={{ fontSize: 12, color: T.dim }}>Vergleichsmotivation</div>
          <div style={{ fontSize: 24, fontWeight: 700, color: scol(r.vergleichsmotivation) }}>{r.vergleichsmotivation}%</div>
          <Bar v={r.vergleichsmotivation} max={100} color={scol(r.vergleichsmotivation)} h={6} />
        </Panel>
      </div>
      {r.gegenansprueche?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="??">Gegenansprüche</SectionTitle>
          {r.gegenansprueche.map((g: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 8, background: '#ff3b3005' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ fontSize: 14, fontWeight: 600 }}>{g.anspruch}</span>
                <div style={{ display: 'flex', gap: 6 }}>
                  {g.betrag && <Chip small>{fmt(g.betrag)}</Chip>}
                  <Chip small color={scol(100 - g.wahrscheinlichkeit)}>{g.wahrscheinlichkeit}%</Chip>
                </div>
              </div>
            </Panel>
          ))}
          {r.netto_prozessgegenstand != null && (
            <Panel style={{ background: T.blue + '08' }}>
              <div style={{ fontSize: 12, color: T.dim }}>Netto-Prozessgegenstand</div>
              <div style={{ fontSize: 22, fontWeight: 700, color: r.netto_prozessgegenstand >= 0 ? T.green : '#ff3b30' }}>{fmt(r.netto_prozessgegenstand)}</div>
            </Panel>
          )}
        </div>
      )}
      {r.schwachstellen?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Schwachstellen Gegner</SectionTitle>
          <Panel>
            {r.schwachstellen.map((s: string, i: number) => (
              <div key={i} style={{ padding: '6px 0', borderBottom: `1px solid ${T.border}08`, fontSize: 13 }}>? {s}</div>
            ))}
          </Panel>
        </div>
      )}
      {r.prozessverhalten_prognose && (
        <Panel style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>? Prozessverhalten-Prognose</div>
          <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.6 }}>{r.prozessverhalten_prognose}</div>
        </Panel>
      )}
      {r.empfehlung && (
        <Panel style={{ background: T.blue + '08' }}>
          <div style={{ fontSize: 13, lineHeight: 1.6 }}>{r.empfehlung}</div>
        </Panel>
      )}
    </div>
  );
}
// ??? NEGOTIATION (NEW) ???
function NegotiationResult({ r }: { r: any }) {
  return (
    <div>
      {/* Verhandlungsstärke */}
      <Panel style={{ marginBottom: 16, display: 'flex', alignItems: 'center', gap: 20 }}>
        <div>
          <div style={{ fontSize: 12, color: T.dim }}>Verhandlungsstärke</div>
          <div style={{ fontSize: 36, fontWeight: 700, color: scol(r.verhandlungsstaerke) }}>{r.verhandlungsstaerke}<span style={{ fontSize: 16 }}>/100</span></div>
        </div>
        <div style={{ flex: 1 }}><Bar v={r.verhandlungsstaerke} max={100} color={scol(r.verhandlungsstaerke)} h={10} /></div>
      </Panel>
      {/* Prioritätenliste */}
      {r.prioritaeten?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Verhandlungs-Prioritätenliste</SectionTitle>
          {/* Gegner-Bedrohungen zuerst */}
          <div style={{ fontSize: 11, fontWeight: 700, color: '#ff3b30', textTransform: 'uppercase', marginBottom: 8, marginTop: 4 }}>
            ? Zu neutralisieren (Gegner-Argumente)
          </div>
          {r.prioritaeten.filter((p: any) => p.side === 'opp').map((p: any) => (
            <Panel key={p.argument_id} style={{ marginBottom: 6, borderLeft: `3px solid ${p.score_impact > 10 ? '#ff3b30' : p.score_impact > 5 ? '#ff9500' : T.green}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: 600 }}>{p.label}</span>
                <div style={{ display: 'flex', gap: 6 }}>
                  <Chip small>Impact: {p.score_impact}%</Chip>
                  <Chip small color={T.dim}>Kraft: {p.strength}/10</Chip>
                  <Chip small color={T.dim}>{p.evidence_count} Beweise</Chip>
                </div>
              </div>
              <div style={{ fontSize: 12, color: T.dim }}>{p.empfehlung}</div>
            </Panel>
          ))}
          {/* Eigene Stärken */}
          <div style={{ fontSize: 11, fontWeight: 700, color: T.blue, textTransform: 'uppercase', marginBottom: 8, marginTop: 16 }}>
            ? Eigene Verhandlungsstärken
          </div>
          {r.prioritaeten.filter((p: any) => p.side === 'own').map((p: any) => (
            <Panel key={p.argument_id} style={{ marginBottom: 6, borderLeft: `3px solid ${p.score_impact > 10 ? T.blue : p.score_impact > 5 ? T.green : T.dim}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: 600 }}>{p.label}</span>
                <div style={{ display: 'flex', gap: 6 }}>
                  <Chip small>Impact: {p.score_impact}%</Chip>
                  <Chip small color={T.dim}>Kraft: {p.strength}/10</Chip>
                </div>
              </div>
              <div style={{ fontSize: 12, color: T.dim }}>{p.empfehlung}</div>
            </Panel>
          ))}
        </div>
      )}
      {/* Tausch-Analyse */}
      {r.tausch_optionen?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <SectionTitle icon="?">Tausch-Analyse (Konzessionen)</SectionTitle>
          <Panel>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
                <thead>
                  <tr style={{ borderBottom: `2px solid ${T.border}` }}>
                    {['Aufgeben (eigene Position)', 'Score-Verlust', 'Erhalten (Gegner gibt auf)', 'Score-Gewinn', 'Netto'].map(h => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 6px', fontSize: 11, fontWeight: 700, color: T.dim, textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {r.tausch_optionen.map((t: any, i: number) => (
                    <tr key={i} style={{ borderBottom: `1px solid ${T.border}08` }}>
                      <td style={{ padding: '8px 6px' }}>{t.aufgeben_label}</td>
                      <td style={{ padding: '8px 6px', color: '#ff3b30' }}>-{t.aufgeben_score_verlust}%</td>
                      <td style={{ padding: '8px 6px' }}>{t.erhalten_label}</td>
                      <td style={{ padding: '8px 6px', color: T.green }}>+{t.erhalten_score_gewinn}%</td>
                      <td style={{ padding: '8px 6px', fontWeight: 700, color: t.netto_effekt >= 0 ? T.green : '#ff3b30' }}>
                        {t.netto_effekt >= 0 ? '+' : ''}{t.netto_effekt}%
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Panel>
        </div>
      )}
      {/* BATNA */}
      {r.batna && (
        <Panel style={{ marginBottom: 16, background: T.blue + '08' }}>
          <SectionTitle icon="?">BATNA (Best Alternative)</SectionTitle>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 12 }}>
            <div>
              <div style={{ fontSize: 12, color: T.dim }}>BATNA-Wert</div>
              <div style={{ fontSize: 24, fontWeight: 700 }}>{fmt(r.batna.wert)}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: T.dim }}>Mindest-Vergleichsschwelle</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: T.orange }}>{fmt(r.batna.schwelle)}</div>
            </div>
          </div>
          <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.6 }}>{r.batna.empfehlung}</div>
        </Panel>
      )}
      {r.empfehlung && (
        <Panel style={{ background: T.blue + '08' }}>
          <div style={{ fontSize: 13, lineHeight: 1.6 }}>{r.empfehlung}</div>
        </Panel>
      )}
    </div>
  );
}
