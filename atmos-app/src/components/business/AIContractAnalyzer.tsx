import React, { useState } from 'react';
import { BusinessScenario, BusinessOption, createEmptyOption, RiskItem, Deadline } from '@/types/business';
import { supabase } from '@/integrations/supabase/client';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label } from '@/components/lexara/Primitives';
import { analyzeContractAlgorithmically } from '@/lib/algorithmicExtractor';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
interface AIResult {
  zusammenfassung: string;
  kategorie: string;
  optionen: {
    label: string;
    description: string;
    anwaltskosten?: number;
    gerichtskosten?: number;
    interneKosten?: number;
    opportunitaetskosten?: number;
    erfolgswahrscheinlichkeit: number;
    bestCase?: number;
    worstCase?: number;
    likelyCase?: number;
    minMonths?: number;
    maxMonths?: number;
    relevanteLaws?: string[];
    proArgumente?: string[];
    contraArgumente?: string[];
  }[];
  risiken?: { label: string; auftretenswahrscheinlichkeit?: number; bedeutung?: number; entdeckungswahrscheinlichkeit?: number }[];
  fristen?: { label: string; date?: string; type?: string; critical?: boolean; notes?: string }[];
  vertragsbestandteile?: { titel: string; inhalt: string; risiko: string; bewertung: string }[];
  konfidenz: string;
  warnungen?: string[];
}
export function AIContractAnalyzer({ scenario, onUpdate }: Props) {
  const [text, setText] = useState('');
  const [context, setContext] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<AIResult | null>(null);
  const [error, setError] = useState('');
  const [files, setFiles] = useState<File[]>([]);
  const [dragActive, setDragActive] = useState(false);
  const [useKi, setUseKi] = useState(false);
  const fileInputRef = React.useRef<HTMLInputElement>(null);
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selected = Array.from(e.target.files || []);
    if (!selected.length) return;
    const maxSize = 10 * 1024 * 1024;
    const tooLarge = selected.find(f => f.size > maxSize);
    if (tooLarge) { setError(`Datei "${tooLarge.name}" zu groß (max. 10 MB)`); return; }
    if (files.length + selected.length > 5) { setError('Maximal 5 Dateien erlaubt'); return; }
    setFiles(prev => [...prev, ...selected]);
    setError('');
    if (fileInputRef.current) fileInputRef.current.value = '';
  };
  const removeFile = (idx: number) => setFiles(prev => prev.filter((_, i) => i !== idx));
  const analyzeAlgorithmic = () => {
    if (!text.trim()) return;
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const algoResult = analyzeContractAlgorithmically(text.trim(), context.trim() || undefined);
      setResult(algoResult as any);
    } catch (e: any) {
      setError(e.message || 'Algorithmische Analyse fehlgeschlagen');
    } finally {
      setLoading(false);
    }
  };
  const analyzeKi = async () => {
    if (!text.trim() && files.length === 0) return;
    setLoading(true);
    setError('');
    setResult(null);
    try {
      let body: any = { context: context.trim() || undefined };
      if (files.length > 0) {
        const fileDataArray: { base64: string; mimeType: string; name: string }[] = [];
        for (const f of files) {
          const buffer = await f.arrayBuffer();
          const bytes = new Uint8Array(buffer);
          let binary = '';
          for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
          fileDataArray.push({
            base64: btoa(binary),
            mimeType: f.type || 'application/octet-stream',
            name: f.name,
          });
        }
        body.files = fileDataArray;
        body.fileBase64 = fileDataArray[0].base64;
        body.fileMimeType = fileDataArray[0].mimeType;
      }
      if (text.trim()) body.text = text.trim();
      const { data, error: fnError } = await supabase.functions.invoke('analyze-contract', { body });
      if (fnError) throw new Error(fnError.message);
      if (!data?.success) throw new Error(data?.error || 'Analyse fehlgeschlagen');
      setResult(data.data);
    } catch (e: any) {
      setError(e.message || 'Unbekannter Fehler');
    } finally {
      setLoading(false);
    }
  };
  const analyze = () => {
    if (useKi) analyzeKi();
    else analyzeAlgorithmic();
  };
  const applyResults = () => {
    if (!result) return;
    const newOptions: BusinessOption[] = result.optionen.map((o, i) => {
      const opt = createEmptyOption(o.label);
      opt.description = o.description || '';
      opt.costs = {
        anwaltskosten: o.anwaltskosten || 0,
        gerichtskosten: o.gerichtskosten || 0,
        interneKosten: o.interneKosten || 0,
        opportunitaetskosten: o.opportunitaetskosten || 0,
      };
      opt.risk = {
        erfolgswahrscheinlichkeit: o.erfolgswahrscheinlichkeit || 50,
        bestCase: o.bestCase || 0,
        worstCase: o.worstCase || 0,
        likelyCase: o.likelyCase || 0,
      };
      opt.timeframe = {
        minMonths: o.minMonths || 1,
        maxMonths: o.maxMonths || 6,
        earliestResult: '',
      };
      opt.relevanteLaws = o.relevanteLaws || [];
      opt.arguments = [
        ...(o.proArgumente || []).map((t, j) => ({
          id: `arg-ai-${i}-pro-${j}`,
          side: 'pro' as const,
          text: t,
          weight: 5,
        })),
        ...(o.contraArgumente || []).map((t, j) => ({
          id: `arg-ai-${i}-con-${j}`,
          side: 'contra' as const,
          text: t,
          weight: 5,
        })),
      ];
      if (result.risiken && i === 0) {
        opt.riskItems = result.risiken.map((r, j) => ({
          id: `ri-ai-${j}`,
          label: r.label,
          auftretenswahrscheinlichkeit: r.auftretenswahrscheinlichkeit || 5,
          bedeutung: r.bedeutung || 5,
          entdeckungswahrscheinlichkeit: r.entdeckungswahrscheinlichkeit || 5,
        }));
      }
      if (result.fristen && i === 0) {
        opt.deadlines = result.fristen.map((f, j) => ({
          id: `dl-ai-${j}`,
          label: f.label,
          date: f.date || new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          type: (f.type as any) || 'Sonstige',
          critical: f.critical || false,
          notes: f.notes || '',
        }));
      }
      return opt;
    });
    onUpdate({
      ...scenario,
      description: result.zusammenfassung || scenario.description,
      category: result.kategorie as any || scenario.category,
      options: [...scenario.options, ...newOptions],
    });
    setResult(null);
    setText('');
  };
  const konfidenzColor = (k: string) =>
    k === 'hoch' ? T.green : k === 'mittel' ? T.orange : T.red;
  return (
    <div style={{ padding: '24px 40px', maxWidth: 900 }}>
      {/* Modus-Toggle */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16,
        padding: '12px 16px', borderRadius: 12, background: T.surface,
      }}>
        <span style={{ fontSize: 13, fontWeight: 600, color: T.dim }}>Modus:</span>
        <button onClick={() => setUseKi(false)} style={{
          fontFamily: sans, fontSize: 13, fontWeight: !useKi ? 700 : 400, color: !useKi ? T.text : T.dim,
          background: !useKi ? T.bg : 'transparent', border: !useKi ? `1px solid ${T.border}` : '1px solid transparent',
          borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
        }}>? Algorithmus</button>
        <button onClick={() => setUseKi(true)} style={{
          fontFamily: sans, fontSize: 13, fontWeight: useKi ? 700 : 400, color: useKi ? T.text : T.dim,
          background: useKi ? T.bg : 'transparent', border: useKi ? `1px solid ${T.border}` : '1px solid transparent',
          borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
        }}>? KI</button>
        <span style={{ fontSize: 11, color: T.dim, flex: 1, textAlign: 'right' }}>
          {useKi ? 'KI-gestützte Analyse ? DSGVO-Hinweis beachten' : 'Rein algorithmisch ? sofortige Ergebnisse, kein KI-Aufruf'}
        </span>
      </div>
      {/* KI-Analyse Disclaimer ? only in KI mode */}
      {useKi && (
      <div style={{
        padding: '16px 20px', borderRadius: 12, marginBottom: 24,
        background: '#fff3cd', border: '1px solid #ffc107',
        fontSize: 13, color: '#664d03', lineHeight: 1.7,
      }}>
        <div style={{ fontWeight: 700, marginBottom: 4, fontSize: 14 }}>?? KI-Analyse ? Kein Ersatz für juristische Prüfung</div>
        <div>Die KI kann sich irren. Alle vorgeschlagenen Zahlen, Wahrscheinlichkeiten und Einschätzungen sind <strong>unverbindliche Vorschläge</strong> und müssen von einem Juristen geprüft und ggf. angepasst werden. Die KI ersetzt keine Rechtsberatung.</div>
      </div>
      )}
      {/* Input Area */}
      <div style={{ background: T.surface, borderRadius: 16, padding: 28, marginBottom: 24 }}>
        <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Vertrag oder Dokument analysieren</div>
        <div style={{ fontSize: 13, color: T.dim, marginBottom: 16 }}>
          Die KI zerlegt Verträge in Einzelteile, identifiziert Risiken, Klauseln und Fristen.
        </div>
        <textarea
          value={text}
          onChange={e => setText(e.target.value)}
          placeholder="Vertragstext hier einfügen oder Dateien hochladen?"
          rows={6}
          style={{
            fontFamily: sans, fontSize: 14, width: '100%', padding: '14px 16px',
            border: 'none', borderRadius: 12, background: T.bg,
            outline: 'none', color: T.text, resize: 'vertical', lineHeight: 1.6,
          }}
        />
        {/* File Upload */}
        <div
          onDragOver={e => { e.preventDefault(); setDragActive(true); }}
          onDragEnter={e => { e.preventDefault(); setDragActive(true); }}
          onDragLeave={e => { e.preventDefault(); setDragActive(false); }}
          onDrop={e => {
            e.preventDefault(); setDragActive(false);
            const dropped = Array.from(e.dataTransfer.files || []);
            if (!dropped.length) return;
            if (files.length + dropped.length > 5) { setError('Maximal 5 Dateien'); return; }
            setFiles(prev => [...prev, ...dropped]);
          }}
          style={{
            marginTop: 16, padding: '16px 20px', borderRadius: 12,
            border: `1px dashed ${dragActive ? T.text : T.muted}`,
            background: dragActive ? T.bg : 'transparent',
            transition: 'all 0.2s',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 500 }}>
                {dragActive ? 'Ablegen?' : 'Dateien hochladen'}
              </div>
              <div style={{ fontSize: 12, color: T.dim }}>PDF, DOCX, Bilder, CSV ? max. 10 MB, bis zu 5 Dateien</div>
            </div>
            <button
              onClick={() => fileInputRef.current?.click()}
              style={{
                fontFamily: sans, fontSize: 13, fontWeight: 500, color: T.text,
                background: T.bg, border: 'none', borderRadius: 8,
                padding: '8px 16px', cursor: 'pointer',
              }}
            >
              Auswählen
            </button>
            <input
              ref={fileInputRef}
              type="file"
              accept="*/*"
              multiple
              onChange={handleFileChange}
              style={{ display: 'none' }}
            />
          </div>
          {files.length > 0 && (
            <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 6 }}>
              {files.map((f, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', borderRadius: 8, background: T.bg }}>
                  <span style={{ fontSize: 13, flex: 1 }}>{f.name} <span style={{ color: T.dim }}>({(f.size / 1024).toFixed(0)} KB)</span></span>
                  <button onClick={() => removeFile(i)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: T.dim }}>?</button>
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={{ marginTop: 14 }}>
          <div style={{ fontSize: 12, color: T.dim, marginBottom: 6 }}>Kontext (optional)</div>
          <input
            value={context}
            onChange={e => setContext(e.target.value)}
            placeholder="z.B. 'Streitwert 500.000€, mittelständisches Unternehmen'"
            style={{
              fontFamily: sans, fontSize: 14, width: '100%', padding: '12px 16px',
              border: 'none', borderRadius: 12, background: T.bg,
              outline: 'none', color: T.text,
            }}
          />
        </div>
        <div style={{ marginTop: 20, display: 'flex', gap: 12, alignItems: 'center' }}>
          <button
            onClick={analyze}
            disabled={(!text.trim() && files.length === 0) || loading}
            style={{
              fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff',
              background: loading ? T.dim : T.text,
              border: 'none', borderRadius: 12, padding: '12px 28px', cursor: loading ? 'wait' : 'pointer',
              opacity: (!text.trim() && files.length === 0) ? 0.4 : 1,
            }}
          >
            {loading ? 'Analysiere?' : 'Analysieren'}
          </button>
          <span style={{ fontSize: 12, color: T.dim }}>
            {files.length > 0 ? `${files.length} Datei(en)` : ''}{files.length > 0 && text.length > 0 ? ' + ' : ''}{text.length > 0 ? `${text.length} Zeichen` : ''}
          </span>
        </div>
      </div>
      {/* Error */}
      {error && (
        <div style={{ padding: '14px 18px', borderRadius: 12, marginBottom: 24, background: T.surface, color: T.red, fontSize: 14, fontWeight: 500 }}>
          {error}
        </div>
      )}
      {/* Results */}
      {result && (
        <>
          {/* Confidence */}
          <div style={{ background: T.surface, borderRadius: 16, padding: 24, marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
              <div style={{
                fontSize: 11, fontWeight: 700, color: konfidenzColor(result.konfidenz),
                textTransform: 'uppercase', letterSpacing: '0.06em',
              }}>
                Konfidenz: {result.konfidenz}
              </div>
            </div>
            <div style={{ fontSize: 14, color: T.text, lineHeight: 1.7 }}>
              {result.zusammenfassung}
            </div>
            {result.warnungen && result.warnungen.length > 0 && (
              <div style={{ marginTop: 12 }}>
                {result.warnungen.map((w, i) => (
                  <div key={i} style={{ fontSize: 12, color: T.orange, marginBottom: 4 }}>{w}</div>
                ))}
              </div>
            )}
          </div>
          {/* Contract Components */}
          {result.vertragsbestandteile && result.vertragsbestandteile.length > 0 && (
            <div style={{ background: T.surface, borderRadius: 16, padding: 24, marginBottom: 16 }}>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Vertragsbestandteile</div>
              {result.vertragsbestandteile.map((v, i) => (
                <div key={i} style={{
                  padding: '14px 16px', marginBottom: 8, borderRadius: 12, background: T.bg,
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>                    <div style={{ fontSize: 14, fontWeight: 600 }}>{v.titel}</div>
                    <span style={{
                      fontSize: 10, fontWeight: 600, padding: '2px 8px', borderRadius: 4,
                      color: v.risiko === 'hoch' ? T.red : v.risiko === 'mittel' ? T.orange : T.green,
                      background: (v.risiko === 'hoch' ? T.red : v.risiko === 'mittel' ? T.orange : T.green) + '12',
                      textTransform: 'uppercase',
                    }}>{v.risiko}</span>
                  </div>
                  <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.5, marginBottom: 4 }}>{v.inhalt}</div>
                  <div style={{ fontSize: 12, color: T.text }}>{v.bewertung}</div>
                </div>
              ))}
            </div>
          )}
          {/* Options */}
          <div style={{ background: T.surface, borderRadius: 16, padding: 24, marginBottom: 16 }}>
            <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Handlungsoptionen ({result.optionen.length})</div>            {result.optionen.map((o, i) => (
              <div key={i} style={{
                padding: '16px 18px', marginBottom: 10, borderRadius: 12, background: T.bg,
              }}>
                <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{o.label}</div>
                <div style={{ fontSize: 13, color: T.dim, marginBottom: 10, lineHeight: 1.5 }}>{o.description}</div>
                <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', fontSize: 13 }}>
                  <span>Erfolg: <strong>{o.erfolgswahrscheinlichkeit}%</strong></span>
                  {o.bestCase != null && <span>Best: <strong style={{ color: T.green }}>{o.bestCase.toLocaleString('de-DE')}€</strong></span>}
                  {o.worstCase != null && <span>Worst: <strong style={{ color: T.red }}>{o.worstCase.toLocaleString('de-DE')}€</strong></span>}
                </div>
              </div>
            ))}
          </div>
          {/* Risks & Deadlines */}
          {result.risiken && result.risiken.length > 0 && (
            <div style={{ background: T.surface, borderRadius: 16, padding: 24, marginBottom: 16 }}>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Risiken ({result.risiken.length})</div>
              {result.risiken.map((r, i) => (
                <div key={i} style={{ fontSize: 13, padding: '8px 0', borderBottom: i < result.risiken!.length - 1 ? `1px solid ${T.bg}` : 'none' }}>
                  {r.label}
                </div>
              ))}
            </div>
          )}
          {result.fristen && result.fristen.length > 0 && (
            <div style={{ background: T.surface, borderRadius: 16, padding: 24, marginBottom: 16 }}>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Fristen ({result.fristen.length})</div>
              {result.fristen.map((f, i) => (
                <div key={i} style={{ fontSize: 13, padding: '8px 0', borderBottom: i < result.fristen!.length - 1 ? `1px solid ${T.bg}` : 'none', display: 'flex', justifyContent: 'space-between' }}>
                  <span>{f.critical && <span style={{ color: T.red }}>Kritisch: </span>}{f.label}</span>
                  {f.date && <span style={{ color: T.dim }}>{f.date}</span>}
                </div>
              ))}
            </div>
          )}
          {/* Apply */}
          <div style={{ background: T.surface, borderRadius: 16, padding: 24, display: 'flex', alignItems: 'center', gap: 20 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Ergebnisse übernehmen</div>
              <div style={{ fontSize: 13, color: T.dim }}>Optionen werden zum Szenario hinzugefügt. Alle Werte sind danach anpassbar.</div>
            </div>
            <button onClick={applyResults} style={{
              fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff',
              background: T.text, border: 'none', borderRadius: 12, padding: '12px 28px', cursor: 'pointer',
            }}>
              Übernehmen
            </button>
          </div>
        </>
      )}
    </div>
  );
}
