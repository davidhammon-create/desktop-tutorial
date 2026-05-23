
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Plus, X, CheckCircle2, Circle, Clock } from "lucide-react";
import { getTByLanguage } from "../lib/jurisdictionConfig";
import { useUserProfile } from "../hooks/useUserProfile";

const PRIORITY_CONFIG = {
  hoch:    { label: { DE: "Hoch",   EN: "High",   FR: "Élevée"  }, color: "bg-red-100 text-red-700 ring-red-200" },
  mittel:  { label: { DE: "Mittel", EN: "Medium", FR: "Moyenne" }, color: "bg-amber-100 text-amber-700 ring-amber-200" },
  niedrig: { label: { DE: "Niedrig",EN: "Low",    FR: "Faible"  }, color: "bg-green-100 text-green-700 ring-green-200" },
};

const STATUS_CONFIG = {
  offen:          { label: { DE: "Offen",        EN: "Open",        FR: "Ouvert"   }, icon: Circle },
  in_bearbeitung: { label: { DE: "In Bearbeitung",EN: "In Progress", FR: "En cours" }, icon: Clock },
  erledigt:       { label: { DE: "Erledigt",     EN: "Done",        FR: "Terminé"  }, icon: CheckCircle2 },
};

const EMPTY = { title: "", case_id: "", case_name: "", notes: "", assignee: "", due_date: "", priority: "mittel", status: "offen" };

export default function Aufgaben() {
  const { language } = useUserProfile();
  const t = getTByLanguage(language);
  const lang = language || "DE";

  const [tasks, setTasks] = useState([]);
  const [cases, setCases] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("alle");
  const [filterPriority, setFilterPriority] = useState("alle");

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    setLoading(true);
    const [ts, cs] = await Promise.all([
      base44.entities.Task.list("-created_date"),
      base44.entities.Case.list("-updated_date", 100),
    ]);
    setTasks(ts);
    setCases(cs);
    setLoading(false);
  };

  const save = async () => {
    if (!form.title.trim()) return;
    const selectedCase = cases.find(c => c.id
