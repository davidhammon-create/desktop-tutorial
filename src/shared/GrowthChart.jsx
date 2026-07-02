import React, { useMemo } from "react";
import { T } from "./tokens";
import { futureValue } from "./format";
import { useReveal } from "./Reveal";

export function GrowthChart({ monthly, ret, years }) {
  const [ref, vis] = useReveal();
  const points = useMemo(() => {
    const pts = [];
    for (let y = 0; y <= years; y++) {
      pts.push({ y, invested: monthly * 12 * y, value: futureValue(monthly, ret, y) });
    }
    return pts;
  }, [monthly, ret, years]);
  const max = points[points.length - 1].value || 1;
  const W = 640, H = 260, P = 10;
  const toXY = (i, v) => [P + (i / years) * (W - 2 * P), H - P - (v / max) * (H - 2 * P)];
  const path = (key) => points.map((p, i) => { const [x, y] = toXY(i, p[key]); return `${i === 0 ? "M" : "L"}${x},${y}`; }).join(" ");
  return (
    <div ref={ref} style={{ width: "100%" }}>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: "100%", height: "auto", display: "block" }}>
        <defs>
          <linearGradient id="gGreen" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={T.green} stopOpacity="0.35" />
            <stop offset="100%" stopColor={T.green} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={`${path("value")} L${W - P},${H - P} L${P},${H - P} Z`} fill="url(#gGreen)"
          style={{ opacity: vis ? 1 : 0, transition: "opacity 1.5s ease 0.8s" }} />
        <path d={path("invested")} fill="none" stroke={T.textFaint} strokeWidth="2" strokeDasharray="6 6"
          style={{ strokeDashoffset: vis ? 0 : 1200, strokeDasharray: vis ? "6 6" : "1200", transition: "all 2s ease" }} />
        <path d={path("value")} fill="none" stroke={T.green} strokeWidth="3" strokeLinecap="round"
          pathLength="100"
          style={{ strokeDasharray: 100, strokeDashoffset: vis ? 0 : 100, transition: "stroke-dashoffset 2.2s cubic-bezier(0.6,0,0.2,1) 0.2s" }} />
      </svg>
      <div style={{ display: "flex", gap: 24, marginTop: 8, fontSize: 13, color: T.textDim }}>
        <span><span style={{ color: T.green }}>—</span> Vermögen mit Zinseszins</span>
        <span><span style={{ color: T.textFaint }}>- -</span> Nur eingezahlt</span>
      </div>
    </div>
  );
}

// Overlays several ETFs' growth curves for side-by-side comparison.
export function CompareChart({ series, years }) {
  const [ref, vis] = useReveal();
  const colors = [T.green, T.teal, T.purple, T.orange];
  const allPoints = useMemo(() => series.map((s) => {
    const pts = [];
    for (let y = 0; y <= years; y++) pts.push({ y, value: futureValue(s.monthly, s.ret, y) });
    return pts;
  }), [series, years]);
  const max = Math.max(1, ...allPoints.map((pts) => pts[pts.length - 1].value));
  const W = 640, H = 260, P = 10;
  const toXY = (i, v) => [P + (i / years) * (W - 2 * P), H - P - (v / max) * (H - 2 * P)];
  const pathFor = (pts) => pts.map((p, i) => { const [x, y] = toXY(i, p.value); return `${i === 0 ? "M" : "L"}${x},${y}`; }).join(" ");
  return (
    <div ref={ref} style={{ width: "100%" }}>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: "100%", height: "auto", display: "block" }}>
        {allPoints.map((pts, i) => (
          <path key={i} d={pathFor(pts)} fill="none" stroke={colors[i % colors.length]} strokeWidth="3" strokeLinecap="round"
            pathLength="100"
            style={{ strokeDasharray: 100, strokeDashoffset: vis ? 0 : 100, transition: `stroke-dashoffset 2s cubic-bezier(0.6,0,0.2,1) ${i * 0.15}s` }} />
        ))}
      </svg>
      <div style={{ display: "flex", gap: 20, marginTop: 8, fontSize: 13, color: T.textDim, flexWrap: "wrap" }}>
        {series.map((s, i) => (
          <span key={i}><span style={{ color: colors[i % colors.length] }}>—</span> {s.name}</span>
        ))}
      </div>
    </div>
  );
}
