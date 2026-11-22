import React, { useState } from 'react';
import { generateCaseReportPdf } from './CaseReportPdf';
import { LexaraCase, LexaraArgument } from '@/types/lexara';
import { computeWinProbability, getStrategieEmpfehlung, computeDecisionAnalysis } from '@/lib/lexaraUtils';
import { T, sans, scol } from './theme';
import { Chip } from './Primitives';
import { StrategyTab } from './StrategyTab';
import { InteractiveGraphTab } from './InteractiveGraphTab';
import { EvidenceTabEditable } from './EvidenceTabEditable';
import { PersonsTab } from './PersonsTab';
import { FristenTab } from './FristenTab';
import { KostenAnalyseTab } from './KostenAnalyseTab';
import { LitigationStrategyView } from './LitigationStrategyView';
import { ArgumentFormDialog } from './ArgumentFormDialog';
interface CaseDetailProps {
  c: LexaraCase;
  onBack: () => void;
  onUpdateCase: (updated: LexaraCase) => void;
}
export function CaseDetail({ c, onBack, onUpdateCase }: CaseDetailProps) {
  const [tab, setTab] = useState('strategy');
  const [editingArg, setEditingArg] = useState<LexaraArgument | null>(null);
  const [showArgDialog, setShowArgDialog] = useState(false);
  const { final } = computeWinProbability(c);
  const col = scol(final);
  const decision = computeDecisionAnalysis(c);
  const empfehlungIcon = decision.empfehlung === 'klage' ? '??' : decision.empfehlung === 'vergleich' ? '?' : '?';
  // Tabs organized logically per PDF: Strategy ? Graph ? Evidence ? Persons ? Deadlines ? Costs/Decision
  const tabs = [
    { id: 'strategy', label: 'Strategie', icon: '?' },
    { id: 'litigation', label: 'Strategie-Engine', icon: '?' },
    { id: 'graph', label: 'Prozeßgraph', icon: '?' },
    { id: 'evidence', label: 'Beweisstränge', icon: '?' },
    { id: 'persons', label: 'Personen', icon: '?' },
    { id: 'fristen', label: 'Fristen', icon: '?' },
    { id: 'analyse', label: 'Analyse', icon: empfehlungIcon },
  ];
  // Count pending deadlines
  const pendingFristen = (c.fristen || []).filter(f => f.status === 'offen').length;
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
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Header bar */}
      <div style={{ background: T.surface, borderBottom: `1px solid ${T.border}`, padding: '12px 24px', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 10 }}>
          <button onClick={onBack} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.textSecondary, background: 'none', border: 'none',
            cursor: 'pointer', padding: 0, display: 'flex', alignItems: 'center', gap: 4,
          }}>
            ? Zurück
          </button>
          <div style={{ flex: 1 }} />
          <button onClick={() => generateCaseReportPdf(c)} style={{
            fontFamily: sans, fontSize: 13, fontWeight: 500, color: '#fff', background: T.text,
            border: 'none', borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            PDF Export
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: T.text }}>{final}%</span>
            <span style={{ fontSize: 12, color: T.dim }}>Prognose</span>
          </div>
        </div>
        <div style={{ marginBottom: 10 }}>
          <div style={{ fontSize: 12, color: T.dim }}>{c.number}</div>
          <div style={{ fontSize: 22, fontWeight: 700, color: T.text }}>{c.name}</div>
          {c.kernfrage && <div style={{ fontSize: 13, color: T.textSecondary, marginTop: 4, fontStyle: 'italic' }}>?{c.kernfrage}"</div>}
          <div style={{ display: 'flex', gap: 6, marginTop: 6, flexWrap: 'wrap', alignItems: 'center' }}>
            <Chip small>{c.type}</Chip>
            <Chip small>{c.goal}</Chip>
            {c.instanz && <Chip small color={T.purple}>{c.instanz}</Chip>}
            <Chip small color={c.status === 'Aktiv' ? T.green : T.dim}>{c.status}</Chip>
            <Chip small color={T.dim}>{c.created}</Chip>
            {pendingFristen > 0 && <Chip small color={T.orange}>? {pendingFristen} Fristen</Chip>}
            <button onClick={() => { setEditingArg(null); setShowArgDialog(true); }} style={{
              fontFamily: sans, fontSize: 13, fontWeight: 500, color: T.text, background: 'rgba(0,0,0,0.04)',
              border: '1px solid rgba(0,0,0,0.08)', borderRadius: 8, padding: '4px 14px', cursor: 'pointer',
            }}>
              + Argument
            </button>
          </div>
        </div>
        {/* Tabs ? iOS segmented control style */}
        <div style={{
          display: 'inline-flex', background: T.bg, borderRadius: 10, padding: 3,
        }}>
          {tabs.map(t => (
            <button key={t.id} onClick={() => setTab(t.id)} style={{
              fontFamily: sans, fontSize: 14, fontWeight: tab === t.id ? 600 : 400,
              color: tab === t.id ? T.text : T.dim,
              background: tab === t.id ? T.surface : 'transparent',
              border: 'none', borderRadius: 8, padding: '8px 18px',
              cursor: 'pointer', transition: 'all 0.2s',
              boxShadow: tab === t.id ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
            }}>
              {t.icon} {t.label}
            </button>
          ))}
        </div>
      </div>
      {/* Content */}
      <div style={{ flex: 1, overflow: tab === 'graph' ? 'hidden' : 'auto' }}>
        {tab === 'strategy' && <StrategyTab c={c} onUpdateCase={onUpdateCase} />}
        {tab === 'litigation' && <LitigationStrategyView c={c} onUpdateCase={onUpdateCase} />}
        {tab === 'graph' && <InteractiveGraphTab c={c} onUpdateCase={onUpdateCase} />}
        {tab === 'evidence' && <EvidenceTabEditable c={c} onUpdateCase={onUpdateCase} onEditArg={(a) => { setEditingArg(a); setShowArgDialog(true); }} />}
        {tab === 'persons' && <PersonsTab c={c} onUpdateCase={onUpdateCase} />}
        {tab === 'fristen' && <FristenTab c={c} onUpdateCase={onUpdateCase} />}
        {tab === 'analyse' && <KostenAnalyseTab c={c} onUpdateCase={onUpdateCase} />}
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
