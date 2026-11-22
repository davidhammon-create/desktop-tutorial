import React, { useState, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { T, sans, scol } from '@/components/lexara/theme';
import { LexaraCase, LexaraArgument } from '@/types/lexara';
import { toast } from 'sonner';
import { extractFromText } from '@/lib/algorithmicExtractor';
interface ExtractedArg {
  label: string;
  content: string;
  side: 'own' | 'opp';
  strength: number;
  legal_basis?: string;
  seite?: number | null;
  arg_type?: string;
}
interface Widerspruch {
  titel: string;
  beschreibung: string;
  schwere: number;
  seite?: number | null;
  angreifbar?: boolean;
}
interface DruckmittelItem {
  titel: string;
  beschreibung: string;
  staerke: number;
  zielseite: 'own' | 'opp';
  legal_basis?: string;
}
interface ParagraphRef {
  paragraph: string;
  kontext: string;
  im_text_genannt: boolean;
}
interface PsychoProfile {
  seite: 'own' | 'opp';
  schwaeche: string;
  beschreibung: string;
  taktik?: string;
  ausnutzbar: number;
  kategorie: string;
  textstelle?: string;
}
interface EigenSchwaeche {
  titel: string;
  beschreibung: string;
  schwere: number;
  gegenmassnahme?: string;
  seite?: number | null;
}
interface Strang {
  from_index: number;
  to_index: number;
  type: 'supports' | 'weakens' | 'causal';
  beschreibung: string;
}
interface ExtractionResult {
  argumente: ExtractedArg[];
  widersprueche?: Widerspruch[];
  druckmittel?: DruckmittelItem[];
  paragraphen?: ParagraphRef[];
  psycho_profile?: PsychoProfile[];
  eigen_schwaechen?: EigenSchwaeche[];
  straenge?: Strang[];
  zusammenfassung: string;
  konfidenz: string;
  warnungen?: string[];
}
interface UploadedDoc {
  name: string;
  type: string;
  storagePath: string;
  size: number;
}
interface Props {
  c?: LexaraCase;
  onUpdateCase?: (updated: LexaraCase) => void;
}
const ALLOWED_EXT = ['.pdf', '.docx', '.doc', '.txt', '.csv', '.xml', '.json'];
const MAX_SIZE = 20 * 1024 * 1024;
export function CompactArgumentExtractor({ c, onUpdateCase }: Props) {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<ExtractionResult | null>(null);
  const [expanded, setExpanded] = useState(false);
  const [files, setFiles] = useState<UploadedDoc[]>([]);
  const [uploading, setUploading] = useState(false);
  const [dsgvoAccepted, setDsgvoAccepted] = useState(false);
  const [adopted, setAdopted] = useState<Set<number>>(new Set());
  const [adoptedDruckmittel, setAdoptedDruckmittel] = useState<Set<number>>(new Set());
  const [adoptedWidersprueche, setAdoptedWidersprueche] = useState<Set<number>>(new Set());
  const [adoptedPsycho, setAdoptedPsycho] = useState<Set<string>>(new Set());
  const [adoptedEigenSchwaechen, setAdoptedEigenSchwaechen] = useState<Set<number>>(new Set());
  const [adoptedStraenge, setAdoptedChains] = useState<Set<number>>(new Set());
  const [useKi, setUseKi] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const selected = e.target.files;
    if (!selected?.length) return;
    setUploading(true);
    const newFiles: UploadedDoc[] = [];
    for (const file of Array.from(selected)) {
      const ext = '.' + file.name.split('.').pop()?.toLowerCase();
      if (!ALLOWED_EXT.includes(ext)) { toast.error(`${file.name}: Format nicht unterstützt`); continue; }
      if (file.size > MAX_SIZE) { toast.error(`${file.name}: max 20MB`); continue; }
      const storagePath = `anonymous/extract/${crypto.randomUUID()}-${file.name}`;
      const { error } = await supabase.storage.from('business-files').upload(storagePath, file);
      if (error) { toast.error(`Upload fehlgeschlagen: ${file.name}`); continue; }
      newFiles.push({ name: file.name, type: file.type || 'application/octet-stream', storagePath, size: file.size });
    }
    setFiles(prev => [...prev, ...newFiles]);
    if (newFiles.length) toast.success(`${newFiles.length} Datei(en) hochgeladen`);
    setUploading(false);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };
  const removeFile = (idx: number) => {
    const file = files[idx];
    supabase.storage.from('business-files').remove([file.storagePath]).catch(() => {});
    setFiles(prev => prev.filter((_, i) => i !== idx));
  };
  const analyzeAlgorithmic = () => {
    if (!text.trim()) return;
    setLoading(true);
    try {
      const algoResult = extractFromText(text.trim());
      setResult(algoResult);
      setAdopted(new Set());
      setAdoptedChains(new Set());
      toast.success(`${algoResult.argumente.length} Argumente algorithmisch extrahiert`);
    } catch (e: any) {
      toast.error(e.message || 'Algorithmische Extraktion fehlgeschlagen');
    } finally {
      setLoading(false);
    }
  };
  const analyzeKi = async () => {
    if (!text.trim() && files.length === 0) return;
    if (!dsgvoAccepted) { toast.error('Bitte DSGVO-Hinweis bestätigen'); return; }
    setLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke('extract-arguments', {
        body: { text: text.trim(), uploadedFiles: files.length > 0 ? files : undefined },
      });
      if (error) throw new Error(error.message);
      if (!data?.success) throw new Error(data?.error || 'Fehler');
      setResult(data.data);
      setAdopted(new Set());
      setAdoptedChains(new Set());
      setFiles([]);
      toast.success(`${data.data.argumente.length} Argumente extrahiert (KI)`);
    } catch (e: any) {
      toast.error(e.message || 'KI-Extraktion fehlgeschlagen');
    } finally {
      setLoading(false);
    }
  };
  const analyze = () => {
    if (useKi) {
      analyzeKi();
    } else {
      analyzeAlgorithmic();
    }
  };
  const adoptArg = (arg: ExtractedArg, idx: number) => {
    if (!c || !onUpdateCase) return;
    const newArg: LexaraArgument = {
      id: `ki-${Date.now()}-${idx}`,
      side: arg.side,
      label: arg.label,
      strength: arg.strength,
      content: arg.content,
      legalBasis: arg.legal_basis,
      source: 'ki',
      seite: arg.seite,
    };
    const updatedArgs = [...c.arguments, newArg];
    const updatedEvidence = { ...c.evidence, [newArg.id]: [] };
    onUpdateCase({ ...c, arguments: updatedArgs, evidence: updatedEvidence });
    setAdopted(prev => new Set(prev).add(idx));
    toast.success('Argument übernommen');
  };
  const adoptAll = () => {
    if (!result || !c || !onUpdateCase) return;
    const newArgs: LexaraArgument[] = [];
    const newEvidence = { ...c.evidence };
    const idMap: Record<number, string> = {}; // map argumente index -> new arg id
    result.argumente.forEach((arg, idx) => {
      if (adopted.has(idx)) return;
      const newArg: LexaraArgument = {
        id: `ki-${Date.now()}-${idx}`,
        side: arg.side,
        label: arg.label,
        strength: arg.strength,
        content: arg.content,
        legalBasis: arg.legal_basis,
        source: 'ki',
        seite: arg.seite,
      };
      newArgs.push(newArg);
      newEvidence[newArg.id] = [];
      idMap[idx] = newArg.id;
    });
    // Auto-create edges from Stränge (causal chains)
    const newEdges = [...c.edges];
    if (result.straenge?.length) {
      for (const chain of result.straenge) {
        const fromId = idMap[chain.from_index];
        const toId = idMap[chain.to_index];
        if (fromId && toId) {
          newEdges.push({
            from: fromId,
            to: toId,
            type: chain.type,
          });
        }
      }
    }
    onUpdateCase({ ...c, arguments: [...c.arguments, ...newArgs], evidence: newEvidence, edges: newEdges });
    setAdopted(new Set(result.argumente.map((_, i) => i)));
    const strangCount = result.straenge?.filter(ch => idMap[ch.from_index] && idMap[ch.to_index]).length || 0;
    toast.success(`${newArgs.length} Argumente übernommen${strangCount > 0 ? ` + ${strangCount} Stränge` : ''}`);
  };
  const adoptDruckmittel = (d: DruckmittelItem, idx: number) => {
    if (!c || !onUpdateCase) return;
    const newArg: LexaraArgument = {
      id: `dm-${Date.now()}-${idx}`,
      side: d.zielseite === 'opp' ? 'own' : 'opp',
      label: `? ${d.titel}`,
      strength: d.staerke,
      content: d.beschreibung,
      legalBasis: d.legal_basis,
      source: 'ki',
      argType: 'Tatsachenargument',
      notes: 'Druckmittel ? aus KI-Analyse übernommen',
    };
    const updatedArgs = [...c.arguments, newArg];
    const updatedEvidence = { ...c.evidence, [newArg.id]: [] };
    onUpdateCase({ ...c, arguments: updatedArgs, evidence: updatedEvidence });
    setAdoptedDruckmittel(prev => new Set(prev).add(idx));
    toast.success('Druckmittel als Argument übernommen');
  };
  const adoptWiderspruch = (w: Widerspruch, idx: number) => {
    if (!c || !onUpdateCase) return;
    const newArg: LexaraArgument = {
      id: `ws-${Date.now()}-${idx}`,
      side: 'own',
      label: `?? ${w.titel}`,
      strength: Math.min(10, w.schwere),
      content: w.beschreibung,
      source: 'ki',
      argType: 'Gegenargument',
      notes: `Widerspruch (Schwere ${w.schwere}/10) ? aus KI-Analyse übernommen`,
    };
    const updatedArgs = [...c.arguments, newArg];
    const updatedEvidence = { ...c.evidence, [newArg.id]: [] };
    onUpdateCase({ ...c, arguments: updatedArgs, evidence: updatedEvidence });
    setAdoptedWidersprueche(prev => new Set(prev).add(idx));
    toast.success('Widerspruch als Gegenargument übernommen');
  };
  const adoptPsychoProfile = (p: PsychoProfile, idx: number) => {
    if (!c || !onUpdateCase) return;
    const key = `${p.seite}-${idx}`;
    const isOwn = p.seite === 'own';
    const newArg: LexaraArgument = {
      id: `psy-${Date.now()}-${idx}`,
      side: isOwn ? 'opp' : 'own',
      label: `? ${p.schwaeche}`,
      strength: p.ausnutzbar,
      content: `${p.beschreibung}${p.taktik ? `\n\n? Taktik: ${p.taktik}` : ''}${p.textstelle ? `\n\n?${p.textstelle}"` : ''}`,      source: 'ki',
      argType: 'Tatsachenargument',
      notes: `Psychologisches Profil (${p.kategorie}) ? ${isOwn ? 'Eigene Verwundbarkeit' : 'Gegenseite ausnutzbar'} ? aus KI-Analyse übernommen`,
    };
    const updatedArgs = [...c.arguments, newArg];
    const updatedEvidence = { ...c.evidence, [newArg.id]: [] };
    onUpdateCase({ ...c, arguments: updatedArgs, evidence: updatedEvidence });
    setAdoptedPsycho(prev => new Set(prev).add(key));
    toast.success('Psychologisches Profil als Argument übernommen');
  };
  const adoptEigenSchwaeche = (s: EigenSchwaeche, idx: number) => {
    if (!c || !onUpdateCase) return;
    const newArg: LexaraArgument = {
      id: `esw-${Date.now()}-${idx}`,
      side: 'opp',
      label: `?? ${s.titel}`,
      strength: s.schwere,
      content: `${s.beschreibung}${s.gegenmassnahme ? `\n\n? Gegenmaßnahme: ${s.gegenmassnahme}` : ''}`,
      source: 'ki',
      argType: 'Gegenargument',
      seite: s.seite,
      notes: `Eigene Schwäche (Schwere ${s.schwere}/10) ? aus KI-Analyse übernommen`,
    };
    const updatedArgs = [...c.arguments, newArg];
    const updatedEvidence = { ...c.evidence, [newArg.id]: [] };
    onUpdateCase({ ...c, arguments: updatedArgs, evidence: updatedEvidence });
    setAdoptedEigenSchwaechen(prev => new Set(prev).add(idx));
    toast.success('Eigene Schwäche als Gegenargument übernommen');
  };
  const adoptStrang = (chain: Strang, idx: number) => {
    if (!c || !onUpdateCase || !result) return;
    // Find the corresponding argument IDs in the case
    const fromArg = result.argumente[chain.from_index];
    const toArg = result.argumente[chain.to_index];
    if (!fromArg || !toArg) return;

    // Find adopted argument IDs - they may have been adopted already
    const fromId = c.arguments.find(a => a.label === fromArg.label && a.source === 'ki')?.id;
    const toId = c.arguments.find(a => a.label === toArg.label && a.source === 'ki')?.id;

    if (!fromId || !toId) {
      // Auto-adopt both arguments first if not yet adopted
      const newArgs = [...c.arguments];
      const newEvidence = { ...c.evidence };
      let resolvedFromId = fromId;
      let resolvedToId = toId;

      if (!resolvedFromId) {
        resolvedFromId = `ki-chain-${Date.now()}-from-${idx}`;
        newArgs.push({
          id: resolvedFromId, side: fromArg.side, label: fromArg.label,
          strength: fromArg.strength, content: fromArg.content,
          legalBasis: fromArg.legal_basis, source: 'ki', seite: fromArg.seite,
        });
        newEvidence[resolvedFromId] = [];
      }
      if (!resolvedToId) {
        resolvedToId = `ki-chain-${Date.now()}-to-${idx}`;
        newArgs.push({
          id: resolvedToId, side: toArg.side, label: toArg.label,
          strength: toArg.strength, content: toArg.content,
          legalBasis: toArg.legal_basis, source: 'ki', seite: toArg.seite,
        });
        newEvidence[resolvedToId] = [];
      }

      const newEdge = { from: resolvedFromId, to: resolvedToId, type: chain.type as any };
      onUpdateCase({ ...c, arguments: newArgs, edges: [...c.edges, newEdge], evidence: newEvidence });
    } else {
      // Both already adopted, just add the edge
      const exists = c.edges.some(e => e.from === fromId && e.to === toId);
      if (!exists) {
        onUpdateCase({ ...c, edges: [...c.edges, { from: fromId, to: toId, type: chain.type as any }] });
      }
    }
    setAdoptedChains(prev => new Set(prev).add(idx));
    toast.success('Strang übernommen');
  };
  const ownArgs = result?.argumente.filter(a => a.side === 'own') || [];
  const oppArgs = result?.argumente.filter(a => a.side === 'opp') || [];
  const hasInput = text.trim().length > 0 || files.length > 0;
  return (
    <div style={{ marginBottom: 16 }}>
      <button
        onClick={() => setExpanded(!expanded)}
        style={{
          width: '100%', fontFamily: sans, fontSize: 13, fontWeight: 600,
          color: T.text, background: T.surface, border: `1px solid ${T.border}`,
          borderRadius: expanded ? '10px 10px 0 0' : 10, padding: '10px 14px',
          cursor: 'pointer', textAlign: 'left',
          display: 'flex', alignItems: 'center', gap: 8,
        }}
      >
        <span>{useKi ? '?' : '?'}</span>
        <span style={{ flex: 1 }}>Argument-Extraktion {useKi ? '(KI)' : '(Algorithmus)'}</span>
        <span style={{ fontSize: 11, color: T.dim, fontWeight: 400 }}>Dokumente & Texte analysieren</span>
        <span style={{ fontSize: 11, color: T.dim, transition: 'transform 0.2s', transform: expanded ? 'rotate(90deg)' : 'rotate(0)' }}>?</span>
      </button>
      {expanded && (
        <div style={{ background: T.surface, border: `1px solid ${T.border}`, borderTop: 'none', borderRadius: '0 0 10px 10px', padding: 14 }}>
          {/* Modus-Toggle: Algorithmus vs KI */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10, padding: '6px 8px', background: T.bg, borderRadius: 6 }}>
            <span style={{ fontSize: 11, fontWeight: 600, color: T.dim }}>Modus:</span>
            <button onClick={() => setUseKi(false)} style={{
              fontFamily: sans, fontSize: 11, fontWeight: !useKi ? 700 : 400, color: !useKi ? T.text : T.dim,
              background: !useKi ? T.surface : 'transparent', border: !useKi ? `1px solid ${T.border}` : '1px solid transparent',
              borderRadius: 6, padding: '4px 10px', cursor: 'pointer',
            }}>? Algorithmus</button>
            <button onClick={() => setUseKi(true)} style={{
              fontFamily: sans, fontSize: 11, fontWeight: useKi ? 700 : 400, color: useKi ? T.text : T.dim,
              background: useKi ? T.surface : 'transparent', border: useKi ? `1px solid ${T.border}` : '1px solid transparent',              borderRadius: 6, padding: '4px 10px', cursor: 'pointer',
            }}>? KI</button>
            <span style={{ fontSize: 9, color: T.dim, flex: 1, textAlign: 'right' }}>
              {useKi ? 'KI-gestützte Analyse (DSGVO-Zustimmung nötig)' : 'Rein algorithmisch ? kein KI-Aufruf, sofortige Ergebnisse'}
            </span>
          </div>
          {/* DSGVO ? only shown in KI mode */}
          {useKi && (
          <div style={{ fontSize: 10, color: T.dim, marginBottom: 10, padding: '6px 8px', background: T.bg, borderRadius: 6, lineHeight: 1.5, border: `1px solid ${T.border}` }}>
            <div style={{ fontWeight: 700, fontSize: 11, marginBottom: 3, color: T.text }}>? DSGVO-Hinweis (Art. 13, 28 DSGVO)</div>
            <div>? Hochgeladene Dokumente werden <b>ausschließlich zur Analyse</b> verarbeitet und <b>sofort nach Extraktion gelöscht</b></div>
            <div>? Es erfolgt <b>keine dauerhafte Speicherung</b> der Originaldokumente</div>
            <div>? Die KI-Verarbeitung erfolgt über sichere, verschlüsselte Verbindungen</div>
            <div>? <b>Keine Weitergabe</b> an Dritte ? Daten werden nicht für KI-Training verwendet</div>
            <div style={{ marginTop: 4 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                <input type="checkbox" checked={dsgvoAccepted} onChange={e => setDsgvoAccepted(e.target.checked)} style={{ accentColor: T.blue }} />
                <span style={{ fontSize: 10, fontWeight: 600 }}>Ich habe den DSGVO-Hinweis gelesen und stimme der Verarbeitung zu</span>
              </label>
            </div>
          </div>
          )}
          <div style={{ fontSize: 10, color: T.orange, marginBottom: 10, padding: '4px 8px', background: T.orange + '08', borderRadius: 6 }}>
            ?? {useKi ? 'KI-Vorschläge' : 'Algorithmische Ergebnisse'} ? müssen juristisch geprüft werden
          </div>
          {/* File upload */}
          <div style={{ border: `1px dashed ${T.border}`, borderRadius: 8, padding: '10px 12px', marginBottom: 8, background: T.bg }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: files.length > 0 ? 8 : 0 }}>
              <button onClick={() => fileInputRef.current?.click()} disabled={uploading} style={{
                fontFamily: sans, fontSize: 11, fontWeight: 600, color: T.blue,
                background: T.blue + '10', border: `1px solid ${T.blue}30`,
                borderRadius: 6, padding: '5px 12px', cursor: uploading ? 'wait' : 'pointer',
              }}>
                {uploading ? '? Lädt?' : '? Dokument hochladen'}
              </button>
              <span style={{ fontSize: 10, color: T.dim }}>PDF, DOCX, TXT, CSV ? max 20MB</span>
              <input ref={fileInputRef} type="file" multiple accept=".pdf,.docx,.doc,.txt,.csv,.xml,.json" onChange={handleFileUpload} style={{ display: 'none' }} />
            </div>
            {files.length > 0 && (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {files.map((f, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, background: T.surface, padding: '3px 8px', borderRadius: 5, border: `1px solid ${T.border}` }}>
                    <span>?</span>
                    <span style={{ maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{f.name}</span>
                    <span style={{ color: T.dim }}>({(f.size / 1024).toFixed(0)}KB)</span>
                    <button onClick={() => removeFile(i)} style={{ border: 'none', background: 'none', color: T.red, cursor: 'pointer', fontSize: 11, padding: '0 2px' }}>?</button>
                  </div>
                ))}
              </div>
            )}
          </div>
          <textarea value={text} onChange={e => setText(e.target.value)} placeholder="Oder Text manuell einfügen?" rows={3}
            style={{ fontFamily: sans, fontSize: 12, width: '100%', padding: '8px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg, outline: 'none', color: T.text, resize: 'vertical', lineHeight: 1.5 }}
          />
          <div style={{ marginTop: 8, display: 'flex', gap: 8, alignItems: 'center' }}>
            <button onClick={analyze} disabled={!hasInput || loading || (useKi && !dsgvoAccepted)} style={{
              fontFamily: sans, fontSize: 11, fontWeight: 600, color: '#fff',
              background: loading ? T.dim : ((useKi && !dsgvoAccepted) ? T.dim : T.blue),
              border: 'none', borderRadius: 8, padding: '6px 14px',
              cursor: loading ? 'wait' : (!hasInput || (useKi && !dsgvoAccepted) ? 'not-allowed' : 'pointer'),
              opacity: !hasInput || (useKi && !dsgvoAccepted) ? 0.5 : 1,
            }}>
              {loading ? '? Analysiere?' : useKi ? '? KI-Extraktion' : '? Algorithmisch extrahieren'}
            </button>
            {(text.length > 0 || files.length > 0) && (
              <span style={{ fontSize: 10, color: T.dim }}>
                {files.length > 0 && `${files.length} Datei(en)`}
                {files.length > 0 && text.length > 0 && ' + '}
                {text.length > 0 && `${text.length} Zeichen`}
              </span>
            )}
          </div>
          {/* Results with adopt buttons */}
          {result && (
            <div style={{ marginTop: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <div style={{ fontSize: 11, color: T.dim, lineHeight: 1.4, flex: 1 }}>
                  {result.zusammenfassung.slice(0, 150)}?
                </div>
                {c && onUpdateCase && (
                  <button onClick={adoptAll} style={{
                    fontFamily: sans, fontSize: 10, fontWeight: 700, color: '#fff',
                    background: T.green, border: 'none', borderRadius: 6, padding: '5px 12px',
                    cursor: 'pointer', whiteSpace: 'nowrap', marginLeft: 8,
                  }}>
                    ? Alle übernehmen
                  </button>
                )}
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div>
                  <div style={{
                    fontSize: 11, fontWeight: 600, color: T.blue, marginBottom: 8,
                    textTransform: 'uppercase', letterSpacing: '0.05em',
                    paddingBottom: 6, borderBottom: `1px solid ${T.border}`,
                  }}>
                    Eigene Argumente ? {ownArgs.length}
                  </div>
                  {ownArgs.map((a, i) => {
                    const globalIdx = result!.argumente.indexOf(a);
                    return <CompactArgCard key={i} arg={a} color={T.blue} adopted={adopted.has(globalIdx)} onAdopt={() => adoptArg(a, globalIdx)} canAdopt={!!c && !!onUpdateCase} />;
                  })}
                </div>
                <div>
                  <div style={{
                    fontSize: 11, fontWeight: 600, color: T.red, marginBottom: 8,
                    textTransform: 'uppercase', letterSpacing: '0.05em',
                    paddingBottom: 6, borderBottom: `1px solid ${T.border}`,
                  }}>
                    Gegenseite ? {oppArgs.length}
                  </div>
                  {oppArgs.map((a, i) => {
                    const globalIdx = result!.argumente.indexOf(a);
                    return <CompactArgCard key={i} arg={a} color={T.red} adopted={adopted.has(globalIdx)} onAdopt={() => adoptArg(a, globalIdx)} canAdopt={!!c && !!onUpdateCase} />;
                  })}
                </div>
              </div>
              {/* Widersprüche */}
              {result.widersprueche && result.widersprueche.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: T.red, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    ? Widersprüche ({result.widersprueche.length})
                  </div>
                  {result.widersprueche.map((w, i) => (
                    <WiderspruchCard key={i} item={w} canAdopt={!!c && !!onUpdateCase} adopted={adoptedWidersprueche.has(i)} onAdopt={() => adoptWiderspruch(w, i)} />
                  ))}
                </div>
              )}
              {/* Druckmittel */}
              {result.druckmittel && result.druckmittel.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: '#9333ea', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    ? Druckmittel & Hebel ({result.druckmittel.length})
                  </div>
              {result.druckmittel.map((d, i) => (
                    <DruckmittelCard key={i} item={d} canAdopt={!!c && !!onUpdateCase} adopted={adoptedDruckmittel.has(i)} onAdopt={() => adoptDruckmittel(d, i)} />
                  ))}
                </div>
              )}
              {/* Eigene Schwächen */}
              {result.eigen_schwaechen && result.eigen_schwaechen.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: T.orange, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    ?? Eigene Schwächen & Angriffspunkte ({result.eigen_schwaechen.length})
                  </div>
                  {result.eigen_schwaechen.map((s, i) => (
                    <EigenSchwacheCard key={i} item={s} canAdopt={!!c && !!onUpdateCase} adopted={adoptedEigenSchwaechen.has(i)} onAdopt={() => adoptEigenSchwaeche(s, i)} />
                  ))}
                </div>
              )}
              {/* Psychologische Profile */}
              {result.psycho_profile && result.psycho_profile.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: T.dim, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    ? Psychologische Analyse ? Machiavelli / 48 Laws ({result.psycho_profile.length})
                  </div>
                  {(() => {
                    const ownProfiles = result.psycho_profile!.filter(p => p.seite === 'own');
                    const oppProfiles = result.psycho_profile!.filter(p => p.seite === 'opp');
                    return (
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                        <div>
                          <div style={{ fontSize: 10, fontWeight: 600, color: T.orange, marginBottom: 6, paddingBottom: 4, borderBottom: `1px solid ${T.border}` }}>
                            ?? Eigene Seite ? Verwundbarkeit ({ownProfiles.length})
                          </div>
                          {ownProfiles.length === 0 && <div style={{ fontSize: 10, color: T.dim, fontStyle: 'italic' }}>Keine erkannt</div>}
                          {ownProfiles.map((p, i) => {
                            const key = `own-${i}`;
                            return <PsychoCard key={i} item={p} canAdopt={!!c && !!onUpdateCase} adopted={adoptedPsycho.has(key)} onAdopt={() => adoptPsychoProfile(p, i)} />;
                          })}
                        </div>
                        <div>
                          <div style={{ fontSize: 10, fontWeight: 600, color: T.text, marginBottom: 6, paddingBottom: 4, borderBottom: `1px solid ${T.border}` }}>
                            ? Gegenseite ? Ausnutzbar ({oppProfiles.length})
                          </div>
                          {oppProfiles.length === 0 && <div style={{ fontSize: 10, color: T.dim, fontStyle: 'italic' }}>Keine erkannt</div>}
                          {oppProfiles.map((p, i) => {
                            const key = `opp-${i}`;
                            return <PsychoCard key={i} item={p} canAdopt={!!c && !!onUpdateCase} adopted={adoptedPsycho.has(key)} onAdopt={() => adoptPsychoProfile(p, ownProfiles.length + i)} />;
                          })}
                        </div>
                      </div>
                    );
                  })()}
                </div>
              )}
              {/* Paragraphen */}
              {result.paragraphen && result.paragraphen.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: T.text, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    ? Relevante Paragraphen ({result.paragraphen.length})
                  </div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                    {result.paragraphen.map((p, i) => (
                      <ParagraphChip key={i} item={p} />
                    ))}
                  </div>
                </div>
              )}
              {/* Stränge / Kausalzusammenhänge */}
              {result.straenge && result.straenge.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: '#0891b2', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    ? Stränge & Kausalzusammenhänge ({result.straenge.length})
                  </div>
                  <div style={{ fontSize: 10, color: T.dim, marginBottom: 8 }}>
                    Automatisch erkannte Zusammenhänge ? einzeln übernehmen oder über ?Alle übernehmen".
                  </div>
                  {result.straenge.map((chain, i) => {
                    const fromArg = result!.argumente[chain.from_index];
                    const toArg = result!.argumente[chain.to_index];
                    if (!fromArg || !toArg) return null;
                    const isAdopted = adoptedStraenge.has(i);
                    const typeLabel = chain.type === 'supports' ? '? stützt' : chain.type === 'weakens' ? '? schwächt' : '? kausal';
                    const typeColor = chain.type === 'supports' ? T.green : chain.type === 'weakens' ? T.red : '#0891b2';
                    return (
                      <div key={i} style={{
                        padding: '8px 10px', marginBottom: 4, borderRadius: 6,
                        background: isAdopted ? T.green + '10' : typeColor + '08',
                        border: `1px solid ${isAdopted ? T.green + '40' : typeColor + '25'}`,
                        fontSize: 11, lineHeight: 1.5,
                        display: 'flex', alignItems: 'flex-start', gap: 8,
                      }}>
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                            <span style={{ fontWeight: 600, color: fromArg.side === 'own' ? T.blue : T.red, maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'inline-block' }}>
                              {fromArg.label}
                            </span>
                            <span style={{ color: typeColor, fontWeight: 700, fontSize: 10 }}>{typeLabel}</span>
                            <span style={{ color: '#666' }}>?</span>
                            <span style={{ fontWeight: 600, color: toArg.side === 'own' ? T.blue : T.red, maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'inline-block' }}>
                              {toArg.label}
                            </span>
                          </div>
                          {chain.beschreibung && (
                            <div style={{ fontSize: 10, color: T.dim, marginTop: 3 }}>{chain.beschreibung}</div>
                          )}
                        </div>
                        {c && onUpdateCase && (
                          <button
                            onClick={() => !isAdopted && adoptStrang(chain, i)}
                            disabled={isAdopted}
                            style={{
                              fontFamily: sans, fontSize: 9, fontWeight: 700,
                              color: isAdopted ? T.green : '#fff',
                              background: isAdopted ? 'transparent' : T.green,
                              border: isAdopted ? `1px solid ${T.green}` : 'none',
                              borderRadius: 5, padding: '3px 8px', cursor: isAdopted ? 'default' : 'pointer',
                              whiteSpace: 'nowrap', flexShrink: 0, marginTop: 2,
                            }}
                          >
                            {isAdopted ? '?' : '+ Graph'}
                          </button>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
              {result.warnungen && result.warnungen.length > 0 && (
                <div style={{ marginTop: 8 }}>
                  {result.warnungen.map((w, i) => (
                    <div key={i} style={{ fontSize: 10, color: T.orange }}>?? {w}</div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
function CompactArgCard({ arg, color, adopted, onAdopt, canAdopt }: {
  arg: ExtractedArg; color: string; adopted: boolean; onAdopt: () => void; canAdopt: boolean;
}) {
  const [open, setOpen] = useState(false);
  const sideColor = arg.side === 'own' ? T.blue : T.red;
  return (
    <div style={{
      padding: '10px 12px', marginBottom: 6, borderRadius: 10,
      background: adopted ? 'rgba(0,0,0,0.02)' : T.surface,
      border: `1px solid ${T.border}`,
      transition: 'all 0.2s ease',
    }}>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <div onClick={() => setOpen(!open)} style={{ flex: 1, cursor: 'pointer' }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: T.text, lineHeight: 1.4, letterSpacing: '-0.01em' }}>
            {arg.label}
          </div>
          {arg.arg_type && (
            <span style={{ fontSize: 10, color: T.dim, fontWeight: 500, fontFamily: sans, letterSpacing: '0.02em' }}>
              {arg.arg_type}
            </span>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: scol(arg.strength * 10),
            background: scol(arg.strength * 10) + '0a', padding: '2px 8px', borderRadius: 6,
            fontFamily: "'SF Mono', monospace", letterSpacing: '0.02em',
          }}>
            {arg.strength}/10
          </div>
          {arg.seite && (
            <span style={{ fontSize: 10, color: T.dim, fontFamily: "'SF Mono', monospace" }}>S.{arg.seite}</span>
          )}
          {canAdopt && !adopted && (
            <button onClick={onAdopt} style={{
              fontFamily: sans, fontSize: 10, fontWeight: 600, color: T.blue,
              background: T.blue + '0a', border: `1px solid ${T.blue}20`,
              borderRadius: 6, padding: '3px 10px', cursor: 'pointer',
              transition: 'all 0.15s',
            }}>Übernehmen</button>
          )}
          {adopted && (
            <span style={{ fontSize: 10, color: T.green, fontWeight: 600 }}>?</span>
          )}
        </div>
      </div>
      {open && (
        <div style={{ marginTop: 8, paddingTop: 8, borderTop: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6 }}>{arg.content}</div>
          {arg.legal_basis && (
            <div style={{
              fontSize: 11, color: T.blue, marginTop: 6, fontWeight: 500,
              fontFamily: "'SF Mono', monospace",
            }}>
              {arg.legal_basis}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
function WiderspruchCard({ item, canAdopt, adopted, onAdopt }: { item: Widerspruch; canAdopt?: boolean; adopted?: boolean; onAdopt?: () => void }) {
  const [open, setOpen] = useState(false);
  return (
    <div style={{
      padding: '10px 12px', marginBottom: 6, borderRadius: 10,
      background: adopted ? 'rgba(0,0,0,0.02)' : T.surface,
      border: `1px solid ${T.border}`,
      transition: 'all 0.2s ease',
    }}>
      <div onClick={() => setOpen(!open)} style={{ display: 'flex', gap: 8, alignItems: 'center', cursor: 'pointer' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: T.text, lineHeight: 1.4, letterSpacing: '-0.01em' }}>{item.titel}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: T.red,
            background: T.red + '0a', padding: '2px 8px', borderRadius: 6,
            fontFamily: "'SF Mono', monospace",
          }}>
            {item.schwere}/10
          </div>
          {item.angreifbar && (
            <span style={{
              fontSize: 9, fontWeight: 700, color: '#fff', background: T.red,
              padding: '2px 6px', borderRadius: 4, letterSpacing: '0.03em',
            }}>ANGREIFBAR</span>
          )}
          {item.seite && <span style={{ fontSize: 10, color: T.dim, fontFamily: "'SF Mono', monospace" }}>S.{item.seite}</span>}
          {canAdopt && !adopted && (
            <button onClick={(e) => { e.stopPropagation(); onAdopt?.(); }} style={{
              fontFamily: sans, fontSize: 10, fontWeight: 600, color: T.red,
              background: T.red + '0a', border: `1px solid ${T.red}20`,
              borderRadius: 6, padding: '3px 10px', cursor: 'pointer',
              transition: 'all 0.15s',
            }}>? Strategie</button>
          )}
          {adopted && <span style={{ fontSize: 10, color: T.green, fontWeight: 600 }}>?</span>}
        </div>
      </div>
      {open && (
        <div style={{ marginTop: 8, paddingTop: 8, borderTop: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6 }}>{item.beschreibung}</div>
        </div>
      )}
    </div>
  );
}
function DruckmittelCard({ item, canAdopt, adopted, onAdopt }: { item: DruckmittelItem; canAdopt?: boolean; adopted?: boolean; onAdopt?: () => void }) {
  const [open, setOpen] = useState(false);
  return (
    <div style={{
      padding: '10px 12px', marginBottom: 6, borderRadius: 10,
      background: adopted ? 'rgba(0,0,0,0.02)' : T.surface,
      border: `1px solid ${T.border}`,
      transition: 'all 0.2s ease',
    }}>
      <div onClick={() => setOpen(!open)} style={{ display: 'flex', gap: 8, alignItems: 'center', cursor: 'pointer' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: T.text, lineHeight: 1.4, letterSpacing: '-0.01em' }}>{item.titel}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: T.purple,
            background: T.purple + '0a', padding: '2px 8px', borderRadius: 6,
            fontFamily: "'SF Mono', monospace",
          }}>
            {item.staerke}/10
          </div>
          <span style={{
            fontSize: 9, fontWeight: 600, letterSpacing: '0.02em',
            color: item.zielseite === 'opp' ? T.green : T.orange,
          }}>
            {item.zielseite === 'opp' ? '? Gegner' : '? Eigen'}
          </span>
          {canAdopt && !adopted && (
            <button onClick={(e) => { e.stopPropagation(); onAdopt?.(); }} style={{
              fontFamily: sans, fontSize: 10, fontWeight: 600, color: T.purple,
              background: T.purple + '0a', border: `1px solid ${T.purple}20`,
              borderRadius: 6, padding: '3px 10px', cursor: 'pointer',
              transition: 'all 0.15s',
            }}>? Strategie</button>
          )}
          {adopted && <span style={{ fontSize: 10, color: T.green, fontWeight: 600 }}>?</span>}
        </div>
      </div>
      {open && (
        <div style={{ marginTop: 8, paddingTop: 8, borderTop: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6 }}>{item.beschreibung}</div>
          {item.legal_basis && (
            <div style={{ fontSize: 11, color: T.blue, marginTop: 6, fontWeight: 500, fontFamily: "'SF Mono', monospace" }}>
              {item.legal_basis}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
function PsychoCard({ item, canAdopt, adopted, onAdopt }: { item: PsychoProfile; canAdopt?: boolean; adopted?: boolean; onAdopt?: () => void }) {
  const [open, setOpen] = useState(false);
  const isOwn = item.seite === 'own';
  return (
    <div style={{
      padding: '10px 12px', marginBottom: 6, borderRadius: 10,
      background: adopted ? 'rgba(0,0,0,0.02)' : T.surface, border: `1px solid ${T.border}`,
      transition: 'all 0.2s ease',
    }}>
      <div onClick={() => setOpen(!open)} style={{ display: 'flex', gap: 8, alignItems: 'center', cursor: 'pointer' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: T.text, lineHeight: 1.4, letterSpacing: '-0.01em' }}>{item.schwaeche}</div>
          <span style={{ fontSize: 10, color: T.dim, fontWeight: 500 }}>{item.kategorie}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: isOwn ? T.orange : T.text,
            background: isOwn ? T.orange + '0a' : 'rgba(0,0,0,0.04)', padding: '2px 8px', borderRadius: 6,
            fontFamily: "'SF Mono', monospace",
          }}>
            {item.ausnutzbar}/10
          </div>
          {canAdopt && !adopted && (
            <button onClick={(e) => { e.stopPropagation(); onAdopt?.(); }} style={{
              fontFamily: sans, fontSize: 10, fontWeight: 600, color: T.text,
              background: 'rgba(0,0,0,0.04)', border: `1px solid ${T.border}`,
              borderRadius: 6, padding: '3px 10px', cursor: 'pointer',
              transition: 'all 0.15s',
            }}>? Strategie</button>
          )}
          {adopted && <span style={{ fontSize: 10, color: T.green, fontWeight: 600 }}>?</span>}
        </div>
      </div>
      {open && (
        <div style={{ marginTop: 8, paddingTop: 8, borderTop: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6 }}>{item.beschreibung}</div>
          {item.taktik && (
            <div style={{ fontSize: 11, color: T.text, marginTop: 6, fontWeight: 600, fontFamily: "'SF Mono', monospace" }}>
              ? {item.taktik}
            </div>
          )}
          {item.textstelle && (
            <div style={{ fontSize: 10, color: T.dim, marginTop: 4, fontStyle: 'italic', lineHeight: 1.5, padding: '4px 8px', background: 'rgba(0,0,0,0.02)', borderRadius: 6 }}>
              ?{item.textstelle}"
            </div>
          )}
        </div>
      )}
    </div>
  );
}
function EigenSchwacheCard({ item, canAdopt, adopted, onAdopt }: { item: EigenSchwaeche; canAdopt?: boolean; adopted?: boolean; onAdopt?: () => void }) {
  const [open, setOpen] = useState(false);
  return (
    <div style={{
      padding: '10px 12px', marginBottom: 6, borderRadius: 10,
      background: adopted ? 'rgba(0,0,0,0.02)' : T.surface, border: `1px solid ${T.border}`,
      transition: 'all 0.2s ease',
    }}>
      <div onClick={() => setOpen(!open)} style={{ display: 'flex', gap: 8, alignItems: 'center', cursor: 'pointer' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: T.text, lineHeight: 1.4, letterSpacing: '-0.01em' }}>{item.titel}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: T.orange,
            background: T.orange + '0a', padding: '2px 8px', borderRadius: 6,
            fontFamily: "'SF Mono', monospace",
          }}>
            {item.schwere}/10
          </div>
          {item.seite && <span style={{ fontSize: 10, color: T.dim, fontFamily: "'SF Mono', monospace" }}>S.{item.seite}</span>}
          {canAdopt && !adopted && (
            <button onClick={(e) => { e.stopPropagation(); onAdopt?.(); }} style={{
              fontFamily: sans, fontSize: 10, fontWeight: 600, color: T.orange,
              background: T.orange + '0a', border: `1px solid ${T.orange}20`,
              borderRadius: 6, padding: '3px 10px', cursor: 'pointer',
              transition: 'all 0.15s',
            }}>? Strategie</button>
          )}
          {adopted && <span style={{ fontSize: 10, color: T.green, fontWeight: 600 }}>?</span>}
        </div>
      </div>
      {open && (
        <div style={{ marginTop: 8, paddingTop: 8, borderTop: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6 }}>{item.beschreibung}</div>
          {item.gegenmassnahme && (
            <div style={{ fontSize: 11, color: T.green, marginTop: 6, fontWeight: 500 }}>
              ? Gegenmaßnahme: {item.gegenmassnahme}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
function ParagraphChip({ item }: { item: ParagraphRef }) {
  const [open, setOpen] = useState(false);
  return (
    <div
      onClick={() => setOpen(!open)}
      style={{
        fontSize: 10, fontWeight: 600, color: T.text, background: 'rgba(0,0,0,0.04)',
        border: `1px solid ${T.border}`, borderRadius: 5, padding: '3px 8px',
        cursor: 'pointer', position: 'relative',
      }}
    >
      {item.paragraph}
      {!item.im_text_genannt && <span style={{ fontSize: 8, color: T.dim, marginLeft: 3 }}>(ergänzt)</span>}
      {open && (
        <div style={{
          position: 'absolute', top: '100%', left: 0, zIndex: 10, marginTop: 4,
          background: T.surface, border: `1px solid ${T.border}`, borderRadius: 6,
          padding: '6px 8px', fontSize: 10, color: T.dim, width: 220, lineHeight: 1.4,
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
        }}>
          {item.kontext}
        </div>
      )}
    </div>
  );
}
