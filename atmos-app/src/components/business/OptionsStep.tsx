import React, { useState } from 'react';
import { BusinessScenario, BusinessOption, createEmptyOption } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label, Btn } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
export function OptionsStep({ scenario, onUpdate }: Props) {
  const [newLabel, setNewLabel] = useState('');
  const addOption = () => {
    if (!newLabel.trim()) return;
    const opt = createEmptyOption(newLabel.trim());
    onUpdate({ ...scenario, options: [...scenario.options, opt] });
    setNewLabel('');
  };
  const removeOption = (id: string) => {
    onUpdate({ ...scenario, options: scenario.options.filter(o => o.id !== id) });
  };
  const updateOption = (id: string, patch: Partial<BusinessOption>) => {
    onUpdate({
      ...scenario,
      options: scenario.options.map(o => o.id === id ? { ...o, ...patch } : o),
    });
  };
  return (
    <div style={{ padding: 24, maxWidth: 800 }}>
      <Panel style={{ marginBottom: 20 }}>
        <Label>Neue Handlungsoption hinzufügen</Label>
        <div style={{ display: 'flex', gap: 10 }}>
          <input
            value={newLabel} onChange={e => setNewLabel(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && addOption()}
            placeholder="z.B. 'Klage einreichen', 'Vergleich anbieten'?"
            style={{
              fontFamily: sans, fontSize: 14, flex: 1, padding: '10px 14px',
              border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
              outline: 'none', color: T.text,
            }}
          />
          <button onClick={addOption} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff',
            background: T.blue, border: 'none', borderRadius: 10, padding: '10px 20px', cursor: 'pointer',
          }}>+ Hinzufügen</button>
        </div>
      </Panel>
      {scenario.options.length === 0 && (
        <div style={{ textAlign: 'center', padding: 40, color: T.dim }}>
          <div style={{ fontSize: 15, fontWeight: 600 }}>Noch keine Optionen</div>
          <div style={{ fontSize: 13, marginTop: 4 }}>Fügen Sie mindestens 2 Handlungsoptionen hinzu</div>
        </div>
      )}
      {scenario.options.map((opt, i) => (
        <Panel key={opt.id} style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{
                width: 28, height: 28, borderRadius: '50%', background: T.blue,
                color: '#fff', fontSize: 13, fontWeight: 700,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{String.fromCharCode(65 + i)}</span>
              <input
                value={opt.label}
                onChange={e => updateOption(opt.id, { label: e.target.value })}
                style={{
                  fontFamily: sans, fontSize: 16, fontWeight: 600, border: 'none',
                  outline: 'none', background: 'transparent', color: T.text, width: '100%',
                }}
              />
            </div>
            <button onClick={() => removeOption(opt.id)} style={{
              fontFamily: sans, fontSize: 12, color: T.red, background: T.red + '10',
              border: 'none', borderRadius: 8, padding: '4px 10px', cursor: 'pointer',
            }}>Entfernen</button>
          </div>
          <textarea
            value={opt.description}
            onChange={e => updateOption(opt.id, { description: e.target.value })}
            placeholder="Kurze Beschreibung dieser Option?"
            rows={2}
            style={{
              fontFamily: sans, fontSize: 13, width: '100%', padding: '8px 12px',
              border: `1px solid ${T.border}`, borderRadius: 8, background: T.bg,
              outline: 'none', color: T.text, resize: 'vertical',
            }}
          />
        </Panel>
      ))}
    </div>
  );
}
