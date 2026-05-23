
/**
 * SubstanzDiagramme.jsx — Stärken-Analyse Visualisierung
 * Zeigt Argumente & Beweise als interaktive Recharts-Diagramme
 * Eingebunden in TabSimulationCockpit (Reiter 7, Sub-Tab 5)
 */

import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import {
  RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis,
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  Cell, Legend, LabelList
} from "recharts";
import { Scale, Shield, TrendingUp, AlertTriangle } from "lucide-react";

const MATTE_COLORS = {
  eigen:    "#4F86C6",   // gedämpftes Blau
  gegner:   "#C0666A",   // gedämpftes Rot/Korall
  ki:       "#5BAA7D",   // gedämpftes Grün
  manual:   "#B07CC6",   // gedämpftes Violett
  neutral:  "#8FA4B0",   // Grau-Blau
};

const STRENGTH_COLORS = [
  "#4F86C6","#5BAA7D","#B07CC6","#C09A3A","#C0666A",
  "#6AABB5","#8F7BC6","#5A9E8A","#C0804F","#6080C0",
];

function StatChip({ label, value, color }) {
  return (
    <div className="flex flex-col items-center px-4 py-3 rounded-xl"
      style={{ background: `${color}18`, border: `1px solid ${color}55` }}>
      <span className="text-lg font-bold" style={{ color }}>{value}</span>
      <span className="text-[10px] text-gray-500 mt-0.5 text-center leading-tight">{label}</span>
    </div>
  );
}

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white/95 border rounded-xl px-3 py-2 shadow-lg text-xs"
      style={{ borderColor: "rgba(0,0,0,0.1)" }}>
      <p className="font-semibold text-gray-800 mb-1">{label}</p>
      {payload.map((p, i) => (
        <div key={i} className="flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full" style={{ background: p.color }} />
          <span className="text-gray-500">{p.name}:</span>
          <span className="font-semibold text-gray-800">{p.value}/10</span>
        </div>
      ))}
    </div>
  );
};

export default function SubstanzDiagramme({ caseId }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState("bar"); // bar | radar | scatter

  useEffect(() => {
    (async () => {
      setLoading(true);
      const [a, e] = await Promise.all([
        base44.entities.Argument.filter({ case_id: caseId }),
        base44.entities.Evidence.filter({ case_id: caseId }),
      ]);
      setArgs(a);
      setEvidence(e);
      setLoading(false);
    })();
  }, [caseId]);

  if (loading) return (
    <div className="flex items-center justify-center py-16 text-gray-400 text-sm gap-2">
      <div className="w-4 h-4 border-2 border-gray-300 border-t-blue-400 rounded-full animate-spin" />
      Lade Analyse…
    </div>
  );

  // ── Stats ──────────────────────────────────────────────────────────────────
  const eigenArgs   = args.filter(a => a.side === "eigen");
  const gegnerArgs  = args.filter(a => a.side === "gegner");
  const avgEigen    = eigenArgs.length ? (eigenArgs.reduce((s, a) => s + (a.ki_strength ?? a.strength ?? 5), 0) / eigenArgs.length).toFixed(1) : "–";
  const avgGegner   = gegnerArgs.length ? (gegnerArgs.reduce((s, a) => s + (a.ki_strength ?? a.strength ?? 5), 0) / gegnerArgs.length).toFixed(1) : "–";
  const avgEvidence = evidence.length ? (evidence.reduce((s, e) => s + (e.ki_weight ?? e.weight ?? 5), 0) / evidence.length).toFixed(1) : "–";
  const widersprueche = args.filter(a => a.is_contradiction).length;

  // ── Bar-Chart Daten: Argumente ─────────────────────────────────────────────
  const argBarData = args.slice(0, 12).map(a => ({
    name: a.title?.length > 18 ? a.title.slice(0, 18) + "…" : (a.title || "–"),
    Manuell: a.strength ?? 5,
    KI:      a.ki_strength ?? null,
    side:    a.side,
  }));

  // ── Bar-Chart Daten: Beweise ───────────────────────────────────────────────
  const evBarData = evidence.slice(0, 10).map(e => ({
    name:    e.title?.length > 18 ? e.title.slice(0, 18) + "…" : (e.title || "–"),
    Manuell: e.weight ?? 5,
    KI:      e.ki_weight ?? null,
  }));

  // ── Radar: Typen-Durchschnitt ──────────────────────────────────────────────
  const typeMap = {};
  args.forEach(a => {
    const t = a.type || "Sonstig";
    if (!typeMap[t]) typeMap[t] = { count: 0, total: 0 };
    typeMap[t].count++;
    typeMap[t].total += (a.ki_strength ?? a.strength ?? 5);
  });
  const radarData = Object.entries(typeMap).map(([type, d]) => ({
    subject: type.length > 14 ? type.slice(0, 14) + "…" : type,
    Stärke:  +(d.total / d.count).toFixed(1),
  }));

  // ── Scatter: Manuell vs KI ─────────────────────────────────────────────────
  const discrepancyData = args
    .filter(a => a.ki_strength !== undefined && a.ki_strength !== null)
    .map(a => ({
      name: a.title?.slice(0, 20) || "–",
      manuell: a.strength ?? 5,
      ki:      a.ki_strength,
      diff:    Math.abs((a.strength ?? 5) - a.ki_strength),
      side:    a.side,
    }))
    .sort((a, b) => b.diff - a.diff)
    .slice(0, 10);

  const VIEWS = [
    { id: "bar",        label: "Stärken-Balken" },
    { id: "radar",      label: "Typen-Radar" },
    { id: "discrepancy",label: "KI-Abweichung" },
  ];

  return (
    <div className="space-y-5">
      {/* ── KPI-Chips ── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatChip label="Ø eigene Argumente" value={avgEigen}   color={MATTE_COLORS.eigen} />
        <StatChip label="Ø Gegner-Argumente" value={avgGegner}  color={MATTE_COLORS.gegner} />
        <StatChip label="Ø Beweis-Gewicht"   value={avgEvidence} color={MATTE_COLORS.ki} />
        <StatChip label="Widersprüche"        value={widersprueche} color={MATTE_COLORS.neutral} />
      </div>

      {/* ── View Switcher ── */}
      <div className="flex gap-2 flex-wrap">
        {VIEWS.map(v => (
          <button key={v.id} onClick={() => setView(v.id)}
            className="no-override px-3 py-1.5 text-xs font-semibold rounded-lg transition-all"
            style={{
              background: view
