
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
        const q = questionnaires.find(q => q.case_id === c.id);
        if (q?.tatsaechliche_dauer) map[rg].dauerArr.push(q.tatsaechliche_dauer);
      }
      map[rg].sumPrognose += c.prognose || 0;
      map[rg].sumStreitwert += c.streitwert || 0;
    });
    return Object.values(map).map(d => ({
      ...d,
      avgPrognose: d.total ? Math.round(d.sumPrognose / d.total) : 0,
      avgStreitwert: d.total ? Math.round(d.sumStreitwert / d.total) : 0,
      winRate: d.abgeschlossen ? Math.round((d.won / d.abgeschlossen) * 100) : 0,
      avgDauer: d.dauerArr.length ? Math.round(d.dauerArr.reduce((a, b) => a + b, 0) / d.dauerArr.length) : 0,
    })).sort((a, b) => b.total - a.total);
  }, [cases, questionnaires]);

  if (!rgData.length) {
    return (
      <div className="text-center py-12 text-gray-400">
        <p className="text-sm">Keine Rechtsgebietsdaten vorhanden</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h3 className="text-sm font-semibold text-gray-800">📊 Konzern-Rechtsgebiet-Dashboard</h3>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        {rgData.slice(0, 8).map(d => (
          <div key={d.name} className="bg-white border border-gray-100 rounded-xl p-3">
            <p className="text-xs font-semibold text-gray-700 truncate">{d.name}</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{d.total}</p>
            <div className="flex gap-2 mt-1">
              <span className="text-[10px] text-blue-500">{d.aktiv} aktiv</span>
              <span className="text-[10px] text-green-500">{d.winRate}% Win</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
}
