import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LexaraCase, LexaraArgument } from '@/types/lexara';
import { computeWinProbability } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Chip, ScoreRing } from './Primitives';
import { StrategyTab } from './StrategyTab';
import { InteractiveGraphTab } from './InteractiveGraphTab';
import { EvidenceTabEditable } from './EvidenceTabEditable';
import { PersonsTab } from './PersonsTab';
import { FristenTab } from './FristenTab';
import { KostenAnalyseTab } from './KostenAnalyseTab';
import { ArgumentFormDialog } from './ArgumentFormDialog';
import { CaseBasicsStep } from './CaseBasicsStep';
import { ArgumentsStep } from './ArgumentsStep';
import { StrategieberaterTab } from './StrategieberaterTab';
const STEPS = [
  { id: 'basics', nr: 1, label: 'Basisdaten', icon: '?', desc: 'Falldaten & Kernfrage' },
  { id: 'arguments', nr: 2, label: 'Argumente', icon: '??', desc: 'Eigene & gegnerische Argumente' },
  { id: 'evidence', nr: 3, label: 'Beweise', icon: '?', desc: 'Beweisstränge & Dokumente' },
  { id: 'graph', nr: 4, label: 'Verkettung', icon: '?', desc: 'Argument-Beweis-Ketten' },
  { id: 'persons', nr: 5, label: 'Personen', icon: '?', desc: 'Zeugen, Richter, Parteien' },
  { id: 'fristen', nr: 6, label: 'Fristen', icon: '?', desc: 'Termine & Fristen' },
  { id: 'strategy', nr: 7, label: 'Strategie', icon: '?', desc: 'Hebel & Taktiken' },
  { id: 'advisor', nr: 8, label: 'KI-Berater', icon: '?', desc: 'Taktische & psychologische Analyse' },
  { id: 'analyse', nr: 9, label: 'Analyse', icon: '?', desc: 'Prognose & Empfehlung' },
];
interface Props {
  c: LexaraCase;
  onBack: () => void;
  onUpdateCase: (updated: LexaraCase) => void;
}
export function CaseWorkflow({ c, onBack, onUpdateCase }: Props) {
  const [step, setStep] = useState(0);
  const navigate = useNavigate();
  const [editingArg, setEditingArg] = useState<LexaraArgument | null>(null);
  const [showArgDialog, setShowArgDialog] = useState(false);
  const { final } = computeWinProbability(c);
  const col = scol(final);
  const currentStep = STEPS[step];
  const handleSaveArg = (arg: LexaraArgument) => {
    const exists = c.arguments.find(a => a.id === arg.id);
    const updatedArgs = exists
      ? c.arguments.map(a => a.id === arg.id ? arg : a)
      : [...c.arguments, arg];
    const updatedEvidence = { ...c.evidence };
    if (!updatedEvidence[arg.id]) updatedEvidence[arg.id] = [];
    onUpdateCase({ ...c, arguments: updatedArgs, evidence: updatedEvidence });
    setShowArgDialog(false);
    setEditingArg(null);
  };
  const handleDeleteArg = (id: string) => {
    const updatedArgs = c.arguments.filter(a => a.id !== id);
    const updatedEdges = c.edges.filter(e => e.from !== id && e.to !== id);
    const updatedEvidence = { ...c.evidence };
    delete updatedEvidence[id];
    onUpdateCase({ ...c, arguments: updatedArgs, edges: updatedEdges, evidence: updatedEvidence });
  };
  const canGoNext = step < STEPS.length - 1;
  const canGoBack = step > 0;
  const renderContent = () => {
    switch (currentStep.id) {
      case 'basics':
        return <CaseBasicsStep c={c} onUpdateCase={onUpdateCase} />;
      case 'arguments':
        return (
          <ArgumentsStep
            c={c}
            onUpdateCase={onUpdateCase}
            onEditArg={(a) => { setEditingArg(a); setShowArgDialog(true); }}
            onAddArg={() => { setEditingArg(null); setShowArgDialog(true); }}
          />
        );
      case 'evidence':
        return <EvidenceTabEditable c={c} onUpdateCase={onUpdateCase} onEditArg={(a) => { setEditingArg(a); setShowArgDialog(true); }} />;
      case 'graph':
        return <InteractiveGraphTab c={c} onUpdateCase={onUpdateCase} />;
      case 'persons':
        return <PersonsTab c={c} onUpdateCase={onUpdateCase} />;
      case 'fristen':
        return <FristenTab c={c} onUpdateCase={onUpdateCase} />;
      case 'strategy':
        return <StrategyTab c={c} />;
      case 'advisor':
        return <StrategieberaterTab c={c} onUpdateCase={onUpdateCase} />;
      case 'analyse':
        return <KostenAnalyseTab c={c} onUpdateCase={onUpdateCase} />;
      default:
        return null;
    }
  };
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* ??? Top Bar ??? */}
      <div style={{
        background: T.surface, borderBottom: `1px solid ${T.border}`,
        padding: '10px 20px', flexShrink: 0,
        display: 'flex', alignItems: 'center', gap: 16,
      }}>
        <button onClick={() => navigate('/')} style={{
          fontFamily: sans, fontSize: 12, fontWeight: 500, color: T.dim,
          background: 'none', border: `1px solid ${T.border}`, borderRadius: 6,
          padding: '4px 10px', cursor: 'pointer',
        }}>?</button>
        <button onClick={onBack} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.blue,
          background: 'none', border: 'none', cursor: 'pointer', padding: 0,
        }}>
          ? Fälle
        </button>
        <div style={{ width: 1, height: 24, background: T.border }} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, color: T.dim }}>{c.number}</div>
          <div style={{ fontSize: 17, fontWeight: 700 }}>{c.name}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Chip small>{c.type}</Chip>
          <Chip small color={c.status === 'Aktiv' ? T.green : T.dim}>{c.status}</Chip>
        </div>
        <ScoreRing score={final} size={42} />
      </div>
      {/* ??? Step Navigation ??? */}
      <div style={{
        background: T.surface, borderBottom: `1px solid ${T.border}`,
        padding: '0 20px', overflowX: 'auto', flexShrink: 0,
      }}>
        <div style={{ display: 'flex', gap: 0, minWidth: 'max-content' }}>
          {STEPS.map((s, i) => {
            const isActive = i === step;
            const isPast = i < step;
            const isFuture = i > step;
            return (
              <button
                key={s.id}
                onClick={() => setStep(i)}
                style={{
                  fontFamily: sans, fontSize: 13, fontWeight: isActive ? 600 : 400,
                  color: isActive ? T.blue : isPast ? T.text : T.dim,
                  background: isActive ? T.blue + '08' : 'transparent',
                  border: 'none', borderBottom: isActive ? `2px solid ${T.blue}` : '2px solid transparent',
                  padding: '12px 16px', cursor: 'pointer',
                  display: 'flex', alignItems: 'center', gap: 6,
                  transition: 'all 0.15s', whiteSpace: 'nowrap',
                  opacity: isFuture ? 0.6 : 1,
                }}
              >
                <span style={{
                  width: 22, height: 22, borderRadius: '50%',
                  background: isPast ? T.green : isActive ? T.blue : T.muted,
                  color: isPast || isActive ? '#fff' : T.dim,
                  fontSize: 11, fontWeight: 700,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  {isPast ? '?' : s.nr}
                </span>
                {s.label}
              </button>
            );
          })}
        </div>
      </div>
      {/* ??? Step Header ??? */}
      <div style={{ padding: '16px 24px 0', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
              Schritt {currentStep.nr} von {STEPS.length}
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, marginTop: 2 }}>
              {currentStep.icon} {currentStep.label}
            </div>
            <div style={{ fontSize: 13, color: T.dim, marginTop: 2 }}>{currentStep.desc}</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {canGoBack && (
              <button onClick={() => setStep(step - 1)} style={{
                fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.dim,
                background: T.surface, border: `1px solid ${T.border}`,
                borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
              }}>
                ? Zurück
              </button>
            )}
            {canGoNext && (
              <button onClick={() => setStep(step + 1)} style={{
                fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff',
                background: T.blue, border: 'none',
                borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
              }}>
                Weiter ?
              </button>
            )}
          </div>
        </div>
      </div>
      {/* ??? Content ??? */}
      <div style={{ flex: 1, overflow: currentStep.id === 'graph' ? 'hidden' : 'auto', minHeight: 0, position: 'relative' }}>
        {renderContent()}
      </div>
      {/* ??? Bottom Nav ??? */}
      <div style={{
        background: T.surface, borderTop: `1px solid ${T.border}`,
        padding: '10px 24px', flexShrink: 0,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div style={{ fontSize: 12, color: T.dim }}>
          {c.arguments.length} Argumente ? {Object.values(c.evidence).flat().length} Beweise ? {c.persons.length} Personen ? {(c.fristen || []).length} Fristen
        </div>
        <div style={{ display: 'flex', gap: 4 }}>
          {STEPS.map((s, i) => (
            <div
              key={s.id}
              onClick={() => setStep(i)}
              style={{
                width: i === step ? 24 : 8, height: 8,
                borderRadius: 4, cursor: 'pointer',
                background: i === step ? T.blue : i < step ? T.green : T.muted,
                transition: 'all 0.2s',
              }}
            />
          ))}
        </div>
      </div>
      <ArgumentFormDialog
        isOpen={showArgDialog}
        initial={editingArg}
        onClose={() => { setShowArgDialog(false); setEditingArg(null); }}
        onSave={handleSaveArg}
        onDelete={handleDeleteArg}
      />
    </div>
  );
}
