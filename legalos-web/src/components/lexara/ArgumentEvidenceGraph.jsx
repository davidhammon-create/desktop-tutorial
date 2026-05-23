
import { useState, useRef, useEffect, useCallback } from "react";

const NODE_R = 28;
const COLORS = {
  eigen: { fill: "#16a34a", stroke: "#14532d", text: "#fff", light: "#dcfce7" },
  gegner: { fill: "#dc2626", stroke: "#7f1d1d", text: "#fff", light: "#fee2e2" },
  evidence: { fill: "#2563eb", stroke: "#1e3a8a", text: "#fff", light: "#dbeafe" },
};

function layout(eigenArgs, gegnerArgs, evidence) {
  const nodes = [];
  const links = [];

  // Place eigen args on left arc, gegner on right arc
  const placeArc = (list, cx, cy, r, color) => {
    list.forEach((arg, i) => {
      const angle = (Math.PI / (list.length + 1)) * (i + 1) - Math.PI / 2;
      nodes.push({
        id: arg.id,
        label: arg.title?.slice(0, 18) || "?",
        fullLabel: arg.title || "?",
        type: "argument",
        side: arg.side,
        strength: arg.strength || 5,
        color,
        x: cx + r * Math.cos(angle),
        y: cy + r * Math.sin(angle),
      });
    });
  };

  placeArc(eigenArgs, 220, 300, 160, COLORS.eigen);
  placeArc(gegnerArgs, 580, 300, 160, COLORS.gegner);

  // Place evidence nodes near their parent argument
  const argMap = {};
  nodes.forEach((n) => (argMap[n.id] = n));

  evidence.forEach((ev, i) => {
    const parent = argMap[ev.argument_id];
    if (!parent) return;
    const angle = (Math.PI * 2 * i) / Math.max(evidence.length, 1);
    const ex = parent.x + Math.cos(angle) * 70;
    const ey = parent.y + Math.sin(angle) * 70;
    nodes.push({
      id: `ev_${ev.id}`,
      label: ev.title?.slice(0, 14) || "Beweis",
      fullLabel: ev.title || "Beweis",
      type: "evidence",
      weight: ev.weight || 5,
      color: COLORS.evidence,
      x: ex,
      y: ey,
    });
    links.push({ source: parent.id, target: `ev_${ev.id}`, weight: ev.weight || 5 });
  });

  // Cross-links: arguments with same paragraph or connected via evidence
  eigenArgs.forEach((ea) => {
    gegnerArgs.forEach((ga) => {
      if (ea.is_contradiction || ga.is_contradiction) {
        links.push({ source: ea.id, target: ga.id, weight: 3, contradiction: true });
      }
    });
  });

  return { nodes, links };
}

export default function ArgumentEvidenceGraph({ args, evidence }) {
  const svgRef = useRef(null);
  const [positions, setPositions] = useState({});
  const [dragging, setDragging] = useState(null);
  const [hovered, setHovered] = useState(null);
  const [offset, setOffset] = useState({ x: 0, y: 0 });

  const eigenArgs = args.filter((a) => a.side === "eigen");
  const gegnerArgs = args.filter((a) => a.side === "gegner");
  const { nodes, links } = layout(eigenArgs, gegnerArgs, evidence);

  // Init positions
  useEffect(() => {
    const pos = {};
    nodes.forEach((n) => { pos[n.id] = { x: n.x, y: n.y }; });
    setPositions(pos);
  }, [args, evidence]);

  const getPos = (id) => positions[id] || { x: 0, y: 0 };

  const onMouseDown = useCallback((e, id) => {
    e.preventDefault();
    const svg = svgRef.current;
    const pt = svg.createSVGPoint();
    pt.x = e.clientX; pt.y = e.clientY;
    const svgP = pt.matrixTransform(svg.getScreenCTM().inverse());
    const pos = positions[id] || { x: 0, y: 0 };
    setDragging(id);
    setOffset({ x: svgP.x - pos.x, y: svgP.y - pos.y });
  }, [positions]);

  const onMouseMove = useCallback((e) => {
    if (!dragging) return;
    const svg = svgRef.current;
    const pt = svg.createSVGPoint();
    pt.x = e.clientX; pt.y = e.clientY;
    const svgP = pt.matrixTransform(svg.getScreenCTM().inverse());
    setPositions((prev) => ({ ...prev, [dragging]: { x: svgP.x - offset.x, y: svgP.y - offset.y } }));
  }, [dragging, offset]);

  const onMouseUp = useCallback(() => setDragging(null), []);

  if (nodes.length
