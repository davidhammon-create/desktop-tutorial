
import { useMemo } from "react";
import {
  RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis,
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, Cell, ScatterChart, Scatter, ZAxis, ReferenceLine, Legend,
} from "recharts";

const SF = { fontFamily: "-apple-system, 'SF Pro Display', 'Helvetica Neue', Arial, sans-serif" };
const APPLE_COLORS = ["#007AFF", "#34C759", "#FF9500", "#5856D6", "#FF3B30", "#AF52DE", "#FF2D55", "#00C7BE"];

function Section({ title, subtitle, children }) {
  return (
    <div style={{
      background: "rgba(255,255,255,0.88)",
      backdropFilter: "blur(20px)",
      borderRadius: 20,
      border: "1px solid rgba(0,0,0,0.06)",
      boxShadow: "0 2px 12px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.04)",
      overflow: "hidden",
      ...SF,
    }}>
      <div style={{ padding: "20px 24px 0" }}>
        <p style={{ fontSize: 11, fontWeight: 700, color: "#aaa", textTransform: "uppercase", letterSpacing: "0.07em" }}>{title}</p>
        {subtitle && <p style={{ fontSize: 12, color: "#bbb", marginTop: 3 }}>{subtitle}</p>}
      </div>
      <div style={{ padding: "16px 24px 22px" }}>{children}</div>
    </div>
  );
}

const tooltipStyle = {
  borderRadius: 12, border: "none",
  boxShadow: "0 4px 20px rgba(0,0,0,0.12)", fontSize: 12, fontFamily: SF.fontFamily,
};

// Custom Radar tick
function RadarTick({ payload, x, y, textAnchor }) {
  return (
    <text x={x} y={y} textAnchor={textAnchor} style={{ fontSize: 10, fill: "#999", fontFamily: SF.fontFamily }}>
      {payload.value.length > 14 ? payload.value.slice(0, 13) + "…" : payload.value}
    </text>
  );
}

export default function KonzernRechtsgebietDashboard({ cases, questionnaires }) {
  const tooltipS = tooltipStyle;

  // ── Daten pro Rechtsgebiet ───────────────────────────────────────────────
  const rgData = useMemo(() => {
    const map = {};
    cases.forEach(c => {
      const rg = c.rechtsgebiet;
      if (!rg) return;
      if (!map[rg]) map[rg] = { name: rg, total: 0, aktiv: 0, abgeschlossen: 0, sumPrognose: 0, sumStreitwert: 0, won: 0, dauerArr: [] };
      map[rg].total++;
      if (c.status === "Aktiv") map[rg].aktiv++;
      if (c.status === "Abgeschlossen") {
        map[rg].abgeschlossen++;
        if ((c.prognose || 0) >= 50) map[rg].won++;
        const q = questionnaires.find(q => q.case_id
