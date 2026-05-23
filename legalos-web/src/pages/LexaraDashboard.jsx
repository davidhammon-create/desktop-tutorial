
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Search, Plus, X, Scale, TrendingUp, Clock, AlertCircle, LogIn, Folder } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/lib/AuthContext";
import FolderOrganizer, { AssignFolderDropdown } from "@/components/lexara/FolderOrganizer";

/* ── Design tokens (SwiftUI / Apple HIG) ─────────── */
const C = {
  bg:          "#F2F2F7",
  card:        "#FFFFFF",
  cardSecond:  "#F9F9F9",
  separator:   "rgba(0,0,0,0.08)",
  label:       "#1C1C1E",
  label2:      "#636366",
  label3:      "#AEAEB2",
  emerald:     "#1DB954",
  emeraldDim:  "rgba(29,185,84,0.10)",
  emeraldText: "#166F38",
  ocean:       "#0A84FF",
  bordeaux:    "#B81C3A",
  bordeauxDim: "rgba(184,28,58,0.09)",
  shadowSm:    "0 1px 4px rgba(0,0,0,0.07), 0 1px 2px rgba(0,0,0,0.04)",
  shadow:      "0 4px 20px rgba(0,0,0,0.07), 0 1px 5px rgba(0,0,0,0.05)",
};
const SF = { fontFamily: "-apple-system,'SF Pro Text','Helvetica Neue',Arial,sans-serif" };

/* ── Prognose arc ─────────────────────────────────── */
function PrognoseArc({ value = 0 }) {
  const color = value >= 65 ? C.emerald : value >= 40 ? "#FF9500" : C.bordeaux;
  const r = 15, circ = 2 * Math.PI * r, offset = circ - (value / 100) * circ;
  return (
    <div style={{ position:"relative", width:38, height:38, display:"flex", alignItems:"center", justifyContent:"center" }}>
      <svg width="38" height="38" style={{ transform:"rotate(-90deg)", position:"absolute", inset:0 }}>
        <circle cx="19" cy="19" r={r} fill="none" stroke="rgba(0,0,0,0.07)" strokeWidth="3" />
        <circle cx="19" cy="19" r={r} fill="none" stroke={color} strokeWidth="3"
          strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"
          style={{ transition:"stroke-dashoffset 0.5s ease" }} />
      </svg>
      <span style={{ position:"relative", fontSize:9, fontWeight:700, color }}>{Math.round(value)}</span>
    </div>
  );
}

