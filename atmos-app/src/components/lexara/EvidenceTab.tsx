import React, { useState, useMemo } from 'react';
import { LexaraCase } from '@/types/lexara';
import { T, mono, serif, sans, scol } from './theme';
import { Bar, Chip, Panel, Label } from './Primitives';
export function EvidenceTab({ c }: { c: LexaraCase }) {
  const [active, setActive] = useState<string | null>(c.arguments[0]?.id || null);
  const arg = c.arguments.find(a => a.id === active);
  const evs = active ? (c.evidence[active] || []) : [];
  const col = arg ? (arg.side === 'own' ? T.own : T.opp) : T.gold;
  // Compute KET (Kumulative Evidenz-Tragkraft)
  const ket = useMemo(() => {
    if (evs.length === 0) return 0;
    return evs.reduce((s, e) => s + (e.strength ?? 5) * ((e.validity ?? 50) / 100), 0) / evs.length * 10;
  }, [evs]);
  return (
    <div style={{ display: 'flex', gap: 16, height: '100%', overflow: 'hidden', padding: 16 }}>
      {/* Arguments list */}
      <div style={{ width: 200, overflowY: 'auto', flexShrink: 0 }}>
        <Label>Argumente</Label>
        {c.arguments.map(a => {
          const ac = a.side === 'own' ? T.own : T.opp;
          const isA = active === a.id;
          return (
            <div key={a.id} onClick={() => setActive(a.id)} style={{
              background: isA ? T.raised : T.surface,
              border: 'none',
              padding: '10px 12px', marginBottom: 4, cursor: 'pointer', transition: 'all 0.15s', borderRadius: 2,
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, alignItems: 'center' }}>
                <Chip color={ac} small>{a.side === 'own' ? 'Eigen' : 'Gegner'}</Chip>
                <span style={{ fontFamily: mono, fontSize: 11, color: ac }}>{a.strength}</span>
              </div>
              <div style={{ fontFamily: sans, fontSize: 11, color: isA ? T.text : T.dim, lineHeight: 1.4 }}>
                {a.label}
              </div>
            </div>
          );
        })}
      </div>
      {/* Evidence detail */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div>
            <Label>{arg?.label}</Label>
            <div style={{ fontFamily: serif, fontSize: 19, color: T.text }}>{evs.length} Beweisstränge</div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontFamily: mono, fontSize: 9, color: T.dim, marginBottom: 2 }}>KET</div>
            <div style={{ fontFamily: mono, fontSize: 24, color: col }}>{Math.min(99, Math.round(ket))}</div>
          </div>
        </div>
        {/* Divider */}
        <div style={{ borderTop: '1px solid rgba(0,0,0,0.06)', marginBottom: 16 }} />
        {evs.map((e, i) => {
          const comb = (e.strength ?? 5) * ((e.validity ?? 50) / 100);
          return (
            <div key={e.id} style={{ display: 'flex', gap: 0, alignItems: 'stretch', marginBottom: 0 }}>
              {/* Timeline dot */}
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 24 }}>
                <div style={{ width: 24, height: 24, border: `2px solid ${col}66`, borderRadius: '50%', background: T.surface, flexShrink: 0 }} />
                {i < evs.length - 1 && <div style={{ flex: 1, width: 1, background: `${col}33` }} />}
              </div>
              {/* Evidence card */}
              <div style={{ flex: 1, background: T.surface, borderRadius: 2, padding: 14, marginBottom: 12, marginLeft: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                  <div>
                    <div style={{ fontFamily: sans, fontSize: 13, fontWeight: 500, color: T.text }}>{e.name}</div>
                    {e.type && <Chip small>{e.type}</Chip>}
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span style={{ fontFamily: mono, fontSize: 14, color: scol(comb / 9 * 100) }}>{comb.toFixed(2)}</span>
                  </div>
                </div>
                <div style={{ fontFamily: sans, fontSize: 11, color: T.dim, lineHeight: 1.5, marginBottom: 8 }}>
                  {e.desc}
                </div>
                {e.validity !== undefined && (
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ fontFamily: mono, fontSize: 8, color: T.dim }}>Beweisgültigkeit</span>
                        <span style={{ fontFamily: mono, fontSize: 8, color: scol(e.validity) }}>{e.validity}%</span>
                      </div>
                      <Bar v={e.validity} max={100} color={scol(e.validity)} h={2} />
                    </div>
                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ fontFamily: mono, fontSize: 8, color: T.dim }}>Beweiskraft</span>
                        <span style={{ fontFamily: mono, fontSize: 8, color: scol((e.strength ?? 5) / 10 * 100) }}>{e.strength}</span>
                      </div>
                      <Bar v={e.strength ?? 5} max={10} color={scol((e.strength ?? 5) / 10 * 100)} h={2} />
                    </div>
                  </div>
                )}
              </div>
            </div>
          );
        })}
        {evs.length === 0 && (
          <Panel>
            <div style={{ fontFamily: sans, fontSize: 12, color: T.dim, textAlign: 'center', padding: 20 }}>
              Keine Beweise für dieses Argument hinterlegt.
            </div>
          </Panel>
        )}
      </div>
    </div>
  );
}
