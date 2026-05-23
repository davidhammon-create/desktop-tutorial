
import { useState, useEffect, useRef, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";
import { RefreshCw, ZoomIn, ZoomOut, Maximize2, Brain } from "lucide-react";

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

function useForceLayout(nodes, edges, width, height) {
  const [positions, setPositions] = useState({});
  const animRef = useRef(null);
  const posRef = useRef({});
  const velRef = useRef({});

  useEffect(() => {
    if (!nodes.length) return;
    // Initialize positions in a circle
    const init = {};
    const vel = {};
    nodes.forEach((n, i) => {
      const angle = (i / nodes.length) * 2 * Math.PI;
      const r = Math.min(width, height) * 0.3;
      init[n.id] = { x: width / 2 + r * Math.cos(angle), y: height / 2 + r * Math.sin(angle) };
      vel[n.id] = { x: 0, y: 0 };
    });
    posRef.current = init;
    velRef.current = vel;

    let iter = 0;
    const simulate = () => {
      if (iter++ > 300) return;
      const pos = posRef.current;
      const vel = velRef.current;
      const newPos = {};

      nodes.forEach(n => {
        let fx = 0, fy = 0;
        const cx = width / 2, cy = height / 2;
        // Center gravity
        fx += (cx - pos[n.id].x) * 0.01;
        fy += (cy - pos[n.id].y) * 0.01;

        // Repulsion between all nodes
        nodes.forEach(m => {
          if (m.id
