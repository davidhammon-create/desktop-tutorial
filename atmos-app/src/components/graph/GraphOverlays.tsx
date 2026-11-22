import React from 'react';
import { ArgumentNode, ARGUMENT_TYPE_CONFIG } from '@/types/argument';
interface GraphOverlaysProps {
  nodes: ArgumentNode[];
}
const LEGEND_ITEMS: { type: string; label: string; color: string }[] = [
  { type: 'claim', label: 'Eigene Claims', color: ARGUMENT_TYPE_CONFIG.claim.color },
  { type: 'counterargument', label: 'Gegenargumente', color: ARGUMENT_TYPE_CONFIG.counterargument.color },
  { type: 'evidence', label: 'Beweise', color: ARGUMENT_TYPE_CONFIG.evidence.color },
  { type: 'rebuttal', label: 'Erwiderung', color: ARGUMENT_TYPE_CONFIG.rebuttal.color },
  { type: 'premise', label: 'Prämisse', color: ARGUMENT_TYPE_CONFIG.premise.color },
];
export const GraphOverlays: React.FC<GraphOverlaysProps> = ({ nodes }) => {
  const ownNodes = nodes.filter(n => n.type === 'claim' || n.type === 'evidence' || n.type === 'premise');
  const oppNodes = nodes.filter(n => n.type === 'counterargument' || n.type === 'rebuttal');
  const ownTotal = ownNodes.reduce((s, n) => s + n.strength, 0);
  const oppTotal = oppNodes.reduce((s, n) => s + n.strength, 0);
  const max = Math.max(ownTotal + oppTotal, 1);
  const ownPct = Math.round((ownTotal / max) * 100);
  const oppPct = 100 - ownPct;
  return (
    <>
      {/* Score bar ? top-right */}
      <div className="absolute top-3 right-3 z-10 bg-card/90 backdrop-blur-sm border border-border rounded-lg p-3 shadow-sm" style={{ width: 240 }}>
        <div className="text-xs font-medium text-muted-foreground mb-1.5 tracking-wide">Stärke-Vergleich</div>
        <div className="flex items-center gap-2 mb-1">
          <span className="text-xs font-semibold" style={{ color: ARGUMENT_TYPE_CONFIG.claim.color, minWidth: 20 }}>{ownTotal}</span>
          <div className="flex-1 h-3 rounded-full bg-muted overflow-hidden flex">
            <div
              className="h-full rounded-l-full transition-all duration-500"
              style={{ width: `${ownPct}%`, backgroundColor: ARGUMENT_TYPE_CONFIG.claim.color }}
            />
            <div
              className="h-full rounded-r-full transition-all duration-500"
              style={{ width: `${oppPct}%`, backgroundColor: ARGUMENT_TYPE_CONFIG.counterargument.color }}
            />
          </div>
          <span className="text-xs font-semibold" style={{ color: ARGUMENT_TYPE_CONFIG.counterargument.color, minWidth: 20, textAlign: 'right' }}>{oppTotal}</span>
        </div>
        <div className="flex justify-between text-[10px] text-muted-foreground">
          <span>Eigene ({ownNodes.length})</span>
          <span>Gegner ({oppNodes.length})</span>
        </div>
      </div>
      {/* Legend ? bottom-left */}
      <div className="absolute bottom-3 left-3 z-10 bg-card/90 backdrop-blur-sm border border-border rounded-lg p-2.5 shadow-sm">
        <div className="text-[10px] font-medium text-muted-foreground mb-1.5 tracking-wide uppercase">Legende</div>
        <div className="flex flex-col gap-1">
          {LEGEND_ITEMS.map(item => (
            <div key={item.type} className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-sm flex-shrink-0" style={{ backgroundColor: item.color }} />
              <span className="text-[11px] text-foreground/80">{item.label}</span>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};
