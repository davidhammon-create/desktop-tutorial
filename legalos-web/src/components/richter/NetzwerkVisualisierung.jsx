
import { useState, useEffect, useRef, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";
import { RefreshCw, ZoomIn, ZoomOut } from "lucide-react";

const KAT_COLOR = {
  Richter: "#1a3560",
  Anwalt: "#3b82f6",
  Kanzlei: "#8b5cf6",
  Zeuge: "#f59e0b",
  Sachverstaendiger: "#10b981",
  Partei: "#ef4444",
  Sonstiges: "#94a3b8",
};
const KAT_ICONS = { Richter: "⚖️", Anwalt: "👔", Kanzlei: "🏛️", Zeuge: "👁️", Sachverstaendiger: "🔬", Partei: "🏢", Sonstiges: "📋" };

export default function NetzwerkVisualisierung({ judges }) {
  const [nodes, setNodes] = useState([]);
  const [edges, setEdges] = useState([]);
  const [loading, setLoading] = useState(false);
  const [zoom, setZoom] = useState(1);
  const svgRef = useRef(null);

  const W = 600;
  const H = 400;

  useEffect(() => {
    if (!judges?.length) return;
    const n = judges.map((j, i) => {
      const angle = (i / judges.length) * 2 * Math.PI;
      const r = Math.min(W, H) * 0.35;
      return {
        id: j.id,
        label: j.name || "Richter",
        kat: "Richter",
        x: W / 2 + r * Math.cos(angle),
        y: H / 2 + r * Math.sin(angle),
        data: j,
      };
    });
    setNodes(n);

    // Create edges between judges at same court
    const e = [];
    for (let i = 0; i < n.length; i++) {
      for (let j = i + 1; j < n.length; j++) {
        if (n[i].data?.gericht && n[i].data.gericht === n[j].data?.gericht) {
          e.push({ from: n[i].id, to: n[j].id, label: "gleiches Gericht" });
        }
      }
    }
    setEdges(e);
  }, [judges]);

  const [selected, setSelected] = useState(null);
  const selectedNode = nodes.find(n => n.id === selected);

  if (!judges?.length) return (
    <div className="flex items-center justify-center py-10 text-gray-400">
      <p className="text-sm">Keine Richter für Netzwerkanalyse vorhanden</p>
    </div>
  );

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <p className="text-sm font-semibold text-gray-700">🕸️ Richter-Netzwerk</p>
        <div className="flex gap-1">
          <Button size="sm" variant="outline" onClick={() => setZoom(z => Math.min(2, z + 0.2))} className="text-xs px-2"><ZoomIn className="w-3 h-3" /></Button>
          <Button size="sm" variant="outline" onClick={() => setZoom(z => Math.max(0.5, z - 0.2))} className="text-xs px-2"><ZoomOut className="w-3 h-3" /></Button>
          <Button size="sm" variant="outline" onClick={() => { setZoom(1); setSelected(null); }} className="text-xs px-2"><RefreshCw className="w-3 h-3" /></Button>
        </div>
      </div>

      <div className="bg-white border border-gray-100 rounded-xl overflow-hidden" style={{ height: 320 }}>
        <svg ref={svgRef} width="100%" height="100%" viewBox={`0 0 ${W} ${H}`} style={{ transform: `scale(${zoom})`, transformOrigin: "center" }}>
          {/* Edges */}
          {edges.map((e, i) => {
            const from = nodes.find(n => n.id === e.from);
            const to = nodes.find(n => n.id === e.to);
            if (!from || !to) return null;
            return (
              <line key={i} x1={from.x} y1={from.y} x2={to.x} y2={to.y}
                stroke="rgba(0,0,0,0.1)" strokeWidth={1.5} strokeDasharray="4 3" />
            );
          })}
          {/* Nodes */}
          {nodes.map(n => {
            const color = KAT_COLOR[n.kat] || "#94a3b8";
            const isSelected = selected === n.id;
            return (
              <g key={n.id} onClick={() => setSelected(isSelected ? null : n.id)} style={{ cursor: "pointer" }}>
                <circle cx={n.x} cy={n.y} r={isSelected ? 26 : 20}
                  fill={isSelected ? color : `${color}20`}
                  stroke={color}
                  strokeWidth={isSelected ? 3 : 1.5} />
                <text x={n.x} y={n.y + 4} textAnchor="middle" fontSize="12" fill={isSelected ? "#fff" : color}>
                  {KAT_ICONS[n.kat] || "⚖️"}
                </text>
                <text x={n.x} y={n.y + (isSelected ? 40 : 34)} textAnchor="middle" fontSize="9" fill="#555">
                  {n.label.length > 12 ? n.label.slice(0, 11) + "…" : n.label}
                </text>
              </g>
            );
          })}
        </svg>
      </div>

      {selectedNode && (
        <div className="bg-white border border-gray-100 rounded-xl p-4">
          <p className="text-sm font-semibold text-gray-900">{selectedNode.label}</p>
          <div className="grid grid-cols-3 gap-2 mt-2">
            {[
              ["Kläger-Rate", `${selectedNode.data?.klaeger_rate || 0}%`],
              ["Vergleiche", `${selectedNode.data?.vergleich_rate || 0}%`],
              ["Ø Dauer", `${selectedNode.data?.dauer_monate || "—"} Mo.`],
            ].map(([l, v]) => (
              <div key={l} className="text-center bg-gray-50 rounded-lg p-2">
                <p className="text-[10px] text-gray-400">{l}</p>
                <p className="text-sm font-bold text-gray-800">{v}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
