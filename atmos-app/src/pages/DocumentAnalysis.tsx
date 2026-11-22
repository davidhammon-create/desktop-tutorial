import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label } from '@/components/lexara/Primitives';
import { FileUploadSection } from '@/components/business/FileUploadSection';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { UploadedFile } from '@/types/business';
interface AnalysisResult {
  zusammenfassung: string;
  risiken: { label: string; schwere: string; beschreibung: string }[];
  empfehlungen: string[];
  relevanteParagraphen: string[];
  lohntEsSich?: {
    ersparnis?: number;
    kosten?: number;
    fazit?: string;
  };
}
const DocumentAnalysisPage = () => {
  const navigate = useNavigate();
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [fragestellung, setFragestellung] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({
    zusammenfassung: true,
    risiken: true,
    empfehlungen: false,
    paragraphen: false,
    lohnt: false,
  });
  const toggleSection = (key: string) =>
    setExpandedSections(prev => ({ ...prev, [key]: !prev[key] }));
  const handleAnalyze = async () => {
    if (!files.length && !fragestellung) {
      toast.error('Bitte lade mindestens eine Datei hoch oder stelle eine Frage.');
      return;
    }
    setLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke('analyze-document', {
        body: {
          fragestellung,
          uploadedFiles: files.map(f => ({
            name: f.name,
            type: f.type,
            storagePath: f.storagePath,
          })),
        },
      });
      if (error) throw error;
      if (!data?.success) throw new Error(data?.error || 'Keine Antwort');
      setResult(data.data as AnalysisResult);
      toast.success('Analyse abgeschlossen!');
    } catch (e: any) {
      console.error(e);
      toast.error(e.message || 'Analyse fehlgeschlagen');
    } finally {
      setLoading(false);
    }
  };
  const fmt = (n?: number) => n != null ? `${n.toLocaleString('de-DE')} €` : '?';
  const sections = result ? [
    {
      key: 'zusammenfassung', title: 'Zusammenfassung',
      hint: 'Kurze Übersicht der Analyse-Ergebnisse',
      content: <p style={{ fontSize: 14, lineHeight: 1.7, color: T.text, whiteSpace: 'pre-wrap' }}>{result.zusammenfassung}</p>,
    },
    {
      key: 'risiken', title: `Risiken (${result.risiken.length})`,
      hint: 'Identifizierte Risiken mit Schweregrad',
      content: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {result.risiken.map((r, i) => (
            <div key={i} style={{
              padding: '10px 14px', borderRadius: 10,
              background: r.schwere === 'hoch' ? '#ef444410' : r.schwere === 'mittel' ? '#f9731610' : T.bg,
            }}>
              <div style={{ fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{
                  fontSize: 10, fontWeight: 700, padding: '2px 6px', borderRadius: 4,
                  background: r.schwere === 'hoch' ? '#ef4444' : r.schwere === 'mittel' ? '#f97316' : T.dim,
                  color: '#fff', textTransform: 'uppercase',
                }}>{r.schwere}</span>
                {r.label}
              </div>
              <div style={{ fontSize: 12, color: T.dim, marginTop: 4 }}>{r.beschreibung}</div>
            </div>
          ))}
        </div>
      ),
    },
    {
      key: 'empfehlungen', title: 'Empfehlungen',
      hint: 'Konkrete Handlungsempfehlungen basierend auf der Analyse',
      content: (
        <ul style={{ margin: 0, paddingLeft: 20 }}>
          {result.empfehlungen.map((e, i) => (
            <li key={i} style={{ fontSize: 13, color: T.text, marginBottom: 6, lineHeight: 1.5 }}>{e}</li>
          ))}
        </ul>
      ),
    },
    {
      key: 'paragraphen', title: 'Relevante Paragraphen',
      hint: 'Deutsche Gesetze und Paragraphen die relevant sind',
      content: (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {result.relevanteParagraphen.map((p, i) => (
            <span key={i} style={{
              fontSize: 12, padding: '4px 10px', borderRadius: 6,
              background: T.blue + '10', color: T.blue, fontWeight: 500,
            }}>{p}</span>
          ))}
        </div>
      ),
    },
    ...(result.lohntEsSich ? [{
      key: 'lohnt', title: 'Lohnt es sich?',
      hint: 'Kosten-Nutzen-Analyse: Ersparnis vs. Risiken',
      content: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ display: 'flex', gap: 16 }}>
            <div style={{ flex: 1, padding: 12, borderRadius: 10, background: T.green + '10', textAlign: 'center' }}>
              <div style={{ fontSize: 11, color: T.dim }}>Ersparnis</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: T.green }}>{fmt(result.lohntEsSich!.ersparnis)}</div>
            </div>
            <div style={{ flex: 1, padding: 12, borderRadius: 10, background: '#ef444410', textAlign: 'center' }}>
              <div style={{ fontSize: 11, color: T.dim }}>Kosten/Strafen</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: '#ef4444' }}>{fmt(result.lohntEsSich!.kosten)}</div>
            </div>
          </div>
          {result.lohntEsSich!.fazit && (
            <div style={{ fontSize: 13, color: T.text, padding: 12, background: T.bg, borderRadius: 10, lineHeight: 1.6 }}>
              {result.lohntEsSich!.fazit}
            </div>
          )}
        </div>
      ),
    }] : []),
  ] : [];
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Top Bar */}
      <div style={{
        background: T.surface, borderBottom: `1px solid ${T.border}`,
        padding: '10px 20px', display: 'flex', alignItems: 'center', gap: 16,
      }}>
        <button onClick={() => navigate('/')} style={{
          fontFamily: sans, fontSize: 12, fontWeight: 500, color: T.dim,
          background: 'none', border: `1px solid ${T.border}`, borderRadius: 6,
          padding: '4px 10px', cursor: 'pointer',
        }}>Home</button>
        <div style={{ width: 1, height: 24, background: T.border }} />
        <div style={{ fontSize: 17, fontWeight: 700 }}>Dokument-Analyse</div>
        <div style={{ fontSize: 12, color: T.dim }}>Lade Dateien hoch und lass sie KI-gestützt analysieren</div>
      </div>
      <div style={{ maxWidth: 800, margin: '0 auto', padding: 24 }}>
        <Panel>
          <Label>Dateien hochladen</Label>
          <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>
            Lade Verträge, Buchhaltung, CSV-Dateien oder andere Dokumente hoch. Die KI liest den Inhalt und analysiert ihn.
          </div>
          <FileUploadSection
            files={files}
            scenarioId={`doc-analysis-${Date.now()}`}
            onFilesChange={setFiles}
          />
          <Label>Fragestellung (optional)</Label>
          <div style={{ fontSize: 12, color: T.dim, marginBottom: 8 }}>
            Was möchtest du über die Dokumente wissen? Z.B. "Gibt es versteckte Risiken?" oder "Ist der Vertrag fair?"
          </div>
          <textarea
            value={fragestellung}
            onChange={e => setFragestellung(e.target.value)}
            placeholder="z.B. Prüfe den Vertrag auf nachteilige Klauseln?"
            rows={3}
            style={{
              fontFamily: sans, fontSize: 14, width: '100%', padding: '10px 14px',
              border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
              outline: 'none', color: T.text, resize: 'vertical', marginBottom: 20,
            }}
          />
          <button
            onClick={handleAnalyze}
            disabled={loading || (!files.length && !fragestellung)}
            style={{
              fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', width: '100%',
              background: loading ? T.dim : T.blue,
              border: 'none', borderRadius: 12, padding: '12px 20px',
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            {loading ? 'Analysiere? (ca. 15-30 Sek.)' : 'Dokumente analysieren'}
          </button>
        </Panel>
        {/* Results */}
        {result && (
          <div style={{ marginTop: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
            {sections.map(sec => (
              <div key={sec.key} style={{
                background: T.surface, borderRadius: 12,
                overflow: 'hidden',
              }}>
                <button
                  onClick={() => toggleSection(sec.key)}
                  style={{
                    width: '100%', fontFamily: sans, fontSize: 14, fontWeight: 600,
                    color: T.text, background: 'none', border: 'none',
                    padding: '14px 18px', cursor: 'pointer', textAlign: 'left',
                    display: 'flex', alignItems: 'center', gap: 10,
                  }}
                >
                  <span style={{ flex: 1 }}>{sec.title}</span>
                  <span style={{ fontSize: 12, color: T.dim, fontWeight: 400, marginRight: 8 }}>
                    {sec.hint}
                  </span>
                  <span style={{ fontSize: 12, color: T.dim, transition: 'transform 0.2s', transform: expandedSections[sec.key] ? 'rotate(90deg)' : 'rotate(0)' }}>?</span>
                </button>
                {expandedSections[sec.key] && (
                  <div style={{ padding: '0 18px 16px' }}>{sec.content}</div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
export default DocumentAnalysisPage;
