
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Plus, Edit, Trash2, X, Link, ChevronRight, Network } from "lucide-react";
import { Button } from "@/components/ui/button";
import RichterDetail from "../components/richter/RichterDetail";
import NetzwerkVisualisierung from "../components/richter/NetzwerkVisualisierung";

const STILE = ["Neutral","Kooperativ","Streng","Prozessaktiv","Vergleichsorientiert"];
const KATEGORIEN = ["Richter","Anwalt","Kanzlei","Zeuge","Sachverständiger","Partei","Sonstiges"];
const EMPTY = { name:"", gericht:"", kammer:"", rechtsgebiet:"", kategorie:"Richter", klaeger_rate:50, vergleich_rate:30, durchschnitt_dauer_monate:12, urteile_gesamt:0, stil:"Neutral", bekannt_fuer:"", notizen:"" };
const KAT_ICONS = { Richter:"⚖️", Anwalt:"👔", Kanzlei:"🏛️", Zeuge:"👁️", "Sachverständiger":"🔬", Partei:"🏢", Sonstiges:"📋" };
const STIL_COLOR = { Kooperativ:"bg-green-100 text-green-700", Streng:"bg-red-100 text-red-700", Neutral:"bg-gray-100 text-gray-600", Prozessaktiv:"bg-blue-100 text-blue-700", Vergleichsorientiert:"bg-purple-100 text-purple-700" };

function GaugeBar({ value, max = 100, color = "bg-gray-800" }) {
  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 h-1.5 bg-[#f0f0f0] rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full`} style={{ width: `${Math.min((value / max) * 100, 100)}%` }} />
      </div>
      <span className="text-xs text-[#666] w-8 text-right">{value}%</span>
    </div>
  );
}

export default function RichterProfile() {
  const [profiles, setProfiles] = useState([]);
  const [cases, setCases] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [search, setSearch] = useState("");
  const [linkingId, setLinkingId] = useState(null);
  const [selectedCase, setSelectedCase] = useState("");
  const [detailProfile, setDetailProfile] = useState(null);
  const [katFilter, setKatFilter] = useState("Alle");
  const [showNetzwerk, setShowNetzwerk] = useState(false);

  useEffect(() => { load(); }, []);

  const load = async () => {
    setLoading(true);
    const [p, c] = await Promise.all([
      base44.entities.JudgeProfile.list("-created_date"),
      base44.entities.Case.list("-created_date"),
    ]);
    setProfiles(p);
    setCases(c);
    setLoading(false);
  };

  const save = async () => {
    if (!form.name.trim() || !form.gericht.trim()) return;
    if (editing) { await base44.entities.JudgeProfile.update(editing, form); setEditing(null); }
    else { await base44.entities.JudgeProfile.create(form); }
    setForm(EMPTY);
    setShowForm(false);
    load();
  };

  const del = async (id) => { await base44.entities.JudgeProfile.delete(id); load(); };

  const startEdit = (p) => {
    setForm({ name:p.name||"", gericht:p.gericht||"", kammer:p.kammer||"", rechtsgebiet:p.rechtsgebiet||"", kategorie:p.kategorie||"Richter", klaeger_rate:p.klaeger_rate||50, vergleich_rate:p.vergleich_rate||30, durchschnitt_dauer_monate:p.durchschnitt_dauer_monate||12, urteile_gesamt:p.urteile_gesamt||0, stil:p.stil||"Neutral", bekannt_fuer:p.bekannt_fuer||"", notizen:p.notizen||"" });
    setEditing(p.id);
    setShowForm(true);
  };

  const handleProfileUpdate = (updated) => {
    setProfiles(prev => prev.map(p => p.id
