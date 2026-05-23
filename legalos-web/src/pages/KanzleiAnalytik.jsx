
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { TrendingUp, AlertTriangle, Users, FileText, RefreshCw, Trophy, Timer } from "lucide-react";
import { useJurisdiction } from "../hooks/useJurisdiction";
import { getT, getTByLanguage } from "../lib/jurisdictionConfig";
import { useUserProfile } from "../hooks/useUserProfile";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend, LineChart, Line, Area, AreaChart, ReferenceLine,
} from "recharts";
import FallAnalyseModal from "../components/dashboard/FallAnalyseModal";
import AkteureAnalytik from "../components/lexara/AkteureAnalytik";
import KonzernRechtsgebietDashboard from "../components/lexara/KonzernRechtsgebietDashboard";

const SF = { fontFamily: "-apple-system, 'SF Pro Display', 'Helvetica Neue', Arial, sans-serif" };
// SwiftUI-aligned monochrome palette — graphs still distinguishable
const APPLE_COLORS = ["#0A84FF","#1DB954","#636366","#8E8E93","#3A3A3C","#48484A","#30D158","#0071E3"];

// ── SwiftUI-style card ────────────────────────────────────────────────────────
function AppleCard({ title, children, style = {} }) {
  return (
    <div style={{
      background: "#FFFFFF",
      borderRadius: 20,
      border: "1px solid rgba(0,0,0,0.07)",
      boxShadow: "0 2px 16px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)",
      overflow: "hidden",
      ...style,
    }}>
      {title && (
        <div style={{ padding: "20px 24px 0" }}>
          <p style={{ fontSize: 10.5, fontWeight: 700, color: "#AEAEB2", textTransform: "uppercase", letterSpacing: "0.09em" }}>{title}</p>
        </div>
      )}
      <div style={{ padding: title ? "14px 24px 24px" : "24px" }}>
        {children}
      </div>
    </div>
  );
}

// ── KPI card ──────────────────────────────────────────────────────────────────
function KpiCard({ icon: Icon, label, value, sub, iconBg, iconColor }) {
  return (
    <AppleCard>
      <div style={{ marginBottom: 16 }}>
        <div style={{ width: 42, height: 42, borderRadius: 13, background: iconBg || "rgba(0,0,0,0.05)", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Icon style={{ width: 20, height: 20, color: iconColor || "#8E8E93" }} />
        </div>
      </div>
      <p style={{ fontSize: 32, fontWeight: 700, color: "#1C1C1E", letterSpacing: "-0.04em", lineHeight: 1 }}>{value}</p>
      <p style={{ fontSize: 10.5, fontWeight: 700, color: "#AEAEB2", marginTop: 7, textTransform: "uppercase", letterSpacing: "0.08em" }}>{label}</p>
      {sub && <p style={{ fontSize: 11, color: "#C7C7CC", marginTop: 4 }}>{sub}</p>}
    </AppleCard>
  );
}

// ── Erfolgsrate Gauge ─────────────────────────────────────────────────────────
function ErfolgsrateGauge({ rate }) {
  const r = 70, circ = 2 * Math.PI * r;
  const half = circ / 2;
  const offset = half - (rate / 100) * half;
  const color = rate >= 65 ? "#1DB954" : rate >= 40 ? "#636366" : "#B81C3A";
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
      <svg width={180} height={110} viewBox="0 0 180 110">
        <path d={`M 20 95 A ${r} ${r} 0 0 1 160 95`} fill="none" stroke="rgba(0,0,0,0.06)" strokeWidth={12} strokeLinecap="round" />
        <path d={`M 20 95 A ${r} ${r} 0 0 1 160 95`} fill="none" stroke={color} strokeWidth={12} strokeLinecap="round"
          strokeDasharray={half} strokeDashoffset={offset} style={{ transition: "stroke-dashoffset 0.8s cubic-bezier(0.4,0,0.2,1)" }} />
        <text x="90" y="84" textAnchor="middle" fontSize="27" fontWeight="700" fill="#1C1C1E" fontFamily="-apple-system" letterSpacing="-2">{rate}%</text>
        <text x="90" y="103" textAnchor="middle" fontSize="10" fill="#AEAEB2" fontFamily="-apple-system" letterSpacing="0.5">Ø ERFOLGSRATE</text>
      </svg>
      <div style={{ display: "flex", gap: 18 }}>
        {[["≥65% Hoch","#1DB954"],["≥40% Mittel","#636366"],["Niedrig","#B81C3A"]].map(([l,c]) => (
          <div key={l} style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%", background: c }} />
            <span style={{ fontSize: 10, color: "#AEAEB2" }}>{l}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function KanzleiAnalytik() {
  const [cases, setCases] = useState([]);
  const [deadlines, setDeadlines] = useState([]);
  const [arguments_, setArguments] = useState([]);
  const [questionnaires, setQuestionnaires] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [filterLabel, setFilterLabel] = useState(null);
  const [filteredCases, setFilteredCases] = useState([]);
  const { jurisdiction } = useJurisdiction();
  const { language } = useUserProfile();
  const t = language === "EN" || language === "FR" ? getTByLanguage(language) : getT(jurisdiction);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    setLoading(true);
    const [cs, dl, args, qs] = await Promise.all([
      base44.entities.Case.list(),
      base44.entities.Deadline.list(),
      base44.entities.Argument.list(),
      base44.entities.CaseQuestionnaire.list().catch(() => []),
    ]);
    setCases(cs || []);
    setDeadlines(dl || []);
    setArguments(args || []);
    setQuestionnaires(qs || []);
    setLoading(false);
  };

  // ── Core metrics ──────────────────────────────────────────────────────────
  const activeCases = cases.filter(c => c.status === "Aktiv").length;
  const closedCases = cases.filter(c => c.status === "Abgeschlossen");
  const openDeadlines = deadlines.filter(d => d.status === "offen").length;
  const overdueDeadlines = deadlines.filter(d => d.status === "offen" && new Date(d.due_date) < new Date()).length;
  const avgPrognose = cases.length
    ? Math.round(cases.filter(c => c.prognose).reduce((a, c) => a + (c.prognose || 0), 0) / (cases.filter(c => c.prognose).length || 1))
    : 0;

  // ── ERFOLGSRATE: aus abgeschlossenen Fällen + Fragebögen ──────────────────
  // Basis: Prognose der abgeschlossenen Fälle >= 50 = "gewonnen"
  const gewonnenCases = closedCases.filter(c => (c.prognose || 0) >= 50).length;
  const erfolgsrate = closedCases.length > 0 ? Math.round((gewonnenCases / closedCases.length) * 100) : avgPrognose;

  // Ergänze mit Fragebögen wenn vorhanden
  const qGewonnen = questionnaires.filter(q => q.ziel_erreicht
