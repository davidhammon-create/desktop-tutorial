import React, { useState } from 'react';
import { BusinessScenario, BusinessOption, totalCosts } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label, Bar } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
function CurrencyInput({ value, onChange, label }: { value: number; onChange: (v: number) => void; label: string }) {
  return (
    <div style={{ flex: 1, minWidth: 140 }}>
      <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
        <input
          type="number" value={value || ''} onChange={e => onChange(Number(e.target.value) || 0)}
          style={{
            fontFamily: sans, fontSize: 14, width: '100%', padding: '8px 10px',
            border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg,
            outline: 'none', color: T.text,
          }}
        />
        <span style={{ fontSize: 13, color: T.dim }}>€</span>
      </div>
    </div>
  );
}
function SliderInput({ value, onChange, label, max = 100, suffix = '%' }: {
  value: number; onChange: (v: number) => void; label: string; max?: number; suffix?: string;
}) {
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: T.dim, marginBottom: 4 }}>
        <span>{label}</span><span style={{ fontWeight: 600, color: T.text }}>{value}{suffix}</span>
      </div>
      <input type="range" min={0} max={max} value={value} onChange={e => onChange(Number(e.target.value))}
        style={{ width: '100%', accentColor: T.blue }} />
    </div>
  );
}
export function DetailAnalysisStep({ scenario, onUpdate }: Props) {
  const [activeIdx, setActiveIdx] = useState(0);
  const updateOption = (id: string, patch: Partial<BusinessOption>) => {
    onUpdate({
      ...scenario,
      options: scenario.options.map(o => o.id === id ? { ...o, ...patch } : o),
    });
  };
  if (!scenario.options.length) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: T.dim }}>
        <div style={{ fontSize: 15 }}>Bitte fügen Sie zuerst Optionen in Schritt 2 hinzu</div>
      </div>
    );
  }
  const opt = scenario.options[activeIdx] || scenario.options[0];
  return (
    <div style={{ padding: 24, maxWidth: 900 }}>
      {/* Option tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, overflowX: 'auto' }}>
        {scenario.options.map((o, i) => (
          <button key={o.id} onClick={() => setActiveIdx(i)} style={{
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
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        {/* Kosten */}
        <Panel>
          <Label>Kosten</Label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
            <CurrencyInput label="Anwaltskosten" value={opt.costs.anwaltskosten}
              onChange={v => updateOption(opt.id, { costs: { ...opt.costs, anwaltskosten: v } })} />
            <CurrencyInput label="Gerichtskosten" value={opt.costs.gerichtskosten}
              onChange={v => updateOption(opt.id, { costs: { ...opt.costs, gerichtskosten: v } })} />
            <CurrencyInput label="Interne Kosten" value={opt.costs.interneKosten}
              onChange={v => updateOption(opt.id, { costs: { ...opt.costs, interneKosten: v } })} />
            <CurrencyInput label="Opportunitätskosten" value={opt.costs.opportunitaetskosten}
              onChange={v => updateOption(opt.id, { costs: { ...opt.costs, opportunitaetskosten: v } })} />
          </div>
          <div style={{ marginTop: 12, fontSize: 14, fontWeight: 600, color: T.text }}>
            Gesamt: {totalCosts(opt.costs).toLocaleString('de-DE')} €
          </div>
        </Panel>
        {/* Chancen & Risiken */}
        <Panel>
          <Label>Chancen & Risiken</Label>
          <SliderInput label="Erfolgswahrscheinlichkeit" value={opt.risk.erfolgswahrscheinlichkeit}
            onChange={v => updateOption(opt.id, { risk: { ...opt.risk, erfolgswahrscheinlichkeit: v } })} />
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
            <CurrencyInput label="Best Case" value={opt.risk.bestCase}
              onChange={v => updateOption(opt.id, { risk: { ...opt.risk, bestCase: v } })} />
            <CurrencyInput label="Worst Case" value={opt.risk.worstCase}
              onChange={v => updateOption(opt.id, { risk: { ...opt.risk, worstCase: v } })} />
            <CurrencyInput label="Wahrscheinlichster Fall" value={opt.risk.likelyCase}
              onChange={v => updateOption(opt.id, { risk: { ...opt.risk, likelyCase: v } })} />
          </div>
        </Panel>
        {/* Zeitrahmen */}
        <Panel>
          <Label>Zeitrahmen</Label>
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Min. Monate</div>
              <input type="number" min={0} value={opt.timeframe.minMonths}
                onChange={e => updateOption(opt.id, { timeframe: { ...opt.timeframe, minMonths: Number(e.target.value) || 0 } })}
                style={{ fontFamily: sans, fontSize: 14, width: '100%', padding: '8px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg, outline: 'none', color: T.text }}
              />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Max. Monate</div>
              <input type="number" min={0} value={opt.timeframe.maxMonths}
                onChange={e => updateOption(opt.id, { timeframe: { ...opt.timeframe, maxMonths: Number(e.target.value) || 0 } })}
                style={{ fontFamily: sans, fontSize: 14, width: '100%', padding: '8px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg, outline: 'none', color: T.text }}
              />
            </div>
          </div>
          <div style={{ marginTop: 12 }}>
            <div style={{ fontSize: 12, color: T.dim, marginBottom: 4 }}>Frühestes Ergebnis</div>
            <input value={opt.timeframe.earliestResult}
              onChange={e => updateOption(opt.id, { timeframe: { ...opt.timeframe, earliestResult: e.target.value } })}
              placeholder="z.B. 'Ergebnis nach ca. 6 Monaten'"
              style={{ fontFamily: sans, fontSize: 13, width: '100%', padding: '8px 10px', border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg, outline: 'none', color: T.text }}
            />
          </div>
        </Panel>
        {/* Nicht-monetäre Faktoren */}
        <Panel>
          <Label>Nicht-monetäre Faktoren</Label>
          <SliderInput label="Reputationsrisiko" value={opt.nonMonetary.reputationsrisiko} max={10} suffix="/10"
            onChange={v => updateOption(opt.id, { nonMonetary: { ...opt.nonMonetary, reputationsrisiko: v } })} />
          <SliderInput label="Geschäftsbeziehung gefährdet" value={opt.nonMonetary.geschaeftsbeziehungGefaehrdet} max={10} suffix="/10"
            onChange={v => updateOption(opt.id, { nonMonetary: { ...opt.nonMonetary, geschaeftsbeziehungGefaehrdet: v } })} />
          <SliderInput label="Medienöffentlichkeit" value={opt.nonMonetary.medienoeffentlichkeit} max={10} suffix="/10"
            onChange={v => updateOption(opt.id, { nonMonetary: { ...opt.nonMonetary, medienoeffentlichkeit: v } })} />
          <SliderInput label="Präzedenzwirkung" value={opt.nonMonetary.praezedenzwirkung ?? 0} max={10} suffix="/10"
            onChange={v => updateOption(opt.id, { nonMonetary: { ...opt.nonMonetary, praezedenzwirkung: v } })} />
          <SliderInput label="Mitarbeitermoral-Auswirkung" value={opt.nonMonetary.mitarbeitermoralAuswirkung ?? 0} max={10} suffix="/10"
            onChange={v => updateOption(opt.id, { nonMonetary: { ...opt.nonMonetary, mitarbeitermoralAuswirkung: v } })} />
        </Panel>
      </div>
      {/* Relevante Gesetze */}
      <Panel style={{ marginTop: 16 }}>
        <Label>Relevante Gesetze & Präzedenzfälle</Label>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 10 }}>
          {opt.relevanteLaws.map((law, i) => (
            <span key={i} style={{
              fontSize: 12, fontWeight: 500, color: T.blue, background: T.blue + '10',
              borderRadius: 8, padding: '4px 10px', display: 'flex', alignItems: 'center', gap: 6,
            }}>
              {law}
              <span onClick={() => {
                const updated = [...opt.relevanteLaws];
                updated.splice(i, 1);
                updateOption(opt.id, { relevanteLaws: updated });
              }} style={{ cursor: 'pointer', opacity: 0.6 }}>?</span>
            </span>
          ))}
        </div>
        <input
          placeholder="z.B. '§ 823 BGB' eingeben + Enter"
          onKeyDown={e => {
            if (e.key === 'Enter' && (e.target as HTMLInputElement).value.trim()) {
              updateOption(opt.id, { relevanteLaws: [...opt.relevanteLaws, (e.target as HTMLInputElement).value.trim()] });
              (e.target as HTMLInputElement).value = '';
            }
          }}
          style={{
            fontFamily: sans, fontSize: 13, width: '100%', maxWidth: 300, padding: '8px 10px',
            border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg, outline: 'none', color: T.text,
          }}
        />
      </Panel>
    </div>
  );
}
