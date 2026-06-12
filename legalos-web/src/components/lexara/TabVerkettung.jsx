
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Plus, X, Sparkles, RefreshCw, Pencil, Check, Network, BarChart3, GitBranch } from "lucide-react";
import ArgumentGraphiOS from "./ArgumentGraphiOS";
import ArgumentZeitstrahlChart from "./ArgumentZeitstrahlChart";
import ArgumentationskettenVisualisierung from "./ArgumentationskettenVisualisierung";
import { Button } from "@/components/ui/button";

const CONN_TYPES = ["stützt", "entkräftet", "schließt aus", "kausal", "widerspricht", "schwächt", "verstärkt"];
const COLORS = {
  "stützt": "text-green-600 border-green-300 bg-green-50",
  "entkräftet": "text-red-500 border-red-300 bg-red-50",
  "schließt aus": "text-gray-600 border-gray-300 bg-gray-50",
  "kausal": "text-blue-500 border-blue-300 bg-blue-50",
  "widerspricht": "text-orange-500 border-orange-300 bg-orange-50",
  "schwächt": "text-amber-500 border-amber-300 bg-amber-50",
  "verstärkt": "text-emerald-600 border-emerald-300 bg-emerald-50",
};

export default function TabVerkettung({ caseId }) {
  const [args, setArgs] = useState([]);
  const [deadlines, setDeadlines] = useState([]);
  const [showAddConn, setShowAddConn] = useState(false);
  const [view, setView] = useState("argumentkette"); // "argumentkette" | "zeitstrahl" | "liste" | "graph"
  const [newConn, setNewConn] = useState({ from: "", to: "", type: "stützt", explanation: "", intensitaet: 5 });
  const [editConn, setEditConn] = useState(null); // { fromId, toId, type, explanation, intensitaet }
  const [kiAnalyzing, setKiAnalyzing] = useState(false);
  const [kiSuggestions, setKiSuggestions] = useState([]);
  const [showGraph, setShowGraph] = useState(false);

  useEffect(() => { load(); }, [caseId]);

  const load = async () => {
    const [a, dl] = await Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Deadline.filter({ case_id: caseId }),
    ]);
    setArgs(a);
    setDeadlines(dl);
  };

  const addConnection = async () => {
    if (!newConn.from || !newConn.to || newConn.from
