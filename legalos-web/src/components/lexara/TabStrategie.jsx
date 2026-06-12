
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { invokeLLM } from "@/lib/kiProvider";
import ArgumentEvidenceGraph from "./ArgumentEvidenceGraph";
import WasWaereWennSimulation from "./WasWaereWennSimulation";
import TimelineVisualization from "./TimelineVisualization";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar, Legend, RadarChart, PolarGrid, PolarAngleAxis, Radar } from "recharts";
import { Button } from "@/components/ui/button";
import { Info } from "lucide-react";
import { useKIProtokoll } from "@/hooks/useKIProtokoll";

function PrognoseCircle({ value }) {
  const r = 42, circ = 2 * Math.PI * r, offset = circ - (value/100)*circ;
  const color = value>=60?"#16a34a":value>=40?"#d97706":"#dc2626";
  return (
    <div className="relative inline-flex items-center justify-center">
      <svg width="100" height="100" style={{transform:"rotate(-90deg)"}}>
        <circle cx="50" cy="50" r={r} fill="none" stroke="#e5e7eb" strokeWidth="5"/>
        <circle cx="50" cy="50" r={r} fill="none" stroke={color} strokeWidth="5" strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"/>
      </svg>
      <div className="absolute text-center">
        <div className="text-xl font-bold text-gray-900">{Math.round(value)}%</div>
        <div className="text-[10px] text-gray-400">Prognose</div>
      </div>
    </div>
  );
}

export default function TabStrategie({ caseId, caseData, onUpdate, kiMode = true, activeSub = 0 }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [persons, setPersons] = useState([]);
  const [deadlines, setDeadlines] = useState([]);
  const [gegnerVerhalten, setGegnerVerhalten] = useState([]);
  const [sortMode, setSortMode] = useState("staerke");
  const [prognose, setPrognose] = useState(caseData?.prognose || 0);
  const [algorithm, setAlgorithm] = useState({});
  const [saving, setSaving] = useState(false);
  const [chartView, setChartView] = useState("overlap");
  const [showTacticalInfo, setShowTacticalInfo] = useState(false);
  const [kiPrognose, setKiPrognose] = useState(null);
  const [kiPrognoseLoading, setKiPrognoseLoading] = useState(false);
  // activeSub: 0=strategie, 1=simulation, 2=timeline
  const activeView = activeSub
