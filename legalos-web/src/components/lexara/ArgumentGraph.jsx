
import { useState, useEffect, useRef, useCallback } from "react";
import { X, ZoomIn, ZoomOut, RefreshCw } from "lucide-react";

const EDGE_COLORS = {
  "stützt": "#16a34a",
  "entkräftet": "#ef4444",
  "schließt aus": "#6b7280",
  "kausal": "#3b82f6",
  "widerspricht": "#f97316",
  "schwächt": "#d97706",
  "verstärkt": "#059669",
};

const EDGE_LABELS = {
  "stützt": "stützt",
  "entkräftet": "entkräftet",
  "schließt aus": "schließt aus",
  "kausal": "kausal",
  "widerspricht": "widerspricht",
  "schwächt": "schwächt",
  "verstärkt": "verstärkt",
};

function useForceLayout(nodes, edges, width, height) {
  const [positions, setPositions] = useState({});
  const animRef = useRef(null);
  const posRef = useRef({});
  const velRef = useRef({});

  const initPositions = useCallback(() => {
    const pos = {};
    const vel = {};
    nodes.forEach((n, i) => {
      const angle = (2 * Math.PI * i) / nodes.length;
      const r = Math.min(width, height) * 0.3;
      pos[n.id] = { x: width / 2 + r * Math.cos(angle), y: height / 2 + r * Math.sin(angle) };
      vel[n.id] = { x: 0, y: 0 };
    });
    posRef.current = pos;
    velRef.current = vel;
    setPositions({ ...pos });
  }, [nodes, width, height]);

  useEffect(() => {
    if (nodes.length
