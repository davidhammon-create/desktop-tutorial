
import { useState, useEffect, useRef, useCallback } from "react";
import { X, ChevronDown, Zap } from "lucide-react";

const COLORS = {
  "stützt": { edge: "#10B981", bg: "#D1FAE5", label: "stützt", impact: "+" },
  "entkräftet": { edge: "#EF4444", bg: "#FEE2E2", label: "entkräftet", impact: "−" },
  "verstärkt": { edge: "#8B5CF6", bg: "#F3E8FF", label: "verstärkt", impact: "↑" },
  "schwächt": { edge: "#F59E0B", bg: "#FEF3C7", label: "schwächt", impact: "↓" },
  "widerspricht": { edge: "#EC4899", bg: "#FCE7F3", label: "widerspricht", impact: "≠" },
  "schließt aus": { edge: "#06B6D4", bg: "#CFFAFE", label: "schließt aus", impact: "✗" },
  "kausal": { edge: "#3B82F6", bg: "#DBEAFE", label: "kausal", impact: "→" },
};

/**
 * Sankey-ähnliches Diagramm-Layout
 * Eigene Argumente links, Gegner rechts, klare Verbindungen dazwischen
 */
function computeSankeyLayout(nodes, edges, width, height) {
  const positions = {};
  const eigenArgs = nodes.filter(n => n.side === "eigen").sort((a, b) => a.title.localeCompare(b.title));
  const gegnerArgs = nodes.filter(n => n.side === "gegner").sort((a, b) => a.title.localeCompare(b.title));

  const leftX = 80;
  const rightX = width - 80;
  const topY = 60;
  const spacing = Math.max(70, (height - 120) / Math.max(eigenArgs.length, gegnerArgs.length));

  // Left side (eigen)
  eigenArgs.forEach((node, idx) => {
    positions[node.id] = {
      x: leftX,
      y: topY + idx * spacing
    };
  });

  // Right side (gegner)
  gegnerArgs.forEach((node, idx) => {
    positions[node.id] = {
      x: rightX,
      y: topY + idx * spacing
    };
  });

  return positions;
}

export default function ArgumentGraphiOS({ args, onClose }) {
  const containerRef = useRef(null);
  const [dims, setDims] = useState({ w: 800, h: 520 });
  const [selected, setSelected] = useState(null);
  const [zoom, setZoom] = useState(1);
  const [showLegend, setShowLegend] = useState(false);

  useEffect(() => {
    const update = () => {
      if (containerRef.current) {
        const r = containerRef.current.getBoundingClientRect();
        setDims({ w: r.width || 800, h: 520 });
      }
    };
    update();
    window.addEventListener("resize", update);
    return () => window.removeEventListener("resize", update);
  }, []);

  // Build nodes and edges
  const nodes = args.map(a => ({ id: a.id, title: a.title, side: a.side, strength: a.strength || 5 }));
  const edges = [];
  args.forEach(a => {
    (a.connections || []).forEach(c => {
      if (c.targetId) edges.push({ 
        fromId: a.id, 
        toId: c.targetId, 
        type: c.type || "stützt", 
        explanation: c.explanation || "", 
        intensitaet: c.intensitaet ?? 5 
      });
    });
  });

  const positions = computeSankeyLayout(nodes, edges, dims.w, dims.h);

  const selectedEdges = selected ? edges.filter(e => e.fromId
