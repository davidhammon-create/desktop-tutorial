import React, { useState } from 'react';
import {
  BusinessScenario, BusinessOption, totalCosts, expectedValue, argumentScore,
  breakEvenProbability, nettoRisiko, computeRPN, RiskItem,
} from '@/types/business';
import {
  riskAdjustedValue, downsideRisk, sharpeRatio, kellyKriterium,
  weightedScore, ComparisonWeights, DEFAULT_COMPARISON_WEIGHTS,
  recommendationStrength, qualitativeScore,
} from '@/types/businessFormulas';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label, Bar, BigRing } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
function fmt(n: number): string {
  return n.toLocaleString('de-DE', { maximumFractionDigits: 0 });
}
interface Milestone {
  id: string;
  label: string;
  geplant: string;
  tatsaechlich: string;
  status: 'done' | 'pending' | 'overdue';
}
export function RecommendationStep({ scenario, onUpdate }: Props) {
  const opts = scenario.options;
  const [milestones, setMilestones] = useState<Milestone[]>([
    { id: 'ms-1', label: 'Rechtliche Beratung einholen', geplant: 'Tag 7', tatsaechlich: '', status: 'pending' },
    { id: 'ms-2', label: 'Finanzabteilung einbinden', geplant: 'Tag 14', tatsaechlich: '', status: 'pending' },
    { id: 'ms-3', label: 'Erstkontakt Gegenpartei', geplant: 'Tag 21', tatsaechlich: '', status: 'pending' },
  ]);
  if (opts.length < 2) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: T.dim }}>
        <div style={{ fontSize: 15 }}>Mindestens 2 Optionen mit Daten nötig für eine Empfehlung</div>
      </div>
    );
  }
  const scored = opts.map(o => ({
    option: o,
    ev: expectedValue(o),
    rav: riskAdjustedValue(o),
    downside: downsideRisk(o),
    sharpe: sharpeRatio(o),
    kelly: kellyKriterium(o),
    breakEven: breakEvenProbability(o),
    argScore: argumentScore(o.arguments),
    qualiScore: qualitativeScore(o),
    netto: nettoRisiko(o),
    costs: totalCosts(o.costs),
    wScore: weightedScore(o, opts),
    criticalRPN: (o.riskItems || []).filter(i => computeRPN(i) >= 100).length,
  })).sort((a, b) => b.wScore - a.wScore);
  const best = scored[0];
  const bestIdx = opts.findIndex(o => o.id === best.option.id);
  const strength = recommendationStrength(best.wScore);
  const actionSteps: string[] = [];
  if (best.criticalRPN > 0) {
    actionSteps.push(`${best.criticalRPN} kritische Risiken (RPN > 100) zuerst mitigieren`);
  }
  if (best.option.deadlines?.length) {
    const urgentDl = best.option.deadlines.filter(dl => {
      const days = Math.ceil((new Date(dl.date).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      return days <= 30 && days >= 0;
    });
    if (urgentDl.length) {
      actionSteps.push(`${urgentDl.length} dringende Fristen innerhalb 30 Tagen beachten`);
    }
  }
  actionSteps.push(`Budget freigeben: ${fmt(best.costs)}€`);
  actionSteps.push(`Kelly-Empfehlung: Max. ${(best.kelly * 100).toFixed(0)}% des Rechtsbudgets einsetzen`);
  if (best.option.timeframe.earliestResult) {
    actionSteps.push(`Zeithorizont: ${best.option.timeframe.earliestResult}`);
  }
  actionSteps.push('Anwalt beauftragen und Strategie finalisieren');
  actionSteps.push('Monitoring-Plan aktivieren und Review-Termine setzen');
  const fallback = scored.length > 1 ? scored[1] : null;
  const addMilestone = () => {
    setMilestones([...milestones, {
      id: `ms-${Date.now()}`,
      label: '',
      geplant: '',
      tatsaechlich: '',
      status: 'pending',
    }]);
  };
  const updateMilestone = (idx: number, patch: Partial<Milestone>) => {
    const arr = [...milestones];
    arr[idx] = { ...arr[idx], ...patch };
    setMilestones(arr);
  };
  const removeMilestone = (idx: number) => {
    setMilestones(milestones.filter((_, i) => i !== idx));
  };
  return (
    <div style={{ padding: 24, maxWidth: 1000 }}>
      {/* Main Recommendation Card */}
      <Panel style={{ marginBottom: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          <BigRing score={Math.round(best.wScore * 100)} size={110} />
          <div style={{ flex: 1 }}>
            <div style={{
              fontSize: 11, fontWeight: 700, color: strength.color,
              textTransform: 'uppercase', letterSpacing: '0.06em',
              padding: '3px 10px', borderRadius: 6, background: strength.color + '15',
              display: 'inline-block', marginBottom: 6,
            }}>
              {strength.label}
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, marginTop: 4 }}>
              Option {String.fromCharCode(65 + bestIdx)}: {best.option.label}
            </div>
            <div style={{ fontSize: 14, color: T.dim, marginTop: 6, lineHeight: 1.5 }}>
              {best.option.description || 'Keine Beschreibung'}
            </div>
          </div>
        </div>
        {/* Key metrics */}
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))', gap: 16,
          marginTop: 20, paddingTop: 16, borderTop: `1px solid ${T.border}`,
        }}>
          {[
            { label: 'Erwartungswert', value: `${best.ev >= 0 ? '+' : ''}${fmt(best.ev)} €`, color: best.ev >= 0 ? T.green : T.red },
            { label: 'Risikoadj. Wert', value: `${best.rav >= 0 ? '+' : ''}${fmt(best.rav)} €`, color: best.rav >= 0 ? T.green : T.red },
            { label: 'Kosten', value: `${fmt(best.costs)} €`, color: T.text },
            { label: 'Dauer', value: `${best.option.timeframe.minMonths}?${best.option.timeframe.maxMonths} Mon.`, color: T.text },
            { label: 'Sharpe Ratio', value: best.sharpe.toFixed(2), color: best.sharpe >= 1 ? T.green : T.orange },
            { label: 'Gesamt-Score', value: best.wScore.toFixed(2), color: T.blue },
          ].map(({ label, value, color }) => (
            <div key={label}>
              <div style={{ fontSize: 11, color: T.dim }}>{label}</div>
              <div style={{ fontSize: 17, fontWeight: 700, color }}>{value}</div>
            </div>
          ))}
        </div>
      </Panel>
      {/* Ranking */}
      <Panel style={{ marginBottom: 24 }}>
        <Label>Ranking aller Optionen</Label>
        {scored.map((r, rank) => {
          const isBest = r.option.id === best.option.id;
          const rStrength = recommendationStrength(r.wScore);
          return (
            <div key={r.option.id} style={{
              display: 'flex', alignItems: 'center', gap: 14, padding: '14px 0',
              borderBottom: rank < scored.length - 1 ? `1px solid ${T.border}` : 'none',
            }}>
              <div style={{
                width: 30, height: 30, borderRadius: '50%',
                background: isBest ? T.green : T.muted,
                color: isBest ? '#fff' : T.dim,
                fontSize: 14, fontWeight: 700,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                {rank + 1}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 8 }}>
                  {String.fromCharCode(65 + opts.findIndex(o => o.id === r.option.id))}: {r.option.label}
                  <span style={{
                    fontSize: 10, fontWeight: 600, color: rStrength.color,
                    padding: '2px 8px', borderRadius: 6, background: rStrength.color + '15',
                  }}>{rStrength.label}</span>
                </div>
                <div style={{ fontSize: 12, color: T.dim, marginTop: 2 }}>
                  EW: {r.ev >= 0 ? '+' : ''}{fmt(r.ev)}€ ? Sharpe: {r.sharpe.toFixed(2)} ? Score: {r.wScore.toFixed(2)} ? {r.option.risk.erfolgswahrscheinlichkeit}% Erfolg
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 16, fontWeight: 700, color: r.ev >= 0 ? T.green : T.red }}>
                  {r.ev >= 0 ? '+' : ''}{fmt(r.ev)} €
                </div>
              </div>
            </div>
          );
        })}
      </Panel>
      {/* Handlungsplan */}
      <Panel style={{ marginBottom: 24 }}>
        <Label>Handlungsplan</Label>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
          {actionSteps.map((step, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px',
              borderRadius: 10, background: T.bg, fontSize: 13,
            }}>
              <div style={{
                width: 24, height: 24, borderRadius: '50%', background: T.blue,
                color: '#fff', fontSize: 11, fontWeight: 700, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{i + 1}</div>
              <div style={{ paddingTop: 2 }}>{step}</div>
            </div>
          ))}
        </div>
        {fallback && (
          <div style={{
            padding: 14, borderRadius: 10,
            background: T.orange + '06', marginBottom: 16,
          }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: T.orange, marginBottom: 4 }}>
              Plan B: Falls {best.option.label} scheitert
            </div>
            <div style={{ fontSize: 13, color: T.text }}>
              Wechsel zu Option {String.fromCharCode(65 + opts.findIndex(o => o.id === fallback.option.id))}: {fallback.option.label}
              (Score: {fallback.wScore.toFixed(2)}, EW: {fallback.ev >= 0 ? '+' : ''}{fmt(fallback.ev)}€)
            </div>
          </div>
        )}
      </Panel>
      {/* Monitoring */}
      <Panel style={{ marginBottom: 24 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <Label>Monitoring & Meilensteine</Label>
          <button onClick={addMilestone} style={{
            fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.blue,
            background: T.blue + '10', border: 'none', borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
          }}>+ Meilenstein</button>
        </div>
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>
          Tracken Sie den Fortschritt und passen Sie bei neuen Informationen die Analyse an.
        </div>
        {milestones.map((ms, i) => (
          <div key={ms.id} style={{
            display: 'grid', gridTemplateColumns: '1fr 100px 100px 90px 32px',
            gap: 8, alignItems: 'center', fontSize: 13, padding: '8px 0',
            borderBottom: i < milestones.length - 1 ? `1px solid ${T.border}` : 'none',
          }}>
            <input value={ms.label} onChange={e => updateMilestone(i, { label: e.target.value })}
              placeholder="Meilenstein..."
              style={{ fontFamily: sans, fontSize: 13, padding: '6px 10px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
            <input value={ms.geplant} onChange={e => updateMilestone(i, { geplant: e.target.value })}
              placeholder="Geplant"
              style={{ fontFamily: sans, fontSize: 12, padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'center' }} />
            <input value={ms.tatsaechlich} onChange={e => updateMilestone(i, { tatsaechlich: e.target.value })}
              placeholder="Tatsächl."
              style={{ fontFamily: sans, fontSize: 12, padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'center' }} />
            <select value={ms.status} onChange={e => updateMilestone(i, { status: e.target.value as Milestone['status'] })}
              style={{ fontFamily: sans, fontSize: 11, padding: '6px 4px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }}>
              <option value="pending">Offen</option>
              <option value="done">Erledigt</option>
              <option value="overdue">Überfällig</option>
            </select>
            <button onClick={() => removeMilestone(i)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: T.dim, fontSize: 14 }}>?</button>
          </div>
        ))}
      </Panel>
      {/* Notizen */}
      <Panel style={{ marginBottom: 24 }}>
        <Label>Notizen & Ergänzungen</Label>
        <textarea
          value={scenario.notes}
          onChange={e => onUpdate({ ...scenario, notes: e.target.value })}
          placeholder={"Besondere Hinweise, zusätzliche Erwägungen, Management-Vorgaben?"}
          rows={5}
          style={{
            fontFamily: sans, fontSize: 14, width: '100%', padding: '12px 14px',
            border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
            outline: 'none', color: T.text, resize: 'vertical', lineHeight: 1.6,
          }}
        />
      </Panel>
      {/* Mark as complete */}
      <div style={{ textAlign: 'center' }}>
        <button onClick={() => onUpdate({ ...scenario, status: 'Abgeschlossen', selectedOptionId: best.option.id })} style={{
          fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff',
          background: T.green, border: 'none', borderRadius: 12, padding: '12px 32px', cursor: 'pointer',
        }}>
          Analyse abschließen ? {best.option.label} empfehlen
        </button>
      </div>
    </div>
  );
}
