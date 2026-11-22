import React, { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { T, sans } from './theme';
import { Panel, Label } from './Primitives';
interface ExtractedArgument {
  label: string;
  content: string;
  side: 'own' | 'opp';
  strength: number;
  legal_basis?: string;
}
interface ExtractedEvidence {
  name: string;
  type: string;
  description: string;
  relevanz?: number;
}
interface ExtractionResult {
  argumente: ExtractedArgument[];
  beweismittel?: ExtractedEvidence[];
  zusammenfassung: string;
  kernproblem?: string;
  empfohlene_strategie?: string;
  konfidenz: string;
  warnungen?: string[];
}
interface Props {
  caseName?: string;
  caseType?: string;
  onApplyArguments?: (args: ExtractedArgument[]) => void;
  onApplyEvidence?: (evidence: ExtractedEvidence[]) => void;
}
export function AIArgumentExtractor({ caseName, caseType, onApplyArguments, onApplyEvidence }: Props) {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<ExtractionResult | null>(null);
  const [error, setError] = useState('');
  const [selectedArgs, setSelectedArgs] = useState<Set<number>>(new Set());
  const analyze = async () => {
    if (!text.trim()) return;
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const { data, error: fnError } = await supabase.functions.invoke('extract-arguments', {
        body: { text: text.trim(), caseName, caseType },
      });
      if (fnError) throw new Error(fnError.message);
      if (!data?.success) throw new Error(data?.error || 'Analyse fehlgeschlagen');
      setResult(data.data);
      // Select all by default
      setSelectedArgs(new Set(data.data.argumente.map((_: any, i: number) => i)));
    } catch (e: any) {
      setError(e.message || 'Unbekannter Fehler');
    } finally {
      setLoading(false);
    }
  };
  const toggleArg = (idx: number) => {
    const next = new Set(selectedArgs);
    next.has(idx) ? next.delete(idx) : next.add(idx);
    setSelectedArgs(next);
  };
  const applySelected = () => {
    if (!result || !onApplyArguments) return;
    const selected = result.argumente.filter((_, i) => selectedArgs.has(i));
    onApplyArguments(selected);
    if (result.beweismittel && onApplyEvidence) {
      onApplyEvidence(result.beweismittel);
    }
    setResult(null);
    setText('');
  };
  const konfidenzColor = (k: string) =>
    k === 'hoch' ? T.green : k === 'mittel' ? T.orange : T.red;
  return (
    <div>
      {/* Disclaimer */}
      <Panel style={{ marginBottom: 16, background: T.orange + '08', border: `1px solid ${T.orange}30` }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
          <span style={{ fontSize: 22, flexShrink: 0 }}>?</span>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, color: T.orange, marginBottom: 2 }}>
              KI-Vorschlag ? Nachträglich prüfen!
            </div>
            <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.5 }}>
              Die KI extrahiert Argumente aus Ihrem Text. Alle Ergebnisse sind <strong>Vorschläge</strong> und
              müssen juristisch geprüft werden. Wählen Sie aus, welche Sie übernehmen möchten.
            </div>
          </div>
        </div>
      </Panel>
      {/* Input */}
      <Panel style={{ marginBottom: 16 }}>
        <Label>? Text einfügen (Schriftsatz, Vertrag, Urteil?)</Label>
        <textarea
          value={text}
          onChange={e => setText(e.target.value)}
          placeholder="Schriftsatz, Vertrag, Urteil, Gutachten oder andere juristische Dokumente hier einfügen?"
          rows={6}
          style={{
            fontFamily: sans, fontSize: 13, width: '100%', padding: '12px 14px',
            border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
            outline: 'none', color: T.text, resize: 'vertical', lineHeight: 1.6,
          }}
        />
        <div style={{ marginTop: 12, display: 'flex', gap: 10, alignItems: 'center' }}>
          <button
            onClick={analyze}
            disabled={!text.trim() || loading}
            style={{
              fontFamily: sans, fontSize: 13, fontWeight: 600, color: '#fff',
              background: loading ? T.dim : T.blue,
              border: 'none', borderRadius: 10, padding: '8px 20px', cursor: loading ? 'wait' : 'pointer',
              opacity: !text.trim() ? 0.5 : 1,
            }}
          >
            {loading ? '? Analysiere?' : '? Argumente extrahieren'}
          </button>
          {text.length > 0 && <span style={{ fontSize: 11, color: T.dim }}>{text.length} Zeichen</span>}
        </div>
      </Panel>
      {/* Error */}
      {error && (
        <Panel style={{ marginBottom: 16, background: T.red + '08', border: `1px solid ${T.red}30` }}>
          <div style={{ fontSize: 13, color: T.red, fontWeight: 600 }}>? {error}</div>
        </Panel>
      )}
      {/* Results */}
      {result && (
        <>
          {/* Summary */}
          <Panel style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
              <span style={{
                fontSize: 11, fontWeight: 700, color: konfidenzColor(result.konfidenz),
                padding: '3px 10px', borderRadius: 6, background: konfidenzColor(result.konfidenz) + '15',
              }}>
                Konfidenz: {result.konfidenz}
              </span>
            </div>
            <div style={{ fontSize: 13, color: T.text, lineHeight: 1.6, marginBottom: 8 }}>
              {result.zusammenfassung}
            </div>
            {result.kernproblem && (
              <div style={{ fontSize: 12, color: T.dim, fontStyle: 'italic' }}>
                Kernproblem: {result.kernproblem}
              </div>
            )}
            {result.warnungen && result.warnungen.length > 0 && (
              <div style={{ marginTop: 8 }}>
                {result.warnungen.map((w, i) => (
                  <div key={i} style={{ fontSize: 11, color: T.orange, marginBottom: 2 }}>?? {w}</div>
                ))}
              </div>
            )}
          </Panel>
          {/* Arguments */}
          <Panel style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <Label>?? Extrahierte Argumente ({result.argumente.length})</Label>
              <button onClick={() => {
                if (selectedArgs.size === result.argumente.length) setSelectedArgs(new Set());
                else setSelectedArgs(new Set(result.argumente.map((_, i) => i)));
              }} style={{
                fontFamily: sans, fontSize: 11, color: T.blue, background: 'none',
                border: 'none', cursor: 'pointer',
              }}>
                {selectedArgs.size === result.argumente.length ? 'Keine auswählen' : 'Alle auswählen'}
              </button>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {/* Eigene Seite */}
              <div>
                <div style={{ fontSize: 11, fontWeight: 600, color: T.green, marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                  ? Eigene Seite
                </div>
                {result.argumente.map((a, i) => a.side === 'own' && (
                  <div key={i} onClick={() => toggleArg(i)} style={{
                    padding: 12, marginBottom: 8, borderRadius: 10,
                    background: selectedArgs.has(i) ? T.green + '08' : T.bg,
                    border: `1px solid ${selectedArgs.has(i) ? T.green + '40' : T.border}`,
                    cursor: 'pointer', transition: 'all 0.15s',
                  }}>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
                      <div style={{
                        width: 18, height: 18, borderRadius: 4, flexShrink: 0, marginTop: 1,
                        border: `2px solid ${selectedArgs.has(i) ? T.green : T.muted}`,
                        background: selectedArgs.has(i) ? T.green : 'transparent',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        {selectedArgs.has(i) && <span style={{ color: '#fff', fontSize: 10 }}>?</span>}
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 2 }}>{a.label}</div>
                        <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.4 }}>{a.content}</div>
                        <div style={{ display: 'flex', gap: 8, marginTop: 6, fontSize: 11 }}>
                          <span style={{ color: T.green, fontWeight: 600 }}>Stärke: {a.strength}/10</span>
                          {a.legal_basis && <span style={{ color: T.blue }}>{a.legal_basis}</span>}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              {/* Gegenseite */}
              <div>
                <div style={{ fontSize: 11, fontWeight: 600, color: T.orange, marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                  ? Gegenseite
                </div>
                {result.argumente.map((a, i) => a.side === 'opp' && (
                  <div key={i} onClick={() => toggleArg(i)} style={{
                    padding: 12, marginBottom: 8, borderRadius: 10,
                    background: selectedArgs.has(i) ? T.orange + '08' : T.bg,
                    border: `1px solid ${selectedArgs.has(i) ? T.orange + '40' : T.border}`,
                    cursor: 'pointer', transition: 'all 0.15s',
                  }}>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
                      <div style={{
                        width: 18, height: 18, borderRadius: 4, flexShrink: 0, marginTop: 1,
                        border: `2px solid ${selectedArgs.has(i) ? T.orange : T.muted}`,
                        background: selectedArgs.has(i) ? T.orange : 'transparent',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        {selectedArgs.has(i) && <span style={{ color: '#fff', fontSize: 10 }}>?</span>}
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 2 }}>{a.label}</div>
                        <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.4 }}>{a.content}</div>
                        <div style={{ display: 'flex', gap: 8, marginTop: 6, fontSize: 11 }}>
                          <span style={{ color: T.orange, fontWeight: 600 }}>Stärke: {a.strength}/10</span>
                          {a.legal_basis && <span style={{ color: T.blue }}>{a.legal_basis}</span>}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </Panel>
          {/* Evidence */}
          {result.beweismittel && result.beweismittel.length > 0 && (
            <Panel style={{ marginBottom: 16 }}>
              <Label>? Erkannte Beweismittel ({result.beweismittel.length})</Label>
              {result.beweismittel.map((ev, i) => (
                <div key={i} style={{
                  padding: '8px 12px', fontSize: 13, borderBottom: `1px solid ${T.border}`,
                  display: 'flex', gap: 10, alignItems: 'center',
                }}>
                  <span style={{
                    fontSize: 10, fontWeight: 600, padding: '2px 8px', borderRadius: 6,
                    background: T.blue + '10', color: T.blue,
                  }}>{ev.type}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 500 }}>{ev.name}</div>
                    <div style={{ fontSize: 11, color: T.dim }}>{ev.description}</div>
                  </div>
                </div>
              ))}
            </Panel>
          )}
          {/* Strategy */}
          {result.empfohlene_strategie && (
            <Panel style={{ marginBottom: 16, background: T.blue + '06', border: `1px solid ${T.blue}20` }}>
              <Label>? Empfohlene Strategie</Label>
              <div style={{ fontSize: 13, color: T.text, lineHeight: 1.6 }}>
                {result.empfohlene_strategie}
              </div>
            </Panel>
          )}
          {/* Apply */}
          {onApplyArguments && (
            <Panel style={{ background: T.green + '08', border: `1px solid ${T.green}30` }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: T.green }}>
                    {selectedArgs.size} von {result.argumente.length} Argumente ausgewählt
                  </div>
                  <div style={{ fontSize: 12, color: T.dim }}>
                    Übernommene Argumente können Sie danach anpassen und ergänzen.
                  </div>
                </div>
                <button onClick={applySelected} disabled={selectedArgs.size === 0} style={{
                  fontFamily: sans, fontSize: 13, fontWeight: 600, color: '#fff',
                  background: selectedArgs.size > 0 ? T.green : T.dim,
                  border: 'none', borderRadius: 10, padding: '8px 20px', cursor: 'pointer',
                }}>
                  ? Übernehmen
                </button>
              </div>
            </Panel>
          )}
        </>
      )}
    </div>
  );
}
