
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  Cell, Legend, ScatterChart, Scatter, ZAxis, ReferenceLine
} from "recharts";
import { Users, TrendingUp, Award, AlertTriangle } from "lucide-react";

const KAT_COLORS = {
  Richter: "#1a3560",
  Anwalt: "#3b82f6",
  Kanzlei: "#8b5cf6",
  Zeuge: "#f59e0b",
  Sachverstaendiger: "#10b981",
  Partei: "#ef4444",
  Sonstiges: "#94a3b8",
};

const KATEGORIEN = ["Alle", "Richter", "Anwalt", "Kanzlei", "Sachverstaendiger", "Partei"];

function MiniLabel({ value }) {
  const color = value >= 60 ? "text-green-600" : value >= 40 ? "text-amber-600" : "text-red-600";
  return <span className={`text-[10px] font-bold ${color}`}>{value}%</span>;
}

const CustomBarTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0].payload;
  return (
    <div className="bg-white border border-slate-200 rounded-xl shadow-lg p-3 text-xs">
      <p className="font-bold text-slate-900 mb-1">{d.name}</p>
      <p className="text-slate-500">{d.kategorie}</p>
      {d.klaeger_rate !== undefined && <p className="text-blue-600 mt-1">Klägerquote: <strong>{d.klaeger_rate}%</strong></p>}
      {d.vergleich_rate !== undefined && <p className="text-violet-600">Vergleichsrate: <strong>{d.vergleich_rate}%</strong></p>}
      {d.urteile_gesamt > 0 && <p className="text-slate-400">{d.urteile_gesamt} Urteile</p>}
    </div>
  );
};

export default function AkteureAnalytik() {
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [katFilter, setKatFilter] = useState("Alle");
  const [sortBy, setSortBy] = useState("klaeger_rate");

  useEffect(() => {
    base44.entities.JudgeProfile.list().then(data => {
      setProfiles(data || []);
      setLoading(false);
    });
  }, []);

  const filtered = profiles
    .filter(p => katFilter === "Alle" || (p.kategorie || "Richter")
