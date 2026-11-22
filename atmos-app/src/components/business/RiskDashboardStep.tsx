import React, { useState } from 'react';
import {
  BusinessScenario, BusinessOption, RiskItem, RiskMitigation,
  totalCosts, expectedValue, computeRPN, bruttoRisiko, nettoRisiko,
  totalMitigationReduction, totalMitigationCost, valueAtRisk, riskAmpel,
  breakEvenProbability, roiMitigation, sensitivityEV, monteCarloSimulation,
  MonteCarloResult,
} from '@/types/business';
import {
  riskAdjustedValue, downsideRisk, sharpeRatio, kellyKriterium,
  tornadoAnalysis, TornadoItem,
} from '@/types/businessFormulas';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label, Bar } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
const RPN_CRITICAL = 100;
const ampelEmoji = (a: 'green' | 'yellow' | 'red') =>
  a === 'green' ? '?' : a === 'yellow' ? '?' : '?';
const ampelLabel = (a: 'green' | 'yellow' | 'red') =>
  a === 'green' ? 'Empfehlenswert' : a === 'yellow' ? 'Akzeptabel' : 'Kritisch';
function fmt(n: number): string {
  return n.toLocaleString('de-DE', { maximumFractionDigits: 0 });
}
function fmtDec(n: number, digits: number = 2): string {
  return n.toLocaleString('de-DE', { minimumFractionDigits: digits, maximumFractionDigits: digits });
}
// ??? Mode Toggle ???
function ModeToggle({ mode, onChange }: { mode: 'auto' | 'expert'; onChange: (m: 'auto' | 'expert') => void }) {
  return (
    <div style={{
      display: 'inline-flex', background: T.muted, borderRadius: 10, padding: 3,
    }}>
      {(['auto', 'expert'] as const).map(m => (
        <button key={m} onClick={() => onChange(m)} style={{
          fontFamily: sans, fontSize: 12, fontWeight: mode === m ? 600 : 400,
          color: mode === m ? '#fff' : T.dim,
          background: mode === m ? T.blue : 'transparent',
          border: 'none', borderRadius: 8, padding: '6px 16px', cursor: 'pointer',
          transition: 'all 0.2s',
        }}>
          {m === 'auto' ? 'Autopilot' : 'Experten-Modus'}
        </button>
      ))}
    </div>
  );
}
// ??? Collapsible Section ???
function Section({ title, defaultOpen = false, children, badge }: {
  title: string; defaultOpen?: boolean; children: React.ReactNode; badge?: string;
}) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <Panel style={{ marginBottom: 16 }}>
      <button onClick={() => setOpen(!open)} style={{
        fontFamily: sans, fontSize: 13, fontWeight: 600, color: T.dim,
        textTransform: 'uppercase', letterSpacing: '0.03em',
        background: 'none', border: 'none', cursor: 'pointer', padding: 0,
        display: 'flex', alignItems: 'center', gap: 8, width: '100%',
      }}>
        <span style={{ flex: 1, textAlign: 'left' }}>{title}</span>
        {badge && (
          <span style={{
            fontSize: 10, fontWeight: 700, color: '#fff', background: T.blue,
            borderRadius: 10, padding: '2px 8px',
          }}>{badge}</span>
        )}
        <span style={{ fontSize: 12, transition: 'transform 0.2s', transform: open ? 'rotate(180deg)' : 'rotate(0deg)' }}>?</span>
      </button>
      {open && <div style={{ marginTop: 16 }}>{children}</div>}
    </Panel>
  );
}
// ??? Formula display ???
function FormulaBlock({ title, formula, calculation, result, resultColor, info }: {
  title: string; formula: string; calculation: string; result: string; resultColor?: string; info?: string;
}) {
  return (
    <div style={{
      fontSize: 12, color: T.dim, fontFamily: "'SF Mono', 'DM Mono', 'Menlo', monospace",
      lineHeight: 1.8, background: T.bg, padding: 14, borderRadius: 10, marginBottom: 12,
    }}>
      <div style={{ fontSize: 11, fontWeight: 600, color: T.text, marginBottom: 4, fontFamily: sans }}>{title}</div>
      <div style={{ opacity: 0.7 }}>{formula}</div>
      <div style={{ marginTop: 6, color: T.text }}>{calculation}</div>
      <div style={{ marginTop: 4, fontWeight: 700, color: resultColor || T.blue, fontSize: 15 }}>
        = {result}
      </div>
      {info && <div style={{ marginTop: 6, fontSize: 11, color: T.dim, fontFamily: sans, fontStyle: 'italic' }}>{info}</div>}
    </div>
  );
}
// ??? Sub-components ???
function RiskItemRow({ item, onChange, onRemove }: {
  item: RiskItem; onChange: (i: RiskItem) => void; onRemove: () => void;
}) {
  const rpn = computeRPN(item);
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1fr 60px 60px 60px 60px 32px',
      gap: 6, alignItems: 'center', fontSize: 13, padding: '6px 0',
      borderBottom: `1px solid ${T.border}`,
    }}>
      <input value={item.label} onChange={e => onChange({ ...item, label: e.target.value })}
        placeholder="Risiko-Bezeichnung"
        style={{ fontFamily: sans, fontSize: 13, padding: '4px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
      <input type="number" min={1} max={10} value={item.auftretenswahrscheinlichkeit}
        onChange={e => onChange({ ...item, auftretenswahrscheinlichkeit: Math.min(10, Math.max(1, Number(e.target.value) || 1)) })}
        style={{ fontFamily: sans, fontSize: 13, padding: '4px 6px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'center' }} />
      <input type="number" min={1} max={10} value={item.bedeutung}
        onChange={e => onChange({ ...item, bedeutung: Math.min(10, Math.max(1, Number(e.target.value) || 1)) })}
        style={{ fontFamily: sans, fontSize: 13, padding: '4px 6px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'center' }} />
      <input type="number" min={1} max={10} value={item.entdeckungswahrscheinlichkeit}
        onChange={e => onChange({ ...item, entdeckungswahrscheinlichkeit: Math.min(10, Math.max(1, Number(e.target.value) || 1)) })}
        style={{ fontFamily: sans, fontSize: 13, padding: '4px 6px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'center' }} />
      <div style={{ fontWeight: 700, textAlign: 'center', color: rpn >= RPN_CRITICAL ? T.red : T.text }}>
        {rpn}
      </div>
      <button onClick={onRemove} style={{ background: 'none', border: 'none', cursor: 'pointer', color: T.dim, fontSize: 14 }}>?</button>
    </div>
  );
}
function MitigationRow({ m, onChange, onRemove }: {
  m: RiskMitigation; onChange: (m: RiskMitigation) => void; onRemove: () => void;
}) {
  const roi = roiMitigation(m);
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1fr 100px 100px 70px 50px 32px',
      gap: 6, alignItems: 'center', fontSize: 13, padding: '6px 0',
      borderBottom: `1px solid ${T.border}`,
    }}>
      <input value={m.label} onChange={e => onChange({ ...m, label: e.target.value })}
        placeholder="Maßnahme"
        style={{ fontFamily: sans, fontSize: 13, padding: '4px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
      <input type="number" value={m.risikoreduktion || ''} onChange={e => onChange({ ...m, risikoreduktion: Number(e.target.value) || 0 })}
        placeholder="€" style={{ fontFamily: sans, fontSize: 13, padding: '4px 6px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'right' }} />
      <input type="number" value={m.kosten || ''} onChange={e => onChange({ ...m, kosten: Number(e.target.value) || 0 })}
        placeholder="€" style={{ fontFamily: sans, fontSize: 13, padding: '4px 6px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none', textAlign: 'right' }} />
      <div style={{ textAlign: 'center', fontSize: 12, fontWeight: 600, color: roi >= 1 ? T.green : T.red }}>
        {roi === Infinity ? '?' : roi.toFixed(1)}:1
      </div>
      <div style={{ textAlign: 'center', fontSize: 16 }}>{roi >= 1 ? 'Ja' : 'Nein'}</div>
      <button onClick={onRemove} style={{ background: 'none', border: 'none', cursor: 'pointer', color: T.dim, fontSize: 14 }}>?</button>
    </div>
  );
}
export function RiskDashboardStep({ scenario, onUpdate }: Props) {
  const [activeIdx, setActiveIdx] = useState(0);
  const [mcResult, setMcResult] = useState<MonteCarloResult | null>(null);
  const [mcRuns, setMcRuns] = useState(1000);
  const [mode, setMode] = useState<'auto' | 'expert'>('auto');
  const [diskontRate, setDiskontRate] = useState(5); // percent
  const [risikofreierZins, setRisikofreierZins] = useState(3); // percent
  const opts = scenario.options;
  if (!opts.length) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: T.dim }}>
        <div style={{ fontSize: 15 }}>Bitte fügen Sie zuerst Optionen hinzu</div>
      </div>
    );
  }
  const opt = opts[activeIdx] || opts[0];
  const updateOption = (id: string, patch: Partial<BusinessOption>) => {
    onUpdate({
      ...scenario,
      options: scenario.options.map(o => o.id === id ? { ...o, ...patch } : o),
    });
  };
  const addRiskItem = () => {
    const item: RiskItem = {
      id: `ri-${Date.now()}`,
      label: '',
      auftretenswahrscheinlichkeit: 5,
      bedeutung: 5,
      entdeckungswahrscheinlichkeit: 5,
    };
    updateOption(opt.id, { riskItems: [...(opt.riskItems || []), item] });
  };
  const addMitigation = () => {
    const m: RiskMitigation = {
      id: `mit-${Date.now()}`,
      label: '',
      risikoreduktion: 0,
      kosten: 0,
    };
    updateOption(opt.id, { mitigations: [...(opt.mitigations || []), m] });
  };
  const riskItems = opt.riskItems || [];
  const mitigations = opt.mitigations || [];
  const ev = expectedValue(opt);
  const rav = riskAdjustedValue(opt, diskontRate / 100);
  const dRisk = downsideRisk(opt);
  const brutto = bruttoRisiko(opt);
  const netto = nettoRisiko(opt);
  const var_ = valueAtRisk(opt);
  const ampel = riskAmpel(opt);
  const criticalRPN = riskItems.filter(i => computeRPN(i) >= RPN_CRITICAL).length;
  const beP = breakEvenProbability(opt);
  const sharpe = sharpeRatio(opt, risikofreierZins / 100);
  const kelly = kellyKriterium(opt);
  const tornado = tornadoAnalysis(opt);
  const costs = totalCosts(opt.costs);
  const sensData = sensitivityEV(opt, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);
  const sensMaxAbs = Math.max(...sensData.map(d => Math.abs(d.ev)), 1);
  const runMonteCarlo = () => {
    setMcResult(monteCarloSimulation(opt, mcRuns));
  };
  const isExpert = mode === 'expert';
  return (
    <div style={{ padding: 24, maxWidth: 1100 }}>
      {/* Header: Mode toggle + Option tabs */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16, flexWrap: 'wrap', gap: 10 }}>
        <ModeToggle mode={mode} onChange={setMode} />
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div style={{ fontSize: 11, color: T.dim }}>
            Diskont:
            <input type="number" value={diskontRate} onChange={e => setDiskontRate(Number(e.target.value) || 5)}
              style={{ width: 42, fontFamily: sans, fontSize: 12, padding: '2px 4px', border: `1px solid ${T.border}`, borderRadius: 4, background: T.bg, color: T.text, outline: 'none', textAlign: 'center', marginLeft: 4 }} />%
          </div>
          <div style={{ fontSize: 11, color: T.dim }}>
            Rf-Zins:
            <input type="number" value={risikofreierZins} onChange={e => setRisikofreierZins(Number(e.target.value) || 3)}
              style={{ width: 42, fontFamily: sans, fontSize: 12, padding: '2px 4px', border: `1px solid ${T.border}`, borderRadius: 4, background: T.bg, color: T.text, outline: 'none', textAlign: 'center', marginLeft: 4 }} />%
          </div>
        </div>
      </div>
      {/* Option tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, overflowX: 'auto' }}>
        {opts.map((o, i) => (
          <button key={o.id} onClick={() => { setActiveIdx(i); setMcResult(null); }} style={{
            fontFamily: sans, fontSize: 13, fontWeight: i === activeIdx ? 600 : 400,
            color: i === activeIdx ? '#fff' : T.text,
            background: i === activeIdx ? T.blue : T.surface,
            border: `1px solid ${i === activeIdx ? T.blue : T.border}`,
            borderRadius: 10, padding: '8px 16px', cursor: 'pointer', whiteSpace: 'nowrap',
          }}>
            {String.fromCharCode(65 + i)}: {o.label}
          </button>
        ))}
      </div>
      {/* ??? Summary Dashboard ??? */}
      <Panel style={{
        marginBottom: 20,
        background: T.surface,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
          <span style={{ fontSize: 24, color: ampel === 'green' ? T.green : ampel === 'yellow' ? T.orange : T.red }}>{ampelEmoji(ampel)}</span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 18, fontWeight: 700 }}>{opt.label}</div>
            <div style={{ fontSize: 13, color: T.dim }}>{ampelLabel(ampel)}</div>
          </div>
          <div style={{
            fontSize: 11, fontWeight: 600, color: '#fff', padding: '4px 12px', borderRadius: 8,
            background: ampel === 'green' ? T.green : ampel === 'yellow' ? T.orange : T.red,
          }}>
            {mode === 'auto' ? 'Autopilot' : 'Experte'}
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: 12 }}>
          {[
            { label: 'Erwartungswert', value: `${ev >= 0 ? '+' : ''}${fmt(ev)} €`, color: ev >= 0 ? T.green : T.red },
            { label: 'Risikoadj. Wert', value: `${rav >= 0 ? '+' : ''}${fmt(rav)} €`, color: rav >= 0 ? T.green : T.red },
            { label: 'Downside Risk', value: `${fmt(dRisk)} €`, color: T.red },
            { label: 'Break-Even', value: `${beP.toFixed(0)}%`, color: T.blue },
            { label: 'Sharpe Ratio', value: fmtDec(sharpe), color: sharpe >= 1 ? T.green : sharpe >= 0.5 ? T.orange : T.red },
            { label: 'Kelly-Anteil', value: `${(kelly * 100).toFixed(0)}%`, color: T.purple },
            { label: 'Kritische RPNs', value: `${criticalRPN}`, color: criticalRPN > 0 ? T.red : T.green },
          ].map(({ label, value, color }) => (
            <div key={label}>
              <div style={{ fontSize: 11, color: T.dim }}>{label}</div>
              <div style={{ fontSize: 17, fontWeight: 700, color }}>{value}</div>
            </div>
          ))}
        </div>
      </Panel>
      {/* ??? Formel 1: EV ??? */}
      <Section title="Formel 1: Erwartungswert (EV)" defaultOpen={true} badge="Kernformel">
        <FormulaBlock
          title="Expected Value"
          formula="EV = P(Erfolg) ? Gewinn + P(Misserfolg) ? Verlust ? Kosten"
          calculation={`= ${(opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)} ? ${fmt(opt.risk.bestCase)}€ + ${(1 - opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)} ? ${fmt(opt.risk.worstCase)}€ ? ${fmt(costs)}€`}
          result={`${ev >= 0 ? '+' : ''}${fmt(ev)} €`}
          resultColor={ev >= 0 ? T.green : T.red}
          info={ev >= 0 ? 'Positive Rendite erwartet' : 'Negative Rendite erwartet ? Vorsicht!'}
        />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginTop: 8 }}>
          <div>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>P(Erfolg) %</div>
            <input type="number" min={0} max={100} value={opt.risk.erfolgswahrscheinlichkeit}
              onChange={e => updateOption(opt.id, { risk: { ...opt.risk, erfolgswahrscheinlichkeit: Number(e.target.value) || 0 } })}
              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
          </div>
          <div>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Best Case €</div>
            <input type="number" value={opt.risk.bestCase}
              onChange={e => updateOption(opt.id, { risk: { ...opt.risk, bestCase: Number(e.target.value) || 0 } })}
              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
          </div>
          <div>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Worst Case €</div>
            <input type="number" value={opt.risk.worstCase}
              onChange={e => updateOption(opt.id, { risk: { ...opt.risk, worstCase: Number(e.target.value) || 0 } })}
              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 8 }}>
          <div>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Likely Case €</div>
            <input type="number" value={opt.risk.likelyCase}
              onChange={e => updateOption(opt.id, { risk: { ...opt.risk, likelyCase: Number(e.target.value) || 0 } })}
              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
          </div>
          <div>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Gesamtkosten €</div>
            <input type="number" value={costs} disabled
              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.muted, color: T.dim, outline: 'none' }} />
            <div style={{ fontSize: 10, color: T.dim, marginTop: 2 }}>Aus Schritt 4 (Details)</div>
          </div>
        </div>
      </Section>
      {/* ??? Formel 2: RAV ??? */}
      <Section title="Formel 2: Risikoadjustierter Wert (RAV)" badge="Zeitwert">
        <FormulaBlock
          title="Risk-Adjusted Value"
          formula={`RAV = EV / (1 + r)^t    [r = ${diskontRate}%, t = ${(opt.timeframe.maxMonths / 12).toFixed(1)} Jahre]`}
          calculation={`= ${fmt(ev)}€ / (1 + ${(diskontRate / 100).toFixed(2)})^${(opt.timeframe.maxMonths / 12).toFixed(1)}`}
          result={`${rav >= 0 ? '+' : ''}${fmt(rav)} €`}
          resultColor={rav >= 0 ? T.green : T.red}
          info={`Zeitwert-Verlust: ${fmt(ev - rav)}€ durch ${opt.timeframe.maxMonths} Monate Wartezeit`}
        />
        <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Diskontrate (%)</div>
            <input type="range" min={0} max={20} value={diskontRate} onChange={e => setDiskontRate(Number(e.target.value))}
              style={{ width: '100%', accentColor: T.blue }} />
            <div style={{ fontSize: 12, color: T.text, textAlign: 'center' }}>{diskontRate}% p.a.</div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Max. Monate</div>
            <input type="number" min={1} value={opt.timeframe.maxMonths}
              onChange={e => updateOption(opt.id, { timeframe: { ...opt.timeframe, maxMonths: Number(e.target.value) || 1 } })}              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '6px 8px', border: `1px solid ${T.border}`, borderRadius: 6, background: T.bg, color: T.text, outline: 'none' }} />
          </div>
        </div>
      </Section>
      {/* ??? Formel 3: Downside Risk ??? */}
      <Section title="Formel 3: Downside Risk" badge="Verlustrisiko">
        <FormulaBlock
          title="Maximales Verlustrisiko"
          formula="Risk = ? (P_negativ ? Verlust_negativ) + Kosten"
          calculation={`= ${(1 - opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)} ? ${fmt(Math.abs(opt.risk.worstCase))}€ + ${fmt(costs)}€`}
          result={`${fmt(dRisk)} €`}
          resultColor={T.red}
          info="Maximaler Verlust im schlechtesten Fall inkl. aller Kosten"
        />
        <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
          <div style={{ flex: 1, background: T.bg, borderRadius: 10, padding: 12, textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: T.dim }}>VaR 95%</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: T.orange }}>max. {fmt(var_.var95)} €</div>
          </div>
          <div style={{ flex: 1, background: T.bg, borderRadius: 10, padding: 12, textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: T.dim }}>VaR 99%</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: T.red }}>max. {fmt(var_.var99)} €</div>
          </div>
        </div>
      </Section>
      {/* ??? Formel 4: RPN ??? */}
      <Section title="Formel 4: Risikoprioritätszahl (RPN)" defaultOpen={true} badge="FMEA">
        <FormulaBlock
          title="RPN = A ? B ? E"
          formula="A = Auftreten (1-10) ? B = Bedeutung (1-10) ? E = Entdeckung (1-10)"
          calculation={`Kritisch ab RPN > ${RPN_CRITICAL}`}
          result={`${criticalRPN} kritische Risiken`}
          resultColor={criticalRPN > 0 ? T.red : T.green}
        />
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 8 }}>
          <button onClick={addRiskItem} style={{
            fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.blue,
            background: T.blue + '10', border: 'none', borderRadius: 8, padding: '6px 12px', cursor: 'pointer',
          }}>+ Risiko</button>
        </div>
        {riskItems.length > 0 && (
          <>
            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 60px 60px 60px 60px 32px',
              gap: 6, fontSize: 10, fontWeight: 600, color: T.dim, padding: '4px 0',
              textTransform: 'uppercase', letterSpacing: '0.04em',
            }}>
              <span>Risiko</span><span style={{ textAlign: 'center' }}>A</span>
              <span style={{ textAlign: 'center' }}>B</span><span style={{ textAlign: 'center' }}>E</span>
              <span style={{ textAlign: 'center' }}>RPN</span><span></span>
            </div>
            {riskItems.map((item, i) => (
              <RiskItemRow key={item.id} item={item}
                onChange={updated => {
                  const arr = [...riskItems]; arr[i] = updated;
                  updateOption(opt.id, { riskItems: arr });
                }}
                onRemove={() => {
                  updateOption(opt.id, { riskItems: riskItems.filter((_, j) => j !== i) });
                }}
              />
            ))}
          </>
        )}
        {riskItems.length === 0 && (
          <div style={{ fontSize: 13, color: T.dim, textAlign: 'center', padding: 16 }}>
            Noch keine Risiken eingetragen. Klicken Sie ?+ Risiko".
          </div>
        )}
      </Section>
      {/* ??? Formel 5: VaR + Monte Carlo ??? */}
      <Section title="Formel 5: Value at Risk & Monte-Carlo" badge="Simulation">
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>
          {mcRuns.toLocaleString('de-DE')} Szenarien mit Dreiecksverteilung (Best/Worst/Likely) und variierender Erfolgswahrscheinlichkeit.
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 16 }}>
          <button onClick={runMonteCarlo} style={{
            fontFamily: sans, fontSize: 13, fontWeight: 600, color: '#fff',
            background: T.blue, border: 'none', borderRadius: 10, padding: '10px 20px',
            cursor: 'pointer',
          }}>
            ? {mcRuns.toLocaleString('de-DE')} Szenarien simulieren
          </button>
          {isExpert && (
            <select value={mcRuns} onChange={e => setMcRuns(Number(e.target.value))} style={{
              fontFamily: sans, fontSize: 12, padding: '8px 12px', border: `1px solid ${T.border}`,
              borderRadius: 8, background: T.bg, color: T.text, outline: 'none',
            }}>
              <option value={1000}>1.000 Runs</option>
              <option value={5000}>5.000 Runs</option>
              <option value={10000}>10.000 Runs</option>
              <option value={50000}>50.000 Runs</option>
              <option value={100000}>100.000 Runs</option>
            </select>
          )}
        </div>
        {mcResult && (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 16 }}>
              {[
                { label: 'Mittelwert', val: mcResult.mean, col: T.blue },
                { label: 'Median', val: mcResult.median, col: T.text },
                { label: '5%-Perzentil', val: mcResult.p5, col: T.red },
                { label: '95%-Perzentil', val: mcResult.p95, col: T.green },
              ].map(({ label, val, col }) => (
                <div key={label} style={{ background: T.bg, borderRadius: 10, padding: 12, textAlign: 'center' }}>
                  <div style={{ fontSize: 11, color: T.dim }}>{label}</div>
                  <div style={{ fontSize: 16, fontWeight: 700, color: col }}>{val >= 0 ? '+' : ''}{fmt(val)} €</div>
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11, fontWeight: 600, color: T.dim, marginBottom: 8 }}>Ergebnisverteilung</div>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height: 100 }}>
              {mcResult.histogram.map((bin, i) => {
                const maxCount = Math.max(...mcResult.histogram.map(b => b.count), 1);
                const h = (bin.count / maxCount) * 100;
                const midVal = (bin.binStart + bin.binEnd) / 2;
                return (
                  <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                    <div style={{ fontSize: 9, color: T.dim }}>{bin.count}</div>
                    <div style={{
                      width: '100%', height: `${h}%`, minHeight: 2,
                      background: midVal >= 0 ? T.green : T.red,
                      borderRadius: '4px 4px 0 0', transition: 'height 0.3s',
                    }} />
                  </div>
                );
              })}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 9, color: T.dim, marginTop: 4 }}>
              <span>{fmt(mcResult.min)}€</span>
              <span>{fmt(mcResult.max)}€</span>
            </div>
          </>
        )}
      </Section>
      {/* ??? Formel 6: Sharpe Ratio ??? */}
      <Section title="Formel 6: Sharpe Ratio" badge="Rendite/Risiko">
        <FormulaBlock
          title="Sharpe = (EV ? risikofreier Gewinn) / Standardabweichung"
          formula={`Risikofreier Zins: ${risikofreierZins}% ? Risikofreier Gewinn: ${fmt(risikofreierZins / 100 * costs)}€`}
          calculation={`= (${fmt(ev)} ? ${fmt(risikofreierZins / 100 * costs)}) / Stdabw.`}
          result={fmtDec(sharpe)}
          resultColor={sharpe >= 1 ? T.green : sharpe >= 0.5 ? T.orange : T.red}
          info={sharpe >= 2 ? 'Sehr gut ? hohe Rendite pro Risikoeinheit' : sharpe >= 1 ? 'Gut ? akzeptable Rendite pro Risiko' : sharpe >= 0.5 ? 'Mittelmäßig' : 'Schlecht ? zu viel Risiko für die erwartete Rendite'}
        />
        <div style={{ marginTop: 8 }}>
          <div style={{ fontSize: 11, color: T.dim, marginBottom: 4 }}>Risikofreier Zins anpassen (%)</div>
          <input type="range" min={0} max={10} step={0.5} value={risikofreierZins} onChange={e => setRisikofreierZins(Number(e.target.value))}
            style={{ width: '100%', accentColor: T.blue }} />
          <div style={{ fontSize: 12, color: T.text, textAlign: 'center' }}>{risikofreierZins}% p.a.</div>
        </div>
      </Section>
      {/* ??? Formel 7: Kelly ??? */}
      <Section title="Formel 7: Kelly-Kriterium" badge="Budgetallokation">
        <FormulaBlock
          title="f* = (p ? b ? q) / b"
          formula={`p = ${(opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)} ? q = ${(1 - opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)} ? b = Gewinn/Einsatz = ${costs > 0 ? (opt.risk.bestCase / costs).toFixed(2) : '?'}`}
          calculation={costs > 0 ? `= (${(opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)} ? ${(opt.risk.bestCase / costs).toFixed(2)} ? ${(1 - opt.risk.erfolgswahrscheinlichkeit / 100).toFixed(2)}) / ${(opt.risk.bestCase / costs).toFixed(2)}` : 'Keine Kosten definiert'}
          result={`${(kelly * 100).toFixed(0)}% des Rechtsbudgets`}
          resultColor={T.purple}
          info={`Empfehlung: Maximal ${(kelly * 100).toFixed(0)}% des verfügbaren Budgets in diesen Fall investieren`}
        />
      </Section>
      {/* ??? Formel 8: Break-Even ??? */}
      <Section title="Formel 8: Break-Even-Wahrscheinlichkeit" badge="Schwelle">
        <FormulaBlock
          title="P_break-even = (Verlust + Kosten) / (Gewinn + Verlust)"
          formula="Ab dieser Wahrscheinlichkeit lohnt sich die Option finanziell"
          calculation={`= (${fmt(Math.abs(opt.risk.worstCase))} + ${fmt(costs)}) / (${fmt(opt.risk.bestCase)} + ${fmt(Math.abs(opt.risk.worstCase))})`}
          result={`${beP.toFixed(1)}%`}
          resultColor={T.blue}
          info={opt.risk.erfolgswahrscheinlichkeit >= beP
            ? `Aktuelle P (${opt.risk.erfolgswahrscheinlichkeit}%) > Break-Even (${beP.toFixed(0)}%) ? lohnt sich`
            : `Aktuelle P (${opt.risk.erfolgswahrscheinlichkeit}%) < Break-Even (${beP.toFixed(0)}%) ? lohnt sich nicht`}
        />
        <div style={{ position: 'relative', height: 40, background: T.bg, borderRadius: 10, overflow: 'hidden', marginBottom: 8 }}>
          <div style={{ position: 'absolute', left: `${beP}%`, top: 0, bottom: 0, width: 2, background: T.red, zIndex: 2 }} />
          <div style={{
            position: 'absolute', left: `${opt.risk.erfolgswahrscheinlichkeit}%`, top: 4, bottom: 4,
            width: 16, marginLeft: -8, borderRadius: 8,
            background: opt.risk.erfolgswahrscheinlichkeit >= beP ? T.green : T.red,
            zIndex: 3, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <span style={{ fontSize: 8, color: '#fff', fontWeight: 700 }}>P</span>
          </div>
          <div style={{ position: 'absolute', left: `${beP}%`, top: 0, bottom: 0, right: 0, background: T.green + '15' }} />
          <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${beP}%`, background: T.red + '10' }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: T.dim }}>
          <span>0%</span>
          <span style={{ color: T.red }}>Break-Even: {beP.toFixed(0)}%</span>
          <span style={{ color: T.blue }}>Aktuell: {opt.risk.erfolgswahrscheinlichkeit}%</span>
          <span>100%</span>
        </div>
      </Section>
      {/* ??? Sensitivitätsanalyse ??? */}
      <Section title="Sensitivitätsanalyse" badge="Was-wäre-wenn">
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>
          Wie verändert sich der Erwartungswert bei unterschiedlichen Erfolgswahrscheinlichkeiten?
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {sensData.map(({ p, ev: sensEv }) => {
            const isCurrentP = p === opt.risk.erfolgswahrscheinlichkeit;
            const barWidth = (Math.abs(sensEv) / sensMaxAbs) * 50;
            const isPositive = sensEv >= 0;
            return (
              <div key={p} style={{
                display: 'grid', gridTemplateColumns: '50px 1fr 90px',
                gap: 8, alignItems: 'center', fontSize: 12,
                padding: '4px 8px', borderRadius: 6,
                background: isCurrentP ? T.blue + '10' : 'transparent',
                fontWeight: isCurrentP ? 700 : 400,
              }}>
                <div style={{ textAlign: 'right', color: isCurrentP ? T.blue : T.dim }}>
                  P={p}%{isCurrentP ? ' ?' : ''}
                </div>
                <div style={{ height: 16, position: 'relative' }}>
                  <div style={{ position: 'absolute', left: '50%', top: 0, bottom: 0, width: 1, background: T.border }} />
                  <div style={{
                    position: 'absolute',
                    [isPositive ? 'left' : 'right']: '50%',
                    top: 2, bottom: 2,
                    width: `${barWidth}%`,
                    background: isPositive ? T.green : T.red,
                    borderRadius: 4, transition: 'width 0.3s',
                  }} />
                </div>
                <div style={{ textAlign: 'right', color: isPositive ? T.green : T.red, fontWeight: 600 }}>
                  {isPositive ? '+' : ''}{fmt(sensEv)} €
                </div>
              </div>
            );
          })}
        </div>
      </Section>
      {/* ??? Tornado-Diagramm ??? */}
      <Section title="Tornado-Diagramm" badge="Sensitivität">
        <div style={{ fontSize: 12, color: T.dim, marginBottom: 12 }}>
          Welcher Parameter beeinflusst den Erwartungswert am stärksten? (?20% Variation)
        </div>
        {tornado.map((t, i) => {
          const maxSpread = Math.max(...tornado.map(x => x.spread), 1);
          const barWidth = (t.spread / maxSpread) * 100;
          return (
            <div key={t.parameter} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                <span style={{ fontWeight: i === 0 ? 700 : 400 }}>{i + 1}. {t.parameter}</span>
                <span style={{ color: T.dim }}>Spread: {fmt(t.spread)}€</span>
              </div>
              <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
                <div style={{ fontSize: 10, color: T.red, width: 70, textAlign: 'right' }}>{fmt(Math.min(t.evAtLow, t.evAtHigh))}€</div>
                <div style={{ flex: 1, height: 16, background: T.bg, borderRadius: 8, position: 'relative', overflow: 'hidden' }}>
                  <div style={{
                    position: 'absolute', left: `${50 - barWidth / 2}%`, width: `${barWidth}%`,
                    top: 2, bottom: 2,
                    background: `linear-gradient(90deg, ${T.red}, ${T.green})`,
                    borderRadius: 6,
                  }} />
                </div>
                <div style={{ fontSize: 10, color: T.green, width: 70 }}>{fmt(Math.max(t.evAtLow, t.evAtHigh))}€</div>
              </div>
            </div>
          );
        })}
      </Section>
      {/* ??? Schutzmaßnahmen ??? */}
      <Section title="Schutzmaßnahmen (Brutto ? Netto)" defaultOpen={true}>
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 8 }}>
          <button onClick={addMitigation} style={{
            fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.green,
            background: T.green + '10', border: 'none', borderRadius: 8, padding: '6px 12px', cursor: 'pointer',
          }}>+ Maßnahme</button>
        </div>
        <div style={{ display: 'flex', gap: 16, marginBottom: 16 }}>
          <div style={{ flex: 1, background: T.bg, borderRadius: 10, padding: 12 }}>
            <div style={{ fontSize: 11, color: T.dim }}>Brutto-Risiko</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: T.red }}>{fmt(brutto)} €</div>
          </div>
          <div style={{ flex: 0, display: 'flex', alignItems: 'center', fontSize: 18, color: T.dim }}>?</div>
          <div style={{ flex: 1, background: T.bg, borderRadius: 10, padding: 12 }}>
            <div style={{ fontSize: 11, color: T.dim }}>Reduktion</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: T.green }}>?{fmt(totalMitigationReduction(mitigations))} €</div>
          </div>
          <div style={{ flex: 0, display: 'flex', alignItems: 'center', fontSize: 18, color: T.dim }}>=</div>
          <div style={{ flex: 1, background: T.bg, borderRadius: 10, padding: 12 }}>
            <div style={{ fontSize: 11, color: T.dim }}>Netto-Risiko</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: T.orange }}>{fmt(netto)} €</div>
          </div>
        </div>
        {mitigations.length > 0 && (
          <>
            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 100px 100px 70px 50px 32px',
              gap: 6, fontSize: 10, fontWeight: 600, color: T.dim, padding: '4px 0',
              textTransform: 'uppercase', letterSpacing: '0.04em',
            }}>
              <span>Maßnahme</span><span style={{ textAlign: 'right' }}>Reduktion €</span>
              <span style={{ textAlign: 'right' }}>Kosten €</span><span style={{ textAlign: 'center' }}>ROI</span>
              <span style={{ textAlign: 'center' }}>Lohnt?</span><span></span>
            </div>
            {mitigations.map((m, i) => (
              <MitigationRow key={m.id} m={m}
                onChange={updated => {
                  const arr = [...mitigations]; arr[i] = updated;
                  updateOption(opt.id, { mitigations: arr });
                }}
                onRemove={() => {
                  updateOption(opt.id, { mitigations: mitigations.filter((_, j) => j !== i) });
                }}
              />
            ))}
            <div style={{ marginTop: 8, fontSize: 13, fontWeight: 600, color: T.text }}>
              Maßnahmen-Kosten: {fmt(totalMitigationCost(mitigations))} € ?
              {totalMitigationReduction(mitigations) > totalMitigationCost(mitigations)
                ? <span style={{ color: T.green }}> Lohnt sich</span>
                : <span style={{ color: T.red }}> Kostet mehr als Nutzen</span>
              }
            </div>
          </>
        )}
      </Section>
      {/* ??? Risk Matrix (5?5) ??? */}
      <Section title="Risikomatrix (5?5)" defaultOpen={true}>
        <Panel style={{ marginBottom: 16, background: T.blue + '06' }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: T.blue, marginBottom: 8 }}>Was zeigt die Risikomatrix?</div>
          <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.8 }}>
            Die <strong>Risikomatrix</strong> ordnet jedes Risiko nach zwei Dimensionen ein:
          </div>
          <ul style={{ fontSize: 12, color: T.dim, lineHeight: 1.8, margin: '8px 0', paddingLeft: 20 }}>
            <li><strong>X-Achse (horizontal)</strong>: <em>Eintrittswahrscheinlichkeit</em> (A-Wert, 1?10) ? wie wahrscheinlich tritt das Risiko ein?</li>
            <li><strong>Y-Achse (vertikal)</strong>: <em>Auswirkung/Bedeutung</em> (B-Wert, 1?10) ? wie schwer wäre der Schaden?</li>
          </ul>
          <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.8, marginBottom: 8 }}>
            Die Zellen sind farbcodiert nach Risikostufe:
          </div>
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', fontSize: 12 }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 14, height: 14, borderRadius: 3, background: '#c8e6c9', display: 'inline-block' }} />
              <strong>L</strong> = Low (gering) ? akzeptabel, beobachten
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 14, height: 14, borderRadius: 3, background: '#fff9c4', display: 'inline-block' }} />
              <strong>M</strong> = Medium (mittel) ? Maßnahmen planen
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 14, height: 14, borderRadius: 3, background: '#ffccbc', display: 'inline-block' }} />
              <strong>H</strong> = High (hoch) ? sofort handeln
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 14, height: 14, borderRadius: 3, background: '#ef9a9a', display: 'inline-block' }} />
              <strong>C</strong> = Critical (kritisch) ? höchste Priorität
            </span>
          </div>
          <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.8, marginTop: 8 }}>
            Jedes eingetragene Risiko aus der RPN-Tabelle (Formel 4) wird als <strong>nummerierter Punkt</strong> in der Matrix positioniert.
            {riskItems.length === 0 && <span style={{ color: T.orange }}> <strong>Noch keine Risiken eingetragen ? fügen Sie Risiken in Formel 4 (RPN) hinzu!</strong></span>}
          </div>
        </Panel>
        {/* Matrix Grid */}
        {(() => {
          // Map risk items to 5?5 grid (A: 1-2?0, 3-4?1, 5-6?2, 7-8?3, 9-10?4)
          const toCell = (v: number) => Math.min(4, Math.max(0, Math.floor((v - 1) / 2)));
          const cellMap: Record<string, { label: string; idx: number }[]> = {};
          riskItems.forEach((ri, idx) => {
            const col = toCell(ri.auftretenswahrscheinlichkeit);
            const row = toCell(ri.bedeutung);
            const key = `${row}-${col}`;
            if (!cellMap[key]) cellMap[key] = [];
            cellMap[key].push({ label: ri.label, idx: idx + 1 });
          });
          return (
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ fontSize: 11, color: T.dim, writingMode: 'vertical-rl', transform: 'rotate(180deg)', textAlign: 'center' }}>
                Auswirkung (B) ?
              </div>
              <div>
                <div style={{ display: 'flex', gap: 3, marginBottom: 3 }}>
                  <div style={{ width: 28 }} />
                  {['1-2', '3-4', '5-6', '7-8', '9-10'].map(l => (
                    <div key={l} style={{ width: 64, textAlign: 'center', fontSize: 9, color: T.dim, fontWeight: 600 }}>{l}</div>
                  ))}
                </div>
                {[4, 3, 2, 1, 0].map(row => (
                  <div key={row} style={{ display: 'flex', gap: 3, marginBottom: 3, alignItems: 'center' }}>
                    <div style={{ width: 28, fontSize: 9, color: T.dim, textAlign: 'right', fontWeight: 600 }}>
                      {['1-2', '3-4', '5-6', '7-8', '9-10'][row]}
                    </div>
                    {[0, 1, 2, 3, 4].map(col => {
                      const level = row + col;
                      const bg = level <= 2 ? '#c8e6c9' : level <= 4 ? '#fff9c4' : level <= 6 ? '#ffccbc' : '#ef9a9a';
                      const label = level <= 2 ? 'L' : level <= 4 ? 'M' : level <= 6 ? 'H' : 'C';
                      const items = cellMap[`${row}-${col}`] || [];
                      return (
                        <div key={col} title={items.map(i => `#${i.idx}: ${i.label}`).join('\n')} style={{
                          width: 64, height: 44, display: 'flex', flexDirection: 'column',
                          alignItems: 'center', justifyContent: 'center',
                          background: bg, borderRadius: 6, fontSize: 12, fontWeight: 600, color: '#555',
                          position: 'relative', border: items.length > 0 ? '2px solid #333' : 'none',
                        }}>
                          {items.length > 0 ? (
                            <div style={{ display: 'flex', gap: 2, flexWrap: 'wrap', justifyContent: 'center' }}>
                              {items.map(i => (
                                <span key={i.idx} style={{
                                  fontSize: 10, fontWeight: 700, color: '#fff',
                                  background: '#333', borderRadius: '50%',
                                  width: 18, height: 18, display: 'flex', alignItems: 'center', justifyContent: 'center',
                                }}>
                                  {i.idx}
                                </span>
                              ))}
                            </div>
                          ) : (
                            <span style={{ opacity: 0.4 }}>{label}</span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                ))}
                <div style={{ display: 'flex', gap: 3, marginTop: 6 }}>
                  <div style={{ width: 28 }} />
                  <div style={{ flex: 1, textAlign: 'center', fontSize: 11, color: T.dim }}>
                    Eintrittswahrscheinlichkeit (A) ?
                  </div>
                </div>
              </div>
            </div>
          );
        })()}
        {/* Risk Legend */}
        {riskItems.length > 0 && (
          <div style={{ marginTop: 16, padding: 12, background: T.bg, borderRadius: 10 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: T.dim, marginBottom: 8 }}>Legende:</div>
            {riskItems.map((ri, idx) => {
              const rpn = computeRPN(ri);
              return (
                <div key={ri.id} style={{ fontSize: 12, display: 'flex', gap: 8, alignItems: 'center', padding: '3px 0' }}>
                  <span style={{
                    fontSize: 10, fontWeight: 700, color: '#fff',
                    background: '#333', borderRadius: '50%',
                    width: 18, height: 18, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>{idx + 1}</span>
                  <span style={{ fontWeight: 600 }}>{ri.label || '(kein Name)'}</span>
                  <span style={{ color: T.dim }}>A={ri.auftretenswahrscheinlichkeit} B={ri.bedeutung} E={ri.entdeckungswahrscheinlichkeit}</span>
                  <span style={{ fontWeight: 700, color: rpn >= RPN_CRITICAL ? T.red : T.text }}>RPN={rpn}</span>
                </div>
              );
            })}
          </div>
        )}
      </Section>
    </div>
  );
}
