import React, { useState } from 'react';
import { LexaraCase } from '@/types/lexara';
import { T, sans, scol } from './theme';
import { Panel, SectionTitle, Chip, Bar, Btn } from './Primitives';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
interface GegnerProfil {
  organisation: { name: string; groesse: string; finanzlage: string; reputation_sensibel: boolean; branche: string };
  entscheider: { name: string; alter: string; persoenlichkeit: string; karriere_phase: string; schwaechen: string };
  anwalt_gegenseite: { kanzlei: string; bekannt_fuer: string; schwaechen: string };
  bisheriges_verhalten: { verhandlungsbereitschaft: string; taktik: string; fehler: string };
}
interface EigenePosition {
  staerken: string;
  schwaechen: string;
  ziel_maximal: string;
  ziel_realistisch: string;
  ziel_minimal: string;
  nicht_verhandelbar: string;
}
interface Kontext {
  oeffentlichkeit: string;
  zeitdruck: string;
  externe_faktoren: string;
}
const MODULES = [
  { id: 'profiling', icon: '?', label: 'Psychologisches Profil', desc: 'Big Five + Dark Triad Assessment der Gegenpartei. Identifiziert Trigger, Schwachpunkte und optimalen Verhandlungsansatz.' },
  { id: 'leverage', icon: '?', label: 'Druckmittel-Analyse', desc: 'Systematische Identifikation aller Schwachstellen: Zeitdruck, Finanzen, Reputation, persönliche Risiken.' },
  { id: 'tactics', icon: '??', label: 'Strategieempfehlungen', desc: '3-5 taktische Optionen von kooperativ bis aggressiv mit Erfolgswahrscheinlichkeit und Risikobewertung.' },
  { id: 'timing', icon: '?', label: 'Timing & Momentum', desc: 'Optimaler Zeitpunkt für jeden Schritt. Identifiziert kritische Zeitfenster und Schwächephasen des Gegners.' },
  { id: 'infowar', icon: '?', label: 'Informationsstrategie', desc: 'Was offenlegen, verbergen oder als Bluff nutzen? Ethische Klassifizierung jeder Maßnahme.' },
  { id: 'negotiation', icon: '?', label: 'Verhandlungsskript', desc: 'Maßgeschneidertes Skript mit FBI-Techniken (Mirroring, Calibrated Questions) und konkreten Formulierungen.' },
] as const;
type ModuleId = typeof MODULES[number]['id'];
export function StrategieberaterTab({ c, onUpdateCase }: { c: LexaraCase; onUpdateCase: (c: LexaraCase) => void }) {
  const { toast } = useToast();
  const [showDisclaimer, setShowDisclaimer] = useState(true);
  const [activeModule, setActiveModule] = useState<ModuleId | null>(null);
  const [loading, setLoading] = useState<ModuleId | null>(null);
  const [results, setResults] = useState<Record<string, any>>({});
  const [showInput, setShowInput] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({});
  // Input state
  const [gegner, setGegner] = useState<GegnerProfil>({
    organisation: { name: '', groesse: '', finanzlage: '', reputation_sensibel: false, branche: '' },
    entscheider: { name: '', alter: '', persoenlichkeit: '', karriere_phase: '', schwaechen: '' },
    anwalt_gegenseite: { kanzlei: '', bekannt_fuer: '', schwaechen: '' },
    bisheriges_verhalten: { verhandlungsbereitschaft: '', taktik: '', fehler: '' },
  });
  const [eigene, setEigene] = useState<EigenePosition>({
    staerken: '', schwaechen: '', ziel_maximal: '', ziel_realistisch: '', ziel_minimal: '', nicht_verhandelbar: '',
  });
  const [kontext, setKontext] = useState<Kontext>({ oeffentlichkeit: '', zeitdruck: '', externe_faktoren: '' });
  const toggleSection = (key: string) => setExpandedSections(prev => ({ ...prev, [key]: !prev[key] }));
  const runAnalysis = async (moduleId: ModuleId) => {
    setLoading(moduleId);
    setActiveModule(moduleId);
    try {
      const { data, error } = await supabase.functions.invoke('strategy-advisor', {
        body: {
          module: moduleId,
          caseData: {
            name: c.name, number: c.number, court: c.court, type: c.type, goal: c.goal, status: c.status,
            arguments: c.arguments, evidence: c.evidence, persons: c.persons, fristen: c.fristen,
          },
          gegnerProfil: gegner,
          eigenePosition: eigene,
          kontext,
        },
      });
      if (error) throw error;
      if (data?.error) throw new Error(data.error);
      setResults(prev => ({ ...prev, [moduleId]: data.result }));
      toast({ title: 'Analyse abgeschlossen', description: `${MODULES.find(m => m.id === moduleId)?.label} wurde generiert.` });
    } catch (e: any) {
      console.error(e);
      toast({ title: 'Fehler', description: e.message || 'Analyse fehlgeschlagen', variant: 'destructive' });
    } finally {
      setLoading(null);
    }
  };
  if (showDisclaimer) {
    return (
      <div style={{ padding: 24, maxWidth: 700, margin: '0 auto' }}>
        <Panel style={{  }}>
          <div style={{ fontSize: 20, fontWeight: 700, marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
            ?? Rechtshinweis & Vertraulichkeit
          </div>
          <div style={{ fontSize: 14, color: T.dim, lineHeight: 1.7, marginBottom: 16 }}>
            <p style={{ marginBottom: 12 }}>Diese Analyse dient <strong>ausschließlich der Vorbereitung</strong> auf mögliche gegnerische Taktiken und der Entwicklung legitimer Verhandlungsstrategien.</p>
            <p style={{ marginBottom: 12 }}>? Absolut vertraulich (§ 203 StGB Anwaltsgeheimnis)</p>
            <p style={{ marginBottom: 12 }}>? Keine Anleitung zu unlauteren Methoden (§ 138 ZPO)</p>
            <p style={{ marginBottom: 12 }}>? Defensive Taktik-Analyse, kein Rechtsbruch</p>
            <p style={{ marginBottom: 0 }}>? <strong>Endverantwortung liegt IMMER beim Anwalt</strong></p>
          </div>
          <button onClick={() => setShowDisclaimer(false)} style={{
            fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff',
            background: T.blue, border: 'none', borderRadius: 10,
            padding: '10px 24px', cursor: 'pointer', width: '100%',
          }}>
            Verstanden ? Strategischen Berater öffnen
          </button>
        </Panel>
      </div>
    );
  }
  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto', overflowY: 'auto', height: '100%' }}>
      {/* Input Section (collapsible) */}
      <div style={{ marginBottom: 20 }}>
        <button onClick={() => setShowInput(!showInput)} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 600, color: T.blue, background: T.blue + '10',
          border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer',
          display: 'flex', alignItems: 'center', gap: 8, width: '100%', justifyContent: 'space-between',
        }}>
          <span>? Gegner-Profil & Kontext eingeben {showInput ? '(ausblenden)' : '(Details öffnen für bessere Analyse)'}</span>          <span style={{ fontSize: 18 }}>{showInput ? '?' : '?'}</span>
        </button>
        {showInput && (
          <Panel style={{ marginTop: 12 }}>
            {/* Gegner Organisation */}
            <CollapsibleInput title="? Gegner-Organisation" desc="Name, Größe, Finanzlage, Branche" expanded={expandedSections['org']} onToggle={() => toggleSection('org')}>
              <InputRow label="Name" value={gegner.organisation.name} onChange={v => setGegner(g => ({ ...g, organisation: { ...g.organisation, name: v } }))} placeholder="z.B. ABC GmbH" />
              <InputRow label="Größe" value={gegner.organisation.groesse} onChange={v => setGegner(g => ({ ...g, organisation: { ...g.organisation, groesse: v } }))} placeholder="z.B. Mittelstand, 200 MA" />
              <InputRow label="Finanzlage" value={gegner.organisation.finanzlage} onChange={v => setGegner(g => ({ ...g, organisation: { ...g.organisation, finanzlage: v } }))} placeholder="z.B. Liquiditätsprobleme" />
              <InputRow label="Branche" value={gegner.organisation.branche} onChange={v => setGegner(g => ({ ...g, organisation: { ...g.organisation, branche: v } }))} placeholder="z.B. Pharma" />
            </CollapsibleInput>
            {/* Entscheider */}
            <CollapsibleInput title="? Entscheider (CEO/GF)" desc="Persönlichkeit, Schwächen, Karrierephase" expanded={expandedSections['ent']} onToggle={() => toggleSection('ent')}>
              <InputRow label="Name/Titel" value={gegner.entscheider.name} onChange={v => setGegner(g => ({ ...g, entscheider: { ...g.entscheider, name: v } }))} placeholder="z.B. Dr. Max Müller (CEO)" />
              <InputRow label="Alter" value={gegner.entscheider.alter} onChange={v => setGegner(g => ({ ...g, entscheider: { ...g.entscheider, alter: v } }))} placeholder="z.B. 58" />
              <InputRow label="Persönlichkeit" value={gegner.entscheider.persoenlichkeit} onChange={v => setGegner(g => ({ ...g, entscheider: { ...g.entscheider, persoenlichkeit: v } }))} placeholder="z.B. Dominant, risikoscheu" />
              <InputRow label="Karrierephase" value={gegner.entscheider.karriere_phase} onChange={v => setGegner(g => ({ ...g, entscheider: { ...g.entscheider, karriere_phase: v } }))} placeholder="z.B. Kurz vor Ruhestand" />
              <TextareaRow label="Schwächen" value={gegner.entscheider.schwaechen} onChange={v => setGegner(g => ({ ...g, entscheider: { ...g.entscheider, schwaechen: v } }))} placeholder="z.B. Angst vor Medienberichten, persönlich haftbar" />
            </CollapsibleInput>
            {/* Gegnerischer Anwalt */}
            <CollapsibleInput title="?? Anwalt Gegenseite" desc="Kanzlei, Stärken, Schwächen" expanded={expandedSections['anw']} onToggle={() => toggleSection('anw')}>
              <InputRow label="Kanzlei" value={gegner.anwalt_gegenseite.kanzlei} onChange={v => setGegner(g => ({ ...g, anwalt_gegenseite: { ...g.anwalt_gegenseite, kanzlei: v } }))} placeholder="z.B. Schmidt & Partner" />
              <InputRow label="Bekannt für" value={gegner.anwalt_gegenseite.bekannt_fuer} onChange={v => setGegner(g => ({ ...g, anwalt_gegenseite: { ...g.anwalt_gegenseite, bekannt_fuer: v } }))} placeholder="z.B. Aggressive Taktik" />
              <InputRow label="Schwächen" value={gegner.anwalt_gegenseite.schwaechen} onChange={v => setGegner(g => ({ ...g, anwalt_gegenseite: { ...g.anwalt_gegenseite, schwaechen: v } }))} placeholder="z.B. Überzieht oft, Richter genervt" />
            </CollapsibleInput>
            {/* Bisheriges Verhalten */}
            <CollapsibleInput title="? Bisheriges Verhalten" desc="Verhandlungsbereitschaft, Taktiken, Fehler" expanded={expandedSections['verh']} onToggle={() => toggleSection('verh')}>
              <InputRow label="Verhandlungsbereitschaft" value={gegner.bisheriges_verhalten.verhandlungsbereitschaft} onChange={v => setGegner(g => ({ ...g, bisheriges_verhalten: { ...g.bisheriges_verhalten, verhandlungsbereitschaft: v } }))} placeholder="z.B. Öffentlich: Null. Privat: Signale" />
              <InputRow label="Taktik" value={gegner.bisheriges_verhalten.taktik} onChange={v => setGegner(g => ({ ...g, bisheriges_verhalten: { ...g.bisheriges_verhalten, taktik: v } }))} placeholder="z.B. Verzögerung, viele Beweisanträge" />
              <TextareaRow label="Fehler" value={gegner.bisheriges_verhalten.fehler} onChange={v => setGegner(g => ({ ...g, bisheriges_verhalten: { ...g.bisheriges_verhalten, fehler: v } }))} placeholder="z.B. Widerspruch zwischen Schriftsätzen" />
            </CollapsibleInput>
            {/* Eigene Position */}
            <CollapsibleInput title="? Eigene Position" desc="Stärken, Schwächen, Verhandlungsziele" expanded={expandedSections['eig']} onToggle={() => toggleSection('eig')}>
              <TextareaRow label="Stärken" value={eigene.staerken} onChange={v => setEigene(e => ({ ...e, staerken: v }))} placeholder="z.B. Klare Beweislage, Zeit auf unserer Seite" />
              <TextareaRow label="Schwächen" value={eigene.schwaechen} onChange={v => setEigene(e => ({ ...e, schwaechen: v }))} placeholder="z.B. Mandant finanziell limitiert" />
              <InputRow label="Ziel maximal" value={eigene.ziel_maximal} onChange={v => setEigene(e => ({ ...e, ziel_maximal: v }))} placeholder="z.B. 500.000€ + Unterlassung" />
              <InputRow label="Ziel realistisch" value={eigene.ziel_realistisch} onChange={v => setEigene(e => ({ ...e, ziel_realistisch: v }))} placeholder="z.B. 300.000€" />
              <InputRow label="Ziel minimal" value={eigene.ziel_minimal} onChange={v => setEigene(e => ({ ...e, ziel_minimal: v }))} placeholder="z.B. 150.000€" />
              <InputRow label="Nicht verhandelbar" value={eigene.nicht_verhandelbar} onChange={v => setEigene(e => ({ ...e, nicht_verhandelbar: v }))} placeholder="z.B. Öffentliche Entschuldigung" />
            </CollapsibleInput>
            {/* Kontext */}
            <CollapsibleInput title="? Kontext & Externe Faktoren" desc="Öffentlichkeit, Zeitdruck, Fusionen" expanded={expandedSections['ctx']} onToggle={() => toggleSection('ctx')}>
              <InputRow label="Öffentlichkeit" value={kontext.oeffentlichkeit} onChange={v => setKontext(k => ({ ...k, oeffentlichkeit: v }))} placeholder="z.B. Medieninteresse vorhanden" />
              <InputRow label="Zeitdruck" value={kontext.zeitdruck} onChange={v => setKontext(k => ({ ...k, zeitdruck: v }))} placeholder="z.B. Fusion in 6 Monaten" />
              <TextareaRow label="Weitere Faktoren" value={kontext.externe_faktoren} onChange={v => setKontext(k => ({ ...k, externe_faktoren: v }))} placeholder="z.B. Hauptversammlung, Geschäftsjahr-Ende" />
            </CollapsibleInput>
          </Panel>
        )}
      </div>
      {/* Module Grid */}
      <SectionTitle icon="?">Analyse-Module</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 24 }}>
        {MODULES.map(m => {
          const hasResult = !!results[m.id];
          const isLoading = loading === m.id;
          return (
            <Panel key={m.id} onClick={() => !isLoading && runAnalysis(m.id)} style={{
              cursor: isLoading ? 'wait' : 'pointer',
              transition: 'opacity 0.2s',
              opacity: isLoading ? 0.7 : 1,
            }}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>{m.icon}</div>
              <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>{m.label}</div>
              <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.5, marginBottom: 10 }}>{m.desc}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                {hasResult && <Chip small color={T.green}>? Ergebnis</Chip>}
                {isLoading && <Chip small color={T.orange}>? Analysiert...</Chip>}
                {!hasResult && !isLoading && <Chip small color={T.blue}>Starten ?</Chip>}
              </div>
            </Panel>
          );
        })}
      </div>
      {/* Results */}
      {activeModule && results[activeModule] && (
        <div style={{ marginBottom: 24 }}>
          <SectionTitle icon={MODULES.find(m => m.id === activeModule)?.icon}>
            {MODULES.find(m => m.id === activeModule)?.label} ? Ergebnis
          </SectionTitle>
          <ResultRenderer moduleId={activeModule} result={results[activeModule]} />
        </div>
      )}
      {/* Show all completed results */}
      {Object.keys(results).filter(k => k !== activeModule).length > 0 && (
        <div>
          <SectionTitle icon="?">Weitere Ergebnisse</SectionTitle>
          {Object.entries(results).filter(([k]) => k !== activeModule).map(([moduleId, result]) => (
            <div key={moduleId} style={{ marginBottom: 16 }}>
              <button onClick={() => setActiveModule(moduleId as ModuleId)} style={{
                fontFamily: sans, fontSize: 14, fontWeight: 600, color: T.blue,
                background: T.blue + '10', border: 'none', borderRadius: 8,
                padding: '8px 16px', cursor: 'pointer', marginBottom: 8,
              }}>
                {MODULES.find(m => m.id === moduleId)?.icon} {MODULES.find(m => m.id === moduleId)?.label} anzeigen
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
// ??? Collapsible Input Section ???
function CollapsibleInput({ title, desc, expanded, onToggle, children }: {
  title: string; desc: string; expanded?: boolean; onToggle: () => void; children: React.ReactNode;
}) {
  return (
    <div style={{ marginBottom: 12, paddingBottom: 12 }}>
      <button onClick={onToggle} style={{
        fontFamily: sans, fontSize: 14, fontWeight: 600, color: T.text,
        background: 'none', border: 'none', padding: '4px 0', cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 8, width: '100%', textAlign: 'left',
      }}>
        <span>{title}</span>
        <span style={{ fontSize: 12, color: T.dim, fontWeight: 400, flex: 1 }}>? {desc}</span>
        <span style={{ fontSize: 14, color: T.dim }}>{expanded ? '?' : '?'}</span>
      </button>
      {expanded && <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 10, paddingLeft: 4 }}>{children}</div>}
    </div>
  );
}
// ??? Input Components ???
function InputRow({ label, value, onChange, placeholder }: { label: string; value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <label style={{ fontSize: 13, fontWeight: 500, color: T.dim, width: 140, flexShrink: 0 }}>{label}</label>
      <input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} style={{
        fontFamily: sans, fontSize: 14, color: T.text, background: T.bg,
        border: `1px solid ${T.border}`, borderRadius: 8, padding: '7px 12px',
        flex: 1, outline: 'none',
      }} />
    </div>
  );
}
function TextareaRow({ label, value, onChange, placeholder }: { label: string; value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
      <label style={{ fontSize: 13, fontWeight: 500, color: T.dim, width: 140, flexShrink: 0, paddingTop: 8 }}>{label}</label>
      <textarea value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} rows={3} style={{
        fontFamily: sans, fontSize: 14, color: T.text, background: T.bg,
        border: `1px solid ${T.border}`, borderRadius: 8, padding: '7px 12px',
        flex: 1, outline: 'none', resize: 'vertical',
      }} />
    </div>
  );
}
// ??? Result Renderers ???
function ResultRenderer({ moduleId, result }: { moduleId: string; result: any }) {
  if (result?.raw) {
    return <Panel><pre style={{ fontSize: 13, whiteSpace: 'pre-wrap', color: T.text, fontFamily: sans, lineHeight: 1.6 }}>{typeof result.raw === 'string' ? result.raw : JSON.stringify(result.raw, null, 2)}</pre></Panel>;
  }
  switch (moduleId) {
    case 'profiling': return <ProfilingResult data={result} />;
    case 'leverage': return <LeverageResult data={result} />;
    case 'tactics': return <TacticsResult data={result} />;
    case 'timing': return <TimingResult data={result} />;
    case 'infowar': return <InfowarResult data={result} />;
    case 'negotiation': return <NegotiationResult data={result} />;
    default: return <Panel><pre style={{ fontSize: 13 }}>{JSON.stringify(result, null, 2)}</pre></Panel>;
  }
}
function ProfilingResult({ data }: { data: any }) {
  const bf = data.big_five || {};
  const dt = data.dark_triad || {};
  const traits = [
    { label: 'Machtmotivation', v: bf.machtmotivation || 0 },
    { label: 'Risikobereitschaft', v: bf.risikobereitschaft || 0 },
    { label: 'Gesichtswahrung', v: bf.gesichtswahrung || 0 },
    { label: 'Verhandlungsstil (1=kooperativ, 10=kompetitiv)', v: bf.verhandlungsstil || 0 },
    { label: 'Emotionale Kontrolle', v: bf.emotionale_kontrolle || 0 },
    { label: 'Entscheidungsgeschwindigkeit', v: bf.entscheidungsgeschwindigkeit || 0 },
  ];
  const darkTraits = [
    { label: 'Narzissmus', v: dt.narzissmus || 0, col: T.purple },
    { label: 'Machiavellismus', v: dt.machiavellismus || 0, col: T.orange },
    { label: 'Psychopathie', v: dt.psychopathie || 0, col: T.red },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
      <Panel>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 14 }}>? Big Five Analyse</div>
        {traits.map(t => (
          <div key={t.label} style={{ marginBottom: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 4 }}>
              <span style={{ color: T.dim }}>{t.label}</span>
              <span style={{ fontWeight: 700 }}>{t.v}/10</span>
            </div>
            <Bar v={t.v} max={10} color={t.v >= 7 ? T.red : t.v >= 4 ? T.orange : T.green} h={6} />
          </div>
        ))}
      </Panel>
      <div>
        <Panel style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 14 }}>? Dark Triad</div>
          {darkTraits.map(t => (
            <div key={t.label} style={{ marginBottom: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 4 }}>
                <span style={{ color: T.dim }}>{t.label}</span>
                <span style={{ fontWeight: 700, color: t.col }}>{t.v}/10</span>
              </div>
              <Bar v={t.v} max={10} color={t.col} h={6} />
            </div>
          ))}
        </Panel>
        {data.trigger?.length > 0 && (
          <Panel>
            <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 10 }}>? Psychologische Trigger</div>
            {data.trigger.map((t: any, i: number) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                <Chip small color={t.intensitaet === 'hoch' ? T.red : t.intensitaet === 'mittel' ? T.orange : T.green}>{t.intensitaet}</Chip>
                <span style={{ fontSize: 13 }}><strong>{t.kategorie}:</strong> {t.beschreibung}</span>
              </div>
            ))}
          </Panel>
        )}
      </div>
      {data.empfohlener_ansatz && (
        <Panel style={{ gridColumn: '1/3',  }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 6 }}>? Empfohlener Ansatz: {data.empfohlener_ansatz}</div>          <div style={{ fontSize: 14, color: T.dim, lineHeight: 1.6 }}>{data.begruendung}</div>
        </Panel>
      )}
    </div>
  );
}
function LeverageResult({ data }: { data: any }) {
  const ethikColor = (e: string) => e === 'gruen' ? T.green : e === 'gelb' ? T.orange : T.red;
  const ethikLabel = (e: string) => e === 'gruen' ? '? Unbedenklich' : e === 'gelb' ? '?? Grauzone' : '? Verboten';
  return (
    <div>
      {data.druckmittel?.map((d: any, i: number) => (
        <Panel key={i} style={{ marginBottom: 12,  }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <div>
              <Chip small color={T.dim}>{d.kategorie}</Chip>
              <span style={{ fontSize: 16, fontWeight: 700, marginLeft: 10 }}>{d.hebel}</span>
            </div>
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip small color={ethikColor(d.ethik)}>{ethikLabel(d.ethik)}</Chip>
              <Chip small color={scol(d.staerke * 10)}>Stärke: {d.staerke}/10</Chip>
            </div>
          </div>
          <div style={{ fontSize: 14, marginBottom: 4 }}><strong>Wie nutzen:</strong> {d.wie_nutzen}</div>
          {d.wann_einsetzen && <div style={{ fontSize: 13, color: T.dim }}>? {d.wann_einsetzen}</div>}
          <div style={{ fontSize: 13, color: T.orange, marginTop: 4 }}>?? Risiko: {d.risiko}</div>
          {d.zitat && <div style={{ fontSize: 12, color: T.blue, fontStyle: 'italic', marginTop: 6 }}>"{d.zitat}"</div>}
        </Panel>
      ))}
      {data.empfohlene_reihenfolge?.length > 0 && (
        <Panel style={{ marginTop: 16 }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>? Empfohlene Sequenz</div>
          {data.empfohlene_reihenfolge.map((s: any) => (
            <div key={s.schritt} style={{ display: 'flex', gap: 12, marginBottom: 12, alignItems: 'flex-start' }}>
              <div style={{
                width: 28, height: 28, borderRadius: '50%', background: T.blue, color: '#fff',
                fontSize: 14, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>{s.schritt}</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{s.aktion}</div>
                <div style={{ fontSize: 13, color: T.dim }}>Ziel: {s.ziel}</div>
                {s.erwartete_reaktion && <div style={{ fontSize: 12, color: T.orange }}>? {s.erwartete_reaktion}</div>}
              </div>
            </div>
          ))}
        </Panel>
      )}
    </div>
  );
}
function TacticsResult({ data }: { data: any }) {
  return (
    <div>
      <div style={{ display: 'grid', gap: 12 }}>
        {data.strategien?.map((s: any, i: number) => (
          <Panel key={i} style={{  }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
              <div style={{ fontSize: 16, fontWeight: 700 }}>{s.name}</div>
              <div style={{ display: 'flex', gap: 6 }}>
                {s.empfohlen && <Chip small variant="filled" color={T.green}>? Empfohlen</Chip>}
                <Chip small color={scol(s.erfolgswahrscheinlichkeit)}>{s.erfolgswahrscheinlichkeit}% Erfolg</Chip>
              </div>
            </div>
            <div style={{ fontSize: 14, color: T.dim, marginBottom: 8 }}>{s.ansatz}</div>
            <div style={{ marginBottom: 8 }}>
              {s.taktiken?.map((t: string, j: number) => (
                <div key={j} style={{ fontSize: 13, marginBottom: 4, display: 'flex', gap: 6 }}>
                  <span style={{ color: T.blue }}>?</span> {t}
                </div>
              ))}
            </div>
            <div style={{ fontSize: 13, color: T.orange }}>?? Risiko: {s.risiko}</div>
            {s.zitat && <div style={{ fontSize: 12, color: T.blue, fontStyle: 'italic', marginTop: 6 }}>"{s.zitat}"</div>}
          </Panel>
        ))}
      </div>
      {data.empfehlung && (
        <Panel style={{ marginTop: 16,  }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 6 }}>? Empfehlung</div>
          <div style={{ fontSize: 14, marginBottom: 4 }}>{data.empfehlung}</div>
          <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.6 }}>{data.begruendung}</div>
        </Panel>
      )}
    </div>
  );
}
function TimingResult({ data }: { data: any }) {
  return (
    <div>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <div>
            <div style={{ fontSize: 13, color: T.dim, marginBottom: 4 }}>Aktuelles Momentum</div>
            <div style={{ fontSize: 18, fontWeight: 700 }}>{data.momentum}</div>
          </div>
          <div style={{ flex: 1 }}>
            <Bar v={data.momentum_score || 50} max={100} color={scol(data.momentum_score || 50)} h={10} />
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, color: scol(data.momentum_score || 50) }}>{data.momentum_score || 50}%</div>
        </div>
      </Panel>
      {data.kritische_zeitfenster?.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 10 }}>? Kritische Zeitfenster</div>
          {data.kritische_zeitfenster.map((z: any, i: number) => (
            <Panel key={i} style={{ marginBottom: 10,  }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: 700 }}>{z.zeitraum}</span>
                {z.druck_level && <Chip small color={z.druck_level === 'MAXIMUM' ? T.red : T.orange}>{z.druck_level}</Chip>}
              </div>
              <div style={{ fontSize: 13, color: T.dim, marginBottom: 4 }}>{z.ereignis}</div>
              <div style={{ fontSize: 14 }}>? {z.taktik}</div>
            </Panel>
          ))}
        </div>
      )}
      {data.naechster_schritt && (
        <Panel style={{ }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 8 }}>? Nächster optimaler Schritt</div>
          <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{data.naechster_schritt.aktion}</div>
          <div style={{ fontSize: 13, marginBottom: 4 }}>? Wann: {data.naechster_schritt.wann}</div>
          {data.naechster_schritt.wie && <div style={{ fontSize: 13, marginBottom: 4 }}>? Wie: {data.naechster_schritt.wie}</div>}
          <div style={{ fontSize: 13, color: T.dim }}>? Ziel: {data.naechster_schritt.ziel}</div>
        </Panel>
      )}
    </div>
  );
}
function InfowarResult({ data }: { data: any }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16 }}>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: T.green, marginBottom: 10 }}>? Sofort offenlegen</div>
        {data.sofort_offenlegen?.map((item: any, i: number) => (
          <Panel key={i} style={{ marginBottom: 10,  }}>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{item.was}</div>
            <div style={{ fontSize: 13, color: T.dim }}>{item.warum}</div>
            {item.wie_praesentieren && <div style={{ fontSize: 12, color: T.blue, marginTop: 4 }}>? {item.wie_praesentieren}</div>}
          </Panel>
        ))}
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: T.orange, marginBottom: 10 }}>? Verbergen bis Prozess</div>
        {data.verbergen?.map((item: any, i: number) => (
          <Panel key={i} style={{ marginBottom: 10,  }}>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{item.was}</div>
            <div style={{ fontSize: 13, color: T.dim }}>{item.warum}</div>
            {item.wann_offenlegen && <div style={{ fontSize: 12, color: T.blue, marginTop: 4 }}>? {item.wann_offenlegen}</div>}            {item.risiko && <div style={{ fontSize: 12, color: T.orange, marginTop: 2 }}>?? {item.risiko}</div>}
          </Panel>
        ))}
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: T.purple, marginBottom: 10 }}>? Als Bluff nutzen</div>
        {data.als_bluff?.map((item: any, i: number) => (
          <Panel key={i} style={{ marginBottom: 10,  }}>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{item.was}</div>
            <div style={{ fontSize: 13, fontStyle: 'italic', marginBottom: 4 }}>"{item.formulierung}"</div>
            <div style={{ fontSize: 13, color: T.dim }}>? {item.ziel}</div>
            {item.risiko && <div style={{ fontSize: 12, color: T.orange, marginTop: 2 }}>?? {item.risiko}</div>}
          </Panel>
        ))}
      </div>
      {data.empfehlung && (
        <Panel style={{ gridColumn: '1/4',  }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 6 }}>? Strategie-Empfehlung</div>
          <div style={{ fontSize: 14, lineHeight: 1.6 }}>{data.empfehlung}</div>
        </Panel>
      )}
    </div>
  );
}
function NegotiationResult({ data }: { data: any }) {
  const sections = [
    { key: 'vorbereitung', icon: '?', title: 'Vorbereitung', content: data.vorbereitung },
    { key: 'opening', icon: '?', title: 'Opening (Erste Minuten)', content: data.opening },
    { key: 'argumentation', icon: '??', title: 'Argumentation', content: data.argumentation },
    { key: 'closing', icon: '?', title: 'Closing', content: data.closing },
    { key: 'backup', icon: '?', title: 'Backup Plan', content: data.backup_plan },
  ];
  return (
    <div>
      {sections.filter(s => s.content).map(s => (
        <Panel key={s.key} style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
            {s.icon} {s.title}
          </div>
          <div style={{ fontSize: 14, lineHeight: 1.7, whiteSpace: 'pre-wrap', color: T.text }}>{s.content}</div>
        </Panel>
      ))}
      {data.einwandbehandlung?.length > 0 && (
        <Panel style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>? Einwandbehandlung</div>
          {data.einwandbehandlung.map((e: any, i: number) => (
            <div key={i} style={{ marginBottom: 16, paddingLeft: 14 }}>
              <div style={{ fontSize: 14, fontWeight: 600, color: T.red, marginBottom: 4 }}>Einwand: "{e.einwand}"</div>
              <div style={{ fontSize: 14, marginBottom: 4 }}>{e.antwort}</div>
              {e.technik && <Chip small color={T.blue}>{e.technik}</Chip>}
            </div>
          ))}
        </Panel>
      )}
      {data.psychologische_notizen?.length > 0 && (
        <Panel style={{ }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 10 }}>? Psychologische Notizen</div>
          {data.psychologische_notizen.map((n: string, i: number) => (
            <div key={i} style={{ fontSize: 13, marginBottom: 6, display: 'flex', gap: 6 }}>
              <span>?</span> {n}
            </div>
          ))}
        </Panel>
      )}
    </div>
  );
}
