import React, { useState, useRef } from 'react';
import { BusinessScenario, BusinessOption, BusinessArgument, argumentScore } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label, Bar, Btn } from '@/components/lexara/Primitives';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
export function ArgumentWeightingStep({ scenario, onUpdate }: Props) {
  const [activeIdx, setActiveIdx] = useState(0);
  const [newText, setNewText] = useState('');
  const [newSide, setNewSide] = useState<'pro' | 'contra'>('pro');
  const [dragId, setDragId] = useState<string | null>(null);
  const [dragOverId, setDragOverId] = useState<string | null>(null);
  const updateOption = (id: string, patch: Partial<BusinessOption>) => {
    onUpdate({
      ...scenario,
      options: scenario.options.map(o => o.id === id ? { ...o, ...patch } : o),
    });
  };
  if (!scenario.options.length) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: T.dim }}>
        <div style={{ fontSize: 15 }}>Bitte fügen Sie zuerst Optionen hinzu</div>
      </div>
    );
  }
  const opt = scenario.options[activeIdx] || scenario.options[0];
  const score = argumentScore(opt.arguments);
  const pros = opt.arguments.filter(a => a.side === 'pro');
  const contras = opt.arguments.filter(a => a.side === 'contra');
  const addArg = () => {
    if (!newText.trim()) return;
    const arg: BusinessArgument = {
      id: `arg-${Date.now()}`,
      side: newSide,
      text: newText.trim(),
      weight: 5,
    };
    updateOption(opt.id, { arguments: [...opt.arguments, arg] });
    setNewText('');
  };
  const updateArg = (argId: string, patch: Partial<BusinessArgument>) => {
    updateOption(opt.id, {
      arguments: opt.arguments.map(a => a.id === argId ? { ...a, ...patch } : a),
    });
  };
  const deleteArg = (argId: string) => {
    updateOption(opt.id, { arguments: opt.arguments.filter(a => a.id !== argId) });
  };
  // Drag and drop reordering
  const getVisualOrder = (list: BusinessArgument[]): BusinessArgument[] => {
    if (!dragId || !dragOverId || dragId === dragOverId) return list;
    const fromIdx = list.findIndex(a => a.id === dragId);
    const toIdx = list.findIndex(a => a.id === dragOverId);
    if (fromIdx === -1 || toIdx === -1) return list;
    const reordered = [...list];
    const [moved] = reordered.splice(fromIdx, 1);
    reordered.splice(toIdx, 0, moved);
    return reordered;
  };
  const handleDrop = (side: 'pro' | 'contra') => {
    if (!dragId || !dragOverId || dragId === dragOverId) {
      setDragId(null);
      setDragOverId(null);
      return;
    }
    const sideArgs = opt.arguments.filter(a => a.side === side);
    const fromIdx = sideArgs.findIndex(a => a.id === dragId);
    const toIdx = sideArgs.findIndex(a => a.id === dragOverId);
    if (fromIdx === -1 || toIdx === -1) {
      setDragId(null);
      setDragOverId(null);
      return;
    }
    const reordered = [...sideArgs];
    const [moved] = reordered.splice(fromIdx, 1);
    reordered.splice(toIdx, 0, moved);
    // Reconstruct full arguments array preserving other side's order
    const otherArgs = opt.arguments.filter(a => a.side !== side);
    updateOption(opt.id, { arguments: [...otherArgs, ...reordered] });
    setDragId(null);
    setDragOverId(null);
  };
  const renderArgList = (list: BusinessArgument[], side: 'pro' | 'contra', color: string) => {
    const visual = getVisualOrder(list);
    return visual.map(a => (
      <div
        key={a.id}
        draggable
        onDragStart={() => setDragId(a.id)}
        onDragOver={(e) => { e.preventDefault(); setDragOverId(a.id); }}
        onDrop={() => handleDrop(side)}
        onDragEnd={() => { setDragId(null); setDragOverId(null); }}
        style={{
          marginBottom: 8, padding: '12px 14px', background: T.surface, borderRadius: 10,
          borderLeft: `3px solid ${color}`,
          opacity: dragId === a.id ? 0.3 : 1,
          transition: 'transform 0.15s ease, opacity 0.15s ease',
          transform: dragOverId === a.id && dragId !== a.id ? 'translateY(4px)' : 'none',
          cursor: 'grab',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: 1 }}>
            <span style={{ fontSize: 11, color: T.dim, cursor: 'grab', userSelect: 'none' }}>?</span>
            <div style={{ fontSize: 13, flex: 1 }}>{a.text}</div>
          </div>
          <button onClick={() => deleteArg(a.id)} style={{
            fontSize: 12, color: T.dim, background: 'none', border: 'none', cursor: 'pointer',
          }}>?</button>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
          <span style={{ fontSize: 11, color: T.dim }}>Gewicht:</span>
          <input type="range" min={1} max={10} value={a.weight}
            onChange={e => updateArg(a.id, { weight: Number(e.target.value) })}
            style={{ flex: 1, accentColor: color }} />
          <span style={{ fontSize: 12, fontWeight: 600, color, minWidth: 30 }}>{a.weight}/10</span>
        </div>
      </div>
    ));
  };
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
      {/* Score overview */}
      <Panel style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 24, justifyContent: 'center' }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, fontWeight: 700, color: T.green }}>{score.pro.toFixed(1)}</div>
            <div style={{ fontSize: 12, color: T.dim }}>Pro ?</div>
          </div>
          <div style={{ fontSize: 20, color: T.dim }}>vs</div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, fontWeight: 700, color: T.red }}>{score.contra.toFixed(1)}</div>
            <div style={{ fontSize: 12, color: T.dim }}>Contra ?</div>
          </div>
          <div style={{ width: 1, height: 40, background: T.border }} />
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, fontWeight: 700, color: score.net >= 0 ? T.green : T.red }}>
              {score.net >= 0 ? '+' : ''}{score.net.toFixed(1)}
            </div>
            <div style={{ fontSize: 12, color: T.dim }}>Netto</div>
          </div>
        </div>
      </Panel>
      {/* Add argument */}
      <Panel style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
          <Btn small active={newSide === 'pro'} color={T.green} onClick={() => setNewSide('pro')}>PRO</Btn>
          <Btn small active={newSide === 'contra'} color={T.red} onClick={() => setNewSide('contra')}>CONTRA</Btn>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <input value={newText} onChange={e => setNewText(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && addArg()}
            placeholder="Argument eingeben?"
            style={{
              fontFamily: sans, fontSize: 14, flex: 1, padding: '10px 14px',
              border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
              outline: 'none', color: T.text,
            }}
          />
          <button onClick={addArg} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff',
            background: T.blue, border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer',
          }}>+</button>
        </div>
      </Panel>
      {/* Arguments list */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        {/* PRO */}
        <div>
          <Label>Pro-Argumente ({pros.length})</Label>
          {renderArgList(pros, 'pro', T.green)}
          {!pros.length && <div style={{ fontSize: 13, color: T.dim, padding: 16 }}>Noch keine Pro-Argumente</div>}
        </div>
        {/* CONTRA */}
        <div>
          <Label>Contra-Argumente ({contras.length})</Label>
          {renderArgList(contras, 'contra', T.red)}
          {!contras.length && <div style={{ fontSize: 13, color: T.dim, padding: 16 }}>Noch keine Contra-Argumente</div>}
        </div>
      </div>
    </div>
  );
}