/* ── Case card ────────────────────────────────────── */
function CaseCard({ caseData, counts, folders, onReload }) {
  const navigate = useNavigate();
  const total = 9;
  const done = [caseData.fallname, caseData.gericht, caseData.zentrale_rechtsfrage,
    counts.args > 0, counts.evidence > 0, counts.persons > 0,
    counts.deadlines > 0, caseData.prognose, caseData.streitwert].filter(Boolean).length;
  const pct = Math.round((done / total) * 100);
  const progColor = (caseData.prognose||0) >= 65 ? C.emerald : (caseData.prognose||0) >= 40 ? "#FF9500" : C.bordeaux;

  const statusStyle = {
    Aktiv:         { bg: C.emeraldDim, color: C.emeraldText },
    Vorbereitung:  { bg: "rgba(10,132,255,0.09)", color: "#0A5FC4" },
    Abgeschlossen: { bg: "rgba(0,0,0,0.05)", color: C.label2 },
    Ruhend:        { bg: "rgba(255,149,0,0.09)", color: "#BF7200" },
  }[caseData.status] || { bg: "rgba(0,0,0,0.05)", color: C.label2 };

  return (
    <div
      onClick={() => navigate(`/lexara/case?id=${caseData.id}`)}
      style={{
        background: C.card,
        border: `1px solid ${C.separator}`,
        borderRadius: 18,
        boxShadow: C.shadowSm,
        cursor: "pointer",
        transition: "box-shadow 0.18s, transform 0.18s, border-color 0.18s",
        display: "flex", flexDirection: "column",
        ...SF,
      }}
      onMouseEnter={e => {
        e.currentTarget.style.boxShadow = C.shadow;
        e.currentTarget.style.borderColor = "rgba(29,185,84,0.28)";
        e.currentTarget.style.transform = "translateY(-2px)";
      }}
      onMouseLeave={e => {
        e.currentTarget.style.boxShadow = C.shadowSm;
        e.currentTarget.style.borderColor = C.separator;
        e.currentTarget.style.transform = "none";
      }}
    >
      {/* Header */}
      <div style={{ padding:"18px 20px 14px", display:"flex", alignItems:"flex-start", justifyContent:"space-between", gap:12 }}>
        <div style={{ flex:1, minWidth:0 }}>
          {caseData.aktenzeichen && (
            <p style={{ fontFamily:"'SF Mono',Menlo,monospace", fontSize:9.5, color:C.label3, letterSpacing:"0.04em", marginBottom:4 }}>
              {caseData.aktenzeichen}
            </p>
          )}
          <h3 style={{ fontSize:13.5, fontWeight:600, color:C.label, lineHeight:1.35, marginBottom:8 }}>
            {caseData.fallname}
          </h3>
          <div style={{ display:"flex", flexWrap:"wrap", gap:5 }}>
            {caseData.status && (
              <span style={{ fontSize:10.5, fontWeight:600, padding:"2px 8px", borderRadius:6, background:statusStyle.bg, color:statusStyle.color }}>
                {caseData.status}
              </span>
            )}
            {caseData.rechtsgebiet && (
              <span style={{ fontSize:10.5, padding:"2px 8px", borderRadius:6, background:"rgba(0,0,0,0.04)", color:C.label2 }}>
                {caseData.rechtsgebiet}
              </span>
            )}
            {caseData.instanz && caseData.instanz !== "Erstinstanz" && (
              <span style={{ fontSize:10.5, padding:"2px 8px", borderRadius:6, background:"rgba(0,0,0,0.04)", color:C.label2 }}>
                {caseData.instanz}
              </span>
            )}
          </div>
        </div>
        <div style={{ flexShrink:0, textAlign:"right" }}>
          <p style={{ fontSize:22, fontWeight:700, color:progColor, lineHeight:1, letterSpacing:"-0.03em" }}>{Math.round(caseData.prognose||0)}%</p>
          <p style={{ fontSize:9, color:C.label3, marginTop:2 }}>Prognose</p>
        </div>
      </div>

      {/* Progress */}
      <div style={{ paddingInline:20, paddingBottom:14 }}>
        <div style={{ display:"flex", justifyContent:"space-between", marginBottom:5 }}>
          <span style={{ fontSize:10, color:C.label3 }}>Vollständigkeit</span>
          <span style={{ fontSize:10, fontWeight:600, color:C.label2 }}>{pct}%</span>
        </div>
        <div style={{ height:4, background:"rgba(0,0,0,0.06)", borderRadius:99, overflow:"hidden" }}>
          <div style={{
            height:"100%", borderRadius:99,
            width:`${pct}%`,
            background: pct >= 80 ? C.emerald : pct >= 50 ? "#FF9500" : "rgba(0,0,0,0.15)",
            transition:"width 0.35s ease",
          }} />
        </div>
      </div>

      {/* Stats */}
      <div style={{
        display:"grid", gridTemplateColumns:"repeat(4,1fr)",
        borderTop:`1px solid ${C.separator}`,
        paddingBlock:12,
      }}>
        {[["Argum.", counts.args], ["Beweise", counts.evidence], ["Personen", counts.persons], ["Fristen", counts.deadlines]].map(([l, v]) => (
          <div key={l} style={{ textAlign:"center" }}>
            <p style={{ fontSize:15, fontWeight:700, color:C.label, lineHeight:1 }}>{v}</p>
            <p style={{ fontSize:9.5, color:C.label3, marginTop:3 }}>{l}</p>
          </div>
        ))}
      </div>

      {/* Ordner-Zuordnung */}
      <div style={{ paddingInline:16, paddingBottom:12, borderTop:`1px solid ${C.separator}`, paddingTop:10 }}
        onClick={e => e.stopPropagation()}>
        <AssignFolderDropdown
          caseId={caseData.id}
          currentFolderId={caseData.folder_id}
          folders={folders}
          onAssigned={onReload}
        />
      </div>
    </div>
  );
}

/* ── KPI chip ─────────────────────────────────────── */
function KpiChip({ icon: Icon, label, value, accent }) {
  return (
    <div style={{
      background: C.card,
      border:`1px solid ${C.separator}`,
      borderRadius:16,
      padding:"16px 18px",
      display:"flex", alignItems:"center", gap:14,
      boxShadow: C.shadowSm,
    }}>
      <div style={{
        width:40, height:40, borderRadius:12,
        background: accent ? `${accent}14` : "rgba(0,0,0,0.05)",
        display:"flex", alignItems:"center", justifyContent:"center",
        flexShrink:0,
      }}>
        <Icon style={{ width:18, height:18, color: accent || C.label3 }} />
      </div>
      <div>
        <p style={{ fontSize:22, fontWeight:700, color:C.label, lineHeight:1, letterSpacing:"-0.03em" }}>{value}</p>
        <p style={{ fontSize:10.5, color:C.label3, marginTop:4 }}>{label}</p>
      </div>
    </div>
  );
}

/* ── Main ─────────────────────────────────────────── */
export default function LexaraDashboard() {
  const { isAuthenticated, isLoadingAuth, navigateToLogin } = useAuth();
  const [cases, setCases]         = useState([]);
  const [search, setSearch]       = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [loading, setLoading]     = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newCase, setNewCase]     = useState({ fallname:"", aktenzeichen:"", rechtsgebiet:"", status:"Aktiv", instanz:"Erstinstanz" });
  const [caseCounts, setCaseCounts] = useState({});
  const [creating, setCreating]   = useState(false);
  const [folders, setFolders]     = useState([]);
  const [selectedFolder, setSelectedFolder] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => { if (isAuthenticated) loadData(); }, [isAuthenticated]);

  const loadData = async () => {
    setLoading(true);
    try {
      const [cs, args, evs, pers, deadlines, folds] = await Promise.all([
        base44.entities.Case.list("-created_date").catch(() => []),
        base44.entities.Argument.filter({}).catch(() => []),
        base44.entities.Evidence.filter({}).catch(() => []),
        base44.entities.Person.filter({}).catch(() => []),
        base44.entities.Deadline.filter({}).catch(() => []),
        base44.entities.CaseFolder.list("-created_date").catch(() => []),
      ]);
      setCases(cs);
      setFolders(folds);
      const counts = {};
      cs.forEach(c => {
        counts[c.id] = {
          args:      args.filter(a => a.case_id
