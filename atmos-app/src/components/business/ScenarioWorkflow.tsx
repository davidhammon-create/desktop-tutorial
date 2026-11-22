import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { BusinessScenario } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { ProblemStep } from './ProblemStep';
import { OptionsStep } from './OptionsStep';
import { DetailAnalysisStep } from './DetailAnalysisStep';
import { ScenarioComparisonStep } from './ScenarioComparisonStep';
import { ArgumentWeightingStep } from './ArgumentWeightingStep';
import { RiskDashboardStep } from './RiskDashboardStep';
import { DeadlineStep } from './DeadlineStep';
import { RecommendationStep } from './RecommendationStep';
import { AIContractAnalyzer } from './AIContractAnalyzer';
import { ClauseAnalysisView } from './ClauseAnalysisView';
import { BusinessLitigationView } from './BusinessLitigationView';
import { generateBusinessReportPdf, exportScenarioJson } from './BusinessReportPdf';
import { OutcomeFeedbackStep } from './OutcomeFeedbackStep';
import { toast } from 'sonner';
const STEPS = [
  { id: 'problem', nr: 1, label: 'Situation', desc: 'Problem beschreiben' },
  { id: 'ai-analyze', nr: 2, label: 'Dokumente', desc: 'Verträge & Dokumente analysieren' },
  { id: 'clause-analysis', nr: 3, label: 'Klauseln', desc: 'Klauselweise Vertragsanalyse' },
  { id: 'options', nr: 4, label: 'Optionen', desc: 'Handlungsoptionen' },
  { id: 'details', nr: 5, label: 'Kosten', desc: 'Kosten & Zeitrahmen' },
  { id: 'compare', nr: 6, label: 'Vergleich', desc: 'Szenarien vergleichen' },
  { id: 'arguments', nr: 7, label: 'Argumente', desc: 'Pro & Contra' },
  { id: 'risk', nr: 8, label: 'Risiko', desc: 'Risikoanalyse' },
  { id: 'litigation', nr: 9, label: 'Prozess', desc: 'Litigation-Strategie' },
  { id: 'deadlines', nr: 10, label: 'Fristen', desc: 'Termine' },
  { id: 'recommend', nr: 11, label: 'Empfehlung', desc: 'Entscheidung' },
  { id: 'feedback', nr: 12, label: 'Ergebnis', desc: 'Outcome bewerten' },
];
interface Props {
  scenario: BusinessScenario;
  onBack: () => void;
  onUpdate: (s: BusinessScenario) => void;
}
export function ScenarioWorkflow({ scenario, onBack, onUpdate }: Props) {
  const [step, setStep] = useState(0);
  const navigate = useNavigate();
  const currentStep = STEPS[step];
  const renderContent = () => {
    switch (currentStep.id) {
      case 'problem': return <ProblemStep scenario={scenario} onUpdate={onUpdate} />;
      case 'ai-analyze': return <AIContractAnalyzer scenario={scenario} onUpdate={onUpdate} />;
      case 'clause-analysis': return <ClauseAnalysisView scenario={scenario} onUpdate={onUpdate} />;
      case 'options': return <OptionsStep scenario={scenario} onUpdate={onUpdate} />;
      case 'details': return <DetailAnalysisStep scenario={scenario} onUpdate={onUpdate} />;
      case 'compare': return <ScenarioComparisonStep scenario={scenario} />;
      case 'arguments': return <ArgumentWeightingStep scenario={scenario} onUpdate={onUpdate} />;
      case 'risk': return <RiskDashboardStep scenario={scenario} onUpdate={onUpdate} />;
      case 'litigation': return <BusinessLitigationView scenario={scenario} onUpdate={onUpdate} />;
      case 'deadlines': return <DeadlineStep scenario={scenario} onUpdate={onUpdate} />;
      case 'recommend': return <RecommendationStep scenario={scenario} onUpdate={onUpdate} />;
      case 'feedback': return <OutcomeFeedbackStep scenario={scenario} onUpdate={onUpdate} />;
      default: return null;
    }
  };
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Top Bar ? ultra clean */}
      <div style={{
        background: 'rgba(255,255,255,0.8)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: `1px solid ${T.border}`,
        padding: '0 32px', height: 52, flexShrink: 0,
        display: 'flex', alignItems: 'center', gap: 16,
        position: 'sticky', top: 0, zIndex: 10,
      }}>
        <button onClick={() => navigate('/')} style={{
          fontFamily: sans, fontSize: 13, color: T.dim,
          background: 'none', border: 'none', cursor: 'pointer', padding: 0,
        }}>Home</button>
        <span style={{ color: T.muted }}>?</span>
        <button onClick={onBack} style={{
          fontFamily: sans, fontSize: 13, fontWeight: 500, color: T.text,
          background: 'none', border: 'none', cursor: 'pointer', padding: 0,
        }}>? Übersicht</button>
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 15, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
           {scenario.title || 'Neues Szenario'}
        </div>
        <div style={{ flex: 1 }} />
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <span style={{
            fontSize: 11, fontWeight: 600, color: statusColor(scenario.status),
            textTransform: 'uppercase', letterSpacing: '0.05em',
          }}>{scenario.status}</span>
          <button onClick={() => { generateBusinessReportPdf(scenario); toast.success('PDF exportiert'); }} style={{
            fontFamily: sans, fontSize: 12, color: T.dim,
            background: T.bg, border: 'none', borderRadius: 8,
            padding: '6px 12px', cursor: 'pointer',
          }}>PDF</button>
          <button onClick={() => { exportScenarioJson(scenario); toast.success('JSON exportiert'); }} style={{
            fontFamily: sans, fontSize: 12, color: T.dim,
            background: T.bg, border: 'none', borderRadius: 8,
            padding: '6px 12px', cursor: 'pointer',
          }}>JSON</button>
        </div>
      </div>
      {/* Step Pills ? Apple segmented control style */}
      <div style={{
        background: T.surface, borderBottom: `1px solid ${T.border}`,
        padding: '8px 32px', overflowX: 'auto', flexShrink: 0,
      }}>
        <div style={{ display: 'flex', gap: 4, minWidth: 'max-content' }}>
          {STEPS.map((s, i) => {
            const isActive = i === step;
            const isPast = i < step;
            return (
              <button key={s.id} onClick={() => setStep(i)} style={{
                fontFamily: sans, fontSize: 13, fontWeight: isActive ? 600 : 400,
                color: isActive ? T.text : isPast ? T.dim : T.muted,
                background: isActive ? T.bg : 'transparent',
                border: 'none',
                borderRadius: 8,
                padding: '8px 14px', cursor: 'pointer',
                transition: 'all 0.15s',
                whiteSpace: 'nowrap',
              }}>
                {s.label}
              </button>
            );
          })}
        </div>
      </div>
      {/* Step Header */}
      <div style={{ padding: '28px 40px 0', flexShrink: 0, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.01em' }}>{currentStep.label}</div>
          <div style={{ fontSize: 14, color: T.dim, marginTop: 4 }}>{currentStep.desc}</div>
        </div>
        <div style={{ display: 'flex', gap: 8, paddingBottom: 4 }}>
          {step > 0 && (
            <button onClick={() => setStep(step - 1)} style={{
              fontFamily: sans, fontSize: 13, color: T.dim,
              background: T.surface, border: 'none',
              borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
            }}>Zurück</button>
          )}
          {step < STEPS.length - 1 && (
            <button onClick={() => setStep(step + 1)} style={{
              fontFamily: sans, fontSize: 13, fontWeight: 600, color: '#fff',
              background: T.text, border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
            }}>Weiter</button>
          )}
        </div>
      </div>
      {/* Content */}
      <div style={{ flex: 1, overflow: 'auto' }}>{renderContent()}</div>
      {/* Minimal footer progress */}
      <div style={{
        padding: '10px 40px', flexShrink: 0,
        display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6,
      }}>
        {STEPS.map((s, i) => (
          <div key={s.id} onClick={() => setStep(i)} style={{
            width: i === step ? 24 : 6, height: 6, borderRadius: 3, cursor: 'pointer',
            background: i === step ? T.text : i < step ? T.dim : T.muted,
            transition: 'all 0.25s',
          }} />
        ))}
      </div>
    </div>
  );
}
const statusColor = (s: string) =>
  s === 'Abgeschlossen' ? T.green : s === 'In Analyse' ? T.orange : T.dim;
