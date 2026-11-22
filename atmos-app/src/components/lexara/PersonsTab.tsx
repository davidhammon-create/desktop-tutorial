import React, { useMemo, useState } from 'react';
import { LexaraCase, LexaraPerson } from '@/types/lexara';
import { computeCredibility, computeMachiavelliRisk, computeDarkEmpathScore, classifyPersonality } from '@/lib/lexaraUtils';
import { T, sans, scol, roleBadge } from './theme';
import { Bar, Chip, Panel, SectionTitle, CheckboxItem } from './Primitives';
import { PersonComparisonView } from './PersonComparisonView';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
interface PersonsTabProps {
  c: LexaraCase;
  onUpdateCase?: (updated: LexaraCase) => void;
}
type PersonView = 'matrix' | 'analysis' | 'create' | 'edit' | 'compare';
const EMPTY_PERSON: Omit<LexaraPerson, 'id'> = {
  name: '',
  role: 'Zeuge',
  party: null,
  court: '',
  historicalCases: 0,
  historicalConsistency: 50,
  priorContradictions: 0,
  plaintiffWinRate: null,
  settleRate: null,
  avgDuration: null,
  conflictOfInterest: 0,
  hiddenMotive: 0,
  competenceLevel: 50,
  selfPreservation: 30,
  loyaltySignals: 50,
  fearFactor: 20,
  narcissism: 20,
  cognitiveEmpathy: 50,
  affectiveEmpathy: 50,
  manipulationSkill: 10,
  coldness: 10,
  legalLevers: [],
  psychLevers: [],
  questionModules: [],
  pastCaseNotes: '',
};
const DARK_TRIAD_TRAITS = [
  { key: 'narcissism', label: 'Narzissmus', desc: 'Selbstüberschätzung, Geltungsdrang, Überlegenheitsgefühl' },
  { key: 'manipulationSkill', label: 'Manipulationsfähigkeit', desc: 'Strategisches Kalkül, Täuschungstalent' },
  { key: 'coldness', label: 'Kaltblütigkeit', desc: 'Emotionale Kälte, fehlende Reue, skrupelloses Handeln' },
] as const;
const EMPATHY_TRAITS = [
  { key: 'cognitiveEmpathy', label: 'Kognitive Empathie', desc: 'Kann Emotionen anderer lesen & verstehen (HOCH = gefährlicher!)' },
  { key: 'affectiveEmpathy', label: 'Affektive Empathie', desc: 'Echtes Mitgefühl, emotionale Resonanz (NIEDRIG = Dark Empath)' },
] as const;
const TACTICAL_TRAITS = [
  { key: 'conflictOfInterest', label: 'Interessenkonflikt', desc: 'Befangenheit / Eigeninteresse' },
  { key: 'hiddenMotive', label: 'Verborgenes Motiv', desc: 'Verdeckte Agenda / versteckte Absicht' },
  { key: 'selfPreservation', label: 'Selbstschutz', desc: 'Wahrheit beugen, um sich selbst zu schützen' },
  { key: 'fearFactor', label: 'Angstfaktor', desc: 'Unter Druck manipulierbar / einschüchterbar' },
  { key: 'loyaltySignals', label: 'Loyalität', desc: 'Erkennbare Nähe zu einer Seite' },
] as const;
const RELIABILITY_TRAITS = [
  { key: 'competenceLevel', label: 'Kompetenzniveau', desc: 'Fachliche Eignung / Belastbarkeit' },
  { key: 'historicalConsistency', label: 'Konsistenz', desc: 'Beständigkeit früherer Aussagen' },
] as const;
const PSYCH_LEVER_OPTIONS = [
  { type: 'Geschwätzigkeit provozieren', example: 'Offene Fragen stellen, die zum Erzählen verleiten' },
  { type: 'Eitelkeit ausnutzen', example: 'Expertise loben und dann präzisieren lassen' },
  { type: 'Angst / Unsicherheit schüren', example: 'Konsequenzen und Verantwortung zuspitzen' },
  { type: 'Übertreibung provozieren', example: 'untertreiben, um Korrekturreflex auszulösen' },
  { type: 'Autoritätshörigkeit testen', example: 'Druck durch Hierarchie simulieren' },
  { type: 'Kontrollverlust herbeiführen', example: 'Tempo und Richtung der Befragung wechseln' },
];
const LEGAL_LEVER_OPTIONS = [
  { title: 'Befangenheitsangriff', desc: 'Eigeninteresse oder Nähe zur Partei herausarbeiten' },
  { title: 'Widerspruch zur Beweislage', desc: 'Aussage mit Dokumenten oder Protokollen konfrontieren' },
  { title: 'Glaubwürdigkeitsangriff', desc: 'Widersprüche und Motive systematisch offenlegen' },
  { title: 'Zeugnisverweigerungsrecht prüfen', desc: 'prozesstaktische Reichweite prüfen' },
  { title: 'Vereidigung thematisieren', desc: 'Druck über förmliche Vernehmung erhöhen' },
  { title: 'Protokollgenauigkeit erzwingen', desc: 'Formulierungen exakt festhalten lassen' },
];
function buildSelectionMap<T>(selectedItems: T[], allItems: T[], getKey: (item: T) => string) {
  const keys = new Set(selectedItems.map(getKey));
  return allItems.reduce<Record<number, boolean>>((acc, item, index) => {
    acc[index] = keys.has(getKey(item));
    return acc;
  }, {});
}
export function PersonsTab({ c, onUpdateCase }: PersonsTabProps) {
  const [selectedPersonId, setSelectedPersonId] = useState<string | null>(null);
  const [editingPersonId, setEditingPersonId] = useState<string | null>(null);
  const [view, setView] = useState<PersonView>('matrix');
  const [draftPerson, setDraftPerson] = useState<Omit<LexaraPerson, 'id'>>(EMPTY_PERSON);
  const [selectedPsychLevers, setSelectedPsychLevers] = useState<Record<number, boolean>>({});
  const [selectedLegalLevers, setSelectedLegalLevers] = useState<Record<number, boolean>>({});
  const selectedPerson = useMemo(
    () => c.persons.find((p) => p.id === selectedPersonId) || null,
    [c.persons, selectedPersonId],
  );
  const resetForm = () => {
    setDraftPerson(EMPTY_PERSON);
    setSelectedPsychLevers({});
    setSelectedLegalLevers({});
    setEditingPersonId(null);
  };
  const openCreate = () => {
    resetForm();
    setView('create');
  };
  const openEdit = (personId: string) => {
    const person = c.persons.find((p) => p.id === personId);
    if (!person) return;
    setEditingPersonId(person.id);
    setDraftPerson({ ...person });
    setSelectedPsychLevers(buildSelectionMap(person.psychLevers || [], PSYCH_LEVER_OPTIONS, (item) => item.type));
    setSelectedLegalLevers(buildSelectionMap(person.legalLevers || [], LEGAL_LEVER_OPTIONS, (item) => item.title));
    setSelectedPersonId(person.id);
    setView('edit');
  };
  const goBackToMatrix = () => {
    resetForm();
    setView('matrix');
  };
  const handleSavePerson = () => {
    if (!onUpdateCase || !draftPerson.name.trim()) return;
    const nextPerson: LexaraPerson = {
      ...draftPerson,
      id: editingPersonId || `p-${Date.now()}`,
      psychLevers: PSYCH_LEVER_OPTIONS.filter((_, index) => !!selectedPsychLevers[index]),
      legalLevers: LEGAL_LEVER_OPTIONS.filter((_, index) => !!selectedLegalLevers[index]),
    };
    const nextPersons = editingPersonId
      ? c.persons.map((person) => (person.id === editingPersonId ? nextPerson : person))
      : [...c.persons, nextPerson];
    onUpdateCase({ ...c, persons: nextPersons });
    setSelectedPersonId(nextPerson.id);
    resetForm();
    setView('matrix');
  };
  const handleDeletePerson = (personId: string) => {
    if (!onUpdateCase) return;
    onUpdateCase({ ...c, persons: c.persons.filter((person) => person.id !== personId) });
    if (selectedPersonId === personId) setSelectedPersonId(null);
    if (editingPersonId === personId) resetForm();
    if (view !== 'matrix') setView('matrix');
  };
  return (
    <div style={{ padding: 20, height: '100%', overflowY: 'auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, gap: 12 }}>
        <SectionTitle>
          {view === 'matrix' && 'Personen & Zeugen-Matrix'}
          {view === 'analysis' && `Analyse: ${selectedPerson?.name || ''}`}
          {view === 'create' && 'Neue Person hinzufügen'}
          {view === 'edit' && `Person bearbeiten: ${draftPerson.name || ''}`}
        </SectionTitle>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          {view === 'analysis' && selectedPerson && (
            <button
              onClick={() => openEdit(selectedPerson.id)}
              style={{
                fontFamily: sans,
                fontSize: 13,
                fontWeight: 500,
                color: T.text,
                background: T.surface,
                border: `1px solid ${T.border}`,
                borderRadius: 8,
                padding: '6px 14px',
                cursor: 'pointer',
              }}
            >
              Bearbeiten
            </button>
          )}
          {view !== 'matrix' && (
            <button
              onClick={goBackToMatrix}
              style={{
                fontFamily: sans,
                fontSize: 13,
                fontWeight: 500,
                color: T.textSecondary,
                background: 'none',
                border: `1px solid ${T.border}`,
                borderRadius: 8,
                padding: '6px 14px',
                cursor: 'pointer',
              }}
            >
              ? Zurück
            </button>
          )}
          {view === 'matrix' && c.persons.length >= 2 && (
            <button
              onClick={() => setView('compare')}
              style={{
                fontFamily: sans,
                fontSize: 13,
                fontWeight: 500,
                color: T.textSecondary,
                background: 'none',
                border: `1px solid ${T.border}`,
                borderRadius: 8,
                padding: '6px 14px',
                cursor: 'pointer',
              }}
            >
              Vergleichen
            </button>
          )}
          {view === 'matrix' && (
            <button
              onClick={openCreate}
              style={{
                fontFamily: sans,
                fontSize: 13,
                fontWeight: 600,
                color: '#fff',
                background: T.text,
                border: 'none',
                borderRadius: 8,
                padding: '6px 16px',
                cursor: 'pointer',
              }}
            >
              + Person hinzufügen
            </button>
          )}
        </div>
      </div>
      {view === 'matrix' && (
        <WitnessMatrix
          persons={c.persons}
          onSelect={(personId) => {
            setSelectedPersonId(personId);
            setView('analysis');
          }}
          onEdit={openEdit}
          onDelete={handleDeletePerson}
        />
      )}
      {(view === 'create' || view === 'edit') && (
        <PersonForm
          mode={view}
          person={draftPerson}
          onChange={setDraftPerson}
          selectedPsychLevers={selectedPsychLevers}
          onTogglePsych={(index) => setSelectedPsychLevers((prev) => ({ ...prev, [index]: !prev[index] }))}
          selectedLegalLevers={selectedLegalLevers}
          onToggleLegal={(index) => setSelectedLegalLevers((prev) => ({ ...prev, [index]: !prev[index] }))}
          onSave={handleSavePerson}
          onCancel={goBackToMatrix}
          onDelete={view === 'edit' && editingPersonId ? () => handleDeletePerson(editingPersonId) : undefined}
          caseData={c}
        />
      )}
      {view === 'analysis' && selectedPerson && <HypothesisAnalysis person={selectedPerson} caseData={c} />}
      {view === 'compare' && <PersonComparisonView persons={c.persons} onClose={goBackToMatrix} />}
    </div>
  );
}
function PersonForm({
  mode,
  person,
  onChange,
  selectedPsychLevers,
  onTogglePsych,
  selectedLegalLevers,
  onToggleLegal,
  onSave,
  onCancel,
  onDelete,
  caseData,
}: {
  mode: 'create' | 'edit';
  person: Omit<LexaraPerson, 'id'>;
  onChange: (person: Omit<LexaraPerson, 'id'>) => void;
  selectedPsychLevers: Record<number, boolean>;
  onTogglePsych: (index: number) => void;
  selectedLegalLevers: Record<number, boolean>;
  onToggleLegal: (index: number) => void;
  onSave: () => void;
  onCancel: () => void;
  onDelete?: () => void;
  caseData?: LexaraCase;
}) {
  const [aiLoading, setAiLoading] = useState(false);
  const setField = <K extends keyof Omit<LexaraPerson, 'id'>>(key: K, value: Omit<LexaraPerson, 'id'>[K]) => {
    onChange({ ...person, [key]: value });
  };
  const handleAiSuggest = async () => {
    if (!person.pastCaseNotes?.trim() && person.historicalCases === 0) {
      toast.info('Bitte tragen Sie zuerst Notizen oder frühere Auffälligkeiten ein.');
      return;
    }
    setAiLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke('profile-person', {
        body: {
          person,
          caseContext: caseData ? { type: caseData.type, goal: caseData.goal, instanz: caseData.instanz } : null,
        },
      });
      if (error) throw error;
      if (data?.error) throw new Error(data.error);
      const r = data.result;
      if (r) {
        onChange({
          ...person,
          narcissism: r.narcissism ?? person.narcissism,
          cognitiveEmpathy: r.cognitiveEmpathy ?? person.cognitiveEmpathy,
          affectiveEmpathy: r.affectiveEmpathy ?? person.affectiveEmpathy,
          manipulationSkill: r.manipulationSkill ?? person.manipulationSkill,
          coldness: r.coldness ?? person.coldness,
          conflictOfInterest: r.conflictOfInterest ?? person.conflictOfInterest,
          hiddenMotive: r.hiddenMotive ?? person.hiddenMotive,
          selfPreservation: r.selfPreservation ?? person.selfPreservation,
          fearFactor: r.fearFactor ?? person.fearFactor,
          loyaltySignals: r.loyaltySignals ?? person.loyaltySignals,
          competenceLevel: r.competenceLevel ?? person.competenceLevel,
          historicalConsistency: r.historicalConsistency ?? person.historicalConsistency,
        });
        if (r.reasoning) {
          toast.success(r.reasoning, { duration: 8000 });
        } else {
          toast.success('Profil-Vorschlag übernommen.');
        }
      }
    } catch (e: any) {
      toast.error(e.message || 'Fehler bei der Analyse.');
    } finally {
      setAiLoading(false);
    }
  };
  return (
    <div style={{ maxWidth: 900 }}>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 14 }}>Grunddaten</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Name *">
            <input
              value={person.name}
              onChange={(e) => setField('name', e.target.value)}
              placeholder="Name der Person"
              style={inputStyle}
            />
          </Field>
          <Field label="Rolle *">
            <select value={person.role} onChange={(e) => setField('role', e.target.value as LexaraPerson['role'])} style={inputStyle}>
              <option value="Zeuge">Zeuge</option>
              <option value="Richter">Richter</option>
              <option value="Anwalt">Anwalt</option>
            </select>
          </Field>
          <Field label="Partei">
            <input
              value={person.party || ''}
              onChange={(e) => setField('party', e.target.value || null)}
              placeholder="z. B. Kläger"
              style={inputStyle}
            />
          </Field>
          <Field label="Gericht / Bezug">
            <input
              value={person.court}
              onChange={(e) => setField('court', e.target.value)}
              placeholder="z. B. LG München I"
              style={inputStyle}
            />
          </Field>
        </div>
        {person.role === 'Richter' && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginTop: 12 }}>
            <Field label="Klägerquote %">
              <input type="number" min={0} max={100} value={person.plaintiffWinRate ?? ''} onChange={(e) => setField('plaintiffWinRate', e.target.value ? Number(e.target.value) : null)} style={inputStyle} />
            </Field>
            <Field label="Vergleichsquote %">
              <input type="number" min={0} max={100} value={person.settleRate ?? ''} onChange={(e) => setField('settleRate', e.target.value ? Number(e.target.value) : null)} style={inputStyle} />
            </Field>
            <Field label="? Dauer">
              <input value={person.avgDuration ?? ''} onChange={(e) => setField('avgDuration', e.target.value || null)} placeholder="z. B. 8 Monate" style={inputStyle} />
            </Field>
          </div>
        )}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 12 }}>
          <Field label="Bisherige Aussagen / Fälle">
            <input type="number" min={0} value={person.historicalCases} onChange={(e) => setField('historicalCases', Number(e.target.value))} style={inputStyle} />
          </Field>
          <Field label="Bekannte Widersprüche">
            <input type="number" min={0} value={person.priorContradictions} onChange={(e) => setField('priorContradictions', Number(e.target.value))} style={inputStyle} />
          </Field>
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>? Dunkle Triade</div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 14 }}>Narzissmus, Manipulation, Kaltblütigkeit ? Kernmerkmale toxischer Persönlichkeit</div>
        <div style={{ display: 'grid', gap: 14 }}>
          {DARK_TRIAD_TRAITS.map((trait) => {
            const value = person[trait.key];
            return (
              <div key={trait.key}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', marginBottom: 4 }}>
                  <div>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{trait.label}</span>
                    <span style={{ fontSize: 11, color: T.dim, marginLeft: 8 }}>{trait.desc}</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 700, color: scol(100 - (value as number)), minWidth: 30, textAlign: 'right' }}>{value}</span>
                </div>
                <input type="range" min={0} max={100} value={value as number} onChange={(e) => setField(trait.key, Number(e.target.value) as never)} style={{ width: '100%', accentColor: T.red }} />
              </div>
            );
          })}
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>? Empathie-Profil</div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 14 }}>
          <strong>Dark Empath</strong> = hohe kognitive Empathie + niedrige affektive Empathie + dunkle Triade. Gefährlicher als reiner Dark Triad, weil sie Emotionen lesen und gezielt ausnutzen.
        </div>
        <div style={{ display: 'grid', gap: 14 }}>
          {EMPATHY_TRAITS.map((trait) => {
            const value = person[trait.key];
            const isAffective = trait.key === 'affectiveEmpathy';
            const colorVal = isAffective ? (value as number) : (100 - (value as number));
            return (
              <div key={trait.key}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', marginBottom: 4 }}>
                  <div>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{trait.label}</span>
                    <span style={{ fontSize: 11, color: T.dim, marginLeft: 8 }}>{trait.desc}</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 700, color: scol(colorVal), minWidth: 30, textAlign: 'right' }}>{value}</span>
                </div>
                <input type="range" min={0} max={100} value={value as number} onChange={(e) => setField(trait.key, Number(e.target.value) as never)} style={{ width: '100%', accentColor: isAffective ? T.green : T.orange }} />
              </div>
            );
          })}
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>? Taktische Einschätzung</div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 14 }}>Wie schätzen wir diese Person im Verfahrenskontext ein?</div>
        <div style={{ display: 'grid', gap: 14 }}>
          {TACTICAL_TRAITS.map((trait) => {
            const value = person[trait.key];
            return (
              <div key={trait.key}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', marginBottom: 4 }}>
                  <div>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{trait.label}</span>
                    <span style={{ fontSize: 11, color: T.dim, marginLeft: 8 }}>{trait.desc}</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 700, color: scol(100 - (value as number)), minWidth: 30, textAlign: 'right' }}>{value}</span>
                </div>
                <input type="range" min={0} max={100} value={value as number} onChange={(e) => setField(trait.key, Number(e.target.value) as never)} style={{ width: '100%', accentColor: T.text }} />
              </div>
            );
          })}
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>? Kompetenz & Verlässlichkeit</div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 14 }}>Fachliche Eignung und Beständigkeit früherer Aussagen</div>
        <div style={{ display: 'grid', gap: 14 }}>
          {RELIABILITY_TRAITS.map((trait) => {
            const value = person[trait.key];
            return (
              <div key={trait.key}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', marginBottom: 4 }}>
                  <div>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{trait.label}</span>
                    <span style={{ fontSize: 11, color: T.dim, marginLeft: 8 }}>{trait.desc}</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 700, color: scol(value as number), minWidth: 30, textAlign: 'right' }}>{value}</span>
                </div>
                <input type="range" min={0} max={100} value={value as number} onChange={(e) => setField(trait.key, Number(e.target.value) as never)} style={{ width: '100%', accentColor: T.green }} />
              </div>
            );
          })}
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>Psychologische Hebel</div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>Anklicken, was bei dieser Person strategisch relevant ist</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
          {PSYCH_LEVER_OPTIONS.map((lever, index) => (
            <CheckboxItem key={lever.type} label={lever.type} checked={!!selectedPsychLevers[index]} onChange={() => onTogglePsych(index)} />
          ))}
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>Juristische Hebel</div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>Relevante Angriffspunkte und Taktiken auswählen</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
          {LEGAL_LEVER_OPTIONS.map((lever, index) => (
            <CheckboxItem key={lever.title} label={lever.title} checked={!!selectedLegalLevers[index]} onChange={() => onToggleLegal(index)} />
          ))}
        </div>
      </Panel>
      <Panel style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 8 }}>Notizen / frühere Auffälligkeiten</div>
        <textarea
          value={person.pastCaseNotes}
          onChange={(e) => setField('pastCaseNotes', e.target.value)}
          placeholder="Widersprüche, taktische Muster, frühere Aussagen ..."
          rows={4}
          style={{
            width: '100%',
            fontFamily: sans,
            fontSize: 14,
            padding: '10px 12px',
            border: `1px solid ${T.muted}`,
            borderRadius: 8,
            background: T.bg,
            outline: 'none',
            resize: 'vertical',
          }}
        />
      </Panel>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, marginBottom: 16 }}>
        <div />
        <button
          onClick={handleAiSuggest}
          disabled={aiLoading}
          title="Schlägt Werte basierend auf den Notizen vor"
          style={{
            fontFamily: sans,
            fontSize: 12,
            fontWeight: 500,
            color: aiLoading ? T.dim : T.textSecondary,
            background: 'none',
            border: `1px solid ${T.border}`,
            borderRadius: 8,
            padding: '5px 12px',
            cursor: aiLoading ? 'wait' : 'pointer',
            opacity: aiLoading ? 0.6 : 1,
          }}
        >
          {aiLoading ? '? Analysiert?' : '? Vorschlag'}
        </button>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
        <div>
          {onDelete && (
            <button
              onClick={onDelete}
              style={{
                fontFamily: sans,
                fontSize: 13,
                fontWeight: 500,
                color: T.red,
                background: 'transparent',
                border: `1px solid ${T.border}`,
                borderRadius: 8,
                padding: '8px 14px',
                cursor: 'pointer',
              }}
            >
              Person löschen
            </button>
          )}
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            onClick={onCancel}
            style={{
              fontFamily: sans,
              fontSize: 14,
              fontWeight: 500,
              color: T.dim,
              background: T.surface,
              border: `1px solid ${T.border}`,
              borderRadius: 8,
              padding: '8px 20px',
              cursor: 'pointer',
            }}
          >
            Abbrechen
          </button>
          <button
            onClick={onSave}
            disabled={!person.name.trim()}
            style={{
              fontFamily: sans,
              fontSize: 14,
              fontWeight: 600,
              color: '#fff',
              background: person.name.trim() ? T.text : T.muted,
              border: 'none',
              borderRadius: 8,
              padding: '8px 24px',
              cursor: person.name.trim() ? 'pointer' : 'not-allowed',
            }}
          >
            {mode === 'edit' ? 'Änderungen speichern' : 'Person speichern'}
          </button>
        </div>
      </div>
    </div>
  );
}
function WitnessMatrix({ persons, onSelect, onEdit, onDelete }: { persons: LexaraPerson[]; onSelect: (id: string) => void; onEdit: (id: string) => void; onDelete: (id: string) => void }) {
  if (persons.length === 0) {
    return (
      <Panel style={{ textAlign: 'center', padding: 40 }}>
        <div style={{ fontSize: 15, color: T.dim, marginBottom: 8 }}>Noch keine Personen angelegt</div>
        <div style={{ fontSize: 13, color: T.dim }}>Fügen Sie Zeugen, Richter oder Anwälte hinzu und pflegen Sie deren Eigenschaften direkt im Formular.</div>
      </Panel>
    );
  }
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: 16 }}>
      {persons.map((person) => {
        const credibility = computeCredibility(person);
        const machiavelliRisk = computeMachiavelliRisk(person);
        const darkEmpathScore = computeDarkEmpathScore(person);
        const personality = classifyPersonality(person);
        const classification = person.role === 'Richter'
          ? 'Richter'
          : person.conflictOfInterest > 70
            ? 'Feind'
            : person.conflictOfInterest > 40
              ? 'Bekannt'
              : 'Neutral';
        const badge = roleBadge(classification);
        return (
          <Panel
            key={person.id}
            style={{ cursor: 'pointer', transition: 'transform 0.15s, box-shadow 0.15s' }}
            onClick={() => onSelect(person.id)}
            onMouseEnter={(e) => {
              const element = e.currentTarget as HTMLElement;
              element.style.transform = 'translateY(-2px)';
              element.style.boxShadow = '0 4px 16px rgba(0,0,0,0.08)';
            }}
            onMouseLeave={(e) => {
              const element = e.currentTarget as HTMLElement;
              element.style.transform = '';
              element.style.boxShadow = '';
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12, marginBottom: 10 }}>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                <Chip small variant="filled" color={badge.color}>{badge.label}</Chip>
                <Chip small>{person.role}</Chip>
              </div>
              <div style={{ display: 'flex', gap: 6 }}>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onEdit(person.id);
                  }}
                  style={{ ...smallActionButtonStyle, color: T.text }}
                >
                  Bearbeiten
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onDelete(person.id);
                  }}
                  style={{ ...smallActionButtonStyle, color: T.red }}
                >
                  Löschen
                </button>
              </div>
            </div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>{person.name}</div>
            {person.court && <div style={{ fontSize: 12, color: T.dim, marginTop: 2 }}>{person.court}</div>}
            <div style={{ display: 'flex', gap: 16, fontSize: 12, marginTop: 10, marginBottom: 10, flexWrap: 'wrap' }}>
              <div><span style={{ fontWeight: 700 }}>{person.historicalCases}</span> <span style={{ color: T.dim }}>Aussagen</span></div>
              <div><span style={{ fontWeight: 700 }}>{person.priorContradictions}</span> <span style={{ color: T.dim }}>Widersprüche</span></div>
              <div><span style={{ fontWeight: 700, color: credibility !== null ? scol(credibility) : T.dim }}>{credibility !== null ? `${Math.round(credibility / 10)}/10` : '?'}</span> <span style={{ color: T.dim }}>Glaubw.</span></div>
            </div>
            {person.role !== 'Richter' && darkEmpathScore !== null && (
              <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: personality.color, background: `${personality.color}15`, padding: '2px 8px', borderRadius: 6 }}>{personality.label}</span>
                <span style={{ fontSize: 12, color: T.dim }}>Dark-Empath {darkEmpathScore}%</span>
              </div>
            )}
            {person.role !== 'Richter' && machiavelliRisk !== null && (
              <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 10 }}>
                <span style={{ fontSize: 12, color: machiavelliRisk > 60 ? T.red : machiavelliRisk > 30 ? T.orange : T.green, fontWeight: 600 }}>
                  {machiavelliRisk > 60 ? 'Hoch' : machiavelliRisk > 30 ? 'Mittel' : 'Niedrig'}
                </span>
                <span style={{ fontSize: 12, color: T.dim }}>Taktisches Risiko {machiavelliRisk}%</span>
              </div>
            )}
            {person.role === 'Richter' && (
              <div style={{ background: T.bg, borderRadius: 8, padding: 10, display: 'flex', gap: 14, flexWrap: 'wrap', fontSize: 12, marginBottom: 10 }}>
                <div><span style={{ fontWeight: 600 }}>{person.plaintiffWinRate ?? '?'}%</span> <span style={{ color: T.dim }}>Kläger</span></div>
                <div><span style={{ fontWeight: 600 }}>{person.settleRate ?? '?'}%</span> <span style={{ color: T.dim }}>Vergleiche</span></div>
                <div><span style={{ fontWeight: 600 }}>{person.avgDuration || '?'}</span> <span style={{ color: T.dim }}>Dauer</span></div>
              </div>
            )}
            {person.psychLevers?.length > 0 && (
              <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                {person.psychLevers.slice(0, 3).map((lever, index) => (
                  <Chip key={index} small>{lever.type}</Chip>
                ))}
                {person.psychLevers.length > 3 && <Chip small>+{person.psychLevers.length - 3}</Chip>}
              </div>
            )}
          </Panel>
        );
      })}
    </div>
  );
}
function HypothesisAnalysis({ person, caseData }: { person: LexaraPerson; caseData: LexaraCase }) {
  const darkEmpathScore = computeDarkEmpathScore(person);
  const personality = classifyPersonality(person);
  const credibility = computeCredibility(person);
  const machiavelliRisk = computeMachiavelliRisk(person);
  const [damageLevel, setDamageLevel] = useState<'low' | 'medium' | 'high'>('medium');
  const [integrityChecks, setIntegrityChecks] = useState<Record<string, boolean>>({});
  const [credibilityChecks, setCredibilityChecks] = useState<Record<string, boolean>>({});
  const [psychChecks, setPsychChecks] = useState<Record<string, boolean>>({});
  const toggle = (setter: React.Dispatch<React.SetStateAction<Record<string, boolean>>>, key: string) => {
    setter((prev) => ({ ...prev, [key]: !prev[key] }));
  };
  const damageColors = { low: T.green, medium: T.orange, high: T.red };
  const possibleStatement = person.role === 'Zeuge'
    ? person.pastCaseNotes.includes('widerspr')
      ? '"Die Lieferung war pünktlich und vollständig."'
      : '"Der Mangel war nicht vorhersehbar."'
    : null;
  const evidenceFor = caseData.evidence[caseData.arguments[0]?.id]?.[0];
  const evidenceAgainst = caseData.evidence[caseData.arguments.find((argument) => argument.side === 'opp')?.id || '']?.[0];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, maxWidth: 1100 }}>
      <div>
        {possibleStatement && (
          <Panel style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div style={{ fontSize: 16, fontWeight: 700 }}>Mögliche Aussage</div>
              <div style={{ display: 'inline-flex', background: T.bg, borderRadius: 8, padding: 2 }}>
                {(['low', 'medium', 'high'] as const).map((level) => (
                  <button
                    key={level}
                    onClick={() => setDamageLevel(level)}
                    style={{
                      fontSize: 12,
                      fontWeight: damageLevel === level ? 600 : 400,
                      color: damageLevel === level ? damageColors[level] : T.dim,
                      background: damageLevel === level ? `${damageColors[level]}15` : 'transparent',
                      border: 'none',
                      borderRadius: 6,
                      padding: '3px 10px',
                      cursor: 'pointer',
                    }}
                  >
                    {level === 'low' ? 'Gering' : level === 'medium' ? 'Mittel' : 'Hoch'}
                  </button>
                ))}
              </div>
            </div>
            <div style={{ background: T.bg, borderRadius: 8, padding: 14, marginBottom: 12 }}>
              <div style={{ fontSize: 14, fontStyle: 'italic', color: T.text, marginBottom: 8 }}>{possibleStatement}</div>
              {evidenceAgainst && <div style={{ fontSize: 12, color: T.red }}>Dagegen: {evidenceAgainst.name}</div>}
              {evidenceFor && <div style={{ fontSize: 12, color: T.green }}>Dafür: {evidenceFor.name}</div>}
            </div>
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>Integrität der Aussage</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
                {['Widerspruch zu Beweisen', 'Erinnerungslücke', 'Innere Widersprüchlichkeit', 'Kontextverschiebung'].map((item) => (
                  <CheckboxItem key={item} label={item} checked={!!integrityChecks[item]} onChange={() => toggle(setIntegrityChecks, item)} />
                ))}
              </div>
            </div>
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>Glaubwürdigkeit</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
                {['Interesse / Befangenheit', 'Kompetenzgrenze', 'Unzuverlässigkeit', 'Verborgenes Motiv'].map((item) => (
                  <CheckboxItem key={item} label={item} checked={!!credibilityChecks[item]} onChange={() => toggle(setCredibilityChecks, item)} />
                ))}
              </div>
            </div>
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>Psychologische Hebel</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
                {['Geschwätzigkeit provozieren', 'Eitelkeit ausnutzen', 'Angst schüren', 'Übertreibung provozieren'].map((item) => (
                  <CheckboxItem key={item} label={item} checked={!!psychChecks[item]} onChange={() => toggle(setPsychChecks, item)} />
                ))}
              </div>
            </div>
          </Panel>
        )}
      </div>
      <div>
        <Panel style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>Taktisches Arsenal</div>
          {(person.legalLevers || []).length > 0 && (
            <>
              <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8 }}>Juristische Hebel</div>
              {(person.legalLevers || []).map((lever, index) => (
                <div key={index} style={{ background: T.bg, borderRadius: 8, padding: 12, marginBottom: 8 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{lever.title}</div>
                  <div style={{ fontSize: 12, color: T.dim, marginTop: 2 }}>{lever.desc}</div>
                </div>
              ))}
            </>
          )}
          {(person.psychLevers || []).length > 0 && (
            <>
              <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginTop: 12, marginBottom: 8 }}>Psychologische Hebel</div>
              {(person.psychLevers || []).map((lever, index) => (
                <div key={index} style={{ background: T.bg, borderRadius: 8, padding: 12, marginBottom: 8 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{lever.type}</div>
                  <div style={{ fontSize: 12, color: T.dim, marginTop: 2 }}>{lever.example}</div>
                </div>
              ))}
            </>
          )}
        </Panel>
        {person.role !== 'Richter' && (
          <Panel style={{ marginBottom: 16 }}>
            <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>Psychologisches Profil</div>

            <div style={{ background: `${personality.color}10`, border: `1px solid ${personality.color}30`, borderRadius: 10, padding: 14, marginBottom: 16 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                <span style={{ fontSize: 15, fontWeight: 700, color: personality.color }}>{personality.label}</span>
                {darkEmpathScore !== null && <span style={{ fontSize: 12, color: T.dim }}>Score: {darkEmpathScore}%</span>}
              </div>
              <div style={{ fontSize: 12, color: T.textSecondary }}>{personality.desc}</div>
            </div>
            <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8 }}>Dunkle Triade</div>
            {[
              ['Narzissmus', person.narcissism || 0],
              ['Manipulationsfähigkeit', person.manipulationSkill || 0],
              ['Kaltblütigkeit', person.coldness || 0],
            ].map(([label, value]) => (
              <div key={label as string} style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                  <span style={{ fontSize: 12 }}>{label as string}</span>
                  <span style={{ fontSize: 12, fontWeight: 600, color: scol(100 - (value as number)) }}>{value as number}</span>
                </div>
                <Bar v={value as number} max={100} color={scol(100 - (value as number))} h={4} />
              </div>
            ))}
            <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginTop: 14, marginBottom: 8 }}>Empathie-Profil</div>
            {[
              ['Kognitive Empathie (lesen)', person.cognitiveEmpathy || 50, true],
              ['Affektive Empathie (fühlen)', person.affectiveEmpathy || 50, false],
            ].map(([label, value, isDanger]) => (
              <div key={label as string} style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                  <span style={{ fontSize: 12 }}>{label as string}</span>
                  <span style={{ fontSize: 12, fontWeight: 600, color: isDanger ? scol(100 - (value as number)) : scol(value as number) }}>{value as number}</span>
                </div>
                <Bar v={value as number} max={100} color={isDanger ? scol(100 - (value as number)) : scol(value as number)} h={4} />
              </div>
            ))}
            <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginTop: 14, marginBottom: 8 }}>Bewertungen</div>
            {[
              ['Glaubwürdigkeit', credibility ?? 50, false],
              ['Taktisches Risiko', machiavelliRisk ?? 0, true],
            ].map(([label, value, isDanger]) => (
              <div key={label as string} style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                  <span style={{ fontSize: 12 }}>{label as string}</span>
                  <span style={{ fontSize: 12, fontWeight: 600, color: isDanger ? scol(100 - (value as number)) : scol(value as number) }}>{value as number}%</span>
                </div>
                <Bar v={value as number} max={100} color={(isDanger as boolean) ? scol(100 - (value as number)) : scol(value as number)} h={4} />
              </div>
            ))}
          </Panel>
        )}
        <Panel>
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>Taktische Einschätzung</div>
          {[
            ['Historische Konsistenz', person.historicalConsistency],
            ['Kompetenzniveau', person.competenceLevel],
            ['Interessenkonflikt', 100 - person.conflictOfInterest],
            ['Verborgene Motive', 100 - person.hiddenMotive],
            ['Selbstschutz', 100 - person.selfPreservation],
            ['Angstfaktor', 100 - person.fearFactor],
          ].map(([label, value]) => (
            <div key={label as string} style={{ marginBottom: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 13 }}>{label as string}</span>
                <span style={{ fontSize: 13, fontWeight: 600, color: scol(value as number) }}>{value as number}</span>
              </div>
              <Bar v={value as number} max={100} color={scol(value as number)} h={4} />
            </div>
          ))}
        </Panel>
      </div>
    </div>
  );
}
function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label style={{ fontSize: 12, fontWeight: 600, color: T.dim, display: 'block', marginBottom: 4 }}>{label}</label>
      {children}
    </div>
  );
}
const inputStyle: React.CSSProperties = {
  width: '100%',
  fontFamily: sans,
  fontSize: 14,
  padding: '8px 12px',
  border: `1px solid ${T.muted}`,
  borderRadius: 8,
  background: T.bg,
  outline: 'none',
};
const smallActionButtonStyle: React.CSSProperties = {
  fontFamily: sans,
  fontSize: 11,
  fontWeight: 500,
  background: 'none',
  border: `1px solid ${T.border}`,
  borderRadius: 6,
  padding: '4px 8px',
  cursor: 'pointer',
};
