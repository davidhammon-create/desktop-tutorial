import React, { useState } from 'react';
import { T, sans } from '@/components/lexara/theme';
import {
  ClauseAnalysisResult, ClauseScore, ClauseDefinition, ContractType, Perspective,
  getClausesForType, getClauseById, getClassLabel, groupClausesByGroup,
  computeGesamtScore, getEmpfehlung, getTrafficLight
} from '@/types/contractClauses';
import { BusinessScenario } from '@/types/business';
import { supabase } from '@/integrations/supabase/client';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
const CONTRACT_TYPES: { id: ContractType; label: string; icon: string }[] = [
  { id: 'Dienstleistung', label: 'Dienstleistungsvertrag', icon: '?' },
  { id: 'Kauf', label: 'Kaufvertrag', icon: '?' },
  { id: 'Lizenz', label: 'Lizenzvertrag', icon: '?' },
];
const PERSPECTIVES: { id: Perspective; label: string }[] = [
  { id: 'A', label: 'Auftraggeber / Käufer / Lizenznehmer' },
  { id: 'L', label: 'Leistungserbringer / Verkäufer / Lizenzgeber' },
];
const ampelColor = (tl: string) => tl === 'green' ? '#34c759' : tl === 'yellow' ? '#ff9f0a' : '#ff3b30';
const ampelBg = (tl: string) => tl === 'green' ? '#34c75912' : tl === 'yellow' ? '#ff9f0a12' : '#ff3b3012';
export function ClauseAnalysisView({ scenario, onUpdate }: Props) {
  const [contractType, setContractType] = useState<ContractType>('Dienstleistung');
  const [perspective, setPerspective] = useState<Perspective>('A');
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<ClauseAnalysisResult | null>(null);
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());
  const [filter, setFilter] = useState<'all' | 'red' | 'yellow' | 'green'>('all');
  const toggleGroup = (g: string) => {
    const next = new Set(expandedGroups);
    next.has(g) ? next.delete(g) : next.add(g);
    setExpandedGroups(next);
  };
  const analyze = async () => {
    if (!text.trim()) return;
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const definitions = getClausesForType(contractType);
      const clauseList = definitions.map(c => `${c.id}: ${c.name} (${c.description})`).join('\n');
      const { data, error: fnError } = await supabase.functions.invoke('analyze-contract-clauses', {
        body: {
          text: text.trim(),
          contractType,
          perspective,
          clauseList,
          context: scenario.description || '',
        },
      });
      if (fnError) throw new Error(fnError.message);
      if (!data?.success) throw new Error(data?.error || 'Analyse fehlgeschlagen');
      const aiClauses: ClauseScore[] = (data.data.clauses || []).map((c: any) => {
        const def = definitions.find(d => d.id === c.clauseId);
        return {
          clauseId: c.clauseId,
          rawValue: c.rawValue || 'nicht gefunden',
          score: Math.max(0, Math.min(100, c.score || 0)),
          confidence: c.confidence || 50,
          trafficLight: getTrafficLight(c.score || 0, def?.klpiClass || 3),
          comment: c.comment || '',
          bewertung: c.bewertung || '',
          verhandlungsempfehlung: c.verhandlungsempfehlung || '',
        };
      });
      const gesamtScore = computeGesamtScore(aiClauses, definitions);
      const reds = aiClauses.filter(c => c.trafficLight === 'red').map(c => c.clauseId);
      const greens = aiClauses.filter(c => c.trafficLight === 'green' && c.score >= 80);
      const yellows = aiClauses.filter(c => c.trafficLight === 'yellow');
      const analysisResult: ClauseAnalysisResult = {
        contractType,
        perspective,
        gesamtScore,
        clauses: aiClauses,
        zusammenfassung: data.data.zusammenfassung || '',
        empfehlung: getEmpfehlung(gesamtScore),
        kritischeKlauseln: reds,
        staerken: greens.slice(0, 5).map(c => getClauseById(c.clauseId)?.name || c.clauseId),
        schwaechen: aiClauses.filter(c => c.trafficLight === 'red').slice(0, 5).map(c => getClauseById(c.clauseId)?.name || c.clauseId),
      };
      setResult(analysisResult);
      setExpandedGroups(new Set()); // collapse all initially
    } catch (e: any) {
      setError(e.message || 'Unbekannter Fehler');
    } finally {
      setLoading(false);
    }
  };
  const definitions = getClausesForType(contractType);
  const grouped = result ? groupClausesByGroup(result.clauses, definitions) : {};
  const filteredGrouped = Object.fromEntries(
    Object.entries(grouped).map(([g, data]) => [
      g,
      {
        ...data,
        clauses: filter === 'all' ? data.clauses : data.clauses.filter(c => c.trafficLight === filter),
      },
    ]).filter(([, data]) => (data as any).clauses.length > 0)
  );
  const empfehlungColor = (e: string) =>
    e === 'Unterzeichnen' ? '#34c759' : e === 'Nachverhandeln' ? '#ff9f0a' : '#ff3b30';
  return (
    <div style={{ padding: '24px 40px', maxWidth: 1000 }}>
      {/* Disclaimer */}
      <div style={{
        padding: '14px 18px', borderRadius: 12, marginBottom: 20,
        background: '#fff3cd', border: '1px solid #ffc107',
        fontSize: 13, color: '#664d03', lineHeight: 1.6,
      }}>
        <strong>?? KI-gestützte Klauselanalyse</strong> ? Alle Scores sind KI-Schätzungen und müssen juristisch geprüft werden.      </div>
      {/* Setup: Contract Type + Perspective */}
      {!result && (
        <div style={{ background: T.surface, borderRadius: 16, padding: 28, marginBottom: 20 }}>
          <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>Vertragstyp & Perspektive</div>
          <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
            {CONTRACT_TYPES.map(ct => (
              <button key={ct.id} onClick={() => setContractType(ct.id)}
                style={{
                  fontFamily: sans, fontSize: 14, fontWeight: contractType === ct.id ? 600 : 400,
                  color: contractType === ct.id ? '#fff' : T.text,
                  background: contractType === ct.id ? T.text : T.bg,
                  border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
                  transition: 'all 0.15s',
                }}>
                {ct.icon} {ct.label}
              </button>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
            {PERSPECTIVES.map(p => (
              <button key={p.id} onClick={() => setPerspective(p.id)}
                style={{
                  fontFamily: sans, fontSize: 13, fontWeight: perspective === p.id ? 600 : 400,
                  color: perspective === p.id ? '#fff' : T.text,
                  background: perspective === p.id ? T.text : T.bg,
                  border: 'none', borderRadius: 8, padding: '8px 16px', cursor: 'pointer',
                }}>
                {p.id === 'A' ? '?' : '?'} {p.label}
              </button>
            ))}
          </div>
          <div style={{ fontSize: 12, color: T.dim, marginBottom: 8 }}>
            {definitions.length} Klauseln werden analysiert ({contractType}vertrag)
          </div>
          <textarea
            value={text}
            onChange={e => setText(e.target.value)}
            placeholder="Vollständigen Vertragstext hier einfügen?"
            rows={8}
            style={{
              fontFamily: sans, fontSize: 14, width: '100%', padding: '14px 16px',
              border: 'none', borderRadius: 12, background: T.bg,
              outline: 'none', color: T.text, resize: 'vertical', lineHeight: 1.6,
            }}
          />
          <div style={{ marginTop: 16, display: 'flex', gap: 12, alignItems: 'center' }}>
            <button
              onClick={analyze}
              disabled={!text.trim() || loading}
              style={{
                fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff',
                background: loading ? T.dim : T.text,
                border: 'none', borderRadius: 12, padding: '12px 28px',
                cursor: loading ? 'wait' : 'pointer',
                opacity: !text.trim() ? 0.4 : 1,
              }}>
              {loading ? 'Analysiere Klauseln?' : `${definitions.length} Klauseln analysieren`}
            </button>
            {text.length > 0 && <span style={{ fontSize: 12, color: T.dim }}>{text.length} Zeichen</span>}
          </div>
        </div>
      )}
      {error && (
        <div style={{ padding: '14px 18px', borderRadius: 12, marginBottom: 20, background: T.surface, color: '#ff3b30', fontSize: 14, fontWeight: 500 }}>
          {error}
        </div>
      )}
      {/* Results */}
      {result && (
        <>
          {/* Executive Summary */}
          <div style={{ background: T.surface, borderRadius: 16, padding: 28, marginBottom: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
              <div>
                <div style={{ fontSize: 12, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 4 }}>Gesamtbewertung</div>
                <div style={{ fontSize: 48, fontWeight: 800, letterSpacing: '-0.02em', color: ampelColor(result.gesamtScore >= 70 ? 'green' : result.gesamtScore >= 40 ? 'yellow' : 'red') }}>
                  {result.gesamtScore}
                  <span style={{ fontSize: 20, fontWeight: 400, color: T.dim }}>/100</span>
                </div>
              </div>
              <div style={{
                padding: '10px 20px', borderRadius: 10,
                background: empfehlungColor(result.empfehlung) + '15',
                color: empfehlungColor(result.empfehlung),
                fontSize: 16, fontWeight: 700,
              }}>
                {result.empfehlung === 'Unterzeichnen' ? '?' : result.empfehlung === 'Nachverhandeln' ? '?' : '?'} {result.empfehlung}
              </div>
            </div>
            <div style={{ fontSize: 14, color: T.text, lineHeight: 1.7, marginBottom: 16 }}>
              {result.zusammenfassung}
            </div>
            {/* Ampel overview */}
            <div style={{ display: 'flex', gap: 16 }}>
              {(['red', 'yellow', 'green'] as const).map(tl => {
                const count = result.clauses.filter(c => c.trafficLight === tl).length;
                return (
                  <div key={tl} style={{
                    flex: 1, padding: '12px 16px', borderRadius: 10,
                    background: ampelBg(tl), textAlign: 'center',
                  }}>
                    <div style={{ fontSize: 24, fontWeight: 700, color: ampelColor(tl) }}>{count}</div>
                    <div style={{ fontSize: 11, color: T.dim }}>
                      {tl === 'red' ? 'Kritisch' : tl === 'yellow' ? 'Nachverhandeln' : 'OK'}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
          {/* Stärken & Schwächen */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
            <div style={{ background: T.surface, borderRadius: 12, padding: 18 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#34c759', marginBottom: 8 }}>? Stärken</div>
              {result.staerken.map((s, i) => (
                <div key={i} style={{ fontSize: 13, color: T.text, padding: '3px 0' }}>? {s}</div>
              ))}
              {result.staerken.length === 0 && <div style={{ fontSize: 13, color: T.dim }}>Keine identifiziert</div>}
            </div>
            <div style={{ background: T.surface, borderRadius: 12, padding: 18 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#ff3b30', marginBottom: 8 }}>? Schwächen</div>
              {result.schwaechen.map((s, i) => (
                <div key={i} style={{ fontSize: 13, color: T.text, padding: '3px 0' }}>? {s}</div>
              ))}
              {result.schwaechen.length === 0 && <div style={{ fontSize: 13, color: T.dim }}>Keine identifiziert</div>}
            </div>
          </div>
          {/* Filter pills */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
            {([['all', 'Alle'], ['red', '? Kritisch'], ['yellow', '? Nachverhandeln'], ['green', '? OK']] as const).map(([f, label]) => (
              <button key={f} onClick={() => setFilter(f as any)} style={{
                fontFamily: sans, fontSize: 13, fontWeight: filter === f ? 600 : 400,
                color: filter === f ? '#fff' : T.text,
                background: filter === f ? T.text : T.surface,
                border: 'none', borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
              }}>{label}</button>
            ))}
          </div>
          {/* Grouped Clauses */}
          {Object.entries(filteredGrouped).map(([group, data]) => {
            const gData = data as { clauses: (ClauseScore & { def: ClauseDefinition })[]; avgScore: number };
            const isOpen = expandedGroups.has(group);
            return (
              <div key={group} style={{ background: T.surface, borderRadius: 12, marginBottom: 8, overflow: 'hidden' }}>
                <button onClick={() => toggleGroup(group)} style={{
                  width: '100%', fontFamily: sans, display: 'flex', alignItems: 'center',
                  padding: '14px 18px', gap: 12, background: 'transparent',
                  border: 'none', cursor: 'pointer', textAlign: 'left',
                }}>
                  <span style={{ fontSize: 12, transform: isOpen ? 'rotate(90deg)' : 'none', transition: 'transform 0.15s' }}>?</span>
                  <span style={{ flex: 1, fontSize: 14, fontWeight: 600, color: T.text }}>{group}</span>
                  <span style={{ fontSize: 12, color: T.dim }}>{gData.clauses.length} Klauseln</span>
                  <div style={{
                    padding: '3px 10px', borderRadius: 6, fontSize: 12, fontWeight: 600,
                    color: ampelColor(gData.avgScore >= 70 ? 'green' : gData.avgScore >= 40 ? 'yellow' : 'red'),
                    background: ampelBg(gData.avgScore >= 70 ? 'green' : gData.avgScore >= 40 ? 'yellow' : 'red'),
                  }}>? {gData.avgScore}</div>
                </button>
                {isOpen && (
                  <div style={{ padding: '0 18px 14px' }}>
                    {gData.clauses.map(clause => (
                      <div key={clause.clauseId} style={{
                        padding: '12px 14px', marginBottom: 6, borderRadius: 10,
                        background: T.bg, borderLeft: `3px solid ${ampelColor(clause.trafficLight)}`,
                      }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
                          <div>
                            <span style={{ fontSize: 11, color: T.dim, marginRight: 8 }}>{clause.clauseId}</span>
                            <span style={{ fontSize: 14, fontWeight: 600 }}>{clause.def.name}</span>
                            <span style={{
                              fontSize: 10, marginLeft: 8, padding: '1px 6px', borderRadius: 4,
                              background: T.surface, color: T.dim,
                            }}>{getClassLabel(clause.def.klpiClass)}</span>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                            <div style={{
                              width: 60, height: 6, borderRadius: 3, background: T.bg,
                              overflow: 'hidden',
                            }}>
                              <div style={{
                                width: `${clause.score}%`, height: '100%',
                                background: ampelColor(clause.trafficLight),
                                borderRadius: 3,
                              }} />
                            </div>
                            <span style={{ fontSize: 13, fontWeight: 700, color: ampelColor(clause.trafficLight), minWidth: 28, textAlign: 'right' }}>
                              {clause.score}
                            </span>
                          </div>
                        </div>
                        {clause.rawValue && clause.rawValue !== 'nicht gefunden' && (
                          <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>
                            <strong>Extrahiert:</strong> {clause.rawValue}
                          </div>
                        )}
                        {clause.bewertung && (
                          <div style={{ fontSize: 13, color: T.text, lineHeight: 1.5, marginBottom: 4 }}>
                            {clause.bewertung}
                          </div>
                        )}
                        {clause.trafficLight === 'red' && clause.def.problemTextRed && (
                          <div style={{ fontSize: 12, color: '#ff3b30', lineHeight: 1.5, marginTop: 6, padding: '6px 10px', borderRadius: 6, background: '#ff3b3008' }}>
                            ? {clause.def.problemTextRed}
                          </div>
                        )}
                        {clause.verhandlungsempfehlung && (
                          <div style={{ fontSize: 12, color: '#007aff', lineHeight: 1.5, marginTop: 4, padding: '6px 10px', borderRadius: 6, background: '#007aff08' }}>
                            ? {clause.verhandlungsempfehlung}
                          </div>
                        )}
                        {clause.confidence < 50 && (
                          <div style={{ fontSize: 11, color: T.dim, marginTop: 4, fontStyle: 'italic' }}>
                            Niedrige Konfidenz ({clause.confidence}%) ? manuelle Prüfung empfohlen
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            );
          })}
          {/* Actions */}
          <div style={{ display: 'flex', gap: 12, marginTop: 20 }}>
            <button onClick={() => { setResult(null); setText(''); }} style={{
              fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.dim,
              background: T.surface, border: 'none', borderRadius: 10,
              padding: '10px 20px', cursor: 'pointer',
            }}>Neue Analyse</button>
          </div>
        </>
      )}
    </div>
  );
}
