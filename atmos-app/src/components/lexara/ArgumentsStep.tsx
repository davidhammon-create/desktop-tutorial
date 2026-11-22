import React, { useState } from 'react';
import { LexaraCase, LexaraArgument } from '@/types/lexara';
import { T, sans, scol } from './theme';
import { Panel, SectionTitle, Chip, Bar } from './Primitives';
import { CompactArgumentExtractor } from '@/components/document/CompactArgumentExtractor';
interface Props {
  c: LexaraCase;
  onUpdateCase: (updated: LexaraCase) => void;
  onEditArg: (arg: LexaraArgument) => void;
  onAddArg: () => void;
}
export function ArgumentsStep({ c, onUpdateCase, onEditArg, onAddArg }: Props) {
  const [filter, setFilter] = useState<'all' | 'own' | 'opp'>('all');
  const ownArgs = c.arguments.filter(a => a.side === 'own');
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  const filtered = filter === 'all' ? c.arguments : c.arguments.filter(a => a.side === filter);
  const handleDelete = (id: string) => {
    const updatedArgs = c.arguments.filter(a => a.id !== id);
    const updatedEdges = c.edges.filter(e => e.from !== id && e.to !== id);
    const updatedEvidence = { ...c.evidence };
    delete updatedEvidence[id];
    onUpdateCase({ ...c, arguments: updatedArgs, edges: updatedEdges, evidence: updatedEvidence });
  };
  return (
    <div style={{ padding: 24, maxWidth: 1000, margin: '0 auto' }}>
      {/* Summary bar */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
        <Panel style={{ flex: 1, textAlign: 'center', padding: 16 }}>
          <div style={{ fontSize: 28, fontWeight: 700, color: T.blue }}>{ownArgs.length}</div>
          <div style={{ fontSize: 12, color: T.dim }}>Eigene Argumente</div>
          <div style={{ fontSize: 12, color: T.blue, fontWeight: 600, marginTop: 4 }}>
            ? Stärke: {ownArgs.length > 0 ? (ownArgs.reduce((s, a) => s + a.strength, 0) / ownArgs.length).toFixed(1) : '?'}
          </div>
        </Panel>
        <Panel style={{ flex: 1, textAlign: 'center', padding: 16 }}>
          <div style={{ fontSize: 28, fontWeight: 700, color: T.red }}>{oppArgs.length}</div>
          <div style={{ fontSize: 12, color: T.dim }}>Gegnerische Argumente</div>
          <div style={{ fontSize: 12, color: T.red, fontWeight: 600, marginTop: 4 }}>
            ? Stärke: {oppArgs.length > 0 ? (oppArgs.reduce((s, a) => s + a.strength, 0) / oppArgs.length).toFixed(1) : '?'}
          </div>
        </Panel>
      </div>
      {/* Controls */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div style={{ display: 'inline-flex', background: T.surface, borderRadius: 10, padding: 3 }}>
          {[
            { id: 'all' as const, label: 'Alle' },
            { id: 'own' as const, label: 'Eigene' },
            { id: 'opp' as const, label: 'Gegner' },
          ].map(f => (
            <button key={f.id} onClick={() => setFilter(f.id)} style={{
              fontFamily: sans, fontSize: 13, fontWeight: filter === f.id ? 600 : 400,
              color: filter === f.id ? T.text : T.dim,
              background: filter === f.id ? T.bg : 'transparent',
              border: 'none', borderRadius: 8, padding: '6px 16px', cursor: 'pointer',
            }}>
              {f.label}
            </button>
          ))}
        </div>
        <button onClick={onAddArg} style={{
          fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.blue,
          border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
        }}>
          + Argument
        </button>
      </div>
      {/* AI Argument Extractor - compact */}
      <CompactArgumentExtractor c={c} onUpdateCase={onUpdateCase} />
      {/* Divider */}
      <div style={{ borderTop: '1px solid rgba(0,0,0,0.06)', margin: '20px 0' }} />
      {/* Arguments list */}
      {filtered.length === 0 ? (
        <Panel style={{ textAlign: 'center', padding: 48, color: T.dim }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Noch keine Argumente</div>
          <div style={{ fontSize: 13, marginTop: 4 }}>Füge eigene und gegnerische Argumente hinzu, um die Analyse zu starten.</div>
          <button onClick={onAddArg} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 600, color: T.blue,
            background: T.blue + '10', border: 'none', borderRadius: 10,
            padding: '10px 24px', cursor: 'pointer', marginTop: 16,
          }}>
            + Erstes Argument hinzufügen
          </button>
        </Panel>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {filtered.map(a => {
            const col = a.side === 'own' ? T.blue : T.red;
            const evCount = (c.evidence[a.id] || []).length;
            return (
              <Panel key={a.id} style={{ padding: 16, transition: 'background 0.2s ease', cursor: 'pointer' }}
                onMouseEnter={e => { (e.currentTarget as HTMLElement).style.background = 'rgba(0,0,0,0.03)'; }}
                onMouseLeave={e => { (e.currentTarget as HTMLElement).style.background = T.surface; }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                      <Chip small color={col}>{a.side === 'own' ? 'Eigen' : 'Gegner'}</Chip>
                      {a.source === 'ki' && <Chip small color={T.orange}>KI</Chip>}
                      {a.argType && <Chip small color={T.dim}>{a.argType}</Chip>}
                      {a.legalBasis && <Chip small color={T.purple}>{a.legalBasis}</Chip>}
                      {a.seite && <Chip small color={T.dim}>S.{a.seite}</Chip>}
                    </div>
                    <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>{a.label}</div>
                    {a.content && <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.5, marginBottom: 6 }}>{a.content}</div>}
                    <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, width: 120 }}>
                        <Bar v={a.strength} max={10} color={scol(a.strength * 10)} h={4} />
                        <span style={{ fontSize: 13, fontWeight: 600, color: scol(a.strength * 10) }}>{a.strength}/10</span>
                      </div>
                      {evCount > 0 && <Chip small color={T.green}>{evCount} Beweise</Chip>}
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 4, flexShrink: 0, marginLeft: 12 }}>
                    <button onClick={() => onEditArg(a)} style={{
                      width: 32, height: 32, borderRadius: 8, background: T.bg,
                      border: 'none', cursor: 'pointer', fontSize: 14, color: T.dim,
                    }}>?</button>
                    <button onClick={() => { if (confirm('Argument löschen?')) handleDelete(a.id); }} style={{
                      width: 32, height: 32, borderRadius: 8, background: T.bg,
                      border: 'none', cursor: 'pointer', fontSize: 14, color: T.red,
                    }}>?</button>
                  </div>
                </div>
              </Panel>
            );
          })}
        </div>
      )}
    </div>
  );
}
